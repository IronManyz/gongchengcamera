/**
 * 项目列表页面
 * 显示所有项目，支持搜索、过滤、排序和下拉刷新功能
 */

import router from '@ohos.router'
import { Project } from '../../models/Project'
import { projectStore } from '../../store/project/ProjectStore'
import { ProjectFilter, ProjectSortOrder, ProjectStatus } from '../../types/AppTypes'
import { SearchBar } from '../../components/common/SearchBar'
import { EmptyView } from '../../components/common/EmptyView'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

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

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

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
      .padding({ horizontal: 16 })

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
    .margin({ horizontal: 16 })
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
        .padding({ horizontal: 16, vertical: 8 })
        .onRefresh(() => this.onRefresh())
      } else {
        EmptyView({
          icon: $r('app.media.ic_empty_projects'),
          message: this.searchQuery ? '未找到匹配的项目' : '暂无项目',
          description: this.searchQuery ? '尝试修改搜索条件' : '点击下方按钮创建第一个项目'
        })
          .layoutWeight(1)
          .margin({ horizontal: 16 })
      }
    }
  }

  /**
   * 构建项目项
   */
  @Builder
  private buildProjectItem(project: Project) {
    Column() {
      // 项目基本信息
      Row({ space: 12 }) {
        // 项目状态指示器
        Column() {
          Text('')
            .width(4)
            .height(40)
            .borderRadius(2)
            .backgroundColor(this.getProjectStatusColor(project.status))
        }
        .margin({ left: 4 })

        // 项目信息
        Column({ space: 8 }) {
          // 项目名称和状态
          Row() {
            Text(project.getDisplayName())
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(project.getStatusText())
              .fontSize(12)
              .fontColor(this.getProjectStatusColor(project.status))
              .padding({ horizontal: 8, vertical: 4 })
              .backgroundColor(`${this.getProjectStatusColor(project.status)}20`)
              .borderRadius(12)
          }
          .width('100%')

          // 项目代码和客户
          Row({ space: 16 }) {
            if (project.code) {
              Text(`编号: ${project.code}`)
                .fontSize(14)
                .fontColor('#666666')
            }

            if (project.client) {
              Text(`客户: ${project.client}`)
                .fontSize(14)
                .fontColor('#666666')
            }

            Blank()

            Text(`${this.formatDate(project.startDate)} - ${this.formatDate(project.endDate)}`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')

          // 项目描述（如果有）
          if (project.description) {
            Text(project.description)
              .fontSize(14)
              .fontColor('#666666')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }

          // 统计信息和标签
          Row({ space: 16 }) {
            // 工点和照片统计
            Row({ space: 12 }) {
              Text(`${project.siteCount} 个工点`)
                .fontSize(12)
                .fontColor('#666666')

              Text(`${project.photoCount} 张照片`)
                .fontSize(12)
                .fontColor('#666666')
            }

            // 标签
            if (project.tags.length > 0) {
              Row({ space: 8 }) {
                ForEach(
                  project.tags.slice(0, 3),
                  (tag: string) => {
                    Text(tag)
                      .fontSize(10)
                      .fontColor('#007AFF')
                      .padding({ horizontal: 6, vertical: 2 })
                      .backgroundColor('#007AFF20')
                      .borderRadius(10)
                  },
                  (tag: string) => tag
                )

                if (project.tags.length > 3) {
                  Text(`+${project.tags.length - 3}`)
                    .fontSize(10)
                    .fontColor('#666666')
                    .padding({ horizontal: 6, vertical: 2 })
                    .backgroundColor('#F0F0F0')
                    .borderRadius(10)
                }
              }
            }
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Column({ space: 8 }) {
          Button() {
            Image($r('app.media.ic_more'))
              .width(20)
              .height(20)
              .fillColor('#666666')
          }
          .width(36)
          .height(36)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            // 显示更多操作菜单
          })
        }
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.navigateToProjectDetail(project))
    .onLongPress(() => {
      this.selectedProject = project
      this.showDeleteDialog = true
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