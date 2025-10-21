/**
 * 权限工具类
 * 提供文件权限检查和请求功能
 */

import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Logger } from './Logger'

/**
 * 权限类型
 */
export enum PermissionType {
  READ_MEDIA = 'ohos.permission.READ_MEDIA',
  WRITE_MEDIA = 'ohos.permission.WRITE_MEDIA',
  READ_WRITE_IMAGES = 'ohos.permission.READ_WRITE_IMAGES',
  READ_WRITE_VIDEO = 'ohos.permission.READ_WRITE_VIDEO'
}

/**
 * 权限检查结果
 */
export interface PermissionResult {
  granted: boolean
  canRequest: boolean
  reason?: string
}

export class PermissionUtils {
  private static instance: PermissionUtils | null = null
  private logger = new Logger('PermissionUtils')
  private atManager: abilityAccessCtrl.AtManager | null = null

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): PermissionUtils {
    if (!PermissionUtils.instance) {
      PermissionUtils.instance = new PermissionUtils()
    }
    return PermissionUtils.instance
  }

  /**
   * 初始化权限管理器
   */
  async initialize(): Promise<void> {
    try {
      this.atManager = abilityAccessCtrl.createAtManager()
      this.logger.info('PermissionUtils initialized')
    } catch (error) {
      this.logger.error('Failed to initialize PermissionUtils', error)
      throw error
    }
  }

  /**
   * 检查单个权限
   */
  async checkPermission(permission: PermissionType): Promise<PermissionResult> {
    if (!this.atManager) {
      await this.initialize()
    }

    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
      const tokenID = bundleInfo.appInfo.accessTokenId

      const grantStatus = await this.atManager!.checkAccessToken(tokenID, permission)
      const granted = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED

      this.logger.info('Permission check result', {
        permission,
        granted,
        grantStatus
      })

      return {
        granted,
        canRequest: true // 在HarmonyOS中，通常可以请求权限
      }
    } catch (error) {
      this.logger.error('Failed to check permission', { permission, error })
      return {
        granted: false,
        canRequest: false,
        reason: `权限检查失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 检查多个权限
   */
  async checkPermissions(permissions: PermissionType[]): Promise<Record<PermissionType, PermissionResult>> {
    const results: Record<string, PermissionResult> = {}

    for (const permission of permissions) {
      results[permission] = await this.checkPermission(permission)
    }

    this.logger.info('Multiple permissions check completed', {
      permissions,
      grantedCount: Object.values(results).filter(r => r.granted).length,
      totalCount: permissions.length
    })

    return results as Record<PermissionType, PermissionResult>
  }

  /**
   * 请求权限
   */
  async requestPermissions(permissions: PermissionType[]): Promise<Record<PermissionType, boolean>> {
    if (!this.atManager) {
      await this.initialize()
    }

    try {
      this.logger.info('Requesting permissions', { permissions })

      // 在实际应用中，这里需要使用UI组件来请求权限
      // 由于这是服务类，我们只检查权限状态
      const results = await this.checkPermissions(permissions)

      const grantedResults: Record<string, boolean> = {}
      for (const [permission, result] of Object.entries(results)) {
        grantedResults[permission] = result.granted
      }

      return grantedResults as Record<PermissionType, boolean>
    } catch (error) {
      this.logger.error('Failed to request permissions', { permissions, error })

      // 返回所有权限都未授权
      const failedResults: Record<string, boolean> = {}
      for (const permission of permissions) {
        failedResults[permission] = false
      }
      return failedResults as Record<PermissionType, boolean>
    }
  }

  /**
   * 检查文件读写权限
   */
  async checkFilePermissions(): Promise<{
    canRead: boolean
    canWrite: boolean
    details: Record<PermissionType, PermissionResult>
  }> {
    const filePermissions = [
      PermissionType.READ_MEDIA,
      PermissionType.WRITE_MEDIA,
      PermissionType.READ_WRITE_IMAGES
    ]

    const results = await this.checkPermissions(filePermissions)

    const canRead = results[PermissionType.READ_MEDIA]?.granted ||
                   results[PermissionType.READ_WRITE_IMAGES]?.granted

    const canWrite = results[PermissionType.WRITE_MEDIA]?.granted ||
                    results[PermissionType.READ_WRITE_IMAGES]?.granted

    this.logger.info('File permissions check completed', {
      canRead,
      canWrite,
      results
    })

    return {
      canRead,
      canWrite,
      details: results
    }
  }

  /**
   * 获取权限状态描述
   */
  getPermissionStatusText(result: PermissionResult): string {
    if (result.granted) {
      return '已授权'
    }

    if (!result.canRequest) {
      return `无法请求权限: ${result.reason || '未知原因'}`
    }

    return '未授权，可以请求'
  }

  /**
   * 检查应用是否有必要的权限
   */
  async hasNecessaryPermissions(): Promise<boolean> {
    try {
      const filePerms = await this.checkFilePermissions()
      return filePerms.canRead && filePerms.canWrite
    } catch (error) {
      this.logger.error('Failed to check necessary permissions', error)
      return false
    }
  }

  /**
   * 获取权限建议
   */
  async getPermissionRecommendations(): Promise<{
    needed: PermissionType[]
    optional: PermissionType[]
    issues: string[]
  }> {
    const needed: PermissionType[] = []
    const optional: PermissionType[] = []
    const issues: string[] = []

    try {
      // 检查基本文件权限
      const basicPermissions = [
        PermissionType.READ_MEDIA,
        PermissionType.WRITE_MEDIA
      ]

      const results = await this.checkPermissions(basicPermissions)

      for (const [permission, result] of Object.entries(results)) {
        if (!result.granted) {
          needed.push(permission as PermissionType)

          if (!result.canRequest) {
            issues.push(`权限 ${permission} 无法请求: ${result.reason}`)
          }
        }
      }

      // 检查可选权限
      const optionalPermissions = [
        PermissionType.READ_WRITE_IMAGES,
        PermissionType.READ_WRITE_VIDEO
      ]

      const optionalResults = await this.checkPermissions(optionalPermissions)

      for (const [permission, result] of Object.entries(optionalResults)) {
        if (!result.granted && result.canRequest) {
          optional.push(permission as PermissionType)
        }
      }

    } catch (error) {
      this.logger.error('Failed to get permission recommendations', error)
      issues.push(`权限检查失败: ${error instanceof Error ? error.message : String(error)}`)
    }

    return {
      needed,
      optional,
      issues
    }
  }

  /**
   * 验证文件操作权限
   */
  async validateFileOperation(operation: 'read' | 'write' | 'delete'): Promise<{
    allowed: boolean
    reason?: string
  }> {
    try {
      const filePerms = await this.checkFilePermissions()

      switch (operation) {
        case 'read':
          if (!filePerms.canRead) {
            return {
              allowed: false,
              reason: '应用没有读取媒体文件的权限'
            }
          }
          break

        case 'write':
          if (!filePerms.canWrite) {
            return {
              allowed: false,
              reason: '应用没有写入媒体文件的权限'
            }
          }
          break

        case 'delete':
          if (!filePerms.canWrite) {
            return {
              allowed: false,
              reason: '应用没有删除媒体文件的权限（需要写入权限）'
            }
          }
          break
      }

      return { allowed: true }
    } catch (error) {
      this.logger.error('Failed to validate file operation', { operation, error })
      return {
        allowed: false,
        reason: `权限验证失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 权限状态变更监听器
   */
  private permissionListeners: Array<(permissions: PermissionType[], granted: boolean) => void> = []

  /**
   * 添加权限状态监听器
   */
  addPermissionListener(listener: (permissions: PermissionType[], granted: boolean) => void): void {
    this.permissionListeners.push(listener)
  }

  /**
   * 移除权限状态监听器
   */
  removePermissionListener(listener: (permissions: PermissionType[], granted: boolean) => void): void {
    const index = this.permissionListeners.indexOf(listener)
    if (index > -1) {
      this.permissionListeners.splice(index, 1)
    }
  }

  /**
   * 通知权限状态变更
   */
  private notifyPermissionChange(permissions: PermissionType[], granted: boolean): void {
    for (const listener of this.permissionListeners) {
      try {
        listener(permissions, granted)
      } catch (error) {
        this.logger.error('Permission listener error', error)
      }
    }
  }

  /**
   * 获取权限使用说明
   */
  getPermissionDescription(permission: PermissionType): string {
    const descriptions: Record<PermissionType, string> = {
      [PermissionType.READ_MEDIA]: '读取媒体文件权限，用于访问照片、视频等媒体内容',
      [PermissionType.WRITE_MEDIA]: '写入媒体文件权限，用于保存、修改媒体文件',
      [PermissionType.READ_WRITE_IMAGES]: '图片读写权限，用于访问和保存图片文件',
      [PermissionType.READ_WRITE_VIDEO]: '视频读写权限，用于访问和保存视频文件'
    }

    return descriptions[permission] || '未知权限'
  }

  /**
   * 获取应用权限使用情况统计
   */
  async getPermissionUsageStats(): Promise<{
    totalPermissions: number
    grantedPermissions: number
    deniedPermissions: number
    permissionHealth: 'good' | 'warning' | 'critical'
  }> {
    try {
      const allPermissions = Object.values(PermissionType)
      const results = await this.checkPermissions(allPermissions)

      const granted = Object.values(results).filter(r => r.granted).length
      const denied = allPermissions.length - granted

      let health: 'good' | 'warning' | 'critical' = 'good'
      if (denied > allPermissions.length * 0.5) {
        health = 'critical'
      } else if (denied > 0) {
        health = 'warning'
      }

      return {
        totalPermissions: allPermissions.length,
        grantedPermissions: granted,
        deniedPermissions: denied,
        permissionHealth: health
      }
    } catch (error) {
      this.logger.error('Failed to get permission usage stats', error)
      return {
        totalPermissions: 0,
        grantedPermissions: 0,
        deniedPermissions: 0,
        permissionHealth: 'critical'
      }
    }
  }
}