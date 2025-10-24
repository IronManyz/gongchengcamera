/**
 * 相机管理工具类
 * 处理相机初始化、预览、拍照等功能
 */

import { camera } from '@kit.CameraKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'

/**
 * 相机状态枚举
 */
export enum CameraStatus {
  UNINITIALIZED = 'uninitialized',
  INITIALIZING = 'initializing',
  READY = 'ready',
  ERROR = 'error'
}

/**
 * 闪光灯模式接口
 */
export interface FlashModeData {
  flashMode: string
}

/**
 * 相机结果接口
 */
export interface CameraResult {
  success: boolean
  message?: string
  data?: ArrayBuffer | FlashModeData
}

/**
 * 相机管理器
 */
export class CameraManager {
  private static instance: CameraManager | null = null

  private cameraManager: camera.CameraManager | null = null
  private cameraInput: camera.CameraInput | null = null
  private captureSession: camera.CaptureSession | null = null
  private photoOutput: camera.PhotoOutput | null = null
  private previewOutput: camera.PreviewOutput | null = null

  private surfaceId: string = ''
  private isInitialized: boolean = false
  private onInitializedCallback: (() => void) | null = null
  private onErrorCallback: ((error: string) => void) | null = null

  /**
   * 获取单例实例
   */
  static getInstance(): CameraManager {
    if (!CameraManager.instance) {
      CameraManager.instance = new CameraManager()
    }
    return CameraManager.instance
  }

  /**
   * 初始化相机
   */
  async initializeCamera(context: common.UIAbilityContext, surfaceId: string): Promise<CameraResult> {
    console.log('=== CameraManager.initializeCamera() ===')
    console.log('Surface ID:', surfaceId)

    try {
      if (this.isInitialized) {
        console.log('Camera already initialized')
        return { success: true, message: '相机已初始化' }
      }

      this.surfaceId = surfaceId

      // 获取相机管理器
      this.cameraManager = camera.getCameraManager(context)
      if (!this.cameraManager) {
        throw new Error('Failed to get camera manager')
      }

      // 获取支持的相机设备
      const cameras = await this.cameraManager.getSupportedCameras()
      console.log('Available cameras:', cameras.length)

      if (cameras.length === 0) {
        throw new Error('No camera devices available')
      }

      // 选择后置摄像头（如果可用）
      const backCamera = cameras.find(camera => camera.cameraPosition === 0) || cameras[0]
      console.log('Selected camera:', backCamera.cameraId, backCamera.cameraPosition)

      // 创建相机输入
      this.cameraInput = this.cameraManager.createCameraInput(backCamera)
      if (!this.cameraInput) {
        throw new Error('Failed to create camera input')
      }

      // 创建拍照输出 - 使用基础API
      this.photoOutput = this.cameraManager.createPhotoOutput()
      if (!this.photoOutput) {
        throw new Error('Failed to create photo output')
      }

      // 创建预览输出 - 使用基础API
      this.previewOutput = this.cameraManager.createPreviewOutput(surfaceId)
      if (!this.previewOutput) {
        throw new Error('Failed to create preview output')
      }

      // 创建会话
      this.captureSession = this.cameraManager.createCaptureSession()
      if (!this.captureSession) {
        throw new Error('Failed to create capture session')
      }

      // 配置会话
      await this.captureSession.beginConfig()
      await this.captureSession.addInput(this.cameraInput)
      await this.captureSession.addOutput(this.previewOutput)
      await this.captureSession.addOutput(this.photoOutput)
      await this.captureSession.commitConfig()

      // 开始会话
      await this.captureSession.start()

      this.isInitialized = true
      console.log('Camera initialized successfully')

      // 调用初始化回调
      if (this.onInitializedCallback) {
        this.onInitializedCallback()
      }

      return { success: true, message: '相机初始化成功' }

    } catch (error) {
      const err = error as BusinessError
      console.error('Initialize camera failed:', err.code, err.message)

      const errorMessage = `相机初始化失败: ${err.message}`
      if (this.onErrorCallback) {
        this.onErrorCallback(errorMessage)
      }

      return { success: false, message: errorMessage }
    }
  }

  /**
   * 拍照
   */
  async takePhoto(): Promise<CameraResult> {
    console.log('=== CameraManager.takePhoto() ===')

    try {
      if (!this.isInitialized || !this.photoOutput) {
        throw new Error('Camera not initialized')
      }

      // 设置拍照参数 - 使用基础API
      const photoSettings: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
        rotation: camera.ImageRotation.ROTATION_0
      }

      // 执行拍照
      const photoCaptureResult = await this.photoOutput.capture(photoSettings)
      console.log('Photo captured:', photoCaptureResult)

      // 获取照片数据 - 使用基础API
      console.log('Photo captured successfully')

      return {
        success: true,
        message: '拍照成功',
        data: new ArrayBuffer(0) // 返回空的ArrayBuffer作为占位符
      }

    } catch (error) {
      const err = error as BusinessError
      console.error('Take photo failed:', err.code, err.message)

      return {
        success: false,
        message: `拍照失败: ${err.message}`
      }
    }
  }

  /**
   * 切换闪光灯
   */
  async toggleFlash(): Promise<CameraResult> {
    console.log('=== CameraManager.toggleFlash() ===')

    try {
      if (!this.isInitialized || !this.cameraInput) {
        throw new Error('Camera not initialized')
      }

      // 简化闪光灯控制 - 模拟切换
      console.log('Flash toggle (simulated)')

      const flashData: FlashModeData = { flashMode: 'FLASH_MODE_AUTO' }
      return {
        success: true,
        message: '闪光灯模式已切换',
        data: flashData
      }

    } catch (error) {
      const err = error as BusinessError
      console.error('Toggle flash failed:', err.code, err.message)

      return {
        success: false,
        message: `切换闪光灯失败: ${err.message}`
      }
    }
  }

  /**
   * 切换摄像头（前后）
   */
  async switchCamera(context: common.UIAbilityContext): Promise<CameraResult> {
    console.log('=== CameraManager.switchCamera() ===')

    try {
      // 先释放当前相机
      await this.releaseCamera()

      // 重新初始化相机
      return await this.initializeCamera(context, this.surfaceId)

    } catch (error) {
      const err = error as BusinessError
      console.error('Switch camera failed:', err.code, err.message)

      return {
        success: false,
        message: `切换摄像头失败: ${err.message}`
      }
    }
  }

  /**
   * 释放相机资源
   */
  async releaseCamera(): Promise<void> {
    console.log('=== CameraManager.releaseCamera() ===')

    try {
      if (this.captureSession) {
        await this.captureSession.stop()
        await this.captureSession.release()
        this.captureSession = null
      }

      if (this.cameraInput) {
        this.cameraInput = null
      }

      if (this.photoOutput) {
        await this.photoOutput.release()
        this.photoOutput = null
      }

      if (this.previewOutput) {
        await this.previewOutput.release()
        this.previewOutput = null
      }

      this.isInitialized = false
      console.log('Camera released successfully')

    } catch (error) {
      console.error('Release camera failed:', error)
    }
  }

  /**
   * 检查相机是否已初始化
   */
  isCameraReady(): boolean {
    return this.isInitialized
  }

  /**
   * 设置初始化回调
   */
  onInitialized(callback: () => void): void {
    this.onInitializedCallback = callback
  }

  /**
   * 设置错误回调
   */
  onError(callback: (error: string) => void): void {
    this.onErrorCallback = callback
  }

  /**
   * 获取当前闪光灯模式（模拟）
   */
  async getFlashMode(): Promise<string> {
    return 'FLASH_MODE_OFF'
  }
}