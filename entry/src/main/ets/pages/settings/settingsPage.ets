/**
 * 设置主页面
 * 提供应用设置主界面，包括设置项分类、导航和状态持久化
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { ThemeStore } from '../../store/theme/ThemeStore'
import { UserStore } from '../../store/user/UserStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 设置项接口
 */
interface SettingsItem {
  id: string
  title: string
  subtitle?: string
  icon?: Resource
  type: 'navigation' | 'switch' | 'action' | 'info'
  value?: any
  action?: () => void
  page?: string
}

/**
 * 设置分组接口
 */
interface SettingsGroup {
  title: string
  items: SettingsItem[]
}

@Entry
@Component
struct SettingsPage {
  private logger = new Logger('SettingsPage')
  private themeStore = ThemeStore.getInstance()
  private userStore = UserStore.getInstance()

  // 状态管理
  @State private isLoading: boolean = false
  @State private settingsGroups: SettingsGroup[] = []
  @State private showAboutDialog: boolean = false
  @State private showResetDialog: boolean = false

  aboutToAppear() {
    this.logger.info('SettingsPage appeared')
    this.initializeSettings()
  }

  aboutToDisappear() {
    this.logger.info('SettingsPage disappeared')
  }

  /**
   * 初始化设置项
   */
  private async initializeSettings() {
    this.isLoading = true
    try {
      await this.loadSettingsData()
    } catch (error) {
      this.logger.error('初始化设置失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 加载设置数据
   */
  private async loadSettingsData() {
    this.settingsGroups = [
      {
        title: '通用设置',
        items: [
          {
            id: 'theme',
            title: '主题设置',
            subtitle: this.getThemeText(this.themeStore.currentTheme),
            icon: $r('app.media.ic_theme'),
            type: 'navigation',
            page: 'pages/settings/ThemePage'
          },
          {
            id: 'language',
            title: '语言设置',
            subtitle: '简体中文',
            icon: $r('app.media.ic_language'),
            type: 'navigation',
            page: 'pages/settings/LanguagePage'
          },
          {
            id: 'notification',
            title: '通知设置',
            subtitle: '管理应用通知',
            icon: $r('app.media.ic_notification'),
            type: 'navigation',
            page: 'pages/settings/NotificationPage'
          }
        ]
      },
      {
        title: '相机设置',
        items: [
          {
            id: 'camera_quality',
            title: '照片质量',
            subtitle: '高质量',
            icon: $r('app.media.ic_camera'),
            type: 'navigation',
            page: 'pages/settings/CameraSettingsPage'
          },
          {
            id: 'watermark',
            title: '水印设置',
            subtitle: '配置默认水印',
            icon: $r('app.media.ic_watermark'),
            type: 'navigation',
            page: 'pages/settings/WatermarkSettingsPage'
          },
          {
            id: 'location',
            title: '位置服务',
            subtitle: '自动记录位置信息',
            icon: $r('app.media.ic_location'),
            type: 'switch',
            value: true,
            action: () => this.toggleLocationService()
          }
        ]
      },
      {
        title: '数据管理',
        items: [
          {
            id: 'database',
            title: '数据库管理',
            subtitle: '管理项目、照片数据',
            icon: $r('app.media.ic_database'),
            type: 'navigation',
            page: 'pages/settings/DatabasePage'
          },
          {
            id: 'backup',
            title: '备份管理',
            subtitle: '数据备份与恢复',
            icon: $r('app.media.ic_backup'),
            type: 'navigation',
            page: 'pages/settings/BackupPage'
          },
          {
            id: 'storage',
            title: '存储空间',
            subtitle: '查看存储使用情况',
            icon: $r('app.media.ic_storage'),
            type: 'navigation',
            page: 'pages/settings/StoragePage'
          }
        ]
      },
      {
        title: '隐私与安全',
        items: [
          {
            id: 'privacy',
            title: '隐私设置',
            subtitle: '管理数据权限',
            icon: $r('app.media.ic_privacy'),
            type: 'navigation',
            page: 'pages/settings/PrivacyPage'
          },
          {
            id: 'security',
            title: '安全设置',
            subtitle: '应用安全配置',
            icon: $r('app.media.ic_security'),
            type: 'navigation',
            page: 'pages/settings/SecurityPage'
          },
          {
            id: 'biometric',
            title: '生物识别',
            subtitle: '指纹、面部识别',
            icon: $r('app.media.ic_biometric'),
            type: 'switch',
            value: false,
            action: () => this.toggleBiometric()
          }
        ]
      },
      {
        title: '关于应用',
        items: [
          {
            id: 'about',
            title: '关于应用',
            subtitle: '版本信息和帮助',
            icon: $r('app.media.ic_about'),
            type: 'action',
            action: () => this.showAboutDialog = true
          },
          {
            id: 'feedback',
            title: '意见反馈',
            subtitle: '提交问题和建议',
            icon: $r('app.media.ic_feedback'),
            type: 'navigation',
            page: 'pages/settings/FeedbackPage'
          },
          {
            id: 'help',
            title: '帮助中心',
            subtitle: '使用指南和常见问题',
            icon: $r('app.media.ic_help'),
            type: 'navigation',
            page: 'pages/settings/HelpPage'
          }
        ]
      },
      {
        title: '高级设置',
        items: [
          {
            id: 'developer',
            title: '开发者选项',
            subtitle: '调试和开发工具',
            icon: $r('app.media.ic_developer'),
            type: 'navigation',
            page: 'pages/settings/DeveloperPage'
          },
          {
            id: 'reset',
            title: '重置设置',
            subtitle: '恢复默认设置',
            icon: $r('app.media.ic_reset'),
            type: 'action',
            action: () => this.showResetDialog = true
          }
        ]
      }
    ]
  }

  /**
   * 获取���题文本
   */
  private getThemeText(theme: any): string {
    switch (theme) {
      case 'light':
        return '浅色主题'
      case 'dark':
        return '深色主题'
      case 'system':
        return '跟随系统'
      default:
        return '跟随系统'
    }
  }

  /**
   * 切换位置服务
   */
  private async toggleLocationService() {
    try {
      // 实现位置服务切换逻辑
      this.logger.info('切换位置服务')
    } catch (error) {
      this.logger.error('切换位置服务失败', error)
    }
  }

  /**
   * 切换生物识别
   */
  private async toggleBiometric() {
    try {
      // 实现生物识别切换逻辑
      this.logger.info('切换生物识别')
    } catch (error) {
      this.logger.error('切换生物识别失败', error)
    }
  }

  /**
   * 重置设置
   */
  private async resetSettings() {
    try {
      // 实现设置重置逻辑
      this.logger.info('重置设置')
      this.showResetDialog = false
    } catch (error) {
      this.logger.error('重置设置失败', error)
    }
  }

  /**
   * 导航到设置页面
   */
  private navigateToSettingsPage(page: string, item: SettingsItem) {
    router.pushUrl({
      url: page,
      params: {
        settingsId: item.id,
        settingsTitle: item.title
      }
    })
  }

  /**
   * 处理设置项点击
   */
  private handleSettingsItemClick(item: SettingsItem) {
    switch (item.type) {
      case 'navigation':
        if (item.page) {
          this.navigateToSettingsPage(item.page, item)
        }
        break
      case 'action':
        if (item.action) {
          item.action()
        }
        break
      case 'switch':
        // 切换开关状态
        if (item.action) {
          item.action()
        }
        break
      case 'info':
        // 显示信息
        break
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 设置列表
      this.buildSettingsList()

      // 关于对话框
      if (this.showAboutDialog) {
        this.buildAboutDialog()
      }

      // 重置确认对话框
      if (this.showResetDialog) {
        ConfirmDialog({
          title: '重置设置',
          message: '确定要重置所有设置吗？此操作不可恢复。',
          confirmText: '重置',
          cancelText: '取消',
          onConfirm: () => this.resetSettings(),
          onCancel: () => this.showResetDialog = false
        })
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  private buildTopBar() {
    Row() {
      // 标题
      Text('设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      // 搜索按钮（可选）
      Button() {
        Image($r('app.media.ic_search'))
          .width(24)
          .height(24)
          .fillColor('#666666')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        // 实现设置搜索功能
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 2,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 1
    })
  }

  /**
   * 构建设置列表
   */
  @Builder
  private buildSettingsList() {
    Scroll() {
      Column({ space: 16 }) {
        ForEach(
          this.settingsGroups,
          (group: SettingsGroup) => {
            this.buildSettingsGroup(group)
          },
          (group: SettingsGroup) => group.title
        )
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 16 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  /**
   * 构建设置分组
   */
  @Builder
  private buildSettingsGroup(group: SettingsGroup) {
    Column({ space: 0 }) {
      // 分组标题
      if (group.title) {
        Row() {
          Text(group.title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ left: 16, bottom: 8 })
        .alignItems(VerticalAlign.Center)
      }

      // 分组内容
      Column() {
        ForEach(
          group.items,
          (item: SettingsItem, index: number) => {
            this.buildSettingsItem(item, index === group.items.length - 1)
          },
          (item: SettingsItem) => item.id
        )
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 4,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 2
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建设���项
   */
  @Builder
  private buildSettingsItem(item: SettingsItem, isLast: boolean) {
    Row() {
      // 图标
      if (item.icon) {
        Image(item.icon)
          .width(24)
          .height(24)
          .fillColor('#666666')
          .margin({ right: 12 })
      }

      // 标题和副标题
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)

        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(14)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧内容
      if (item.type === 'switch') {
        Toggle({ type: ToggleType.Switch, isOn: item.value })
          .selectedColor('#007AFF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            item.value = isOn
            if (item.action) {
              item.action()
            }
          })
      } else if (item.type === 'navigation' || item.type === 'action') {
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor('#CCCCCC')
      }
    }
    .width('100%')
    .height(56)
    .padding({ horizontal: 16, vertical: 8 })
    .onClick(() => this.handleSettingsItemClick(item))

    if (!isLast) {
      Divider()
        .width('100%')
        .margin({ left: 52 })
        .color('#F0F0F0')
    }
  }

  /**
   * 构建关于对话框
   */
  @Builder
  private buildAboutDialog() {
    Column({ space: 20 }) {
      // 应用图标
      Image($r('app.media.app_icon'))
        .width(80)
        .height(80)
        .borderRadius(16)

      // 应用信息
      Column({ space: 8 }) {
        Text('工程相机')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text('版本 1.0.0')
          .fontSize(16)
          .fontColor('#666666')

        Text('专业的工程照片管理应用')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
      }

      // 功能介绍
      Column({ space: 12 }) {
        Text('主要功能')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)

        Column({ space: 8 }) {
          ForEach(
            [
              '• 项目和工点管理',
              '• 专业拍照和水印',
              '• 照片编辑和标注',
              '• 数据备份和导出'
            ],
            (feature: string) => {
              Text(feature)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Start)
            },
            (feature: string) => feature
          )
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 版权信息
      Text('© 2025 Engineering Camera. All rights reserved.')
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
    }
    .width('90%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 4
    })
    .zIndex(10)
    .position({ x: '5%', y: '30%' })
    .onClick(() => {
      this.showAboutDialog = false
    })
  }
}
