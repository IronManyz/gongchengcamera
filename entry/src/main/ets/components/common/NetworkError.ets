/**
 * 网络错误处理组件
 * 专门处理网络相关的错误和状态
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface NetworkErrorConfig {
  error?: Error
  onRetry?: () => void
  onSettings?: () => void
  showDetails?: boolean
  customMessage?: string
}

export enum NetworkErrorType {
  NO_CONNECTION = 'NO_CONNECTION',
  TIMEOUT = 'TIMEOUT',
  SERVER_ERROR = 'SERVER_ERROR',
  CLIENT_ERROR = 'CLIENT_ERROR',
  UNKNOWN = 'UNKNOWN'
}

export interface NetworkErrorInfo {
  type: NetworkErrorType
  message: string
  details?: string
  canRetry: boolean
  suggestedAction?: string
}

@ComponentV2
export struct NetworkError {
  @Param config?: NetworkErrorConfig = {}
  @State private errorInfo?: NetworkErrorInfo

  aboutToAppear() {
    this.analyzeError()
  }

  /**
   * 分析错误类型
   */
  private analyzeError(): void {
    const error = this.config?.error
    if (!error) {
      this.errorInfo = {
        type: NetworkErrorType.UNKNOWN,
        message: this.config?.customMessage || '网络请求失败',
        canRetry: true
      }
      return
    }

    // 错误类型判断
    let errorType = NetworkErrorType.UNKNOWN
    let message = this.config?.customMessage || '网络请求失败'
    let details = ''
    let canRetry = true
    let suggestedAction = ''

    const errorMessage = error.message.toLowerCase()

    if (errorMessage.includes('network') || errorMessage.includes('connection')) {
      errorType = NetworkErrorType.NO_CONNECTION
      message = '网络连接失败'
      details = '请检查网络连接后重试'
      suggestedAction = '检查网络设置'
    } else if (errorMessage.includes('timeout')) {
      errorType = NetworkErrorType.TIMEOUT
      message = '请求超时'
      details = '网络响应时间过长，请稍后重试'
      canRetry = true
    } else if (errorMessage.includes('server') || errorMessage.includes('500')) {
      errorType = NetworkErrorType.SERVER_ERROR
      message = '服务器错误'
      details = '服务器暂时无法响应，请稍后重试'
      canRetry = true
    } else if (errorMessage.includes('401') || errorMessage.includes('403')) {
      errorType = NetworkErrorType.CLIENT_ERROR
      message = '认证失败'
      details = '请检查登录状态或权限'
      canRetry = false
      suggestedAction = '重新登录'
    } else if (errorMessage.includes('404')) {
      errorType = NetworkErrorType.CLIENT_ERROR
      message = '资源未找到'
      details = '请求的资源不存在'
      canRetry = false
    }

    this.errorInfo = {
      type: errorType,
      message,
      details,
      canRetry,
      suggestedAction
    }
  }

  /**
   * 获取错误图标
   */
  private getErrorIcon(): string {
    switch (this.errorInfo?.type) {
      case NetworkErrorType.NO_CONNECTION:
        return '📶'
      case NetworkErrorType.TIMEOUT:
        return '⏱️'
      case NetworkErrorType.SERVER_ERROR:
        return '🖥️'
      case NetworkErrorType.CLIENT_ERROR:
        return '🔒'
      default:
        return '❓'
    }
  }

  /**
   * 获取错误颜色
   */
  private getErrorColor(): string {
    switch (this.errorInfo?.type) {
      case NetworkErrorType.NO_CONNECTION:
        return '#FF9500'
      case NetworkErrorType.TIMEOUT:
        return '#FF9500'
      case NetworkErrorType.SERVER_ERROR:
        return '#FF3B30'
      case NetworkErrorType.CLIENT_ERROR:
        return '#007AFF'
      default:
        return '#666666'
    }
  }

  /**
   * 获取主要错误信息
   */
  @Builder
  private ErrorIconSection() {
    Column() {
      Text(this.getErrorIcon())
        .fontSize(48)
        .fontColor(this.getErrorColor())
        .textAlign(TextAlign.Center)
        .margin({ bottom: 12 })

      Text(this.errorInfo?.message || '网络错误')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      if (this.config?.showDetails && this.errorInfo?.details) {
        Text(this.errorInfo.details)
          .fontSize(14)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 操作按钮区域
   */
  @Builder
  private ActionButtons() {
    Column({ space: 12 }) {
      // 重试按钮
      if (this.errorInfo?.canRetry && this.config?.onRetry) {
        Button() {
          Row({ space: 8 }) {
            Text('🔄')
              .fontSize(16)
            Text('重试')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
        }
        .height(44)
        .padding({ left: 24, right: 24 })
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(22)
        .fontColor('#FFFFFF')
        .onClick(() => this.config.onRetry?.())
      }

      // 建议操作按钮
      if (this.errorInfo?.suggestedAction && this.config?.onSettings) {
        Button(this.errorInfo.suggestedAction)
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
          .borderRadius(22)
          .padding({ left: 20, right: 20 })
          .onClick(() => this.config.onSettings?.())
      }

      // 详细信息切换
      if (this.config?.showDetails !== undefined) {
        Button() {
          Text(this.config.showDetails ? '隐藏详情' : '显示详情')
            .fontSize(14)
            .fontColor('#999999')
        }
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 这里可以切换详情显示状态
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column({ space: 24 }) {
      this.ErrorIconSection()
      this.ActionButtons()
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#00000015',
      offsetX: 0,
      offsetY: 4
    })
    .margin(16)
  }
}