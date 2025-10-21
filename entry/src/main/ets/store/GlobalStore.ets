/**
 * GlobalStore.ets
 * 全局状态管理Store
 * 使用V2响应式状态管理，提供全局共享状态
 */

import { BaseStore } from './BaseStore'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'GlobalStore'

/**
 * 应用全局状态类
 * 使用V2响应式装饰器，确保状态变化能够触发UI更新
 */
@ObservedV2
export class GlobalAppState {
  /**
   * 应用加载状态
   */
  @Trace isLoading: boolean = false

  /**
   * 网络连接状态
   */
  @Trace isNetworkConnected: boolean = true

  /**
   * 应用是否在前台
   */
  @Trace isAppInForeground: boolean = true

  /**
   * 全局错误信息
   */
  @Trace globalError: string = ''

  /**
   * 应用版本信息
   */
  @Trace appVersion: string = '1.0.0'

  /**
   * 调试模式开关
   */
  @Trace isDebugMode: boolean = false
}

/**
 * 全局Store类
 * 管理应用级别的状态和通用功能
 */
export class GlobalStore extends BaseStore {
  /**
   * 全局应用状态实例
   */
  @ObservedV2
  private _appState: GlobalAppState = new GlobalAppState()

  /**
   * 构造函数
   */
  constructor() {
    super('GlobalStore')
  }

  /**
   * 初始化全局Store
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      this.log('Already initialized')
      return
    }

    await this.safeExecute(
      async () => {
        // 初始化应用状态
        await this.initializeAppState()

        // 设置错误监听
        this.setupErrorHandling()

        // 设置网络状态监听
        await this.setupNetworkMonitoring()

        this.markInitialized()
      },
      'initialize',
      'Failed to initialize GlobalStore'
    )
  }

  /**
   * 销毁Store，清理资源
   */
  async destroy(): Promise<void> {
    await this.safeExecute(
      async () => {
        // 清理监听器
        this.cleanupListeners()

        // 重置状态
        this.reset()

        this.log('Destroyed successfully')
      },
      'destroy',
      'Failed to destroy GlobalStore'
    )
  }

  /**
   * 获取应用状态
   */
  get appState(): GlobalAppState {
    return this._appState
  }

  /**
   * 设置加载状态
   */
  setLoading(loading: boolean): void {
    this.checkInitialized()
    this._appState.isLoading = loading
    this.log(`Loading state changed: ${loading}`)
  }

  /**
   * 设置网络连接状态
   */
  setNetworkStatus(connected: boolean): void {
    this.checkInitialized()
    this._appState.isNetworkConnected = connected
    this.log(`Network status changed: ${connected}`)
  }

  /**
   * 设置应用前台/后台状态
   */
  setAppForeground(foreground: boolean): void {
    this.checkInitialized()
    this._appState.isAppInForeground = foreground
    this.log(`App foreground state changed: ${foreground}`)
  }

  /**
   * 设置全局错误信息
   */
  setGlobalError(error: string): void {
    this.checkInitialized()
    this._appState.globalError = error
    this.logError('Global error set', error)
  }

  /**
   * 清除全局错误信息
   */
  clearGlobalError(): void {
    this.checkInitialized()
    this._appState.globalError = ''
    this.log('Global error cleared')
  }

  /**
   * 设置调试模式
   */
  setDebugMode(debug: boolean): void {
    this.checkInitialized()
    this._appState.isDebugMode = debug
    this.log(`Debug mode changed: ${debug}`)
  }

  /**
   * 初始化应用状态
   */
  private async initializeAppState(): Promise<void> {
    // 获取应用版本信息
    try {
      // 这里可以添加获取应用版本信息的逻辑
      // const packageInfo = bundle.getApplicationInfoSync()
      // this._appState.appVersion = packageInfo.version.name || '1.0.0'

      // 检查是否为调试模式
      this._appState.isDebugMode = this.isDevelopmentMode()

      this.log('App state initialized', {
        version: this._appState.appVersion,
        debugMode: this._appState.isDebugMode
      })
    } catch (error) {
      this.logError('Failed to initialize app state', error)
      throw error
    }
  }

  /**
   * 设置错误处理
   */
  private setupErrorHandling(): void {
    // 这里可以添加全局错误处理逻辑
    // 例如：设置未捕获异常的处理器
    this.log('Error handling setup completed')
  }

  /**
   * 设置网络状态监听
   */
  private async setupNetworkMonitoring(): Promise<void> {
    try {
      // 这里可以添加网络状态监听逻辑
      // 例如：使用 @ohos.net.connection 监听网络状态
      this.log('Network monitoring setup completed')
    } catch (error) {
      this.logError('Failed to setup network monitoring', error)
      // 网络监听失败不应该阻止应用初始化
    }
  }

  /**
   * 清理监听器
   */
  private cleanupListeners(): void {
    // 清理所有注册的监听器
    this.log('Listeners cleaned up')
  }

  /**
   * 检查是否为开发模式
   */
  private isDevelopmentMode(): boolean {
    // 这里可以根据环境变量或构建配置判断
    // 暂时返回true，实际项目中需要根据构建配置确定
    return true
  }
}

/**
 * 全局Store单例实例
 */
export const globalStore = new GlobalStore()