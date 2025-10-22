/**
 * 相册页��占位符
 * 临时页面，用于测试底部导航栏跳转功能
 */

import router from '@ohos.router'

@Entry
@Component
struct GalleryPlaceholderPage {
  build() {
    Column() {
      Text('📱 相册页面')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Text('此功能正在开发中...')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 40 })

      Button('返回主页')
        .fontSize(16)
        .backgroundColor('#1890FF')
        .onClick(() => {
          router.back()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}