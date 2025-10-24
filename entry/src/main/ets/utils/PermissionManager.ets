/**
 * 权限管理工具类
 * 处理应用权限的申请、检查和管理
 */

import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'

/**
 * 权限状态枚举
 */
export enum PermissionStatus {
  GRANTED = 'granted',           // 已授权
  DENIED = 'denied',             // 已拒绝
  NOT_DETERMINED = 'not_determined' // 未确定
}

/**
 * 权限结果接口
 */
export interface PermissionResult {
  status: PermissionStatus
  message?: string
}

/**
 * 权限管理器
 */
export class PermissionManager {
  private static instance: PermissionManager | null = null

  /**
   * 获取单例实例
   */
  static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager()
    }
    return PermissionManager.instance
  }

  /**
   * 检查相机权限状态
   */
  async checkCameraPermission(context: common.UIAbilityContext): Promise<PermissionResult> {
    try {
      console.log('=== PermissionManager.checkCameraPermission() ===')

      const atManager = abilityAccessCtrl.createAtManager()
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const tokenId = bundleInfo.appInfo.accessTokenId

      const permissionStatus = await atManager.checkAccessToken(tokenId, 'ohos.permission.CAMERA')
      console.log('Camera permission status:', permissionStatus)

      if (permissionStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.log('Camera permission is GRANTED')
        return {
          status: PermissionStatus.GRANTED,
          message: '相机权限已授权'
        }
      } else {
        console.log('Camera permission is DENIED or NOT_DETERMINED')
        return {
          status: PermissionStatus.NOT_DETERMINED,
          message: '相机权限未授权'
        }
      }
    } catch (error) {
      const err = error as BusinessError
      console.error('Check camera permission failed:', err.code, err.message)
      return {
        status: PermissionStatus.DENIED,
        message: `权限检查失败: ${err.message}`
      }
    }
  }

  /**
   * 申请相机权限
   */
  async requestCameraPermission(context: common.UIAbilityContext): Promise<PermissionResult> {
    try {
      console.log('=== PermissionManager.requestCameraPermission() ===')

      // 先检查权限状态
      const checkResult = await this.checkCameraPermission(context)
      if (checkResult.status === PermissionStatus.GRANTED) {
        return checkResult
      }

      const atManager = abilityAccessCtrl.createAtManager()
      const permissions: Array<Permissions> = ['ohos.permission.CAMERA']

      console.log('Requesting camera permission...')

      const result = await atManager.requestPermissionsFromUser(context, permissions)
      console.log('Permission request result:', result)

      if (result.permissions.length > 0 && result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.log('Camera permission granted successfully')
        return {
          status: PermissionStatus.GRANTED,
          message: '相机权限授权成功'
        }
      } else {
        console.log('Camera permission denied')
        return {
          status: PermissionStatus.DENIED,
          message: '相机权限被拒绝'
        }
      }
    } catch (error) {
      const err = error as BusinessError
      console.error('Request camera permission failed:', err.code, err.message)
      return {
        status: PermissionStatus.DENIED,
        message: `权限申请失败: ${err.message}`
      }
    }
  }

  /**
   * 检查并申���相机权限（如果需要）
   */
  async ensureCameraPermission(context: common.UIAbilityContext): Promise<PermissionResult> {
    console.log('=== PermissionManager.ensureCameraPermission() ===')

    const checkResult = await this.checkCameraPermission(context)

    if (checkResult.status === PermissionStatus.GRANTED) {
      console.log('Camera permission already granted')
      return checkResult
    }

    console.log('Camera permission not granted, requesting...')
    return await this.requestCameraPermission(context)
  }

  /**
   * 显示权限说明对话框（用于引导用户到设置中开启权限）
   */
  showPermissionDeniedDialog(): void {
    console.log('=== PermissionManager.showPermissionDeniedDialog() ===')
    // TODO: 实现权限说明对话框
    // 可以显示一个对话框，说明权限用途，并提供"去设置"按钮
    console.log('Please enable camera permission in system settings')
  }

  /**
   * 打开应用设置页面
   */
  async openAppSettings(context: common.UIAbilityContext): Promise<void> {
    try {
      console.log('=== PermissionManager.openAppSettings() ===')
      // TODO: 实现打开应用设置页面的逻辑
      // 在实际应用中，可能需要使用特定的API来打开设置页面
      console.log('Opening app settings...')
    } catch (error) {
      const err = error as BusinessError
      console.error('Open app settings failed:', err.code, err.message)
    }
  }
}