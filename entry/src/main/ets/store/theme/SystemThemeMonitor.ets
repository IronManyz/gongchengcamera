/**
 * SystemThemeMonitor.ets
 * 系统主题监听功能
 * 监听系统主题变化并通知ThemeStore
 */

import { ThemeType } from './ThemeConstants'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { systemTime } from '@kit.BasicServicesKit'

const TAG = 'SystemThemeMonitor'

/**
 * 系统主题监听器接口
 */
export interface SystemThemeListener {
  onSystemThemeChanged(theme: ThemeType): void
}

/**
 * 系统主题监控器
 * 负责监听系统主题变化
 */
export class SystemThemeMonitor {
  private static instance: SystemThemeMonitor | null = null

  /**
   * 监听器列表
   */
  private listeners: SystemThemeListener[] = []

  /**
   * 当前系统主题
   */
  private currentSystemTheme: ThemeType = ThemeType.LIGHT

  /**
   * 是否正在监听
   */
  private isListening: boolean = false

  /**
   * 监听定时器ID
   */
  private monitorTimer: number | null = null

  /**
   * 监听间隔（毫秒）
   */
  private readonly MONITOR_INTERVAL = 5000 // 5秒检查一次

  /**
   * 获取单例实例
   */
  static getInstance(): SystemThemeMonitor {
    if (!SystemThemeMonitor.instance) {
      SystemThemeMonitor.instance = new SystemThemeMonitor()
    }
    return SystemThemeMonitor.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.initializeSystemTheme()
  }

  /**
   * 添加主题监听器
   */
  addListener(listener: SystemThemeListener): void {
    if (this.listeners.includes(listener)) {
      hilog.warn(0x0000, TAG, 'Listener already added')
      return
    }

    this.listeners.push(listener)
    hilog.debug(0x0000, TAG, `Theme listener added, total: ${this.listeners.length}`)

    // 如果是第一个监听器，开始监听
    if (this.listeners.length === 1 && !this.isListening) {
      this.startMonitoring()
    }
  }

  /**
   * 移除主题监听器
   */
  removeListener(listener: SystemThemeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
      hilog.debug(0x0000, TAG, `Theme listener removed, total: ${this.listeners.length}`)

      // 如果没有监听器了，停止监听
      if (this.listeners.length === 0 && this.isListening) {
        this.stopMonitoring()
      }
    }
  }

  /**
   * 获取当前系统主题
   */
  getCurrentSystemTheme(): ThemeType {
    return this.currentSystemTheme
  }

  /**
   * 开始监听系统主题变化
   */
  private startMonitoring(): void {
    if (this.isListening) {
      return
    }

    this.isListening = true

    // 启动定时器，定期检查系统主题
    this.monitorTimer = setInterval(() => {
      this.checkSystemThemeChange()
    }, this.MONITOR_INTERVAL)

    hilog.info(0x0000, TAG, 'System theme monitoring started')
  }

  /**
   * 停止监听系统主题变化
   */
  private stopMonitoring(): void {
    if (!this.isListening) {
      return
    }

    this.isListening = false

    if (this.monitorTimer) {
      clearInterval(this.monitorTimer)
      this.monitorTimer = null
    }

    hilog.info(0x0000, TAG, 'System theme monitoring stopped')
  }

  /**
   * 检查系统主题变化
   */
  private checkSystemThemeChange(): void {
    try {
      const newTheme = this.detectSystemTheme()

      if (newTheme !== this.currentSystemTheme) {
        const oldTheme = this.currentSystemTheme
        this.currentSystemTheme = newTheme

        hilog.info(0x0000, TAG, `System theme changed from ${oldTheme} to ${newTheme}`)

        // 通知所有监听器
        this.notifyThemeChanged(newTheme)
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to check system theme: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 通知所有监听器主题已变化
   */
  private notifyThemeChanged(theme: ThemeType): void {
    for (const listener of this.listeners) {
      try {
        listener.onSystemThemeChanged(theme)
      } catch (error) {
        hilog.error(0x0000, TAG, `Listener notification failed: ${JSON.stringify(error)}`)
      }
    }
  }

  /**
   * 初始化系统主题
   */
  private initializeSystemTheme(): void {
    try {
      this.currentSystemTheme = this.detectSystemTheme()
      hilog.info(0x0000, TAG, `Initial system theme: ${this.currentSystemTheme}`)
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize system theme: ${JSON.stringify(error)}`)
      // 使用默认主题
      this.currentSystemTheme = ThemeType.LIGHT
    }
  }

  /**
   * 检测当前系统主题
   * 这里需要根据HarmonyOS的API来实现
   * 暂时使用时间模拟主题检测
   */
  private detectSystemTheme(): ThemeType {
    try {
      // 这里应该使用HarmonyOS的API来获取系统主题
      // 例如：使用 @ohos.app.ability.UIAbility 或者其他系统API
      // 暂时使用时间来模拟主题检测（白天为浅色，夜晚为深色）
      const now = systemTime.getTime()
      const hour = new Date(now).getHours()

      // 6:00-18:00 为浅色主题，其他时间为深色主题
      if (hour >= 6 && hour < 18) {
        return ThemeType.LIGHT
      } else {
        return ThemeType.DARK
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to detect system theme: ${JSON.stringify(error)}`)
      return ThemeType.LIGHT // 默认返回浅色主题
    }
  }

  /**
   * 手动触发主题检查
   * 用于测试或特殊情况
   */
  triggerThemeCheck(): void {
    this.checkSystemThemeChange()
  }

  /**
   * 销毁监控器
   */
  destroy(): void {
    this.stopMonitoring()
    this.listeners = []
    this.isListening = false
    hilog.info(0x0000, TAG, 'SystemThemeMonitor destroyed')
  }
}

/**
 * 系统主题监控器单例
 */
export const systemThemeMonitor = SystemThemeMonitor.getInstance()