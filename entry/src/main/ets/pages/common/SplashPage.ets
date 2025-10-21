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
    // 这里后续会跳转到项目主页面
    // router.pushUrl({ url: 'pages/project/ProjectListPage' })
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

      // 跳转提示 (可选)
      if (this.navigateToMain) {
        Text('点击进入应用')
          .fontSize(14)
          .fontColor('#007DFF')
          .margin({ bottom: 80 })
          .onClick(() => {
            // 跳转逻辑
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}