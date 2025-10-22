/**
 * 简单工点模型
 * 用于项目中的工点/工地管理
 */

import { LocationData, WeatherInfo } from '../types/AppTypes'

@ObservedV2
export class SimpleSite {
  @Trace id: string = ''
  @Trace projectId: string = ''
  @Trace name: string = ''
  @Trace description: string = ''
  @Trace address: string = ''
  @Trace latitude: number = 0
  @Trace longitude: number = 0
  @Trace altitude: number = 0
  @Trace photoCount: number = 0
  @Trace lastPhotoTime: Date = new Date()
  @Trace tags: string[] = []
  @Trace locationData: LocationData | null = null
  @Trace createdAt: Date = new Date()
  @Trace updatedAt: Date = new Date()

  constructor(id?: string, name?: string, projectId?: string) {
    if (id) this.id = id
    if (name) this.name = name
    if (projectId) this.projectId = projectId
    if (!this.id) this.id = Date.now().toString()
  }

  /**
   * 获取工点显示名称
   */
  getDisplayName(): string {
    return this.name || '未命名工点'
  }

  /**
   * 获取工点完整地址
   */
  getFullAddress(): string {
    if (this.address) return this.address

    if (this.locationData) {
      const parts: string[] = []
      if (this.locationData.district) parts.push(this.locationData.district)
      if (this.locationData.city) parts.push(this.locationData.city)
      if (this.locationData.province) parts.push(this.locationData.province)
      return parts.join('')
    }

    return '位置未设置'
  }

  /**
   * 获取位置坐标字符串
   */
  getCoordinatesString(): string {
    if (this.latitude === 0 && this.longitude === 0) {
      return '位置未设置'
    }
    return `${this.latitude.toFixed(6)}, ${this.longitude.toFixed(6)}`
  }

  /**
   * 获取最后更新时间描述
   */
  getLastUpdateTime(): string {
    const now = new Date()
    const diff = now.getTime() - this.lastPhotoTime.getTime()
    const minutes = Math.floor(diff / (1000 * 60))
    const hours = Math.floor(minutes / 60)
    const days = Math.floor(hours / 24)

    if (minutes < 1) return '刚刚'
    if (minutes < 60) return `${minutes}分钟前`
    if (hours < 24) return `${hours}小时前`
    if (days < 30) return `${days}天前`

    return this.lastPhotoTime.toLocaleDateString()
  }

  /**
   * 检查是否有位置信息
   */
  hasLocation(): boolean {
    return this.latitude !== 0 || this.longitude !== 0
  }

  /**
   * 检查是否有照片
   */
  hasPhotos(): boolean {
    return this.photoCount > 0
  }

  /**
   * 获取状态描述
   */
  getStatusText(): string {
    if (this.photoCount === 0) return '暂无照片'
    if (this.photoCount < 10) return '照片较少'
    return '照片充足'
  }

  /**
   * 获取状态颜色
   */
  getStatusColor(): string {
    if (this.photoCount === 0) return '#8C8C8C'
    if (this.photoCount < 10) return '#FAAD14'
    return '#52C41A'
  }

  /**
   * 设置位置信息
   */
  setLocation(latitude: number, longitude: number, altitude?: number): void {
    this.latitude = latitude
    this.longitude = longitude
    if (altitude !== undefined) {
      this.altitude = altitude
    }
    this.updatedAt = new Date()
  }

  /**
   * 设置地址信息
   */
  setAddress(address: string, locationData?: LocationData): void {
    this.address = address
    if (locationData) {
      this.locationData = locationData
    }
    this.updatedAt = new Date()
  }

  /**
   * 增加照片数量
   */
  incrementPhotoCount(): void {
    this.photoCount++
    this.lastPhotoTime = new Date()
    this.updatedAt = new Date()
  }

  /**
   * 减少照片数量
   */
  decrementPhotoCount(): void {
    if (this.photoCount > 0) {
      this.photoCount--
      this.updatedAt = new Date()
    }
  }

  /**
   * 添加标签
   */
  addTag(tag: string): void {
    if (tag && !this.tags.includes(tag)) {
      this.tags.push(tag)
      this.updatedAt = new Date()
    }
  }

  /**
   * 移除标签
   */
  removeTag(tag: string): void {
    const index = this.tags.indexOf(tag)
    if (index > -1) {
      this.tags.splice(index, 1)
      this.updatedAt = new Date()
    }
  }

  /**
   * 检查是否包含指定标签
   */
  hasTag(tag: string): boolean {
    return this.tags.includes(tag)
  }
}