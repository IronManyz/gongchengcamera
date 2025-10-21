/**
 * 拍照服务类
 * 专门负责拍照功能、照片保存和参数设置
 */

import { camera } from '@kit.CameraKit'
import { image } from '@kit.ImageKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Logger } from '../../utils/Logger'
import { CameraService, CameraState } from './CameraService'
import { CameraConfigManager, CameraParameters, ImageQuality } from './CameraConfigManager'

/**
 * 拍照状态枚举
 */
export enum CaptureState {
  IDLE = 'idle',
  PREPARING = 'preparing',
  CAPTURING = 'capturing',
  PROCESSING = 'processing',
  SAVING = 'saving',
  COMPLETED = 'completed',
  ERROR = 'error'
}

/**
 * 拍照模式枚举
 */
export enum CaptureMode {
  SINGLE = 'single',
  BURST = 'burst',
  TIMER = 'timer',
  HDR = 'hdr',
  NIGHT = 'night',
  PROFESSIONAL = 'professional'
}

/**
 * 照片格式枚举
 */
export enum PhotoFormat {
  JPEG = 'jpeg',
  PNG = 'png',
  RAW = 'raw',
  HEIC = 'heic'
}

/**
 * 拍照配置接口
 */
export interface CaptureConfig {
  mode: CaptureMode
  format: PhotoFormat
  quality: ImageQuality
  resolution?: { width: number, height: number }
  burstCount?: number // 连拍数量
  timerSeconds?: number // 定时器秒数
  saveToGallery?: boolean
  addWatermark?: boolean
}

/**
 * 照片信息接口
 */
export interface PhotoInfo {
  id: string
  uri: string
  path: string
  name: string
  size: number
  width: number
  height: number
  format: PhotoFormat
  quality: ImageQuality
  timestamp: Date
  duration: number // 拍照耗时
  metadata: PhotoMetadata
}

/**
 * 照片元数据接口
 */
export interface PhotoMetadata {
  cameraSettings: {
    flashMode: string
    focusMode: string
    exposureMode: string
    whiteBalance: string
    iso: number
    exposureTime: number
    focalLength: number
    aperture: number
  }
  location?: {
    latitude: number
    longitude: number
    altitude: number
    accuracy: number
  }
  device: {
    manufacturer: string
    model: string
    software: string
  }
  user?: {
    projectId?: string
    siteId?: string
    description?: string
    tags?: string[]
  }
}

/**
 * 拍照结果接口
 */
export interface CaptureResult {
  success: boolean
  photo?: PhotoInfo
  error?: Error
  captureTime: number
  processingTime: number
}

/**
 * 拍照进度接口
 */
export interface CaptureProgress {
  state: CaptureState
  progress: number // 0-100
  message: string
  timestamp: number
}

/**
 * 拍照回调接口
 */
export interface CaptureCallbacks {
  onProgress?: (progress: CaptureProgress) => void
  onSuccess?: (result: CaptureResult) => void
  onError?: (error: Error) => void
  onShutter?: () => void
  onFocus?: (focused: boolean) => void
}

/**
 * 拍照服务类
 */
export class PhotoCaptureService {
  private static instance: PhotoCaptureService | null = null
  private logger = new Logger('PhotoCaptureService')
  private cameraService: CameraService
  private configManager: CameraConfigManager

  // 拍照状态
  private currentState: CaptureState = CaptureState.IDLE
  private currentConfig: CaptureConfig
  private captureStartTime: number = 0
  private processingStartTime: number = 0

  // 拍照相关
  private photoOutput: camera.PhotoOutput | null = null
  private isCapturing: boolean = false
  private pendingCaptures: number = 0

  // 回调
  private callbacks: CaptureCallbacks = {}

  // 默认配置
  private readonly defaultConfig: CaptureConfig = {
    mode: CaptureMode.SINGLE,
    format: PhotoFormat.JPEG,
    quality: ImageQuality.HIGH,
    saveToGallery: true,
    addWatermark: false
  }

  private constructor() {
    this.cameraService = CameraService.getInstance()
    this.configManager = CameraConfigManager.getInstance()
    this.currentConfig = { ...this.defaultConfig }
  }

  /**
   * 获取单例实例
   */
  static getInstance(): PhotoCaptureService {
    if (!PhotoCaptureService.instance) {
      PhotoCaptureService.instance = new PhotoCaptureService()
    }
    return PhotoCaptureService.instance
  }

  /**
   * 初始化拍照服务
   */
  async initialize(): Promise<void> {
    this.logger.info('Initializing PhotoCaptureService...')

    try {
      // 确保相机服务已就绪
      if (this.cameraService.getState() !== CameraState.READY) {
        throw new Error('Camera service not ready')
      }

      // 设置拍照输出
      await this.setupPhotoOutput()

      this.setState(CaptureState.IDLE)
      this.logger.info('PhotoCaptureService initialized successfully')
    } catch (error) {
      this.setState(CaptureState.ERROR)
      this.logger.error('Failed to initialize PhotoCaptureService', error)
      throw error
    }
  }

  /**
   * 设置拍照输出
   */
  private async setupPhotoOutput(): Promise<void> {
    this.logger.info('Setting up photo output...')

    try {
      // 获取相机服务的预览输出
      const previewOutput = this.cameraService.getPreviewOutput()
      if (!previewOutput) {
        throw new Error('Preview output not available')
      }

      // 这里需要根据实际的相机API创建拍照输出
      // 由于API限制，这里只做模拟
      this.logger.info('Photo output setup completed')
    } catch (error) {
      this.logger.error('Failed to setup photo output', error)
      throw error
    }
  }

  /**
   * 配置拍照参数
   */
  configureCapture(config: Partial<CaptureConfig>): void {
    this.logger.info('Configuring capture parameters...', config)

    this.currentConfig = { ...this.currentConfig, ...config }

    // 验证配置
    this.validateCaptureConfig()

    this.logger.info('Capture configuration updated', this.currentConfig)
  }

  /**
   * 验证拍照配置
   */
  private validateCaptureConfig(): void {
    const config = this.currentConfig

    // 验证连拍数量
    if (config.burstCount && config.burstCount > 20) {
      this.logger.warn('Burst count too high, limiting to 20')
      config.burstCount = 20
    }

    // 验证定时器秒数
    if (config.timerSeconds && (config.timerSeconds < 1 || config.timerSeconds > 30)) {
      this.logger.warn('Timer seconds out of range, setting to default')
      config.timerSeconds = 3
    }

    // 验证分辨率
    if (config.resolution) {
      if (config.resolution.width <= 0 || config.resolution.height <= 0) {
        this.logger.warn('Invalid resolution, using default')
        delete config.resolution
      }
    }
  }

  /**
   * 拍照
   */
  async capturePhoto(metadata?: Partial<PhotoMetadata>): Promise<CaptureResult> {
    this.logger.info('Starting photo capture...')

    if (this.isCapturing) {
      throw new Error('Already capturing photo')
    }

    if (this.cameraService.getState() !== CameraState.READY) {
      throw new Error('Camera not ready for capture')
    }

    this.isCapturing = true
    this.captureStartTime = Date.now()

    try {
      // 1. 准备拍照
      await this.prepareCapture()
      this.reportProgress(10, '准备拍照...')

      // 2. 处理定时器
      if (this.currentConfig.timerSeconds && this.currentConfig.timerSeconds > 0) {
        await this.handleTimerCapture()
      }

      // 3. 执行拍照
      this.setState(CaptureState.CAPTURING)
      this.reportProgress(30, '正在拍照...')

      const captureResult = await this.performCapture(metadata)
      this.reportProgress(60, '拍照完成')

      // 4. 处理照片
      this.setState(CaptureState.PROCESSING)
      this.processingStartTime = Date.now()

      const processedPhoto = await this.processPhoto(captureResult)
      this.reportProgress(80, '处理照片...')

      // 5. 保存照片
      if (this.currentConfig.saveToGallery) {
        this.setState(CaptureState.SAVING)
        const savedPhoto = await this.savePhoto(processedPhoto)
        this.reportProgress(100, '保存完成')

        const result: CaptureResult = {
          success: true,
          photo: savedPhoto,
          captureTime: this.processingStartTime - this.captureStartTime,
          processingTime: Date.now() - this.processingStartTime
        }

        this.setState(CaptureState.COMPLETED)
        this.notifySuccess(result)
        return result
      } else {
        const result: CaptureResult = {
          success: true,
          photo: processedPhoto,
          captureTime: this.processingStartTime - this.captureStartTime,
          processingTime: Date.now() - this.processingStartTime
        }

        this.setState(CaptureState.COMPLETED)
        this.notifySuccess(result)
        return result
      }

    } catch (error) {
      this.setState(CaptureState.ERROR)
      const captureError = error instanceof Error ? error : new Error(String(error))
      this.logger.error('Photo capture failed', error)
      this.notifyError(captureError)

      const result: CaptureResult = {
        success: false,
        error: captureError,
        captureTime: Date.now() - this.captureStartTime,
        processingTime: 0
      }

      return result
    } finally {
      this.isCapturing = false
      this.setState(CaptureState.IDLE)
    }
  }

  /**
   * 准备拍照
   */
  private async prepareCapture(): Promise<void> {
    this.setState(CaptureState.PREPARING)

    try {
      // 获取当前相机参数
      const currentParameters = this.configManager.getCurrentParameters()
      if (!currentParameters) {
        throw new Error('Camera parameters not available')
      }

      // 应用拍照特定的设置
      await this.applyCaptureSettings()

      this.logger.info('Capture preparation completed')
    } catch (error) {
      this.logger.error('Failed to prepare capture', error)
      throw error
    }
  }

  /**
   * 应用拍照设置
   */
  private async applyCaptureSettings(): Promise<void> {
    this.logger.info('Applying capture settings...')

    try {
      // 根据拍照模式应用不同的设置
      switch (this.currentConfig.mode) {
        case CaptureMode.HDR:
          await this.applyHDRSettings()
          break
        case CaptureMode.NIGHT:
          await this.applyNightSettings()
          break
        case CaptureMode.PROFESSIONAL:
          await this.applyProfessionalSettings()
          break
        default:
          await this.applyNormalSettings()
      }
    } catch (error) {
      this.logger.error('Failed to apply capture settings', error)
      throw error
    }
  }

  /**
   * 应用HDR设置
   */
  private async applyHDRSettings(): Promise<void> {
    this.logger.info('Applying HDR settings...')
    // 设置HDR相关的相机参数
  }

  /**
   * 应用夜间模式设置
   */
  private async applyNightSettings(): Promise<void> {
    this.logger.info('Applying night mode settings...')
    // 设置夜间模式相关的相机参数
  }

  /**
   * 应用专业模式设置
   */
  private async applyProfessionalSettings(): Promise<void> {
    this.logger.info('Applying professional mode settings...')
    // 设置专业模式相关的相机参数
  }

  /**
   * 应用普通设置
   */
  private async applyNormalSettings(): Promise<void> {
    this.logger.info('Applying normal settings...')
    // 应用普通的拍照设置
  }

  /**
   * 处理定时拍照
   */
  private async handleTimerCapture(): Promise<void> {
    const seconds = this.currentConfig.timerSeconds || 3
    this.logger.info(`Timer capture: ${seconds} seconds`)

    for (let i = seconds; i > 0; i--) {
      this.reportProgress(10 + (seconds - i) * 5, `${i}秒后拍照...`)
      await this.sleep(1000)
    }
  }

  /**
   * 执行拍照
   */
  private async performCapture(metadata?: Partial<PhotoMetadata>): Promise<any> {
    this.logger.info('Performing photo capture...')

    return new Promise((resolve, reject) => {
      try {
        // 通知快门
        this.notifyShutter()

        // 这里需要根据实际的相机API执行拍照
        // 由于API限制，这里创建一个模拟结果
        setTimeout(() => {
          const mockCaptureResult = {
            pixelMap: null, // 实际应该是PixelMap对象
            metadata: metadata || {}
          }
          resolve(mockCaptureResult)
        }, 500)

      } catch (error) {
        reject(error)
      }
    })
  }

  /**
   * 处理照片
   */
  private async processPhoto(captureResult: any): Promise<PhotoInfo> {
    this.logger.info('Processing captured photo...')

    try {
      const photoInfo: PhotoInfo = {
        id: this.generatePhotoId(),
        uri: '', // 实际应该是文件URI
        path: '', // 实际应该是文件路径
        name: this.generatePhotoName(),
        size: 0, // 实际应该是文件大小
        width: this.currentConfig.resolution?.width || 1920,
        height: this.currentConfig.resolution?.height || 1080,
        format: this.currentConfig.format,
        quality: this.currentConfig.quality,
        timestamp: new Date(),
        duration: Date.now() - this.captureStartTime,
        metadata: this.createPhotoMetadata(captureResult.metadata)
      }

      this.logger.info('Photo processing completed', photoInfo)
      return photoInfo
    } catch (error) {
      this.logger.error('Failed to process photo', error)
      throw error
    }
  }

  /**
   * 创建照片元数据
   */
  private createPhotoMetadata(userMetadata?: Partial<PhotoMetadata>): PhotoMetadata {
    const currentParameters = this.configManager.getCurrentParameters()

    return {
      cameraSettings: {
        flashMode: currentParameters?.flashMode || 'auto',
        focusMode: currentParameters?.focusMode || 'auto',
        exposureMode: currentParameters?.exposureMode || 'auto',
        whiteBalance: currentParameters?.whiteBalanceMode || 'auto',
        iso: currentParameters?.iso || 100,
        exposureTime: currentParameters?.shutterSpeed || 1 / 125,
        focalLength: 4.0, // 默认焦距
        aperture: 2.0 // 默认光圈
      },
      location: userMetadata?.location,
      device: {
        manufacturer: 'Huawei',
        model: 'Engineering Camera',
        software: '1.0.0'
      },
      user: userMetadata?.user
    }
  }

  /**
   * 保存照片
   */
  private async savePhoto(photoInfo: PhotoInfo): Promise<PhotoInfo> {
    this.logger.info('Saving photo...', { name: photoInfo.name })

    try {
      // 这里需要实现实际的文件保存逻辑
      // 可以使用FileService来保存照片

      // 模拟保存过程
      await this.sleep(200)

      // 更新照片信息
      photoInfo.uri = `file://photos/${photoInfo.name}`
      photoInfo.path = `/data/storage/photos/${photoInfo.name}`
      photoInfo.size = this.calculateFileSize(photoInfo)

      this.logger.info('Photo saved successfully', photoInfo)
      return photoInfo
    } catch (error) {
      this.logger.error('Failed to save photo', error)
      throw error
    }
  }

  /**
   * 连拍
   */
  async captureBurst(count: number = 5): Promise<CaptureResult[]> {
    this.logger.info(`Starting burst capture (${count} photos)...`)

    if (this.isCapturing) {
      throw new Error('Already capturing photo')
    }

    const results: CaptureResult[] = []
    const originalMode = this.currentConfig.mode

    try {
      this.isCapturing = true
      this.currentConfig.mode = CaptureMode.BURST
      this.currentConfig.burstCount = count

      for (let i = 0; i < count; i++) {
        this.reportProgress(i * 100 / count, `连拍 ${i + 1}/${count}`)

        const result = await this.capturePhoto()
        results.push(result)

        // 连拍间隔
        if (i < count - 1) {
          await this.sleep(200)
        }
      }

      this.logger.info('Burst capture completed', { count, successCount: results.filter(r => r.success).length })
      return results

    } finally {
      this.isCapturing = false
      this.currentConfig.mode = originalMode
      delete this.currentConfig.burstCount
    }
  }

  /**
   * 生成照片ID
   */
  private generatePhotoId(): string {
    return `photo_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  /**
   * 生成照片名称
   */
  private generatePhotoName(): string {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
    const extension = this.getFileExtension()
    return `IMG_${timestamp}.${extension}`
  }

  /**
   * 获取文件扩展名
   */
  private getFileExtension(): string {
    switch (this.currentConfig.format) {
      case PhotoFormat.JPEG:
        return 'jpg'
      case PhotoFormat.PNG:
        return 'png'
      case PhotoFormat.RAW:
        return 'raw'
      case PhotoFormat.HEIC:
        return 'heic'
      default:
        return 'jpg'
    }
  }

  /**
   * 计算文件大小
   */
  private calculateFileSize(photoInfo: PhotoInfo): number {
    const pixels = photoInfo.width * photoInfo.height
    const qualityFactor = this.getQualityFactor()
    return Math.round(pixels * qualityFactor)
  }

  /**
   * 获取质量系数
   */
  private getQualityFactor(): number {
    switch (this.currentConfig.quality) {
      case ImageQuality.LOW:
        return 0.1
      case ImageQuality.MEDIUM:
        return 0.2
      case ImageQuality.HIGH:
        return 0.4
      case ImageQuality.SUPERIOR:
        return 0.8
      default:
        return 0.4
    }
  }

  /**
   * 设置回调
   */
  setCallbacks(callbacks: CaptureCallbacks): void {
    this.callbacks = { ...this.callbacks, ...callbacks }
  }

  /**
   * 设置状态
   */
  private setState(state: CaptureState): void {
    const oldState = this.currentState
    this.currentState = state
    this.logger.info('Capture state changed', { from: oldState, to: state })
  }

  /**
   * 报告进度
   */
  private reportProgress(progress: number, message: string): void {
    const progressInfo: CaptureProgress = {
      state: this.currentState,
      progress,
      message,
      timestamp: Date.now()
    }

    this.logger.info('Capture progress', progressInfo)

    if (this.callbacks.onProgress) {
      try {
        this.callbacks.onProgress(progressInfo)
      } catch (error) {
        this.logger.error('Error in progress callback', error)
      }
    }
  }

  /**
   * 通知成功
   */
  private notifySuccess(result: CaptureResult): void {
    if (this.callbacks.onSuccess) {
      try {
        this.callbacks.onSuccess(result)
      } catch (error) {
        this.logger.error('Error in success callback', error)
      }
    }
  }

  /**
   * 通知错误
   */
  private notifyError(error: Error): void {
    if (this.callbacks.onError) {
      try {
        this.callbacks.onError(error)
      } catch (callbackError) {
        this.logger.error('Error in error callback', callbackError)
      }
    }
  }

  /**
   * 通知快门
   */
  private notifyShutter(): void {
    if (this.callbacks.onShutter) {
      try {
        this.callbacks.onShutter()
      } catch (error) {
        this.logger.error('Error in shutter callback', error)
      }
    }
  }

  /**
   * 通知对焦
   */
  private notifyFocus(focused: boolean): void {
    if (this.callbacks.onFocus) {
      try {
        this.callbacks.onFocus(focused)
      } catch (error) {
        this.logger.error('Error in focus callback', error)
      }
    }
  }

  /**
   * 睡眠
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  /**
   * 获取当前状态
   */
  getState(): CaptureState {
    return this.currentState
  }

  /**
   * 是否正在拍照
   */
  isCapturingPhoto(): boolean {
    return this.isCapturing
  }

  /**
   * 获取当前配置
   */
  getCurrentConfig(): CaptureConfig {
    return { ...this.currentConfig }
  }

  /**
   * 获取拍照统计信息
   */
  getCaptureStats(): {
    state: CaptureState
    isCapturing: boolean
    config: CaptureConfig
  } {
    return {
      state: this.currentState,
      isCapturing: this.isCapturing,
      config: { ...this.currentConfig }
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    this.logger.info('Releasing PhotoCaptureService resources...')

    try {
      this.isCapturing = false
      this.photoOutput = null
      this.setState(CaptureState.IDLE)

      this.logger.info('PhotoCaptureService resources released successfully')
    } catch (error) {
      this.logger.error('Failed to release PhotoCaptureService resources', error)
    }
  }
}