/**
 * 微交互组件库
 * 提供丰富的微交互效果，提升用户体验
 */

import { ThemeManager } from '../../theme/ThemeManager'

export type RippleEffect =
  | 'none'           // 无波纹
  | 'default'        // 默认波纹
  | 'expanded'        // 扩散波纹
  | 'circular'       // 圆形波纹
  | 'infinite'        // 无限波纹
  | 'bounded'         // 有界波纹

export type HapticType =
  | 'none'           // 无反馈
  | 'light'           // 轻触感
  | 'medium'          // 中等触感
  | 'heavy'           // 重触感
  | 'success'         // 成功反馈
  | 'warning'         // 警告反馈
  | 'error'           // 错误反馈
  | 'selection'       // 选择反馈

export type AnimationType =
  | 'bounce'         // 弹跳
  | 'scale'          // 缩放
  | 'rotate'         // 旋转
  | 'shake'          // 震动
  | 'pulse'          // 脉冲
  | 'flip'           // 翻转
  | 'slide'          // 滑动
  | 'glow'           // 发光
  | 'fade'           // 淡入淡出

/**
 * 按钮波纹效果组件
 * 为按钮提供Material Design风格的波纹效果
 */
@ComponentV2
export struct RippleButton {
  @Param text: string = ''
  @Param rippleEffect: RippleEffect = 'default'
  @Param hapticType: HapticType = 'light'
  @Param color: string = '#FFFFFF'
  @Param backgroundColor: string = '#007AFF'
  @Param borderRadius: number = 8
  @Param animationDuration: number = 200
  @Param onTap?: () => void = () => {}

  @State private isPressed: boolean = false
  @State private rippleScale: number = 0
  @State private rippleOpacity: number = 0

  build() {
    Stack() {
      // 按钮内容
      Column() {
        Text(this.text)
          .fontSize(16)
          .fontColor(this.color)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.backgroundColor)
      .borderRadius(this.borderRadius)
      .shadow(
        this.isPressed ? {
          radius: 8,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 0,
          offsetY: 2
        } : {
          radius: 4,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetX: 0,
          offsetY: 2
        }
      )
      .animation({
        duration: this.animationDuration,
        curve: Curve.EaseInOut
      })
      .transform({
        scale: {
          x: this.isPressed ? 0.95 : 1,
          y: this.isPressed ? 0.95 : 1
        }
      })

      // 波纹效果
      if (this.rippleEffect !== 'none') {
        this.buildRippleEffect()
      }
    }
    .width('100%')
    .height(48)
    .backgroundColor(Color.Transparent)
    .borderRadius(this.borderRadius)
    .onClick(() => {
      this.handlePress()
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          this.handlePress()
        })
    )
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.handleLongPress()
        })
    )
  }

  /**
   * 构建波纹效果
   */
  @Builder
  private buildRippleEffect() {
    Circle({ width: 200, height: 200 })
      .fill(Color.Transparent)
      .border({
        width: 2,
        color: this.color,
        radius: 100
      })
      .scale({ x: this.rippleScale, y: this.rippleScale })
      .opacity(this.rippleOpacity)
      .position({ x: '50%', y: '50%' })
      .transform({ x: '-50%', y: '-50%' })
      .animation({
        duration: this.animationDuration,
        curve: Curve.EaseOutCubic
      })
  }

  /**
   * 处理按下事件
   */
  private handlePress() {
    this.isPressed = true
    this.startRippleAnimation()
    this.onTap?.()
    this.triggerHaptic()

    setTimeout(() => {
      this.isPressed = false
    }, 100)
  }

  /**
   * 处理长按事件
   */
  private handleLongPress() {
    this.startRippleAnimation()
    this.triggerHaptic('heavy')
  }

  /**
   * 启动波纹动画
   */
  private startRippleAnimation() {
    switch (this.rippleEffect) {
      case 'expanded':
        this.animateExpandedRipple()
        break
      case 'infinite':
        this.animateInfiniteRipple()
        break
      default:
        this.animateDefaultRipple()
        break
    }
  }

  /**
   * 默认波纹动画
   */
  private animateDefaultRipple() {
    animateTo({
      duration: this.animationDuration,
      curve: Curve.EaseOutCubic
    }, () => {
      this.rippleScale = 1.5
      this.rippleOpacity = 0.6
    })

    setTimeout(() => {
      animateTo({
        duration: this.animationDuration,
        curve: Curve.EaseInCubic
      }, () => {
        this.rippleScale = 0
        this.rippleOpacity = 0
      })
    }, 100)
  }

  /**
   * 扩散波纹动画
   */
  private animateExpandedRipple() {
    animateTo({
      duration: this.animationDuration,
      curve: Curve.EaseOutCubic
    }, () => {
      this.rippleScale = 2.5
      this.rippleOpacity = 0.4
    })

    setTimeout(() => {
      animateTo({
        duration: this.animationDuration * 1.5,
        curve: Curve.EaseInCubic
      }, () => {
        this.rippleScale = 0
        this.rippleOpacity = 0
      })
    }, 100)
  }

  /**
   * 无限波纹动画
   */
  private animateInfiniteRipple() {
    animateTo({
      duration: this.animationDuration,
      curve: Curve.EaseOutCubic,
      iterations: -1
    }, () => {
      this.rippleScale = 2
      this.rippleOpacity = 0.3
    })
  }

  /**
   * 触发触觉反馈
   */
  private triggerHaptic(type?: HapticType) {
    // 这里应该调用设备的触觉反馈API
    console.info(`Haptic feedback: ${type || this.hapticType}`)
  }
}

/**
 * 可交互的卡片组件
 * 支持多种微交互效果
 */
@ComponentV2
export struct InteractiveCard {
  @Param children: () => void = () => {}
  @Param rippleEffect: RippleEffect = 'default'
  @Param animationType: AnimationType = 'scale'
  @Param hapticType: HapticType = 'light'
  @Param scaleOnHover: boolean = true
  @Param glowOnHover: boolean = false
  @Param shadowOnHover: boolean = true
  @Param borderRadius: number = 12
  @Param onTap?: () => void = () => {}
  @Param onHover?: (isHovering: boolean) => void = () => {}

  @State private isHovering: boolean = false
  @State private isPressed: boolean = false

  build() {
    Column() {
      this.children()
    }
    .width('100%')
    .backgroundColor(ThemeManager.getCurrentSurfaceColor())
    .borderRadius(this.borderRadius)
    .shadow(
      this.shadowOnHover && this.isHovering ? {
        radius: 12,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 4
      } : {
        radius: 4,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 2
      }
    )
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
    .transform({
      scale: {
        x: this.getScaleX(),
        y: this.getScaleY()
      },
      rotate: this.isHovering && this.animationType === 'rotate' ? 5 : 0
    })
    .border({
      width: this.isHovering ? 2 : 1,
      color: this.isHovering ? ThemeManager.getCurrentPrimaryColor() : ThemeManager.getCurrentBorderColor()
    })
    .onClick(() => {
      this.handlePress()
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          this.handlePress()
        })
    )
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.handleLongPress()
        })
    )
    .onAreaChange((isHovering: boolean) => {
      if (this.isHovering !== isHovering) {
        this.isHovering = isHovering
        this.onHover?.(isHovering)
      }
    })
  }

  /**
   * 获取X轴缩放比例
   */
  private getScaleX(): number {
    if (this.isPressed) return 0.95
    if (this.isHovering && this.scaleOnHover) return 1.05
    return 1
  }

  /**
   * 获取Y轴缩放比例
   */
  private getScaleY(): number {
    if (this.isPressed) return 0.95
    if (this.isHovering && this.scaleOnHover) return 1.02
    return 1
  }

  /**
   * 处理按下事件
   */
  private handlePress() {
    this.isPressed = true
    this.triggerHaptic()
    this.onTap?.()

    setTimeout(() => {
      this.isPressed = false
    }, 100)
  }

  /**
   * 处理长按事件
   */
  private handleLongPress() {
    this.triggerHaptic('heavy')
  }

  /**
   * 触发触觉反馈
   */
  private triggerHaptic(type?: HapticType) {
    console.info(`Haptic feedback: ${type || this.hapticType}`)
  }
}

/**
 * 动画图标组件
 * 支持多种动画效果的图标
 */
@ComponentV2
export struct AnimatedIcon {
  @Param icon: string = ''
  @Param animationType: AnimationType = 'pulse'
  @Param animationDuration: number = 1000
  @Param color: string = '#007AFF'
  @Param size: number = 24
  @Param autoPlay: boolean = true
  @Param onTap?: () => void = () => {}
  @Param onAnimationComplete?: () => void = () => {}

  @State private animationPhase: number = 0
  @State private isAnimating: boolean = false

  aboutToAppear() {
    if (this.autoPlay) {
      this.startAnimation()
    }
  }

  /**
   * 启动动画
   */
  private startAnimation() {
    this.isAnimating = true
    this.animationPhase = 0

    switch (this.animationType) {
      case 'bounce':
        this.animateBounce()
        break
      case 'rotate':
        this.animateRotate()
        break
      case 'shake':
        this.animateShake()
        break
      case 'flip':
        this.animateFlip()
        break
      case 'slide':
        this.animateSlide()
        break
      case 'glow':
        this.animateGlow()
        break
      default:
        this.animatePulse()
        break
    }
  }

  /**
   * 脉冲动画
   */
  private animatePulse() {
    animateTo({
      duration: this.animationDuration,
      curve: Curve.EaseInOut,
      iterations: -1
    }, () => {
      this.animationPhase = (this.animationPhase + 180) % 360
    })
  }

  /**
   * 弹跳动画
   */
  private animateBounce() {
    animateTo({
      duration: this.animationDuration / 2,
      curve: Curve.EaseOutBounce
    }, () => {
      this.animationPhase = 1
    })

    setTimeout(() => {
      animateTo({
        duration: this.animationDuration / 2,
        curve: Curve.EaseInBounce
      }, () => {
        this.animationPhase = 0
        this.onAnimationComplete?.()
      })
    }, this.animationDuration / 2)
  }

  /**
   * 旋转动画
   */
  private animateRotate() {
    animateTo({
      duration: this.animationDuration,
      curve: Curve.Linear,
      iterations: -1
    }, () => {
      this.animationPhase = (this.animationPhase + 90) % 360
    })
  }

  /**
   * 震动动画
   */
  private animateShake() {
    animateTo({
      duration: 100,
      curve: Curve.EaseInOut,
      iterations: 3
    }, () => {
      this.animationPhase = Math.sin(this.animationPhase * Math.PI / 180) * 10
    })

    setTimeout(() => {
      this.onAnimationComplete?.()
    }, 300)
  }

  /**
   * 翻转动画
   */
  private animateFlip() {
    animateTo({
      duration: this.animationDuration / 2,
      curve: Curve.EaseInOut
    }, () => {
      this.animationPhase = 1
    })

    setTimeout(() => {
      animateTo({
        duration: this.animationDuration / 2,
        curve: Curve.EaseInOut
      }, () => {
        this.animationPhase = 0
        this.onAnimationComplete?.()
      })
    }, this.animationDuration / 2)
  }

  /**
   * 滑动动画
   */
  private animateSlide() {
    animateTo({
      duration: this.animationDuration / 2,
      curve: Curve.EaseInOut
    }, () => {
      this.animationPhase = 1
    })

    setTimeout(() => {
      animateTo({
        duration: this.animationDuration / 2,
        curve: Curve.EaseInOut
      }, () => {
        this.animationPhase = 0
        this.onAnimationComplete?.()
      })
    }, this.animationDuration / 2)
  }

  /**
   * 发光动画
   */
  private animateGlow() {
    animateTo({
      duration: this.animationDuration,
      curve: Curve.EaseInOut,
      iterations: -1
    }, () => {
      this.animationPhase = Math.sin(this.animationPhase * Math.PI / 180) * 0.3 + 1
    })
  }

  build() {
    Text(this.icon)
      .fontSize(this.size)
      .fontColor(this.color)
      .transform({
        scale: this.getTransform(),
        rotate: this.getRotation(),
        translate: {
          x: this.getTranslateX(),
          y: this.getTranslateY()
        }
      })
      .animation({
        duration: 50,
        curve: Curve.EaseInOut
      })
      .onClick(() => {
        this.onTap?.()
        if (!this.isAnimating && this.autoPlay) {
          this.startAnimation()
        }
      })
  }

  /**
   * 获取变换比例
   */
  private getTransform(): { x: number; y: number } {
    switch (this.animationType) {
      case 'pulse':
      case 'glow':
        return {
          x: this.animationPhase / 100 + 1,
          y: this.animationPhase / 100 + 1
        }
      case 'bounce':
        return {
          x: 1,
          y: this.animationPhase === 1 ? 0.8 : 1
        }
      case 'flip':
        return {
          x: this.animationPhase === 1 ? -1 : 1,
          y: 1
        }
      default:
        return { x: 1, y: 1 }
    }
  }

  /**
   * 获取旋转角度
   */
  private getRotation(): number {
    return this.animationType === 'rotate' ? this.animationPhase : 0
  }

  /**
   * 获取X轴平移
   */
  private getTranslateX(): number {
    return this.animationType === 'slide' && this.animationPhase === 1 ? 10 : 0
  }

  /**
   * 获取Y轴平移
   */
  private getTranslateY(): number {
    return this.animationType === 'bounce' && this.animationPhase === 1 ? -5 : 0
  }
}

/**
 * 悬浮提示组件
 * 提供丰富的悬浮交互体验
 */
@ComponentV2
export struct HoverTooltip {
  @Param content: string = ''
  @Param position: 'top' | 'bottom' | 'left' | 'right' = 'top'
  @Param showDelay: number = 300
  @Param hideDelay: number = 200
  @Param maxWidth: number = 200
  @Param backgroundColor: string = '#333333'
  @Param textColor: string = '#FFFFFF'
  @Param borderRadius: number = 6
  @Param children: () => void = () => {}

  @State private isVisible: boolean = false
  @State private timeoutId?: number

  build() {
    Stack() {
      // 触发区域
      Column() {
        this.children()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .onHover((isHovering: boolean) => {
        if (isHovering) {
          this.showTooltip()
        } else {
          this.hideTooltip()
        }
      })

      // 提示内容
      if (this.isVisible) {
        this.buildTooltipContent()
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建提示内容
   */
  @Builder
  private buildTooltipContent() {
    Column({ space: 4 }) {
      // 提示箭头
      this.buildTooltipArrow()

      // 提示文本
      Text(this.content)
        .fontSize(14)
        .fontColor(this.textColor)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
        .padding(12)
        .backgroundColor(this.backgroundColor)
        .borderRadius(this.borderRadius)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.2)',
          offsetX: 0,
          offsetY: 2
        })
        .maxWidth(this.maxWidth)
        .position(this.getTooltipPosition())
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建提示箭头
   */
  @Builder
  private buildTooltipArrow() {
    Polygon([
      { x: 0, y: 0 },
      { x: 6, y: 6 },
      { x: 12, y: 0 }
    ])
      .fill(this.backgroundColor)
      .width(12)
      .height(6)
      .position(this.getArrowPosition())
  }

  /**
   * 获取提示位置
   */
  private getTooltipPosition(): { [key: string]: string | number } {
    const positions = {
      'top': { bottom: -8, left: '50%', transform: 'translateX(-50%)' },
      'bottom': { top: 8, left: '50%', transform: 'translateX(-50%)' },
      'left': { right: 8, top: '50%', transform: 'translateY(-50%)' },
      'right': { left: 8, top: '50%', transform: 'translateY(-50%)' }
    }
    return positions[this.position]
  }

  /**
   * 获取箭头位置
   */
  private getArrowPosition(): { [key: string]: string | number } {
    const positions = {
      'top': { bottom: -6, left: '50%', transform: 'translateX(-50%)' },
      'bottom': { top: -6, left: '50%', transform: 'translateX(-50%) rotate(180deg)' },
      'left': { right: -6, top: '50%', transform: 'translateY(-50%) rotate(-90deg)' },
      'right': { left: -6, top: '50%', transform: 'translateY(-50%) rotate(90deg)' }
    }
    return positions[this.position]
  }

  /**
   * 显示提示
   */
  private showTooltip() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    this.timeoutId = setTimeout(() => {
      this.isVisible = true
    }, this.showDelay)
  }

  /**
   * 隐藏提示
   */
  private hideTooltip() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    this.timeoutId = setTimeout(() => {
      this.isVisible = false
    }, this.hideDelay)
  }
}