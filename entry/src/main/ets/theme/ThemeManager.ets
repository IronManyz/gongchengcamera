/**
 * 主题管理器
 * 负责主题的切换和应用
 */

import { AppColors, ColorPalettes } from './AppColors'

/**
 * 主题类型枚举
 */
export enum ThemeType {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto' // 跟随系统
}

/**
 * 主题名称
 */
export enum ThemeName {
  ENGINEERING = 'engineering',
  SAFETY = 'safety',
  PROFESSIONAL = 'professional'
}

/**
 * 颜色调色板接口
 */
export interface ColorPalette {
  primary: string
  secondary: string
  background: string
  surface: string
  text: string
  border: string
}

/**
 * 主题配置接口
 */
export interface ThemeConfig {
  type: ThemeType
  name: ThemeName
  isDark: boolean
}

/**
 * 主题变化监听器接口
 */
export interface ThemeChangeListener {
  onThemeChanged(theme: ThemeConfig): void
}

/**
 * 主题管理器类
 */
export class ThemeManager {
  private static currentTheme: ThemeConfig = {
    type: ThemeType.LIGHT,
    name: ThemeName.ENGINEERING,
    isDark: false
  }
  private static listeners: ThemeChangeListener[] = []

  /**
   * 获取当前主题配置
   */
  static getCurrentTheme(): ThemeConfig {
    return ThemeManager.currentTheme
  }

  /**
   * 添加主题变化监听器
   */
  static addThemeChangeListener(listener: ThemeChangeListener): void {
    if (!ThemeManager.listeners.includes(listener)) {
      ThemeManager.listeners.push(listener)
    }
  }

  /**
   * 移除主题变化监听器
   */
  static removeThemeChangeListener(listener: ThemeChangeListener): void {
    const index = ThemeManager.listeners.indexOf(listener)
    if (index > -1) {
      ThemeManager.listeners.splice(index, 1)
    }
  }

  /**
   * 设置主题
   */
  static setTheme(theme: ThemeConfig): void {
    ThemeManager.currentTheme = theme
    // TODO: 保存到本地存储
    console.log('设置主题:', theme)
    // 通知所有监听器
    ThemeManager.listeners.forEach(listener => {
      try {
        listener.onThemeChanged(theme)
      } catch (error) {
        console.error('主题监听器错误:', error)
      }
    })
  }

  /**
   * 切换到浅色主题
   */
  static setLightTheme(): void {
    ThemeManager.setTheme({
      type: ThemeType.LIGHT,
      name: ThemeManager.currentTheme.name,
      isDark: false
    })
  }

  /**
   * 切换到深色主题
   */
  static setDarkTheme(): void {
    ThemeManager.setTheme({
      type: ThemeType.DARK,
      name: ThemeManager.currentTheme.name,
      isDark: true
    })
  }

  /**
   * 切换到自动主题
   */
  static setAutoTheme(): void {
    ThemeManager.setTheme({
      type: ThemeType.AUTO,
      name: ThemeManager.currentTheme.name,
      isDark: false // 默认浅色，实际会根据系统调整
    })
  }

  /**
   * 切换主题名称
   */
  static setThemeName(name: ThemeName): void {
    ThemeManager.setTheme({
      type: ThemeManager.currentTheme.type,
      name: name,
      isDark: ThemeManager.currentTheme.isDark
    })
  }

  /**
   * 获取当前颜色方案
   */
  static getCurrentPalette(): ColorPalette {
    switch (ThemeManager.currentTheme.name) {
      case ThemeName.ENGINEERING:
        return ColorPalettes.engineering
      case ThemeName.SAFETY:
        return ColorPalettes.safety
      case ThemeName.PROFESSIONAL:
        return ColorPalettes.professional
      default:
        return ColorPalettes.engineering
    }
  }

  /**
   * 获取当前背景色
   */
  static getCurrentBgColor(): string {
    const isDark = ThemeManager.currentTheme.isDark
    const themeName = ThemeManager.currentTheme.name
    console.log('=== ThemeManager.getCurrentBgColor() ===')
    console.log('ThemeManager: isDark:', isDark, 'themeName:', themeName)
    console.log('ThemeManager: Full currentTheme:', JSON.stringify(ThemeManager.currentTheme))

    if (isDark) {
      const darkBg = ColorPalettes.dark.background
      console.log('ThemeManager: Returning DARK background:', darkBg)
      return darkBg
    } else {
      const palette = ThemeManager.getCurrentPalette()
      const lightBg = palette.background
      console.log('ThemeManager: Returning LIGHT background from palette:', themeName, 'color:', lightBg)
      return lightBg
    }
  }

  /**
   * 获取当前文本色
   */
  static getCurrentTextColor(): string {
    const isDark = ThemeManager.currentTheme.isDark
    const themeName = ThemeManager.currentTheme.name
    console.log('=== ThemeManager.getCurrentTextColor() ===')
    console.log('ThemeManager: isDark:', isDark, 'themeName:', themeName)

    if (isDark) {
      const darkText = ColorPalettes.dark.text
      console.log('ThemeManager: Returning DARK text color:', darkText)
      return darkText
    } else {
      const palette = ThemeManager.getCurrentPalette()
      const lightText = palette.text
      console.log('ThemeManager: Returning LIGHT text color from palette:', themeName, 'color:', lightText)
      return lightText
    }
  }

  /**
   * 获取当前表面色（卡片背景）
   */
  static getCurrentSurfaceColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return ColorPalettes.dark.surface // 使用深色主题表面色
    } else {
      return ThemeManager.getCurrentPalette().surface
    }
  }

  /**
   * 获取当前边框色
   */
  static getCurrentBorderColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return ColorPalettes.dark.border // 使用深色主题边框色
    } else {
      return ThemeManager.getCurrentPalette().border
    }
  }

  /**
   * 获取适配当前主题的主色调
   */
  static getCurrentPrimaryColor(): string {
    return ThemeManager.getCurrentPalette().primary
  }

  /**
   * 获取适配当前主题的成功色
   */
  static getCurrentSuccessColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return AppColors.successLight // 深色主题使用浅成功色
    } else {
      return AppColors.success
    }
  }

  /**
   * 获取适配当前主题的警告色
   */
  static getCurrentWarningColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return AppColors.warningLight // 深色主题使用浅警告色
    } else {
      return AppColors.warning
    }
  }

  /**
   * 获取适配当前主题的错误色
   */
  static getCurrentErrorColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return AppColors.errorLight // 深色主题使用浅错误色
    } else {
      return AppColors.error
    }
  }

  /**
   * 获取适配当前主题的文本次色
   */
  static getCurrentTextSecondaryColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return AppColors.textQuaternary // 深色主题使用最浅文本色
    } else {
      return AppColors.textSecondary
    }
  }

  /**
   * 获取适配当前主题的分割线色
   */
  static getCurrentDividerColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return AppColors.dividerLight // 深色主题使用浅分割线
    } else {
      return AppColors.divider
    }
  }

  /**
   * 获取适配当前主题的阴影色
   */
  static getCurrentShadowColor(): string {
    if (ThemeManager.currentTheme.isDark) {
      return AppColors.overlayDark // 深色主题使用深阴影
    } else {
      return AppColors.shadowLight
    }
  }

  /**
   * 主题切换工具方法
   */
  static toggleTheme(): void {
    if (ThemeManager.currentTheme.isDark) {
      ThemeManager.setLightTheme()
    } else {
      ThemeManager.setDarkTheme()
    }
  }

  /**
   * 重置到默认主题
   */
  static resetToDefault(): void {
    ThemeManager.setTheme({
      type: ThemeType.LIGHT,
      name: ThemeName.ENGINEERING,
      isDark: false
    })
  }

  /**
   * 从本地存储加载主题设置
   */
  static loadFromStorage(): void {
    // TODO: 从AsyncStorage加载用户主题偏好
    try {
      // const savedTheme = localStorage.getItem('app_theme')
      // if (savedTheme) {
      //   const theme = JSON.parse(savedTheme)
      //   ThemeManager.setTheme(theme)
      // }
    } catch (error) {
      console.warn('加载主题设置失败:', error)
      ThemeManager.resetToDefault()
    }
  }

  /**
   * 保存主题设置到本地存储
   */
  static saveToStorage(): void {
    // TODO: 保存用户主题偏好到AsyncStorage
    try {
      // localStorage.setItem('app_theme', JSON.stringify(ThemeManager.currentTheme))
    } catch (error) {
      console.warn('保存主题设置失败:', error)
    }
  }

  /**
   * 初始化主题管理器
   */
  static initialize(): void {
    ThemeManager.loadFromStorage()
    console.log('主题管理器初始化完成:', ThemeManager.currentTheme)

    // Test dark theme palette availability
    console.log('=== Dark Theme Palette Test ===')
    console.log('ColorPalettes.dark exists:', !!ColorPalettes.dark)
    console.log('ColorPalettes.dark.background:', ColorPalettes.dark.background)
    console.log('ColorPalettes.dark.text:', ColorPalettes.dark.text)
    console.log('ColorPalettes.dark.surface:', ColorPalettes.dark.surface)
  }
}