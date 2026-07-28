/**
 * 购买结果数据
 * createPurchase / queryPurchases 返回的 purchaseData JSON 字符串解析后的结构
 */
export interface PurchaseData {
  /** 商品类型: 0-消耗型, 1-非消耗型, 2-自动续期订阅, 3-非自动续期订阅 */
  type: number;
  /** JWS编码的购买订单信息（消耗型/非消耗型/非自动续期订阅） */
  jwsPurchaseOrder?: string;
  /** JWS编码的订阅组状态信息（仅自动续期订阅） */
  jwsSubscriptionStatus?: string;
}

/**
 * 购买订单载荷 — jwsPurchaseOrder 解码验签后得到的完整数据
 * 官方文档: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model
 */
export interface PurchaseOrderPayload {
  /** 应用ID (最大128字符) */
  applicationId: string;
  /** 商品ID (最大256字符) */
  productId: string;
  /** 商品类型: 0-消耗型, 1-非消耗型, 2-自动续期订阅, 3-非自动续期订阅 */
  productType: number;
  /** 购买订单ID，唯一标识一笔订单，一旦生成不会变化 (最大64字符) */
  purchaseOrderId: string;
  /** 购买令牌，自动续期订阅场景中与subscriptionId一一对应 (最大512字符) */
  purchaseToken: string;
  /** 购买时间戳(ms) */
  purchaseTime: number;
  /** JWS签名时间戳(ms) */
  signedTime: number;
  /** 用户国家/地区代码 */
  countryCode: string;
  /** 商品价格 */
  price: number;
  /** 币种代码(如CNY, USD) */
  currency: string;
  /** 环境标识: Sandbox-沙盒, Production-生产 */
  environment: string;
  /** 发货状态: 1-已发货, 2-未发货 */
  finishStatus: FinishStatus;
  /** 是否需要调用finishPurchase确认发货 */
  needFinish: boolean;
  /** 商户侧保留信息，由开发者在调用支付接口时传入，续费订单和服务端通知中100%原样返回 */
  developerPayload?: string;
  /** 购买订单撤销原因码，为空代表购买成功 */
  purchaseOrderRevocationReasonCode?: string;
  /** 优惠ID (最大256字符) */
  offerId?: string;
  /** 订阅ID (最大64字符)，订阅场景使用 */
  subscriptionId?: string;
  /** 订阅组生成ID (最大512字符)，订阅场景使用 */
  subGroupGenerationId?: string;
}

/** 发货状态枚举 */
export enum FinishStatus {
  /** 已发货 */
  FINISHED = '1',
  /** 未发货 */
  UNFINISHED = '2'
}

/**
 * 订阅组状态载荷 — jwsSubscriptionStatus 解码验签后得到的完整数据
 */
export interface SubGroupStatusPayload {
  /** 环境标识: Sandbox-沙盒, Production-生产 */
  environment: string;
  /** 应用ID */
  applicationId: string;
  /** 应用包名 */
  packageName: string;
  /** 订阅组ID */
  subGroupId: string;
  /** 最新订阅状态 */
  lastSubscriptionStatus?: SubscriptionStatus;
  /** 历史订阅状态列表 */
  historySubscriptionStatusList?: SubscriptionStatus[];
}

/**
 * 订阅状态
 */
export interface SubscriptionStatus {
  /** 订阅组生成ID */
  subGroupGenerationId: string;
  /** 订阅ID，与purchaseToken一一对应 */
  subscriptionId: string;
  /** 购买令牌，续费时不变，切换订阅时变化 */
  purchaseToken: string;
  /** 订阅状态: '1'-生效中, '2'-已过期, '3'-扣费重试中, '5'-已撤销 */
  status: SubStatus;
  /** 订阅到期时间戳(ms) */
  expiresTime: number;
  /** 最新购买订单 */
  lastPurchaseOrder?: PurchaseOrderPayload;
  /** 续期信息 */
  renewalInfo?: SubRenewalInfo;
}

/** 续期信息 */
export interface SubRenewalInfo {
  /** 续期商品ID */
  productId: string;
}

/** 订阅状态枚举 */
export enum SubStatus {
  /** 生效中 */
  ACTIVE = '1',
  /** 已过期 */
  EXPIRED = '2',
  /** 扣费重试中 */
  CHARGE_ATTEMPT = '3',
  /** 已撤销 */
  REVOKED = '5'
}

/**
 * 服务端REST API响应 — 订单状态查询
 * POST /order/harmony/v1/application/order/status/query
 */
export interface OrderStatusQueryResponse {
  /** 响应码，0表示成功 */
  responseCode: string;
  /** 响应描述 */
  responseMessage?: string;
  /** JWS编码的购买订单信息，解码后为PurchaseOrderPayload */
  jwsPurchaseOrder?: string;
}

/**
 * 服务端REST API响应 — 订阅状态查询
 * POST /subscription/harmony/v1/application/subscription/status/query
 */
export interface SubStatusQueryResponse {
  /** 响应码，0表示成功 */
  responseCode: string;
  /** 响应描述 */
  responseMessage?: string;
  /** JWS编码的订阅组状态信息，解码后为SubGroupStatusPayload */
  jwsSubGroupStatus?: string;
}

/**
 * 服务端关键事件通知载荷 — 通知JWS解码后得到的数据
 */
export interface NotificationPayload {
  /** 通知类型 */
  notificationType: string;
  /** 通知子类型 */
  notificationSubtype: string;
  /** 通知请求ID */
  notificationRequestId: string;
  /** 通知元数据 */
  notificationMetaData: NotificationMetaData;
  /** 通知版本 */
  notificationVersion: string;
  /** 签名时间戳(ms) */
  signedTime: number;
}

/**
 * 通知元数据
 */
export interface NotificationMetaData {
  /** 环境标识 */
  environment: string;
  /** 应用ID */
  applicationId: string;
  /** 应用包名 */
  packageName: string;
  /** 商品类型: 0-消耗型, 1-非消耗型, 2-自动续期订阅, 3-非自动续期订阅 */
  type: number;
  /** 当前商品ID */
  currentProductId: string;
  /** 订阅组ID */
  subGroupId?: string;
  /** 订阅组生成ID */
  subGroupGenerationId?: string;
  /** 订阅ID */
  subscriptionId?: string;
  /** 购买令牌 */
  purchaseToken: string;
  /** 购买订单ID */
  purchaseOrderId: string;
}
