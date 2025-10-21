/**
 * 相机权限管理器
 * 专门负责相机相关权限的检查、请求和管理
 */

import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { Logger } from '../../utils/Logger'
import { PermissionUtils, PermissionType } from '../../utils/PermissionUtils'

/**
 * 相机权限类型
 */
export enum CameraPermission {
  CAMERA = 'ohos.permission.CAMERA',
  MICROPHONE = 'ohos.permission.MICROPHONE',
  LOCATION = 'ohos.permission.APPROXIMATELY_LOCATION',
  STORAGE = 'ohos.permission.READ_MEDIA',
  STORAGE_WRITE = 'ohos.permission.WRITE_MEDIA'
}

/**
 * 权限请求结果
 */
export interface PermissionRequestResult {
  success: boolean
  grantedPermissions: CameraPermission[]
  deniedPermissions: CameraPermission[]
  permanentlyDenied: CameraPermission[]
  error?: string
}

/**
 * 权限状态枚举
 */
export enum PermissionStatus {
  GRANTED = 'granted',
  DENIED = 'denied',
  PERMANENTLY_DENIED = 'permanently_denied',
  NOT_DETERMINED = 'not_determined'
}

/**
 * 权限配置接口
 */
export interface PermissionConfig {
  requiredPermissions: CameraPermission[]
  optionalPermissions: CameraPermission[]
  showRationale: boolean
  rationalMessage?: string
  autoRequest: boolean
  forceRequest: boolean
}

/**
 * 权限监听器接口
 */
export interface PermissionListeners {
  onPermissionGranted?: (permissions: CameraPermission[]) => void
  onPermissionDenied?: (permissions: CameraPermission[], permanentlyDenied: CameraPermission[]) => void
  onPermissionRequestNeeded?: (permissions: CameraPermission[]) => Promise<boolean>
  onSettingsRedirectNeeded?: (permissions: CameraPermission[]) => void
}

/**
 * 相机权限管理器
 */
export class CameraPermissionManager {
  private static instance: CameraPermissionManager | null = null
  private logger = new Logger('CameraPermissionManager')
  private permissionUtils: PermissionUtils

  // 权限状态缓存
  private permissionCache: Map<CameraPermission, PermissionStatus> = new Map()
  private lastCheckTime: number = 0
  private readonly CACHE_DURATION = 5000 // 5秒缓存

  // 配置
  private config: PermissionConfig = {
    requiredPermissions: [
      CameraPermission.CAMERA,
      CameraPermission.STORAGE,
      CameraPermission.STORAGE_WRITE
    ],
    optionalPermissions: [
      CameraPermission.MICROPHONE,
      CameraPermission.LOCATION
    ],
    showRationale: true,
    rationalMessage: '应用需要相机权限来拍摄工程照片，需要存储权限来保存照片',
    autoRequest: true,
    forceRequest: false
  }

  // 监听器
  private listeners: PermissionListeners = {}

  private constructor() {
    this.permissionUtils = PermissionUtils.getInstance()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): CameraPermissionManager {
    if (!CameraPermissionManager.instance) {
      CameraPermissionManager.instance = new CameraPermissionManager()
    }
    return CameraPermissionManager.instance
  }

  /**
   * 设置权限配置
   */
  setConfiguration(config: Partial<PermissionConfig>): void {
    this.config = { ...this.config, ...config }
    this.logger.info('Permission configuration updated', this.config)
  }

  /**
   * 设置权限监听器
   */
  setListeners(listeners: PermissionListeners): void {
    this.listeners = { ...this.listeners, ...listeners }
  }

  /**
   * 检查所有必需权限
   */
  async checkRequiredPermissions(): Promise<boolean> {
    this.logger.info('Checking required permissions...')

    try {
      const statusMap = await this.checkPermissions(this.config.requiredPermissions)
      const allGranted = this.config.requiredPermissions.every(permission =>
        statusMap.get(permission) === PermissionStatus.GRANTED
      )

      this.logger.info('Required permissions check result', { allGranted, statusMap })
      return allGranted
    } catch (error) {
      this.logger.error('Failed to check required permissions', error)
      return false
    }
  }

  /**
   * 检查权限状态
   */
  async checkPermissions(permissions: CameraPermission[]): Promise<Map<CameraPermission, PermissionStatus>> {
    this.logger.info('Checking permission status...', { permissions })

    const statusMap = new Map<CameraPermission, PermissionStatus>()
    const now = Date.now()

    // 检查缓存
    const uncachedPermissions: CameraPermission[] = []
    for (const permission of permissions) {
      const cached = this.permissionCache.get(permission)
      if (cached && (now - this.lastCheckTime) < this.CACHE_DURATION) {
        statusMap.set(permission, cached)
      } else {
        uncachedPermissions.push(permission)
      }
    }

    // 检查未缓存的权限
    if (uncachedPermissions.length > 0) {
      try {
        const results = await this.queryPermissionStatus(uncachedPermissions)

        for (const [permission, status] of results) {
          statusMap.set(permission, status)
          this.permissionCache.set(permission, status)
        }

        this.lastCheckTime = now
      } catch (error) {
        this.logger.error('Failed to query permission status', error)
        // 设置默认状态
        for (const permission of uncachedPermissions) {
          statusMap.set(permission, PermissionStatus.NOT_DETERMINED)
        }
      }
    }

    return statusMap
  }

  /**
   * 查询权限状态
   */
  private async queryPermissionStatus(permissions: CameraPermission[]): Promise<Map<CameraPermission, PermissionStatus>> {
    const statusMap = new Map<CameraPermission, PermissionStatus>()

    try {
      // 获取应用信息
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
      const tokenID = bundleInfo.appInfo.accessTokenId

      const atManager = abilityAccessCtrl.createAtManager()

      for (const permission of permissions) {
        try {
          const grantStatus = await atManager.checkAccessToken(tokenID, permission)

          switch (grantStatus) {
            case abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED:
              statusMap.set(permission, PermissionStatus.GRANTED)
              break
            case abilityAccessCtrl.GrantStatus.PERMISSION_DENIED:
              // 需要进一步检查是否是永久拒绝
              const canRequest = await this.canRequestPermission(permission, tokenID, atManager)
              statusMap.set(permission, canRequest ? PermissionStatus.DENIED : PermissionStatus.PERMANENTLY_DENIED)
              break
            default:
              statusMap.set(permission, PermissionStatus.NOT_DETERMINED)
          }
        } catch (error) {
          this.logger.error(`Failed to check permission ${permission}`, error)
          statusMap.set(permission, PermissionStatus.NOT_DETERMINED)
        }
      }
    } catch (error) {
      this.logger.error('Failed to query permission status', error)
      throw error
    }

    return statusMap
  }

  /**
   * 检查是否可以请求权限
   */
  private async canRequestPermission(
    permission: CameraPermission,
    tokenID: number,
    atManager: abilityAccessCtrl.AtManager
  ): Promise<boolean> {
    try {
      // 检查权限是否可以被请求
      const permissionFlag = await atManager.getPermissionFlags(tokenID, permission)

      // 如果权限被永久拒绝，无法再次请求
      if (permissionFlag === abilityAccessCtrl.PermissionFlags.PERMISSION_DENIED_ALWAYS) {
        return false
      }

      return true
    } catch (error) {
      this.logger.error(`Failed to check if permission ${permission} can be requested`, error)
      return true // 默认返回true，允许尝试请求
    }
  }

  /**
   * 请求权限
   */
  async requestPermissions(
    permissions: CameraPermission[],
    context: common.UIAbilityContext
  ): Promise<PermissionRequestResult> {
    this.logger.info('Requesting permissions...', { permissions })

    const result: PermissionRequestResult = {
      success: false,
      grantedPermissions: [],
      deniedPermissions: [],
      permanentlyDenied: []
    }

    try {
      // 1. 检查当前权限状态
      const statusMap = await this.checkPermissions(permissions)
      const needToRequest: CameraPermission[] = []

      for (const permission of permissions) {
        const status = statusMap.get(permission)
        if (status === PermissionStatus.GRANTED) {
          result.grantedPermissions.push(permission)
        } else if (status === PermissionStatus.PERMANENTLY_DENIED) {
          result.permanentlyDenied.push(permission)
        } else {
          needToRequest.push(permission)
        }
      }

      // 2. 如果没有需要请求的权限，直接返回结果
      if (needToRequest.length === 0) {
        result.success = result.grantedPermissions.length === permissions.length
        this.logger.info('No permissions need to be requested', result)
        return result
      }

      // 3. 检查是否需要显示权限说明
      if (this.config.showRationale && this.listeners.onPermissionRequestNeeded) {
        const shouldContinue = await this.listeners.onPermissionRequestNeeded(needToRequest)
        if (!shouldContinue) {
          result.error = 'User cancelled permission request'
          return result
        }
      }

      // 4. 请求权限
      const requestResults = await this.performPermissionRequest(needToRequest, context)

      // 5. 处理请求结果
      for (let i = 0; i < needToRequest.length; i++) {
        const permission = needToRequest[i]
        const granted = requestResults[i]

        if (granted) {
          result.grantedPermissions.push(permission)
          this.permissionCache.set(permission, PermissionStatus.GRANTED)
        } else {
          // 检查是否是永久拒绝
          const canRequest = await this.canRequestPermissionAgain(permission)
          if (canRequest) {
            result.deniedPermissions.push(permission)
            this.permissionCache.set(permission, PermissionStatus.DENIED)
          } else {
            result.permanentlyDenied.push(permission)
            this.permissionCache.set(permission, PermissionStatus.PERMANENTLY_DENIED)
          }
        }
      }

      result.success = result.grantedPermissions.length === permissions.length

      // 6. 通知监听器
      if (result.grantedPermissions.length > 0) {
        this.notifyPermissionGranted(result.grantedPermissions)
      }

      if (result.deniedPermissions.length > 0 || result.permanentlyDenied.length > 0) {
        this.notifyPermissionDenied(result.deniedPermissions, result.permanentlyDenied)
      }

      this.logger.info('Permission request completed', result)
      return result

    } catch (error) {
      this.logger.error('Failed to request permissions', error)
      result.error = error instanceof Error ? error.message : String(error)
      return result
    }
  }

  /**
   * 执行权限请求
   */
  private async performPermissionRequest(
    permissions: CameraPermission[],
    context: common.UIAbilityContext
  ): Promise<boolean[]> {
    this.logger.info('Performing permission request...', { permissions })

    return new Promise((resolve) => {
      try {
        context.startAbilityForResult({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          parameters: {
            // 这里可能需要根据具体的权限请求方式调整
            permissions: permissions
          }
        }).then((result) => {
          // 解析权限请求结果
          // 这里需要根据实际的权限请求API来实现
          const granted = permissions.map(() => true) // 临时实现
          resolve(granted)
        }).catch((error) => {
          this.logger.error('Permission request failed', error)
          resolve(permissions.map(() => false))
        })
      } catch (error) {
        this.logger.error('Failed to start permission request', error)
        resolve(permissions.map(() => false))
      }
    })
  }

  /**
   * 检查权限是否可以再次请求
   */
  private async canRequestPermissionAgain(permission: CameraPermission): Promise<boolean> {
    try {
      // 重新检查权限状态
      const statusMap = await this.checkPermissions([permission])
      const status = statusMap.get(permission)

      return status !== PermissionStatus.PERMANENTLY_DENIED
    } catch (error) {
      this.logger.error(`Failed to check if permission ${permission} can be requested again`, error)
      return true
    }
  }

  /**
   * 请求所有必需权限
   */
  async requestRequiredPermissions(context: common.UIAbilityContext): Promise<PermissionRequestResult> {
    return this.requestPermissions(this.config.requiredPermissions, context)
  }

  /**
   * 请求可选权限
   */
  async requestOptionalPermissions(context: common.UIAbilityContext): Promise<PermissionRequestResult> {
    return this.requestPermissions(this.config.optionalPermissions, context)
  }

  /**
   * 请求所有权限
   */
  async requestAllPermissions(context: common.UIAbilityContext): Promise<PermissionRequestResult> {
    const allPermissions = [...this.config.requiredPermissions, ...this.config.optionalPermissions]
    return this.requestPermissions(allPermissions, context)
  }

  /**
   * 打开应用设置页面
   */
  async openAppSettings(context: common.UIAbilityContext): Promise<void> {
    this.logger.info('Opening app settings...')

    try {
      await context.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        parameters: {
          // 这里需要根据具体的设置页面跳转方式调整
          page: 'application_settings'
        }
      })

      this.logger.info('App settings opened successfully')
    } catch (error) {
      this.logger.error('Failed to open app settings', error)
      throw error
    }
  }

  /**
   * 获取权限状态描述
   */
  getPermissionStatusDescription(status: PermissionStatus): string {
    switch (status) {
      case PermissionStatus.GRANTED:
        return '已授权'
      case PermissionStatus.DENIED:
        return '未授权'
      case PermissionStatus.PERMANENTLY_DENIED:
        return '永久拒绝'
      case PermissionStatus.NOT_DETERMINED:
        return '未确定'
      default:
        return '未知状态'
    }
  }

  /**
   * 获取权限描述
   */
  getPermissionDescription(permission: CameraPermission): string {
    const descriptions: Record<CameraPermission, string> = {
      [CameraPermission.CAMERA]: '相机权限，用于拍摄工程照片',
      [CameraPermission.MICROPHONE]: '麦克风权限，用于录制视频时收录声音',
      [CameraPermission.LOCATION]: '位置权限，用于在照片中添加位置信息',
      [CameraPermission.STORAGE]: '存储权限，用于读取媒体文件',
      [CameraPermission.STORAGE_WRITE]: '存储权限，用于保存拍摄的照片'
    }

    return descriptions[permission] || '未知权限'
  }

  /**
   * 获取权限建议
   */
  getPermissionRecommendations(): {
    required: { permission: CameraPermission, description: string }[]
    optional: { permission: CameraPermission, description: string }[]
    issues: string[]
  } {
    const required = this.config.requiredPermissions.map(permission => ({
      permission,
      description: this.getPermissionDescription(permission)
    }))

    const optional = this.config.optionalPermissions.map(permission => ({
      permission,
      description: this.getPermissionDescription(permission)
    }))

    const issues: string[] = []

    // 检查权限配置的合理性
    if (this.config.requiredPermissions.length === 0) {
      issues.push('没有配置必需权限')
    }

    if (!this.config.requiredPermissions.includes(CameraPermission.CAMERA)) {
      issues.push('相机权限未设置为必需权限')
    }

    if (!this.config.requiredPermissions.includes(CameraPermission.STORAGE) &&
        !this.config.requiredPermissions.includes(CameraPermission.STORAGE_WRITE)) {
      issues.push('存储权限未设置为必需权限')
    }

    return { required, optional, issues }
  }

  /**
   * 通知权限已授权
   */
  private notifyPermissionGranted(permissions: CameraPermission[]): void {
    if (this.listeners.onPermissionGranted) {
      try {
        this.listeners.onPermissionGranted(permissions)
      } catch (error) {
        this.logger.error('Error in permission granted callback', error)
      }
    }
  }

  /**
   * 通知权限被拒绝
   */
  private notifyPermissionDenied(
    denied: CameraPermission[],
    permanentlyDenied: CameraPermission[]
  ): void {
    if (this.listeners.onPermissionDenied) {
      try {
        this.listeners.onPermissionDenied(denied, permanentlyDenied)
      } catch (error) {
        this.logger.error('Error in permission denied callback', error)
      }
    }

    // 如果有永久拒绝的权限，通知需要跳转到设置
    if (permanentlyDenied.length > 0 && this.listeners.onSettingsRedirectNeeded) {
      try {
        this.listeners.onSettingsRedirectNeeded(permanentlyDenied)
      } catch (error) {
        this.logger.error('Error in settings redirect callback', error)
      }
    }
  }

  /**
   * 清除权限缓存
   */
  clearPermissionCache(): void {
    this.permissionCache.clear()
    this.lastCheckTime = 0
    this.logger.info('Permission cache cleared')
  }

  /**
   * 获取权限统计信息
   */
  getPermissionStats(): {
    requiredCount: number
    optionalCount: number
    cacheSize: number
    lastCheckTime: number
  } {
    return {
      requiredCount: this.config.requiredPermissions.length,
      optionalCount: this.config.optionalPermissions.length,
      cacheSize: this.permissionCache.size,
      lastCheckTime: this.lastCheckTime
    }
  }

  /**
   * 检查权限完整性
   */
  async validatePermissions(): Promise<{
    isComplete: boolean
    missingRequired: CameraPermission[]
    missingOptional: CameraPermission[]
    recommendations: string[]
  }> {
    const statusMap = await this.checkPermissions([
      ...this.config.requiredPermissions,
      ...this.config.optionalPermissions
    ])

    const missingRequired: CameraPermission[] = []
    const missingOptional: CameraPermission[] = []

    for (const permission of this.config.requiredPermissions) {
      if (statusMap.get(permission) !== PermissionStatus.GRANTED) {
        missingRequired.push(permission)
      }
    }

    for (const permission of this.config.optionalPermissions) {
      if (statusMap.get(permission) !== PermissionStatus.GRANTED) {
        missingOptional.push(permission)
      }
    }

    const recommendations: string[] = []

    if (missingRequired.length > 0) {
      recommendations.push(`需要请求必需权限: ${missingRequired.map(p => this.getPermissionDescription(p)).join(', ')}`)
    }

    if (missingOptional.length > 0) {
      recommendations.push(`建议请求可选权限: ${missingOptional.map(p => this.getPermissionDescription(p)).join(', ')}`)
    }

    return {
      isComplete: missingRequired.length === 0,
      missingRequired,
      missingOptional,
      recommendations
    }
  }
}