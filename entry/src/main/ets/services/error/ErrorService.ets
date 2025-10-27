/**
 * 全局错误处理服务
 * 提供统一的错误收集、分析和处理机制
 */

import { ErrorInfo, ErrorBoundaryConfig } from '../../components/common/ErrorBoundary'
import { NetworkErrorType, NetworkErrorInfo } from '../../components/common/NetworkError'
import { PermissionType, PermissionInfo } from '../../components/common/PermissionError'

export enum ErrorLevel {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL'
}

export enum ErrorCategory {
  NETWORK = 'NETWORK',
  PERMISSION = 'PERMISSION',
  CAMERA = 'CAMERA',
  STORAGE = 'STORAGE',
  UI = 'UI',
  BUSINESS = 'BUSINESS',
  UNKNOWN = 'UNKNOWN'
}

export interface GlobalError extends ErrorInfo {
  category: ErrorCategory
  level: ErrorLevel
  userMessage: string
  technicalDetails?: string
  suggestions?: string[]
  recoverable: boolean
  context?: Record<string, any>
}

export interface ErrorHandler {
  canHandle(error: GlobalError): boolean
  handle(error: GlobalError): void
  priority: number
}

export interface ErrorReport {
  id: string
  timestamp: number
  errors: GlobalError[]
  userAgent: string
  appVersion: string
  deviceInfo?: any
}

/**
 * 全局错误处理服务
 */
export class ErrorService {
  private static instance: ErrorService
  private handlers: ErrorHandler[] = []
  private errorBuffer: GlobalError[] = []
  private maxBufferSize: number = 100
  private isReporting: boolean = false

  static getInstance(): ErrorService {
    if (!ErrorService.instance) {
      ErrorService.instance = new ErrorService()
    }
    return ErrorService.instance
  }

  private constructor() {
    this.initializeHandlers()
  }

  /**
   * 初始化错误处理器
   */
  private initializeHandlers(): void {
    // 注册默认错误处理器
    this.addHandler(new NetworkErrorHandler())
    this.addHandler(new PermissionErrorHandler())
    this.addHandler(new CameraErrorHandler())
    this.addHandler(new UIErrorHandler())
    this.addHandler(new DefaultErrorHandler())
  }

  /**
   * 注册错误处理器
   */
  addHandler(handler: ErrorHandler): void {
    this.handlers.push(handler)
    // 按优先级排序
    this.handlers.sort((a, b) => b.priority - a.priority)
  }

  /**
   * 移除错误处理器
   */
  removeHandler(handler: ErrorHandler): void {
    const index = this.handlers.indexOf(handler)
    if (index > -1) {
      this.handlers.splice(index, 1)
    }
  }

  /**
   * 处理错误
   */
  handleError(error: Error, context?: Record<string, any>): void {
    const globalError = this.createGlobalError(error, context)

    // 添加到缓冲区
    this.addToBuffer(globalError)

    // 查找合适的处理器
    const handler = this.handlers.find(h => h.canHandle(globalError))

    if (handler) {
      try {
        handler.handle(globalError)
      } catch (handleError) {
        console.error('Error handler failed:', handleError)
        this.handleFallback(globalError)
      }
    } else {
      this.handleFallback(globalError)
    }

    // 记录错误
    this.logError(globalError)
  }

  /**
   * 创建全局错误对象
   */
  private createGlobalError(error: Error, context?: Record<string, any>): GlobalError {
    const category = this.categorizeError(error)
    const level = this.determineErrorLevel(error, category)
    const userMessage = this.generateUserMessage(error, category)
    const suggestions = this.generateSuggestions(error, category)

    return {
      error,
      category,
      level,
      userMessage,
      technicalDetails: error.stack,
      suggestions,
      recoverable: this.isRecoverable(error, category),
      timestamp: Date.now(),
      context
    }
  }

  /**
   * 错误分类
   */
  private categorizeError(error: Error): ErrorCategory {
    const message = error.message.toLowerCase()
    const name = error.name.toLowerCase()

    if (message.includes('network') || message.includes('connection') || message.includes('timeout')) {
      return ErrorCategory.NETWORK
    }
    if (message.includes('permission') || name.includes('permission')) {
      return ErrorCategory.PERMISSION
    }
    if (message.includes('camera') || name.includes('camera')) {
      return ErrorCategory.CAMERA
    }
    if (message.includes('storage') || message.includes('file')) {
      return ErrorCategory.STORAGE
    }
    if (message.includes('component') || message.includes('render')) {
      return ErrorCategory.UI
    }
    if (message.includes('business') || message.includes('logic')) {
      return ErrorCategory.BUSINESS
    }

    return ErrorCategory.UNKNOWN
  }

  /**
   * 确定错误级别
   */
  private determineErrorLevel(error: Error, category: ErrorCategory): ErrorLevel {
    const message = error.message.toLowerCase()

    // 关键错误
    if (message.includes('critical') || message.includes('fatal') || category === ErrorCategory.CAMERA) {
      return ErrorLevel.CRITICAL
    }

    // 高级错误
    if (message.includes('server') || message.includes('permission denied') || category === ErrorCategory.NETWORK) {
      return ErrorLevel.HIGH
    }

    // 中级错误
    if (message.includes('timeout') || message.includes('not found')) {
      return ErrorLevel.MEDIUM
    }

    return ErrorLevel.LOW
  }

  /**
   * 生成用户友好的错误消息
   */
  private generateUserMessage(error: Error, category: ErrorCategory): string {
    const message = error.message.toLowerCase()

    switch (category) {
      case ErrorCategory.NETWORK:
        if (message.includes('timeout')) return '网络请求超时，请稍后重试'
        if (message.includes('connection')) return '网络连接失败，请检查网络设置'
        return '网络请求失败，请稍后重试'

      case ErrorCategory.PERMISSION:
        if (message.includes('camera')) return '需要相机权限来拍摄照片'
        if (message.includes('storage')) return '需要存储权限来保存文件'
        return '需要相关权限来继续操作'

      case ErrorCategory.CAMERA:
        return '相机功能出现异常，请重启相机或联系技术支持'

      case ErrorCategory.STORAGE:
        return '文件存储出现问题，请检查存储空间或权限'

      case ErrorCategory.UI:
        return '界面显示异常，请刷新页面或重启应用'

      default:
        return '操作出现异常，请稍后重试'
    }
  }

  /**
   * 生成错误建议
   */
  private generateSuggestions(error: Error, category: ErrorCategory): string[] {
    const suggestions: string[] = []

    switch (category) {
      case ErrorCategory.NETWORK:
        suggestions.push('检查网络连接是否正常', '尝试切换网络环境', '稍后重试')
        break
      case ErrorCategory.PERMISSION:
        suggestions.push('检查应用权限设置', '重新授予权限', '重启应用')
        break
      case ErrorCategory.CAMERA:
        suggestions.push('检查相机权限', '重启相机功能', '重启应用')
        break
      case ErrorCategory.STORAGE:
        suggestions.push('检查存储空间', '检查文件权限', '清理缓存')
        break
    }

    return suggestions
  }

  /**
   * 判断错误是否可恢复
   */
  private isRecoverable(error: Error, category: ErrorCategory): boolean {
    const message = error.message.toLowerCase()

    // 不可恢复的错误
    if (message.includes('fatal') || message.includes('critical')) {
      return false
    }

    // 某些权限错误需要用户干预
    if (category === ErrorCategory.PERMISSION) {
      return false
    }

    return true
  }

  /**
   * 添加到缓冲区
   */
  private addToBuffer(error: GlobalError): void {
    this.errorBuffer.push(error)

    // 限制缓冲区大小
    if (this.errorBuffer.length > this.maxBufferSize) {
      this.errorBuffer.shift()
    }
  }

  /**
   * 错误记录
   */
  private logError(error: GlobalError): void {
    const logData = {
      timestamp: error.timestamp,
      level: error.level,
      category: error.category,
      message: error.userMessage,
      technical: error.technicalDetails,
      context: error.context
    }

    console.error('GlobalError:', logData)
  }

  /**
   * 错误回退处理
   */
  private handleFallback(error: GlobalError): void {
    // 基本的错误处理逻辑
    console.warn('Using fallback error handler for:', error)

    // 这里可以显示通用的错误提示
    // Toast.error(error.userMessage)
  }

  /**
   * 获取错误统计
   */
  getErrorStats(): Record<ErrorCategory, number> {
    const stats: Record<string, number> = {}

    for (const error of this.errorBuffer) {
      const category = error.category
      stats[category] = (stats[category] || 0) + 1
    }

    return stats as Record<ErrorCategory, number>
  }

  /**
   * 获取最近错误
   */
  getRecentErrors(count: number = 10): GlobalError[] {
    return this.errorBuffer.slice(-count)
  }

  /**
   * 清理错误缓冲区
   */
  clearErrors(): void {
    this.errorBuffer = []
  }

  /**
   * 生成错误报告
   */
  generateErrorReport(): ErrorReport {
    return {
      id: `report_${Date.now()}`,
      timestamp: Date.now(),
      errors: this.getRecentErrors(50),
      userAgent: 'EngineeringCamera App',
      appVersion: '1.0.0',
      deviceInfo: {} // 这里可以添加设备信息
    }
  }
}

/**
 * 网络错误处理器
 */
class NetworkErrorHandler implements ErrorHandler {
  priority = 100

  canHandle(error: GlobalError): boolean {
    return error.category === ErrorCategory.NETWORK
  }

  handle(error: GlobalError): void {
    // 网络错误特殊处理逻辑
    console.log('Handling network error:', error)
    // 可以触发网络状态检查等
  }
}

/**
 * 权限错误处理器
 */
class PermissionErrorHandler implements ErrorHandler {
  priority = 90

  canHandle(error: GlobalError): boolean {
    return error.category === ErrorCategory.PERMISSION
  }

  handle(error: GlobalError): void {
    // 权限错误特殊处理逻辑
    console.log('Handling permission error:', error)
    // 可以显示权限请求对话框
  }
}

/**
 * 相机错误处理器
 */
class CameraErrorHandler implements ErrorHandler {
  priority = 95

  canHandle(error: GlobalError): boolean {
    return error.category === ErrorCategory.CAMERA
  }

  handle(error: GlobalError): void {
    // 相机错误特殊处理逻辑
    console.log('Handling camera error:', error)
    // 可以尝试重新���始化相机
  }
}

/**
 * UI错误处理器
 */
class UIErrorHandler implements ErrorHandler {
  priority = 80

  canHandle(error: GlobalError): boolean {
    return error.category === ErrorCategory.UI
  }

  handle(error: GlobalError): void {
    // UI错误特殊处理逻辑
    console.log('Handling UI error:', error)
    // 可以尝试重新渲染组件
  }
}

/**
 * 默认错误处理器
 */
class DefaultErrorHandler implements ErrorHandler {
  priority = 0

  canHandle(error: GlobalError): boolean {
    return true // 总是可以处理
  }

  handle(error: GlobalError): void {
    // 默认错误处理逻辑
    console.log('Handling error with default handler:', error)
  }
}