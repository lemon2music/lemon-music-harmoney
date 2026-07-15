# 真实会员登录 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把假的硬编码登录替换为真实后端会员认证（`POST http://47.119.121.254:8080/api/auth/login`），持久化会话、启动恢复、在「我的」页展示会员等级徽章。

**Architecture:** 新建独立 `AuthService` 静态服务（对标 `avplayermanager.ets` 风格）封装登录调用与会话持久化；响应解析抽成纯函数 `parseLoginResponse` 单独成文件以便本地单元测试。会话用 `@ohos.data.preferences` 持久化，`AppStorage` 作响应式层驱动 UI。`isLogin` 沿用现有 `mainpage.ets` 的 `PersistentStorage` 管理，`AuthService` 不接手，避免双写冲突。

**Tech Stack:** ArkTS / ArkUI, HarmonyOS 5.0.0 (API 12), `@ohos.net.http`, `@ohos.data.preferences`, AppStorage / PersistentStorage, `@ohos/hypium` 单元测试。

## Global Constraints

- 目标 SDK：HarmonyOS 5.0.0 (API 12)，Stage 模型。明文 HTTP 在 Stage 模型默认允许（无需 `usesCleartextTraffic` 等配置），仅需声明 `ohos.permission.INTERNET`。
- 后端 BASE：`http://47.119.121.254:8080`，登录路径 `/api/auth/login`，请求体 `{"username":string,"password":string}`，`Content-Type: application/json`。
- AppStorage 键约定：`isLogin`（由 `mainpage.ets` 的 PersistentStorage 拥有，**AuthService 不得写**）、`username`、`membershipLevel`、`userId`、`token`（后四个由 AuthService 管理）。
- 服务风格：静态类 + `setContext()` 注入上下文（对标 `services/avplayermanager.ets`、`services/deeplinkHandler.ets`）。命名导出 `{ AuthService }`。
- `@ohos.net.http` 调用必须 `finally { client.destroy() }`，超时 15s。
- 提交规范：每个任务结束提交一次，提交信息结尾加 `Co-Authored-By: Claude <noreply@anthropic.com>`。

---

## File Structure

| 文件 | 职责 | 动作 |
|---|---|---|
| `entry/src/main/ets/services/authModels.ets` | 纯类型 + `parseLoginResponse`（不依赖任何 `@ohos.*`，可本地单测） | 新建 |
| `entry/src/main/ets/services/authservice.ets` | `AuthService`：login/logout/restore + 持久化 + AppStorage 同步 | 新建 |
| `entry/src/test/AuthModels.test.ets` | `parseLoginResponse` 本地单元测试 | 新建 |
| `entry/src/test/List.test.ets` | 注册新测试套件 | 修改 |
| `entry/src/main/module.json5` | 放开 `ohos.permission.INTERNET` | 修改 |
| `entry/src/main/ets/otherpages/login_page.ets` | `doLogin()` 接真实接口；删硬编码 | 修改 |
| `entry/src/main/ets/entryability/EntryAbility.ets` | 注入 context + `restore()` | 修改 |
| `entry/src/main/ets/components/my_page.ets` | 昵称用 `username`、会员徽章、退出调 `logout()` | 修改 |

---

## Task 1: 纯响应解析函数（TDD）

**Files:**
- Create: `entry/src/main/ets/services/authModels.ets`
- Create: `entry/src/test/AuthModels.test.ets`
- Modify: `entry/src/test/List.test.ets`

**Interfaces:**
- Produces: `parseLoginResponse(raw: string): LoginResult`，及类型 `LoginData` / `ApiResponse` / `LoginResult`。供 Task 3 的 `AuthService` 导入。

- [ ] **Step 1: 写失败测试**

Create `entry/src/test/AuthModels.test.ets`:

```ts
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
```

- [ ] **Step 2: 注册测试套件**

Replace the whole content of `entry/src/test/List.test.ets` with:

```ts
import localUnitTest from './LocalUnit.test'
import authModelsTest from './AuthModels.test'

export default function testsuite() {
  localUnitTest()
  authModelsTest()
}
```

- [ ] **Step 3: 运行测试确认失败**

Run: `hvigorw test`（或 DevEco Studio Test Runner）
Expected: FAIL —— `parseLoginResponse` 未定义 / 模块 `../main/ets/services/authModels` 不存在。

- [ ] **Step 4: 写最小实现**

Create `entry/src/main/ets/services/authModels.ets`:

```ts
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
```

- [ ] **Step 5: 运行测试确认通过**

Run: `hvigorw test`（或 DevEco Test Runner）
Expected: PASS —— `parseLoginResponse_success`、`parseLoginResponse_wrongPassword`、`parseLoginResponse_invalidJson` 三例全部通过。

> 若本地单测无法解析 `../main/ets/services/authModels` 导入（hvigor 测试构建配置差异），将 `AuthModels.test.ets` 改放到 `entry/src/ohosTest/ets/test/` 并在 `entry/src/ohosTest/ets/test/List.test.ets` 注册；ohosTest 运行在设备上，导入路径相同、必然可用。

- [ ] **Step 6: 提交**

```bash
git add entry/src/main/ets/services/authModels.ets entry/src/test/AuthModels.test.ets entry/src/test/List.test.ets
git commit -m "$(cat <<'EOF'
feat(auth): add pure login response parser with unit tests

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: 放开 INTERNET 权限

**Files:**
- Modify: `entry/src/main/module.json5:14-24`（当前 `requestPermissions` 整段被注释）

**Interfaces:**
- 无代码接口。放开后 `@ohos.net.http` 才能真正联网（Stage 模型无需明文配置）。

- [ ] **Step 1: 放开权限声明**

在 `entry/src/main/module.json5` 中，把被注释的 `requestPermissions` 整段替换为只声明 INTERNET 的有效段。

把：
```json5
//    "requestPermissions": [
//      { "name": "ohos.permission.INTERNET" },
//      {
//        "name": "ohos.permission.SUBSCRIBE_NOTIFICATION",
//        "reason": "$string:notification_reason",
//        "usedScene": {
//          "abilities": ["EntryAbility"],
//          "when": "always"
//        }
//      }
//    ],
```

替换为：
```json5
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" }
    ],
```

（保持其在 `"module"` 对象内、`"routerMap"` 附近的原有相对位置即可。）

- [ ] **Step 2: 校验配置可编译**

Run: `hvigorw assembleHap --mode debug`
Expected: 构建成功，无 module.json5 解析错误。

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/module.json5
git commit -m "$(cat <<'EOF'
chore: enable ohos.permission.INTERNET for network access

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: AuthService 服务（login/logout/restore）

**Files:**
- Create: `entry/src/main/ets/services/authservice.ets`

**Interfaces:**
- Consumes: Task 1 的 `parseLoginResponse`、`LoginData`、`LoginResult`（来自 `./authModels`）。
- Produces: `AuthService` 类，命名导出。后续任务使用：
  - `AuthService.setContext(ctx: common.Context): void`
  - `AuthService.login(username: string, password: string): Promise<LoginResult>`
  - `AuthService.logout(): Promise<void>`
  - `AuthService.restore(): Promise<void>`
- 写入 AppStorage 键：`username`、`membershipLevel`、`userId`、`token`（**不写 `isLogin`**，见 Global Constraints）。

- [ ] **Step 1: 写实现**

Create `entry/src/main/ets/services/authservice.ets`:

```ts
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
```

- [ ] **Step 2: 校验编译**

Run: `hvigorw assembleHap --mode debug`
Expected: 构建成功（`AuthService` 尚未被引用，但不影响编译）。

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/services/authservice.ets
git commit -m "$(cat <<'EOF'
feat(auth): add AuthService for login, logout, and session restore

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: login_page 接入真实接口

**Files:**
- Modify: `entry/src/main/ets/otherpages/login_page.ets:2`（import）
- Modify: `entry/src/main/ets/otherpages/login_page.ets:157-177`（`doLogin`）
- Modify: `entry/src/main/ets/otherpages/login_page.ets:314-327`（按钮 `onClick`）

**Interfaces:**
- Consumes: `AuthService.login(username, password): Promise<LoginResult>`（Task 3）。

- [ ] **Step 1: 加 import**

在 `entry/src/main/ets/otherpages/login_page.ets` 顶部，现有 import 之后加：

```ts
import { AuthService } from '../services/authservice'
```

（放在第 2 行 `import { router } from '@kit.ArkUI'` 之后。）

- [ ] **Step 2: 重写 `doLogin()`**

把 `login_page.ets:157-177` 的整个 `doLogin` 方法替换为：

```ts
  private async doLogin() {
    if (!this.validate()) { return }
    this.loading = true
    const result = await AuthService.login(this.account.trim(), this.password)
    if (result.success) {
      this.isLogin = true
      this.mainindex = true
      this.selectMineAfterLogin = true
      this.loading = false
      this.error = ''
      router.back()
    } else {
      this.loading = false
      this.error = result.message || '登录失败，请重试'
    }
  }
```

- [ ] **Step 3: 改登录按钮 `onClick`，删除硬编码**

把 `login_page.ets:314-327` 的 `onClick` 替换为（只保留协议勾选闸门，删除 `admin/123456` 与重复的密码长度判断——`validate()` 已覆盖）：

```ts
          .onClick(() => {
            if (!this.ischoose) {
              this.dialogControllerCheckBox.open()
              return
            }
            this.doLogin()
          })
```

- [ ] **Step 4: 校验编译**

Run: `hvigorw assembleHap --mode debug`
Expected: 构建成功。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/otherpages/login_page.ets
git commit -m "$(cat <<'EOF'
feat(auth): wire login page to real backend, remove hardcoded check

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: 启动恢复登录态（EntryAbility）

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets:4` 附近（import）
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets:32` 之后（`onWindowStageCreate` 内注入 context + restore）

**Interfaces:**
- Consumes: `AuthService.setContext(ctx)`、`AuthService.restore()`（Task 3）。
- 注入的 `this.context`（`UIAbilityContext`，兼容 `common.Context`）。

- [ ] **Step 1: 加 import**

在 `EntryAbility.ets` 顶部 import 区（第 6 行 `import { DeeplinkHandler } ...` 之后）加：

```ts
import { AuthService } from '../services/authservice';
```

- [ ] **Step 2: 在 `onWindowStageCreate` 注入 context 并恢复会话**

在 `EntryAbility.ets:32` 的 `avplayerClass.setContext(...)` 调用之后，紧接着插入两行：

```ts
    AuthService.setContext(this.context)
    AuthService.restore()
```

（最终该段形如：）
```ts
    const rm = this.context.resourceManager;
    avplayerClass.setContext(this.context.cacheDir, this.context.filesDir, (path: string) => rm.getRawFileDescriptor(path));

    AuthService.setContext(this.context)
    AuthService.restore()

    console.info('MusicNotification: 已配置通知管理器的跳转目标')
```

- [ ] **Step 3: 校验编译**

Run: `hvigorw assembleHap --mode debug`
Expected: 构建成功。

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/ets/entryability/EntryAbility.ets
git commit -m "$(cat <<'EOF'
feat(auth): restore auth session on app startup

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: 「我的」页会员徽章 + 真实退出

**Files:**
- Modify: `entry/src/main/ets/components/my_page.ets:7`（import）
- Modify: `entry/src/main/ets/components/my_page.ets:17-25`（新增 StorageLink）
- Modify: `entry/src/main/ets/components/my_page.ets:57-68`（昵称 + 徽章）
- Modify: `entry/src/main/ets/components/my_page.ets:160-165`（退出调 logout）
- 新增私有方法 `membershipLabel()`

**Interfaces:**
- Consumes: AppStorage 键 `username`、`membershipLevel`（Task 3 写入）；`AuthService.logout()`（Task 3）。

- [ ] **Step 1: 加 import**

在 `my_page.ets:7` 的 `import { router } from "@kit.ArkUI";` 之后加：

```ts
import { AuthService } from '../services/authservice'
```

- [ ] **Step 2: 新增 StorageLink**

在 `my_page.ets` 的 `@StorageLink` 区（第 24-25 行的 `isLogin`、`selectMineAfterLogin` 之后）加：

```ts
  @StorageLink('username') username:string=''
  @StorageLink('membershipLevel') membershipLevel:string=''
```

- [ ] **Step 3: 加 `membershipLabel()` 方法**

在 `my_page.ets` 的 `build()` 方法之前（`@StorageLink` 声明之后、`build() {` 之前）加：

```ts
  private membershipLabel(): string {
    switch (this.membershipLevel) {
      case 'NORMAL': return '普通会员'
      case 'VIP': return 'VIP会员'
      case '': return ''
      default: return this.membershipLevel
    }
  }
```

- [ ] **Step 4: 昵称改用 username 并加会员徽章**

把 `my_page.ets:57-68` 的昵称 `Row` 替换为：

```ts
      Row({space:5}){
        Text(this.username || this.name)
          .fontSize(24)
          .fontWeight(700)
          .fontColor('#ffda2620')
          .textAlign(TextAlign.Center)
        if (this.membershipLabel()) {
          Text(this.membershipLabel())
            .fontSize(12)
            .fontColor('#ffab884c')
            .backgroundColor('#fff3e6')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 4 })
        }
        Image($r('app.media.lv3'))
          .width(20)
          .aspectRatio(1)
          .borderRadius(15)
      }
      .margin({bottom:5})
```

- [ ] **Step 5: 退出登录调用 AuthService.logout()**

把 `my_page.ets:160-165` 的退出 `onClick` 替换为：

```ts
          .onClick(()=>{
            // 清除后端会话与本地登录状态并返回主页面
            AuthService.logout()
            this.isLogin = false
            this.selectMineAfterLogin = false
            router.replaceUrl({ url: 'pages/mainpage' })
          })
```

- [ ] **Step 6: 校验编译**

Run: `hvigorw assembleHap --mode debug`
Expected: 构建成功。

- [ ] **Step 7: 提交**

```bash
git add entry/src/main/ets/components/my_page.ets
git commit -m "$(cat <<'EOF'
feat(auth): show membership badge and real logout on profile page

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: 端到端设备验收

**Files:**
- 无代码改动。在真机/模拟器上验证整条链路。

**Interfaces:**
- 验证 Task 1-6 联动后的真实行为。

- [ ] **Step 1: 安装到设备**

Run: `hvigorw assembleHap` 然后 `hdc install entry/build/default/outputs/default/entry-default-signed.hap`
Expected: 安装成功。

- [ ] **Step 2: 成功登录路径**

操作：打开 App → 「我的」→ 去登录 → 输入 `weixing` / `Test@123456` → 勾选协议 → 登录。
Expected: 返回「我的」页，昵称显示 `weixing`，昵称旁出现「普通会员」徽章。

- [ ] **Step 3: 失败路径（错误密码）**

操作：退出登录后，再次登录 `weixing` / `wrongpass`。
Expected: 登录按钮恢复，错误区显示后端原文 `username or password is incorrect`。

- [ ] **Step 4: 本地校验路径**

操作：不填账号点登录；只填账号、密码填 `123`（<6 位）点登录。
Expected: 分别提示 `请输入账号`、`密码不少于6位`（来自 `validate()`，不发请求）。

- [ ] **Step 5: 持久化与启动恢复**

操作：登录成功后，杀进程彻底退出 App，重新打开。
Expected: 直接进入登录态，「我的」页仍显示 `weixing` + 「普通会员」徽章（`AuthService.restore()` 生效）。

- [ ] **Step 6: 退出登录**

操作：「我的」→ 退出登录。
Expected: 回到未登录占位 UI；再次杀进程重启 → 仍为未登录态（会话已清除）。

- [ ] **Step 7: 断网路径**

操作：断开设备网络，输入正确账号点登录。
Expected: 错误区显示 `网络异常，请稍后重试`，不崩溃。

- [ ] **Step 8: 全量构建确认**

Run: `hvigorw assembleHap`
Expected: 构建成功，无报错。

> 全部用例通过即视为完成。无需提交（本任务无代码改动）。
