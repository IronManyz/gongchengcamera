/**
 * 报告生成页面
 * 提供工程报告生成功能，包括模板选择、内容配置和PDF生成
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { ProjectStore } from '../../store/project/ProjectStore'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 报告模板枚举
 */
enum ReportTemplate {
  BASIC = 'basic',           // 基础模板
  DETAILED = 'detailed',     // 详细模板
  SUMMARY = 'summary',       // 汇总模板
  CUSTOM = 'custom'          // 自定义模板
}

/**
 * 报告格式枚举
 */
enum ReportFormat {
  PDF = 'pdf',
  WORD = 'docx',
  EXCEL = 'xlsx',
  HTML = 'html'
}

/**
 * 报告内容配置接口
 */
interface ReportContent {
  includeProjectInfo: boolean      // 包含项目信息
  includeSiteInfo: boolean         // 包含工点信息
  includePhotos: boolean           // 包含照片
  includeStatistics: boolean       // 包含统计信息
  includeTimeline: boolean         // 包含时间线
  includeLocation: boolean         // 包含位置信息
  includeWeather: boolean          // 包含天气信息
  includeNotes: boolean            // 包含备注
  photoLayout: 'grid' | 'list' | 'timeline'  // 照片布局
  photoQuality: 'high' | 'medium' | 'low'     // 照片质量
}

/**
 * 报告配置接口
 */
interface ReportConfig {
  template: ReportTemplate
  format: ReportFormat
  title: string
  subtitle: string
  author: string
  content: ReportContent
  watermark: {
    enabled: boolean
    text: string
    opacity: number
  }
  pageSettings: {
    pageSize: 'A4' | 'A3' | 'Letter'
    orientation: 'portrait' | 'landscape'
    margin: number
  }
}

/**
 * 报告生成任务接口
 */
interface ReportTask {
  id: string
  name: string
  projectId: string
  config: ReportConfig
  status: 'pending' | 'in_progress' | 'completed' | 'failed'
  progress: number
  createdAt: Date
  completedAt?: Date
  outputPath?: string
  error?: string
}

@Entry
@Component
struct ReportGenPage {
  private logger = new Logger('ReportGenPage')
  private projectStore = ProjectStore.getInstance()
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private projectId: string = ''
  private project: any = null

  // 状态管理
  @State private isLoading: boolean = false
  @State private currentTab: 'config' | 'preview' | 'tasks' = 'config'
  @State private selectedTemplate: ReportTemplate = ReportTemplate.BASIC
  @State private reportConfig: ReportConfig = {
    template: ReportTemplate.BASIC,
    format: ReportFormat.PDF,
    title: '工程报告',
    subtitle: 'Engineering Camera Report',
    author: 'Engineering Camera',
    content: {
      includeProjectInfo: true,
      includeSiteInfo: true,
      includePhotos: true,
      includeStatistics: true,
      includeTimeline: false,
      includeLocation: true,
      includeWeather: false,
      includeNotes: true,
      photoLayout: 'grid',
      photoQuality: 'medium'
    },
    watermark: {
      enabled: true,
      text: 'Engineering Camera',
      opacity: 0.3
    },
    pageSettings: {
      pageSize: 'A4',
      orientation: 'portrait',
      margin: 20
    }
  }
  @State private reportTasks: ReportTask[] = []

  // 对话框状态
  @State private showTemplateDialog: boolean = false
  @State private showConfigDialog: boolean = false
  @State private showPreviewDialog: boolean = false
  @State private showGenerateDialog: boolean = false
  @State private selectedTask: ReportTask | null = null

  // 生成状态
  @State private isGenerating: boolean = false
  @State private currentGenerateProgress: number = 0

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.projectId = params?.projectId || ''

    this.logger.info('ReportGenPage appeared', { projectId: this.projectId })

    this.loadProjectData()
  }

  aboutToDisappear() {
    this.logger.info('ReportGenPage disappeared')
  }

  /**
   * 加载项目数据
   */
  private async loadProjectData() {
    this.isLoading = true
    try {
      if (this.projectId) {
        this.project = await this.projectStore.getProjectById(this.projectId)
        if (this.project) {
          this.reportConfig.title = `${this.project.name} - 工程报告`
          this.reportConfig.subtitle = this.project.description || ''
        }
      }
    } catch (error) {
      this.logger.error('加载项目数据失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 切换标签
   */
  private switchTab(tab: 'config' | 'preview' | 'tasks') {
    this.currentTab = tab
  }

  /**
   * 选择模板
   */
  private selectTemplate(template: ReportTemplate) {
    this.selectedTemplate = template
    this.reportConfig.template = template
    this.applyTemplateSettings(template)
  }

  /**
   * 应用模板设置
   */
  private applyTemplateSettings(template: ReportTemplate) {
    switch (template) {
      case ReportTemplate.BASIC:
        this.reportConfig.content = {
          includeProjectInfo: true,
          includeSiteInfo: true,
          includePhotos: true,
          includeStatistics: false,
          includeTimeline: false,
          includeLocation: true,
          includeWeather: false,
          includeNotes: false,
          photoLayout: 'grid',
          photoQuality: 'medium'
        }
        break
      case ReportTemplate.DETAILED:
        this.reportConfig.content = {
          includeProjectInfo: true,
          includeSiteInfo: true,
          includePhotos: true,
          includeStatistics: true,
          includeTimeline: true,
          includeLocation: true,
          includeWeather: true,
          includeNotes: true,
          photoLayout: 'timeline',
          photoQuality: 'high'
        }
        break
      case ReportTemplate.SUMMARY:
        this.reportConfig.content = {
          includeProjectInfo: true,
          includeSiteInfo: false,
          includePhotos: true,
          includeStatistics: true,
          includeTimeline: false,
          includeLocation: false,
          includeWeather: false,
          includeNotes: false,
          photoLayout: 'grid',
          photoQuality: 'low'
        }
        break
      case ReportTemplate.CUSTOM:
        // 保持当前配置
        break
    }
  }

  /**
   * 配置报告内容
   */
  private configureReport() {
    this.showConfigDialog = true
  }

  /**
   * 生成报告
   */
  private async generateReport() {
    if (!this.project) {
      return
    }

    this.isGenerating = true
    this.currentGenerateProgress = 0

    try {
      this.logger.info('开始生成报告', { projectId: this.projectId })

      // 创建报告任务
      const task: ReportTask = {
        id: Date.now().toString(),
        name: `${this.reportConfig.title} - ${new Date().toLocaleString()}`,
        projectId: this.projectId,
        config: { ...this.reportConfig },
        status: 'in_progress',
        progress: 0,
        createdAt: new Date()
      }

      this.reportTasks.unshift(task)

      // 模拟报告生成进度
      const steps = [
        { name: '收集数据', duration: 500 },
        { name: '处理照片', duration: 1000 },
        { name: '生成内容', duration: 800 },
        { name: '渲染PDF', duration: 1200 },
        { name: '保存文件', duration: 300 }
      ]

      for (let i = 0; i < steps.length; i++) {
        const step = steps[i]
        await new Promise(resolve => setTimeout(resolve, step.duration))
        this.currentGenerateProgress = Math.round(((i + 1) / steps.length) * 100)
        task.progress = this.currentGenerateProgress
      }

      // 完成生成
      task.status = 'completed'
      task.completedAt = new Date()
      task.outputPath = `/storage/reports/report_${Date.now()}.${this.reportConfig.format}`

      this.logger.info('报告生成完成', { outputPath: task.outputPath })
      this.showGenerateDialog = false

      // 切换到任务标签
      this.currentTab = 'tasks'
    } catch (error) {
      this.logger.error('报告生成失败', error)
    } finally {
      this.isGenerating = false
      this.currentGenerateProgress = 0
    }
  }

  /**
   * 预览报告
   */
  private previewReport() {
    this.showPreviewDialog = true
  }

  /**
   * 删除任务
   */
  private deleteTask(task: ReportTask) {
    const index = this.reportTasks.findIndex(t => t.id === task.id)
    if (index > -1) {
      this.reportTasks.splice(index, 1)
    }
  }

  /**
   * 重新生成报告
   */
  private async regenerateReport(task: ReportTask) {
    this.reportConfig = { ...task.config }
    await this.generateReport()
  }

  /**
   * 获取模板名称
   */
  private getTemplateName(template: ReportTemplate): string {
    switch (template) {
      case ReportTemplate.BASIC:
        return '基础模板'
      case ReportTemplate.DETAILED:
        return '详细模板'
      case ReportTemplate.SUMMARY:
        return '汇总模板'
      case ReportTemplate.CUSTOM:
        return '自定义模板'
      default:
        return '基础模板'
    }
  }

  /**
   * 获取格式名称
   */
  private getFormatName(format: ReportFormat): string {
    switch (format) {
      case ReportFormat.PDF:
        return 'PDF'
      case ReportFormat.WORD:
        return 'Word'
      case ReportFormat.EXCEL:
        return 'Excel'
      case ReportFormat.HTML:
        return 'HTML'
      default:
        return 'PDF'
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
        return '生成中'
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
      if (this.currentTab === 'config') {
        this.buildConfigContent()
      } else if (this.currentTab === 'preview') {
        this.buildPreviewContent()
      } else {
        this.buildTasksContent()
      }

      // 模板选择对话框
      if (this.showTemplateDialog) {
        this.buildTemplateDialog()
      }

      // 配置对话框
      if (this.showConfigDialog) {
        this.buildConfigDialog()
      }

      // 预览对话框
      if (this.showPreviewDialog) {
        this.buildPreviewDialog()
      }

      // 生成确认对话框
      if (this.showGenerateDialog) {
        ConfirmDialog({
          title: '确认生成报告',
          message: `确定要生成"${this.reportConfig.title}"报告吗？`,
          confirmText: '生成',
          cancelText: '取消',
          onConfirm: () => this.generateReport(),
          onCancel: () => this.showGenerateDialog = false
        })
      }

      // 生成进度对话框
      if (this.isGenerating) {
        this.buildGenerateProgressDialog()
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
      Text('报告生成')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 操作按钮
      if (this.currentTab === 'config' && this.project) {
        Button('生成')
          .fontSize(16)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.showGenerateDialog = true)
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
      // 配置标签
      Column({ space: 4 }) {
        Text('配置')
          .fontSize(16)
          .fontColor(this.currentTab === 'config' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'config' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'config') {
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
      .onClick(() => this.switchTab('config'))

      // 预览标签
      Column({ space: 4 }) {
        Text('预览')
          .fontSize(16)
          .fontColor(this.currentTab === 'preview' ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === 'preview' ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === 'preview') {
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
      .onClick(() => this.switchTab('preview'))

      // 任务标签
      Column({ space: 4 }) {
        Text(`任务 (${this.reportTasks.length})`)
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
   * 构建配置内容
   */
  @Builder
  private buildConfigContent() {
    Scroll() {
      Column({ space: 16 }) {
        // 项目信息卡片
        if (this.project) {
          this.buildProjectInfoCard()
        }

        // 模板选择卡片
        this.buildTemplateSelectionCard()

        // 报告配置卡片
        this.buildReportConfigCard()

        // 生成按钮
        this.buildGenerateButton()
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 16 })
    }
    .layoutWeight(1)
  }

  /**
   * 构建项目信息卡片
   */
  @Builder
  private buildProjectInfoCard() {
    Column({ space: 12 }) {
      Text('项目信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        Row() {
          Text('项目名称:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.project?.name || '')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        if (this.project?.description) {
          Row() {
            Text('项目描述:')
              .fontSize(14)
              .fontColor('#666666')
              .width(80)

            Text(this.project.description)
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
   * 构建模板选择卡片
   */
  @Builder
  private buildTemplateSelectionCard() {
    Column({ space: 12 }) {
      Row() {
        Text('报告模板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Text(this.getTemplateName(this.selectedTemplate))
          .fontSize(14)
          .fontColor('#007AFF')
      }
      .width('100%')

      Row({ space: 12 }) {
        ForEach(
          [ReportTemplate.BASIC, ReportTemplate.DETAILED, ReportTemplate.SUMMARY, ReportTemplate.CUSTOM],
          (template: ReportTemplate) => {
            Button(this.getTemplateName(template))
              .fontSize(12)
              .fontColor(this.selectedTemplate === template ? '#FFFFFF' : '#666666')
              .backgroundColor(this.selectedTemplate === template ? '#007AFF' : '#F8F8F8')
              .borderRadius(8)
              .layoutWeight(1)
              .height(40)
              .onClick(() => this.selectTemplate(template))
          },
          (template: ReportTemplate) => template
        )
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
   * 构建报告配置卡片
   */
  @Builder
  private buildReportConfigCard() {
    Column({ space: 12 }) {
      Row() {
        Text('报告配置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Button('配置')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.configureReport())
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text('格式:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.getFormatName(this.reportConfig.format))
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('页面:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(`${this.reportConfig.pageSettings.pageSize} - ${this.reportConfig.pageSettings.orientation === 'portrait' ? '竖向' : '横向'}`)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('内容:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)

          Text(this.getContentSummary())
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
   * 获取内容摘要
   */
  private getContentSummary(): string {
    const items = []
    if (this.reportConfig.content.includeProjectInfo) items.push('项目')
    if (this.reportConfig.content.includeSiteInfo) items.push('工点')
    if (this.reportConfig.content.includePhotos) items.push('照片')
    if (this.reportConfig.content.includeStatistics) items.push('统计')
    if (this.reportConfig.content.includeTimeline) items.push('时间线')
    if (this.reportConfig.content.includeLocation) items.push('位置')
    if (this.reportConfig.content.includeWeather) items.push('天气')
    if (this.reportConfig.content.includeNotes) items.push('备注')

    return items.join('、')
  }

  /**
   * 构建生成按钮
   */
  @Builder
  private buildGenerateButton() {
    Button('生成报告')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#007AFF')
      .borderRadius(12)
      .width('100%')
      .height(48)
      .margin({ top: 20 })
      .onClick(() => this.showGenerateDialog = true)
  }

  /**
   * 构建预览内容
   */
  @Builder
  private buildPreviewContent() {
    Column({ space: 16 }) {
      // 预览标题
      Text('报告预览')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Center)

      // 预览卡片
      this.buildPreviewCard()

      // 预览按钮
      Button('详细预览')
        .fontSize(16)
        .fontColor('#007AFF')
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#007AFF' })
        .borderRadius(12)
        .width('100%')
        .height(48)
        .onClick(() => this.previewReport())
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ horizontal: 16, vertical: 16 })
  }

  /**
   * 构建预览卡片
   */
  @Builder
  private buildPreviewCard() {
    Column({ space: 16 }) {
      // 报告标题
      Text(this.reportConfig.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Center)

      // 报告副标题
      if (this.reportConfig.subtitle) {
        Text(this.reportConfig.subtitle)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 4 })
      }

      Divider().color('#E0E0E0')

      // 内容预览
      Column({ space: 12 }) {
        if (this.reportConfig.content.includeProjectInfo && this.project) {
          this.buildProjectPreview()
        }

        if (this.reportConfig.content.includeSiteInfo) {
          this.buildSitePreview()
        }

        if (this.reportConfig.content.includePhotos) {
          this.buildPhotoPreview()
        }

        if (this.reportConfig.content.includeStatistics) {
          this.buildStatisticsPreview()
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Divider().color('#E0E0E0')

      // 页脚信息
      Row({ space: 16 }) {
        Text(`生成时间: ${new Date().toLocaleDateString()}`)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)

        Text(`格式: ${this.getFormatName(this.reportConfig.format)}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .padding(20)
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
   * 构建项目预览
   */
  @Builder
  private buildProjectPreview() {
    Column({ space: 8 }) {
      Text('项目信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text(`项目名称: ${this.project?.name || ''}`)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      if (this.project?.description) {
        Text(`项目描述: ${this.project.description}`)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建工点预览
   */
  @Builder
  private buildSitePreview() {
    Column({ space: 8 }) {
      Text('工点信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text('工点1、工点2、工点3...')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建照片预览
   */
  @Builder
  private buildPhotoPreview() {
    Column({ space: 8 }) {
      Text('照片记录')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text(`布局: ${this.reportConfig.content.photoLayout === 'grid' ? '网格' : this.reportConfig.content.photoLayout === 'list' ? '列表' : '时间线'}`)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      Text(`质量: ${this.reportConfig.content.photoQuality === 'high' ? '高质量' : this.reportConfig.content.photoQuality === 'medium' ? '中等质量' : '低质量'}`)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建统计预览
   */
  @Builder
  private buildStatisticsPreview() {
    Column({ space: 8 }) {
      Text('统计信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text('照片总数、工点数量、拍摄时间范围等统计信息')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建任务内容
   */
  @Builder
  private buildTasksContent() {
    if (this.reportTasks.length > 0) {
      List({ space: 12 }) {
        ForEach(
          this.reportTasks,
          (task: ReportTask) => {
            ListItem() {
              this.buildTaskItem(task)
            }
          },
          (task: ReportTask) => task.id
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

        Text('暂无生成任务')
          .fontSize(16)
          .fontColor('#666666')

        Text('报告生成记录将显示在这里')
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
  private buildTaskItem(task: ReportTask) {
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
            Text(this.getFormatName(task.config.format))
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getTemplateName(task.config.template))
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
              .onClick(() => this.regenerateReport(task))
          }

          if (task.status === 'completed' && task.outputPath) {
            Button('打开')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#34C759')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                // 打开报告文件
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
        Text('报告配置')
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

          // 内容配置
          this.buildContentConfig()

          // 页面设置
          this.buildPageSettings()

          // 水印设置
          this.buildWatermarkSettings()
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
          .onClick(() => this.showConfigDialog = false)
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
      Text('报告格式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row({ space: 12 }) {
        ForEach(
          [ReportFormat.PDF, ReportFormat.WORD, ReportFormat.EXCEL, ReportFormat.HTML],
          (format: ReportFormat) => {
            Button(this.getFormatName(format))
              .fontSize(14)
              .fontColor(this.reportConfig.format === format ? '#FFFFFF' : '#666666')
              .backgroundColor(this.reportConfig.format === format ? '#007AFF' : '#F8F8F8')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                this.reportConfig.format = format
              })
          },
          (format: ReportFormat) => format
        )
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建内容配置
   */
  @Builder
  private buildContentConfig() {
    Column({ space: 12 }) {
      Text('报告内容')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        ForEach(
          [
            { key: 'includeProjectInfo', label: '项目信息' },
            { key: 'includeSiteInfo', label: '工点信息' },
            { key: 'includePhotos', label: '照片记录' },
            { key: 'includeStatistics', label: '统计信息' },
            { key: 'includeTimeline', label: '时间线' },
            { key: 'includeLocation', label: '位置信息' },
            { key: 'includeWeather', label: '天气信息' },
            { key: 'includeNotes', label: '备注信息' }
          ],
          (item: { key: string, label: string }) => {
            Row() {
              Text(item.label)
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: (this.reportConfig.content as any)[item.key] })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  (this.reportConfig.content as any)[item.key] = isOn
                })
            }
            .width('100%')
          },
          (item: { key: string, label: string }) => item.key
        )
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建页面设置
   */
  @Builder
  private buildPageSettings() {
    Column({ space: 12 }) {
      Text('页面设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        Row() {
          Text('页面大小')
            .fontSize(14)
            .fontColor('#333333')
            .width(80)

          Text(this.reportConfig.pageSettings.pageSize)
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('页面方向')
            .fontSize(14)
            .fontColor('#333333')
            .width(80)

          Text(this.reportConfig.pageSettings.orientation === 'portrait' ? '竖向' : '横向')
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('页边距')
            .fontSize(14)
            .fontColor('#333333')
            .width(80)

          Text(`${this.reportConfig.pageSettings.margin}mm`)
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
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建水印设置
   */
  @Builder
  private buildWatermarkSettings() {
    Column({ space: 12 }) {
      Text('水印设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row() {
        Text('启用水印')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.reportConfig.watermark.enabled })
          .selectedColor('#007AFF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            this.reportConfig.watermark.enabled = isOn
          })
      }
      .width('100%')

      if (this.reportConfig.watermark.enabled) {
        Column({ space: 8 }) {
          Row() {
            Text('水印文字')
              .fontSize(14)
              .fontColor('#333333')
              .width(80)

            Text(this.reportConfig.watermark.text)
              .fontSize(14)
              .fontColor('#666666')
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('透明度')
              .fontSize(14)
              .fontColor('#333333')
              .width(80)

            Text(`${Math.round(this.reportConfig.watermark.opacity * 100)}%`)
              .fontSize(14)
              .fontColor('#666666')
              .layoutWeight(1)
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
      Text('报告预览')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      // 预览内容
      this.buildPreviewCard()

      Button('关闭')
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .width('100%')
        .onClick(() => this.showPreviewDialog = false)
    }
    .width('90%')
    .height('80%')
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
    .position({ x: '5%', y: '10%' })
  }

  /**
   * 构建模板选择对话框
   */
  @Builder
  private buildTemplateDialog() {
    Column({ space: 16 }) {
      Text('选择报告模板')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Column({ space: 12 }) {
        ForEach(
          [
            { template: ReportTemplate.BASIC, name: '基础模板', desc: '包含基本的项目信息和照片记录' },
            { template: ReportTemplate.DETAILED, name: '详细模板', desc: '包含完整的项目信息、统计和时间线' },
            { template: ReportTemplate.SUMMARY, name: '汇总模板', desc: '简化的项目概述和关键信息' },
            { template: ReportTemplate.CUSTOM, name: '自定义模板', desc: '根据需要自由配置报告内容' }
          ],
          (item: { template: ReportTemplate, name: string, desc: string }) => {
            Column({ space: 8 }) {
              Row() {
                Text(item.name)
                  .fontSize(16)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)

                if (this.selectedTemplate === item.template) {
                  Image($r('app.media.ic_check'))
                    .width(16)
                    .height(16)
                    .fillColor('#007AFF')
                }
              }
              .width('100%')

              Text(item.desc)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .width('100%')
            .padding(12)
            .borderRadius(8)
            .backgroundColor(this.selectedTemplate === item.template ? '#F0F8FF' : '#F8F8F8')
            .onClick(() => {
              this.selectTemplate(item.template)
              this.showTemplateDialog = false
            })
          },
          (item: { template: ReportTemplate, name: string, desc: string }) => item.template
        )
      }
      .width('100%')

      Button('取消')
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .width('100%')
        .onClick(() => this.showTemplateDialog = false)
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
   * 构建生成进度对话框
   */
  @Builder
  private buildGenerateProgressDialog() {
    Column({ space: 20 }) {
      // 进度指示器
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007AFF')

      // 生成描述
      Text('正在生成报告...')
        .fontSize(16)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      // 进度条
      Progress({
        value: this.currentGenerateProgress,
        total: 100,
        type: ProgressType.Linear
      })
      .width('80%')
      .color('#007AFF')
      .backgroundColor('#F0F0F0')

      // 进度百分比
      Text(`${this.currentGenerateProgress}%`)
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