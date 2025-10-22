/**
 * 设计系统输入框组件
 * 统一样式的文本输入框和变体
 */

import { AppColors } from '../AppColors'
import { AppTypography } from '../AppTypography'
import { Spacing } from '../AppSpacing'

/**
 * 输入框类型
 */
export enum InputType {
  TEXT = 'text',
  PASSWORD = 'password',
  NUMBER = 'number',
  EMAIL = 'email',
  PHONE = 'phone',
  SEARCH = 'search'
}

/**
 * 输入框尺寸
 */
export enum InputSize {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large'
}

/**
 * 输入框状态
 */
export enum InputState {
  DEFAULT = 'default',
  SUCCESS = 'success',
  WARNING = 'warning',
  ERROR = 'error',
  DISABLED = 'disabled'
}

/**
 * 输入框组件接口
 */
export interface InputProps {
  type?: InputType
  size?: InputSize
  state?: InputState
  value?: string
  placeholder?: string
  label?: string
  helper?: string
  error?: string
  disabled?: boolean
  readonly?: boolean
  required?: boolean
  maxLength?: number
  borderRadius?: number
  prefix?: string
  suffix?: string
  onChange?: (value: string) => void
  onFocus?: () => void
  onBlur?: () => void
  onSubmit?: () => void
}

/**
 * 获取输入框高度
 */
const getInputHeight = (size: InputSize): number => {
  switch (size) {
    case InputSize.SMALL:
      return 32
    case InputSize.MEDIUM:
      return 40
    case InputSize.LARGE:
      return 48
    default:
      return 40
  }
}

/**
 * 获取输入框字号
 */
const getInputFontSize = (size: InputSize): number => {
  switch (size) {
    case InputSize.SMALL:
      return AppTypography.FontSizes.bodySmall
    case InputSize.MEDIUM:
      return AppTypography.FontSizes.bodyMedium
    case InputSize.LARGE:
      return AppTypography.FontSizes.bodyLarge
    default:
      return AppTypography.FontSizes.bodyMedium
  }
}

/**
 * 获取输入框内边距
 */
const getInputPadding = (size: InputSize): { left: number, right: number } => {
  switch (size) {
    case InputSize.SMALL:
      return { left: Spacing.sm, right: Spacing.sm }
    case InputSize.MEDIUM:
      return { left: Spacing.md, right: Spacing.md }
    case InputSize.LARGE:
      return { left: Spacing.lg, right: Spacing.lg }
    default:
      return { left: Spacing.md, right: Spacing.md }
  }
}

/**
 * 获取输入框边框色
 */
const getInputBorderColor = (state: InputState): string => {
  switch (state) {
    case InputState.SUCCESS:
      return AppColors.success
    case InputState.WARNING:
      return AppColors.warning
    case InputState.ERROR:
      return AppColors.error
    case InputState.DISABLED:
      return AppColors.borderTertiary
    case InputState.DEFAULT:
    default:
      return AppColors.borderPrimary
  }
}

/**
 * 获取输入框文字色
 */
const getInputTextColor = (state: InputState): string => {
  switch (state) {
    case InputState.DISABLED:
      return AppColors.textDisabled
    case InputState.ERROR:
      return AppColors.error
    case InputState.SUCCESS:
      return AppColors.success
    case InputState.WARNING:
      return AppColors.warning
    case InputState.DEFAULT:
    default:
      return AppColors.textPrimary
  }
}

/**
 * 设计系统输入框组件
 */
@ComponentV2
export struct DesignInput {
  @Local value: string = ''
  @Local focused: boolean = false

  @Param type: InputType = InputType.TEXT
  @Param size: InputSize = InputSize.MEDIUM
  @Param state: InputState = InputState.DEFAULT
  @Param placeholder: string = ''
  @Param label: string = ''
  @Param helper: string = ''
  @Param error: string = ''
  @Param disabled: boolean = false
  @Param readonly: boolean = false
  @Param required: boolean = false
  @Param maxLength: number = 0
  @Param borderRadius: number = 8
  @Param prefix: string = ''
  @Param suffix: string = ''
  @Param onChange?: (value: string) => void
  @Param onFocus?: () => void
  @Param onBlur?: () => void
  @Param onSubmit?: () => void

  build() {
    Column() {
      if (this.label) {
        this.buildLabel()
      }

      this.buildInput()

      if (this.error) {
        this.buildError()
      } else if (this.helper) {
        this.buildHelper()
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建标签
   */
  @Builder
  private buildLabel() {
    Text(this.label + (this.required ? ' *' : ''))
      .fontSize(AppTypography.FontSizes.bodySmall)
      .fontColor(this.getInputStateColor())
      .fontWeight(FontWeight.Medium)
      .margin({ bottom: Spacing.xs })
  }

  /**
   * 构建输入框
   */
  @Builder
  private buildInput() {
    Row() {
      if (this.prefix) {
        Text(this.prefix)
          .fontSize(getInputFontSize(this.size))
          .fontColor(AppColors.textSecondary)
          .margin({ right: Spacing.xs })
      }

      TextInput({
        placeholder: this.placeholder,
        text: this.value
      })
        .width('100%')
        .height(getInputHeight(this.size))
        .fontSize(getInputFontSize(this.size))
        .fontColor(getInputTextColor(this.state))
        .backgroundColor(AppColors.bgPrimary)
        .borderRadius(this.borderRadius)
        .border({
          width: 1,
          color: this.focused ? AppColors.primary : getInputBorderColor(this.state)
        })
        .padding({
          left: getInputPadding(this.size).left,
          right: getInputPadding(this.size).right
        })
        .enabled(!this.disabled && !this.readonly)
        .maxLength(this.maxLength > 0 ? this.maxLength : undefined)
        .type(this.getInputType())
        .onChange((value: string) => {
          this.value = value
          if (this.onChange) {
            this.onChange(value)
          }
        })
        .onFocus(() => {
          this.focused = true
          if (this.onFocus) {
            this.onFocus()
          }
        })
        .onBlur(() => {
          this.focused = false
          if (this.onBlur) {
            this.onBlur()
          }
        })
        .onSubmit(() => {
          if (this.onSubmit) {
            this.onSubmit()
          }
        })

      if (this.suffix) {
        Text(this.suffix)
          .fontSize(getInputFontSize(this.size))
          .fontColor(AppColors.textSecondary)
          .margin({ left: Spacing.xs })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.disabled ? AppColors.bgDisabled : AppColors.bgPrimary)
    .borderRadius(this.borderRadius)
    .border({
      width: 1,
      color: this.focused ? AppColors.primary : getInputBorderColor(this.state)
    })
    .padding({ left: getInputPadding(this.size).left, right: getInputPadding(this.size).right })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 构建错误信息
   */
  @Builder
  private buildError() {
    Text(this.error)
      .fontSize(AppTypography.FontSizes.bodySmall)
      .fontColor(AppColors.error)
      .margin({ top: Spacing.xs })
  }

  /**
   * 构建帮助信息
   */
  @Builder
  private buildHelper() {
    Text(this.helper)
      .fontSize(AppTypography.FontSizes.bodySmall)
      .fontColor(AppColors.textTertiary)
      .margin({ top: Spacing.xs })
  }

  /**
   * 获取输入类型
   */
  private getInputType(): InputType {
    if (this.disabled) return InputType.TEXT
    return this.type
  }

  /**
   * 获取状态对应的文字色
   */
  private getInputStateColor(): string {
    switch (this.state) {
      case InputState.ERROR:
        return AppColors.error
      case InputState.WARNING:
        return AppColors.warning
      case InputState.SUCCESS:
        return AppColors.success
      case InputState.DISABLED:
        return AppColors.textDisabled
      default:
        return AppColors.textPrimary
    }
  }
}

/**
 * 搜索输入框
 */
@ComponentV2
export struct SearchInput {
  @Local value: string = ''

  @Param placeholder: string = '搜索...'
  @Param onSearch?: (keyword: string) => void
  @Param onChange?: (value: string) => void
  @Param size: InputSize = InputSize.MEDIUM

  build() {
    DesignInput({
      value: this.value,
      type: InputType.SEARCH,
      size: this.size,
      placeholder: this.placeholder,
      prefix: '🔍',
      onChange: (value: string) => {
        this.value = value
        if (this.onChange) {
          this.onChange(value)
        }
      },
      onSubmit: () => {
        if (this.onSearch && this.value) {
          this.onSearch(this.value)
        }
      }
    })
  }
}

/**
 * 数字输入框
 */
@ComponentV2
export struct NumberInput {
  @Local value: string = ''

  @Param placeholder: string = '请输入数字'
  @Param min?: number
  @Param max?: number
  @Param step: number = 1
  @Param onChange?: (value: number) => void

  build() {
    DesignInput({
      value: this.value,
      type: InputType.NUMBER,
      placeholder: this.placeholder,
      onChange: (value: string) => {
        if (this.isValidNumber(value)) {
          this.value = value
          if (this.onChange) {
            this.onChange(parseFloat(value) || 0)
          }
        }
      }
    })
  }

  /**
   * 验证是否为有效数字
   */
  private isValidNumber(value: string): boolean {
    const num = parseFloat(value)
    if (isNaN(num)) return false
    if (this.min !== undefined && num < this.min) return false
    if (this.max !== undefined && num > this.max) return false
    return true
  }
}