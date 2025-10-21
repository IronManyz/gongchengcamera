/**
 * 工点数据模型
 * 用于管理工程项目的施工地点信息
 */

import { BaseModel } from './base/BaseModel'
import { LocationData } from '../types/AppTypes'
import { Photo } from './Photo'
import { Project } from './Project'

@ObservedV2
export class Site extends BaseModel {
  @Trace projectId: string = ''
  @Trace name: string = ''
  @Trace address: string = ''
  @Trace latitude: number = 0
  @Trace longitude: number = 0
  @Trace altitude: number = 0
  @Trace description: string = ''
  @Trace tags: string[] = []
  @Trace photoCount: number = 0
  @Local locationData: LocationData | null = null

  // 关联数据 (通过查询获取，不直接序列化)
  project: Project | null = null
  photos: Photo[] = []

  constructor() {
    super()
    if (this.id === '') {
      this.id = BaseModel.generateId()
    }
  }

  /**
   * 验证工点数据是否完整
   */
  override isValid(): boolean {
    return super.isValid() &&
           this.projectId.trim().length > 0 &&
           this.name.trim().length > 0
  }

  /**
   * 检查是否有有效位置信息
   */
  hasValidLocation(): boolean {
    return this.latitude !== 0 || this.longitude !== 0
  }

  /**
   * 获取完整地址信息
   */
  getFullAddress(): string {
    if (this.address) {
      return this.address
    }

    if (this.locationData) {
      const parts = [
        this.locationData.province,
        this.locationData.city,
        this.locationData.district,
        this.locationData.street
      ].filter(Boolean)

      return parts.join(' ') || '位置信息不完整'
    }

    return '暂无地址信息'
  }

  /**
   * 计算与另一个位置的距离（米）
   */
  distanceTo(otherLat: number, otherLng: number): number {
    if (!this.hasValidLocation()) {
      return Infinity
    }

    const R = 6371e3 // 地球半径（米）
    const φ1 = this.latitude * Math.PI / 180
    const φ2 = otherLat * Math.PI / 180
    const Δφ = (otherLat - this.latitude) * Math.PI / 180
    const Δλ = (otherLng - this.longitude) * Math.PI / 180

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    return R * c
  }

  /**
   * 获取距离显示文本
   */
  getDistanceText(otherLat: number, otherLng: number): string {
    const distance = this.distanceTo(otherLat, otherLng)

    if (distance === Infinity) {
      return '位置未知'
    } else if (distance < 1000) {
      return `${Math.round(distance)}米`
    } else {
      return `${(distance / 1000).toFixed(1)}公里`
    }
  }

  /**
   * 更新位置数据
   */
  updateLocation(lat: number, lng: number, alt?: number): void {
    this.latitude = lat
    this.longitude = lng
    if (alt !== undefined) {
      this.altitude = alt
    }
    this.updateTimestamp()
  }

  /**
   * 设置详细位置数据
   */
  setLocationData(locationData: LocationData): void {
    this.locationData = locationData
    this.updateTimestamp()
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
   * 更新照片数量
   */
  updatePhotoCount(count: number): void {
    if (this.photoCount !== count) {
      this.photoCount = count
      this.updateTimestamp()
    }
  }

  /**
   * 搜索工点内容
   */
  matchesSearch(query: string): boolean {
    if (!query) return true

    const lowercaseQuery = query.toLowerCase()
    return this.name.toLowerCase().includes(lowercaseQuery) ||
           this.address.toLowerCase().includes(lowercaseQuery) ||
           this.description.toLowerCase().includes(lowercaseQuery) ||
           this.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery)) ||
           (this.locationData && (
             this.locationData.city.toLowerCase().includes(lowercaseQuery) ||
             this.locationData.district.toLowerCase().includes(lowercaseQuery) ||
             this.locationData.street.toLowerCase().includes(lowercaseQuery)
           ))
  }

  /**
   * 获取工点显示名称
   */
  getDisplayName(): string {
    return this.name || '未命名工点'
  }

  /**
   * 获取位置坐标显示文本
   */
  getCoordinateText(): string {
    if (!this.hasValidLocation()) {
      return '无坐标信息'
    }

    const lat = Math.abs(this.latitude).toFixed(6)
    const lng = Math.abs(this.longitude).toFixed(6)
    const latDir = this.latitude >= 0 ? 'N' : 'S'
    const lngDir = this.longitude >= 0 ? 'E' : 'W'

    return `${lat}°${latDir}, ${lng}°${lngDir}`
  }

  /**
   * 转换为JSON对象（包含额外字段）
   */
  override toJSON(): Record<string, any> {
    return {
      ...super.toJSON(),
      projectId: this.projectId,
      name: this.name,
      address: this.address,
      latitude: this.latitude,
      longitude: this.longitude,
      altitude: this.altitude,
      description: this.description,
      tags: this.tags,
      photoCount: this.photoCount,
      locationData: this.locationData
    }
  }

  /**
   * 从JSON对象创建实例
   */
  static override fromJSON(data: Record<string, any>): Site {
    const site = new Site()

    if (data.id) site.id = data.id
    if (data.createdAt) site.createdAt = new Date(data.createdAt)
    if (data.updatedAt) site.updatedAt = new Date(data.updatedAt)
    if (data.version) site.version = data.version

    if (data.projectId) site.projectId = data.projectId
    if (data.name) site.name = data.name
    if (data.address) site.address = data.address
    if (data.latitude) site.latitude = data.latitude
    if (data.longitude) site.longitude = data.longitude
    if (data.altitude) site.altitude = data.altitude
    if (data.description) site.description = data.description
    if (data.tags) site.tags = data.tags
    if (data.photoCount) site.photoCount = data.photoCount
    if (data.locationData) site.locationData = data.locationData

    return site
  }

  /**
   * 深度克隆对象
   */
  override clone(): Site {
    const cloned = super.clone() as Site
    cloned.tags = [...this.tags]
    cloned.locationData = this.locationData ? { ...this.locationData } : null
    return cloned
  }
}