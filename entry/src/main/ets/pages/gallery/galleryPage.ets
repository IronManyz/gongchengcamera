/**
 * 相册主页面
 * 提供相册浏览和管理功能，包括网格展示、筛选和批量选择功能
 */

import router from '@ohos.router'
import { vibrator } from '@kit.SensorServiceKit'
import { Logger } from '../../utils/Logger'
import { GalleryStore, GalleryViewMode, BatchOperationType } from '../../store/gallery/GalleryStore'
import { PhotoGrid, TimelinePhotoGrid, WaterfallPhotoGrid } from '../../components/photo/PhotoGrid'
import { SearchBar } from '../../components/common/SearchBar'
import { EmptyView } from '../../components/common/EmptyView'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'
import { Photo } from '../../models/Photo'

@Entry
@Component
struct GalleryPage {
  private logger = new Logger('GalleryPage')
  private galleryStore = GalleryStore.getInstance()

  // 状态管理
  @State private isLoading: boolean = false
  @State private isRefreshing: boolean = false
  @State private searchQuery: string = ''
  @State private showFilterPanel: boolean = false
  @State private showBatchOperationDialog: boolean = false
  @State private showViewModeDialog: boolean = false
  @State private pendingBatchOperation: BatchOperationType | null = null
  @State private selectedProjectId: string = ''

  aboutToAppear() {
    this.logger.info('GalleryPage appeared')
    this.loadGalleryData()
  }

  aboutToDisappear() {
    this.logger.info('GalleryPage disappeared')
    this.galleryStore.exitSelectionMode()
  }

  /**
   * 加载相册数据
   */
  private async loadGalleryData() {
    this.isLoading = true
    try {
      if (!this.galleryStore['isInitialized']) {
        await this.galleryStore.refresh()
      }
    } catch (error) {
      this.logger.error('加载相册数据失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 下拉刷新
   */
  private async onRefresh() {
    this.isRefreshing = true
    try {
      await this.galleryStore.refresh()
    } catch (error) {
      this.logger.error('刷新相册数据失败', error)
    } finally {
      this.isRefreshing = false
    }
  }

  /**
   * 搜索处理
   */
  private onSearch(query: string) {
    this.searchQuery = query
    // 这里需要调用PhotoStore的搜索功能
    this.logger.info('搜索照片', { query })
  }

  /**
   * 切换视图模式
   */
  private onViewModeChange(mode: GalleryViewMode) {
    this.galleryStore.setViewMode(mode)
    this.showViewModeDialog = false
  }

  /**
   * 照片点击处理
   */
  private onPhotoClick(photo: Photo, index: number) {
    if (this.galleryStore.isSelectionMode) {
      this.galleryStore.togglePhotoSelection(photo.id)
    } else {
      router.pushUrl({
        url: 'pages/gallery/PhotoDetailPage',
        params: {
          photoId: photo.id,
          fromGallery: true
        }
      })
    }
  }

  /**
   * 照片��按处理
   */
  private onPhotoLongPress(photo: Photo, index: number) {
    if (!this.galleryStore.isSelectionMode) {
      // 触觉反馈
      try {
        vibrator.startVibration({
          mode: vibrator.VibratorMode.PULSE,
          duration: 100,
          intensity: 150
        })
      } catch (error) {
        // 震动不是必需功能，静默忽略错误
      }

      // 进入选择模式并选择该照片
      this.galleryStore.enterSelectionMode()
      this.galleryStore.togglePhotoSelection(photo.id)
    } else {
      // 已在选择模式下，切换选择状态
      this.galleryStore.togglePhotoSelection(photo.id)
    }
  }

  /**
   * 选择变化处理
   */
  private onSelectionChange(photoId: string, selected: boolean) {
    this.galleryStore.togglePhotoSelection(photoId)
  }

  /**
   * 切换选择模式
   */
  private toggleSelectionMode() {
    this.galleryStore.toggleSelectionMode()
  }

  /**
   * 选择所有照片
   */
  private selectAllPhotos() {
    this.galleryStore.selectAllPhotos()
  }

  /**
   * 清空选择
   */
  private clearSelection() {
    this.galleryStore.clearSelection()
  }

  /**
   * 显示筛选面板
   */
  private showFilterOptions() {
    this.galleryStore.toggleFilterPanel()
  }

  /**
   * 显示批量操作对话框
   */
  private showBatchOperation(operation: BatchOperationType) {
    this.pendingBatchOperation = operation
    this.showBatchOperationDialog = true
  }

  /**
   * 执行批量操作
   */
  private async executeBatchOperation() {
    if (!this.pendingBatchOperation) return

    const selectedPhotos = this.galleryStore.getSelectedPhotos()
    const photoIds = selectedPhotos.map(photo => photo.id)

    try {
      await this.galleryStore.executeBatchOperation({
        type: this.pendingBatchOperation,
        photoIds: photoIds,
        data: this.pendingBatchOperation === BatchOperationType.ADD_TO_PROJECT
          ? { projectId: this.selectedProjectId }
          : undefined
      })

      this.showBatchOperationDialog = false
      this.pendingBatchOperation = null
      this.selectedProjectId = ''
    } catch (error) {
      this.logger.error('批量操作失败', error)
    }
  }

  /**
   * 跳转到搜索页面
   */
  private navigateToSearch() {
    router.pushUrl({
      url: 'pages/gallery/PhotoSearchPage'
    })
  }

  /**
   * 获取视图模式文本
   */
  private getViewModeText(mode: GalleryViewMode): string {
    switch (mode) {
      case GalleryViewMode.GRID:
        return '网格'
      case GalleryViewMode.LIST:
        return '列表'
      case GalleryViewMode.TIMELINE:
        return '时间线'
      default:
        return '网格'
    }
  }

  /**
   * 获取批量操作文本
   */
  private getBatchOperationText(operation: BatchOperationType): string {
    switch (operation) {
      case BatchOperationType.DELETE:
        return '删除'
      case BatchOperationType.EXPORT:
        return '导出'
      case BatchOperationType.ADD_TO_PROJECT:
        return '添加到项目'
      case BatchOperationType.ADD_TAGS:
        return '添加标签'
      case BatchOperationType.REMOVE_TAGS:
        return '移除标签'
      case BatchOperationType.SET_FAVORITE:
        return '设为收藏'
      case BatchOperationType.UNSET_FAVORITE:
        return '取消收藏'
      default:
        return '操作'
    }
  }

  build() {
    Column() {
      Blank()
        .height(24)

      // 顶部导航栏
      this.buildTopBar()

      // 搜索和筛选栏
      this.buildSearchAndFilterBar()

      // 相册内容区域
      this.buildGalleryContent()

      // 批量操作底部栏
      if (this.galleryStore.isSelectionMode) {
        this.buildBatchActionBottomBar()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 批量操作确认对话框
      if (this.showBatchOperationDialog) {
        this.buildBatchOperationDialog()
      }

      // 视图模式选择对话框
      if (this.showViewModeDialog) {
        this.buildViewModeDialog()
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
      // 标题
      Text('相册')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      // 操作按钮
      Row({ space: 12 }) {
        // 搜索按钮
        Button() {
          Image($r('app.media.ic_search'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.navigateToSearch())

        // 选择模式按钮
        if (this.galleryStore.isSelectionMode) {
          // 显示选择状态信息
          Row({ space: 8 }) {
            Text('已选择')
              .fontSize(14)
              .fontColor('#666666')
            Text(`${this.galleryStore.selectedPhotos.size}`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007AFF')
            Text('项')
              .fontSize(14)
              .fontColor('#666666')
          }
          .height(40)
          .padding({ horizontal: 12 })
          .backgroundColor('#F0F8FF')
          .borderRadius(20)
          .border({ width: 1, color: '#B3D8FF' })
          .onClick(() => this.toggleSelectionMode())
        } else {
          Button() {
            Image($r('app.media.ic_select'))
              .width(24)
              .height(24)
              .fillColor('#666666')
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.toggleSelectionMode())
        }
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
   * 构建搜索和筛选栏
   */
  @Builder
  private buildSearchAndFilterBar() {
    Column({ space: 12 }) {
      // 搜索栏
      SearchBar({
        query: this.searchQuery,
        placeholder: '搜索照片...',
        onSearch: (query: string) => this.onSearch(query),
        onChange: (query: string) => this.searchQuery = query
      })

      // 筛选和控制栏
      Row({ space: 12 }) {
        // 筛选按钮
        Button() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_filter'))
              .width(16)
              .height(16)
              .fillColor(this.galleryStore.hasActiveFilter() ? '#007AFF' : '#666666')

            Text('筛选')
              .fontSize(14)
              .fontColor(this.galleryStore.hasActiveFilter() ? '#007AFF' : '#666666')
          }
        }
        .height(36)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({
          width: 1,
          color: this.galleryStore.hasActiveFilter() ? '#007AFF' : '#E0E0E0'
        })
        .onClick(() => this.showFilterOptions())

        // 视图模式按钮
        Button() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_grid'))
              .width(16)
              .height(16)
              .fillColor('#666666')

            Text(this.getViewModeText(this.galleryStore.viewMode))
              .fontSize(14)
              .fontColor('#666666')
          }
        }
        .height(36)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({ width: 1, color: '#E0E0E0' })
        .onClick(() => this.showViewModeDialog = true)

        Blank()

        // 统计信息
        Text(`${this.galleryStore['photoStore']?.photos?.length || 0} 张`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 12 })

        // 清空筛选
        if (this.galleryStore.hasActiveFilter()) {
          Button('清空')
            .height(36)
            .fontSize(14)
            .fontColor('#666666')
            .backgroundColor(Color.Transparent)
            .onClick(() => this.galleryStore.clearFilter())
        }
      }
      .width('100%')
      .padding({ horizontal: 16 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建相册内容区域
   */
  @Builder
  private buildGalleryContent() {
    Refresh({ refreshing: $$isRefreshing, friction: 100 }) {
      const photos = this.galleryStore['photoStore']?.photos || []

      if (photos.length > 0) {
        // 根据视图模式显示不同的网格
        if (this.galleryStore.viewMode === GalleryViewMode.TIMELINE) {
          TimelinePhotoGrid({
            photos: photos,
            showSelection: this.galleryStore.isSelectionMode,
            selectedPhotos: this.galleryStore.selectedPhotos,
            onPhotoClick: (photo: Photo, index: number) => this.onPhotoClick(photo, index),
            onPhotoLongPress: (photo: Photo, index: number) => this.onPhotoLongPress(photo, index),
            onSelectionChange: (photoId: string, selected: boolean) => this.onSelectionChange(photoId, selected),
            onLoadMore: () => this.galleryStore.loadMore(),
            isLoading: this.galleryStore['photoStore']?.isLoading || false,
            hasMore: this.galleryStore['photoStore']?.hasMore || true
          })
        } else {
          PhotoGrid({
            photos: photos,
            columns: this.galleryStore.getGridColumns(),
            showSelection: this.galleryStore.isSelectionMode,
            selectedPhotos: this.galleryStore.selectedPhotos,
            onPhotoClick: (photo: Photo, index: number) => this.onPhotoClick(photo, index),
            onPhotoLongPress: (photo: Photo, index: number) => this.onPhotoLongPress(photo, index),
            onSelectionChange: (photoId: string, selected: boolean) => this.onSelectionChange(photoId, selected),
            onLoadMore: () => this.galleryStore.loadMore(),
            isLoading: this.galleryStore['photoStore']?.isLoading || false,
            hasMore: this.galleryStore['photoStore']?.hasMore || true
          })
        }
      } else {
        EmptyView({
          icon: $r('app.media.ic_empty_photos'),
          message: '暂无照片',
          description: '点击拍照按钮拍摄第一张照片'
        })
          .layoutWeight(1)
          .margin({ horizontal: 16 })
      }
    }
    .layoutWeight(1)
    .onRefresh(() => this.onRefresh())
  }

  /**
   * 构建批量操作底部栏
   */
  @Builder
  private buildBatchActionBottomBar() {
    Column() {
      // 选择信息
      Row() {
        Text(`已选择 ${this.galleryStore.selectedPhotos.size} 张`)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        // 全选/清空按钮
        Button(this.galleryStore.selectedPhotos.size === this.galleryStore['photoStore']?.photos.length ? '清空' : '全选')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.galleryStore.selectedPhotos.size === this.galleryStore['photoStore']?.photos.length) {
              this.clearSelection()
            } else {
              this.selectAllPhotos()
            }
          })
          .onLongPress(() => {
            // 长按全选功能：如果已全选则清空，否则全选
            if (this.galleryStore.selectedPhotos.size === this.galleryStore['photoStore']?.photos.length) {
              this.clearSelection()
            } else {
              this.selectAllPhotos()
            }
            // 震动反馈
            try {
              vibrator.startVibration({
                mode: vibrator.VibratorMode.SHORT,
                duration: 80,
                intensity: 180
              })
            } catch (error) {
              // 震动不是必需功能，静默忽略错误
            }
          })
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 8 })

      // 批量操作按钮
      Row({ space: 12 }) {
        Button('删除')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF3B30')
          .borderRadius(20)
          .layoutWeight(1)
          .onClick(() => this.showBatchOperation(BatchOperationType.DELETE))

        Button('导出')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(20)
          .layoutWeight(1)
          .onClick(() => this.showBatchOperation(BatchOperationType.EXPORT))

        Button('更多')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#34C759')
          .borderRadius(20)
          .layoutWeight(1)
          .onClick(() => {
            // 显示更多批量操作选项
          })
      }
      .width('100%')
      .padding({ horizontal: 16, bottom: 20 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: -2
    })
  }

  /**
   * 构建批量操作确认对话框
   */
  @Builder
  private buildBatchOperationDialog() {
    ConfirmDialog({
      title: this.getBatchOperationText(this.pendingBatchOperation!),
      message: `确定要${this.getBatchOperationText(this.pendingBatchOperation!)} ${this.galleryStore.selectedPhotos.size} 张照片吗？此操作不可恢复。`,
      confirmText: '确认',
      cancelText: '取消',
      onConfirm: () => this.executeBatchOperation(),
      onCancel: () => {
        this.showBatchOperationDialog = false
        this.pendingBatchOperation = null
      }
    })
  }

  /**
   * 构建视图模式选择对话框
   */
  @Builder
  private buildViewModeDialog() {
    Column({ space: 0 }) {
      // 视图模式选项
      ForEach(
        [
          { key: GalleryViewMode.GRID, label: '网格视图' },
          { key: GalleryViewMode.LIST, label: '列表视图' },
          { key: GalleryViewMode.TIMELINE, label: '时间线视图' }
        ],
        (mode: { key: GalleryViewMode, label: string }) => {
          Row() {
            Text(mode.label)
              .fontSize(16)
              .fontColor(this.galleryStore.viewMode === mode.key ? '#007AFF' : '#333333')
              .layoutWeight(1)

            if (this.galleryStore.viewMode === mode.key) {
              Image($r('app.media.ic_check'))
                .width(20)
                .height(20)
                .fillColor('#007AFF')
            }
          }
          .width('100%')
          .height(48)
          .padding({ horizontal: 16 })
          .onClick(() => this.onViewModeChange(mode.key))

          if (mode.key !== GalleryViewMode.TIMELINE) {
            Divider().color('#F0F0F0')
          }
        },
        (mode: { key: GalleryViewMode, label: string }) => mode.key
      )
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ horizontal: 16 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 2
    })
    .zIndex(10)
  }
}
