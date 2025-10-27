/**
 * 文字标注工具面板组件
 * 提供文字添加、编辑和样式设置功能
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface TextAnnotation {
  id: string
  text: string
  x: number
  y: number
  fontSize: number
  fontColor: string
  backgroundColor?: string
  fontFamily: string
  fontWeight: FontWeight
  opacity: number
  rotation: number
}

export interface TextPreset {
  name: string
  fontSize: number
  fontColor: string
  fontWeight: FontWeight
  backgroundColor?: string
}

@ComponentV2
export struct TextAnnotationPanel {
  @Param annotations: TextAnnotation[] = []
  @Param selectedAnnotationId?: string
  @Param onAnnotationAdd?: (annotation: TextAnnotation) => void
  @Param onAnnotationUpdate?: (annotation: TextAnnotation) => void
  @Param onAnnotationDelete?: (id: string) => void
  @Param onAnnotationSelect?: (id: string) => void

  @State private currentText: string = ''
  @State private fontSize: number = 16
  @State private fontColor: string = '#000000'
  @State private backgroundColor: string = ''
  @State private fontFamily: string = 'HarmonyOS Sans'
  @State private fontWeight: FontWeight = FontWeight.Normal
  @State private opacity: number = 1.0
  @State private rotation: number = 0
  @State private showColorPicker: boolean = false
  @State private showFontSelector: boolean = false

  private readonly fonts = [
    'HarmonyOS Sans',
    'HarmonyOS Sans SC',
    'HarmonyOS Sans TC',
    'HarmonyOS Serif',
    'Roboto',
    'Arial',
    'Times New Roman'
  ]

  private readonly fontWeights = [
    { name: '细体', value: FontWeight.Thin },
    { name: '常规', value: FontWeight.Normal },
    { name: '中等', value: FontWeight.Medium },
    { name: '粗体', value: FontWeight.Bold }
  ]

  private readonly presetColors = [
    '#000000', '#FFFFFF', '#FF0000', '#00FF00', '#0000FF',
    '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080'
  ]

  private readonly textPresets: TextPreset[] = [
    { name: '标准标注', fontSize: 16, fontColor: '#000000', fontWeight: FontWeight.Normal },
    { name: '重要提示', fontSize: 20, fontColor: '#FF0000', fontWeight: FontWeight.Bold },
    { name: '警告信息', fontSize: 18, fontColor: '#FFA500', fontWeight: FontWeight.Medium },
    { name: '补充说明', fontSize: 14, fontColor: '#0000FF', fontWeight: FontWeight.Normal },
    { name: '标题文本', fontSize: 24, fontColor: '#000000', fontWeight: FontWeight.Bold }
  ]

  /**
   * 获取选中的文字标注
   */
  private get selectedAnnotation(): TextAnnotation | undefined {
    return this.annotations.find(a => a.id === this.selectedAnnotationId)
  }

  /**
   * 添加文字标注
   */
  private addAnnotation(): void {
    if (!this.currentText.trim()) {
      return
    }

    const annotation: TextAnnotation = {
      id: `text_${Date.now()}`,
      text: this.currentText,
      x: 100, // 这里应该是点击位置
      y: 100,
      fontSize: this.fontSize,
      fontColor: this.fontColor,
      backgroundColor: this.backgroundColor || undefined,
      fontFamily: this.fontFamily,
      fontWeight: this.fontWeight,
      opacity: this.opacity,
      rotation: this.rotation
    }

    this.onAnnotationAdd?.(annotation)
    this.currentText = ''
  }

  /**
   * 更新标注样式
   */
  private updateAnnotation(): void {
    const annotation = this.selectedAnnotation
    if (!annotation) return

    const updatedAnnotation: TextAnnotation = {
      ...annotation,
      fontSize: this.fontSize,
      fontColor: this.fontColor,
      backgroundColor: this.backgroundColor || undefined,
      fontFamily: this.fontFamily,
      fontWeight: this.fontWeight,
      opacity: this.opacity,
      rotation: this.rotation
    }

    this.onAnnotationUpdate?.(updatedAnnotation)
  }

  /**
   * 删除标注
   */
  private deleteAnnotation(): void {
    if (!this.selectedAnnotationId) return
    this.onAnnotationDelete?.(this.selectedAnnotationId)
  }

  /**
   * 文字输入区域
   */
  @Builder
  private TextInputArea() {
    Column({ space: 12 }) {
      Text('输入文字')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      TextArea({
        placeholder: '请输入标注文字...',
        text: this.currentText
      })
      .width('100%')
      .height(80)
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .backgroundColor(this.backgroundColor || '#FFFFFF')
      .borderRadius(8)
      .border({ width: 1, color: '#E0E0E0' })
      .padding(12)
      .onChange((value: string) => {
        this.currentText = value
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 快速预设
   */
  @Builder
  private QuickPresets() {
    Column({ space: 8 }) {
      Text('快速样式')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.textPresets, (preset: TextPreset) => {
            Button(preset.name)
              .fontSize(12)
              .fontColor(preset.fontColor)
              .backgroundColor(preset.backgroundColor || '#F5F5F5')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({
                width: 1,
                color: this.selectedAnnotation?.fontColor === preset.fontColor ?
                  ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
              })
              .onClick(() => {
                this.fontSize = preset.fontSize
                this.fontColor = preset.fontColor
                this.fontWeight = preset.fontWeight
                if (this.backgroundColor) {
                  this.backgroundColor = preset.backgroundColor
                }
                this.updateAnnotation()
              })
          })
        }
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .padding({ top: 12, bottom: 12 })
    .backgroundColor('#FAFAFA')
    .borderRadius(12)
  }

  /**
   * 样式设置面板
   */
  @Builder
  private StyleSettings() {
    Column({ space: 16 }) {
      Text('样式设置')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 字体大小
      Column({ space: 8 }) {
        Row() {
          Text('字体大小')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(`${this.fontSize}px`)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
        }

        Slider({
          value: this.fontSize,
          min: 12,
          max: 48,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .trackColor('#E0E0E0')
        .selectedColor(ThemeManager.getCurrentPrimaryColor())
        .onChange((value: number) => {
          this.fontSize = value
          this.updateAnnotation()
        })
      }

      // 颜色设置
      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Text('文字颜色')
            .fontSize(14)
            .fontColor('#333333')

          Row({ space: 8 }) {
            ForEach(this.presetColors, (color: string) => {
              Button() {
                Circle({ width: 24, height: 24 })
                  .fill(color)
                  .border({
                    width: this.fontColor === color ? 3 : 1,
                    color: this.fontColor === color ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
                  })
              }
              .width(32)
              .height(32)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.fontColor = color
                this.updateAnnotation()
              })
            })

            // 自定义颜色按钮
            Button('自定义')
              .fontSize(12)
              .fontColor(ThemeManager.getCurrentPrimaryColor())
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
              .borderRadius(16)
              .onClick(() => {
                this.showColorPicker = !this.showColorPicker
              })
          }
        }

        Text('背景颜色')
          .fontSize(14)
          .fontColor('#333333')

        Row({ space: 8 }) {
          Button('无背景')
            .fontSize(12)
            .fontColor(!this.backgroundColor ? ThemeManager.getCurrentPrimaryColor() : '#666666')
            .backgroundColor(!this.backgroundColor ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5')
            .borderRadius(8)
            .padding({ left: 8, right: 8 })
            .onClick(() => {
              this.backgroundColor = ''
              this.updateAnnotation()
            })

          ForEach(['#FFFFFF', '#000000', '#FFFF00', '#00FF00'], (color: string) => {
            Button() {
              Circle({ width: 16, height: 16 })
                .fill(color)
                .border({
                  width: this.backgroundColor === color ? 2 : 1,
                  color: this.backgroundColor === color ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
                })
            }
            .width(24)
            .height(24)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.backgroundColor = color
              this.updateAnnotation()
            })
          })
        }
      }
      .width('100%')

      // 字体设置
      Column({ space: 8 }) {
        Text('字体')
          .fontSize(14)
          .fontColor('#333333')

        Row({ space: 12 }) {
          // 字体系列
          Button(this.fontFamily)
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.showFontSelector = !this.showFontSelector
            })

          // 字体粗细
          Button(this.fontWeights.find(w => w.value === this.fontWeight)?.name || '常规')
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              // 切换字体粗细
              const currentIndex = this.fontWeights.findIndex(w => w.value === this.fontWeight)
              const nextIndex = (currentIndex + 1) % this.fontWeights.length
              this.fontWeight = this.fontWeights[nextIndex].value
              this.updateAnnotation()
            })
        }
      }

      // 透明度
      Column({ space: 8 }) {
        Row() {
          Text('透明度')
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
        .onChange((value: number) => {
          this.opacity = value
          this.updateAnnotation()
        })
      }

      // 旋转角度
      Column({ space: 8 }) {
        Row() {
          Text('旋转角度')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(`${this.rotation}°`)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
        }

        Slider({
          value: this.rotation,
          min: -180,
          max: 180,
          step: 15,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .trackColor('#E0E0E0')
        .selectedColor(ThemeManager.getCurrentPrimaryColor())
        .onChange((value: number) => {
          this.rotation = value
          this.updateAnnotation()
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 操作按钮
   */
  @Builder
  private ActionButtons() {
    Row({ space: 12 }) {
      Button('添加标注')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .padding({ left: 20, right: 20 })
        .onClick(() => this.addAnnotation())

      if (this.selectedAnnotation) {
        Button('删除')
          .fontSize(14)
          .fontColor('#FF4D4F')
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: '#FF4D4F' })
          .borderRadius(20)
          .padding({ left: 20, right: 20 })
          .onClick(() => this.deleteAnnotation())
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 16 })
  }

  build() {
    Column({ space: 16 }) {
      this.TextInputArea()
      this.QuickPresets()
      this.StyleSettings()
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