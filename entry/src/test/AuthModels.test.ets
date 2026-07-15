import { describe, it, expect } from '@ohos/hypium'
import { parseLoginResponse } from '../main/ets/services/authModels'

export default function authModelsTest() {
  describe('authModelsTest', () => {
    it('parseLoginResponse_success', 0, () => {
      const raw = JSON.stringify({
        success: true,
        message: 'ok',
        data: {
          token: 'abc123',
          userId: 1,
          username: 'weixing',
          membershipLevel: 'NORMAL',
          permissions: ['USER_SELF']
        }
      })
      const r = parseLoginResponse(raw)
      expect(r.success).assertTrue()
      expect(r.data !== undefined).assertTrue()
      expect(r.data!.token).assertEqual('abc123')
      expect(r.data!.username).assertEqual('weixing')
      expect(r.data!.membershipLevel).assertEqual('NORMAL')
    })

    it('parseLoginResponse_wrongPassword', 0, () => {
      const raw = JSON.stringify({
        success: false,
        message: 'username or password is incorrect',
        data: null
      })
      const r = parseLoginResponse(raw)
      expect(r.success).assertFalse()
      expect(r.message).assertEqual('username or password is incorrect')
      expect(r.data).assertUndefined()
    })

    it('parseLoginResponse_invalidJson', 0, () => {
      const r = parseLoginResponse('not a json')
      expect(r.success).assertFalse()
      expect(r.message).assertEqual('登录失败，请重试')
    })
  })
}
