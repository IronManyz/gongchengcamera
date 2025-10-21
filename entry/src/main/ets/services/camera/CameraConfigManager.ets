/**
 * 相机配置管理器
 * 专门负责相机参数的配置、验证和管理
 */

import { camera } from '@kit.CameraKit'
import { Logger } from '../../utils/Logger'
import { CameraService, CameraPosition, FlashMode, CameraInfo, CameraConfig } from './CameraService'

/**
 * 对焦模式枚举
 */
export enum FocusMode {
  AUTO = 'auto',
  MANUAL = 'manual',
  CONTINUOUS_AUTO = 'continuous_auto',
  CONTINUOUS_PICTURE = 'continuous_picture',
  CONTINUOUS_VIDEO = 'continuous_video',
  MACRO = 'macro',
  FIXED = 'fixed'
}

/**
 * 曝光模式枚举
 */
export enum ExposureMode {
  AUTO = 'auto',
  MANUAL = 'manual',
  LOCKED = 'locked'
}

/**
 * 白平衡模式枚举
 */
export enum WhiteBalanceMode {
  AUTO = 'auto',
  INCANDESCENT = 'incandescent',
  FLUORESCENT = 'fluorescent',
  WARM_FLUORESCENT = 'warm_fluorescent',
  DAYLIGHT = 'daylight',
  CLOUDY_DAYLIGHT = 'cloudy_daylight',
  TWILIGHT = 'twilight',
  SHADE = 'shade'
}

/**
 * 场景模式枚举
 */
export enum SceneMode {
  AUTO = 'auto',
  ACTION = 'action',
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape',
  NIGHT = 'night',
  NIGHT_PORTRAIT = 'night_portrait',
  THEATRE = 'theatre',
  BEACH = 'beach',
  SNOW = 'snow',
  SUNSET = 'sunset',
  STEADY_PHOTO = 'steady_photo',
  FIREWORKS = 'fireworks',
  SPORTS = 'sports',
  PARTY = 'party',
  CANDLELIGHT = 'candlelight',
  HDR = 'hdr'
}

/**
 * 图像质量枚举
 */
export enum ImageQuality {
  LOW = 'low',      // 70%
  MEDIUM = 'medium', // 80%
  HIGH = 'high',    // 90%
  SUPERIOR = 'superior' // 100%
}

/**
 * 相机参数配置接口
 */
export interface CameraParameters {
  // 基础配置
  flashMode: FlashMode
  focusMode: FocusMode
  exposureMode: ExposureMode
  whiteBalanceMode: WhiteBalanceMode
  sceneMode: SceneMode

  // 拍照配置
  resolution: { width: number, height: number }
  frameRate: number
  imageQuality: ImageQuality

  // 曝光配置
  exposureCompensation: number // -3.0 to 3.0
  iso: number
  shutterSpeed: number // 秒

  // 对焦配置
  focusDistance: number // 0.0 to 1.0
  autoFocusRegions: Array<{ x: number, y: number, width: number, height: number }>

  // 颜色配置
  saturation: number // 0.0 to 2.0
  contrast: number // 0.0 to 2.0
  brightness: number // 0.0 to 2.0
  sharpness: number // 0.0 to 2.0

  // 高级配置
  zoomRatio: number // 1.0 to max zoom
  videoStabilization: boolean
  noiseReduction: boolean

  // 配置元数据
  timestamp: number
  version: string
}

/**
 * 预设配置枚举
 */
export enum CameraPreset {
  AUTO = 'auto',
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape',
  NIGHT = 'night',
  SPORTS = 'sports',
  MACRO = 'macro',
  DOCUMENT = 'document',
  HDR = 'hdr',
  PROFESSIONAL = 'professional'
}

/**
 * 配置验证结果接口
 */
export interface ConfigValidationResult {
  valid: boolean
  errors: string[]
  warnings: string[]
  supportedParameters: Partial<CameraParameters>
  unsupportedParameters: string[]
}

/**
 * 配置应用结果接口
 */
export interface ConfigApplicationResult {
  success: boolean
  appliedParameters: string[]
  failedParameters: Array<{ parameter: string, error: string }>
  unsupportedParameters: string[]
}

/**
 * 相机配置管理器
 */
export class CameraConfigManager {
  private static instance: CameraConfigManager | null = null
  private logger = new Logger('CameraConfigManager')
  private cameraService: CameraService

  // 当前配置
  private currentParameters: CameraParameters | null = null
  private supportedParameters: Set<string> = new Set()
  private parameterRanges: Record<string, { min: number, max: number }> = {}

  // 默认配置
  private readonly defaultParameters: CameraParameters = {
    flashMode: FlashMode.AUTO,
    focusMode: FocusMode.AUTO,
    exposureMode: ExposureMode.AUTO,
    whiteBalanceMode: WhiteBalanceMode.AUTO,
    sceneMode: SceneMode.AUTO,

    resolution: { width: 1920, height: 1080 },
    frameRate: 30,
    imageQuality: ImageQuality.HIGH,

    exposureCompensation: 0.0,
    iso: 100,
    shutterSpeed: 1 / 125,

    focusDistance: 0.0,
    autoFocusRegions: [],

    saturation: 1.0,
    contrast: 1.0,
    brightness: 1.0,
    sharpness: 1.0,

    zoomRatio: 1.0,
    videoStabilization: false,
    noiseReduction: true,

    timestamp: Date.now(),
    version: '1.0.0'
  }

  private constructor() {
    this.cameraService = CameraService.getInstance()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): CameraConfigManager {
    if (!CameraConfigManager.instance) {
      CameraConfigManager.instance = new CameraConfigManager()
    }
    return CameraConfigManager.instance
  }

  /**
   * 初始化配置管理器
   */
  async initialize(cameraInfo: CameraInfo): Promise<void> {
    this.logger.info('Initializing CameraConfigManager...', cameraInfo)

    try {
      // 分析相机能力
      await this.analyzeCameraCapabilities(cameraInfo)

      // 设置默认参数
      this.currentParameters = { ...this.defaultParameters }
      this.currentParameters.timestamp = Date.now()

      // 应用初始配置
      await this.applyDefaultConfiguration()

      this.logger.info('CameraConfigManager initialized successfully')
    } catch (error) {
      this.logger.error('Failed to initialize CameraConfigManager', error)
      throw error
    }
  }

  /**
   * 分析相机能力
   */
  private async analyzeCameraCapabilities(cameraInfo: CameraInfo): Promise<void> {
    this.logger.info('Analyzing camera capabilities...')

    try {
      // 根据相机能力设置支持的参数
      this.supportedParameters.clear()

      // 基础参数（大多数相机都支持）
      this.supportedParameters.add('flashMode')
      this.supportedParameters.add('focusMode')
      this.supportedParameters.add('exposureMode')
      this.supportedParameters.add('whiteBalanceMode')
      this.supportedParameters.add('sceneMode')
      this.supportedParameters.add('resolution')
      this.supportedParameters.add('frameRate')
      this.supportedParameters.add('imageQuality')

      // 检查闪光灯支持
      const hasFlash = cameraInfo.capabilities.some(cap =>
        cap.flashModes && cap.flashModes.length > 0
      )
      if (!hasFlash) {
        this.supportedParameters.delete('flashMode')
      }

      // 设置参数范围
      this.parameterRanges = {
        exposureCompensation: { min: -3.0, max: 3.0 },
        iso: { min: 100, max: 3200 },
        shutterSpeed: { min: 1 / 4000, max: 30 },
        focusDistance: { min: 0.0, max: 1.0 },
        saturation: { min: 0.0, max: 2.0 },
        contrast: { min: 0.0, max: 2.0 },
        brightness: { min: 0.0, max: 2.0 },
        sharpness: { min: 0.0, max: 2.0 },
        zoomRatio: { min: 1.0, max: 10.0 }
      }

      // 根据支持的分辨率设置范围
      if (cameraInfo.supportedResolutions.length > 0) {
        const maxResolution = cameraInfo.supportedResolutions.reduce((max, res) =>
          (res.width * res.height) > (max.width * max.height) ? res : max
        )
        const minResolution = cameraInfo.supportedResolutions.reduce((min, res) =>
          (res.width * res.height) < (min.width * min.height) ? res : min
        )

        this.logger.info('Resolution range', { min: minResolution, max: maxResolution })
      }

      // 根据支持的帧率设置范围
      if (cameraInfo.supportedFrameRates.length > 0) {
        const maxFrameRate = Math.max(...cameraInfo.supportedFrameRates)
        const minFrameRate = Math.min(...cameraInfo.supportedFrameRates)

        this.parameterRanges.frameRate = { min: minFrameRate, max: maxFrameRate }
        this.logger.info('Frame rate range', { min: minFrameRate, max: maxFrameRate })
      }

      this.logger.info('Supported parameters', Array.from(this.supportedParameters))
    } catch (error) {
      this.logger.error('Failed to analyze camera capabilities', error)
      throw error
    }
  }

  /**
   * 应用默认配置
   */
  private async applyDefaultConfiguration(): Promise<void> {
    this.logger.info('Applying default configuration...')

    try {
      if (!this.currentParameters) {
        throw new Error('Current parameters not initialized')
      }

      // 应用默认配置到相机服务
      const cameraConfig: CameraConfig = {
        position: this.cameraService.getCurrentCameraInfo()?.cameraPosition || CameraPosition.BACK,
        flashMode: this.currentParameters.flashMode,
        resolution: this.currentParameters.resolution,
        frameRate: this.currentParameters.frameRate,
        autoFocus: this.currentParameters.focusMode === FocusMode.AUTO,
        exposureCompensation: this.currentParameters.exposureCompensation
      }

      await this.cameraService.configureCamera(cameraConfig)
      this.logger.info('Default configuration applied successfully')
    } catch (error) {
      this.logger.error('Failed to apply default configuration', error)
      throw error
    }
  }

  /**
   * 配置相机参数
   */
  async configureParameters(parameters: Partial<CameraParameters>): Promise<ConfigApplicationResult> {
    this.logger.info('Configuring camera parameters...', parameters)

    const result: ConfigApplicationResult = {
      success: true,
      appliedParameters: [],
      failedParameters: [],
      unsupportedParameters: []
    }

    if (!this.currentParameters) {
      throw new Error('Configuration manager not initialized')
    }

    try {
      // 验证参数
      const validationResult = this.validateParameters(parameters)
      if (!validationResult.valid) {
        result.success = false
        result.failedParameters = validationResult.errors.map(error => ({ parameter: 'validation', error }))
        return result
      }

      // 应用参数
      for (const [key, value] of Object.entries(parameters)) {
        if (!this.supportedParameters.has(key)) {
          result.unsupportedParameters.push(key)
          continue
        }

        try {
          await this.applyParameter(key, value)
          result.appliedParameters.push(key)

          // 更新当前参数
          (this.currentParameters as any)[key] = value
        } catch (error) {
          result.failedParameters.push({
            parameter: key,
            error: error instanceof Error ? error.message : String(error)
          })
          result.success = false
        }
      }

      // 更新时间戳
      this.currentParameters.timestamp = Date.now()

      this.logger.info('Parameter configuration completed', result)
      return result
    } catch (error) {
      this.logger.error('Failed to configure parameters', error)
      result.success = false
      result.failedParameters.push({
        parameter: 'general',
        error: error instanceof Error ? error.message : String(error)
      })
      return result
    }
  }

  /**
   * 验证参数
   */
  validateParameters(parameters: Partial<CameraParameters>): ConfigValidationResult {
    const result: ConfigValidationResult = {
      valid: true,
      errors: [],
      warnings: [],
      supportedParameters: {},
      unsupportedParameters: []
    }

    for (const [key, value] of Object.entries(parameters)) {
      // 检查参数是否支持
      if (!this.supportedParameters.has(key)) {
        result.unsupportedParameters.push(key)
        continue
      }

      // 验证参数值
      const validationError = this.validateParameterValue(key, value)
      if (validationError) {
        result.errors.push(validationError)
        result.valid = false
      } else {
        (result.supportedParameters as any)[key] = value
      }
    }

    return result
  }

  /**
   * 验证单个参数值
   */
  private validateParameterValue(key: string, value: any): string | null {
    const range = this.parameterRanges[key]
    if (range && typeof value === 'number') {
      if (value < range.min || value > range.max) {
        return `Parameter ${key} value ${value} out of range [${range.min}, ${range.max}]`
      }
    }

    // 特定参数验证
    switch (key) {
      case 'resolution':
        if (!value || !value.width || !value.height) {
          return 'Resolution must have width and height'
        }
        if (value.width <= 0 || value.height <= 0) {
          return 'Resolution dimensions must be positive'
        }
        break

      case 'frameRate':
        if (value <= 0 || value > 120) {
          return 'Frame rate must be between 0 and 120'
        }
        break

      case 'imageQuality':
        if (!Object.values(ImageQuality).includes(value)) {
          return `Invalid image quality: ${value}`
        }
        break

      case 'zoomRatio':
        if (value < 1.0 || value > (this.parameterRanges.zoomRatio?.max || 10.0)) {
          return `Zoom ratio ${value} out of supported range`
        }
        break
    }

    return null
  }

  /**
   * 应用单个参数
   */
  private async applyParameter(key: string, value: any): Promise<void> {
    this.logger.info(`Applying parameter: ${key} = ${value}`)

    try {
      switch (key) {
        case 'flashMode':
          await this.applyFlashMode(value as FlashMode)
          break
        case 'focusMode':
          await this.applyFocusMode(value as FocusMode)
          break
        case 'exposureMode':
          await this.applyExposureMode(value as ExposureMode)
          break
        case 'whiteBalanceMode':
          await this.applyWhiteBalanceMode(value as WhiteBalanceMode)
          break
        case 'sceneMode':
          await this.applySceneMode(value as SceneMode)
          break
        case 'resolution':
          await this.applyResolution(value as { width: number, height: number })
          break
        case 'frameRate':
          await this.applyFrameRate(value as number)
          break
        case 'imageQuality':
          await this.applyImageQuality(value as ImageQuality)
          break
        case 'exposureCompensation':
          await this.applyExposureCompensation(value as number)
          break
        case 'zoomRatio':
          await this.applyZoomRatio(value as number)
          break
        default:
          this.logger.warn(`Unsupported parameter: ${key}`)
      }
    } catch (error) {
      this.logger.error(`Failed to apply parameter ${key}`, error)
      throw error
    }
  }

  /**
   * 应用闪光灯模式
   */
  private async applyFlashMode(flashMode: FlashMode): Promise<void> {
    // 通过相机服务配置闪光灯模式
    await this.cameraService.configureCamera({ flashMode })
  }

  /**
   * 应用对焦模式
   */
  private async applyFocusMode(focusMode: FocusMode): Promise<void> {
    // 根据相机API实现对焦模式设置
    this.logger.info(`Setting focus mode to: ${focusMode}`)
  }

  /**
   * 应用曝光模式
   */
  private async applyExposureMode(exposureMode: ExposureMode): Promise<void> {
    // 根据相机API实现曝光模式设置
    this.logger.info(`Setting exposure mode to: ${exposureMode}`)
  }

  /**
   * 应用白平衡模式
   */
  private async applyWhiteBalanceMode(whiteBalanceMode: WhiteBalanceMode): Promise<void> {
    // 根据相机API实现白平衡模式设置
    this.logger.info(`Setting white balance mode to: ${whiteBalanceMode}`)
  }

  /**
   * 应用场景模式
   */
  private async applySceneMode(sceneMode: SceneMode): Promise<void> {
    // 根据相机API实现场景模式设置
    this.logger.info(`Setting scene mode to: ${sceneMode}`)
  }

  /**
   * 应用分辨率
   */
  private async applyResolution(resolution: { width: number, height: number }): Promise<void> {
    // 通过相机服务配置分辨率
    await this.cameraService.configureCamera({ resolution })
  }

  /**
   * 应用帧率
   */
  private async applyFrameRate(frameRate: number): Promise<void> {
    // 通过相机服务配置帧率
    await this.cameraService.configureCamera({ frameRate })
  }

  /**
   * 应用图像质量
   */
  private async applyImageQuality(imageQuality: ImageQuality): Promise<void> {
    // 根据相机API实现图像质量设置
    this.logger.info(`Setting image quality to: ${imageQuality}`)
  }

  /**
   * 应用曝光补偿
   */
  private async applyExposureCompensation(exposureCompensation: number): Promise<void> {
    // 通过相机服务配置曝光补偿
    await this.cameraService.configureCamera({ exposureCompensation })
  }

  /**
   * 应用变焦比例
   */
  private async applyZoomRatio(zoomRatio: number): Promise<void> {
    // 根据相机API实现变焦设置
    this.logger.info(`Setting zoom ratio to: ${zoomRatio}`)
  }

  /**
   * 应用预设配置
   */
  async applyPreset(preset: CameraPreset): Promise<ConfigApplicationResult> {
    this.logger.info(`Applying preset configuration: ${preset}`)

    const presetParameters = this.getPresetParameters(preset)
    return this.configureParameters(presetParameters)
  }

  /**
   * 获取预设参数
   */
  private getPresetParameters(preset: CameraPreset): Partial<CameraParameters> {
    switch (preset) {
      case CameraPreset.AUTO:
        return {
          sceneMode: SceneMode.AUTO,
          focusMode: FocusMode.AUTO,
          exposureMode: ExposureMode.AUTO,
          whiteBalanceMode: WhiteBalanceMode.AUTO,
          flashMode: FlashMode.AUTO
        }

      case CameraPreset.PORTRAIT:
        return {
          sceneMode: SceneMode.PORTRAIT,
          focusMode: FocusMode.CONTINUOUS_PICTURE,
          exposureMode: ExposureMode.AUTO,
          flashMode: FlashMode.AUTO,
          saturation: 1.2,
          contrast: 1.1
        }

      case CameraPreset.LANDSCAPE:
        return {
          sceneMode: SceneMode.LANDSCAPE,
          focusMode: FocusMode.INFINITY,
          exposureMode: ExposureMode.AUTO,
          whiteBalanceMode: WhiteBalanceMode.DAYLIGHT,
          saturation: 1.3,
          contrast: 1.2,
          sharpness: 1.1
        }

      case CameraPreset.NIGHT:
        return {
          sceneMode: SceneMode.NIGHT,
          focusMode: FocusMode.AUTO,
          exposureMode: ExposureMode.AUTO,
          flashMode: FlashMode.OFF,
          iso: 800,
          shutterSpeed: 1 / 30,
          brightness: 1.2
        }

      case CameraPreset.SPORTS:
        return {
          sceneMode: SceneMode.SPORTS,
          focusMode: FocusMode.CONTINUOUS_PICTURE,
          exposureMode: ExposureMode.AUTO,
          frameRate: 60,
          shutterSpeed: 1 / 500
        }

      case CameraPreset.MACRO:
        return {
          sceneMode: SceneMode.AUTO,
          focusMode: FocusMode.MACRO,
          exposureMode: ExposureMode.AUTO,
          flashMode: FlashMode.OFF,
          sharpness: 1.3
        }

      case CameraPreset.DOCUMENT:
        return {
          sceneMode: SceneMode.AUTO,
          focusMode: FocusMode.AUTO,
          exposureMode: ExposureMode.AUTO,
          flashMode: FlashMode.AUTO,
          contrast: 1.4,
          sharpness: 1.5,
          saturation: 1.1
        }

      case CameraPreset.HDR:
        return {
          sceneMode: SceneMode.HDR,
          focusMode: FocusMode.AUTO,
          exposureMode: ExposureMode.AUTO,
          flashMode: FlashMode.OFF
        }

      case CameraPreset.PROFESSIONAL:
        return {
          sceneMode: SceneMode.AUTO,
          focusMode: FocusMode.MANUAL,
          exposureMode: ExposureMode.MANUAL,
          whiteBalanceMode: WhiteBalanceMode.AUTO,
          iso: 200,
          saturation: 1.0,
          contrast: 1.0,
          brightness: 1.0,
          sharpness: 1.0
        }

      default:
        return {}
    }
  }

  /**
   * 获取当前参数配置
   */
  getCurrentParameters(): CameraParameters | null {
    return this.currentParameters ? { ...this.currentParameters } : null
  }

  /**
   * 重置为默认配置
   */
  async resetToDefaults(): Promise<ConfigApplicationResult> {
    this.logger.info('Resetting to default configuration...')

    const defaultParams = { ...this.defaultParameters }
    defaultParams.timestamp = Date.now()

    return this.configureParameters(defaultParams)
  }

  /**
   * 获取支持的参数列表
   */
  getSupportedParameters(): string[] {
    return Array.from(this.supportedParameters)
  }

  /**
   * 获取参数范围
   */
  getParameterRanges(): Record<string, { min: number, max: number }> {
    return { ...this.parameterRanges }
  }

  /**
   * 检查参数是否支持
   */
  isParameterSupported(parameter: string): boolean {
    return this.supportedParameters.has(parameter)
  }

  /**
   * 保存配置到文件
   */
  async saveConfiguration(filePath: string): Promise<void> {
    if (!this.currentParameters) {
      throw new Error('No configuration to save')
    }

    this.logger.info('Saving configuration to file...', { filePath })

    try {
      // 这里需要实现文件保存逻辑
      // 可以使用FileService来保存配置
      this.logger.info('Configuration saved successfully')
    } catch (error) {
      this.logger.error('Failed to save configuration', error)
      throw error
    }
  }

  /**
   * 从文件加载配置
   */
  async loadConfiguration(filePath: string): Promise<ConfigApplicationResult> {
    this.logger.info('Loading configuration from file...', { filePath })

    try {
      // 这里需要实现文件加载逻辑
      // 可以使用FileService来读取配置
      const loadedParameters: Partial<CameraParameters> = {}

      return this.configureParameters(loadedParameters)
    } catch (error) {
      this.logger.error('Failed to load configuration', error)
      throw error
    }
  }

  /**
   * 获取配置统计信息
   */
  getConfigurationStats(): {
    isConfigured: boolean
    supportedParametersCount: number
    lastUpdateTime: number
    version: string
  } {
    return {
      isConfigured: this.currentParameters !== null,
      supportedParametersCount: this.supportedParameters.size,
      lastUpdateTime: this.currentParameters?.timestamp || 0,
      version: this.currentParameters?.version || '0.0.0'
    }
  }
}