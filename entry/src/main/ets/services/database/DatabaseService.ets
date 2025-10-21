/**
 * 数据库服务
 * 提供数据库初始化、连接管理、事务支持等核心功能
 */

import relationalStore from '@ohos.data.relationalStore'
import { Context } from '@ohos.abilityAccessCtrl'
import { hilog } from '@ohos.log'
import {
  DATABASE_CONFIG,
  ERROR_CODES,
  TABLE_NAMES,
  FILE_PATHS
} from '../constants/DatabaseConstants'
import {
  CREATE_TABLES_SQL,
  CREATE_VERSION_TABLE,
  INSERT_VERSION_SQL,
  GET_CURRENT_VERSION_SQL,
  TABLE_EXISTS_SQL
} from '../constants/TableSchemas'
import {
  ALL_INDEXES_SQL,
  DROP_INDEXES_SQL,
  INDEX_STATS_SQL
} from '../constants/IndexDefinitions'

/**
 * 数据库配置接口
 */
export interface DatabaseConfig {
  name: string
  securityLevel: relationalStore.SecurityLevel
  encrypt?: boolean
  backup?: boolean
}

/**
 * 数据库初始化结果
 */
export interface DatabaseInitResult {
  success: boolean
  version: number
  tablesCreated: number
  indexesCreated: number
  error?: string
}

/**
 * 事务执行回调类型
 */
export type TransactionCallback<T> = (store: relationalStore.RdbStore) => Promise<T>

/**
 * 查询参数类型
 */
export interface QueryParams {
  table: string
  columns?: string[]
  selection?: string
  selectionArgs?: string[]
  orderBy?: string
  limit?: number
  offset?: number
}

/**
 * 分页查询参数
 */
export interface PaginationParams {
  page: number
  pageSize: number
}

/**
 * 分页查询结果
 */
export interface PaginationResult<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

/**
 * 数据库错误类
 */
export class DatabaseError extends Error {
  constructor(
    message: string,
    public code: string = ERROR_CODES.CONNECTION_FAILED,
    public cause?: Error
  ) {
    super(message)
    this.name = 'DatabaseError'
  }
}

/**
 * 数据库服务类
 * 提供数据库连接管理、初始化、事务等核心功能
 */
export class DatabaseService {
  private static instance: DatabaseService | null = null
  private store: relationalStore.RdbStore | null = null
  private context: Context | null = null
  private isInitialized: boolean = false
  private readonly TAG = 'DatabaseService'

  /**
   * 获取单例实例
   */
  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService()
    }
    return DatabaseService.instance
  }

  /**
   * 私有构造函数，确保单例模式
   */
  private constructor() {}

  /**
   * 初始化数据库服务
   * @param context 应用上下文
   * @param config 数据库配置
   * @returns 初始化结果
   */
  async initialize(context: Context, config?: Partial<DatabaseConfig>): Promise<DatabaseInitResult> {
    if (this.isInitialized) {
      return {
        success: true,
        version: DATABASE_CONFIG.VERSION,
        tablesCreated: 0,
        indexesCreated: 0
      }
    }

    this.context = context
    const startTime = Date.now()

    try {
      hilog.info(0x0000, this.TAG, '开始初始化数据库...')

      // 获取数据库文件路径
      const dbPath = await this.getDatabasePath()
      hilog.info(0x0000, this.TAG, `数据库路径: ${dbPath}`)

      // 创建数据库配置
      const dbConfig: relationalStore.StoreConfig = {
        name: config?.name || DATABASE_CONFIG.NAME,
        securityLevel: config?.securityLevel || relationalStore.SecurityLevel.S1,
        encrypt: config?.encrypt || false
      }

      hilog.info(0x0000, this.TAG, `数据库配置: ${JSON.stringify(dbConfig)}`)

      // 打开或创建数据库
      this.store = await relationalStore.getRdbStore(context, dbConfig)

      hilog.info(0x0000, this.TAG, '数据库连接成功')

      // 检查并创建表结构
      const tablesResult = await this.createTables()

      // 检查并创建索引
      const indexesResult = await this.createIndexes()

      // 更新版本信息
      await this.updateSchemaVersion(DATABASE_CONFIG.VERSION, '初始化数据库')

      this.isInitialized = true
      const duration = Date.now() - startTime

      hilog.info(0x0000, this.TAG, `数据库初始化完成，耗时: ${duration}ms`)

      return {
        success: true,
        version: DATABASE_CONFIG.VERSION,
        tablesCreated: tablesResult.createdCount,
        indexesCreated: indexesResult.createdCount
      }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `数据库初始化失败: ${JSON.stringify(error)}`)
      return {
        success: false,
        version: 0,
        tablesCreated: 0,
        indexesCreated: 0,
        error: error instanceof Error ? error.message : String(error)
      }
    }
  }

  /**
   * 获取数据库存储实例
   * @returns RdbStore实例
   */
  getStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new DatabaseError('数据库未初始化', ERROR_CODES.DATABASE_NOT_FOUND)
    }
    return this.store
  }

  /**
   * 检查数据库是否已初始化
   * @returns 是否已初始化
   */
  isReady(): boolean {
    return this.isInitialized && this.store !== null
  }

  /**
   * 获取数据库文件路径
   * @returns 数据库文件路径
   */
  private async getDatabasePath(): Promise<string> {
    if (!this.context) {
      throw new DatabaseError('应用上下文未设置', ERROR_CODES.CONNECTION_FAILED)
    }

    const databaseDir = this.context.databaseDir || FILE_PATHS.DATABASE_DIR
    return `${databaseDir}/${DATABASE_CONFIG.NAME}`
  }

  /**
   * 创建所有表结构
   * @returns 表创建结果
   */
  private async createTables(): Promise<{ createdCount: number; totalCount: number }> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    let createdCount = 0
    const totalTables = CREATE_TABLES_SQL.length

    try {
      // 先创建版本管理表
      await this.store.executeSql(CREATE_VERSION_TABLE)
      createdCount++

      // 创建所有业务表
      for (const createTableSQL of CREATE_TABLES_SQL) {
        try {
          await this.store.executeSql(createTableSQL)
          createdCount++
          hilog.info(0x0000, this.TAG, `表创建成功: ${this.extractTableName(createTableSQL)}`)
        } catch (error) {
          hilog.error(0x0000, this.TAG, `表创建失败: ${createTableSQL}, 错误: ${JSON.stringify(error)}`)
          throw error
        }
      }

      hilog.info(0x0000, this.TAG, `表结构创建完成: ${createdCount}/${totalTables}`)

      return { createdCount, totalCount: totalTables }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `创建表结构失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `创建表结构失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 创建所有索引
   * @returns 索引创建结果
   */
  private async createIndexes(): Promise<{ createdCount: number; totalCount: number }> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    let createdCount = 0
    const totalIndexes = ALL_INDEXES_SQL.length

    try {
      for (const createIndexSQL of ALL_INDEXES_SQL) {
        try {
          await this.store.executeSql(createIndexSQL)
          createdCount++
          hilog.debug(0x0000, this.TAG, `索引创建成功: ${this.extractIndexName(createIndexSQL)}`)
        } catch (error) {
          // 某些索引可能已存在或FTS不支持，记录警告但不中断流程
          hilog.warn(0x0000, this.TAG, `索引创建警告: ${createIndexSQL}, 错误: ${JSON.stringify(error)}`)
        }
      }

      hilog.info(0x0000, this.TAG, `索引创建完成: ${createdCount}/${totalIndexes}`)

      return { createdCount, totalCount: totalIndexes }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `创建索引失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `创建索引失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新数据库版本信息
   * @param version 版本号
   * @param description 版本描述
   */
  private async updateSchemaVersion(version: number, description: string): Promise<void> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      const now = Date.now()
      await this.store.executeSql(INSERT_VERSION_SQL, [version, now, description])
      hilog.info(0x0000, this.TAG, `版本信息更新: v${version} - ${description}`)
    } catch (error) {
      hilog.error(0x0000, this.TAG, `版本信息更新失败: ${JSON.stringify(error)}`)
      // 版本信息更新失败不影响整体初始化
    }
  }

  /**
   * 获取当前数据库版本
   * @returns 当前版本号
   */
  async getCurrentVersion(): Promise<number> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      const resultSet = await this.store.querySql(GET_CURRENT_VERSION_SQL)
      if (resultSet.goToFirstRow()) {
        const version = resultSet.getLong(0)
        resultSet.close()
        return version
      }
      resultSet.close()
      return 0
    } catch (error) {
      hilog.error(0x0000, this.TAG, `获取数据库版本失败: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 检查表是否存在
   * @param tableName 表名
   * @returns 是否存在
   */
  async tableExists(tableName: string): Promise<boolean> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      const resultSet = await this.store.querySql(TABLE_EXISTS_SQL(tableName))
      const exists = resultSet.goToFirstRow()
      resultSet.close()
      return exists
    } catch (error) {
      hilog.error(0x0000, this.TAG, `检查表存在性失败: ${tableName}, 错误: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 执行事务
   * @param callback 事务回调函数
   * @returns 事务执行结果
   */
  async executeTransaction<T>(callback: TransactionCallback<T>): Promise<T> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      await this.store.executeSql('BEGIN TRANSACTION')
      hilog.debug(0x0000, this.TAG, '事务开始')

      const result = await callback(this.store)

      await this.store.executeSql('COMMIT')
      hilog.debug(0x0000, this.TAG, '事务提交成功')

      return result
    } catch (error) {
      try {
        await this.store.executeSql('ROLLBACK')
        hilog.warn(0x0000, this.TAG, '事务回滚成功')
      } catch (rollbackError) {
        hilog.error(0x0000, this.TAG, `事务回滚失败: ${JSON.stringify(rollbackError)}`)
      }

      hilog.error(0x0000, this.TAG, `事务执行失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `事务执行失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.TRANSACTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 执行SQL查询
   * @param sql SQL语句
   * @param args 参数
   * @returns 查询结果
   */
  async executeQuery(sql: string, args?: any[]): Promise<relationalStore.ResultSet> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      hilog.debug(0x0000, this.TAG, `执行查询: ${sql}, 参数: ${JSON.stringify(args)}`)
      return await this.store.querySql(sql, args)
    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询执行失败: ${sql}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询执行失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 执行SQL语句（非查询）
   * @param sql SQL语句
   * @param args 参数
   * @returns 执行结果
   */
  async executeSql(sql: string, args?: any[]): Promise<number> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      hilog.debug(0x0000, this.TAG, `执行SQL: ${sql}, 参数: ${JSON.stringify(args)}`)
      const result = await this.store.executeSql(sql, args)
      return result
    } catch (error) {
      hilog.error(0x0000, this.TAG, `SQL执行失败: ${sql}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `SQL执行失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 重建所有索引
   * @returns 重建结果
   */
  async rebuildIndexes(): Promise<{ success: boolean; rebuiltCount: number; totalCount: number }> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      // 删除现有索引
      for (const dropIndexSQL of DROP_INDEXES_SQL) {
        try {
          await this.store.executeSql(dropIndexSQL)
        } catch (error) {
          hilog.debug(0x0000, this.TAG, `删除索引警告: ${JSON.stringify(error)}`)
        }
      }

      // 重新创建索引
      const result = await this.createIndexes()

      hilog.info(0x0000, this.TAG, `索引重建完成: ${result.createdCount}/${result.totalCount}`)

      return {
        success: true,
        rebuiltCount: result.createdCount,
        totalCount: result.totalCount
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, `索引重建失败: ${JSON.stringify(error)}`)
      return {
        success: false,
        rebuiltCount: 0,
        totalCount: 0
      }
    }
  }

  /**
   * 获取数据库统计信息
   * @returns 统计信息
   */
  async getDatabaseStats(): Promise<{
    version: number
    tableCount: number
    indexCount: number
    indexStats: any[]
  }> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      const version = await this.getCurrentVersion()

      // 获取所有表名
      const tablesResultSet = await this.store.querySql(`
        SELECT name FROM sqlite_master
        WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'projects_fts'
        ORDER BY name
      `)
      const tableCount = tablesResultSet.rowCount
      tablesResultSet.close()

      // 获取索引统计信息
      const indexStatsResultSet = await this.store.querySql(INDEX_STATS_SQL)
      const indexStats: any[] = []
      while (indexStatsResultSet.goToNextRow()) {
        indexStats.push({
          name: indexStatsResultSet.getString(0),
          tableName: indexStatsResultSet.getString(1),
          definition: indexStatsResultSet.getString(2)
        })
      }
      indexStatsResultSet.close()

      return {
        version,
        tableCount,
        indexCount: indexStats.length,
        indexStats
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, `获取数据库统计信息失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `获取数据库统计信息失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 关闭数据库连接
   */
  async close(): Promise<void> {
    if (this.store) {
      try {
        await this.store.close()
        this.store = null
        this.isInitialized = false
        hilog.info(0x0000, this.TAG, '数据库连接已关闭')
      } catch (error) {
        hilog.error(0x0000, this.TAG, `关闭数据库连接失败: ${JSON.stringify(error)}`)
        throw new DatabaseError(
          `关闭数据库连接失败: ${error instanceof Error ? error.message : String(error)}`,
          ERROR_CODES.CONNECTION_FAILED,
          error instanceof Error ? error : undefined
        )
      }
    }
  }

  /**
   * 从SQL语句中提取表名
   * @param sql SQL语句
   * @returns 表名
   */
  private extractTableName(sql: string): string {
    const match = sql.match(/CREATE TABLE IF NOT EXISTS (\w+)/i)
    return match ? match[1] : 'unknown'
  }

  /**
   * 从SQL语句中提取索引名
   * @param sql SQL语句
   * @returns 索引名
   */
  private extractIndexName(sql: string): string {
    const match = sql.match(/CREATE (?:INDEX IF NOT EXISTS|VIRTUAL TABLE IF NOT EXISTS) (\w+)/i)
    return match ? match[1] : 'unknown'
  }

  /**
   * 优化数据库性能
   */
  async optimize(): Promise<void> {
    if (!this.store) {
      throw new DatabaseError('数据库连接未建立', ERROR_CODES.CONNECTION_FAILED)
    }

    try {
      // 分析表统计信息
      await this.store.executeSql('ANALYZE')

      // 清理数据库碎片
      await this.store.executeSql('VACUUM')

      hilog.info(0x0000, this.TAG, '数据库优化完成')
    } catch (error) {
      hilog.error(0x0000, this.TAG, `数据库优化失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `数据库优化失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }
}

/**
 * 导出单例实例
 */
export const databaseService = DatabaseService.getInstance()