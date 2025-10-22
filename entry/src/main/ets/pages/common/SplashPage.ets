import router from '@ohos.router'

/**
 * 启动页面
 * EngineeringCamera 应用启动时的欢迎页面
 * 提供专业的工程应用启动体验
 */
@Entry
@Component
struct SplashPage {
  @State private loadingProgress: number = 0
  @State private appVersion: string = 'v1.0.1'
  @State private appDescription: string = '工程专业相机'
  @State private navigateToMain: boolean = false

  aboutToAppear(): void {
    // 设置应用版本信息
    this.setAppInfo()

    // 开始初始化
    this.initializeApp()
  }

  /**
   * 设置应用信息
   */
  private setAppInfo(): void {
    // 从配置文件读取版本信息
    this.appVersion = 'v1.0.1'
    this.appDescription = '工程专业相机'
  }

  /**
   * 初始化应用
   */
  private async initializeApp(): Promise<void> {
    try {
      // 模拟应用初始化过程
      await this.performInitialization()

      // 等待用户看到启动动画完成
      await this.waitAnimationComplete()

      // 跳转到主页面
      this.navigateToMainPage()
    } catch (error) {
      console.error('SplashPage initialization failed:', error)
      // 即使出错也要跳转到主页面
      this.navigateToMainPage()
    }
  }

  /**
   * 执行应用初始化
   */
  private async performInitialization(): Promise<void> {
    // 模拟各个模块的初始化
    const delays: number[] = [300, 500, 400, 200, 100]

    for (let i = 0; i < delays.length; i++) {
      await new Promise<void>((resolve: () => void) => {
        setTimeout(() => {
          this.loadingProgress = Math.round(((i + 1) / delays.length) * 100)
          resolve()
        }, delays[i])
      })
    }
  }

  /**
   * 等待动画完成
   */
  private async waitAnimationComplete(): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve()
      }, 800)
    })
  }

  /**
   * 跳转到主页面
   */
  private navigateToMainPage(): void {
    this.navigateToMain = true
    setTimeout(() => {
      router.replaceUrl({
        url: 'pages/MainPage',
        params: {
          fromSplash: true
        }
      })
    }, 300)
  }

  build() {
    Stack() {
      // 背景层
      Column() {
        // 应用Logo区域
        Column() {
          // Logo图标
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