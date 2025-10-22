/**
 * 照片数据模型
 * 用于管理工程照片的完整信息和元数据
 */

import { BaseModel } from './base/BaseModel'
import { WeatherInfo, Annotation, ExifData, BaseModelJSON, PhotoJSON } from '../types/AppTypes'
import { Project } from './Project'
import { Site } from './Site'
import { WatermarkTemplate } from './WatermarkTemplate'

@ObservedV2
export class Photo extends BaseModel {
  @Trace projectId: string = ''
  @Trace siteId: string = ''
  @Trace filePath: string = ''
  @Trace thumbnailPath: string = ''
  @Trace takenAt: Date = new Date()
  @Trace latitude: number = 0
  @Trace longitude: number = 0
  @Trace altitude: number = 0
  @Trace azimuth: number = 0
  @Trace address: string = ''
  @Trace weather: WeatherInfo | null = null
  @Trace templateId: string = ''
  @Trace notes: string = ''
  @Trace tags: string[] = []
  @Trace fileSize: number = 0
  @Trace width: number = 0
  @Trace height: number = 0
  @Trace edited: boolean = false
  @Local exifData: ExifData = new ExifData()
  @Local annotations: Annotation[] = []

  // 关联数据 (通过查询获取，不直接序列化)
  project: Project | null = null
  site: Site | null = null
  watermarkTemplate: WatermarkTemplate | null = null

  constructor() {
    super()
    if (this.id === '') {
      this.id = BaseModel.generateId()
    }
  }

  /**
   * 验证照片数据是否完整
   */
  override isValid(): boolean {
    return super.isValid() &&
           this.projectId.trim().length > 0 &&
           this.siteId.trim().length > 0 &&
           this.filePath.trim().length > 0
  }

  /**
   * 检查是否有有效位置信息
   */
  hasValidLocation(): boolean {
    return this.latitude !== 0 || this.longitude !== 0
  }

  /**
   * 检查是否有缩略图
   */
  hasThumbnail(): boolean {
    return this.thumbnailPath.trim().length > 0
  }

  /**
   * 获取照片尺寸描述
   */
  getDimensions(): string {
    if (this.width > 0 && this.height > 0) {
      return `${this.width} × ${this.height}`
    }
    return '尺寸未知'
  }

  /**
   * 获取文件大小描述
   */
  getFileSizeText(): string {
    if (this.fileSize <= 0) {
      return '大小未知'
    }

    const units = ['B', 'KB', 'MB', 'GB']
    let size = this.fileSize
    let unitIndex = 0

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024
      unitIndex++
    }

    return `${size.toFixed(1)} ${units[unitIndex]}`
  }

  /**
   * 获取宽高比
   */
  getAspectRatio(): number {
    if (this.height > 0) {
      return this.width / this.height
    }
    return 0
  }

  /**
   * 检查是否为横向照片
   */
  isLandscape(): boolean {
    return this.getAspectRatio() > 1
  }

  /**
   * 检查是否为纵向照片
   */
  isPortrait(): boolean {
    return this.getAspectRatio() < 1
  }

  /**
   * 获取位置坐标显示文本
   */
  getCoordinateText(): string {
    if (!this.hasValidLocation()) {
      return '无位置信息'
    }

    const lat = Math.abs(this.latitude).toFixed(6)
    const lng = Math.abs(this.longitude).toFixed(6)
    const latDir = this.latitude >= 0 ? 'N' : 'S'
    const lngDir = this.longitude >= 0 ? 'E' : 'W'

    return `${lat}°${latDir}, ${lng}°${lngDir}`
  }

  /**
   * 获取天气显示文本
   */
  getWeatherText(): string {
    if (!this.weather) {
      return '无天气信息'
    }

    const parts: string[] = []
    if (this.weather.temperature) {
      parts.push(`${this.weather.temperature}°C`)
    }
    if (this.weather.humidity) {
      parts.push(`${this.weather.humidity}%`)
    }
    if (this.weather.condition) {
      parts.push(this.weather.condition)
    }

    return parts.join(' · ') || '无详细天气信息'
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
   * 添加标注
   */
  addAnnotation(annotation: Annotation): void {
    if (annotation && annotation.id) {
      // 移除同ID的标注
      this.annotations = this.annotations.filter(a => a.id !== annotation.id)
      this.annotations.push(annotation)
      this.updateTimestamp()
    }
  }

  /**
   * 移除标注
   */
  removeAnnotation(annotationId: string): void {
    const index = this.annotations.findIndex(a => a.id === annotationId)
    if (index > -1) {
      this.annotations.splice(index, 1)
      this.updateTimestamp()
    }
  }

  /**
   * 清空所有标注
   */
  clearAnnotations(): void {
    if (this.annotations.length > 0) {
      this.annotations = []
      this.updateTimestamp()
    }
  }

  /**
   * 设置编辑状态
   */
  setEdited(edited: boolean): void {
    if (this.edited !== edited) {
      this.edited = edited
      this.updateTimestamp()
    }
  }

  /**
   * 设置EXIF数据
   */
  setExifData(key: string, value: string | number | boolean | null): void {
    this.exifData.set(key, value)
    this.updateTimestamp()
  }

  /**
   * 获取EXIF数据
   */
  getExifData(key: string, defaultValue: string | number | boolean | null = null): string | number | boolean | null {
    const value = this.exifData.get(key)
    return value !== null ? value : defaultValue
  }

  /**
   * 搜索照片内容
   */
  matchesSearch(query: string): boolean {
    if (!query) return true

    const lowercaseQuery = query.toLowerCase()
    return this.notes.toLowerCase().includes(lowercaseQuery) ||
           this.address.toLowerCase().includes(lowercaseQuery) ||
           this.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery)) ||
           (this.weather && this.weather.condition ? this.weather.condition.toLowerCase().includes(lowercaseQuery) : false)
  }

  /**
   * 检查是否为今天拍摄的照片
   */
  isTakenToday(): boolean {
    const today = new Date()
    return this.takenAt.toDateString() === today.toDateString()
  }

  /**
   * 检查是否为本周拍摄的照片
   */
  isTakenThisWeek(): boolean {
    const today = new Date()
    const weekStart = new Date(today)
    weekStart.setDate(today.getDate() - today.getDay() + (today.getDay() === 0 ? -6 : 1))
    weekStart.setHours(0, 0, 0, 0)

    return this.takenAt >= weekStart
  }

  /**
   * 获取拍摄时间显示文本
   */
  getTakenAtText(format: 'short' | 'medium' | 'long' = 'medium'): string {
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: format === 'short' ? '2-digit' : format === 'medium' ? 'short' : 'long',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    }

    if (format === 'long') {
      options.second = '2-digit'
      options.hour12 = false
    }

    return this.takenAt.toLocaleString('zh-CN', options)
  }

  /**
   * 获取拍摄方向显示文本
   */
  getAzimuthText(): string {
    if (this.azimuth === 0) {
      return '无方向信息'
    }

    const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北']
    const index = Math.round(this.azimuth / 45) % 8
    return directions[index] + ' (${this.azimuth.toFixed(1)}°)'
  }

  /**
   * 转换为完整的JSON对象（包含额外字段）
   */
  toFullJSON(): PhotoJSON {
    const baseData = super.toJSON()
    const jsonData: PhotoJSON = {
      id: baseData.id,
      createdAt: baseData.createdAt,
      updatedAt: baseData.updatedAt,
      version: baseData.version,
      projectId: this.projectId,
      siteId: this.siteId,
      filePath: this.filePath,
      thumbnailPath: this.thumbnailPath,
      takenAt: this.takenAt.getTime(),
      latitude: this.latitude,
      longitude: this.longitude,
      altitude: this.altitude,
      azimuth: this.azimuth,
      address: this.address,
      weather: this.weather,
      templateId: this.templateId,
      notes: this.notes,
      tags: this.tags,
      fileSize: this.fileSize,
      width: this.width,
      height: this.height,
      edited: this.edited,
      exifData: this.exifDataToRecord(),
      annotations: this.annotations
    }
    return jsonData
  }

  /**
   * 将ExifData转换为Record
   */
  private exifDataToRecord(): Record<string, string | number | boolean | null> {
    const result: Record<string, string | number | boolean | null> = {}
    const keys = this.exifData.keys()
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i]
      result[key] = this.exifData.get(key)
    }
    return result
  }

  /**
   * 从JSON对象创建实例
   */
  static fromFullJSON(data: PhotoJSON): Photo {
    const photo = new Photo()

    if (data.id) photo.id = data.id
    if (data.createdAt) photo.createdAt = new Date(data.createdAt)
    if (data.updatedAt) photo.updatedAt = new Date(data.updatedAt)
    if (data.version) photo.version = data.version

    if (data.projectId) photo.projectId = data.projectId
    if (data.siteId) photo.siteId = data.siteId
    if (data.filePath) photo.filePath = data.filePath
    if (data.thumbnailPath) photo.thumbnailPath = data.thumbnailPath
    if (data.takenAt) photo.takenAt = new Date(data.takenAt)
    if (data.latitude) photo.latitude = data.latitude
    if (data.longitude) photo.longitude = data.longitude
    if (data.altitude) photo.altitude = data.altitude
    if (data.azimuth) photo.azimuth = data.azimuth
    if (data.address) photo.address = data.address
    if (data.weather) photo.weather = data.weather
    if (data.templateId) photo.templateId = data.templateId
    if (data.notes) photo.notes = data.notes
    if (data.tags) photo.tags = data.tags
    if (data.fileSize) photo.fileSize = data.fileSize
    if (data.width) photo.width = data.width
    if (data.height) photo.height = data.height
    if (data.edited) photo.edited = data.edited
    if (data.exifData) {
      const exifKeys = Object.keys(data.exifData)
      for (let i = 0; i < exifKeys.length; i++) {
        const key = exifKeys[i]
        photo.exifData.set(key, data.exifData[key])
      }
    }
    if (data.annotations) photo.annotations = data.annotations

    return photo
  }

  /**
   * 深度克隆对象
   */
  override clone(): Photo {
    const cloned = new Photo()

    // Copy base properties
    cloned.id = this.id
    cloned.createdAt = new Date(this.createdAt)
    cloned.updatedAt = new Date(this.updatedAt)
    cloned.version = this.version

    // Copy Photo properties
    cloned.projectId = this.projectId
    cloned.siteId = this.siteId
    cloned.filePath = this.filePath
    cloned.thumbnailPath = this.thumbnailPath
    cloned.takenAt = new Date(this.takenAt)
    cloned.latitude = this.latitude
    cloned.longitude = this.longitude
    cloned.altitude = this.altitude
    cloned.azimuth = this.azimuth
    cloned.address = this.address
    if (this.weather) {
      cloned.weather = {
        temperature: this.weather.temperature,
        humidity: this.weather.humidity,
        condition: this.weather.condition,
        icon: this.weather.icon
      }
    } else {
      cloned.weather = null
    }
    cloned.templateId = this.templateId
    cloned.notes = this.notes
    cloned.fileSize = this.fileSize
    cloned.width = this.width
    cloned.height = this.height
    cloned.edited = this.edited

    // Clone tags manually
    cloned.tags = []
    for (let i = 0; i < this.tags.length; i++) {
      cloned.tags.push(this.tags[i])
    }

    // Clone exifData manually
    cloned.exifData = new ExifData()
    const exifKeys = this.exifData.keys()
    for (let i = 0; i < exifKeys.length; i++) {
      const key = exifKeys[i]
      cloned.exifData.set(key, this.exifData.get(key))
    }

    // Clone annotations manually
    cloned.annotations = []
    for (let i = 0; i < this.annotations.length; i++) {
      const annotation = this.annotations[i]
      const clonedAnnotation: Annotation = {
        id: annotation.id,
        type: annotation.type,
        content: annotation.content,
        position: annotation.position,
        style: annotation.style,
        createdAt: new Date(annotation.createdAt)
      }
      cloned.annotations.push(clonedAnnotation)
    }

    return cloned
  }
}