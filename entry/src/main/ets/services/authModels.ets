/*
 * 认证相关纯数据模型与响应解析。
 * 刻意不依赖任何 @ohos.* 设备 API，以便在本地单元测试（entry/src/test）中直接导入测试。
 */

/** 登录成功返回的业务数据 */
export interface LoginData {
  token: string
  userId: number
  username: string
  membershipLevel: string
  permissions: string[]
}

/** 后端统一响应体 */
export interface ApiResponse {
  success: boolean
  message: string
  data: LoginData | null
}

/** 供调用方使用的登录结果 */
export interface LoginResult {
  success: boolean
  message: string
  data?: LoginData
}

/**
 * 解析后端 /api/auth/login 的原始 JSON 字符串。
 * - success 且 data.token 存在 → {success:true, message, data}
 * - success:false → {success:false, message}
 * - 解析失败或结构异常 → {success:false, message:'登录失败，请重试'}
 */
export function parseLoginResponse(raw: string): LoginResult {
  let parsed: ApiResponse
  try {
    parsed = JSON.parse(raw) as ApiResponse
  } catch (_) {
    return { success: false, message: '登录失败，请重试' }
  }
  if (parsed === null || typeof parsed !== 'object') {
    return { success: false, message: '登录失败，请重试' }
  }
  if (parsed.success && parsed.data && parsed.data.token) {
    return { success: true, message: parsed.message ?? 'ok', data: parsed.data }
  }
  return { success: false, message: parsed.message || '登录失败，请重试' }
}
