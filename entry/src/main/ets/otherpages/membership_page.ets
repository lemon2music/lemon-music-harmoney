/*
 * 会员中心页面
 * 基于 IapService 实现完整标准流程：
 *   环境检测 → 查询商品(后端+实时价) → 查询购买状态(避免重复购买)
 *   → 预下单 → 收银台 → 验签发货 → 确认发货
 * 进入页面时执行补单（queryPurchases），处理掉单。
 */
import { router, promptAction } from '@kit.ArkUI'
import { BusinessError, emitter } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import iapService, { MembershipProduct, IapEnvironmentStatus } from '../services/IapService'
import AuthService from '../services/authservice'
import { EVENT_TOKEN_MISSING } from '../services/iapApiService'

@Entry
@Component
struct MembershipPage {
  @State productList: MembershipProduct[] = []
  @State loading: boolean = true
  @State purchasing: boolean = false
  @State errorMsg: string = ''
  @StorageLink('membershipLevel') membershipLevel: string = ''
  /** 环境不可用（如账号服务地非中国境内）时隐藏购买入口 */
  @State envAvailable: boolean = true

  aboutToAppear() {
    this.initAndLoad()
    // 监听 token 缺失事件
    try {
      emitter.on(EVENT_TOKEN_MISSING, this.handleTokenMissing)
    } catch (e) {
      console.error('Failed to register token missing listener:', e)
    }
  }

  aboutToDisappear() {
    // 取消监听 token 缺失事件
    try {
      emitter.off(EVENT_TOKEN_MISSING, this.handleTokenMissing)
    } catch (e) {
      console.error('Failed to unregister token missing listener:', e)
    }
  }

  /**
   * 处理 token 缺失事件：执行登出并引导用户重新登录
   */
  private handleTokenMissing = (event: emitter.EventData): void => {
    console.warn('MembershipPage: 收到 token 缺失事件，执行登出')
    this.performLogout()
  }

  /**
   * 执行登出操作
   */
  private async performLogout() {
    try {
      // 调用 AuthService 的登出方法
      await AuthService.logout()

      // 清除本地登录状态
      this.membershipLevel = ''

      // 显示提示信息
      promptAction.showToast({
        message: '登录信息已失效，请重新登录',
        duration: 2000
      })

      // 延迟后返回上一页或导航到登录页
      setTimeout(() => {
        router.back()
      }, 2000)
    } catch (e) {
      console.error('Logout failed:', e)
      promptAction.showToast({
        message: '登出失败，请手动重启应用',
        duration: 2000
      })
    }
  }

  // 初始化 IAP（环境检测 + 补单）并加载商品
  private async initAndLoad() {
    this.loading = true
    this.errorMsg = ''
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      await iapService.init(context)

      const env: IapEnvironmentStatus | null = iapService.getEnvironment()
      if (env && !env.isActivated) {
        this.envAvailable = false
        this.errorMsg = '当前环境不支持应用内支付'
        return
      }

      this.productList = await iapService.loadProducts()
      if (this.productList.length === 0) {
        this.errorMsg = '暂无可用的订阅商品'
      }
      
    } catch (err) {
      const e = err as BusinessError
      console.error('IAP init failed:', e.code, e.message)
      this.errorMsg = `初始化失败: ${e.message || '请检查网络或IAP配置'}`
    } finally {
      this.loading = false
    }
  }

  // 购买（走完整流程：预下单 → 收银台 → 验签发货 → 确认发货）
  private async buySubscription(product: MembershipProduct) {
    if (this.purchasing) {
      return
    }
    this.purchasing = true
    this.errorMsg = ''
    try {
      const result = await iapService.purchaseFlow(product)
      if (result.success) {
        if (result.membershipLevel) {
          this.membershipLevel = result.membershipLevel
        }
        promptAction.showToast({ message: result.message || '开通成功' })
        this.productList = await iapService.loadProducts()
      } else if (result.message) {
        this.errorMsg = result.message
      }
    } catch (err) {
      const e = err as BusinessError
      console.error('IAP purchase failed:', e.code, e.message)
      this.errorMsg = `购买失败: ${e.message || '请稍后重试'}`
    } finally {
      this.purchasing = false
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.back'))
          .width(20)
          .fillColor(Color.Black)
          .margin({ left: 10 })
          .onClick(() => {
            router.back()
          })
        Text('会员中心')
          .margin({ left: '28%' })
          .fontSize(24)
          .fontWeight(500)
          .layoutWeight(1)
      }
      .height(50)
      .width('100%')
      .backgroundColor(Color.White)

      // 会员状态卡片
      Column() {
        Row() {
          Text(this.membershipLevel === 'VIP' ? 'VIP会员' : '普通会员')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.membershipLevel === 'VIP' ? '#FFD700' : '#333')
        }
        .margin({ bottom: 8 })

        if (this.membershipLevel === 'VIP') {
          Text('您已开通VIP会员，畅享全部权益')
            .fontSize(14)
            .fontColor('#666')
        } else {
          Text('开通VIP会员，解锁高品质音乐与专属权益')
            .fontSize(14)
            .fontColor('#666')
        }
      }
      .width('100%')
      .padding(20)
      .margin({ top: 10 })
      .borderRadius(12)
      .backgroundColor(this.membershipLevel === 'VIP' ? '#FFF8E1' : '#fff3e6')
      .alignItems(HorizontalAlign.Center)

      // 订阅商品列表
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#ffab884c')
          Text('加载中…')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 12 })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else if (!this.envAvailable) {
        Column() {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#ff4d4f')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorMsg && this.productList.length === 0) {
        Column() {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#ff4d4f')
            .textAlign(TextAlign.Center)
          Button('重试')
            .height(36)
            .fontSize(14)
            .backgroundColor('#ffab884c')
            .fontColor(Color.Black)
            .borderRadius(10)
            .margin({ top: 12 })
            .onClick(() => {
              this.initAndLoad()
            })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.productList, (product: MembershipProduct) => {
              Row() {
                // 左侧商品信息
                Column() {
                  Text(product.productName)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  if (product.productDesc) {
                    Text(product.productDesc)
                      .fontSize(12)
                      .fontColor('#999')
                      .margin({ top: 4 })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  Text(product.subscriptionPeriod)
                    .fontSize(12)
                    .fontColor('#ffab884c')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 右侧价格与购买按钮
                Column() {
                  Text(product.price)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ffab884c')
                  if (product.originalPrice !== product.price) {
                    Text(`原价 ${product.originalPrice}`)
                      .fontSize(12)
                      .fontColor('#bbb')
                      .decoration({ type: TextDecorationType.LineThrough })
                  }
                  Button(this.buttonLabel(product))
                    .height(32)
                    .fontSize(13)
                    .backgroundColor(this.buttonColor(product))
                    .fontColor(product.owned ? '#999' : Color.Black)
                    .borderRadius(8)
                    .margin({ top: 6 })
                    .enabled(!product.owned && !this.purchasing)
                    .onClick(() => {
                      this.buySubscription(product)
                    })
                }
                .alignItems(HorizontalAlign.End)
                .width(100)
              }
              .width('100%')
              .padding(16)
              .borderRadius(12)
              .backgroundColor(Color.White)
              .shadow({ radius: 2, color: '#1a000000', offsetY: 1 })
            })

            // 错误提示（购买失败）
            if (this.errorMsg) {
              Text(this.errorMsg)
                .fontSize(12)
                .fontColor('#ff4d4f')
                .margin({ top: 8 })
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .margin({ top: 16 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 14, right: 14, top: 5, bottom: 5 })
    .backgroundColor('#f5f5f5')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // 按钮文案：生效中 → 「使用中」，已拥有 → 「已开通」
  private buttonLabel(product: MembershipProduct): string {
    if (product.active) {
      return '使用中'
    }
    if (product.owned) {
      return '已开通'
    }
    return this.purchasing ? '处理中…' : '订阅'
  }

  // 按钮颜色：已拥有权益置灰
  private buttonColor(product: MembershipProduct): ResourceColor {
    if (product.owned) {
      return '#e0e0e0'
    }
    return '#ffab884c'
  }
}
