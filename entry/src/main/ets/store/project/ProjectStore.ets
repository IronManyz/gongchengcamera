/**
 * ProjectStore.ets
 * 项目状态管理Store
 * 严格使用V2响应式状态管理，提供项目的CRUD操作和业务逻辑处理
 */

import { BaseStore } from '../BaseStore'
import { Project } from '../../models/Project'
import { ProjectService, ProjectQueryParams, ProjectStats } from '../../services/database/ProjectService'
import {
  ProjectStatus,
  ProjectFilter,
  ProjectSortOrder,
  PaginationParams,
  PaginationResult
} from '../../types/AppTypes'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ProjectStore'

/**
 * 日期范围接口
 */
export interface DateRange {
  start?: Date
  end?: Date
}

/**
 * 项目搜索和过滤参数接口
 */
export interface ProjectSearchParams {
  query?: string
  status?: ProjectStatus
  manager?: string
  client?: string
  tags?: string[]
  dateRange?: DateRange
  filter?: ProjectFilter
  sortOrder?: ProjectSortOrder
  pagination?: PaginationParams
}

/**
 * 项目管理状态接口
 */
export interface ProjectManagementState {
  isLoading: boolean
  error: string | null
  lastSyncTime: Date | null
  isCreating: boolean
  isUpdating: boolean
  isDeleting: boolean
}

/**
 * 项目管理状态实现类
 */
export class ProjectManagementStateImpl implements ProjectManagementState {
  isLoading: boolean = false
  error: string | null = null
  lastSyncTime: Date | null = null
  isCreating: boolean = false
  isUpdating: boolean = false
  isDeleting: boolean = false
}

/**
 * 项目Store类
 * 管理项目的状态和业务逻辑
 */
@ObservedV2
export class ProjectStore extends BaseStore {
  // 项目列表状态
  @Trace projects: Project[] = []
  @Trace currentProject: Project | null = null
  @Trace filteredProjects: Project[] = []

  // 搜索和过滤状态
  @Trace searchQuery: string = ''
  @Trace currentFilter: ProjectFilter = ProjectFilter.ALL
  @Trace currentSortOrder: ProjectSortOrder = ProjectSortOrder.UPDATED_DESC
  @Trace selectedTags: string[] = []

  // 分页状态
  @Trace currentPage: number = 1
  @Trace pageSize: number = 20
  @Trace totalProjects: number = 0
  @Trace totalPages: number = 0
  @Trace hasNextPage: boolean = false
  @Trace hasPrevPage: boolean = false

  // 管理状态
  @Trace managementState: ProjectManagementState = new ProjectManagementStateImpl()

  // 统计信息
  @Trace projectStats: ProjectStats | null = null

  // 服务实例
  private projectService: ProjectService

  constructor() {
    super('ProjectStore')
    this.projectService = ProjectService.getInstance()
  }

  /**
   * 初始化Store
   */
  async initialize(): Promise<void> {
    await this.safeExecute(async () => {
      this.log('开始初始化项目Store')

      // 加载项目列表
      await this.loadProjects()

      // 加载统计信息
      await this.loadProjectStats()

      this.markInitialized()
      this.log('项目Store初始化完成')

    }, 'initialize', '项目Store初始化失败')
  }

  /**
   * 销毁Store，清理资源
   */
  async destroy(): Promise<void> {
    await this.safeExecute(async () => {
      this.log('开始销毁项目Store')

      // 清理状态
      this.projects.splice(0, this.projects.length)
      this.filteredProjects.splice(0, this.filteredProjects.length)
      this.currentProject = null
      this.projectStats = null

      // 重置状态
      this.reset()

      this.log('项目Store销毁完成')
    }, 'destroy', '项目Store销毁失败')
  }

  /**
   * 加载项目列表
   */
  async loadProjects(params?: ProjectQueryParams): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isLoading', true)
      this.clearError()

      this.log('开始加载项目列表', params)

      // 构建查询参数
      const queryParams: ProjectQueryParams = {
        table: params?.table || 'projects',
        columns: params?.columns,
        selection: params?.selection,
        selectionArgs: params?.selectionArgs,
        orderBy: this.getOrderByField(),
        limit: this.pageSize,
        offset: params?.offset,
        status: params?.status,
        manager: params?.manager,
        client: params?.client,
        tags: params?.tags,
        startDateRange: params?.startDateRange,
        dateRange: params?.dateRange,
        nameKeyword: params?.nameKeyword,
        codeKeyword: params?.codeKeyword
      }

      // 查询项目列表
      const projects = await this.projectService.queryProjects(queryParams)

      // 更新状态
      this.projects.splice(0, this.projects.length, ...projects)
      this.applyFiltersAndSort()

      // 更新分页信息
      await this.updatePaginationInfo(params)

      this.setLoadingState('isLoading', false)
      this.managementState.lastSyncTime = new Date()

      this.log('项目列表加载完成', { count: projects.length })

    }, 'loadProjects', '加载项目列表失败')
  }

  /**
   * 分页加载项目列表
   */
  async loadProjectsWithPagination(
    params: ProjectQueryParams = {},
    pagination: PaginationParams = { page: this.currentPage, pageSize: this.pageSize }
  ): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isLoading', true)
      this.clearError()

      this.log('开始分页加载项目', { params, pagination })

      const result = await this.projectService.queryProjectsWithPagination(params, pagination)

      // 更新状态
      if (pagination.page === 1) {
        this.projects.splice(0, this.projects.length, ...result.data)
      } else {
        this.projects.push(...result.data)
      }

      // 更新分页信息
      this.totalProjects = result.total
      this.currentPage = result.page
      this.pageSize = result.pageSize
      this.totalPages = result.totalPages
      this.hasNextPage = result.hasNext
      this.hasPrevPage = result.hasPrev

      this.applyFiltersAndSort()
      this.setLoadingState('isLoading', false)

      this.log('分页加载项目完成', result)

    }, 'loadProjectsWithPagination', '分页加载项目失败')
  }

  /**
   * 创建项目
   */
  async createProject(projectData: Partial<Project>): Promise<Project | null> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isCreating', true)
      this.clearError()

      this.log('开始创建项目', projectData)

      // 创建项目实例
      const project = new Project()
      Object.assign(project, projectData)

      // 验证项目数据
      if (!project.isValid()) {
        throw new Error('项目数据验证失败')
      }

      // 保存到数据库
      const createdProject = await this.projectService.createProject(project)

      // 更新本地状态
      this.projects.unshift(createdProject)
      this.applyFiltersAndSort()

      // 更新统计信息
      await this.loadProjectStats()

      this.setLoadingState('isCreating', false)
      this.log('项目创建成功', createdProject)

      return createdProject

    }, 'createProject', '创建项目失败')
  }

  /**
   * 更新项目
   */
  async updateProject(project: Project): Promise<boolean> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isUpdating', true)
      this.clearError()

      this.log('开始更新项目', { id: project.id, name: project.name })

      // 验证项目数据
      if (!project.isValid()) {
        throw new Error('项目数据验证失败')
      }

      // 更新数据库
      const success = await this.projectService.updateProject(project)

      if (success) {
        // 更新本地状态
        const index = this.projects.findIndex(p => p.id === project.id)
        if (index >= 0) {
          this.projects.splice(index, 1, project)
        }

        // 如果是当前项目，也要更新
        if (this.currentProject?.id === project.id) {
          this.currentProject = project
        }

        this.applyFiltersAndSort()
        await this.loadProjectStats()
      }

      this.setLoadingState('isUpdating', false)
      this.log('项目更新完成', { success, projectId: project.id })

      return success

    }, 'updateProject', '更新项目失败')
  }

  /**
   * 删除项目
   */
  async deleteProject(projectId: string): Promise<boolean> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isDeleting', true)
      this.clearError()

      this.log('开始删除项目', { projectId })

      // 从数据库删除
      const success = await this.projectService.deleteProject(projectId)

      if (success) {
        // 从本地状态移除
        const index = this.projects.findIndex(p => p.id === projectId)
        if (index >= 0) {
          this.projects.splice(index, 1)
        }

        // 如果是当前项目，清空当前项目
        if (this.currentProject?.id === projectId) {
          this.currentProject = null
        }

        this.applyFiltersAndSort()
        await this.loadProjectStats()
      }

      this.setLoadingState('isDeleting', false)
      this.log('项目删除完成', { success, projectId })

      return success

    }, 'deleteProject', '删除项目失败')
  }

  /**
   * 批量删除项目
   */
  async deleteProjects(projectIds: string[]): Promise<number> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isDeleting', true)
      this.clearError()

      this.log('开始批量删除项目', { count: projectIds.length })

      const deletedCount = await this.projectService.deleteProjects(projectIds)

      if (deletedCount > 0) {
        // 从本地状态移除
        this.projects = this.projects.filter(p => !projectIds.includes(p.id))

        // 清空当前项目（如果在删除列表中）
        if (this.currentProject && projectIds.includes(this.currentProject.id)) {
          this.currentProject = null
        }

        this.applyFiltersAndSort()
        await this.loadProjectStats()
      }

      this.setLoadingState('isDeleting', false)
      this.log('批量删除项目完成', { deletedCount })

      return deletedCount

    }, 'deleteProjects', '批量删除项目失败')
  }

  /**
   * 根据ID获取项目
   */
  async getProjectById(projectId: string): Promise<Project | null> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.clearError()

      this.log('查询项目详情', { projectId })

      // 先从本地缓存查找
      let project = this.projects.find(p => p.id === projectId)

      if (!project) {
        // 从数据库查询
        project = await this.projectService.getProjectById(projectId)
        if (project) {
          this.projects.push(project)
          this.applyFiltersAndSort()
        }
      }

      this.currentProject = project
      this.log('项目详情查询完成', { found: !!project })

      return project

    }, 'getProjectById', '查询项目详情失败')
  }

  /**
   * 搜索项目
   */
  async searchProjects(query: string, limit: number = 50): Promise<Project[]> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.clearError()

      this.log('搜索项目', { query, limit })

      const projects = await this.projectService.searchProjects(query, limit)
      this.log('项目搜索完成', { count: projects.length })

      return projects

    }, 'searchProjects', '搜索项目失败')
  }

  /**
   * 加载项目统计信息
   */
  async loadProjectStats(): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.clearError()

      this.log('加载项目统计信息')

      const stats = await this.projectService.getProjectStats()
      this.projectStats = stats

      this.log('项目统计信息加载完成', stats)

    }, 'loadProjectStats', '加载项目统计信息失败')
  }

  /**
   * 设置搜索查询
   */
  setSearchQuery(query: string): void {
    if (this.searchQuery !== query) {
      this.searchQuery = query
      this.applyFiltersAndSort()
      this.log('设置搜索查询', { query })
    }
  }

  /**
   * 设置过滤器
   */
  setFilter(filter: ProjectFilter): void {
    if (this.currentFilter !== filter) {
      this.currentFilter = filter
      this.applyFiltersAndSort()
      this.log('设置过滤器', { filter })
    }
  }

  /**
   * 设置排序方式
   */
  setSortOrder(sortOrder: ProjectSortOrder): void {
    if (this.currentSortOrder !== sortOrder) {
      this.currentSortOrder = sortOrder
      this.applyFiltersAndSort()
      this.log('设置排序方式', { sortOrder })
    }
  }

  /**
   * 设置选中的标签
   */
  setSelectedTags(tags: string[]): void {
    this.selectedTags = [...tags]
    this.applyFiltersAndSort()
    this.log('设置选中标签', { tags })
  }

  /**
   * 添加选中标签
   */
  addSelectedTag(tag: string): void {
    if (!this.selectedTags.includes(tag)) {
      this.selectedTags.push(tag)
      this.applyFiltersAndSort()
      this.log('添加选中标签', { tag })
    }
  }

  /**
   * 移除选中标签
   */
  removeSelectedTag(tag: string): void {
    const index = this.selectedTags.indexOf(tag)
    if (index > -1) {
      this.selectedTags.splice(index, 1)
      this.applyFiltersAndSort()
      this.log('移除选中标签', { tag })
    }
  }

  /**
   * 清空搜索条件
   */
  clearSearchConditions(): void {
    this.searchQuery = ''
    this.currentFilter = ProjectFilter.ALL
    this.currentSortOrder = ProjectSortOrder.UPDATED_DESC
    this.selectedTags.splice(0, this.selectedTags.length)
    this.applyFiltersAndSort()
    this.log('清空搜索条件')
  }

  /**
   * 刷新数据
   */
  async refresh(): Promise<void> {
    await this.safeExecute(async () => {
      this.log('刷新项目数据')
      await this.loadProjects()
      await this.loadProjectStats()
      this.log('项目数据刷新完成')
    }, 'refresh', '刷新项目数据失败')
  }

  /**
   * 应用过滤和排序
   */
  private applyFiltersAndSort(): void {
    let filtered = [...this.projects]

    // 应用搜索查询
    if (this.searchQuery) {
      filtered = filtered.filter(project =>
        project.matchesSearch(this.searchQuery)
      )
    }

    // 应用状态过滤器
    if (this.currentFilter !== ProjectFilter.ALL) {
      filtered = filtered.filter(project =>
        project.status === this.currentFilter
      )
    }

    // 应用标签过滤
    if (this.selectedTags.length > 0) {
      filtered = filtered.filter(project =>
        this.selectedTags.some(tag => project.tags.includes(tag))
      )
    }

    // 应用排序
    filtered.sort(this.getSortComparator())

    // 更新过滤后的项目列表
    this.filteredProjects.splice(0, this.filteredProjects.length, ...filtered)

    this.log('应用过滤和排序', {
      total: this.projects.length,
      filtered: filtered.length,
      query: this.searchQuery,
      filter: this.currentFilter,
      sort: this.currentSortOrder
    })
  }

  /**
   * 获取排序比较器
   */
  private getSortComparator(): (a: Project, b: Project) => number {
    switch (this.currentSortOrder) {
      case ProjectSortOrder.NAME_ASC:
        return (a, b) => a.name.localeCompare(b.name)

      case ProjectSortOrder.NAME_DESC:
        return (a, b) => b.name.localeCompare(a.name)

      case ProjectSortOrder.CREATED_ASC:
        return (a, b) => a.createdAt.getTime() - b.createdAt.getTime()

      case ProjectSortOrder.CREATED_DESC:
        return (a, b) => b.createdAt.getTime() - a.createdAt.getTime()

      case ProjectSortOrder.UPDATED_ASC:
        return (a, b) => a.updatedAt.getTime() - b.updatedAt.getTime()

      case ProjectSortOrder.UPDATED_DESC:
        return (a, b) => b.updatedAt.getTime() - a.updatedAt.getTime()

      default:
        return (a, b) => b.updatedAt.getTime() - a.updatedAt.getTime()
    }
  }

  /**
   * 获取排序字段名
   */
  private getOrderByField(): string {
    switch (this.currentSortOrder) {
      case ProjectSortOrder.NAME_ASC:
      case ProjectSortOrder.NAME_DESC:
        return 'name'
      case ProjectSortOrder.CREATED_ASC:
      case ProjectSortOrder.CREATED_DESC:
        return 'created_at'
      case ProjectSortOrder.UPDATED_ASC:
      case ProjectSortOrder.UPDATED_DESC:
      default:
        return 'updated_at'
    }
  }

  /**
   * 更新分页信息
   */
  private async updatePaginationInfo(params?: ProjectQueryParams): Promise<void> {
    if (params?.limit) {
      this.totalProjects = this.projects.length
      this.totalPages = Math.ceil(this.totalProjects / this.pageSize)
      this.hasNextPage = this.currentPage < this.totalPages
      this.hasPrevPage = this.currentPage > 1
    }
  }

  /**
   * 设置加载状态
   */
  private setLoadingState(key: keyof ProjectManagementState, value: boolean): void {
    if (key === 'isLoading' || key === 'isCreating' || key === 'isUpdating' || key === 'isDeleting') {
      this.managementState[key] = value
    }
  }

  /**
   * 清空错误信息
   */
  private clearError(): void {
    this.managementState.error = null
  }

  /**
   * 设置错误信息
   */
  private setError(message: string): void {
    this.managementState.error = message
    this.logError('setError', message)
  }

  // Getters
  get isLoading(): boolean { return this.managementState.isLoading }
  get isCreating(): boolean { return this.managementState.isCreating }
  get isUpdating(): boolean { return this.managementState.isUpdating }
  get isDeleting(): boolean { return this.managementState.isDeleting }
  get error(): string | null { return this.managementState.error }
  get lastSyncTime(): Date | null { return this.managementState.lastSyncTime }
  get hasProjects(): boolean { return this.projects.length > 0 }
  get hasFilteredProjects(): boolean { return this.filteredProjects.length > 0 }
  get filteredProjectsCount(): number { return this.filteredProjects.length }
  get totalProjectsCount(): number { return this.projects.length }
}

/**
 * 导出单例实例
 */
export const projectStore = new ProjectStore()