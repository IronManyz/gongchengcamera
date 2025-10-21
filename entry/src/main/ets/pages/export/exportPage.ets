/**
 * 导出主页面
 * 提供照片导出功能，包括格式选择、参数配置和批量导出
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 导出格式枚举
 */
enum ExportFormat {
  JPG = 'jpg',
  PNG = 'png',
  WEBP = 'webp',
  PDF = 'pdf',
  ZIP = 'zip'
}

/**
 * 导出质量枚举
 */
enum ExportQuality {
  LOW = 'low',      // 低质量
  MEDIUM = 'medium', // 中等质量
  HIGH = 'high',    // 高质量
  ORIGINAL = 'original' // 原始质量
}

/**
 * 导出配置接口
 */
interface ExportConfig {
  format: ExportFormat
  quality: ExportQuality
  includeMetadata: boolean
  includeWatermark: boolean
  resize: {
    enabled: boolean
    width: number
    height: number
    maintainAspectRatio: boolean
  }
  outputLocation: string
  filenameTemplate: string
}

/**
 * 导出任务接口
 */
interface ExportTask {
  id: string
  name: string
  photos: string[]
  config: ExportConfig
  status: 'pending' | 'in_progress' | 'completed' | 'failed'
  progress: number
  createdAt: Date
  completedAt?: Date
  outputPath?: string
  error?: string
}

@Entry
@Component
struct ExportPage {
  private logger = new Logger('ExportPage')
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private photoIds: string[] = []

  // 状态管理
  @State private isLoading: boolean = false
  @State private selectedPhotos: any[] = []
  @State private currentTab: 'photos' | 'tasks' = 'photos'
  @State private exportConfig: ExportConfig = {
    format: ExportFormat.JPG,
    quality: ExportQuality.HIGH,
    includeMetadata: true,
    includeWatermark: false,
    resize: {
      enabled: false,
      width: 1920,
      height: 1080,
      maintainAspectRatio: true
    },
    outputLocation: '/storage/exports/',
    filenameTemplate: '{project}_{site}_{date}_{index}'
  }
  @State private exportTasks: ExportTask[] = []

  // 对话框状态
  @State private showConfigDialog: boolean = false
  @State private showExportDialog: boolean = false
  @State private showPreviewDialog: boolean = false
  @State private selectedTask: ExportTask | null = null

  // 导出状态
  @State private isExporting: boolean = false
  @State private currentExportProgress: number = 0

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.photoIds = params?.photoIds || []

    this.logger.info('ExportPage appeared', { photoIds: this.photoIds })

    this.loadSelectedPhotos()
  }

  aboutToDisappear() {
    this.logger.info('ExportPage disappeared')
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
      } else {
        // 加载所有照片
        this.selectedPhotos = this.photoStore.photos
      }
    } catch (error) {
      this.logger.error('加载照片失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 切换标签
   */
  private switchTab(tab: 'photos' | 'tasks') {
    this.currentTab = tab
  }

  /**
   * 配置导出参数
   */
  private configureExport() {
    this.showConfigDialog = true
  }

  /**
   * 开始导出
   */
  private async startExport() {
    if (this.selectedPhotos.length === 0) {
      return
    }

    this.isExporting = true
    this.currentExportProgress = 0

    try {
      this.logger.info('开始导出照片', { count: this.selectedPhotos.length })

      // 创建导出任务
      const task: ExportTask = {
        id: Date.now().toString(),
        name: `导出任务 ${new Date().toLocaleString()}`,
        photos: this.selectedPhotos.map(photo => photo.id),
        config: { ...this.exportConfig },
        status: 'in_progress',
        progress: 0,
        createdAt: new Date()
      }

      this.exportTasks.unshift(task)

      // 模拟导出进度
      const totalSteps = this.selectedPhotos.length
      for (let i = 0; i < totalSteps; i++) {
        this.currentExportProgress = Math.round(((i + 1) / totalSteps) * 100)
        task.progress = this.currentExportProgress

        // 模拟处理时间
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      // 完成导出
      task.status = 'completed'
      task.completedAt = new Date()
      task.outputPath = `${this.exportConfig.outputLocation}/export_${Date.now()}`

      this.logger.info('导出完成', { outputPath: task.outputPath })
      this.showExportDialog = false

      // 切换到任务标签
      this.currentTab = 'tasks'
    } catch (error) {
      this.logger.error('导出失败', error)
    } finally {
      this.isExporting = false
      this.currentExportProgress = 0
    }
  }

  /**
   * 保存配置
   */
  private saveConfig() {
    // 这里应该保存配置到本地存储
    this.logger.info('保存导出配置', this.exportConfig)
    this.showConfigDialog = false
  }

  /**
   * 预览导出结果
   */
  private previewExport() {
    this.showPreviewDialog = true
  }

  /**
   * 删除任务
   */
  private deleteTask(task: ExportTask) {
    const index = this.exportTasks.findIndex(t => t.id === task.id)
    if (index > -1) {
      this.exportTasks.splice(index, 1)
    }
  }

  /**
   * 重新导出
   */
  private async retryExport(task: ExportTask) {
    this.exportConfig = { ...task.config }
    this.selectedPhotos = task.photos.map(id => ({ id }))
    await this.startExport()
  }

  /**
   * 获取格式文本
   */
  private getFormatText(format: ExportFormat): string {
    switch (format) {
      case ExportFormat.JPG:
        return 'JPG'
      case ExportFormat.PNG:
        return 'PNG'
      case ExportFormat.WEBP:
        return 'WebP'
      case ExportFormat.PDF:
        return 'PDF'
      case ExportFormat.ZIP:
        return 'ZIP'
      default:
        return 'JPG'
    }
  }

  /**
   * 获取质量文本
   */
  private getQualityText(quality: ExportQuality): string {
    switch (quality) {
      case ExportQuality.LOW:
        return '低质量'
      case ExportQuality.MEDIUM:
        return '中等质量'
      case ExportQuality.HIGH:
        return '高质量'
      case ExportQuality.ORIGINAL:
        return '原始质量'
      default:
        return '高质量'
    }
  }

  /**
   * 获取状态文本
   */
  private getStatusText(status: string): string {
    switch (status) {
      case 'pending':
        return '等待中'
      case 'in_progress':
        return '进行中'
      case 'completed':
        return '已完成'
      case 'failed':
        return '失败'
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
        return '#FF9500'
      case 'in_progress':
        return '#007AFF'
      case 'completed':
        return '#34C759'
      case 'failed':
        return '#FF3B30'
      default:
        return '#666666'
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 标签切换
      this.buildTabBar()

      // 内容区域
      if (this.currentTab === 'photos') {
        this.buildPhotosContent()
      } else {
        this.buildTasksContent()
      }

      // 配置对话框
      if (this.showConfigDialog) {
        this.buildConfigDialog()
      }

      // 导出确认对话框
      if (this.showExportDialog) {
        ConfirmDialog({
          title: '确认导出',
          message: `确定要导出 ${this.selectedPhotos.length} 张照片吗？`,
          confirmText: '导出',
          cancelText: '取消',
          onConfirm: () => this.startExport(),
          onCancel: () => this.showExportDialog = false
        })
      }

      // 预览对话框
      if (this.showPreviewDialog) {
        this.buildPreviewDialog()
      }

      // 导出进度对话框
      if (this.isExporting) {
        this.buildExportProgressDialog()
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
      Text('照片导出')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 操作按钮
      if (this.currentTab === 'photos' && this.selectedPhotos.length > 0) {
        Button('导出')
          .fontSize(16)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.showExportDialog = true)
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
      // 照片标签
      Column({ space: 4 }) {
        Text(`照片 (${this.selectedPhotos.length})`)
          .fontSize(16)
          .fontColor(this.currentTab === 'photos' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'photos' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'photos') {
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
      .onClick(() => this.switchTab('photos'))

      // 任务标签
      Column({ space: 4 }) {
        Text(`导出任务 (${this.exportTasks.length})`)
          .fontSize(16)
          .fontColor(this.currentTab === 'tasks' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'tasks' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'tasks') {
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
      .onClick(() => this.switchTab('tasks'))
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建照片内容
   */
  @Builder
  private buildPhotosContent() {
    Column({ space: 16 }) {
      // 导出配置卡片
      this.buildExportConfigCard()

      // 照片列表
      if (this.selectedPhotos.length > 0) {
        this.buildPhotosList()
      } else {
        this.buildEmptyState()
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ horizontal: 16, vertical: 16 })
  }

  /**
   * 构建导出配置卡片
   */
  @Builder
  private buildExportConfigCard() {
    Column({ space: 12 }) {
      // 配置标题
      Row() {
        Text('导出配置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Button('配置')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.configureExport())
      }
      .width('100%')

      // 配置信息
      Column({ space: 8 }) {
        Row() {
          Text('格式:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.getFormatText(this.exportConfig.format))
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('质量:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.getQualityText(this.exportConfig.quality))
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('元数据:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.exportConfig.includeMetadata ? '包含' : '不包含')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        if (this.exportConfig.resize.enabled) {
          Row() {
            Text('尺寸:')
              .fontSize(14)
              .fontColor('#666666')
              .width(80)

            Text(`${this.exportConfig.resize.width}×${this.exportConfig.resize.height}`)
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)
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
   * 构建照片列表
   */
  @Builder
  private buildPhotosList() {
    Column() {
      // 列表标题
      Row() {
        Text(`已选择 ${this.selectedPhotos.length} 张照片`)
          .fontSize(14)
          .fontColor('#666666')

        Blank()

        Button('预览')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.previewExport())
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 照片网格
      Grid() {
        ForEach(
          this.selectedPhotos.slice(0, 20), // 限制显示数量
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
      if (this.selectedPhotos.length > 20) {
        Text(`... 还有 ${this.selectedPhotos.length - 20} 张照片`)
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建空状态
   */
  @Builder
  private buildEmptyState() {
    Column() {
      Image($r('app.media.ic_empty_photos'))
        .width(64)
        .height(64)
        .fillColor('#CCCCCC')
        .margin({ bottom: 16 })

      Text('没有选择照片')
        .fontSize(16)
        .fontColor('#666666')

      Text('请先选择要导出的照片')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建任务内容
   */
  @Builder
  private buildTasksContent() {
    if (this.exportTasks.length > 0) {
      List({ space: 12 }) {
        ForEach(
          this.exportTasks,
          (task: ExportTask) => {
            ListItem() {
              this.buildTaskItem(task)
            }
          },
          (task: ExportTask) => task.id
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ horizontal: 16, vertical: 16 })
    } else {
      Column() {
        Image($r('app.media.ic_empty_tasks'))
          .width(64)
          .height(64)
          .fillColor('#CCCCCC')
          .margin({ bottom: 16 })

        Text('暂无导出任务')
          .fontSize(16)
          .fontColor('#666666')

        Text('导出记录将显示在这里')
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
   * 构建任务项
   */
  @Builder
  private buildTaskItem(task: ExportTask) {
    Column({ space: 12 }) {
      // 任务头部
      Row({ space: 12 }) {
        // 状态图标
        Circle({ width: 12, height: 12 })
          .fill(this.getStatusColor(task.status))

        Column({ space: 4 }) {
          Text(task.name)
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row({ space: 16 }) {
            Text(`${task.photos.length} 张照片`)
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getFormatText(task.config.format))
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getQualityText(task.config.quality))
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 状态文本
        Text(this.getStatusText(task.status))
          .fontSize(14)
          .fontColor(this.getStatusColor(task.status))
      }
      .width('100%')

      // 进度条
      if (task.status === 'in_progress') {
        Progress({
          value: task.progress,
          total: 100,
          type: ProgressType.Linear
        })
        .width('100%')
        .color('#007AFF')
        .backgroundColor('#F0F0F0')
      }

      // 时间信息
      Row({ space: 16 }) {
        Text(`创建时间: ${task.createdAt.toLocaleString()}`)
          .fontSize(12)
          .fontColor('#999999')

        if (task.completedAt) {
          Text(`完成时间: ${task.completedAt.toLocaleString()}`)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .width('100%')

      // 操作按钮
      if (task.status === 'completed' || task.status === 'failed') {
        Row({ space: 12 }) {
          if (task.status === 'failed') {
            Button('重试')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#007AFF')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => this.retryExport(task))
          }

          if (task.status === 'completed' && task.outputPath) {
            Button('打开')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#34C759')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                // 打开输出位置
              })
          }

          Button('删除')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF3B30')
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => this.deleteTask(task))
        }
        .width('100%')
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
   * 构建配置对话框
   */
  @Builder
  private buildConfigDialog() {
    Column() {
      // 对话框标题
      Row() {
        Text('导出配置')
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
        .onClick(() => this.showConfigDialog = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      Scroll() {
        Column({ space: 20 }) {
          // 格式选择
          this.buildFormatSelector()

          // 质量选择
          this.buildQualitySelector()

          // 其他选项
          this.buildOtherOptions()

          // 尺寸设置
          this.buildSizeSettings()
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
          .onClick(() => this.showConfigDialog = false)

        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.saveConfig())
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
   * 构建格式选择器
   */
  @Builder
  private buildFormatSelector() {
    Column({ space: 12 }) {
      Text('导出格式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row({ space: 12 }) {
        ForEach(
          [ExportFormat.JPG, ExportFormat.PNG, ExportFormat.WEBP, ExportFormat.PDF],
          (format: ExportFormat) => {
            Button(this.getFormatText(format))
              .fontSize(14)
              .fontColor(this.exportConfig.format === format ? '#FFFFFF' : '#666666')
              .backgroundColor(this.exportConfig.format === format ? '#007AFF' : '#F8F8F8')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                this.exportConfig.format = format
              })
          },
          (format: ExportFormat) => format
        )
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建质量选择器
   */
  @Builder
  private buildQualitySelector() {
    Column({ space: 12 }) {
      Text('导出质量')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        ForEach(
          [ExportQuality.LOW, ExportQuality.MEDIUM, ExportQuality.HIGH, ExportQuality.ORIGINAL],
          (quality: ExportQuality) => {
            Row() {
              Text(this.getQualityText(quality))
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              if (this.exportConfig.quality === quality) {
                Image($r('app.media.ic_check'))
                  .width(16)
                  .height(16)
                  .fillColor('#007AFF')
              }
            }
            .width('100%')
            .height(44)
            .padding({ horizontal: 12 })
            .borderRadius(8)
            .backgroundColor(this.exportConfig.quality === quality ? '#F0F8FF' : Color.Transparent)
            .onClick(() => {
              this.exportConfig.quality = quality
            })
          },
          (quality: ExportQuality) => quality
        )
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建其他选项
   */
  @Builder
  private buildOtherOptions() {
    Column({ space: 12 }) {
      Text('其他选项')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row() {
        Text('包含元数据')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.exportConfig.includeMetadata })
          .selectedColor('#007AFF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            this.exportConfig.includeMetadata = isOn
          })
      }
      .width('100%')

      Row() {
        Text('包含水印')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.exportConfig.includeWatermark })
          .selectedColor('#007AFF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            this.exportConfig.includeWatermark = isOn
          })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建尺寸设置
   */
  @Builder
  private buildSizeSettings() {
    Column({ space: 12 }) {
      Text('尺寸设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row() {
        Text('调整尺寸')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.exportConfig.resize.enabled })
          .selectedColor('#007AFF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            this.exportConfig.resize.enabled = isOn
          })
      }
      .width('100%')

      if (this.exportConfig.resize.enabled) {
        Column({ space: 8 }) {
          Row() {
            Text('宽度')
              .fontSize(14)
              .fontColor('#333333')

            Text(`${this.exportConfig.resize.width}px`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Slider({
            value: this.exportConfig.resize.width,
            min: 100,
            max: 4096,
            style: SliderStyle.InSet
          })
          .width('100%')
          .trackColor('#E0E0E0')
          .selectedColor('#007AFF')
          .blockColor('#007AFF')
          .onChange((value: number) => {
            this.exportConfig.resize.width = value
          })

          Row() {
            Text('高度')
              .fontSize(14)
              .fontColor('#333333')

            Text(`${this.exportConfig.resize.height}px`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Slider({
            value: this.exportConfig.resize.height,
            min: 100,
            max: 4096,
            style: SliderStyle.InSet
          })
          .width('100%')
          .trackColor('#E0E0E0')
          .selectedColor('#007AFF')
          .blockColor('#007AFF')
          .onChange((value: number) => {
            this.exportConfig.resize.height = value
          })

          Row() {
            Text('保持宽高比')
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.exportConfig.resize.maintainAspectRatio })
              .selectedColor('#007AFF')
              .switchPointColor('#FFFFFF')
              .onChange((isOn: boolean) => {
                this.exportConfig.resize.maintainAspectRatio = isOn
              })
          }
          .width('100%')
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建预览对话框
   */
  @Builder
  private buildPreviewDialog() {
    Column({ space: 16 }) {
      Text('导出预览')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      // 预览内容
      Column({ space: 12 }) {
        Text(`格式: ${this.getFormatText(this.exportConfig.format)}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`质量: ${this.getQualityText(this.exportConfig.quality)}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`照片数量: ${this.selectedPhotos.length}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Start)

        if (this.exportConfig.resize.enabled) {
          Text(`输出尺寸: ${this.exportConfig.resize.width}×${this.exportConfig.resize.height}`)
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
    .position({ x: '10%', y: '35%' })
  }

  /**
   * 构建导出进度对话框
   */
  @Builder
  private buildExportProgressDialog() {
    Column({ space: 20 }) {
      // 进度指示器
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007AFF')

      // 导出描述
      Text('正在导出照片...')
        .fontSize(16)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      // 进度条
      Progress({
        value: this.currentExportProgress,
        total: 100,
        type: ProgressType.Linear
      })
      .width('80%')
      .color('#007AFF')
      .backgroundColor('#F0F0F0')

      // 进度百分比
      Text(`${this.currentExportProgress}%`)
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