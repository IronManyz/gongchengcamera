/**
 * 通知系统组件
 * 提供完整的通知、提示和反馈机制
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { ToastMessage, ToastPosition, ToastDuration } from './ErrorHandling'

export type NotificationType =
  | 'toast'          // Toast提示
  | 'snackbar'        // 底部提示
  | 'banner'          // 横幅提示
  | 'modal'           // 模态对话框
  | 'alert'           // 警告对话框
  | 'badge'           // 角标通知
  | 'progress'        // 进度通知
  | 'system'          // 系统通知

export type NotificationPriority =
  | 'low' | 'medium' | 'high' | 'urgent'

export type NotificationStyle =
  | 'default' | 'success' | 'warning' | 'error' | 'info'

export interface NotificationConfig {
  type?: NotificationType
  priority?: NotificationPriority
  style?: NotificationStyle
  title?: string
  message?: string
  description?: string
  icon?: string
  duration?: number
  position?: ToastPosition
  showProgress?: boolean
  progress?: number
  actions?: NotificationAction[]
  autoHide?: boolean
  persistent?: boolean
  onClick?: () => void
  onDismiss?: () => void
}

export interface NotificationAction {
  id: string
  title: string
  action?: () => void
  style?: 'primary' | 'secondary' | 'outline'
}

/**
 * 通知管理器
 * 统一管理所有通知的显示和队列
 */
export class NotificationManager {
  private static instance: NotificationManager
  private notifications: Array<{ id: string; config: NotificationConfig; timestamp: number; isVisible: boolean }> = []
  private activeNotifications: Set<string> = new Set()
  private notificationQueue: Array<{ id: string; config: NotificationConfig }> = []
  private nextId: number = 0

  static getInstance(): NotificationManager {
    if (!NotificationManager.instance) {
      NotificationManager.instance = new NotificationManager()
    }
    return NotificationManager.instance
  }

  /**
   * 显示通知
   */
  static show(config: NotificationConfig): string {
    const id = this.generateNotificationId()
    const notification = {
      id,
      config,
      timestamp: Date.now(),
      isVisible: true
    }

    // 添加到通知列表
    this.notifications.push(notification)
    this.activeNotifications.add(id)

    return id
  }

  /**
   * 显示Toast
   */
  static showToast(message: string, type?: 'success' | 'error' | 'warning' | 'info', duration?: ToastDuration): string {
    return this.show({
      type: 'toast',
      message,
      style: type as NotificationStyle || 'default',
      duration: duration || 'medium'
    })
  }

  /**
   * 显示底部提示
   */
  static showSnackbar(message: string, action?: NotificationAction, duration?: ToastDuration): string {
    return this.show({
      type: 'snackbar',
      message,
      action,
      duration: duration || 'long'
    })
  }

  /**
   * 显示模态对话框
   */
  static showModal(title: string, message: string, config?: Partial<NotificationConfig>): string {
    return this.show({
      type: 'modal',
      title,
      message,
      style: config?.style || 'default',
      persistent: true,
      autoHide: false,
      ...config
    })
  }

  /**
   * 显示警告对话框
   */
  static showAlert(title: string, message: string, config?: Partial<NotificationConfig>): string {
    return this.show({
      type: 'alert',
      title,
      message,
      style: 'warning',
      persistent: false,
      autoHide: false,
      ...config
    })
  }

  /**
   * 显示进度通知
   */
  static showProgress(title: string, message: string, progress: number, config?: Partial<NotificationConfig>): string {
    return this.show({
      type: 'progress',
      title,
      message,
      showProgress: true,
      progress,
      persistent: true,
      autoHide: false,
      ...config
    })
  }

  /**
   * 隐藏指定通知
   */
  static hide(notificationId: string): void {
    const notificationIndex = this.notifications.findIndex(n => n.id === notificationId)
    if (notificationIndex > -1) {
      const notification = this.notifications[notificationIndex]
      notification.isVisible = false
      this.activeNotifications.delete(notificationId)

      // 如果有配置的自动隐藏，则设置定时器
      if (notification.config?.autoHide && notification.config?.duration) {
        setTimeout(() => {
          this.removeNotification(notificationId)
        }, notification.config.duration)
      }
    }
  }

  /**
   * 移除通知
   */
  static removeNotification(notificationId: string): void {
    this.notifications = this.notifications.filter(n => n.id !== notificationId)
    this.activeNotifications.delete(notificationId)
  }

  /**
   * 清除所有通知
   */
  static clearAll(): void {
    this.notifications = []
    this.activeNotifications.clear()
    this.notificationQueue = []
  }

  /**
   * 生成通知ID
   */
  private static generateNotificationId(): string {
    return `notification_${++this.nextId}_${Date.now()}`
  }

  /**
   * 处理通知队列
   */
  static processQueue(): void {
    if (this.notificationQueue.length > 0) {
      const nextConfig = this.notificationQueue.shift()
      this.show(nextConfig)
    }
  }

  /**
   * 添加通知到队列
   */
  static queueNotification(config: NotificationConfig): string {
    const id = this.generateNotificationId()
    this.notificationQueue.push({ id, config })
    return id
  }

  /**
   * 处理通知冲突
   */
  private static handleNotificationConflict(config: NotificationConfig): void {
    // 根据优先级决定是否显示新通知
    const currentNotifications = this.getActiveNotificationsByPriority(config.priority || 'medium')

    if (config.priority === 'urgent' || currentNotifications.length === 0) {
      return
    }

    // 隐藏低优先级通知以显示高优先级通知
    if (config.priority === 'low' && currentNotifications.length > 0) {
      const lowPriorityNotifications = currentNotifications.filter(n =>
        this.getNotificationConfig(n).priority === 'low'
      )

      for (const notification of lowPriorityNotifications) {
        this.hide(notification.id)
      }
    }
  }

  /**
   * 获取指定优先级的活跃通知
   */
  private static getActiveNotificationsByPriority(priority: NotificationPriority): Array<{ id: string; config: NotificationConfig }> {
    return Array.from(this.activeNotifications)
      .filter(([_, notification]) =>
        this.getNotificationConfig(notification).priority === priority
      )
  }

  /**
   * 获取通知配置
   */
  private static getNotificationConfig(notificationId: string): NotificationConfig {
    const notification = this.notifications.find(n => n.id === notificationId)
    return notification?.config || {}
  }

  /**
   * 获取通知统计
   */
  static getNotificationStats(): {
    total: number
    active: number
    byType: Record<string, number>
    byPriority: Record<NotificationPriority, number>
    byStyle: Record<NotificationStyle, number>
  } {
    const now = Date.now()
    const activeNotifications = Array.from(this.activeNotifications)

    const stats = {
      total: this.notifications.length,
      active: activeNotifications.length,
      byType: {} as Record<string, number>,
      byPriority: {} as Record<NotificationPriority, number>,
      byStyle: {} as Record<NotificationStyle, number>
    }

    for (const notification of this.notifications) {
      if (notification.isVisible && now - notification.timestamp < 60000) {
        // 统计类型
        const config = this.getNotificationConfig(notification.id)
        stats.byType[config.type || 'toast'] = (stats.byType[config.type || 'toast'] || 0) + 1

        // 统计优先级
        stats.byPriority[config.priority || 'medium'] = (stats.byPriority[config.priority || 'medium'] || 0) + 1

        // 统计样式
        stats.byStyle[config.style || 'default'] = (stats.byStyle[config.style || 'default'] || 0) + 1
      }
    }

    return stats
  }
}

/**
 * 通知组件容器
 * 提供所有类型的通知显示
 */
@ComponentV2
export struct NotificationContainer {
  @Param notifications: NotificationConfig[] = []
  @Param position?: 'top' | 'bottom' | 'center' = 'top'
  @Param spacing: number = 8
  @Param maxVisible: number = 3

  @State private visibleNotifications: Set<string> = new Set()

  build() {
    Column({ space: this.spacing }) {
      ForEach(this.notifications.slice(0, this.maxVisible), (config: NotificationConfig, index: number) => {
        this.buildNotification(config, index)
      })
    }
    .width('100%')
    .position(this.getContainerPosition())
  }

  /**
   * 构建单个通知
   */
  @Builder
  private buildNotification(config: NotificationConfig, index: number) {
    if (!this.visibleNotifications.has(config.id || '')) {
      switch (config.type) {
        case 'toast':
          this.buildToastNotification(config)
          break
        case 'snackbar':
          this.buildSnackbarNotification(config)
          break
        case 'banner':
          this.buildBannerNotification(config)
          break
        case 'modal':
          this.buildModalNotification(config)
          break
        case 'alert':
          this.buildAlertDialog(config)
          break
        case 'progress':
          this.buildProgressNotification(config)
          break
        default:
          this.buildToastNotification(config)
          break
      }
    }
  }

  /**
   * 构建Toast通知
   */
  @Builder
  private buildToastNotification(config: NotificationConfig) {
    ToastMessage({
      message: config.message || '通知',
      type: config.style || 'default' as 'success' | 'error' | 'warning' | 'info',
      position: config.position || 'bottom',
      duration: config.duration || 'medium',
      showButton: !!config.actions && config.actions.length > 0,
      buttonText: config.actions?.[0]?.title || '确定'
      onButtonPress: config.actions?.[0]?.action
    })
  }

  /**
   * 构建底部提示通知
   */
  @Builder
  private buildSnackbarNotification(config: NotificationConfig) {
    ToastMessage({
      message: config.message || '通知',
      type: 'info',
      position: 'bottom',
      duration: config.duration || 'long',
      showButton: !!config.actions && config.actions.length > 0,
      buttonText: config.actions?.[0]?.title || '确定',
      onButtonPress: config.actions?.[0]?.action
    })
  }

  /**
   * 构建横幅通知
   */
  @Builder
  private buildBannerNotification(config: NotificationConfig) {
    Column() {
      Row() {
        // 图标和关闭按钮
        Row() {
          if (config.icon) {
            Text(config.icon)
              .fontSize(20)
              .margin({ right: 8 })
          }

          Blank()

          Button() {
            Text('×')
              .fontSize(16)
              .fontColor(ThemeManager.getCurrentTextSecondaryColor())
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.removeNotification(config.id || '')
              })
          }
          .width(24)
          .height(24)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 8 })

        // 标题和消息
        Column() {
          Text(config.title || '通知')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeManager.getCurrentTextColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(config.message || '')
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentTextSecondaryColor())
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 操作按钮（如果有）
      if (config.actions && config.actions.length > 0) {
        Row() {
          ForEach(config.actions.slice(0, 2), (action: NotificationAction) => {
            Button(action.title)
              .fontSize(14)
              .fontColor(this.getActionButtonTextColor(action.style))
              .backgroundColor(this.getActionButtonBackgroundColor(action.style))
              .borderRadius(4)
              .onClick(() => {
                action.action?.()
                this.removeNotification(config.id || '')
              })
            .margin({ left: 8 })
          })
        }
        .width('100%')
        .margin({ top: 16 })
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.getBannerBackgroundColor(config.style))
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建模态对话框
   */
  @Builder
  private buildModalNotification(config: NotificationConfig) {
    Column() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (!config.persistent) {
            this.removeNotification(config.id || '')
          }
        })

        // 对话框内容
        Column() {
          Text(config.title || '提示')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeManager.getCurrentTextColor())
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })

          Text(config.message || '')
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentTextSecondaryColor())
            .textAlign(TextAlign.Center)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(20)

          // 操作按钮
          if (config.actions && config.actions.length > 0) {
            Row() {
              ForEach(config.actions, (action: NotificationAction) => {
                Button(action.title)
                  .fontSize(16)
                  .fontColor(this.getActionButtonTextColor(action.style))
                  .backgroundColor(this.getActionButtonBackgroundColor(action.style))
                  .borderRadius(6)
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .onClick(() => {
                    action.action?.()
                    this.removeNotification(config.id || '')
                  })
                  .margin({ left: 8 })
              })
            }
            .width('100%')
            .margin({ top: 24 })
            .justifyContent(FlexAlign.Center)
          } else {
            Button('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor(ThemeManager.getCurrentPrimaryColor())
              .borderRadius(6)
              .padding({ left: 24, right: 24, top: 10, bottom: 10 })
              .onClick(() => {
                this.removeNotification(config.id || '')
              })
              .margin({ top: 24 })
              .width('100%')
              .justifyContent(FlexAlign.Center)
          }
        }
      }
      .width(320)
      .backgroundColor(ThemeManager.getCurrentBackgroundColor())
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .position({ x: '50%', y: '50%', transform: 'translate(-50%, -50%)' })
  }

  /**
   * 构建警告对话框
   */
  @Builder
  private buildAlertDialog(config: NotificationConfig) {
    Column() {
      Text('⚠️')
        .fontSize(48)
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Center)

      Text(config.title || '警告')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getAlertTextColor())
        .textAlign(TextAlign.Center)
        .margin({ bottom: 8 })

      Text(config.message || '')
        .fontSize(14)
        .fontColor(this.getAlertTextColor())
        .textAlign(TextAlign.Center)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(20)

      // 操作按钮
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor(this.getAlertButtonTextColor())
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: this.getAlertButtonTextColor() })
          .borderRadius(6)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .onClick(() => {
            this.removeNotification(config.id || '')
          })
          .margin({ right: 8 })

        Button('确认')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getAlertButtonBackgroundColor('primary'))
          .borderRadius(6)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .onClick(() => {
            if (config.actions?.[0]?.action) {
              config.actions[0].action()
            }
            this.removeNotification(config.id || '')
          })
          .margin({ right: 8 })
      }
      .width('100%')
      .margin({ top: 24 })
      .justifyContent(FlexAlign.Center)
    }
    .width('320')
    .padding(24)
    .backgroundColor(this.getAlertBackgroundColor())
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 4
    })
  }

  /**
   * 构建进度通知
   */
  @Builder
  private buildProgressNotification(config: NotificationConfig) {
    Column() {
      // 进度条
      Progress({
        value: config.progress || 0,
        total: 100,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(6)
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(3)
        .margin({ bottom: 16 })

      // 标题和消息
      Text(config.title || '进度')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.getCurrentTextColor())
        .textAlign(TextAlign.Center)

      Text(config.message || '正在处理中...')
        .fontSize(14)
        .fontColor(ThemeManager.getCurrentTextSecondaryColor())
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(ThemeManager.getCurrentBackgroundColor())
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 获取容器位置
   */
  private getContainerPosition(): { [key: string]: string | number } {
    const positions = {
      'top': { top: 32 },
      'bottom': { bottom: 32 },
      'center': { top: '50%', transform: 'translateY(-50%)' }
    }
    return positions[this.position] || positions['top']
  }

  /**
   * 获取操作按钮文字颜色
   */
  private getActionButtonTextColor(style?: string): string {
    switch (style) {
      case 'primary':
        return '#FFFFFF'
      case 'secondary':
        return '#FFFFFF'
      case 'outline':
        return ThemeManager.getCurrentPrimaryColor()
      case 'text':
        return ThemeManager.getCurrentPrimaryColor()
      default:
        return '#FFFFFF'
    }
  }

  /**
   * 获取操作按钮背景颜色
   */
  private getActionButtonBackgroundColor(style?: string): string {
    switch (style) {
      case 'primary':
        return ThemeManager.getCurrentPrimaryColor()
      case 'secondary':
        return ThemeManager.getCurrentSecondaryColor()
      case 'outline':
        return ThemeManager.getCurrentBackgroundColor()
      case 'text':
        return Color.Transparent
      default:
        return ThemeManager.getCurrentPrimaryColor()
    }
  }

  /**
   * 获取横幅背景颜色
   */
  private getBannerBackgroundColor(style?: string): string {
    switch (style) {
      case 'success':
        return '#F6FFED'
      case 'warning':
        return '#FFF7E6'
      case 'error':
        return '#FFF2F2E'
      case 'info':
        return '#E6F7FF'
      default:
        return ThemeManager.getCurrentPrimaryColor()
    }
  }

  /**
   * 获取警告背景颜色
   */
  private getAlertBackgroundColor(): string {
    return ThemeManager.getCurrentSurfaceColor()
  }

  /**
   * 获取警告文字颜色
   */
  private getAlertTextColor(): string {
    return ThemeManager.getCurrentTextColor()
  }

  /**
   * 获取警告按钮文字颜色
   */
  private getAlertButtonTextColor(type?: string): string {
    return type === 'primary' ? '#FFFFFF' : ThemeManager.getCurrentPrimaryColor()
  }
  }

  /**
   * 获取警告按钮背景颜色
   */
  private getAlertButtonBackgroundColor(type?: string): string {
    return type === 'primary' ? ThemeManager.getCurrentPrimaryColor() : ThemeManager.getCurrentSurfaceColor()
  }
  }
}