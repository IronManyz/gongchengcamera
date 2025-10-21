/**
 * 照片详情页面
 * 提供照片全屏查看、信息展示和编辑操作入口
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { Photo } from '../../models/Photo'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { PhotoViewer } from '../../components/photo/PhotoViewer'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

@Entry
@Component
struct PhotoDetailPage {
  private logger = new Logger('PhotoDetailPage')
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private photoId: string = ''
  private fromGallery: boolean = false
  private currentIndex: number = 0

  // 状态管理
  @State private isLoading: boolean = false
  @State private currentPhoto: Photo | null = null
  @State private showInfoPanel: boolean = false
  @State private showDeleteDialog: boolean = false
  @State private showEditOptions: boolean = false
  @State private showShareOptions: boolean = false

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.photoId = params?.photoId || ''
    this.fromGallery = params?.fromGallery || false
    this.currentIndex = params?.index || 0

    this.logger.info('PhotoDetailPage appeared', { photoId: this.photoId, fromGallery: this.fromGallery })

    if (this.photoId) {
      this.loadPhotoDetail()
    }
  }

  aboutToDisappear() {
    this.logger.info('PhotoDetailPage disappeared')
  }

  /**
   * 加载照片详情
   */
  private async loadPhotoDetail() {
    this.isLoading = true
    try {
      this.currentPhoto = await this.photoStore.getPhotoById(this.photoId)
      if (!this.currentPhoto) {
        this.logger.error('照片未找到', { photoId: this.photoId })
        router.back()
      }
    } catch (error) {
      this.logger.error('加载照片详情失败', error)
      router.back()
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 返回处理
   */
  private onBack() {
    if (this.fromGallery) {
      router.back()
    } else {
      // 返回到主页或其他页面
      router.replaceUrl({
        url: 'pages/Index'
      })
    }
  }

  /**
   * 删除照片
   */
  private async deletePhoto() {
    if (!this.currentPhoto) return

    try {
      const success = await this.photoStore.deletePhotos([this.currentPhoto.id])
      if (success) {
        this.showDeleteDialog = false
        this.onBack()
      }
    } catch (error) {
      this.logger.error('删除照片失败', error)
    }
  }

  /**
   * 切换收藏状态
   */
  private async toggleFavorite() {
    if (!this.currentPhoto) return

    try {
      await this.photoStore.updatePhoto(this.currentPhoto.id, {
        isFavorite: !this.currentPhoto.isFavorite
      })
    } catch (error) {
      this.logger.error('切换收藏状态失败', error)
    }
  }

  /**
   * 跳转到编辑页面
   */
  private navigateToEditor() {
    if (!this.currentPhoto) return

    router.pushUrl({
      url: 'pages/editor/PhotoEditorPage',
      params: {
        photoId: this.currentPhoto.id,
        fromDetail: true
      }
    })
  }

  /**
   * 分享照片
   */
  private sharePhoto() {
    if (!this.currentPhoto) return

    // 调用系统分享
    this.showShareOptions = true
  }

  /**
   * 导出照��
   */
  private exportPhoto() {
    if (!this.currentPhoto) return

    router.pushUrl({
      url: 'pages/export/ExportPage',
      params: {
        photoIds: [this.currentPhoto.id]
      }
    })
  }

  /**
   * 查看照片信息
   */
  private toggleInfoPanel() {
    this.showInfoPanel = !this.showInfoPanel
  }

  /**
   * 格式化文件大小
   */
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  /**
   * 格式化日期时间
   */
  private formatDateTime(date: Date): string {
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  }

  /**
   * 格式化坐标
   */
  private formatCoordinate(coordinate: number, type: 'latitude' | 'longitude'): string {
    const absCoordinate = Math.abs(coordinate)
    const degrees = Math.floor(absCoordinate)
    const minutes = Math.floor((absCoordinate - degrees) * 60)
    const seconds = Math.round(((absCoordinate - degrees) * 60 - minutes) * 60)

    const direction = type === 'latitude'
      ? (coordinate >= 0 ? 'N' : 'S')
      : (coordinate >= 0 ? 'E' : 'W')

    return `${degrees}°${minutes}'${seconds}"${direction}`
  }

  build() {
    Stack() {
      // 主要内容区域
      if (this.currentPhoto) {
        this.buildMainContent()
      }

      // 顶部操作栏
      this.buildTopActionBar()

      // 底部操作栏
      this.buildBottomActionBar()

      // 照片信息面板
      if (this.showInfoPanel && this.currentPhoto) {
        this.buildInfoPanel()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 删除确认对话框
      if (this.showDeleteDialog && this.currentPhoto) {
        ConfirmDialog({
          title: '删除照片',
          message: '确定要删除这张照片吗？此操作不可恢复。',
          confirmText: '删除',
          cancelText: '取消',
          onConfirm: () => this.deletePhoto(),
          onCancel: () => this.showDeleteDialog = false
        })
      }

      // 编辑选项对话框
      if (this.showEditOptions) {
        this.buildEditOptionsDialog()
      }

      // 分享选项对话框
      if (this.showShareOptions) {
        this.buildShareOptionsDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  /**
   * 构建主要内容区域
   */
  @Builder
  private buildMainContent() {
    PhotoViewer({
      photo: this.currentPhoto!,
      showControls: false,
      enableZoom: true,
      enablePan: true,
      onTap: () => {
        // 点击切换控制栏显示/隐藏
      }
    })
    .width('100%')
    .height('100%')
  }

  /**
   * 构建顶部操作栏
   */
  @Builder
  private buildTopActionBar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.onBack())

      Blank()

      // 操作按钮组
      Row({ space: 16 }) {
        // 信息按钮
        Button() {
          Image($r('app.media.ic_info'))
            .width(24)
            .height(24)
            .fillColor(this.showInfoPanel ? '#007AFF' : '#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.toggleInfoPanel())

        // 收藏按钮
        Button() {
          Image(this.currentPhoto?.isFavorite ? $r('app.media.ic_favorite_filled') : $r('app.media.ic_favorite'))
            .width(24)
            .height(24)
            .fillColor(this.currentPhoto?.isFavorite ? '#FF3B30' : '#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.toggleFavorite())

        // 更多操作
        Button() {
          Image($r('app.media.ic_more'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showEditOptions = true)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .position({ x: 0, y: 0 })
    .justifyContent(FlexAlign.SpaceBetween)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['rgba(0,0,0,0.7)', 0.0], ['rgba(0,0,0,0)', 1.0]]
    })
  }

  /**
   * 构建底部操作栏
   */
  @Builder
  private buildBottomActionBar() {
    Column() {
      // 照片名称
      if (this.currentPhoto?.name) {
        Text(this.currentPhoto.name)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('90%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })
      }

      // 操作按钮组
      Row({ space: 24 }) {
        // 编辑按钮
        Column({ space: 4 }) {
          Button() {
            Image($r('app.media.ic_edit'))
              .width(24)
              .height(24)
              .fillColor('#FFFFFF')
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(24)
          .onClick(() => this.navigateToEditor())

          Text('编辑')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }

        // 分享按钮
        Column({ space: 4 }) {
          Button() {
            Image($r('app.media.ic_share'))
              .width(24)
              .height(24)
              .fillColor('#FFFFFF')
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(24)
          .onClick(() => this.sharePhoto())

          Text('分享')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }

        // 导出按钮
        Column({ space: 4 }) {
          Button() {
            Image($r('app.media.ic_export'))
              .width(24)
              .height(24)
              .fillColor('#FFFFFF')
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(24)
          .onClick(() => this.exportPhoto())

          Text('导出')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }

        // 删除按钮
        Column({ space: 4 }) {
          Button() {
            Image($r('app.media.ic_delete'))
              .width(24)
              .height(24)
              .fillColor('#FFFFFF')
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(255,59,48,0.7)')
          .borderRadius(24)
          .onClick(() => this.showDeleteDialog = true)

          Text('删除')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .position({ x: 0, y: '100%' })
    .translate({ y: -120 })
    .alignItems(HorizontalAlign.Center)
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['rgba(0,0,0,0.7)', 0.0], ['rgba(0,0,0,0)', 1.0]]
    })
  }

  /**
   * 构建照片信息面板
   */
  @Builder
  private buildInfoPanel() {
    Column({ space: 16 }) {
      // 面板标题
      Row() {
        Text('照片信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button() {
          Image($r('app.media.ic_close'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showInfoPanel = false)
      }
      .width('100%')
      .padding({ bottom: 8 })

      Scroll() {
        Column({ space: 20 }) {
          // 基本信息
          this.buildInfoSection('基本信息', [
            { label: '文件名', value: this.currentPhoto!.name },
            { label: '拍摄时间', value: this.formatDateTime(this.currentPhoto!.takenAt) },
            { label: '文件大小', value: this.formatFileSize(this.currentPhoto!.fileSize) },
            { label: '分辨率', value: `${this.currentPhoto!.width} × ${this.currentPhoto!.height}` }
          ])

          // 拍摄信息
          if (this.currentPhoto!.cameraMake || this.currentPhoto!.cameraModel) {
            this.buildInfoSection('拍摄信息', [
              { label: '相机品牌', value: this.currentPhoto!.cameraMake || '未知' },
              { label: '相机型号', value: this.currentPhoto!.cameraModel || '未知' },
              { label: '镜头焦距', value: this.currentPhoto!.focalLength ? `${this.currentPhoto!.focalLength}mm` : '未知' },
              { label: 'ISO', value: this.currentPhoto!.iso ? `${this.currentPhoto!.iso}` : '未知' },
              { label: '曝光时间', value: this.currentPhoto!.exposureTime || '未知' },
              { label: '光圈', value: this.currentPhoto!.aperture || '未知' }
            ])
          }

          // 位置信息
          if (this.currentPhoto!.latitude !== null && this.currentPhoto!.longitude !== null) {
            this.buildInfoSection('位置信息', [
              { label: '纬度', value: this.formatCoordinate(this.currentPhoto!.latitude!, 'latitude') },
              { label: '经度', value: this.formatCoordinate(this.currentPhoto!.longitude!, 'longitude') },
              { label: '海拔', value: this.currentPhoto!.altitude ? `${this.currentPhoto!.altitude}m` : '未知' }
            ])
          }

          // 项目信息
          if (this.currentPhoto!.projectId) {
            this.buildInfoSection('项目信息', [
              { label: '项目ID', value: this.currentPhoto!.projectId },
              { label: '工点ID', value: this.currentPhoto!.siteId || '未分配' }
            ])
          }

          // 标签
          if (this.currentPhoto!.tags && this.currentPhoto!.tags.length > 0) {
            Column({ space: 8 }) {
              Text('标签')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')

              Flex({ wrap: FlexWrap.Wrap, spacing: 8 }) {
                ForEach(
                  this.currentPhoto!.tags,
                  (tag: string) => {
                    Text(tag)
                      .fontSize(12)
                      .fontColor('#007AFF')
                      .padding({ horizontal: 8, vertical: 4 })
                      .backgroundColor('#007AFF20')
                      .borderRadius(12)
                  },
                  (tag: string) => tag
                )
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('70%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding(20)
    .position({ x: 0, y: '30%' })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: -4
    })
  }

  /**
   * 构建信息分组
   */
  @Builder
  private buildInfoSection(title: string, items: { label: string, value: string }[]) {
    Column({ space: 12 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Column({ space: 8 }) {
        ForEach(
          items,
          (item: { label: string, value: string }) => {
            Row() {
              Text(item.label)
                .fontSize(14)
                .fontColor('#666666')
                .width(80)

              Text(item.value)
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Divider()
              .width('100%')
              .color('#F0F0F0')
          },
          (item: { label: string, value: string }) => item.label
        )
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建编辑选项对话框
   */
  @Builder
  private buildEditOptionsDialog() {
    Column({ space: 0 }) {
      // 编辑选项
      ForEach(
        [
          { key: 'rotate', label: '旋转', icon: $r('app.media.ic_rotate') },
          { key: 'crop', label: '裁剪', icon: $r('app.media.ic_crop') },
          { key: 'adjust', label: '调整', icon: $r('app.media.ic_adjust') },
          { key: 'annotate', label: '标注', icon: $r('app.media.ic_annotate') },
          { key: 'doodle', label: '涂鸦', icon: $r('app.media.ic_doodle') }
        ],
        (option: { key: string, label: string, icon: Resource }) => {
          Row() {
            Image(option.icon)
              .width(20)
              .height(20)
              .fillColor('#333333')
              .margin({ right: 12 })

            Text(option.label)
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)

            Image($r('app.media.ic_arrow_right'))
              .width(16)
              .height(16)
              .fillColor('#CCCCCC')
          }
          .width('100%')
          .height(48)
          .padding({ horizontal: 16 })
          .onClick(() => {
            this.showEditOptions = false
            this.navigateToEditor()
          })

          if (option.key !== 'doodle') {
            Divider().color('#F0F0F0')
          }
        },
        (option: { key: string, label: string, icon: Resource }) => option.key
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
    .position({ x: 0, y: '50%' })
    .translate({ y: -120 })
  }

  /**
   * 构建分享选项对话框
   */
  @Builder
  private buildShareOptionsDialog() {
    Column({ space: 0 }) {
      // 分享选项
      ForEach(
        [
          { key: 'system', label: '系统分享', icon: $r('app.media.ic_share_system') },
          { key: 'wechat', label: '微信', icon: $r('app.media.ic_wechat') },
          { key: 'qq', label: 'QQ', icon: $r('app.media.ic_qq') },
          { key: 'link', label: '复制链接', icon: $r('app.media.ic_link') }
        ],
        (option: { key: string, label: string, icon: Resource }) => {
          Row() {
            Image(option.icon)
              .width(20)
              .height(20)
              .fillColor('#333333')
              .margin({ right: 12 })

            Text(option.label)
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)
          }
          .width('100%')
          .height(48)
          .padding({ horizontal: 16 })
          .onClick(() => {
            this.showShareOptions = false
            // 实现相应的分享逻辑
          })

          if (option.key !== 'link') {
            Divider().color('#F0F0F0')
          }
        },
        (option: { key: string, label: string, icon: Resource }) => option.key
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
    .position({ x: 0, y: '50%' })
    .translate({ y: -80 })
  }
}