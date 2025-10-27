/**
 * 统一加载状态组件
 * 提供多种加载动画样式和配置选项
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface LoadingConfig {
  type?: 'spinner' | 'dots' | 'pulse' | 'skeleton'
  size?: 'small' | 'medium' | 'large'
  color?: string
  text?: string
  showBackground?: boolean
  backgroundOpacity?: number
}

@ComponentV2
export struct Loading {
  @Param isLoading: boolean = false
  @Param loadingConfig?: LoadingConfig = {}
  @Param fullScreen?: boolean = false

  private get config(): LoadingConfig {
    return {
      type: 'spinner',
      size: 'medium',
      color: ThemeManager.getCurrentPrimaryColor(),
      showBackground: true,
      backgroundOpacity: 0.7,
      ...this.loadingConfig
    }
  }

  private getSizeValue(): number {
    switch (this.config.size) {
      case 'small': return 24
      case 'large': return 48
      default: return 36
    }
  }

  private getFontSize(): number {
    switch (this.config.size) {
      case 'small': return 12
      case 'large': return 18
      default: return 14
    }
  }

  @Builder
  private SpinnerLoading() {
    LoadingProgress()
      .width(this.getSizeValue())
      .height(this.getSizeValue())
      .color(this.config.color || '#1890FF')
  }

  @Builder
  private DotsLoading() {
    Row({ space: 8 }) {
      ForEach([1, 2, 3], (index: number) => {
        Circle({ width: 8, height: 8 })
          .fill(this.config.color || '#1890FF')
          .animation({
            duration: 800,
            curve: Curve.EaseInOut,
            iterations: -1,
            play: this.isLoading,
            delay: index * 150
          })
          .scale({ x: this.isLoading ? 1.2 : 0.8, y: this.isLoading ? 1.2 : 0.8 })
          .opacity(this.isLoading ? 1 : 0.3)
      })
    }
    .justifyContent(FlexAlign.Center)
    .width(this.getSizeValue() * 2)
    .height(this.getSizeValue())
  }

  @Builder
  private PulseLoading() {
    Circle({ width: this.getSizeValue(), height: this.getSizeValue() })
      .fill(this.config.color || '#1890FF')
      .animation({
        duration: 1000,
        curve: Curve.EaseInOut,
        iterations: -1,
        play: this.isLoading
      })
      .scale({ x: this.isLoading ? 1.3 : 0.8, y: this.isLoading ? 1.3 : 0.8 })
      .opacity(this.isLoading ? 0.8 : 0.2)
  }

  @Builder
  private SkeletonLoading() {
    Column({ space: 12 }) {
      // 模拟标题骨架
      Row()
        .width('60%')
        .height(16)
        .backgroundColor('#E0E0E0')
        .borderRadius(4)

      // 模拟内容骨架
      ForEach([1, 2, 3], (index: number) => {
        Row()
          .width(this.isLoading ? `${85 + index * 5}%` : '80%')
          .height(12)
          .backgroundColor('#F0F0F0')
          .borderRadius(4)
          .animation({
            duration: 1500,
            curve: Curve.EaseInOut,
            iterations: -1,
            delay: index * 200
          })
          .opacity(this.isLoading ? 1 : 0.6)
      })
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  private LoadingContent() {
    Column({ space: 12 }) {
      // 加载图标
      if (this.config.type === 'spinner') {
        this.SpinnerLoading()
      } else if (this.config.type === 'dots') {
        this.DotsLoading()
      } else if (this.config.type === 'pulse') {
        this.PulseLoading()
      } else if (this.config.type === 'skeleton') {
        this.SkeletonLoading()
      }

      // 加载文字
      if (this.config.text) {
        Text(this.config.text)
          .fontSize(this.getFontSize())
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    if (this.isLoading) {
      if (this.fullScreen) {
        // 全屏加载遮罩
        Stack() {
          // 半透明背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(`rgba(0, 0, 0, ${this.config.backgroundOpacity || 0.7})`)
            .onClick(() => {}) // 防止点击穿透

          // 加载内容
          this.LoadingContent()
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(1000)
      } else {
        // 内联加载
        if (this.config.type === 'skeleton') {
          this.LoadingContent()
        } else {
          Column({ space: 8 }) {
            this.LoadingContent()
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding(16)
          .backgroundColor(this.config.showBackground ? '#FAFAFA' : Color.Transparent)
          .borderRadius(this.config.showBackground ? 8 : 0)
        }
      }
    }
  }
}