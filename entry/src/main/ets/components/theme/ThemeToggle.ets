/**
 * 主题切换组件
 * 提供浅色/深色主题切换功能
 */

import { ThemeManager, ThemeType, ThemeName } from '../../theme/ThemeManager'
import { ThemeState, ThemeConfig } from '../../theme/ThemeObservable'
import { AppColors } from '../../theme/AppColors'

/**
 * 主题切换属性接口
 */
export interface ThemeToggleProps {
  showText?: boolean // 是否显示文字标签
  size?: 'small' | 'medium' | 'large' // 按钮尺寸
  style?: 'button' | 'switch' // 切换样式
}

@ComponentV2
export struct ThemeToggle {
  @Param showText: boolean = true
  @Param toggleSize: 'small' | 'medium' | 'large' = 'medium'
  @Param style: 'button' | 'switch' = 'button'

  @Local private themeState: ThemeState = ThemeState.getInstance()

  private get currentThemeType(): ThemeType {
    return this.themeState.currentTheme.type
  }

  /**
   * 切换到浅色主题
   */
  private setLightTheme(): void {
    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: ThemeType.LIGHT,
      name: currentTheme.name,
      isDark: false
    }
    ThemeManager.setTheme(newTheme)
    this.themeState.setTheme(newTheme)
  }

  /**
   * 切换到深色主题
   */
  private setDarkTheme(): void {
    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: ThemeType.DARK,
      name: currentTheme.name,
      isDark: true
    }
    ThemeManager.setTheme(newTheme)
    this.themeState.setTheme(newTheme)
  }

  /**
   * 切换到自动主题
   */
  private setAutoTheme(): void {
    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: ThemeType.AUTO,
      name: currentTheme.name,
      isDark: false
    }
    ThemeManager.setTheme(newTheme)
    this.themeState.setTheme(newTheme)
  }

  /**
   * 构建按钮式主题切换
   */
  @Builder
  private buildButtonStyle() {
    Row({ space: 8 }) {
      // 浅色主题按钮
      Button() {
        Row({ space: 6 }) {
          Text('☀️')
            .fontSize(16)
            .fontColor(this.currentThemeType === ThemeType.LIGHT ? '#FFFFFF' : '#666666')

          if (this.showText) {
            Text('浅色')
              .fontSize(14)
              .fontColor(this.currentThemeType === ThemeType.LIGHT ? '#FFFFFF' : '#666666')
          }
        }
      }
      .height(this.toggleSize === 'small' ? 32 : this.toggleSize === 'large' ? 48 : 40)
      .padding({
        left: this.toggleSize === 'small' ? 8 : this.toggleSize === 'large' ? 20 : 12,
        right: this.toggleSize === 'small' ? 8 : this.toggleSize === 'large' ? 20 : 12,
        top: this.toggleSize === 'small' ? 4 : this.toggleSize === 'large' ? 12 : 8,
        bottom: this.toggleSize === 'small' ? 4 : this.toggleSize === 'large' ? 12 : 8
      })
      .backgroundColor(this.currentThemeType === ThemeType.LIGHT ? ThemeManager.getCurrentPrimaryColor() : Color.Transparent)
      .border({
        width: this.currentThemeType === ThemeType.LIGHT ? 0 : 1,
        color: ThemeManager.getCurrentBorderColor()
      })
      .borderRadius(20)
      .onClick(() => this.setLightTheme())

      // 深色主题按钮
      Button() {
        Row({ space: 6 }) {
          Text('🌙')
            .fontSize(16)
            .fontColor(this.currentThemeType === ThemeType.DARK ? '#FFFFFF' : '#666666')

          if (this.showText) {
            Text('深色')
              .fontSize(14)
              .fontColor(this.currentThemeType === ThemeType.DARK ? '#FFFFFF' : '#666666')
          }
        }
      }
      .height(this.toggleSize === 'small' ? 32 : this.toggleSize === 'large' ? 48 : 40)
      .padding({
        left: this.toggleSize === 'small' ? 8 : this.toggleSize === 'large' ? 20 : 12,
        right: this.toggleSize === 'small' ? 8 : this.toggleSize === 'large' ? 20 : 12,
        top: this.toggleSize === 'small' ? 4 : this.toggleSize === 'large' ? 12 : 8,
        bottom: this.toggleSize === 'small' ? 4 : this.toggleSize === 'large' ? 12 : 8
      })
      .backgroundColor(this.currentThemeType === ThemeType.DARK ? ThemeManager.getCurrentPrimaryColor() : Color.Transparent)
      .border({
        width: this.currentThemeType === ThemeType.DARK ? 0 : 1,
        color: ThemeManager.getCurrentBorderColor()
      })
      .borderRadius(20)
      .onClick(() => this.setDarkTheme())

      // 自动主题按钮
      if (this.style === 'button') {
        Button() {
          Row({ space: 6 }) {
            Text('🔄')
              .fontSize(16)
              .fontColor(this.currentThemeType === ThemeType.AUTO ? '#FFFFFF' : '#666666')

            if (this.showText) {
              Text('自动')
                .fontSize(14)
                .fontColor(this.currentThemeType === ThemeType.AUTO ? '#FFFFFF' : '#666666')
            }
          }
        }
        .height(this.toggleSize === 'small' ? 32 : this.toggleSize === 'large' ? 48 : 40)
        .padding({
          left: this.toggleSize === 'small' ? 8 : this.toggleSize === 'large' ? 20 : 12,
          right: this.toggleSize === 'small' ? 8 : this.toggleSize === 'large' ? 20 : 12,
          top: this.toggleSize === 'small' ? 4 : this.toggleSize === 'large' ? 12 : 8,
          bottom: this.toggleSize === 'small' ? 4 : this.toggleSize === 'large' ? 12 : 8
        })
        .backgroundColor(this.currentThemeType === ThemeType.AUTO ? ThemeManager.getCurrentPrimaryColor() : Color.Transparent)
        .border({
          width: this.currentThemeType === ThemeType.AUTO ? 0 : 1,
          color: ThemeManager.getCurrentBorderColor()
        })
        .borderRadius(20)
        .onClick(() => this.setAutoTheme())
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  /**
   * 构建开关式主题切换
   */
  @Builder
  private buildSwitchStyle() {
    Row({ space: 16 }) {
      // 主题标签
      Column() {
        Text('主题模式')
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentTextColor())
          .margin({ bottom: 8 })

        Text(this.currentThemeType === ThemeType.LIGHT ? '浅色' :
               this.currentThemeType === ThemeType.DARK ? '深色' : '跟随系统')
          .fontSize(12)
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 主题切换开关
      Row() {
        // 浅色主题选项
        Row({ space: 8 }) {
          Text('☀️')
            .fontSize(20)
            .fontColor(this.currentThemeType === ThemeType.LIGHT ? AppColors.primary : '#999999')

          Text('浅色')
            .fontSize(16)
            .fontColor(ThemeManager.getCurrentTextColor())
        }
        .layoutWeight(1)
        .onClick(() => this.setLightTheme())

        // 深色主题选项
        Row({ space: 8 }) {
          Text('🌙')
            .fontSize(20)
            .fontColor(this.currentThemeType === ThemeType.DARK ? AppColors.primary : '#999999')

          Text('深色')
            .fontSize(16)
            .fontColor(ThemeManager.getCurrentTextColor())
        }
        .layoutWeight(1)
        .onClick(() => this.setDarkTheme())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeManager.getCurrentSurfaceColor())
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 2
    })
  }

  build() {
    if (this.style === 'switch') {
      this.buildSwitchStyle()
    } else {
      this.buildButtonStyle()
    }
  }
}