/**
 * SiteStore.ets
 * 工点状态管理Store
 * 严格使用V2响应式状态管理，提供工点的CRUD操作和业务逻辑处理
 */

import { BaseStore } from '../BaseStore'
import { Site } from '../../models/Site'
import { SiteService, SiteQueryParams, SiteStats, BoundingBox } from '../../services/database/SiteService'
import { LocationData, PaginationParams, PaginationResult } from '../../types/AppTypes'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'SiteStore'

/**
 * 工点搜索和过滤参数接口
 */
export interface SiteSearchParams {
  query?: string
  projectId?: string
  tags?: string[]
  hasLocation?: boolean
  locationRange?: {
    centerLat: number
    centerLng: number
    radius: number // 半径（米）
  }
  pagination?: PaginationParams
}

/**
 * 附近工点搜索参数接口
 */
export interface NearbySearchParams {
  latitude: number
  longitude: number
  radius?: number // 搜索半径（米）
  limit?: number // 结果数量限制
}

/**
 * 工点管理状态接口
 */
export interface SiteManagementState {
  isLoading: boolean
  error: string | null
  lastSyncTime: Date | null
  isCreating: boolean
  isUpdating: boolean
  isDeleting: boolean
  isSearchingNearby: boolean
}

/**
 * 地理位置管理状态接口
 */
export interface LocationManagementState {
  currentLocation: { latitude: number; longitude: number } | null
  isLocating: boolean
  locationError: string | null
  lastLocationUpdate: Date | null
}

/**
 * 工点Store类
 * 管理工点的状态和业务逻辑
 */
@ObservedV2
export class SiteStore extends BaseStore {
  // 工点列表状态
  @Trace sites: Site[] = []
  @Trace currentSite: Site | null = null
  @Trace filteredSites: Site[] = []

  // 当前项目关联的工点
  @Trace projectSites: Site[] = []
  @Trace currentProjectId: string | null = null

  // 搜索和过滤状态
  @Trace searchQuery: string = ''
  @Trace selectedTags: string[] = []
  @Trace hasLocationFilter: boolean | null = null // null=全部, true=有位置, false=无位置

  // 附近工点
  @Trace nearbySites: Array<{ site: Site; distance: number }> = []

  // 分页状态
  @Trace currentPage: number = 1
  @Trace pageSize: number = 20
  @Trace totalSites: number = 0
  @Trace totalPages: number = 0
  @Trace hasNextPage: boolean = false
  @Trace hasPrevPage: boolean = false

  // 管理状态
  @Trace managementState: SiteManagementState = {
    isLoading: false,
    error: null,
    lastSyncTime: null,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isSearchingNearby: false
  }

  // 地理位置状态
  @Trace locationState: LocationManagementState = {
    currentLocation: null,
    isLocating: false,
    locationError: null,
    lastLocationUpdate: null
  }

  // 统计信息
  @Trace siteStats: SiteStats | null = null

  // 服务实例
  private siteService: SiteService

  constructor() {
    super('SiteStore')
    this.siteService = SiteService.getInstance()
  }

  /**
   * 初始化Store
   */
  async initialize(): Promise<void> {
    await this.safeExecute(async () => {
      this.log('开始初始化工点Store')

      // 尝试获取当前位置
      await this.getCurrentLocation()

      // 加载统计信息
      await this.loadSiteStats()

      this.markInitialized()
      this.log('工点Store初始化完成')

    }, 'initialize', '工点Store初始化失败')
  }

  /**
   * 销毁Store，清理资源
   */
  async destroy(): Promise<void> {
    await this.safeExecute(async () => {
      this.log('开始销毁工点Store')

      // 清理状态
      this.sites.splice(0, this.sites.length)
      this.filteredSites.splice(0, this.filteredSites.length)
      this.projectSites.splice(0, this.projectSites.length)
      this.nearbySites.splice(0, this.nearbySites.length)
      this.currentSite = null
      this.siteStats = null

      // 重置状态
      this.reset()

      this.log('工点Store销毁完成')
    }, 'destroy', '工点Store销毁失败')
  }

  /**
   * 加载工点列表
   */
  async loadSites(params?: SiteQueryParams): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isLoading', true)
      this.clearError()

      this.log('开始加载工点列表', params)

      const sites = await this.siteService.querySites(params)

      // 更新状态
      this.sites.splice(0, this.sites.length, ...sites)
      this.applyFiltersAndSort()

      this.setLoadingState('isLoading', false)
      this.managementState.lastSyncTime = new Date()

      this.log('工点列表加载完成', { count: sites.length })

    }, 'loadSites', '加载工点列表失败')
  }

  /**
   * 分页加载工点列表
   */
  async loadSitesWithPagination(
    params: SiteQueryParams = {},
    pagination: PaginationParams = { page: this.currentPage, pageSize: this.pageSize }
  ): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isLoading', true)
      this.clearError()

      this.log('开始分页加载工点', { params, pagination })

      const result = await this.siteService.querySitesWithPagination(params, pagination)

      // 更新状态
      if (pagination.page === 1) {
        this.sites.splice(0, this.sites.length, ...result.data)
      } else {
        this.sites.push(...result.data)
      }

      // 更新分页信息
      this.totalSites = result.total
      this.currentPage = result.page
      this.pageSize = result.pageSize
      this.totalPages = result.totalPages
      this.hasNextPage = result.hasNext
      this.hasPrevPage = result.hasPrev

      this.applyFiltersAndSort()
      this.setLoadingState('isLoading', false)

      this.log('分页加载工点完成', result)

    }, 'loadSitesWithPagination', '分页加载工点失败')
  }

  /**
   * 加载指定项目的工点列表
   */
  async loadProjectSites(projectId: string): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isLoading', true)
      this.clearError()

      this.log('开始加载项目工点', { projectId })

      const sites = await this.siteService.getSitesByProjectId(projectId)

      // 更新状态
      this.currentProjectId = projectId
      this.projectSites.splice(0, this.projectSites.length, ...sites)

      // 更新全局工点列表（如果需要）
      this.sites.splice(0, this.sites.length, ...sites)
      this.applyFiltersAndSort()

      this.setLoadingState('isLoading', false)

      this.log('项目工点加载完成', { projectId, count: sites.length })

    }, 'loadProjectSites', '加载项目工点失败')
  }

  /**
   * 创建工点
   */
  async createSite(siteData: Partial<Site>): Promise<Site | null> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isCreating', true)
      this.clearError()

      this.log('开始创建工点', siteData)

      // 创建工点实例
      const site = new Site()
      Object.assign(site, siteData)

      // 验证工点数据
      if (!site.isValid()) {
        throw new Error('工点数据验证失败')
      }

      // 保存到数据库
      const createdSite = await this.siteService.createSite(site)

      // 更新本地状态
      this.sites.unshift(createdSite)

      // 如果是当前项目的工点，也要更新项目工点列表
      if (this.currentProjectId === createdSite.projectId) {
        this.projectSites.unshift(createdSite)
      }

      this.applyFiltersAndSort()

      // 更新统计信息
      await this.loadSiteStats()

      this.setLoadingState('isCreating', false)
      this.log('工点创建成功', createdSite)

      return createdSite

    }, 'createSite', '创建工点失败')
  }

  /**
   * 更新工点
   */
  async updateSite(site: Site): Promise<boolean> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isUpdating', true)
      this.clearError()

      this.log('开始更新工点', { id: site.id, name: site.name })

      // 验证工点数据
      if (!site.isValid()) {
        throw new Error('工点数据验证失败')
      }

      // 更新数据库
      const success = await this.siteService.updateSite(site)

      if (success) {
        // 更新本地状态
        this.updateSiteInList(site)
        this.applyFiltersAndSort()
        await this.loadSiteStats()
      }

      this.setLoadingState('isUpdating', false)
      this.log('工点更新完成', { success, siteId: site.id })

      return success

    }, 'updateSite', '更新工点失败')
  }

  /**
   * 删除工点
   */
  async deleteSite(siteId: string): Promise<boolean> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isDeleting', true)
      this.clearError()

      this.log('开始删除工点', { siteId })

      // 从数据库删除
      const success = await this.siteService.deleteSite(siteId)

      if (success) {
        // 从本地状态移除
        this.removeSiteFromList(siteId)
        this.applyFiltersAndSort()
        await this.loadSiteStats()
      }

      this.setLoadingState('isDeleting', false)
      this.log('工点删除完成', { success, siteId })

      return success

    }, 'deleteSite', '删除工点失败')
  }

  /**
   * 批量删除工点
   */
  async deleteSites(siteIds: string[]): Promise<number> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isDeleting', true)
      this.clearError()

      this.log('开始批量删除工点', { count: siteIds.length })

      const deletedCount = await this.siteService.deleteSites(siteIds)

      if (deletedCount > 0) {
        // 从本地状态移除
        siteIds.forEach(siteId => this.removeSiteFromList(siteId))
        this.applyFiltersAndSort()
        await this.loadSiteStats()
      }

      this.setLoadingState('isDeleting', false)
      this.log('批量删除工��完成', { deletedCount })

      return deletedCount

    }, 'deleteSites', '批量删除工点失败')
  }

  /**
   * 根据ID获取工点
   */
  async getSiteById(siteId: string): Promise<Site | null> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.clearError()

      this.log('查询工点详情', { siteId })

      // 先从本地缓存查找
      let site = this.sites.find(s => s.id === siteId)

      if (!site) {
        // 从数据库查询
        site = await this.siteService.getSiteById(siteId)
        if (site) {
          this.sites.push(site)
          this.applyFiltersAndSort()
        }
      }

      this.currentSite = site
      this.log('工点详情查询完成', { found: !!site })

      return site

    }, 'getSiteById', '查询工点详情失败')
  }

  /**
   * 搜索工点
   */
  async searchSites(query: string, projectId?: string, limit: number = 50): Promise<Site[]> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.clearError()

      this.log('搜索工点', { query, projectId, limit })

      const sites = await this.siteService.searchSites(query, projectId, limit)
      this.log('工点搜索完成', { count: sites.length })

      return sites

    }, 'searchSites', '搜索工点失败')
  }

  /**
   * 查找附近工点
   */
  async findNearbySites(params: NearbySearchParams): Promise<Array<{ site: Site; distance: number }>> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isSearchingNearby', true)
      this.clearError()

      this.log('查找附近工点', params)

      const nearbySites = await this.siteService.findNearbySites(
        params.latitude,
        params.longitude,
        params.radius || 1000,
        params.limit || 20
      )

      this.nearbySites.splice(0, this.nearbySites.length, ...nearbySites)
      this.setLoadingState('isSearchingNearby', false)

      this.log('附近工点查找完成', { count: nearbySites.length })
      return nearbySites

    }, 'findNearbySites', '查找附近工点失败')
  }

  /**
   * 更新工点位置信息
   */
  async updateSiteLocation(
    siteId: string,
    latitude: number,
    longitude: number,
    altitude?: number,
    address?: string,
    locationData?: LocationData
  ): Promise<boolean> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.setLoadingState('isUpdating', true)
      this.clearError()

      this.log('更新工点位置', { siteId, latitude, longitude })

      const success = await this.siteService.updateSiteLocation(
        siteId, latitude, longitude, altitude, address, locationData
      )

      if (success) {
        // 更新本地状态
        const site = await this.getSiteById(siteId)
        if (site) {
          this.updateSiteInList(site)
          this.applyFiltersAndSort()
        }
      }

      this.setLoadingState('isUpdating', false)
      this.log('工点位置更新完成', { success, siteId })

      return success

    }, 'updateSiteLocation', '更新工点位置失败')
  }

  /**
   * 获取当前位置
   */
  async getCurrentLocation(): Promise<{ latitude: number; longitude: number } | null> {
    return await this.safeExecute(async () => {
      this.checkInitialized()
      this.locationState.isLocating = true
      this.locationState.locationError = null

      this.log('开始获取当前位置')

      try {
        // 这里应该使用系统定位服务
        // 为了示例，使用模拟位置
        const mockLocation = { latitude: 39.9042, longitude: 116.4074 } // 北京坐标

        this.locationState.currentLocation = mockLocation
        this.locationState.lastLocationUpdate = new Date()
        this.locationState.isLocating = false

        this.log('当前位置获取成功', mockLocation)
        return mockLocation

      } catch (error) {
        this.locationState.locationError = '获取位置失败'
        this.locationState.isLocating = false
        this.logError('getCurrentLocation', error)
        return null
      }

    }, 'getCurrentLocation', '获取当前位置失败')
  }

  /**
   * 加载工点统计信息
   */
  async loadSiteStats(projectId?: string): Promise<void> {
    await this.safeExecute(async () => {
      this.checkInitialized()
      this.clearError()

      this.log('加载工点统计信息', { projectId })

      const stats = await this.siteService.getSiteStats(projectId)
      this.siteStats = stats

      this.log('工点统计信息加载完成', stats)

    }, 'loadSiteStats', '加载工点统计信息失败')
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
   * 设置位置过滤器
   */
  setLocationFilter(hasLocation: boolean | null): void {
    if (this.hasLocationFilter !== hasLocation) {
      this.hasLocationFilter = hasLocation
      this.applyFiltersAndSort()
      this.log('设置位置过滤器', { hasLocation })
    }
  }

  /**
   * 设置选中的标签
   */
  setSelectedTags(tags: string[]): void {
    this.selectedTags = [...tags]
    this.applyFiltersAndSort()
    this.log('��置选中标签', { tags })
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
    this.selectedTags.splice(0, this.selectedTags.length)
    this.hasLocationFilter = null
    this.applyFiltersAndSort()
    this.log('清空搜索条件')
  }

  /**
   * 设置当前项目
   */
  setCurrentProject(projectId: string | null): void {
    if (this.currentProjectId !== projectId) {
      this.currentProjectId = projectId
      if (projectId) {
        this.loadProjectSites(projectId)
      } else {
        this.projectSites.splice(0, this.projectSites.length)
      }
      this.log('设置当前项目', { projectId })
    }
  }

  /**
   * 刷新数据
   */
  async refresh(): Promise<void> {
    await this.safeExecute(async () => {
      this.log('刷新工点数据')

      if (this.currentProjectId) {
        await this.loadProjectSites(this.currentProjectId)
      } else {
        await this.loadSites()
      }

      await this.loadSiteStats()
      this.log('工点数据刷新完成')
    }, 'refresh', '刷新工点数据失败')
  }

  /**
   * 应用过滤和排序
   */
  private applyFiltersAndSort(): void {
    const sourceList = this.currentProjectId ? this.projectSites : this.sites
    let filtered = [...sourceList]

    // 应用搜索查询
    if (this.searchQuery) {
      filtered = filtered.filter(site =>
        site.matchesSearch(this.searchQuery)
      )
    }

    // 应用位置过滤
    if (this.hasLocationFilter !== null) {
      filtered = filtered.filter(site =>
        this.hasLocationFilter ? site.hasValidLocation() : !site.hasValidLocation()
      )
    }

    // 应用标签过滤
    if (this.selectedTags.length > 0) {
      filtered = filtered.filter(site =>
        this.selectedTags.some(tag => site.tags.includes(tag))
      )
    }

    // 按更新时间排序（最新的在前）
    filtered.sort((a, b) => b.updatedAt.getTime() - a.updatedAt.getTime())

    // 更新过滤后的工点列表
    this.filteredSites.splice(0, this.filteredSites.length, ...filtered)

    this.log('应用过滤和排序', {
      total: sourceList.length,
      filtered: filtered.length,
      query: this.searchQuery,
      hasLocation: this.hasLocationFilter,
      tags: this.selectedTags
    })
  }

  /**
   * 更新工点在列表中的信息
   */
  private updateSiteInList(updatedSite: Site): void {
    // 更新全局工点列表
    const index = this.sites.findIndex(s => s.id === updatedSite.id)
    if (index >= 0) {
      this.sites.splice(index, 1, updatedSite)
    }

    // 更新项目工点列表
    const projectIndex = this.projectSites.findIndex(s => s.id === updatedSite.id)
    if (projectIndex >= 0) {
      this.projectSites.splice(projectIndex, 1, updatedSite)
    }

    // 更新当前工点
    if (this.currentSite?.id === updatedSite.id) {
      this.currentSite = updatedSite
    }
  }

  /**
   * 从列表中移除工点
   */
  private removeSiteFromList(siteId: string): void {
    // 从全局工点列表移除
    const index = this.sites.findIndex(s => s.id === siteId)
    if (index >= 0) {
      this.sites.splice(index, 1)
    }

    // 从项目工点列表移除
    const projectIndex = this.projectSites.findIndex(s => s.id === siteId)
    if (projectIndex >= 0) {
      this.projectSites.splice(projectIndex, 1)
    }

    // 清空当前工点
    if (this.currentSite?.id === siteId) {
      this.currentSite = null
    }
  }

  /**
   * 设置加载状态
   */
  private setLoadingState(key: keyof SiteManagementState, value: boolean): void {
    this.managementState[key] = value
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
  get isSearchingNearby(): boolean { return this.managementState.isSearchingNearby }
  get error(): string | null { return this.managementState.error }
  get lastSyncTime(): Date | null { return this.managementState.lastSyncTime }
  get hasSites(): boolean { return this.sites.length > 0 }
  get hasFilteredSites(): boolean { return this.filteredSites.length > 0 }
  get filteredSitesCount(): number { return this.filteredSites.length }
  get totalSitesCount(): number { return this.sites.length }
  get hasProjectSites(): boolean { return this.projectSites.length > 0 }
  get projectSitesCount(): number { return this.projectSites.length }
  get currentLocation(): { latitude: number; longitude: number } | null {
    return this.locationState.currentLocation
  }
  get isLocating(): boolean { return this.locationState.isLocating }
  get locationError(): string | null { return this.locationState.locationError }
}

/**
 * 导出单例实例
 */
export const siteStore = new SiteStore()