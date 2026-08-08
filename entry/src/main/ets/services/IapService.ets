/*
 * IAP 服务类 - 封装 IAP Kit 全部环节 + 后端联动（对齐 music-back-service 契约）。
 *
 * 标准购买流程：
 *   环境检测 → 查询商品(后端 /api/iap/products + iap.queryProducts 实时价)
 *   → 服务器预下单(POST /api/iap/orders，orderNo 即 developerPayload)
 *   → 发起购买(收银台，developerPayload=orderNo)
 *   → 上报验签发放权益(POST /api/iap/orders/report)
 *   → 端侧确认发货(finishPurchase)
 *
 * 补单流程：queryPurchases → 上报验签 → 端侧确认发货。
 * 商品展示前查询购买状态(后端 /api/iap/entitlement + 端侧 queryPurchases)，避免重复购买。
 */
import { iap } from '@kit.IAPKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { JWSUtil } from '../common/JWSUtil'
import Logger from '../common/Logger'
import {
  PurchaseData, PurchaseOrderPayload, SubGroupStatusPayload, SubStatus
} from '../common/IapDataModel'
import { IapApiService } from './iapApiService'
import { BackendProduct, EntitlementData } from './iapModels'

const TAG = 'IapService'

/** 商品展示模型（页面直接消费） */
export interface MembershipProduct {
  /** 后端商品主键（预下单用） */
  backendId: number
  /** 华为 IAP 商品ID */
  huaweiProductId: string
  /** 商品类型枚举名（上报用） */
  iapProductType: string
  productName: string
  productDesc: string
  price: string
  originalPrice: string
  subscriptionPeriod: string
  /** 是否已拥有权益（禁用购买按钮，避免重复购买） */
  owned: boolean
  /** 订阅是否生效中 */
  active: boolean
  /** 到期时间戳(ms) */
  expiresTime: number
}

/** 环境检测结果 */
export interface IapEnvironmentStatus {
  isActivated: boolean
  isSandbox: boolean
}

/** 购买流程结果 */
export interface PurchaseFlowResult {
  success: boolean
  message: string
  /** 发货后会员等级（'VIP' / 'NORMAL'） */
  membershipLevel?: string
  /** 是否为掉单补发 */
  restored?: boolean
}

class IapService {
  private context: common.UIAbilityContext | null = null
  /** 端侧已购商品（queryPurchases 命中） */
  private purchasedProducts: Set<string> = new Set()
  /** 后端已拥有权益商品 */
  private backendOwnedProducts: Set<string> = new Set()
  /** vip 是否生效中 */
  private vipActive: boolean = false
  private lastEnvironment: IapEnvironmentStatus | null = null

  /** 初始化：环境检测 + 补单。由会员页 aboutToAppear 调用。 */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    IapApiService.setContext(context)
    await this.checkEnvironment()
    await this.queryPendingPurchases()
  }

  /** 标准流程①：环境检测（isSandboxActivated） */
  async checkEnvironment(): Promise<IapEnvironmentStatus | null> {
    if (!this.context) {
      Logger.error(TAG, 'checkEnvironment: context 未初始化')
      return null
    }
    try {
      const isSandbox = await iap.isSandboxActivated(this.context)
      this.lastEnvironment = { isActivated: true, isSandbox }
      Logger.info(TAG, `环境检测通过: ${JSON.stringify(this.lastEnvironment)}`)
      return this.lastEnvironment
    } catch (err) {
      const e = err as BusinessError
      Logger.error(TAG, `环境检测失败: ${e.code} - ${e.message}`)
      this.lastEnvironment = { isActivated: false, isSandbox: false }
      return this.lastEnvironment
    }
  }

  getEnvironment(): IapEnvironmentStatus | null {
    return this.lastEnvironment
  }

  /**
   * 加载商品 + 购买状态（页面入口）。
   * 后端 /api/iap/products 提供结构（含 backendId），iap.queryProducts 提供实时价/周期。
   * 合并 /api/iap/entitlement + queryPurchases 标记 owned/active。
   */
  async loadProducts(): Promise<MembershipProduct[]> {
    const backendList: BackendProduct[] | null = await IapApiService.getProducts()
    if (!backendList || backendList.length === 0) {
      return []
    }

    // 实时价/周期（可选增强，失败则用后端配置价）
    const huaweiIds = backendList.map(p => p.huaweiProductId).filter(id => !!id)
    const livePriceMap = await this.queryLiveProducts(huaweiIds)

    // 购买/权益状态
    const statusMap = await this.queryPurchaseStatus()

    return backendList.map(p => this.toMembershipProduct(p, livePriceMap, statusMap))
  }

  /** 查询 iap 实时商品（价格、订阅周期），失败返回空 map */
  private async queryLiveProducts(huaweiIds: string[]): Promise<Map<string, iap.Product>> {
    const map = new Map<string, iap.Product>()
    if (!this.context || huaweiIds.length === 0) {
      return map
    }
    try {
      const result = await iap.queryProducts(this.context, {
        productType: iap.ProductType.AUTORENEWABLE,
        productIds: huaweiIds
      })
      for (const item of result) {
        if (item.id) {
          map.set(item.id, item)
        }
      }
    } catch (err) {
      const e = err as BusinessError
      Logger.warn(TAG, `queryLiveProducts 失败（将使用后端配置价）: ${e.code} - ${e.message}`)
    }
    return map
  }

  /** 合并后端商品 + 实时价 + 状态 → 展示模型 */
  private toMembershipProduct(
    p: BackendProduct,
    liveMap: Map<string, iap.Product>,
    statusMap: Map<string, ProductPurchaseStatus>
  ): MembershipProduct {
    const live = liveMap.get(p.huaweiProductId)
    // 后端 price 为 BigDecimal，序列化可能为 number 或 string，统一 Number() 规整
    const backendPrice = Number(p.price) || 0
    const priceText = live?.localPrice ?? `¥${backendPrice.toFixed(2)}`
    const originalText = live?.originalLocalPrice ?? priceText
    const status = statusMap.get(p.huaweiProductId)
    return {
      backendId: p.id,
      huaweiProductId: p.huaweiProductId,
      iapProductType: p.iapProductType,
      productName: p.name,
      productDesc: p.description,
      price: priceText,
      originalPrice: originalText,
      subscriptionPeriod: this.formatPeriod(live, p.subscriptionType),
      owned: status?.purchased ?? false,
      active: status?.active ?? false,
      expiresTime: status?.expiresTime ?? 0
    }
  }

  /** 订阅周期描述：优先 iap subscriptionInfo，其次后端 subscriptionType */
  private formatPeriod(live?: iap.Product, subscriptionType?: string): string {
    if (live?.subscriptionInfo) {
      const count = live.subscriptionInfo.periodCount ?? 1
      const unit = live.subscriptionInfo.periodUnit
      const unitMap: Record<number, string> = { 0: '天', 1: '周', 2: '月', 3: '年' }
      const unitStr = unitMap[unit] ?? '月'
      return count === 1 ? `每${unitStr}` : `${count}${unitStr}`
    }
    switch (subscriptionType) {
      case 'MONTHLY': return '每月'
      case 'QUARTERLY': return '每季'
      case 'YEARLY': return '每年'
      default: return '自动续期'
    }
  }

  /**
   * 购买/权益状态：合并端侧 queryPurchases + 后端 /api/iap/entitlement。
   */
  async queryPurchaseStatus(): Promise<Map<string, ProductPurchaseStatus>> {
    const statusMap = new Map<string, ProductPurchaseStatus>()

    // 1) 端侧 queryPurchases（补单数据 + 本机未发货订单）
    try {
      const result = await iap.queryPurchases(this.context!, { productType: iap.ProductType.AUTORENEWABLE })
      const list = result?.purchaseDataList ?? []
      for (const purchaseData of list) {
        this.collectSubscriptionStatus(purchaseData, statusMap)
      }
    } catch (err) {
      const e = err as BusinessError
      Logger.error(TAG, `queryPurchases 失败: ${e.code} - ${e.message}`)
    }

    // 2) 后端权益查询（已发放权益 —— 真正的「是否已购买」依据）
    const ent: EntitlementData | null = await IapApiService.getEntitlement()
    if (ent) {
      this.backendOwnedProducts = new Set(ent.ownedHuaweiProductIds)
      this.vipActive = ent.vipActive
      for (const pid of ent.ownedHuaweiProductIds) {
        const exist = statusMap.get(pid) ?? { purchased: false, active: false, expiresTime: 0 }
        exist.purchased = true
        if (ent.vipActive) {
          exist.active = true
          exist.expiresTime = ent.subscriptionExpireAt || exist.expiresTime
        }
        statusMap.set(pid, exist)
      }
    }

    return statusMap
  }

  /** 解析订阅 purchaseData，填充状态 map */
  private collectSubscriptionStatus(purchaseDataStr: string, statusMap: Map<string, ProductPurchaseStatus>): void {
    try {
      const purchaseData: PurchaseData = JSON.parse(purchaseDataStr)
      if (!purchaseData.jwsSubscriptionStatus) {
        return
      }
      const decoded = JWSUtil.decodeJwsObj(purchaseData.jwsSubscriptionStatus)
      if (!decoded) {
        return
      }
      const subGroup: SubGroupStatusPayload = JSON.parse(decoded)
      const last = subGroup.lastSubscriptionStatus
      if (!last?.lastPurchaseOrder) {
        return
      }
      const productId = last.lastPurchaseOrder.productId
      const active = last.status === SubStatus.ACTIVE && last.expiresTime > Date.now()
      this.purchasedProducts.add(productId)
      statusMap.set(productId, {
        purchased: true,
        active,
        expiresTime: last.expiresTime
      })
    } catch (err) {
      Logger.error(TAG, `collectSubscriptionStatus 解析失败: ${JSON.stringify(err)}`)
    }
  }

  /**
   * 补单标准流程：queryPurchases → 上报验签 → 端侧确认发货。
   * 进入会员页时调用，处理掉单。
   */
  async queryPendingPurchases(): Promise<number> {
    if (!this.context) {
      return 0
    }
    let processed = 0
    try {
      Logger.info(TAG, '补单查询开始')
      const result = await iap.queryPurchases(this.context, { productType: iap.ProductType.AUTORENEWABLE })
      const list = result?.purchaseDataList ?? []
      if (list.length === 0) {
        Logger.info(TAG, '无未完成购买')
        return 0
      }
      for (const purchaseData of list) {
        const ok = await this.reportAndDeliver(purchaseData, 'AUTORENEWABLE')
        if (ok) {
          processed++
        }
      }
      Logger.info(TAG, `补单完成，处理 ${processed} 笔`)
    } catch (err) {
      const e = err as BusinessError
      Logger.error(TAG, `补单查询失败: ${e.code} - ${e.message}`)
    }
    return processed
  }

  /**
   * 上报 purchaseData → 服务器验签发放权益 → 端侧 finishPurchase 确认发货。
   * @returns ReportData（fulfilled=false 表示已发放过/已退款，非错误）
   */
  private async reportAndDeliver(purchaseDataStr: string, iapProductType: string): Promise<boolean> {
    // 1) 上报服务端验签发放权益
    const reportResult = await IapApiService.report(iapProductType, purchaseDataStr)
    if (!reportResult) {
      Logger.warn(TAG, '服务端上报失败或未登录')
    }

    // 2) 端侧确认发货（即使服务端判定已发放过，仍需 finish 避免订单悬挂）
    const order = this.extractPurchaseOrder(purchaseDataStr, this.toIapProductType(iapProductType))
    if (order) {
      await this.finishPurchase(this.toIapProductType(iapProductType), order.purchaseToken, order.purchaseOrderId)
    }
    return true
  }

  /** 从 purchaseData 抽取 purchaseToken / purchaseOrderId */
  private extractPurchaseOrder(purchaseDataStr: string, productType: iap.ProductType): PurchaseOrderPayload | null {
    try {
      const purchaseData: PurchaseData = JSON.parse(purchaseDataStr)
      if (productType === iap.ProductType.AUTORENEWABLE) {
        if (!purchaseData.jwsSubscriptionStatus) {
          return null
        }
        const decoded = JWSUtil.decodeJwsObj(purchaseData.jwsSubscriptionStatus)
        const subGroup: SubGroupStatusPayload = JSON.parse(decoded)
        return subGroup.lastSubscriptionStatus?.lastPurchaseOrder ?? null
      }
      if (!purchaseData.jwsPurchaseOrder) {
        return null
      }
      const decoded = JWSUtil.decodeJwsObj(purchaseData.jwsPurchaseOrder)
      return JSON.parse(decoded) as PurchaseOrderPayload
    } catch (err) {
      Logger.error(TAG, `extractPurchaseOrder 失败: ${JSON.stringify(err)}`)
      return null
    }
  }

  /**
   * 完整购买流程（标准流程③~⑥）。
   * @param product 由 loadProducts 返回的展示模型
   */
  async purchaseFlow(product: MembershipProduct): Promise<PurchaseFlowResult> {
    if (!this.context) {
      return { success: false, message: '服务未初始化' }
    }

    const productType = this.toIapProductType(product.iapProductType)

    // 防重复购买：本地/后端已命中则直接补单，不再拉起收银台
    if (this.isProductPurchased(product.huaweiProductId)) {
      Logger.info(TAG, `商品 ${product.huaweiProductId} 已购买，触发补单而非重新购买`)
      await this.queryPendingPurchases()
      return { success: true, message: '已开通，已为您同步权益', restored: true }
    }

    // ③ 服务器预下单（返回 orderNo 作为 developerPayload）
    const preOrder = await IapApiService.preOrder(product.backendId)
    if (!preOrder || !preOrder.orderNo) {
      return { success: false, message: '预下单失败，请稍后重试' }
    }

    // ④ 发起购买，拉起收银台（developerPayload=orderNo，服务端凭此对账发货）
    let purchaseDataStr: string
    try {
      purchaseDataStr = await this.createPurchase(product.huaweiProductId, productType, preOrder.orderNo)
    } catch (err) {
      const e = err as BusinessError
      Logger.error(TAG, `createPurchase 失败: ${e.code} - ${e.message}`)
      if (e.code === 17720011) {
        return { success: false, message: '' } // 用户取消
      }
      // 1001860051 商品已拥有 / 1001860001 系统错误 → 触发补单
      if (e.code === 1001860051 || e.code === 1001860001) {
        await this.queryPendingPurchases()
        return { success: false, message: '检测到未完成订单，已尝试补发权益' }
      }
      return { success: false, message: `购买失败: ${e.message || '请稍后重试'}` }
    }

    // ⑤⑥ 上报验签发放权益 + 端侧确认发货
    await this.reportAndDeliver(purchaseDataStr, product.iapProductType)

    // 更新本地缓存
    this.purchasedProducts.add(product.huaweiProductId)

    // 刷新权益，获取最新 vipActive → 会员等级
    await this.queryPurchaseStatus()
    return {
      success: true,
      message: '开通成功',
      membershipLevel: this.vipActive ? 'VIP' : 'NORMAL'
    }
  }

  /** 标准流程④：发起购买，拉起收银台 */
  private async createPurchase(productId: string, productType: iap.ProductType, developerPayload: string): Promise<string> {
    const purchaseParam: iap.PurchaseParameter = {
      productId,
      productType,
      developerPayload
    }
    const result = await iap.createPurchase(this.context!, purchaseParam)
    Logger.info(TAG, `createPurchase 成功: ${productId}`)
    return result.purchaseData
  }

  /** 标准流程⑥：端侧确认发货 */
  async finishPurchase(productType: iap.ProductType, purchaseToken: string, purchaseOrderId: string): Promise<void> {
    if (!this.context) {
      return
    }
    try {
      const param: iap.FinishPurchaseParameter = { productType, purchaseToken, purchaseOrderId }
      await iap.finishPurchase(this.context, param)
      Logger.info(TAG, `finishPurchase 成功: ${purchaseOrderId}`)
    } catch (err) {
      const e = err as BusinessError
      if (e.code === 1001860053) {
        Logger.info(TAG, '订单已完成发货，无需重复发货')
        return
      }
      Logger.error(TAG, `finishPurchase 失败: ${e.code} - ${e.message}`)
    }
  }

  /** 是否已购（端侧缓存 + 后端权益） */
  isProductPurchased(huaweiProductId: string): boolean {
    return this.purchasedProducts.has(huaweiProductId) || this.backendOwnedProducts.has(huaweiProductId)
  }

  /** 后端商品类型枚举名 → iap.ProductType。
   *  注意：NONRENEWABLE 自 API 14 起提供，本工程目标 API 12 暂不支持，归入默认（当前业务仅订阅）。 */
  private toIapProductType(typeName: string): iap.ProductType {
    switch (typeName) {
      case 'CONSUMABLE': return iap.ProductType.CONSUMABLE
      case 'NON_CONSUMABLE': return iap.ProductType.NONCONSUMABLE
      // NONRENEWABLE 目标 API 12 暂不可用，如需支持请升级 compatibleSdkVersion
      default: return iap.ProductType.AUTORENEWABLE
    }
  }
}

/** 单个商品的购买/权益状态 */
export interface ProductPurchaseStatus {
  purchased: boolean
  active: boolean
  expiresTime: number
}

const iapServiceInstance = new IapService()
export default iapServiceInstance
