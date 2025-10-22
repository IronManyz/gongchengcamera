/**
 * BaseStore.ets
 * 基础Store类，提供通用的状态管理功能
 * 严格使用V2响应式状态管理
 */

import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'BaseStore'

/**
 * 基础Store抽象类
 * 定义了通用的状态管理接口和功能
 */
export abstract class BaseStore {
  /**
   * Store初始化状态
   */
  protected _isInitialized: boolean = false

  /**
   * Store名称，用于日志和调试
   */
  protected readonly storeName: string

  constructor(storeName: string) {
    this.storeName = storeName
    hilog.info(0x0000, TAG, `Store[${storeName}] created`)
  }

  /**
   * 初始化Store
   * 子类必须实现此方法来执行特定的初始化逻辑
   */
  abstract initialize(): Promise<void>

  /**
   * 销毁Store，清理资源
   */
  abstract destroy(): Promise<void>

  /**
   * 获取Store初始化状态
   */
  get isInitialized(): boolean {
    return this._isInitialized
  }

  /**
   * 检查Store是否已初始化
   * @throws 如果未初始化则抛出错误
   */
  protected checkInitialized(): void {
    if (!this._isInitialized) {
      throw new Error(`Store[${this.storeName}] is not initialized. Call initialize() first.`)
    }
  }

  /**
   * 标记Store为已初始化
   */
  protected markInitialized(): void {
    this._isInitialized = true
    hilog.info(0x0000, TAG, `Store[${this.storeName}] initialized successfully`)
  }

  /**
   * 重置Store状态
   */
  protected reset(): void {
    this._isInitialized = false
    hilog.info(0x0000, TAG, `Store[${this.storeName}] reset`)
  }

  /**
   * 安全执行异步操作
   * 统一的错误处理和日志记录
   */
  protected async safeExecute<T>(
    operation: () => Promise<T>,
    operationName: string,
    errorMessage?: string
  ): Promise<T | null> {
    try {
      hilog.debug(0x0000, TAG, `Store[${this.storeName}] executing: ${operationName}`)
      const result = await operation()
      hilog.debug(0x0000, TAG, `Store[${this.storeName}] completed: ${operationName}`)
      return result
    } catch (error) {
      const message = errorMessage || `Failed to execute ${operationName}`
      hilog.error(0x0000, TAG, `Store[${this.storeName}] error: ${message}, ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 记录Store操作日志
   */
  protected log(action: string, data?: Object): void {
    const message = data ? `${action}: ${JSON.stringify(data)}` : action
    hilog.debug(0x0000, TAG, `Store[${this.storeName}] ${message}`)
  }

  /**
   * 记录Store错误日志
   */
  protected logError(action: string, error: Object): void {
    hilog.error(0x0000, TAG, `Store[${this.storeName}] ${action} failed: ${JSON.stringify(error)}`)
  }
}