# 真实会员登录改造设计

- 日期：2026-07-15
- 作者：Claude（与用户协作）
- 状态：待评审

## 1. 背景与目标

当前登录模块（`otherpages/login_page.ets`）是假实现：`doLogin()` 仅把 `isLogin` 置 true，并在按钮点击处硬编码校验 `account === 'admin' && password === '123456'`（行 322-326），没有任何后端交互。

目标：替换为真实后端会员认证，并持久化登录态、展示会员等级。

## 2. 后端接口契约（已实测）

`POST http://47.119.121.254:8080/api/auth/login`

请求体：
```json
{ "username": "weixing", "password": "Test@123456" }
```

成功响应（HTTP 200）：
```json
{
  "success": true,
  "message": "ok",
  "data": {
    "token": "ec4ac44f81964ffa9cab0a90bbb75f06",
    "userId": 1,
    "username": "weixing",
    "membershipLevel": "NORMAL",
    "permissions": ["USER_SELF"]
  }
}
```

失败响应：
```json
{ "success": false, "message": "username or password is incorrect", "data": null }
{ "success": false, "message": "username cannot be blank", "data": null }
```

说明：`/api/user/profile` 不存在（返回 500）。登录响应即用户信息的唯一来源（token / userId / username / membershipLevel / permissions）。

## 3. 已确认的决策

1. **范围**：真实认证 + 会员等级展示（不做权限功能门禁）。
2. **个人资料字段**：后端不返回头像/性别/年龄等。本地保留这些字段（现有编辑页不动），登录后昵称用后端 `username`，新增会员徽章。
3. **持久化**：持久化 token/username/membershipLevel，启动直接恢复登录态（信任本地 token，不在启动时调后端校验）。
4. **实现方案**：方案 A —— 新建独立 `AuthService` 服务（对标 `avplayermanager.ets` 静态服务风格）。

## 4. 架构与组件

### 4.1 新增：`entry/src/main/ets/services/authservice.ets`

静态服务类，职责单一。

```
AuthService
├── 常量
│   ├── API_BASE = 'http://47.119.121.254:8080'
│   ├── LOGIN_PATH = '/api/auth/login'
│   ├── PREF_NAME = 'auth_prefs'
│   └── PREF_KEY_SESSION = 'auth_session'
├── setContext(ctx)                 ← EntryAbility 启动注入
├── login(username, password)       ← 返回 {success, message, data?}；不碰路由
├── logout()                        ← 清持久化 + AppStorage
├── restore()                       ← 启动时从 preferences 恢复到 AppStorage
├── parseLoginResponse(rawJson)     ← 纯函数，便于单元测试
└── 私有: persistSession / clearSession / applyToAppStorage
```

边界约定：
- `login()` 不做路由跳转，只返回结果，由 UI 决定如何导航。
- `restore()` 只在启动时调用一次。
- `logout()` 既清持久化也清 AppStorage。

类型定义：
```ts
interface LoginData {
  token: string
  userId: number
  username: string
  membershipLevel: string   // 'NORMAL' | 其他等级
  permissions: string[]
}
interface ApiResponse {
  success: boolean
  message: string
  data: LoginData | null
}
interface LoginResult { success: boolean; message: string; data?: LoginData }
```

### 4.2 AppStorage 键（UI 用 `@StorageLink` 绑定）

| 键 | 类型 | 用途 |
|---|---|---|
| `isLogin` | boolean | 登录态总开关（已存在）|
| `username` | string | 登录后覆盖「我的」昵称 |
| `membershipLevel` | string | 会员徽章（NORMAL 等）|
| `userId` | number | 预留 |
| `token` | string | 预留，未来鉴权请求用 |

### 4.3 持久化

`@ohos.data.preferences`（与 `Uitl/preferences.ets` 一致）存整个 session 为一条 JSON（键 `auth_session`）。AppStorage 作为响应式层，UI 自动刷新。

## 5. 数据流

### 5.1 登录
```
login_page 输入 → 点「登录」
  → 保留协议勾选(ischoose) 闸门
  → validate(): 账号非空、密码≥6位 → 否则本地报错
  → loading=true → AuthService.login(username, password)
        ├─ http.createHttp() POST {username,password}
        │     (Content-Type: application/json, connectTimeout/readTimeout=15s)
        ├─ 解析 {success,message,data}
        ├─ success && data → persistSession + applyToAppStorage → {success:true}
        └─ 否则 → {success:false, message}
  → 成功: selectMineAfterLogin=true → loading=false → router.back()
  → 失败: loading=false → 把 message 显示到 error
```

### 5.2 启动恢复
```
EntryAbility.onWindowStageCreate
  → AuthService.setContext(context)
  → AuthService.restore()
        └─ 读 preferences 'auth_session' → 有则写入 AppStorage(isLogin=true…)
mainpage / my_page 通过 @StorageLink 自动呈现登录态
```

### 5.3 退出
```
my_page 退出按钮 → AuthService.logout() → 现有 router.replaceUrl(mainpage)
```

## 6. 错误处理

| 情况 | 判定 | UI 提示 |
|---|---|---|
| 账号为空 | 预校验 | 请输入账号 |
| 密码 < 6 位 | 预校验 | 密码不少于6位 |
| 网络异常/超时 | http 抛错或 responseCode ≠ 200 | 网络异常，请稍后重试 |
| 后端 success:false | `success === false` | 显示后端 `message` |
| 数据解析异常 | JSON parse 失败 / data 为空 | 登录失败，请重试 |

实现要点：http 调用包在 try/catch；检查 `resp.responseCode`；JSON 解析单独 try/catch；finally 中 `client.destroy()`。

## 7. 受影响文件

1. **新增** `services/authservice.ets` —— 认证服务。
2. `entry/src/main/module.json5` —— 放开 `ohos.permission.INTERNET`（当前被注释）+ 处理明文 http（见第 9 节风险）。
3. `otherpages/login_page.ets` —— `doLogin()` 改调 `AuthService.login()`；删除 `admin/123456` 硬编码（行 322-326）；保留 `validate()` 与协议勾选。
4. `components/my_page.ets` —— 新增 `@StorageLink('username')`、`@StorageLink('membershipLevel')`；登录态昵称显示 `username || name`；昵称旁加会员徽章（`NORMAL → 普通会员`，未知等级显示原值）；退出按钮调 `AuthService.logout()`。
5. `entryability/EntryAbility.ets` —— 注入 context + 调 `AuthService.restore()`。

## 8. 测试

### 8.1 单元测试（hypium）
- `parseLoginResponse()`：用成功、失败、字段缺失三类样本 JSON 断言映射正确。
- `validate()` 规则：账号空、密码 < 6 的分支。
- http 在 hypium 难以 mock，解析与校验是主要可测部分。

### 8.2 设备手工验收（真正验收标准）
1. `weixing / Test@123456` 登录成功 → 「我的」显示昵称 "weixing" + 「普通会员」徽章。
2. 错误密码 → 显示后端 `message`（username or password is incorrect）。
3. 空提交 → 本地校验提示（请输入账号 / 密码不少于6位）。
4. 杀进程重启 App → 仍为登录态（restore 生效）。
5. 退出登录 → 回到未登录态；再重启 → 未登录。
6. 断网登录 → 显示「网络异常，请稍后重试」。

## 9. 风险与待验证

**头号风险：明文 HTTP 访问**
- 登录接口为 `http://`（明文）。`module.json5` 中 `ohos.permission.INTERNET` 当前被整段注释，必须放开。
- 现有 `avplayermanager` 下载音乐时主动把 `http → https` 升级（行 350-352、412-414），暗示明文流量可能受限。
- 实现阶段需优先验证：放开 INTERNET 权限后，`@ohos.net.http` 能否直接请求 `http://47.119.121.254:8080`。如被系统拦截，需配置明文放行；若系统层面无法放行该 IP，则需后端提供 https 或经代理——这是唯一可能动摇本方案的点，需在实现首步确认。

## 10. 不在范围内

- 启动时调后端校验 token 有效性（信任本地 token）。
- 用 membershipLevel/permissions 做功能门禁。
- 头像/性别/年龄等资料的后端同步（保持本地）。
- 注册、忘记密码、第三方登录。
