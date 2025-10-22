/**
 * 空状态设计组件库
 * 提供专业的空状态显示，提升用户体验
 */

import { ThemeManager } from '../../theme/ThemeManager'

export type EmptyStateType =
  | 'no-data'        // 无数据
  | 'no-results'     // 无搜索结果
  | 'no-network'      // 无网络连接
  | 'error'           // 错误状态
  | 'loading'         // 加载中
  | 'empty-list'      // 空列表
  | 'empty-favorites'  // 无收藏
  | 'no-permission'   // 无权限
  | 'not-found'       // 页面未找到
  | 'maintenance'     // 维护中
  | 'first-use'       // 首次使用
  | 'custom'          // 自定义状态

export type EmptyStateSize =
  | 'small' | 'medium' | 'large' | 'full'

export type ActionButtonType =
  | 'primary' | 'secondary' | 'outline' | 'text' | 'icon'

/**
 * 基础空状态组件
 * 提供统一的空状态显示框架
 */
@ComponentV2
export struct BaseEmptyState {
  @Param type: EmptyStateType = 'no-data'
  @Param title: string = ''
  @Param description: string = ''
  @Param icon: string = ''
  @Param image: string = ''
  @Param size: EmptyStateSize = 'medium'
  @Param showButton: boolean = false
  @Param buttonText: string = '重试'
  @Param buttonType: ActionButtonType = 'primary'
  @Param onButtonPress?: () => void = () => {}
  @Param customContent?: () => void = () => {}

  build() {
    Column() {
      // 主要内容区域
      Column() {
        // 图标区域
        if (this.getIconConfig().type === 'emoji') {
          Text(this.getIconConfig().content)
            .fontSize(this.getIconSize())
            .margin({ bottom: 24 })
        } else if (this.getIconConfig().type === 'image') {
          Image(this.getIconConfig().content)
            .width(this.getIconSize() * 2)
            .height(this.getIconSize() * 2)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 24 })
        } else if (this.customContent) {
          this.customContent()
        }

        // 标题
        if (this.title) {
          Text(this.title)
            .fontSize(this.getTitleSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeManager.getCurrentTextColor())
            .margin({ bottom: 12 })
            .textAlign(TextAlign.Center)
        }

        // 描述
        if (this.description) {
          Text(this.description)
            .fontSize(this.getDescriptionSize())
            .fontColor(ThemeManager.getCurrentTextSecondaryColor())
            .textAlign(TextAlign.Center)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(24)
        }

        // 操作按钮
        if (this.showButton) {
          this.buildActionButton()
        }
      }
      .width(this.getContentWidth())
      .padding(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ThemeManager.getCurrentBackgroundColor())
  }

  /**
   * 构建操作按钮
   */
  @Builder
  private buildActionButton() {
    Button(this.buttonText)
      .fontSize(16)
      .fontColor(this.getButtonTextColor())
      .fontWeight(FontWeight.Medium)
      .padding({ left: 24, right: 24, top: 12, bottom: 12 })
      .borderRadius(this.getButtonBorderRadius())
      .backgroundColor(this.getButtonBackgroundColor())
      .border({
        width: this.getButtonType() === 'outline' ? 1 : 0,
        color: this.getButtonTextColor()
      })
      .onClick(() => {
        this.onButtonPress?.()
      })
  }

  /**
   * 获取图标配置
   */
  private getIconConfig(): { type: 'emoji' | 'image' | 'svg', content: string } {
    if (this.icon) {
      return { type: 'emoji', content: this.icon }
    } else if (this.image) {
      return { type: 'image', content: this.image }
    } else {
      const defaultIcons: Record<EmptyStateType, string> = {
        'no-data': '📦',
        'no-results': '🔍',
        'no-network': '📶',
        'error': '❌',
        'loading': '⏳',
        'empty-list': '📋',
        'empty-favorites': '⭐',
        'no-permission': '🔒',
        'not-found': '🔍',
        'maintenance': '🔧',
        'first-use': '👋'
      }
      return { type: 'emoji', content: defaultIcons[this.type] || '📦' }
    }
  }

  /**
   * 获取图标尺寸
   */
  private getIconSize(): number {
    const sizes = {
      'small': 48,
      'medium': 64,
      'large': 80,
      'full': 96
    }
    return sizes[this.size] || sizes['medium']
  }

  /**
   * 获取标题字体大小
   */
  private getTitleSize(): number {
    const sizes = {
      'small': 18,
      'medium': 20,
      'large': 24,
      'full': 28
    }
    return sizes[this.size] || sizes['medium']
  }

  /**
   * 获取描述字体大小
   */
  private getDescriptionSize(): number {
    const sizes = {
      'small': 14,
      'medium': 16,
      'large': 18,
      'full': 20
    }
    return sizes[this.size] || sizes['medium']
  }

  /**
   * 获取内容宽度
   */
  private getContentWidth(): string {
    const widths = {
      'small': '280',
      'medium': '320',
      'large': '400',
      'full': '80%'
    }
    return widths[this.size] || widths['medium']
  }

  /**
   * 获取按钮背景颜色
   */
  private getButtonBackgroundColor(): string {
    switch (this.buttonType) {
      case 'primary':
        return ThemeManager.getCurrentPrimaryColor()
      case 'secondary':
        return ThemeManager.getCurrentSecondaryColor()
      case 'outline':
        return ThemeManager.getCurrentBackgroundColor()
      case 'text':
        return Color.Transparent
      case 'icon':
        return Color.Transparent
      default:
        return ThemeManager.getCurrentPrimaryColor()
    }
  }

  /**
   * 获取按钮文字颜色
   */
  private getButtonTextColor(): string {
    switch (this.buttonType) {
      case 'primary':
      case 'secondary':
        return '#FFFFFF'
      case 'outline':
        return ThemeManager.getCurrentPrimaryColor()
      case 'text':
        return ThemeManager.getCurrentPrimaryColor()
      case 'icon':
        return ThemeManager.getCurrentPrimaryColor()
      default:
        return '#FFFFFF'
    }
  }

  /**
   * 获取按钮圆角
   */
  private getButtonBorderRadius(): number {
    return this.buttonType === 'icon' ? 50 : 8
  }

  /**
   * 获取按钮类型
   */
  private getButtonType(): string {
    return this.buttonType || 'primary'
  }
}

/**
 * 列表空状态组件
 * 专门用于列表的空状态显示
 */
@ComponentV2
export struct EmptyListState {
  @Param itemCount: number = 0
  @Param itemType: string = '项目'
  @Param actionText: string = '创建新项目'
  @Param showSearch: boolean = false
  @Param searchPlaceholder: string = '搜索项目...'
  @Param onCreateNew?: () => void = () => {}
  @Param onSearch?: (query: string) => void = () => {}

  @State private searchQuery: string = ''

  build() {
    if (this.itemCount === 0) {
      Column() {
        // 搜索区域（可选）
        if (this.showSearch) {
          Row() {
            TextInput({ placeholder: this.searchPlaceholder })
              .width('100%')
              .height(40)
              .backgroundColor(ThemeManager.getCurrentSurfaceColor())
              .borderRadius(8)
              .border({ width: 1, color: ThemeManager.getCurrentBorderColor() })
              .onChange((value: string) => {
                this.searchQuery = value
                this.onSearch?.(value)
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(ThemeManager.getCurrentBackgroundColor())
        }

        // 空状态图标
        Text('📂')
          .fontSize(80)
          .margin({ bottom: 24 })

        // 空状态文本
        Text(`暂无${this.itemType}`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          .margin({ bottom: 16 })

        // 操作按钮
        Button(this.actionText)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(ThemeManager.getCurrentPrimaryColor())
          .borderRadius(8)
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => {
            this.onCreateNew?.()
          })
      }
      .width('100%')
      .padding(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(ThemeManager.getCurrentBackgroundColor())
      .height('100%')
    }
  }
}

/**
 * 搜索空状态组件
 * 专门用于搜索结果的空状态
 */
@ComponentV2
export struct EmptySearchState {
  @Param query: string = ''
  @Param hasQuery: boolean = false
  @Param suggestions: string[] = []
  @Param showHistory: boolean = true
  @Param searchHistory: string[] = []
  @Param onSearch?: (query: string) => void = () => {}
  @Param onSuggestionSelect?: (suggestion: string) => void = () => {}
  @Param onClearHistory?: () => void = () => {}

  @State private selectedSuggestion: string = ''
  @State private showSuggestions: boolean = false

  build() {
    Column() {
      // 搜索图标
      Text('🔍')
        .fontSize(64)
        .margin({ bottom: 24 })

      // 搜索状态文本
      if (this.hasQuery) {
        Text(`未找到与 "${this.query}" 相关的结果`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          .margin({ bottom: 16 })
          .textAlign(TextAlign.Center)
      } else {
        Text('请输入搜索关键词')
          .fontSize(16)
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          .margin({ bottom: 24 })
          .textAlign(TextAlign.Center)
      }

      // 搜索建议（可选）
      if (this.suggestions.length > 0) {
        Column() {
          Text('搜索建议')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeManager.getCurrentTextColor())
            .margin({ bottom: 12 })
            .alignSelf(ItemAlign.Start)

          ForEach(this.suggestions.slice(0, 5), (suggestion: string) => {
            Row() {
              Text(suggestion)
                .fontSize(14)
                .fontColor(this.selectedSuggestion === suggestion ? '#FFFFFF' : ThemeManager.getCurrentTextColor())
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor(this.selectedSuggestion === suggestion ? ThemeManager.getCurrentPrimaryColor() : ThemeManager.getCurrentSurfaceColor())
                .borderRadius(6)
                .borderRadius(6)
                .onClick(() => {
                  this.selectedSuggestion = suggestion
                  this.onSuggestionSelect?.(suggestion)
                  this.onSearch?.(suggestion)
                })
            }
            .width('100%')
            .margin({ bottom: 8 })
          })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(ThemeManager.getCurrentSurfaceColor())
        .borderRadius(12)
        .margin({ top: 16, bottom: 16 })
      }

      // 搜索历史（可选）
      if (this.showHistory && this.searchHistory.length > 0) {
        Column() {
          Row() {
            Text('最近搜索')
              .fontSize(14)
              .fontColor(ThemeManager.getCurrentTextSecondaryColor())
              .layoutWeight(1)

            Text('清除')
              .fontSize(14)
              .fontColor(ThemeManager.getCurrentPrimaryColor())
              .onClick(() => {
                this.onClearHistory?.()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 12 })

          ForEach(this.searchHistory.slice(0, 3), (history: string) => {
            Row() {
              Text(history)
                .fontSize(14)
                .fontColor(ThemeManager.getCurrentTextColor())
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(ThemeManager.getCurrentSurfaceColor())
                .borderRadius(6)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .onClick(() => {
                  this.onSearch?.(history)
                })
            }
            .width('100%')
            .margin({ bottom: 8 })
          })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(ThemeManager.getCurrentSurfaceColor())
        .borderRadius(12)
      }
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ThemeManager.getCurrentBackgroundColor())
    .height('100%')
  }
}

/**
 * 网络错误空状态组件
 * 专门用于网络连接问题的显示
 */
@ComponentV2
export struct NetworkErrorState {
  @Param errorMessage: string = '网络连接失败'
  @Param errorCode?: string = ''
  @Param showRetry: boolean = true
  @Param retryCount: number = 0
  @Param maxRetries: number = 3
  @Param onRetry?: () => void = () => {}
  @Param onSettings?: () => void = () => {}

  build() {
    Column() {
      // 错误图标
      Text('📶')
        .fontSize(80)
        .margin({ bottom: 24 })

      // 错误标题
      Text('连接失败')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.getCurrentErrorColor())
        .margin({ bottom: 12 })

      // 错误描述
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor(ThemeManager.getCurrentTextSecondaryColor())
        .textAlign(TextAlign.Center)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 24 })

      // 错误代码（如果有）
      if (this.errorCode) {
        Text(`错误代码: ${this.errorCode}`)
          .fontSize(12)
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          .backgroundColor(ThemeManager.getCurrentSurfaceColor())
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
          .margin({ bottom: 16 })
      }

      // 重试信息
      if (this.showRetry) {
        Text(`重试次数: ${this.retryCount}/${this.maxRetries}`)
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          .margin({ bottom: 24 })
      }

      // 操作按钮
      Row() {
        // 重试按钮
        if (this.showRetry && this.retryCount < this.maxRetries) {
          Button('重试')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(ThemeManager.getCurrentPrimaryColor())
            .borderRadius(8)
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .onClick(() => {
              this.onRetry?.()
            })
        }

        // 设置按钮
        if (this.onSettings) {
          Button('网络设置')
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
            .borderRadius(8)
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .onClick(() => {
              this.onSettings?.()
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ThemeManager.getCurrentBackgroundColor())
  }
}