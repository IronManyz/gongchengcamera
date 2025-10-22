import router from '@ohos.router'

/**
 * 启动页面
 * 应用启动时的欢迎页面
 */
@Entry
@Component
struct SplashPage {
  @State private loadingProgress: number = 0
  @State private navigateToMain: boolean = false

  aboutToAppear() {
    this.initializeApp()
  }

  /**
   * 初始化应用
   */
  private async initializeApp() {
    try {
      // 模拟加载过程
      await this.simulateLoading()

      // 等待额外1秒让用户看到加载完成
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve()
        }, 1000)
      })

      // 跳转到主页面
      this.navigateToMainPage()
    } catch (error) {
      console.error('SplashPage initialization failed:', error)
      // 即使出错也要跳转到主页面
      this.navigateToMainPage()
    }
  }

  /**
   * 模拟应用加载过程
   */
  private async simulateLoading(): Promise<void> {
    return new Promise((resolve) => {
      const timer = setInterval(() => {
        this.loadingProgress += 20
        if (this.loadingProgress >= 100) {
          clearInterval(timer)
          resolve()
        }
      }, 300)
    })
  }

  /**
   * 跳转到主页面
   */
  private navigateToMainPage() {
    this.navigateToMain = true
    console.log('Attempting to navigate to project list page...')

    // 使用replaceUrl跳转，避免用户返回到启动页
    router.replaceUrl({
      url: 'pages/TestPage',
      params: {}
    }).then(() => {
      console.log('Navigation to TestPage successful')
    }).catch((error: Error) => {
      console.error('Navigation to TestPage failed:', error)
      // 如果跳转失败，尝试跳转到MainPage
      router.replaceUrl({
        url: 'pages/MainPage',
        params: {}
      }).then(() => {
        console.log('Navigation to MainPage successful')
      }).catch((mainPageError: Error) => {
        console.error('Navigation to MainPage also failed:', mainPageError)
        // 最后的备选方案，跳转到Index页面
        router.replaceUrl({
          url: 'pages/Index',
          params: {}
        }).then(() => {
          console.log('Navigation to Index page successful')
        }).catch((indexError: Error) => {
          console.error('All navigation failed:', indexError)
        })
      })
    })
  }

  build() {
    Stack() {
      // 背景层
      Column() {
        // 应用Logo区域
        Column() {
          // Logo图标 (后续替换为实际Logo)
          Image($r('app.media.layered_image'))
            .width(120)
            .height(120)
            .margin({ bottom: 24 })

          // 应用名称
          Text('工程相机')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 12 })

          // 应用描述
          Text('专业的工程拍摄管理工具')
            .fontSize(16)
            .fontColor('#666666')
        }
        .margin({ bottom: 80 })

        Blank()

        // 加载进度条
        Column() {
          Progress({
            value: this.loadingProgress,
            total: 100,
            type: ProgressType.Linear
          })
            .width(200)
            .height(4)
            .color('#007DFF')
            .backgroundColor('#E5E5E5')

          Text(`${this.loadingProgress}%`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
        }

        // 版本信息
        Text('v1.0.0')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 40, bottom: 40 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FFFFFF')

      // 跳转提示 - 始终显示
      Text(this.navigateToMain ? '点击进入应用' : '加载中，请稍候...')
        .fontSize(14)
        .fontColor('#007DFF')
        .margin({ bottom: 80 })
        .opacity(this.navigateToMain ? 1.0 : 0.6)
        .onClick(() => {
          if (this.navigateToMain) {
            console.log('Manual navigation triggered')
            this.navigateToMainPage()
          }
        })
    }
    .width('100%')
    .height('100%')
  }
}