/*
author:wuzheng
* time:2025/8/
* log:...
 */
//我的
import { router } from "@kit.ArkUI";
import { AuthService } from '../services/authservice'
AppStorage.setOrCreate('name','空维')
AppStorage.setOrCreate('sex','男')
AppStorage.setOrCreate('age',20)
AppStorage.setOrCreate('year','2006年1月1日')
AppStorage.setOrCreate('star','摩羯座')
AppStorage.setOrCreate('address','郑州市')
AppStorage.setOrCreate('num','16666666666')
@Component
export struct my_page {
  @StorageLink('touxiang') touxiang:string=''
  @StorageLink('name')name:string=''
  @StorageLink('sex')sex:string=''
  @StorageLink('age')age:number=NaN
  @StorageLink('year')year:string=''
  @StorageLink('star')star:string=''
  @StorageLink('address')address:string=''
  @StorageLink('isLogin') isLogin:boolean=false
  @StorageLink('selectMineAfterLogin') selectMineAfterLogin:boolean=false
  @StorageLink('username') username:string=''
  @StorageLink('membershipLevel') membershipLevel:string=''
  private membershipLabel(): string {
    switch (this.membershipLevel) {
      case 'NORMAL': return '普通会员'
      case 'VIP': return 'VIP会员'
      case '': return ''
      default: return this.membershipLevel
    }
  }
  build() {
    Column(){
      if (!this.isLogin) {
        // 未登录占位 UI
        Image($r('app.media.startIcon'))
          .width(120)
          .borderRadius(20)
          .margin({top:40,bottom:20})
        Text('未登录')
          .fontSize(22)
          .fontWeight(600)
          .fontColor('#ff4d4f')
        Text('登录后可查看个人信息与发布评论')
          .fontSize(14)
          .fontColor('#666')
          .margin({top:6,bottom:16})
        Button('去登录')
          .height(44)
          .backgroundColor('#ffab884c')
          .fontColor(Color.Black)
          .fontSize(16)
          .borderRadius(14)
          .onClick(()=>{
            router.pushUrl({ url: 'otherpages/login_page' })
          })
      } else {
      Image(this.touxiang)
        .width(200)
        .height(200)
        .borderRadius(100)
        .margin({top:20,bottom:20})
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
      Column(){
        Row(){
        Text('ID:4562786256')
          .fontSize(14)
          .fontColor('#333333')
        }
        .margin({bottom:3})
        Text(`${this.sex} | ${this.age}岁 | ${this.year} ${this.star} | ${this.address}`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .borderRadius(5)
      .width('100%')
      .backgroundColor('#f8f8f8')
      .padding(10)
      .margin({bottom:30})
      //会员中心
      Row(){
        Row({space:20}){
          Image($r('app.media.lv3'))
            .width(25)
            .fillColor('#FFD700')
          Text('会员中心')
            .fontColor('#333333')
            .fontSize(20)
            .fontWeight(400)
        }
        .margin({left:10,right:10})
        .layoutWeight(1)
        Image($r('app.media.xiayibu'))
          .fillColor('#888888')
          .width(25)
          .margin({ right:10 })
      }
      .width('100%')
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(()=>{
        router.pushUrl({
          url:'otherpages/membership_page'
        })
      })
      //外连转换
      Row(){
        Row({space:20}){
          Image($r('app.media.mp3zhuan'))
            .width(25)
            .fillColor('#ff098eae')
          Text('外联转换')
            .fontColor('#333333')
            .fontSize(20)
            .fontWeight(400)
        }
        .margin({left:10,right:10})
        .layoutWeight(1)
          Image($r('app.media.xiayibu'))
            .fillColor('#888888')
            .width(25)
            .margin({ right:10 })
            .onClick(()=>{
              router.pushUrl({
                url:'otherpages/Mywailian'
              })
            })
      }
      .width('100%')
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceBetween)
      //设置
      Row(){
        Row({space:20}){
          Image($r('app.media.shezhi'))
            .width(25)
          Text('设置')
            .fontColor('#333333')
            .fontSize(20)
            .fontWeight(400)
        }
        .layoutWeight(1)
        .margin({left:10,right:10})

        Image($r('app.media.xiayibu'))
          .fillColor('#888888')
          .width(25)
          .margin({ right:10 })
          .onClick(()=>{
            router.pushUrl({
              url:'otherpages/myshezhi'
            })
          })
      }
      .margin({top:10})
      .width('100%')
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceBetween)
      // 退出登录
      Row(){
        Row({space:20}){
          Image($r('app.media.loginout'))
            .width(25)
            .fillColor('#ff4d4f')
          Text('退出登录')
            .fontColor('#ff4d4f')
            .fontSize(20)
            .fontWeight(500)
        }
        .layoutWeight(1)
        .margin({left:10,right:10})

        Image($r('app.media.xiayibu'))
          .fillColor('#888888')
          .width(25)
          .margin({ right:10 })
          .onClick(()=>{
            // 清除后端会话与本地登录状态并返回主页面
            AuthService.logout().catch((e: Object) => console.error('logout failed', e))
            this.isLogin = false
            this.selectMineAfterLogin = false
            router.replaceUrl({ url: 'pages/mainpage' })
          })
      }
      .margin({top:10})
      .width('100%')
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
    .padding({left:10,right:10,top:5,bottom:5})
    .radialGradient({
      center:['90%','-10%'],
      radius:'150%',
      colors:[
        ['#ffab884c',0.2],
        [Color.Transparent,1]
      ]
    })
  }
}