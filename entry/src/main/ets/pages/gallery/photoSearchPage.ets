/**
 * 照片搜索页面
 * 提供多条件搜索和过滤功能，支持搜索历史管理
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { Photo } from '../../models/Photo'
import { PhotoFilter, PhotoSortOrder } from '../../models/Photo'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { GalleryStore, GalleryFilter } from '../../store/gallery/GalleryStore'
import { PhotoGrid } from '../../components/photo/PhotoGrid'
import { SearchBar } from '../../components/common/SearchBar'
import { EmptyView } from '../../components/common/EmptyView'
import { LoadingDialog } from '../../components/common/LoadingDialog'

@Entry
@Component
struct PhotoSearchPage {
  private logger = new Logger('PhotoSearchPage')
  private photoStore = PhotoStore.getInstance()
  private galleryStore = GalleryStore.getInstance()

  // 状态管理
  @State private isLoading: boolean = false
  @State private searchQuery: string = ''
  @State private showFilterPanel: boolean = false
  @State private showHistoryPanel: boolean = false
  @State private searchResults: Photo[] = []
  @State private hasSearched: boolean = false
  @State private searchHistory: string[] = []

  // 筛选条件
  @State private currentFilter: GalleryFilter = {}
  @State private selectedProjects: string[] = []
  @State private selectedSites: string[] = []
  @State private selectedTags: string[] = []
  @State private dateRange: { start: Date, end: Date } | null = null
  @State private sortOrder: PhotoSortOrder = PhotoSortOrder.TAKEN_DESC

  aboutToAppear() {
    this.logger.info('PhotoSearchPage appeared')
    this.loadSearchHistory()
  }

  aboutToDisappear() {
    this.logger.info('PhotoSearchPage disappeared')
  }

  /**
   * 加载搜索历史
   */
  private async loadSearchHistory() {
    try {
      // 从本地存储加载搜索历史
      this.searchHistory = []
    } catch (error) {
      this.logger.error('加载搜索历史失败', error)
    }
  }

  /**
   * 执行搜索
   */
  private async executeSearch(query: string) {
    if (!query.trim()) {
      this.searchResults = []
      this.hasSearched = false
      return
    }

    this.isLoading = true
    this.hasSearched = true

    try {
      // 构建搜索查询
      let searchQuery = query.trim()

      // 添加项目筛选
      if (this.selectedProjects.length > 0) {
        const projectQueries = this.selectedProjects.map(id => `project:${id}`)
        searchQuery += ` (${projectQueries.join(' OR ')})`
      }

      // 添加工点筛选
      if (this.selectedSites.length > 0) {
        const siteQueries = this.selectedSites.map(id => `site:${id}`)
        searchQuery += ` (${siteQueries.join(' OR ')})`
      }

      // 添加标签筛选
      if (this.selectedTags.length > 0) {
        const tagQueries = this.selectedTags.map(tag => `tag:${tag}`)
        searchQuery += ` (${tagQueries.join(' OR ')})`
      }

      // 执行搜索
      await this.photoStore.searchPhotos(searchQuery)
      this.searchResults = this.photoStore.photos

      // 保存搜索历史
      this.saveSearchHistory(query.trim())

    } catch (error) {
      this.logger.error('搜索失败', error)
      this.searchResults = []
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(query: string) {
    try {
      // 移除重复项
      const index = this.searchHistory.indexOf(query)
      if (index > -1) {
        this.searchHistory.splice(index, 1)
      }

      // 添加到开头
      this.searchHistory.unshift(query)

      // 限制历史记录数量
      if (this.searchHistory.length > 20) {
        this.searchHistory = this.searchHistory.slice(0, 20)
      }

      // 保存到本地存储
    } catch (error) {
      this.logger.error('保存搜索历史失败', error)
    }
  }

  /**
   * 清除搜索历史
   */
  private async clearSearchHistory() {
    try {
      this.searchHistory = []
      // 清除本地存储
    } catch (error) {
      this.logger.error('清除搜索历史失败', error)
    }
  }

  /**
   * 应用筛选条件
   */
  private async applyFilters() {
    this.currentFilter = {
      projects: this.selectedProjects.length > 0 ? this.selectedProjects : undefined,
      sites: this.selectedSites.length > 0 ? this.selectedSites : undefined,
      tags: this.selectedTags.length > 0 ? this.selectedTags : undefined,
      dateRange: this.dateRange || undefined
    }

    await this.galleryStore.applyFilter(this.currentFilter)
    this.showFilterPanel = false

    // 如果有搜索查询，重新执行搜索
    if (this.searchQuery) {
      await this.executeSearch(this.searchQuery)
    }
  }

  /**
   * 清除筛选条件
   */
  private async clearFilters() {
    this.selectedProjects = []
    this.selectedSites = []
    this.selectedTags = []
    this.dateRange = null
    this.currentFilter = {}

    await this.galleryStore.clearFilter()

    // 如果有搜索查询，重新执行搜索
    if (this.searchQuery) {
      await this.executeSearch(this.searchQuery)
    }
  }

  /**
   * 切换排序方式
   */
  private async changeSortOrder(order: PhotoSortOrder) {
    this.sortOrder = order
    await this.photoStore.applySortOrder(order)
  }

  /**
   * 照片点击处理
   */
  private onPhotoClick(photo: Photo, index: number) {
    router.pushUrl({
      url: 'pages/gallery/PhotoDetailPage',
      params: {
        photoId: photo.id,
        fromSearch: true
      }
    })
  }

  /**
   * 返回相册
   */
  private navigateToGallery() {
    router.back()
  }

  /**
   * 使用历史搜索
   */
  private useHistorySearch(query: string) {
    this.searchQuery = query
    this.executeSearch(query)
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  }

  /**
   * 获取排序文本
   */
  private getSortOrderText(order: PhotoSortOrder): string {
    switch (order) {
      case PhotoSortOrder.TAKEN_DESC:
        return '拍摄时间降序'
      case PhotoSortOrder.TAKEN_ASC:
        return '拍摄时间升序'
      case PhotoSortOrder.NAME_ASC:
        return '名称升序'
      case PhotoSortOrder.NAME_DESC:
        return '名称降序'
      case PhotoSortOrder.SIZE_DESC:
        return '文件大小降序'
      case PhotoSortOrder.SIZE_ASC:
        return '文件大小升序'
      default:
        return '拍摄时间降序'
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 搜索栏
      this.buildSearchBar()

      // 筛选和排序栏
      if (this.hasSearched) {
        this.buildFilterAndSortBar()
      }

      // 内容区域
      this.buildContent()

      // 筛选面板
      if (this.showFilterPanel) {
        this.buildFilterPanel()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '搜索中...' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  private buildTopBar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.navigateToGallery())

      // 标题
      Text('搜索照片')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 搜索历史按钮
      if (!this.hasSearched) {
        Button() {
          Image($r('app.media.ic_history'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showHistoryPanel = !this.showHistoryPanel)
      } else {
        // 清除搜索按钮
        Button() {
          Image($r('app.media.ic_clear'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.searchQuery = ''
          this.searchResults = []
          this.hasSearched = false
          this.clearFilters()
        })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 2,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 1
    })
  }

  /**
   * 构建搜索栏
   */
  @Builder
  private buildSearchBar() {
    Column({ space: 12 }) {
      SearchBar({
        query: this.searchQuery,
        placeholder: '搜索照片名称、标签、项目...',
        onSearch: (query: string) => this.executeSearch(query),
        onChange: (query: string) => this.searchQuery = query
      })

      // 搜索历史
      if (!this.hasSearched && this.searchHistory.length > 0 && this.showHistoryPanel) {
        this.buildSearchHistory()
      }
    }
    .width('100%')
    .padding({ horizontal: 16, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建搜索历史
   */
  @Builder
  private buildSearchHistory() {
    Column({ space: 12 }) {
      // 历史记录标题
      Row() {
        Text('搜索历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#666666')

        Blank()

        Button('清除')
          .fontSize(12)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.clearSearchHistory())
      }
      .width('100%')

      // 历史记录列表
      Column({ space: 8 }) {
        ForEach(
          this.searchHistory.slice(0, 10),
          (query: string) => {
            Row() {
              Image($r('app.media.ic_history'))
                .width(16)
                .height(16)
                .fillColor('#999999')
                .margin({ right: 8 })

              Text(query)
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Image($r('app.media.ic_arrow_up_left'))
                .width(16)
                .height(16)
                .fillColor('#CCCCCC')
            }
            .width('100%')
            .padding({ horizontal: 12, vertical: 8 })
            .borderRadius(8)
            .backgroundColor('#F8F8F8')
            .onClick(() => this.useHistorySearch(query))
          },
          (query: string) => `history_${query}`
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding({ horizontal: 16 })
  }

  /**
   * 构建筛选和排序栏
   */
  @Builder
  private buildFilterAndSortBar() {
    Row({ space: 12 }) {
      // 筛选按钮
      Button() {
        Row({ space: 6 }) {
          Image($r('app.media.ic_filter'))
            .width(16)
            .height(16)
            .fillColor(this.hasActiveFilters() ? '#007AFF' : '#666666')

          Text('筛选')
            .fontSize(14)
            .fontColor(this.hasActiveFilters() ? '#007AFF' : '#666666')
        }
      }
      .height(36)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .border({
        width: 1,
        color: this.hasActiveFilters() ? '#007AFF' : '#E0E0E0'
      })
      .onClick(() => this.showFilterPanel = !this.showFilterPanel)

      // 排序按钮
      Button() {
        Row({ space: 6 }) {
          Image($r('app.media.ic_sort'))
            .width(16)
            .height(16)
            .fillColor('#666666')

          Text(this.getSortOrderText(this.sortOrder))
            .fontSize(14)
            .fontColor('#666666')
        }
      }
      .height(36)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .border({ width: 1, color: '#E0E0E0' })
      .onClick(() => {
        // 循环切换排序方式
        if (this.sortOrder === PhotoSortOrder.TAKEN_DESC) {
          this.changeSortOrder(PhotoSortOrder.TAKEN_ASC)
        } else {
          this.changeSortOrder(PhotoSortOrder.TAKEN_DESC)
        }
      })

      Blank()

      // 搜索结果数量
      Text(`${this.searchResults.length} 个结果`)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ right: 12 })

      // 清除筛选
      if (this.hasActiveFilters()) {
        Button('清除筛选')
          .height(36)
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.clearFilters())
      }
    }
    .width('100%')
    .padding({ horizontal: 16, bottom: 8 })
  }

  /**
   * 构建内容区域
   */
  @Builder
  private buildContent() {
    if (!this.hasSearched) {
      // 未搜索状态
      Column() {
        EmptyView({
          icon: $r('app.media.ic_search'),
          message: '搜索照片',
          description: '输入关键词搜索照片，或使用筛选条件精确查找'
        })
      }
      .layoutWeight(1)
      .margin({ horizontal: 16 })
    } else if (this.searchResults.length > 0) {
      // 搜索结果
      PhotoGrid({
        photos: this.searchResults,
        columns: 3,
        onPhotoClick: (photo: Photo, index: number) => this.onPhotoClick(photo, index),
        onLoadMore: () => this.photoStore.loadMore(),
        isLoading: this.photoStore.isLoading,
        hasMore: this.photoStore.hasMore
      })
      .layoutWeight(1)
    } else {
      // 无搜索结果
      Column() {
        EmptyView({
          icon: $r('app.media.ic_search_empty'),
          message: '未找到匹配的照片',
          description: '尝试调整搜索关键词或筛选条件'
        })
      }
      .layoutWeight(1)
      .margin({ horizontal: 16 })
    }
  }

  /**
   * 构建筛选面板
   */
  @Builder
  private buildFilterPanel() {
    Column({ space: 0 }) {
      // 面板标题
      Row() {
        Text('筛选条件')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button('重置')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.clearFilters())

        Button() {
          Image($r('app.media.ic_close'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showFilterPanel = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      Scroll() {
        Column({ space: 20 }) {
          // 项目筛选
          this.buildProjectFilter()

          // 工点筛选
          this.buildSiteFilter()

          // 标签筛选
          this.buildTagFilter()

          // 日期范围筛选
          this.buildDateRangeFilter()
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      // 底部操作栏
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showFilterPanel = false)

        Button('应用')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.applyFilters())
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('70%')
    .position({ x: 0, y: '30%' })
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: -4
    })
    .zIndex(10)
  }

  /**
   * 构建项目筛选
   */
  @Builder
  private buildProjectFilter() {
    Column({ space: 8 }) {
      Text('项目')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 这里应该从ProjectStore获取项目列表
      Text('项目筛选功能待实现')
        .fontSize(14)
        .fontColor('#999999')
        .padding({ vertical: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建工点筛选
   */
  @Builder
  private buildSiteFilter() {
    Column({ space: 8 }) {
      Text('工点')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 这里应该从SiteStore获取工点列表
      Text('工点筛选功能待实现')
        .fontSize(14)
        .fontColor('#999999')
        .padding({ vertical: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建标签筛选
   */
  @Builder
  private buildTagFilter() {
    Column({ space: 8 }) {
      Text('标签')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 这里应该获取常用标签列表
      Text('标签筛选功能待实现')
        .fontSize(14)
        .fontColor('#999999')
        .padding({ vertical: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建日期范围筛选
   */
  @Builder
  private buildDateRangeFilter() {
    Column({ space: 12 }) {
      Text('日期范围')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Row({ space: 12 }) {
        // 开始日期
        Column({ space: 4 }) {
          Text('开始日期')
            .fontSize(12)
            .fontColor('#666666')

          Button(this.dateRange ? this.formatDate(this.dateRange.start) : '选择开始日期')
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .onClick(() => {
              // 实现日期选择器
            })
        }
        .layoutWeight(1)

        // 结束日期
        Column({ space: 4 }) {
          Text('结束日期')
            .fontSize(12)
            .fontColor('#666666')

          Button(this.dateRange ? this.formatDate(this.dateRange.end) : '选择结束日期')
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .onClick(() => {
              // 实现日期选择器
            })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 检查是否有活动筛选条件
   */
  private hasActiveFilters(): boolean {
    return this.selectedProjects.length > 0 ||
           this.selectedSites.length > 0 ||
           this.selectedTags.length > 0 ||
           this.dateRange !== null
  }
}