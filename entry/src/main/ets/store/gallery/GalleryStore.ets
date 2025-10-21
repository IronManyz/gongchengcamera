/**
 * 相册状态管理
 * 实现相册浏览功能、照片筛选功能和批量操作功能
 */

import { ObservedV2, Trace } from '@kit.ArkTS'
import { Logger } from '../../utils/Logger'
import { BaseStore } from '../BaseStore'
import { Photo } from '../../models/Photo'
import { PhotoStore } from '../photo/PhotoStore'
import { PhotoFilter, PhotoSortOrder } from '../../models/Photo'

/**
 * 相册视图模式枚举
 */
export enum GalleryViewMode {
  GRID = 'grid',
  LIST = 'list',
  TIMELINE = 'timeline'
}

/**
 * 照片筛选条件接口
 */
export interface GalleryFilter {
  projects?: string[]
  sites?: string[]
  dateRange?: {
    start: Date
    end: Date
  }
  tags?: string[]
  hasLocation?: boolean
  favorites?: boolean
  edited?: boolean
  sizeRange?: {
    min: number
    max: number
  }
}

/**
 * 批量操作类型枚举
 */
export enum BatchOperationType {
  DELETE = 'delete',
  EXPORT = 'export',
  ADD_TO_PROJECT = 'addToProject',
  ADD_TAGS = 'addTags',
  REMOVE_TAGS = 'removeTags',
  SET_FAVORITE = 'setFavorite',
  UNSET_FAVORITE = 'unsetFavorite'
}

/**
 * 批量操作参数接口
 */
export interface BatchOperationParams {
  type: BatchOperationType
  photoIds: string[]
  data?: any // 操作相关的额外数据
}

/**
 * 相册状态管理类
 */
@ObservedV2
export class GalleryStore extends BaseStore {
  private static instance: GalleryStore | null = null
  private logger = new Logger('GalleryStore')
  private photoStore: PhotoStore

  // 视图状态
  @Trace viewMode: GalleryViewMode = GalleryViewMode.GRID
  @Trace gridSize: number = 3 // 每行显示的照片数量

  // 筛选状态
  @Trace currentFilter: GalleryFilter = {}
  @Trace isFilterPanelVisible: boolean = false

  // 选择状态
  @Trace isSelectionMode: boolean = false
  @Trace selectedPhotos: Set<string> = new Set()

  // 操作状态
  @Trace isBatchOperationInProgress: boolean = false
  @Trace batchOperationProgress: number = 0
  @Trace batchOperationType: BatchOperationType | null = null

  private constructor() {
    super()
    this.photoStore = PhotoStore.getInstance()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): GalleryStore {
    if (!GalleryStore.instance) {
      GalleryStore.instance = new GalleryStore()
    }
    return GalleryStore.instance
  }

  /**
   * 设置视图模式
   */
  setViewMode(mode: GalleryViewMode): void {
    this.logger.info('Setting view mode', { mode })
    this.viewMode = mode
  }

  /**
   * 设置网格大小
   */
  setGridSize(size: number): void {
    this.logger.info('Setting grid size', { size })
    this.gridSize = Math.max(1, Math.min(5, size)) // 限制在1-5之间
  }

  /**
   * 显示/隐藏筛选面板
   */
  toggleFilterPanel(): void {
    this.isFilterPanelVisible = !this.isFilterPanelVisible
    this.logger.info('Filter panel toggled', { visible: this.isFilterPanelVisible })
  }

  /**
   * 应用筛选条件
   */
  async applyFilter(filter: GalleryFilter): Promise<void> {
    this.logger.info('Applying gallery filter', filter)

    this.currentFilter = { ...filter }
    this.isFilterPanelVisible = false

    // 将相册筛选条件转换为PhotoStore的查询参数
    await this.applyFilterToPhotoStore(filter)
  }

  /**
   * 将筛选条件应用到PhotoStore
   */
  private async applyFilterToPhotoStore(filter: GalleryFilter): Promise<void> {
    // 如果有项目筛选，这里需要转换为搜索查询
    if (filter.projects && filter.projects.length > 0) {
      const projectQueries = filter.projects.map(projectId => `project:${projectId}`)
      const searchQuery = projectQueries.join(' OR ')
      await this.photoStore.searchPhotos(searchQuery)
    } else {
      // 应用日期范围筛选
      if (filter.dateRange) {
        // 这里需要通过PhotoStore的高级搜索功能实现
        this.logger.info('Applying date range filter', filter.dateRange)
      }

      // 应用其他筛选条件
      if (filter.favorites) {
        await this.photoStore.applyFilter(PhotoFilter.FAVORITE)
      } else if (filter.edited) {
        await this.photoStore.applyFilter(PhotoFilter.EDITED)
      } else {
        await this.photoStore.applyFilter(PhotoFilter.ALL)
      }
    }

    // 应用排序
    await this.photoStore.applySortOrder(PhotoSortOrder.TAKEN_DESC)
  }

  /**
   * 清除筛选条件
   */
  async clearFilter(): Promise<void> {
    this.logger.info('Clearing gallery filter')

    this.currentFilter = {}
    await this.photoStore.applyFilter(PhotoFilter.ALL)
    await this.photoStore.searchPhotos('')
  }

  /**
   * 进入选择模式
   */
  enterSelectionMode(): void {
    this.logger.info('Entering selection mode')
    this.isSelectionMode = true
    this.selectedPhotos.clear()
  }

  /**
   * 退出选择模式
   */
  exitSelectionMode(): void {
    this.logger.info('Exiting selection mode')
    this.isSelectionMode = false
    this.selectedPhotos.clear()
  }

  /**
   * 切换选择模式
   */
  toggleSelectionMode(): void {
    if (this.isSelectionMode) {
      this.exitSelectionMode()
    } else {
      this.enterSelectionMode()
    }
  }

  /**
   * 选择/取消选择照片
   */
  togglePhotoSelection(photoId: string): void {
    if (!this.isSelectionMode) {
      return
    }

    if (this.selectedPhotos.has(photoId)) {
      this.selectedPhotos.delete(photoId)
    } else {
      this.selectedPhotos.add(photoId)
    }

    this.logger.info('Photo selection toggled', {
      photoId,
      selected: this.selectedPhotos.has(photoId),
      totalSelected: this.selectedPhotos.size
    })
  }

  /**
   * 选择所有照片
   */
  selectAllPhotos(): void {
    if (!this.isSelectionMode) {
      return
    }

    const allPhotos = this.photoStore.photos
    allPhotos.forEach(photo => {
      this.selectedPhotos.add(photo.id)
    })

    this.logger.info('All photos selected', { count: this.selectedPhotos.size })
  }

  /**
   * 清空选择
   */
  clearSelection(): void {
    this.selectedPhotos.clear()
    this.logger.info('Selection cleared')
  }

  /**
   * 获取选中的照片
   */
  getSelectedPhotos(): Photo[] {
    return this.photoStore.photos.filter(photo => this.selectedPhotos.has(photo.id))
  }

  /**
   * 执行批量操作
   */
  async executeBatchOperation(operation: BatchOperationParams): Promise<void> {
    this.logger.info('Executing batch operation', operation)

    this.isBatchOperationInProgress = true
    this.batchOperationType = operation.type
    this.batchOperationProgress = 0

    try {
      switch (operation.type) {
        case BatchOperationType.DELETE:
          await this.executeBatchDelete(operation.photoIds)
          break
        case BatchOperationType.EXPORT:
          await this.executeBatchExport(operation.photoIds)
          break
        case BatchOperationType.ADD_TO_PROJECT:
          await this.executeAddToProject(operation.photoIds, operation.data.projectId)
          break
        case BatchOperationType.ADD_TAGS:
          await this.executeAddTags(operation.photoIds, operation.data.tags)
          break
        case BatchOperationType.REMOVE_TAGS:
          await this.executeRemoveTags(operation.photoIds, operation.data.tags)
          break
        case BatchOperationType.SET_FAVORITE:
          await this.executeSetFavorite(operation.photoIds, true)
          break
        case BatchOperationType.UNSET_FAVORITE:
          await this.executeSetFavorite(operation.photoIds, false)
          break
        default:
          throw new Error(`Unsupported batch operation: ${operation.type}`)
      }

      this.logger.info('Batch operation completed successfully', operation)
    } catch (error) {
      this.logger.error('Batch operation failed', error)
      throw error
    } finally {
      this.isBatchOperationInProgress = false
      this.batchOperationType = null
      this.batchOperationProgress = 0
    }
  }

  /**
   * 批量删除
   */
  private async executeBatchDelete(photoIds: string[]): Promise<void> {
    this.logger.info('Executing batch delete', { count: photoIds.length })

    const result = await this.photoStore.deletePhotos(photoIds)

    if (!result.success) {
      throw new Error(`Batch delete failed: ${result.errors.length} errors`)
    }

    // 清空选择
    this.clearSelection()
  }

  /**
   * 批量导出
   */
  private async executeBatchExport(photoIds: string[]): Promise<void> {
    this.logger.info('Executing batch export', { count: photoIds.length })

    const total = photoIds.length
    for (let i = 0; i < total; i++) {
      const photoId = photoIds[i]

      try {
        // 导出单个照片
        await this.photoStore.exportPhotos([photoId])

        // 更新进度
        this.batchOperationProgress = Math.round(((i + 1) / total) * 100)

        // 模拟处理时间
        await new Promise(resolve => setTimeout(resolve, 100))

      } catch (error) {
        this.logger.error('Failed to export photo', { photoId, error })
      }
    }

    this.clearSelection()
  }

  /**
   * 添加到项目
   */
  private async executeAddToProject(photoIds: string[], projectId: string): Promise<void> {
    this.logger.info('Adding photos to project', { count: photoIds.length, projectId })

    const total = photoIds.length
    for (let i = 0; i < total; i++) {
      const photoId = photoIds[i]

      try {
        // 更新照片的项目ID
        await this.photoStore.updatePhoto(photoId, { projectId })

        // 更新进度
        this.batchOperationProgress = Math.round(((i + 1) / total) * 100)

      } catch (error) {
        this.logger.error('Failed to add photo to project', { photoId, projectId, error })
      }
    }

    this.clearSelection()
  }

  /**
   * 添加标签
   */
  private async executeAddTags(photoIds: string[], tags: string[]): Promise<void> {
    this.logger.info('Adding tags to photos', { count: photoIds.length, tags })

    const total = photoIds.length
    for (let i = 0; i < total; i++) {
      const photoId = photoIds[i]

      try {
        const photo = this.photoStore.photos.find(p => p.id === photoId)
        if (photo) {
          const existingTags = photo.tags || []
          const newTags = [...new Set([...existingTags, ...tags])]
          await this.photoStore.updatePhoto(photoId, { tags: newTags })
        }

        // 更新进度
        this.batchOperationProgress = Math.round(((i + 1) / total) * 100)

      } catch (error) {
        this.logger.error('Failed to add tags to photo', { photoId, tags, error })
      }
    }

    this.clearSelection()
  }

  /**
   * 移除标签
   */
  private async executeRemoveTags(photoIds: string[], tags: string[]): Promise<void> {
    this.logger.info('Removing tags from photos', { count: photoIds.length, tags })

    const total = photoIds.length
    for (let i = 0; i < total; i++) {
      const photoId = photoIds[i]

      try {
        const photo = this.photoStore.photos.find(p => p.id === photoId)
        if (photo && photo.tags) {
          const remainingTags = photo.tags.filter(tag => !tags.includes(tag))
          await this.photoStore.updatePhoto(photoId, { tags: remainingTags })
        }

        // 更新进度
        this.batchOperationProgress = Math.round(((i + 1) / total) * 100)

      } catch (error) {
        this.logger.error('Failed to remove tags from photo', { photoId, tags, error })
      }
    }

    this.clearSelection()
  }

  /**
   * 设置收藏状态
   */
  private async executeSetFavorite(photoIds: string[], isFavorite: boolean): Promise<void> {
    this.logger.info('Setting favorite status', { count: photoIds.length, isFavorite })

    const total = photoIds.length
    for (let i = 0; i < total; i++) {
      const photoId = photoIds[i]

      try {
        await this.photoStore.updatePhoto(photoId, { isFavorite })

        // 更新进度
        this.batchOperationProgress = Math.round(((i + 1) / total) * 100)

      } catch (error) {
        this.logger.error('Failed to set favorite status', { photoId, isFavorite, error })
      }
    }

    this.clearSelection()
  }

  /**
   * 刷新相册
   */
  async refresh(): Promise<void> {
    this.logger.info('Refreshing gallery')
    await this.photoStore.refresh()
  }

  /**
   * 加载更多照片
   */
  async loadMore(): Promise<void> {
    this.logger.info('Loading more photos in gallery')
    await this.photoStore.loadMore()
  }

  /**
   * 获取相册统计信息
   */
  getGalleryStats(): {
    totalPhotos: number
    selectedPhotos: number
    isFilterActive: boolean
    viewMode: GalleryViewMode
  } {
    return {
      totalPhotos: this.photoStore.photos.length,
      selectedPhotos: this.selectedPhotos.size,
      isFilterActive: Object.keys(this.currentFilter).length > 0,
      viewMode: this.viewMode
    }
  }

  /**
   * 检查是否有活动的筛选条件
   */
  hasActiveFilter(): boolean {
    return Object.keys(this.currentFilter).length > 0 ||
           this.photoStore.searchQuery.length > 0 ||
           this.photoStore.currentFilter !== PhotoFilter.ALL
  }

  /**
   * 重置相册状态
   */
  reset(): void {
    this.viewMode = GalleryViewMode.GRID
    this.gridSize = 3
    this.currentFilter = {}
    this.isFilterPanelVisible = false
    this.isSelectionMode = false
    this.selectedPhotos.clear()
    this.isBatchOperationInProgress = false
    this.batchOperationProgress = 0
    this.batchOperationType = null

    this.logger.info('GalleryStore reset')
  }

  /**
   * 获取网格列数
   */
  getGridColumns(): number {
    switch (this.gridSize) {
      case 1:
        return 1
      case 2:
        return 2
      case 3:
        return 3
      case 4:
        return 4
      case 5:
        return 5
      default:
        return 3
    }
  }

  /**
   * 检查是否可以执行批量操作
   */
  canExecuteBatchOperation(): boolean {
    return this.selectedPhotos.size > 0 && !this.isBatchOperationInProgress
  }

  /**
   * 获取当前批量操作的描述
   */
  getBatchOperationDescription(): string {
    if (!this.batchOperationType) {
      return ''
    }

    const descriptions: Record<BatchOperationType, string> = {
      [BatchOperationType.DELETE]: '删除照片',
      [BatchOperationType.EXPORT]: '导出照片',
      [BatchOperationType.ADD_TO_PROJECT]: '添加到项目',
      [BatchOperationType.ADD_TAGS]: '添加标签',
      [BatchOperationType.REMOVE_TAGS]: '移除标签',
      [BatchOperationType.SET_FAVORITE]: '设为收藏',
      [BatchOperationType.UNSET_FAVORITE]: '取消收藏'
    }

    return descriptions[this.batchOperationType] || '处理中'
  }
}