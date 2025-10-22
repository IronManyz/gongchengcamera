/**
 * 应用主页面
 * 工程相机应用主界面
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
      Text('专业的工程拍摄管理工具')
        .fontSize(18)
        .fontColor('#7F8C8D')
        .margin({ bottom: 40 })

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
            // 跳转到简化版项目列表页面
            router.replaceUrl({
              url: 'pages/project/SimpleProjectListPage',
              params: {}
            }).catch((error: Error) => {
              console.error('跳转到项目列表失败:', error)
            })
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
            // TODO: 跳转到相机页面
            // router.replaceUrl({ url: 'pages/camera/CameraPage' })
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
            // TODO: 跳转到相册页面
            // router.replaceUrl({ url: 'pages/gallery/GalleryPage' })
          })

        Button('照片编辑')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#9B59B6')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('照片编辑按钮被点击')
            // TODO: 跳转到编辑页面
            // router.replaceUrl({ url: 'pages/editor/PhotoEditorPage' })
          })

        Button('应用设置')
          .width('85%')
          .height(52)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#34495E')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.clickCount++
            console.log('应用设置按钮被点击')
            // TODO: 跳转到设置页面
            // router.replaceUrl({ url: 'pages/settings/SettingsPage' })
          })

        Row({ space: 12 }) {
          Button('测试页面')
            .width('42%')
            .height(48)
            .fontSize(16)
            .backgroundColor('#95A5A6')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.clickCount++
              console.log('测试页面按钮被点击')
              router.replaceUrl({
                url: 'pages/TestPage',
                params: {}
              }).catch((error: Error) => {
                console.error('跳转到测试页面失败:', error)
              })
            })

          Button('返回启动页')
            .width('42%')
            .height(48)
            .fontSize(16)
            .backgroundColor('#E74C3C')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.clickCount++
              console.log('返回启动页按钮被点击')
              router.back()
            })
        }
        .width('85%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Blank()

      // 版本信息
      Column() {
        Text('Engineering Camera v1.0.0')
          .fontSize(14)
          .fontColor('#95A5A6')
          .margin({ bottom: 8 })

        Text('专业的工程拍摄与管理解决方案')
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