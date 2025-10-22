/**
 * 设计系统卡片组件
 * 统一样式的卡片容器和变体
 */

import { AppColors } from '../AppColors'
import { AppTypography } from '../AppTypography'
import { Spacing } from '../AppSpacing'
import { SizeUtils } from '../AppSpacing'

/**
 * 卡片类型
 */
export enum CardType {
  DEFAULT = 'default',
  ELEVATED = 'elevated',
  OUTLINED = 'outlined',
  FILLED = 'filled'
}

/**
 * 卡片尺寸
 */
export enum CardSize {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large'
}

/**
 * 卡片组件接口
 */
export interface CardProps {
  type?: CardType
  size?: CardSize
  padding?: number
  margin?: number
  borderRadius?: number
  backgroundColor?: string
  shadow?: number
  fullWidth?: boolean
  children?: any
}

/**
 * 获取卡片背景色
 */
const getCardBackgroundColor = (type: CardType, customColor?: string): string => {
  if (customColor) return customColor

  switch (type) {
    case CardType.FILLED:
      return AppColors.bgSecondary
    case CardType.DEFAULT:
    case CardType.ELEVATED:
    case CardType.OUTLINED:
    default:
      return AppColors.bgPrimary
  }
}

/**
 * 获取卡片边框样式
 */
const getCardBorderStyle = (type: CardType) => {
  switch (type) {
    case CardType.OUTLINED:
      return {
        width: 1,
        color: AppColors.borderPrimary
      }
    case CardType.ELEVATED:
    case CardType.FILLED:
    case CardType.DEFAULT:
    default:
      return {
        width: 0,
        color: 'transparent'
      }
  }
}

/**
 * 获取卡片阴影样式
 */
const getCardShadow = (type: CardType, level: number = 1) => {
  switch (type) {
    case CardType.ELEVATED:
      return SizeUtils.getShadowStyle(level)
    case CardType.DEFAULT:
    case CardType.OUTLINED:
    case CardType.FILLED:
    default:
      return null
  }
}

/**
 * 获取卡片内边距
 */
const getCardPadding = (size: CardSize, customPadding?: number): number => {
  if (customPadding !== undefined) return customPadding

  switch (size) {
    case CardSize.SMALL:
      return Spacing.md
    case CardSize.MEDIUM:
      return Spacing.lg
    case CardSize.LARGE:
      return Spacing.xl
    default:
      return Spacing.lg
  }
}

/**
 * 获取卡片圆角
 */
const getCardBorderRadius = (size: CardSize, customRadius?: number): number => {
  if (customRadius !== undefined) return customRadius

  switch (size) {
    case CardSize.SMALL:
      return 6
    case CardSize.MEDIUM:
      return 8
    case CardSize.LARGE:
      return 12
    default:
      return 8
  }
}

/**
 * 设计系统卡片组件
 */
@ComponentV2
export struct DesignCard {
  @Param type: CardType = CardType.DEFAULT
  @Param size: CardSize = CardSize.MEDIUM
  @Param padding: number = 0
  @Param margin: number = 0
  @Param borderRadius: number = 0
  @Param backgroundColor: string = ''
  @Param shadow: number = 1
  @Param fullWidth: boolean = false
  @BuilderParam children: () => void = this.defaultContent

  build() {
    Column() {
      this.children()
    }
    .width(this.fullWidth ? '100%' : 'auto')
    .backgroundColor(getCardBackgroundColor(this.type, this.backgroundColor))
    .borderRadius(getCardBorderRadius(this.size, this.borderRadius))
    .border(getCardBorderStyle(this.type))
    .padding(getCardPadding(this.size, this.padding))
    .margin(this.margin)
    .shadow(this.getShadowStyle())
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 获取阴影样式
   */
  private getShadowStyle() {
    return getCardShadow(this.type, this.shadow)
  }

  /**
   * 默认内容
   */
  @Builder
  private defaultContent() {
    Text('Card Content')
      .fontSize(AppTypography.FontSizes.bodyMedium)
      .fontColor(AppColors.textPrimary)
  }
}

/**
 * 卡片头部组件
 */
@ComponentV2
export struct CardHeader {
  @Param title: string = ''
  @Param subtitle: string = ''
  @Param icon: string = ''
  @Param action?: () => void
  @Param actionText: string = ''
  @BuilderParam customContent: () => void = this.defaultHeaderContent

  build() {
    Row() {
      if (this.icon || this.title || this.subtitle) {
        this.buildHeaderContent()
      }

      Blank()

      if (this.actionText && this.action) {
        Button(this.actionText)
          .fontSize(AppTypography.FontSizes.bodySmall)
          .fontColor(AppColors.primary)
          .backgroundColor('transparent')
          .onClick(this.action)
      }

      this.customContent()
    }
    .width('100%')
    .padding({ bottom: Spacing.md })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private buildHeaderContent() {
    Row({ space: Spacing.sm }) {
      if (this.icon) {
        Text(this.icon)
          .fontSize(20)
          .fontColor(AppColors.textSecondary)
      }

      Column() {
        if (this.title) {
          Text(this.title)
            .fontSize(AppTypography.FontSizes.heading4)
            .fontColor(AppColors.textPrimary)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(AppTypography.FontSizes.bodySmall)
            .fontColor(AppColors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  private defaultHeaderContent() {
    // 空默认内容
  }
}

/**
 * 卡片内容组件
 */
@ComponentV2
export struct CardContent {
  @BuilderParam children: () => void = this.defaultContent

  build() {
    Column() {
      this.children()
    }
    .width('100%')
  }

  @Builder
  private defaultContent() {
    Text('Card content goes here')
      .fontSize(AppTypography.FontSizes.bodyMedium)
      .fontColor(AppColors.textSecondary)
  }
}

/**
 * 卡片底部组件
 */
@ComponentV2
export struct CardFooter {
  @BuilderParam children: () => void = this.defaultFooterContent

  build() {
    Row() {
      this.children()
    }
    .width('100%')
    .padding({ top: Spacing.md })
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private defaultFooterContent() {
    // 空默认内容
  }
}

/**
 * 基础卡片
 */
export const BasicCard = (content: () => void, props?: Partial<CardProps>) => {
  return DesignCard({
    children: content,
    type: CardType.DEFAULT,
    ...props
  })
}

/**
 * 升起卡片
 */
export const ElevatedCard = (content: () => void, props?: Partial<CardProps>) => {
  return DesignCard({
    children: content,
    type: CardType.ELEVATED,
    shadow: 2,
    ...props
  })
}

/**
 * 轮廓卡片
 */
export const OutlinedCard = (content: () => void, props?: Partial<CardProps>) => {
  return DesignCard({
    children: content,
    type: CardType.OUTLINED,
    ...props
  })
}

/**
 * 填充卡片
 */
export const FilledCard = (content: () => void, props?: Partial<CardProps>) => {
  return DesignCard({
    children: content,
    type: CardType.FILLED,
    ...props
  })
}