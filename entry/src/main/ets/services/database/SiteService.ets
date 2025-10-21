/**
 * 工点数据服务
 * 提供工点的CRUD操作和业务逻辑处理
 */

import { hilog } from '@ohos.log'
import {
  databaseService,
  DatabaseError,
  QueryParams,
  PaginationParams,
  PaginationResult
} from './DatabaseService'
import { Site } from '../../models/Site'
import { LocationData } from '../../types/AppTypes'
import {
  TABLE_NAMES,
  SITE_FIELDS,
  PROJECT_FIELDS,
  DATA_TYPES,
  DEFAULT_VALUES,
  ERROR_CODES,
  PAGINATION,
  SORT_DIRECTIONS
} from '../../constants/DatabaseConstants'

/**
 * 工点查询条件接口
 */
export interface SiteQueryParams extends QueryParams {
  projectId?: string
  tags?: string[]
  locationRange?: {
    centerLat: number
    centerLng: number
    radius: number // 半径（米）
  }
  nameKeyword?: string
  addressKeyword?: string
  hasLocation?: boolean
}

/**
 * 工点统计信息
 */
export interface SiteStats {
  totalSites: number
  sitesByProject: Record<string, number>
  sitesWithLocation: number
  totalPhotos: number
  averagePhotosPerSite: number
  recentSites: Site[]
}

/**
 * 地理边界框
 */
export interface BoundingBox {
  minLat: number
  maxLat: number
  minLng: number
  maxLng: number
}

/**
 * 工点服务类
 * 提供工点的数据访问和业务逻辑处理
 */
export class SiteService {
  private static instance: SiteService | null = null
  private readonly TAG = 'SiteService'

  /**
   * 获取单例实例
   */
  static getInstance(): SiteService {
    if (!SiteService.instance) {
      SiteService.instance = new SiteService()
    }
    return SiteService.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 创建新工点
   * @param site 工点数据
   * @returns 创建成功的工点（包含ID）
   */
  async createSite(site: Site): Promise<Site> {
    try {
      hilog.info(0x0000, this.TAG, `创建工点: ${site.name}`)

      // 验证工点数据
      if (!site.isValid()) {
        throw new DatabaseError('工点数据验证失败', ERROR_CODES.CONSTRAINT_VIOLATION)
      }

      // 验证项目是否存在
      const projectExists = await this.validateProjectExists(site.projectId)
      if (!projectExists) {
        throw new DatabaseError(`项目不存在: ${site.projectId}`, ERROR_CODES.FOREIGN_KEY_VIOLATION)
      }

      // 生成ID和时间戳
      if (!site.id) {
        site.id = Site.generateId()
      }
      const now = Date.now()
      site.createdAt = new Date(now)
      site.updatedAt = new Date(now)

      // 转换为数据库格式
      const dbData = this.siteToDbData(site)

      // 插入数据库
      await databaseService.executeSql(`
        INSERT INTO ${TABLE_NAMES.SITES} (
          ${SITE_FIELDS.SITE_ID},
          ${SITE_FIELDS.PROJECT_ID},
          ${SITE_FIELDS.NAME},
          ${SITE_FIELDS.ADDRESS},
          ${SITE_FIELDS.LATITUDE},
          ${SITE_FIELDS.LONGITUDE},
          ${SITE_FIELDS.ALTITUDE},
          ${SITE_FIELDS.DESCRIPTION},
          ${SITE_FIELDS.TAGS},
          ${SITE_FIELDS.LOCATION_DATA},
          ${SITE_FIELDS.PHOTO_COUNT},
          created_at,
          updated_at,
          version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        dbData.site_id,
        dbData.project_id,
        dbData.name,
        dbData.address,
        dbData.latitude,
        dbData.longitude,
        dbData.altitude,
        dbData.description,
        dbData.tags,
        dbData.location_data,
        dbData.photo_count,
        dbData.created_at,
        dbData.updated_at,
        dbData.version
      ])

      // 更新项目工点数量
      await this.updateProjectSiteCount(site.projectId, 1)

      hilog.info(0x0000, this.TAG, `工点创建成功: ${site.id}`)
      return site

    } catch (error) {
      hilog.error(0x0000, this.TAG, `创建工点失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `创建工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 根据ID获取工点
   * @param siteId 工点ID
   * @returns 工点数据
   */
  async getSiteById(siteId: string): Promise<Site | null> {
    try {
      hilog.debug(0x0000, this.TAG, `查询工点: ${siteId}`)

      const resultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.SITES}
        WHERE ${SITE_FIELDS.SITE_ID} = ?
        LIMIT 1
      `, [siteId])

      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return null
      }

      const site = this.dbDataToSite(resultSet)
      resultSet.close()

      hilog.debug(0x0000, this.TAG, `工点查询成功: ${site.name}`)
      return site

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询工点失败: ${siteId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新工点信息
   * @param site 工点数据
   * @returns 更新是否成功
   */
  async updateSite(site: Site): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, `更新工点: ${site.id}`)

      // 验证工点数据
      if (!site.isValid()) {
        throw new DatabaseError('工点数据验证失败', ERROR_CODES.CONSTRAINT_VIOLATION)
      }

      // 更新时间戳
      site.updatedAt = new Date()
      site.version++

      // 转换为数据库格式
      const dbData = this.siteToDbData(site)

      // 更新数据库
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.SITES} SET
          ${SITE_FIELDS.PROJECT_ID} = ?,
          ${SITE_FIELDS.NAME} = ?,
          ${SITE_FIELDS.ADDRESS} = ?,
          ${SITE_FIELDS.LATITUDE} = ?,
          ${SITE_FIELDS.LONGITUDE} = ?,
          ${SITE_FIELDS.ALTITUDE} = ?,
          ${SITE_FIELDS.DESCRIPTION} = ?,
          ${SITE_FIELDS.TAGS} = ?,
          ${SITE_FIELDS.LOCATION_DATA} = ?,
          ${SITE_FIELDS.PHOTO_COUNT} = ?,
          updated_at = ?,
          version = ?
        WHERE ${SITE_FIELDS.SITE_ID} = ?
      `, [
        dbData.project_id,
        dbData.name,
        dbData.address,
        dbData.latitude,
        dbData.longitude,
        dbData.altitude,
        dbData.description,
        dbData.tags,
        dbData.location_data,
        dbData.photo_count,
        dbData.updated_at,
        dbData.version,
        site.id
      ])

      const success = result > 0
      if (success) {
        hilog.info(0x0000, this.TAG, `工点更新成功: ${site.id}`)
      } else {
        hilog.warn(0x0000, this.TAG, `工点更新失败，可能不存在: ${site.id}`)
      }

      return success

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新工点失败: ${site.id}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `更新工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 删除工点
   * @param siteId 工点ID
   * @returns 删除是否成功
   */
  async deleteSite(siteId: string): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, `删除工点: ${siteId}`)

      // 获取工点信息（用于更新项目统计）
      const site = await this.getSiteById(siteId)
      let projectId: string | null = null

      if (site) {
        projectId = site.projectId
      }

      // 删除工点
      const result = await databaseService.executeSql(`
        DELETE FROM ${TABLE_NAMES.SITES}
        WHERE ${SITE_FIELDS.SITE_ID} = ?
      `, [siteId])

      const success = result > 0
      if (success && projectId) {
        // 更新项目工点数量
        await this.updateProjectSiteCount(projectId, -1)
        hilog.info(0x0000, this.TAG, `工点删除成功: ${siteId}`)
      } else if (!success) {
        hilog.warn(0x0000, this.TAG, `工点删除失败，可能不存在: ${siteId}`)
      }

      return success

    } catch (error) {
      hilog.error(0x0000, this.TAG, `删除工点失败: ${siteId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `删除工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 批量删除工点
   * @param siteIds 工点ID列表
   * @returns 删除成功的工点数量
   */
  async deleteSites(siteIds: string[]): Promise<number> {
    if (siteIds.length === 0) {
      return 0
    }

    try {
      hilog.info(0x0000, this.TAG, `批量删除工点: ${siteIds.length}个`)

      // 获取所有工点信息（用于更新项目统计）
      const sites: Site[] = []
      for (const siteId of siteIds) {
        const site = await this.getSiteById(siteId)
        if (site) {
          sites.push(site)
        }
      }

      // 删除工点
      const placeholders = siteIds.map(() => '?').join(',')
      const result = await databaseService.executeSql(`
        DELETE FROM ${TABLE_NAMES.SITES}
        WHERE ${SITE_FIELDS.SITE_ID} IN (${placeholders})
      `, siteIds)

      // 更新项目工点数量
      const projectCountMap: Record<string, number> = {}
      sites.forEach(site => {
        projectCountMap[site.projectId] = (projectCountMap[site.projectId] || 0) + 1
      })

      for (const [projectId, count] of Object.entries(projectCountMap)) {
        await this.updateProjectSiteCount(projectId, -count)
      }

      hilog.info(0x0000, this.TAG, `批量删除工点成功: ${result}个`)
      return result

    } catch (error) {
      hilog.error(0x0000, this.TAG, `批量删除工点失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `批量删除工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 查询工点列表
   * @param params 查询参数
   * @returns 工点列表
   */
  async querySites(params: SiteQueryParams = {}): Promise<Site[]> {
    try {
      hilog.debug(0x0000, this.TAG, `查询工点列表`)

      let sql = `
        SELECT * FROM ${TABLE_NAMES.SITES}
        WHERE 1=1
      `
      const args: any[] = []

      // 构建查询条件
      if (params.projectId) {
        sql += ` AND ${SITE_FIELDS.PROJECT_ID} = ?`
        args.push(params.projectId)
      }

      if (params.nameKeyword) {
        sql += ` AND ${SITE_FIELDS.NAME} LIKE ?`
        args.push(`%${params.nameKeyword}%`)
      }

      if (params.addressKeyword) {
        sql += ` AND ${SITE_FIELDS.ADDRESS} LIKE ?`
        args.push(`%${params.addressKeyword}%`)
      }

      if (params.tags && params.tags.length > 0) {
        const tagConditions = params.tags.map(() => `${SITE_FIELDS.TAGS} LIKE ?`).join(' OR ')
        sql += ` AND (${tagConditions})`
        params.tags.forEach(tag => args.push(`%"${tag}"%`))
      }

      if (params.hasLocation !== undefined) {
        if (params.hasLocation) {
          sql += ` AND (${SITE_FIELDS.LATITUDE} != 0 AND ${SITE_FIELDS.LONGITUDE} != 0)`
        } else {
          sql += ` AND (${SITE_FIELDS.LATITUDE} = 0 OR ${SITE_FIELDS.LONGITUDE} = 0)`
        }
      }

      if (params.locationRange) {
        // 使用边界框查询（简化版本，精确圆形查询需要复杂计算）
        const { centerLat, centerLng, radius } = params.locationRange
        const deltaLat = radius / 111000 // 大约1度=111km
        const deltaLng = radius / (111000 * Math.cos(centerLat * Math.PI / 180))

        sql += ` AND ${SITE_FIELDS.LATITUDE} BETWEEN ? AND ?`
        sql += ` AND ${SITE_FIELDS.LONGITUDE} BETWEEN ? AND ?`
        args.push(centerLat - deltaLat, centerLat + deltaLat, centerLng - deltaLng, centerLng + deltaLng)
      }

      // 添加排序
      if (params.orderBy) {
        sql += ` ORDER BY ${params.orderBy}`
      } else {
        sql += ` ORDER BY updated_at DESC`
      }

      // 添加限制
      if (params.limit) {
        sql += ` LIMIT ?`
        args.push(params.limit)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const sites: Site[] = []

      while (resultSet.goToNextRow()) {
        sites.push(this.dbDataToSite(resultSet))
      }

      resultSet.close()

      hilog.debug(0x0000, this.TAG, `工点查询完成: ${sites.length}个`)
      return sites

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询工点列表失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询工点列表失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 分页查询工点列表
   * @param params 查询参数
   * @param pagination 分页参数
   * @returns 分页查询结果
   */
  async querySitesWithPagination(
    params: SiteQueryParams = {},
    pagination: PaginationParams = { page: 1, pageSize: PAGINATION.DEFAULT_PAGE_SIZE }
  ): Promise<PaginationResult<Site>> {
    try {
      hilog.debug(0x0000, this.TAG, `分页查询工点: page=${pagination.page}, size=${pagination.pageSize}`)

      // 限制最大页面大小
      const pageSize = Math.min(pagination.pageSize, PAGINATION.MAX_PAGE_SIZE)
      const offset = (pagination.page - 1) * pageSize

      // 查询总数
      const countSql = this.buildCountQuery(params)
      const countResultSet = await databaseService.executeQuery(countSql.sql, countSql.args)
      const total = countResultSet.getLong(0)
      countResultSet.close()

      // 查询数据
      const dataParams = { ...params, limit: pageSize, offset }
      const sites = await this.querySites(dataParams)

      const totalPages = Math.ceil(total / pageSize)

      hilog.debug(0x0000, this.TAG, `分页查询完成: ${sites.length}/${total}条`)

      return {
        data: sites,
        total,
        page: pagination.page,
        pageSize,
        totalPages
      }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `分页查询工点失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `分页查询工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 根据项目ID查询工点列表
   * @param projectId 项目ID
   * @param orderBy 排序字段
   * @returns 工点列表
   */
  async getSitesByProjectId(projectId: string, orderBy?: string): Promise<Site[]> {
    return this.querySites({
      projectId,
      orderBy: orderBy || `${SITE_FIELDS.NAME} ASC`
    })
  }

  /**
   * 搜索工点
   * @param keyword 搜索关键词
   * @param projectId 项目ID（可选，限制在特定项目中搜索）
   * @param limit 结果数量限制
   * @returns 匹配的工点列表
   */
  async searchSites(keyword: string, projectId?: string, limit: number = 50): Promise<Site[]> {
    try {
      hilog.debug(0x0000, this.TAG, `搜索工点: ${keyword}`)

      if (!keyword.trim()) {
        return []
      }

      let sql = `
        SELECT * FROM ${TABLE_NAMES.SITES}
        WHERE (${SITE_FIELDS.NAME} LIKE ?
           OR ${SITE_FIELDS.ADDRESS} LIKE ?
           OR ${SITE_FIELDS.DESCRIPTION} LIKE ?
           OR ${SITE_FIELDS.TAGS} LIKE ?)
      `
      const args: any[] = [
        `%${keyword}%`, `%${keyword}%`, `%${keyword}%`, `%${keyword}%`
      ]

      if (projectId) {
        sql += ` AND ${SITE_FIELDS.PROJECT_ID} = ?`
        args.push(projectId)
      }

      sql += `
        ORDER BY
          CASE
            WHEN ${SITE_FIELDS.NAME} LIKE ? THEN 1
            WHEN ${SITE_FIELDS.ADDRESS} LIKE ? THEN 2
            ELSE 3
          END,
          updated_at DESC
        LIMIT ?
      `

      const exactPattern = `${keyword}%`
      args.push(exactPattern, exactPattern, limit)

      const resultSet = await databaseService.executeQuery(sql, args)
      const sites: Site[] = []

      while (resultSet.goToNextRow()) {
        sites.push(this.dbDataToSite(resultSet))
      }

      resultSet.close()

      hilog.debug(0x0000, this.TAG, `工点搜索完成: ${sites.length}个`)
      return sites

    } catch (error) {
      hilog.error(0x0000, this.TAG, `搜索工点失败: ${keyword}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `搜索工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 查询指定位置附近的工点
   * @param latitude 纬度
   * @param longitude 经度
   * @param radius 搜索半径（米）
   * @param limit 结果数量限制
   * @returns 附近的工点列表，按距离排序
   */
  async findNearbySites(
    latitude: number,
    longitude: number,
    radius: number = 1000,
    limit: number = 20
  ): Promise<Array<{ site: Site; distance: number }>> {
    try {
      hilog.debug(0x0000, this.TAG, `查找附近工点: (${latitude}, ${longitude}), 半径: ${radius}米`)

      // 使用边界框初步筛选
      const deltaLat = radius / 111000
      const deltaLng = radius / (111000 * Math.cos(latitude * Math.PI / 180))

      const sql = `
        SELECT *,
          (${SITE_FIELDS.LATITUDE} - ?) * (${SITE_FIELDS.LATITUDE} - ?) +
          (${SITE_FIELDS.LONGITUDE} - ?) * (${SITE_FIELDS.LONGITUDE} - ?) as distance_sq
        FROM ${TABLE_NAMES.SITES}
        WHERE ${SITE_FIELDS.LATITUDE} BETWEEN ? AND ?
          AND ${SITE_FIELDS.LONGITUDE} BETWEEN ? AND ?
          AND ${SITE_FIELDS.LATITUDE} != 0
          AND ${SITE_FIELDS.LONGITUDE} != 0
        ORDER BY distance_sq ASC
        LIMIT ?
      `

      const resultSet = await databaseService.executeQuery(sql, [
        latitude, latitude, longitude, longitude,
        latitude - deltaLat, latitude + deltaLat,
        longitude - deltaLng, longitude + deltaLng,
        limit * 2 // 获取更多候选，用于精确距离计算
      ])

      const results: Array<{ site: Site; distance: number }> = []

      while (resultSet.goToNextRow()) {
        const site = this.dbDataToSite(resultSet)

        // 计算精确距离
        const distance = this.calculateDistance(
          latitude, longitude,
          site.latitude, site.longitude
        )

        if (distance <= radius) {
          results.push({ site, distance })
        }
      }

      resultSet.close()

      // 按距离排序并限制结果数量
      results.sort((a, b) => a.distance - b.distance)
      return results.slice(0, limit)

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查找附近工点失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查找附近工点失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 获取工点统计信息
   * @param projectId 项目ID（可选，限制统计特定项目）
   * @returns 工点统计信息
   */
  async getSiteStats(projectId?: string): Promise<SiteStats> {
    try {
      hilog.debug(0x0000, this.TAG, `获取工点统计信息`)

      let sql = `
        SELECT
          COUNT(*) as total_sites,
          COUNT(CASE WHEN ${SITE_FIELDS.LATITUDE} != 0 AND ${SITE_FIELDS.LONGITUDE} != 0 THEN 1 END) as sites_with_location,
          COALESCE(SUM(${SITE_FIELDS.PHOTO_COUNT}), 0) as total_photos,
          COALESCE(AVG(${SITE_FIELDS.PHOTO_COUNT}), 0) as avg_photos
        FROM ${TABLE_NAMES.SITES}
      `
      const args: any[] = []

      if (projectId) {
        sql += ` WHERE ${SITE_FIELDS.PROJECT_ID} = ?`
        args.push(projectId)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const stats = {
        totalSites: resultSet.getLong(0),
        sitesWithLocation: resultSet.getLong(1),
        totalPhotos: resultSet.getLong(2),
        averagePhotosPerSite: Math.round(resultSet.getDouble(3) * 100) / 100
      }
      resultSet.close()

      // 统计各项目工点数量
      const projectStatsSql = projectId
        ? `SELECT '${projectId}' as project_id, COUNT(*) as count FROM ${TABLE_NAMES.SITES} WHERE ${SITE_FIELDS.PROJECT_ID} = ?`
        : `SELECT ${SITE_FIELDS.PROJECT_ID} as project_id, COUNT(*) as count FROM ${TABLE_NAMES.SITES} GROUP BY ${SITE_FIELDS.PROJECT_ID}`

      const projectResultSet = await databaseService.executeQuery(
        projectStatsSql,
        projectId ? [projectId] : []
      )

      const sitesByProject: Record<string, number> = {}
      while (projectResultSet.goToNextRow()) {
        const pid = projectResultSet.getString(0)
        const count = projectResultSet.getLong(1)
        sitesByProject[pid] = count
      }
      projectResultSet.close()

      // 获取最近的工点
      const recentResultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.SITES}
        ${projectId ? `WHERE ${SITE_FIELDS.PROJECT_ID} = ?` : ''}
        ORDER BY updated_at DESC
        LIMIT 5
      `, projectId ? [projectId] : [])

      const recentSites: Site[] = []
      while (recentResultSet.goToNextRow()) {
        recentSites.push(this.dbDataToSite(recentResultSet))
      }
      recentResultSet.close()

      hilog.debug(0x0000, this.TAG, `工点统计完成: ${stats.totalSites}个工点`)

      return {
        ...stats,
        sitesByProject,
        recentSites
      }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `获取工点统计失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `获取工点统计失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新��点照片数量
   * @param siteId 工点ID
   * @param increment 增量（正数增加，负数减少）
   */
  async updateSitePhotoCount(siteId: string, increment: number): Promise<boolean> {
    try {
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.SITES}
        SET ${SITE_FIELDS.PHOTO_COUNT} = ${SITE_FIELDS.PHOTO_COUNT} + ?,
            updated_at = ?
        WHERE ${SITE_FIELDS.SITE_ID} = ?
      `, [increment, Date.now(), siteId])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新工点照片数量失败: ${siteId}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 批量更新工点位置信息
   * @param siteId 工点ID
   * @param latitude 纬度
   * @param longitude 经度
   * @param altitude 海拔高度（可选）
   * @param address 地址（可选）
   * @param locationData 详细位置数据（可选）
   */
  async updateSiteLocation(
    siteId: string,
    latitude: number,
    longitude: number,
    altitude?: number,
    address?: string,
    locationData?: LocationData
  ): Promise<boolean> {
    try {
      const site = await this.getSiteById(siteId)
      if (!site) {
        return false
      }

      site.updateLocation(latitude, longitude, altitude)
      if (address) {
        site.address = address
      }
      if (locationData) {
        site.setLocationData(locationData)
      }

      return await this.updateSite(site)

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新工点位置失败: ${siteId}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 验证项目是否存在
   * @param projectId 项目ID
   * @returns 是否存在
   */
  private async validateProjectExists(projectId: string): Promise<boolean> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [projectId])

      const count = resultSet.getLong(0)
      resultSet.close()
      return count > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `验证项目存在性失败: ${projectId}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 更新项目工点数量
   * @param projectId 项目ID
   * @param increment 增量
   */
  private async updateProjectSiteCount(projectId: string, increment: number): Promise<void> {
    try {
      await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.PROJECTS}
        SET ${PROJECT_FIELDS.SITE_COUNT} = ${PROJECT_FIELDS.SITE_COUNT} + ?,
            updated_at = ?
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [increment, Date.now(), projectId])
    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新项目工点数量失败: ${projectId}, 错误: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 构建计数查询SQL
   * @param params 查询参数
   * @returns SQL语句和参数
   */
  private buildCountQuery(params: SiteQueryParams): { sql: string; args: any[] } {
    let sql = `SELECT COUNT(*) as count FROM ${TABLE_NAMES.SITES} WHERE 1=1`
    const args: any[] = []

    if (params.projectId) {
      sql += ` AND ${SITE_FIELDS.PROJECT_ID} = ?`
      args.push(params.projectId)
    }

    if (params.nameKeyword) {
      sql += ` AND ${SITE_FIELDS.NAME} LIKE ?`
      args.push(`%${params.nameKeyword}%`)
    }

    if (params.addressKeyword) {
      sql += ` AND ${SITE_FIELDS.ADDRESS} LIKE ?`
      args.push(`%${params.addressKeyword}%`)
    }

    if (params.tags && params.tags.length > 0) {
      const tagConditions = params.tags.map(() => `${SITE_FIELDS.TAGS} LIKE ?`).join(' OR ')
      sql += ` AND (${tagConditions})`
      params.tags.forEach(tag => args.push(`%"${tag}"%`))
    }

    if (params.hasLocation !== undefined) {
      if (params.hasLocation) {
        sql += ` AND (${SITE_FIELDS.LATITUDE} != 0 AND ${SITE_FIELDS.LONGITUDE} != 0)`
      } else {
        sql += ` AND (${SITE_FIELDS.LATITUDE} = 0 OR ${SITE_FIELDS.LONGITUDE} = 0)`
      }
    }

    return { sql, args }
  }

  /**
   * 计算两点间距离（使用Haversine公式）
   * @param lat1 点1纬度
   * @param lng1 点1经度
   * @param lat2 点2纬度
   * @param lng2 点2经度
   * @returns 距离（米）
   */
  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371e3 // 地球半径（米）
    const φ1 = lat1 * Math.PI / 180
    const φ2 = lat2 * Math.PI / 180
    const Δφ = (lat2 - lat1) * Math.PI / 180
    const Δλ = (lng2 - lng1) * Math.PI / 180

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    return R * c
  }

  /**
   * 将Site对象转换为数据库数据格式
   * @param site 工点对象
   * @returns 数据库数据格式
   */
  private siteToDbData(site: Site): Record<string, any> {
    return {
      site_id: site.id,
      project_id: site.projectId,
      name: site.name,
      address: site.address,
      latitude: site.latitude,
      longitude: site.longitude,
      altitude: site.altitude,
      description: site.description,
      tags: JSON.stringify(site.tags),
      location_data: site.locationData ? JSON.stringify(site.locationData) : null,
      photo_count: site.photoCount,
      created_at: site.createdAt.getTime(),
      updated_at: site.updatedAt.getTime(),
      version: site.version
    }
  }

  /**
   * 将数据库数据转换为Site对象
   * @param resultSet 数据库查询结果集
   * @returns Site对象
   */
  private dbDataToSite(resultSet: any): Site {
    const site = new Site()

    site.id = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.SITE_ID))
    site.projectId = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.PROJECT_ID))
    site.name = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.NAME))
    site.address = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.ADDRESS))
    site.latitude = resultSet.getDouble(resultSet.getColumnIndex(SITE_FIELDS.LATITUDE))
    site.longitude = resultSet.getDouble(resultSet.getColumnIndex(SITE_FIELDS.LONGITUDE))
    site.altitude = resultSet.getDouble(resultSet.getColumnIndex(SITE_FIELDS.ALTITUDE))
    site.description = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.DESCRIPTION))

    // 解析JSON字段
    try {
      const tagsJson = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.TAGS))
      site.tags = tagsJson ? JSON.parse(tagsJson) : []
    } catch (e) {
      site.tags = []
    }

    try {
      const locationDataJson = resultSet.getString(resultSet.getColumnIndex(SITE_FIELDS.LOCATION_DATA))
      site.locationData = locationDataJson ? JSON.parse(locationDataJson) : null
    } catch (e) {
      site.locationData = null
    }

    site.photoCount = resultSet.getLong(resultSet.getColumnIndex(SITE_FIELDS.PHOTO_COUNT))
    site.createdAt = new Date(resultSet.getLong(resultSet.getColumnIndex('created_at')))
    site.updatedAt = new Date(resultSet.getLong(resultSet.getColumnIndex('updated_at')))
    site.version = resultSet.getLong(resultSet.getColumnIndex('version'))

    return site
  }
}

/**
 * 导出单例实例
 */
export const siteService = SiteService.getInstance()