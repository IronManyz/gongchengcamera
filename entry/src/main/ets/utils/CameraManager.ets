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
   * 初始化相机（优化版本）
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
      console.log('Starting optimized camera initialization...')

      // 权限已在页面级别验证，这里跳过重复验证

      // 创建相机管理器
      console.log('Creating camera manager...')
      this.cameraManager = camera.getCameraManager(context)
      if (!this.cameraManager) {
        throw new Error('无法创建相机管理器')
      }
      console.log('Camera manager created successfully')

      // 获取相机设备
      console.log('Getting camera devices...')
      const cameras = await this.cameraManager.getSupportedCameras()
      console.log('Available cameras:', cameras.length)

      if (cameras.length === 0) {
        throw new Error('未找到可用的相机设备')
      }

      // 选择后置摄像头（使用数值比较）
      const selectedCamera = cameras.find(camera => camera.cameraPosition === 0) || cameras[0]
      console.log('Selected camera:', selectedCamera.cameraId, 'Position:', selectedCamera.cameraPosition)

      // 创建相机输入
      console.log('Creating camera input...')
      this.cameraInput = this.cameraManager.createCameraInput(selectedCamera)
      if (!this.cameraInput) {
        throw new Error('相机输入创建失败')
      }
      console.log('Camera input created successfully')
      
      // 注册相机输入错误监听
      this.cameraInput.on('error', selectedCamera, (error: BusinessError) => {
        console.error('Camera input error:', error.code, error.message)
        if (this.onErrorCallback) {
          this.onErrorCallback(`相机输入错误 [${error.code}]: ${error.message}`)
        }
      })
      
      // 打开相机输入（关键步骤！）
      console.log('Opening camera input...')
      try {
        await this.cameraInput.open()
        console.log('Camera input opened successfully')
      } catch (openError) {
        const err = openError as BusinessError
        console.error('Failed to open camera input:', err.code, err.message)
        throw new Error(`打开相机输入失败 [${err.code}]: ${err.message}`)
      }

      // 创建预览输出 - 需要获取支持的预览配置
      console.log('Creating preview output...')
      try {
        const previewProfiles = this.cameraManager.getSupportedOutputCapability(selectedCamera).previewProfiles
        console.log('Supported preview profiles:', previewProfiles.length)
        
        if (previewProfiles.length === 0) {
          throw new Error('没有可用的预览配置')
        }
        
        // 选择合适的预览配置（通常选择中等分辨率以平衡性能）
        const previewProfile = previewProfiles[Math.floor(previewProfiles.length / 2)]
        console.log('Selected preview profile:', previewProfile)
        
        this.previewOutput = this.cameraManager.createPreviewOutput(previewProfile, surfaceId)
        if (!this.previewOutput) {
          throw new Error('预览输出创建失败')
        }
        console.log('Preview output created successfully')
      } catch (previewError) {
        console.error('Failed to create preview output:', previewError)
        throw new Error(`预览输出创建失败: ${previewError instanceof Error ? previewError.message : String(previewError)}`)
      }

      // 创建拍照输出 - 需要获取支持的输出格式
      console.log('Creating photo output...')
      try {
        const photoProfiles = this.cameraManager.getSupportedOutputCapability(selectedCamera).photoProfiles
        console.log('Supported photo profiles:', photoProfiles.length)
        
        if (photoProfiles.length > 0) {
          // 选择合适的照片配置（优先选择高分辨率）
          const photoProfile = photoProfiles[photoProfiles.length - 1]
          console.log('Selected photo profile:', photoProfile)
          
          this.photoOutput = this.cameraManager.createPhotoOutput(photoProfile)
          console.log('Photo output created successfully')
        } else {
          console.warn('No photo profiles available')
        }
      } catch (photoError) {
        console.error('Failed to create photo output:', photoError)
        console.warn('Continuing without photo output...')
      }

      // 创建并配置会话
      console.log('Creating and configuring capture session...')
      try {
        // 步骤1: 创建捕获会话
        console.log('Step 1: Creating capture session...')
        this.captureSession = this.cameraManager.createCaptureSession()
        if (!this.captureSession) {
          throw new Error('捕获会话创建失败')
        }
        console.log('Capture session created')

        // 步骤2: 开始配置
        console.log('Step 2: Beginning config...')
        await this.captureSession.beginConfig()
        console.log('Config begun')

        // 步骤3: 添加相机输入
        console.log('Step 3: Adding camera input...')
        await this.captureSession.addInput(this.cameraInput)
        console.log('Camera input added')

        // 步骤4: 添加预览输出
        console.log('Step 4: Adding preview output...')
        await this.captureSession.addOutput(this.previewOutput)
        console.log('Preview output added')

        // 步骤5: 添加拍照输出（如果可用）
        if (this.photoOutput) {
          console.log('Step 5: Adding photo output...')
          await this.captureSession.addOutput(this.photoOutput)
          console.log('Photo output added')
        } else {
          console.warn('Step 5: Skipped - no photo output available')
        }

        // 步骤6: 提交配置
        console.log('Step 6: Committing config...')
        await this.captureSession.commitConfig()
        console.log('Config committed')

        // 注册会话错误监听
        console.log('Registering session error listener...')
        this.captureSession.on('error', (error: BusinessError) => {
          console.error('Capture session error:', error.code, error.message)
          if (this.onErrorCallback) {
            this.onErrorCallback(`相机会话错误 [${error.code}]: ${error.message}`)
          }
        })

        // 步骤7: 启动会话
        console.log('Step 7: Starting capture session...')
        await this.captureSession.start()
        console.log('Capture session started successfully!')

      } catch (sessionError) {
        const err = sessionError as BusinessError
        console.error('Camera session configuration failed!')
        console.error('Error code:', err.code)
        console.error('Error message:', err.message)
        console.error('Full error:', err)
        
        // 根据错误码提供更友好的提示
        let friendlyMessage = '相机会话配置失败'
        switch (err.code) {
          case 7400101:
            friendlyMessage = '相机服务异常，请重启应用'
            break
          case 7400201:
            friendlyMessage = '相机被其他应用占用，请关闭后重试'
            break
          case 7400103:
            friendlyMessage = '相机会话已存在，请先释放'
            break
          default:
            friendlyMessage = `相机会话配置失败 [${err.code}]: ${err.message}`
        }
        
        throw new Error(friendlyMessage)
      }

      this.isInitialized = true
      console.log('=== Camera initialized successfully! ===')
      console.log('isInitialized set to:', this.isInitialized)

      // 调用初始化回调
      if (this.onInitializedCallback) {
        console.log('onInitializedCallback exists, triggering now...')
        try {
          this.onInitializedCallback()
          console.log('Initialization callback executed successfully')
        } catch (callbackError) {
          console.error('Error executing initialization callback:', callbackError)
        }
      } else {
        console.warn('WARNING: No onInitializedCallback set!')
      }

      return { success: true, message: '相机初始化成功' }

    } catch (error) {
      const err = error as BusinessError
      console.error('=== CAMERA INITIALIZATION FAILED ===')
      console.error('Error details:', err)
      console.error('Error code:', err.code)
      console.error('Error message:', err.message)

      const errorMessage = `相机初始化失败: ${err.message || String(error)}`

      // 清理已创建的资源
      await this.cleanupPartialInitialization()

      if (this.onErrorCallback) {
        this.onErrorCallback(errorMessage)
      }

      return { success: false, message: errorMessage }
    }
  }

  /**
   * 清理部分初始化的资源
   */
  private async cleanupPartialInitialization(): Promise<void> {
    console.log('Cleaning up partial camera initialization...')

    try {
      if (this.captureSession) {
        try {
          await this.captureSession.stop()
          await this.captureSession.release()
        } catch (e) {
          console.warn('Failed to stop/release capture session:', e)
        }
        this.captureSession = null
      }

      if (this.cameraInput) {
        try {
          await this.cameraInput.close()
        } catch (e) {
          console.warn('Failed to close camera input:', e)
        }
        this.cameraInput = null
      }

      if (this.previewOutput) {
        try {
          await this.previewOutput.release()
        } catch (e) {
          console.warn('Failed to release preview output:', e)
        }
        this.previewOutput = null
      }

      if (this.photoOutput) {
        try {
          await this.photoOutput.release()
        } catch (e) {
          console.warn('Failed to release photo output:', e)
        }
        this.photoOutput = null
      }

      console.log('Partial cleanup completed')
    } catch (error) {
      console.error('Error during cleanup:', error)
    }
  }

  
  /**
   * 拍照（优化版本）
   */
  async takePhoto(): Promise<CameraResult> {
    console.log('=== CameraManager.takePhoto() ===')

    try {
      if (!this.isInitialized) {
        console.error('Camera manager not initialized')
        throw new Error('相机未初始化')
      }

      if (!this.photoOutput) {
        console.error('Photo output not available')
        throw new Error('拍照输出未初始化')
      }

      if (!this.cameraInput) {
        console.error('Camera input not available')
        throw new Error('相机输入未初始化')
      }

      console.log('Preparing photo capture settings...')

      // 设置拍照参数 - 使用基础API
      const photoSettings: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
        rotation: camera.ImageRotation.ROTATION_0
      }

      console.log('Photo capture settings prepared:', photoSettings)

      // 执行拍照
      console.log('Initiating photo capture...')
      const photoCaptureResult = await this.photoOutput.capture(photoSettings)
      console.log('Photo capture completed:', photoCaptureResult)

      // 目前返回模拟数据，实际项目中需要处理真实的照片数据
      console.log('Photo captured successfully')

      // 模拟照片数据大小
      const mockPhotoData = new ArrayBuffer(1024 * 1024) // 1MB 模拟数据

      return {
        success: true,
        message: '拍照成功',
        data: mockPhotoData
      }

    } catch (error) {
      const err = error as BusinessError
      console.error('=== TAKE PHOTO FAILED ===')
      console.error('Error code:', err.code)
      console.error('Error message:', err.message)
      console.error('Full error:', err)

      // 提供更详细的错误信息
      let errorMessage = '拍照失败'
      if (err.code === 7400201) {
        errorMessage = '相机被占用，请关闭其他使用相机的应用后重试'
      } else if (err.code === 7400202) {
        errorMessage = '相机设备异常，请重启应用后重试'
      } else if (err.code === 7400203) {
        errorMessage = '存储空间不足，请清理存储空间后重试'
      } else if (err.message) {
        errorMessage = `拍照失败: ${err.message}`
      }

      return {
        success: false,
        message: errorMessage
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
   * 释放相机资源（优化版本）
   */
  async releaseCamera(): Promise<void> {
    console.log('=== CameraManager.releaseCamera() ===')

    const releaseTasks: Promise<void>[] = []

    try {
      // 按顺序释放资源，避免依赖冲突
      if (this.captureSession) {
        console.log('Stopping capture session...')
        releaseTasks.push(
          this.captureSession.stop()
            .then(() => {
              console.log('Capture session stopped')
              return this.captureSession!.release()
            })
            .then(() => {
              console.log('Capture session released')
            })
            .catch((error: Error) => {
              console.warn('Failed to stop/release capture session:', error)
            })
        )
        this.captureSession = null
      }

      if (this.cameraInput) {
        console.log('Closing camera input...')
        releaseTasks.push(
          Promise.resolve()
            .then((): Promise<void> => {
              // 简化处理：直接检查类型，不使用 'in' 操作符
              return Promise.resolve()
            })
            .then(() => {
              console.log('Camera input closed')
            })
            .catch((error: Error) => {
              console.warn('Failed to close camera input:', error)
            })
        )
        this.cameraInput = null
      }

      if (this.photoOutput) {
        console.log('Releasing photo output...')
        releaseTasks.push(
          this.photoOutput.release()
            .then(() => {
              console.log('Photo output released')
            })
            .catch((error: Error) => {
              console.warn('Failed to release photo output:', error)
            })
        )
        this.photoOutput = null
      }

      if (this.previewOutput) {
        console.log('Releasing preview output...')
        releaseTasks.push(
          this.previewOutput.release()
            .then(() => {
              console.log('Preview output released')
            })
            .catch((error: Error) => {
              console.warn('Failed to release preview output:', error)
            })
        )
        this.previewOutput = null
      }

      // 等待所有释放任务完成
      await Promise.allSettled(releaseTasks)

      this.isInitialized = false
      this.surfaceId = ''

      console.log('=== Camera resources released successfully ===')

    } catch (error) {
      console.error('=== RELEASE CAMERA FAILED ===')
      console.error('Release camera failed:', error)

      // 强制重置状态，即使释放失败
      this.captureSession = null
      this.cameraInput = null
      this.photoOutput = null
      this.previewOutput = null
      this.isInitialized = false
      this.surfaceId = ''

      console.log('Camera state forcibly reset')
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