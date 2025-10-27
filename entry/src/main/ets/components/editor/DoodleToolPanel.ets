/**
 * 涂鸦工具面板组件
 * ���供完整的涂鸦绘制工具和设置
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface DoodleTool {
  type: 'pen' | 'highlighter' | 'marker' | 'eraser'
  name: string
  icon: string
  strokeWidth: number
  opacity: number
}

export interface DoodleColor {
  hex: string
  name: string
}

@ComponentV2
export struct DoodleToolPanel {
  @Param selectedTool: DoodleTool
  @Param strokeWidth: number = 3
  @Param strokeColor: string = '#FF0000'
  @Param opacity: number = 1.0
  @Param onToolChange?: (tool: DoodleTool) => void
  @Param onStrokeWidthChange?: (width: number) => void
  @Param onColorChange?: (color: string) => void
  @Param onOpacityChange?: (opacity: number) => void
  @Param onUndo?: () => void
  @Param onRedo?: () => void
  @Param onClear?: () => void

  private readonly tools: DoodleTool[] = [
    {
      type: 'pen',
      name: '画笔',
      icon: '✏️',
      strokeWidth: 3,
      opacity: 1.0
    },
    {
      type: 'highlighter',
      name: '荧光笔',
      icon: '🖍️',
      strokeWidth: 8,
      opacity: 0.5
    },
    {
      type: 'marker',
      name: '马克笔',
      icon: '🖊️',
      strokeWidth: 6,
      opacity: 0.8
    },
    {
      type: 'eraser',
      name: '橡皮擦',
      icon: '🧹',
      strokeWidth: 10,
      opacity: 1.0
    }
  ]

  private readonly colors: DoodleColor[] = [
    { hex: '#FF0000', name: '红色' },
    { hex: '#FF9800', name: '橙色' },
    { hex: '#FFEB3B', name: '黄色' },
    { hex: '#4CAF50', name: '绿色' },
    { hex: '#2196F3', name: '蓝色' },
    { hex: '#9C27B0', name: '紫色' },
    { hex: '#000000', name: '黑色' },
    { hex: '#FFFFFF', name: '白色' },
    { hex: '#795548', name: '棕色' },
    { hex: '#607D8B', name: '蓝灰色' }
  ]

  private readonly strokeWidths = [1, 2, 3, 5, 8, 12, 20]
  private readonly opacities = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]

  /**
   * 工具选择器
   */
  @Builder
  private ToolSelector() {
    Column({ space: 8 }) {
      Text('工具')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Row({ space: 12 }) {
        ForEach(this.tools, (tool: DoodleTool) => {
          Column({ space: 4 }) {
            Button() {
              Text(tool.icon)
                .fontSize(20)
            }
            .width(48)
            .height(48)
            .backgroundColor(this.selectedTool.type === tool.type ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
            .borderRadius(8)
            .border({
              width: this.selectedTool.type === tool.type ? 0 : 1,
              color: '#E0E0E0'
            })
            .onClick(() => this.onToolChange?.(tool))
          }

          Text(tool.name)
            .fontSize(12)
            .fontColor('#666666')
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ horizontal: 16 })
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding({ top: 16, bottom: 16 })
  }

  /**
   * 颜色选择器
   */
  @Builder
  private ColorSelector() {
    Column({ space: 8 }) {
      Text('颜色')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      // 当前颜色显示
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('当前')
            .fontSize(12)
            .fontColor('#666666')

          Row() {
            Circle({ width: 24, height: 24 })
              .fill(this.strokeColor)
              .border({ width: 2, color: '#E0E0E0' })
              .margin({ right: 8 })

            Text(this.getColorName(this.strokeColor))
              .fontSize(14)
              .fontColor('#333333')
          }
        }
        .layoutWeight(1)

        Blank()

        // 自定义颜色按钮
        Button('自定义')
          .fontSize(12)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            // 这里可以打开颜色选择器
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 预设颜色网格
      Grid() {
        ForEach(this.colors, (color: DoodleColor) => {
          GridItem() {
            Button() {
              Circle({ width: 32, height: 32 })
                .fill(color.hex)
                .border({
                  width: this.strokeColor === color.hex ? 3 : 1,
                  color: this.strokeColor === color.hex ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
                })
            }
            .width(40)
            .height(40)
            .backgroundColor(Color.Transparent)
            .onClick(() => this.onColorChange?.(color.hex))
          }
          .margin(4)
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .padding({ top: 12 })
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding({ top: 16, bottom: 16 })
  }

  /**
   * 笔刷设置
   */
  @Builder
  private BrushSettings() {
    Column({ space: 16 }) {
      Text('笔刷设置')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 笔刷宽度
      Column({ space: 8 }) {
        Row() {
          Text('笔刷大小')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(`${this.strokeWidth}px`)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        // 大小调节滑块
        Slider({
          value: this.strokeWidth,
          min: 1,
          max: 50,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .trackColor('#E0E0E0')
        .selectedColor(ThemeManager.getCurrentPrimaryColor())
        .blockColor('#FFFFFF')
        .onChange((value: number) => this.onStrokeWidthChange?.(value))

        // 大小预览
        Row({ space: 8 }) {
          ForEach([2, 5, 10, 20], (size: number) => {
            Circle({ width: size, height: size })
              .fill(this.strokeColor)
              .opacity(this.opacity)
              .border({
                width: this.strokeWidth === size ? 2 : 1,
                color: this.strokeWidth === size ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
              })
              .onClick(() => this.onStrokeWidthChange?.(size))
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
      }

      // 透明度调节
      Column({ space: 8 }) {
        Row() {
          Text('透明度')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(`${Math.round(this.opacity * 100)}%`)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        // 透明度滑块
        Slider({
          value: this.opacity,
          min: 0.1,
          max: 1.0,
          step: 0.1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .trackColor('#E0E0E0')
        .selectedColor(ThemeManager.getCurrentPrimaryColor())
        .blockColor('#FFFFFF')
        .onChange((value: number) => this.onOpacityChange?.(value))

        // 透明度预设
        Row({ space: 12 }) {
          ForEach(this.opacities, (opacity: number) => {
            Column({ space: 4 }) {
              Text(`${Math.round(opacity * 100)}%`)
                .fontSize(12)
                .fontColor('#666666')

              Circle({ width: 20, height: 20 })
                .fill(this.strokeColor)
                .opacity(opacity)
                .border({
                  width: this.opacity === opacity ? 2 : 1,
                  color: this.opacity === opacity ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
                })
                .onClick(() => this.onOpacityChange?.(opacity))
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
  }

  /**
   * 操作按钮
   */
  @Builder
  private ActionButtons() {
    Row({ space: 12 }) {
      // 撤销按钮
      Button() {
        Row({ space: 6 }) {
          Text('↶')
            .fontSize(16)
          Text('撤销')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
        }
      }
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')
      .borderRadius(20)
      .border({ width: 1, color: '#E0E0E0' })
      .onClick(() => this.onUndo?.())

      // 重做按钮
      Button() {
        Row({ space: 6 }) {
          Text('↷')
            .fontSize(16)
          Text('重做')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
        }
      }
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')
      .borderRadius(20)
      .border({ width: 1, color: '#E0E0E0' })
      .onClick(() => this.onRedo?.())

      // 清除按钮
      Button() {
        Row({ space: 6 }) {
          Text('🗑️')
            .fontSize(16)
          Text('清除')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
        }
      }
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFF5F5')
      .borderRadius(20)
      .border({ width: 1, color: '#FFE4E1' })
      .onClick(() => this.onClear?.())
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 16 })
  }

  /**
   * 获取颜色名称
   */
  private getColorName(hex: string): string {
    const color = this.colors.find(c => c.hex === hex)
    return color ? color.name : hex
  }

  build() {
    Column({ space: 16 }) {
      this.ToolSelector()
      this.ColorSelector()
      this.BrushSettings()
      this.ActionButtons()
    }
    .width('100%')
    .backgroundColor('#FAFAFA')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
  }
}