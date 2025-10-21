/**
 * 图形标注组件
 * 提供在照片上添加图形标注功能（箭头、方框、圆形等）
 */

@ComponentV2
export struct ShapeAnnotation {
  @Param backgroundImage: string = ''
  @Param shapes: ShapeData[] = []
  @Param editable: boolean = true
  @Param onShapeAdd?: (shape: ShapeData) => void
  @Param onShapeUpdate?: (index: number, shape: ShapeData) => void
  @Param onShapeDelete?: (index: number) => void
  @Param onSelect?: (index: number) => void

  @State private selectedShape: number = -1
  @State private currentTool: ShapeTool = ShapeTool.ARROW
  @State private showStyleDialog: boolean = false
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

      // 图形标注层
      ForEach(
        this.shapes,
        (shape: ShapeData, index: number) => {
          this.buildShapeItem(shape, index)
        },
        (shape: ShapeData, index: number) => `shape_annotation_${index}`
      )

      // 工具栏
      if (this.editable) {
        this.buildToolbar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.canvas_background'))

    // 样式设置对话框
    if (this.showStyleDialog && this.editingIndex >= 0) {
      ShapeStyleDialog({
        show: this.showStyleDialog,
        shape: this.shapes[this.editingIndex],
        onSave: (shape: ShapeData) => {
          this.onShapeUpdate?.(this.editingIndex, shape)
          this.showStyleDialog = false
          this.editingIndex = -1
        },
        onCancel: () => {
          this.showStyleDialog = false
          this.editingIndex = -1
        }
      })
    }
  }

  @Builder
  private buildShapeItem(shape: ShapeData, index: number) {
    Stack() {
      // 根据形状类型渲染不同的图形
      switch (shape.type) {
        case ShapeType.ARROW:
          this.buildArrow(shape)
          break
        case ShapeType.RECTANGLE:
          this.buildRectangle(shape)
          break
        case ShapeType.CIRCLE:
          this.buildCircle(shape)
          break
        case ShapeType.LINE:
          this.buildLine(shape)
          break
        case ShapeType.TEXT_BOX:
          this.buildTextBox(shape)
          break
      }

      // 选中边框
      if (this.selectedShape === index && this.editable) {
        this.buildSelectionBorder(shape, index)
      }
    }
  }

  @Builder
  private buildArrow(shape: ShapeData) {
    Path()
      .commands(`M ${shape.startX} ${shape.startY} L ${shape.endX} ${shape.endY}`)
      .strokeWidth(shape.strokeWidth)
      .stroke(shape.strokeColor)
      .fill(Color.Transparent)
      .antiAlias(true)

    // 箭头头部
    Path()
      .commands(this.buildArrowHead(shape))
      .strokeWidth(shape.strokeWidth)
      .stroke(shape.strokeColor)
      .fill(shape.strokeColor)
      .antiAlias(true)
  }

  @Builder
  private buildRectangle(shape: ShapeData) {
    Rect({
      width: Math.abs(shape.endX - shape.startX),
      height: Math.abs(shape.endY - shape.startY)
    })
      .position({
        x: Math.min(shape.startX, shape.endX),
        y: Math.min(shape.startY, shape.endY)
      })
      .strokeWidth(shape.strokeWidth)
      .stroke(shape.strokeColor)
      .fill(shape.fillColor || Color.Transparent)
      .antiAlias(true)
  }

  @Builder
  private buildCircle(shape: ShapeData) {
    const radius = Math.sqrt(
      Math.pow(shape.endX - shape.startX, 2) +
      Math.pow(shape.endY - shape.startY, 2)
    )

    Circle({ width: radius * 2, height: radius * 2 })
      .position({
        x: shape.startX - radius,
        y: shape.startY - radius
      })
      .strokeWidth(shape.strokeWidth)
      .stroke(shape.strokeColor)
      .fill(shape.fillColor || Color.Transparent)
      .antiAlias(true)
  }

  @Builder
  private buildLine(shape: ShapeData) {
    Path()
      .commands(`M ${shape.startX} ${shape.startY} L ${shape.endX} ${shape.endY}`)
      .strokeWidth(shape.strokeWidth)
      .stroke(shape.strokeColor)
      .fill(Color.Transparent)
      .antiAlias(true)
  }

  @Builder
  private buildTextBox(shape: ShapeData) {
    Rect({
      width: Math.abs(shape.endX - shape.startX),
      height: Math.abs(shape.endY - shape.startY)
    })
      .position({
        x: Math.min(shape.startX, shape.endX),
        y: Math.min(shape.startY, shape.endY)
      })
      .strokeWidth(shape.strokeWidth)
      .stroke(shape.strokeColor)
      .fill(shape.fillColor || 'rgba(255, 255, 255, 0.9)')
      .antiAlias(true)

    if (shape.text) {
      Text(shape.text)
        .fontSize(shape.fontSize || 14)
        .fontColor(shape.textColor || '#000000')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .position({
          x: Math.min(shape.startX, shape.endX) + Math.abs(shape.endX - shape.startX) / 2,
          y: Math.min(shape.startY, shape.endY) + Math.abs(shape.endY - shape.startY) / 2
        })
    }
  }

  @Builder
  private buildSelectionBorder(shape: ShapeData, index: number) {
    // 计算边界
    const bounds = this.calculateShapeBounds(shape)

    // 选择边框
    Rect({
      width: bounds.width + 10,
      height: bounds.height + 10
    })
      .position({
        x: bounds.x - 5,
        y: bounds.y - 5
      })
      .strokeWidth(2)
      .stroke($r('app.color.primary'))
      .fill(Color.Transparent)
      .strokeDashArray([5, 5])

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
        this.showStyleDialog = true
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
        this.onShapeDelete?.(index)
        if (this.selectedShape === index) {
          this.selectedShape = -1
        }
      })
    }
    .position({
      x: bounds.x + bounds.width + 8,
      y: bounds.y - 8
    })
  }

  @Builder
  private buildToolbar() {
    Column() {
      // 形状工具选择
      Row() {
        ForEach(
          [
            { tool: ShapeTool.ARROW, icon: $r('app.media.ic_arrow') },
            { tool: ShapeTool.RECTANGLE, icon: $r('app.media.ic_rectangle') },
            { tool: ShapeTool.CIRCLE, icon: $r('app.media.ic_circle') },
            { tool: ShapeTool.LINE, icon: $r('app.media.ic_line') },
            { tool: ShapeTool.TEXT_BOX, icon: $r('app.media.ic_text_box') }
          ],
          (item) => {
            Button() {
              Image(item.icon)
                .width(20)
                .height(20)
                .fillColor(
                  this.currentTool === item.tool
                    ? $r('app.color.on_primary')
                    : $r('app.color.text_secondary')
                )
            }
            .width(40)
            .height(40)
            .backgroundColor(
              this.currentTool === item.tool
                ? $r('app.color.primary')
                : $r('app.color.surface')
            )
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.currentTool = item.tool
              this.createShape(item.tool)
            })
          }
        )
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.surface'))
      .borderRadius({ topLeft: 12, topRight: 12 })

      // 样式设置
      ShapeStyleToolbar({
        strokeWidth: 3,
        strokeColor: '#FF0000',
        fillColor: 'transparent',
        onStrokeWidthChange: (width: number) => {
          // 更新当前选中图形的描边宽度
          if (this.selectedShape >= 0 && this.selectedShape < this.shapes.length) {
            const shape = { ...this.shapes[this.selectedShape] }
            shape.strokeWidth = width
            this.onShapeUpdate?.(this.selectedShape, shape)
          }
        },
        onStrokeColorChange: (color: ResourceStr) => {
          // 更新当前选中图形的描边颜色
          if (this.selectedShape >= 0 && this.selectedShape < this.shapes.length) {
            const shape = { ...this.shapes[this.selectedShape] }
            shape.strokeColor = color
            this.onShapeUpdate?.(this.selectedShape, shape)
          }
        },
        onFillColorChange: (color: ResourceStr) => {
          // 更新当前选中图形的填充颜色
          if (this.selectedShape >= 0 && this.selectedShape < this.shapes.length) {
            const shape = { ...this.shapes[this.selectedShape] }
            shape.fillColor = color
            this.onShapeUpdate?.(this.selectedShape, shape)
          }
        }
      })
    }
    .position({ x: 0, y: 60 })
  }

  private createShape(tool: ShapeTool) {
    const newShape: ShapeData = {
      type: tool,
      startX: 100,
      startY: 100,
      endX: 200,
      endY: 200,
      strokeWidth: 3,
      strokeColor: '#FF0000',
      fillColor: Color.Transparent
    }

    this.onShapeAdd?.(newShape)
    this.selectedShape = this.shapes.length
  }

  private buildArrowHead(shape: ShapeData): string {
    const angle = Math.atan2(shape.endY - shape.startY, shape.endX - shape.startX)
    const headLength = 15
    const headAngle = Math.PI / 6

    const x1 = shape.endX - headLength * Math.cos(angle - headAngle)
    const y1 = shape.endY - headLength * Math.sin(angle - headAngle)
    const x2 = shape.endX - headLength * Math.cos(angle + headAngle)
    const y2 = shape.endY - headLength * Math.sin(angle + headAngle)

    return `M ${shape.endX} ${shape.endY} L ${x1} ${y1} L ${x2} ${y2} Z`
  }

  private calculateShapeBounds(shape: ShapeData): { x: number, y: number, width: number, height: number } {
    const x = Math.min(shape.startX, shape.endX)
    const y = Math.min(shape.startY, shape.endY)
    const width = Math.abs(shape.endX - shape.startX)
    const height = Math.abs(shape.endY - shape.startY)

    return { x, y, width, height }
  }
}

/**
 * 图形样式工具栏组件
 */
@ComponentV2
export struct ShapeStyleToolbar {
  @Param strokeWidth: number = 3
  @Param strokeColor: ResourceStr = '#FF0000'
  @Param fillColor: ResourceStr = 'transparent'
  @Param onStrokeWidthChange?: (width: number) => void
  @Param onStrokeColorChange?: (color: ResourceStr) => void
  @Param onFillColorChange?: (color: ResourceStr) => void

  private colorOptions: ResourceStr[] = [
    '#FF0000', '#FFA500', '#FFFF00', '#00FF00', '#00FFFF', '#0000FF', '#FF00FF', '#000000', '#FFFFFF'
  ]

  build() {
    Column() {
      // 描边宽度
      Row() {
        Text('描边宽度')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width(60)

        Slider({
          value: this.strokeWidth,
          min: 1,
          max: 10,
          step: 1,
          style: SliderStyle.Inset
        })
          .width(120)
          .onChange((value: number) => {
            this.onStrokeWidthChange?.(value)
          })

        Text(`${this.strokeWidth}px`)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width(40)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(12)

      // 描边颜色
      Row() {
        Text('描边颜色')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width(60)

        Row() {
          ForEach(
            this.colorOptions,
            (color: ResourceStr) => {
              Column()
                .width(24)
                .height(24)
                .backgroundColor(color)
                .borderRadius(12)
                .border({
                  width: this.strokeColor === color ? 2 : 1,
                  color: this.strokeColor === color ? $r('app.color.primary') : $r('app.color.border_default')
                })
                .margin({ right: 6 })
                .onClick(() => {
                  this.onStrokeColorChange?.(color)
                })
            }
          )
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      // 填充颜色
      Row() {
        Text('填充颜色')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width(60)

        Row() {
          // 透明选项
          Column()
            .width(24)
            .height(24)
            .backgroundColor($r('app.color.surface'))
            .borderRadius(12)
            .border({
              width: this.fillColor === 'transparent' ? 2 : 1,
              color: this.fillColor === 'transparent' ? $r('app.color.primary') : $r('app.color.border_default')
            })
            .margin({ right: 6 })
            .onClick(() => {
              this.onFillColorChange?.('transparent')
            })

          ForEach(
            this.colorOptions,
            (color: ResourceStr) => {
              Column()
                .width(24)
                .height(24)
                .backgroundColor(color)
                .borderRadius(12)
                .border({
                  width: this.fillColor === color ? 2 : 1,
                  color: this.fillColor === color ? $r('app.color.primary') : $r('app.color.border_default')
                })
                .margin({ right: 6 })
                .onClick(() => {
                  this.onFillColorChange?.(color)
                })
            }
          )
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .backgroundColor($r('app.color.surface'))
    .borderRadius({ bottomLeft: 12, bottomRight: 12 })
  }
}

/**
 * 图形样式设置对话框
 */
@ComponentV2
export struct ShapeStyleDialog {
  @Param show: boolean = false
  @Param shape: ShapeData = new ShapeData()
  @Param onSave?: (shape: ShapeData) => void
  @Param onCancel?: () => void

  @State private localShape: ShapeData = new ShapeData()

  aboutToAppear() {
    this.localShape = { ...this.shape }
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
          Text('图形样式设置')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 20 })

          // 如果是文本框，显示文本输入
          if (this.localShape.type === ShapeType.TEXT_BOX) {
            Column() {
              Text('文本内容')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: 8 })

              TextInput({
                placeholder: '请输入文本内容',
                text: this.localShape.text || ''
              })
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor($r('app.color.surface'))
                .borderRadius(8)
                .padding(12)
                .onChange((value: string) => {
                  this.localShape.text = value
                })
            }
            .margin({ bottom: 16 })
          }

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
              .onClick(() => {
                this.onSave?.(this.localShape)
              })
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .width('80%')
        .padding(20)
        .backgroundColor($r('app.color.dialog_background'))
        .borderRadius(12)
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
}

// 枚举和数据类定义
export enum ShapeType {
  ARROW = 'arrow',
  RECTANGLE = 'rectangle',
  CIRCLE = 'circle',
  LINE = 'line',
  TEXT_BOX = 'text_box'
}

export enum ShapeTool {
  ARROW = 'arrow',
  RECTANGLE = 'rectangle',
  CIRCLE = 'circle',
  LINE = 'line',
  TEXT_BOX = 'text_box'
}

export class ShapeData {
  type: ShapeType = ShapeType.ARROW
  startX: number = 0
  startY: number = 0
  endX: number = 0
  endY: number = 0
  strokeWidth: number = 3
  strokeColor: ResourceStr = '#FF0000'
  fillColor: ResourceStr = Color.Transparent
  text?: string
  fontSize?: number
  textColor?: ResourceStr

  constructor(type?: ShapeType, startX?: number, startY?: number, endX?: number, endY?: number) {
    if (type) this.type = type
    if (startX !== undefined) this.startX = startX
    if (startY !== undefined) this.startY = startY
    if (endX !== undefined) this.endX = endX
    if (endY !== undefined) this.endY = endY
  }
}