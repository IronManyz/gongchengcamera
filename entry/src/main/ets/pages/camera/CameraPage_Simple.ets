/**
 * 简化相机页面
 * 根据原型设计实现的工程拍照界面
 */

import router from '@ohos.router'

@Entry
@ComponentV2
struct CameraPage_Simple {
  @Local private isCameraReady: boolean = false
  @Local private isLoading: boolean = true
  @Local private showPreview: boolean = false
  @Local private capturedImagePath: string = ''

  // 工点信息
  @Local private projectId: string = ''
  @Local private siteId: string = ''
  @Local private siteName: string = ''

  // 设置选项
  @Local private watermarkEnabled: boolean = true
  @Local private flashEnabled: boolean = false

  aboutToAppear(): void {
    this.loadRouteParams()
    this.initCamera()
  }

  /**
   * 加载路由参数
   */
  private loadRouteParams(): void {
    try {
      const params = router.getParams() as Record<string, Object>
      if (params) {
        this.projectId = (params.projectId as string) || ''
        this.siteId = (params.siteId as string) || ''
        this.siteName = (params.siteName as string) || ''
      }
    } catch (error) {
      console.error('Failed to load route params:', error)
    }
  }

  /**
   * 初始化相机
   */
  private async initCamera(): Promise<void> {
    // 模拟相机初始化
    setTimeout(() => {
      this.isCameraReady = true
      this.isLoading = false
      console.log('Camera initialized')
    }, 1000)
  }

  /**
   * 拍照
   */
  private takePhoto(): void {
    console.log('Taking photo...')
    // 模拟拍照过程
    setTimeout(() => {
      this.capturedImagePath = '/mock/path/photo_' + Date.now() + '.jpg'
      this.showPreview = true
      console.log('Photo captured:', this.capturedImagePath)
    }, 500)
  }

  /**
   * 返回上一页
   */
  private navigateBack(): void {
    router.back()
  }

  /**
   * 重新拍照
   */
  private retakePhoto(): void {
    this.showPreview = false
    this.capturedImagePath = ''
  }

  /**
   * 确认照片
   */
  private confirmPhoto(): void {
    // TODO: 保存照片信息到数据库，关联工点
    console.log('Photo confirmed and saved')
    this.navigateBack()
  }

  build() {
    Stack() {
      if (this.isLoading) {
        // 加载状态
        Column() {
          Text('📸')
            .fontSize(48)
            .fontColor('#C0C0C0')
            .margin({ bottom: 16 })

          Text('相机初始化中...')
            .fontSize(16)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#000000')

      } else if (this.showPreview) {
        // 预览状态
        this.buildPreviewView()

      } else if (this.isCameraReady) {
        // 相机预览状态
        this.buildCameraView()

      } else {
        // 默认状态
        Column() {
          Text('📸')
            .fontSize(48)
            .fontColor('#C0C0C0')
            .margin({ bottom: 16 })

          Text('相机准备中...')
            .fontSize(16)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#000000')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  /**
   * 构建相机视图
   */
  @Builder
  private buildCameraView() {
    Column() {
      // 顶部控制栏
      Row() {
        Button('←')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .backgroundColor('transparent')
          .onClick(() => {
            this.navigateBack()
          })

        Blank()

        // 工点信息
        if (this.siteName) {
          Text(this.siteName)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#00000080')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
        }

        Blank()

        // 闪光灯按钮
        Button(this.flashEnabled ? '⚡' : '🔦')
          .fontSize(20)
          .fontColor(this.flashEnabled ? '#FFD700' : '#FFFFFF')
          .backgroundColor('transparent')
          .onClick(() => {
            this.flashEnabled = !this.flashEnabled
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 相机预览区域（模拟）
      Column() {
        Text('📷')
          .fontSize(64)
          .fontColor('#666666')
          .margin({ bottom: 16 })

        Text('相机预览区域')
          .fontSize(16)
          .fontColor('#999999')

        if (this.watermarkEnabled) {
          Text('💧 水印已启用')
            .fontSize(14)
            .fontColor('#1890FF')
            .margin({ top: 8 })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#111111')

      // 底部控制栏
      Column() {
        // 功能按钮
        Row({ space: 20 }) {
          Button('🔁')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .backgroundColor('#333333')
            .width(50)
            .height(50)
            .borderRadius(25)
            .onClick(() => {
              // TODO: 切换前后摄像头
              console.log('Switch camera')
            })

          // 拍照按钮
          Button()
            .width(80)
            .height(80)
            .borderRadius(40)
            .backgroundColor('#FFFFFF')
            .border({ width: 4, color: '#E0E0E0' })
            .onClick(() => {
              this.takePhoto()
            })

          Button('💧')
            .fontSize(24)
            .fontColor(this.watermarkEnabled ? '#1890FF' : '#FFFFFF')
            .backgroundColor(this.watermarkEnabled ? '#FFFFFF20' : '#333333')
            .width(50)
            .height(50)
            .borderRadius(25)
            .onClick(() => {
              this.watermarkEnabled = !this.watermarkEnabled
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })

        // 提示信息
        Text('轻触拍照，长按连拍')
          .fontSize(14)
          .fontColor('#CCCCCC')
          .margin({ bottom: 20 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .backgroundColor('#00000080')
    }
  }

  /**
   * 构建预览视图
   */
  @Builder
  private buildPreviewView() {
    Column() {
      // 顶部控制栏
      Row() {
        Button('✕')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .backgroundColor('transparent')
          .onClick(() => {
            this.retakePhoto()
          })

        Blank()

        Text('照片预览')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)

        Blank()

        Button('✓')
          .fontSize(20)
          .fontColor('#1890FF')
          .backgroundColor('transparent')
          .onClick(() => {
            this.confirmPhoto()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 图片预览（模拟）
      Column() {
        Text('🖼️')
          .fontSize(64)
          .fontColor('#666666')
          .margin({ bottom: 16 })

        Text('照片预览')
          .fontSize(16)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Text(this.capturedImagePath)
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.watermarkEnabled) {
          Text('💧 包含水印信息')
            .fontSize(14)
            .fontColor('#1890FF')
            .margin({ top: 8 })
        }

        if (this.siteName) {
          Text(`📍 工点: ${this.siteName}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#00000080')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(12)
            .margin({ top: 8 })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')

      // 底部操作栏
      Row({ space: 20 }) {
        Button('重新拍照')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#666666')
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .borderRadius(8)
          .onClick(() => {
            this.retakePhoto()
          })

        Button('使用照片')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#1890FF')
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .borderRadius(8)
          .onClick(() => {
            this.confirmPhoto()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 20, right: 20, top: 16, bottom: 40 })
      .backgroundColor('#00000080')
    }
  }
}