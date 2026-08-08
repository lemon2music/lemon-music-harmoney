/*
 * IAP 后端服务：商品查询、预下单、上报验签发货、权益查询。
 * 对标 services/authservice.ets 的静态服务风格与 @ohos.net.http 用法。
 * 对应后端 IapController：GET /api/iap/products、POST /api/iap/orders、
 *   POST /api/iap/orders/report、GET /api/iap/entitlement。
 *
 * 鉴权：Authorization: Bearer <token>（与 AuthInterceptor 约定一致，token 取自 AppStorage）。
 */
import http from '@ohos.net.http'
import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { emitter } from '@kit.BasicServicesKit'
import {
  BackendProduct, PreOrderRequest, PreOrderData,
  ReportRequest, ReportData, EntitlementData,
  IapApiResponse, parseIapResponse
} from './iapModels'

const API_BASE = 'https://www.weixing.xin'
const PRODUCTS_PATH = '/api/iap/products'
const ORDERS_PATH = '/api/iap/orders'
const REPORT_PATH = '/api/iap/orders/report'
const ENTITLEMENT_PATH = '/api/iap/entitlement'
const PREF_NAME = 'auth_prefs'
const PREF_KEY_SESSION = 'auth_session'

/**
 * 事件名：当无法从本地存储获取到 token 时触发
 * 业务层应监听此事件并执行登出操作
 */
export const EVENT_TOKEN_MISSING = 'iap_token_missing'

interface SessionPayload {
  token: string
}

export class IapApiService {
  private static ctx: common.Context | null = null

  static setContext(ctx: common.Context): void {
    IapApiService.ctx = ctx
  }

  /** GET /api/iap/products —— 查询上架商品（含后端 id，预下单必需）。 */
  static async getProducts(): Promise<BackendProduct[] | null> {
    return IapApiService.request<BackendProduct[]>('GET', PRODUCTS_PATH, '')
  }

  /** POST /api/iap/orders —— 预下单，返回 orderNo（作为 developerPayload）。 */
  static async preOrder(iapProductId: number): Promise<PreOrderData | null> {
    const body = JSON.stringify(new PreOrderRequestBuilder(iapProductId))
    return IapApiService.request<PreOrderData>('POST', ORDERS_PATH, body)
  }

  /** POST /api/iap/orders/report —— 上报 purchaseData 验签发货（购买与补单共用）。 */
  static async report(iapProductType: string, purchaseData: string): Promise<ReportData | null> {
    const req = new ReportRequest()
    req.iapProductType = iapProductType
    req.purchaseData = purchaseData
    return IapApiService.request<ReportData>('POST', REPORT_PATH, JSON.stringify(req))
  }

  /** GET /api/iap/entitlement —— 查询当前用户权益（是否已购买）。 */
  static async getEntitlement(): Promise<EntitlementData | null> {
    return IapApiService.request<EntitlementData>('GET', ENTITLEMENT_PATH, '')
  }

  /**
   * 统一请求：附加 Bearer token，解析 ApiResponse<T>，失败/未登录返回 null。
   * GET 请求 body 传空字符串（不携带 extraData）。
   */
  private static async request<T>(method: string, path: string, body: string): Promise<T | null> {
    const token = await IapApiService.loadToken()
    if (!token) {
      console.warn(`IapApiService ${path}: 未登录，跳过`)
      return null
    }
    const client = http.createHttp()
    try {
      const option: http.HttpRequestOptions = {
        method: method === 'GET' ? http.RequestMethod.GET : http.RequestMethod.POST,
        header: IapApiService.buildHeader(token),
        connectTimeout: 15000,
        readTimeout: 15000,
        expectDataType: http.HttpDataType.STRING
      }
      if (method !== 'GET' && body !== '') {
        option.extraData = body
      }
      const resp = await client.request(`${API_BASE}${path}`, option)
      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        console.error(`IapApiService ${path} 网络异常:`, resp.responseCode)
        return null
      }
      const raw = typeof resp.result === 'string' ? resp.result : ''
      const result: IapApiResponse<T> = parseIapResponse<T>(raw, '请求失败，请稍后重试')
      const data = result.data
      if (result.success && data !== null && data !== undefined) {
        return data
      }
      console.error(`IapApiService ${path} 失败:`, result.message)
      return null
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e)
      console.error(`IapApiService ${path} 异常:`, msg)
      return null
    } finally {
      try { client.destroy() } catch (_) {}
    }
  }

  /** 读取持久化的 token（与 authservice.ets 的存储约定一致） */
  private static async loadToken(): Promise<string> {
    // token 同时存在于 AppStorage（authservice 写入），优先直接读取，避免重复 IO
    const cached = AppStorage.get<string>('token')
    if (cached) {
      return cached
    }
    const ctx = IapApiService.ctx
    if (!ctx) {
      console.warn('IapApiService.loadToken: context 未初始化')
      return ''
    }
    try {
      const pref = await preferences.getPreferences(ctx, PREF_NAME)
      const raw = await pref.get(PREF_KEY_SESSION, '') as string
      if (raw) {
        const session = JSON.parse(raw) as SessionPayload
        const token = session?.token ?? ''
        if (token) {
          return token
        }
      }
      // 无法获取到 token，触发事件通知业务层执行登出
      console.warn('IapApiService.loadToken: 无法获取到 token，触发登出事件')
      IapApiService.notifyTokenMissing()
    } catch (e) {
      console.error('IapApiService.loadToken: 读取失败', e)
      IapApiService.notifyTokenMissing()
    }
    return ''
  }

  /**
   * 通知业务层 token 缺失，需要重新登录
   * 使用事件机制避免服务层之间的直接依赖
   */
  private static notifyTokenMissing(): void {
    try {
      emitter.emit(EVENT_TOKEN_MISSING, { data: { reason: 'token_not_found_in_storage' } })
    } catch (e) {
      console.error('IapApiService.notifyTokenMissing: 事件发送失败', e)
    }
  }

  private static buildHeader(token: string): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }
  }
}

/** 预下单请求体构造器（仅 iapProductId 字段） */
class PreOrderRequestBuilder {
  iapProductId: number
  constructor(iapProductId: number) {
    this.iapProductId = iapProductId
  }
}

export default IapApiService
