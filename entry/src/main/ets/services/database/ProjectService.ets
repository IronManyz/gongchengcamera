/**
 * 项目数据服务
 * 提供项目的CRUD操��和业务逻辑处理
 */

import { hilog } from '@ohos.log'
import {
  databaseService,
  DatabaseError,
  QueryParams,
  PaginationParams,
  PaginationResult
} from './DatabaseService'
import { Project } from '../../models/Project'
import { ProjectStatus } from '../../types/AppTypes'
import {
  TABLE_NAMES,
  PROJECT_FIELDS,
  DATA_TYPES,
  DEFAULT_VALUES,
  ERROR_CODES,
  PAGINATION,
  SORT_DIRECTIONS
} from '../../constants/DatabaseConstants'

/**
 * 项目查询条件接口
 */
export interface ProjectQueryParams extends QueryParams {
  status?: ProjectStatus
  manager?: string
  client?: string
  tags?: string[]
  startDateRange?: { start?: Date; end?: Date }
  dateRange?: { start?: Date; end?: Date }
  nameKeyword?: string
  codeKeyword?: string
}

/**
 * 项目统计信息
 */
export interface ProjectStats {
  totalProjects: number
  activeProjects: number
  completedProjects: number
  pausedProjects: number
  cancelledProjects: number
  totalPhotos: number
  totalSites: number
  projectsByStatus: Record<ProjectStatus, number>
  recentProjects: Project[]
}

/**
 * 项目服务类
 * 提供项目的数据访问和业务逻辑处理
 */
export class ProjectService {
  private static instance: ProjectService | null = null
  private readonly TAG = 'ProjectService'

  /**
   * 获取单例实例
   */
  static getInstance(): ProjectService {
    if (!ProjectService.instance) {
      ProjectService.instance = new ProjectService()
    }
    return ProjectService.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 创建新项目
   * @param project 项目数据
   * @returns 创建成功的项目（包含ID）
   */
  async createProject(project: Project): Promise<Project> {
    try {
      hilog.info(0x0000, this.TAG, `创建项目: ${project.name}`)

      // 验证项目数据
      if (!project.isValid()) {
        throw new DatabaseError('项目数据验证失败', ERROR_CODES.CONSTRAINT_VIOLATION)
      }

      // 生成ID和时间戳
      if (!project.id) {
        project.id = Project.generateId()
      }
      const now = Date.now()
      project.createdAt = new Date(now)
      project.updatedAt = new Date(now)

      // 转换为数据库格式
      const dbData = this.projectToDbData(project)

      // 插入数据库
      await databaseService.executeSql(`
        INSERT INTO ${TABLE_NAMES.PROJECTS} (
          ${PROJECT_FIELDS.PROJECT_ID},
          ${PROJECT_FIELDS.NAME},
          ${PROJECT_FIELDS.CODE},
          ${PROJECT_FIELDS.CLIENT},
          ${PROJECT_FIELDS.MANAGER},
          ${PROJECT_FIELDS.START_DATE},
          ${PROJECT_FIELDS.END_DATE},
          ${PROJECT_FIELDS.DESCRIPTION},
          ${PROJECT_FIELDS.TAGS},
          ${PROJECT_FIELDS.STATUS},
          ${PROJECT_FIELDS.SITE_COUNT},
          ${PROJECT_FIELDS.PHOTO_COUNT},
          ${PROJECT_FIELDS.METADATA},
          created_at,
          updated_at,
          version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        dbData.project_id,
        dbData.name,
        dbData.code,
        dbData.client,
        dbData.manager,
        dbData.start_date,
        dbData.end_date,
        dbData.description,
        dbData.tags,
        dbData.status,
        dbData.site_count,
        dbData.photo_count,
        dbData.metadata,
        dbData.created_at,
        dbData.updated_at,
        dbData.version
      ])

      hilog.info(0x0000, this.TAG, `项目创建成功: ${project.id}`)
      return project

    } catch (error) {
      hilog.error(0x0000, this.TAG, `创建项目失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `创建项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 根据ID获取项目
   * @param projectId 项目ID
   * @returns 项目数据
   */
  async getProjectById(projectId: string): Promise<Project | null> {
    try {
      hilog.debug(0x0000, this.TAG, `查询项目: ${projectId}`)

      const resultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
        LIMIT 1
      `, [projectId])

      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return null
      }

      const project = this.dbDataToProject(resultSet)
      resultSet.close()

      hilog.debug(0x0000, this.TAG, `项目查询成功: ${project.name}`)
      return project

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询项目失败: ${projectId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新项目信息
   * @param project 项目数据
   * @returns 更新是否成功
   */
  async updateProject(project: Project): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, `更新项目: ${project.id}`)

      // 验证项目数据
      if (!project.isValid()) {
        throw new DatabaseError('项目数据验证失败', ERROR_CODES.CONSTRAINT_VIOLATION)
      }

      // 更新时间戳
      project.updatedAt = new Date()
      project.version++

      // 转换为数据库格式
      const dbData = this.projectToDbData(project)

      // 更新数据库
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.PROJECTS} SET
          ${PROJECT_FIELDS.NAME} = ?,
          ${PROJECT_FIELDS.CODE} = ?,
          ${PROJECT_FIELDS.CLIENT} = ?,
          ${PROJECT_FIELDS.MANAGER} = ?,
          ${PROJECT_FIELDS.START_DATE} = ?,
          ${PROJECT_FIELDS.END_DATE} = ?,
          ${PROJECT_FIELDS.DESCRIPTION} = ?,
          ${PROJECT_FIELDS.TAGS} = ?,
          ${PROJECT_FIELDS.STATUS} = ?,
          ${PROJECT_FIELDS.SITE_COUNT} = ?,
          ${PROJECT_FIELDS.PHOTO_COUNT} = ?,
          ${PROJECT_FIELDS.METADATA} = ?,
          updated_at = ?,
          version = ?
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [
        dbData.name,
        dbData.code,
        dbData.client,
        dbData.manager,
        dbData.start_date,
        dbData.end_date,
        dbData.description,
        dbData.tags,
        dbData.status,
        dbData.site_count,
        dbData.photo_count,
        dbData.metadata,
        dbData.updated_at,
        dbData.version,
        project.id
      ])

      const success = result > 0
      if (success) {
        hilog.info(0x0000, this.TAG, `项目更新成功: ${project.id}`)
      } else {
        hilog.warn(0x0000, this.TAG, `项目更新失败，可能不存在: ${project.id}`)
      }

      return success

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新项目失败: ${project.id}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `更新项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 删除项目
   * @param projectId 项目ID
   * @returns 删除是否成功
   */
  async deleteProject(projectId: string): Promise<boolean> {
    try {
      hilog.info(0x0000, this.TAG, `删除项目: ${projectId}`)

      const result = await databaseService.executeSql(`
        DELETE FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [projectId])

      const success = result > 0
      if (success) {
        hilog.info(0x0000, this.TAG, `项目删除成功: ${projectId}`)
      } else {
        hilog.warn(0x0000, this.TAG, `项目删除失败，可能不存在: ${projectId}`)
      }

      return success

    } catch (error) {
      hilog.error(0x0000, this.TAG, `删除项目失败: ${projectId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `删除项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 批量删除项目
   * @param projectIds 项目ID列表
   * @returns 删除成功的项目数量
   */
  async deleteProjects(projectIds: string[]): Promise<number> {
    if (projectIds.length === 0) {
      return 0
    }

    try {
      hilog.info(0x0000, this.TAG, `批量删除项目: ${projectIds.length}个`)

      const placeholders = projectIds.map(() => '?').join(',')
      const result = await databaseService.executeSql(`
        DELETE FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.PROJECT_ID} IN (${placeholders})
      `, projectIds)

      hilog.info(0x0000, this.TAG, `批量删除项目成功: ${result}个`)
      return result

    } catch (error) {
      hilog.error(0x0000, this.TAG, `批量删除项目失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `批量删除项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 查询项目列表
   * @param params 查询参数
   * @returns 项目列表
   */
  async queryProjects(params: ProjectQueryParams = {}): Promise<Project[]> {
    try {
      hilog.debug(0x0000, this.TAG, `查询项目列表`)

      let sql = `
        SELECT * FROM ${TABLE_NAMES.PROJECTS}
        WHERE 1=1
      `
      const args: any[] = []

      // 构建查询条件
      if (params.status) {
        sql += ` AND ${PROJECT_FIELDS.STATUS} = ?`
        args.push(params.status)
      }

      if (params.manager) {
        sql += ` AND ${PROJECT_FIELDS.MANAGER} LIKE ?`
        args.push(`%${params.manager}%`)
      }

      if (params.client) {
        sql += ` AND ${PROJECT_FIELDS.CLIENT} LIKE ?`
        args.push(`%${params.client}%`)
      }

      if (params.nameKeyword) {
        sql += ` AND ${PROJECT_FIELDS.NAME} LIKE ?`
        args.push(`%${params.nameKeyword}%`)
      }

      if (params.codeKeyword) {
        sql += ` AND ${PROJECT_FIELDS.CODE} LIKE ?`
        args.push(`%${params.codeKeyword}%`)
      }

      if (params.tags && params.tags.length > 0) {
        const tagConditions = params.tags.map(() => `${PROJECT_FIELDS.TAGS} LIKE ?`).join(' OR ')
        sql += ` AND (${tagConditions})`
        params.tags.forEach(tag => args.push(`%"${tag}"%`))
      }

      if (params.dateRange) {
        if (params.dateRange.start) {
          sql += ` AND ${PROJECT_FIELDS.START_DATE} >= ?`
          args.push(params.dateRange.start.getTime())
        }
        if (params.dateRange.end) {
          sql += ` AND ${PROJECT_FIELDS.END_DATE} <= ?`
          args.push(params.dateRange.end.getTime())
        }
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
      const projects: Project[] = []

      while (resultSet.goToNextRow()) {
        projects.push(this.dbDataToProject(resultSet))
      }

      resultSet.close()

      hilog.debug(0x0000, this.TAG, `项目查询完成: ${projects.length}个`)
      return projects

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询项目列表失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询项目列表失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 分页查询项目列表
   * @param params 查询参数
   * @param pagination 分页参数
   * @returns 分页查询结果
   */
  async queryProjectsWithPagination(
    params: ProjectQueryParams = {},
    pagination: PaginationParams = { page: 1, pageSize: PAGINATION.DEFAULT_PAGE_SIZE }
  ): Promise<PaginationResult<Project>> {
    try {
      hilog.debug(0x0000, this.TAG, `分页查询项目: page=${pagination.page}, size=${pagination.pageSize}`)

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
      const projects = await this.queryProjects(dataParams)

      const totalPages = Math.ceil(total / pageSize)

      hilog.debug(0x0000, this.TAG, `分页查询完成: ${projects.length}/${total}条`)

      return {
        data: projects,
        total,
        page: pagination.page,
        pageSize,
        totalPages
      }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `分页查询项目失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `分页查询项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 搜索项目
   * @param keyword 搜索关键词
   * @param limit 结果数量限制
   * @returns 匹配的项目列表
   */
  async searchProjects(keyword: string, limit: number = 50): Promise<Project[]> {
    try {
      hilog.debug(0x0000, this.TAG, `搜索项目: ${keyword}`)

      if (!keyword.trim()) {
        return []
      }

      const sql = `
        SELECT * FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.NAME} LIKE ?
           OR ${PROJECT_FIELDS.CODE} LIKE ?
           OR ${PROJECT_FIELDS.DESCRIPTION} LIKE ?
           OR ${PROJECT_FIELDS.CLIENT} LIKE ?
           OR ${PROJECT_FIELDS.TAGS} LIKE ?
        ORDER BY
          CASE
            WHEN ${PROJECT_FIELDS.NAME} LIKE ? THEN 1
            WHEN ${PROJECT_FIELDS.CODE} LIKE ? THEN 2
            ELSE 3
          END,
          updated_at DESC
        LIMIT ?
      `

      const searchPattern = `%${keyword}%`
      const exactPattern = `${keyword}%`

      const resultSet = await databaseService.executeQuery(sql, [
        searchPattern, searchPattern, searchPattern, searchPattern, searchPattern,
        exactPattern, exactPattern, limit
      ])

      const projects: Project[] = []
      while (resultSet.goToNextRow()) {
        projects.push(this.dbDataToProject(resultSet))
      }

      resultSet.close()

      hilog.debug(0x0000, this.TAG, `项目搜索完成: ${projects.length}个`)
      return projects

    } catch (error) {
      hilog.error(0x0000, this.TAG, `搜索项目失败: ${keyword}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `搜索项目失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 获取项目统计信息
   * @returns 项目统计信息
   */
  async getProjectStats(): Promise<ProjectStats> {
    try {
      hilog.debug(0x0000, this.TAG, `获取项目统计信息`)

      // 统计各状态项目数量
      const statusStats = await databaseService.executeQuery(`
        SELECT
          ${PROJECT_FIELDS.STATUS},
          COUNT(*) as count,
          COALESCE(SUM(${PROJECT_FIELDS.PHOTO_COUNT}), 0) as total_photos,
          COALESCE(SUM(${PROJECT_FIELDS.SITE_COUNT}), 0) as total_sites
        FROM ${TABLE_NAMES.PROJECTS}
        GROUP BY ${PROJECT_FIELDS.STATUS}
      `)

      const projectsByStatus: Record<ProjectStatus, number> = {
        [ProjectStatus.ACTIVE]: 0,
        [ProjectStatus.COMPLETED]: 0,
        [ProjectStatus.PAUSED]: 0,
        [ProjectStatus.CANCELLED]: 0
      }

      let totalPhotos = 0
      let totalSites = 0
      let totalProjects = 0
      let activeProjects = 0
      let completedProjects = 0
      let pausedProjects = 0
      let cancelledProjects = 0

      while (statusStats.goToNextRow()) {
        const status = statusStats.getString(0) as ProjectStatus
        const count = statusStats.getLong(1)
        const photos = statusStats.getLong(2)
        const sites = statusStats.getLong(3)

        projectsByStatus[status] = count
        totalProjects += count
        totalPhotos += photos
        totalSites += sites

        switch (status) {
          case ProjectStatus.ACTIVE:
            activeProjects = count
            break
          case ProjectStatus.COMPLETED:
            completedProjects = count
            break
          case ProjectStatus.PAUSED:
            pausedProjects = count
            break
          case ProjectStatus.CANCELLED:
            cancelledProjects = count
            break
        }
      }

      statusStats.close()

      // 获取最近的项目
      const recentResultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.PROJECTS}
        ORDER BY updated_at DESC
        LIMIT 5
      `)

      const recentProjects: Project[] = []
      while (recentResultSet.goToNextRow()) {
        recentProjects.push(this.dbDataToProject(recentResultSet))
      }
      recentResultSet.close()

      hilog.debug(0x0000, this.TAG, `项目统计完成: ${totalProjects}个项目`)

      return {
        totalProjects,
        activeProjects,
        completedProjects,
        pausedProjects,
        cancelledProjects,
        totalPhotos,
        totalSites,
        projectsByStatus,
        recentProjects
      }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `获取项目统计失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `获取项目统计失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新项目照片数量
   * @param projectId 项目ID
   * @param increment 增量（正数增加，负数减少）
   */
  async updateProjectPhotoCount(projectId: string, increment: number): Promise<boolean> {
    try {
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.PROJECTS}
        SET ${PROJECT_FIELDS.PHOTO_COUNT} = ${PROJECT_FIELDS.PHOTO_COUNT} + ?,
            updated_at = ?
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [increment, Date.now(), projectId])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新项目照片数量失败: ${projectId}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 更新项目工点数量
   * @param projectId 项目ID
   * @param increment 增量（正数增加，负数减少）
   */
  async updateProjectSiteCount(projectId: string, increment: number): Promise<boolean> {
    try {
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.PROJECTS}
        SET ${PROJECT_FIELDS.SITE_COUNT} = ${PROJECT_FIELDS.SITE_COUNT} + ?,
            updated_at = ?
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [increment, Date.now(), projectId])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新项目工点数量失败: ${projectId}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查项目编号是否已存在
   * @param code 项目编号
   * @param excludeId 排除的项目ID（用于更新时检查）
   * @returns 是否已存在
   */
  async isProjectCodeExists(code: string, excludeId?: string): Promise<boolean> {
    try {
      let sql = `
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.CODE} = ?
      `
      const args: any[] = [code]

      if (excludeId) {
        sql += ` AND ${PROJECT_FIELDS.PROJECT_ID} != ?`
        args.push(excludeId)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const count = resultSet.getLong(0)
      resultSet.close()

      return count > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `检查项目编号存在性失败: ${code}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 构建计数查询SQL
   * @param params 查询参数
   * @returns SQL语句和参数
   */
  private buildCountQuery(params: ProjectQueryParams): { sql: string; args: any[] } {
    let sql = `SELECT COUNT(*) as count FROM ${TABLE_NAMES.PROJECTS} WHERE 1=1`
    const args: any[] = []

    // 复用查询条件构建逻辑（参考queryProjects方法）
    if (params.status) {
      sql += ` AND ${PROJECT_FIELDS.STATUS} = ?`
      args.push(params.status)
    }

    if (params.manager) {
      sql += ` AND ${PROJECT_FIELDS.MANAGER} LIKE ?`
      args.push(`%${params.manager}%`)
    }

    if (params.client) {
      sql += ` AND ${PROJECT_FIELDS.CLIENT} LIKE ?`
      args.push(`%${params.client}%`)
    }

    if (params.nameKeyword) {
      sql += ` AND ${PROJECT_FIELDS.NAME} LIKE ?`
      args.push(`%${params.nameKeyword}%`)
    }

    if (params.codeKeyword) {
      sql += ` AND ${PROJECT_FIELDS.CODE} LIKE ?`
      args.push(`%${params.codeKeyword}%`)
    }

    if (params.tags && params.tags.length > 0) {
      const tagConditions = params.tags.map(() => `${PROJECT_FIELDS.TAGS} LIKE ?`).join(' OR ')
      sql += ` AND (${tagConditions})`
      params.tags.forEach(tag => args.push(`%"${tag}"%`))
    }

    if (params.dateRange) {
      if (params.dateRange.start) {
        sql += ` AND ${PROJECT_FIELDS.START_DATE} >= ?`
        args.push(params.dateRange.start.getTime())
      }
      if (params.dateRange.end) {
        sql += ` AND ${PROJECT_FIELDS.END_DATE} <= ?`
        args.push(params.dateRange.end.getTime())
      }
    }

    return { sql, args }
  }

  /**
   * 将Project对象转换为数据库数据格式
   * @param project 项目对象
   * @returns 数据库数据格式
   */
  private projectToDbData(project: Project): Record<string, any> {
    return {
      project_id: project.id,
      name: project.name,
      code: project.code,
      client: project.client,
      manager: project.manager,
      start_date: project.startDate.getTime(),
      end_date: project.endDate.getTime(),
      description: project.description,
      tags: JSON.stringify(project.tags),
      status: project.status,
      site_count: project.siteCount,
      photo_count: project.photoCount,
      metadata: JSON.stringify(project.metadata),
      created_at: project.createdAt.getTime(),
      updated_at: project.updatedAt.getTime(),
      version: project.version
    }
  }

  /**
   * 将数据库数据转换为Project对象
   * @param resultSet 数据库查询结果集
   * @returns Project对象
   */
  private dbDataToProject(resultSet: any): Project {
    const project = new Project()

    project.id = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.PROJECT_ID))
    project.name = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.NAME))
    project.code = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.CODE))
    project.client = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.CLIENT))
    project.manager = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.MANAGER))
    project.startDate = new Date(resultSet.getLong(resultSet.getColumnIndex(PROJECT_FIELDS.START_DATE)))
    project.endDate = new Date(resultSet.getLong(resultSet.getColumnIndex(PROJECT_FIELDS.END_DATE)))
    project.description = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.DESCRIPTION))

    // 解析JSON字段
    try {
      const tagsJson = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.TAGS))
      project.tags = tagsJson ? JSON.parse(tagsJson) : []
    } catch (e) {
      project.tags = []
    }

    project.status = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.STATUS)) as ProjectStatus
    project.siteCount = resultSet.getLong(resultSet.getColumnIndex(PROJECT_FIELDS.SITE_COUNT))
    project.photoCount = resultSet.getLong(resultSet.getColumnIndex(PROJECT_FIELDS.PHOTO_COUNT))

    try {
      const metadataJson = resultSet.getString(resultSet.getColumnIndex(PROJECT_FIELDS.METADATA))
      project.metadata = metadataJson ? JSON.parse(metadataJson) : {}
    } catch (e) {
      project.metadata = {}
    }

    project.createdAt = new Date(resultSet.getLong(resultSet.getColumnIndex('created_at')))
    project.updatedAt = new Date(resultSet.getLong(resultSet.getColumnIndex('updated_at')))
    project.version = resultSet.getLong(resultSet.getColumnIndex('version'))

    return project
  }
}

/**
 * 导出单例实例
 */
export const projectService = ProjectService.getInstance()