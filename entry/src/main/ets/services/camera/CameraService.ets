/**
 * 相机服务类
 * 提供相机初始化、配置、权限管理等基础功能
 */

import { camera } from '@kit.CameraKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Logger } from '../../utils/Logger'
import { PermissionUtils, PermissionType } from '../../utils/PermissionUtils'

/**
 * 相机状态枚举
 */
export enum CameraState {
  UNINITIALIZED = 'uninitialized',
  INITIALIZING = 'initializing',
  READY = 'ready',
  CAPTURING = 'capturing',
  ERROR = 'error'
}

/**
 * 相机位置枚举
 */
export enum CameraPosition {
  BACK = 'back',
  FRONT = 'front',
  EXTERNAL = 'external'
}

/**
 * 闪光灯模式枚举
 */
export enum FlashMode {
  OFF = 'off',
  ON = 'on',
  AUTO = 'auto',
  TORCH = 'torch'
}

/**
 * 相机配置接口
 */
export interface CameraConfig {
  position: CameraPosition
  flashMode: FlashMode
  resolution: {
    width: number
    height: number
  }
  frameRate: number
  autoFocus: boolean
  exposureCompensation: number
}

/**
 * 相机信息接口
 */
export interface CameraInfo {
  cameraId: string
  cameraPosition: CameraPosition
  cameraName: string
  capabilities: camera.CameraDeviceCapability[]
  supportedResolutions: Array<{ width: number, height: number }>
  supportedFrameRates: number[]
}

/**
 * 相机服务回调接口
 */
export interface CameraServiceCallbacks {
  onCameraReady?: (cameraInfo: CameraInfo) => void
  onCameraError?: (error: Error) => void
  onCameraDisconnected?: () => void
  onCaptureStart?: () => void
  onCaptureComplete?: (pixelMap: image.PixelMap) => void
  onCaptureError?: (error: Error) => void
}

/**
 * 相机服务类
 * 管理相机的生命周期、配置和操作
 */
export class CameraService {
  private static instance: CameraService | null = null
  private logger = new Logger('CameraService')
  private permissionUtils = PermissionUtils.getInstance()

  // 相机相关对象
  private cameraManager: camera.CameraManager | null = null
  private cameraDevice: camera.CameraDevice | null = null
  private captureSession: camera.CaptureSession | null = null
  private photoOutput: camera.PhotoOutput | null = null
  private previewOutput: camera.PreviewOutput | null = null

  // 状态管理
  private currentState: CameraState = CameraState.UNINITIALIZED
  private currentCameraInfo: CameraInfo | null = null
  private callbacks: CameraServiceCallbacks = {}

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): CameraService {
    if (!CameraService.instance) {
      CameraService.instance = new CameraService()
    }
    return CameraService.instance
  }

  /**
   * 初始化相机服务
   */
  async initialize(): Promise<void> {
    this.logger.info('Initializing CameraService...')

    if (this.currentState !== CameraState.UNINITIALIZED) {
      this.logger.warn('CameraService already initialized or in progress')
      return
    }

    this.setState(CameraState.INITIALIZING)

    try {
      // 1. 检查相机权限
      await this.checkCameraPermissions()

      // 2. 初始化相机管理器
      await this.initializeCameraManager()

      // 3. 获取可用相机设备
      const availableCameras = await this.getAvailableCameras()

      if (availableCameras.length === 0) {
        throw new Error('No available camera devices found')
      }

      // 4. 默认选择后置摄像头
      const backCamera = availableCameras.find(cam => cam.cameraPosition === CameraPosition.BACK) || availableCameras[0]
      await this.setupCamera(backCamera)

      this.setState(CameraState.READY)
      this.logger.info('CameraService initialized successfully')

    } catch (error) {
      this.setState(CameraState.ERROR)
      this.logger.error('Failed to initialize CameraService', error)
      this.notifyError(error instanceof Error ? error : new Error(String(error)))
      throw error
    }
  }

  /**
   * 检查相机权限
   */
  private async checkCameraPermissions(): Promise<void> {
    this.logger.info('Checking camera permissions...')

    const cameraPermission = await this.permissionUtils.checkPermission(PermissionType.READ_MEDIA)

    if (!cameraPermission.granted) {
      throw new Error('Camera permission not granted')
    }

    this.logger.info('Camera permissions check passed')
  }

  /**
   * 初始化相机管理器
   */
  private async initializeCameraManager(): Promise<void> {
    this.logger.info('Initializing camera manager...')

    try {
      this.cameraManager = camera.getCameraManager()

      if (!this.cameraManager) {
        throw new Error('Failed to get camera manager')
      }

      // 设置相机状态监听
      this.setupCameraStatusListeners()

      this.logger.info('Camera manager initialized successfully')
    } catch (error) {
      this.logger.error('Failed to initialize camera manager', error)
      throw error
    }
  }

  /**
   * 设置相机状态监听器
   */
  private setupCameraStatusListeners(): void {
    if (!this.cameraManager) {
      return
    }

    try {
      // 监听相机设备状态变化
      this.cameraManager.on('cameraStatus', (cameraStatusInfo: camera.CameraStatusInfo) => {
        this.logger.info('Camera status changed', cameraStatusInfo)

        if (cameraStatusInfo.status === camera.CameraStatus.UNAVAILABLE) {
          this.notifyDisconnected()
        }
      })

      this.logger.info('Camera status listeners setup completed')
    } catch (error) {
      this.logger.error('Failed to setup camera status listeners', error)
    }
  }

  /**
   * 获取可用相机设备列表
   */
  private async getAvailableCameras(): Promise<CameraInfo[]> {
    this.logger.info('Getting available cameras...')

    if (!this.cameraManager) {
      throw new Error('Camera manager not initialized')
    }

    try {
      const cameras = this.cameraManager.getSupportedCameras()
      const cameraInfos: CameraInfo[] = []

      for (const cameraDevice of cameras) {
        const cameraInfo: CameraInfo = {
          cameraId: cameraDevice.cameraId,
          cameraPosition: this.convertCameraPosition(cameraDevice.cameraPosition),
          cameraName: cameraDevice.cameraName || `Camera ${cameraDevice.cameraId}`,
          capabilities: cameraDevice.getCameraDeviceCapability(),
          supportedResolutions: this.getSupportedResolutions(cameraDevice),
          supportedFrameRates: this.getSupportedFrameRates(cameraDevice)
        }

        cameraInfos.push(cameraInfo)
        this.logger.info('Found camera', cameraInfo)
      }

      return cameraInfos
    } catch (error) {
      this.logger.error('Failed to get available cameras', error)
      throw error
    }
  }

  /**
   * 转换相机位置枚举
   */
  private convertCameraPosition(position: camera.CameraPosition): CameraPosition {
    switch (position) {
      case camera.CameraPosition.CAMERA_POSITION_BACK:
        return CameraPosition.BACK
      case camera.CameraPosition.CAMERA_POSITION_FRONT:
        return CameraPosition.FRONT
      case camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED:
        return CameraPosition.EXTERNAL
      default:
        return CameraPosition.BACK
    }
  }

  /**
   * 获取支持的分辨率
   */
  private getSupportedResolutions(cameraDevice: camera.CameraDevice): Array<{ width: number, height: number }> {
    const resolutions: Array<{ width: number, height: number }> = []

    try {
      const profiles = cameraDevice.getCameraDeviceCapability().profiles
      for (const profile of profiles) {
        if (profile.previewProfiles) {
          for (const previewProfile of profile.previewProfiles) {
            resolutions.push({
              width: previewProfile.width,
              height: previewProfile.height
            })
          }
        }
      }
    } catch (error) {
      this.logger.error('Failed to get supported resolutions', error)
    }

    return resolutions
  }

  /**
   * 获取支持的帧率
   */
  private getSupportedFrameRates(cameraDevice: camera.CameraDevice): number[] {
    const frameRates: number[] = []

    try {
      const profiles = cameraDevice.getCameraDeviceCapability().profiles
      for (const profile of profiles) {
        if (profile.previewProfiles) {
          for (const previewProfile of profile.previewProfiles) {
            if (previewProfile.defaultFrameRate) {
              frameRates.push(previewProfile.defaultFrameRate)
            }
          }
        }
      }
    } catch (error) {
      this.logger.error('Failed to get supported frame rates', error)
    }

    return [...new Set(frameRates)] // 去重
  }

  /**
   * 设置相机设备
   */
  private async setupCamera(cameraInfo: CameraInfo): Promise<void> {
    this.logger.info('Setting up camera', cameraInfo)

    if (!this.cameraManager) {
      throw new Error('Camera manager not initialized')
    }

    try {
      // 获取相机设备
      const cameras = this.cameraManager.getSupportedCameras()
      this.cameraDevice = cameras.find(cam => cam.cameraId === cameraInfo.cameraId) || null

      if (!this.cameraDevice) {
        throw new Error(`Camera device ${cameraInfo.cameraId} not found`)
      }

      this.currentCameraInfo = cameraInfo

      // 创建拍照会话
      await this.createCaptureSession()

      this.logger.info('Camera setup completed')
    } catch (error) {
      this.logger.error('Failed to setup camera', error)
      throw error
    }
  }

  /**
   * 创建拍照会话
   */
  private async createCaptureSession(): Promise<void> {
    this.logger.info('Creating capture session...')

    if (!this.cameraManager || !this.cameraDevice) {
      throw new Error('Camera manager or device not initialized')
    }

    try {
      // 创建拍照会话
      this.captureSession = this.cameraManager.createCaptureSession()

      // 开始配置会话
      this.captureSession.beginConfig()

      // 创建预览输出
      this.previewOutput = this.cameraManager.createPreviewOutput()

      // 创建拍照输出
      this.photoOutput = this.cameraManager.createPhotoOutput()

      // 添加输出到会话
      this.captureSession.addOutput(this.previewOutput)
      this.captureSession.addOutput(this.photoOutput)

      // 提交配置
      await this.captureSession.commitConfig()

      // 开始会话
      await this.captureSession.start()

      this.logger.info('Capture session created successfully')
    } catch (error) {
      this.logger.error('Failed to create capture session', error)
      throw error
    }
  }

  /**
   * 设置相机配置
   */
  async configureCamera(config: Partial<CameraConfig>): Promise<void> {
    this.logger.info('Configuring camera', config)

    if (this.currentState !== CameraState.READY) {
      throw new Error('Camera not ready for configuration')
    }

    if (!this.captureSession) {
      throw new Error('Capture session not initialized')
    }

    try {
      // 开始重新配置
      this.captureSession.beginConfig()

      // 应用配置
      if (config.flashMode !== undefined) {
        await this.setFlashMode(config.flashMode)
      }

      if (config.resolution !== undefined) {
        await this.setResolution(config.resolution)
      }

      if (config.frameRate !== undefined) {
        await this.setFrameRate(config.frameRate)
      }

      if (config.autoFocus !== undefined) {
        await this.setAutoFocus(config.autoFocus)
      }

      if (config.exposureCompensation !== undefined) {
        await this.setExposureCompensation(config.exposureCompensation)
      }

      // 提交配置
      await this.captureSession.commitConfig()

      this.logger.info('Camera configuration completed')
    } catch (error) {
      this.logger.error('Failed to configure camera', error)
      throw error
    }
  }

  /**
   * 设置闪光灯模式
   */
  private async setFlashMode(flashMode: FlashMode): Promise<void> {
    this.logger.info('Setting flash mode', { flashMode })

    if (!this.photoOutput) {
      return
    }

    try {
      const hasFlash = this.currentCameraInfo?.capabilities.some(cap =>
        cap.flashModes && cap.flashModes.length > 0
      ) || false

      if (!hasFlash && flashMode !== FlashMode.OFF) {
        this.logger.warn('Flash not supported on this camera')
        return
      }

      const cameraFlashMode = this.convertFlashMode(flashMode)
      this.photoOutput.setFlashMode(cameraFlashMode)
    } catch (error) {
      this.logger.error('Failed to set flash mode', error)
    }
  }

  /**
   * 转换闪光灯模式
   */
  private convertFlashMode(flashMode: FlashMode): camera.FlashMode {
    switch (flashMode) {
      case FlashMode.OFF:
        return camera.FlashMode.FLASH_MODE_OFF
      case FlashMode.ON:
        return camera.FlashMode.FLASH_MODE_ON
      case FlashMode.AUTO:
        return camera.FlashMode.FLASH_MODE_AUTO
      case FlashMode.TORCH:
        return camera.FlashMode.FLASH_MODE_ALWAYS_OPEN
      default:
        return camera.FlashMode.FLASH_MODE_OFF
    }
  }

  /**
   * 设置分辨率
   */
  private async setResolution(resolution: { width: number, height: number }): Promise<void> {
    this.logger.info('Setting resolution', resolution)

    // 在实际实现中，这里需要重新创建output配置
    // 由于当前API限制，这里只记录日志
    this.logger.info('Resolution configuration requires output recreation')
  }

  /**
   * 设置帧率
   */
  private async setFrameRate(frameRate: number): Promise<void> {
    this.logger.info('Setting frame rate', { frameRate })

    // 在实际实现中，这里需要重新配置session
    this.logger.info('Frame rate configuration requires session recreation')
  }

  /**
   * 设置自动对焦
   */
  private async setAutoFocus(autoFocus: boolean): Promise<void> {
    this.logger.info('Setting auto focus', { autoFocus })

    // 在实际实现中，这里需要配置对焦模式
    this.logger.info('Auto focus configuration requires specific focus mode setup')
  }

  /**
   * 设置曝光补偿
   */
  private async setExposureCompensation(exposureCompensation: number): Promise<void> {
    this.logger.info('Setting exposure compensation', { exposureCompensation })

    // 在实际实现中，这里需要配置曝光参数
    this.logger.info('Exposure compensation configuration requires specific parameter setup')
  }

  /**
   * 切换相机（前置/后置）
   */
  async switchCamera(position?: CameraPosition): Promise<void> {
    this.logger.info('Switching camera', { position })

    if (this.currentState === CameraState.CAPTURING) {
      throw new Error('Cannot switch camera during capture')
    }

    try {
      // 停止当前会话
      await this.stopCaptureSession()

      // 获取目标相机
      const availableCameras = await this.getAvailableCameras()
      const targetPosition = position ||
        (this.currentCameraInfo?.cameraPosition === CameraPosition.BACK ? CameraPosition.FRONT : CameraPosition.BACK)

      const targetCamera = availableCameras.find(cam => cam.cameraPosition === targetPosition)

      if (!targetCamera) {
        throw new Error(`Camera with position ${targetPosition} not found`)
      }

      // 重新设置相机
      await this.setupCamera(targetCamera)

      this.setState(CameraState.READY)
      this.logger.info('Camera switched successfully')
    } catch (error) {
      this.setState(CameraState.ERROR)
      this.logger.error('Failed to switch camera', error)
      throw error
    }
  }

  /**
   * 停止拍照会话
   */
  private async stopCaptureSession(): Promise<void> {
    this.logger.info('Stopping capture session...')

    if (this.captureSession) {
      try {
        await this.captureSession.stop()
        this.captureSession.release()
      } catch (error) {
        this.logger.error('Failed to stop capture session', error)
      }
    }

    this.captureSession = null
    this.photoOutput = null
    this.previewOutput = null
  }

  /**
   * 获取当前相机信息
   */
  getCurrentCameraInfo(): CameraInfo | null {
    return this.currentCameraInfo
  }

  /**
   * 获取相机状态
   */
  getState(): CameraState {
    return this.currentState
  }

  /**
   * 设置回调函数
   */
  setCallbacks(callbacks: CameraServiceCallbacks): void {
    this.callbacks = { ...this.callbacks, ...callbacks }
  }

  /**
   * 设置相机状态
   */
  private setState(state: CameraState): void {
    const oldState = this.currentState
    this.currentState = state
    this.logger.info('Camera state changed', { from: oldState, to: state })

    if (state === CameraState.READY && this.currentCameraInfo) {
      this.notifyReady(this.currentCameraInfo)
    }
  }

  /**
   * 通知相机就绪
   */
  private notifyReady(cameraInfo: CameraInfo): void {
    if (this.callbacks.onCameraReady) {
      try {
        this.callbacks.onCameraReady(cameraInfo)
      } catch (error) {
        this.logger.error('Error in onCameraReady callback', error)
      }
    }
  }

  /**
   * 通知相机错误
   */
  private notifyError(error: Error): void {
    if (this.callbacks.onCameraError) {
      try {
        this.callbacks.onCameraError(error)
      } catch (callbackError) {
        this.logger.error('Error in onCameraError callback', callbackError)
      }
    }
  }

  /**
   * 通知相机断开连接
   */
  private notifyDisconnected(): void {
    this.setState(CameraState.ERROR)

    if (this.callbacks.onCameraDisconnected) {
      try {
        this.callbacks.onCameraDisconnected()
      } catch (error) {
        this.logger.error('Error in onCameraDisconnected callback', error)
      }
    }
  }

  /**
   * 通知拍照开始
   */
  private notifyCaptureStart(): void {
    if (this.callbacks.onCaptureStart) {
      try {
        this.callbacks.onCaptureStart()
      } catch (error) {
        this.logger.error('Error in onCaptureStart callback', error)
      }
    }
  }

  /**
   * 通知拍照完成
   */
  private notifyCaptureComplete(pixelMap: image.PixelMap): void {
    if (this.callbacks.onCaptureComplete) {
      try {
        this.callbacks.onCaptureComplete(pixelMap)
      } catch (error) {
        this.logger.error('Error in onCaptureComplete callback', error)
      }
    }
  }

  /**
   * 通知拍照错误
   */
  private notifyCaptureError(error: Error): void {
    if (this.callbacks.onCaptureError) {
      try {
        this.callbacks.onCaptureError(error)
      } catch (callbackError) {
        this.logger.error('Error in onCaptureError callback', callbackError)
      }
    }
  }

  /**
   * 获取预览输出
   */
  getPreviewOutput(): camera.PreviewOutput | null {
    return this.previewOutput
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    this.logger.info('Releasing CameraService resources...')

    try {
      // 停止会话
      await this.stopCaptureSession()

      // 释放相机管理器
      if (this.cameraManager) {
        this.cameraManager.release()
        this.cameraManager = null
      }

      // 清理状态
      this.cameraDevice = null
      this.currentCameraInfo = null
      this.setState(CameraState.UNINITIALIZED)

      this.logger.info('CameraService resources released successfully')
    } catch (error) {
      this.logger.error('Failed to release CameraService resources', error)
    }
  }

  /**
   * 检查相机服务是否就绪
   */
  isReady(): boolean {
    return this.currentState === CameraState.READY
  }

  /**
   * 获取相机功能统计信息
   */
  getCameraStats(): {
    state: CameraState
    hasCamera: boolean
    currentCamera: CameraInfo | null
    hasPreviewOutput: boolean
    hasPhotoOutput: boolean
  } {
    return {
      state: this.currentState,
      hasCamera: this.cameraDevice !== null,
      currentCamera: this.currentCameraInfo,
      hasPreviewOutput: this.previewOutput !== null,
      hasPhotoOutput: this.photoOutput !== null
    }
  }
}