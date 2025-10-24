/**
 * 简化相机页面
 * 根据原型设计实现的工程拍照界面
 */

import router from '@ohos.router'
import { common } from '@kit.AbilityKit'
import { PermissionManager, PermissionStatus } from '../../utils/PermissionManager'
import { CameraManager, CameraResult } from '../../utils/CameraManager'

/**
 * Surface尺寸接口
 */
interface SurfaceSize {
  width: number
  height: number
}

@Entry
@ComponentV2
struct CameraPage_Simple {
  @Local private isCameraReady: boolean = false
  @Local private isLoading: boolean = true
  @Local private showPreview: boolean = false
  @Local private capturedImagePath: string = ''
  @Local private capturedPhotoData: ArrayBuffer | null = null

  // 权限相关状态
  @Local private permissionStatus: PermissionStatus = PermissionStatus.NOT_DETERMINED
  @Local private showPermissionDialog: boolean = false
  @Local private permissionMessage: string = ''

  // 工点信息
  @Local private projectId: string = ''
  @Local private siteId: string = ''
  @Local private siteName: string = ''

  // 设置选项
  @Local private watermarkEnabled: boolean = true
  @Local private flashEnabled: boolean = false

  // 相机管理相关
  @Local private cameraManager: CameraManager | null = null
  @Local private cameraErrorMessage: string = ''
  @Local private surfaceId: string = ''
  @Local private showCameraError: boolean = false

  aboutToAppear(): void {
    this.loadRouteParams()
    this.checkAndRequestPermission()
  }

  aboutToDisappear(): void {
    console.log('=== CameraPage.aboutToDisappear() ===')
    this.releaseCamera()
  }

  /**
   * 释放相机资源
   */
  private async releaseCamera(): Promise<void> {
    console.log('=== CameraPage.releaseCamera() ===')

    try {
      if (this.cameraManager) {
        await this.cameraManager.releaseCamera()
        this.cameraManager = null
        console.log('Camera resources released')
      }
    } catch (error) {
      console.error('Release camera failed:', error)
    }
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
   * 检查并申请相机权限
   */
  private async checkAndRequestPermission(): Promise<void> {
    console.log('=== CameraPage.checkAndRequestPermission() ===')

    try {
      console.log('Getting UIAbility context for permission check...')
      // 获取UIAbilityContext
      const context = getContext(this) as common.UIAbilityContext
      if (!context) {
        console.error('Failed to get UIAbility context for permission check')
        throw new Error('Failed to get application context')
      }

      console.log('Checking camera permission...')
      // 检查权限状态
      const permissionManager = PermissionManager.getInstance()
      const result = await permissionManager.ensureCameraPermission(context)

      this.permissionStatus = result.status
      this.permissionMessage = result.message || ''

      console.log('Permission result:', result)
      console.log('Permission status:', result.status)
      console.log('Permission message:', result.message)

      if (result.status === PermissionStatus.GRANTED) {
        console.log('Camera permission granted, initializing camera manager...')
        this.initCameraManager()
      } else {
        console.log('Camera permission not granted:', result.message)
        this.isLoading = false
        this.showPermissionDialog = true
      }
    } catch (error) {
      console.error('Permission check failed:', error)
      this.permissionMessage = `权限检查失败: ${error instanceof Error ? error.message : String(error)}`
      this.permissionStatus = PermissionStatus.DENIED
      this.isLoading = false
      this.showPermissionDialog = true
    }
  }

  /**
   * 申请相机权限
   */
  private async requestPermission(): Promise<void> {
    console.log('=== CameraPage.requestPermission() ===')

    try {
      const context = getContext(this) as common.UIAbilityContext
      const permissionManager = PermissionManager.getInstance()

      const result = await permissionManager.requestCameraPermission(context)

      this.permissionStatus = result.status
      this.permissionMessage = result.message || ''

      if (result.status === PermissionStatus.GRANTED) {
        console.log('Camera permission granted after request')
        this.showPermissionDialog = false
        this.isLoading = true
        this.initCameraManager()
      } else {
        console.log('Camera permission denied after request')
        this.permissionMessage = '相机权限被拒绝，请在设置中手动开启'
      }
    } catch (error) {
      console.error('Request permission failed:', error)
      this.permissionMessage = '权限申请失败'
    }
  }

  /**
   * 初始化相机管理器
   */
  private async initCameraManager(): Promise<void> {
    console.log('=== CameraPage.initCameraManager() ===')

    try {
      // 获取相机管理器实例
      this.cameraManager = CameraManager.getInstance()
      console.log('Camera manager instance created')

      // 重要：设置isLoading为false，让XComponent可以渲染
      this.isLoading = false
      console.log('Loading state set to false, XComponent should now render')

      // 设置初始化超时 - 30秒后自动停止加载
      const timeoutId = setTimeout(() => {
        if (!this.isCameraReady && !this.showCameraError) {
          console.error('Camera initialization timeout (30 seconds)')
          this.cameraErrorMessage = '相机初始化超时，请重试'
          this.showCameraError = true
        }
      }, 30000)

      // 设置回调
      this.cameraManager.onInitialized(() => {
        console.log('Camera manager initialization callback triggered')
        clearTimeout(timeoutId) // 清除超时定时器
        this.isCameraReady = true
        console.log('Camera ready for use')
      })

      this.cameraManager.onError((error: string) => {
        console.error('Camera manager error:', error)
        clearTimeout(timeoutId) // 清除超时定时器
        this.cameraErrorMessage = error
        this.showCameraError = true
      })

      console.log('Camera manager initialized, waiting for surface ID')

    } catch (error) {
      console.error('Init camera manager failed:', error)
      this.cameraErrorMessage = `相机管理器初始化失败: ${error instanceof Error ? error.message : String(error)}`
      this.showCameraError = true
      this.isLoading = false
    }
  }

  /**
   * 使用Surface ID初始化相机
   */
  async initializeCameraWithSurface(surfaceId: string): Promise<void> {
    console.log('=== CameraPage.initializeCameraWithSurface() ===')
    console.log('Surface ID:', surfaceId)
    console.log('Camera manager exists:', !!this.cameraManager)
    console.log('Current loading state:', this.isLoading)

    try {
      if (!this.cameraManager) {
        console.error('Camera manager is null or undefined')
        throw new Error('Camera manager not initialized')
      }

      console.log('Getting UIAbility context...')
      const context = getContext(this) as common.UIAbilityContext
      if (!context) {
        console.error('Failed to get UIAbility context')
        throw new Error('Failed to get application context')
      }

      console.log('Starting camera initialization with surface...')
      const result = await this.cameraManager.initializeCamera(context, surfaceId)
      console.log('Camera initialization result:', result)

      if (result.success) {
        console.log('Camera initialized with surface successfully')
        this.surfaceId = surfaceId
        // 注意：不要在这里设置isLoading = false，因为这会在onInitialized回调中处理
      } else {
        console.error('Camera initialization failed:', result.message)
        this.cameraErrorMessage = result.message || '相机初始化失败'
        this.showCameraError = true
        this.isLoading = false
      }

    } catch (error) {
      console.error('Initialize camera with surface failed:', error)
      this.cameraErrorMessage = `相机预览初始化失败: ${error instanceof Error ? error.message : String(error)}`
      this.showCameraError = true
      this.isLoading = false
    }
  }

  /**
   * 拍照
   */
  private async takePhoto(): Promise<void> {
    console.log('=== CameraPage.takePhoto() ===')

    try {
      if (!this.cameraManager || !this.cameraManager.isCameraReady()) {
        console.error('Camera not ready for taking photo')
        this.cameraErrorMessage = '相机未就绪，无法拍照'
        this.showCameraError = true
        return
      }

      console.log('Taking photo with camera...')

      // 执行真实拍照
      const result = await this.cameraManager.takePhoto()

      if (result.success) {
        console.log('Photo captured successfully')
        this.capturedPhotoData = result.data instanceof ArrayBuffer ? result.data : null
        this.capturedImagePath = `/storage/camera/photo_${Date.now()}.jpg`
        this.showPreview = true
        console.log('Photo data size:', this.capturedPhotoData?.byteLength || 0)
      } else {
        console.error('Take photo failed:', result.message)
        this.cameraErrorMessage = result.message || '拍照失败'
        this.showCameraError = true
      }

    } catch (error) {
      console.error('Take photo failed with exception:', error)
      this.cameraErrorMessage = '拍照过程中发生错误'
      this.showCameraError = true
    }
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

      } else if (this.showCameraError) {
        // 相机错误状态
        this.buildCameraErrorDialog()

      } else if (this.showPermissionDialog) {
        // 权限对话框状态
        this.buildPermissionDialog()

      } else if (this.showPreview) {
        // 预览状态
        this.buildPreviewView()

      } else if (this.isCameraReady) {
        // 相机预览状态
        this.buildCameraView()

      } else {
        // 默认状态 - 等待相机管理器设置完成
        this.buildCameraView()
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
  buildCameraView() {
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
          .onClick(async () => {
            if (this.cameraManager && this.cameraManager.isCameraReady()) {
              const result = await this.cameraManager.toggleFlash()
              if (result.success) {
                this.flashEnabled = !this.flashEnabled
                console.log('Flash toggled successfully')
              } else {
                console.error('Toggle flash failed:', result.message)
              }
            } else {
              console.log('Camera not ready for flash toggle')
            }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 相机预览区域
      Stack() {
        // 相机预览Surface
        XComponent({
          id: 'camera_preview',
          type: 'surface',
          libraryname: '',
        })
          .onLoad((xComponent: XComponentController) => {
            console.log('Camera preview XComponent loaded')
            try {
              xComponent.setXComponentSurfaceSize({
                surfaceWidth: 1280,
                surfaceHeight: 960
              })
              console.log('Surface size set: 1280 x 960')

              // 获取Surface ID
              const surfaceId: string = xComponent.getXComponentSurfaceId()
              console.log('Surface ID:', surfaceId)

              if (surfaceId && surfaceId.length > 0) {
                // 使用Surface ID初始化相机
                console.log('Surface ID is valid, initializing camera...')
                this.initializeCameraWithSurface(surfaceId)
              } else {
                console.error('Surface ID is empty or invalid')
                this.cameraErrorMessage = '相机预览区域初始化失败：Surface ID无效'
                this.showCameraError = true
                this.isLoading = false
              }
            } catch (error) {
              console.error('Get surface size failed:', error)
              this.cameraErrorMessage = '获取相机预览区域失败'
              this.showCameraError = true
              this.isLoading = false
            }
          })
          .width('100%')
          .height('100%')

        // 水印覆盖层
        if (this.watermarkEnabled) {
          Column({ space: 8 }) {
            Text('📸 工程拍记')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#00000080')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)

            if (this.siteName) {
              Text(`📍 ${this.siteName}`)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor('#00000080')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(12)
            }

            Text(new Date().toLocaleString())
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#00000080')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(12)
          }
          .position({ x: 16, y: 16 })
          .alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#000000')

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
  buildPreviewView() {
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

  /**
   * 构建权限对话框
   */
  @Builder
  buildPermissionDialog() {
    Column() {
      // 权限对话框内容
      Column({ space: 20 }) {
        // 图标
        Text('📸')
          .fontSize(64)
          .fontColor('#FFFFFF')
          .margin({ bottom: 16 })

        // 标题
        Text('需要相机权限')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 8 })

        // 说明
        Text('工程拍记需要访问相机来拍摄工程现场照片')
          .fontSize(16)
          .fontColor('#E0E0E0')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })

        Text('用于项目记录和管理')
          .fontSize(14)
          .fontColor('#B0B0B0')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 })

        // 错误信息（如果有）
        if (this.permissionMessage) {
          Text(this.permissionMessage)
            .fontSize(14)
            .fontColor('#FF6B6B')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 20 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 按钮组
        Column({ space: 12 }) {
          if (this.permissionStatus === PermissionStatus.NOT_DETERMINED) {
            // 首次申请权限
            Button('授予相机权限')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#1890FF')
              .borderRadius(8)
              .onClick(() => {
                console.log('User clicked grant permission')
                this.requestPermission()
              })
          } else {
            // 权限被拒绝的情况
            Button('重新申请权限')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#1890FF')
              .borderRadius(8)
              .onClick(() => {
                console.log('User clicked retry permission')
                this.requestPermission()
              })

            Button('前往设置')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#1890FF')
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .border({ width: 1, color: '#1890FF' })
              .onClick(() => {
                console.log('User clicked open settings')
                const permissionManager = PermissionManager.getInstance()
                const context = getContext(this) as common.UIAbilityContext
                permissionManager.openAppSettings(context)
              })
          }

          Button('返回')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor('#8C8C8C')
            .backgroundColor('transparent')
            .borderRadius(8)
            .onClick(() => {
              console.log('User clicked back')
              this.navigateBack()
            })
        }
        .width('100%')
      }
      .width('88%')
      .backgroundColor('#1E1E1E')
      .borderRadius(16)
      .padding({ top: 32, bottom: 24, left: 24, right: 24 })
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.3)',
        offsetX: 0,
        offsetY: 8
      })
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.8)')
    .onClick(() => {
      // 点击背景不会关闭对话框，确保用户必须做出选择
      console.log('Permission dialog background clicked - ignoring')
    })
  }

  /**
   * 构建相机错误对话框
   */
  @Builder
  buildCameraErrorDialog() {
    Column() {
      // 错误对话框内容
      Column({ space: 20 }) {
        // 图标
        Text('⚠️')
          .fontSize(64)
          .fontColor('#FF6B6B')
          .margin({ bottom: 16 })

        // 标题
        Text('相机错误')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 8 })

        // 错误信息
        if (this.cameraErrorMessage) {
          Text(this.cameraErrorMessage)
            .fontSize(16)
            .fontColor('#E0E0E0')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 说明文字
        Text('请检查相机是否被其他应用占用，或重启应用后重试')
          .fontSize(14)
          .fontColor('#B0B0B0')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 })

        // 按钮组
        Column({ space: 12 }) {
          Button('重试')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .borderRadius(8)
            .onClick(() => {
              console.log('User clicked retry camera')
              if (this.showCameraError !== undefined) {
                this.showCameraError = false
              }
              if (this.cameraErrorMessage !== undefined) {
                this.cameraErrorMessage = ''
              }
              if (this.isLoading !== undefined) {
                this.isLoading = true
              }
              this.initCameraManager()
            })

          Button('返回')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor('#8C8C8C')
            .backgroundColor('transparent')
            .borderRadius(8)
            .onClick(() => {
              console.log('User clicked back from camera error')
              this.navigateBack()
            })
        }
        .width('100%')
      }
      .width('88%')
      .backgroundColor('#1E1E1E')
      .borderRadius(16)
      .padding({ top: 32, bottom: 24, left: 24, right: 24 })
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.3)',
        offsetX: 0,
        offsetY: 8
      })
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.8)')
    .onClick(() => {
      // 点击背景不会关闭对话框
      console.log('Camera error dialog background clicked - ignoring')
    })
  }
}