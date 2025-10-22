/**
 * 应用主题颜色定义
 * 统一管理应用的颜色系统
 */

// 主品牌色 - 蓝色系
export const primary = '#1890FF'
export const primaryLight = '#40A9FF'
export const primaryDark = '#096DD9'
export const primaryBg = '#E6F7FF'
export const primaryBgLight = '#F0F9FF'

// 辅助色
export const success = '#52C41A'
export const successLight = '#73D13D'
export const successDark = '#389E0D'
export const successBg = '#F6FFED'

export const warning = '#FAAD14'
export const warningLight = '#FFC53D'
export const warningDark = '#D48806'
export const warningBg = '#FFFBE6'

export const error = '#FF4D4F'
export const errorLight = '#FF7875'
export const errorDark = '#D32029'
export const errorBg = '#FFF2F0'

export const info = '#1890FF'
export const infoLight = '#40A9FF'
export const infoDark = '#096DD9'
export const infoBg = '#E6F7FF'

// 中性色
export const textPrimary = '#262626'
export const textSecondary = '#595959'
export const textTertiary = '#8C8C8C'
export const textQuaternary = '#BFBFBF'
export const textDisabled = '#D9D9D9'

// 背景色
export const bgPrimary = '#FFFFFF'
export const bgSecondary = '#FAFAFA'
export const bgTertiary = '#F5F5F5'
export const bgQuaternary = '#FAFAFA'
export const bgDisabled = '#F5F5F5'

// 边框色
export const border = '#D9D9D9'
export const borderLight = '#F0F0F0'
export const borderSecondary = '#F5F5F5'
export const borderTertiary = '#FAFAFA'
export const borderPrimary = '#D9D9D9'
export const borderDisabled = '#F5F5F5'

// 分割线色
export const divider = '#F0F0F0'
export const dividerLight = '#FAFAFA'
export const dividerSecondary = '#F5F5F5'

// 阴影色
export const shadow = 'rgba(0, 0, 0, 0.1)'
export const shadowLight = 'rgba(0, 0, 0, 0.05)'
export const shadowDark = 'rgba(0, 0, 0, 0.2)'

// 覆盖层
export const overlay = '#00000040'
export const overlayLight = '#00000020'
export const overlayDark = '#00000060'

// 表面色
export const surface = '#FFFFFF'
export const surfaceVariant = '#F8F9FA'

/**
 * 颜色集合接口
 */
interface ColorCollection {
  primary: string
  primaryLight: string
  primaryDark: string
  primaryBg: string
  primaryBgLight: string
  success: string
  successLight: string
  successDark: string
  successBg: string
  warning: string
  warningLight: string
  warningDark: string
  warningBg: string
  error: string
  errorLight: string
  errorDark: string
  errorBg: string
  info: string
  infoLight: string
  infoDark: string
  infoBg: string
  textPrimary: string
  textSecondary: string
  textTertiary: string
  textQuaternary: string
  textDisabled: string
  bgPrimary: string
  bgSecondary: string
  bgTertiary: string
  bgQuaternary: string
  bgDisabled: string
  border: string
  borderLight: string
  borderSecondary: string
  borderTertiary: string
  borderPrimary: string
  borderDisabled: string
  divider: string
  dividerLight: string
  dividerSecondary: string
  shadow: string
  shadowLight: string
  shadowDark: string
  overlay: string
  overlayLight: string
  overlayDark: string
  surface: string
  surfaceVariant: string
}

/**
 * 应用颜色集合
 */
export const AppColors: ColorCollection = {
  primary,
  primaryLight,
  primaryDark,
  primaryBg,
  primaryBgLight,
  success,
  successLight,
  successDark,
  successBg,
  warning,
  warningLight,
  warningDark,
  warningBg,
  error,
  errorLight,
  errorDark,
  errorBg,
  info,
  infoLight,
  infoDark,
  infoBg,
  textPrimary,
  textSecondary,
  textTertiary,
  textQuaternary,
  textDisabled,
  bgPrimary,
  bgSecondary,
  bgTertiary,
  bgQuaternary,
  bgDisabled,
  border,
  borderLight,
  borderSecondary,
  borderTertiary,
  borderPrimary,
  borderDisabled,
  divider,
  dividerLight,
  dividerSecondary,
  shadow,
  shadowLight,
  shadowDark,
  overlay,
  overlayLight,
  overlayDark,
  surface,
  surfaceVariant
}

/**
 * 工程主题色
 */
export const EngineeringColors = {
  safetyGreen: '#52C41A',
  safetyYellow: '#FAAD14',
  safetyRed: '#FF4D4F',
  safetyBlue: '#1890FF',
  active: '#52C41A',
  completed: '#1890FF',
  paused: '#FAAD14',
  cancelled: '#FF4D4F',
  high: '#FF4D4F',
  medium: '#FAAD14',
  low: '#1890FF',
  excellent: '#52C41A',
  good: '#73D13D',
  average: '#FAAD14',
  poor: '#FF7875',
  critical: '#D32029'
}

/**
 * 主题色彩搭配接口
 */
interface ColorPalette {
  primary: string
  secondary: string
  accent?: string
  background: string
  surface: string
  text: string
  border: string
  shadow: string
}

interface ColorPalettesType {
  engineering: ColorPalette
  safety: ColorPalette
  professional: ColorPalette
}

/**
 * 主题色彩搭配
 */
export const ColorPalettes: ColorPalettesType = {
  engineering: {
    primary: primary,
    secondary: success,
    background: bgPrimary,
    surface: bgSecondary,
    text: textPrimary,
    border: border,
    shadow: shadow
  },
  safety: {
    primary: EngineeringColors.safetyGreen,
    secondary: EngineeringColors.safetyYellow,
    background: bgPrimary,
    surface: bgSecondary,
    text: textPrimary,
    border: border,
    shadow: shadow
  },
  professional: {
    primary: '#2C3E50',
    secondary: '#34495E',
    accent: primary,
    background: '#FFFFFF',
    surface: '#F8F9FA',
    text: '#2C3E50',
    border: '#E1E8ED',
    shadow: 'rgba(0, 0, 0, 0.1)'
  }
}