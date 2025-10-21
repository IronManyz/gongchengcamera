/**
 * 文字标注组件
 * 提供在照片上添加文字标注功能
 */

@ComponentV2
export struct TextAnnotation {
  @Param backgroundImage: string = ''
  @Param annotations: TextAnnotationData[] = []
  @Param editable: boolean = true
  @Param onAnnotationAdd?: (annotation: TextAnnotationData) => void
  @Param onAnnotationUpdate?: (index: number, annotation: TextAnnotationData) => void
  @Param onAnnotationDelete?: (index: number) => void
  @Param onSelect?: (index: number) => void

  @State private selectedAnnotation: number = -1
  @State private showAddDialog: boolean = false
  @State private showEditDialog: boolean = false
  @State private editingIndex: number = -1

  build() {
    Stack() {
      // 背景图片
      if (this.backgroundImage) {
        Image(this.backgroundImage)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      }

      // 标注层
      ForEach(
        this.annotations,
        (annotation: TextAnnotationData, index: number) => {
          this.buildAnnotationItem(annotation, index)
        },
        (annotation: TextAnnotationData, index: number) => `text_annotation_${index}`
      )

      // 添加按钮
      if (this.editable) {
        Button() {
          Image($r('app.media.ic_add_text'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(24)
        .position({ x: 16, y: 100 })
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.showAddDialog = true
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.canvas_background'))

    // 添加标注对话框
    if (this.showAddDialog) {
      TextAnnotationDialog({
        show: this.showAddDialog,
        title: '添加文字标注',
        onSave: (annotation: TextAnnotationData) => {
          this.onAnnotationAdd?.(annotation)
          this.showAddDialog = false
        },
        onCancel: () => {
          this.showAddDialog = false
        }
      })
    }

    // 编辑标注对话框
    if (this.showEditDialog && this.editingIndex >= 0) {
      TextAnnotationDialog({
        show: this.showEditDialog,
        title: '编辑文字标注',
        annotation: this.annotations[this.editingIndex],
        onSave: (annotation: TextAnnotationData) => {
          this.onAnnotationUpdate?.(this.editingIndex, annotation)
          this.showEditDialog = false
          this.editingIndex = -1
        },
        onCancel: () => {
          this.showEditDialog = false
          this.editingIndex = -1
        }
      })
    }
  }

  @Builder
  private buildAnnotationItem(annotation: TextAnnotationData, index: number) {
    Stack() {
      // 标注背景
      Column() {
        Text(annotation.text)
          .fontSize(annotation.fontSize)
          .fontColor(annotation.color)
          .fontWeight(annotation.fontWeight)
          .textAlign(TextAlign.Start)
          .maxWidth(200)
          .padding(8)
          .backgroundColor(annotation.backgroundColor)
          .borderRadius(annotation.borderRadius)
          .shadow({
            radius: annotation.shadowRadius,
            color: annotation.shadowColor,
            offsetX: annotation.shadowOffsetX,
            offsetY: annotation.shadowOffsetY
          })
      }
      .position({ x: annotation.x, y: annotation.y })

      // 选中边框
      if (this.selectedAnnotation === index && this.editable) {
        Column()
          .width('100%')
          .height('100%')
          .border({
            width: 2,
            color: $r('app.color.primary'),
            style: BorderStyle.Dashed
          })
          .borderRadius(annotation.borderRadius)
          .position({ x: annotation.x - 2, y: annotation.y - 2 })
          .onClick(() => {
            this.selectedAnnotation = index
            this.onSelect?.(index)
          })

        // 操作按钮
        Row() {
          // 编辑按钮
          Button() {
            Image($r('app.media.ic_edit'))
              .width(16)
              .height(16)
              .fillColor(Color.White)
          }
          .width(28)
          .height(28)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(14)
          .margin({ right: 4 })
          .onClick(() => {
            this.editingIndex = index
            this.showEditDialog = true
          })

          // 删除按钮
          Button() {
            Image($r('app.media.ic_delete'))
              .width(16)
              .height(16)
              .fillColor(Color.White)
          }
          .width(28)
          .height(28)
          .backgroundColor($r('app.color.error'))
          .borderRadius(14)
          .onClick(() => {
            this.onAnnotationDelete?.(index)
            if (this.selectedAnnotation === index) {
              this.selectedAnnotation = -1
            }
          })
        }
        .position({
          x: annotation.x + annotation.width + 4,
          y: annotation.y - 8
        })
      } else {
        // 非选中状态点击事件
        Column()
          .width(annotation.width + 16)
          .height(annotation.height + 16)
          .position({ x: annotation.x - 8, y: annotation.y - 8 })
          .onClick(() => {
            this.selectedAnnotation = index
            this.onSelect?.(index)
          })
      }
    }
  }
}

/**
 * 文字标注对话框组件
 */
@ComponentV2
export struct TextAnnotationDialog {
  @Param show: boolean = false
  @Param title: string = '文字标注'
  @Param annotation: TextAnnotationData = new TextAnnotationData()
  @Param onSave?: (annotation: TextAnnotationData) => void
  @Param onCancel?: () => void

  @State private localAnnotation: TextAnnotationData = new TextAnnotationData()

  aboutToAppear() {
    this.localAnnotation = { ...this.annotation }
  }

  build() {
    if (this.show) {
      Stack() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onCancel?.()
          })

        // 对话框内容
        Column() {
          // 标题
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 20 })

          Scroll() {
            Column() {
              // 文字内容
              Column() {
                Text('标注内容')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: 8 })

                TextArea({
                  placeholder: '请输入标注内容',
                  text: this.localAnnotation.text
                })
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .backgroundColor($r('app.color.surface'))
                  .borderRadius(8)
                  .padding(12)
                  .height(80)
                  .onChange((value: string) => {
                    this.localAnnotation.text = value
                  })
              }
              .margin({ bottom: 16 })

              // 字体大小
              Column() {
                Text('字体大小')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: 8 })

                Row() {
                  ForEach(
                    [12, 14, 16, 18, 20, 24],
                    (size: number) => {
                      Text(`${size}`)
                        .fontSize(14)
                        .fontColor(
                          this.localAnnotation.fontSize === size
                            ? $r('app.color.on_primary')
                            : $r('app.color.text_secondary')
                        )
                        .padding(8)
                        .backgroundColor(
                          this.localAnnotation.fontSize === size
                            ? $r('app.color.primary')
                            : $r('app.color.surface')
                        )
                        .borderRadius(6)
                        .margin({ right: 8 })
                        .onClick(() => {
                          this.localAnnotation.fontSize = size
                        })
                    }
                  )
                }
              }
              .margin({ bottom: 16 })

              // 文字颜色
              Column() {
                Text('文字颜色')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: 8 })

                Row() {
                  ForEach(
                    this.getColorOptions(),
                    (color) => {
                      Column()
                        .width(32)
                        .height(32)
                        .backgroundColor(color.value)
                        .borderRadius(16)
                        .border({
                          width: this.localAnnotation.color === color.value ? 2 : 1,
                          color: this.localAnnotation.color === color.value ? $r('app.color.primary') : $r('app.color.border_default')
                        })
                        .margin({ right: 8 })
                        .onClick(() => {
                          this.localAnnotation.color = color.value
                        })
                    }
                  )
                }
              }
              .margin({ bottom: 16 })

              // 背景颜色
              Column() {
                Text('背景颜色')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: 8 })

                Row() {
                  ForEach(
                    this.getBackgroundColorOptions(),
                    (color) => {
                      Column()
                        .width(32)
                        .height(32)
                        .backgroundColor(color.value)
                        .borderRadius(6)
                        .border({
                          width: this.localAnnotation.backgroundColor === color.value ? 2 : 1,
                          color: this.localAnnotation.backgroundColor === color.value ? $r('app.color.primary') : $r('app.color.border_default')
                        })
                        .margin({ right: 8 })
                        .onClick(() => {
                          this.localAnnotation.backgroundColor = color.value
                        })
                    }
                  )
                }
              }
              .margin({ bottom: 16 })

              // 字体粗细
              Column() {
                Text('字体粗细')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: 8 })

                Row() {
                  Text('普通')
                    .fontSize(14)
                    .fontColor(
                      this.localAnnotation.fontWeight === FontWeight.Normal
                        ? $r('app.color.on_primary')
                        : $r('app.color.text_secondary')
                    )
                    .padding(12)
                    .backgroundColor(
                      this.localAnnotation.fontWeight === FontWeight.Normal
                        ? $r('app.color.primary')
                        : $r('app.color.surface')
                    )
                    .borderRadius(8)
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.localAnnotation.fontWeight = FontWeight.Normal
                    })

                  Text('粗体')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(
                      this.localAnnotation.fontWeight === FontWeight.Medium
                        ? $r('app.color.on_primary')
                        : $r('app.color.text_secondary')
                    )
                    .padding(12)
                    .backgroundColor(
                      this.localAnnotation.fontWeight === FontWeight.Medium
                        ? $r('app.color.primary')
                        : $r('app.color.surface')
                    )
                    .borderRadius(8)
                    .onClick(() => {
                      this.localAnnotation.fontWeight = FontWeight.Medium
                    })
                }
              }
            }
          }
          .layoutWeight(1)

          // 按钮
          Row() {
            Button('取消')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .onClick(() => {
                this.onCancel?.()
              })

            Button('保存')
              .fontSize(16)
              .fontColor($r('app.color.on_primary'))
              .backgroundColor($r('app.color.primary'))
              .layoutWeight(1)
              .enabled(this.localAnnotation.text.trim().length > 0)
              .onClick(() => {
                this.onSave?.(this.localAnnotation)
              })
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .width('90%')
        .height('80%')
        .maxHeight(600)
        .backgroundColor($r('app.color.dialog_background'))
        .borderRadius(12)
        .padding(20)
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }

  private getColorOptions(): Array<{ value: string }> {
    return [
      { value: '#FFFFFF' },
      { value: '#000000' },
      { value: '#FF0000' },
      { value: '#00FF00' },
      { value: '#0000FF' },
      { value: '#FFFF00' },
      { value: '#FF00FF' },
      { value: '#00FFFF' }
    ]
  }

  private getBackgroundColorOptions(): Array<{ value: string }> {
    return [
      { value: 'rgba(0, 0, 0, 0.8)' },
      { value: 'rgba(255, 255, 255, 0.9)' },
      { value: 'rgba(255, 0, 0, 0.8)' },
      { value: 'rgba(0, 255, 0, 0.8)' },
      { value: 'rgba(0, 0, 255, 0.8)' },
      { value: 'rgba(255, 255, 0, 0.8)' },
      { value: 'rgba(255, 0, 255, 0.8)' },
      { value: 'rgba(0, 255, 255, 0.8)' }
    ]
  }
}

/**
 * 快速文字标注组件
 */
@ComponentV2
export struct QuickTextAnnotation {
  @Param text: string = ''
  @Param fontSize: number = 16
  @Param color: ResourceStr = '#FFFFFF'
  @Param backgroundColor: ResourceStr = 'rgba(0, 0, 0, 0.8)'
  @Param position: { x: number, y: number } = { x: 0, y: 0 }
  @Param editable: boolean = false
  @Param onEdit?: () => void
  @Param onDelete?: () => void

  build() {
    Stack() {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(this.color)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)
        .padding(8)
        .backgroundColor(this.backgroundColor)
        .borderRadius(6)
        .shadow({
          radius: 4,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 0,
          offsetY: 2
        })
        .position({ x: this.position.x, y: this.position.y })

      if (this.editable) {
        Row() {
          Button() {
            Image($r('app.media.ic_edit'))
              .width(14)
              .height(14)
              .fillColor(Color.White)
          }
          .width(24)
          .height(24)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(12)
          .margin({ right: 4 })
          .onClick(() => {
            this.onEdit?.()
          })

          Button() {
            Image($r('app.media.ic_delete'))
              .width(14)
              .height(14)
              .fillColor(Color.White)
          }
          .width(24)
          .height(24)
          .backgroundColor($r('app.color.error'))
          .borderRadius(12)
          .onClick(() => {
            this.onDelete?.()
          })
        }
        .position({
          x: this.position.x + 100,
          y: this.position.y - 8
        })
      }
    }
  }
}

// 数据类定义
export class TextAnnotationData {
  text: string = ''
  x: number = 0
  y: number = 0
  fontSize: number = 16
  color: ResourceStr = '#FFFFFF'
  backgroundColor: ResourceStr = 'rgba(0, 0, 0, 0.8)'
  fontWeight: FontWeight = FontWeight.Normal
  borderRadius: number = 6
  shadowRadius: number = 4
  shadowColor: string = 'rgba(0, 0, 0, 0.3)'
  shadowOffsetX: number = 0
  shadowOffsetY: number = 2
  width: number = 100 // 预估宽度，实际渲染时重新计算
  height: number = 30 // 预估高度，实际渲染时重新计算

  constructor(text?: string, x?: number, y?: number) {
    if (text) this.text = text
    if (x !== undefined) this.x = x
    if (y !== undefined) this.y = y
  }
}