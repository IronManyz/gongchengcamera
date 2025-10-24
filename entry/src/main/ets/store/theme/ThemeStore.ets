/**
 * ThemeStore.ets
 * 主题状态管理Store
 * 使用V2响应式状态管理，实现主题切换和系统主题监听
 */

import { BaseStore } from '../BaseStore'
import {
  ThemeType,
  ThemeColors,
  FontSizes,
  FontWeights,
  BorderRadius,
  Spacing,
  Shadows,
  DefaultThemeConfig,
  ThemeStorageKeys,
  ThemeChangeEvent
} from './ThemeConstants'
import { systemThemeMonitor, SystemThemeListener } from './SystemThemeMonitor'
import { preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ConfigurationConstant } from '@kit.AbilityKit'

const TAG = 'ThemeStore'

/**
 * 主题状态类
 * 使用V2响应式装饰器确保主题变化触发UI更新
 */
@ObservedV2
export class ThemeState {
  /**
   * 当前主题类型
   */
  @Trace currentTheme: ThemeType = ThemeType.SYSTEM

  /**
   * 实际应用的主题（考虑系统主题）
   */
  @Trace appliedTheme: ThemeType = ThemeType.LIGHT

  /**
   * 系统主题类型
   */
  @Trace systemTheme: ThemeType = ThemeType.LIGHT

  /**
   * 字体大小
   */
  @Trace fontSize: number = DefaultThemeConfig.fontSize

  /**
   * 字体族
   */
  @Trace fontFamily: string = DefaultThemeConfig.fontFamily

  /**
   * 圆角大小
   */
  @Trace borderRadius: number = DefaultThemeConfig.borderRadius

  /**
   * 是否启用动画
   */
  @Trace enableAnimations: boolean = DefaultThemeConfig.enableAnimations

  /**
   * 是否启用触觉反馈
   */
  @Trace enableHaptics: boolean = DefaultThemeConfig.enableHaptics

  /**
   * 是否自动跟随系统主题
   */
  @Trace autoTheme: boolean = DefaultThemeConfig.autoTheme

  /**
   * 主题是否正在加载
   */
  @Trace isLoading: boolean = false
}

/**
 * 应用主题类
 * 提供主题相关的工具方法和颜色访问
 */
@ObservedV2
export class AppTheme {
  /**
   * 获取当前主题颜色
   */
  get colors() {
    const theme = this.getCurrentTheme()
    return ThemeColors[theme]
  }

  /**
   * 获取当前主题
   */
  getCurrentTheme(): 'light' | 'dark' {
    // 这里需要从ThemeState获取实际主题
    // 暂时返回light，实际使用时会与ThemeState关联
    return 'light'
  }

  /**
   * 获取颜色值
   */
  getColor(colorName: keyof typeof ThemeColors.light): string {
    return this.colors[colorName]
  }

  /**
   * 获取字体大小
   */
  getFontSize(size: keyof typeof FontSizes): number {
    return FontSizes[size]
  }

  /**
   * 获取字体粗细
   */
  getFontWeight(weight: keyof typeof FontWeights): FontWeight {
    return FontWeights[weight]
  }

  /**
   * 获取圆角大小
   */
  getBorderRadius(size: keyof typeof BorderRadius): number {
    return BorderRadius[size]
  }

  /**
   * 获取间距
   */
  getSpacing(size: keyof typeof Spacing): number {
    return Spacing[size]
  }

  /**
   * 获取阴影配置
   */
  getShadow(size: keyof typeof Shadows): typeof Shadows.sm {
    return Shadows[size]
  }
}

/**
 * 主题Store类
 */
export class ThemeStore extends BaseStore implements SystemThemeListener {
  /**
   * 主题状态实例
   */
  @ObservedV2
  private _themeState: ThemeState = new ThemeState()

  /**
   * 应用主题实例
   */
  @ObservedV2
  private _appTheme: AppTheme = new AppTheme()

  /**
   * Preferences实例
   */
  private preferencesInstance: preferences.Preferences | null = null

  /**
   * 系统主题监听器
   */
  private systemThemeListener: ((themeType: ThemeType) => void) | null = null

  constructor() {
    super('ThemeStore')
  }

  /**
   * 初始化主题Store
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      this.log('Already initialized')
      return
    }

    await this.safeExecute(
      async () => {
        // 初始化Preferences
        await this.initializePreferences()

        // 加载保存的主题设置
        await this.loadThemeSettings()

        // 设置系统主题监听
        this.setupSystemThemeListener()

        // 获取初始系统主题
        this._themeState.systemTheme = systemThemeMonitor.getCurrentSystemTheme()

        // 更新应用主题
        this.updateAppliedTheme()

        this.markInitialized()
      },
      'initialize',
      'Failed to initialize ThemeStore'
    )
  }

  /**
   * 销毁Store，清理资源
   */
  async destroy(): Promise<void> {
    await this.safeExecute(
      async () => {
        // 移除系统主题监听
        this.removeSystemThemeListener()

        // 保存主题设置
        await this.saveThemeSettings()

        // 清理Preferences
        if (this.preferencesInstance) {
          await preferences.deletePreferences(this.getContext(), 'theme_preferences')
          this.preferencesInstance = null
        }

        this.reset()
        this.log('Destroyed successfully')
      },
      'destroy',
      'Failed to destroy ThemeStore'
    )
  }

  /**
   * 获取主题状态
   */
  get themeState(): ThemeState {
    return this._themeState
  }

  /**
   * 获取应用主题
   */
  get appTheme(): AppTheme {
    return this._appTheme
  }

  /**
   * 设置主题类型
   */
  async setTheme(themeType: ThemeType): Promise<void> {
    this.checkInitialized()

    if (this._themeState.currentTheme === themeType) {
      this.log(`Theme already set to: ${themeType}`)
      return
    }

    await this.safeExecute(
      async () => {
        this._themeState.currentTheme = themeType
        this._themeState.autoTheme = (themeType === ThemeType.SYSTEM)

        // 更新应用主题
        this.updateAppliedTheme()

        // 保存设置
        await this.saveThemeSettings()

        this.log(`Theme changed to: ${themeType}`)
      },
      'setTheme',
      `Failed to set theme to ${themeType}`
    )
  }

  /**
   * 切换主题
   */
  async toggleTheme(): Promise<void> {
    this.checkInitialized()

    const currentTheme = this._themeState.appliedTheme
    const newTheme = currentTheme === ThemeType.LIGHT ? ThemeType.DARK : ThemeType.LIGHT

    await this.setTheme(newTheme)
  }

  /**
   * 设置字体大小
   */
  async setFontSize(fontSize: number): Promise<void> {
    this.checkInitialized()

    if (this._themeState.fontSize === fontSize) {
      return
    }

    await this.safeExecute(
      async () => {
        this._themeState.fontSize = fontSize
        await this.saveThemeSettings()
        this.log(`Font size changed to: ${fontSize}`)
      },
      'setFontSize',
      `Failed to set font size to ${fontSize}`
    )
  }

  /**
   * 设置字体族
   */
  async setFontFamily(fontFamily: string): Promise<void> {
    this.checkInitialized()

    if (this._themeState.fontFamily === fontFamily) {
      return
    }

    await this.safeExecute(
      async () => {
        this._themeState.fontFamily = fontFamily
        await this.saveThemeSettings()
        this.log(`Font family changed to: ${fontFamily}`)
      },
      'setFontFamily',
      `Failed to set font family to ${fontFamily}`
    )
  }

  /**
   * 设置圆角大小
   */
  async setBorderRadius(borderRadius: number): Promise<void> {
    this.checkInitialized()

    if (this._themeState.borderRadius === borderRadius) {
      return
    }

    await this.safeExecute(
      async () => {
        this._themeState.borderRadius = borderRadius
        await this.saveThemeSettings()
        this.log(`Border radius changed to: ${borderRadius}`)
      },
      'setBorderRadius',
      `Failed to set border radius to ${borderRadius}`
    )
  }

  /**
   * 设置动画开关
   */
  async setEnableAnimations(enable: boolean): Promise<void> {
    this.checkInitialized()

    if (this._themeState.enableAnimations === enable) {
      return
    }

    await this.safeExecute(
      async () => {
        this._themeState.enableAnimations = enable
        await this.saveThemeSettings()
        this.log(`Animations ${enable ? 'enabled' : 'disabled'}`)
      },
      'setEnableAnimations',
      `Failed to ${enable ? 'enable' : 'disable'} animations`
    )
  }

  /**
   * 设置触觉反馈开关
   */
  async setEnableHaptics(enable: boolean): Promise<void> {
    this.checkInitialized()

    if (this._themeState.enableHaptics === enable) {
      return
    }

    await this.safeExecute(
      async () => {
        this._themeState.enableHaptics = enable
        await this.saveThemeSettings()
        this.log(`Haptics ${enable ? 'enabled' : 'disabled'}`)
      },
      'setEnableHaptics',
      `Failed to ${enable ? 'enable' : 'disable'} haptics`
    )
  }

  /**
   * 重置主题设置
   */
  async resetTheme(): Promise<void> {
    this.checkInitialized()

    await this.safeExecute(
      async () => {
        this._themeState.currentTheme = DefaultThemeConfig.type
        this._themeState.fontSize = DefaultThemeConfig.fontSize
        this._themeState.fontFamily = DefaultThemeConfig.fontFamily
        this._themeState.borderRadius = DefaultThemeConfig.borderRadius
        this._themeState.enableAnimations = DefaultThemeConfig.enableAnimations
        this._themeState.enableHaptics = DefaultThemeConfig.enableHaptics
        this._themeState.autoTheme = DefaultThemeConfig.autoTheme

        this.updateAppliedTheme()
        await this.saveThemeSettings()

        this.log('Theme reset to default')
      },
      'resetTheme',
      'Failed to reset theme'
    )
  }

  /**
   * 初始化Preferences
   */
  private async initializePreferences(): Promise<void> {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.getContext(), 'theme_preferences')
      this.log('Preferences initialized')
    } catch (error) {
      this.logError('Failed to initialize preferences', error)
      throw error
    }
  }

  /**
   * 加载主题设置
   */
  private async loadThemeSettings(): Promise<void> {
    if (!this.preferencesInstance) {
      this.logError('Preferences not initialized', new Error('Preferences instance is null'))
      return
    }

    try {
      // 加载主题类型
      const themeType = await preferences.get(this.preferencesInstance, ThemeStorageKeys.THEME_TYPE, DefaultThemeConfig.type) as ThemeType
      this._themeState.currentTheme = themeType

      // 加载字体大小
      const fontSize = await preferences.get(this.preferencesInstance, ThemeStorageKeys.FONT_SIZE, DefaultThemeConfig.fontSize) as number
      this._themeState.fontSize = fontSize

      // 加载字体族
      const fontFamily = await preferences.get(this.preferencesInstance, ThemeStorageKeys.FONT_FAMILY, DefaultThemeConfig.fontFamily) as string
      this._themeState.fontFamily = fontFamily

      // 加载圆角大小
      const borderRadius = await preferences.get(this.preferencesInstance, ThemeStorageKeys.BORDER_RADIUS, DefaultThemeConfig.borderRadius) as number
      this._themeState.borderRadius = borderRadius

      // 加载动画开关
      const enableAnimations = await preferences.get(this.preferencesInstance, ThemeStorageKeys.ENABLE_ANIMATIONS, DefaultThemeConfig.enableAnimations) as boolean
      this._themeState.enableAnimations = enableAnimations

      // 加载触觉反馈开关
      const enableHaptics = await preferences.get(this.preferencesInstance, ThemeStorageKeys.ENABLE_HAPTICS, DefaultThemeConfig.enableHaptics) as boolean
      this._themeState.enableHaptics = enableHaptics

      // 加载自动主题开关
      const autoTheme = await preferences.get(this.preferencesInstance, ThemeStorageKeys.AUTO_THEME, DefaultThemeConfig.autoTheme) as boolean
      this._themeState.autoTheme = autoTheme

      this.log('Theme settings loaded successfully')
    } catch (error) {
      this.logError('Failed to load theme settings', error)
      // 加载失败不应该阻止初始化，使用默认值
    }
  }

  /**
   * 保存主题设置
   */
  private async saveThemeSettings(): Promise<void> {
    if (!this.preferencesInstance) {
      return
    }

    try {
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.THEME_TYPE, this._themeState.currentTheme)
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.FONT_SIZE, this._themeState.fontSize)
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.FONT_FAMILY, this._themeState.fontFamily)
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.BORDER_RADIUS, this._themeState.borderRadius)
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.ENABLE_ANIMATIONS, this._themeState.enableAnimations)
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.ENABLE_HAPTICS, this._themeState.enableHaptics)
      await preferences.put(this.preferencesInstance, ThemeStorageKeys.AUTO_THEME, this._themeState.autoTheme)

      await preferences.flush(this.preferencesInstance)
      this.log('Theme settings saved successfully')
    } catch (error) {
      this.logError('Failed to save theme settings', error)
      // 保存失败不应该影响用户体验
    }
  }

  /**
   * 设置系统主题监听
   */
  private setupSystemThemeListener(): void {
    try {
      systemThemeMonitor.addListener(this)
      this.log('System theme listener setup completed')
    } catch (error) {
      this.logError('Failed to setup system theme listener', error)
    }
  }

  /**
   * 移除系统主题监听
   */
  private removeSystemThemeListener(): void {
    try {
      systemThemeMonitor.removeListener(this)
      this.log('System theme listener removed')
    } catch (error) {
      this.logError('Failed to remove system theme listener', error)
    }
  }

  /**
   * 系统主题变化回调
   * 实现SystemThemeListener接口
   */
  onSystemThemeChanged(theme: ThemeType): void {
    this.checkInitialized()

    if (this._themeState.systemTheme === theme) {
      return
    }

    this._themeState.systemTheme = theme
    this.log(`System theme changed to: ${theme}`)

    // 如果启用了自动主题，更新应用主题
    if (this._themeState.autoTheme) {
      this.updateAppliedTheme()
    }
  }

  /**
   * 更新应用主题
   */
  private updateAppliedTheme(): void {
    let appliedTheme: ThemeType

    if (this._themeState.currentTheme === ThemeType.SYSTEM) {
      // 跟随系统主题
      appliedTheme = this._themeState.systemTheme
    } else {
      // 使用用户指定的主题
      appliedTheme = this._themeState.currentTheme
    }

    if (this._themeState.appliedTheme !== appliedTheme) {
      this._themeState.appliedTheme = appliedTheme
      this.log(`Applied theme updated to: ${appliedTheme}`)
    }
  }

  /**
   * 获取Context
   * 这里需要根据实际应用结构获取Context
   */
  private getContext(): Context {
    // 暂时返回一个默认值，实际使用时需要从Ability或其他地方获取
    // 这个方法需要根据项目的实际情况来实现
    return getContext() as Context
  }

  /**
   * 强制应用主题到全局应用上下文
   * 基于HarmonyOS Next官方文档的实现
   */
  private async applyThemeGlobally(themeType: ThemeType): Promise<void> {
    try {
      const context = this.getContext()

      // 使用官方API设置应用级主题
      let colorMode: ConfigurationConstant.ColorMode
      switch (themeType) {
        case ThemeType.LIGHT:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
          break
        case ThemeType.DARK:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          break
        case ThemeType.SYSTEM:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
          break
        default:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
          break
      }

      // 应用主题到应用上下文
      context.getApplicationContext().setColorMode(colorMode)

      this.log(`Global theme applied: ${themeType}, colorMode: ${colorMode}`)

      // 触发全局主题变更事件
      this.triggerGlobalThemeChange(themeType)

    } catch (error) {
      this.logError('Failed to apply theme globally', error)
    }
  }

  /**
   * 触发全局主题变更事件
   * 通知所有监听器主题已变更
   */
  private triggerGlobalThemeChange(themeType: ThemeType): void {
    try {
      // 可以使用EventHub或其他事件系统来通知所有页面
      this.log(`Triggering global theme change: ${themeType}`)

      // 这里应该调用全局的事件通知系统
      // 实际实现中可能需要与应用的主Ability集成

    } catch (error) {
      this.logError('Failed to trigger global theme change', error)
    }
  }
}

/**
 * 主题Store单例实例
 */
export const themeStore = new ThemeStore()