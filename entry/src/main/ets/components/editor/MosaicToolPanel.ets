/**
 * 马赛克模糊工具面板组件
 * 提供马赛克画笔和敏感信息模糊功能
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface MosaicArea {
  id: string
  x: number
  y: number
  width: number
  height: number
  blurLevel: number
  mosaicSize: number
}

export interface MosaicMode {
  type: 'brush' | 'rectangle' | 'smart'
  name: string
  icon: string
  description: string
}

@ComponentV2
export struct MosaicToolPanel {
  @Param selectedMode: MosaicMode
  @Param blurLevel: number = 10
  @Param mosaicSize: number = 15
  @Param onModeChange?: (mode: MosaicMode) => void
  @Param onBlurLevelChange?: (level: number) => void
  @Param onMosaicSizeChange?: (size: number) => void
  @Param onClearAll?: () => void

  private readonly modes: MosaicMode[] = [
    {
      type: 'brush',
      name: '画笔模式',
      icon: '🖌️',
      description: '自由涂抹马赛克'
    },
    {
      type: 'rectangle',
      name: '矩形模式',
      icon: '▭',
      description: '框选区域进行马赛克'
    },
    {
      type: 'smart',
      name: '智能模式',
      icon: '✨',
      description: '自动识别人脸进行马赛克'
    }
  ]

  private readonly blurLevels = [
    { name: '轻度', value: 5, preview: '🙂' },
    { name: '中度', value: 10, preview: '😐' },
    { name: '重度', value: 20, preview: '😵' },
    { name: '完全', value: 50, preview: '⬛' }
  ]

  private readonly mosaicSizes = [5, 10, 15, 20, 30, 50]

  /**
   * 模式选择器
   */
  @Builder
  private ModeSelector() {
    Column({ space: 12 }) {
      Text('马赛克模式')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Grid() {
        ForEach(this.modes, (mode: MosaicMode) => {
          GridItem() {
            Column({ space: 8 }) {
              Button() {
                Text(mode.icon)
                  .fontSize(24)
                  .fontColor(this.selectedMode?.type === mode.type ? '#FFFFFF' : '#666666')
              }
              .width(60)
              .height(60)
              .backgroundColor(this.selectedMode?.type === mode.type ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
              .borderRadius(12)
              .onClick(() => this.onModeChange?.(mode))

              Text(mode.name)
                .fontSize(12)
                .fontColor('#333333')
                .textAlign(TextAlign.Center)

              Text(mode.description)
                .fontSize(10)
                .fontColor('#999999')
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
      .width('100%')
      .padding(20)
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  /**
   * 模糊强度设置
   */
  @Builder
  private BlurLevelSettings() {
    Column({ space: 16 }) {
      Text('模糊强度')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 强度预览
      Row({ space: 16 }) {
        ForEach(this.blurLevels, (level, index) => {
          Column({ space: 8 }) {
            Text(level.name)
              .fontSize(12)
              .fontColor('#666666')

            Text(level.preview)
              .fontSize(32)
              .textAlign(TextAlign.Center)

            Text(`${level.value}px`)
              .fontSize(10)
              .fontColor('#999999')
          }
          .width(80)
          .height(100)
          .backgroundColor(this.blurLevel === level.value ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
          .borderRadius(8)
          .border({
            width: 2,
            color: this.blurLevel === level.value ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => this.onBlurLevelChange?.(level.value))
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // 自定义调节
      Column({ space: 8 }) {
        Row() {
          Text('自定义强度')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(`${this.blurLevel}px`)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .fontWeight(FontWeight.Medium)
        }

        Slider({
          value: this.blurLevel,
          min: 1,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .trackColor('#E0E0E0')
        .selectedColor(ThemeManager.getCurrentPrimaryColor())
        .onChange((value: number) => this.onBlurLevelChange?.(value))

        // 效果预览区域
        Row() {
          ForEach([0.2, 0.4, 0.6, 0.8], (opacity, index) => {
            Circle({ width: 30, height: 30 })
              .backgroundColor('#FF6B6B')
              .blur(this.blurLevel * opacity)
              .borderRadius(15)
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
   * 马赛克大小设置
   */
  @Builder
  private MosaicSizeSettings() {
    Column({ space: 16 }) {
      Text('马赛克大小')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 大小预览网格
      Grid() {
        ForEach(this.mosaicSizes, (size: number) => {
          GridItem() {
            Button() {
              // 马赛克块预览
              Grid() {
                ForEach(Array(size * size).fill(0), (_, index) => {
                  GridItem() {
                    Rectangle()
                      .width(100 / size)
                      .height(100 / size)
                      .fill(index % 2 === 0 ? '#FF0000' : '#00FF00')
                      .borderRadius(1)
                  }
                })
              }
              .width(50)
              .height(50)
              .borderRadius(8)
              .border({
                width: this.mosaicSize === size ? 3 : 1,
                color: this.mosaicSize === size ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
              })
            }
            .onClick(() => this.onMosaicSizeChange?.(size))
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .padding(20)

      // 大小数值显示
      Row() {
        Text('马赛克块大小')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(`${this.mosaicSize} × ${this.mosaicSize}px`)
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .fontWeight(FontWeight.Medium)
      }

      // 自定义调节
      Slider({
        value: this.mosaicSize,
        min: 3,
        max: 100,
        step: 1,
        style: SliderStyle.OutSet
      })
      .width('100%')
      .trackColor('#E0E0E0')
      .selectedColor(ThemeManager.getCurrentPrimaryColor())
      .onChange((value: number) => this.onMosaicSizeChange?.(value))
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 使用提示
   */
  @Builder
  private UsageTips() {
    Column({ space: 12 }) {
      Text('使用提示')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('💡')
            .fontSize(16)

          Text('画笔模式：直接在需要模糊的区域涂抹')
            .fontSize(13)
            .fontColor('#666666')
            .layoutWeight(1)
        }

        Row({ space: 8 }) {
          Text('▭')
            .fontSize(16)

          Text('矩形模式：框选需要处理的区域')
            .fontSize(13)
            .fontColor('#666666')
            .layoutWeight(1)
        }

        Row({ space: 8 }) {
          Text('✨')
            .fontSize(16)

          Text('智能模式：自动识别人脸和敏感信息')
            .fontSize(13)
            .fontColor('#666666')
            .layoutWeight(1)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFF8F0')
      .borderRadius(8)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 清除和撤销
   */
  @Builder
  private ActionButtons() {
    Row({ space: 12 }) {
      Button('清除所有马赛克')
        .fontSize(14)
        .fontColor('#666666')
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .border({ width: 1, color: '#E0E0E0' })
        .padding({ left: 20, right: 20 })
        .onClick(() => this.onClearAll?.())

      Button('撤销上一步')
        .fontSize(14)
        .fontColor('#666666')
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .border({ width: 1, color: '#E0E0E0' })
        .padding({ left: 20, right: 20 })
        .onClick(() => {
          // 撤销马赛克操作
        })

      Button('智能识别')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .padding({ left: 20, right: 20 })
        .onClick(() => {
          // 执行智能识别
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 20 })
  }

  build() {
    Column({ space: 16 }) {
      this.ModeSelector()
      this.BlurLevelSettings()
      this.MosaicSizeSettings()
      this.UsageTips()
      this.ActionButtons()
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#00000010',
      offsetX: 0,
      offsetY: 4
    })
  }
}