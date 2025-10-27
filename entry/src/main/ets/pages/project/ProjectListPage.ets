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
import { ProjectCard } from '../../components/project/ProjectCard'


/**
 * 过滤选项接口
 */
interface FilterOption {
  key: ProjectFilter
  label: string
}

/**
 * 选项接口
 */
interface OptionItem {
  key: string
  label: string
}

/**
 * 时间范围选项类型
 */
type TimeRangeKey = 'all' | 'today' | 'week' | 'month' | 'quarter' | 'year'

/**
 * 优先级选项类型
 */
type PriorityKey = 'all' | 'high' | 'medium' | 'low'

/**
 * 日期范围接口
 */
interface DateRange {
  start: Date
  end: Date
}

@Entry
@Component
struct ProjectListPage {
  // 状态管理
  @State private isLoading: boolean = false
  @State private isRefreshing: boolean = false
  @State private searchQuery: string = ''
  @State private currentFilter: ProjectFilter = ProjectFilter.ALL
  @State private selectedProjectId: string = ''
  @State private showDeleteDialog: boolean = false
  @State private showFilterDialog: boolean = false
  @State private showAdvancedFilter: boolean = false
  @State private selectedManager: string = 'all'
  @State private selectedTimeRange: string = 'all'
  @State private selectedPriority: string = 'all'

  // 项目Store
  private projectStore = projectStore

  // 筛选选项
  private readonly filterOptions: FilterOption[] = [
    { key: ProjectFilter.ALL, label: '全部项目' },
    { key: ProjectFilter.ACTIVE, label: '进行中' },
    { key: ProjectFilter.COMPLETED, label: '已完成' },
    { key: ProjectFilter.PAUSED, label: '已暂停' },
    { key: ProjectFilter.CANCELLED, label: '已取消' }
  ]

  // 时间范围选项
  private readonly timeRangeOptions: OptionItem[] = [
    { key: 'all', label: '全部时间' },
    { key: 'today', label: '今天' },
    { key: 'week', label: '本周' },
    { key: 'month', label: '本月' },
    { key: 'quarter', label: '本季度' },
    { key: 'year', label: '本年' }
  ]

  // 优先级选项
  private readonly priorityOptions: OptionItem[] = [
    { key: 'all', label: '全部优先级' },
    { key: 'high', label: '高优先级' },
    { key: 'medium', label: '中优先级' },
    { key: 'low', label: '低优先级' }
  ]

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
  private async onRefresh(): Promise<void> {
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
  private onSearch(query: string): void {
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
  private navigateToProjectDetail(project: Project): void {
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
  private async deleteProject(): Promise<void> {
    if (this.selectedProjectId) {
      const success = await this.projectStore.deleteProject(this.selectedProjectId)
      if (success) {
        this.selectedProjectId = ''
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
        LoadingDialog({
          show: this.isLoading,
          message: '加载中...',
          onCancel: () => {}
        })
      }

      // 删除确认对话框
      if (this.showDeleteDialog) {
        ConfirmDialog({
          show: this.showDeleteDialog,
          title: '删除项目',
          message: `确定要删除选中的项目吗？此操作不可恢复。`,
          confirmText: '删除',
          cancelText: '取消',
          onConfirm: () => this.deleteProject(),
          onCancel: () => {
            this.showDeleteDialog = false
            this.selectedProjectId = ''
          },
          onClose: () => {
            this.showDeleteDialog = false
            this.selectedProjectId = ''
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
    if (this.projectStore.projectStats) {
      Column({ space: 16 }) {
        // 主要统计卡片
        Row() {
          // 工程数量统计
          Column() {
            Text(String(this.projectStore.projectStats.totalProjects))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007AFF')

            Text('总工程')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .width('33.33%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F0F8FF')
          .borderRadius(12)
          .padding({ top: 16, bottom: 16 })

          // 工点数量统计
          Column() {
            Text(String(this.projectStore.projectStats.totalSites))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#34C759')

            Text('总工点')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .width('33.33%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F0FFF4')
          .borderRadius(12)
          .padding({ top: 16, bottom: 16 })

          // 照片数量统计
          Column() {
            Text(String(this.projectStore.projectStats.totalPhotos))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')

            Text('总照片')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .width('33.33%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFF8F0')
          .borderRadius(12)
          .padding({ top: 16, bottom: 16 })
        }
        .width('100%')
        .height(100)
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // 状态分布统计
        if (this.projectStore.projectStats.projectsByStatus) {
          Row({ space: 8 }) {
            this.buildStatusIndicator('进行中', this.projectStore.projectStats.projectsByStatus[ProjectStatus.ACTIVE] || 0, '#4CAF50')
            this.buildStatusIndicator('已完成', this.projectStore.projectStats.projectsByStatus[ProjectStatus.COMPLETED] || 0, '#2196F3')
            this.buildStatusIndicator('已暂停', this.projectStore.projectStats.projectsByStatus[ProjectStatus.PAUSED] || 0, '#FF9800')
            this.buildStatusIndicator('已取消', this.projectStore.projectStats.projectsByStatus[ProjectStatus.CANCELLED] || 0, '#F44336')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.SpaceEvenly)
        }
      }
      .width('100%')
      .padding({ top: 12, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 4,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 2
      })
    }
  }

  /**
   * 构建状态指示器
   */
  @Builder
  private buildStatusIndicator(label: string, count: number, color: string) {
    Column() {
      Text(String(count))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .flexShrink(1)
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  private buildTopBar() {
    Row() {
      // 返回按钮
      Button() {
        Text('🔙')
          .width(24)
          .height(24)
          .fontColor('#333333')
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
            Text('🔍')
              .width(16)
              .height(16)
              .fontColor(this.currentFilter !== ProjectFilter.ALL ? '#007AFF' : '#666666')

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

        // 高级筛选按钮
        Button() {
          Row({ space: 6 }) {
            Text('⚙️')
              .width(16)
              .height(16)
              .fontColor(this.hasAdvancedFilters() ? '#007AFF' : '#666666')

            Text('高级')
              .fontSize(14)
              .fontColor(this.hasAdvancedFilters() ? '#007AFF' : '#666666')
          }
        }
        .height(36)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({
          width: 1,
          color: this.hasAdvancedFilters() ? '#007AFF' : '#E0E0E0'
        })
        .onClick(() => {
          this.showAdvancedFilter = !this.showAdvancedFilter
        })

        // 排序按钮
        Button() {
          Row({ space: 6 }) {
            Text('📊')
              .width(16)
              .height(16)
              .fontColor('#666666')

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

      // 高级筛选弹窗
      if (this.showAdvancedFilter) {
        this.buildAdvancedFilterDialog()
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
        this.filterOptions,
        (filter: FilterOption) => {
          Row() {
            Text(filter.label)
              .fontSize(16)
              .fontColor(this.currentFilter === filter.key ? '#007AFF' : '#333333')
              .layoutWeight(1)

            if (this.currentFilter === filter.key) {
              Text('✅')
                .width(20)
                .height(20)
                .fontColor('#007AFF')
            }
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .onClick(() => this.onFilterChange(filter.key))

          if (filter.key !== ProjectFilter.CANCELLED) {
            Divider().color('#F0F0F0')
          }
        },
        (filter: FilterOption) => filter.key
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
        List({ space: 12 }) {
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
          Text('📁')
            .width(120)
            .height(120)
            .fontColor('#C0C0C0')
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
        this.selectedProjectId = project.id
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
          Text('➕')
            .width(20)
            .height(20)
            .fontColor('#FFFFFF')

          Text('新建项目')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
      }
      .height(48)
      .padding({ left: 24, right: 24 })
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
   * 构建高级筛选对话框
   */
  @Builder
  private buildAdvancedFilterDialog() {
    Column() {
      // 头部
      Row() {
        Text('高级筛选')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button('关闭')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showAdvancedFilter = false
          })
      }
      .width('100%')
      .padding(16)
      .borderRadius({ topLeft: 8, topRight: 8 })

      Divider().color('#F0F0F0')

      // 时间范围筛选
      Column() {
        Text('时间范围')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 12 })

        Grid() {
          ForEach(
            this.timeRangeOptions,
            (option: OptionItem) => {
              GridItem() {
                Text(option.label)
                  .fontSize(14)
                  .fontColor(this.selectedTimeRange === (option.key as TimeRangeKey) ? '#007AFF' : '#333333')
                  .backgroundColor(this.selectedTimeRange === (option.key as TimeRangeKey) ? '#E6F4FF' : '#F8F8F8')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .borderRadius(6)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.selectedTimeRange = option.key as TimeRangeKey
                  })
              }
            },
            (option: OptionItem) => option.key
          )
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)

      Divider().color('#F0F0F0')

      // 优先级筛选
      Column() {
        Text('优先级')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 12 })

        Row({ space: 8 }) {
          ForEach(
            this.priorityOptions,
            (option: OptionItem) => {
              Text(option.label)
                .fontSize(14)
                .fontColor(this.selectedPriority === option.key ? '#007AFF' : '#333333')
                .backgroundColor(this.selectedPriority === option.key ? '#E6F4FF' : '#F8F8F8')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(6)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.selectedPriority = option.key as PriorityKey
                })
            },
            (option: OptionItem) => option.key as string
          )
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)

      Divider().color('#F0F0F0')

      // 操作按钮
      Row({ space: 12 }) {
        Button('重置')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F8F8F8')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .onClick(() => {
            this.resetAdvancedFilters()
          })

        Button('应用筛选')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .onClick(() => {
            this.applyAdvancedFilters()
          })
      }
      .width('100%')
      .padding(16)
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
   * 检查是否有高级筛选
   */
  private hasAdvancedFilters(): boolean {
    return this.selectedTimeRange !== 'all' ||
           this.selectedPriority !== 'all' ||
           this.selectedManager !== 'all'
  }

  /**
   * 重置高级筛选
   */
  private resetAdvancedFilters(): void {
    this.selectedTimeRange = 'all'
    this.selectedPriority = 'all'
    this.selectedManager = 'all'
    this.showAdvancedFilter = false
    // 触发重新筛选
    this.applyAdvancedFilters()
  }

  /**
   * 应用高级筛选
   */
  private applyAdvancedFilters(): void {
    // 构建筛选参数
    const filterParams: Map<string, Object> = new Map<string, Object>()

    // 添加时间范围筛选
    const timeRange = this.getTimeRangeFilter()
    if (timeRange) {
      filterParams.set('dateRange', timeRange)
    }

    // 添加优先级筛选
    const priority = this.getPriorityFilter()
    if (priority) {
      filterParams.set('priorities', [priority])
    }

    // 添加负责人筛选
    if (this.selectedManager !== 'all') {
      filterParams.set('managers', [this.selectedManager])
    }

    // 应用到ProjectStore
    this.projectStore.setAdvancedFilters(filterParams)
    this.showAdvancedFilter = false

    console.log('应用高级筛选:', filterParams)
  }

  /**
   * 获取时间范围筛选参数
   */
  private getTimeRangeFilter(): DateRange | undefined {
    const now = new Date()
    let startDate: Date | undefined

    switch (this.selectedTimeRange) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        break
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
        break
      case 'month':
        startDate = new Date(now.getFullYear(), now.getMonth(), 1)
        break
      case 'quarter':
        startDate = new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1)
        break
      case 'year':
        startDate = new Date(now.getFullYear(), 0, 1)
        break
      default:
        return undefined
    }

    if (startDate) {
      return {
        start: startDate,
        end: now
      }
    }

    return undefined
  }

  /**
   * 获取优先级筛选参数
   */
  private getPriorityFilter(): string | undefined {
    switch (this.selectedPriority) {
      case 'high':
        return 'high'
      case 'medium':
        return 'medium'
      case 'low':
        return 'low'
      default:
        return undefined
    }
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