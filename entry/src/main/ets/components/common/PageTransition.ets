/**
 * 页面转场动画组件
 * 提供平滑的页面切换动画效果
 */

export interface TransitionConfig {
  duration?: number
  curve?: Curve
  delay?: number
  opacity?: number
}

@ComponentV2
export struct PageTransition {
  @Require @Param content: () => void = () => {}
  @Param isLoading: boolean = false
  @Param animationConfig?: TransitionConfig = {}
  @Param onAnimationEnd?: () => void = () => {}

  @State private isVisible: boolean = false
  @State private currentOpacity: number = 0

  aboutToAppear() {
    if (this.animationConfig.delay) {
      setTimeout(() => {
        this.showTransition()
      }, this.animationConfig.delay)
    }
  }

  private showTransition(): void {
    this.isVisible = true
    this.animateOpacity()
  }

  private hideTransition(): void {
    this.isVisible = false
    this.animateOpacity()
  }

  private animateOpacity(): void {
    if (this.animationConfig.opacity !== undefined) {
      // 淡入动画到目标透明度
      const duration = this.animationConfig.duration || 300
      const targetOpacity = this.animationConfig.opacity || 1
      const startTime = Date.now()

      const animate = () => {
        const elapsed = Date.now() - startTime
        const progress = Math.min(elapsed / duration)
        const opacity = this.currentOpacity + (targetOpacity - this.currentOpacity) * (progress / duration)

        this.currentOpacity = Math.max(0, Math.min(1, opacity))

        if (progress < 1) {
          requestAnimationFrame(animate)
        }
      }

      requestAnimationFrame(animate)
    }
  }
  }

  build() {
    Column() {
      if (this.isLoading) {
        // 加载状态
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#1890FF')
      } else {
        // 页面内容
        this.content()
          .opacity(this.currentOpacity)
          .animation({
            duration: this.animationConfig.duration || 300,
            curve: this.animationConfig.curve || Curve.EaseInOut,
            delay: 0,
            play: true
            onFinish: () => {
              this.hideTransition()
              if (this.onAnimationEnd) {
                this.onAnimationEnd()
              }
            }
          })
      }

      // 转场遮罩
      if (this.isVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.hideTransition()
          })
          .justifyContent(FlexAlign.Center)
        }
      }
    }
  }
}