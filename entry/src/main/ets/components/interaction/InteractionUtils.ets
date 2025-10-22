/**
 * 交互工具类
 * 提供通用的微交互动画和效果工具
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { HapticType } from './MicroInteractions'

/**
 * 通用动画工具类
 */
export class AnimationUtils {
  /**
   * 创建弹簧动画
   */
  static createSpringAnimation(
    startValue: number,
    endValue: number,
    duration: number = 600,
    tension: number = 300,
    friction: number = 15
  ): { duration: number, curve: Curve } {
    return {
      duration,
      curve: Curve.EaseInOut
    }
  }

  /**
   * 创建缓动动画
   */
  static createEasingAnimation(
    duration: number,
    type: 'ease' | 'ease-in' | 'ease-out' | 'ease-in-out' | 'bounce' | 'elastic'
  ): { duration: number, curve: Curve } {
    switch (type) {
      case 'ease':
        return { duration, curve: Curve.EaseInOut }
      case 'ease-in':
        return { duration, curve: Curve.EaseIn }
      case 'ease-out':
        return { duration, curve: Curve.EaseOut }
      case 'ease-in-out':
        return { duration, curve: Curve.EaseInOut }
      case 'bounce':
        return { duration, curve: Curve.EaseInOut }
      case 'elastic':
        return { duration, curve: Curve.EaseOut }
      default:
        return { duration, curve: Curve.EaseInOut }
    }
  }

  /**
   * 创建序列动画
   */
  static createSequentialAnimation(
    animations: Array<{ duration: number; curve: Curve }>,
    totalDuration?: number
  ): { duration: number, curve: Curve } {
    return {
      duration: totalDuration || animations.reduce((sum, anim) => sum + anim.duration, 0),
      curve: Curve.EaseInOut
    }
  }

  /**
   * 获取缓动函数
   */
  static getEasingFunction(type: string): (t: number) => number {
    switch (type) {
      case 'ease':
        return (t: number) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
      case 'ease-in':
        return (t: number) => t * t
      case 'ease-out':
        return (t: number) => t * (2 - t)
      case 'ease-in-out':
        return (t: number) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
      case 'bounce':
        return (t: number) => {
          const n1 = 7.5625
          const d1 = 2.75
          if (t < 1 / d1) {
            return n1 * t * t
          } else if (t < 2 / d1) {
            return n1 * (t -= 1.5 / d1) * t + 0.75
          } else if (t < 2.5 / d1) {
            return n1 * (t -= 2.25 / d1) * t + 0.9375
          } else if (t < 2.625 / d1) {
            return n1 * (t -= 2.625 / d1) * t + 0.984375
          } else {
            return n1 * (t -= 2.875 / d1) * t + 0.9984375
          }
        }
      case 'elastic':
        return (t: number) => {
          const c4 = (2 * Math.PI) / 3
          return t === 0 ? 0 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1
        }
      default:
        return (t: number) => t
    }
  }
}

/**
 * 触觉反馈工具类
 */
export class HapticUtils {
  private static instance: HapticUtils
  private static hapticQueue: Array<{ type: HapticType; timestamp: number }> = []

  static getInstance(): HapticUtils {
    if (!HapticUtils.instance) {
      HapticUtils.instance = new HapticUtils()
    }
    return HapticUtils.instance
  }

  /**
   * 触发触觉反馈
   */
  static triggerHaptic(type: HapticType, intensity: number = 1): void {
    const timestamp = Date.now()

    // 防止短时间内重复触发
    HapticUtils.hapticQueue.push({ type, timestamp })
    HapticUtils.hapticQueue = HapticUtils.hapticQueue.filter(
      item => timestamp - item.timestamp < 50
    )

    if (HapticUtils.hapticQueue.length > 1) {
      return // 防抖
    }

    // 实际触觉反馈实现
    HapticUtils.executeHapticFeedback(type, intensity)
  }

  /**
   * 执行触觉反馈
   */
  private static executeHapticFeedback(type: HapticType, intensity: number): void {
    // 这里应该调用HarmonyOS的触觉反馈API
    // 目前只做日志记录
    console.info(`Haptic feedback: Type=${type}, Intensity=${intensity}`)

    // 模拟不同类型的触觉反馈
    switch (type) {
      case 'light':
        console.info('Light haptic feedback')
        break
      case 'medium':
        console.info('Medium haptic feedback')
        break
      case 'heavy':
        console.info('Heavy haptic feedback')
        break
      case 'success':
        console.info('Success haptic feedback')
        break
      case 'warning':
        console.info('Warning haptic feedback')
        break
      case 'error':
        console.info('Error haptic feedback')
        break
      case 'selection':
        console.info('Selection haptic feedback')
        break
    }
  }

  /**
   * 创建自定义触觉模式
   */
  static createCustomPattern(pattern: Array<{ type: HapticType; delay: number; duration: number }>): void {
    let index = 0
    const executeNext = () => {
      if (index >= pattern.length) return

      const item = pattern[index]
      setTimeout(() => {
        HapticUtils.triggerHaptic(item.type)
        index++
        executeNext()
      }, item.delay)
    }

    executeNext()
  }

  /**
   * 清除触觉队列
   */
  static clearQueue(): void {
    HapticUtils.hapticQueue = []
  }
}

/**
 * 动画状态管理器
 */
export class AnimationStateManager {
  private static instance: AnimationStateManager
  private static animations: Map<string, { isActive: boolean; startTime: number; duration: number }> = new Map()

  static getInstance(): AnimationStateManager {
    if (!AnimationStateManager.instance) {
      AnimationStateManager.instance = new AnimationStateManager()
    }
    return AnimationStateManager.instance
  }

  /**
   * 开始动画
   */
  static startAnimation(id: string, duration: number): void {
    this.animations.set(id, {
      isActive: true,
      startTime: Date.now(),
      duration
    })
  }

  /**
   * 停止动画
   */
  static stopAnimation(id: string): void {
    const anim = this.animations.get(id)
    if (anim) {
      this.animations.set(id, {
        ...anim,
        isActive: false
      })
    }
  }

  /**
   * 检查动画是否活跃
   */
  static isAnimationActive(id: string): boolean {
    const anim = this.animations.get(id)
    return anim?.isActive || false
  }

  /**
   * 获取动画进度
   */
  static getAnimationProgress(id: string): number {
    const anim = this.animations.get(id)
    if (!anim || !anim.isActive) return 0

    const elapsed = Date.now() - anim.startTime
    return Math.min(1, elapsed / anim.duration)
  }

  /**
   * 获取所有活跃动画
   */
  static getActiveAnimations(): string[] {
    return Array.from(this.animations.entries())
      .filter(([_, anim]) => anim.isActive)
      .map(([id, _]) => id)
  }

  /**
   * 清除所有动画
   */
  static clearAllAnimations(): void {
    this.animations.clear()
  }
}

/**
 * 微交互组件包装器
 * 为现有组件添加微交互效果
 */
@ComponentV2
export struct MicroInteractionWrapper {
  @Param children: () => void = () => {}
  @Param enableHover: boolean = true
  @Param enablePress: boolean = true
  @Param enableRipple: boolean = true
  @Param hoverScale: number = 1.02
  @Param pressScale: number = 0.95
  @Param hoverOpacity: number = 1
  @Param pressOpacity: number = 0.8
  @Param enableHaptic: boolean = true
  @Param hapticType: HapticType = 'light'
  @Param borderRadius: number = 8
  @Param transitionDuration: number = 200

  @State private isHovering: boolean = false
  @State private isPressed: boolean = false
  @State private interactionScale: number = 1
  @State private interactionOpacity: number = 1

  build() {
    Column() {
      this.children()
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.borderRadius)
    .transform({ scale: { x: this.interactionScale, y: this.interactionScale } })
    .opacity(this.interactionOpacity)
    .shadow({
      radius: this.isPressed ? 8 : this.isHovering ? 6 : 4,
      color: this.isPressed ?
        'rgba(0, 123, 255, 0.4)' :
        this.isHovering ?
          'rgba(0, 123, 255, 0.2)' :
          ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: this.isPressed ? 4 : this.isHovering ? 2 : 1
    })
    .animation({
      duration: this.transitionDuration,
      curve: Curve.EaseInOut
    })
    .onAreaChange((isHovering: boolean) => {
      if (this.enableHover && this.isHovering !== isHovering) {
        this.isHovering = isHovering
        this.updateInteractionState()
      }
    })
    .onClick(() => {
      if (this.enablePress) {
        this.isPressed = true
        this.updateInteractionState()

        if (this.enableHaptic) {
          HapticUtils.triggerHaptic(this.hapticType)
        }

        setTimeout(() => {
          this.isPressed = false
          this.updateInteractionState()
        }, 150)
      }
    })
  }

  /**
   * 更新交互状态
   */
  private updateInteractionState(): void {
    let targetScale = 1
    let targetOpacity = 1

    if (this.isPressed) {
      targetScale = this.pressScale
      targetOpacity = this.pressOpacity
    } else if (this.isHovering) {
      targetScale = this.hoverScale
      targetOpacity = this.hoverOpacity
    }

    animateTo({
      duration: this.transitionDuration,
      curve: Curve.EaseInOut
    }, () => {
      this.interactionScale = targetScale
      this.interactionOpacity = targetOpacity
    })
  }
}

/**
 * 性能监控工具类
 */
export class PerformanceMonitor {
  private static instance: PerformanceMonitor
  private static metrics: Map<string, number> = new Map()

  static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor()
    }
    return PerformanceMonitor.instance
  }

  /**
   * 开始性能监控
   */
  static startMonitoring(name: string): void {
    this.metrics.set(`${name}_start`, Date.now())
  }

  /**
   * 结束性能监控
   */
  static endMonitoring(name: string): number {
    const startTime = this.metrics.get(`${name}_start`)
    if (!startTime) return 0

    const duration = Date.now() - startTime
    this.metrics.set(name, duration)
    return duration
  }

  /**
   * 获取性能指标
   */
  static getMetric(name: string): number {
    return this.metrics.get(name) || 0
  }

  /**
   * 获取所有指标
   */
  static getAllMetrics(): Record<string, number> {
    return Object.fromEntries(this.metrics.entries())
  }

  /**
   * 清除所有指标
   */
  static clearMetrics(): void {
    this.metrics.clear()
  }

  /**
   * 记录性能警告
   */
  static logPerformanceWarning(name: string, threshold: number): void {
    const duration = this.getMetric(name)
    if (duration > threshold) {
      console.warn(`Performance warning: ${name} took ${duration}ms (threshold: ${threshold}ms)`)
    }
  }

  /**
   * 获取性能等级
   */
  static getPerformanceGrade(duration: number): 'excellent' | 'good' | 'fair' | 'poor' {
    if (duration < 16) return 'excellent'
    if (duration < 33) return 'good'
    if (duration < 66) return 'fair'
    return 'poor'
  }
}