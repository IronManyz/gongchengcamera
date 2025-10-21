/**
 * 日志工具类
 * 提供统一的日志记录功能
 */

import hilog from '@ohos.hilog'

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

export class Logger {
  private tag: string
  private static readonly DOMAIN: number = 0xFF00

  constructor(tag: string) {
    this.tag = tag
  }

  private formatMessage(message: string, ...args: any[]): string {
    if (args.length === 0) {
      return message
    }

    try {
      const formattedArgs = args.map(arg => {
        if (typeof arg === 'object') {
          return JSON.stringify(arg, null, 2)
        }
        return String(arg)
      })
      return `${message} ${formattedArgs.join(' ')}`
    } catch (error) {
      return `${message} [Args serialization failed: ${error}]`
    }
  }

  debug(message: string, ...args: any[]): void {
    const formattedMessage = this.formatMessage(message, ...args)
    hilog.debug(Logger.DOMAIN, this.tag, formattedMessage)
  }

  info(message: string, ...args: any[]): void {
    const formattedMessage = this.formatMessage(message, ...args)
    hilog.info(Logger.DOMAIN, this.tag, formattedMessage)
  }

  warn(message: string, ...args: any[]): void {
    const formattedMessage = this.formatMessage(message, ...args)
    hilog.warn(Logger.DOMAIN, this.tag, formattedMessage)
  }

  error(message: string, ...args: any[]): void {
    const formattedMessage = this.formatMessage(message, ...args)
    hilog.error(Logger.DOMAIN, this.tag, formattedMessage)
  }

  /**
   * 创建带有特定前缀的子Logger
   */
  child(prefix: string): Logger {
    return new Logger(`${this.tag}:${prefix}`)
  }

  /**
   * 记录方法执行时间
   */
  async time<T>(
    operation: string,
    fn: () => Promise<T> | T
  ): Promise<T> {
    const startTime = Date.now()
    this.info(`[${operation}] Started`)

    try {
      const result = await fn()
      const duration = Date.now() - startTime
      this.info(`[${operation}] Completed in ${duration}ms`)
      return result
    } catch (error) {
      const duration = Date.now() - startTime
      this.error(`[${operation}] Failed in ${duration}ms`, error)
      throw error
    }
  }

  /**
   * 记录性能指标
   */
  performance(operation: string, metrics: Record<string, number>): void {
    const metricsStr = Object.entries(metrics)
      .map(([key, value]) => `${key}=${value}`)
      .join(', ')
    this.info(`[Performance] ${operation}: ${metricsStr}`)
  }
}