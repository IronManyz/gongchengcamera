/**
 * 图形标注工具面板组件
 * 提供矩形、圆形、箭头等图形绘制功能
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface ShapeAnnotation {
  id: string
  type: 'rectangle' | 'circle' | 'arrow' | 'line'
  startX: number
  startY: number
  endX: number
  endY: number
  strokeWidth: number
  strokeColor: string
  fillColor?: string
  opacity: number
  dashArray?: number[]
}

export interface ShapeTool {
  type: 'rectangle' | 'circle' | 'arrow' | 'line'
  name: string
  icon: string
  description: string
}

@ComponentV2
export struct ShapeAnnotationPanel {
  @Param selectedTool: ShapeTool
  @Param strokeWidth: number = 2
  @Param strokeColor: string = '#FF0000'
  @Param fillColor: string = ''
  @Param opacity: number = 1.0
  @Param dashArray: number[] = []
  @Param onToolChange?: (tool: ShapeTool) => void
  @Param onStrokeWidthChange?: (width: number) => void
  @Param onStrokeColorChange?: (color: string) => void
  @Param onFillColorChange?: (color: string) => void
  @Param onOpacityChange?: (opacity: number) => void
  @Param onDashArrayChange?: (dashArray: number[]) => void

  private readonly tools: ShapeTool[] = [
    {
      type: 'rectangle',
      name: '矩形',
      icon: '▭',
      description: '绘制矩形框'
    },
    {
      type: 'circle',
      name: '圆形',
      icon: '○',
      description: '绘制圆形标记'
    },
    {
      type: 'arrow',
      name: '箭头',
      icon: '→',
      description: '绘制指示箭头'
    },
    {
      type: 'line',
      name: '直线',
      icon: '╱',
      description: '绘制直线标记'
    }
  ]

  private readonly presetColors = [
    '#FF0000', '#00FF00', '#0000FF', '#FFFF00',
    '#FF00FF', '#00FFFF', '#FFA500', '#800080',
    '#000000', '#FFFFFF'
  ]

  private readonly strokeWidths = [1, 2, 3, 5, 8, 12]
  private readonly opacities = [0.3, 0.5, 0.7, 0.9, 1.0]
  private readonly dashPatterns = [
    { name: '实线', value: [] },
    { name: '虚线', value: [5, 5] },
    { name: '点线', value: [2, 2] },
    { name: '点划线', value: [10, 5, 2, 5] }
  ]

  /**
   * 工具选择器
   */
  @Builder
  private ToolSelector() {
    Column({ space: 12 }) {
      Text('绘制工具')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Grid() {
        ForEach(this.tools, (tool: ShapeTool) => {
          GridItem() {
            Column({ space: 6 }) {
              Button() {
                Text(tool.icon)
                  .fontSize(24)
                  .fontColor(this.selectedTool?.type === tool.type ? '#FFFFFF' : '#666666')
              }
              .width(56)
              .height(56)
              .backgroundColor(this.selectedTool?.type === tool.type ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
              .borderRadius(12)
              .onClick(() => this.onToolChange?.(tool))
            }

            Text(tool.name)
              .fontSize(12)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
          }
          .alignItems(HorizontalAlign.Center)
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
      .padding(16)
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  /**
   * 线条设置
   */
  @Builder
  private StrokeSettings() {
    Column({ space: 16 }) {
      Text('线条设置')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 线条宽度
      Column({ space: 8 }) {
        Row() {
          Text('线条宽度')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(`${this.strokeWidth}px`)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .fontWeight(FontWeight.Medium)
        }

        // 宽度选择器
        Row({ space: 8 }) {
          ForEach(this.strokeWidths, (width: number) => {
            Button() {
              Line()
                .width(40)
                .height(width)
                .strokeWidth(width)
                .strokeColor(this.strokeColor)
            }
            .width(48)
            .height(32)
            .backgroundColor(this.strokeWidth === width ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
            .borderRadius(6)
            .border({
              width: 1,
              color: this.strokeWidth === width ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
            })
            .onClick(() => this.onStrokeWidthChange?.(width))
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }

      // 线条颜色
      Column({ space: 8 }) {
        Row() {
          Text('线条颜色')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          // 当前颜色显示
          Circle({ width: 24, height: 24 })
            .fill(this.strokeColor)
            .border({ width: 2, color: '#E0E0E0' })
        }

        // 颜色选择器
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.presetColors, (color: string) => {
              Button() {
                Circle({ width: 28, height: 28 })
                  .fill(color)
                  .border({
                    width: this.strokeColor === color ? 3 : 1,
                    color: this.strokeColor === color ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
                  })
              }
              .width(36)
              .height(36)
              .backgroundColor(Color.Transparent)
              .onClick(() => this.onStrokeColorChange?.(color))
            })
          }
        }
        .width('100%')
        .scrollBar(BarState.Off)
      }

      // 线条样式
      Column({ space: 8 }) {
        Row() {
          Text('线条样式')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(this.dashPatterns.find(p =>
            JSON.stringify(p.value) === JSON.stringify(this.dashArray))?.name || '自定义')
        }
        .width('100%')

        // 样式选择器
        Row({ space: 12 }) {
          ForEach(this.dashPatterns, (pattern) => {
            Button(pattern.name)
              .fontSize(12)
              .fontColor(this.dashArray.length > 0 &&
                JSON.stringify(this.dashArray) === JSON.stringify(pattern.value) ?
                '#FFFFFF' : '#666666')
              .backgroundColor(this.dashArray.length > 0 &&
                JSON.stringify(this.dashArray) === JSON.stringify(pattern.value) ?
                ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onClick(() => this.onDashArrayChange?.(pattern.value))
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // 线条预览
        Row({ space: 16 }) {
          ForEach(this.dashPatterns, (pattern, index) => {
            Column({ space: 4 }) {
              Text(pattern.name)
                .fontSize(12)
                .fontColor('#666666')

              Line()
                .width(60)
                .strokeWidth(2)
                .strokeColor(this.strokeColor)
                .dashArray(pattern.value)
                .opacity(0.7 + (index * 0.06))
            }
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 填充设置
   */
  @Builder
  private FillSettings() {
    Column({ space: 16 }) {
      Text('填充设置')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 填充开关
      Row({ space: 12 }) {
        Text('启用填充')
          .fontSize(14)
          .fontColor('#333333')

        Toggle({ type: ToggleType.Switch, isOn: !!this.fillColor })
          .onChange((isOn: boolean) => {
            if (isOn && !this.fillColor) {
              this.onFillColorChange?.(this.strokeColor + '40') // 添加透明度
            } else if (!isOn) {
              this.onFillColorChange?.('')
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      if (this.fillColor) {
        // 透明度调节
        Column({ space: 8 }) {
          Row() {
            Text('填充透明度')
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)

            Text(`${Math.round(this.opacity * 100)}%`)
              .fontSize(14)
              .fontColor(ThemeManager.getCurrentPrimaryColor())
          }

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
          .onChange((value: number) => this.onOpacityChange?.(value))
        }
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 预设模板
   */
  @Builder
  private PresetTemplates() {
    Column({ space: 12 }) {
      Text('快速模板')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Grid() {
        ForEach([
          { name: '重点标记', color: '#FF0000', width: 3, fill: '#FF000020' },
          { name: '提示信息', color: '#FFA500', width: 2, fill: '#FFA50020' },
          { name: '安全区域', color: '#00FF00', width: 2, fill: '#00FF0020' },
          { name: '问题标记', color: '#0000FF', width: 3, fill: '#0000FF20' }
        ], (template, index) => {
          GridItem() {
            Button() {
              Column({ space: 6 }) {
                Text(template.name)
                  .fontSize(12)
                  .fontColor('#333333')

                Row({ space: 4 }) {
                  Line()
                    .width(20)
                    .strokeWidth(template.width)
                    .strokeColor(template.color)

                  if (template.fill) {
                    Circle({ width: 12, height: 12 })
                      .fill(template.fill)
                  }
                }
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .onClick(() => {
              this.onStrokeWidthChange?.(template.width)
              this.onStrokeColorChange?.(template.color)
              this.onFillColorChange?.(template.fill)
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .padding(16)
    }
    .backgroundColor('#FAFAFA')
    .borderRadius(12)
  }

  build() {
    Column({ space: 16 }) {
      this.ToolSelector()
      this.StrokeSettings()
      this.FillSettings()
      this.PresetTemplates()
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(16)
  }
}