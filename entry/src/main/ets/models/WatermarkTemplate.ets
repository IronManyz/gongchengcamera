/**
 * 水印模板数据模型
 * 用于管理水印模板的配置和样式
 */

import { BaseModel } from './base/BaseModel'
import { TemplateCategory, WatermarkField, WatermarkStyle } from '../types/AppTypes'

@ObservedV2
export class WatermarkTemplate extends BaseModel {
  @Trace name: string = ''
  @Trace description: string = ''
  @Trace category: TemplateCategory = TemplateCategory.CUSTOM
  @Trace fields: WatermarkField[] = []
  @Trace style: WatermarkStyle = {}
  @Trace preview: string = ''
  @Trace isDefault: boolean = false
  @Trace isSystem: boolean = false
  @Trace usageCount: number = 0
  @Local config: Record<string, string | number | boolean> = {}

  constructor() {
    super()
    if (this.id === '') {
      this.id = BaseModel.generateId()
    }
    this.initializeDefaultStyle()
  }

  /**
   * 初始化默认样式
   */
  private initializeDefaultStyle(): void {
    this.style = {
      backgroundColor: 'rgba(0, 0, 0, 0.7)',
      textColor: '#FFFFFF',
      fontSize: 14,
      fontFamily: 'HarmonyOS Sans',
      opacity: 0.9,
      borderRadius: 8,
      padding: 12,
      position: 'bottom-right'
    }
  }

  /**
   * 验证模板数据是否完整
   */
  override isValid(): boolean {
    return super.isValid() &&
           this.name.trim().length > 0 &&
           this.fields.length > 0
  }

  /**
   * 添加水印字段
   */
  addField(field: WatermarkField): void {
    if (field && field.key && !this.fields.find(f => f.key === field.key)) {
      this.fields.push(field)
      this.updateTimestamp()
    }
  }

  /**
   * 移除水印字段
   */
  removeField(fieldKey: string): void {
    const index = this.fields.findIndex(f => f.key === fieldKey)
    if (index > -1) {
      this.fields.splice(index, 1)
      this.updateTimestamp()
    }
  }

  /**
   * 更新水印字段
   */
  updateField(fieldKey: string, updates: Partial<WatermarkField>): void {
    const field = this.fields.find(f => f.key === fieldKey)
    if (field) {
      if (updates.key !== undefined) field.key = updates.key
      if (updates.label !== undefined) field.label = updates.label
      if (updates.enabled !== undefined) field.enabled = updates.enabled
      if (updates.format !== undefined) field.format = updates.format
      if (updates.position !== undefined) field.position = updates.position
      this.updateTimestamp()
    }
  }

  /**
   * 获取启用的字段
   */
  getEnabledFields(): WatermarkField[] {
    return this.fields.filter(field => field.enabled)
  }

  /**
   * 设置字段启用状态
   */
  setFieldEnabled(fieldKey: string, enabled: boolean): void {
    const field = this.fields.find(f => f.key === fieldKey)
    if (field && field.enabled !== enabled) {
      field.enabled = enabled
      this.updateTimestamp()
    }
  }

  /**
   * 更新样式
   */
  updateStyle(styleUpdates: Partial<WatermarkStyle>): void {
    if (styleUpdates.backgroundColor !== undefined) this.style.backgroundColor = styleUpdates.backgroundColor
    if (styleUpdates.textColor !== undefined) this.style.textColor = styleUpdates.textColor
    if (styleUpdates.fontSize !== undefined) this.style.fontSize = styleUpdates.fontSize
    if (styleUpdates.fontFamily !== undefined) this.style.fontFamily = styleUpdates.fontFamily
    if (styleUpdates.opacity !== undefined) this.style.opacity = styleUpdates.opacity
    if (styleUpdates.borderRadius !== undefined) this.style.borderRadius = styleUpdates.borderRadius
    if (styleUpdates.padding !== undefined) this.style.padding = styleUpdates.padding
    if (styleUpdates.position !== undefined) this.style.position = styleUpdates.position
    this.updateTimestamp()
  }

  /**
   * 设置模板为默认
   */
  setDefault(isDefault: boolean): void {
    if (this.isDefault !== isDefault) {
      this.isDefault = isDefault
      this.updateTimestamp()
    }
  }

  /**
   * 增加使用次数
   */
  incrementUsage(): void {
    this.usageCount++
    this.updateTimestamp()
  }

  /**
   * 重置使用次数
   */
  resetUsageCount(): void {
    if (this.usageCount !== 0) {
      this.usageCount = 0
      this.updateTimestamp()
    }
  }

  /**
   * 设置配置项
   */
  setConfig(key: string, value: string | number | boolean): void {
    this.config[key] = value
    this.updateTimestamp()
  }

  /**
   * 获取配置项
   */
  getConfig(key: string, defaultValue: string | number | boolean | null = null): string | number | boolean | null {
    return this.config[key] ?? defaultValue
  }

  /**
   * 获取分类显示文本
   */
  getCategoryText(): string {
    switch (this.category) {
      case TemplateCategory.SYSTEM:
        return '系统模板'
      case TemplateCategory.CONSTRUCTION:
        return '工程施工'
      case TemplateCategory.QUALITY:
        return '质量检查'
      case TemplateCategory.SAFETY:
        return '安全管理'
      case TemplateCategory.CUSTOM:
        return '自定义'
      default:
        return '未知分类'
    }
  }

  /**
   * 获取模板显示名称
   */
  getDisplayName(): string {
    return this.name || '未命名模板'
  }

  /**
   * 检查是否为系统模板
   */
  isSystemTemplate(): boolean {
    return this.isSystem || this.category === TemplateCategory.SYSTEM
  }

  /**
   * 检查是否可以编辑
   */
  isEditable(): boolean {
    return !this.isSystemTemplate()
  }

  /**
   * 检查是否可以删除
   */
  isDeletable(): boolean {
    return !this.isSystemTemplate() && !this.isDefault
  }

  /**
   * 克隆模板（用于创建副本）
   */
  clone(name?: string): WatermarkTemplate {
    const cloned = new WatermarkTemplate()

    cloned.name = name || `${this.name} 副本`
    cloned.description = this.description
    cloned.category = TemplateCategory.CUSTOM // 克隆的模板总是自定义的

    // Clone fields manually without spread operator
    cloned.fields = []
    for (const field of this.fields) {
      const clonedField: WatermarkField = {
        key: field.key,
        label: field.label,
        enabled: field.enabled,
        format: field.format,
        position: field.position
      }
      cloned.fields.push(clonedField)
    }

    // Clone style manually without spread operator
    cloned.style = {
      backgroundColor: this.style.backgroundColor,
      textColor: this.style.textColor,
      fontSize: this.style.fontSize,
      fontFamily: this.style.fontFamily,
      opacity: this.style.opacity,
      borderRadius: this.style.borderRadius,
      padding: this.style.padding,
      position: this.style.position
    }

    cloned.preview = this.preview
    cloned.isDefault = false // 克隆的模板不能是默认的
    cloned.isSystem = false // 克隆的模板不是系统的
    cloned.usageCount = 0 // 重置使用次数

    // Clone config manually without spread operator
    cloned.config = {}
    const configKeys = Object.keys(this.config) as string[]
    for (let i = 0; i < configKeys.length; i++) {
      const key = configKeys[i]
      cloned.config[key] = this.config[key]
    }

    return cloned
  }

  /**
   * 导出配置接口
   */
  interface ExportConfig {
    name: string
    description: string
    category: TemplateCategory
    fields: WatermarkField[]
    style: WatermarkStyle
    config: Record<string, string | number | boolean>
  }

  /**
   * 导出为JSON配置
   */
  exportConfig(): ExportConfig {
    const config: ExportConfig = {
      name: this.name,
      description: this.description,
      category: this.category,
      fields: this.fields,
      style: this.style,
      config: this.config
    }
    return config
  }

  /**
   * 从JSON配置导入
   */
  importConfig(config: ExportConfig): void {
    if (config.name) this.name = config.name
    if (config.description) this.description = config.description
    if (config.category) this.category = config.category
    if (config.fields) this.fields = config.fields
    if (config.style) {
      const styleConfig = config.style
      if (styleConfig.backgroundColor !== undefined) this.style.backgroundColor = styleConfig.backgroundColor
      if (styleConfig.textColor !== undefined) this.style.textColor = styleConfig.textColor
      if (styleConfig.fontSize !== undefined) this.style.fontSize = styleConfig.fontSize
      if (styleConfig.fontFamily !== undefined) this.style.fontFamily = styleConfig.fontFamily
      if (styleConfig.opacity !== undefined) this.style.opacity = styleConfig.opacity
      if (styleConfig.borderRadius !== undefined) this.style.borderRadius = styleConfig.borderRadius
      if (styleConfig.padding !== undefined) this.style.padding = styleConfig.padding
      if (styleConfig.position !== undefined) this.style.position = styleConfig.position
    }
    if (config.config) {
      const configConfig = config.config
      const configKeys = Object.keys(configConfig)
      for (let i = 0; i < configKeys.length; i++) {
        const key = configKeys[i]
        this.config[key] = configConfig[key]
      }
    }
    this.updateTimestamp()
  }

  /**
   * 搜索模板内容
   */
  matchesSearch(query: string): boolean {
    if (!query) return true

    const lowercaseQuery = query.toLowerCase()
    return this.name.toLowerCase().includes(lowercaseQuery) ||
           this.description.toLowerCase().includes(lowercaseQuery) ||
           this.getCategoryText().toLowerCase().includes(lowercaseQuery) ||
           this.fields.some(field => field.label.toLowerCase().includes(lowercaseQuery))
  }

  /**
   * JSON数据接口
   */
  interface WatermarkTemplateJSON {
    id: string
    createdAt: Date | null
    updatedAt: Date | null
    version: number
    name: string
    description: string
    category: TemplateCategory
    fields: WatermarkField[]
    style: WatermarkStyle
    preview: string
    isDefault: boolean
    isSystem: boolean
    usageCount: number
    config: Record<string, string | number | boolean>
  }

  /**
   * 转换为JSON对象（包含额外字段）
   */
  override toJSON(): WatermarkTemplateJSON {
    const baseData = super.toJSON()
    const jsonData: WatermarkTemplateJSON = {
      id: baseData.id,
      createdAt: baseData.createdAt,
      updatedAt: baseData.updatedAt,
      version: baseData.version,
      name: this.name,
      description: this.description,
      category: this.category,
      fields: this.fields,
      style: this.style,
      preview: this.preview,
      isDefault: this.isDefault,
      isSystem: this.isSystem,
      usageCount: this.usageCount,
      config: this.config
    }
    return jsonData
  }

  /**
   * 从JSON对象创建实例
   */
  static override fromJSON(data: WatermarkTemplateJSON): WatermarkTemplate {
    const template = new WatermarkTemplate()

    if (data.id) template.id = data.id
    if (data.createdAt) template.createdAt = new Date(data.createdAt)
    if (data.updatedAt) template.updatedAt = new Date(data.updatedAt)
    if (data.version) template.version = data.version

    if (data.name) template.name = data.name
    if (data.description) template.description = data.description
    if (data.category) template.category = data.category
    if (data.fields) template.fields = data.fields
    if (data.style) {
      const styleData = data.style
      if (styleData.backgroundColor !== undefined) template.style.backgroundColor = styleData.backgroundColor
      if (styleData.textColor !== undefined) template.style.textColor = styleData.textColor
      if (styleData.fontSize !== undefined) template.style.fontSize = styleData.fontSize
      if (styleData.fontFamily !== undefined) template.style.fontFamily = styleData.fontFamily
      if (styleData.opacity !== undefined) template.style.opacity = styleData.opacity
      if (styleData.borderRadius !== undefined) template.style.borderRadius = styleData.borderRadius
      if (styleData.padding !== undefined) template.style.padding = styleData.padding
      if (styleData.position !== undefined) template.style.position = styleData.position
    }
    if (data.preview) template.preview = data.preview
    if (data.isDefault) template.isDefault = data.isDefault
    if (data.isSystem) template.isSystem = data.isSystem
    if (data.usageCount) template.usageCount = data.usageCount
    if (data.config) {
      const configData = data.config
      const configKeys = Object.keys(configData)
      for (let i = 0; i < configKeys.length; i++) {
        const key = configKeys[i]
        template.config[key] = configData[key]
      }
    }

    return template
  }

  /**
   * 深度克隆对象
   */
  override clone(): WatermarkTemplate {
    const cloned = new WatermarkTemplate()

    cloned.id = this.id
    cloned.createdAt = new Date(this.createdAt)
    cloned.updatedAt = new Date(this.updatedAt)
    cloned.version = this.version
    cloned.name = this.name
    cloned.description = this.description
    cloned.category = this.category
    cloned.preview = this.preview
    cloned.isDefault = this.isDefault
    cloned.isSystem = this.isSystem
    cloned.usageCount = this.usageCount

    // Clone fields manually
    cloned.fields = []
    for (const field of this.fields) {
      const clonedField: WatermarkField = {
        key: field.key,
        label: field.label,
        enabled: field.enabled,
        format: field.format,
        position: field.position
      }
      cloned.fields.push(clonedField)
    }

    // Clone style manually
    cloned.style = {
      backgroundColor: this.style.backgroundColor,
      textColor: this.style.textColor,
      fontSize: this.style.fontSize,
      fontFamily: this.style.fontFamily,
      opacity: this.style.opacity,
      borderRadius: this.style.borderRadius,
      padding: this.style.padding,
      position: this.style.position
    }

    // Clone config manually
    cloned.config = {}
    const configKeys = Object.keys(this.config) as string[]
    for (let i = 0; i < configKeys.length; i++) {
      const key = configKeys[i]
      cloned.config[key] = this.config[key]
    }

    return cloned
  }
}