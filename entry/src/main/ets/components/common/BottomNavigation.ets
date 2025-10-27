/**
 * 底部导航栏组件
 * 提供统一的底部导航功能
 * 使用专业 SVG 图标替换 emoji
 */

import router from '@ohos.router'
import { EngineeringIcon } from '../icons/EngineeringIcon'

export interface NavigationItem {
  icon: string
  iconName?: string  // 新增：图标名称字段
  label: string
  route: string
  params?: ESObject
}

@ComponentV2
export struct BottomNavigation {
  @Param currentPage: string = ''
  @Param onNavigationChange?: (page: string) => void = () => {}

  private navigationItems: NavigationItem[] = [
    {
      icon: '🏗️',
      iconName: 'building',
      label: '工程',
      route: 'pages/MainPage'
    },
    {
      icon: '📱',
      iconName: 'photo',
      label: '相册',
      route: 'pages/gallery/GalleryPlaceholderPage'
    },
    {
      icon: '⚙️',
      iconName: 'settings',
      label: '设置',
      route: 'pages/settings/SettingsPlaceholderPage'
    }
  ]

  private handleNavigation(item: NavigationItem): void {
    console.log('Navigate to:', item.route)

    // ���果点击的是当前页面，不做任何操作
    if (item.route === this.currentPage) {
      return
    }

    // 通知父组件导航变化
    this.onNavigationChange?.(item.route)

    // 执行页面跳转
    try {
      router.replaceUrl({
        url: item.route,
        params: item.params || {} as ESObject
      }).catch((error: Error) => {
        console.error('Navigation failed:', error)
      })
    } catch (error) {
      console.error('Navigation exception:', error)
    }
  }

  build() {
    Row() {
      ForEach(this.navigationItems, (item: NavigationItem) => {
        Column() {
          // 使用专业图标组件替换 emoji
          if (item.iconName) {
            this.renderIcon(item.iconName, item.route)
          } else {
            // 兼容旧的 emoji 图标
            Text(item.icon)
              .fontSize(24)
              .fontColor(this.getPageIconColor(item.route))
          }
          Text(item.label)
            .fontSize(12)
            .fontColor(this.getPageIconColor(item.route))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.getPageBackgroundColor(item.route))
        .borderRadius(8)
        .padding({ top: 4, bottom: 4 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .onClick(() => {
          this.handleNavigation(item)
        })
      })
    }
    .width('100%')
    .height(60)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#E8E8E8' })
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ bottom: 8 }) // 为安全区域留出空间
  }

  private getPageIconColor(route: string): string {
    return this.currentPage === route ? '#1890FF' : '#8C8C8C'
  }

  private getPageBackgroundColor(route: string): string {
    return this.currentPage === route ? '#E6F7FF' : ''
  }

  /**
   * 渲染图标组件
   * 根据路由状态决定图标颜色
   */
  @Builder
  private renderIcon(iconName: string, route: string) {
    let iconColor = this.getPageIconColor(route)

    switch (iconName) {
      case 'building':
        EngineeringIcon({ name: 'building', size: 24, color: iconColor, strokeWidth: 2 })
        break
      case 'photo':
        EngineeringIcon({ name: 'photo', size: 24, color: iconColor, strokeWidth: 2 })
        break
      case 'settings':
        EngineeringIcon({ name: 'settings', size: 24, color: iconColor, strokeWidth: 2 })
        break
      default:
        // 默认使用 info-circle 图标
        EngineeringIcon({ name: 'info-circle', size: 24, color: iconColor, strokeWidth: 2 })
        break
    }
  }
}