/**
 * 主题切换组件
 * 提供浅色/深色主题切换功能
 */

import { ThemeManager, ThemeType, ThemeName } from '../../theme/ThemeManager'
import { AppColors } from '../../theme/AppColors'

/**
 * 主题切换属性接口
 */
export interface ThemeToggleProps {
  showText?: boolean // 是否显示文字标签
  size?: 'small' | 'medium' | 'large' // 按钮尺寸
  style?: 'button' | 'switch' // 切换样式
}

@Component
export struct ThemeToggle {
  private props: ThemeToggleProps = {
    showText: true,
    size: 'medium',
    style: 'button'
  }

  @State private currentThemeType: ThemeType = ThemeType.LIGHT

  aboutToAppear() {
    this.currentThemeType = ThemeManager.getCurrentTheme().type
  }

  /**
   * 切换到浅色主题
   */
  private setLightTheme(): void {
    ThemeManager.setLightTheme()
    this.currentThemeType = ThemeType.LIGHT
  }

  /**
   * 切换到深色主题
   */
  private setDarkTheme(): void {
    ThemeManager.setDarkTheme()
    this.currentThemeType = ThemeType.DARK
  }

  /**
   * 切换到自动主题
   */
  private setAutoTheme(): void {
    ThemeManager.setAutoTheme()
    this.currentThemeType = ThemeType.AUTO
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
          Image($r('app.media.ic_sun'))
            .width(16)
            .height(16)
            .fillColor(this.currentThemeType === ThemeType.LIGHT ? '#FFFFFF' : '#666666')

          if (this.props.showText) {
            Text('浅色')
              .fontSize(14)
              .fontColor(this.currentThemeType === ThemeType.LIGHT ? '#FFFFFF' : '#666666')
          }
        }
      }
      .height(this.props.size === 'small' ? 32 : this.props.size === 'large' ? 48 : 40)
      .padding({
        horizontal: this.props.size === 'small' ? 8 : this.props.size === 'large' ? 20 : 12,
        vertical: this.props.size === 'small' ? 4 : this.props.size === 'large' ? 12 : 8
      })
      .backgroundColor(this.currentThemeType === ThemeType.LIGHT ? AppColors.primary : Color.Transparent)
      .border({
        width: this.currentThemeType === ThemeType.LIGHT ? 0 : 1,
        color: '#E0E0E0'
      })
      .borderRadius(20)
      .onClick(() => this.setLightTheme())

      // 深色主题按钮
      Button() {
        Row({ space: 6 }) {
          Image($r('app.media.ic_moon'))
            .width(16)
            .height(16)
            .fillColor(this.currentThemeType === ThemeType.DARK ? '#FFFFFF' : '#666666')

          if (this.props.showText) {
            Text('深色')
              .fontSize(14)
              .fontColor(this.currentThemeType === ThemeType.DARK ? '#FFFFFF' : '#666666')
          }
        }
      }
      .height(this.props.size === 'small' ? 32 : this.props.size === 'large' ? 48 : 40)
      .padding({
        horizontal: this.props.size === 'small' ? 8 : this.props.size === 'large' ? 20 : 12,
        vertical: this.props.size === 'small' ? 4 : this.props.size === 'large' ? 12 : 8
      })
      .backgroundColor(this.currentThemeType === ThemeType.DARK ? AppColors.primary : Color.Transparent)
      .border({
        width: this.currentThemeType === ThemeType.DARK ? 0 : 1,
        color: '#E0E0E0'
      })
      .borderRadius(20)
      .onClick(() => this.setDarkTheme())

      // 自动主题按钮
      if (this.props.style === 'button') {
        Button() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_auto'))
              .width(16)
              .height(16)
              .fillColor(this.currentThemeType === ThemeType.AUTO ? '#FFFFFF' : '#666666')

            if (this.props.showText) {
              Text('自动')
                .fontSize(14)
                .fontColor(this.currentThemeType === ThemeType.AUTO ? '#FFFFFF' : '#666666')
            }
          }
        }
        .height(this.props.size === 'small' ? 32 : this.props.size === 'large' ? 48 : 40)
        .padding({
          horizontal: this.props.size === 'small' ? 8 : this.props.size === 'large' ? 20 : 12,
          vertical: this.props.size === 'small' ? 4 : this.props.size === 'large' ? 12 : 8
        })
        .backgroundColor(this.currentThemeType === ThemeType.AUTO ? AppColors.primary : Color.Transparent)
        .border({
          width: this.currentThemeType === ThemeType.AUTO ? 0 : 1,
          color: '#E0E0E0'
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
          Image($r('app.media.ic_sun'))
            .width(20)
            .height(20)
            .fillColor(this.currentThemeType === ThemeType.LIGHT ? AppColors.primary : '#999999')

          Text('浅色')
            .fontSize(16)
            .fontColor(ThemeManager.getCurrentTextColor())
        }
        .layoutWeight(1)
        .onClick(() => this.setLightTheme())

        // 深色主题选项
        Row({ space: 8 }) {
          Image($r('app.media.ic_moon'))
            .width(20)
            .height(20)
            .fillColor(this.currentThemeType === ThemeType.DARK ? AppColors.primary : '#999999')

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
    if (this.props.style === 'switch') {
      this.buildSwitchStyle()
    } else {
      this.buildButtonStyle()
    }
  }
}