/**
 * 分享页面
 * 提供内容分享功能，包括系统分享集成、分享内容配置和分享历史记录
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 分享类型枚举
 */
enum ShareType {
  SINGLE_PHOTO = 'single_photo',    // 单张照片
  MULTIPLE_PHOTOS = 'multiple_photos', // 多张照片
  PROJECT_REPORT = 'project_report',   // 项目报告
  ALBUM = 'album',                    // 相册
  CUSTOM = 'custom'                   // 自定义内容
}

/**
 * 分享平台枚举
 */
enum SharePlatform {
  SYSTEM = 'system',       // 系统分享
  WECHAT = 'wechat',       // 微信
  WECHAT_MOMENTS = 'wechat_moments', // 朋友圈
  QQ = 'qq',              // QQ
  WEIBO = 'weibo',        // 微博
  DINGTALK = 'dingtalk',  // 钉钉
  EMAIL = 'email',        // 邮件
  BLUETOOTH = 'bluetooth' // 蓝牙
}

/**
 * 分享内容配置接口
 */
interface ShareContent {
  type: ShareType
  title: string
  description: string
  photos: string[]           // 照片ID列表
  includeMetadata: boolean   // 包含元数据
  includeWatermark: boolean  // 包含水印
  compression: 'none' | 'low' | 'medium' | 'high'  // 压缩级别
  format: 'original' | 'jpg' | 'png' | 'webp'      // 输出格式
  maxSize: number           // 最大文件大小 (MB)
}

/**
 * 分享记录接口
 */
interface ShareRecord {
  id: string
  content: ShareContent
  platform: SharePlatform
  status: 'pending' | 'success' | 'failed' | 'cancelled'
  sharedAt: Date
  recipient?: string       // 接收者
  filePath?: string        // 文件路径
  error?: string          // 错误信息
}

/**
 * 分享任务接口
 */
interface ShareTask {
  id: string
  name: string
  content: ShareContent
  platforms: SharePlatform[]
  status: 'preparing' | 'sharing' | 'completed' | 'failed'
  progress: number
  createdAt: Date
  completedAt?: Date
  records: ShareRecord[]
}

@Entry
@Component
struct SharePage {
  private logger = new Logger('SharePage')
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private photoIds: string[] = []
  private projectId: string = ''

  // 状态管理
  @State private isLoading: boolean = false
  @State private currentTab: 'content' | 'platform' | 'history' = 'content'
  @State private selectedPhotos: any[] = []
  @State private shareContent: ShareContent = {
    type: ShareType.MULTIPLE_PHOTOS,
    title: '照片分享',
    description: '来自 Engineering Camera',
    photos: [],
    includeMetadata: false,
    includeWatermark: false,
    compression: 'medium',
    format: 'jpg',
    maxSize: 10
  }
  @State private shareTasks: ShareTask[] = []
  @State private shareHistory: ShareRecord[] = []

  // 对话框状态
  @State private showContentDialog: boolean = false
  @State private showPlatformDialog: boolean = false
  @State private showShareDialog: boolean = false
  @State private showPreviewDialog: boolean = false
  @State private selectedTask: ShareTask | null = null

  // 分享状态
  @State private isSharing: boolean = false
  @State private currentShareProgress: number = 0
  @State private selectedPlatforms: SharePlatform[] = [SharePlatform.SYSTEM]

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.photoIds = params?.photoIds || []
    this.projectId = params?.projectId || ''

    this.logger.info('SharePage appeared', { photoIds: this.photoIds, projectId: this.projectId })

    this.loadSelectedPhotos()
    this.loadShareHistory()
  }

  aboutToDisappear() {
    this.logger.info('SharePage disappeared')
  }

  /**
   * 加载选中的照片
   */
  private async loadSelectedPhotos() {
    this.isLoading = true
    try {
      if (this.photoIds.length > 0) {
        // 根据ID加载照片
        this.selectedPhotos = this.photoIds.map(id => ({ id }))
        this.shareContent.photos = this.photoIds
      } else {
        // 加载所有照片
        this.selectedPhotos = this.photoStore.photos
        this.shareContent.photos = this.selectedPhotos.map(photo => photo.id)
      }

      // 根据照片数量设置分享类型
      if (this.selectedPhotos.length === 1) {
        this.shareContent.type = ShareType.SINGLE_PHOTO
        this.shareContent.title = '照片分享'
      } else if (this.selectedPhotos.length > 1) {
        this.shareContent.type = ShareType.MULTIPLE_PHOTOS
        this.shareContent.title = `${this.selectedPhotos.length}张照片分享`
      }
    } catch (error) {
      this.logger.error('加载照片失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 加载分享历史
   */
  private async loadShareHistory() {
    try {
      // 模拟加载历史记录
      this.shareHistory = [
        {
          id: '1',
          content: {
            type: ShareType.MULTIPLE_PHOTOS,
            title: '项目照片分享',
            description: '工程项目照片',
            photos: ['1', '2', '3'],
            includeMetadata: false,
            includeWatermark: true,
            compression: 'medium',
            format: 'jpg',
            maxSize: 10
          },
          platform: SharePlatform.SYSTEM,
          status: 'success',
          sharedAt: new Date(Date.now() - 86400000), // 1天前
          filePath: '/storage/shared/photos_20240101.zip'
        },
        {
          id: '2',
          content: {
            type: ShareType.SINGLE_PHOTO,
            title: '现场照片',
            description: '工地现场照片',
            photos: ['1'],
            includeMetadata: true,
            includeWatermark: false,
            compression: 'none',
            format: 'original',
            maxSize: 10
          },
          platform: SharePlatform.WECHAT,
          status: 'success',
          sharedAt: new Date(Date.now() - 172800000), // 2天前
          recipient: '张三'
        }
      ]
    } catch (error) {
      this.logger.error('加载分享历史失败', error)
    }
  }

  /**
   * 切换标签
   */
  private switchTab(tab: 'content' | 'platform' | 'history') {
    this.currentTab = tab
  }

  /**
   * 配置分享内容
   */
  private configureContent() {
    this.showContentDialog = true
  }

  /**
   * 选择分享平台
   */
  private selectPlatforms() {
    this.showPlatformDialog = true
  }

  /**
   * 开始分享
   */
  private async startShare() {
    if (this.selectedPhotos.length === 0 || this.selectedPlatforms.length === 0) {
      return
    }

    this.isSharing = true
    this.currentShareProgress = 0

    try {
      this.logger.info('开始分享', {
        photoCount: this.selectedPhotos.length,
        platforms: this.selectedPlatforms
      })

      // 创建分享任务
      const task: ShareTask = {
        id: Date.now().toString(),
        name: `${this.shareContent.title} - ${new Date().toLocaleString()}`,
        content: { ...this.shareContent },
        platforms: [...this.selectedPlatforms],
        status: 'preparing',
        progress: 0,
        createdAt: new Date(),
        records: []
      }

      this.shareTasks.unshift(task)

      // 模拟分享过程
      task.status = 'sharing'

      for (let i = 0; i < this.selectedPlatforms.length; i++) {
        const platform = this.selectedPlatforms[i]

        // 创建分享记录
        const record: ShareRecord = {
          id: `${task.id}_${i}`,
          content: { ...this.shareContent },
          platform: platform,
          status: 'pending',
          sharedAt: new Date()
        }

        task.records.push(record)

        // 模拟分享进度
        for (let j = 0; j <= 100; j += 10) {
          this.currentShareProgress = Math.round(((i * 100 + j) / (this.selectedPlatforms.length * 100)) * 100)
          task.progress = this.currentShareProgress
          await new Promise(resolve => setTimeout(resolve, 50))
        }

        // 完成分享
        record.status = 'success'
        record.sharedAt = new Date()
        record.filePath = `/storage/shared/share_${Date.now()}.${this.shareContent.format}`

        // 添加到历史记录
        this.shareHistory.unshift(record)
      }

      // 完成任务
      task.status = 'completed'
      task.completedAt = new Date()

      this.logger.info('分享完成', { taskId: task.id })
      this.showShareDialog = false

      // 切换到历史标签
      this.currentTab = 'history'
    } catch (error) {
      this.logger.error('分享失败', error)
    } finally {
      this.isSharing = false
      this.currentShareProgress = 0
    }
  }

  /**
   * 预览分享内容
   */
  private previewShare() {
    this.showPreviewDialog = true
  }

  /**
   * 删除历史记录
   */
  private deleteRecord(record: ShareRecord) {
    const index = this.shareHistory.findIndex(r => r.id === record.id)
    if (index > -1) {
      this.shareHistory.splice(index, 1)
    }
  }

  /**
   * 重新分享
   */
  private async reshareRecord(record: ShareRecord) {
    this.shareContent = { ...record.content }
    this.selectedPlatforms = [record.platform]
    await this.startShare()
  }

  /**
   * 获取分享类型名称
   */
  private getShareTypeName(type: ShareType): string {
    switch (type) {
      case ShareType.SINGLE_PHOTO:
        return '单张照片'
      case ShareType.MULTIPLE_PHOTOS:
        return '多张照片'
      case ShareType.PROJECT_REPORT:
        return '项目报告'
      case ShareType.ALBUM:
        return '相册'
      case ShareType.CUSTOM:
        return '自定义内容'
      default:
        return '多张照片'
    }
  }

  /**
   * 获取平台名称
   */
  private getPlatformName(platform: SharePlatform): string {
    switch (platform) {
      case SharePlatform.SYSTEM:
        return '系统分享'
      case SharePlatform.WECHAT:
        return '微信'
      case SharePlatform.WECHAT_MOMENTS:
        return '朋友圈'
      case SharePlatform.QQ:
        return 'QQ'
      case SharePlatform.WEIBO:
        return '微博'
      case SharePlatform.DINGTALK:
        return '钉钉'
      case SharePlatform.EMAIL:
        return '邮件'
      case SharePlatform.BLUETOOTH:
        return '蓝牙'
      default:
        return '系统分享'
    }
  }

  /**
   * 获取状态文本
   */
  private getStatusText(status: string): string {
    switch (status) {
      case 'pending':
        return '等待中'
      case 'preparing':
        return '准备中'
      case 'sharing':
        return '分享中'
      case 'success':
      case 'completed':
        return '已完成'
      case 'failed':
        return '失败'
      case 'cancelled':
        return '已取消'
      default:
        return '未知'
    }
  }

  /**
   * 获取状态颜色
   */
  private getStatusColor(status: string): string {
    switch (status) {
      case 'pending':
      case 'preparing':
        return '#FF9500'
      case 'sharing':
        return '#007AFF'
      case 'success':
      case 'completed':
        return '#34C759'
      case 'failed':
        return '#FF3B30'
      case 'cancelled':
        return '#666666'
      default:
        return '#666666'
    }
  }

  /**
   * 获取压缩级别名称
   */
  private getCompressionName(compression: string): string {
    switch (compression) {
      case 'none':
        return '无压缩'
      case 'low':
        return '低压缩'
      case 'medium':
        return '中等压缩'
      case 'high':
        return '高压缩'
      default:
        return '中等压缩'
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 标签切换
      this.buildTabBar()

      // 内容区域
      if (this.currentTab === 'content') {
        this.buildContentTab()
      } else if (this.currentTab === 'platform') {
        this.buildPlatformTab()
      } else {
        this.buildHistoryTab()
      }

      // 内容配置对话框
      if (this.showContentDialog) {
        this.buildContentDialog()
      }

      // 平台选择对话框
      if (this.showPlatformDialog) {
        this.buildPlatformDialog()
      }

      // 分享确认对话框
      if (this.showShareDialog) {
        ConfirmDialog({
          title: '确认分享',
          message: `确定要分享 ${this.selectedPhotos.length} 张照片到 ${this.selectedPlatforms.length} 个平台吗？`,
          confirmText: '分享',
          cancelText: '取消',
          onConfirm: () => this.startShare(),
          onCancel: () => this.showShareDialog = false
        })
      }

      // 预览对话框
      if (this.showPreviewDialog) {
        this.buildPreviewDialog()
      }

      // 分享进度对话框
      if (this.isSharing) {
        this.buildShareProgressDialog()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
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
      .onClick(() => router.back())

      // 标题
      Text('内容分享')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 操作按钮
      if ((this.currentTab === 'content' && this.selectedPhotos.length > 0) ||
          (this.currentTab === 'platform' && this.selectedPlatforms.length > 0)) {
        Button('分享')
          .fontSize(16)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.showShareDialog = true)
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
   * 构建标签栏
   */
  @Builder
  private buildTabBar() {
    Row() {
      // 内容标签
      Column({ space: 4 }) {
        Text('内容')
          .fontSize(16)
          .fontColor(this.currentTab === 'content' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'content' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'content') {
          Row()
            .width(40)
            .height(3)
            .backgroundColor('#007AFF')
            .borderRadius(2)
        }
      }
      .layoutWeight(1)
      .height(50)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.switchTab('content'))

      // 平台标签
      Column({ space: 4 }) {
        Text('平台')
          .fontSize(16)
          .fontColor(this.currentTab === 'platform' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'platform' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'platform') {
          Row()
            .width(40)
            .height(3)
            .backgroundColor('#007AFF')
            .borderRadius(2)
        }
      }
      .layoutWeight(1)
      .height(50)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.switchTab('platform'))

      // 历史标签
      Column({ space: 4 }) {
        Text(`历史 (${this.shareHistory.length})`)
          .fontSize(16)
          .fontColor(this.currentTab === 'history' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'history' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'history') {
          Row()
            .width(40)
            .height(3)
            .backgroundColor('#007AFF')
            .borderRadius(2)
        }
      }
      .layoutWeight(1)
      .height(50)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.switchTab('history'))
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建内容标签
   */
  @Builder
  private buildContentTab() {
    Scroll() {
      Column({ space: 16 }) {
        // 分享内容配置卡片
        this.buildShareContentCard()

        // 照片选择卡片
        this.buildPhotoSelectionCard()

        // 分享设置卡片
        this.buildShareSettingsCard()

        // 分享按钮
        this.buildShareButton()
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 16 })
    }
    .layoutWeight(1)
  }

  /**
   * 构建分享内容卡片
   */
  @Builder
  private buildShareContentCard() {
    Column({ space: 12 }) {
      Row() {
        Text('分享内容')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Button('配置')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.configureContent())
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text('标题:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.shareContent.title)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('类型:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.getShareTypeName(this.shareContent.type))
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        if (this.shareContent.description) {
          Row() {
            Text('描述:')
              .fontSize(14)
              .fontColor('#666666')
              .width(80)

            Text(this.shareContent.description)
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建照片选择卡片
   */
  @Builder
  private buildPhotoSelectionCard() {
    Column({ space: 12 }) {
      Row() {
        Text(`已选择照片 (${this.selectedPhotos.length})`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Button('预览')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.previewShare())
      }
      .width('100%')

      if (this.selectedPhotos.length > 0) {
        // 照片网格
        Grid() {
          ForEach(
            this.selectedPhotos.slice(0, 12), // 限制显示数量
            (photo: any, index: number) => {
              GridItem() {
                Stack() {
                  // 照片缩略图
                  Image($r('app.media.ic_photo_placeholder'))
                    .width('100%')
                    .aspectRatio(1)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)

                  // 照片编号
                  Text(`${index + 1}`)
                    .fontSize(12)
                    .fontColor('#FFFFFF')
                    .backgroundColor('rgba(0,0,0,0.5)')
                    .padding({ horizontal: 4, vertical: 2 })
                    .borderRadius(4)
                    .position({ x: 4, y: 4 })
                }
              }
            },
            (photo: any, index: number) => `photo_${photo.id}_${index}`
          )
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')

        // 如果照片太多，显示更多提示
        if (this.selectedPhotos.length > 12) {
          Text(`... 还有 ${this.selectedPhotos.length - 12} 张照片`)
            .fontSize(14)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 8 })
        }
      } else {
        Column() {
          Text('没有选择照片')
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建分享设置卡片
   */
  @Builder
  private buildShareSettingsCard() {
    Column({ space: 12 }) {
      Text('分享设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        Row() {
          Text('包含元数据')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.shareContent.includeMetadata })
            .selectedColor('#007AFF')
            .switchPointColor('#FFFFFF')
            .onChange((isOn: boolean) => {
              this.shareContent.includeMetadata = isOn
            })
        }
        .width('100%')

        Row() {
          Text('包含水印')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.shareContent.includeWatermark })
            .selectedColor('#007AFF')
            .switchPointColor('#FFFFFF')
            .onChange((isOn: boolean) => {
              this.shareContent.includeWatermark = isOn
            })
        }
        .width('100%')

        Row() {
          Text('压缩级别')
            .fontSize(14)
            .fontColor('#333333')
            .width(80)

          Text(this.getCompressionName(this.shareContent.compression))
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('输出格式')
            .fontSize(14)
            .fontColor('#333333')
            .width(80)

          Text(this.shareContent.format.toUpperCase())
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('最大大小')
            .fontSize(14)
            .fontColor('#333333')
            .width(80)

          Text(`${this.shareContent.maxSize}MB`)
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建分享按钮
   */
  @Builder
  private buildShareButton() {
    Button('选择分享平台')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#007AFF')
      .borderRadius(12)
      .width('100%')
      .height(48)
      .margin({ top: 20 })
      .onClick(() => this.switchTab('platform'))
  }

  /**
   * 构建平台标签
   */
  @Builder
  private buildPlatformTab() {
    Column({ space: 16 }) {
      // 平台选择标题
      Row() {
        Text('选择分享平台')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text(`已选择 ${this.selectedPlatforms.length} 个`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding({ horizontal: 16 })

      // 平台网格
      Grid() {
        ForEach(
          [
            SharePlatform.SYSTEM,
            SharePlatform.WECHAT,
            SharePlatform.WECHAT_MOMENTS,
            SharePlatform.QQ,
            SharePlatform.WEIBO,
            SharePlatform.DINGTALK,
            SharePlatform.EMAIL,
            SharePlatform.BLUETOOTH
          ],
          (platform: SharePlatform) => {
            GridItem() {
              Column({ space: 8 }) {
                // 平台图标
                Image($r('app.media.ic_share_placeholder'))
                  .width(48)
                  .height(48)
                  .fillColor(this.selectedPlatforms.includes(platform) ? '#007AFF' : '#666666')

                // 平台名称
                Text(this.getPlatformName(platform))
                  .fontSize(12)
                  .fontColor(this.selectedPlatforms.includes(platform) ? '#007AFF' : '#333333')
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(80)
              .justifyContent(FlexAlign.Center)
              .padding(8)
              .borderRadius(12)
              .backgroundColor(this.selectedPlatforms.includes(platform) ? '#F0F8FF' : '#FFFFFF')
              .border({
                width: 1,
                color: this.selectedPlatforms.includes(platform) ? '#007AFF' : '#E0E0E0'
              })
              .onClick(() => {
                const index = this.selectedPlatforms.indexOf(platform)
                if (index > -1) {
                  // 不能取消选择系统分享
                  if (platform !== SharePlatform.SYSTEM || this.selectedPlatforms.length > 1) {
                    this.selectedPlatforms.splice(index, 1)
                  }
                } else {
                  this.selectedPlatforms.push(platform)
                }
              })
            }
          },
          (platform: SharePlatform) => platform
        )
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
      .padding({ horizontal: 16 })

      // 分享按钮
      if (this.selectedPlatforms.length > 0) {
        Button('开始分享')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(12)
          .width('calc(100% - 32px)')
          .height(48)
          .margin({ top: 20, horizontal: 16 })
          .onClick(() => this.showShareDialog = true)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建历史标签
   */
  @Builder
  private buildHistoryTab() {
    if (this.shareHistory.length > 0) {
      List({ space: 12 }) {
        ForEach(
          this.shareHistory,
          (record: ShareRecord) => {
            ListItem() {
              this.buildHistoryItem(record)
            }
          },
          (record: ShareRecord) => record.id
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ horizontal: 16, vertical: 16 })
    } else {
      Column() {
        Image($r('app.media.ic_empty_history'))
          .width(64)
          .height(64)
          .fillColor('#CCCCCC')
          .margin({ bottom: 16 })

        Text('暂无分享记录')
          .fontSize(16)
          .fontColor('#666666')

        Text('分享记录将显示在这里')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
  }

  /**
   * 构建历史记录项
   */
  @Builder
  private buildHistoryItem(record: ShareRecord) {
    Column({ space: 12 }) {
      // 记录头部
      Row({ space: 12 }) {
        // 状态图标
        Circle({ width: 12, height: 12 })
          .fill(this.getStatusColor(record.status))

        Column({ space: 4 }) {
          Text(record.content.title)
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row({ space: 16 }) {
            Text(this.getPlatformName(record.platform))
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getShareTypeName(record.content.type))
              .fontSize(14)
              .fontColor('#666666')

            if (record.recipient) {
              Text(`发送给: ${record.recipient}`)
                .fontSize(14)
                .fontColor('#666666')
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 状态文本
        Text(this.getStatusText(record.status))
          .fontSize(14)
          .fontColor(this.getStatusColor(record.status))
      }
      .width('100%')

      // 分享信息
      Column({ space: 4 }) {
        Row() {
          Text(`照片数量: ${record.content.photos.length}`)
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)

          Text(`压缩: ${this.getCompressionName(record.content.compression)}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')

        if (record.content.includeMetadata || record.content.includeWatermark) {
          Row() {
            if (record.content.includeMetadata) {
              Text('包含元数据')
                .fontSize(12)
                .fontColor('#999999')
            }

            if (record.content.includeMetadata && record.content.includeWatermark) {
              Text('•')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ horizontal: 4 })
            }

            if (record.content.includeWatermark) {
              Text('包含水印')
                .fontSize(12)
                .fontColor('#999999')
            }
          }
          .width('100%')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 时间信息
      Text(`分享时间: ${record.sharedAt.toLocaleString()}`)
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .textAlign(TextAlign.Start)

      // 操作按钮
      Row({ space: 12 }) {
        if (record.status === 'success') {
          Button('重新分享')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => this.reshareRecord(record))

          if (record.filePath) {
            Button('打开文件')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#34C759')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                // 打开分享文件
              })
          }
        }

        Button('删除')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF3B30')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.deleteRecord(record))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建内容配置对话框
   */
  @Builder
  private buildContentDialog() {
    Column() {
      // 对话框标题
      Row() {
        Text('内容配置')
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
        .onClick(() => this.showContentDialog = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      Scroll() {
        Column({ space: 20 }) {
          // 基本信息配置
          this.buildBasicContentConfig()

          // 输出格式配置
          this.buildOutputFormatConfig()

          // 压缩设置
          this.buildCompressionConfig()
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
          .onClick(() => this.showContentDialog = false)

        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showContentDialog = false)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('80%')
    .position({ x: 0, y: '20%' })
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
   * 构建基本内容配置
   */
  @Builder
  private buildBasicContentConfig() {
    Column({ space: 12 }) {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        Text('分享标题')
          .fontSize(14)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)

        TextInput({ text: this.shareContent.title })
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .height(40)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.shareContent.title = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('分享描述')
          .fontSize(14)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)

        TextArea({ placeholder: '请输入分享描述' })
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .height(80)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.shareContent.description = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建输出格式配置
   */
  @Builder
  private buildOutputFormatConfig() {
    Column({ space: 12 }) {
      Text('输出格式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row({ space: 12 }) {
        ForEach(
          ['original', 'jpg', 'png', 'webp'],
          (format: string) => {
            Button(format.toUpperCase())
              .fontSize(14)
              .fontColor(this.shareContent.format === format ? '#FFFFFF' : '#666666')
              .backgroundColor(this.shareContent.format === format ? '#007AFF' : '#F8F8F8')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                this.shareContent.format = format as any
              })
          },
          (format: string) => format
        )
      }
      .width('100%')

      Row() {
        Text('最大文件大小 (MB)')
          .fontSize(14)
          .fontColor('#333333')
          .width(140)

        Text(`${this.shareContent.maxSize}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)

        Row({ space: 8 }) {
          Button('-')
            .width(32)
            .height(32)
            .fontSize(16)
            .fontColor('#007AFF')
            .backgroundColor('#F8F8F8')
            .borderRadius(6)
            .onClick(() => {
              if (this.shareContent.maxSize > 1) {
                this.shareContent.maxSize--
              }
            })

          Button('+')
            .width(32)
            .height(32)
            .fontSize(16)
            .fontColor('#007AFF')
            .backgroundColor('#F8F8F8')
            .borderRadius(6)
            .onClick(() => {
              if (this.shareContent.maxSize < 100) {
                this.shareContent.maxSize++
              }
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建压缩配置
   */
  @Builder
  private buildCompressionConfig() {
    Column({ space: 12 }) {
      Text('压缩设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        ForEach(
          [
            { key: 'none', name: '无压缩', desc: '保持原始文件大小' },
            { key: 'low', name: '低压缩', desc: '轻微压缩，质量损失较小' },
            { key: 'medium', name: '中等压缩', desc: '平衡文件大小和质量' },
            { key: 'high', name: '高压缩', desc: '大幅减小文件大小' }
          ],
          (item: { key: string, name: string, desc: string }) => {
            Column({ space: 4 }) {
              Row() {
                Text(item.name)
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1)

                if (this.shareContent.compression === item.key) {
                  Image($r('app.media.ic_check'))
                    .width(16)
                    .height(16)
                    .fillColor('#007AFF')
                }
              }
              .width('100%')

              Text(item.desc)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .width('100%')
            .padding(12)
            .borderRadius(8)
            .backgroundColor(this.shareContent.compression === item.key ? '#F0F8FF' : Color.Transparent)
            .onClick(() => {
              this.shareContent.compression = item.key as any
            })
          },
          (item: { key: string, name: string, desc: string }) => item.key
        )
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建平台选择对话框
   */
  @Builder
  private buildPlatformDialog() {
    Column({ space: 16 }) {
      Text('选择分享平台')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Text('请选择要分享到的平台')
        .fontSize(14)
        .fontColor('#666666')

      Column({ space: 12 }) {
        ForEach(
          [
            SharePlatform.SYSTEM,
            SharePlatform.WECHAT,
            SharePlatform.WECHAT_MOMENTS,
            SharePlatform.QQ,
            SharePlatform.WEIBO,
            SharePlatform.DINGTALK,
            SharePlatform.EMAIL,
            SharePlatform.BLUETOOTH
          ],
          (platform: SharePlatform) => {
            Row() {
              Text(this.getPlatformName(platform))
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.selectedPlatforms.includes(platform) })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  if (isOn) {
                    if (!this.selectedPlatforms.includes(platform)) {
                      this.selectedPlatforms.push(platform)
                    }
                  } else {
                    // 不能取消选择系统分享
                    if (platform !== SharePlatform.SYSTEM || this.selectedPlatforms.length > 1) {
                      const index = this.selectedPlatforms.indexOf(platform)
                      if (index > -1) {
                        this.selectedPlatforms.splice(index, 1)
                      }
                    }
                  }
                })
            }
            .width('100%')
            .height(44)
            .padding({ horizontal: 16 })
            .borderRadius(8)
            .backgroundColor('#F8F8F8')
          },
          (platform: SharePlatform) => platform
        )
      }
      .width('100%')

      Button('确定')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(8)
        .width('100%')
        .onClick(() => this.showPlatformDialog = false)
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 4
    })
    .zIndex(10)
    .position({ x: '10%', y: '25%' })
  }

  /**
   * 构建预览对话框
   */
  @Builder
  private buildPreviewDialog() {
    Column({ space: 16 }) {
      Text('分享预览')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      // 预览内容
      Column({ space: 12 }) {
        Text(`标题: ${this.shareContent.title}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`类型: ${this.getShareTypeName(this.shareContent.type)}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`照片数量: ${this.selectedPhotos.length}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`格式: ${this.shareContent.format.toUpperCase()}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`压缩: ${this.getCompressionName(this.shareContent.compression)}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`最大大小: ${this.shareContent.maxSize}MB`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        if (this.shareContent.includeMetadata || this.shareContent.includeWatermark) {
          Text(`附加信息: ${this.shareContent.includeMetadata ? '元数据' : ''}${this.shareContent.includeMetadata && this.shareContent.includeWatermark ? '、' : ''}${this.shareContent.includeWatermark ? '水印' : ''}`)
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Button('关闭')
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .width('100%')
        .onClick(() => this.showPreviewDialog = false)
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 4
    })
    .zIndex(10)
    .position({ x: '10%', y: '30%' })
  }

  /**
   * 构建分享进度对话框
   */
  @Builder
  private buildShareProgressDialog() {
    Column({ space: 20 }) {
      // 进度指示器
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007AFF')

      // 分享描述
      Text('正在分享内容...')
        .fontSize(16)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      // 进度条
      Progress({
        value: this.currentShareProgress,
        total: 100,
        type: ProgressType.Linear
      })
      .width('80%')
      .color('#007AFF')
      .backgroundColor('#F0F0F0')

      // 进度百分比
      Text(`${this.currentShareProgress}%`)
        .fontSize(14)
        .fontColor('#666666')

      // 提示信息
      Text('请勿关闭应用或执行其他操作')
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 4
    })
    .zIndex(20)
    .position({ x: '10%', y: '40%' })
  }
}