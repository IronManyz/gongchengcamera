/**
 * 水印服务类
 * 提供水印模板渲染、动态信息叠加和样式配置功能
 */

import { image } from '@kit.ImageKit'
import { Logger } from '../../utils/Logger'
import { LocationData } from '../location/LocationService'

/**
 * 水印位置枚举
 */
export enum WatermarkPosition {
  TOP_LEFT = 'top-left',
  TOP_RIGHT = 'top-right',
  BOTTOM_LEFT = 'bottom-left',
  BOTTOM_RIGHT = 'bottom-right',
  CENTER = 'center'
}

/**
 * 水印模板类型枚举
 */
export enum WatermarkTemplateType {
  ENGINEERING = 'engineering',
  CONSTRUCTION = 'construction',
  QUALITY = 'quality',
  SAFETY = 'safety',
  CUSTOM = 'custom'
}

/**
 * 水印字段枚举
 */
export enum WatermarkField {
  PROJECT_NAME = 'projectName',
  SITE_NAME = 'siteName',
  DATE_TIME = 'dateTime',
  LOCATION = 'location',
  WEATHER = 'weather',
  CAMERA_SETTINGS = 'cameraSettings',
  COMPANY_NAME = 'companyName',
  DESCRIPTION = 'description'
}

/**
 * 水印配置接口
 */
export interface WatermarkConfig {
  templateType: WatermarkTemplateType
  position: WatermarkPosition
  backgroundColor: string
  textColor: string
  fontSize: number
  fontFamily: string
  opacity: number
  borderRadius: number
  padding: number
  margin: number
  maxWidth: number
  autoResize: boolean
}

/**
 * 水印数据接口
 */
export interface WatermarkData {
  projectName?: string
  siteName?: string
  dateTime?: Date
  location?: LocationData
  weather?: {
    temperature: number
    condition: string
  }
  cameraSettings?: {
    model: string
    focalLength: string
    aperture: string
    iso: string
    shutterSpeed: string
  }
  companyName?: string
  description?: string
  customFields?: Record<string, string>
}

/**
 * 渲染结果接口
 */
export interface WatermarkRenderResult {
  success: boolean
  pixelMap?: image.PixelMap
  error?: Error
  renderTime: number
}

/**
 * 水印模板定义接口
 */
export interface WatermarkTemplate {
  id: string
  name: string
  type: WatermarkTemplateType
  config: WatermarkConfig
  fields: WatermarkField[]
  template: string // HTML模板字符串
  preview?: string // 预览图URL
}

/**
 * 水印服务类
 */
export class WatermarkService {
  private static instance: WatermarkService | null = null
  private logger = new Logger('WatermarkService')

  // 默认配置
  private readonly defaultConfig: WatermarkConfig = {
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

  // 预定义模板
  private readonly predefinedTemplates: WatermarkTemplate[] = [
    {
      id: 'engineering-standard',
      name: '工程标准',
      type: WatermarkTemplateType.ENGINEERING,
      config: { ...this.defaultConfig },
      fields: [
        WatermarkField.PROJECT_NAME,
        WatermarkField.SITE_NAME,
        WatermarkField.DATE_TIME,
        WatermarkField.LOCATION,
        WatermarkField.COMPANY_NAME
      ],
      template: this.getEngineeringTemplate()
    },
    {
      id: 'construction-simple',
      name: '施工简易',
      type: WatermarkTemplateType.CONSTRUCTION,
      config: { ...this.defaultConfig },
      fields: [
        WatermarkField.PROJECT_NAME,
        WatermarkField.DATE_TIME,
        WatermarkField.LOCATION
      ],
      template: this.getConstructionTemplate()
    },
    {
      id: 'quality-detailed',
      name: '质量详细',
      type: WatermarkTemplateType.QUALITY,
      config: { ...this.defaultConfig },
      fields: [
        WatermarkField.PROJECT_NAME,
        WatermarkField.SITE_NAME,
        WatermarkField.DATE_TIME,
        WatermarkField.LOCATION,
        WatermarkField.CAMERA_SETTINGS,
        WatermarkField.DESCRIPTION
      ],
      template: this.getQualityTemplate()
    }
  ]

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): WatermarkService {
    if (!WatermarkService.instance) {
      WatermarkService.instance = new WatermarkService()
    }
    return WatermarkService.instance
  }

  /**
   * 渲染水印
   */
  async renderWatermark(
    originalImage: image.PixelMap,
    data: WatermarkData,
    config?: Partial<WatermarkConfig>
  ): Promise<WatermarkRenderResult> {
    const startTime = Date.now()
    this.logger.info('Rendering watermark...')

    try {
      // 合并配置
      const finalConfig = { ...this.defaultConfig, ...config }

      // 获取模板
      const template = this.getTemplate(finalConfig.templateType)

      // 生成HTML内容
      const htmlContent = this.generateHtmlContent(template, data, finalConfig)

      // 渲染HTML到图像
      const watermarkedImage = await this.renderHtmlToImage(originalImage, htmlContent, finalConfig)

      const result: WatermarkRenderResult = {
        success: true,
        pixelMap: watermarkedImage,
        renderTime: Date.now() - startTime
      }

      this.logger.info('Watermark rendered successfully', { renderTime: result.renderTime })
      return result

    } catch (error) {
      const renderError = error instanceof Error ? error : new Error(String(error))
      this.logger.error('Failed to render watermark', error)

      const result: WatermarkRenderResult = {
        success: false,
        error: renderError,
        renderTime: Date.now() - startTime
      }

      return result
    }
  }

  /**
   * 获取模板
   */
  private getTemplate(type: WatermarkTemplateType): WatermarkTemplate {
    const template = this.predefinedTemplates.find(t => t.type === type)
    if (!template) {
      throw new Error(`Template not found for type: ${type}`)
    }
    return template
  }

  /**
   * 生成HTML内容
   */
  private generateHtmlContent(
    template: WatermarkTemplate,
    data: WatermarkData,
    config: WatermarkConfig
  ): string {
    let html = template.template

    // 替换字段占位符
    html = this.replaceFieldPlaceholders(html, data)

    // 应用样式
    html = this.applyStyles(html, config)

    return html
  }

  /**
   * 替换字段占位符
   */
  private replaceFieldPlaceholders(html: string, data: WatermarkData): string {
    // 项目名称
    html = html.replace(/\{\{projectName\}\}/g, data.projectName || '未指定项目')

    // 工点名称
    html = html.replace(/\{\{siteName\}\}/g, data.siteName || '未指定工点')

    // 日期时间
    if (data.dateTime) {
      const dateTimeStr = this.formatDateTime(data.dateTime)
      html = html.replace(/\{\{dateTime\}\}/g, dateTimeStr)
    } else {
      html = html.replace(/\{\{dateTime\}\}/g, this.formatDateTime(new Date()))
    }

    // 位置信息
    if (data.location) {
      const locationStr = this.formatLocation(data.location)
      html = html.replace(/\{\{location\}\}/g, locationStr)
    } else {
      html = html.replace(/\{\{location\}\}/g, '位置信息不可用')
    }

    // 天气信息
    if (data.weather) {
      const weatherStr = `${data.weather.temperature}°C ${data.weather.condition}`
      html = html.replace(/\{\{weather\}\}/g, weatherStr)
    } else {
      html = html.replace(/\{\{weather\}\}/g, '天气信息不可用')
    }

    // 相机设置
    if (data.cameraSettings) {
      const cameraStr = `${data.cameraSettings.model} ${data.cameraSettings.focalLength} f/${data.cameraSettings.aperture} ISO${data.cameraSettings.iso} ${data.cameraSettings.shutterSpeed}`
      html = html.replace(/\{\{cameraSettings\}\}/g, cameraStr)
    } else {
      html = html.replace(/\{\{cameraSettings\}\}/g, '相机信息不可用')
    }

    // 公司名称
    html = html.replace(/\{\{companyName\}\}/g, data.companyName || '')

    // 描述
    html = html.replace(/\{\{description\}\}/g, data.description || '')

    // 自定义字段
    if (data.customFields) {
      for (const [key, value] of Object.entries(data.customFields)) {
        const placeholder = `{{${key}}}`
        html = html.replace(new RegExp(placeholder, 'g'), value)
      }
    }

    return html
  }

  /**
   * 应用样式
   */
  private applyStyles(html: string, config: WatermarkConfig): string {
    const style = `
      position: absolute;
      ${this.getPositionStyle(config.position)};
      background-color: ${config.backgroundColor};
      color: ${config.textColor};
      font-size: ${config.fontSize}px;
      font-family: ${config.fontFamily};
      opacity: ${config.opacity};
      border-radius: ${config.borderRadius}px;
      padding: ${config.padding}px;
      margin: ${config.margin}px;
      max-width: ${config.maxWidth}px;
      word-wrap: break-word;
    `

    return html.replace('{{style}}', style)
  }

  /**
   * 获取位置样式
   */
  private getPositionStyle(position: WatermarkPosition): string {
    switch (position) {
      case WatermarkPosition.TOP_LEFT:
        return 'top: 0; left: 0;'
      case WatermarkPosition.TOP_RIGHT:
        return 'top: 0; right: 0;'
      case WatermarkPosition.BOTTOM_LEFT:
        return 'bottom: 0; left: 0;'
      case WatermarkPosition.BOTTOM_RIGHT:
        return 'bottom: 0; right: 0;'
      case WatermarkPosition.CENTER:
        return 'top: 50%; left: 50%; transform: translate(-50%, -50%);'
      default:
        return 'bottom: 0; right: 0;'
    }
  }

  /**
   * 渲染HTML到图像
   */
  private async renderHtmlToImage(
    originalImage: image.PixelMap,
    htmlContent: string,
    config: WatermarkConfig
  ): Promise<image.PixelMap> {
    // 这里需要实现HTML到图像的渲染
    // 由于HarmonyOS的限制，这里返回原始图像作为占位符
    // 在实际实现中，需要使用Canvas或其他渲染方式

    this.logger.info('Rendering HTML to image...')

    // 模拟渲染过程
    await new Promise(resolve => setTimeout(resolve, 100))

    return originalImage
  }

  /**
   * 格式化日期时间
   */
  private formatDateTime(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    const seconds = String(date.getSeconds()).padStart(2, '0')

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
  }

  /**
   * 格式化位置信息
   */
  private formatLocation(location: LocationData): string {
    const lat = Math.abs(location.latitude).toFixed(6)
    const lng = Math.abs(location.longitude).toFixed(6)
    const latDir = location.latitude >= 0 ? 'N' : 'S'
    const lngDir = location.longitude >= 0 ? 'E' : 'W'

    return `${lat}°${latDir} ${lng}°${lngDir}`
  }

  /**
   * 获取工程模板
   */
  private getEngineeringTemplate(): string {
    return `
      <div style="{{style}}">
        <div style="font-weight: bold; margin-bottom: 4px;">{{projectName}}</div>
        <div style="font-size: 0.9em; margin-bottom: 2px;">{{siteName}}</div>
        <div style="font-size: 0.8em; margin-bottom: 2px;">{{dateTime}}</div>
        <div style="font-size: 0.8em; margin-bottom: 2px;">{{location}}</div>
        <div style="font-size: 0.7em; color: rgba(255,255,255,0.8);">{{companyName}}</div>
      </div>
    `
  }

  /**
   * 获取施工模板
   */
  private getConstructionTemplate(): string {
    return `
      <div style="{{style}}">
        <div style="font-weight: bold; margin-bottom: 4px;">{{projectName}}</div>
        <div style="font-size: 0.9em; margin-bottom: 2px;">{{dateTime}}</div>
        <div style="font-size: 0.8em;">{{location}}</div>
      </div>
    `
  }

  /**
   * 获取质量模板
   */
  private getQualityTemplate(): string {
    return `
      <div style="{{style}}">
        <div style="font-weight: bold; margin-bottom: 4px;">{{projectName}}</div>
        <div style="font-size: 0.9em; margin-bottom: 2px;">{{siteName}}</div>
        <div style="font-size: 0.8em; margin-bottom: 2px;">{{dateTime}}</div>
        <div style="font-size: 0.8em; margin-bottom: 2px;">{{location}}</div>
        <div style="font-size: 0.7em; margin-bottom: 2px;">{{cameraSettings}}</div>
        <div style="font-size: 0.8em; font-style: italic;">{{description}}</div>
      </div>
    `
  }

  /**
   * 创建自定义模板
   */
  createCustomTemplate(
    name: string,
    fields: WatermarkField[],
    template: string,
    config: Partial<WatermarkConfig>
  ): WatermarkTemplate {
    const customTemplate: WatermarkTemplate = {
      id: `custom-${Date.now()}`,
      name,
      type: WatermarkTemplateType.CUSTOM,
      config: { ...this.defaultConfig, ...config },
      fields,
      template
    }

    this.predefinedTemplates.push(customTemplate)
    this.logger.info('Custom template created', { name, id: customTemplate.id })

    return customTemplate
  }

  /**
   * 获取所有可用模板
   */
  getAvailableTemplates(): WatermarkTemplate[] {
    return [...this.predefinedTemplates]
  }

  /**
   * 获取模板详情
   */
  getTemplateById(id: string): WatermarkTemplate | null {
    return this.predefinedTemplates.find(t => t.id === id) || null
  }

  /**
   * 更新模板配置
   */
  updateTemplateConfig(id: string, config: Partial<WatermarkConfig>): boolean {
    const template = this.predefinedTemplates.find(t => t.id === id)
    if (!template) {
      return false
    }

    template.config = { ...template.config, ...config }
    this.logger.info('Template config updated', { id })
    return true
  }

  /**
   * 删除自定义模板
   */
  deleteTemplate(id: string): boolean {
    const index = this.predefinedTemplates.findIndex(t => t.id === id)
    if (index === -1) {
      return false
    }

    const template = this.predefinedTemplates[index]
    if (template.type !== WatermarkTemplateType.CUSTOM) {
      this.logger.warn('Cannot delete predefined template', { id })
      return false
    }

    this.predefinedTemplates.splice(index, 1)
    this.logger.info('Template deleted', { id })
    return true
  }

  /**
   * 预览水印
   */
  async previewWatermark(
    data: WatermarkData,
    config?: Partial<WatermarkConfig>
  ): Promise<string> {
    this.logger.info('Generating watermark preview...')

    try {
      const finalConfig = { ...this.defaultConfig, ...config }
      const template = this.getTemplate(finalConfig.templateType)
      const htmlContent = this.generateHtmlContent(template, data, finalConfig)

      // 生成预览图URL
      // 这里需要实现HTML到预览图的转换
      const previewUrl = `data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`

      return previewUrl
    } catch (error) {
      this.logger.error('Failed to generate watermark preview', error)
      throw error
    }
  }

  /**
   * 验证模板数据
   */
  validateTemplateData(template: WatermarkTemplate, data: WatermarkData): {
    valid: boolean
    missingFields: WatermarkField[]
  } {
    const missingFields: WatermarkField[] = []

    for (const field of template.fields) {
      const hasValue = this.checkFieldValue(field, data)
      if (!hasValue) {
        missingFields.push(field)
      }
    }

    return {
      valid: missingFields.length === 0,
      missingFields
    }
  }

  /**
   * 检查字段值
   */
  private checkFieldValue(field: WatermarkField, data: WatermarkData): boolean {
    switch (field) {
      case WatermarkField.PROJECT_NAME:
        return !!data.projectName
      case WatermarkField.SITE_NAME:
        return !!data.siteName
      case WatermarkField.DATE_TIME:
        return !!data.dateTime
      case WatermarkField.LOCATION:
        return !!data.location
      case WatermarkField.WEATHER:
        return !!data.weather
      case WatermarkField.CAMERA_SETTINGS:
        return !!data.cameraSettings
      case WatermarkField.COMPANY_NAME:
        return !!data.companyName
      case WatermarkField.DESCRIPTION:
        return !!data.description
      default:
        return true
    }
  }

  /**
   * 导出模板
   */
  exportTemplate(id: string): string | null {
    const template = this.getTemplateById(id)
    if (!template) {
      return null
    }

    return JSON.stringify(template, null, 2)
  }

  /**
   * 导入模板
   */
  importTemplate(templateJson: string): WatermarkTemplate | null {
    try {
      const template: WatermarkTemplate = JSON.parse(templateJson)

      // 验证模板结构
      if (!template.id || !template.name || !template.template) {
        throw new Error('Invalid template structure')
      }

      // 确保ID唯一
      template.id = `imported-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
      template.type = WatermarkTemplateType.CUSTOM

      this.predefinedTemplates.push(template)
      this.logger.info('Template imported successfully', { name: template.name })

      return template
    } catch (error) {
      this.logger.error('Failed to import template', error)
      return null
    }
  }

  /**
   * 获取服务统计信息
   */
  getServiceStats(): {
    templateCount: number
    customTemplateCount: number
    supportedFields: WatermarkField[]
    supportedPositions: WatermarkPosition[]
  } {
    return {
      templateCount: this.predefinedTemplates.length,
      customTemplateCount: this.predefinedTemplates.filter(t => t.type === WatermarkTemplateType.CUSTOM).length,
      supportedFields: Object.values(WatermarkField),
      supportedPositions: Object.values(WatermarkPosition)
    }
  }
}