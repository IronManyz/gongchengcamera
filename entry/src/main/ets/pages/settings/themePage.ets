/**
 * 主题设置页面
 * 提供完整的主题管理功能
 */

import router from '@ohos.router'
import { ThemeManager, ThemeType, ThemeName } from '../../theme/ThemeManager'
import { ThemeToggle } from '../../components/theme/ThemeToggle'
import { AppColors } from '../../theme/AppColors'

@Entry
@Component
struct ThemePage {
  @State private currentThemeType: ThemeType = ThemeType.LIGHT
  @State private currentThemeName: ThemeName = ThemeName.ENGINEERING

  aboutToAppear() {
    const theme = ThemeManager.getCurrentTheme()
    this.currentThemeType = theme.type
    this.currentThemeName = theme.name
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
   * 返回上一页
   */
  private goBack(): void {
    router.back()
  }

  /**
   * 设置主题类型
   */
  private setThemeType(type: ThemeType): void {
    switch (type) {
      case ThemeType.LIGHT:
        ThemeManager.setLightTheme()
        break
      case ThemeType.DARK:
        ThemeManager.setDarkTheme()
        break
      case ThemeType.AUTO:
        ThemeManager.setAutoTheme()
        break
    }
    this.currentThemeType = type
  }

  /**
   * 设置主题名称
   */
  private setThemeName(name: ThemeName): void {
    ThemeManager.setThemeName(name)
    this.currentThemeName = name
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.goBack())

        Text('主题设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
        .width(48)
      }
      .width('100%')
      .height(56)
      .padding({ horizontal: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 内容区域
      Scroll() {
        Column({ space: 24 }) {
          // 主题类型选择
          Column({ space: 16 }) {
            Text('主题模式')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)

            // 主题类型选择器
            ThemeToggle({
              size: 'large',
              showText: true,
              style: 'button'
            })
              .margin({ top: 12 })

            // 当前主题状态显示
            Row() {
              Text('当前主题')
                .fontSize(14)
                .fontColor('#666666')

              Text(this.getThemeTypeText(this.currentThemeType))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
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
          .padding({ horizontal: 16, top: 24 })

          // 主题名称选择
          Column({ space: 16 }) {
            Text('主题配色')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
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
          .padding({ horizontal: 16, bottom: 24 })

          // 主题预览
          this.buildThemePreview()
        }
        .width('100%')
        .padding({ vertical: 16 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
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
              .fontColor('#666666')
          }

          // 选中指示器
          if (isSelected) {
            Image($r('app.media.ic_check'))
              .width(16)
              .height(16)
              .fillColor(ThemeManager.getCurrentPrimaryColor())
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
      .padding({ horizontal: 16 })
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
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 预览卡片
      Column({ space: 12 }) {
        // 主色调预览
        Row() {
          Text('主色调')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(ThemeManager.getCurrentPrimaryColor())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .padding({ horizontal: 8, vertical: 4 })
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
              .fontColor('#666666')
              .width(40)

            Text(ThemeManager.getCurrentSuccessColor())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .padding({ horizontal: 8, vertical: 4 })
              .backgroundColor(ThemeManager.getCurrentSuccessColor() + '20')
              .borderRadius(4)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }

          Column({ space: 4 }) {
            Text('警告')
              .fontSize(12)
              .fontColor('#666666')
              .width(40)

            Text(ThemeManager.getCurrentWarningColor())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .padding({ horizontal: 8, vertical: 4 })
              .backgroundColor(ThemeManager.getCurrentWarningColor() + '20')
              .borderRadius(4)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }

          Column({ space: 4 }) {
            Text('错误')
              .fontSize(12)
              .fontColor('#666666')
              .width(40)

            Text(ThemeManager.getCurrentErrorColor())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .padding({ horizontal: 8, vertical: 4 })
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
            .fontColor('#666666')
            .width(80)

          Text(ThemeManager.getCurrentTextColor())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .padding({ horizontal: 8, vertical: 4 })
            .backgroundColor(ThemeManager.getCurrentBgColor())
            .borderRadius(4)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
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