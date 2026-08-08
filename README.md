# MyAppmusic - HarmonyOS Next入门 音乐播放应用

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.1-blue)
![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0.0(12)-green)
![License](https://img.shields.io/badge/license-MIT-orange)
![Status](https://img.shields.io/badge/status-stable-success)

一款功能完善的HarmonyOS Next音乐播放应用，采用ArkTS和ArkUI框架开发，提供流畅的音乐播放体验。

[功能特性](#功能特性) • [快速开始](#快速开始) • [技术栈](#技术栈) • [使用指南](#使用指南) • [深度链接](#深度链接) • [贡献指南](#贡献指南)

</div>

---

## 📋 目录

- [项目概述](#项目概述)
- [功能特性](#功能特性)
- [技术栈](#技术栈)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [使用指南](#使用指南)
- [配置说明](#配置说明)
- [深度链接](#深度链接)
- [常见问题](#常见问题)
- [贡献指南](#贡献指南)
- [许可证](#许可证)
- [联系方式](#联系方式)

---

## 🎯 项目概述

**MyAppmusic** 是一款基于HarmonyOS Next平台开发的音乐播放应用，采用模块化架构设计，集成了音频播放、用户管理、内容推荐等核心功能，为用户提供流畅、便捷的音乐体验。

### 项目信息

| 项目 | 详情 |
|------|------|
| **项目名称** | MyAppmusic |
| **Bundle ID** | com.wuzheng.mymusic |
| **当前版本** | 2.0.1 |
| **开发语言** | ArkTS |
| **目标平台** | HarmonyOS 5.0.0(12) |
| **支持设备** | Phone, Tablet, 2in1 |
| **作者** | silver-kite |

---

## ✨ 功能特性

### 🎵 核心播放功能

- **多数据源支持**: 支持本地rawfile、网络URL和本地文件播放
- **播放控制**: 播放/暂停、上一首/下一首、进度拖拽
- **播放状态同步**: 迷你播放器与主播放页面状态实时同步
- **状态持久化**: 应用重启后自动恢复上次播放状态

### 📱 用户界面

- **启动页**: 精美的启动页面，支持自动跳过和手动跳过
- **主页**: 轮播图、每日推荐、推荐歌单、其他应用入口
- **发现页**: 音乐搜索、分类浏览
- **评论页**: 评论列表、点赞互动
- **我的页面**: 个人信息管理、会员中心、设置、外联转换

### 👤 用户系统

- **登录注册**: 完整的用户登录注册流程
- **个人信息**: 头像、昵称、性别、年龄、生日、星座、地址
- **状态持久化**: 登录状态持久化存储
- **退出登录**: 安全的退出登录功能

### 💎 会员与订阅

- **会员中心**: 查看当前会员等级（普通/VIP），跳转会员中心页面
- **IAP自动订阅**: 集成华为IAP Kit，查询自动续期订阅商品并展示
- **订阅购买**: 支持一键购买VIP订阅，购买成功自动更新会员等级
- **会员标识**: 个人页展示VIP会员徽章

### 🎯 智能推荐

- **每日推荐**: 个性化音乐推荐
- **推荐歌单**: 多种主题歌单
- **分类浏览**: 按类型、歌手等维度分类

### 🔧 其他功能

- **搜索功能**: 音乐搜索、歌手搜索
- **会员订阅**: IAP自动续期订阅，VIP会员权益
- **外联转换**: 支持外链音乐转换
- **网页跳转**: 内置浏览器支持
- **剪贴板**: 长按复制链接功能
- **通知栏**: 音乐播放通知
- **深度链接**: 支持外部应用直接播放特定歌曲 (通过 `mymusic://play?song=<song_name>` URI scheme)

---

## 🛠 技术栈

### 核心框架

| 技术 | 版本 | 用途 |
|------|------|------|
| **HarmonyOS SDK** | 5.0.0(12) | 应用开发框架 |
| **ArkTS** | - | 开发语言 |
| **ArkUI** | - | UI框架 |
| **DevEco Studio** | - | 开发IDE |

### 主要依赖

```json5
{
  "dependencies": {},
  "devDependencies": {
    "@ohos/hypium": "1.0.19",
    "@ohos/hamock": "1.0.0"
  }
}
```

### 核心API

- **@kit.MediaKit**: AVPlayer音频播放
- **@kit.ArkUI**: UI组件、路由管理
- **@kit.IAPKit**: 应用内支付（IAP），自动续期订阅商品查询与购买
- **@kit.BasicServicesKit**: 事件总线、业务错误处理
- **@kit.NotificationKit**: 通知管理
- **@kit.AbilityKit**: 能力管理
- **@kit.PerformanceAnalysisKit**: 性能分析
- **@kit.ImageKit**: 图片处理
- **@kit.ArkData**: 数据持久化
- **@ohos.net.http**: 网络请求
- **@ohos.file.fs**: 文件系统
- **@ohos.router**: 路由导航
- **@ohos.pasteboard**: 剪贴板

---

## 💻 环境要求

### 开发环境

- **操作系统**: Windows 10/11, macOS
- **DevEco Studio**: 5.0.0 或更高版本
- **Node.js**: 16.x 或更高版本
- **HarmonyOS SDK**: API 12 或更高版本

### 运行设备

- **HarmonyOS 设备**: 5.0.0(12) 或更高版本
- **设备类型**: 手机、平板、2in1设备
- **存储空间**: 至少 100MB 可用空间
- **网络**: 需要网络连接（用于图片显示）

### 开发工具

- **Git**: 版本控制
- **Hvigor**: 构建工具
- **模拟器**: HarmonyOS模拟器（可选）

---

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/silver-kite-wu/HarmonyOS-MyAppmusic.git
cd MyAppmusic
```

### 2. 安装依赖

使用DevEco Studio打开项目，IDE会自动安装依赖。如需手动安装：

```bash
npm install
```

### 3. 配置签名

在 `build-profile.json5` 中配置签名信息：

```json5
{
  "signingConfigs": [
    {
      "name": "default",
      "type": "HarmonyOS",
      "material": {
        "storePassword": "your_store_password",
        "certpath": "path/to/your/cert.cer",
        "keyAlias": "your_key_alias",
        "keyPassword": "your_key_password",
        "profile": "path/to/your/profile.p7b",
        "signAlg": "SHA256withECDSA",
        "storeFile": "path/to/your/.p12"
      }
    }
  ]
}
```

### 4. 构建项目

在DevEco Studio中：

1. 选择目标设备（模拟器或真机）
2. 点击 `Build > Build Hap(s)/App(s) > Build Hap(s)`
3. 等待构建完成

### 5. 运行应用

```bash
# 使用命令行运行
hvigorw assembleHap

# 或在DevEco Studio中点击运行按钮
```

### 6. 安装到设备

```bash
# 使用hdc工具安装
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

---

## 📁 项目结构

```
MyAppmusic/
├── AppScope/                      # 应用全局配置
│   ├── resources/                 # 全局资源文件
│   │   ├── base/                  # 基础资源
│   │   │   ├── element/           # 元素资源
│   │   │   └── media/             # 媒体资源
│   └── app.json5                  # 应用配置
│
├── entry/                         # 主模块
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/               # ArkTS源码
│   │   │   │   ├── Uitl/          # 工具类
│   │   │   │   │   └── preferences.ets    
│   │   │   │   ├── components/    # 组件
│   │   │   │   │   ├── my_page.ets        # 我的页面
│   │   │   │   │   ├── pinglun.ets        # 评论页面
│   │   │   │   │   ├── pinglun_coms.ets   # 评论组件
│   │   │   │   │   ├── playfind_page.ets  # 发现页面
│   │   │   │   │   └── zhu_page.ets       # 主页组件
│   │   │   │   ├── data/          # 数据模型
│   │   │   │   │   ├── address_data.ets   # 地址数据
│   │   │   │   │   ├── maindailytype.ets  # 每日推荐数据
│   │   │   │   │   ├── maintabdata.ets    # 主页标签数据
│   │   │   │   │   ├── music.ets          # 音乐数据
│   │   │   │   │   ├── othersoft.ets      # 其他软件数据
│   │   │   │   │   ├── pinglundata.ets    # 评论数据
│   │   │   │   │   ├── recommenddata.ets  # 推荐数据
│   │   │   │   │   └── swiperdata.ets     # 轮播图数据
│   │   │   │   ├── entryability/  # 应用入口
│   │   │   │   │   └── EntryAbility.ets   # 主Ability
│   │   │   │   ├── entrybackupability/    # 备份Ability
│   │   │   │   │   └── EntryBackupAbility.ets
│   │   │   │   ├── otherpages/    # 其他页面
│   │   │   │   │   ├── Mywailian.ets      # 外联转换
│   │   │   │   │   ├── address_page.ets   # 地址页面
│   │   │   │   │   ├── age_page.ets       # 年龄页面
│   │   │   │   │   ├── birthday_page.ets  # 生日页面
│   │   │   │   │   ├── login_page.ets     # 登录页面
│   │   │   │   │   ├── membership_page.ets # 会员中心（IAP订阅）
│   │   │   │   │   ├── my_redirect.ets    # 重定向页面
│   │   │   │   │   ├── myshezhi.ets       # 设置页面
│   │   │   │   │   ├── name_page.ets      # 姓名页面
│   │   │   │   │   ├── num_page.ets       # 手机号页面
│   │   │   │   │   ├── seek_page.ets      # 搜索页面
│   │   │   │   │   ├── sex_page.ets       # 性别页面
│   │   │   │   │   ├── song_list.ets      # 歌曲列表
│   │   │   │   │   ├── touxiang_page.ets  # 头像页面
│   │   │   │   │   └── web_page.ets       # 网页页面
│   │   │   │   ├── pages/         # 主页面
│   │   │   │   │   ├── Index.ets          # 入口页面
│   │   │   │   │   ├── Playnow.ets        # 播放页面
│   │   │   │   │   ├── mainpage.ets       # 主页面
│   │   │   │   │   └── start.ets          # 启动页
│   │   │   │   └── services/       # 服务层
│   │   │   │       ├── authModels.ets      # 认证数据模型
│   │   │   │       ├── authservice.ets     # 认证服务（登录/登出/会话）
│   │   │   │       ├── avplayermanager.ets # 播放器管理
│   │   │   │       └── deeplinkHandler.ets # 深度链接处理
│   │   │   ├── resources/          # 资源文件
│   │   │   │   ├── base/           # 基础资源
│   │   │   │   │   ├── element/    # 元素资源
│   │   │   │   │   │   ├── color.json     # 颜色配置
│   │   │   │   │   │   └── string.json    # 字符串资源
│   │   │   │   │   ├── media/      # 媒体资源
│   │   │   │   │   │   ├── *.svg   # 图标资源
│   │   │   │   │   │   ├── *.jpg   # 图片资源
│   │   │   │   │   │   └── *.png   # 图片资源
│   │   │   │   │   └── profile/    # 配置文件
│   │   │   │   │       ├── backup_config.json
│   │   │   │   │       ├── main_pages.json
│   │   │   │   │       └── route_map.json
│   │   │   │   ├── en_US/          # 英文资源
│   │   │   │   ├── zh_CN/          # 中文资源
│   │   │   │   └── rawfile/        # 原始文件
│   │   │   │       └── *.mp3        # 音乐文件
│   │   │   └── module.json5        # 模块配置
│   │   ├── mock/                   # Mock数据
│   │   ├── ohosTest/               # 测试代码
│   │   └── test/                   # 单元测试
│   ├── build-profile.json5         # 构建配置
│   ├── hvigorfile.ts               # 构建脚本
│   ├── obfuscation-rules.txt       # 混淆规则
│   └── oh-package.json5            # 依赖配置
│
├── hvigor/                         # Hvigor配置
│   └── hvigor-config.json5
│
├── .gitignore                      # Git忽略文件
├── build-profile.json5             # 全局构建配置
├── code-linter.json5               # 代码检查配置
├── hvigorfile.ts                   # 全局构建脚本
├── oh-package-lock.json5           # 依赖锁定文件
└── oh-package.json5                # 全局依赖配置
```

---

## 📖 使用指南

### 基本操作

#### 1. 启动应用

首次启动应用会显示启动页，3秒后自动跳转到主页面，也可以点击"跳过"按钮立即进入。

#### 2. 播放音乐

- **选择歌曲**: 在主页的推荐列表中点击歌曲
- **播放控制**: 使用播放/暂停、上一首/下一首按钮
- **进度控制**: 拖动进度条调整播放进度

#### 3. 迷你播放器

底部悬浮的迷你播放器显示当前播放歌曲信息，点击可进入完整播放页面。

#### 4. 用户登录

1. 点击"我的"标签页
2. 点击"去登录"按钮
3. 填写登录信息并提交
4. 登录成功后可查看和管理个人信息

#### 5. 搜索音乐

1. 点击主页顶部的搜索框
2. 输入歌曲名称或歌手名
3. 查看搜索结果并播放

### 高级功能

#### 播放模式切换

```typescript
// 自动播放
avplayerClass.playmodel = 'auto';

// 单曲循环
avplayerClass.playmodel = 'repeat';

// 随机播放
avplayerClass.playmodel = 'random';
```

#### 会员中心与订阅

1. 进入"我的"页面
2. 点击"会员中心"查看当前会员等级
3. 选择订阅商品（月度/年度等）
4. 点击"订阅"按钮完成IAP购买
5. 购买成功后自动升级为VIP会员

#### 外联转换

1. 进入"我的"页面
2. 点击"外联转换"
3. 输入音乐外链
4. 点击转换并播放

#### 网页跳转

点击图标可直接跳转到网页。

---

## ⚙️ 配置说明

### 应用配置

在 `AppScope/app.json5` 中配置应用基本信息：

```json5
{
  "app": {
    "bundleName": "com.wuzheng.mymusic",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "2.0.1",
    "icon": "$media:startIcon",
    "label": "$string:app_name"
  }
}
```

### 模块配置

在 `entry/src/main/module.json5` 中配置模块信息：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": ["phone", "tablet", "2in1"],
    "pages": "$profile:main_pages",
    "abilities": [...],
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.SUBSCRIBE_NOTIFICATION" }
    ]
  }
}
```

### 路由配置

在 `entry/src/main/resources/base/profile/route_map.json` 中配置路由映射。

### 页面配置

在 `entry/src/main/resources/base/profile/main_pages.json` 中配置页面列表。

---

## 🔗 深度链接

Lemon Music 支持深度链接功能，允许外部应用、网页或二维码直接启动应用并播放指定的歌曲。

### URI Scheme 格式

```
mymusic://play?song=<song_name>
```

### 参数说明

- `song` (必需): 要播放的歌曲名称
  - 如果包含特殊字符，必须进行URL编码
  - 必须与应用内歌曲名称完全匹配（区分大小写）

### 使用示例

#### 从网页启动
```html
<a href="mymusic://play?song=起风了">播放 起风了</a>
```

#### 二维码生成
使用任意二维码生成器，将深度链接作为数据输入：
```
mymusic://play?song=起风了
```

#### 从其他应用
```typescript
// 从其他HarmonyOS应用启动
const want = {
  action: 'ohos.want.action.viewData',
  uri: 'mymusic://play?song=起风了'
};
```

### 可用歌曲列表

当前播放列表包含以下歌曲：
- 起风了
- 篝火旁
- 室内系的
- 在你的身边
- 春娇与志明
- 青丝
- 你从未离去
- 烟火里的尘埃
- 画离弦 (坐骑版)
- 偏爱
- 褪黑素
- 悬溺
- 唯一
- 大雪
- Catch My Breath
- 此生不换

### 行为说明

**成功播放流程：**
1. 应用启动或切换到前台
2. 在播放列表中搜索匹配的歌曲
3. 如果找到：播放该歌曲
4. 如果未找到：播放第一首歌曲
5. 导航到完整的播放器页面

**错误处理：**
- 无效的URI格式：显示错误提示，导航到主页面
- 歌曲未找到：静默播放第一首歌曲（不显示错误消息）
- 播放列表为空：显示错误提示，导航到主页面
- 导航失败：显示错误提示，停留在当前页面

### 完整文档

更多详细信息请参阅：
- 📖 [深度链接使用指南](docs/deeplink-usage-guide.md) - 完整的使用文档和集成示例

---

## ❓ 常见问题

### Q1: 应用无法播放音乐？

**A**: 请检查以下项目：
- 确保设备已连接网络
- 检查音乐URL是否有效
- 确认应用有网络权限
- 查看控制台日志获取详细错误信息

### Q2: 迷你播放器状态不同步？

**A**: 确保已正确订阅事件总线：

```typescript
emitter.on('play_state_update', (eventData) => {
  // 更新UI状态
});
```

### Q3: 应用启动后闪退？

**A**: 可能的原因：
- 签名配置不正确
- SDK版本不匹配
- 设备系统版本过低
- 检查日志获取具体错误信息

### Q4: 如何添加新的音乐？

**A**: 在 `entry/src/main/ets/data/music.ets` 中添加音乐数据：

```typescript
export const songlist: songtype[] = [
  {
    img: "图片URL",
    name: "歌曲名称",
    author: "歌手名称",
    url: "rawfile:文件名.mp3",
    id: 唯一ID
  },
  // 添加更多音乐...
];
```

### Q5: 如何修改主题颜色？

**A**: 在 `entry/src/main/resources/base/element/color.json` 中修改颜色配置。

### Q6: 应用需要哪些权限？

**A**: 应用需要以下权限：
- `ohos.permission.INTERNET`: 网络访问
- `ohos.permission.SUBSCRIBE_NOTIFICATION`: 通知权限

### Q7: 如何调试应用？

**A**: 使用DevEco Studio的调试功能：
1. 连接设备或启动模拟器
2. 设置断点
3. 点击调试按钮
4. 查看日志输出

### Q8: 如何配置IAP订阅商品？

**A**: 在华为开发者后台（AppGallery Connect）配置自动续期订阅商品：
1. 登录 [AppGallery Connect](https://developer.huawei.com/) 后台
2. 进入"应用内支付" > "商品管理"
3. 添加自动续期订阅商品（设置productId、名称、价格、订阅周期等）
4. 商品审核通过后，`iap.queryProducts()` 即可查询到
5. 如需指定商品ID，修改 `membership_page.ets` 中 `querySubscriptionProducts()` 的 productIds 参数

### Q8.1: IAP 购买流程是怎样的？需要哪些后端接口？

**A**: 客户端通过 `services/IapService.ets` 严格遵循官方标准流程，进入会员页时自动补单（处理掉单）。后端为 `music-back-service`（`IapController` / `MembershipController`）。

```
环境检测(isSandboxActivated)
  → 查询商品(GET /api/iap/products 取后端 id + iap.queryProducts 取实时价)
  → 查询购买状态(queryPurchases + GET /api/iap/entitlement，命中则禁用按钮，避免重复购买)
  → 服务器预下单(POST /api/iap/orders，返回 orderNo 作为 developerPayload)
  → 收银台(createPurchase，developerPayload=orderNo)
  → 上报验签发放权益(POST /api/iap/orders/report)
  → 端侧确认发货(finishPurchase)
```

**后端接口（已实现）：**

| 接口 | 入参 | 返回 |
|------|------|------|
| `GET /api/iap/products` | 凭 token | `[{ id, name, huaweiProductId, iapProductType, price, currency, subscriptionType, description }]` |
| `GET /api/iap/entitlement` | 凭 token | `{ vipActive, subscriptionExpireAt, ownedHuaweiProductIds }` |
| `POST /api/iap/orders` | `{ iapProductId }` | `{ orderNo, huaweiProductId, iapProductType, amount, currency }` |
| `POST /api/iap/orders/report` | `{ iapProductType, purchaseData }` | `{ fulfilled, orderId, message }` |

关键：`developerPayload` = 预下单返回的 `orderNo`，服务端凭它在 `/orders/report` 中对账发货；购买与补单共用此接口。验签发货已处理幂等与退款回收（`purchaseOrderRevocationReasonCode` 非空不发，已发放过的不重复发）。

---


### Q9: 如何打包发布？

**A**: 
1. 配置发布签名
2. 选择 `release` 构建模式
3. 执行 `Build > Build Hap(s)/App(s) > Build Hap(s)`
4. 在 `entry/build/default/outputs/default/` 目录找到生成的HAP文件

---

## 🤝 贡献指南

我们欢迎所有形式的贡献！以下是参与项目贡献的指南。

### 如何贡献

1. **Fork 项目**: 点击页面右上角的Fork按钮
2. **创建分支**: 为你的功能或修复创建一个新分支
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **提交更改**: 提交你的更改
   ```bash
   git commit -m 'Add some feature'
   ```
4. **推送分支**: 推送你的分支到远程仓库
   ```bash
   git push origin feature/your-feature-name
   ```
5. **创建Pull Request**: 在GitHub上创建Pull Request

### 代码规范

- 遵循ArkTS代码规范
- 使用有意义的变量和函数名
- 添加必要的注释
- 保持代码简洁清晰
- 遵循项目的代码风格

### 提交信息规范

使用清晰的提交信息格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型（type）：
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关

示例：
```
feat(player): 添加随机播放模式

实现了随机播放功能，用户可以在播放设置中切换到随机播放模式。

Closes #123
```

### 报告问题

如果发现bug或有功能建议，请在GitHub上创建Issue，包含：
- 问题描述
- 复现步骤
- 预期行为
- 实际行为
- 环境信息（设备型号、系统版本等）
- 截图或日志（如适用）

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

```
MIT License

Copyright (c) 2026 silver-kite

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

---

## 🙏 致谢

- **参考项目**: https://github.com/silver-kite-wu/HarmonyOS-MyAppmusic.git

---


<div align="center">

**如果这个项目对你有帮助，请给它一个 ⭐️ Star！**


</div>
