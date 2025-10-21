/**
 * 数据库服务统一导出
 * 提供所有数据库相关服务的统一访问入口
 */

// 核心数据库服务
export { DatabaseService, databaseService, type DatabaseConfig, type DatabaseInitResult, type TransactionCallback, type QueryParams, type PaginationParams, type PaginationResult, type DatabaseError } from './DatabaseService'

// 业务数据服务
export { ProjectService, projectService, type ProjectQueryParams, type ProjectStats } from './ProjectService'
export { SiteService, siteService, type SiteQueryParams, type SiteStats, type BoundingBox } from './SiteService'
export { PhotoService, photoService, type PhotoQueryParams } from './PhotoService'
export { UserService, userService, type UserQueryParams } from './UserService'

/**
 * 数据库服务管理器
 * 提供统一的数据库服务初始化和管理功能
 */
export class DatabaseManager {
  private static instance: DatabaseManager | null = null
  private readonly TAG = 'DatabaseManager'
  private isInitialized: boolean = false

  static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager()
    }
    return DatabaseManager.instance
  }

  private constructor() {}

  /**
   * 初始化所有数据库服务
   * @param context 应用上下文
   * @param config 数据库配置
   */
  async initialize(context: any, config?: any): Promise<boolean> {
    if (this.isInitialized) {
      return true
    }

    try {
      // 初始化核心数据库服务
      const result = await databaseService.initialize(context, config)

      if (!result.success) {
        console.error(`${this.TAG}: 数据库初始化失败: ${result.error}`)
        return false
      }

      this.isInitialized = true
      console.info(`${this.TAG}: 数据库服务初始化成功`)
      console.info(`${this.TAG}: 创建了 ${result.tablesCreated} 个表，${result.indexesCreated} 个索引`)

      return true

    } catch (error) {
      console.error(`${this.TAG}: 数据库服务初始化异常: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查数据库是否已初始化
   */
  isReady(): boolean {
    return this.isInitialized && databaseService.isReady()
  }

  /**
   * 获取数据库统计信息
   */
  async getStats(): Promise<any> {
    if (!this.isReady()) {
      throw new Error('数据库服务未初始化')
    }

    return await databaseService.getDatabaseStats()
  }

  /**
   * 优化数据库
   */
  async optimize(): Promise<void> {
    if (!this.isReady()) {
      throw new Error('数据库服务未初始化')
    }

    await databaseService.optimize()
  }

  /**
   * 关闭所有数据库服务
   */
  async close(): Promise<void> {
    if (this.isInitialized) {
      await databaseService.close()
      this.isInitialized = false
      console.info(`${this.TAG}: 数据库服务已关闭`)
    }
  }
}

/**
 * 导出数据库管理器单例
 */
export const databaseManager = DatabaseManager.getInstance()