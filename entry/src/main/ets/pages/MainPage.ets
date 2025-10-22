/**
 * 应用主页面
 * 简单的主页面用于测试
 */

import router from '@ohos.router'

@Entry
@Component
struct MainPage {
  @State private clickCount: number = 0

  build() {
    Column() {
      // 标题
      Text('工程相机')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2C3E50')
        .margin({ top: 80, bottom: 20 })

      // 欢迎信息
      Text('欢迎使用工程相机应用')
        .fontSize(18)
        .fontColor('#7F8C8D')
        .margin({ bottom: 40 })

      // 点击计数器显示
      Text(`点击次数: ${this.clickCount}`)
        .fontSize(14)
        .fontColor('#E74C3C')
        .margin({ bottom: 30 })

      // 功能按钮
      Column({ space: 16 }) {
        Button('项目管理')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#3498DB')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('项目管理按钮被点击')
          })

        Button('相机拍照')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#27AE60')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('相机拍照按钮被点击')
          })

        Button('相册浏览')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#F39C12')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('相册浏览按钮被点击')
          })

        Button('测试交互')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#9B59B6')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('测试交互按钮被点击')
          })

        Button('返回启动页')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#E74C3C')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('返回启动页按钮被点击')
            router.back()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Blank()

      // 版本信息
      Column() {
        Text('版本: v1.0.0')
          .fontSize(14)
          .fontColor('#95A5A6')
          .margin({ bottom: 8 })

        Text('点击任意按钮测试交互')
          .fontSize(12)
          .fontColor('#BDC3C7')
      }
      .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ECF0F1')
  }
}