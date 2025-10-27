/**
 * 权限错误处理组件
 * 专门处理权限相关的错误和状态
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { Permissions } from '@ohos.permission'

export interface PermissionErrorConfig {
  permission?: string
  permissions?: string[]
  onGrant?: () => void
  onSettings?: () => void
  onRetry?: () => void
  customMessage?: string
  showRationale?: boolean
}

export enum PermissionType {
  CAMERA = 'ohos.permission.CAMERA',
  MICROPHONE = 'ohos.permission.MICROPHONE',
  LOCATION = 'ohos.permission.APPROXIMATELY_LOCATION',
  STORAGE = 'ohos.permission.READ_WRITE_IMAGES',
  NOTIFICATION = 'ohos.permission.NOTIFICATION_CONTROLLER'
}

export interface PermissionInfo {
  type: PermissionType
  name: string
  description: string
  icon: string
  rationale: string
  dangerous: boolean
}

@ComponentV2
export struct PermissionError {
  @Param config?: PermissionErrorConfig = {}
  @State private permissionInfo?: PermissionInfo
  @State private isCheckingPermission: boolean = false

  private readonly permissionMap: Map<PermissionType, PermissionInfo> = new Map([
    [PermissionType.CAMERA, {
      type: PermissionType.CAMERA,
      name: '相机权限',
      description: '需要相机权限来拍摄工程照片',
      icon: '📷',
      rationale: '相机功能需要访问您的设备相机，用于拍摄工程现场照片。我们承诺仅用于工程管理相关的拍摄，不会存储或分享您的私人信息。',
      dangerous: true
    }],
    [PermissionType.MICROPHONE, {
      type: PermissionType.MICROPHONE,
      name: '麦克风权限',
      description: '需要麦克风权限来录制工程解说',
      icon: '🎤',
      rationale: '录制工程解说功能需要访问您的设备麦克风，用于添加语音说明。我们不会在您不知情的情况下录制音频。',
      dangerous: true
    }],
    [PermissionType.LOCATION, {
      type: PermissionType.LOCATION,
      name: '位置权限',
      description: '需要位置权限来记录工程位置',
      icon: '📍',
      rationale: '位置功能需要获取您的设备位置，用于记录工点的地理位置信息。这将帮助您更好地管理和追踪工程项目位置。',
      dangerous: true
    }],
    [PermissionType.STORAGE, {
      type: PermissionType.STORAGE,
      name: '存储权限',
      description: '需要存储权限来保存和管理照片',
      icon: '💾',
      rationale: '存储功能��要访问您的设备存储，用于保存工程照片和相关文件。我们将按照您的隐私设置安全地管理这些文件。',
      dangerous: true
    }],
    [PermissionType.NOTIFICATION, {
      type: PermissionType.NOTIFICATION,
      name: '通知权限',
      description: '需要通知权限来发送工程提醒',
      icon: '🔔',
      rationale: '通知功能需要发送系统通知，用于提醒您重要的工程事件和任务。您可以随时在设置中管理通知偏好。',
      dangerous: false
    }]
  ])

  aboutToAppear() {
    this.analyzePermission()
  }

  /**
   * 分析权限类型
   */
  private analyzePermission(): void {
    const permission = this.config?.permission
    const permissions = this.config?.permissions

    if (permission) {
      this.permissionInfo = this.permissionMap.get(permission as PermissionType)
    } else if (permissions && permissions.length > 0) {
      // 处理多个权限的情况
      this.permissionInfo = {
        type: PermissionType.CAMERA,
        name: '多个权限',
        description: '需要多个权限来完整使用应用功能',
        icon: '🔐',
        rationale: '此功能需要多个权限配合使用，请按照提示逐一授权。',
        dangerous: true
      }
    } else {
      // 默认权限信息
      this.permissionInfo = {
        type: PermissionType.CAMERA,
        name: '应用权限',
        description: '需要相关权限来正常使用应用功能',
        icon: '🔐',
        rationale: '请授予必要的权限，以便我们为您提供完整的工程管理服务。',
        dangerous: true
      }
    }
  }

  /**
   * 检查权限状态
   */
  private async checkPermissionStatus(): Promise<void> {
    if (!this.permissionInfo) return

    this.isCheckingPermission = true

    try {
      // 这里应该使用实际的权限检查API
      // const status = await Permissions.checkPermission(this.permissionInfo.type)
      // handle permission status

      // 模拟权限检查
      await new Promise(resolve => setTimeout(resolve, 1000))
    } catch (error) {
      console.error('Permission check failed:', error)
    } finally {
      this.isCheckingPermission = false
    }
  }

  /**
   * 请求权限
   */
  private async requestPermission(): Promise<void> {
    if (!this.permissionInfo) return

    try {
      // 这里应该使用实际的权限请求API
      // await Permissions.requestPermission(this.permissionInfo.type)

      // 模拟权限请求
      await new Promise(resolve => setTimeout(resolve, 1500))
      this.config?.onGrant?.()
    } catch (error) {
      console.error('Permission request failed:', error)
    }
  }

  /**
   * 跳转到设置
   */
  private openSettings(): void {
    // 这里应该跳转到应用设置页面
    this.config?.onSettings?.()
  }

  /**
   * 权限图标和信息
   */
  @Builder
  private PermissionInfoSection() {
    Column({ space: 16 }) {
      // 权限图标
      Text(this.permissionInfo?.icon || '🔐')
        .fontSize(64)
        .textAlign(TextAlign.Center)

      // 权限名称
      Text(this.permissionInfo?.name || '权限要求')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      // 权限描述
      Text(this.config?.customMessage || this.permissionInfo?.description || '需要相关权限')
        .fontSize(16)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })

      // 权限说明
      if (this.config?.showRationale && this.permissionInfo?.rationale) {
        Column({ space: 8 }) {
          Text('权限说明')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)

          Text(this.permissionInfo.rationale)
            .fontSize(12)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .lineHeight(18)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .margin({ top: 16 })
      }
    }
    .alignItems(HorizontalAlign.Center)
    .padding(20)
  }

  /**
   * 操作按钮区域
   */
  @Builder
  private ActionButtons() {
    Column({ space: 12 }) {
      // 授权按钮
      if (this.config?.onGrant) {
        Button() {
          Row({ space: 8 }) {
            if (this.isCheckingPermission) {
              LoadingProgress()
                .width(16)
                .height(16)
                .color('#FFFFFF')
            } else {
              Text('✓')
                .fontSize(16)
            }
            Text(this.isCheckingPermission ? '检查中...' : '授予权限')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
        }
        .height(48)
        .width('100%')
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(24)
        .fontColor('#FFFFFF')
        .enabled(!this.isCheckingPermission)
        .onClick(() => {
          if (this.config.onRetry) {
            this.config.onRetry()
          } else {
            this.requestPermission()
          }
        })
      }

      // 设置按钮
      if (this.config?.onSettings) {
        Button('前往设置')
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
          .borderRadius(22)
          .width('100%')
          .onClick(() => this.openSettings())
      }

      // 重试按钮
      if (this.config?.onRetry && !this.config?.onGrant) {
        Button('重新检查')
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(22)
          .width('100%')
          .onClick(() => this.checkPermissionStatus())
      }
    }
    .width('100%')
    .margin({ top: 16 })
  }

  build() {
    Column({ space: 24 }) {
      this.PermissionInfoSection()
      this.ActionButtons()
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#00000015',
      offsetX: 0,
      offsetY: 4
    })
    .margin(16)
  }
}