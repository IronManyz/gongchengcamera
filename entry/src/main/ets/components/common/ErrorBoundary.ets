/**
 * 错误边界组件
 * 提供统一的错误捕获和处理机制
 */

export interface ErrorInfo {
  error: Error
  errorInfo?: any
  componentStack?: string
  timestamp: number
  context?: string
}

export interface ErrorBoundaryConfig {
  fallbackComponent?: () => void
  onError?: (error: ErrorInfo) => void
  enableRetry?: boolean
  maxRetries?: number
  context?: string
}

@ComponentV2
export struct ErrorBoundary {
  @Require @Param children: () => void
  @Param config?: ErrorBoundaryConfig = {}
  @State private hasError: boolean = false
  @State private errorInfo?: ErrorInfo
  @State private retryCount: number = 0

  private get errorConfig(): ErrorBoundaryConfig {
    return {
      enableRetry: true,
      maxRetries: 3,
      ...this.config
    }
  }

  /**
   * 错误处理
   */
  private handleError(error: Error, errorInfo?: any): void {
    const errorData: ErrorInfo = {
      error,
      errorInfo,
      timestamp: Date.now(),
      context: this.errorConfig.context || 'Unknown',
      componentStack: errorInfo?.componentStack
    }

    this.errorInfo = errorData
    this.hasError = true

    // 调用自定义错误处理
    if (this.errorConfig.onError) {
      this.errorConfig.onError(errorData)
    }

    // 记录到控制台
    console.error('ErrorBoundary caught error:', errorData)
  }

  /**
   * 重试机制
   */
  private handleRetry(): void {
    if (this.retryCount >= (this.errorConfig.maxRetries || 3)) {
      console.warn('Max retries reached')
      return
    }

    this.retryCount++
    this.hasError = false
    this.errorInfo = undefined
  }

  /**
   * 默认错误界面
   */
  @Builder
  private DefaultErrorFallback() {
    Column({ space: 16 }) {
      // 错误图标
      Column() {
        Text('⚠️')
          .fontSize(48)
          .fontColor('#FF9500')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })

        Text('出现了一些问题')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)

        Text(this.errorInfo?.error.message || '未知错误')
          .fontSize(14)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
      .padding(20)
      .backgroundColor('#FFF8F0')
      .borderRadius(12)
      .border({ width: 1, color: '#FFE4B5' })

      // 操作按钮
      Row({ space: 12 }) {
        if (this.errorConfig.enableRetry && this.retryCount < (this.errorConfig.maxRetries || 3)) {
          Button('重试')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(6)
            .padding({ left: 16, right: 16 })
            .onClick(() => this.handleRetry())
        }

        Button('返回')
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(6)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            // 这里可以添加全局错误处理逻辑
          })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ top: 16 })

      // 重试次数提示
      if (this.retryCount > 0) {
        Text(`已重试 ${this.retryCount}/${this.errorConfig.maxRetries || 3} 次`)
          .fontSize(12)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    if (this.hasError) {
      // 使用自定义错误组件或默认错误组件
      if (this.errorConfig.fallbackComponent) {
        this.errorConfig.fallbackComponent()
      } else {
        this.DefaultErrorFallback()
      }
    } else {
      // 正常渲染子组件
      this.children()
    }
  }
}