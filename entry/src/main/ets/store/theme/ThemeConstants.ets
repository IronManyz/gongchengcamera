/**
 * ThemeConstants.ets
 * 主题相关常量和默认配置
 */

/**
 * 主题类型枚举
 */
export enum ThemeType {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

/**
 * 颜色资源常量
 */
export const ThemeColors = {
  // 浅色主题
  light: {
    primary: '#007DFF',
    secondary: '#34A853',
    accent: '#FF6B35',
    background: '#FFFFFF',
    surface: '#F5F5F5',
    error: '#EA4335',
    warning: '#FBBC05',
    success: '#34A853',
    info: '#007DFF',

    // 文本颜色
    text_primary: '#202124',
    text_secondary: '#5F6368',
    text_disabled: '#9AA0A6',
    text_on_primary: '#FFFFFF',
    text_on_secondary: '#FFFFFF',

    // 边框和分割线
    border: '#E0E0E0',
    divider: '#F0F0F0',

    // 阴影
    shadow: 'rgba(0, 0, 0, 0.12)',

    // 特殊用途
    transparent: 'transparent',
    overlay: 'rgba(0, 0, 0, 0.5)'
  },

  // 深色主题
  dark: {
    primary: '#4285F4',
    secondary: '#34A853',
    accent: '#FF8A65',
    background: '#121212',
    surface: '#1E1E1E',
    error: '#F44336',
    warning: '#FF9800',
    success: '#4CAF50',
    info: '#2196F3',

    // 文本颜色
    text_primary: '#FFFFFF',
    text_secondary: '#B3B3B3',
    text_disabled: '#666666',
    text_on_primary: '#FFFFFF',
    text_on_secondary: '#FFFFFF',

    // 边框和分割线
    border: '#333333',
    divider: '#2C2C2C',

    // 阴影
    shadow: 'rgba(0, 0, 0, 0.24)',

    // 特殊用途
    transparent: 'transparent',
    overlay: 'rgba(255, 255, 255, 0.12)'
  }
} as const

/**
 * 字体大小常量
 */
export const FontSizes = {
  xs: 10,
  sm: 12,
  base: 14,
  lg: 16,
  xl: 18,
  '2xl': 20,
  '3xl': 24,
  '4xl': 28,
  '5xl': 32,
  '6xl': 36
} as const

/**
 * 字体粗细常量
 */
export const FontWeights = {
  light: FontWeight.Lighter,
  normal: FontWeight.Normal,
  medium: FontWeight.Medium,
  semibold: FontWeight.Medium,
  bold: FontWeight.Bold,
  extrabold: FontWeight.Bolder
} as const

/**
 * 圆角大小常量
 */
export const BorderRadius = {
  none: 0,
  sm: 4,
  base: 8,
  md: 12,
  lg: 16,
  xl: 20,
  '2xl': 24,
  full: 9999
} as const

/**
 * 间距常量
 */
export const Spacing = {
  xs: 4,
  sm: 8,
  base: 16,
  md: 24,
  lg: 32,
  xl: 48,
  '2xl': 64,
  '3xl': 96
} as const

/**
 * 阴影配置
 */
export const Shadows = {
  sm: {
    radius: 2,
    color: '#000000',
    offsetX: 0,
    offsetY: 1
  },
  base: {
    radius: 4,
    color: '#000000',
    offsetX: 0,
    offsetY: 2
  },
  md: {
    radius: 8,
    color: '#000000',
    offsetX: 0,
    offsetY: 4
  },
  lg: {
    radius: 16,
    color: '#000000',
    offsetX: 0,
    offsetY: 8
  }
} as const

/**
 * 默认主题配置
 */
export const DefaultThemeConfig = {
  type: ThemeType.SYSTEM,
  fontSize: FontSizes.base,
  fontFamily: 'HarmonyOS Sans',
  borderRadius: BorderRadius.base,
  enableAnimations: true,
  enableHaptics: true,
  autoTheme: true
} as const

/**
 * 主题持久化存储键名
 */
export const ThemeStorageKeys = {
  THEME_TYPE: 'theme_type',
  FONT_SIZE: 'theme_font_size',
  FONT_FAMILY: 'theme_font_family',
  BORDER_RADIUS: 'theme_border_radius',
  ENABLE_ANIMATIONS: 'theme_enable_animations',
  ENABLE_HAPTICS: 'theme_enable_haptics',
  AUTO_THEME: 'theme_auto_theme'
} as const

/**
 * 系统主题变化事件类型
 */
export enum ThemeChangeEvent {
  SYSTEM_THEME_CHANGED = 'system_theme_changed',
  USER_THEME_CHANGED = 'user_theme_changed'
}