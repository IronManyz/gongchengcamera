/**
 * 空状态组件
 * 提供统一的空数据展示和操作引导
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface EmptyStateConfig {
  icon?: string
  title: string
  description?: string
  actionText?: string
  onAction?: () => void
  type?: 'default' | 'search' | 'error' | 'network' | 'permission'
  customImage?: string
}

@ComponentV2
export struct EmptyState {
  @Param config?: EmptyStateConfig
  @Param height?: number = 300
  @Param showBackground: boolean = true

  private get defaultConfig(): EmptyStateConfig {
    return {
      title: '暂无数据',
      description: '这里还没有内容',
      type: 'default'
    }
  }

  private get currentConfig(): EmptyStateConfig {
    return { ...this.defaultConfig, ...this.config }
  }

  private getDefaultIcon(): string {
    switch (this.currentConfig.type) {
      case 'search': return '🔍'
      case 'error': return '⚠️'
      case 'network': return '🌐'
      case 'permission': return '🔒'
      default: return '📭'
    }
  }

  private getDefaultTitle(): string {
    switch (this.currentConfig.type) {
      case 'search': return '未找到结果'
      case 'error': return '加载失败'
      case 'network': return '网络连接异常'
      case 'permission': return '权限不足'
      default: return '暂无数据'
    }
  }

  private getDefaultDescription(): string {
    switch (this.currentConfig.type) {
      case 'search': return '尝试使用其他关键词搜索'
      case 'error': return '请稍后重试或联系技术支持'
      case 'network': return '请检查网络连接后重试'
      case 'permission': return '请在设置中开启相关权限'
      default: return '这里还没有任何内容'
    }
  }

  private getDefaultActionText(): string {
    switch (this.currentConfig.type) {
      case 'error': return '重试'
      case 'network': return '刷新'
      case 'permission': return '去设置'
      default: return '开始使用'
    }
  }

  @Builder
  private DefaultIcon() {
    Text(this.currentConfig.icon || this.getDefaultIcon())
      .fontSize(64)
      .fontColor('#C0C0C0')
      .textAlign(TextAlign.Center)
      .margin({ bottom: 16 })
  }

  @Builder
  private SearchEmptyState() {
    Column({ space: 16 }) {
      Text('🔍')
        .fontSize(64)
        .fontColor('#E0E0E0')
        .textAlign(TextAlign.Center)

      Text('未找到匹配结果')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      Text('尝试调整搜索条件或使用其他关键词')
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
    }
  }

  @Builder
  private ErrorEmptyState() {
    Column({ space: 16 }) {
      Text('⚠️')
        .fontSize(64)
        .fontColor('#FFB800')
        .textAlign(TextAlign.Center)

      Text('出现了一些问题')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      Text('请检查网络连接或稍后重试')
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })

      if (this.currentConfig.onAction) {
        Button() {
          Text('重试')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .height(40)
        .padding({ left: 24, right: 24 })
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .margin({ top: 16 })
        .onClick(this.currentConfig.onAction)
      }
    }
  }

  @Builder
  private NetworkEmptyState() {
    Column({ space: 16 }) {
      Text('🌐')
        .fontSize(64)
        .fontColor('#1890FF')
        .textAlign(TextAlign.Center)

      Text('网络连接异常')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      Text('请检查网络设置后重试')
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })

      if (this.currentConfig.onAction) {
        Button() {
          Text('刷新')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .height(40)
        .padding({ left: 24, right: 24 })
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .margin({ top: 16 })
        .onClick(this.currentConfig.onAction)
      }
    }
  }

  @Builder
  private PermissionEmptyState() {
    Column({ space: 16 }) {
      Text('🔒')
        .fontSize(64)
        .fontColor('#FAAD14')
        .textAlign(TextAlign.Center)

      Text('需要相关权限')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      Text('请在设置中开启所需权限以继续使用')
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })

      if (this.currentConfig.onAction) {
        Button() {
          Text('去设置')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .height(40)
        .padding({ left: 24, right: 24 })
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .margin({ top: 16 })
        .onClick(this.currentConfig.onAction)
      }
    }
  }

  @Builder
  private DefaultEmptyState() {
    Column({ space: 16 }) {
      // 图标
      this.DefaultIcon()

      // 标题
      Text(this.currentConfig.title || this.getDefaultTitle())
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      // 描述
      Text(this.currentConfig.description || this.getDefaultDescription())
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })

      // 操作按钮
      if (this.currentConfig.actionText && this.currentConfig.onAction) {
        Button() {
          Text(this.currentConfig.actionText)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .height(40)
        .padding({ left: 24, right: 24 })
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .margin({ top: 16 })
        .onClick(this.currentConfig.onAction)
      }
    }
  }

  build() {
    Column() {
      // 根据类型选择不同的空状态
      if (this.currentConfig.type === 'search') {
        this.SearchEmptyState()
      } else if (this.currentConfig.type === 'error') {
        this.ErrorEmptyState()
      } else if (this.currentConfig.type === 'network') {
        this.NetworkEmptyState()
      } else if (this.currentConfig.type === 'permission') {
        this.PermissionEmptyState()
      } else {
        this.DefaultEmptyState()
      }
    }
    .width('100%')
    .height(this.height || 300)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
    .backgroundColor(this.showBackground ? '#FAFAFA' : Color.Transparent)
    .borderRadius(this.showBackground ? 12 : 0)
  }
}