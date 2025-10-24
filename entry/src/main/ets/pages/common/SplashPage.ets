import router from '@ohos.router'

/**
 * 启动页面
 * EngineeringCamera 应用启动时的欢迎页面
 * 根据原型设��提供专业的工程应用启动体验
 */
@Entry
@Component
struct SplashPage {
  @State private loadingProgress: number = 0
  @State private appVersion: string = 'v1.0.0'
  @State private appDescription: string = '工程专业相机'
  @State private navigateToMain: boolean = false
  @State private loadingText: string = '正在初始化...'

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
    this.appVersion = 'v1.0.0'
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
    const loadingSteps: string[] = [
      '正在初始化数据库...',
      '正在加载配置文件...',
      '正在检查权限...',
      '正在启动服务...',
      '正在准备界面...'
    ]

    for (let i = 0; i < loadingSteps.length; i++) {
      await new Promise<void>((resolve: () => void) => {
        setTimeout(() => {
          this.loadingProgress = Math.round(((i + 1) / loadingSteps.length) * 100)
          this.loadingText = loadingSteps[i]
          resolve()
        }, 400)
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
      }).catch((error: Error) => {
        console.error('Navigation failed:', error)
        // 如果导航失败，尝试其他页面
        router.replaceUrl({
          url: 'pages/Index',
          params: {}
        })
      })
    }, 300)
  }

  build() {
    Stack() {
      // 背景层 - 使用渐变背景
      Column() {
        // 应用Logo区域
        Column() {
          // Logo图标 - 使用emoji代替不存在的资源
          Text('📸')
            .fontSize(80)
            .margin({ bottom: 24 })

          // 应用名称
          Text('工程拍记')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1890FF')
            .margin({ bottom: 8 })

          // 英文名称
          Text('Engineering Photo Record')
            .fontSize(18)
            .fontColor('#52C41A')
            .margin({ bottom: 16 })

          // 应用描述
          Text('专业 · 安全 · 高效')
            .fontSize(16)
            .fontColor('#666666')
        }
        .margin({ bottom: 80 })

        // 加载进度区域
        Column() {
          // 进度条
          Progress({
            value: this.loadingProgress,
            total: 100,
            type: ProgressType.Linear
          })
            .width(240)
            .height(6)
            .color('#1890FF')
            .backgroundColor('#E5E5E5')
            .borderRadius(3)

          // 加载文本
          Text(this.loadingText)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 12 })

          // 进度百分比
          Text(`${this.loadingProgress}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1890FF')
            .margin({ top: 8 })
        }

        Blank()

        // 版本信息
        Column() {
          Text(this.appVersion)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ bottom: 8 })

          Text('专业的工程拍摄管理工具')
            .fontSize(12)
            .fontColor('#BFBFBF')
        }
        .margin({ bottom: 60 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F5F5F5')

      // 跳转提示已取消，保持界面简洁
    }
    .width('100%')
    .height('100%')
  }
}
