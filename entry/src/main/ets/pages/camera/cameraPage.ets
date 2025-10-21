/**
 * 相机预览页面
 * 提供相机实时预览、拍照控制、参数调节等功能
 */

import { router } from '@ohos.router'
import { camera } from '@kit.CameraKit'
import { Logger } from '../../utils/Logger'
import { CameraService, CameraState, CameraPosition, FlashMode } from '../../services/camera/CameraService'
import { PhotoCaptureService, CaptureState, CaptureMode, PhotoFormat, ImageQuality } from '../../services/camera/PhotoCaptureService'
import { PhotoInfo, CaptureResult } from '../../services/camera/PhotoCaptureService'
import { GlobalStore } from '../../store/GlobalStore'
import { UserStore } from '../../store/user/UserStore'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'

/**
 * 页面参数接口
 */
interface CameraPageParams {
  projectId?: string
  siteId?: string
  photoMode?: 'engineering' | 'personal' | 'inspection'
}

/**
 * 相机控制配置接口
 */
interface CameraControlConfig {
  flashMode: FlashMode
  gridLines: boolean
  aspectRatio: '4:3' | '16:9' | '1:1'
  quality: ImageQuality
  format: PhotoFormat
  selfTimer: number
  burstMode: boolean
  burstCount: number
}

@Entry
@Component
struct CameraPage {
  private logger = new Logger('CameraPage')

  // 服务实例
  private cameraService: CameraService = CameraService.getInstance()
  private captureService: PhotoCaptureService = PhotoCaptureService.getInstance()
  private globalStore = GlobalStore.getInstance()
  private userStore = UserStore.getInstance()
  private projectStore = ProjectStore.getInstance()
  private siteStore = SiteStore.getInstance()

  // 页面参数
  @State private pageParams: CameraPageParams = {}

  // 相机状态
  @State private cameraState: CameraState = CameraState.UNINITIALIZED
  @State private captureState: CaptureState = CaptureState.IDLE
  @State private currentCameraPosition: CameraPosition = CameraPosition.BACK
  @State private isInitialized: boolean = false

  // 相机控制配置
  @State private cameraConfig: CameraControlConfig = {
    flashMode: FlashMode.AUTO,
    gridLines: false,
    aspectRatio: '4:3',
    quality: ImageQuality.HIGH,
    format: PhotoFormat.JPEG,
    selfTimer: 0,
    burstMode: false,
    burstCount: 3
  }

  // UI状态
  @State private showControls: boolean = true
  @State private showSettings: boolean = false
  @State private showProgress: boolean = false
  @State private captureProgress: number = 0
  @State private progressMessage: string = ''
  @State private capturedPhoto: PhotoInfo | null = null
  @State private showPreview: boolean = false
  @State private errorMessage: string = ''
  @State private showError: boolean = false

  // 自动隐藏控制器的定时器
  private hideControlsTimer: number = -1

  aboutToAppear() {
    this.logger.info('CameraPage aboutToAppear')
    this.initializePage()
  }

  aboutToDisappear() {
    this.logger.info('CameraPage aboutToDisappear')
    this.cleanupResources()
  }

  /**
   * 初始化页面
   */
  private async initializePage(): Promise<void> {
    try {
      // 获取页面参数
      this.parsePageParams()

      // 初始化相机服务
      await this.initializeCameraServices()

      // 设置服务回调
      this.setupServiceCallbacks()

      // 配置拍照参数
      this.configureCaptureServices()

      this.isInitialized = true
      this.logger.info('CameraPage initialized successfully')

    } catch (error) {
      this.logger.error('Failed to initialize CameraPage', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 解析页面参数
   */
  private parsePageParams(): void {
    try {
      const params = router.getParams() as CameraPageParams
      if (params) {
        this.pageParams = { ...params }
        this.logger.info('Page params parsed', this.pageParams)
      }
    } catch (error) {
      this.logger.error('Failed to parse page params', error)
    }
  }

  /**
   * 初始化相机服务
   */
  private async initializeCameraServices(): Promise<void> {
    this.logger.info('Initializing camera services...')

    try {
      // 初始化相机服务
      if (this.cameraService.getState() === CameraState.UNINITIALIZED) {
        await this.cameraService.initialize()
      }

      // 初始化拍照服务
      await this.captureService.initialize()

      // 更新状态
      this.cameraState = this.cameraService.getState()
      this.currentCameraPosition = this.cameraService.getCurrentCameraInfo()?.cameraPosition || CameraPosition.BACK

      this.logger.info('Camera services initialized', {
        cameraState: this.cameraState,
        cameraPosition: this.currentCameraPosition
      })

    } catch (error) {
      this.logger.error('Failed to initialize camera services', error)
      throw error
    }
  }

  /**
   * 设置服务回调
   */
  private setupServiceCallbacks(): void {
    // 相机服务回调
    this.cameraService.setCallbacks({
      onCameraReady: (cameraInfo) => {
        this.logger.info('Camera ready', cameraInfo)
        this.cameraState = CameraState.READY
        this.currentCameraPosition = cameraInfo.cameraPosition
      },
      onCameraError: (error) => {
        this.logger.error('Camera error', error)
        this.cameraState = CameraState.ERROR
        this.handleError(error)
      },
      onCameraDisconnected: () => {
        this.logger.warn('Camera disconnected')
        this.cameraState = CameraState.ERROR
        this.handleError(new Error('相机连接已断开'))
      }
    })

    // 拍照服务回调
    this.captureService.setCallbacks({
      onProgress: (progress) => {
        this.captureProgress = progress.progress
        this.progressMessage = progress.message
        this.showProgress = true
      },
      onSuccess: (result) => {
        this.logger.info('Capture success', result)
        this.handleCaptureSuccess(result)
      },
      onError: (error) => {
        this.logger.error('Capture error', error)
        this.handleError(error)
      },
      onShutter: () => {
        this.logger.info('Shutter triggered')
        // 播放快门声音或震动反馈
      }
    })
  }

  /**
   * 配置拍照服务
   */
  private configureCaptureServices(): void {
    this.captureService.configureCapture({
      mode: this.cameraConfig.burstMode ? CaptureMode.BURST : CaptureMode.SINGLE,
      format: this.cameraConfig.format,
      quality: this.cameraConfig.quality,
      timerSeconds: this.cameraConfig.selfTimer > 0 ? this.cameraConfig.selfTimer : undefined,
      burstCount: this.cameraConfig.burstMode ? this.cameraConfig.burstCount : undefined,
      saveToGallery: true,
      addWatermark: true
    })
  }

  /**
   * 拍照
   */
  private async capturePhoto(): Promise<void> {
    if (this.captureState !== CaptureState.IDLE) {
      this.logger.warn('Cannot capture, not in idle state')
      return
    }

    try {
      this.captureState = CaptureState.PREPARING
      this.startAutoHideControlsTimer()

      // 准备元数据
      const metadata = this.preparePhotoMetadata()

      // 执行拍照
      const result = await this.captureService.capturePhoto(metadata)

      if (result.success && result.photo) {
        this.handleCaptureSuccess(result)
      } else {
        throw result.error || new Error('拍照失败')
      }

    } catch (error) {
      this.logger.error('Failed to capture photo', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    } finally {
      this.captureState = CaptureState.IDLE
      this.showProgress = false
    }
  }

  /**
   * 准备照片元数据
   */
  private preparePhotoMetadata(): any {
    const metadata: any = {
      user: {
        projectId: this.pageParams.projectId,
        siteId: this.pageParams.siteId,
        photoMode: this.pageParams.photoMode
      }
    }

    // 添加位置信息（如果可用）
    // 这里可以添加定位服务的调用

    return metadata
  }

  /**
   * 处理拍照成功
   */
  private handleCaptureSuccess(result: CaptureResult): void {
    if (result.photo) {
      this.capturedPhoto = result.photo
      this.showPreview = true
      this.logger.info('Photo captured successfully', result.photo)
    }
  }

  /**
   * 切换相机（前置/后置）
   */
  private async switchCamera(): Promise<void> {
    try {
      const targetPosition = this.currentCameraPosition === CameraPosition.BACK
        ? CameraPosition.FRONT
        : CameraPosition.BACK

      await this.cameraService.switchCamera(targetPosition)
      this.currentCameraPosition = targetPosition

      this.startAutoHideControlsTimer()
    } catch (error) {
      this.logger.error('Failed to switch camera', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 切换闪光灯模式
   */
  private switchFlashMode(): void {
    const modes: FlashMode[] = [FlashMode.OFF, FlashMode.AUTO, FlashMode.ON, FlashMode.TORCH]
    const currentIndex = modes.indexOf(this.cameraConfig.flashMode)
    const nextIndex = (currentIndex + 1) % modes.length

    this.cameraConfig.flashMode = modes[nextIndex]
    this.applyFlashMode()
    this.startAutoHideControlsTimer()
  }

  /**
   * 应用闪光灯模式
   */
  private async applyFlashMode(): Promise<void> {
    try {
      await this.cameraService.configureCamera({ flashMode: this.cameraConfig.flashMode })
    } catch (error) {
      this.logger.error('Failed to apply flash mode', error)
    }
  }

  /**
   * 切换网格线显示
   */
  private toggleGridLines(): void {
    this.cameraConfig.gridLines = !this.cameraConfig.gridLines
    this.startAutoHideControlsTimer()
  }

  /**
   * 开始自动隐藏控制器的定时器
   */
  private startAutoHideControlsTimer(): void {
    if (this.hideControlsTimer >= 0) {
      clearTimeout(this.hideControlsTimer)
    }

    this.hideControlsTimer = setTimeout(() => {
      this.showControls = false
    }, 3000) // 3秒后隐藏
  }

  /**
   * 显示控制器
   */
  private showControlsPanel(): void {
    this.showControls = true
    this.startAutoHideControlsTimer()
  }

  /**
   * 处理错误
   */
  private handleError(error: Error): void {
    this.errorMessage = error.message
    this.showError = true
    this.logger.error('Camera page error', error)
  }

  /**
   * 关闭错误提示
   */
  private dismissError(): void {
    this.showError = false
    this.errorMessage = ''
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    router.back()
  }

  /**
   * 跳转到水印配置页面
   */
  private goToWatermarkConfig(): void {
    router.pushUrl({
      url: 'pages/camera/watermarkConfigPage',
      params: {
        returnToCamera: true
      }
    })
  }

  /**
   * 查看拍摄结果
   */
  private viewCaptureResult(): void {
    if (this.capturedPhoto) {
      router.pushUrl({
        url: 'pages/camera/captureResultPage',
        params: {
          photoInfo: this.capturedPhoto,
          fromCamera: true
        }
      })
    }
  }

  /**
   * 继续拍照
   */
  private continueCapture(): void {
    this.showPreview = false
    this.capturedPhoto = null
    this.showControls = true
    this.startAutoHideControlsTimer()
  }

  /**
   * 清理资源
   */
  private cleanupResources(): void {
    if (this.hideControlsTimer >= 0) {
      clearTimeout(this.hideControlsTimer)
    }
  }

  build() {
    Stack() {
      // 相机预览区域
      this.buildCameraPreview()

      // 控制层
      this.buildControlsLayer()

      // 进度提示
      if (this.showProgress) {
        this.buildProgressIndicator()
      }

      // 拍摄结果预览
      if (this.showPreview && this.capturedPhoto) {
        this.buildCapturePreview()
      }

      // 错误提示
      if (this.showError) {
        this.buildErrorDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .onClick(() => {
      this.showControlsPanel()
    })
  }

  /**
   * 构建相机预览
   */
  @Builder
  buildCameraPreview() {
    Stack() {
      // 相机预览组件（这里需要根据实际的相机API实现）
      if (this.cameraState === CameraState.READY) {
        XComponent({
          id: 'camera_preview',
          type: 'surface',
          libraryname: ''
        })
          .width('100%')
          .height('100%')
          .onLoad(() => {
            this.logger.info('Camera preview loaded')
            // 设置相机预览输出
            const previewOutput = this.cameraService.getPreviewOutput()
            if (previewOutput) {
              // 这里需要将预览输出绑定到XComponent
            }
          })
      } else {
        Column() {
          Text(this.cameraState === CameraState.INITIALIZING ? '正在初始化相机...' :
               this.cameraState === CameraState.ERROR ? '相机初始化失败' : '相机未就绪')
            .fontSize(16)
            .fontColor(Color.White)
            .opacity(0.8)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }

      // 网格线
      if (this.cameraConfig.gridLines) {
        this.buildGridLines()
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建网格线
   */
  @Builder
  buildGridLines() {
    Stack() {
      // 横线
      Line()
        .width('100%')
        .height(1)
        .stroke(Color.White)
        .strokeOpacity(0.3)
        .position({ x: 0, y: '33.33%' })

      Line()
        .width('100%')
        .height(1)
        .stroke(Color.White)
        .strokeOpacity(0.3)
        .position({ x: 0, y: '66.67%' })

      // 竖线
      Line()
        .width(1)
        .height('100%')
        .stroke(Color.White)
        .strokeOpacity(0.3)
        .position({ x: '33.33%', y: 0 })

      Line()
        .width(1)
        .height('100%')
        .stroke(Color.White)
        .strokeOpacity(0.3)
        .position({ x: '66.67%', y: 0 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }

  /**
   * 构建控制层
   */
  @Builder
  buildControlsLayer() {
    Column() {
      // 顶部控制栏
      this.buildTopControls()

      Blank()

      // 底部控制栏
      this.buildBottomControls()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .opacity(this.showControls ? 1 : 0)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 构建顶部控制栏
   */
  @Builder
  buildTopControls() {
    Row() {
      // 返回按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => this.goBack())

      Blank()

      // 设置按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_settings'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => this.goToWatermarkConfig())

      // 网格线按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_grid'))
          .width(24)
          .height(24)
          .fillColor(this.cameraConfig.gridLines ? Color.Blue : Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => this.toggleGridLines())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 40 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 构建底部控制栏
   */
  @Builder
  buildBottomControls() {
    Column() {
      // 拍照模式指示器
      this.buildModeIndicator()

      // 控制按钮组
      Row() {
        // 切换相机按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_switch_camera'))
            .width(28)
            .height(28)
            .fillColor(Color.White)
        }
        .width(50)
        .height(50)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.switchCamera())

        Blank()

        // 拍照按钮
        Button({ type: ButtonType.Circle }) {
          Circle()
            .width(60)
            .height(60)
            .fill(Color.White)
            .stroke(Color.Red)
            .strokeWidth(3)
        }
        .width(70)
        .height(70)
        .backgroundColor('rgba(0,0,0,0.3)')
        .enabled(this.captureState === CaptureState.IDLE && this.cameraState === CameraState.READY)
        .onClick(() => this.capturePhoto())

        Blank()

        // 闪光灯按钮
        Button({ type: ButtonType.Circle }) {
          Image(this.getFlashModeIcon())
            .width(28)
            .height(28)
            .fillColor(Color.White)
        }
        .width(50)
        .height(50)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.switchFlashMode())
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceAround)
    }
    .padding({ bottom: 40 })
  }

  /**
   * 构建拍照模式指示器
   */
  @Builder
  buildModeIndicator() {
    Row() {
      // 项目信息
      if (this.pageParams.projectId) {
        Text(`项目: ${this.getProjectName()}`)
          .fontSize(14)
          .fontColor(Color.White)
          .opacity(0.8)
      }

      Blank()

      // 相机状态
      Text(this.getCameraStateText())
        .fontSize(14)
        .fontColor(this.getStateColor())
        .opacity(0.8)

      Blank()

      // 拍照配置
      Text(`${this.cameraConfig.quality} ${this.cameraConfig.format.toUpperCase()}`)
        .fontSize(14)
        .fontColor(Color.White)
        .opacity(0.8)
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
  }

  /**
   * 构建进度指示器
   */
  @Builder
  buildProgressIndicator() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(Color.White)

      Text(this.progressMessage)
        .fontSize(16)
        .fontColor(Color.White)
        .margin({ top: 12 })
        .opacity(0.9)

      if (this.captureProgress > 0 && this.captureProgress < 100) {
        Progress({ value: this.captureProgress, total: 100, type: ProgressType.Linear })
          .width(200)
          .height(4)
          .color(Color.White)
          .margin({ top: 8 })
      }
    }
    .width(200)
    .padding(20)
    .backgroundColor('rgba(0,0,0,0.7)')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .position({ x: '50%', y: '50%' })
    .markAnchor({ x: '50%', y: '50%' })
  }

  /**
   * 构建拍摄结果预览
   */
  @Builder
  buildCapturePreview() {
    Column() {
      // 预览图片
      Image(this.capturedPhoto?.uri || '')
        .width('100%')
        .height('60%')
        .objectFit(ImageFit.Contain)
        .backgroundColor(Color.Black)

      // 操作按钮
      Row() {
        Button('重新拍摄')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => this.continueCapture())

        Blank()

        Button('查看照片')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(Color.Blue)
          .onClick(() => this.viewCaptureResult())
      }
      .width('100%')
      .padding(20)
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 构建错误对话框
   */
  @Builder
  buildErrorDialog() {
    Column() {
      Text('错误')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Red)
        .margin({ bottom: 12 })

      Text(this.errorMessage)
        .fontSize(14)
        .fontColor(Color.Black)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })

      Button('确定')
        .fontSize(16)
        .onClick(() => this.dismissError())
    }
    .width(280)
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .position({ x: '50%', y: '50%' })
    .markAnchor({ x: '50%', y: '50%' })
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.3)',
      offsetX: 0,
      offsetY: 4
    })
  }

  /**
   * 获取闪光灯模式图标
   */
  private getFlashModeIcon(): Resource {
    switch (this.cameraConfig.flashMode) {
      case FlashMode.OFF:
        return $r('app.media.ic_flash_off')
      case FlashMode.AUTO:
        return $r('app.media.ic_flash_auto')
      case FlashMode.ON:
        return $r('app.media.ic_flash_on')
      case FlashMode.TORCH:
        return $r('app.media.ic_flash_torch')
      default:
        return $r('app.media.ic_flash_auto')
    }
  }

  /**
   * 获取相机状态文本
   */
  private getCameraStateText(): string {
    switch (this.cameraState) {
      case CameraState.UNINITIALIZED:
        return '未初始化'
      case CameraState.INITIALIZING:
        return '初始化中'
      case CameraState.READY:
        return '就绪'
      case CameraState.CAPTURING:
        return '拍照中'
      case CameraState.ERROR:
        return '错误'
      default:
        return '未知状态'
    }
  }

  /**
   * 获取状态颜色
   */
  private getStateColor(): Color {
    switch (this.cameraState) {
      case CameraState.READY:
        return Color.Green
      case CameraState.ERROR:
        return Color.Red
      case CameraState.CAPTURING:
        return Color.Blue
      default:
        return Color.White
    }
  }

  /**
   * 获取项目名称
   */
  private getProjectName(): string {
    // 这里应该从ProjectStore获取项目名称
    return '工程项目' // 临时返回
  }
}