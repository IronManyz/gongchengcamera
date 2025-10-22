/**
 * 设计系统按钮组件
 * 统一样式的按钮变体和尺寸
 */

import { AppColors } from '../AppColors'
import { AppTypography } from '../AppTypography'
import { Spacing } from '../AppSpacing'

/**
 * 按钮类型
 */
export enum ButtonType {
  PRIMARY = 'primary',
  SECONDARY = 'secondary',
  OUTLINE = 'outline',
  GHOST = 'ghost',
  LINK = 'link',
  DANGER = 'danger',
  SUCCESS = 'success',
  WARNING = 'warning'
}

/**
 * 按钮尺寸
 */
export enum ButtonSize {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large',
  EXTRA_LARGE = 'extra_large'
}

/**
 * 按钮组件接口
 */
export interface ButtonProps {
  type?: ButtonType
  size?: ButtonSize
  text?: string
  disabled?: boolean
  loading?: boolean
  icon?: string
  iconPosition?: 'left' | 'right'
  fullWidth?: boolean
  borderRadius?: number
  onClick?: () => void
}

/**
 * 获取按钮背景色
 */
const getButtonBackgroundColor = (type: ButtonType, disabled: boolean): string => {
  if (disabled) return AppColors.textDisabled

  switch (type) {
    case ButtonType.PRIMARY:
      return AppColors.primary
    case ButtonType.SECONDARY:
      return AppColors.textSecondary
    case ButtonType.DANGER:
      return AppColors.error
    case ButtonType.SUCCESS:
      return AppColors.success
    case ButtonType.WARNING:
      return AppColors.warning
    case ButtonType.OUTLINE:
    case ButtonType.GHOST:
    case ButtonType.LINK:
      return 'transparent'
    default:
      return AppColors.primary
  }
}

/**
 * 获取按钮文字色
 */
const getButtonTextColor = (type: ButtonType, disabled: boolean): string => {
  if (disabled) return AppColors.textDisabled

  switch (type) {
    case ButtonType.PRIMARY:
    case ButtonType.SECONDARY:
    case ButtonType.DANGER:
    case ButtonType.SUCCESS:
    case ButtonType.WARNING:
      return AppColors.bgPrimary
    case ButtonType.OUTLINE:
      return AppColors.primary
    case ButtonType.LINK:
      return AppColors.primary
    case ButtonType.GHOST:
      return AppColors.textPrimary
    default:
      return AppColors.bgPrimary
  }
}

/**
 * 获取按钮边框色
 */
const getButtonBorderColor = (type: ButtonType, disabled: boolean): string => {
  if (disabled) return AppColors.textDisabled

  switch (type) {
    case ButtonType.OUTLINE:
      return AppColors.primary
    case ButtonType.GHOST:
      return AppColors.borderPrimary
    case ButtonType.DANGER:
      return AppColors.error
    case ButtonType.SUCCESS:
      return AppColors.success
    case ButtonType.WARNING:
      return AppColors.warning
    default:
      return 'transparent'
  }
}

/**
 * 获取按钮尺寸样式
 */
const getButtonSizeStyle = (size: ButtonSize) => {
  switch (size) {
    case ButtonSize.SMALL:
      return {
        height: 32,
        paddingHorizontal: Spacing.md,
        fontSize: AppTypography.FontSizes.bodySmall,
        iconSize: 16
      }
    case ButtonSize.MEDIUM:
      return {
        height: 40,
        paddingHorizontal: Spacing.lg,
        fontSize: AppTypography.FontSizes.bodyMedium,
        iconSize: 18
      }
    case ButtonSize.LARGE:
      return {
        height: 48,
        paddingHorizontal: Spacing.xl,
        fontSize: AppTypography.FontSizes.bodyLarge,
        iconSize: 20
      }
    case ButtonSize.EXTRA_LARGE:
      return {
        height: 56,
        paddingHorizontal: Spacing.xxl,
        fontSize: AppTypography.FontSizes.heading5,
        iconSize: 22
      }
    default:
      return {
        height: 40,
        paddingHorizontal: Spacing.lg,
        fontSize: AppTypography.FontSizes.bodyMedium,
        iconSize: 18
      }
  }
}

/**
 * 设计系统按钮组件
 */
@ComponentV2
export struct DesignButton {
  @Param type: ButtonType = ButtonType.PRIMARY
  @Param size: ButtonSize = ButtonSize.MEDIUM
  @Param text: string = ''
  @Param disabled: boolean = false
  @Param loading: boolean = false
  @Param icon: string = ''
  @Param iconPosition: 'left' | 'right' = 'left'
  @Param fullWidth: boolean = false
  @Param borderRadius: number = 8
  @Param onClick?: () => void

  build() {
    Button(this.buildButtonContent())
      .width(this.fullWidth ? '100%' : 'auto')
      .height(getButtonSizeStyle(this.size).height)
      .fontSize(getButtonSizeStyle(this.size).fontSize)
      .fontColor(getButtonTextColor(this.type, this.disabled))
      .fontWeight(FontWeight.Medium)
      .backgroundColor(getButtonBackgroundColor(this.type, this.disabled))
      .borderRadius(this.borderRadius)
      .border({
        width: this.isOutlined() ? 1 : 0,
        color: getButtonBorderColor(this.type, this.disabled)
      })
      .padding({
        left: getButtonSizeStyle(this.size).paddingHorizontal,
        right: getButtonSizeStyle(this.size).paddingHorizontal
      })
      .enabled(!this.disabled && !this.loading)
      .onClick(() => {
        if (this.onClick && !this.disabled && !this.loading) {
          this.onClick()
        }
      })
      .animation({
        duration: 200,
        curve: Curve.EaseInOut
      })
  }

  /**
   * 构建按钮内容
   */
  @Builder
  private buildButtonContent() {
    Row({ space: Spacing.xs }) {
      if (this.loading) {
        LoadingIndicator()
          .width(getButtonSizeStyle(this.size).iconSize)
          .height(getButtonSizeStyle(this.size).iconSize)
          .color(getButtonTextColor(this.type, this.disabled))
      } else if (this.icon && this.iconPosition === 'left') {
        Text(this.icon)
          .fontSize(getButtonSizeStyle(this.size).iconSize)
          .fontColor(getButtonTextColor(this.type, this.disabled))
      }

      if (this.text) {
        Text(this.text)
          .fontSize(getButtonSizeStyle(this.size).fontSize)
          .fontColor(getButtonTextColor(this.type, this.disabled))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (!this.loading && this.icon && this.iconPosition === 'right') {
        Text(this.icon)
          .fontSize(getButtonSizeStyle(this.size).iconSize)
          .fontColor(getButtonTextColor(this.type, this.disabled))
      }
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 检查是否为轮廓按钮
   */
  private isOutlined(): boolean {
    return this.type === ButtonType.OUTLINE ||
           this.type === ButtonType.GHOST ||
           this.type === ButtonType.DANGER ||
           this.type === ButtonType.SUCCESS ||
           this.type === ButtonType.WARNING
  }
}

/**
 * 主要按钮样式
 */
export const PrimaryButton = (text: string, onClick?: () => void, props?: Partial<ButtonProps>) => {
  return DesignButton({
    text: text,
    type: ButtonType.PRIMARY,
    onClick: onClick,
    ...props
  })
}

/**
 * 次要按钮样式
 */
export const SecondaryButton = (text: string, onClick?: () => void, props?: Partial<ButtonProps>) => {
  return DesignButton({
    text: text,
    type: ButtonType.SECONDARY,
    onClick: onClick,
    ...props
  })
}

/**
 * 轮廓按钮样式
 */
export const OutlineButton = (text: string, onClick?: () => void, props?: Partial<ButtonProps>) => {
  return DesignButton({
    text: text,
    type: ButtonType.OUTLINE,
    onClick: onClick,
    ...props
  })
}

/**
 * 文字按钮样式
 */
export const TextButton = (text: string, onClick?: () => void, props?: Partial<ButtonProps>) => {
  return DesignButton({
    text: text,
    type: ButtonType.GHOST,
    onClick: onClick,
    ...props
  })
}