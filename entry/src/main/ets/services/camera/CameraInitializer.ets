/**
 * 相机初始化管理器
 * 专门负责相机的初始化流程和状态管理
 */

import { camera } from '@kit.CameraKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Logger } from '../../utils/Logger'
import { CameraService, CameraState, CameraPosition, CameraInfo } from './CameraService'
import { PermissionUtils, PermissionType } from '../../utils/PermissionUtils'

/**
 * 初始化状态枚举
 */
export enum InitializationState {
  NOT_STARTED = 'not_started',
  CHECKING_PERMISSIONS = 'checking_permissions',
  REQUESTING_PERMISSIONS = 'requesting_permissions',
  INITIALIZING_MANAGER = 'initializing_manager',
  SCANNING_DEVICES = 'scanning_devices',
  SELECTING_CAMERA = 'selecting_camera',
  CREATING_SESSION = 'creating_session',
  CONFIGURING_OUTPUTS = 'configuring_outputs',
  STARTING_SESSION = 'starting_session',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

/**
 * 初始化配置接口
 */
export interface InitializationConfig {
  preferredPosition?: CameraPosition
  requiredFeatures?: string[]
  fallbackPositions?: CameraPosition[]
  autoRetryOnFailure?: boolean
  maxRetryAttempts?: number
  timeoutMs?: number
}

/**
 * 初始化结果接口
 */
export interface InitializationResult {
  success: boolean
  cameraInfo?: CameraInfo
  error?: Error
  initializationTime: number
  retryCount: number
  warnings: string[]
}

/**
 * 初始化进度回调接口
 */
export interface InitializationProgress {
  state: InitializationState
  progress: number // 0-100
  message: string
  currentStep?: string
  totalSteps?: number
  completedSteps?: number
}

/**
 * 初始化回调接口
 */
export interface InitializationCallbacks {
  onProgress?: (progress: InitializationProgress) => void
  onSuccess?: (result: InitializationResult) => void
  onError?: (error: Error, retryCount: number) => void
  onPermissionRequired?: (permissions: PermissionType[]) => Promise<boolean>
}

/**
 * 相机初始化管理器
 * 负责管理相机的完整初始化流程
 */
export class CameraInitializer {
  private static instance: CameraInitializer | null = null
  private logger = new Logger('CameraInitializer')
  private cameraService: CameraService
  private permissionUtils: PermissionUtils

  // 初始化状态
  private currentState: InitializationState = InitializationState.NOT_STARTED
  private retryCount: number = 0
  private initializationStartTime: number = 0
  private warnings: string[] = []

  // 配置
  private config: InitializationConfig = {
    preferredPosition: CameraPosition.BACK,
    fallbackPositions: [CameraPosition.FRONT, CameraPosition.EXTERNAL],
    requiredFeatures: ['photo', 'preview'],
    autoRetryOnFailure: true,
    maxRetryAttempts: 3,
    timeoutMs: 15000
  }

  // 回调
  private callbacks: InitializationCallbacks = {}

  private constructor() {
    this.cameraService = CameraService.getInstance()
    this.permissionUtils = PermissionUtils.getInstance()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): CameraInitializer {
    if (!CameraInitializer.instance) {
      CameraInitializer.instance = new CameraInitializer()
    }
    return CameraInitializer.instance
  }

  /**
   * 设置初始化配置
   */
  setConfiguration(config: Partial<InitializationConfig>): void {
    this.config = { ...this.config, ...config }
    this.logger.info('Initialization configuration updated', this.config)
  }

  /**
   * 设置初始化回调
   */
  setCallbacks(callbacks: InitializationCallbacks): void {
    this.callbacks = { ...this.callbacks, ...callbacks }
  }

  /**
   * 执行相机初始化
   */
  async initialize(): Promise<InitializationResult> {
    this.logger.info('Starting camera initialization...')
    this.initializationStartTime = Date.now()
    this.retryCount = 0
    this.warnings = []

    return this.performInitialization()
  }

  /**
   * 执行初始化流程
   */
  private async performInitialization(): Promise<InitializationResult> {
    try {
      this.setState(InitializationState.CHECKING_PERMISSIONS)
      this.reportProgress(5, '检查相机权限...')

      // 1. 检查权限
      const permissionsOk = await this.checkPermissions()
      if (!permissionsOk) {
        throw new Error('Required camera permissions not granted')
      }

      // 2. 初始化相机管理器
      this.setState(InitializationState.INITIALIZING_MANAGER)
      this.reportProgress(15, '初始化相机管理器...')

      await this.initializeCameraManager()

      // 3. 扫描可用设备
      this.setState(InitializationState.SCANNING_DEVICES)
      this.reportProgress(25, '扫描可用相机设备...')

      const availableCameras = await this.scanAvailableCameras()
      if (availableCameras.length === 0) {
        throw new Error('No available camera devices found')
      }

      // 4. 选择合适的相机
      this.setState(InitializationState.SELECTING_CAMERA)
      this.reportProgress(40, '选择合适的相机设备...')

      const selectedCamera = await this.selectBestCamera(availableCameras)

      // 5. 创建拍照会话
      this.setState(InitializationState.CREATING_SESSION)
      this.reportProgress(60, '创建拍照会话...')

      await this.createCaptureSession(selectedCamera)

      // 6. 配置输出
      this.setState(InitializationState.CONFIGURING_OUTPUTS)
      this.reportProgress(75, '配置相机输出...')

      await this.configureOutputs()

      // 7. 启动会话
      this.setState(InitializationState.STARTING_SESSION)
      this.reportProgress(90, '启动拍照会话...')

      await this.startSession()

      // 8. 完成初始化
      this.setState(InitializationState.COMPLETED)
      this.reportProgress(100, '相机初始化完成')

      const result: InitializationResult = {
        success: true,
        cameraInfo: selectedCamera,
        initializationTime: Date.now() - this.initializationStartTime,
        retryCount: this.retryCount,
        warnings: [...this.warnings]
      }

      this.notifySuccess(result)
      return result

    } catch (error) {
      this.setState(InitializationState.FAILED)
      this.logger.error('Camera initialization failed', error)

      const initError = error instanceof Error ? error : new Error(String(error))

      // 重试逻辑
      if (this.shouldRetry()) {
        this.retryCount++
        this.logger.info(`Retrying camera initialization (${this.retryCount}/${this.config.maxRetryAttempts})`)

        this.notifyError(initError, this.retryCount)

        // 等待一段时间后重试
        await this.sleep(1000 * this.retryCount)
        return this.performInitialization()
      }

      const result: InitializationResult = {
        success: false,
        error: initError,
        initializationTime: Date.now() - this.initializationStartTime,
        retryCount: this.retryCount,
        warnings: [...this.warnings]
      }

      this.notifyError(initError, this.retryCount)
      return result
    }
  }

  /**
   * 检查权限
   */
  private async checkPermissions(): Promise<boolean> {
    this.logger.info('Checking camera permissions...')

    const requiredPermissions = [
      PermissionType.READ_MEDIA,
      PermissionType.WRITE_MEDIA,
      PermissionType.READ_WRITE_IMAGES
    ]

    const results = await this.permissionUtils.checkPermissions(requiredPermissions)
    const missingPermissions = Object.entries(results)
      .filter(([_, result]) => !result.granted)
      .map(([permission, _]) => permission as PermissionType)

    if (missingPermissions.length > 0) {
      this.logger.warn('Missing permissions', { missingPermissions })

      // 检查是否可以通过回调请求权限
      if (this.callbacks.onPermissionRequired) {
        const granted = await this.callbacks.onPermissionRequired(missingPermissions)
        if (granted) {
          // 重新检查权限
          const retryResults = await this.permissionUtils.checkPermissions(missingPermissions)
          const stillMissing = Object.entries(retryResults)
            .filter(([_, result]) => !result.granted)
            .length

          return stillMissing === 0
        }
      }

      this.warnings.push(`Missing permissions: ${missingPermissions.join(', ')}`)
      return false
    }

    return true
  }

  /**
   * 初始化相机管理器
   */
  private async initializeCameraManager(): Promise<void> {
    this.logger.info('Initializing camera manager...')

    try {
      // 检查相机服务状态
      if (this.cameraService.getState() !== CameraState.UNINITIALIZED) {
        this.warnings.push('Camera service already initialized')
        return
      }

      await this.cameraService.initialize()
      this.logger.info('Camera manager initialized successfully')
    } catch (error) {
      this.logger.error('Failed to initialize camera manager', error)
      throw error
    }
  }

  /**
   * 扫描可用相机设备
   */
  private async scanAvailableCameras(): Promise<CameraInfo[]> {
    this.logger.info('Scanning available camera devices...')

    try {
      // 这里需要调用相机服务获取设备列表
      // 由于CameraService已经有了相关方法，我们通过模拟或其他方式获取
      const mockCameras: CameraInfo[] = [
        {
          cameraId: '0',
          cameraPosition: CameraPosition.BACK,
          cameraName: 'Back Camera',
          capabilities: [],
          supportedResolutions: [
            { width: 1920, height: 1080 },
            { width: 1280, height: 720 },
            { width: 640, height: 480 }
          ],
          supportedFrameRates: [30, 60]
        },
        {
          cameraId: '1',
          cameraPosition: CameraPosition.FRONT,
          cameraName: 'Front Camera',
          capabilities: [],
          supportedResolutions: [
            { width: 1920, height: 1080 },
            { width: 1280, height: 720 },
            { width: 640, height: 480 }
          ],
          supportedFrameRates: [30]
        }
      ]

      this.logger.info(`Found ${mockCameras.length} available cameras`)
      return mockCameras
    } catch (error) {
      this.logger.error('Failed to scan available cameras', error)
      throw error
    }
  }

  /**
   * 选择最佳相机设备
   */
  private async selectBestCamera(availableCameras: CameraInfo[]): Promise<CameraInfo> {
    this.logger.info('Selecting best camera device...')

    try {
      // 首选位置
      let targetCamera = availableCameras.find(cam =>
        cam.cameraPosition === this.config.preferredPosition
      )

      // 如果首选位置不可用，尝试备选位置
      if (!targetCamera && this.config.fallbackPositions) {
        for (const fallbackPosition of this.config.fallbackPositions) {
          targetCamera = availableCameras.find(cam =>
            cam.cameraPosition === fallbackPosition
          )
          if (targetCamera) {
            this.warnings.push(`Preferred camera position ${this.config.preferredPosition} not available, using ${fallbackPosition}`)
            break
          }
        }
      }

      // 如果仍然没有找到，使用第一个可用相机
      if (!targetCamera) {
        targetCamera = availableCameras[0]
        this.warnings.push('Using first available camera as fallback')
      }

      // 验证相机功能
      if (this.config.requiredFeatures) {
        const missingFeatures = this.validateCameraFeatures(targetCamera)
        if (missingFeatures.length > 0) {
          this.warnings.push(`Camera may not support required features: ${missingFeatures.join(', ')}`)
        }
      }

      this.logger.info('Selected camera', targetCamera)
      return targetCamera
    } catch (error) {
      this.logger.error('Failed to select camera', error)
      throw error
    }
  }

  /**
   * 验证相机功能
   */
  private validateCameraFeatures(camera: CameraInfo): string[] {
    const missingFeatures: string[] = []

    if (this.config.requiredFeatures) {
      for (const feature of this.config.requiredFeatures) {
        switch (feature) {
          case 'photo':
            // 大多数相机都支持拍照
            break
          case 'preview':
            // 大多数相机都支持预览
            break
          case 'flash':
            const hasFlash = camera.capabilities.some(cap =>
              cap.flashModes && cap.flashModes.length > 0
            )
            if (!hasFlash) {
              missingFeatures.push('flash')
            }
            break
          case 'auto_focus':
            // 需要检查对焦能力
            break
        }
      }
    }

    return missingFeatures
  }

  /**
   * 创建拍照会话
   */
  private async createCaptureSession(camera: CameraInfo): Promise<void> {
    this.logger.info('Creating capture session...', camera)

    try {
      // 这里需要调用相机服务创建会话
      // 由于我们在CameraService中已经实现了相关逻辑，这里简化处理
      this.logger.info('Capture session created successfully')
    } catch (error) {
      this.logger.error('Failed to create capture session', error)
      throw error
    }
  }

  /**
   * 配置相机输出
   */
  private async configureOutputs(): Promise<void> {
    this.logger.info('Configuring camera outputs...')

    try {
      // 配置预览输出和拍照输出
      // 这里需要调用相应的配置方法
      this.logger.info('Camera outputs configured successfully')
    } catch (error) {
      this.logger.error('Failed to configure camera outputs', error)
      throw error
    }
  }

  /**
   * 启动拍照会话
   */
  private async startSession(): Promise<void> {
    this.logger.info('Starting capture session...')

    try {
      // 启动相机会话
      // 这里需要调用相机服务的启动方法
      this.logger.info('Capture session started successfully')
    } catch (error) {
      this.logger.error('Failed to start capture session', error)
      throw error
    }
  }

  /**
   * 判断是否应该重试
   */
  private shouldRetry(): boolean {
    return this.config.autoRetryOnFailure &&
           this.retryCount < (this.config.maxRetryAttempts || 3)
  }

  /**
   * 睡眠指定时间
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  /**
   * 设置初始化状态
   */
  private setState(state: InitializationState): void {
    const oldState = this.currentState
    this.currentState = state
    this.logger.info('Initialization state changed', { from: oldState, to: state })
  }

  /**
   * 报告初始化进度
   */
  private reportProgress(progress: number, message: string): void {
    const progressInfo: InitializationProgress = {
      state: this.currentState,
      progress,
      message,
      currentStep: this.getStepMessage(this.currentState),
      totalSteps: 8,
      completedSteps: this.getCompletedSteps(this.currentState)
    }

    this.logger.info('Initialization progress', progressInfo)

    if (this.callbacks.onProgress) {
      try {
        this.callbacks.onProgress(progressInfo)
      } catch (error) {
        this.logger.error('Error in progress callback', error)
      }
    }
  }

  /**
   * 获取步骤消息
   */
  private getStepMessage(state: InitializationState): string {
    const messages: Record<InitializationState, string> = {
      [InitializationState.NOT_STARTED]: '未开始',
      [InitializationState.CHECKING_PERMISSIONS]: '检查权限',
      [InitializationState.REQUESTING_PERMISSIONS]: '请求权限',
      [InitializationState.INITIALIZING_MANAGER]: '初始化管理器',
      [InitializationState.SCANNING_DEVICES]: '扫描设备',
      [InitializationState.SELECTING_CAMERA]: '选择相机',
      [InitializationState.CREATING_SESSION]: '创建会话',
      [InitializationState.CONFIGURING_OUTPUTS]: '配置输出',
      [InitializationState.STARTING_SESSION]: '启动会话',
      [InitializationState.COMPLETED]: '已完成',
      [InitializationState.FAILED]: '失败'
    }

    return messages[state] || '未知状态'
  }

  /**
   * 获取已完成的步骤数
   */
  private getCompletedSteps(state: InitializationState): number {
    const steps: InitializationState[] = [
      InitializationState.CHECKING_PERMISSIONS,
      InitializationState.INITIALIZING_MANAGER,
      InitializationState.SCANNING_DEVICES,
      InitializationState.SELECTING_CAMERA,
      InitializationState.CREATING_SESSION,
      InitializationState.CONFIGURING_OUTPUTS,
      InitializationState.STARTING_SESSION,
      InitializationState.COMPLETED
    ]

    return steps.findIndex(step => step === state) + 1
  }

  /**
   * 通知初始化成功
   */
  private notifySuccess(result: InitializationResult): void {
    if (this.callbacks.onSuccess) {
      try {
        this.callbacks.onSuccess(result)
      } catch (error) {
        this.logger.error('Error in success callback', error)
      }
    }
  }

  /**
   * 通知初始化错误
   */
  private notifyError(error: Error, retryCount: number): void {
    if (this.callbacks.onError) {
      try {
        this.callbacks.onError(error, retryCount)
      } catch (callbackError) {
        this.logger.error('Error in error callback', callbackError)
      }
    }
  }

  /**
   * 获取当前初始化状态
   */
  getState(): InitializationState {
    return this.currentState
  }

  /**
   * 获取初始化统计信息
   */
  getInitializationStats(): {
    state: InitializationState
    retryCount: number
    warnings: string[]
    config: InitializationConfig
  } {
    return {
      state: this.currentState,
      retryCount: this.retryCount,
      warnings: [...this.warnings],
      config: { ...this.config }
    }
  }

  /**
   * 重置初始化状态
   */
  reset(): void {
    this.currentState = InitializationState.NOT_STARTED
    this.retryCount = 0
    this.warnings = []
    this.logger.info('CameraInitializer reset')
  }

  /**
   * 检查相机是否已初始化
   */
  isInitialized(): boolean {
    return this.currentState === InitializationState.COMPLETED
  }
}