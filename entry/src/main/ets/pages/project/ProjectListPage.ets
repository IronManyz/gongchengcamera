/**
 * 项目列表页面
 * 显示所有项目，支持搜索、过滤、排序和下拉刷新功能
 */

import router from '@ohos.router'
import { Project } from '../../models/Project'
import { projectStore } from '../../store/project/ProjectStore'
import { ProjectFilter, ProjectSortOrder, ProjectStatus } from '../../types/AppTypes'
import { SearchBar } from '../../components/common/SearchBar'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'
import { StatCard } from '../../components/common/StatCard'
import { ProjectCard } from '../../components/project/ProjectCard'

@Entry
@Component
struct ProjectListPage {
  // 状态管理
  @State private isLoading: boolean = false
  @State private isRefreshing: boolean = false
  @State private searchQuery: string = ''
  @State private currentFilter: ProjectFilter = ProjectFilter.ALL
  @State private selectedProject: Project | null = null
  @State private showDeleteDialog: boolean = false
  @State private showFilterDialog: boolean = false

  // 项目Store
  private projectStore = projectStore

  aboutToAppear() {
    this.loadProjectData()
  }

  /**
   * 加载项目数据
   */
  private async loadProjectData() {
    this.isLoading = true
    try {
      if (!this.projectStore.isInitialized) {
        await this.projectStore.initialize()
      } else {
        await this.projectStore.refresh()
      }
    } catch (error) {
      console.error('加载项目数据失败:', error)
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
      await this.projectStore.refresh()
    } catch (error) {
      console.error('刷新项目数据失败:', error)
    } finally {
      this.isRefreshing = false
    }
  }

  /**
   * 搜索处理
   */
  private onSearch(query: string) {
    this.searchQuery = query
    this.projectStore.setSearchQuery(query)
  }

  /**
   * 筛选处理
   */
  private onFilterChange(filter: ProjectFilter) {
    this.currentFilter = filter
    this.projectStore.setFilter(filter)
    this.showFilterDialog = false
  }

  /**
   * 排序处理
   */
  private onSortOrderChange(sortOrder: ProjectSortOrder) {
    this.projectStore.setSortOrder(sortOrder)
  }

  /**
   * 跳转到项目详情
   */
  private navigateToProjectDetail(project: Project) {
    router.pushUrl({
      url: 'pages/project/ProjectDetailPage',
      params: {
        projectId: project.id
      }
    })
  }

  /**
   * 跳转到创建项目
   */
  private navigateToCreateProject() {
    router.pushUrl({
      url: 'pages/project/ProjectEditPage',
      params: {
        mode: 'create'
      }
    })
  }

  /**
   * 跳转到编辑项目
   */
  private navigateToEditProject(project: Project) {
    router.pushUrl({
      url: 'pages/project/ProjectEditPage',
      params: {
        mode: 'edit',
        projectId: project.id
      }
    })
  }

  /**
   * 删除项目
   */
  private async deleteProject() {
    if (this.selectedProject) {
      const success = await this.projectStore.deleteProject(this.selectedProject.id)
      if (success) {
        this.selectedProject = null
        this.showDeleteDialog = false
      }
    }
  }

  /**
   * 获取项目状态颜色
   */
  private getProjectStatusColor(status: ProjectStatus): string {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return '#4CAF50'
      case ProjectStatus.COMPLETED:
        return '#2196F3'
      case ProjectStatus.PAUSED:
        return '#FF9800'
      case ProjectStatus.CANCELLED:
        return '#F44336'
      default:
        return '#757575'
    }
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  }

  /**
   * 获取项目统计信息
   */
  private getProjectStats() {
    const projects = this.projectStore.projects
    const totalProjects = projects.length
    const activeProjects = projects.filter(p => p.status === ProjectStatus.ACTIVE).length
    const totalSites = projects.reduce((sum, p) => sum + (p.siteCount || 0), 0)
    const totalPhotos = projects.reduce((sum, p) => sum + (p.photoCount || 0), 0)

    return {
      totalProjects,
      activeProjects,
      totalSites,
      totalPhotos
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 统计概览卡片
      this.buildStatsOverview()

      // 搜索和筛选栏
      this.buildSearchAndFilterBar()

      // 项目列表
      this.buildProjectList()

      // 底部操作栏
      this.buildBottomActionBar()

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 删除确认对话框
      if (this.showDeleteDialog && this.selectedProject) {
        ConfirmDialog({
          title: '删除项目',
          message: `确定要删除项目"${this.selectedProject.getDisplayName()}"吗？此操作不可恢复。`,
          confirmText: '删除',
          cancelText: '取消',
          onConfirm: () => this.deleteProject(),
          onCancel: () => {
            this.showDeleteDialog = false
            this.selectedProject = null
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建统计概览卡片
   */
  @Builder
  private buildStatsOverview() {
    const stats = this.getProjectStats()

    Column() {
      // 标题
      Text('📊 统计概览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#262626')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 统计卡片网格
      Row() {
        StatCard({
          title: '工程总数',
          value: stats.totalProjects,
          icon: $r('app.media.ic_folder'),
          color: '#1890FF',
          trend: 'stable'
        })
        .layoutWeight(1)

        StatCard({
          title: '进行中',
          value: stats.activeProjects,
          icon: $r('app.media.ic_folder'),
          color: '#52C41A',
          trend: 'up'
        })
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        StatCard({
          title: '工点总计',
          value: stats.totalSites,
          icon: $r('app.media.ic_folder'),
          color: '#FAAD14',
          trend: 'stable'
        })
        .layoutWeight(1)

        StatCard({
          title: '照片总计',
          value: stats.totalPhotos,
          icon: $r('app.media.ic_folder'),
          color: '#722ED1',
          trend: 'up'
        })
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 16, right: 16, top: 12, bottom: 12 })
    .shadow({
      radius: 6,
      color: '#00000008',
      offsetX: 0,
      offsetY: 3
    })
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
      .onClick(() => {
        router.back()
      })

      // 标题
      Text('项目管理')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 统计信息
      if (this.projectStore.projectStats) {
        Text(`${this.projectStore.projectStats.totalCount}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 12 })
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
        placeholder: '搜索项目名称、代码、客户...',
        onSearch: (query: string) => this.onSearch(query),
        onChange: (query: string) => this.searchQuery = query
      })

      // 筛选和排序栏
      Row({ space: 12 }) {
        // 筛选按钮
        Button() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_filter'))
              .width(16)
              .height(16)
              .fillColor(this.currentFilter !== ProjectFilter.ALL ? '#007AFF' : '#666666')

            Text(this.getFilterText(this.currentFilter))
              .fontSize(14)
              .fontColor(this.currentFilter !== ProjectFilter.ALL ? '#007AFF' : '#666666')
          }
        }
        .height(36)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({
          width: 1,
          color: this.currentFilter !== ProjectFilter.ALL ? '#007AFF' : '#E0E0E0'
        })
        .onClick(() => {
          this.showFilterDialog = !this.showFilterDialog
        })

        // 排序按钮
        Button() {
          Row({ space: 6 }) {
            Image($r('app.media.ic_sort'))
              .width(16)
              .height(16)
              .fillColor('#666666')

            Text('最新')
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
          const currentOrder = this.projectStore.currentSortOrder
          if (currentOrder === ProjectSortOrder.UPDATED_DESC) {
            this.onSortOrderChange(ProjectSortOrder.UPDATED_ASC)
          } else {
            this.onSortOrderChange(ProjectSortOrder.UPDATED_DESC)
          }
        })

        Blank()

        // 清空筛选
        if (this.currentFilter !== ProjectFilter.ALL || this.searchQuery) {
          Button('清空')
            .height(36)
            .fontSize(14)
            .fontColor('#666666')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.searchQuery = ''
              this.currentFilter = ProjectFilter.ALL
              this.projectStore.clearSearchConditions()
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 筛选选项弹窗
      if (this.showFilterDialog) {
        this.buildFilterDialog()
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建筛选对话框
   */
  @Builder
  private buildFilterDialog() {
    Column({ space: 0 }) {
      // 筛选选项
      ForEach(
        [
          { key: ProjectFilter.ALL, label: '全部项目' },
          { key: ProjectFilter.ACTIVE, label: '进行中' },
          { key: ProjectFilter.COMPLETED, label: '已完成' },
          { key: ProjectFilter.PAUSED, label: '已暂停' },
          { key: ProjectFilter.CANCELLED, label: '已取消' }
        ],
        (filter: { key: ProjectFilter, label: string }) => {
          Row() {
            Text(filter.label)
              .fontSize(16)
              .fontColor(this.currentFilter === filter.key ? '#007AFF' : '#333333')
              .layoutWeight(1)

            if (this.currentFilter === filter.key) {
              Image($r('app.media.ic_check'))
                .width(20)
                .height(20)
                .fillColor('#007AFF')
            }
          }
          .width('100%')
          .height(48)
          .padding({ horizontal: 16 })
          .onClick(() => this.onFilterChange(filter.key))

          if (filter.key !== ProjectFilter.CANCELLED) {
            Divider().color('#F0F0F0')
          }
        },
        (filter: { key: ProjectFilter, label: string }) => filter.key
      )
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 16, right: 16 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 2
    })
    .zIndex(10)
  }

  /**
   * 构建项目列表
   */
  @Builder
  private buildProjectList() {
    Refresh({ refreshing: $$isRefreshing, friction: 100 }) {
      if (this.projectStore.hasFilteredProjects) {
        List({ space: 12, onRefresh: () => this.onRefresh() }) {
          ForEach(
            this.projectStore.filteredProjects,
            (project: Project) => {
              ListItem() {
                this.buildProjectItem(project)
              }
            },
            (project: Project) => project.id
          )
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      } else {
        Column() {
          Image($r('app.media.ic_folder'))
            .width(120)
            .height(120)
            .fillColor('#C0C0C0')
            .margin({ bottom: 16 })

          Text(this.searchQuery ? '未找到匹配的项目' : '暂无项目')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
            .margin({ bottom: 8 })

          Text(this.searchQuery ? '尝试修改搜索条件' : '点击下方按钮创建第一个项目')
            .fontSize(14)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .lineHeight(20)
            .padding({ left: 32, right: 32 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .margin({ left: 16, right: 16 })
      }
    }
  }

  /**
   * 构建项目项
   */
  @Builder
  private buildProjectItem(project: Project) {
    ProjectCard({
      project: project,
      showStats: true,
      onTap: (project) => this.navigateToProjectDetail(project),
      onLongPress: (project) => {
        this.selectedProject = project
        this.showDeleteDialog = true
      }
    })
  }

  /**
   * 构建底部操作栏
   */
  @Builder
  private buildBottomActionBar() {
    Row() {
      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')

          Text('新建项目')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
      }
      .height(48)
      .padding({ horizontal: 24 })
      .backgroundColor('#007AFF')
      .borderRadius(24)
      .margin({ bottom: 20 })
      .onClick(() => this.navigateToCreateProject())
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.Transparent)
  }

  /**
   * 获取筛选文本
   */
  private getFilterText(filter: ProjectFilter): string {
    switch (filter) {
      case ProjectFilter.ALL:
        return '全部'
      case ProjectFilter.ACTIVE:
        return '进行中'
      case ProjectFilter.COMPLETED:
        return '已完成'
      case ProjectFilter.PAUSED:
        return '已暂停'
      case ProjectFilter.CANCELLED:
        return '已取消'
      default:
        return '全部'
    }
  }
}