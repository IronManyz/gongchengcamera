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
  @Local config: Record<string, any> = {}

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
      Object.assign(field, updates)
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
    Object.assign(this.style, styleUpdates)
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
  setConfig(key: string, value: any): void {
    this.config[key] = value
    this.updateTimestamp()
  }

  /**
   * 获取配置项
   */
  getConfig(key: string, defaultValue: any = null): any {
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
    cloned.fields = this.fields.map(field => ({ ...field }))
    cloned.style = { ...this.style }
    cloned.preview = this.preview
    cloned.isDefault = false // 克隆的模板不能是默认的
    cloned.isSystem = false // 克隆的模板不是系统的
    cloned.usageCount = 0 // 重置使用次数
    cloned.config = { ...this.config }

    return cloned
  }

  /**
   * 导出为JSON配置
   */
  exportConfig(): Record<string, any> {
    return {
      name: this.name,
      description: this.description,
      category: this.category,
      fields: this.fields,
      style: this.style,
      config: this.config
    }
  }

  /**
   * 从JSON配置导入
   */
  importConfig(config: Record<string, any>): void {
    if (config.name) this.name = config.name
    if (config.description) this.description = config.description
    if (config.category) this.category = config.category
    if (config.fields) this.fields = config.fields
    if (config.style) this.style = { ...this.style, ...config.style }
    if (config.config) this.config = { ...this.config, ...config.config }
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
   * 转换为JSON对象（包含额外字段）
   */
  override toJSON(): Record<string, any> {
    return {
      ...super.toJSON(),
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
  }

  /**
   * 从JSON对象创建实例
   */
  static override fromJSON(data: Record<string, any>): WatermarkTemplate {
    const template = new WatermarkTemplate()

    if (data.id) template.id = data.id
    if (data.createdAt) template.createdAt = new Date(data.createdAt)
    if (data.updatedAt) template.updatedAt = new Date(data.updatedAt)
    if (data.version) template.version = data.version

    if (data.name) template.name = data.name
    if (data.description) template.description = data.description
    if (data.category) template.category = data.category
    if (data.fields) template.fields = data.fields
    if (data.style) template.style = { ...template.style, ...data.style }
    if (data.preview) template.preview = data.preview
    if (data.isDefault) template.isDefault = data.isDefault
    if (data.isSystem) template.isSystem = data.isSystem
    if (data.usageCount) template.usageCount = data.usageCount
    if (data.config) template.config = data.config

    return template
  }

  /**
   * 深度克隆对象
   */
  override clone(): WatermarkTemplate {
    const cloned = super.clone() as WatermarkTemplate
    cloned.fields = this.fields.map(field => ({ ...field }))
    cloned.style = { ...this.style }
    cloned.config = { ...this.config }
    return cloned
  }
}