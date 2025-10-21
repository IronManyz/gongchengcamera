/**
 * UserStore.ets
 * 用户状态管理Store
 * 使用V2响应式状态管理，实现用户信息和权限管理
 */

import { BaseStore } from '../BaseStore'
import { User } from '../../models/User'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { preferences } from '@kit.ArkData'

const TAG = 'UserStore'

/**
 * 用户权限枚举
 */
export enum UserPermission {
  // 项目管理权限
  PROJECT_CREATE = 'project_create',
  PROJECT_EDIT = 'project_edit',
  PROJECT_DELETE = 'project_delete',
  PROJECT_VIEW = 'project_view',

  // 工点管理权限
  SITE_CREATE = 'site_create',
  SITE_EDIT = 'site_edit',
  SITE_DELETE = 'site_delete',
  SITE_VIEW = 'site_view',

  // 照片管理权限
  PHOTO_CAPTURE = 'photo_capture',
  PHOTO_EDIT = 'photo_edit',
  PHOTO_DELETE = 'photo_delete',
  PHOTO_VIEW = 'photo_view',
  PHOTO_EXPORT = 'photo_export',

  // 系统管理权限
  USER_MANAGE = 'user_manage',
  SETTINGS_EDIT = 'settings_edit',
  BACKUP_RESTORE = 'backup_restore',

  // 基础权限
  BASIC_USE = 'basic_use'
}

/**
 * 用户角色类型
 */
export enum UserRole {
  ADMIN = 'admin',
  MANAGER = 'manager',
  ENGINEER = 'engineer',
  VIEWER = 'viewer',
  GUEST = 'guest'
}

/**
 * 用户状态类
 * 使用V2响应式装饰器确保用户信息变化触发UI更新
 */
@ObservedV2
export class UserState {
  /**
   * 当前用户信息
   */
  @Trace currentUser: User | null = null

  /**
   * 用户是否已登录
   */
  @Trace isLoggedIn: boolean = false

  /**
   * 用户角色
   */
  @Trace userRole: UserRole = UserRole.GUEST

  /**
   * 用户权限列表
   */
  @Trace permissions: UserPermission[] = []

  /**
   * 用户偏好设置
   */
  @Trace preferences: UserPreferences = new UserPreferences()

  /**
   * 用户登录状态是否正在加载
   */
  @Trace isLoading: boolean = false

  /**
   * 最后登录时间
   */
  @Trace lastLoginTime: Date | null = null

  /**
   * 用户会话ID
   */
  @Trace sessionId: string = ''
}

/**
 * 用户偏好设置类
 */
@ObservedV2
export class UserPreferences {
  /**
   * 语言偏好
   */
  @Trace language: string = 'zh-CN'

  /**
   * 自动保存间隔（秒）
   */
  @Trace autoSaveInterval: number = 300

  /**
   * 照片质量设置
   */
  @Trace photoQuality: 'high' | 'medium' | 'low' = 'high'

  /**
   * 默认水印模板ID
   */
  @Trace defaultWatermarkTemplate: string = ''

  /**
   * 是否启用位置服务
   */
  @Trace enableLocationService: boolean = true

  /**
   * 是否自动备份
   */
  @Trace enableAutoBackup: boolean = true

  /**
   * 备份间隔（小时）
   */
  @Trace backupInterval: number = 24

  /**
   * 界面主题偏好
   */
  @Trace themePreference: string = 'system'

  /**
   * 是否启用通知
   */
  @Trace enableNotifications: boolean = true
}

/**
 * 权限管理器
 * 负责权限检查和管理
 */
export class PermissionManager {
  /**
   * 角色权限映射
   */
  private static readonly ROLE_PERMISSIONS: Record<UserRole, UserPermission[]> = {
    [UserRole.ADMIN]: [
      // 管理员拥有所有权限
      UserPermission.PROJECT_CREATE, UserPermission.PROJECT_EDIT, UserPermission.PROJECT_DELETE, UserPermission.PROJECT_VIEW,
      UserPermission.SITE_CREATE, UserPermission.SITE_EDIT, UserPermission.SITE_DELETE, UserPermission.SITE_VIEW,
      UserPermission.PHOTO_CAPTURE, UserPermission.PHOTO_EDIT, UserPermission.PHOTO_DELETE, UserPermission.PHOTO_VIEW, UserPermission.PHOTO_EXPORT,
      UserPermission.USER_MANAGE, UserPermission.SETTINGS_EDIT, UserPermission.BACKUP_RESTORE, UserPermission.BASIC_USE
    ],
    [UserRole.MANAGER]: [
      // 经理拥有大部分权限，但不能管理用户
      UserPermission.PROJECT_CREATE, UserPermission.PROJECT_EDIT, UserPermission.PROJECT_DELETE, UserPermission.PROJECT_VIEW,
      UserPermission.SITE_CREATE, UserPermission.SITE_EDIT, UserPermission.SITE_DELETE, UserPermission.SITE_VIEW,
      UserPermission.PHOTO_CAPTURE, UserPermission.PHOTO_EDIT, UserPermission.PHOTO_DELETE, UserPermission.PHOTO_VIEW, UserPermission.PHOTO_EXPORT,
      UserPermission.SETTINGS_EDIT, UserPermission.BACKUP_RESTORE, UserPermission.BASIC_USE
    ],
    [UserRole.ENGINEER]: [
      // 工程师拥有基础操作权限
      UserPermission.PROJECT_VIEW,
      UserPermission.SITE_CREATE, UserPermission.SITE_EDIT, UserPermission.SITE_VIEW,
      UserPermission.PHOTO_CAPTURE, UserPermission.PHOTO_EDIT, UserPermission.PHOTO_VIEW, UserPermission.PHOTO_EXPORT,
      UserPermission.BASIC_USE
    ],
    [UserRole.VIEWER]: [
      // 查看者只有查看权限
      UserPermission.PROJECT_VIEW,
      UserPermission.SITE_VIEW,
      UserPermission.PHOTO_VIEW,
      UserPermission.BASIC_USE
    ],
    [UserRole.GUEST]: [
      // 访客只有最基础的使用权限
      UserPermission.BASIC_USE
    ]
  }

  /**
   * 获取角色的权限列表
   */
  static getRolePermissions(role: UserRole): UserPermission[] {
    return this.ROLE_PERMISSIONS[role] || []
  }

  /**
   * 检查用户是否有指定权限
   */
  static hasPermission(userPermissions: UserPermission[], permission: UserPermission): boolean {
    return userPermissions.includes(permission)
  }

  /**
   * 检查用户是否有任一权限
   */
  static hasAnyPermission(userPermissions: UserPermission[], permissions: UserPermission[]): boolean {
    return permissions.some(permission => userPermissions.includes(permission))
  }

  /**
   * 检查用户是否有所有权限
   */
  static hasAllPermissions(userPermissions: UserPermission[], permissions: UserPermission[]): boolean {
    return permissions.every(permission => userPermissions.includes(permission))
  }
}

/**
 * 用户Store类
 */
export class UserStore extends BaseStore {
  /**
   * 用户状态实例
   */
  @ObservedV2
  private _userState: UserState = new UserState()

  /**
   * Preferences实例
   */
  private preferencesInstance: preferences.Preferences | null = null

  /**
   * 用户持久化存储键名
   */
  private readonly USER_STORAGE_KEYS = {
    USER_ID: 'user_id',
    USER_NAME: 'user_name',
    USER_EMAIL: 'user_email',
    USER_ROLE: 'user_role',
    IS_LOGGED_IN: 'is_logged_in',
    LAST_LOGIN_TIME: 'last_login_time',
    SESSION_ID: 'session_id',
    USER_PREFERENCES: 'user_preferences'
  } as const

  constructor() {
    super('UserStore')
  }

  /**
   * 初始化用户Store
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      this.log('Already initialized')
      return
    }

    await this.safeExecute(
      async () => {
        // 初始化Preferences
        await this.initializePreferences()

        // 加载用户信息
        await this.loadUserInfo()

        // 加载用户偏好设置
        await this.loadUserPreferences()

        // 检查登录状态
        await this.checkLoginStatus()

        this.markInitialized()
      },
      'initialize',
      'Failed to initialize UserStore'
    )
  }

  /**
   * 销毁Store，清理资源
   */
  async destroy(): Promise<void> {
    await this.safeExecute(
      async () => {
        // 保存用户偏好设置
        await this.saveUserPreferences()

        // 清理Preferences
        if (this.preferencesInstance) {
          await preferences.deletePreferences(this.getContext(), 'user_preferences')
          this.preferencesInstance = null
        }

        this.reset()
        this.log('Destroyed successfully')
      },
      'destroy',
      'Failed to destroy UserStore'
    )
  }

  /**
   * 获取用户状态
   */
  get userState(): UserState {
    return this._userState
  }

  /**
   * 用户登录
   */
  async login(username: string, password: string): Promise<boolean> {
    this.checkInitialized()

    return await this.safeExecute(
      async () => {
        this._userState.isLoading = true

        // 这里应该实现实际的登录逻辑
        // 暂时使用模拟登录
        const loginSuccess = await this.performLogin(username, password)

        if (loginSuccess) {
          // 创建用户对象
          const user = new User('1', username, `${username}@example.com`)
          user.name = username
          user.role = UserRole.ENGINEER // 默认角色

          // 更新用户状态
          this._userState.currentUser = user
          this._userState.isLoggedIn = true
          this._userState.userRole = user.role
          this._userState.permissions = PermissionManager.getRolePermissions(user.role)
          this._userState.lastLoginTime = new Date()
          this._userState.sessionId = this.generateSessionId()

          // 保存登录信息
          await this.saveUserInfo()

          this.log(`User logged in: ${username}`)
        }

        this._userState.isLoading = false
        return loginSuccess
      },
      'login',
      `Login failed for user: ${username}`
    ) || false
  }

  /**
   * 用户登出
   */
  async logout(): Promise<void> {
    this.checkInitialized()

    await this.safeExecute(
      async () => {
        // 清除用户状态
        this._userState.currentUser = null
        this._userState.isLoggedIn = false
        this._userState.userRole = UserRole.GUEST
        this._userState.permissions = []
        this._userState.sessionId = ''

        // 保存登出状态
        await this.saveUserInfo()

        this.log('User logged out')
      },
      'logout',
      'Logout failed'
    )
  }

  /**
   * 检查用户权限
   */
  hasPermission(permission: UserPermission): boolean {
    return PermissionManager.hasPermission(this._userState.permissions, permission)
  }

  /**
   * 检查用户是否有任一权限
   */
  hasAnyPermission(permissions: UserPermission[]): boolean {
    return PermissionManager.hasAnyPermission(this._userState.permissions, permissions)
  }

  /**
   * 检查用户是否有所有权限
   */
  hasAllPermissions(permissions: UserPermission[]): boolean {
    return PermissionManager.hasAllPermissions(this._userState.permissions, permissions)
  }

  /**
   * 更新用户偏好设置
   */
  async updatePreferences(preferences: Partial<UserPreferences>): Promise<void> {
    this.checkInitialized()

    await this.safeExecute(
      async () => {
        // 更新偏好设置
        Object.assign(this._userState.preferences, preferences)

        // 保存偏好设置
        await this.saveUserPreferences()

        this.log('User preferences updated')
      },
      'updatePreferences',
      'Failed to update user preferences'
    )
  }

  /**
   * 更新用户信息
   */
  async updateUserInfo(userInfo: Partial<User>): Promise<void> {
    this.checkInitialized()

    if (!this._userState.currentUser) {
      this.logError('Cannot update user info: user not logged in', new Error('User not logged in'))
      return
    }

    await this.safeExecute(
      async () => {
        // 更新用户信息
        Object.assign(this._userState.currentUser, userInfo)

        // 保存用户信息
        await this.saveUserInfo()

        this.log('User info updated')
      },
      'updateUserInfo',
      'Failed to update user info'
    )
  }

  /**
   * 初始化Preferences
   */
  private async initializePreferences(): Promise<void> {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.getContext(), 'user_preferences')
      this.log('Preferences initialized')
    } catch (error) {
      this.logError('Failed to initialize preferences', error)
      throw error
    }
  }

  /**
   * 加载用户信息
   */
  private async loadUserInfo(): Promise<void> {
    if (!this.preferencesInstance) {
      return
    }

    try {
      const isLoggedIn = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.IS_LOGGED_IN, false) as boolean

      if (isLoggedIn) {
        const userId = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_ID, '') as string
        const userName = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_NAME, '') as string
        const userEmail = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_EMAIL, '') as string
        const userRole = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_ROLE, UserRole.GUEST) as UserRole
        const lastLoginTime = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.LAST_LOGIN_TIME, '') as string
        const sessionId = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.SESSION_ID, '') as string

        // 创建用户对象
        if (userId && userName) {
          const user = new User(userId, userName, userEmail)
          user.role = userRole

          this._userState.currentUser = user
          this._userState.isLoggedIn = true
          this._userState.userRole = userRole
          this._userState.permissions = PermissionManager.getRolePermissions(userRole)
          this._userState.lastLoginTime = lastLoginTime ? new Date(lastLoginTime) : null
          this._userState.sessionId = sessionId
        }
      }

      this.log('User info loaded successfully')
    } catch (error) {
      this.logError('Failed to load user info', error)
    }
  }

  /**
   * 保存用户信息
   */
  private async saveUserInfo(): Promise<void> {
    if (!this.preferencesInstance) {
      return
    }

    try {
      const user = this._userState.currentUser

      if (user && this._userState.isLoggedIn) {
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_ID, user.id)
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_NAME, user.name)
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_EMAIL, user.email)
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_ROLE, user.role)
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.IS_LOGGED_IN, true)
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.LAST_LOGIN_TIME, this._userState.lastLoginTime?.toISOString() || '')
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.SESSION_ID, this._userState.sessionId)
      } else {
        // 清除登录信息
        await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.IS_LOGGED_IN, false)
      }

      await preferences.flush(this.preferencesInstance)
      this.log('User info saved successfully')
    } catch (error) {
      this.logError('Failed to save user info', error)
    }
  }

  /**
   * 加载用户偏好设置
   */
  private async loadUserPreferences(): Promise<void> {
    if (!this.preferencesInstance) {
      return
    }

    try {
      const preferencesJson = await preferences.get(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_PREFERENCES, '{}') as string
      const preferencesData = JSON.parse(preferencesJson)

      Object.assign(this._userState.preferences, preferencesData)

      this.log('User preferences loaded successfully')
    } catch (error) {
      this.logError('Failed to load user preferences', error)
    }
  }

  /**
   * 保存用户偏好设置
   */
  private async saveUserPreferences(): Promise<void> {
    if (!this.preferencesInstance) {
      return
    }

    try {
      const preferencesJson = JSON.stringify(this._userState.preferences)
      await preferences.put(this.preferencesInstance, this.USER_STORAGE_KEYS.USER_PREFERENCES, preferencesJson)
      await preferences.flush(this.preferencesInstance)

      this.log('User preferences saved successfully')
    } catch (error) {
      this.logError('Failed to save user preferences', error)
    }
  }

  /**
   * 检查登录状态
   */
  private async checkLoginStatus(): Promise<void> {
    if (this._userState.isLoggedIn && this._userState.sessionId) {
      // 这里可以添加会话验证逻辑
      // 暂时保持登录状态
      this.log('Login status checked')
    }
  }

  /**
   * 执行登录（模拟）
   */
  private async performLogin(username: string, password: string): Promise<boolean> {
    // 这里应该实现实际的登录验证逻辑
    // 暂时使用简单的用户名密码验证
    return new Promise((resolve) => {
      setTimeout(() => {
        // 模拟登录成功（用户名不为空，密码为"password"）
        const success = username.trim().length > 0 && password === 'password'
        resolve(success)
      }, 1000) // 模拟网络延迟
    })
  }

  /**
   * 生成会话ID
   */
  private generateSessionId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2)
  }

  /**
   * 获取Context
   */
  private getContext(): Context {
    // 暂时返回一个默认值，实际使用时需要从Ability或其他地方获取
    return getContext() as Context
  }
}

/**
 * 用户Store单例实例
 */
export const userStore = new UserStore()