/*
 * 认证服务：封装登录接口调用、会话持久化与 AppStorage 同步。
 * 对标 services/avplayermanager.ets 的静态服务风格。
 * 注意：isLogin 由 mainpage.ets 的 PersistentStorage 拥有，本服务不写该键。
 */
import http from '@ohos.net.http'
import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'
import { parseLoginResponse, LoginData, LoginResult } from './authModels'

const API_BASE = 'http://47.119.121.254:8080'
const LOGIN_PATH = '/api/auth/login'
const PREF_NAME = 'auth_prefs'
const PREF_KEY_SESSION = 'auth_session'

interface StoredSession {
  token: string
  userId: number
  username: string
  membershipLevel: string
  permissions: string[]
}

export class AuthService {
  private static ctx: common.Context | null = null

  static setContext(ctx: common.Context): void {
    this.ctx = ctx
  }

  static async login(username: string, password: string): Promise<LoginResult> {
    const client = http.createHttp()
    try {
      const resp = await client.request(`${API_BASE}${LOGIN_PATH}`, {
        method: http.RequestMethod.POST,
        // HarmonyOS http 通过 extraData 携带请求体；传 JSON 字符串 + json Content-Type 最稳。
        extraData: JSON.stringify({ username: username, password: password }),
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 15000,
        readTimeout: 15000,
        expectDataType: http.HttpDataType.STRING
      })
      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        return { success: false, message: '网络异常，请稍后重试' }
      }
      const raw = typeof resp.result === 'string' ? resp.result : ''
      const result = parseLoginResponse(raw)
      if (result.success && result.data) {
        await this.persistSession(result.data)
        this.applyToAppStorage(result.data)
      }
      return result
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e)
      console.error('AuthService.login 失败:', msg)
      return { success: false, message: '网络异常，请稍后重试' }
    } finally {
      try { client.destroy() } catch (_) {}
    }
  }

  static async logout(): Promise<void> {
    await this.clearSession()
    this.clearAppStorage()
  }

  static async restore(): Promise<void> {
    const session = await this.loadSession()
    if (session) {
      this.applyToAppStorage(session)
    }
  }

  private static applyToAppStorage(s: StoredSession): void {
    AppStorage.setOrCreate('username', s.username)
    AppStorage.setOrCreate('membershipLevel', s.membershipLevel)
    AppStorage.setOrCreate('userId', s.userId)
    AppStorage.setOrCreate('token', s.token)
  }

  private static clearAppStorage(): void {
    AppStorage.setOrCreate('username', '')
    AppStorage.setOrCreate('membershipLevel', '')
    AppStorage.setOrCreate('userId', 0)
    AppStorage.setOrCreate('token', '')
  }

  private static async persistSession(data: LoginData): Promise<void> {
    if (!this.ctx) {
      console.error('AuthService: 未设置 context，无法持久化会话')
      return
    }
    const pref = await preferences.getPreferences(this.ctx, PREF_NAME)
    const session: StoredSession = {
      token: data.token,
      userId: data.userId,
      username: data.username,
      membershipLevel: data.membershipLevel,
      permissions: data.permissions
    }
    await pref.put(PREF_KEY_SESSION, JSON.stringify(session))
    await pref.flush()
  }

  private static async clearSession(): Promise<void> {
    if (!this.ctx) { return }
    const pref = await preferences.getPreferences(this.ctx, PREF_NAME)
    await pref.delete(PREF_KEY_SESSION)
    await pref.flush()
  }

  private static async loadSession(): Promise<StoredSession | null> {
    if (!this.ctx) { return null }
    const pref = await preferences.getPreferences(this.ctx, PREF_NAME)
    const raw = await pref.get(PREF_KEY_SESSION, '') as string
    if (!raw) { return null }
    try {
      const obj = JSON.parse(raw) as StoredSession
      if (obj && obj.token) { return obj }
    } catch (_) {}
    return null
  }
}

export default AuthService
