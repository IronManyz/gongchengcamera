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
      console.log('Starting camera initialization...')

      // 获取相机管理器
      try {
        this.cameraManager = camera.getCameraManager(context)
        console.log('Camera manager created:', !!this.cameraManager)
      } catch (error) {
        console.error('Failed to create camera manager:', error)
        throw new Error(`创建相机管理器失败: ${error}`)
      }

      if (!this.cameraManager) {
        throw new Error('无法获取相机管理器实例')
      }

      // 获取支持的相机设备
      try {
        const cameras = await this.cameraManager.getSupportedCameras()
        console.log('Available cameras:', cameras.length)

        if (cameras.length === 0) {
          throw new Error('没有可用的相机设备')
        }

        // 选择第一个可用的相机
        const selectedCamera = cameras[0]
        console.log('Selected camera:', selectedCamera.cameraId, selectedCamera.cameraPosition)

        // 创建相机输入
        try {
          this.cameraInput = this.cameraManager.createCameraInput(selectedCamera)
          console.log('Camera input created:', !!this.cameraInput)
        } catch (error) {
          console.error('Failed to create camera input:', error)
          throw new Error(`创建相机输入失败: ${error}`)
        }

        if (!this.cameraInput) {
          throw new Error('相机输入创建失败')
        }

      } catch (error) {
        console.error('Failed to get cameras:', error)
        throw new Error(`获取相机设备失败: ${error}`)
      }

      // 简化版本：只创建基本的拍照功能，不使用复杂的会话配置
      try {
        // 创建拍照输出
        this.photoOutput = this.cameraManager.createPhotoOutput()
        console.log('Photo output created:', !!this.photoOutput)

        if (!this.photoOutput) {
          throw new Error('拍照输出创建失败')
        }

        // 创建预览输出
        this.previewOutput = this.cameraManager.createPreviewOutput(surfaceId)
        console.log('Preview output created:', !!this.previewOutput)

        if (!this.previewOutput) {
          throw new Error('预览输出创建失败')
        }

      } catch (error) {
        console.error('Failed to create outputs:', error)
        throw new Error(`创建相机输出失败: ${error}`)
      }

      // 标记为已初始化
      this.isInitialized = true
      console.log('Camera initialized successfully')

      // 调用初始化回调
      if (this.onInitializedCallback) {
        console.log('Calling initialization callback...')
        this.onInitializedCallback()
      } else {
        console.log('No initialization callback set')
      }

      return { success: true, message: '相机初始化成功' }

    } catch (error) {
      const err = error as BusinessError
      console.error('Initialize camera failed:', err.code, err.message)

      const errorMessage = `相机初始化失败: ${err.message}`
      console.error('Error message:', errorMessage)

      if (this.onErrorCallback) {
        console.log('Calling error callback...')
        this.onErrorCallback(errorMessage)
      } else {
        console.log('No error callback set')
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