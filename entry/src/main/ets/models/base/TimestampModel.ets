/**
 * 时间戳模型类
 * 提供时间相关的工具方法和格式化功能
 */

export class TimestampModel {
  /**
   * 获取当前时间戳（毫秒）
   */
  static now(): number {
    return Date.now()
  }

  /**
   * 获取当前日期时间
   */
  static nowDate(): Date {
    return new Date()
  }

  /**
   * 格式化日期为本地字符串
   */
  static formatDateTime(date: Date, format: 'short' | 'medium' | 'long' = 'medium'): string {
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: format === 'short' ? '2-digit' : format === 'medium' ? 'short' : 'long',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    }

    if (format === 'long') {
      options.second = '2-digit'
      options.hour12 = false
    }

    return date.toLocaleString('zh-CN', options)
  }

  /**
   * 格式化日期为本地字符串（仅日期）
   */
  static formatDate(date: Date, format: 'short' | 'medium' | 'long' = 'medium'): string {
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: format === 'short' ? '2-digit' : format === 'medium' ? 'short' : 'long',
      day: '2-digit'
    }

    return date.toLocaleDateString('zh-CN', options)
  }

  /**
   * 格式化时间为本地字符串（仅时间）
   */
  static formatTime(date: Date, includeSeconds: boolean = false): string {
    const options: Intl.DateTimeFormatOptions = {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    }

    if (includeSeconds) {
      options.second = '2-digit'
    }

    return date.toLocaleTimeString('zh-CN', options)
  }

  /**
   * 计算两个日期之间的时间差
   */
  static timeDiff(from: Date, to: Date = new Date()): {
    days: number
    hours: number
    minutes: number
    seconds: number
    milliseconds: number
    totalMilliseconds: number
  } {
    const diff = to.getTime() - from.getTime()

    return {
      days: Math.floor(diff / (1000 * 60 * 60 * 24)),
      hours: Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
      minutes: Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60)),
      seconds: Math.floor((diff % (1000 * 60)) / 1000),
      milliseconds: diff % 1000,
      totalMilliseconds: diff
    }
  }

  /**
   * 获取相对时间描述（如：刚刚、5分钟前、2小时前等）
   */
  static getRelativeTime(date: Date, baseDate: Date = new Date()): string {
    const diff = baseDate.getTime() - date.getTime()
    const seconds = Math.floor(diff / 1000)

    if (seconds < 10) {
      return '刚刚'
    } else if (seconds < 60) {
      return `${seconds}秒前`
    }

    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) {
      return `${minutes}分钟前`
    }

    const hours = Math.floor(minutes / 60)
    if (hours < 24) {
      return `${hours}小时前`
    }

    const days = Math.floor(hours / 24)
    if (days < 7) {
      return `${days}天前`
    }

    // 超过7天显示具体日期
    return this.formatDate(date)
  }

  /**
   * 检查日期是否为今天
   */
  static isToday(date: Date): boolean {
    const today = new Date()
    return date.toDateString() === today.toDateString()
  }

  /**
   * 检查日期是否为昨天
   */
  static isYesterday(date: Date): boolean {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    return date.toDateString() === yesterday.toDateString()
  }

  /**
   * 检查日期是否为本周
   */
  static isThisWeek(date: Date): boolean {
    const today = new Date()
    const weekStart = new Date(today)
    weekStart.setDate(today.getDate() - today.getDay())
    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekStart.getDate() + 6)

    return date >= weekStart && date <= weekEnd
  }

  /**
   * 获取本周开始日期（周一）
   */
  static getWeekStart(date: Date = new Date()): Date {
    const d = new Date(date)
    const day = d.getDay()
    const diff = d.getDate() - day + (day === 0 ? -6 : 1) // 周日作为0，调整为上周一
    return new Date(d.setDate(diff))
  }

  /**
   * 获取本月开始日期
   */
  static getMonthStart(date: Date = new Date()): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1)
  }

  /**
   * 获取本年开始日期
   */
  static getYearStart(date: Date = new Date()): Date {
    return new Date(date.getFullYear(), 0, 1)
  }

  /**
   * 解析时间字符串为Date对象
   */
  static parseDateTime(dateString: string): Date | null {
    try {
      const date = new Date(dateString)
      return isNaN(date.getTime()) ? null : date
    } catch {
      return null
    }
  }

  /**
   * 将Date对象转换为ISO字符串（本地时区）
   */
  static toISOStringLocal(date: Date): string {
    const offset = date.getTimezoneOffset()
    const localDate = new Date(date.getTime() - offset * 60000)
    return localDate.toISOString().slice(0, -1)
  }

  /**
   * 从ISO字符串创建Date对象（本地时区）
   */
  static fromISOStringLocal(isoString: string): Date {
    const date = new Date(isoString)
    const offset = date.getTimezoneOffset()
    return new Date(date.getTime() + offset * 60000)
  }
}