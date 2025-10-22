/**
 * 错误处理和提示系统
 * 提供专业的错误提示、Toast通知和错误处理机制
 */

import { ThemeManager } from '../../theme/ThemeManager'

export type MessageType =
  | 'success'         // 成功
  | 'error'           // 错误
  | 'warning'         // 警告
  | 'info'            // 信息
  | 'loading'         // 加载中

export type ToastPosition =
  | 'top' | 'center' | 'bottom'
  | 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'

export type ToastDuration =
  | 'short'          // 2秒
  | 'medium'         // 3.5秒
  | 'long'           // 5秒
  | 'infinite'        // 持续显示

export type ErrorSeverity =
  | 'low'            // 低级错误
  | 'medium'         // 中级错误
  | 'high'            // 高级错误
  | 'critical'        // 严重错误

export type ErrorType =
  | 'network'         // 网络错误
  | 'validation'      // 验证错误
  | 'permission'      // 权限错误
  | 'system'          // 系统错误
  | 'business'        // 业务逻辑错误
  | 'file'            // 文件错误
  | 'api'             // API错误
  | 'unknown'         // 未知错误

/**
 * Toast消息组件
 * 提供统一的Toast提示功能
 */
@ComponentV2
export struct ToastMessage {
  @Param message: string = ''
  @Param type: MessageType = 'info'
  @Param position: ToastPosition = 'bottom'
  @Param duration: ToastDuration = 'medium'
  @Param showIcon: boolean = true
  @Param showButton: boolean = false
  @Param buttonText: string = '确定'
  @Param onButtonPress?: () => void = () => {}
  @Param onDismiss?: () => void = () => {}

  @State private isVisible: boolean = false
  @State private opacity: number = 0

  aboutToAppear() {
    this.showToast()
  }

  /**
   * 显示Toast
   */
  private showToast() {
    this.isVisible = true
    animateTo({
      duration: 200,
      curve: Curve.EaseInOut
    }, () => {
      this.opacity = 1
    })

    // 自动隐藏
    if (this.duration !== 'infinite') {
      const durationMap = {
        'short': 2000,
        'medium': 3500,
        'long': 5000
      }

      setTimeout(() => {
        this.hideToast()
      }, durationMap[this.duration])
    }
  }

  /**
   * 隐藏Toast
   */
  private hideToast() {
    animateTo({
      duration: 200,
      curve: Curve.EaseInOut
    }, () => {
      this.opacity = 0
    })

    setTimeout(() => {
      this.isVisible = false
      this.onDismiss?.()
    }, 200)
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.hideToast()
          })

        // Toast内容
        Column() {
          // 图标和按钮行
          Row({ space: 12 }) {
            // 图标
            if (this.showIcon) {
              this.buildToastIcon()
            }

            Blank()

            // 按钮（可选）
            if (this.showButton) {
              Button(this.buttonText)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(ThemeManager.getCurrentPrimaryColor())
                .borderRadius(16)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .onClick(() => {
                  this.hideToast()
                  this.onButtonPress?.()
                })
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        // 消息内容
        Text(this.message)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .width('100%')
        }
      }
      .width(280)
      .backgroundColor(this.getToastBackgroundColor())
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.3)',
        offsetX: 0,
        offsetY: 4
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .opacity(this.opacity)
    .position(this.getToastPosition())
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 构建Toast图标
   */
  @Builder
  private buildToastIcon() {
    Circle({ width: 20, height: 20 })
      .fill(this.getToastIconColor())
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  /**
   * 获取Toast背景颜色
   */
  private getToastBackgroundColor(): string {
    switch (this.type) {
      case 'success':
        return '#52C41A'
      case 'error':
        return '#FF4D4F'
      case 'warning':
        return '#FAAD14'
      case 'info':
        return '#1890FF'
      case 'loading':
        return '#722ED1'
      default:
        return '#333333'
    }
  }

  /**
   * 获取Toast图标颜色
   */
  private getToastIconColor(): string {
    switch (this.type) {
      case 'success':
      case 'error':
      case 'warning':
      case 'info':
        return '#FFFFFF'
      case 'loading':
        return '#FFFFFF'
      default:
        return '#FFFFFF'
    }
  }

  /**
   * 获取Toast位置
   */
  private getToastPosition(): { [key: string]: string | number } {
    const positions = {
      'top': { top: 80, left: '50%', transform: 'translateX(-50%)' },
      'center': { top: '50%', left: '50%', transform: 'translate(-50%, -50%)' },
      'bottom': { bottom: 80, left: '50%', transform: 'translateX(-50%)' },
      'top-left': { top: 80, left: 20 },
      'top-right': { top: 80, right: 20 },
      'bottom-left': { bottom: 80, left: 20 },
      'bottom-right': { bottom: 80, right: 20 }
    }
    return positions[this.position] || positions['bottom']
  }
}

/**
 * 错误提示对话框组件
 * 提供专业的错误处理和用户反馈机制
 */
@ComponentV2
export struct ErrorDialog {
  @Param title: string = '操作失败'
  @Param message: string = '操作过程中发生了错误'
  @Param severity: ErrorSeverity = 'medium'
  @Param type: ErrorType = 'unknown'
  @Param errorCode?: string = ''
  @Param details?: string[] = []
  @Param showRetry: boolean = false
  @Param showReport: boolean = false
  @Param retryText: string = '重试'
  @Param reportText: string = '报告问题'
  @Param onRetry?: () => void = () => {}
  @Param onReport?: () => void = () => {}
  @Param onDismiss?: () => void = () => {}
  @Param autoDismissDelay: number = 0

  @State private isVisible: boolean = false
  @State private expandedDetails: boolean = false

  aboutToAppear() {
    this.isVisible = true
    if (this.autoDismissDelay > 0) {
      setTimeout(() => {
        this.isVisible = false
        this.onDismiss?.()
      }, this.autoDismissDelay)
    }
  }

  build() {
    if (this.isVisible) {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          if (this.autoDismissDelay === 0) {
            this.isVisible = false
            this.onDismiss?.()
          }
        })

        // 错误对话框
        Column() {
          // 对话框头部
          Row() {
            Circle({ width: 8, height: 8 })
              .fill(this.getErrorIndicatorColor())

            Text(this.title)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getErrorTextColor())
              .margin({ left: 12 })
              .layoutWeight(1)

            // 关闭按钮
            Button() {
              Text('×')
                .fontSize(16)
                .fontColor(this.getErrorTextColor())
            }
            .width(32)
            .height(32)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.isVisible = false
              this.onDismiss?.()
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .padding(20)
          .backgroundColor(this.getErrorBackgroundColor())
          .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 12 })
        }

        // 错误内容
        Column() {
          // 主要错误信息
          Text(this.message)
            .fontSize(16)
            .fontColor(this.getErrorTextColor())
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
            .width('100%')

          // 错误详情（可选）
          if (this.details && this.details.length > 0) {
            Column() {
              Text('错误详情：')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.getErrorTextColor())
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8 })

              ForEach(this.details, (detail: string, index: number) => {
                Row() {
                  Text(`• ${detail}`)
                    .fontSize(14)
                    .fontColor(this.getErrorTextColor())
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .margin({ bottom: 4 })
                }
                .width('100%')
              })
            }
            .width('100%')
            .padding({ bottom: 16 })
            .backgroundColor(this.getErrorBackgroundColor() + '20')
            .borderRadius(8)
          }

          // 错误代码（可选）
          if (this.errorCode) {
            Row() {
              Text(`错误代码：${this.errorCode}`)
                .fontSize(12)
                .fontColor(this.getErrorSecondaryTextColor())
                .backgroundColor(this.getErrorBackgroundColor() + '20')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4)
                .margin({ bottom: 16 })
            }
            .width('100%')
          }

          // 操作按钮区域
          Row() {
            // 重试按钮
            if (this.showRetry) {
              Button(this.retryText)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor(this.getErrorPrimaryColor())
                .borderRadius(8)
                .padding({ left: 20, right: 20, top: 12, bottom: 12 })
                .onClick(() => {
                  this.isVisible = false
                  this.onRetry?.()
                })
            }

            // 报告按钮
            if (this.showReport) {
              Button(this.reportText)
                .fontSize(14)
                .fontColor(this.getErrorPrimaryColor())
                .backgroundColor(Color.Transparent)
                .border({ width: 1, color: this.getErrorPrimaryColor() })
                .borderRadius(8)
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .onClick(() => {
                  this.isVisible = false
                  this.onReport?.()
                })
            }

            // 展开详情按钮
            if (this.details && this.details.length > 0) {
              Button(this.expandedDetails ? '收起详情' : '展开详情')
                .fontSize(14)
                .fontColor(this.getErrorPrimaryColor())
                .backgroundColor(Color.Transparent)
                .border({ width: 1, color: this.getErrorPrimaryColor() })
                .borderRadius(8)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .onClick(() => {
                  this.expandedDetails = !this.expandedDetails
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .margin({ top: 16 })
        }

        // 对话框底部
        Row() {
          Blank()

          Text('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getErrorPrimaryColor())
            .borderRadius(8)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .onClick(() => {
              this.isVisible = false
              this.onDismiss?.()
            })
        }
        .width('100%')
        .padding(20)
        .justifyContent(FlexAlign.End)
        .backgroundColor(this.getErrorBackgroundColor())
        .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 12 })
      }
    }
    .width(320)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.3)',
      offsetX: 0,
      offsetY: 8
    })
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
    .position({ x: '50%', y: '50%', transform: 'translate(-50%, -50%)' })
  }

  /**
   * 获取错误指示器颜色
   */
  private getErrorIndicatorColor(): string {
    switch (this.severity) {
      case 'low':
        return '#52C41A'
      case 'medium':
        return '#FAAD14'
      case 'high':
        return '#FF7A45'
      case 'critical':
        return '#F5222D'
      default:
        return '#666666'
    }
  }

  /**
   * 获取错误背景颜色
   */
  private getErrorBackgroundColor(): string {
    switch (this.severity) {
      case 'low':
        return '#F6FFED'
      case 'medium':
        return '#FFF7E6'
      case 'high':
        return '#FFF1F0'
      case 'critical':
        return '#FFF1F0'
      default:
        return '#FFF7E6'
    }
  }

  /**
   * 获取错误主色调
   */
  private getErrorPrimaryColor(): string {
    switch (this.severity) {
      case 'low':
        return '#52C41A'
      case 'medium':
        return '#FAAD14'
      case 'high':
        return '#FF7A45'
      case 'critical':
        return '#F5222D'
      default:
        return '#FAAD14'
    }
  }

  /**
   * 获取错误文字颜色
   */
  private getErrorTextColor(): string {
    switch (this.severity) {
      case 'low':
        return '#262626'
      case 'medium':
        return '#262626'
      case 'high':
        return '#FFFFFF'
      case 'critical':
        return '#FFFFFF'
      default:
        return '#262626'
    }
  }

  /**
   * 获取错误次要文字颜色
   */
  private getErrorSecondaryTextColor(): string {
    switch (this.severity) {
      case 'low':
        return '#595959'
      case 'medium':
        return '#595959'
      case 'high':
        return '#D9D9D9'
      case 'critical':
        return '#D9D9D9'
      default:
        return '#595959'
    }
  }
}

/**
 * 全局错误处理管理器
 * 统一管理错误处理和用户反馈
 */
export class ErrorHandler {
  private static instance: ErrorHandler
  private errorQueue: Array<{ type: ErrorType; message: string; timestamp: number; severity: ErrorSeverity }> = []
  private static isHandling: boolean = false

  static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler()
    }
    return ErrorHandler.instance
  }

  /**
   * 处理错误
   */
  static handleError(error: {
    type: ErrorType
    message: string
    details?: string
    severity?: ErrorSeverity
    errorCode?: string
    context?: string
  }): void {
    // 防止重复处理
    if (ErrorHandler.isHandling) return

    const errorRecord = {
      type: error.type || 'unknown',
      message: error.message || '未知错误',
      timestamp: Date.now(),
      severity: error.severity || 'medium',
      context: error.context || 'unknown'
    }

    // 添加到错误队列
    ErrorHandler.errorQueue.push(errorRecord)

    // 限制队列大小
    if (ErrorHandler.errorQueue.length > 100) {
      ErrorHandler.errorQueue.shift()
    }

    // 记录错误日志
    console.error(`[${errorRecord.severity.toUpperCase()}] ${errorRecord.type}: ${errorRecord.message}`, error)

    // 根据严重程度决定处理方式
    switch (errorRecord.severity) {
      case 'critical':
        ErrorHandler.handleCriticalError(errorRecord)
        break
      case 'high':
        ErrorHandler.handleHighError(errorRecord)
        break
      case 'medium':
        ErrorHandler.handleMediumError(errorRecord)
        break
      default:
        ErrorHandler.handleLowError(errorRecord)
        break
    }
  }

  /**
   * 处理严重错误
   */
  private static handleCriticalError(error: any): void {
    // 严重错误需要立即处理
    ErrorHandler.isHandling = true

    // 这里可以添加严重错误的特殊处理逻辑
    // 例如：发送错误报告、停止相关操作、显示紧急错误提示等

    setTimeout(() => {
      ErrorHandler.isHandling = false
    }, 1000)
  }

  /**
   * 处理高级错误
   */
  private static handleHighError(error: any): void {
    // 高级错误需要用户关注
    ErrorHandler.isHandling = true

    // 记录错误到本地存储（如果需要）
    // 这里可以添加本地错误日志记录功能

    setTimeout(() => {
      ErrorHandler.isHandling = false
    }, 500)
  }

  /**
   * 处理中级错误
   */
  private static handleMediumError(error: any): void {
    // 中级错误需要适当处理
    ErrorHandler.isHandling = true

    setTimeout(() => {
      ErrorHandler.isHandling = false
    }, 300)
  }

  /**
   * 处理低级错误
   */
  private static handleLowError(error: any): void {
    // 低级错误可以静默处理
    console.warn(`Low severity error: ${error.message}`)
  }

  /**
   * 获取错误统计
   */
  static getErrorStats(): {
    total: number
    byType: Record<ErrorType, number>
    bySeverity: Record<ErrorSeverity, number>
    byTimeRange: Record<string, number>
  } {
    const now = Date.now()
    const last24Hours = now - 24 * 60 * 60 * 1000
    const last1Hour = now - 1 * 60 * 60 * 1000
    const last1Minute = now - 1 * 60 * 1000

    const stats = {
      total: ErrorHandler.errorQueue.length,
      byType: {} as Record<ErrorType, number>,
      bySeverity: {} as Record<ErrorSeverity, number>,
      byTimeRange: {} as Record<string, number>
    }

    // 统计错误类型
    for (const error of ErrorHandler.errorQueue) {
      stats.byType[error.type] = (stats.byType[error.type] || 0) + 1
      stats.bySeverity[error.severity] = (stats.bySeverity[error.severity] || 0) + 1

      // 统计时间范围
      if (error.timestamp >= last24Hours) {
        stats.byTimeRange['24h'] = (stats.byTimeRange['24h'] || 0) + 1
      } else if (error.timestamp >= last1Hour) {
        stats.byTimeRange['1h'] = (stats.byTimeRange['1h'] || 0) + 1
      } else if (error.timestamp >= last1Minute) {
        stats.byTimeRange['1m'] = (stats.byTimeRange['1m'] || 0) + 1
      }
    }

    return stats
  }

  /**
   * 清除错误队列
   */
  static clearErrorQueue(): void {
    ErrorHandler.errorQueue = []
  }

  /**
   * 获取最近的错误
   */
  static getRecentErrors(limit: number = 10): Array<any> {
    return ErrorHandler.errorQueue
      .slice(-limit)
      .reverse()
  }

  /**
   * 格式化错误消息
   */
  static formatErrorMessage(error: any): string {
    if (typeof error === 'string') return error
    if (error?.message) return error.message
    if (error?.toString) return error.toString()
    return '未知错误'
  }

  /**
   * 获取用户友好的错误消息
   */
  static getUserFriendlyMessage(error: any): string {
    const message = ErrorHandler.formatErrorMessage(error)

    // 根据错误类型提供友好的消息
    const friendlyMessages: Record<string, string> = {
      '网络连接失败': '网络连接出现问题，请检查网络设置后重试',
      '请求超时': '请求超时，请稍后重试',
      '权限不足': '您没有权限执行此操作，请联系管理员',
      '数据验证失败': '输入的信息有误，请检查后重试',
      '服务器错误': '服务器暂时无法响应，请稍后重试',
      '文件操作失败': '文件操作失败，请检查文件权限',
      '未知错误': '操作失败，请稍后重试或联系技术支持'
    }

    return friendlyMessages[message] || friendlyMessages['未知错误']
  }
}