/*
 * IAP 后端交互数据模型（强类型 DTO），与后端 record 一一对应。
 * 对标 services/authModels.ets 的纯数据风格，便于本地单元测试导入。
 * 不依赖任何 @ohos.* 设备 API。
 *
 * 对应后端端点：
 *   GET  /api/iap/products       → List<IapProductResponse>
 *   POST /api/iap/orders         入参 { iapProductId } → PreOrderResponse
 *   POST /api/iap/orders/report  入参 { iapProductType, purchaseData } → ReportPurchaseResponse
 *   GET  /api/iap/entitlement    → IapEntitlementResponse
 */

/** 后端 IAP 商品（IapProductResponse） */
export class BackendProduct {
  /** 后端商品主键（预下单用） */
  id: number = 0
  name: string = ''
  /** 华为 IAP 商品ID（createPurchase / 权益匹配用） */
  huaweiProductId: string = ''
  /** 商品类型枚举名：CONSUMABLE / NON_CONSUMABLE / AUTORENEWABLE / NONRENEWABLE */
  iapProductType: string = 'AUTORENEWABLE'
  /** 配置价格（元） */
  price: number = 0
  currency: string = 'CNY'
  /** 订阅类型：MONTHLY / QUARTERLY / YEARLY（订阅商品才有） */
  subscriptionType?: string
  description: string = ''
}

/** 预下单请求体 */
export class PreOrderRequest {
  iapProductId: number = 0
}

/** 预下单响应（PreOrderResponse）。orderNo 即端侧 createPurchase 的 developerPayload。 */
export class PreOrderData {
  orderNo: string = ''
  huaweiProductId: string = ''
  iapProductType: string = 'AUTORENEWABLE'
  amount: number = 0
  currency: string = 'CNY'
}

/** 上报验签请求体 */
export class ReportRequest {
  /** 商品类型枚举名：CONSUMABLE / NON_CONSUMABLE / AUTORENEWABLE / NONRENEWABLE */
  iapProductType: string = 'AUTORENEWABLE'
  purchaseData: string = ''
}

/** 上报验签响应（ReportPurchaseResponse） */
export class ReportData {
  /** 是否成功发货（false 表示已发放过/已退款，非错误） */
  fulfilled: boolean = false
  orderId: number = 0
  message: string = ''
}

/** 权益查询响应（IapEntitlementResponse） */
export class EntitlementData {
  /** 会员资格是否生效中 */
  vipActive: boolean = false
  /** 订阅到期时间戳(ms)，无生效订阅时为 0 */
  subscriptionExpireAt: number = 0
  /** 已拥有权益的华为商品ID列表 */
  ownedHuaweiProductIds: string[] = []
}

/** 后端统一响应体 */
export class IapApiResponse<T> {
  success: boolean = true
  message: string = ''
  data: T | null = null
}

/**
 * 解析后端统一响应。与 parseLoginResponse 保持一致的容错策略。
 */
export function parseIapResponse<T>(raw: string, fallbackMessage: string): IapApiResponse<T> {
  let parsed: IapApiResponse<T>
  try {
    parsed = JSON.parse(raw) as IapApiResponse<T>
  } catch (_) {
    return { success: false, message: fallbackMessage, data: null }
  }
  if (parsed === null || typeof parsed !== 'object') {
    return { success: false, message: fallbackMessage, data: null }
  }
  return parsed
}
