/**
 * 项目数据模型
 * 用于管理工程项目的基本信息和状态
 */

import { BaseModel } from './base/BaseModel'
import { ProjectStatus } from '../types/AppTypes'
import { Site } from './Site'
import { Photo } from './Photo'

@ObservedV2
export class Project extends BaseModel {
  @Trace name: string = ''
  @Trace code: string = ''
  @Trace client: string = ''
  @Trace manager: string = ''
  @Trace startDate: Date = new Date()
  @Trace endDate: Date = new Date()
  @Trace description: string = ''
  @Trace tags: string[] = []
  @Trace status: ProjectStatus = ProjectStatus.ACTIVE
  @Trace siteCount: number = 0
  @Trace photoCount: number = 0
  @Local metadata: Record<string, any> = {}

  // 关联数据 (通过查询获取，不直接序列化)
  sites: Site[] = []
  photos: Photo[] = []

  constructor() {
    super()
    if (this.id === '') {
      this.id = BaseModel.generateId()
    }
  }

  /**
   * 验证项目数据是否完整
   */
  override isValid(): boolean {
    return super.isValid() &&
           this.name.trim().length > 0
  }

  /**
   * 获取项目持续时间（天数）
   */
  getDurationInDays(): number {
    const diffTime = Math.abs(this.endDate.getTime() - this.startDate.getTime())
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  }

  /**
   * 检查项目是否已过期
   */
  isExpired(): boolean {
    return new Date() > this.endDate
  }

  /**
   * 检查项目是否正在进行中
   */
  isActive(): boolean {
    const now = new Date()
    return this.status === ProjectStatus.ACTIVE &&
           this.startDate <= now &&
           this.endDate >= now
  }

  /**
   * 获取项目进度百分比（基于日期）
   */
  getProgressPercentage(): number {
    const now = new Date()
    const total = this.endDate.getTime() - this.startDate.getTime()
    const elapsed = now.getTime() - this.startDate.getTime()

    if (elapsed <= 0) return 0
    if (elapsed >= total) return 100

    return Math.round((elapsed / total) * 100)
  }

  /**
   * 添加标签
   */
  addTag(tag: string): void {
    if (tag && tag.trim() && !this.tags.includes(tag.trim())) {
      this.tags.push(tag.trim())
      this.updateTimestamp()
    }
  }

  /**
   * 移除标签
   */
  removeTag(tag: string): void {
    const index = this.tags.indexOf(tag)
    if (index > -1) {
      this.tags.splice(index, 1)
      this.updateTimestamp()
    }
  }

  /**
   * 设置项目状态
   */
  setStatus(status: ProjectStatus): void {
    if (this.status !== status) {
      this.status = status
      this.updateTimestamp()
    }
  }

  /**
   * 更新工点数量
   */
  updateSiteCount(count: number): void {
    if (this.siteCount !== count) {
      this.siteCount = count
      this.updateTimestamp()
    }
  }

  /**
   * 更新照片数量
   */
  updatePhotoCount(count: number): void {
    if (this.photoCount !== count) {
      this.photoCount = count
      this.updateTimestamp()
    }
  }

  /**
   * 设置元数据
   */
  setMetadata(key: string, value: any): void {
    this.metadata[key] = value
    this.updateTimestamp()
  }

  /**
   * 获取元数据
   */
  getMetadata(key: string, defaultValue: any = null): any {
    return this.metadata[key] ?? defaultValue
  }

  /**
   * 搜索项目内容
   */
  matchesSearch(query: string): boolean {
    if (!query) return true

    const lowercaseQuery = query.toLowerCase()
    return this.name.toLowerCase().includes(lowercaseQuery) ||
           this.code.toLowerCase().includes(lowercaseQuery) ||
           this.client.toLowerCase().includes(lowercaseQuery) ||
           this.manager.toLowerCase().includes(lowercaseQuery) ||
           this.description.toLowerCase().includes(lowercaseQuery) ||
           this.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery))
  }

  /**
   * 获取项目显示名称
   */
  getDisplayName(): string {
    return this.name || this.code || '未命名项目'
  }

  /**
   * 获取项目状态显示文本
   */
  getStatusText(): string {
    switch (this.status) {
      case ProjectStatus.ACTIVE:
        return '进行中'
      case ProjectStatus.COMPLETED:
        return '已完成'
      case ProjectStatus.PAUSED:
        return '已暂停'
      case ProjectStatus.CANCELLED:
        return '已取消'
      default:
        return '未知状态'
    }
  }

  /**
   * 转换为JSON对象（包含额外字段）
   */
  override toJSON(): Record<string, any> {
    return {
      ...super.toJSON(),
      name: this.name,
      code: this.code,
      client: this.client,
      manager: this.manager,
      startDate: this.startDate.getTime(),
      endDate: this.endDate.getTime(),
      description: this.description,
      tags: this.tags,
      status: this.status,
      siteCount: this.siteCount,
      photoCount: this.photoCount,
      metadata: this.metadata
    }
  }

  /**
   * 从JSON对象创建实例
   */
  static override fromJSON(data: Record<string, any>): Project {
    const project = new Project()

    if (data.id) project.id = data.id
    if (data.createdAt) project.createdAt = new Date(data.createdAt)
    if (data.updatedAt) project.updatedAt = new Date(data.updatedAt)
    if (data.version) project.version = data.version

    if (data.name) project.name = data.name
    if (data.code) project.code = data.code
    if (data.client) project.client = data.client
    if (data.manager) project.manager = data.manager
    if (data.startDate) project.startDate = new Date(data.startDate)
    if (data.endDate) project.endDate = new Date(data.endDate)
    if (data.description) project.description = data.description
    if (data.tags) project.tags = data.tags
    if (data.status) project.status = data.status
    if (data.siteCount) project.siteCount = data.siteCount
    if (data.photoCount) project.photoCount = data.photoCount
    if (data.metadata) project.metadata = data.metadata

    return project
  }

  /**
   * 深度克隆对象
   */
  override clone(): Project {
    const cloned = super.clone() as Project
    cloned.startDate = new Date(this.startDate)
    cloned.endDate = new Date(this.endDate)
    cloned.tags = [...this.tags]
    cloned.metadata = { ...this.metadata }
    return cloned
  }
}