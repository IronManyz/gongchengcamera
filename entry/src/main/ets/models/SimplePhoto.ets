/**
 * 简单照片模型
 * 用于工程照片数据管理
 */

@ObservedV2
export class SimplePhoto {
  @Trace id: string = ''
  @Trace projectId: string = ''
  @Trace siteId: string = ''
  @Trace name: string = ''
  @Trace description: string = ''
  @Trace filePath: string = ''
  @Trace thumbnailPath: string = ''
  @Trace fileSize: number = 0
  @Trace width: number = 0
  @Trace height: number = 0
  @Trace latitude: number = 0
  @Trace longitude: number = 0
  @Trace altitude: number = 0
  @Trace address: string = ''
  @Trace takenAt: Date = new Date()
  @Trace createdAt: Date = new Date()
  @Trace updatedAt: Date = new Date()
  @Trace tags: string[] = []
  @Trace watermarkEnabled: boolean = true
  @Trace watermarkTemplate: string = ''
  @Trace isEdited: boolean = false
  @Trace editedAt?: Date

  constructor(id?: string, filePath?: string, projectId?: string, siteId?: string) {
    if (id) this.id = id
    if (filePath) this.filePath = filePath
    if (projectId) this.projectId = projectId
    if (siteId) this.siteId = siteId
    if (!this.id) this.id = Date.now().toString()
  }

  /**
   * 获取照片显示名称
   */
  getDisplayName(): string {
    if (this.name) return this.name
    if (this.filePath) {
      const fileName = this.filePath.split('/').pop() || ''
      return fileName.replace(/\.[^/.]+$/, '') // 移除文件扩展名
    }
    return '未命名照片'
  }

  /**
   * 获取文件大小显示文本
   */
  getFileSizeText(): string {
    if (this.fileSize === 0) return '未知大小'

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
   * 获取尺寸显示文本
   */
  getDimensionsText(): string {
    if (this.width === 0 || this.height === 0) return '未知尺寸'
    return `${this.width} × ${this.height}`
  }

  /**
   * 获取拍摄时间显示文本
   */
  getTakenTimeText(): string {
    return this.takenAt.toLocaleString()
  }

  /**
   * 获取相对时间描述
   */
  getRelativeTimeText(): string {
    const now = new Date()
    const diff = now.getTime() - this.takenAt.getTime()
    const minutes = Math.floor(diff / (1000 * 60))
    const hours = Math.floor(minutes / 60)
    const days = Math.floor(hours / 24)

    if (minutes < 1) return '刚刚'
    if (minutes < 60) return `${minutes}分钟前`
    if (hours < 24) return `${hours}小时前`
    if (days < 30) return `${days}天前`

    return this.takenAt.toLocaleDateString()
  }

  /**
   * 检查是否有位置信息
   */
  hasLocation(): boolean {
    return this.latitude !== 0 || this.longitude !== 0
  }

  /**
   * 获取位置坐标字符串
   */
  getCoordinatesString(): string {
    if (!this.hasLocation()) return '位置未设置'
    return `${this.latitude.toFixed(6)}, ${this.longitude.toFixed(6)}`
  }

  /**
   * 检查是否有缩略图
   */
  hasThumbnail(): boolean {
    return this.thumbnailPath.length > 0
  }

  /**
   * 检查是否有标签
   */
  hasTags(): boolean {
    return this.tags.length > 0
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
  setAddress(address: string): void {
    this.address = address
    this.updatedAt = new Date()
  }

  /**
   * 标记为已编辑
   */
  markAsEdited(): void {
    this.isEdited = true
    this.editedAt = new Date()
    this.updatedAt = new Date()
  }

  /**
   * 获取编辑状态显示文本
   */
  getEditedStatusText(): string {
    if (!this.isEdited) return '原始照片'
    if (this.editedAt) {
      return `已编辑 (${this.editedAt.toLocaleDateString()})`
    }
    return '已编辑'
  }

  /**
   * 克隆照片对象
   */
  clone(): SimplePhoto {
    const cloned = new SimplePhoto()
    cloned.id = Date.now().toString()
    cloned.name = this.name
    cloned.description = this.description
    cloned.filePath = this.filePath
    cloned.thumbnailPath = this.thumbnailPath
    cloned.fileSize = this.fileSize
    cloned.width = this.width
    cloned.height = this.height
    cloned.latitude = this.latitude
    cloned.longitude = this.longitude
    cloned.altitude = this.altitude
    cloned.address = this.address
    cloned.takenAt = new Date(this.takenAt)
    cloned.projectId = this.projectId
    cloned.siteId = this.siteId
    cloned.tags = [...this.tags]
    cloned.watermarkEnabled = this.watermarkEnabled
    cloned.watermarkTemplate = this.watermarkTemplate
    return cloned
  }
}

/**
 * 照片过滤器
 */
export class PhotoFilter {
  id: string = ''
  name: string = ''
  type: PhotoFilterType = PhotoFilterType.NONE
  intensity: number = 50
  isEnabled: boolean = true
  createdAt: Date = new Date()

  constructor(id?: string, name?: string, type?: PhotoFilterType) {
    if (id) this.id = id
    if (name) this.name = name
    if (type) this.type = type
    if (!this.id) this.id = Date.now().toString()
  }

  getDisplayName(): string {
    return this.name || '未命名滤镜'
  }
}

/**
 * 照片滤镜类型
 */
export enum PhotoFilterType {
  NONE = 'none',
  BRIGHTNESS = 'brightness',
  CONTRAST = 'contrast',
  SATURATION = 'saturation',
  SEPIA = 'sepia',
  GRAYSCALE = 'grayscale',
  BLUR = 'blur',
  VINTAGE = 'vintage',
  COLD = 'cold',
  WARM = 'warm'
}

/**
 * 预设滤镜
 */
export class PresetPhotoFilters {
  static getOriginal(): PhotoFilter {
    const filter = new PhotoFilter('original', '原图', PhotoFilterType.NONE)
    return filter
  }

  static getBrightness(): PhotoFilter {
    const filter = new PhotoFilter('brightness', '亮度增强', PhotoFilterType.BRIGHTNESS)
    return filter
  }

  static getContrast(): PhotoFilter {
    const filter = new PhotoFilter('contrast', '对比度增强', PhotoFilterType.CONTRAST)
    return filter
  }

  static getSepia(): PhotoFilter {
    const filter = new PhotoFilter('sepia', '复古', PhotoFilterType.SEPIA)
    return filter
  }

  static getGrayscale(): PhotoFilter {
    const filter = new PhotoFilter('grayscale', '黑白', PhotoFilterType.GRAYSCALE)
    return filter
  }

  static getVintage(): PhotoFilter {
    const filter = new PhotoFilter('vintage', '怀旧', PhotoFilterType.VINTAGE)
    return filter
  }

  static getCold(): PhotoFilter {
    const filter = new PhotoFilter('cold', '冷色调', PhotoFilterType.COLD)
    return filter
  }

  static getWarm(): PhotoFilter {
    const filter = new PhotoFilter('warm', '暖色调', PhotoFilterType.WARM)
    return filter
  }

  static getAllPresets(): PhotoFilter[] {
    return [
      PresetPhotoFilters.getOriginal(),
      PresetPhotoFilters.getBrightness(),
      PresetPhotoFilters.getContrast(),
      PresetPhotoFilters.getSepia(),
      PresetPhotoFilters.getGrayscale(),
      PresetPhotoFilters.getVintage(),
      PresetPhotoFilters.getCold(),
      PresetPhotoFilters.getWarm()
    ]
  }
}