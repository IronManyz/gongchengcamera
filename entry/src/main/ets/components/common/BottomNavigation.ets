/**
 * 底部导航栏组件
 * 提供统一的底部导航功能
 */

import router from '@ohos.router'

export interface NavigationItem {
  icon: string
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
      label: '工程',
      route: 'pages/MainPage'
    },
    {
      icon: '📱',
      label: '相册',
      route: 'pages/gallery/GalleryPlaceholderPage'
    },
    {
      icon: '⚙️',
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
          Text(item.icon)
            .fontSize(24)
            .fontColor(this.getPageIconColor(item.route))
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
}