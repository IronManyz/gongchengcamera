/**
 * 页面加载动画组件
 * 提供多种页面切换和数据加载动画效果
 */

import { ThemeManager } from '../../theme/ThemeManager'

export type LoadingType =
  | 'skeleton'     // 骨架屏加载
  | 'spinner'      // 转圈加载
  | 'progress'     // 进度条加载
  | 'dots'         // 点状动画
  | 'pulse'        // 脉冲动画
  | 'wave'         // 波浪动画
  | 'bounce'       // 弹跳动画
  | 'shimmer'      // 闪光效果
  | 'fade'         // 淡入淡出
  | 'slide'        // 滑动动画
  | 'custom'        // 自定义动画

export type LoadingSize =
  | 'small' | 'medium' | 'large' | 'full'

export type LoadingPosition =
  | 'center' | 'top' | 'bottom'

@ComponentV2
export struct PageLoading {
  @Param isLoading: boolean = false
  @Param type: LoadingType = 'spinner'
  @Param message: string = ''
  @Param size: LoadingSize = 'medium'
  @Param position: LoadingPosition = 'center'
  @Param color: string = '#007AFF'
  @Param bgColor: string = 'rgba(255, 255, 255, 0.9)'
  @Param showProgress: boolean = false
  @Param progress: number = 0
  @Param duration: number = 1500
  @Param enableTransition: boolean = true
  @Param onTimeout?: () => void
  @Param onCancel?: () => void

  @State private currentProgress: number = 0
  @State private animationPhase: number = 0
  @State private isVisible: boolean = false

  aboutToAppear() {
    if (this.isLoading) {
      this.startLoading()
    }
  }

  aboutToDisappear() {
    this.stopLoading()
  }

  /**
   * 开始加载动画
   */
  private startLoading() {
    this.isVisible = true
    this.startProgressAnimation()

    if (this.onTimeout && this.duration > 0) {
      setTimeout(() => {
        this.onTimeout?.()
      }, this.duration)
    }
  }

  /**
   * 停止加载动画
   */
  private stopLoading() {
    this.isVisible = false
  }

  /**
   * 启动进度动画
   */
  private startProgressAnimation() {
    if (this.showProgress) {
      this.animateProgress()
    }
  }

  /**
   * 进度动画
   */
  private animateProgress() {
    animateTo({
      duration: 1000,
      curve: Curve.Linear,
      iterations: -1
    }, () => {
      this.currentProgress = (this.currentProgress + 10) % 110
    })
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // 背景遮罩
        this.buildBackground()

        // 加载内容
        this.buildLoadingContent()
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
      .animation(
        this.enableTransition ? {
          duration: 300,
          curve: Curve.EaseInOut
        } : undefined
      )
    }
  }

  /**
   * 构建背景遮罩
   */
  @Builder
  private buildBackground() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgColor)
      .onClick(() => {
        // 可选的取消功能
        if (this.onCancel) {
          this.onCancel()
        }
      })
      .gesture(
        TapGesture()
          .onAction(() => {
            if (this.onCancel) {
              this.onCancel()
            }
          })
      )
  }

  /**
   * 构建加载内容
   */
  @Builder
  private buildLoadingContent() {
    Column({ space: 16 }) {
      // 加载动画
      this.buildLoadingAnimation()

      // 进度条（可选）
      if (this.showProgress && this.type === 'progress') {
        this.buildProgressBar()
      }

      // 加载文字
      if (this.message) {
        Text(this.message)
          .fontSize(16)
          .fontColor(ThemeManager.getCurrentTextColor())
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })
      }

      // 取消按钮（如果有取消回调）
      if (this.onCancel) {
        Button('取消')
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
          .borderRadius(20)
          .padding({ left: 24, right: 24, top: 8, bottom: 8 })
          .margin({ top: 24 })
          .onClick(() => {
            this.onCancel()
          })
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .position(this.getContentPosition())
  }

  /**
   * 构建加载动画
   */
  @Builder
  private buildLoadingAnimation() {
    switch (this.type) {
      case 'skeleton':
        this.buildSkeletonLoader()
        break
      case 'spinner':
        this.buildSpinnerLoader()
        break
      case 'dots':
        this.buildDotsLoader()
        break
      case 'pulse':
        this.buildPulseLoader()
        break
      case 'wave':
        this.buildWaveLoader()
        break
      case 'bounce':
        this.buildBounceLoader()
        break
      case 'shimmer':
        this.buildShimmerLoader()
        break
      default:
        this.buildSpinnerLoader()
        break
    }
  }

  /**
   * 骨架屏加载器
   */
  @Builder
  private buildSkeletonLoader() {
    Column({ space: 12 }) {
      // 标题骨架
      Row()
        .width(120)
        .height(16)
        .backgroundColor('#F0F0F0')
        .borderRadius(4)

      // 内容骨架
      ForEach([1, 2, 3], (index: number) => {
        Row()
          .width('100%')
          .height(12)
          .backgroundColor('#F0F0F0')
          .borderRadius(4)
          .margin({ top: 8 })
          .opacity(1 - index * 0.2)
      })
    }
    .width(this.getLoadingWidth())
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 转圈加载器
   */
  @Builder
  private buildSpinnerLoader() {
    LoadingProgress()
      .width(this.getLoadingSize())
      .height(this.getLoadingSize())
      .color(this.color)
  }

  /**
   * 点状动画加载器
   */
  @Builder
  private buildDotsLoader() {
    Row({ space: 8 }) {
      ForEach([1, 2, 3], (index: number) => {
        Circle({ width: 12, height: 12 })
          .fill(this.color)
          .scale({
            x: this.getDotScale(index),
            y: this.getDotScale(index)
          })
          .animation({
            duration: 1200,
            curve: Curve.EaseInOut,
            iterations: -1,
            delay: index * 150
          })
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 脉冲加载器
   */
  @Builder
  private buildPulseLoader() {
    Circle({ width: this.getLoadingSize(), height: this.getLoadingSize() })
      .fill(this.color)
      .scale({ x: 1, y: 1 })
      .animation({
        duration: 1000,
        curve: Curve.EaseInOut,
        iterations: -1
      })
  }

  /**
   * 波浪加载器
   */
  @Builder
  private buildWaveLoader() {
    Row({ space: 4 }) {
      ForEach([1, 2, 3, 4, 5], (index: number) => {
        Circle({ width: 8, height: 8 })
          .fill(this.color)
          .scale({
            x: 1,
            y: this.getWaveScale(index)
          })
          .animation({
            duration: 1000,
            curve: Curve.EaseInOut,
            iterations: -1,
            delay: index * 100
          })
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 弹跳加载器
   */
  @Builder
  private buildBounceLoader() {
    Circle({ width: this.getLoadingSize(), height: this.getLoadingSize() })
      .fill(this.color)
      .translate({
        y: this.getBounceOffset()
      })
      .animation({
        duration: 600,
        curve: Curve.EaseInOut,
        iterations: -1
      })
  }

  /**
   * 闪光加载器
   */
  @Builder
  private buildShimmerLoader() {
    Column()
      .width(this.getLoadingWidth())
      .height(120)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .linearGradient({
        direction: GradientDirection.Left,
        colors: [
          ['#E8E8E8', '#F5F5F5', '#E8E8E8', '#F5F5F5']
        ]
      })
      .animation({
        duration: 1500,
        curve: Curve.Linear,
        iterations: -1
      })
  }

  /**
   * 进度条
   */
  @Builder
  private buildProgressBar() {
    Column({ space: 8 }) {
      Progress({
        value: this.currentProgress,
        total: 100,
        type: ProgressType.Linear
      })
        .width(this.getLoadingWidth())
        .height(8)
        .color(this.color)
        .backgroundColor('#F0F0F0')
        .borderRadius(4)

      Text(`${Math.round(this.currentProgress)}%`)
        .fontSize(14)
        .fontColor(ThemeManager.getCurrentTextSecondaryColor())
        .textAlign(TextAlign.Center)
    }
    .width(this.getLoadingWidth())
  }

  /**
   * 获取加载尺寸
   */
  private getLoadingSize(): number {
    const sizes = {
      'small': 24,
      'medium': 48,
      'large': 72,
      'full': 96
    }
    return sizes[this.size] || sizes['medium']
  }

  /**
   * 获取加载宽度
   */
  private getLoadingWidth(): string {
    const widths = {
      'small': 120,
      'medium': 200,
      'large': 280,
      'full': '80%'
    }
    return `${widths[this.size] || widths['medium']}`
  }

  /**
   * 获取内容位置
   */
  private getContentPosition(): { [key: string]: string | number } {
    const positions = {
      'center': { top: '50%', left: '50%', transform: 'translate(-50%, -50%)' },
      'top': { top: 80, left: '50%', transform: 'translateX(-50%)' },
      'bottom': { bottom: 80, left: '50%', transform: 'translateX(-50%)' }
    }
    return positions[this.position] || positions['center']
  }

  /**
   * 获取点的缩放比例
   */
  private getDotScale(index: number): number {
    const phase = (Date.now() / 150 + index * 120) % 360
    return 0.5 + Math.sin(phase * Math.PI / 180) * 0.5
  }

  /**
   * 获取波浪缩放比例
   */
  private getWaveScale(index: number): number {
    const phase = (Date.now() / 200 + index * 72) % 360
    return 0.5 + Math.sin(phase * Math.PI / 180) * 0.5
  }

  /**
   * 获取弹跳偏移量
   */
  private getBounceOffset(): number {
    const phase = (Date.now() / 300) % 360
    return -Math.abs(Math.sin(phase * Math.PI / 180)) * 20
  }
}

/**
 * 页面过渡动画组件
 * 用于页面切换时的过渡效果
 */
@ComponentV2
export struct PageTransition {
  @Param isVisible: boolean = false
  @Param type: 'fade' | 'slide' | 'scale' | 'flip' = 'fade'
  @Param direction: 'left' | 'right' | 'up' | 'down' = 'right'
  @Param duration: number = 300
  @Param content: () => void = () => {}

  build() {
    Stack() {
      if (this.isVisible) {
        this.buildTransitionContent()
      }
    }
    .width('100%')
    .height('100%')
    .animation({
      duration: this.duration,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 构建过渡内容
   */
  @Builder
  private buildTransitionContent() {
    Column() {
      this.content()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .transition(this.getTransitionType())
  }

  /**
   * 获取过渡类型
   */
  private getTransitionType() {
    switch (this.type) {
      case 'fade':
        return TransitionType.All
      case 'slide':
        return TransitionType.All
      case 'scale':
        return TransitionType.All
      case 'flip':
        return TransitionType.All
      default:
        return TransitionType.All
    }
  }
}

/**
 * 加载状态管理器
 * 统一管理全局加载状态
 */
export class LoadingManager {
  private static instance: LoadingManager
  private loadingStates: Map<string, boolean> = new Map()

  static getInstance(): LoadingManager {
    if (!LoadingManager.instance) {
      LoadingManager.instance = new LoadingManager()
    }
    return LoadingManager.instance
  }

  /**
   * 设置加载状态
   */
  setLoading(key: string, isLoading: boolean): void {
    this.loadingStates.set(key, isLoading)
  }

  /**
   * 获取加载状态
   */
  isLoading(key: string): boolean {
    return this.loadingStates.get(key) || false
  }

  /**
   * 检查是否有任何加载状态
   */
  hasAnyLoading(): boolean {
    return Array.from(this.loadingStates.values()).some(state => state)
  }

  /**
   * 清除所有加载状态
   */
  clearAllLoading(): void {
    this.loadingStates.clear()
  }

  /**
   * 获取所有加载状态
   */
  getAllLoadingStates(): Record<string, boolean> {
    return Object.fromEntries(this.loadingStates.entries())
  }
}