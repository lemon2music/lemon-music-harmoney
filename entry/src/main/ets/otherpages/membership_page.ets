/*
 * 会员中心页面：查询 IAP 自动订阅商品并展示
 */
import { router } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'

// 商品信息本地展示模型
interface SubscriptionProductDisplay {
  productId: string
  productName: string
  productDesc: string
  price: string
  originalPrice: string
  subscriptionPeriod: string
  subProductType: iap.ProductType
}

@Entry
@Component
struct MembershipPage {
  @State productList: SubscriptionProductDisplay[] = []
  @State loading: boolean = true
  @State errorMsg: string = ''
  @StorageLink('membershipLevel') membershipLevel: string = ''

  aboutToAppear() {
    this.querySubscriptionProducts()
  }

  // 查询 IAP 自动续期订阅商品
  private async querySubscriptionProducts() {
    this.loading = true
    this.errorMsg = ''
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      iap.isSandboxActivated(context).then(state => {
        console.info('IAP state is:', state)
      }).catch((err: BusinessError) => {
        console.error('IAP queryProducts failed:', err.code, err.message)
        this.errorMsg = `查询沙盒失败: ${err.message || '请检查网络或IAP配置'}`
      })
      const queryParam: iap.QueryProductsParameter = {
        productType: iap.ProductType.AUTORENEWABLE,
        productIds: ['vip_normal_month','vip_normal_quarter','vip_normal_year']  // 空数组查询所有已配置的自动续期商品
      }
      const result: iap.Product[] = await iap.queryProducts(context, queryParam)
      if (result && result.length > 0) {
        this.productList = result.map((item: iap.Product) => {
          return this.toDisplayProduct(item)
        })
      } else {
        this.errorMsg = '暂无可用的订阅商品'
      }
    } catch (err) {
      const e = err as BusinessError
      console.error('IAP queryProducts failed:', e.code, e.message)
      this.errorMsg = `查询失败: ${e.message || '请检查网络或IAP配置'}`
    } finally {
      this.loading = false
    }
  }

  // 将 IAP Product 转为展示模型
  private toDisplayProduct(product: iap.Product): SubscriptionProductDisplay {
    const priceVal = product.localPrice ?? '0'
    const originalPriceVal: string = product.originalLocalPrice ?? product.localPrice ?? '0'
    return {
      productId: product.id ?? '',
      productName: product.name ?? product.id ?? '',
      productDesc: product.description ?? '',
      price: typeof priceVal === 'number' ? `¥${(priceVal / 100).toFixed(2)}` : String(priceVal),
      originalPrice: typeof originalPriceVal === 'number' ? `¥${(originalPriceVal / 100).toFixed(2)}` : String(originalPriceVal),
      subscriptionPeriod: this.formatSubPeriod(product.type, product.subscriptionInfo),
      subProductType: product.type ?? iap.ProductType.AUTORENEWABLE
    }
  }

  // 格式化订阅周期描述
  private formatSubPeriod(subType?: iap.ProductType, subscriptionInfo?: iap.SubscriptionInfo): string {
    if (subscriptionInfo) {
      const count = subscriptionInfo.periodCount ?? 1;
      const unit = subscriptionInfo.periodUnit;

      // 鸿蒙 IAP periodUnit 枚举值映射：0-天, 1-周, 2-月, 3-年
      const unitMap: Record<number, string> = {
        0: '天',
        1: '周',
        2: '月',
        3: '年'
      };

      const unitStr = unitMap[unit] ?? '月';

      // count 为 1 时展示 "每月"/"每年"，大于 1 时展示 "3月"/"2年"
      return count === 1 ? `每${unitStr}` : `${count}${unitStr}`;
    }

    return '自动续期';
  }

  // 购买订阅商品
  private async buySubscription(productId: string) {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const purchaseParam: iap.PurchaseParameter = {
        productId: productId,
        productType: iap.ProductType.AUTORENEWABLE
      }
      const purchaseResult = await iap.createPurchase(context, purchaseParam)
      console.info('IAP purchase success:', JSON.stringify(purchaseResult))
      // 购买成功后更新会员等级
      this.membershipLevel = 'VIP'
      AppStorage.setOrCreate('membershipLevel', 'VIP')
    } catch (err) {
      const e = err as BusinessError
      console.error('IAP purchase failed:', e.code, e.message)
      // 用户取消购买不提示错误
      if (e.code !== 17720011) {
        this.errorMsg = `购买失败: ${e.message || '请稍后重试'}`
      }
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
              this.querySubscriptionProducts()
            })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Column({ space: 12 }) {
          ForEach(this.productList, (product: SubscriptionProductDisplay) => {
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
                Button(this.membershipLevel === 'VIP' ? '已开通' : '订阅')
                  .height(32)
                  .fontSize(13)
                  .backgroundColor(this.membershipLevel === 'VIP' ? '#e0e0e0' : '#ffab884c')
                  .fontColor(this.membershipLevel === 'VIP' ? '#999' : Color.Black)
                  .borderRadius(8)
                  .margin({ top: 6 })
                  .enabled(this.membershipLevel !== 'VIP')
                  .onClick(() => {
                    this.buySubscription(product.productId)
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
        }
        .margin({ top: 16 })
      }

      // 错误提示（购买失败）
      if (this.errorMsg && this.productList.length > 0) {
        Text(this.errorMsg)
          .fontSize(12)
          .fontColor('#ff4d4f')
          .margin({ top: 8 })
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 14, right: 14, top: 5, bottom: 5 })
    .backgroundColor('#f5f5f5')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}