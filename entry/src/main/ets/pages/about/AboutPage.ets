/**
 * 关于应用页面
 * 显示应用信息、版本、开发者等内容
 */

import { BottomNavigation } from '../../components/common/BottomNavigation'
import router from '@ohos.router'

interface AppInfo {
  name: string
  description: string
  company: string
  website: string
  email: string
  github: string
}

@Entry
@Component
struct AboutPage {
  @State private appVersion: string = '1.0.0'
  @State private buildNumber: string = '2024.01.01'
  @State private appInfo: AppInfo = {
    name: '工程拍记',
    description: '专业的工程拍照记录管理应用',
    company: '工程拍记团队',
    website: 'https://engineering-camera.example.com',
    email: 'support@engineering-camera.example.com',
    github: 'https://github.com/engineering-camera'
  }

  private navigateBack(): void {
    try {
      router.replaceUrl({
        url: 'pages/settings/SettingsPlaceholderPage',
        params: {}
      }).catch((error: Error) => {
        console.error('Navigation back failed:', error)
      })
    } catch (error) {
      console.error('Navigation back exception:', error)
    }
  }

  build() {
    Column() {
      // 头部导航
      Row() {
        Row() {
          Text('‹')
            .fontSize(24)
            .fontColor('#1890FF')
            .onClick(() => {
              this.navigateBack()
            })
          Text('关于应用')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262626')
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 内容区域
      Scroll() {
        Column({ space: 20 }) {
          // 应用图标和名称
          Column() {
            // 应用图标占位符
            Text('📷')
              .fontSize(80)
              .fontColor('#1890FF')
              .margin({ bottom: 16 })

            Text(this.appInfo.name)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#262626')
              .margin({ bottom: 8 })

            Text(this.appInfo.description)
              .fontSize(16)
              .fontColor('#8C8C8C')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(40)
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Center)

          // 版本信息
          Column() {
            Text('版本信息')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            Row() {
              Text('版本号')
                .fontSize(14)
                .fontColor('#8C8C8C')
                .width(80)

              Text(this.appVersion)
                .fontSize(14)
                .fontColor('#262626')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 1 }, color: '#F0F0F0' })

            Row() {
              Text('构建日期')
                .fontSize(14)
                .fontColor('#8C8C8C')
                .width(80)

              Text(this.buildNumber)
                .fontSize(14)
                .fontColor('#262626')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Start)

          // 开发团队
          Column() {
            Text('开发团队')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            Text(this.appInfo.company)
              .fontSize(16)
              .fontColor('#262626')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 20 })

            Text('专业的工程管理应用开发团队')
              .fontSize(14)
              .fontColor('#8C8C8C')
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Center)

          // 联系方式
          Column() {
            Text('联系我们')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 16 })

            Column({ space: 1 }) {
              Row() {
                Text('📧 邮箱')
                  .fontSize(14)
                  .fontColor('#8C8C8C')
                  .margin({ right: 12 })

                Text(this.appInfo.email)
                  .fontSize(14)
                  .fontColor('#1890FF')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
                  .onClick(() => {
                    console.log('Copy email to clipboard')
                  })
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')

              Row() {
                Text('🌐 网站')
                  .fontSize(14)
                  .fontColor('#8C8C8C')
                  .margin({ right: 12 })

                Text(this.appInfo.website)
                  .fontSize(14)
                  .fontColor('#1890FF')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
                  .onClick(() => {
                    console.log('Open website')
                  })
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')

              Row() {
                Text('💻 GitHub')
                  .fontSize(14)
                  .fontColor('#8C8C8C')
                  .margin({ right: 12 })

                Text(this.appInfo.github)
                  .fontSize(14)
                  .fontColor('#1890FF')
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
                  .onClick(() => {
                    console.log('Open GitHub')
                  })
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
            }
            .borderRadius(8)
            .border({ width: 1, color: '#E8E8E8' })
          }
          .width('100%')
          .padding(20)

          // 版权信息
          Column() {
            Text('© 2024 工程拍记团队')
              .fontSize(14)
              .fontColor('#8C8C8C')
              .textAlign(TextAlign.Center)
            Text('All rights reserved')
              .fontSize(12)
              .fontColor('#C0C0C0')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .alignItems(HorizontalAlign.Center)
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