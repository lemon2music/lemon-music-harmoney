# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概述

MyAppmusic 是一款使用 ArkTS 和 ArkUI 构建的 HarmonyOS Next 音乐播放应用。它提供完整的音乐播放体验，包括用户认证、智能推荐和多源音频支持。

**Bundle ID：** `com.wuzheng.mymusic`  
**目标 SDK：** HarmonyOS 5.0.0 (API 12)  
**开发语言：** ArkTS

## 常用开发命令

### 构建应用
```bash
# 构建 HAP 包（命令行）
hvigorw assembleHap

# 通过 DevEco Studio 构建
# Build > Build Hap(s)/App(s) > Build Hap(s)
```

### 测试
```bash
# 运行单元测试
hvigorw test

# 运行特定测试
# 使用 DevEco Studio 测试运行器
```

### 安装
```bash
# 安装到设备/模拟器
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# 卸载
hdc uninstall com.wuzheng.mymusic
```

### 开发工作流
```bash
# 安装依赖（如需要）
npm install

# 清理构建
hvigorw clean

# 开发构建（更快，优化较少）
hvigorw assembleHap --mode debug
```

## 架构概览

### 核心架构模式

**面向服务的架构**
- `services/avplayermanager.ets` - 管理 AVPlayer 生命周期的中央音频播放服务
- 单一职责：所有音频操作都通过此服务进行
- 使用事件总线（`emitter`）在组件间同步状态

**事件驱动的状态管理**
- 通过 `@kit.BasicServicesKit` emitter 更新播放状态
- 事件：`play_state_update` 携带当前歌曲信息、播放状态、进度
- 组件订阅事件以保持与播放器状态同步

**导航架构**
- 入口点：`pages/Index.ets` → `pages/start.ets` → `pages/mainpage.ets`
- `mainpage.ets` 使用 Tab 导航，包含 4 个主要部分
- 路由配置：`resources/base/profile/main_pages.json` 和 `route_map.json`

### 目录结构

```
entry/src/main/ets/
├── services/
│   └── avplayermanager.ets      # 核心音频播放服务
├── components/
│   ├── zhu_page.ets             # 主页组件
│   ├── my_page.ets              # 用户个人页面
│   ├── pinglun.ets              # 评论页面
│   └── playfind_page.ets        # 发现页面
├── pages/
│   ├── Index.ets                # 导航入口点
│   ├── start.ets                # 启动屏幕
│   ├── mainpage.ets             # 主标签容器
│   └── Playnow.ets              # 功能完整的播放器页面
├── otherpages/
│   ├── login_page.ets           # 用户认证
│   ├── seek_page.ets            # 搜索功能
│   ├── song_list.ets            # 歌曲列表显示
│   └── [various settings pages]  # 用户个人设置
├── data/
│   ├── music.ets                # 歌曲数据模型和播放列表
│   └── [other data models]       # UI 数据结构
└── entryability/
    └── EntryAbility.ets         # 应用生命周期和上下文设置
```

### 关键组件及其职责

**avplayermanager.ets**（核心服务）
- 管理 `media.AVPlayer` 生命周期（创建、准备、播放、暂停、停止、重置）
- 处理三种播放模式：`auto`（顺序播放）、`repeat`（单曲循环）、`random`（随机播放）
- 支持三种音频源：
  1. Rawfile 资源：`rawfile:filename.mp3`
  2. 网络 URL：播放前自动下载到本地存储
  3. 本地文件：直接从文件系统播放
- 发出 `play_state_update` 事件以同步 UI
- 持久化状态：`playindex`、`isplay`、`playmodel`、`duration`、`time`

**EntryAbility.ets**（应用入口）
- 为 AVPlayer 设置上下文（cacheDir、filesDir、resourceManager）
- 应用启动时初始化 avplayermanager
- 处理通知点击，导航到播放器页面

**Playnow.ets**（播放器页面）
- 功能完整的播放器 UI，包含进度滑块和播放控制
- 订阅 `play_state_update` 事件以实现实时同步
- 发布音乐播放通知
- 处理搜索操作和曲目切换

**mainpage.ets**（主导航）
- 基于 Tab 的导航（主页、发现、评论、我的）
- 通过 `PersistentStorage.persistProp('isLogin')` 管理登录状态
- 登录成功后自动导航到"我的"标签页

### 数据流

**播放流程**
1. 用户选择歌曲 → 组件调用 `avplayerClass.playSongByIndex()`
2. AVPlayerManager 确定源类型（rawfile/网络/本地）
3. 网络源：下载到 `filesDir/music/`，然后通过 `file://` URL 播放
4. Rawfile 源：使用资源管理器的文件描述符
5. AVPlayer 发出状态/时间更新 → 管理器通过 emitter 广播
6. 所有订阅的组件同时更新 UI

**用户认证流程**
1. 登录页面验证输入 → 在 PersistentStorage 中设置 `isLogin`
2. 设置 `selectMineAfterLogin` 标志
3. 返回 mainpage → 标志触发导航到"我的"标签页
4. 个人页面根据 `isLogin` 状态显示不同 UI

### 重要实现细节

**上下文依赖**
- 必须在 `EntryAbility.onWindowStageCreate()` 中调用 `avplayerClass.setContext()`
- 用于：rawfile 访问、文件下载、持久化存储
- 切勿在上下文初始化前调用 AVPlayer 方法

**事件订阅清理**
- 始终在组件生命周期中成对使用 `emitter.on()` 和 `emitter.off()`
- 使用 `aboutToAppear()` 订阅，`aboutToDisappear()` 取消订阅
- 清理失败会导致内存泄漏和幽灵更新

**状态同步**
- 优先使用事件驱动更新，而非直接状态访问
- 组件应订阅 `play_state_update`，而非轮询 `avplayerClass` 属性
- 这确保所有页面（迷你播放器、完整播放器、主页）的 UI 一致性

**Rawfile 播放**
- 格式：歌曲数据中的 `url: "rawfile:filename.mp3"`
- AVPlayerManager 提取文件名并调用 `getRawFileDescriptor()`
- 对于捆绑资源最可靠（无网络延迟，无存储顾虑）

**网络 URL 播放**
- URL 自动下载到 `{filesDir}/music/song_{id}.mp3`
- 后续播放使用缓存文件（不重新下载）
- 基于哈希的命名防止重复下载
- 如下载失败，检查存储权限

### 测试和调试

**测试框架**
- 单元测试：`@ohos/hypium` + `@ohos/hamock`
- 测试位置：`entry/src/test/`（单元测试）、`entry/src/ohosTest/`（集成测试）

**调试日志**
- 使用 `console.log()` / `console.error()` 进行开发日志记录
- 检查 DevEco Studio 控制台输出以查看 AVPlayer 状态转换
- 常见事件：`stateChange`、`timeUpdate`、`durationUpdate`、`error`

**常见问题**
- "播放器未初始化"：在任何播放操作前调用 `avplayerClass.init()`
- "未设置上下文"：确保在 EntryAbility 中调用了 `setContext()`
- "状态不同步"：检查 `aboutToDisappear()` 中的事件订阅清理
- "Rawfile 播放失败"：验证文件名格式和资源中是否存在文件

## 配置文件

**模块配置**（`entry/src/main/module.json5`）
- 声明权限：`ohos.permission.INTERNET`、`ohos.permission.SUBSCRIBE_NOTIFICATION`
- 定义 abilities 和入口点
- 配置支持的设备类型（手机、平板、2in1）

**构建配置**（`build-profile.json5`）
- 两个产品：`default`（HarmonyOS）和 `android`（OpenHarmony）
- 发布版本的签名配置
- 构建模式：`debug` 和 `release`

**资源配置**
- `resources/base/element/string.json` - 文本资源
- `resources/base/element/color.json` - 颜色主题
- `resources/rawfile/*.mp3` - 捆绑的音频文件
- `resources/base/media/*` - 图像和图标

## 扩展点

**添加新的音乐源**
1. 在 `avplayermanager.ets` 中扩展 `playFromLocalOrDownload()` 或添加新方法
2. 更新 `playSongByIndex()` 以检测并路由到新源
3. 确保适当的文件清理和错误处理

**添加新页面**
1. 在 `pages/` 或 `otherpages/` 中创建页面文件
2. 将路由添加到 `resources/base/profile/main_pages.json`
3. 使用 `router.pushUrl()` 或 Navigation 路径栈进行导航

**自定义播放模式**
1. 在 `data/music.ets` 中修改 `playmodel` 类型
2. 在 `avplayermanager.ets` 中更新 `next()` 方法以处理新模式
3. 在播放器页面添加 UI 控件以选择模式
