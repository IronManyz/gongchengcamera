/**
 * Toast通知组件
 * 提供统一的消息提示功能
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface ToastConfig {
  message: string
  type?: 'success' | 'error' | 'warning' | 'info'
  duration?: number
  position?: 'top' | 'center' | 'bottom'
  showIcon?: boolean
  dismissible?: boolean
}

export interface ToastItem extends ToastConfig {
  id: string
  timestamp: number
}

@ComponentV2
export struct Toast {
  @State private toasts: ToastItem[] = []
  @State private isVisible: boolean = false
  @Watch('toasts') private onToastsChange() {
    this.isVisible = this.toasts.length > 0
  }

  /**
   * 显示Toast消息
   */
  static show(config: ToastConfig): string {
    // 这里需要通过全局状态管理来实现
    // 暂时使用console.log作为示例
    console.log(`Toast: ${config.message}`)
    return 'toast-id'
  }

  /**
   * 成功消息
   */
  static success(message: string, duration?: number): string {
    return Toast.show({
      message,
      type: 'success',
      duration: duration || 3000
    })
  }

  /**
   * 错误消息
   */
  static error(message: string, duration?: number): string {
    return Toast.show({
      message,
      type: 'error',
      duration: duration || 5000
    })
  }

  /**
   * 警告消息
   */
  static warning(message: string, duration?: number): string {
    return Toast.show({
      message,
      type: 'warning',
      duration: duration || 4000
    })
  }

  /**
   * 信息消息
   */
  static info(message: string, duration?: number): string {
    return Toast.show({
      message,
      type: 'info',
      duration: duration || 3000
    })
  }

  /**
   * 隐藏指定Toast
   */
  static hide(toastId: string): void {
    console.log(`Hide toast: ${toastId}`)
  }

  /**
   * 清除所有Toast
   */
  static clear(): void {
    console.log('Clear all toasts')
  }

  private getIconColor(type: string): string {
    switch (type) {
      case 'success': return '#52C41A'
      case 'error': return '#FF4D4F'
      case 'warning': return '#FAAD14'
      case 'info':
      default: return '#1890FF'
    }
  }

  private getBackgroundColor(type: string): string {
    switch (type) {
      case 'success': return '#F6FFED'
      case 'error': return '#FFF2F0'
      case 'warning': return '#FFFBE6'
      case 'info':
      default: return '#F0F9FF'
    }
  }

  private getBorderColor(type: string): string {
    switch (type) {
      case 'success': return '#B7EB8F'
      case 'error': return '#FFCCC7'
      case 'warning': return '#FFE58F'
      case 'info':
      default: return '#91D5FF'
    }
  }

  private getIcon(type: string): string {
    switch (type) {
      case 'success': return '✓'
      case 'error': return '✕'
      case 'warning': return '⚠'
      case 'info':
      default: return 'ℹ'
    }
  }

  @Builder
  private ToastItem(toast: ToastItem) {
    Row({ space: 12 }) {
      // 图标
      if (toast.showIcon !== false) {
        Text(this.getIcon(toast.type || 'info'))
          .fontSize(16)
          .fontColor(this.getIconColor(toast.type || 'info'))
          .fontWeight(FontWeight.Bold)
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
      }

      // 消息内容
      Text(toast.message)
        .fontSize(14)
        .fontColor('#333333')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      // 关闭按钮
      if (toast.dismissible) {
        Button('✕')
          .fontSize(12)
          .fontColor('#999999')
          .backgroundColor(Color.Transparent)
          .width(20)
          .height(20)
          .onClick(() => {
            this.removeToast(toast.id)
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.getBackgroundColor(toast.type || 'info'))
    .borderRadius(8)
    .border({ width: 1, color: this.getBorderColor(toast.type || 'info') })
    .shadow({
      radius: 6,
      color: '#00000015',
      offsetX: 0,
      offsetY: 2
    })
    .animation({
      duration: 300,
      curve: Curve.EaseInOut,
      delay: 0,
      play: true
    })
    .translate({ x: this.isVisible ? 0 : '100%' })
    .opacity(this.isVisible ? 1 : 0)
  }

  private removeToast(toastId: string): void {
    this.toasts = this.toasts.filter(toast => toast.id !== toastId)
  }

  private autoRemoveToast(toast: ToastItem): void {
    setTimeout(() => {
      this.removeToast(toast.id)
    }, toast.duration || 3000)
  }

  build() {
    if (this.isVisible) {
      Column() {
        ForEach(this.toasts, (toast: ToastItem) => {
          this.ToastItem(toast)
            .margin({ bottom: 8 })
            .onClick(() => {
              if (toast.dismissible) {
                this.removeToast(toast.id)
              }
            })
        })
      }
      .position({ x: 16, y: 80 }) // 顶部位置
      .zIndex(2000)
      .maxWidth('80%')
    }
  }
}

// 全局Toast管理器
export class ToastManager {
  private static instance: ToastManager
  private toastList: ToastItem[] = []

  static getInstance(): ToastManager {
    if (!ToastManager.instance) {
      ToastManager.instance = new ToastManager()
    }
    return ToastManager.instance
  }

  show(config: ToastConfig): string {
    const toastId = `toast_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    const toast: ToastItem = {
      ...config,
      id: toastId,
      timestamp: Date.now()
    }

    this.toastList.push(toast)

    // 自动移除
    setTimeout(() => {
      this.hide(toastId)
    }, config.duration || 3000)

    return toastId
  }

  hide(toastId: string): void {
    this.toastList = this.toastList.filter(toast => toast.id !== toastId)
  }

  clear(): void {
    this.toastList = []
  }

  getAllToasts(): ToastItem[] {
    return [...this.toastList]
  }
}