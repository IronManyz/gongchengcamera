/**
 * 手势交互组件库
 * 提供丰富的手势交互效果和动画
 */

import { ThemeManager } from '../../theme/ThemeManager'

export type SwipeDirection =
  | 'horizontal' | 'vertical' | 'both'

export type SwipeAction =
  | 'tap' | 'swipe-left' | 'swipe-right' | 'swipe-up' | 'swipe-down'

export type DragAxis =
  | 'x' | 'y' | 'both'

export type PinchType =
  | 'zoom' | 'rotate' | 'both'

/**
 * 可滑动的卡片组件
 * 支持左右滑动操作和动画效果
 */
@ComponentV2
export struct SwipeableCard {
  @Param children: () => void = () => {}
  @Param swipeDirection: SwipeDirection = 'horizontal'
  @Param swipeThreshold: number = 50
  @Param onSwipe?: (action: SwipeAction) => void = () => {}
  @Param onSwipeStart?: () => void = () => {}
  @Param onSwipeEnd?: () => void = () => {}
  @Param swipeLeftAction?: () => void = () => {}
  @Param swipeRightAction?: () => void = () => {}
  @Param backgroundColor: string = ThemeManager.getCurrentSurfaceColor()
  @Param borderRadius: number = 12

  @State private swipeOffset: number = 0
  @State private isSwiping: boolean = false
  @State private swipeStartX: number = 0
  @State private swipeStartY: number = 0

  build() {
    Column() {
      this.children()
    }
    .width('100%')
    .backgroundColor(this.backgroundColor)
    .borderRadius(this.borderRadius)
    .shadow({
      radius: 4,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 2
    })
    .transform({
      translate: { x: this.swipeOffset, y: 0 }
    })
    .animation({
      duration: 200,
      curve: Curve.EaseOutCubic
    })
    .gesture(
      PanGesture({ fingers: 1 })
        .onActionStart((event: GestureEvent) => {
          this.handleSwipeStart(event)
        })
        .onActionUpdate((event: GestureEvent) => {
          this.handleSwipeUpdate(event)
        })
        .onActionEnd(() => {
          this.handleSwipeEnd()
        })
    )
  }

  /**
   * 处理滑动开始
   */
  private handleSwipeStart(event: GestureEvent) {
    this.isSwiping = true
    this.swipeStartX = event.globalX
    this.swipeStartY = event.globalY
    this.onSwipeStart?.()
  }

  /**
   * 处理滑动更新
   */
  private handleSwipeUpdate(event: GestureEvent) {
    if (!this.isSwiping) return

    let offset = 0
    if (this.swipeDirection === 'horizontal' || this.swipeDirection === 'both') {
      offset = event.globalX - this.swipeStartX
    }
    if (this.swipeDirection === 'vertical' || this.swipeDirection === 'both') {
      offset = event.globalY - this.swipeStartY
    }

    this.swipeOffset = Math.max(-this.swipeThreshold, Math.min(this.swipeThreshold, offset))
  }

  /**
   * 处理滑动结束
   */
  private handleSwipeEnd() {
    if (!this.isSwiping) return

    this.isSwiping = false
    const finalOffset = this.swipeOffset

    // 重置位置
    this.swipeOffset = 0

    // 触发相应的回调
    if (Math.abs(finalOffset) >= this.swipeThreshold) {
      if (this.swipeDirection === 'horizontal' || this.swipeDirection === 'both') {
        if (finalOffset > 0) {
          this.onSwipe?.('swipe-right')
          this.onSwipeRightAction?.()
        } else {
          this.onSwipe?.('swipe-left')
          this.onSwipeLeftAction?.()
        }
      } else if (this.swipeDirection === 'vertical') {
        if (finalOffset > 0) {
          this.onSwipe?.('swipe-down')
        } else {
          this.onSwipe?.('swipe-up')
        }
      }
    } else {
      this.onSwipe?.('tap')
    }

    this.onSwipeEnd?.()
  }
}

/**
 * 可拖拽的元素组件
 * 支持拖拽操作和视觉反馈
 */
@ComponentV2
export struct DraggableElement {
  @Param children: () => void = () => {}
  @Param dragAxis: DragAxis = 'both'
  @Param dragBounds?: { minX: number, maxX: number, minY: number, maxY: number }
  @Param onDragStart?: (position: { x: number, y: number }) => void = () => {}
  @Param onDrag?: (position: { x: number, y: number }) => void = () => {}
  @Param onDragEnd?: (position: { x: number, y: number }) => void = () => {}
  @Param snapToGrid?: boolean = false
  @Param gridSize: number = 20

  @State private dragPosition: { x: number, y: number } = { x: 0, y: 0 }
  @State private isDragging: boolean = false
  @State private dragScale: number = 1

  build() {
    Column() {
      this.children()
    }
    .width('100%')
    .height('100%')
    .transform({
      translate: { x: this.dragPosition.x, y: this.dragPosition.y }
    })
    .scale({ x: this.dragScale, y: this.dragScale })
    .animation({
      duration: 100,
      curve: Curve.EaseInOut
    })
    .shadow(
      this.isDragging ? {
        radius: 12,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 6
      } : {
        radius: 4,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 2
      }
    )
    .gesture(
      PanGesture({ fingers: 1 })
        .onActionStart((event: GestureEvent) => {
          this.handleDragStart(event)
        })
        .onActionUpdate((event: GestureEvent) => {
          this.handleDrag(event)
        })
        .onActionEnd(() => {
          this.handleDragEnd(event)
        })
    )
  }

  /**
   * 处理拖拽开始
   */
  private handleDragStart(event: GestureEvent) {
    this.isDragging = true
    this.dragScale = 0.95
    this.onDragStart?.({ x: event.globalX, y: event.globalY })
  }

  /**
   * 处理拖拽
   */
  private handleDrag(event: GestureEvent) {
    if (!this.isDragging) return

    let x = event.globalX
    let y = event.globalY

    // 应用边界限制
    if (this.dragBounds) {
      x = Math.max(this.dragBounds.minX, Math.min(this.dragBounds.maxX, x))
      y = Math.max(this.dragBounds.minY, Math.min(this.dragBounds.maxY, y))
    }

    // 应用网格吸附
    if (this.snapToGrid) {
      x = Math.round(x / this.gridSize) * this.gridSize
      y = Math.round(y / this.gridSize) * this.gridSize
    }

    this.dragPosition = { x, y }
    this.onDrag?.({ x, y })
  }

  /**
   * 处理拖拽结束
   */
  private handleDragEnd(event: GestureEvent) {
    this.isDragging = false
    this.dragScale = 1
    this.onDragEnd?.({ x: event.globalX, y: event.globalY })
  }
}

/**
 * 可缩放的图片组件
 * 支持双指缩放和拖拽操作
 */
@ComponentV2
export struct ScalableImage {
  @Param src: string = ''
  @Param initialScale: number = 1
  @Param minScale: number = 0.5
  @Param maxScale: number = 3
  @Param pinchType: PinchType = 'both'
  @Param onScaleChange?: (scale: number) => void = () => {}
  @Param onDoubleTap?: () => void = () => {}

  @State private currentScale: number = 1
  @State private position: { x: number, y: number } = { x: 0, y: 0 }
  @State private lastDistance: number = 0

  build() {
    Stack() {
      Image(this.src)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .scale({ x: this.currentScale, y: this.currentScale })
        .transform({
          translate: { x: this.position.x, y: this.position.y }
        })
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
        .gesture(
          // 缩放手势
          PinchGesture({ fingers: 2 })
            .onActionStart((event: GestureEvent) => {
              this.lastDistance = event.scale
            })
            .onActionUpdate((event: GestureEvent) => {
              this.handlePinch(event)
            })
            .onActionEnd(() => {
              this.lastDistance = 0
            })
        )
        .gesture(
          // 单击手势
          TapGesture({ count: 2 })
            .onAction(() => {
              this.handleDoubleTap()
            })
        )
        .gesture(
          // 拖拽手势
          PanGesture({ fingers: 1 })
            .onActionUpdate((event: GestureEvent) => {
              this.position = { x: event.offsetX, y: event.offsetY }
            })
        )
    }
  }

  /**
   * 处理缩放操作
   */
  private handlePinch(event: GestureEvent) {
    if (this.lastDistance === 0) {
      this.lastDistance = event.scale
      return
    }

    const scaleChange = event.scale - this.lastDistance
    let newScale = this.currentScale + (scaleChange * 0.01)

    // 限制缩放范围
    newScale = Math.max(this.minScale, Math.min(this.maxScale, newScale))

    if (newScale !== this.currentScale) {
      this.currentScale = newScale
      this.onScaleChange?.(newScale)
    }
  }

  /**
   * 处理双击操作
   */
  private handleDoubleTap() {
    animateTo({
      duration: 200,
      curve: Curve.EaseOutBounce
    }, () => {
      this.currentScale = this.initialScale
    })
    this.onScaleChange?.(this.initialScale)
    this.onDoubleTap?.()
  }
}

/**
 * 页面过渡动画组件
 * 用于页面切换时的动画效果
 */
@ComponentV2
export struct PageTransitionAnimator {
  @Param isVisible: boolean = false
  @Param enterAnimation: 'slide-left' | 'slide-right' | 'slide-up' | 'slide-down' | 'fade' | 'scale' | 'flip' = 'fade'
  @Param exitAnimation: 'slide-left' | 'slide-right' | 'slide-up' | 'slide-down' | 'fade' | 'scale' | 'flip' = 'fade'
  @Param duration: number = 400
  @Param easing: string = 'ease'
  @Param children: () => void = () => {}

  @State private animationProgress: number = 0

  build() {
    Stack() {
      this.children()
    }
    .width('100%')
    .height('100%')
    .opacity(this.isVisible ? this.animationProgress : 1 - this.animationProgress)
    .transform({
      scale: this.isVisible ? this.getEnterScale() : this.getExitScale(),
      translate: this.isVisible ? this.getEnterTranslate() : this.getExitTranslate(),
      rotate: this.isVisible ? this.getEnterRotate() : this.getExitRotate()
    })
    .animation({
      duration: this.duration,
      curve: this.getCurveType()
    })
  }

  /**
   * 获取进入时的缩放
   */
  private getEnterScale(): { x: number; y: number } {
    switch (this.enterAnimation) {
      case 'scale':
        return { x: 0.8, y: 0.8 }
      case 'flip':
        return { x: 0.8, y: 1 }
      default:
        return { x: 1, y: 1 }
    }
  }

  /**
   * 获取退出时的缩放
   */
  private getExitScale(): { x: number; y: number } {
    switch (this.exitAnimation) {
      case 'scale':
        return { x: 1.2, y: 1.2 }
      case 'flip':
        return { x: 1.2, y: 1 }
      default:
        return { x: 1, y: 1 }
    }
  }

  /**
   * 获取进入时的平移
   */
  private getEnterTranslate(): { x: number; y: number } {
    switch (this.enterAnimation) {
      case 'slide-left':
        return { x: -50, y: 0 }
      case 'slide-right':
        return { x: 50, y: 0 }
      case 'slide-up':
        return { x: 0, y: -50 }
      case 'slide-down':
        return { x: 0, y: 50 }
      default:
        return { x: 0, y: 0 }
    }
  }

  /**
   * 获取退出时的平移
   */
  private getExitTranslate(): { x: number; y: number } {
    switch (this.exitAnimation) {
      case 'slide-left':
        return { x: 50, y: 0 }
      case 'slide-right':
        return { x: -50, y: 0 }
      case 'slide-up':
        return { x: 0, y: 50 }
      case 'slide-down':
        return { x: 0, y: -50 }
      default:
        return { x: 0, y: 0 }
    }
  }

  /**
   * 获取进入时的旋转
   */
  private getEnterRotate(): number {
    return this.enterAnimation === 'flip' ? -180 : 0
  }

  /**
   * 获取退出时的旋转
   */
  private getExitRotate(): number {
    return this.exitAnimation === 'flip' ? 180 : 0
  }

  /**
   * 获取曲线类型
   */
  private getCurveType(): Curve {
    switch (this.easing) {
      case 'ease':
        return Curve.EaseInOut
      case 'ease-in':
        return Curve.EaseIn
      case 'ease-out':
        return Curve.EaseOut
      case 'bounce':
        return Curve.EaseInOut
      case 'elastic':
        return Curve.EaseOut
      default:
        return Curve.EaseInOut
    }
  }
}