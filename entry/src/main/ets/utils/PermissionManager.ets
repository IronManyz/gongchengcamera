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

      try {
        const atManager = abilityAccessCtrl.createAtManager()
        console.log('Access control manager created:', !!atManager)

        const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        console.log('Bundle info retrieved:', !!bundleInfo)
        console.log('Bundle info:', bundleInfo.appInfo)

        const tokenId = bundleInfo.appInfo.accessTokenId
        console.log('Token ID:', tokenId)

        const permissionStatus = await atManager.checkAccessToken(tokenId, 'ohos.permission.CAMERA')
        console.log('Camera permission status:', permissionStatus)
        console.log('Permission granted status:', abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)

        if (permissionStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          console.log('Camera permission is GRANTED')
          return {
            status: PermissionStatus.GRANTED,
            message: '相机权限已授权'
          }
        } else {
          console.log('Camera permission is DENIED or NOT_DETERMINED')
          console.log('Actual status value:', permissionStatus)
          return {
            status: PermissionStatus.NOT_DETERMINED,
            message: '相机权限未授权'
          }
        }
      } catch (checkError) {
        console.error('Permission check operation failed:', checkError)
        throw new Error(`权限检查操作失败: ${checkError}`)
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
   * 申请相机权限（包括相机和存储权限）
   */
  async requestCameraPermission(context: common.UIAbilityContext): Promise<PermissionResult> {
    try {
      console.log('=== PermissionManager.requestCameraPermission() ===')

      // 先检查权限状态
      const checkResult = await this.checkCameraPermission(context)
      console.log('Current permission status:', checkResult.status)

      if (checkResult.status === PermissionStatus.GRANTED) {
        console.log('Camera permission already granted')
        return checkResult
      }

      console.log('Camera permission not granted, requesting from user...')

      const atManager = abilityAccessCtrl.createAtManager()
      console.log('Permission manager created:', !!atManager)

      // 请求相机、存储和位置权限
      const permissions: Array<Permissions> = [
        'ohos.permission.CAMERA',
        'ohos.permission.READ_MEDIA',
        'ohos.permission.WRITE_MEDIA',
        'ohos.permission.APPROXIMATELY_LOCATION'
      ]
      console.log('Requesting permissions:', permissions)

      try {
        const result = await atManager.requestPermissionsFromUser(context, permissions)
        console.log('Permission request completed')
        console.log('Request result:', result)
        console.log('Permissions requested:', result.permissions)
        console.log('Auth results:', result.authResults)

        // 检查相机权限是否被授予
        const cameraIndex = result.permissions.indexOf('ohos.permission.CAMERA')
        const cameraGranted = cameraIndex >= 0 && 
                             result.authResults[cameraIndex] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        
        // 检查存储权限是否被授予
        const readMediaIndex = result.permissions.indexOf('ohos.permission.READ_MEDIA')
        const writeMediaIndex = result.permissions.indexOf('ohos.permission.WRITE_MEDIA')
        const storageGranted = (readMediaIndex >= 0 && 
                               result.authResults[readMediaIndex] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) ||
                              (writeMediaIndex >= 0 && 
                               result.authResults[writeMediaIndex] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)

        if (cameraGranted && storageGranted) {
          console.log('Camera and storage permissions granted successfully')
          return {
            status: PermissionStatus.GRANTED,
            message: '相机权限授权成功'
          }
        } else if (!cameraGranted) {
          console.log('Camera permission denied')
          return {
            status: PermissionStatus.DENIED,
            message: '相机权限被拒绝'
          }
        } else {
          console.log('Storage permission denied')
          return {
            status: PermissionStatus.DENIED,
            message: '存储权限被拒绝，无法保存照片'
          }
        }
      } catch (requestError) {
        console.error('Permission request failed:', requestError)
        throw new Error(`权限请求失败: ${requestError}`)
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
      
      // 打开应用详情设置页面
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      const bundleName = bundleInfo.name
      
      await context.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: `application_info_entry://application_info_entry?bundleName=${bundleName}`,
        parameters: {
          pushParams: bundleName
        }
      })
      
      console.log('App settings opened successfully')
    } catch (error) {
      const err = error as BusinessError
      console.error('Open app settings failed:', err.code, err.message)
      
      // 如果上面的方法失败，尝试使用通用设置页面
      try {
        await context.startAbility({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility'
        })
        console.log('General settings opened successfully')
      } catch (fallbackError) {
        console.error('Fallback open settings failed:', fallbackError)
      }
    }
  }
}