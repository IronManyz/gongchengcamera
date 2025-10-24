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
  private static instance: ThemeState | null = null
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
      console.log('ThemeState: New instance created')
    }
    console.log('ThemeState: Returning instance', ThemeState.instance)
    return ThemeState.instance
  }

  get currentTheme(): ThemeConfig {
    return this._currentTheme
  }

  get updateCount(): number {
    return this._updateCount
  }

  setTheme(theme: ThemeConfig): void {
    console.log('ThemeState: setTheme called with', theme)
    console.log('ThemeState: Before update, currentTheme:', this._currentTheme)
    this._currentTheme = theme
    this._updateCount++
    console.log('ThemeState: After update, currentTheme:', this._currentTheme)
    console.log('ThemeState: Update count:', this._updateCount)
  }
}