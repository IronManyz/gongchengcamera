/**
 * 批量操作组件
 * 提供多选、批量导出、删除等功能
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { Photo } from '../../models/Photo'

export interface BatchSelection {
  allSelected: boolean
  selectedCount: number
  totalCount: number
  selectedPhotos: Photo[]
}

export interface BatchOperation {
  key: string
  label: string
  icon: string
  description: string
  action: () => void
  type?: 'primary' | 'secondary' | 'danger'
  disabled?: boolean
}

@ComponentV2
export struct BatchOperations {
  @Param selection: BatchSelection
  @Param onToggleAll?: () => void
  @Param onClearSelection?: () => void
  @Param onDelete?: () => void
  @Param onExport?: (format?: string) => void
  @Param onAddTags?: () => void
  @Param onMoveToProject?: () => void

  @State private showExportOptions: boolean = false
  @State private showTagOptions: boolean = false
  @State private showProjectOptions: boolean = false
  @State private selectedExportFormat: string = 'PDF'

  private readonly exportFormats = [
    { key: 'PDF', label: 'PDF报告', icon: '📄' },
    { key: 'JPG', label: 'JPG图片', icon: '🖼️' },
    { key: 'PNG', label: 'PNG图片', icon: '🖼️' },
    { key: 'ZIP', label: 'ZIP压缩包', icon: '🗜️' }
  ]

  private readonly tagOptions = [
    { key: 'important', label: '重要', icon: '⭐', color: '#FFA500' },
    { key: 'review', label: '待检查', icon: '👁️', color: '#2196F3' },
    { key: 'approved', label: '已通过', icon: '✅', color: '#4CAF50' },
    { key: 'issue', label: '问题', icon: '❌', color: '#F44336' }
  ]

  /**
   * 选择控制栏
   */
  @Builder
  private SelectionControlBar() {
    Row({ space: 12 }) {
      // 全选按钮
      Button() {
        Row({ space: 6 }) {
          Text(this.selection.allSelected ? '☑️' : '⬜')
            .fontSize(16)

          Text(this.selection.allSelected ? '取消全选' : '全选')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('auto')
      .height(40)
      .backgroundColor(this.selection.allSelected ? '#F5F5F5' : ThemeManager.getCurrentPrimaryColor())
      .borderRadius(20)
      .border({
        width: 1,
        color: this.selection.allSelected ? '#E0E0E0' : ThemeManager.getCurrentPrimaryColor()
      })
      .fontColor(this.selection.allSelected ? '#666666' : '#FFFFFF')
      .onClick(() => this.onToggleAll?.())

      // 选择统计
      Column({ space: 4 }) {
        Text(`已选择`)
          .fontSize(14)
          .fontColor('#666666')

        Text(`${this.selection.selectedCount}张`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(this.selection.allSelected ? '#E3F2FD' : '#FFF7E6')
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(8)
      }

        Text(`/共${this.selection.totalCount}张`)
          .fontSize(14)
          .fontColor('#999999')
      }

      // 清除选择按钮
      if (this.selection.selectedCount > 0) {
        Button('清除选择')
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .border({ width: 1, color: '#E0E0E0' })
          .padding({ left: 12, right: 12 })
          .onClick(() => this.onClearSelection?.())
      }
    }
    .width('100%')
    .padding({ horizontal: 16, vertical: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 批量操作按钮
   */
  @Builder
  private BatchActionButtons() {
    Column({ space: 12 }) {
      Text('批量操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      // 操作按钮组
      Row({ space: 12 }) {
        // 导出按钮
        Column({ space: 8 }) {
          Button() {
            Text('📤 导出')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .height(48)
          .backgroundColor(ThemeManager.getCurrentPrimaryColor())
          .borderRadius(8)
          .onClick(() => this.showExportOptions = !this.showExportOptions)

          Text(this.selectedExportFormat)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .opacity(0.8)
          .margin({ top: -24 })
        }
        .width('100%')

        // 添加标签按钮
        Button() {
          Text('🏷️ 添加标签')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(48)
        .backgroundColor('#52C41A')
        .borderRadius(8)
        .onClick(() => this.showTagOptions = !this.showTagOptions)
      }
        .width('100%')

        // 移动到项目按钮
        Button() {
          Text('📁 移动到项目')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(48)
        .backgroundColor('#1890FF')
        .borderRadius(8)
        .onClick(() => this.showProjectOptions = !this.showProjectOptions)
      }
        .width('100%')

        // 删除按钮
        Button() {
          Text('🗑️ 删除')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(48)
        .backgroundColor('#FF4D4F')
        .borderRadius(8)
        .onClick(() => this.onDelete?.())
      }
        .width('100%')
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .width('100%')
    }
    .padding(20)
    .backgroundColor('#FAFAFA')
    .borderRadius(12)
  }

  /**
   * 导出选项弹窗
   */
  @Builder
  private ExportOptionsDialog() {
    Column({ space: 16 }) {
      // 标题栏
      Row() {
        Text('选择导出格式')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Spacer()

        Button('✕')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.showExportOptions = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })

      // 格式选择
      Column({ space: 8 }) {
        Text('导出格式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Grid() {
          ForEach(this.exportFormats, (format) => {
            GridItem() {
              Button() {
                Row({ space: 8 }) {
                  Text(format.icon)
                    .fontSize(16)

                  Column({ space: 4 }) {
                    Text(format.label)
                      .fontSize(14)
                      .fontColor(
                        this.selectedExportFormat === format.key ? '#FFFFFF' : '#333333'
                      )
                  }
                }
              }
              .width('100%')
              .height(60)
              .backgroundColor(
                this.selectedExportFormat === format.key ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5'
              )
              .borderRadius(8)
              .border({
                width: 1,
                color: this.selectedExportFormat === format.key ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
              })
              .onClick(() => {
                this.selectedExportFormat = format.key
              })
            }
          })
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')

      // 确认按钮
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 24, right: 24 })
          .onClick(() => this.showExportOptions = false)

        Button('确认导出')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ThemeManager.getCurrentPrimaryColor())
          .borderRadius(20)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            this.onExport?.(this.selectedExportFormat)
            this.showExportOptions = false
          })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#00000030',
      offsetX: 0,
      offsetY: 8
    })
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }

  /**
   * 标签选择弹窗
   */
  @Builder
  private TagOptionsDialog() {
    Column({ space: 16 }) {
      // 标题栏
      Row() {
        Text('选择标签')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Spacer()

        Button('✕')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.showTagOptions = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })

      // 标签选择
      Grid() {
        ForEach(this.tagOptions, (tag) => {
          GridItem() {
            Button() {
              Row({ space: 8 }) {
                Text(tag.icon)
                  .fontSize(16)

                Text(tag.label)
                  .fontSize(14)
                  .fontColor('#333333')
                  .textAlign(TextAlign.Start)
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .onClick(() => {
              // 应用标签到选中的照片
              this.onAddTags?.()
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')

      // 确认按钮
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 24, right: 24 })
          .onClick(() => this.showTagOptions = false)

        Button('应用标签')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ThemeManager.getCurrentPrimaryColor())
          .borderRadius(20)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            this.onAddTags?.()
            this.showTagOptions = false
          })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#00000030',
      offsetX: 0,
      offsetY: 8
    })
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }

  build() {
    Column({ space: 16 }) {
      this.SelectionControlBar()
      this.BatchActionButtons()
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(16)

    // 导出选项弹窗
    if (this.showExportOptions) {
      this.ExportOptionsDialog()
    }

    // 标签选项弹窗
    if (this.showTagOptions) {
      this.TagOptionsDialog()
    }
  }
}