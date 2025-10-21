/**
 * 用户数据模型
 * 用于管理应用用户的基本信息和设置
 */

import { BaseModel } from './base/BaseModel'
import { UserRole, Permission, UserPreferences } from '../types/AppTypes'

@ObservedV2
export class User extends BaseModel {
  @Trace username: string = ''
  @Trace email: string = ''
  @Trace displayName: string = ''
  @Trace avatar: string = ''
  @Trace phone: string = ''
  @Trace department: string = ''
  @Trace position: string = ''
  @Trace role: UserRole = UserRole.VIEWER
  @Trace permissions: Permission[] = []
  @Trace isActive: boolean = true
  @Trace lastLoginAt: Date = new Date()
  @Trace photoCount: number = 0
  @Trace projectCount: number = 0
  @Local preferences: UserPreferences = {
    theme: 'system' as any,
    language: 'zh-CN',
    autoBackup: true,
    compressImages: true,
    locationServices: true
  }
  @Local settings: Record<string, any> = {}

  constructor() {
    super()
    if (this.id === '') {
      this.id = BaseModel.generateId()
    }
  }

  /**
   * 验证用户数据是否完整
   */
  override isValid(): boolean {
    return super.isValid() &&
           this.username.trim().length > 0
  }

  /**
   * 获取用户显示名称
   */
  getDisplayName(): string {
    return this.displayName || this.username || '未知用户'
  }

  /**
   * 获取用户角色显示文本
   */
  getRoleText(): string {
    switch (this.role) {
      case UserRole.OWNER:
        return '所有者'
      case UserRole.EDITOR:
        return '编辑者'
      case UserRole.VIEWER:
        return '查看者'
      default:
        return '未知角色'
    }
  }

  /**
   * 检查是否有指定权限
   */
  hasPermission(permission: Permission): boolean {
    return this.permissions.includes(permission) || this.role === UserRole.OWNER
  }

  /**
   * 添加权限
   */
  addPermission(permission: Permission): void {
    if (!this.permissions.includes(permission)) {
      this.permissions.push(permission)
      this.updateTimestamp()
    }
  }

  /**
   * 移除权限
   */
  removePermission(permission: Permission): void {
    const index = this.permissions.indexOf(permission)
    if (index > -1) {
      this.permissions.splice(index, 1)
      this.updateTimestamp()
    }
  }

  /**
   * 设置用户角色
   */
  setRole(role: UserRole): void {
    if (this.role !== role) {
      this.role = role
      // 根据角色调整权限
      this.adjustPermissionsByRole()
      this.updateTimestamp()
    }
  }

  /**
   * 根据角色调整权限
   */
  private adjustPermissionsByRole(): void {
    switch (this.role) {
      case UserRole.OWNER:
        // 所有者拥有所有权限
        this.permissions = [
          Permission.READ,
          Permission.WRITE,
          Permission.DELETE,
          Permission.SHARE,
          Permission.MANAGE
        ]
        break
      case UserRole.EDITOR:
        // 编辑者拥有读写和分享权限
        this.permissions = [
          Permission.READ,
          Permission.WRITE,
          Permission.SHARE
        ]
        break
      case UserRole.VIEWER:
        // 查看者只有读权限
        this.permissions = [Permission.READ]
        break
    }
  }

  /**
   * 激活用户
   */
  activate(): void {
    if (!this.isActive) {
      this.isActive = true
      this.updateTimestamp()
    }
  }

  /**
   * 停用用户
   */
  deactivate(): void {
    if (this.isActive) {
      this.isActive = false
      this.updateTimestamp()
    }
  }

  /**
   * 更新最后登录时间
   */
  updateLastLogin(): void {
    this.lastLoginAt = new Date()
    this.updateTimestamp()
  }

  /**
   * 检查用户是否在线（基于最后登录时间）
   */
  isOnline(timeoutMinutes: number = 5): boolean {
    const now = new Date()
    const diffMinutes = (now.getTime() - this.lastLoginAt.getTime()) / (1000 * 60)
    return diffMinutes <= timeoutMinutes
  }

  /**
   * 更新用户偏好设置
   */
  updatePreferences(preferences: Partial<UserPreferences>): void {
    Object.assign(this.preferences, preferences)
    this.updateTimestamp()
  }

  /**
   * 获取偏好设置
   */
  getPreference<K extends keyof UserPreferences>(key: K): UserPreferences[K] {
    return this.preferences[key]
  }

  /**
   * 设置偏好设置
   */
  setPreference<K extends keyof UserPreferences>(key: K, value: UserPreferences[K]): void {
    if (this.preferences[key] !== value) {
      this.preferences[key] = value
      this.updateTimestamp()
    }
  }

  /**
   * 设置用户设置项
   */
  setSetting(key: string, value: any): void {
    this.settings[key] = value
    this.updateTimestamp()
  }

  /**
   * 获取用户设置项
   */
  getSetting(key: string, defaultValue: any = null): any {
    return this.settings[key] ?? defaultValue
  }

  /**
   * 更新照片数量
   */
  updatePhotoCount(count: number): void {
    if (this.photoCount !== count) {
      this.photoCount = count
      this.updateTimestamp()
    }
  }

  /**
   * 更新项目数量
   */
  updateProjectCount(count: number): void {
    if (this.projectCount !== count) {
      this.projectCount = count
      this.updateTimestamp()
    }
  }

  /**
   * 搜索用户信息
   */
  matchesSearch(query: string): boolean {
    if (!query) return true

    const lowercaseQuery = query.toLowerCase()
    return this.username.toLowerCase().includes(lowercaseQuery) ||
           this.displayName.toLowerCase().includes(lowercaseQuery) ||
           this.email.toLowerCase().includes(lowercaseQuery) ||
           this.phone.toLowerCase().includes(lowercaseQuery) ||
           this.department.toLowerCase().includes(lowercaseQuery) ||
           this.position.toLowerCase().includes(lowercaseQuery)
  }

  /**
   * 获取用户统计信息
   */
  getStats(): {
    photoCount: number
    projectCount: number
    permissionCount: number
    daysSinceLastLogin: number
  } {
    const now = new Date()
    const daysSinceLastLogin = Math.floor(
      (now.getTime() - this.lastLoginAt.getTime()) / (1000 * 60 * 60 * 24)
    )

    return {
      photoCount: this.photoCount,
      projectCount: this.projectCount,
      permissionCount: this.permissions.length,
      daysSinceLastLogin
    }
  }

  /**
   * 检查是否为新用户（注册不超过7天）
   */
  isNewUser(): boolean {
    const now = new Date()
    const daysSinceCreation = Math.floor(
      (now.getTime() - this.createdAt.getTime()) / (1000 * 60 * 60 * 24)
    )
    return daysSinceCreation <= 7
  }

  /**
   * 获取用户最后登录时间显示文本
   */
  getLastLoginText(): string {
    const now = new Date()
    const diffMinutes = Math.floor(
      (now.getTime() - this.lastLoginAt.getTime()) / (1000 * 60)
    )

    if (diffMinutes < 1) {
      return '刚刚'
    } else if (diffMinutes < 60) {
      return `${diffMinutes}分钟前`
    } else if (diffMinutes < 1440) { // 24小时
      const hours = Math.floor(diffMinutes / 60)
      return `${hours}小时前`
    } else if (diffMinutes < 10080) { // 7天
      const days = Math.floor(diffMinutes / 1440)
      return `${days}天前`
    } else {
      return this.lastLoginAt.toLocaleDateString('zh-CN')
    }
  }

  /**
   * 转换为JSON对象（排除敏感信息）
   */
  override toJSON(): Record<string, any> {
    return {
      ...super.toJSON(),
      username: this.username,
      email: this.email,
      displayName: this.displayName,
      avatar: this.avatar,
      phone: this.phone,
      department: this.department,
      position: this.position,
      role: this.role,
      permissions: this.permissions,
      isActive: this.isActive,
      lastLoginAt: this.lastLoginAt.getTime(),
      photoCount: this.photoCount,
      projectCount: this.projectCount,
      preferences: this.preferences,
      settings: this.settings
    }
  }

  /**
   * 从JSON对象创建实例
   */
  static override fromJSON(data: Record<string, any>): User {
    const user = new User()

    if (data.id) user.id = data.id
    if (data.createdAt) user.createdAt = new Date(data.createdAt)
    if (data.updatedAt) user.updatedAt = new Date(data.updatedAt)
    if (data.version) user.version = data.version

    if (data.username) user.username = data.username
    if (data.email) user.email = data.email
    if (data.displayName) user.displayName = data.displayName
    if (data.avatar) user.avatar = data.avatar
    if (data.phone) user.phone = data.phone
    if (data.department) user.department = data.department
    if (data.position) user.position = data.position
    if (data.role) user.role = data.role
    if (data.permissions) user.permissions = data.permissions
    if (data.isActive) user.isActive = data.isActive
    if (data.lastLoginAt) user.lastLoginAt = new Date(data.lastLoginAt)
    if (data.photoCount) user.photoCount = data.photoCount
    if (data.projectCount) user.projectCount = data.projectCount
    if (data.preferences) user.preferences = { ...user.preferences, ...data.preferences }
    if (data.settings) user.settings = data.settings

    return user
  }

  /**
   * 深度克隆对象
   */
  override clone(): User {
    const cloned = super.clone() as User
    cloned.lastLoginAt = new Date(this.lastLoginAt)
    cloned.permissions = [...this.permissions]
    cloned.preferences = { ...this.preferences }
    cloned.settings = { ...this.settings }
    return cloned
  }
}