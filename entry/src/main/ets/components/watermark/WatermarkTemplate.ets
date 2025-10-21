/**
 * 水印模板组件
 * 提供水印模板的选择和管理功能
 */

import { WatermarkTemplate, TemplateCategory } from '../../models/WatermarkTemplate'

@ComponentV2
export struct WatermarkTemplate {
  @Param templates: WatermarkTemplate[] = []
  @Param selectedTemplateId: string = ''
  @Param showCreateButton: boolean = true
  @Param onTemplateSelect?: (template: WatermarkTemplate) => void
  @Param onTemplateEdit?: (template: WatermarkTemplate) => void
  @Param onTemplateDelete?: (template: WatermarkTemplate) => void
  @Param onTemplateCreate?: () => void
  @Param onTemplateDuplicate?: (template: WatermarkTemplate) => void

  @State private currentCategory: TemplateCategory = TemplateCategory.ALL
  @State private searchQuery: string = ''

  private getFilteredTemplates(): WatermarkTemplate[] {
    let filtered = this.templates

    // 按分类过滤
    if (this.currentCategory !== TemplateCategory.ALL) {
      filtered = filtered.filter(template => template.category === this.currentCategory)
    }

    // 按搜索关键词过滤
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase()
      filtered = filtered.filter(template =>
        template.name.toLowerCase().includes(query) ||
        template.description.toLowerCase().includes(query)
      )
    }

    return filtered
  }

  private getGroupedTemplates(): Map<TemplateCategory, WatermarkTemplate[]> {
    const grouped = new Map<TemplateCategory, WatermarkTemplate[]>()
    const filtered = this.getFilteredTemplates()

    // 按分类分组
    Object.values(TemplateCategory).forEach(category => {
      if (category !== TemplateCategory.ALL) {
        const categoryTemplates = filtered.filter(template => template.category === category)
        if (categoryTemplates.length > 0) {
          grouped.set(category, categoryTemplates)
        }
      }
    })

    return grouped
  }

  build() {
    Column() {
      // 搜索栏
      SearchBar({
        query: this.searchQuery,
        placeholder: '搜索水印模板...',
        onChange: (query: string) => {
          this.searchQuery = query
        }
      })
      .margin({ bottom: 16 })

      // 分类标签
      this.buildCategoryTabs()

      // 模板列表
      Scroll() {
        Column() {
          ForEach(
            Array.from(this.getGroupedTemplates().entries()),
            ([category, templates]) => {
              this.buildTemplateCategory(category, templates)
            },
            (category) => `category_${category}`
          )

          // 空状态
          if (this.getFilteredTemplates().length === 0) {
            EmptyView({
              icon: $r('app.media.ic_template_empty'),
              title: this.searchQuery ? '未找到相关模板' : '暂无水印模板',
              description: this.searchQuery ? '尝试使用其他关键词搜索' : '点击下方按钮创建您的第一个水印模板',
              showButton: this.showCreateButton,
              buttonText: '创建模板',
              onButtonClick: () => {
                this.onTemplateCreate?.()
              }
            })
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 创建按钮
      if (this.showCreateButton) {
        Button('创建新模板')
          .fontSize(16)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .width('100%')
          .height(48)
          .margin(16)
          .onClick(() => {
            this.onTemplateCreate?.()
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private buildCategoryTabs() {
    Row() {
      ForEach(
        [
          { category: TemplateCategory.ALL, label: '全部' },
          { category: TemplateCategory.CONSTRUCTION, label: '施工' },
          { category: TemplateCategory.QUALITY, label: '质检' },
          { category: TemplateCategory.SAFETY, label: '安全' },
          { category: TemplateCategory.CUSTOM, label: '自定义' }
        ],
        (item) => {
          Text(item.label)
            .fontSize(14)
            .fontColor(
              this.currentCategory === item.category
                ? $r('app.color.primary')
                : $r('app.color.text_secondary')
            )
            .padding({ horizontal: 16, vertical: 8 })
            .backgroundColor(
              this.currentCategory === item.category
                ? $r('app.color.primary_container')
                : Color.Transparent
            )
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.currentCategory = item.category
            })
        }
      )
    }
    .width('100%')
    .padding({ horizontal: 16 })
    .margin({ bottom: 16 })
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  private buildTemplateCategory(category: TemplateCategory, templates: WatermarkTemplate[]) {
    Column() {
      // 分类标题
      Row() {
        Text(this.getCategoryLabel(category))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Text(`${templates.length}个模板`)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 模板网格
      Grid() {
        ForEach(
          templates,
          (template: WatermarkTemplate) => {
            GridItem() {
              this.buildTemplateCard(template)
            }
          },
          (template: WatermarkTemplate) => template.id
        )
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .margin({ bottom: 24 })
    }
    .width('100%')
  }

  @Builder
  private buildTemplateCard(template: WatermarkTemplate) {
    Column() {
      // 预览图
      Stack() {
        // 模板预览
        Image(template.preview || $r('app.media.ic_watermark_placeholder'))
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 8, topRight: 8 })
          .alt($r('app.media.ic_watermark_placeholder'))

        // 默认标记
        if (template.isDefault) {
          Row() {
            Text('默认')
              .fontSize(10)
              .fontColor(Color.White)
              .padding({ horizontal: 6, vertical: 2 })
              .backgroundColor($r('app.color.primary'))
              .borderRadius(10)
          }
          .position({ x: 8, y: 8 })
        }

        // 系统标记
        if (template.isSystem) {
          Row() {
            Text('系统')
              .fontSize(10)
              .fontColor(Color.White)
              .padding({ horizontal: 6, vertical: 2 })
              .backgroundColor($r('app.color.secondary'))
              .borderRadius(10)
          }
          .position({ x: 8, y: template.isDefault ? 28 : 8 })
        }

        // 选中标记
        if (this.selectedTemplateId === template.id) {
          Row() {
            Blank()
            Image($r('app.media.ic_check_circle'))
              .width(24)
              .height(24)
              .fillColor($r('app.color.primary'))
          }
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
        }
      }

      // 模板信息
      Column() {
        Text(template.name)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })

        Text(template.description)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 8 })

        // 使用次数
        Row() {
          Text(`使用 ${template.usageCount} 次`)
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))

          Blank()

          // 更多按钮
          Button() {
            Image($r('app.media.ic_more_vert'))
              .width(16)
              .height(16)
              .fillColor($r('app.color.text_tertiary'))
          }
          .width(24)
          .height(24)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showTemplateOptions(template)
          })
        }
        .width('100%')
      }
      .padding(12)
      .backgroundColor($r('app.color.surface'))
      .borderRadius({ bottomLeft: 8, bottomRight: 8 })
    }
    .backgroundColor(this.selectedTemplateId === template.id ? $r('app.color.primary_container') : $r('app.color.background'))
    .borderRadius(8)
    .border({
      width: this.selectedTemplateId === template.id ? 2 : 1,
      color: this.selectedTemplateId === template.id ? $r('app.color.primary') : $r('app.color.border_default')
    })
    .onClick(() => {
      this.onTemplateSelect?.(template)
    })
  }

  private getCategoryLabel(category: TemplateCategory): string {
    switch (category) {
      case TemplateCategory.CONSTRUCTION:
        return '施工模板'
      case TemplateCategory.QUALITY:
        return '质检模板'
      case TemplateCategory.SAFETY:
        return '安全模板'
      case TemplateCategory.CUSTOM:
        return '自定义模板'
      default:
        return '其他模板'
    }
  }

  private showTemplateOptions(template: WatermarkTemplate) {
    // 显示模板选项菜单
    const options = [
      { text: '编辑', action: () => this.onTemplateEdit?.(template) },
      { text: '复制', action: () => this.onTemplateDuplicate?.(template) }
    ]

    // 系统模板不能删除
    if (!template.isSystem) {
      options.push({ text: '删除', action: () => this.onTemplateDelete?.(template) })
    }

    // 这里应该显示选择器或自定义菜单
  }
}

/**
 * 简化的水印模板选择器
 */
@ComponentV2
export struct WatermarkTemplateSelector {
  @Param templates: WatermarkTemplate[] = []
  @Param selectedTemplateId: string = ''
  @Param onTemplateSelect?: (template: WatermarkTemplate) => void

  build() {
    Column() {
      ForEach(
        this.templates,
        (template: WatermarkTemplate) => {
          Row() {
            // 预览图
            Image(template.preview || $r('app.media.ic_watermark_placeholder'))
              .width(60)
              .height(40)
              .objectFit(ImageFit.Cover)
              .borderRadius(4)
              .alt($r('app.media.ic_watermark_placeholder'))

            // 模板信息
            Column() {
              Text(template.name)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(template.description)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })

            // 选中标记
            if (this.selectedTemplateId === template.id) {
              Image($r('app.media.ic_check'))
                .width(20)
                .height(20)
                .fillColor($r('app.color.primary'))
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.selectedTemplateId === template.id ? $r('app.color.primary_container') : $r('app.color.background'))
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onClick(() => {
            this.onTemplateSelect?.(template)
          })
        },
        (template: WatermarkTemplate) => template.id
      )
    }
    .width('100%')
  }
}

/**
 * 水印模板卡片组件
 */
@ComponentV2
export struct WatermarkTemplateCard {
  @Param template: WatermarkTemplate = new WatermarkTemplate()
  @Param isSelected: boolean = false
  @Param showActions: boolean = true
  @Param onClick?: (template: WatermarkTemplate) => void
  @Param onEdit?: (template: WatermarkTemplate) => void
  @Param onDelete?: (template: WatermarkTemplate) => void
  @Param onDuplicate?: (template: WatermarkTemplate) => void

  build() {
    Column() {
      // 预览区域
      Stack() {
        Image(this.template.preview || $r('app.media.ic_watermark_placeholder'))
          .width('100%')
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })
          .alt($r('app.media.ic_watermark_placeholder'))

        // 标签
        if (this.template.isDefault || this.template.isSystem) {
          Row() {
            if (this.template.isDefault) {
              Text('默认')
                .fontSize(10)
                .fontColor(Color.White)
                .padding({ horizontal: 6, vertical: 2 })
                .backgroundColor($r('app.color.primary'))
                .borderRadius(10)
                .margin({ right: 4 })
            }
            if (this.template.isSystem) {
              Text('系统')
                .fontSize(10)
                .fontColor(Color.White)
                .padding({ horizontal: 6, vertical: 2 })
                .backgroundColor($r('app.color.secondary'))
                .borderRadius(10)
            }
          }
          .margin(8)
        }
      }

      // 信息区域
      Column() {
        Text(this.template.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })

        Text(this.template.description)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 8 })

        Row() {
          Text(`使用 ${this.template.usageCount} 次`)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))

          if (this.showActions) {
            Blank()
            Button() {
              Image($r('app.media.ic_more_vert'))
                .width(20)
                .height(20)
                .fillColor($r('app.color.text_tertiary'))
            }
            .width(32)
            .height(32)
            .backgroundColor(Color.Transparent)
            .borderRadius(16)
            .onClick(() => {
              this.showActionMenu()
            })
          }
        }
        .width('100%')
      }
      .padding(16)
      .backgroundColor($r('app.color.surface'))
      .borderRadius({ bottomLeft: 12, bottomRight: 12 })
    }
    .backgroundColor(this.isSelected ? $r('app.color.primary_container') : $r('app.color.background'))
    .borderRadius(12)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? $r('app.color.primary') : $r('app.color.border_default')
    })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.onClick?.(this.template)
    })
  }

  private showActionMenu() {
    // 显示操作菜单
  }
}