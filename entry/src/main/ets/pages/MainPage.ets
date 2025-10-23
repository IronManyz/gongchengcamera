/**
 * 主界面 - 工程列表
 * 根据原型设计实现的工程管理主界面
 * 包含统计概览、工程列表和底部导航
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { StatCard } from '../components/common/StatCard'
import { SearchBar } from '../components/common/SearchBar'
import { DeleteConfirmDialog } from '../components/common/ConfirmDialog'
import { SimpleProjectCard } from '../components/project/SimpleProjectCard'
import { SimpleProject, ProjectStatus } from '../models/SimpleProject'

interface StatusFilterOption {
  key: 'all' | ProjectStatus
  label: string
}

const PROJECT_STATUS_FILTERS: StatusFilterOption[] = [
  { key: 'all', label: '全部' },
  { key: ProjectStatus.ACTIVE, label: '进行中' },
  { key: ProjectStatus.COMPLETED, label: '已完成' },
  { key: ProjectStatus.PAUSED, label: '已暂停' },
  { key: ProjectStatus.CANCELLED, label: '已取消' }
]

@Entry
@Component
struct MainPage {
  @State private currentTab: string = 'projects'
  @State private searchQuery: string = ''
  @State private totalProjectCount: number = 0
  @State private totalSiteCount: number = 0
  @State private totalPhotoCount: number = 0
  @State private projectRevision: number = 0
  @State private statusFilter: 'all' | ProjectStatus = 'all'
  private projects: SimpleProject[] = []
  private filteredProjects: SimpleProject[] = []
  private activeProjectCache: SimpleProject | null = null
  @State private showSearchPanel: boolean = false
  @State private showQuickActions: boolean = false
  @State private showCreateDialog: boolean = false
  @State private newProjectName: string = ''
  @State private newProjectManager: string = ''
  @State private newProjectDescription: string = ''
  @State private activeProjectId: string | null = null
  @State private showProjectActions: boolean = false
  @State private showDeleteDialog: boolean = false

  aboutToAppear(): void {
    console.log('MainPage aboutToAppear')
    this.initializeProjects()
  }

  /**
   * 初始化工程数据
   */
  private initializeProjects(): void {
    if (this.projects.length > 0) {
      this.searchProjects()
      this.updateProjectStatistics()
      return
    }

    const mockProjects = this.createMockProjects()
    this.projects = mockProjects
    this.searchProjects()
    this.updateProjectStatistics()
  }

  /**
   * 构建默认工程数据
   */
  private createMockProjects(): SimpleProject[] {
    const now = new Date()

    const projectA = new SimpleProject('P2025-001', '市政道路改造工程', ProjectStatus.ACTIVE, '张三', 4, 52)
    projectA.code = 'P2025-001'
    projectA.client = '市政建设局'
    projectA.description = '市区主干道改造，一期覆盖 4 个工点，持续优化排水系统与道路铺装。'
    projectA.createdAt = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 30)
    projectA.updatedAt = new Date(now.getTime() - 1000 * 60 * 60 * 6)

    const projectB = new SimpleProject('P2025-002', '电力线路巡检工程', ProjectStatus.COMPLETED, '李四', 6, 89)
    projectB.code = 'P2025-002'
    projectB.client = '国家电网'
    projectB.description = '城区高压线路巡检与隐患排查，输出巡检照片与整改单。'
    projectB.createdAt = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 90)
    projectB.updatedAt = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 2)

    const projectC = new SimpleProject('P2025-003', '园林绿化项目', ProjectStatus.PAUSED, '王五', 2, 15)
    projectC.code = 'P2025-003'
    projectC.client = '城市园林管理处'
    projectC.description = '城区绿化提升工程，当前因设计调整暂缓施工。'
    projectC.createdAt = new Date(now.getTime() - 1000 * 60 * 60 * 24 * 45)
    projectC.updatedAt = new Date(now.getTime() - 1000 * 60 * 60 * 12)

    return [projectA, projectB, projectC]
  }

  /**
   * 更新工程统计信息
   */
  private updateProjectStatistics(): void {
    this.totalProjectCount = this.projects.length
    this.totalSiteCount = this.projects.reduce((sum, project) => sum + project.siteCount, 0)
    this.totalPhotoCount = this.projects.reduce((sum, project) => sum + project.photoCount, 0)
  }

  /**
   * 生成工程编号
   */
  private generateProjectCode(): string {
    const prefix = `P${new Date().getFullYear()}`
    const random = Math.floor(Math.random() * 900 + 100)
    return `${prefix}-${random}`
  }

  /**
   * 获取当前选中工程
   */
  private getActiveProject(): SimpleProject | null {
    if (!this.activeProjectId) {
      return null
    }
    if (this.activeProjectCache && this.activeProjectCache.id === this.activeProjectId) {
      return this.activeProjectCache
    }

    const project = this.projects.find((item: SimpleProject) => item.id === this.activeProjectId) || null
    this.activeProjectCache = project
    return project
  }

  /**
   * 刷新工程列表视图
   */
  private refreshProjectView(): void {
    this.projectRevision++
  }

  /**
   * 处理项目卡片点击
   */
  private handleProjectClick(project: SimpleProject): void {
    console.log('Project clicked:', project.name)
    this.closeProjectActions()
    router.pushUrl({
      url: 'pages/project/ProjectDetailPage',
      params: { projectId: project.id }
    }).catch((error: Error) => {
      console.error('跳转到项目详情失败:', error)
    })
  }

  /**
   * 处理项目卡片长按
   */
  private handleProjectLongPress(project: SimpleProject): void {
    console.log('Project long pressed:', project.name)
    this.closeQuickActions()
    this.activeProjectId = project.id
    this.activeProjectCache = project
    this.showProjectActions = true
  }

  /**
   * 跳转到拍照页面
   */
  private navigateToCamera(): void {
    console.log('Navigate to camera - Starting navigation')
    this.closeQuickActions()
    this.closeProjectActions()
    try {
      router.pushUrl({
        url: 'pages/camera/CameraPage_Simple',
        params: {}
      }).then(() => {
        console.log('Successfully navigated to camera page')
      }).catch((error: Error) => {
        console.error('跳转到相机页面失败:', error)
      })
    } catch (error) {
      console.error('Navigation to camera failed with exception:', error)
    }
  }

  /**
   * 跳转到相册页面
   */
  private navigateToGallery(): void {
    console.log('Navigate to gallery - Starting navigation')
    this.closeQuickActions()
    this.closeProjectActions()
    try {
      router.replaceUrl({
        url: 'pages/gallery/GalleryPlaceholderPage',
        params: {}
      }).then(() => {
        console.log('Successfully navigated to gallery page')
      }).catch((error: Error) => {
        console.error('跳转到相册页面失败:', error)
      })
    } catch (error) {
      console.error('Navigation to gallery failed with exception:', error)
    }
  }

  /**
   * 跳转到设置页面
   */
  private navigateToSettings(): void {
    console.log('Navigate to settings - Starting navigation')
    this.closeQuickActions()
    this.closeProjectActions()
    try {
      router.replaceUrl({
        url: 'pages/settings/SettingsPlaceholderPage',
        params: {}
      }).then(() => {
        console.log('Successfully navigated to settings page')
      }).catch((error: Error) => {
        console.error('跳转到设置页面失败:', error)
      })
    } catch (error) {
      console.error('Navigation to settings failed with exception:', error)
    }
  }

  /**
   * 创建新工程
   */
  private createNewProject(): void {
    console.log('Create new project')
    this.closeQuickActions()
    this.openCreateDialog()
  }

  /**
   * 打开创建工程对话框
   */
  private openCreateDialog(): void {
    this.resetProjectForm()
    this.showCreateDialog = true
  }

  /**
   * 关闭创建工程对话框
   */
  private closeCreateDialog(): void {
    this.showCreateDialog = false
  }

  /**
   * 重置创建工程表单
   */
  private resetProjectForm(): void {
    this.newProjectName = ''
    this.newProjectManager = ''
    this.newProjectDescription = ''
  }

  /**
   * 保存新工程
   */
  private saveNewProject(): void {
    if (!this.newProjectName.trim()) {
      this.showToast('请输入工程名称')
      return
    }

    const project = new SimpleProject(this.generateProjectCode(), this.newProjectName.trim(), ProjectStatus.ACTIVE,
      this.newProjectManager.trim() || '未设置', 0, 0)
    project.code = project.id
    project.description = this.newProjectDescription.trim()
    project.client = '未设置'
    project.createdAt = new Date()
    project.updatedAt = new Date()

    this.projects = [...this.projects, project]
    this.closeCreateDialog()
    this.showToast('新工程创建成功')
    this.searchProjects()
    this.updateProjectStatistics()
  }

  /**
   * 搜索项目
   */
  private searchProjects(): void {
    const keyword = this.searchQuery.trim().toLowerCase()

    this.filteredProjects = this.projects.filter((project: SimpleProject) => {
      const matchStatus = this.statusFilter === 'all' || project.status === this.statusFilter

      if (!matchStatus) {
        return false
      }

      if (!keyword) {
        return true
      }

      const fields = [
        project.name,
        project.code,
        project.manager,
        project.client,
        project.description
      ]

      return fields.some(field => (field || '').toLowerCase().includes(keyword))
    })

    this.refreshProjectView()
  }

  /**
   * 搜索输入变化
   */
  private onSearchChange(query: string): void {
    this.searchQuery = query
    this.searchProjects()
  }

  /**
   * 搜索提交
   */
  private onSearchSubmit(query: string): void {
    this.searchQuery = query
    this.searchProjects()
  }

  /**
   * 状态筛选变更
   */
  private onStatusFilterChange(filter: 'all' | ProjectStatus): void {
    if (this.statusFilter === filter) {
      return
    }
    this.statusFilter = filter
    this.searchProjects()
  }

  /**
   * 切换搜索面板显示
   */
  private toggleSearchPanel(): void {
    const willOpen = !this.showSearchPanel
    this.showSearchPanel = !this.showSearchPanel
    if (willOpen) {
      this.closeQuickActions()
    }
    if (!this.showSearchPanel) {
      this.clearSearch()
    }
  }

  /**
   * 清空搜索条件
   */
  private clearSearch(): void {
    this.searchQuery = ''
    this.searchProjects()
  }

  /**
   * 重置筛选条件
   */
  private resetFilters(): void {
    this.searchQuery = ''
    this.statusFilter = 'all'
    this.showSearchPanel = false
    this.searchProjects()
  }

  private hasActiveFilter(): boolean {
    return this.statusFilter !== 'all' || this.searchQuery.trim().length > 0
  }

  /**
   * 关闭搜索面板
   */
  private closeSearchPanel(): void {
    this.showSearchPanel = false
    this.clearSearch()
  }

  /**
   * 打开快捷操作面板
   */
  private openQuickActions(): void {
    this.closeProjectActions()
    this.showQuickActions = true
  }

  /**
   * 关闭快捷操作面板
   */
  private closeQuickActions(): void {
    this.showQuickActions = false
  }

  /**
   * 处理快捷操作
   */
  private handleQuickAction(action: 'sync' | 'report' | 'help'): void {
    switch (action) {
      case 'sync':
        this.showToast('正在同步项目数据...')
        break
      case 'report':
        this.showToast('已生成最新工程统计报表')
        break
      case 'help':
        this.showToast('请前往设置页查看帮助文档')
        break
    }
    this.closeQuickActions()
  }

  /**
   * 关闭项目操作面板
   */
  private closeProjectActions(): void {
    this.showProjectActions = false
    // 清理选中工程缓存，保留删除流程时的缓存由调用方控制
    if (!this.showDeleteDialog) {
      this.resetActiveProject()
    }
  }

  private resetActiveProject(): void {
    this.activeProjectId = null
    this.activeProjectCache = null
  }

  /**
   * 标记工程为完成
   */
  private markProjectAsCompleted(project: SimpleProject): void {
    if (project.status === ProjectStatus.COMPLETED) {
      this.showToast('该工程已是完成状态')
      return
    }

    project.status = ProjectStatus.COMPLETED
    project.updatedAt = new Date()
    this.projects = [...this.projects]
    this.searchProjects()
    this.updateProjectStatistics()
    this.showToast('已标记工程为完成')
    this.closeProjectActions()
  }

  /**
   * 删除当前选中的工程
   */
  private deleteActiveProject(): void {
    if (!this.activeProjectId) {
      this.showDeleteDialog = false
      return
    }

    const targetId = this.activeProjectId
    this.projects = this.projects.filter((project: SimpleProject) => project.id !== targetId)
    this.resetActiveProject()
    this.showDeleteDialog = false
    this.closeProjectActions()
    this.searchProjects()
    this.updateProjectStatistics()
    this.showToast('工程已删除')
  }

  /**
   * 显示提示信息
   */
  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message,
        duration: 2000
      })
    } catch (error) {
      console.warn('showToast failed:', error)
    }
  }

  build() {
    Stack() {
      Column() {
        Blank()
          .height(24)

        this.buildTopBar()

        if (this.showSearchPanel) {
          this.buildSearchPanel()
        }

        this.buildFilterBar()

        this.buildProjectContent()

        this.buildBottomNavigation()
      }

      if (this.showQuickActions) {
        this.buildQuickActionsPanel()
      }

      if (this.showCreateDialog) {
        this.buildCreateProjectDialog()
      }

      if (this.showProjectActions && this.activeProjectCache) {
        this.buildProjectActionSheet(this.activeProjectCache)
      }

      DeleteConfirmDialog({
        show: this.showDeleteDialog,
        itemName: this.getActiveProject()?.getDisplayName() || '',
        onConfirm: () => this.deleteActiveProject(),
        onCancel: () => {
          this.showDeleteDialog = false
          this.resetActiveProject()
        },
        onClose: () => {
          this.showDeleteDialog = false
          this.resetActiveProject()
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 顶部导航栏
   */
  @Builder
  private buildTopBar() {
    Row() {
      // 侧边菜单按钮
      Button() {
        Text('☰')
          .fontSize(18)
          .fontColor(this.showQuickActions ? '#FFFFFF' : '#1890FF')
      }
      .width(36)
      .height(36)
      .backgroundColor(this.showQuickActions ? '#1890FF' : '#E6F7FF')
      .borderRadius(12)
      .onClick(() => {
        console.log('Menu clicked')
        if (this.showQuickActions) {
          this.closeQuickActions()
        } else {
          this.openQuickActions()
        }
      })

      Blank()

      // 应用标题
      Text('工程相机')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#262626')

      Blank()

      // 搜索按钮
      Button() {
        Text(this.showSearchPanel ? '✕' : '🔍')
          .fontSize(18)
          .fontColor(this.showSearchPanel ? '#FFFFFF' : '#1890FF')
      }
      .width(36)
      .height(36)
      .backgroundColor(this.showSearchPanel ? '#1890FF' : '#E6F7FF')
      .borderRadius(12)
      .margin({ right: 8 })
      .animation({ duration: 150, curve: Curve.EaseInOut })
      .onClick(() => {
        console.log('Search clicked')
        this.toggleSearchPanel()
      })

      // 拍照快捷入口
      Button() {
        Text('📷')
          .fontSize(18)
          .fontColor('#1890FF')
      }
      .width(36)
      .height(36)
      .backgroundColor('#E6F7FF')
      .borderRadius(12)
      .margin({ right: 8 })
      .onClick(() => {
        console.log('Camera quick action clicked')
        this.navigateToCamera()
      })

      // 新建按钮
      Button() {
        Text('⊕')
          .fontSize(18)
          .fontColor(this.showCreateDialog ? '#FFFFFF' : '#1890FF')
      }
      .width(36)
      .height(36)
      .backgroundColor(this.showCreateDialog ? '#1890FF' : '#E6F7FF')
      .borderRadius(12)
      .animation({ duration: 150, curve: Curve.EaseInOut })
      .onClick(() => {
        console.log('Create project button clicked')
        this.createNewProject()
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E8E8E8' })
  }

  /**
   * 搜索面板
   */
  @Builder
  private buildSearchPanel() {
    Column({ space: 8 }) {
      SearchBar({
        query: this.searchQuery,
        placeholder: '搜索工程名称、编号或负责人',
        showCancel: true,
        autoFocus: true,
        onSearch: (query: string) => this.onSearchSubmit(query),
        onChange: (query: string) => this.onSearchChange(query),
        onCancel: () => this.closeSearchPanel()
      })
        .padding({ left: 16, right: 16, top: 12 })

      if (this.searchQuery.trim().length > 0) {
        Text(`共找到 ${this.filteredProjects.length} 个工程`)
          .fontSize(12)
          .fontColor('#8C8C8C')
          .padding({ left: 20, right: 20, bottom: 4 })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E8E8E8' })
  }

  /**
   * 工程状态筛选
   */
  @Builder
  private buildFilterBar() {
    Row({ space: 8 }) {
      ForEach(PROJECT_STATUS_FILTERS, (option: StatusFilterOption) => {
        Button(option.label)
          .fontSize(14)
          .fontColor(this.statusFilter === option.key ? '#FFFFFF' : '#1890FF')
          .backgroundColor(this.statusFilter === option.key ? '#1890FF' : '#EDF4FF')
          .padding({ left: 16, right: 16 })
          .height(36)
          .borderRadius(18)
          .onClick(() => this.onStatusFilterChange(option.key))
      }, (option: StatusFilterOption) => option.key)
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  /**
   * 工程内容区域
   */
  @Builder
  private buildProjectContent() {
    Scroll() {
      Column() {
        // 统计概览
        Column() {
          Text('📊 统计概览')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262626')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          // 统计卡片行
          Row({ space: 12 }) {
            StatCard({
              title: '工程数',
              value: this.totalProjectCount.toString(),
              icon: '📁',
              color: '#1890FF'
            })

            StatCard({
              title: '工点数',
              value: this.totalSiteCount.toString(),
              icon: '📍',
              color: '#52C41A'
            })

            StatCard({
              title: '照片数',
              value: this.totalPhotoCount.toString(),
              icon: '📷',
              color: '#FAAD14'
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .margin({ bottom: 12 })
        .borderRadius(8)

        // 工程列表标题
        Row() {
          Text('🏗️ 我的工程')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262626')

          Blank()

          Text(`${this.filteredProjects.length} 个工程`)
            .fontSize(14)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
        .alignItems(VerticalAlign.Center)

        if (this.filteredProjects.length === 0) {
          Column({ space: 12 }) {
            Text(this.hasActiveFilter() ? '未找到匹配的工程' : '还没有工程项目')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .textAlign(TextAlign.Center)

            Text(this.hasActiveFilter() ? '尝试调整筛选条件或清空搜索关键字。' : '创建一个新的工程，开始管理项目与现场数据。')
              .fontSize(14)
              .fontColor('#8C8C8C')
              .textAlign(TextAlign.Center)
              .lineHeight(20)
              .padding({ left: 24, right: 24 })

            Button(this.hasActiveFilter() ? '重置筛选' : '新建工程')
              .height(44)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#1890FF')
              .borderRadius(22)
              .padding({ left: 32, right: 32 })
              .onClick(() => {
                if (this.hasActiveFilter()) {
                  this.resetFilters()
                } else {
                  this.createNewProject()
                }
              })
          }
          .width('100%')
          .padding({ top: 48, bottom: 60 })
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 80 })
        } else {
          Column({ space: 12 }) {
            ForEach(this.filteredProjects, (project: SimpleProject) => {
              SimpleProjectCard({
                project: project,
                showStats: true,
                onTap: (p: SimpleProject) => this.handleProjectClick(p),
                onLongPress: (p: SimpleProject) => this.handleProjectLongPress(p)
              })
            }, (project: SimpleProject) => `${project.id}_${this.projectRevision}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 80 }) // 底部留出导航栏空间
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
  }

  /**
   * 底部导航栏
   */
  @Builder
  private buildBottomNavigation() {
    Row() {
      // 工程导航
      Column() {
        Text('🏗️')
          .fontSize(24)
          .fontColor(this.currentTab === 'projects' ? '#1890FF' : '#8C8C8C')
        Text('工程')
          .fontSize(12)
          .fontColor(this.currentTab === 'projects' ? '#1890FF' : '#8C8C8C')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentTab === 'projects' ? '#E6F7FF' : Color.Transparent)
      .borderRadius(8)
      .padding({ top: 4, bottom: 4 })
      .animation({ duration: 200, curve: Curve.EaseInOut })
      .onClick(() => {
        console.log('Projects tab clicked')
        this.currentTab = 'projects'
        this.closeQuickActions()
      })

      // 相册导航
      Column() {
        Text('📱')
          .fontSize(24)
          .fontColor(this.currentTab === 'gallery' ? '#1890FF' : '#8C8C8C')
        Text('相册')
          .fontSize(12)
          .fontColor(this.currentTab === 'gallery' ? '#1890FF' : '#8C8C8C')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentTab === 'gallery' ? '#E6F7FF' : Color.Transparent)
      .borderRadius(8)
      .padding({ top: 4, bottom: 4 })
      .animation({ duration: 200, curve: Curve.EaseInOut })
      .onClick(() => {
        console.log('Gallery tab clicked')
        this.currentTab = 'gallery'
        this.navigateToGallery()
      })

      // 设置导航
      Column() {
        Text('⚙️')
          .fontSize(24)
          .fontColor(this.currentTab === 'settings' ? '#1890FF' : '#8C8C8C')
        Text('设置')
          .fontSize(12)
          .fontColor(this.currentTab === 'settings' ? '#1890FF' : '#8C8C8C')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentTab === 'settings' ? '#E6F7FF' : Color.Transparent)
      .borderRadius(8)
      .padding({ top: 4, bottom: 4 })
      .animation({ duration: 200, curve: Curve.EaseInOut })
      .onClick(() => {
        console.log('Settings tab clicked')
        this.currentTab = 'settings'
        this.navigateToSettings()
      })
    }
    .width('100%')
    .height(60)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#E8E8E8' })
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ bottom: 8 }) // 为安全区域留出空间
  }

  /**
   * 快捷操作面板
   */
  @Builder
  private buildQuickActionsPanel() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.35)')
        .onClick(() => this.closeQuickActions())

      Column({ space: 12 }) {
        Text('快捷操作')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')

        Text('同步项目数据')
          .fontSize(16)
          .fontColor('#1890FF')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => this.handleQuickAction('sync'))

        Text('导出项目报表')
          .fontSize(16)
          .fontColor('#262626')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => this.handleQuickAction('report'))

        Text('查看帮助与指南')
          .fontSize(16)
          .fontColor('#262626')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => this.handleQuickAction('help'))

        Divider()
          .color('#F0F0F0')
          .margin({ top: 8, bottom: 8 })

        Text('关闭')
          .fontSize(16)
          .fontColor('#8C8C8C')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => this.closeQuickActions())
      }
      .width('88%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .padding({ top: 20, bottom: 12, left: 20, right: 20 })
      .shadow({
        radius: 18,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 8
      })
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(200)
  }

  /**
   * 创建工程对话框
   */
  @Builder
  private buildCreateProjectDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.35)')
        .onClick(() => this.closeCreateDialog())

      Column({ space: 16 }) {
        Text('新建工程')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')

        Column({ space: 12 }) {
          Text('工程名称')
            .fontSize(14)
            .fontColor('#8C8C8C')
          TextInput({ placeholder: '请输入工程名称', text: this.newProjectName })
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .height(48)
            .padding({ left: 12, right: 12 })
            .borderRadius(12)
            .onChange((value: string) => this.newProjectName = value)

          Text('负责人')
            .fontSize(14)
            .fontColor('#8C8C8C')
          TextInput({ placeholder: '请输入负责人', text: this.newProjectManager })
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .height(48)
            .padding({ left: 12, right: 12 })
            .borderRadius(12)
            .onChange((value: string) => this.newProjectManager = value)

          Text('工程简介')
            .fontSize(14)
            .fontColor('#8C8C8C')
          TextArea({ placeholder: '可选，说明工程的主要内容', text: this.newProjectDescription })
            .fontSize(16)
            .backgroundColor('#F5F5F5')
            .height(96)
            .borderRadius(12)
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .onChange((value: string) => this.newProjectDescription = value)
        }

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor('#8C8C8C')
            .backgroundColor('#F0F0F0')
            .borderRadius(12)
            .onClick(() => this.closeCreateDialog())

          Button('创建')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .borderRadius(12)
            .onClick(() => this.saveNewProject())
        }
      }
      .width('88%')
      .backgroundColor('#FFFFFF')
      .padding({ left: 20, right: 20, top: 24, bottom: 20 })
      .borderRadius(20)
      .shadow({
        radius: 24,
        color: 'rgba(0, 0, 0, 0.18)',
        offsetX: 0,
        offsetY: 12
      })
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(250)
  }

  /**
   * 工程操作面板
   */
  @Builder
  private buildProjectActionSheet(project: SimpleProject) {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.35)')
        .onClick(() => this.closeProjectActions())

      Column({ space: 12 }) {
        Text(project.getDisplayName())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')
          .textAlign(TextAlign.Center)

        Button('查看详情')
          .height(44)
          .fontSize(16)
          .fontColor('#1890FF')
          .backgroundColor('#EDF4FF')
          .borderRadius(12)
          .onClick(() => {
            this.handleProjectClick(project)
          })

        Button(project.status === ProjectStatus.COMPLETED ? '标记为进行中' : '标记为完成')
          .height(44)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(project.status === ProjectStatus.COMPLETED ? '#52C41A' : '#1890FF')
          .borderRadius(12)
          .onClick(() => {
            if (project.status === ProjectStatus.COMPLETED) {
              project.status = ProjectStatus.ACTIVE
              project.updatedAt = new Date()
              this.projects = [...this.projects]
              this.searchProjects()
              this.updateProjectStatistics()
              this.showToast('已恢复工程为进行中')
              this.closeProjectActions()
            } else {
              this.markProjectAsCompleted(project)
            }
          })

        Button('删除工程')
          .height(44)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF4D4F')
          .borderRadius(12)
          .onClick(() => {
            this.showProjectActions = false
            this.showDeleteDialog = true
          })

        Button('取消')
          .height(44)
          .fontSize(16)
          .fontColor('#8C8C8C')
          .backgroundColor('#F0F0F0')
          .borderRadius(12)
          .onClick(() => this.closeProjectActions())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 32 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      .alignSelf(ItemAlign.End)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(220)
  }
}
