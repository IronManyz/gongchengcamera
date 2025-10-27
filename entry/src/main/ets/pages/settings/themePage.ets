/**
 * 主题设置页面
 * 提供完整的主题管理功能
 */

import router from '@ohos.router'
import { ThemeManager, ThemeType, ThemeName } from '../../theme/ThemeManager'
import { ThemeState, ThemeConfig } from '../../theme/ThemeObservable'
import { ThemeToggle } from '../../components/theme/ThemeToggle'
import { AppColors, ColorPalettes } from '../../theme/AppColors'
import { BottomNavigation } from '../../components/common/BottomNavigation'
import { SVGIcon } from '../../components/icons/SVGIcon'

@Entry
@ComponentV2
struct ThemePage {
  @Local private themeState: ThemeState = ThemeState.getInstance()
  @Local private refreshTrigger: number = 0
  @Local private currentBgColor: string = '#FFFFFF'
  @Local private currentTextColor: string = '#262626'
  @Local private currentSurfaceColor: string = '#FFFFFF'

  private get currentThemeType(): ThemeType {
    // 强制依赖refreshTrigger以确保UI重新渲染
    void this.refreshTrigger
    return this.themeState.currentTheme.type
  }

  private get currentThemeName(): ThemeName {
    // 强制依赖refreshTrigger以确保UI重新渲染
    void this.refreshTrigger
    return this.themeState.currentTheme.name
  }

  aboutToAppear() {
    this.themeState = ThemeState.getInstance()
  }

  /**
   * 主题状态变化监听器
   */
  onThemeStateChanged(): void {
    console.log('=== ThemePage.onThemeStateChanged() ===')
    console.log('ThemePage: Theme state changed, triggering UI refresh')
    this.refreshTrigger++
    console.log('ThemePage: refreshTrigger updated to:', this.refreshTrigger)
  }

  /**
   * 手动测试主题系统（调试用）
   */
  private testThemeSystem(): void {
    console.log('=== MANUAL THEME SYSTEM TEST ===')

    // Test 1: Check ThemeState
    console.log('1. ThemeState Test:')
    console.log('   ThemeState.currentTheme:', JSON.stringify(this.themeState.currentTheme))
    console.log('   ThemeState.updateCount:', this.themeState.updateCount)

    // Test 2: Check ThemeManager
    console.log('2. ThemeManager Test:')
    console.log('   ThemeManager.currentTheme:', JSON.stringify(ThemeManager.getCurrentTheme()))

    // Test 3: Check color retrieval
    console.log('3. Color Retrieval Test:')
    console.log('   getCurrentBgColor():', ThemeManager.getCurrentBgColor())
    console.log('   getCurrentTextColor():', ThemeManager.getCurrentTextColor())
    console.log('   getCurrentSurfaceColor():', ThemeManager.getCurrentSurfaceColor())
    console.log('   getCurrentPrimaryColor():', ThemeManager.getCurrentPrimaryColor())

    // Test 4: Check dark palette
    console.log('4. Dark Palette Test:')
    console.log('   ColorPalettes.dark.background:', ColorPalettes.dark.background)
    console.log('   ColorPalettes.dark.text:', ColorPalettes.dark.text)

    // Test 5: Check current UI state
    console.log('5. UI State Test:')
    console.log('   this.currentThemeType:', this.currentThemeType)
    console.log('   this.currentThemeName:', this.currentThemeName)
    console.log('   this.refreshTrigger:', this.refreshTrigger)

    console.log('=== END MANUAL TEST ===')
  }

  private refreshTheme(): void {
    console.log('=== ThemePage.refreshTheme START ===')
    console.log('ThemePage: refreshTheme called, current trigger:', this.refreshTrigger)
    this.refreshTrigger++
    console.log('ThemePage: refreshTrigger incremented to:', this.refreshTrigger)

    // 获取最新的颜色并更新@State变量
    this.currentBgColor = ThemeManager.getCurrentBgColor()
    this.currentTextColor = ThemeManager.getCurrentTextColor()
    this.currentSurfaceColor = ThemeManager.getCurrentSurfaceColor()

    console.log('ThemePage: Updated @State color variables:')
    console.log('ThemePage: currentBgColor =', this.currentBgColor)
    console.log('ThemePage: currentTextColor =', this.currentTextColor)
    console.log('ThemePage: currentSurfaceColor =', this.currentSurfaceColor)

    // 测试颜色获取
    console.log('ThemePage: Testing color retrieval...')
    console.log('ThemePage: Current theme type:', this.currentThemeType)
    console.log('ThemePage: Current theme name:', this.currentThemeName)
    const currentTheme = ThemeManager.getCurrentTheme()
    console.log('ThemePage: ThemeManager isDark:', currentTheme.isDark)
    console.log('ThemePage: Background color from ThemeManager:', ThemeManager.getCurrentBgColor())
    console.log('ThemePage: Text color from ThemeManager:', ThemeManager.getCurrentTextColor())
    console.log('ThemePage: Surface color from ThemeManager:', ThemeManager.getCurrentSurfaceColor())
    console.log('ThemePage: Primary color:', ThemeManager.getCurrentPrimaryColor())

    // Test if ThemeState and ThemeManager are in sync
    console.log('ThemePage: ThemeState currentTheme:', JSON.stringify(this.themeState.currentTheme))
    console.log('ThemePage: ThemeManager currentTheme:', JSON.stringify(ThemeManager.getCurrentTheme()))

    // 强制触发重新渲染
    console.log('ThemePage: Forcing UI re-render with @State variables...')
    console.log('ThemePage: refreshTheme completed, new trigger:', this.refreshTrigger)
    console.log('=== ThemePage.refreshTheme END ===')
  }

  /**
   * 获取主题类型文本
   */
  private getThemeTypeText(type: ThemeType): string {
    switch (type) {
      case ThemeType.LIGHT:
        return '浅色'
      case ThemeType.DARK:
        return '深色'
      case ThemeType.AUTO:
        return '跟随系统'
      default:
        return '浅色'
    }
  }

  /**
   * 获取主题名称文本
   */
  private getThemeNameText(name: ThemeName): string {
    switch (name) {
      case ThemeName.ENGINEERING:
        return '工程主题'
      case ThemeName.SAFETY:
        return '安全主题'
      case ThemeName.PROFESSIONAL:
        return '专业主题'
      default:
        return '工程主题'
    }
  }

  /**
   * 返回设置页面
   */
  private goBack(): void {
    try {
      router.replaceUrl({
        url: 'pages/settings/SettingsPlaceholderPage',
        params: {}
      }).catch((error: Error) => {
        console.error('Navigation back to settings failed:', error)
      })
    } catch (error) {
      console.error('Navigation back to settings failed with exception:', error)
    }
  }

  /**
   * 设置主题类型
   */
  private setThemeType(type: ThemeType): void {
    const currentTheme = this.themeState.currentTheme
    let newTheme: ThemeConfig

    switch (type) {
      case ThemeType.LIGHT:
        newTheme = {
          type: ThemeType.LIGHT,
          name: currentTheme.name,
          isDark: false
        }
        break
      case ThemeType.DARK:
        newTheme = {
          type: ThemeType.DARK,
          name: currentTheme.name,
          isDark: true
        }
        break
      case ThemeType.AUTO:
        newTheme = {
          type: ThemeType.AUTO,
          name: currentTheme.name,
          isDark: false
        }
        break
      default:
        newTheme = currentTheme
    }

    ThemeManager.setTheme(newTheme)
    this.themeState.setTheme(newTheme)

    // Debug test after theme change
    this.testThemeSystem()

    this.refreshTheme()
  }

  /**
   * 设置主题名称
   */
  private setThemeName(name: ThemeName): void {
    const currentTheme = this.themeState.currentTheme
    const newTheme: ThemeConfig = {
      type: currentTheme.type,
      name: name,
      isDark: currentTheme.isDark
    }

    ThemeManager.setThemeName(name)
    this.themeState.setTheme(newTheme)

    // Debug test after theme change
    this.testThemeSystem()

    this.refreshTheme()
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Text('‹')
            .fontSize(24)
            .fontColor(ThemeManager.getCurrentTextColor())
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.goBack())

        Text('主题设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.getCurrentTextColor())
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
        .width(48)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(ThemeManager.getCurrentSurfaceColor())
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 内容区域
      Scroll() {
        Column({ space: 24 }) {
          // 调试信息显示区域
          Column({ space: 8 }) {
            Row() {
                SVGIcon({
                  iconName: 'search',
                  iconSize: 30,
                  iconColor: '#1890FF',
                  iconStrokeWidth: 2.5
                })
                  .margin({ right: 8 })
                Text('调试信息')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.currentTextColor)
              }
              .alignSelf(ItemAlign.Start)

            Row() {
              Text('背景色:')
                .fontSize(12)
                .fontColor(this.currentTextColor)
                .width(60)

              Text(this.currentBgColor)
                .fontSize(12)
                .fontColor(this.currentTextColor)
                .padding(4)
                .backgroundColor(this.currentBgColor)
                .borderRadius(4)
                .layoutWeight(1)
            }
            .width('100%')

            Row() {
              Text('文本色:')
                .fontSize(12)
                .fontColor(this.currentTextColor)
                .width(60)

              Text(this.currentTextColor)
                .fontSize(12)
                .fontColor(this.currentTextColor)
                .padding(4)
                .backgroundColor(this.currentBgColor)
                .borderRadius(4)
                .layoutWeight(1)
            }
            .width('100%')

            Row() {
              Text('主题类型:')
                .fontSize(12)
                .fontColor(ThemeManager.getCurrentTextSecondaryColor())
                .width(60)

              Text(this.currentThemeType + ' (触发器:' + this.refreshTrigger + ')')
                .fontSize(12)
                .fontColor(this.currentTextColor)
                .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.currentSurfaceColor)
          .borderRadius(12)
          .margin({ bottom: 16 })

          // 调试按钮（临时）
          Button() {
            Row() {
              SVGIcon({
                iconName: 'search',
                iconSize: 24,
                iconColor: '#FFFFFF',
                iconStrokeWidth: 2.5
              })
                .margin({ right: 8 })
              Text('手动测试主题系统')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
          }
          .width('100%')
          .height(40)
          .backgroundColor('#FF6B35')
          .borderRadius(8)
          .margin({ bottom: 16 })
          .onClick(() => {
            this.testThemeSystem()
          })

          // 主题类型选择
          Column({ space: 16 }) {
            Text('主题模式')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeManager.getCurrentTextColor())
              .alignSelf(ItemAlign.Start)

            // 主题类型选择器
            ThemeToggle({
              showText: true,
              toggleSize: 'large',
              style: 'button',
              onThemeChanged: () => {
                console.log('=== ThemePage: ThemeToggle callback ===')
                this.refreshTheme()
              }
            })
              .margin({ top: 12 })

            // 当前主题状态显示
            Row() {
              Text('当前主题')
                .fontSize(14)
                .fontColor(ThemeManager.getCurrentTextSecondaryColor())

              Text(this.getThemeTypeText(this.currentThemeType))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeManager.getCurrentTextColor())
                .margin({ left: 8 })

              Text(`(${this.getThemeNameText(this.currentThemeName)})`)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ left: 4 })
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
          .width('100%')
          .padding({ left: 16, right: 16, top: 24 })

          // 主题名称选择
          Column({ space: 16 }) {
            Text('主题配色')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeManager.getCurrentTextColor())
              .alignSelf(ItemAlign.Start)

            // 主题名称选择
            Column({ space: 12 }) {
              // 工程主题
              this.buildThemeOption(
                ThemeName.ENGINEERING,
                '工程主题',
                AppColors.primary,
                this.currentThemeName === ThemeName.ENGINEERING
              )

              // 安全主题
              this.buildThemeOption(
                ThemeName.SAFETY,
                '安全主题',
                '#52C41A',
                this.currentThemeName === ThemeName.SAFETY
              )

              // 专业主题
              this.buildThemeOption(
                ThemeName.PROFESSIONAL,
                '专业主题',
                '#2C3E50',
                this.currentThemeName === ThemeName.PROFESSIONAL
              )
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
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })

          // 主题预览
          this.buildThemePreview()
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .backgroundColor(this.currentBgColor)

      // 底部导航栏
      BottomNavigation({
        currentPage: 'pages/settings/SettingsPlaceholderPage'
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建主题选项
   */
  @Builder
  private buildThemeOption(name: ThemeName, title: string, color: string, isSelected: boolean) {
    Row() {
      // 颜色预览圆点
      Column({ space: 8 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(isSelected ? ThemeManager.getCurrentPrimaryColor() : '#333333')

        Row({ space: 8 }) {
          // 颜色预览
          Row({ space: 4 }) {
            Circle({ width: 16, height: 16 })
              .fill(color)
              .margin({ right: 4 })

            Text('主色调')
              .fontSize(12)
              .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          }

          // 选中指示器
          if (isSelected) {
            Text('✓')
              .fontSize(16)
              .fontColor(ThemeManager.getCurrentPrimaryColor())
          }
        }
      }
      .layoutWeight(1)

      // 选择按钮
      Button() {
        Text(isSelected ? '已选择' : '选择')
          .fontSize(14)
          .fontColor(isSelected ? '#FFFFFF' : ThemeManager.getCurrentPrimaryColor())
      }
      .height(36)
      .padding({ left: 16, right: 16 })
      .backgroundColor(isSelected ? ThemeManager.getCurrentPrimaryColor() : Color.Transparent)
      .borderRadius(18)
      .border({
        width: 1,
        color: isSelected ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
      })
      .onClick(() => this.setThemeName(name))
    }
    .width('100%')
    .padding(12)
    .backgroundColor(isSelected ? ThemeManager.getCurrentPrimaryColor() + '20' : Color.Transparent)
    .borderRadius(8)
  }

  /**
   * 构建主题预览
   */
  @Builder
  private buildThemePreview() {
    Column({ space: 16 }) {
      Text('主题预览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeManager.getCurrentTextColor())
        .alignSelf(ItemAlign.Start)

      // 预览卡片
      Column({ space: 12 }) {
        // 主色调预览
        Row() {
          Text('主色调')
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentTextSecondaryColor())
            .width(80)

          Text(ThemeManager.getCurrentPrimaryColor())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeManager.getCurrentTextColor())
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ThemeManager.getCurrentPrimaryColor() + '20')
            .borderRadius(4)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')

        // 状态色预览
        Row() {
          Column({ space: 4 }) {
            Text('成功')
              .fontSize(12)
              .fontColor(ThemeManager.getCurrentTextSecondaryColor())
              .width(40)

            Text(ThemeManager.getCurrentSuccessColor())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeManager.getCurrentTextColor())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ThemeManager.getCurrentSuccessColor() + '20')
              .borderRadius(4)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }

          Column({ space: 4 }) {
            Text('警告')
              .fontSize(12)
              .fontColor(ThemeManager.getCurrentTextSecondaryColor())
              .width(40)

            Text(ThemeManager.getCurrentWarningColor())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeManager.getCurrentTextColor())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ThemeManager.getCurrentWarningColor() + '20')
              .borderRadius(4)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }

          Column({ space: 4 }) {
            Text('错误')
              .fontSize(12)
              .fontColor(ThemeManager.getCurrentTextSecondaryColor())
              .width(40)

            Text(ThemeManager.getCurrentErrorColor())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeManager.getCurrentTextColor())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ThemeManager.getCurrentErrorColor() + '20')
              .borderRadius(4)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }
        }
        .width('100%')

        // 文本色预览
        Row() {
          Text('主要文本')
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentTextSecondaryColor())
            .width(80)

          Text(ThemeManager.getCurrentTextColor())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeManager.getCurrentTextColor())
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ThemeManager.getCurrentBgColor())
            .borderRadius(4)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(ThemeManager.getCurrentSurfaceColor())
      .borderRadius(12)
      .shadow({
        radius: 4,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 2
      })
    }
  }
}