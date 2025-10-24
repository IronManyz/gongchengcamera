/**
 * 主题观察者模式实现
 * 提供全局主题状态管理
 */

import { ThemeType, ThemeName, ThemeConfig } from './ThemeManager'

// 重新导出ThemeConfig以避免循环导入问题
export { ThemeConfig } from './ThemeManager'

/**
 * 简单的主题状态管理器
 */
export class ThemeState {
  private static instance: ThemeState
  private _currentTheme: ThemeConfig = {
    type: ThemeType.LIGHT,
    name: ThemeName.ENGINEERING,
    isDark: false
  }
  private _updateCount: number = 0

  private constructor() {}

  static getInstance(): ThemeState {
    if (!ThemeState.instance) {
      ThemeState.instance = new ThemeState()
    }
    return ThemeState.instance
  }

  get currentTheme(): ThemeConfig {
    return this._currentTheme
  }

  get updateCount(): number {
    return this._updateCount
  }

  setTheme(theme: ThemeConfig): void {
    this._currentTheme = theme
    this._updateCount++
  }
}