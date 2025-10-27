/**
 * 统一按钮组件
 * 提供多种按钮样式和状态配置
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface ButtonConfig {
  type?: 'primary' | 'secondary' | 'outline' | 'text' | 'danger'
  size?: 'small' | 'medium' | 'large'
  disabled?: boolean
  loading?: boolean
  icon?: string
  iconPosition?: 'left' | 'right'
  fullWidth?: boolean
  rounded?: boolean
}

@ComponentV2
export struct AppButton {
  @Param text: string = ''
  @Param config?: ButtonConfig = {}
  @Param onTap?: () => void = () => {}

  private get buttonConfig(): ButtonConfig {
    return {
      type: 'primary',
      size: 'medium',
      disabled: false,
      loading: false,
      iconPosition: 'left',
      fullWidth: false,
      rounded: false,
      ...this.config
    }
  }

  private getHeight(): number {
    switch (this.buttonConfig.size) {
      case 'small': return 32
      case 'large': return 48
      default: return 40
    }
  }

  private getFontSize(): number {
    switch (this.buttonConfig.size) {
      case 'small': return 12
      case 'large': return 16
      default: return 14
    }
  }

  private getPadding(): { left: number, right: number } {
    const basePadding = this.buttonConfig.size === 'small' ? 16 : 24
    if (this.buttonConfig.icon) {
      return { left: 12, right: 12 }
    }
    return { left: basePadding, right: basePadding }
  }

  private getBackgroundColor(): string {
    if (this.buttonConfig.disabled) {
      return '#E0E0E0'
    }

    switch (this.buttonConfig.type) {
      case 'secondary':
        return '#F0F0F0'
      case 'outline':
      case 'text':
        return Color.Transparent.toString()
      case 'danger':
        return '#FF4D4F'
      case 'primary':
      default:
        return ThemeManager.getCurrentPrimaryColor()
    }
  }

  private getTextColor(): string {
    if (this.buttonConfig.disabled) {
      return '#999999'
    }

    switch (this.buttonConfig.type) {
      case 'outline':
        return ThemeManager.getCurrentPrimaryColor()
      case 'text':
        return ThemeManager.getCurrentPrimaryColor()
      case 'secondary':
        return '#333333'
      case 'danger':
        return '#FFFFFF'
      case 'primary':
      default:
        return '#FFFFFF'
    }
  }

  private getBorderColor(): string {
    if (this.buttonConfig.disabled) {
      return '#E0E0E0'
    }

    switch (this.buttonConfig.type) {
      case 'outline':
        return ThemeManager.getCurrentPrimaryColor()
      case 'danger':
        return '#FF4D4F'
      default:
        return Color.Transparent.toString()
    }
  }

  private getBorderWidth(): number {
    return this.buttonConfig.type === 'outline' ? 1 : 0
  }

  @Builder
  private ButtonContent() {
    Row({ space: 8 }) {
      // 加载图标
      if (this.buttonConfig.loading) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color(this.getTextColor())
      }

      // 左侧图标
      if (this.buttonConfig.icon && this.buttonConfig.iconPosition === 'left' && !this.buttonConfig.loading) {
        Text(this.buttonConfig.icon)
          .fontSize(this.getFontSize())
          .fontColor(this.getTextColor())
      }

      // 按钮文字
      if (this.text) {
        Text(this.text)
          .fontSize(this.getFontSize())
          .fontColor(this.getTextColor())
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }

      // 右侧图标
      if (this.buttonConfig.icon && this.buttonConfig.iconPosition === 'right' && !this.buttonConfig.loading) {
        Text(this.buttonConfig.icon)
          .fontSize(this.getFontSize())
          .fontColor(this.getTextColor())
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height('100%')
  }

  private handleButtonClick(): void {
    if (!this.buttonConfig.disabled && !this.buttonConfig.loading && this.onTap) {
      this.onTap()
    }
  }

  build() {
    Button() {
      this.ButtonContent()
    }
      .height(this.getHeight())
      .padding({
        left: this.getPadding().left,
        right: this.getPadding().right,
        top: 0,
        bottom: 0
      })
      .backgroundColor(this.getBackgroundColor())
      .fontColor(this.getTextColor())
      .border({
        width: this.getBorderWidth(),
        color: this.getBorderColor()
      })
      .borderRadius(
        this.buttonConfig.rounded
          ? this.getHeight() / 2
          : (this.buttonConfig.size === 'small' ? 4 : 6)
      )
      .width(this.buttonConfig.fullWidth ? '100%' : 'auto')
      .enabled(!this.buttonConfig.disabled && !this.buttonConfig.loading)
      .onClick(() => this.handleButtonClick())
      .animation({
        duration: 200,
        curve: Curve.EaseInOut,
        delay: 0
      })
      .scale({
        x: this.buttonConfig.disabled ? 1 : 1,
        y: this.buttonConfig.disabled ? 1 : 1
      })
      .opacity(this.buttonConfig.disabled ? 0.6 : 1)
      .shadow(
        this.buttonConfig.type === 'primary' && !this.buttonConfig.disabled
          ? {
              radius: 4,
              color: '#00000020',
              offsetX: 0,
              offsetY: 2
            }
          : {
              radius: 0,
              color: Color.Transparent,
              offsetX: 0,
              offsetY: 0
            }
      )
  }
}