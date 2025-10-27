/**
 * 设置主页面
 * 提供应用设置主界面，包括设置项分类、导航和状态持久化
 */

import router from '@ohos.router'
import { bundleManager } from '@kit.AbilityKit'
import { Logger } from '../../utils/Logger'
import { EnhancedSVGIcon } from '../../components/icons/EnhancedSVGIcon'
import { themeStore as themeStoreInstance } from '../../store/theme/ThemeStore'
import { userStore as userStoreInstance } from '../../store/user/UserStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'
import { ThemeType } from '../../store/theme/ThemeConstants'
import { projectStore } from '../../store/project/ProjectStore'
import { ProjectStats } from '../../services/database/ProjectService'

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

interface UsageOverview {
  totalProjects: number
  activeProjects: number
  totalPhotos: number
  totalSites: number
}

@Entry
@Component
struct SettingsPage {
  private logger = new Logger('SettingsPage')
  private themeStore = themeStoreInstance
  private userStore = userStoreInstance

  // 状态管理
  @State private isLoading: boolean = false
  @State private settingsGroups: SettingsGroup[] = []
  @State private showAboutDialog: boolean = false
  @State private showResetDialog: boolean = false
  @State private showThemeDialog: boolean = false
  @State private showCameraQualityDialog: boolean = false
  @State private showHelpDialog: boolean = false
  @State private usageStats: UsageOverview = this.createDefaultUsageStats()
  @State private isUsageLoading: boolean = false
  @State private appVersion: string = '1.0.0'
  @State private buildNumber: string = ''
  @State private pendingTheme: ThemeType = ThemeType.SYSTEM
  @State private pendingPhotoQuality: 'high' | 'medium' | 'low' = 'high'

  aboutToAppear() {
    this.logger.info('SettingsPage appeared')
    this.initializeSettings()
  }

  aboutToDisappear() {
    this.logger.info('SettingsPage disappeared')
  }

  private createDefaultUsageStats(): UsageOverview {
    return {
      totalProjects: 0,
      activeProjects: 0,
      totalPhotos: 0,
      totalSites: 0
    }
  }

  /**
   * 初始化设置项
   */
  private async initializeSettings() {
    this.isLoading = true
    try {
      if (!this.themeStore.isInitialized) {
        await this.themeStore.initialize()
      }
      if (!this.userStore.isInitialized) {
        await this.userStore.initialize()
      }
      if (!projectStore.isInitialized) {
        await projectStore.initialize()
      }

      await this.loadSettingsData()
      await this.loadUsageStats()
      await this.loadAppInfo()
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
    const preferences = this.userStore.userState.preferences
    const themeState = this.themeStore.themeState

    this.pendingTheme = themeState.currentTheme
    this.pendingPhotoQuality = preferences.photoQuality

    this.settingsGroups = [
      {
        title: '通用设置',
        items: [
          {
            id: 'theme',
            title: '主题设置',
            subtitle: this.getThemeText(themeState.currentTheme),
            icon: $r('app.media.ic_theme'),
            type: 'action',
            action: () => this.showThemeDialog = true
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
            subtitle: this.getPhotoQualityText(preferences.photoQuality),
            icon: $r('app.media.ic_camera'),
            type: 'action',
            action: () => this.showCameraQualityDialog = true
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
            subtitle: preferences.enableLocationService ? '自动记录位置信息' : '位置服务已关闭',
            icon: $r('app.media.ic_location'),
            type: 'switch',
            value: preferences.enableLocationService,
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
            subtitle: `版本 ${this.appVersion}${this.buildNumber ? ` (${this.buildNumber})` : ''}`,
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
            type: 'action',
            action: () => this.showHelpDialog = true
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

  private async loadUsageStats() {
    this.isUsageLoading = true
    try {
      if (!projectStore.isInitialized) {
        await projectStore.initialize()
      }

      const stats: ProjectStats | null = projectStore.projectStats
      if (stats) {
        this.usageStats = {
          totalProjects: stats.totalProjects,
          activeProjects: stats.activeProjects,
          totalPhotos: stats.totalPhotos,
          totalSites: stats.totalSites
        }
      } else {
        this.usageStats = this.createDefaultUsageStats()
      }
    } catch (error) {
      this.logger.error('加载使用统计失败', error)
      this.usageStats = this.createDefaultUsageStats()
    } finally {
      this.isUsageLoading = false
    }
  }

  private async loadAppInfo() {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      this.appVersion = bundleInfo?.versionName || this.appVersion
      this.buildNumber = bundleInfo?.versionCode ? bundleInfo.versionCode.toString() : this.buildNumber
    } catch (error) {
      this.logger.error('获取应用信息失败', error)
    }
  }

  /**
   * 获取主题文本
   */
  private getThemeText(theme: ThemeType): string {
    switch (theme) {
      case ThemeType.LIGHT:
        return '浅色主题'
      case ThemeType.DARK:
        return '深色主题'
      case ThemeType.SYSTEM:
        return '跟随系统'
      default:
        return '跟随系统'
    }
  }

  private getPhotoQualityText(quality: 'high' | 'medium' | 'low'): string {
    switch (quality) {
      case 'high':
        return '高质量'
      case 'medium':
        return '标准质量'
      case 'low':
        return '节省存储'
      default:
        return '标准质量'
    }
  }

  /**
   * 切换位置服务
   */
  private async toggleLocationService() {
    try {
      if (!this.userStore.isInitialized) {
        await this.userStore.initialize()
      }
      const preferences = this.userStore.userState.preferences
      const targetValue = !preferences.enableLocationService
      await this.userStore.updatePreferences({ enableLocationService: targetValue })
      await this.loadSettingsData()
      this.logger.info(`位置服务已${targetValue ? '开启' : '关闭'}`)
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

  private async updatePhotoQuality(quality: 'high' | 'medium' | 'low') {
    try {
      if (!this.userStore.isInitialized) {
        await this.userStore.initialize()
      }
      await this.userStore.updatePreferences({ photoQuality: quality })
      this.pendingPhotoQuality = quality
      await this.loadSettingsData()
      this.showCameraQualityDialog = false
      this.logger.info(`照片质量已设置为: ${quality}`)
    } catch (error) {
      this.logger.error('更新照片质量失败', error)
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

  private async applyTheme(theme: ThemeType) {
    try {
      if (!this.themeStore.isInitialized) {
        await this.themeStore.initialize()
      }
      await this.themeStore.setTheme(theme)
      this.pendingTheme = theme
      await this.loadSettingsData()
      this.showThemeDialog = false
      this.logger.info(`主题已设置为: ${theme}`)
    } catch (error) {
      this.logger.error('设置主题失败', error)
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

      if (this.showThemeDialog) {
        this.buildThemeDialog()
      }

      if (this.showCameraQualityDialog) {
        this.buildCameraQualityDialog()
      }

      if (this.showHelpDialog) {
        this.buildHelpDialog()
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
        this.buildPersonalCenter()

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
   * 构建个人中心
   */
  @Builder
  private buildPersonalCenter() {
    Column({ space: 16 }) {
      // 用户信息卡片
      Row({ space: 16 }) {
        // 用户头像
        Column() {
          EnhancedSVGIcon({ iconName: 'user', iconSize: 48, iconColor: '#1890FF', iconStrokeWidth: 2 })
            .width(64)
            .height(64)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#E6F4FF')
            .borderRadius(32)
        }
        .width(64)
        .height(64)

        // 用户信息
        Column({ space: 4 }) {
          Text('工程师')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)

          Text('专业工程拍摄与管理')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)

          Row({ space: 8 }) {
            Text('高级用户')
              .fontSize(12)
              .fontColor('#1890FF')
              .backgroundColor('#E6F4FF')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(8)

            Text('已认证')
              .fontSize(12)
              .fontColor('#52C41A')
              .backgroundColor('#F6FFED')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(8)
          }
          .alignSelf(ItemAlign.Start)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 2
      })

      // 个人统计信息
      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Text(this.usageStats.totalProjects.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1890FF')

          Text('项目数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F0F8FF')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text(this.usageStats.totalPhotos.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#52C41A')

          Text('照片数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F0FFF0')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text(this.usageStats.totalSites.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FAAD14')

          Text('工点数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFAF0')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text('100%')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#722ED1')

          Text('完成率')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(64)
        .height(64)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F8F0FF')
        .borderRadius(8)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      // 快捷操作
      Row({ space: 12 }) {
        Button() {
          Column({ space: 4 }) {
            EnhancedSVGIcon({ iconName: 'database', iconSize: 28, iconColor: '#FFFFFF', iconStrokeWidth: 2 })
            Text('数据分析')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
        }
        .width(80)
        .height(60)
        .backgroundColor('#1890FF')
        .borderRadius(8)
        .onClick(() => {
          // TODO: 导航到数据分析页面
        })

        Button() {
          Column({ space: 4 }) {
            Text('⭐')
              .fontSize(20)
            Text('我的收藏')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
        }
        .width(80)
        .height(60)
        .backgroundColor('#52C41A')
        .borderRadius(8)
        .onClick(() => {
          // TODO: 导航到收藏页面
        })

        Button() {
          Column({ space: 4 }) {
            Text('📝')
              .fontSize(20)
            Text('使用日志')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
        }
        .width(80)
        .height(60)
        .backgroundColor('#FAAD14')
        .borderRadius(8)
        .onClick(() => {
          // TODO: 导航到使用日志页面
        })

        Button() {
          Column({ space: 4 }) {
            Text('🏆')
              .fontSize(20)
            Text('成就勋章')
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
        }
        .width(80)
        .height(60)
        .backgroundColor('#722ED1')
        .borderRadius(8)
        .onClick(() => {
          // TODO: 导航到成就页面
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      // 个性设置
      Column({ space: 12 }) {
        Row() {
          Text('个性设置')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
          Blank()
          Text('编辑资料')
            .fontSize(12)
            .fontColor('#1890FF')
            .onClick(() => {
              // TODO: 导航到编辑资料页面
            })
        }
        .width('100%')

        Row({ space: 12 }) {
          Column() {
            EnhancedSVGIcon({ iconName: 'palette', iconSize: 24, iconColor: '#1890FF', iconStrokeWidth: 2 })
            Text('主题')
              .fontSize(12)
              .fontColor('#666666')
          }
          .width(60)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)

          Column() {
            EnhancedSVGIcon({ iconName: 'photo', iconSize: 24, iconColor: '#1890FF', iconStrokeWidth: 2 })
            Text('布局')
              .fontSize(12)
              .fontColor('#666666')
          }
          .width(60)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)

          Column() {
            Text('🔔')
              .fontSize(16)
            Text('通知')
              .fontSize(12)
              .fontColor('#666666')
          }
          .width(60)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)

          Column() {
            EnhancedSVGIcon({ iconName: 'cloud-storage', iconSize: 24, iconColor: '#1890FF', iconStrokeWidth: 2 })
            Text('云端')
              .fontSize(12)
              .fontColor('#666666')
          }
          .width(60)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)

          Column() {
            EnhancedSVGIcon({ iconName: 'shield', iconSize: 24, iconColor: '#1890FF', iconStrokeWidth: 2 })
            Text('隐私')
              .fontSize(12)
              .fontColor('#666666')
          }
          .width(60)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 2
      })
    }
    .width('100%')
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
   * 构建主题选择对话框
   */
  @Builder
  private buildThemeDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.showThemeDialog = false)

      Column({ space: 16 }) {
        Text('选择主题')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Column({ space: 12 }) {
          const options: { label: string; value: ThemeType; description: string }[] = [
            { label: '浅色模式', value: ThemeType.LIGHT, description: '适合明亮环境，提升可读性' },
            { label: '深色模式', value: ThemeType.DARK, description: '适合夜间与弱光环境，保护视力' },
            { label: '跟随系统', value: ThemeType.SYSTEM, description: '自动适配系统主题' }
          ]

          ForEach(
            options,
            (option) => {
              Column({ space: 6 }) {
                Row() {
                  Text(option.label)
                    .fontSize(16)
                    .fontColor('#262626')
                    .layoutWeight(1)

                  if (this.pendingTheme === option.value) {
                    Text('✓')
                      .fontSize(18)
                      .fontColor('#1890FF')
                  }
                }
                .width('100%')
                .onClick(() => this.applyTheme(option.value))

                Text(option.description)
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .width('100%')
              }
              .width('100%')
              .padding({ vertical: 12, horizontal: 12 })
              .backgroundColor(this.pendingTheme === option.value ? '#EDF4FF' : '#F7F9FC')
              .borderRadius(12)
              .onClick(() => this.applyTheme(option.value))
            },
            (option) => option.value
          )
        }

        Button('取消')
          .fontSize(16)
          .fontColor('#1890FF')
          .backgroundColor(Color.Transparent)
          .height(44)
          .border({ width: 1, color: '#1890FF' })
          .borderRadius(22)
          .onClick(() => this.showThemeDialog = false)
      }
      .width('86%')
      .padding({ top: 24, bottom: 20, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .shadow({
        radius: 18,
        color: 'rgba(0,0,0,0.2)',
        offsetX: 0,
        offsetY: 6
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(200)
  }

  /**
   * 构建照片质量选择对话框
   */
  @Builder
  private buildCameraQualityDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.showCameraQualityDialog = false)

      Column({ space: 16 }) {
        Text('照片质量')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Column({ space: 12 }) {
          const options: Array<{ label: string; value: 'high' | 'medium' | 'low'; description: string }> = [
            { label: '高质量', value: 'high', description: '最高画质，适合精细工程记录，文件较大' },
            { label: '标准质量', value: 'medium', description: '画质与体积平衡，推荐日常使用' },
            { label: '节省存储', value: 'low', description: '降低画质换取最小体积，节省存储空间' }
          ]

          ForEach(
            options,
            (option) => {
              Column({ space: 6 }) {
                Row() {
                  Text(option.label)
                    .fontSize(16)
                    .fontColor('#262626')
                    .layoutWeight(1)

                  if (this.pendingPhotoQuality === option.value) {
                    Text('✓')
                      .fontSize(18)
                      .fontColor('#1890FF')
                  }
                }
                .width('100%')
                .onClick(() => this.updatePhotoQuality(option.value))

                Text(option.description)
                  .fontSize(12)
                  .fontColor('#8C8C8C')
                  .width('100%')
              }
              .width('100%')
              .padding({ vertical: 12, horizontal: 12 })
              .backgroundColor(this.pendingPhotoQuality === option.value ? '#EDF4FF' : '#F7F9FC')
              .borderRadius(12)
              .onClick(() => this.updatePhotoQuality(option.value))
            },
            (option) => option.value
          )
        }

        Button('取消')
          .fontSize(16)
          .fontColor('#1890FF')
          .backgroundColor(Color.Transparent)
          .height(44)
          .border({ width: 1, color: '#1890FF' })
          .borderRadius(22)
          .onClick(() => this.showCameraQualityDialog = false)
      }
      .width('86%')
      .padding({ top: 24, bottom: 20, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .shadow({
        radius: 18,
        color: 'rgba(0,0,0,0.2)',
        offsetX: 0,
        offsetY: 6
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(210)
  }

  /**
   * 帮助中心对话框
   */
  @Builder
  private buildHelpDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.showHelpDialog = false)

      Column({ space: 16 }) {
        Text('使用帮助')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Column({ space: 10 }) {
          Text('快速上手')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262626')
            .alignSelf(ItemAlign.Start)

          ForEach(
            [
              '1. 在“工程”页创建项目与工点，完成项目基础信息。',
              '2. 进入“拍照”快速记录现场，并自动写入水印和定位。', 
              '3. 在“相册”中筛选、编辑、导出工程照片。',
              '4. 设置页可调整主题、拍照质量、备份策略等。'
            ],
            (tip) => {
              Text(tip)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Start)
            },
            (tip) => tip
          )
        }

        Column({ space: 8 }) {
          Text('更多资源')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262626')
            .alignSelf(ItemAlign.Start)

          ForEach(
            [
              '• 用户手册：详解主要功能与操作流程',
              '• 常见问题：快速定位并解决常见疑问',
              '• 联系支持：通过意见反馈与我们取得联系'
            ],
            (item) => {
              Text(item)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Start)
            },
            (item) => item
          )
        }

        Button('知道了')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#1890FF')
          .height(44)
          .borderRadius(22)
          .onClick(() => this.showHelpDialog = false)
      }
      .width('88%')
      .padding({ top: 24, bottom: 20, left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .shadow({
        radius: 18,
        color: 'rgba(0,0,0,0.2)',
        offsetX: 0,
        offsetY: 6
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(200)
  }

  /**
   * 构建关于对话框
   */
  @Builder
  private buildAboutDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.35)')
        .onClick(() => this.showAboutDialog = false)

      Column({ space: 20 }) {
        Image($r('app.media.app_icon'))
          .width(80)
          .height(80)
          .borderRadius(16)

        Column({ space: 8 }) {
          Text('工程相机')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Text(`版本 ${this.appVersion}${this.buildNumber ? ` (${this.buildNumber})` : ''}`)
            .fontSize(16)
            .fontColor('#666666')

          Text('专业的工程拍摄与管理工具')
            .fontSize(14)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
        }

        Column({ space: 12 }) {
          Text('主要功能')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)

          Column({ space: 8 }) {
            ForEach(
              [
                '• 项目与工点全流程管理',
                '• 专业拍照与水印模板',
                '• 照片标注、批处理与导出',
                '• 数据备份与团队协作'
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

        Text('© 2025 工程相机团队保留所有权利')
          .fontSize(12)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)

        Button('关闭')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#1890FF')
          .height(44)
          .borderRadius(22)
          .onClick(() => this.showAboutDialog = false)
      }
      .width('88%')
      .padding({ top: 24, bottom: 20, left: 24, right: 24 })
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .shadow({
        radius: 18,
        color: 'rgba(0,0,0,0.2)',
        offsetX: 0,
        offsetY: 6
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(220)
  }
}
