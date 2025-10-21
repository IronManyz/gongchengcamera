/**
 * 水印配置页面
 * 提供水印模板选择、字段配置、样式设置等功能
 */

import { router } from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { WatermarkService, WatermarkTemplate, WatermarkTemplateType, WatermarkPosition, WatermarkField, WatermarkConfig, WatermarkData } from '../../services/camera/WatermarkService'
import { GlobalStore } from '../../store/GlobalStore'
import { UserStore } from '../../store/user/UserStore'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'

/**
 * 页面参数接口
 */
interface WatermarkConfigPageParams {
  returnToCamera?: boolean
  templateId?: string
}

/**
 * 水印配置状态接口
 */
interface WatermarkConfigState {
  selectedTemplate: WatermarkTemplate | null
  config: WatermarkConfig
  data: WatermarkData
  previewUrl: string
  isCustomizing: boolean
  editingTemplate: boolean
}

@Entry
@Component
struct WatermarkConfigPage {
  private logger = new Logger('WatermarkConfigPage')
  private watermarkService: WatermarkService = WatermarkService.getInstance()
  private globalStore = GlobalStore.getInstance()
  private userStore = UserStore.getInstance()
  private projectStore = ProjectStore.getInstance()
  private siteStore = SiteStore.getInstance()

  // 页面参数
  @State private pageParams: WatermarkConfigPageParams = {}

  // 配置状态
  @State private configState: WatermarkConfigState = {
    selectedTemplate: null,
    config: this.watermarkService.getAvailableTemplates()[0]?.config || this.getDefaultConfig(),
    data: this.getDefaultWatermarkData(),
    previewUrl: '',
    isCustomizing: false,
    editingTemplate: false
  }

  // UI状态
  @State private availableTemplates: WatermarkTemplate[] = []
  @State private showTemplateSelector: boolean = false
  @State private showFieldEditor: boolean = false
  @State private showStyleEditor: boolean = false
  @State private showCustomTemplateDialog: boolean = false
  @State private errorMessage: string = ''
  @State private showError: boolean = false
  @State private showSaveSuccess: boolean = false

  // 自定义模板相关
  @State private customTemplateName: string = ''
  @State private customTemplateFields: WatermarkField[] = []
  @State private customTemplateContent: string = ''

  aboutToAppear() {
    this.logger.info('WatermarkConfigPage aboutToAppear')
    this.initializePage()
  }

  aboutToDisappear() {
    this.logger.info('WatermarkConfigPage aboutToDisappear')
  }

  /**
   * 初始化页面
   */
  private async initializePage(): Promise<void> {
    try {
      // 获取页面参数
      this.parsePageParams()

      // 加载可用模板
      this.loadAvailableTemplates()

      // 选择默认模板
      this.selectDefaultTemplate()

      // 生成预览
      await this.generatePreview()

      this.logger.info('WatermarkConfigPage initialized successfully')

    } catch (error) {
      this.logger.error('Failed to initialize WatermarkConfigPage', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 解析页面参数
   */
  private parsePageParams(): void {
    try {
      const params = router.getParams() as WatermarkConfigPageParams
      if (params) {
        this.pageParams = { ...params }
        this.logger.info('Page params parsed', this.pageParams)
      }
    } catch (error) {
      this.logger.error('Failed to parse page params', error)
    }
  }

  /**
   * 加载可用模板
   */
  private loadAvailableTemplates(): void {
    this.availableTemplates = this.watermarkService.getAvailableTemplates()
    this.logger.info('Available templates loaded', { count: this.availableTemplates.length })
  }

  /**
   * 选择默认模板
   */
  private selectDefaultTemplate(): void {
    if (this.pageParams.templateId) {
      // 根据参数选择模板
      const template = this.watermarkService.getTemplateById(this.pageParams.templateId)
      if (template) {
        this.configState.selectedTemplate = template
        this.configState.config = { ...template.config }
      }
    }

    if (!this.configState.selectedTemplate && this.availableTemplates.length > 0) {
      // 选择第一个可用模板
      this.configState.selectedTemplate = this.availableTemplates[0]
      this.configState.config = { ...this.availableTemplates[0].config }
    }

    this.logger.info('Template selected', {
      templateId: this.configState.selectedTemplate?.id,
      templateName: this.configState.selectedTemplate?.name
    })
  }

  /**
   * 生成预览
   */
  private async generatePreview(): Promise<void> {
    if (!this.configState.selectedTemplate) {
      return
    }

    try {
      this.configState.previewUrl = await this.watermarkService.previewWatermark(
        this.configState.data,
        this.configState.config
      )
    } catch (error) {
      this.logger.error('Failed to generate preview', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 选择模板
   */
  private selectTemplate(template: WatermarkTemplate): void {
    this.configState.selectedTemplate = template
    this.configState.config = { ...template.config }
    this.showTemplateSelector = false
    this.generatePreview()
    this.logger.info('Template selected', { templateId: template.id, templateName: template.name })
  }

  /**
   * 更新配置
   */
  private updateConfig(updates: Partial<WatermarkConfig>): void {
    this.configState.config = { ...this.configState.config, ...updates }
    this.generatePreview()
  }

  /**
   * 更新数据
   */
  private updateData(updates: Partial<WatermarkData>): void {
    this.configState.data = { ...this.configState.data, ...updates }
    this.generatePreview()
  }

  /**
   * 保存配置
   */
  private saveConfiguration(): void {
    if (!this.configState.selectedTemplate) {
      this.handleError(new Error('请先选择一个模板'))
      return
    }

    try {
      // 更新模板配置
      this.watermarkService.updateTemplateConfig(
        this.configState.selectedTemplate.id,
        this.configState.config
      )

      // 保存到全局配置
      this.saveToGlobalConfig()

      this.showSaveSuccess = true
      this.logger.info('Watermark configuration saved successfully')

      // 如果是从相机页面跳转过来的，返回相机页面
      if (this.pageParams.returnToCamera) {
        setTimeout(() => {
          router.back()
        }, 1500)
      }

    } catch (error) {
      this.logger.error('Failed to save configuration', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 保存到全局配置
   */
  private saveToGlobalConfig(): void {
    // 这里应该将配置保存到GlobalStore或持久化存储
    this.globalStore.setWatermarkConfig({
      templateId: this.configState.selectedTemplate?.id,
      config: this.configState.config,
      data: this.configState.data
    })
  }

  /**
   * 创建自定义模板
   */
  private createCustomTemplate(): void {
    if (!this.customTemplateName.trim()) {
      this.handleError(new Error('请输入模板名称'))
      return
    }

    if (this.customTemplateFields.length === 0) {
      this.handleError(new Error('请至少选择一个字段'))
      return
    }

    try {
      const customTemplate = this.watermarkService.createCustomTemplate(
        this.customTemplateName.trim(),
        this.customTemplateFields,
        this.customTemplateContent || this.generateDefaultTemplateContent(this.customTemplateFields),
        this.configState.config
      )

      this.availableTemplates = this.watermarkService.getAvailableTemplates()
      this.selectTemplate(customTemplate)
      this.showCustomTemplateDialog = false
      this.resetCustomTemplateForm()

      this.logger.info('Custom template created successfully', { templateId: customTemplate.id })

    } catch (error) {
      this.logger.error('Failed to create custom template', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 生成默认模板内容
   */
  private generateDefaultTemplateContent(fields: WatermarkField[]): string {
    let content = '<div style="{{style}}">\n'

    for (const field of fields) {
      switch (field) {
        case WatermarkField.PROJECT_NAME:
          content += '  <div style="font-weight: bold; margin-bottom: 4px;">{{projectName}}</div>\n'
          break
        case WatermarkField.SITE_NAME:
          content += '  <div style="font-size: 0.9em; margin-bottom: 2px;">{{siteName}}</div>\n'
          break
        case WatermarkField.DATE_TIME:
          content += '  <div style="font-size: 0.8em; margin-bottom: 2px;">{{dateTime}}</div>\n'
          break
        case WatermarkField.LOCATION:
          content += '  <div style="font-size: 0.8em; margin-bottom: 2px;">{{location}}</div>\n'
          break
        case WatermarkField.COMPANY_NAME:
          content += '  <div style="font-size: 0.7em; color: rgba(255,255,255,0.8);">{{companyName}}</div>\n'
          break
        case WatermarkField.DESCRIPTION:
          content += '  <div style="font-size: 0.8em; font-style: italic;">{{description}}</div>\n'
          break
        case WatermarkField.CAMERA_SETTINGS:
          content += '  <div style="font-size: 0.7em; margin-bottom: 2px;">{{cameraSettings}}</div>\n'
          break
        case WatermarkField.WEATHER:
          content += '  <div style="font-size: 0.8em; margin-bottom: 2px;">{{weather}}</div>\n'
          break
      }
    }

    content += '</div>'
    return content
  }

  /**
   * 重置自定义模板表单
   */
  private resetCustomTemplateForm(): void {
    this.customTemplateName = ''
    this.customTemplateFields = []
    this.customTemplateContent = ''
  }

  /**
   * 删除自定义模板
   */
  private deleteTemplate(template: WatermarkTemplate): void {
    if (template.type !== WatermarkTemplateType.CUSTOM) {
      this.handleError(new Error('只能删除自定义模板'))
      return
    }

    try {
      const success = this.watermarkService.deleteTemplate(template.id)
      if (success) {
        this.availableTemplates = this.watermarkService.getAvailableTemplates()
        if (this.configState.selectedTemplate?.id === template.id) {
          this.selectDefaultTemplate()
        }
        this.logger.info('Template deleted successfully', { templateId: template.id })
      } else {
        this.handleError(new Error('删除模板失败'))
      }
    } catch (error) {
      this.logger.error('Failed to delete template', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 导出模板
   */
  private exportTemplate(template: WatermarkTemplate): void {
    try {
      const templateJson = this.watermarkService.exportTemplate(template.id)
      if (templateJson) {
        // 这里应该触发文件下载或分享功能
        this.logger.info('Template exported successfully', { templateId: template.id })
      } else {
        this.handleError(new Error('导出模板失败'))
      }
    } catch (error) {
      this.logger.error('Failed to export template', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 处理错误
   */
  private handleError(error: Error): void {
    this.errorMessage = error.message
    this.showError = true
    this.logger.error('Watermark config page error', error)
  }

  /**
   * 关闭错误提示
   */
  private dismissError(): void {
    this.showError = false
    this.errorMessage = ''
  }

  /**
   * 关闭成功提示
   */
  private dismissSuccess(): void {
    this.showSaveSuccess = false
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    router.back()
  }

  /**
   * 获取默认配置
   */
  private getDefaultConfig(): WatermarkConfig {
    return {
      templateType: WatermarkTemplateType.ENGINEERING,
      position: WatermarkPosition.BOTTOM_RIGHT,
      backgroundColor: 'rgba(0, 0, 0, 0.7)',
      textColor: '#FFFFFF',
      fontSize: 14,
      fontFamily: 'sans-serif',
      opacity: 0.9,
      borderRadius: 8,
      padding: 12,
      margin: 20,
      maxWidth: 300,
      autoResize: true
    }
  }

  /**
   * 获取默认水印数据
   */
  private getDefaultWatermarkData(): WatermarkData {
    return {
      projectName: '示例工程项目',
      siteName: '示例工点',
      dateTime: new Date(),
      location: {
        latitude: 39.9042,
        longitude: 116.4074,
        altitude: 50,
        accuracy: 5
      },
      weather: {
        temperature: 25,
        condition: '晴'
      },
      cameraSettings: {
        model: 'Camera Model',
        focalLength: '24mm',
        aperture: '2.8',
        iso: '100',
        shutterSpeed: '1/125'
      },
      companyName: '示例公司',
      description: '示例描述信息'
    }
  }

  /**
   * 获取字段显示名称
   */
  private getFieldDisplayName(field: WatermarkField): string {
    const fieldNames: Record<WatermarkField, string> = {
      [WatermarkField.PROJECT_NAME]: '项目名称',
      [WatermarkField.SITE_NAME]: '工点名称',
      [WatermarkField.DATE_TIME]: '日期时间',
      [WatermarkField.LOCATION]: '地理位置',
      [WatermarkField.WEATHER]: '天气信息',
      [WatermarkField.CAMERA_SETTINGS]: '相机参数',
      [WatermarkField.COMPANY_NAME]: '公司名称',
      [WatermarkField.DESCRIPTION]: '描述信息'
    }
    return fieldNames[field] || field
  }

  /**
   * 获取位置显示名称
   */
  private getPositionDisplayName(position: WatermarkPosition): string {
    const positionNames: Record<WatermarkPosition, string> = {
      [WatermarkPosition.TOP_LEFT]: '左上角',
      [WatermarkPosition.TOP_RIGHT]: '右上角',
      [WatermarkPosition.BOTTOM_LEFT]: '左下角',
      [WatermarkPosition.BOTTOM_RIGHT]: '右下角',
      [WatermarkPosition.CENTER]: '居中'
    }
    return positionNames[position] || position
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 主要内容区
      Scroll() {
        Column() {
          // 模板选择区域
          this.buildTemplateSection()

          // 预览区域
          this.buildPreviewSection()

          // 字段配置区域
          this.buildFieldSection()

          // 样式配置区域
          this.buildStyleSection()

          // 操作按钮区域
          this.buildActionButtons()
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)

      // 底部保存栏
      this.buildBottomBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  buildTopBar() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(Color.Black)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.goBack())

      Blank()

      Text('水印配置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)

      Blank()

      Button('新建模板')
        .fontSize(14)
        .fontColor(Color.Blue)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showCustomTemplateDialog = true
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: 'rgba(0,0,0,0.1)', offsetY: 1 })
  }

  /**
   * 构建模板选择区域
   */
  @Builder
  buildTemplateSection() {
    Column() {
      Text('选择模板')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 当前选中模板
      Row() {
        Column() {
          Text(this.configState.selectedTemplate?.name || '未选择模板')
            .fontSize(14)
            .fontColor(Color.Black)
            .alignSelf(ItemAlign.Start)

          Text(this.configState.selectedTemplate?.type || '')
            .fontSize(12)
            .fontColor(Color.Gray)
            .alignSelf(ItemAlign.Start)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('更换')
          .fontSize(14)
          .fontColor(Color.Blue)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showTemplateSelector = true
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(() => {
        this.showTemplateSelector = true
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建预览区域
   */
  @Builder
  buildPreviewSection() {
    Column() {
      Text('预览效果')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 预览图
      Stack() {
        // 背景图（模拟）
        Image($r('app.media.preview_placeholder'))
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)

        // 水印预览（这里应该渲染实际的水印）
        if (this.configState.previewUrl) {
          Text('水印预览')
            .fontSize(12)
            .fontColor(Color.White)
            .padding(8)
            .backgroundColor('rgba(0,0,0,0.7)')
            .borderRadius(4)
            .position({
              x: this.getPositionStyleX(this.configState.config.position),
              y: this.getPositionStyleY(this.configState.config.position)
            })
        }
      }
      .width('100%')
      .height(200)
      .borderRadius(8)
      .backgroundColor(Color.Gray)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建字段配置区域
   */
  @Builder
  buildFieldSection() {
    Column() {
      Row() {
        Text('字段配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Blank()

        Button('编辑')
          .fontSize(14)
          .fontColor(Color.Blue)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showFieldEditor = true
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 字段列表
      Column() {
        ForEach(
          this.configState.selectedTemplate?.fields || [],
          (field: WatermarkField) => {
            Row() {
              Text(this.getFieldDisplayName(field))
                .fontSize(14)
                .fontColor(Color.Black)
                .layoutWeight(1)

              Text(this.getFieldValue(field))
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(4)
            .margin({ bottom: 8 })
          },
          (field: WatermarkField) => field
        )
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建样式配置区域
   */
  @Builder
  buildStyleSection() {
    Column() {
      Row() {
        Text('样式配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Blank()

        Button('编辑')
          .fontSize(14)
          .fontColor(Color.Blue)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showStyleEditor = true
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 样式预览
      Column() {
        Row() {
          Text('位置')
            .fontSize(14)
            .fontColor(Color.Gray)
            .width(80)

          Text(this.getPositionDisplayName(this.configState.config.position))
            .fontSize(14)
            .fontColor(Color.Black)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(4)
        .margin({ bottom: 8 })

        Row() {
          Text('字体大小')
            .fontSize(14)
            .fontColor(Color.Gray)
            .width(80)

          Text(`${this.configState.config.fontSize}px`)
            .fontSize(14)
            .fontColor(Color.Black)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(4)
        .margin({ bottom: 8 })

        Row() {
          Text('透明度')
            .fontSize(14)
            .fontColor(Color.Gray)
            .width(80)

          Text(`${Math.round(this.configState.config.opacity * 100)}%`)
            .fontSize(14)
            .fontColor(Color.Black)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(4)
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建操作按钮区域
   */
  @Builder
  buildActionButtons() {
    Row() {
      if (this.configState.selectedTemplate?.type === WatermarkTemplateType.CUSTOM) {
        Button('删除模板')
          .fontSize(14)
          .fontColor(Color.Red)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.deleteTemplate(this.configState.selectedTemplate!)
          })

        Button('导出模板')
          .fontSize(14)
          .fontColor(Color.Blue)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 12 })
          .onClick(() => {
            this.exportTemplate(this.configState.selectedTemplate!)
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .margin({ bottom: 16 })
  }

  /**
   * 构建底部保存栏
   */
  @Builder
  buildBottomBar() {
    Row() {
      Button('取消')
        .fontSize(16)
        .fontColor(Color.Black)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width(100)
        .onClick(() => this.goBack())

      Blank()

      Button('保存配置')
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(Color.Blue)
        .borderRadius(8)
        .width(120)
        .onClick(() => this.saveConfiguration())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .shadow({ radius: 2, color: 'rgba(0,0,0,0.1)', offsetY: -1 })
  }

  /**
   * 构建模板选择器
   */
  @Builder
  buildTemplateSelector() {
    if (this.showTemplateSelector) {
      Column() {
        Text('选择模板')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        Scroll() {
          Column() {
            ForEach(
              this.availableTemplates,
              (template: WatermarkTemplate) => {
                Row() {
                  Column() {
                    Text(template.name)
                      .fontSize(16)
                      .fontColor(Color.Black)
                      .alignSelf(ItemAlign.Start)

                    Text(template.type)
                      .fontSize(12)
                      .fontColor(Color.Gray)
                      .alignSelf(ItemAlign.Start)
                      .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  if (this.configState.selectedTemplate?.id === template.id) {
                    Image($r('app.media.ic_check'))
                      .width(20)
                      .height(20)
                      .fillColor(Color.Blue)
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor(
                  this.configState.selectedTemplate?.id === template.id ? Color.Blue : Color.White
                )
                .borderRadius(8)
                .margin({ bottom: 8 })
                .onClick(() => this.selectTemplate(template))
              },
              (template: WatermarkTemplate) => template.id
            )
          }
          .width('100%')
        }
        .layoutWeight(1)

        Button('取消')
          .fontSize(16)
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .width('100%')
          .onClick(() => {
            this.showTemplateSelector = false
          })
      }
      .width('90%')
      .height('80%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  /**
   * 构建自定义模板对话框
   */
  @Builder
  buildCustomTemplateDialog() {
    if (this.showCustomTemplateDialog) {
      Column() {
        Text('创建自定义模板')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        // 模板名称
        TextInput({ placeholder: '请输入模板名称' })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.customTemplateName = value
          })

        // 字段选择
        Text('选择字段')
          .fontSize(14)
          .fontColor(Color.Black)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })

        Column() {
          ForEach(
            Object.values(WatermarkField),
            (field: WatermarkField) => {
              Row() {
                Checkbox({
                  name: field,
                  group: 'templateFields'
                })
                  .select(this.customTemplateFields.includes(field))
                  .selectedColor(Color.Blue)
                  .onChange((checked: boolean) => {
                    if (checked) {
                      this.customTemplateFields.push(field)
                    } else {
                      const index = this.customTemplateFields.indexOf(field)
                      if (index > -1) {
                        this.customTemplateFields.splice(index, 1)
                      }
                    }
                  })

                Text(this.getFieldDisplayName(field))
                  .fontSize(14)
                  .fontColor(Color.Black)
                  .margin({ left: 8 })
              }
              .width('100%')
              .padding(8)
              .alignItems(VerticalAlign.Center)
            }
          )
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 20 })

        // 操作按钮
        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor(Color.Black)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .width(100)
            .onClick(() => {
              this.showCustomTemplateDialog = false
              this.resetCustomTemplateForm()
            })

          Blank()

          Button('创建')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(Color.Blue)
            .borderRadius(8)
            .width(100)
            .onClick(() => this.createCustomTemplate())
        }
        .width('100%')
      }
      .width('90%')
      .height('80%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  /**
   * 构建错误提示
   */
  @Builder
  buildErrorDialog() {
    if (this.showError) {
      Column() {
        Text('错误')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
          .margin({ bottom: 12 })

        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Black)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        Button('确定')
          .fontSize(16)
          .onClick(() => this.dismissError())
      }
      .width(280)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  /**
   * 构建成功提示
   */
  @Builder
  buildSuccessDialog() {
    if (this.showSaveSuccess) {
      Column() {
        Image($r('app.media.ic_success'))
          .width(40)
          .height(40)
          .fillColor(Color.Green)
          .margin({ bottom: 12 })

        Text('保存成功')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ bottom: 8 })

        Text('水印配置已保存')
          .fontSize(14)
          .fontColor(Color.Gray)
      }
      .width(200)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  /**
   * 获取字段值
   */
  private getFieldValue(field: WatermarkField): string {
    switch (field) {
      case WatermarkField.PROJECT_NAME:
        return this.configState.data.projectName || '未设置'
      case WatermarkField.SITE_NAME:
        return this.configState.data.siteName || '未设置'
      case WatermarkField.DATE_TIME:
        return this.configState.data.dateTime?.toLocaleString() || '当前时间'
      case WatermarkField.LOCATION:
        return this.configState.data.location ? '已获取' : '未获取'
      case WatermarkField.WEATHER:
        return this.configState.data.weather ? `${this.configState.data.weather.temperature}°C ${this.configState.data.weather.condition}` : '未获取'
      case WatermarkField.CAMERA_SETTINGS:
        return this.configState.data.cameraSettings ? '已设置' : '未设置'
      case WatermarkField.COMPANY_NAME:
        return this.configState.data.companyName || '未设置'
      case WatermarkField.DESCRIPTION:
        return this.configState.data.description || '未设置'
      default:
        return '未设置'
    }
  }

  /**
   * 获取位置样式X坐标
   */
  private getPositionStyleX(position: WatermarkPosition): string {
    switch (position) {
      case WatermarkPosition.TOP_LEFT:
      case WatermarkPosition.BOTTOM_LEFT:
        return '20px'
      case WatermarkPosition.TOP_RIGHT:
      case WatermarkPosition.BOTTOM_RIGHT:
        return 'calc(100% - 120px)'
      case WatermarkPosition.CENTER:
        return '50%'
      default:
        return 'calc(100% - 120px)'
    }
  }

  /**
   * 获取位置样式Y坐标
   */
  private getPositionStyleY(position: WatermarkPosition): string {
    switch (position) {
      case WatermarkPosition.TOP_LEFT:
      case WatermarkPosition.TOP_RIGHT:
        return '20px'
      case WatermarkPosition.BOTTOM_LEFT:
      case WatermarkPosition.BOTTOM_RIGHT:
        return 'calc(100% - 60px)'
      case WatermarkPosition.CENTER:
        return '50%'
      default:
        return 'calc(100% - 60px)'
    }
  }
}