/**
 * 应用排版系统
 * 统一管理字体、字号、行高等排版规范
 */

/**
 * 字体定义
 */
export const AppFonts = {
  // 系统字体
  system: 'HarmonyOS Sans',
  systemCondensed: 'HarmonyOS Sans Condensed',

  // 数字字体
  mono: 'HarmonyOS Sans SC',

  // 装饰字体
  decorative: 'HarmonyOS Sans'
}

/**
 * 字号定义
 */
export const FontSizes = {
  // 标题字号
  heading1: 32,  // 页面主标题
  heading2: 28,  // 区块标题
  heading3: 24,  // 卡片标题
  heading4: 20,  // 小标题
  heading5: 18,  // 导航标题

  // 正文字号
  bodyLarge: 16,  // 正文大号
  bodyMedium: 14, // 正文中号
  bodySmall: 12,  // 正文小号
  bodyTiny: 10,   // 正文极小

  // 特殊字号
  caption: 12,   // 说明文字
  footnote: 10,   // 脚注文字
  overline: 8     // 超小文字
}

/**
 * 字重定义
 */
export const FontWeights = {
  ultraLight: FontWeight.UltraLight,
  light: FontWeight.Light,
  normal: FontWeight.Normal,
  regular: FontWeight.Regular,
  medium: FontWeight.Medium,
  semibold: FontWeight.SemiBold,
  bold: FontWeight.Bold,
  heavy: FontWeight.Heavy
}

/**
 * 行高定义
 */
export const LineHeights = {
  heading1: 1.2,
  heading2: 1.3,
  heading3: 1.3,
  heading4: 1.4,
  heading5: 1.4,

  bodyLarge: 1.5,
  bodyMedium: 1.5,
  bodySmall: 1.4,
  bodyTiny: 1.4,

  caption: 1.3,
  footnote: 1.3,
  overline: 1.2
}

/**
 * 字间距定义
 */
export const LetterSpacings = {
  tight: -0.5,
  normal: 0,
  wide: 0.5,
  wider: 1
}

/**
 * 排版样式组合
 */
export const TypographyStyles = {
  // 标题样式
  heading1: {
    fontSize: FontSizes.heading1,
    fontWeight: FontWeights.medium,
    lineHeight: LineHeights.heading1,
    letterSpacing: LetterSpacings.tight,
    color: '#262626'
  },

  heading2: {
    fontSize: FontSizes.heading2,
    fontWeight: FontWeights.medium,
    lineHeight: LineHeights.heading2,
    letterSpacing: LetterSpacings.tight,
    color: '#262626'
  },

  heading3: {
    fontSize: FontSizes.heading3,
    fontWeight: FontWeights.medium,
    lineHeight: LineHeights.heading3,
    letterSpacing: LetterSpacings.normal,
    color: '#262626'
  },

  heading4: {
    fontSize: FontSizes.heading4,
    fontWeight: FontWeight.Medium,
    lineHeight: LineHeights.heading4,
    letterSpacing: LetterSpacings.normal,
    color: '#262626'
  },

  heading5: {
    fontSize: FontSizes.heading5,
    fontWeight: FontWeight.Medium,
    lineHeight: LineHeights.heading5,
    letterSpacing: LetterSpacings.normal,
    color: '#262626'
  },

  // 正文样式
  bodyLarge: {
    fontSize: FontSizes.bodyLarge,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodyLarge,
    letterSpacing: LetterSpacings.normal,
    color: '#262626'
  },

  bodyMedium: {
    fontSize: FontSizes.bodyMedium,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodyMedium,
    letterSpacing: LetterSpacings.normal,
    color: '#595959'
  },

  bodySmall: {
    fontSize: FontSizes.bodySmall,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodySmall,
    letterSpacing: LetterSpacings.normal,
    color: '#8C8C8C'
  },

  bodyTiny: {
    fontSize: FontSizes.bodyTiny,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodyTiny,
    letterSpacing: LetterSpacings.normal,
    color: '#BFBFBF'
  },

  // 特殊样式
  caption: {
    fontSize: FontSizes.caption,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.caption,
    letterSpacing: LetterSpacings.normal,
    color: '#8C8C8C'
  },

  footnote: {
    fontSize: FontSizes.footnote,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.footnote,
    letterSpacing: LetterSpacings.normal,
    color: '#BFBFBF'
  },

  overline: {
    fontSize: FontSizes.overline,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.overline,
    letterSpacing: LetterSpacings.wide,
    color: '#D9D9D9',
    textTransform: TextTransform.Uppercase
  },

  // 强调文字
  bodyLargeBold: {
    fontSize: FontSizes.bodyLarge,
    fontWeight: FontWeights.medium,
    lineHeight: LineHeights.bodyLarge,
    letterSpacing: LetterSpacings.normal,
    color: '#262626'
  },

  bodyMediumBold: {
    fontSize: FontSizes.bodyMedium,
    fontWeight: FontWeights.medium,
    lineHeight: LineHeights.bodyMedium,
    letterSpacing: LetterSpacings.normal,
    color: '#262626'
  },

  bodySmallBold: {
    fontSize: FontSizes.bodySmall,
    fontWeight: FontWeights.medium,
    lineHeight: LineHeights.bodySmall,
    letterSpacing: LetterSpacings.normal,
    color: '#595959'
  },

  // 状态文字
  textDisabled: {
    fontSize: FontSizes.bodyMedium,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodyMedium,
    letterSpacing: LetterSpacings.normal,
    color: '#D9D9D9'
  },

  textLink: {
    fontSize: FontSizes.bodyMedium,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodyMedium,
    letterSpacing: LetterSpacings.normal,
    color: '#1890FF',
    textDecoration: TextDecoration.Underline
  },

  textError: {
    fontSize: FontSizes.bodySmall,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodySmall,
    letterSpacing: LetterSpacings.normal,
    color: '#FF4D4F'
  },

  textWarning: {
    fontSize: FontSizes.bodySmall,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodySmall,
    letterSpacing: LetterSpacings.normal,
    color: '#FAAD14'
  },

  textSuccess: {
    fontSize: FontSizes.bodySmall,
    fontWeight: FontWeights.normal,
    lineHeight: LineHeights.bodySmall,
    letterSpacing: LetterSpacings.normal,
    color: '#52C41A'
  }
}

/**
 * 响应式字号
 */
export const ResponsiveSizes = {
  // 小屏幕设备
  small: {
    heading1: 28,
    heading2: 24,
    heading3: 20,
    heading4: 18,
    heading5: 16,
    bodyLarge: 14,
    bodyMedium: 13,
    bodySmall: 11,
    caption: 11
  },

  // 中等屏幕设备
  medium: {
    heading1: 30,
    heading2: 26,
    heading3: 22,
    heading4: 20,
    heading5: 18,
    bodyLarge: 15,
    bodyMedium: 14,
    bodySmall: 12,
    caption: 12
  },

  // 大屏幕设备
  large: {
    heading1: 32,
    heading2: 28,
    heading3: 24,
    heading4: 20,
    heading5: 18,
    bodyLarge: 16,
    bodyMedium: 14,
    bodySmall: 12,
    caption: 12
  }
}

/**
 * 排版工具函数
 */
export const TypographyUtils = {
  /**
   * 获取响应式字号
   */
  getResponsiveSize: (baseSize: number, screenWidth: number): number => {
    if (screenWidth < 320) return Math.max(10, baseSize - 4)
    if (screenWidth < 600) return Math.max(12, baseSize - 2)
    return baseSize
  },

  /**
   * 应用文本样式到组件
   */
  applyStyle: (style: any, textStyle: any) => {
    Object.assign(style, textStyle)
  },

  /**
   * 创建自定义文本样式
   */
  createStyle: (
    fontSize: number,
    fontWeight: FontWeight = FontWeight.Normal,
    lineHeight: number = 1.4,
    color: string = '#262626',
    letterSpacing: number = 0
  ) => {
    return {
      fontSize: fontSize,
      fontWeight: fontWeight,
      lineHeight: lineHeight,
      color: color,
      letterSpacing: letterSpacing
    }
  },

  /**
   * 获取截断文本样式
   */
  getEllipsisStyle: (maxLines: number = 1) => {
    return {
      maxLines: maxLines,
      textOverflow: { overflow: TextOverflow.Ellipsis }
    }
  },

  /**
   * 获取强调文本样式
   */
  getEmphasisStyle: (baseStyle: any) => {
    return {
      ...baseStyle,
      fontWeight: FontWeights.medium
    }
  },

  /**
   * 获取次要文本样式
   */
  getSecondaryStyle: (baseStyle: any) => {
    return {
      ...baseStyle,
      fontWeight: FontWeights.normal,
      color: '#8C8C8C'
    }
  }
}

/**
 * 文本转换工具
 */
export const TextTransforms = {
  capitalize: (text: string): string => {
    return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase()
  },

  uppercase: (text: string): string => {
    return text.toUpperCase()
  },

  lowercase: (text: string): string => {
    return text.toLowerCase()
  }
}