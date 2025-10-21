/**
 * ErrorHandlingManager.ets
 * 错误处理管理器
 * 负责统一的错误处理、错误日志记录、错误恢复和用户友好的错误提示
 */

import { hilog } from '@kit.PerformanceAnalysisKit'
import { ErrorInfo } from '../../types/AppTypes'

const TAG = 'ErrorHandlingManager'

/**
 * 错误类型枚举
 */
export enum ErrorType {
  VALIDATION = 'validation',        // 数据验证错误
  DATABASE = 'database',            // 数据库操作错误
  NETWORK = 'network',              // 网络请求错误
  FILE_SYSTEM = 'file_system',      // 文件系统错误
  PERMISSION = 'permission',        // 权限错误
  CAMERA = 'camera',                // 相机操作错误
  LOCATION = 'location',            // 定位服务错误
  STORAGE = 'storage',              // 存储空间错误
  BUSINESS_LOGIC = 'business_logic', // 业务逻辑错误
  SYSTEM = 'system',                // 系统级错误
  USER_INPUT = 'user_input',        // 用户输入错误
  UNKNOWN = 'unknown'               // 未知错误
}

/**
 * 错误严重程度
 */
export enum ErrorSeverity {
  LOW = 'low',           // 低级别，不影响核心功能
  MEDIUM = 'medium',     // 中等级别，影响部分功能
  HIGH = 'high',         // 高级别，影响主要功能
  CRITICAL = 'critical'  // 关键级别，影响应用正常运行
}

/**
 * 错误处理策略
 */
export enum ErrorHandlingStrategy {
  LOG_ONLY = 'log_only',               // 仅记录日志
  RETRY = 'retry',                     // 自动重试
  FALLBACK = 'fallback',               // 降级处理
  USER_INTERVENTION = 'user_intervention', // 需要用户干预
  IGNORE = 'ignore'                    // 忽略错误
}

/**
 * 自定义错误类
 */
export class AppError extends Error {
  public readonly code: string
  public readonly type: ErrorType
  public readonly severity: ErrorSeverity
  public readonly userMessage: string
  public readonly technicalMessage?: string
  public readonly cause?: Error
  public readonly context?: Record<string, any>
  public readonly timestamp: Date
  public readonly handlingStrategy: ErrorHandlingStrategy
  public readonly retryable: boolean
  public readonly maxRetries?: number

  constructor(options: {
    code: string
    type: ErrorType
    severity: ErrorSeverity
    userMessage: string
    technicalMessage?: string
    cause?: Error
    context?: Record<string, any>
    handlingStrategy?: ErrorHandlingStrategy
    retryable?: boolean
    maxRetries?: number
  }) {
    super(options.technicalMessage || options.userMessage)

    this.code = options.code
    this.type = options.type
    this.severity = options.severity
    this.userMessage = options.userMessage
    this.technicalMessage = options.technicalMessage
    this.cause = options.cause
    this.context = options.context
    this.timestamp = new Date()
    this.handlingStrategy = options.handlingStrategy || ErrorHandlingStrategy.LOG_ONLY
    this.retryable = options.retryable || false
    this.maxRetries = options.maxRetries

    // 保持错误堆栈
    if (options.cause && options.cause.stack) {
      this.stack = options.cause.stack
    }
  }

  /**
   * 转换为ErrorInfo格式
   */
  toErrorInfo(): ErrorInfo {
    return {
      code: this.code,
      message: this.userMessage,
      details: {
        type: this.type,
        severity: this.severity,
        technicalMessage: this.technicalMessage,
        context: this.context,
        timestamp: this.timestamp,
        handlingStrategy: this.handlingStrategy
      },
      timestamp: this.timestamp
    }
  }
}

/**
 * 错误处理配置
 */
export interface ErrorHandlingConfig {
  enableLogging: boolean
  enableUserNotification: boolean
  maxLogEntries: number
  autoRetryAttempts: number
  enableFallback: boolean
  enableCrashReporting: boolean
  logLevel: 'debug' | 'info' | 'warn' | 'error'
}

/**
 * 错误恢复结果
 */
export interface ErrorRecoveryResult {
  success: boolean
  error?: AppError
  message?: string
  actionTaken?: string
}

/**
 * 错误处理管理器
 */
export class ErrorHandlingManager {
  private static instance: ErrorHandlingManager | null = null

  // 错误处理配置
  private config: ErrorHandlingConfig = {
    enableLogging: true,
    enableUserNotification: true,
    maxLogEntries: 1000,
    autoRetryAttempts: 3,
    enableFallback: true,
    enableCrashReporting: false,
    logLevel: 'error'
  }

  // 错误日志
  private errorLog: ErrorInfo[] = []

  // 错误处理器映射
  private readonly errorHandlers: Map<string, (error: AppError) => Promise<ErrorRecoveryResult>> = new Map()

  // 重试计数器
  private readonly retryCounters: Map<string, number> = new Map()

  /**
   * 获取单例实例
   */
  static getInstance(): ErrorHandlingManager {
    if (!ErrorHandlingManager.instance) {
      ErrorHandlingManager.instance = new ErrorHandlingManager()
    }
    return ErrorHandlingManager.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.initializeDefaultHandlers()
  }

  /**
   * 初始化默认错误处理器
   */
  private initializeDefaultHandlers(): void {
    // 数据库错误处理器
    this.registerHandler('DB_001', async (error) => {
      // 数据库连接失败
      if (error.retryable) {
        return await this.retryOperation(error)
      }
      return {
        success: false,
        error,
        message: '数据库连接失败，请检查应用设置'
      }
    })

    // 文件系统错误处理器
    this.registerHandler('FS_001', async (error) => {
      // 文件不存在
      return {
        success: true,
        message: '文件不存在，已自动处理'
      }
    })

    // 权限错误处理器
    this.registerHandler('PERM_001', async (error) => {
      // 相机权限被拒绝
      return {
        success: false,
        error,
        message: '需要相机权限才能拍照',
        actionTaken: 'request_permission'
      }
    })

    // 存储空间不足错误处理器
    this.registerHandler('STORAGE_001', async (error) => {
      // 存储空间不足
      return {
        success: false,
        error,
        message: '存储空间不足，请清理空间后重试',
        actionTaken: 'show_cleanup_dialog'
      }
    })
  }

  /**
   * 处理错误
   */
  async handleError(error: Error | AppError, context?: Record<string, any>): Promise<ErrorRecoveryResult> {
    const appError = this.normalizeError(error, context)

    try {
      // 记录错误日志
      if (this.config.enableLogging) {
        this.logError(appError)
      }

      // 获取错误处理器
      const handler = this.errorHandlers.get(appError.code)

      if (handler) {
        // 使用自定义处理器
        const result = await handler(appError)

        if (this.config.enableLogging) {
          hilog.info(0x0000, TAG, `错误处理完成: ${appError.code}, 结果: ${result.success}`)
        }

        return result
      } else {
        // 使用默认处理策略
        return await this.handleWithDefaultStrategy(appError)
      }

    } catch (handlingError) {
      // 错误处理本身出错
      const criticalError = new AppError({
        code: 'SYS_001',
        type: ErrorType.SYSTEM,
        severity: ErrorSeverity.CRITICAL,
        userMessage: '系统发生错误，请重启应用',
        technicalMessage: `错误处理失败: ${handlingError instanceof Error ? handlingError.message : String(handlingError)}`,
        cause: handlingError,
        context: { originalError: appError }
      })

      this.logError(criticalError)

      return {
        success: false,
        error: criticalError,
        message: '错误处理失败，请联系技术支持'
      }
    }
  }

  /**
   * 注册错误处理器
   */
  registerHandler(errorCode: string, handler: (error: AppError) => Promise<ErrorRecoveryResult>): void {
    this.errorHandlers.set(errorCode, handler)
    hilog.info(0x0000, TAG, `注册错误处理器: ${errorCode}`)
  }

  /**
   * 注销错误处理器
   */
  unregisterHandler(errorCode: string): void {
    this.errorHandlers.delete(errorCode)
    hilog.info(0x0000, TAG, `注销错误处理器: ${errorCode}`)
  }

  /**
   * 创建标准错误
   */
  createError(options: {
    code: string
    type: ErrorType
    severity: ErrorSeverity
    userMessage: string
    technicalMessage?: string
    cause?: Error
    context?: Record<string, any>
    handlingStrategy?: ErrorHandlingStrategy
    retryable?: boolean
  }): AppError {
    return new AppError(options)
  }

  /**
   * 包装异步操作，自动处理错误
   */
  async wrapAsyncOperation<T>(
    operation: () => Promise<T>,
    errorContext?: {
      operationName?: string
      errorType?: ErrorType
      errorCode?: string
      userMessage?: string
      retryable?: boolean
      fallback?: () => Promise<T>
    }
  ): Promise<{ success: boolean; data?: T; error?: AppError }> {
    try {
      const data = await operation()
      return { success: true, data }
    } catch (error) {
      const appError = this.normalizeError(error, {
        operationName: errorContext?.operationName,
        ...errorContext
      })

      // 如果有降级处理
      if (errorContext?.fallback && this.config.enableFallback) {
        try {
          const fallbackData = await errorContext.fallback()
          hilog.info(0x0000, TAG, `降级处理成功: ${errorContext.operationName}`)
          return { success: true, data: fallbackData }
        } catch (fallbackError) {
          hilog.error(0x0000, TAG, `降级处理失败: ${errorContext.operationName}`)
        }
      }

      // 处理错误
      const recoveryResult = await this.handleError(appError)

      return {
        success: false,
        error: appError
      }
    }
  }

  /**
   * 重试操作
   */
  async retryOperation(error: AppError): Promise<ErrorRecoveryResult> {
    if (!error.retryable || !error.maxRetries) {
      return {
        success: false,
        error,
        message: '操作不可重试'
      }
    }

    const retryKey = `${error.code}_${Date.now()}`
    const currentRetryCount = this.retryCounters.get(retryKey) || 0

    if (currentRetryCount >= error.maxRetries) {
      this.retryCounters.delete(retryKey)
      return {
        success: false,
        error,
        message: `重试次数已达上限 (${error.maxRetries})`
      }
    }

    this.retryCounters.set(retryKey, currentRetryCount + 1)

    hilog.info(0x0000, TAG, `重试操作: ${error.code}, 第${currentRetryCount + 1}次`)

    // 等待一段时间后重试（指数退避）
    const delay = Math.min(1000 * Math.pow(2, currentRetryCount), 10000)
    await new Promise(resolve => setTimeout(resolve, delay))

    // 这里应该重新执行原始操作，但作为示例，我们只返回失败
    // 在实际应用中，需要存储原始操作以便重试
    return {
      success: false,
      error,
      message: `重试第${currentRetryCount + 1}次失败`
    }
  }

  /**
   * 使用默认策略处理错误
   */
  private async handleWithDefaultStrategy(error: AppError): Promise<ErrorRecoveryResult> {
    switch (error.handlingStrategy) {
      case ErrorHandlingStrategy.LOG_ONLY:
        return {
          success: true,
          message: '错误已记录'
        }

      case ErrorHandlingStrategy.RETRY:
        if (error.retryable) {
          return await this.retryOperation(error)
        }
        break

      case ErrorHandlingStrategy.FALLBACK:
        return {
          success: false,
          error,
          message: '使用默认降级处理'
        }

      case ErrorHandlingStrategy.USER_INTERVENTION:
        return {
          success: false,
          error,
          message: error.userMessage,
          actionTaken: 'show_user_dialog'
        }

      case ErrorHandlingStrategy.IGNORE:
        return {
          success: true,
          message: '错误已忽略'
        }

      default:
        return {
          success: false,
          error,
          message: error.userMessage
        }
    }

    return {
      success: false,
      error,
      message: error.userMessage
    }
  }

  /**
   * 标准化错误对象
   */
  private normalizeError(error: Error | AppError, context?: Record<string, any>): AppError {
    if (error instanceof AppError) {
      // 如果是自定义错误，添加上下文
      if (context) {
        return new AppError({
          ...error,
          context: { ...error.context, ...context }
        })
      }
      return error
    }

    // 将普通Error转换为AppError
    return new AppError({
      code: 'SYS_999',
      type: ErrorType.UNKNOWN,
      severity: ErrorSeverity.MEDIUM,
      userMessage: '发生未知错误',
      technicalMessage: error.message,
      cause: error,
      context,
      handlingStrategy: ErrorHandlingStrategy.LOG_ONLY
    })
  }

  /**
   * 记录错误日志
   */
  private logError(error: AppError): void {
    const errorInfo = error.toErrorInfo()

    // 添加到内存日志
    this.errorLog.unshift(errorInfo)

    // 限制日志条数
    if (this.errorLog.length > this.config.maxLogEntries) {
      this.errorLog = this.errorLog.slice(0, this.config.maxLogEntries)
    }

    // 输出到系统日志
    const logLevel = this.getLogLevel(error.severity)
    const logMessage = `[${error.code}] ${error.userMessage}`

    switch (logLevel) {
      case 'debug':
        hilog.debug(0x0000, TAG, logMessage)
        break
      case 'info':
        hilog.info(0x0000, TAG, logMessage)
        break
      case 'warn':
        hilog.warn(0x0000, TAG, logMessage)
        break
      case 'error':
        hilog.error(0x0000, TAG, logMessage)
        break
    }

    // 记录详细错误信息
    if (error.technicalMessage || error.context) {
      hilog.debug(0x0000, TAG, `错误详情: ${JSON.stringify({
        technicalMessage: error.technicalMessage,
        context: error.context,
        cause: error.cause?.message
      })}`)
    }
  }

  /**
   * 根据严重程度获取日志级别
   */
  private getLogLevel(severity: ErrorSeverity): 'debug' | 'info' | 'warn' | 'error' {
    switch (severity) {
      case ErrorSeverity.LOW:
        return 'debug'
      case ErrorSeverity.MEDIUM:
        return 'info'
      case ErrorSeverity.HIGH:
        return 'warn'
      case ErrorSeverity.CRITICAL:
        return 'error'
      default:
        return 'error'
    }
  }

  /**
   * 获取错误日志
   */
  getErrorLog(limit?: number): ErrorInfo[] {
    if (limit) {
      return this.errorLog.slice(0, limit)
    }
    return [...this.errorLog]
  }

  /**
   * 清空错误日志
   */
  clearErrorLog(): void {
    this.errorLog = []
    this.retryCounters.clear()
    hilog.info(0x0000, TAG, '错误日志已清空')
  }

  /**
   * 获取错误统计
   */
  getErrorStats(): {
    total: number
    byType: Record<ErrorType, number>
    bySeverity: Record<ErrorSeverity, number>
    recent: number // 最近24小时错误数
  } {
    const now = new Date()
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)

    const stats = {
      total: this.errorLog.length,
      byType: {} as Record<ErrorType, number>,
      bySeverity: {} as Record<ErrorSeverity, number>,
      recent: 0
    }

    // 初始化计数器
    Object.values(ErrorType).forEach(type => {
      stats.byType[type] = 0
    })
    Object.values(ErrorSeverity).forEach(severity => {
      stats.bySeverity[severity] = 0
    })

    // 统计错误
    this.errorLog.forEach(errorInfo => {
      if (errorInfo.details?.type) {
        stats.byType[errorInfo.details.type as ErrorType]++
      }
      if (errorInfo.details?.severity) {
        stats.bySeverity[errorInfo.details.severity as ErrorSeverity]++
      }
      if (errorInfo.timestamp > oneDayAgo) {
        stats.recent++
      }
    })

    return stats
  }

  /**
   * 更新配置
   */
  updateConfig(newConfig: Partial<ErrorHandlingConfig>): void {
    this.config = { ...this.config, ...newConfig }
    hilog.info(0x0000, TAG, '错误处理配置已更新')
  }

  /**
   * 获取配置
   */
  getConfig(): ErrorHandlingConfig {
    return { ...this.config }
  }

  /**
   * 检查应用健康状态
   */
  getHealthStatus(): {
    status: 'healthy' | 'warning' | 'critical'
    issues: string[]
    recommendations: string[]
  } {
    const stats = this.getErrorStats()
    const issues: string[] = []
    const recommendations: string[] = []

    let status: 'healthy' | 'warning' | 'critical' = 'healthy'

    // 检查错误频率
    if (stats.recent > 10) {
      status = 'critical'
      issues.push('最近24小时错误过多')
      recommendations.push('检查应用稳定性，修复高频错误')
    } else if (stats.recent > 5) {
      status = 'warning'
      issues.push('最近24小时错误较多')
      recommendations.push('关注错误趋势，及时处理问题')
    }

    // 检查关键错误
    if (stats.bySeverity[ErrorSeverity.CRITICAL] > 0) {
      status = 'critical'
      issues.push('存在关键错误')
      recommendations.push('立即处理关键错误，确保应用正常运行')
    }

    // 检查系统错误
    if (stats.byType[ErrorType.SYSTEM] > 0) {
      status = 'critical'
      issues.push('存在系统级错误')
      recommendations.push('检查系统配置和权限设置')
    }

    return { status, issues, recommendations }
  }
}

/**
 * 导出单例实例和常用工具函数
 */
export const errorHandlingManager = ErrorHandlingManager.getInstance()

/**
 * 便捷函数：处理错误
 */
export async function handleError(error: Error | AppError, context?: Record<string, any>): Promise<ErrorRecoveryResult> {
  return await errorHandlingManager.handleError(error, context)
}

/**
 * 便捷函数：包装异步操作
 */
export async function wrapOperation<T>(
  operation: () => Promise<T>,
  errorContext?: {
    operationName?: string
    errorType?: ErrorType
    errorCode?: string
    userMessage?: string
    retryable?: boolean
  }
): Promise<{ success: boolean; data?: T; error?: AppError }> {
  return await errorHandlingManager.wrapAsyncOperation(operation, errorContext)
}

/**
 * 便捷函数：创建标准错误
 */
export function createError(options: {
  code: string
  type: ErrorType
  severity: ErrorSeverity
  userMessage: string
  technicalMessage?: string
  cause?: Error
  context?: Record<string, any>
}): AppError {
  return errorHandlingManager.createError(options)
}