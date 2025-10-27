/**
 * 统一输入框组件
 * 提供多种输入框样式和验证功能
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface InputConfig {
  type?: 'text' | 'password' | 'number' | 'email' | 'phone'
  placeholder?: string
  label?: string
  required?: boolean
  disabled?: boolean
  readonly?: boolean
  clearable?: boolean
  prefixIcon?: string
  suffixIcon?: string
  errorMessage?: string
  helperText?: string
  maxLength?: number
  size?: 'small' | 'medium' | 'large'
  variant?: 'outlined' | 'filled' | 'underlined'
}

@ComponentV2
export struct AppInput {
  @Param value: string = ''
  @Param config?: InputConfig = {}
  @Param onChange?: (value: string) => void = () => {}
  @Param onFocus?: () => void = () => {}
  @Param onBlur?: () => void = () => {}
  @Param onClear?: () => void = () => {}

  @State private isFocused: boolean = false
  @State private showPassword: boolean = false
  @State private localValue: string = ''

  aboutToAppear() {
    this.localValue = this.value
  }

  private get inputConfig(): InputConfig {
    return {
      type: 'text',
      size: 'medium',
      variant: 'outlined',
      required: false,
      disabled: false,
      readonly: false,
      clearable: true,
      ...this.config
    }
  }

  private getHeight(): number {
    switch (this.inputConfig.size) {
      case 'small': return 36
      case 'large': return 48
      default: return 44
    }
  }

  private getFontSize(): number {
    switch (this.inputConfig.size) {
      case 'small': return 12
      case 'large': return 16
      default: return 14
    }
  }

  private getLabelFontSize(): number {
    return this.inputConfig.size === 'small' ? 10 : 12
  }

  private getInputBorderRadius(): number {
    switch (this.inputConfig.variant) {
      case 'underlined': return 0
      default: return this.inputConfig.size === 'small' ? 4 : 6
    }
  }

  private getInputBackgroundColor(): string {
    if (this.inputConfig.disabled) {
      return '#F5F5F5'
    }

    switch (this.inputConfig.variant) {
      case 'filled':
        return '#FAFAFA'
      case 'underlined':
        return Color.Transparent.toString()
      case 'outlined':
      default:
        return '#FFFFFF'
    }
  }

  private getInputBorderColor(): string {
    if (this.inputConfig.disabled) {
      return '#E0E0E0'
    }

    if (this.inputConfig.errorMessage) {
      return '#FF4D4F'
    }

    if (this.isFocused) {
      return ThemeManager.getCurrentPrimaryColor()
    }

    return '#D9D9D9'
  }

  private getInputBorderWidth(): number {
    switch (this.inputConfig.variant) {
      case 'underlined':
        return this.isFocused ? 2 : 1
      case 'filled':
        return 0
      case 'outlined':
      default:
        return 1
    }
  }

  private handleInputChange(newValue: string): void {
    if (this.inputConfig.maxLength && newValue.length > this.inputConfig.maxLength) {
      return
    }

    this.localValue = newValue
    if (this.onChange) {
      this.onChange(newValue)
    }
  }

  private handleInputFocus(): void {
    this.isFocused = true
    if (this.onFocus) {
      this.onFocus()
    }
  }

  private handleInputBlur(): void {
    this.isFocused = false
    if (this.onBlur) {
      this.onBlur()
    }
  }

  private handleClear(): void {
    this.localValue = ''
    if (this.onChange) {
      this.onChange('')
    }
    if (this.onClear) {
      this.onClear()
    }
  }

  private togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword
  }

  @Builder
  private InputField() {
    Row({ space: 8 }) {
      // 前缀图标
      if (this.inputConfig.prefixIcon) {
        Text(this.inputConfig.prefixIcon)
          .fontSize(this.getFontSize())
          .fontColor('#999999')
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
      }

      // 输入框
      TextInput({
        placeholder: this.inputConfig.placeholder || '',
        text: this.localValue
      })
        .width('100%')
        .height('100%')
        .fontSize(this.getFontSize())
        .fontColor('#333333')
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .border({ width: 0 })
        .maxLength(this.inputConfig.maxLength)
        .enabled(!this.inputConfig.disabled && !this.inputConfig.readonly)
        .type(this.inputConfig.type === 'password' && !this.showPassword ? InputType.Password : InputType.Normal)
        .onChange((value: string) => this.handleInputChange(value))
        .onFocus(() => this.handleInputFocus())
        .onBlur(() => this.handleInputBlur())

      // 清除按钮
      if (this.inputConfig.clearable && this.localValue && !this.inputConfig.disabled && !this.inputConfig.readonly) {
        Button('✕')
          .fontSize(12)
          .fontColor('#999999')
          .backgroundColor(Color.Transparent)
          .width(20)
          .height(20)
          .borderRadius(10)
          .onClick(() => this.handleClear())
      }

      // 密码显示切换
      if (this.inputConfig.type === 'password' && !this.inputConfig.disabled && !this.inputConfig.readonly) {
        Button(this.showPassword ? '👁️' : '👁️‍🗨️')
          .fontSize(14)
          .fontColor('#999999')
          .backgroundColor(Color.Transparent)
          .width(20)
          .height(20)
          .borderRadius(10)
          .onClick(() => this.togglePasswordVisibility())
      }

      // 后缀图标
      if (this.inputConfig.suffixIcon && this.inputConfig.type !== 'password') {
        Text(this.inputConfig.suffixIcon)
          .fontSize(this.getFontSize())
          .fontColor('#999999')
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12 })
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column({ space: 4 }) {
      // 标签
      if (this.inputConfig.label) {
        Row() {
          Text(this.inputConfig.label)
            .fontSize(this.getLabelFontSize())
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)

          if (this.inputConfig.required) {
            Text('*')
              .fontSize(this.getLabelFontSize())
              .fontColor('#FF4D4F')
              .margin({ left: 2 })
          }

          Blank()
        }
        .width('100%')
        .margin({ bottom: 4 })
      }

      // 输入框容器
      Column() {
        this.InputField()
      }
      .width('100%')
      .height(this.getHeight())
      .backgroundColor(this.getInputBackgroundColor())
      .borderRadius(this.getInputBorderRadius())
      .border({
        width: this.getInputBorderWidth(),
        color: this.getInputBorderColor()
      })
      .animation({
        duration: 200,
        curve: Curve.EaseInOut,
        delay: 0,
        play: true
      })
      .shadow(
        this.inputConfig.variant === 'outlined' && this.isFocused
          ? {
              radius: 4,
              color: `${ThemeManager.getCurrentPrimaryColor()}20`,
              offsetX: 0,
              offsetY: 0
            }
          : {
              radius: 0,
              color: Color.Transparent,
              offsetX: 0,
              offsetY: 0
            }
      )

      // 底部边框（underlined样式）
      if (this.inputConfig.variant === 'underlined') {
        Column()
          .width('100%')
          .height(2)
          .backgroundColor(this.getInputBorderColor())
          .margin({ top: -1 })
      }

      // 错误信息
      if (this.inputConfig.errorMessage) {
        Row() {
          Text(this.inputConfig.errorMessage)
            .fontSize(12)
            .fontColor('#FF4D4F')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })
      }

      // 帮助文字
      if (this.inputConfig.helperText && !this.inputConfig.errorMessage) {
        Row() {
          Text(this.inputConfig.helperText)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 字符计数
          if (this.inputConfig.maxLength) {
            Text(`${this.localValue.length}/${this.inputConfig.maxLength}`)
              .fontSize(12)
              .fontColor('#999999')
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}