/**
 * 设置页面
 * 提供应用的各种设置选项，包括主题、存储、关于等功能
 */

import router from '@ohos.router'
import { BottomNavigation } from '../../components/common/BottomNavigation'

interface SettingItem {
  title: string
  subtitle?: string
  icon: string
  onPress: () => void
}

@Entry
@Component
struct SettingsPage {
  @State private isDarkMode: boolean = false
  @State private storageUsed: string = '125.6 MB'
  @State private photoCount: number = 156
  @State private version: string = '1.0.0'

  private settingsList: SettingItem[] = [
    {
      title: '主题设置',
      subtitle: '切换浅色/深色主题',
      icon: '🎨',
      onPress: () => {
        console.log('Theme settings clicked')
      }
    },
    {
      title: '存储管理',
      subtitle: `已使用 ${this.storageUsed}`,
      icon: '📱',
      onPress: () => {
        console.log('Storage management clicked')
      }
    },
    {
      title: '相机设置',
      subtitle: '照片质量、水印配置',
      icon: '📸',
      onPress: () => {
        console.log('Camera settings clicked')
      }
    },
    {
      title: '关于应用',
      subtitle: `版本 ${this.version}`,
      icon: 'ℹ️',
      onPress: () => {
        console.log('About clicked')
      }
    }
  ]

  build() {
    Column() {
      // 头部
      Row() {
        Button('← 返回')
          .fontSize(16)
          .fontColor('#1890FF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.replaceUrl({
              url: 'pages/MainPage',
              params: {}
            })
          })

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 设置项列表
      Scroll() {
        Column({ space: 1 }) {
          // 用户信息区域
          Column() {
            Row() {
              Column() {
                Text('👤 工���师')
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
            Text('📊 使用统计')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
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
                Text(item.icon)
                  .fontSize(20)
                  .margin({ right: 12 })

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
            Text('© 2024 工程相机团队')
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
      BottomNavigation({})
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}