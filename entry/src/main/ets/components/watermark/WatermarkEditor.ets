/**
 * 水印编辑器组件
 * 提供水印模板的创建和编辑功能
 */

import { WatermarkTemplate, WatermarkField, WatermarkStyle, TemplateCategory } from '../../models/WatermarkTemplate'

@ComponentV2
export struct WatermarkEditor {
  @Param template: WatermarkTemplate = new WatermarkTemplate()
  @Param isEditing: boolean = false
  @Param onSave?: (template: WatermarkTemplate) => void
  @Param onCancel?: () => void
  @Param onPreview?: (template: WatermarkTemplate) => void

  @State private localTemplate: WatermarkTemplate = new WatermarkTemplate()
  @State private selectedField: WatermarkField | null = null
  @State private showPreview: boolean = true

  aboutToAppear() {
    this.localTemplate = { ...this.template }
  }

  build() {
    Column() {
      // 顶部栏
      this.buildHeader()

      // 主要内容
      Row() {
        // 左侧编辑面板
        Column() {
          this.buildBasicInfo()
          this.buildFieldEditor()
          this.buildStyleEditor()
        }
        .layoutWeight(1)
        .margin({ right: 16 })

        // 右侧预览面板
        Column() {
          this.buildPreviewPanel()
        }
        .width(350)
      }
      .layoutWeight(1)
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private buildHeader() {
    Row() {
      // 取消按钮
      Button('取消')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.onCancel?.()
        })

      Blank()

      // 标题
      Text(this.isEditing ? '编辑水印模板' : '创建水印模板')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Blank()

      // 保存按钮
      Button('保存')
        .fontSize(16)
        .fontColor($r('app.color.on_primary'))
        .backgroundColor($r('app.color.primary'))
        .enabled(this.validateTemplate())
        .onClick(() => {
          this.onSave?.(this.localTemplate)
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.surface'))
    .borderRadius({ topLeft: 0, topRight: 0 })
  }

  @Builder
  private buildBasicInfo() {
    Column() {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })

      // 模板名称
      Column() {
        Text('模板名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 4 })

        TextInput({
          placeholder: '请输入模板名称',
          text: this.localTemplate.name
        })
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            this.localTemplate.name = value
          })
      }
      .margin({ bottom: 16 })

      // 模板描述
      Column() {
        Text('模板描述')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 4 })

        TextArea({
          placeholder: '请输入模板描述',
          text: this.localTemplate.description
        })
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .borderRadius(8)
          .padding(12)
          .height(80)
          .onChange((value: string) => {
            this.localTemplate.description = value
          })
      }
      .margin({ bottom: 16 })

      // 模板分类
      Column() {
        Text('模板分类')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 4 })

        Row() {
          ForEach(
            [
              { category: TemplateCategory.CONSTRUCTION, label: '施工' },
              { category: TemplateCategory.QUALITY, label: '质检' },
              { category: TemplateCategory.SAFETY, label: '安全' },
              { category: TemplateCategory.CUSTOM, label: '自定义' }
            ],
            (item) => {
              Text(item.label)
                .fontSize(14)
                .fontColor(
                  this.localTemplate.category === item.category
                    ? $r('app.color.on_primary')
                    : $r('app.color.text_secondary')
                )
                .padding({ horizontal: 12, vertical: 6 })
                .backgroundColor(
                  this.localTemplate.category === item.category
                    ? $r('app.color.primary')
                    : $r('app.color.surface')
                )
                .borderRadius(16)
                .margin({ right: 8 })
                .onClick(() => {
                  this.localTemplate.category = item.category
                })
            }
          )
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder
  private buildFieldEditor() {
    Column() {
      Row() {
        Text('显示字段')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Button('添加字段')
          .fontSize(14)
          .fontColor($r('app.color.primary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.addNewField()
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 字段列表
      Column() {
        ForEach(
          this.localTemplate.fields,
          (field: WatermarkField, index: number) => {
            this.buildFieldItem(field, index)
          },
          (field: WatermarkField, index: number) => `field_${index}`
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  @Builder
  private buildFieldItem(field: WatermarkField, index: number) {
    Row() {
      // 拖拽图标
      Image($r('app.media.ic_drag'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_tertiary'))
        .margin({ right: 12 })

      // 字段信息
      Column() {
        Text(field.label)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))

        Text(this.getFieldPreview(field.key))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: field.enabled })
        .onChange((isOn: boolean) => {
          field.enabled = isOn
        })

      // 删除按钮
      Button() {
        Image($r('app.media.ic_delete'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.error'))
      }
      .width(32)
      .height(32)
      .backgroundColor(Color.Transparent)
      .margin({ left: 8 })
      .onClick(() => {
        this.removeField(index)
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.background'))
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.selectedField = field
    })
  }

  @Builder
  private buildStyleEditor() {
    Column() {
      Text('样式设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })

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
              Row() {
                Column()
                  .width(32)
                  .height(32)
                  .backgroundColor(color.value)
                  .borderRadius(6)
                  .border({
                    width: this.localTemplate.style.backgroundColor === color.value ? 2 : 1,
                    color: this.localTemplate.style.backgroundColor === color.value ? $r('app.color.primary') : $r('app.color.border_default')
                  })
              }
              .margin({ right: 8 })
              .onClick(() => {
                this.localTemplate.style.backgroundColor = color.value
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
            this.getTextColorOptions(),
            (color) => {
              Row() {
                Column()
                  .width(32)
                  .height(32)
                  .backgroundColor(color.value)
                  .borderRadius(6)
                  .border({
                    width: this.localTemplate.style.textColor === color.value ? 2 : 1,
                    color: this.localTemplate.style.textColor === color.value ? $r('app.color.primary') : $r('app.color.border_default')
                  })
              }
              .margin({ right: 8 })
              .onClick(() => {
                this.localTemplate.style.textColor = color.value
              })
            }
          )
        }
      }
      .margin({ bottom: 16 })

      // 字体大小
      Column() {
        Text('字体大小')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 8 })

        Slider({
          value: this.localTemplate.style.fontSize || 14,
          min: 10,
          max: 24,
          step: 1,
          style: SliderStyle.InSet
        })
          .width('100%')
          .onChange((value: number) => {
            this.localTemplate.style.fontSize = value
          })

        Text(`${this.localTemplate.style.fontSize || 14}px`)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 4 })
      }
      .margin({ bottom: 16 })

      // 位置设置
      Column() {
        Text('水印位置')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 8 })

        Grid() {
          ForEach(
            [
              { position: 'top-left', label: '左上' },
              { position: 'top-right', label: '右上' },
              { position: 'center', label: '居中' },
              { position: 'bottom-left', label: '左下' },
              { position: 'bottom-right', label: '右下' }
            ],
            (item) => {
              GridItem() {
                Text(item.label)
                  .fontSize(14)
                  .fontColor(
                    this.localTemplate.style.position === item.position
                      ? $r('app.color.on_primary')
                      : $r('app.color.text_secondary')
                  )
                  .padding(12)
                  .backgroundColor(
                    this.localTemplate.style.position === item.position
                      ? $r('app.color.primary')
                      : $r('app.color.surface')
                  )
                  .borderRadius(8)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.localTemplate.style.position = item.position as any
                  })
              }
            }
          )
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
    .borderRadius(12)
  }

  @Builder
  private buildPreviewPanel() {
    Column() {
      Row() {
        Text('实时预览')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.showPreview })
          .onChange((isOn: boolean) => {
            this.showPreview = isOn
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.showPreview) {
        // 预览区域
        Column() {
          Text('预览效果')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 12 })

          // 这里应该使用 WatermarkPreview 组件
          Column() {
            Text('水印预览区域')
              .fontSize(16)
              .fontColor($r('app.color.text_tertiary'))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(200)
          .backgroundColor($r('app.color.background'))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text('在真实环境中，这里会显示实际的水印预览效果')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .textAlign(TextAlign.Center)
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.surface'))
        .borderRadius(12)
      }
    }
    .width('100%')
  }

  private validateTemplate(): boolean {
    return this.localTemplate.name.trim().length > 0 &&
           this.localTemplate.fields.some(field => field.enabled)
  }

  private addNewField() {
    // 显示字段选择器
    const availableFields = this.getAvailableFields()
    if (availableFields.length > 0) {
      const newField: WatermarkField = {
        key: availableFields[0].key,
        label: availableFields[0].label,
        enabled: true
      }
      this.localTemplate.fields.push(newField)
    }
  }

  private removeField(index: number) {
    this.localTemplate.fields.splice(index, 1)
  }

  private getAvailableFields(): Array<{ key: string, label: string }> {
    const existingKeys = this.localTemplate.fields.map(field => field.key)
    const allFields = [
      { key: 'time', label: '时间' },
      { key: 'date', label: '日期' },
      { key: 'projectName', label: '项目名称' },
      { key: 'projectCode', label: '项目编号' },
      { key: 'siteName', label: '工点名称' },
      { key: 'address', label: '地址' },
      { key: 'coordinates', label: '坐标' },
      { key: 'weather', label: '天气' },
      { key: 'temperature', label: '温度' },
      { key: 'humidity', label: '湿度' }
    ]
    return allFields.filter(field => !existingKeys.includes(field.key))
  }

  private getFieldPreview(key: string): string {
    switch (key) {
      case 'time': return '14:30:25'
      case 'date': return '2024-01-15'
      case 'projectName': return '某某工程项目'
      case 'projectCode': return 'PRJ-2024-001'
      case 'siteName': return '某某工点'
      case 'address': return '某某省某某市某某区'
      case 'coordinates': return 'N 39.9042° E 116.4074°'
      case 'weather': return '晴'
      case 'temperature': return '25°C'
      case 'humidity': return '60%'
      default: return ''
    }
  }

  private getBackgroundColorOptions(): Array<{ value: string }> {
    return [
      { value: 'rgba(0, 0, 0, 0.6)' },
      { value: 'rgba(255, 255, 255, 0.8)' },
      { value: 'rgba(33, 150, 243, 0.8)' },
      { value: 'rgba(76, 175, 80, 0.8)' },
      { value: 'rgba(255, 152, 0, 0.8)' }
    ]
  }

  private getTextColorOptions(): Array<{ value: string }> {
    return [
      { value: '#FFFFFF' },
      { value: '#000000' },
      { value: '#2196F3' },
      { value: '#4CAF50' },
      { value: '#FF9800' }
    ]
  }
}