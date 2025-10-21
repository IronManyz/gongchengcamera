/**
 * 用户数据服务
 * 提供用户的CRUD操作和业务逻辑处理
 */

import { hilog } from '@ohos.log'
import {
  databaseService,
  DatabaseError,
  QueryParams,
  PaginationParams,
  PaginationResult
} from './DatabaseService'
import { User } from '../../models/User'
import { UserRole } from '../../types/AppTypes'
import {
  TABLE_NAMES,
  USER_FIELDS,
  DATA_TYPES,
  DEFAULT_VALUES,
  ERROR_CODES,
  PAGINATION,
  SORT_DIRECTIONS
} from '../../constants/DatabaseConstants'

/**
 * 用户查询条件接口
 */
export interface UserQueryParams extends QueryParams {
  role?: UserRole
  isActive?: boolean
  department?: string
  nameKeyword?: string
}

/**
 * 用户服务类
 */
export class UserService {
  private static instance: UserService | null = null
  private readonly TAG = 'UserService'

  static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService()
    }
    return UserService.instance
  }

  private constructor() {}

  /**
   * 创建新用户
   */
  async createUser(user: User): Promise<User> {
    try {
      hilog.info(0x0000, this.TAG, `创建用户: ${user.username}`)

      if (!user.isValid()) {
        throw new DatabaseError('用户数据验证失败', ERROR_CODES.CONSTRAINT_VIOLATION)
      }

      // 检查用户名是否已存在
      const usernameExists = await this.isUsernameExists(user.username)
      if (usernameExists) {
        throw new DatabaseError(`用户名已存在: ${user.username}`, ERROR_CODES.UNIQUE_VIOLATION)
      }

      // 检查邮箱是否已存在
      if (user.email) {
        const emailExists = await this.isEmailExists(user.email)
        if (emailExists) {
          throw new DatabaseError(`邮箱已存在: ${user.email}`, ERROR_CODES.UNIQUE_VIOLATION)
        }
      }

      const now = Date.now()
      user.createdAt = new Date(now)
      user.updatedAt = new Date(now)
      user.lastLoginAt = new Date(now)

      const dbData = this.userToDbData(user)

      await databaseService.executeSql(`
        INSERT INTO ${TABLE_NAMES.USERS} (
          ${USER_FIELDS.USER_ID},
          ${USER_FIELDS.USERNAME},
          ${USER_FIELDS.EMAIL},
          ${USER_FIELDS.DISPLAY_NAME},
          ${USER_FIELDS.AVATAR},
          ${USER_FIELDS.PHONE},
          ${USER_FIELDS.DEPARTMENT},
          ${USER_FIELDS.POSITION},
          ${USER_FIELDS.ROLE},
          ${USER_FIELDS.PERMISSIONS},
          ${USER_FIELDS.IS_ACTIVE},
          ${USER_FIELDS.LAST_LOGIN_AT},
          ${USER_FIELDS.PHOTO_COUNT},
          ${USER_FIELDS.PROJECT_COUNT},
          ${USER_FIELDS.PREFERENCES},
          ${USER_FIELDS.SETTINGS},
          created_at,
          updated_at,
          version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        dbData.user_id,
        dbData.username,
        dbData.email,
        dbData.display_name,
        dbData.avatar,
        dbData.phone,
        dbData.department,
        dbData.position,
        dbData.role,
        dbData.permissions,
        dbData.is_active,
        dbData.last_login_at,
        dbData.photo_count,
        dbData.project_count,
        dbData.preferences,
        dbData.settings,
        dbData.created_at,
        dbData.updated_at,
        dbData.version
      ])

      hilog.info(0x0000, this.TAG, `用户创建成功: ${user.id}`)
      return user

    } catch (error) {
      hilog.error(0x0000, this.TAG, `创建用户失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `创建用户失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 根据ID获取用户
   */
  async getUserById(userId: string): Promise<User | null> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.USER_ID} = ?
        LIMIT 1
      `, [userId])

      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return null
      }

      const user = this.dbDataToUser(resultSet)
      resultSet.close()

      return user

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询用户失败: ${userId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询用户失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 根据用户名获取用户
   */
  async getUserByUsername(username: string): Promise<User | null> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.USERNAME} = ?
        LIMIT 1
      `, [username])

      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return null
      }

      const user = this.dbDataToUser(resultSet)
      resultSet.close()

      return user

    } catch (error) {
      hilog.error(0x0000, this.TAG, `根据用户名查询失败: ${username}, 错误: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 更新用户信息
   */
  async updateUser(user: User): Promise<boolean> {
    try {
      user.updatedAt = new Date()
      user.version++

      const dbData = this.userToDbData(user)

      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.USERS} SET
          ${USER_FIELDS.EMAIL} = ?,
          ${USER_FIELDS.DISPLAY_NAME} = ?,
          ${USER_FIELDS.AVATAR} = ?,
          ${USER_FIELDS.PHONE} = ?,
          ${USER_FIELDS.DEPARTMENT} = ?,
          ${USER_FIELDS.POSITION} = ?,
          ${USER_FIELDS.ROLE} = ?,
          ${USER_FIELDS.PERMISSIONS} = ?,
          ${USER_FIELDS.IS_ACTIVE} = ?,
          ${USER_FIELDS.PHOTO_COUNT} = ?,
          ${USER_FIELDS.PROJECT_COUNT} = ?,
          ${USER_FIELDS.PREFERENCES} = ?,
          ${USER_FIELDS.SETTINGS} = ?,
          updated_at = ?,
          version = ?
        WHERE ${USER_FIELDS.USER_ID} = ?
      `, [
        dbData.email,
        dbData.display_name,
        dbData.avatar,
        dbData.phone,
        dbData.department,
        dbData.position,
        dbData.role,
        dbData.permissions,
        dbData.is_active,
        dbData.photo_count,
        dbData.project_count,
        dbData.preferences,
        dbData.settings,
        dbData.updated_at,
        dbData.version,
        user.id
      ])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新用户失败: ${user.id}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `更新用户失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新最后登录时间
   */
  async updateLastLogin(userId: string): Promise<boolean> {
    try {
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.USERS}
        SET ${USER_FIELDS.LAST_LOGIN_AT} = ?,
            updated_at = ?
        WHERE ${USER_FIELDS.USER_ID} = ?
      `, [Date.now(), Date.now(), userId])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新最后登录时间失败: ${userId}`)
      return false
    }
  }

  /**
   * 删除用户
   */
  async deleteUser(userId: string): Promise<boolean> {
    try {
      const result = await databaseService.executeSql(`
        DELETE FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.USER_ID} = ?
      `, [userId])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `删除用户失败: ${userId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `删除用户失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 查询用户列表
   */
  async queryUsers(params: UserQueryParams = {}): Promise<User[]> {
    try {
      let sql = `SELECT * FROM ${TABLE_NAMES.USERS} WHERE 1=1`
      const args: any[] = []

      if (params.role) {
        sql += ` AND ${USER_FIELDS.ROLE} = ?`
        args.push(params.role)
      }

      if (params.isActive !== undefined) {
        sql += ` AND ${USER_FIELDS.IS_ACTIVE} = ?`
        args.push(params.isActive ? 1 : 0)
      }

      if (params.department) {
        sql += ` AND ${USER_FIELDS.DEPARTMENT} LIKE ?`
        args.push(`%${params.department}%`)
      }

      if (params.nameKeyword) {
        sql += ` AND (${USER_FIELDS.USERNAME} LIKE ? OR ${USER_FIELDS.DISPLAY_NAME} LIKE ?)`
        args.push(`%${params.nameKeyword}%`, `%${params.nameKeyword}%`)
      }

      sql += ` ORDER BY ${params.orderBy || USER_FIELDS.LAST_LOGIN_AT + ' DESC'}`

      if (params.limit) {
        sql += ` LIMIT ?`
        args.push(params.limit)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const users: User[] = []

      while (resultSet.goToNextRow()) {
        users.push(this.dbDataToUser(resultSet))
      }

      resultSet.close()
      return users

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询用户列表失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询用户列表失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 搜索用户
   */
  async searchUsers(keyword: string, limit: number = 20): Promise<User[]> {
    try {
      if (!keyword.trim()) {
        return []
      }

      const sql = `
        SELECT * FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.USERNAME} LIKE ?
           OR ${USER_FIELDS.DISPLAY_NAME} LIKE ?
           OR ${USER_FIELDS.EMAIL} LIKE ?
           OR ${USER_FIELDS.DEPARTMENT} LIKE ?
        ORDER BY
          CASE
            WHEN ${USER_FIELDS.USERNAME} LIKE ? THEN 1
            WHEN ${USER_FIELDS.DISPLAY_NAME} LIKE ? THEN 2
            ELSE 3
          END,
          ${USER_FIELDS.LAST_LOGIN_AT} DESC
        LIMIT ?
      `

      const searchPattern = `%${keyword}%`
      const exactPattern = `${keyword}%`

      const resultSet = await databaseService.executeQuery(sql, [
        searchPattern, searchPattern, searchPattern, searchPattern,
        exactPattern, exactPattern, limit
      ])

      const users: User[] = []
      while (resultSet.goToNextRow()) {
        users.push(this.dbDataToUser(resultSet))
      }

      resultSet.close()
      return users

    } catch (error) {
      hilog.error(0x0000, this.TAG, `搜索用户失败: ${keyword}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `搜索用户失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 检查用户名是否已存在
   */
  async isUsernameExists(username: string, excludeId?: string): Promise<boolean> {
    try {
      let sql = `
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.USERNAME} = ?
      `
      const args: any[] = [username]

      if (excludeId) {
        sql += ` AND ${USER_FIELDS.USER_ID} != ?`
        args.push(excludeId)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const count = resultSet.getLong(0)
      resultSet.close()

      return count > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `检查用户名存在性失败: ${username}`)
      return false
    }
  }

  /**
   * 检查邮箱是否已存在
   */
  async isEmailExists(email: string, excludeId?: string): Promise<boolean> {
    try {
      let sql = `
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.EMAIL} = ?
      `
      const args: any[] = [email]

      if (excludeId) {
        sql += ` AND ${USER_FIELDS.USER_ID} != ?`
        args.push(excludeId)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const count = resultSet.getLong(0)
      resultSet.close()

      return count > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `检查邮箱存在性失败: ${email}`)
      return false
    }
  }

  /**
   * 获取活跃用户数量
   */
  async getActiveUserCount(): Promise<number> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.USERS}
        WHERE ${USER_FIELDS.IS_ACTIVE} = 1
      `)
      const count = resultSet.getLong(0)
      resultSet.close()
      return count

    } catch (error) {
      hilog.error(0x0000, this.TAG, `获取活跃用户数量失败`)
      return 0
    }
  }

  /**
   * 批量更新用户统计信息
   */
  async updateUserStats(userId: string, photoIncrement: number = 0, projectIncrement: number = 0): Promise<boolean> {
    try {
      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.USERS}
        SET ${USER_FIELDS.PHOTO_COUNT} = ${USER_FIELDS.PHOTO_COUNT} + ?,
            ${USER_FIELDS.PROJECT_COUNT} = ${USER_FIELDS.PROJECT_COUNT} + ?,
            updated_at = ?
        WHERE ${USER_FIELDS.USER_ID} = ?
      `, [photoIncrement, projectIncrement, Date.now(), userId])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新用户统计失败: ${userId}`)
      return false
    }
  }

  // 私有辅助方法
  private userToDbData(user: User): Record<string, any> {
    return {
      user_id: user.id,
      username: user.username,
      email: user.email,
      display_name: user.displayName,
      avatar: user.avatar,
      phone: user.phone,
      department: user.department,
      position: user.position,
      role: user.role,
      permissions: JSON.stringify(user.permissions),
      is_active: user.isActive ? 1 : 0,
      last_login_at: user.lastLoginAt.getTime(),
      photo_count: user.photoCount,
      project_count: user.projectCount,
      preferences: JSON.stringify(user.preferences),
      settings: JSON.stringify(user.settings),
      created_at: user.createdAt.getTime(),
      updated_at: user.updatedAt.getTime(),
      version: user.version
    }
  }

  private dbDataToUser(resultSet: any): User {
    const user = new User()

    user.id = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.USER_ID))
    user.username = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.USERNAME))
    user.email = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.EMAIL))
    user.displayName = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.DISPLAY_NAME))
    user.avatar = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.AVATAR))
    user.phone = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.PHONE))
    user.department = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.DEPARTMENT))
    user.position = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.POSITION))
    user.role = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.ROLE)) as UserRole
    user.isActive = resultSet.getInt(resultSet.getColumnIndex(USER_FIELDS.IS_ACTIVE)) === 1
    user.lastLoginAt = new Date(resultSet.getLong(resultSet.getColumnIndex(USER_FIELDS.LAST_LOGIN_AT)))
    user.photoCount = resultSet.getLong(resultSet.getColumnIndex(USER_FIELDS.PHOTO_COUNT))
    user.projectCount = resultSet.getLong(resultSet.getColumnIndex(USER_FIELDS.PROJECT_COUNT))

    // 解析JSON字段
    try {
      const permissionsJson = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.PERMISSIONS))
      user.permissions = permissionsJson ? JSON.parse(permissionsJson) : []
    } catch (e) {
      user.permissions = []
    }

    try {
      const preferencesJson = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.PREFERENCES))
      user.preferences = preferencesJson ? JSON.parse(preferencesJson) : user.preferences
    } catch (e) {
      // 保持默认值
    }

    try {
      const settingsJson = resultSet.getString(resultSet.getColumnIndex(USER_FIELDS.SETTINGS))
      user.settings = settingsJson ? JSON.parse(settingsJson) : {}
    } catch (e) {
      user.settings = {}
    }

    user.createdAt = new Date(resultSet.getLong(resultSet.getColumnIndex('created_at')))
    user.updatedAt = new Date(resultSet.getLong(resultSet.getColumnIndex('updated_at')))
    user.version = resultSet.getLong(resultSet.getColumnIndex('version'))

    return user
  }
}

export const userService = UserService.getInstance()