/**
 * 应用主页面
 * 简单的主页面用于测试
 */

import router from '@ohos.router'

@Entry
@Component
struct MainPage {
  build() {
    Column() {
      // 标题
      Text('工程相机')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 40 })

      // 欢迎信息
      Text('欢迎使用工程相机应用')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 60 })

      // 功能按钮
      Column({ space: 20 }) {
        Button('项目管理')
          .width('80%')
          .height(48)
          .fontSize(16)
          .onClick(() => {
            console.log('项目管理')
          })

        Button('相机拍照')
          .width('80%')
          .height(48)
          .fontSize(16)
          .onClick(() => {
            console.log('相机拍照')
          })

        Button('相册浏览')
          .width('80%')
          .height(48)
          .fontSize(16)
          .onClick(() => {
            console.log('相册浏览')
          })

        Button('返回启动页')
          .width('80%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#FF6B6B')
          .onClick(() => {
            router.back()
          })
      }
      .width('100%')
      .padding(20)

      Blank()

      // 版本信息
      Text('版本: v1.0.0')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}