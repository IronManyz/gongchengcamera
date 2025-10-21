/**
 * 照片状态管理
 * 实现照片CRUD操作、搜索功能和分类管理
 */

import { ObservedV2, Trace } from '@kit.ArkTS'
import { Logger } from '../../utils/Logger'
import { BaseStore } from '../BaseStore'
import { Photo, PhotoFilter, PhotoSortOrder } from '../../models/Photo'
import { PhotoService } from '../../services/database/PhotoService'
import { PaginatedResponse, SearchParams } from '../../types/AppTypes'

/**
 * 照片查询参数接口
 */
export interface PhotoQueryParams extends SearchParams {
  projectId?: string
  siteId?: string
  dateFrom?: Date
  dateTo?: Date
  tags?: string[]
  hasLocation?: boolean
  minSize?: number
  maxSize?: number
}

/**
 * 照片统计信息接口
 */
export interface PhotoStats {
  totalCount: number
  totalSize: number
  todayCount: number
  weekCount: number
  monthCount: number
  projectCounts: Record<string, number>
  tagCounts: Record<string, number>
}

/**
 * 照片操作结果接口
 */
export interface PhotoOperationResult {
  success: boolean
  photo?: Photo
  error?: string
}

/**
 * 批量操作结果接口
 */
export interface BatchOperationResult {
  success: boolean
  processedCount: number
  failedCount: number
  errors: Array<{ photoId: string, error: string }>
}

/**
 * 照片状态管理类
 */
@ObservedV2
export class PhotoStore extends BaseStore {
  private static instance: PhotoStore | null = null
  private logger = new Logger('PhotoStore')
  private photoService: PhotoService

  // 状态数据
  @Trace photos: Photo[] = []
  @Trace currentPhoto: Photo | null = null
  @Trace isLoading: boolean = false
  @Trace error: string | null = null

  // 分页状态
  @Trace currentPage: number = 1
  @Trace pageSize: number = 20
  @Trace totalCount: number = 0
  @Trace hasMore: boolean = false

  // 搜索和过滤状态
  @Trace currentFilter: PhotoFilter = PhotoFilter.ALL
  @Trace currentSortOrder: PhotoSortOrder = PhotoSortOrder.TAKEN_DESC
  @Trace searchQuery: string = ''
  @Trace selectedPhotos: Set<string> = new Set()

  // 统计信息
  @Trace stats: PhotoStats | null = null

  private constructor() {
    super()
    this.photoService = new PhotoService()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): PhotoStore {
    if (!PhotoStore.instance) {
      PhotoStore.instance = new PhotoStore()
    }
    return PhotoStore.instance
  }

  /**
   * 加载照片列表
   */
  async loadPhotos(refresh: boolean = false): Promise<void> {
    if (refresh) {
      this.currentPage = 1
      this.photos = []
    }

    if (this.isLoading && !refresh) {
      return
    }

    this.isLoading = true
    this.error = null

    try {
      const params = this.buildQueryParams()
      const response = await this.photoService.getPhotos(params)

      if (refresh) {
        this.photos = response.data
      } else {
        this.photos.push(...response.data)
      }

      this.totalCount = response.total
      this.hasMore = response.hasNext
      this.currentPage++

      // 更新统计信息
      await this.updateStats()

      this.logger.info('Photos loaded', {
        count: response.data.length,
        total: response.total,
        hasMore: response.hasNext
      })
    } catch (error) {
      this.error = error instanceof Error ? error.message : String(error)
      this.logger.error('Failed to load photos', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 根据ID获取照片
   */
  async getPhotoById(id: string): Promise<Photo | null> {
    this.logger.info('Getting photo by ID', { id })

    try {
      // 先从本地状态查找
      const localPhoto = this.photos.find(photo => photo.id === id)
      if (localPhoto) {
        this.currentPhoto = localPhoto
        return localPhoto
      }

      // 从数据库获取
      const photo = await this.photoService.getPhotoById(id)
      if (photo) {
        this.currentPhoto = photo
      }

      return photo
    } catch (error) {
      this.error = error instanceof Error ? error.message : String(error)
      this.logger.error('Failed to get photo by ID', error)
      return null
    }
  }

  /**
   * 创建照片
   */
  async createPhoto(photoData: Partial<Photo>): Promise<PhotoOperationResult> {
    this.logger.info('Creating photo', photoData)

    try {
      const photo = await this.photoService.createPhoto(photoData)

      // 添加到本地状态
      this.photos.unshift(photo)
      this.currentPhoto = photo
      this.totalCount++

      // 更新统计信息
      await this.updateStats()

      this.logger.info('Photo created successfully', { id: photo.id })
      return { success: true, photo }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      this.error = errorMessage
      this.logger.error('Failed to create photo', error)
      return { success: false, error: errorMessage }
    }
  }

  /**
   * 更新照片
   */
  async updatePhoto(id: string, updates: Partial<Photo>): Promise<PhotoOperationResult> {
    this.logger.info('Updating photo', { id, updates })

    try {
      const updatedPhoto = await this.photoService.updatePhoto(id, updates)

      if (!updatedPhoto) {
        return { success: false, error: 'Photo not found' }
      }

      // 更新本地状态
      const index = this.photos.findIndex(photo => photo.id === id)
      if (index !== -1) {
        this.photos[index] = updatedPhoto
      }

      if (this.currentPhoto?.id === id) {
        this.currentPhoto = updatedPhoto
      }

      // 更新统计信息
      await this.updateStats()

      this.logger.info('Photo updated successfully', { id })
      return { success: true, photo: updatedPhoto }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      this.error = errorMessage
      this.logger.error('Failed to update photo', error)
      return { success: false, error: errorMessage }
    }
  }

  /**
   * 删除照片
   */
  async deletePhoto(id: string): Promise<PhotoOperationResult> {
    this.logger.info('Deleting photo', { id })

    try {
      const success = await this.photoService.deletePhoto(id)

      if (!success) {
        return { success: false, error: 'Failed to delete photo' }
      }

      // 从本地状态移除
      this.photos = this.photos.filter(photo => photo.id !== id)
      this.selectedPhotos.delete(id)
      this.totalCount--

      if (this.currentPhoto?.id === id) {
        this.currentPhoto = null
      }

      // 更新统计信息
      await this.updateStats()

      this.logger.info('Photo deleted successfully', { id })
      return { success: true }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      this.error = errorMessage
      this.logger.error('Failed to delete photo', error)
      return { success: false, error: errorMessage }
    }
  }

  /**
   * 批量删除照片
   */
  async deletePhotos(ids: string[]): Promise<BatchOperationResult> {
    this.logger.info('Deleting photos in batch', { count: ids.length })

    const result: BatchOperationResult = {
      success: true,
      processedCount: 0,
      failedCount: 0,
      errors: []
    }

    try {
      for (const id of ids) {
        try {
          const deleteResult = await this.deletePhoto(id)
          if (deleteResult.success) {
            result.processedCount++
          } else {
            result.failedCount++
            result.errors.push({ photoId: id, error: deleteResult.error || 'Unknown error' })
          }
        } catch (error) {
          result.failedCount++
          result.errors.push({
            photoId: id,
            error: error instanceof Error ? error.message : String(error)
          })
        }
      }

      // 清空选中状态
      this.selectedPhotos.clear()

      result.success = result.failedCount === 0
      this.logger.info('Batch delete completed', result)
    } catch (error) {
      this.logger.error('Batch delete failed', error)
      result.success = false
    }

    return result
  }

  /**
   * 搜索照片
   */
  async searchPhotos(query: string): Promise<void> {
    this.logger.info('Searching photos', { query })

    this.searchQuery = query
    this.currentPage = 1
    this.photos = []

    await this.loadPhotos(true)
  }

  /**
   * 应用过滤器
   */
  async applyFilter(filter: PhotoFilter): Promise<void> {
    this.logger.info('Applying filter', { filter })

    this.currentFilter = filter
    this.currentPage = 1
    this.photos = []

    await this.loadPhotos(true)
  }

  /**
   * 应用排序
   */
  async applySortOrder(sortOrder: PhotoSortOrder): Promise<void> {
    this.logger.info('Applying sort order', { sortOrder })

    this.currentSortOrder = sortOrder
    this.currentPage = 1
    this.photos = []

    await this.loadPhotos(true)
  }

  /**
   * 选择/取消选择照片
   */
  togglePhotoSelection(id: string): void {
    if (this.selectedPhotos.has(id)) {
      this.selectedPhotos.delete(id)
    } else {
      this.selectedPhotos.add(id)
    }
    this.logger.info('Photo selection toggled', { id, selected: this.selectedPhotos.has(id) })
  }

  /**
   * 选择所有照片
   */
  selectAllPhotos(): void {
    this.photos.forEach(photo => {
      this.selectedPhotos.add(photo.id)
    })
    this.logger.info('All photos selected', { count: this.selectedPhotos.size })
  }

  /**
   * 清空选择
   */
  clearSelection(): void {
    this.selectedPhotos.clear()
    this.logger.info('Photo selection cleared')
  }

  /**
   * 获取选中的照片
   */
  getSelectedPhotos(): Photo[] {
    return this.photos.filter(photo => this.selectedPhotos.has(photo.id))
  }

  /**
   * 构建查询参数
   */
  private buildQueryParams(): PhotoQueryParams {
    const params: PhotoQueryParams = {
      pagination: {
        page: this.currentPage,
        pageSize: this.pageSize,
        sortBy: this.getSortField(),
        sortOrder: this.getSortDirection()
      }
    }

    // 添加搜索查询
    if (this.searchQuery) {
      params.query = this.searchQuery
    }

    // 添加过滤条件
    switch (this.currentFilter) {
      case PhotoFilter.TODAY:
        const today = new Date()
        today.setHours(0, 0, 0, 0)
        params.dateFrom = today
        break
      case PhotoFilter.THIS_WEEK:
        const weekStart = new Date()
        weekStart.setDate(weekStart.getDate() - weekStart.getDay())
        weekStart.setHours(0, 0, 0, 0)
        params.dateFrom = weekStart
        break
      case PhotoFilter.THIS_MONTH:
        const monthStart = new Date()
        monthStart.setDate(1)
        monthStart.setHours(0, 0, 0, 0)
        params.dateFrom = monthStart
        break
      case PhotoFilter.EDITED:
        // 这里需要根据照片的编辑状态过滤
        break
      case PhotoFilter.FAVORITE:
        // 这里需要根据照片的收藏状态过滤
        break
    }

    return params
  }

  /**
   * 获取排序字段
   */
  private getSortField(): string {
    switch (this.currentSortOrder) {
      case PhotoSortOrder.TAKEN_ASC:
      case PhotoSortOrder.TAKEN_DESC:
        return 'takenAt'
      case PhotoSortOrder.CREATED_ASC:
      case PhotoSortOrder.CREATED_DESC:
        return 'createdAt'
      case PhotoSortOrder.NAME_ASC:
      case PhotoSortOrder.NAME_DESC:
        return 'name'
      case PhotoSortOrder.SIZE_ASC:
      case PhotoSortOrder.SIZE_DESC:
        return 'size'
      default:
        return 'takenAt'
    }
  }

  /**
   * 获取排序方向
   */
  private getSortDirection(): 'asc' | 'desc' {
    switch (this.currentSortOrder) {
      case PhotoSortOrder.TAKEN_ASC:
      case PhotoSortOrder.CREATED_ASC:
      case PhotoSortOrder.NAME_ASC:
      case PhotoSortOrder.SIZE_ASC:
        return 'asc'
      default:
        return 'desc'
    }
  }

  /**
   * 更新统计信息
   */
  private async updateStats(): Promise<void> {
    try {
      this.stats = await this.photoService.getPhotoStats()
    } catch (error) {
      this.logger.error('Failed to update stats', error)
    }
  }

  /**
   * 刷新照片列表
   */
  async refresh(): Promise<void> {
    this.logger.info('Refreshing photos')
    await this.loadPhotos(true)
  }

  /**
   * 加载更多照片
   */
  async loadMore(): Promise<void> {
    if (this.hasMore && !this.isLoading) {
      this.logger.info('Loading more photos')
      await this.loadPhotos(false)
    }
  }

  /**
   * 清空错误状态
   */
  clearError(): void {
    this.error = null
  }

  /**
   * 重置状态
   */
  reset(): void {
    this.photos = []
    this.currentPhoto = null
    this.isLoading = false
    this.error = null
    this.currentPage = 1
    this.totalCount = 0
    this.hasMore = false
    this.currentFilter = PhotoFilter.ALL
    this.currentSortOrder = PhotoSortOrder.TAKEN_DESC
    this.searchQuery = ''
    this.selectedPhotos.clear()
    this.stats = null

    this.logger.info('PhotoStore reset')
  }

  /**
   * 获取Store状态
   */
  getStoreState(): {
    photosCount: number
    selectedCount: number
    isLoading: boolean
    hasError: boolean
    currentPage: number
    totalPages: number
  } {
    return {
      photosCount: this.photos.length,
      selectedCount: this.selectedPhotos.size,
      isLoading: this.isLoading,
      hasError: !!this.error,
      currentPage: this.currentPage,
      totalPages: Math.ceil(this.totalCount / this.pageSize)
    }
  }

  /**
   * 导出照片数据
   */
  async exportPhotos(ids?: string[]): Promise<string> {
    this.logger.info('Exporting photos', { count: ids?.length || 'all' })

    try {
      const photoIds = ids || this.photos.map(photo => photo.id)
      const exportData = await this.photoService.exportPhotos(photoIds)

      this.logger.info('Photos exported successfully', { count: photoIds.length })
      return exportData
    } catch (error) {
      this.error = error instanceof Error ? error.message : String(error)
      this.logger.error('Failed to export photos', error)
      throw error
    }
  }

  /**
   * 导入照片数据
   */
  async importPhotos(data: string): Promise<BatchOperationResult> {
    this.logger.info('Importing photos')

    const result: BatchOperationResult = {
      success: true,
      processedCount: 0,
      failedCount: 0,
      errors: []
    }

    try {
      const importResults = await this.photoService.importPhotos(data)

      // 更新本地状态
      if (importResults.success) {
        await this.refresh()
      }

      result.processedCount = importResults.processedCount || 0
      result.failedCount = importResults.failedCount || 0
      result.errors = importResults.errors || []
      result.success = result.failedCount === 0

      this.logger.info('Photos import completed', result)
    } catch (error) {
      this.logger.error('Photos import failed', error)
      result.success = false
    }

    return result
  }
}