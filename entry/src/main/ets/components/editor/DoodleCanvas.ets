/**
 * 涂鸦画布组件
 * 提供在照片上进行涂鸦绘制功能
 */

@ComponentV2
export struct DoodleCanvas {
  @Param backgroundImage: string = ''
  @Param strokeWidth: number = 3
  @Param strokeColor: ResourceStr = '#FF0000'
  @Param enableEraser: boolean = false
  @Param onDrawingChange?: (paths: DrawPath[]) => void
  @Param onUndo?: () => void
  @Param onRedo?: () => void

  @State private currentPath: DrawPath = new DrawPath()
  @State private paths: DrawPath[] = []
  @State private undoStack: DrawPath[] = []
  @State private isDrawing: boolean = false
  @State private canvasWidth: number = 0
  @State private canvasHeight: number = 0

  build() {
    Stack() {
      // 背景图片
      if (this.backgroundImage) {
        Image(this.backgroundImage)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      }

      // 绘制画布
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.initializeCanvas()
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event)
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.canvas_background'))
  }

  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D()

  private initializeCanvas() {
    this.context.lineCap = 'round'
    this.context.lineJoin = 'round'
    this.redrawCanvas()
  }

  private handleTouch(event: TouchEvent) {
    switch (event.type) {
      case TouchType.Down:
        this.startDrawing(event.touches[0])
        break
      case TouchType.Move:
        if (this.isDrawing) {
          this.draw(event.touches[0])
        }
        break
      case TouchType.Up:
      case TouchType.Cancel:
        this.stopDrawing()
        break
    }
  }

  private startDrawing(touch: TouchObject) {
    this.isDrawing = true
    this.currentPath = new DrawPath()
    this.currentPath.color = this.strokeColor
    this.currentPath.width = this.strokeWidth
    this.currentPath.isEraser = this.enableEraser
    this.currentPath.points.push({
      x: touch.x - this.getCanvasOffsetX(),
      y: touch.y - this.getCanvasOffsetY()
    })
  }

  private draw(touch: TouchObject) {
    const x = touch.x - this.getCanvasOffsetX()
    const y = touch.y - this.getCanvasOffsetY()

    this.currentPath.points.push({ x, y })

    // 绘制当前路径
    this.drawPath(this.currentPath)
  }

  private stopDrawing() {
    if (this.isDrawing && this.currentPath.points.length > 1) {
      this.paths.push(this.currentPath)
      this.undoStack = [] // 清空重做栈
      this.onDrawingChange?.(this.paths)
    }
    this.isDrawing = false
    this.currentPath = new DrawPath()
  }

  private drawPath(path: DrawPath) {
    if (path.points.length < 2) return

    this.context.save()

    if (path.isEraser) {
      this.context.globalCompositeOperation = 'destination-out'
      this.context.lineWidth = path.width * 2
    } else {
      this.context.globalCompositeOperation = 'source-over'
      this.context.strokeStyle = path.color as string
      this.context.lineWidth = path.width
    }

    this.context.beginPath()
    this.context.moveTo(path.points[0].x, path.points[0].y)

    for (let i = 1; i < path.points.length; i++) {
      this.context.lineTo(path.points[i].x, path.points[i].y)
    }

    this.context.stroke()
    this.context.restore()
  }

  private redrawCanvas() {
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight)

    // 重绘所有路径
    this.paths.forEach(path => {
      this.drawPath(path)
    })
  }

  private getCanvasOffsetX(): number {
    // 计算画布在页面中的X偏移
    return 0 // 实际实现中需要获取真实偏移
  }

  private getCanvasOffsetY(): number {
    // 计算画布在页面中的Y偏移
    return 0 // 实际实现中需要获取真实偏移
  }

  // 公共方法
  public undo() {
    if (this.paths.length > 0) {
      const lastPath = this.paths.pop()!
      this.undoStack.push(lastPath)
      this.redrawCanvas()
      this.onDrawingChange?.(this.paths)
      this.onUndo?.()
    }
  }

  public redo() {
    if (this.undoStack.length > 0) {
      const path = this.undoStack.pop()!
      this.paths.push(path)
      this.redrawCanvas()
      this.onDrawingChange?.(this.paths)
      this.onRedo?.()
    }
  }

  public clear() {
    this.paths = []
    this.undoStack = []
    this.currentPath = new DrawPath()
    this.redrawCanvas()
    this.onDrawingChange?.(this.paths)
  }

  public setStrokeColor(color: ResourceStr) {
    this.strokeColor = color
  }

  public setStrokeWidth(width: number) {
    this.strokeWidth = width
  }

  public setEraser(enabled: boolean) {
    this.enableEraser = enabled
  }

  public getPaths(): DrawPath[] {
    return [...this.paths]
  }

  public canUndo(): boolean {
    return this.paths.length > 0
  }

  public canRedo(): boolean {
    return this.undoStack.length > 0
  }
}

/**
 * 涂鸦工具栏组件
 */
@ComponentV2
export struct DoodleToolbar {
  @Param strokeWidth: number = 3
  @Param strokeColor: ResourceStr = '#FF0000'
  @Param enableEraser: boolean = false
  @Param canUndo: boolean = false
  @Param canRedo: boolean = false
  @Param onColorChange?: (color: ResourceStr) => void
  @Param onWidthChange?: (width: number) => void
  @Param onEraserToggle?: (enabled: boolean) => void
  @Param onUndo?: () => void
  @Param onRedo?: () => void
  @Param onClear?: () => void

  private colorOptions: ResourceStr[] = [
    '#FF0000', '#FFA500', '#FFFF00', '#00FF00', '#00FFFF', '#0000FF', '#FF00FF', '#000000', '#FFFFFF'
  ]

  build() {
    Column() {
      // 工具栏第一行：颜色选择
      Row() {
        ForEach(
          this.colorOptions,
          (color: ResourceStr) => {
            Button() {
              Column()
                .width(32)
                .height(32)
                .backgroundColor(color)
                .borderRadius(16)
                .border({
                  width: this.strokeColor === color && !this.enableEraser ? 2 : 1,
                  color: this.strokeColor === color && !this.enableEraser ? $r('app.color.primary') : $r('app.color.border_default')
                })
            }
            .width(36)
            .height(36)
            .backgroundColor(Color.Transparent)
            .margin({ right: 8 })
            .onClick(() => {
              this.onColorChange?.(color)
              this.onEraserToggle?.(false)
            })
          }
        )
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ bottom: 12 })

      // 工具栏第二行：画笔大小和操作
      Row() {
        // 画笔大小
        Column() {
          Text('画笔大小')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 4 })

          Slider({
            value: this.strokeWidth,
            min: 1,
            max: 20,
            step: 1,
            style: SliderStyle.Inset
          })
            .width(120)
            .onChange((value: number) => {
              this.onWidthChange?.(value)
            })

          Text(`${this.strokeWidth}px`)
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 2 })
        }
        .margin({ right: 16 })

        // 工具按钮
        Column() {
          Row() {
            // 橡皮擦
            Button() {
              Column() {
                Image($r('app.media.ic_eraser'))
                  .width(20)
                  .height(20)
                  .fillColor(this.enableEraser ? $r('app.color.primary') : $r('app.color.text_secondary'))
              }
              .width(40)
              .height(40)
              .backgroundColor(this.enableEraser ? $r('app.color.primary_container') : $r('app.color.surface'))
              .borderRadius(8)
            }
            .onClick(() => {
              this.onEraserToggle?.(!this.enableEraser)
            })
            .margin({ right: 8 })

            // 撤销
            Button() {
              Image($r('app.media.ic_undo'))
                .width(20)
                .height(20)
                .fillColor(this.canUndo ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
            }
            .width(40)
            .height(40)
            .backgroundColor($r('app.color.surface'))
            .borderRadius(8)
            .enabled(this.canUndo)
            .onClick(() => {
              this.onUndo?.()
            })
            .margin({ right: 8 })

            // 重做
            Button() {
              Image($r('app.media.ic_redo'))
                .width(20)
                .height(20)
                .fillColor(this.canRedo ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
            }
            .width(40)
            .height(40)
            .backgroundColor($r('app.color.surface'))
            .borderRadius(8)
            .enabled(this.canRedo)
            .onClick(() => {
              this.onRedo?.()
            })
            .margin({ right: 8 })

            // 清除
            Button() {
              Image($r('app.media.ic_clear'))
                .width(20)
                .height(20)
                .fillColor($r('app.color.error'))
            }
            .width(40)
            .height(40)
            .backgroundColor($r('app.color.surface'))
            .borderRadius(8)
            .onClick(() => {
              this.onClear?.()
            })
          }
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background'))
    .borderRadius({ topLeft: 12, topRight: 12 })
  }
}

/**
 * 涂鸦编辑器组件
 */
@ComponentV2
export struct DoodleEditor {
  @Param backgroundImage: string = ''
  @Param onSave?: (paths: DrawPath[]) => void
  @Param onCancel?: () => void

  @State private paths: DrawPath[] = []
  @State private strokeWidth: number = 3
  @State private strokeColor: ResourceStr = '#FF0000'
  @State private enableEraser: boolean = false
  @State private canvas: DoodleCanvas | null = null

  build() {
    Column() {
      // 顶部栏
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onCancel?.()
          })

        Blank()

        Text('涂鸦编辑')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Button('保存')
          .fontSize(16)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .onClick(() => {
            this.onSave?.(this.paths)
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.surface'))

      // 画布区域
      Column() {
        DoodleCanvas({
          backgroundImage: this.backgroundImage,
          strokeWidth: this.strokeWidth,
          strokeColor: this.strokeColor,
          enableEraser: this.enableEraser,
          onDrawingChange: (paths: DrawPath[]) => {
            this.paths = paths
          }
        })
        .layoutWeight(1)
      }
      .layoutWeight(1)

      // 工具栏
      DoodleToolbar({
        strokeWidth: this.strokeWidth,
        strokeColor: this.strokeColor,
        enableEraser: this.enableEraser,
        canUndo: this.canvas?.canUndo() || false,
        canRedo: this.canvas?.canRedo() || false,
        onColorChange: (color: ResourceStr) => {
          this.strokeColor = color
        },
        onWidthChange: (width: number) => {
          this.strokeWidth = width
        },
        onEraserToggle: (enabled: boolean) => {
          this.enableEraser = enabled
        },
        onUndo: () => {
          this.canvas?.undo()
        },
        onRedo: () => {
          this.canvas?.redo()
        },
        onClear: () => {
          this.canvas?.clear()
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}

// 数据类定义
export class DrawPath {
  color: ResourceStr = '#FF0000'
  width: number = 3
  isEraser: boolean = false
  points: Point[] = []

  constructor(color?: ResourceStr, width?: number, isEraser?: boolean) {
    if (color) this.color = color
    if (width) this.width = width
    if (isEraser !== undefined) this.isEraser = isEraser
  }
}

export interface Point {
  x: number
  y: number
}