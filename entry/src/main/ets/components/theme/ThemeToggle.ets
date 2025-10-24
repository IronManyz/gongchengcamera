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
  onThemeChanged?: () => void // 主题变化回调
}

@ComponentV2
export struct ThemeToggle {
  @Param showText: boolean = true
  @Param toggleSize: 'small' | 'medium' | 'large' = 'medium'
  @Param style: 'button' | 'switch' = 'button'
  @Param onThemeChanged: (() => void) | undefined = undefined

  @Local private themeState: ThemeState = ThemeState.getInstance()
  @Local private refreshTrigger: number = 0

  private get currentThemeType(): ThemeType {
    // 强制依赖refreshTrigger以确保UI重新渲染
    void this.refreshTrigger
    return this.themeState.currentTheme.type
  }

  aboutToAppear() {
    this.themeState = ThemeState.getInstance()
  }

  private refreshTheme(): void {
    console.log('=== ThemeToggle.refreshTheme() START ===')
    console.log('ThemeToggle: refreshTheme called, current trigger:', this.refreshTrigger)
    this.refreshTrigger++
    console.log('ThemeToggle: refreshTheme completed, new trigger:', this.refreshTrigger)
    console.log('ThemeToggle: After refresh - currentThemeType:', this.currentThemeType)
    console.log('=== ThemeToggle.refreshTheme() END ===')
  }

  /**
   * 切换到浅色主题
   */
  private setLightTheme(): void {
    console.log('ThemeToggle: setLightTheme called')
    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: ThemeType.LIGHT,
      name: currentTheme.name,
      isDark: false
    }
    console.log('ThemeToggle: Setting theme to', newTheme)
    ThemeManager.setTheme(newTheme)
    this.themeState.setTheme(newTheme)
    this.refreshTheme()

    // 调用父组件的回调
    if (this.onThemeChanged) {
      console.log('ThemeToggle: Calling onThemeChanged callback')
      this.onThemeChanged()
    }

    console.log('ThemeToggle: Light theme set completed')
  }

  /**
   * 切换到深色主题
   */
  private setDarkTheme(): void {
    console.log('=== ThemeToggle.setDarkTheme START ===')
    console.log('ThemeToggle: setDarkTheme called')
    console.log('ThemeToggle: Before - ThemeState currentTheme:', JSON.stringify(this.themeState.currentTheme))
    console.log('ThemeToggle: Before - ThemeManager currentTheme:', JSON.stringify(ThemeManager.getCurrentTheme()))

    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: ThemeType.DARK,
      name: currentTheme.name,
      isDark: true
    }

    console.log('ThemeToggle: New theme config:', JSON.stringify(newTheme))
    console.log('ThemeToggle: Calling ThemeManager.setTheme...')

    ThemeManager.setTheme(newTheme)

    console.log('ThemeToggle: After ThemeManager.setTheme - ThemeManager currentTheme:', JSON.stringify(ThemeManager.getCurrentTheme()))
    console.log('ThemeToggle: Calling ThemeState.setTheme...')

    this.themeState.setTheme(newTheme)

    console.log('ThemeToggle: After ThemeState.setTheme - ThemeState currentTheme:', JSON.stringify(this.themeState.currentTheme))
    console.log('ThemeToggle: After ThemeState.setTheme - ThemeManager currentTheme:', JSON.stringify(ThemeManager.getCurrentTheme()))

    // Test color retrieval immediately
    console.log('ThemeToggle: Testing color retrieval...')
    console.log('ThemeToggle: getCurrentBgColor() should return #121212, got:', ThemeManager.getCurrentBgColor())
    console.log('ThemeToggle: getCurrentTextColor() should return #FFFFFF, got:', ThemeManager.getCurrentTextColor())
    console.log('ThemeToggle: getCurrentSurfaceColor() should return #1E1E1E, got:', ThemeManager.getCurrentSurfaceColor())

    this.refreshTheme()

    // 调用父组件的回调
    if (this.onThemeChanged) {
      console.log('ThemeToggle: Calling onThemeChanged callback')
      this.onThemeChanged()
    }

    console.log('ThemeToggle: Dark theme set completed')
    console.log('ThemeToggle: Final check - currentThemeType:', this.currentThemeType)
    console.log('ThemeToggle: Final check - refreshTrigger:', this.refreshTrigger)
    console.log('=== ThemeToggle.setDarkTheme END ===')
  }

  /**
   * 切换到自动主题
   */
  private setAutoTheme(): void {
    console.log('ThemeToggle: setAutoTheme called')
    console.log('ThemeToggle: Before - ThemeState currentTheme:', this.themeState.currentTheme)
    console.log('ThemeToggle: Before - ThemeManager currentTheme:', ThemeManager.getCurrentTheme())

    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: ThemeType.AUTO,
      name: currentTheme.name,
      isDark: false
    }

    console.log('ThemeToggle: New theme config:', newTheme)
    console.log('ThemeToggle: Calling ThemeManager.setTheme...')

    ThemeManager.setTheme(newTheme)

    console.log('ThemeToggle: After ThemeManager.setTheme - ThemeManager currentTheme:', ThemeManager.getCurrentTheme())
    console.log('ThemeToggle: Calling ThemeState.setTheme...')

    this.themeState.setTheme(newTheme)

    console.log('ThemeToggle: After ThemeState.setTheme - ThemeState currentTheme:', this.themeState.currentTheme)
    console.log('ThemeToggle: After ThemeState.setTheme - ThemeManager currentTheme:', ThemeManager.getCurrentTheme())

    this.refreshTheme()

    // 调用父组件的回调
    if (this.onThemeChanged) {
      console.log('ThemeToggle: Calling onThemeChanged callback')
      this.onThemeChanged()
    }

    console.log('ThemeToggle: Auto theme set completed')
    console.log('ThemeToggle: Final check - currentThemeType:', this.currentThemeType)
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