/**
 * 设置页面
 * 提供应用的各种设置选项，包括主题、存储、关于等功能
 */

import { BottomNavigation } from '../../components/common/BottomNavigation'
import { SVGIcon } from '../../components/icons/SVGIcon'
import router from '@ohos.router'
import { ThemeManager } from '../../theme/ThemeManager'

interface SettingItem {
  title: string
  subtitle?: string
  icon: string
  iconName?: string // 新增：SVG图标名称
  onPress: () => void
}

@Entry
@Component
struct SettingsPage {
  @State private isDarkMode: boolean = false
  @State private storageUsed: string = '125.6 MB'
  @State private photoCount: number = 156
  @State private version: string = '1.0.0'

  // 主题相关状态
  @State private themeRefreshTrigger: number = 0
  @State private currentBgColor: string = '#FFFFFF'
  @State private currentTextColor: string = '#262626'
  @State private currentSurfaceColor: string = '#FFFFFF'
  @State private currentPrimaryColor: string = '#1890FF'

  private settingsList: SettingItem[] = [
    {
      title: '主题设置',
      subtitle: '切换浅色/深色主题',
      icon: '🎨',
      iconName: 'palette',
      onPress: () => {
        this.navigateToTheme()
      }
    },
    {
      title: '存储管理',
      subtitle: `已使用 ${this.storageUsed}`,
      icon: '📱',
      iconName: 'photo',
      onPress: () => {
        console.log('Storage management clicked')
      }
    },
    {
      title: '相机设置',
      subtitle: '照片质量、水印配置',
      icon: '📸',
      iconName: 'camera',
      onPress: () => {
        console.log('Camera settings clicked')
      }
    },
    {
      title: '关于应用',
      subtitle: `版本 ${this.version}`,
      icon: 'ℹ️',
      iconName: 'info-circle',
      onPress: () => {
        this.navigateToAbout()
      }
    }
  ]

  /**
   * 刷新主题颜色
   */
  private refreshThemeColors(): void {
    console.log('SettingsPage: Refreshing theme colors...')
    this.currentBgColor = ThemeManager.getCurrentBgColor()
    this.currentTextColor = ThemeManager.getCurrentTextColor()
    this.currentSurfaceColor = ThemeManager.getCurrentSurfaceColor()
    this.currentPrimaryColor = ThemeManager.getCurrentPrimaryColor()
    this.themeRefreshTrigger++
    console.log('SettingsPage: Theme colors updated - Bg:', this.currentBgColor, 'Text:', this.currentTextColor)
  }

  aboutToAppear(): void {
    console.log('SettingsPage aboutToAppear')
    this.refreshThemeColors()
  }

  onPageShow(): void {
    console.log('SettingsPage onPageShow - checking theme updates')
    this.refreshThemeColors()
  }

  private navigateToTheme(): void {
    try {
      router.replaceUrl({
        url: 'pages/settings/themePage',
        params: {}
      }).catch((error: Error) => {
        console.error('Navigate to theme page failed:', error)
      })
    } catch (error) {
      console.error('Navigation to theme page failed with exception:', error)
    }
  }

  private navigateToAbout(): void {
    try {
      router.replaceUrl({
        url: 'pages/about/AboutPage',
        params: {}
      }).catch((error: Error) => {
        console.error('Navigate to about page failed:', error)
      })
    } catch (error) {
      console.error('Navigation to about page failed with exception:', error)
    }
  }

  build() {
    Column() {
      // 强制依赖主题触发器以确保重新渲染
      if (this.themeRefreshTrigger >= 0) {
        // 头部
        Row() {
          Text('设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTextColor)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(this.currentSurfaceColor)
      } else {
        // 头部
        Row() {
          Text('设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTextColor)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(this.currentSurfaceColor)
      }

      // 设置项列表
      Scroll() {
        Column({ space: 1 }) {
          // 用户信息区域
          Column() {
            Row() {
              SVGIcon({ iconName: 'user', iconSize: 24, iconColor: '#1890FF', iconStrokeWidth: 2 })
                .margin({ right: 12 })

              Column() {
                Text('工程师')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#262626')
                Text('管理员')
                  .fontSize(14)
                  .fontColor('#8C8C8C')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('>')
                .fontSize(16)
                .fontColor('#C0C0C0')
            }
            .width('100%')
            .padding(16)
            .alignItems(VerticalAlign.Center)
          }
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            console.log('User profile clicked')
          })

          // 统计信息区域
          Column() {
            Row() {
                SVGIcon({ iconName: 'database', iconSize: 20, iconColor: '#1890FF', iconStrokeWidth: 2 })
                  .margin({ right: 8 })
                Text('使用统计')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#262626')
              }
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 12 })

            Row() {
              Column() {
                Text(this.photoCount.toString())
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1890FF')
                Text('照片')
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
              .layoutWeight(1)

              Column() {
                Text('12')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#52C41A')
                Text('工程')
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
              .layoutWeight(1)

              Column() {
                Text('28')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FAAD14')
                Text('工点')
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
              .layoutWeight(1)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')

          // 设置选项
          ForEach(this.settingsList, (item: SettingItem) => {
            Column() {
              Row() {
                // 使用SVG图标或fallback到emoji
                if (item.iconName) {
                  SVGIcon({ iconName: item.iconName, iconSize: 24, iconColor: '#1890FF', iconStrokeWidth: 2 })
                    .margin({ right: 12 })
                } else {
                  Text(item.icon)
                    .fontSize(24)
                    .margin({ right: 12 })
                }

                Column() {
                  Text(item.title)
                    .fontSize(16)
                    .fontColor('#262626')
                  if (item.subtitle) {
                    Text(item.subtitle)
                      .fontSize(14)
                      .fontColor('#8C8C8C')
                      .margin({ top: 2 })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('>')
                  .fontSize(16)
                  .fontColor('#C0C0C0')
              }
              .width('100%')
              .padding(16)
              .alignItems(VerticalAlign.Center)
            }
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              item.onPress()
            })
          })

          // 版本信息
          Column() {
            Text(`Engineering Camera v${this.version}`)
              .fontSize(14)
              .fontColor('#8C8C8C')
              .textAlign(TextAlign.Center)
            Text('© 2024 工程拍记团队')
              .fontSize(12)
              .fontColor('#C0C0C0')
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .margin({ top: 20 })
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 底部导航栏
      BottomNavigation({
        currentPage: 'pages/settings/SettingsPlaceholderPage'
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
