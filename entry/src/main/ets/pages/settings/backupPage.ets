/**
 * 备份管理页面
 * 提供本地备份管理、云端备份配置和备份历史查看功能
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 备份类型枚举
 */
enum BackupType {
  LOCAL = 'local',
  CLOUD = 'cloud'
}

/**
 * 备份状态枚举
 */
enum BackupStatus {
  SUCCESS = 'success',
  FAILED = 'failed',
  IN_PROGRESS = 'in_progress',
  PENDING = 'pending'
}

/**
 * 备份记录接口
 */
interface BackupRecord {
  id: string
  type: BackupType
  status: BackupStatus
  size: number
  itemCount: number
  createdAt: Date
  completedAt?: Date
  description?: string
  location?: string
}

/**
 * 备份配置接口
 */
interface BackupConfig {
  autoBackup: boolean
  backupInterval: number // 小时
  maxBackupCount: number
  includePhotos: boolean
  includeDatabase: boolean
  compressionEnabled: boolean
  encryptionEnabled: boolean
}

@Entry
@Component
struct BackupPage {
  private logger = new Logger('BackupPage')

  // 路由参数
  private settingsId: string = ''
  private settingsTitle: string = ''

  // 状态管理
  @State private isLoading: boolean = false
  @State private isRefreshing: boolean = false
  @State private currentTab: BackupType = BackupType.LOCAL
  @State private backupRecords: BackupRecord[] = []
  @State private backupConfig: BackupConfig = {
    autoBackup: true,
    backupInterval: 24,
    maxBackupCount: 5,
    includePhotos: true,
    includeDatabase: true,
    compressionEnabled: true,
    encryptionEnabled: false
  }

  // 对话框状态
  @State private showBackupDialog: boolean = false
  @State private showRestoreDialog: boolean = false
  @State private showConfigDialog: boolean = false
  @State private showDeleteDialog: boolean = false
  @State private selectedBackup: BackupRecord | null = null

  // 操作状态
  @State private operationInProgress: boolean = false
  @State private operationProgress: number = 0

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.settingsId = params?.settingsId || ''
    this.settingsTitle = params?.settingsTitle || '备份管理'

    this.logger.info('BackupPage appeared', { settingsId: this.settingsId })

    this.loadBackupData()
  }

  aboutToDisappear() {
    this.logger.info('BackupPage disappeared')
  }

  /**
   * 加载备份数据
   */
  private async loadBackupData() {
    this.isLoading = true
    try {
      // 模拟加载备份记录
      this.backupRecords = [
        {
          id: '1',
          type: BackupType.LOCAL,
          status: BackupStatus.SUCCESS,
          size: 1024 * 1024 * 25, // 25MB
          itemCount: 150,
          createdAt: new Date('2025-01-20T10:30:00'),
          completedAt: new Date('2025-01-20T10:35:00'),
          description: '完整备份',
          location: '/storage/backups/backup_20250120_103000.zip'
        },
        {
          id: '2',
          type: BackupType.LOCAL,
          status: BackupStatus.SUCCESS,
          size: 1024 * 1024 * 18, // 18MB
          itemCount: 120,
          createdAt: new Date('2025-01-19T22:00:00'),
          completedAt: new Date('2025-01-19T22:03:00'),
          description: '增量备份',
          location: '/storage/backups/backup_20250119_220000.zip'
        },
        {
          id: '3',
          type: BackupType.CLOUD,
          status: BackupStatus.SUCCESS,
          size: 1024 * 1024 * 30, // 30MB
          itemCount: 180,
          createdAt: new Date('2025-01-18T15:45:00'),
          completedAt: new Date('2025-01-18T15:50:00'),
          description: '云端完整备份',
          location: 'cloud://backup_server/backup_20250118_154500'
        }
      ]

      // 按当前标签过滤
      this.backupRecords = this.backupRecords.filter(record => record.type === this.currentTab)
    } catch (error) {
      this.logger.error('加载备份数据失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 刷新备份数据
   */
  private async refreshBackupData() {
    this.isRefreshing = true
    try {
      await this.loadBackupData()
    } catch (error) {
      this.logger.error('刷新备份数据失败', error)
    } finally {
      this.isRefreshing = false
    }
  }

  /**
   * 切换标签
   */
  private switchTab(tab: BackupType) {
    if (this.currentTab !== tab) {
      this.currentTab = tab
      this.loadBackupData()
    }
  }

  /**
   * 执行备份
   */
  private async executeBackup() {
    this.operationInProgress = true
    this.operationProgress = 0

    try {
      this.logger.info('开始执行备份')

      // 模拟备份进度
      for (let i = 0; i <= 100; i += 5) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      // 添加新的备份记录
      const newBackup: BackupRecord = {
        id: Date.now().toString(),
        type: this.currentTab,
        status: BackupStatus.SUCCESS,
        size: 1024 * 1024 * 20, // 20MB
        itemCount: 140,
        createdAt: new Date(),
        completedAt: new Date(),
        description: '手动备份',
        location: this.currentTab === BackupType.LOCAL
          ? '/storage/backups/backup_' + this.formatDateTime(new Date()) + '.zip'
          : 'cloud://backup_server/backup_' + this.formatDateTime(new Date())
      }

      this.backupRecords.unshift(newBackup)

      this.logger.info('备份完成')
      this.showBackupDialog = false
    } catch (error) {
      this.logger.error('备份失败', error)
    } finally {
      this.operationInProgress = false
      this.operationProgress = 0
    }
  }

  /**
   * 恢复备份
   */
  private async restoreBackup(backup: BackupRecord) {
    this.operationInProgress = true
    this.operationProgress = 0

    try {
      this.logger.info('开始恢复备份', { backupId: backup.id })

      // 模拟恢复进度
      for (let i = 0; i <= 100; i += 10) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 150))
      }

      this.logger.info('恢复完成')
      this.showRestoreDialog = false
      this.selectedBackup = null
    } catch (error) {
      this.logger.error('恢复失败', error)
    } finally {
      this.operationInProgress = false
      this.operationProgress = 0
    }
  }

  /**
   * 删除备份
   */
  private async deleteBackup(backup: BackupRecord) {
    try {
      this.logger.info('删除备份', { backupId: backup.id })

      // 从列表中移除
      const index = this.backupRecords.findIndex(record => record.id === backup.id)
      if (index > -1) {
        this.backupRecords.splice(index, 1)
      }

      this.showDeleteDialog = false
      this.selectedBackup = null
    } catch (error) {
      this.logger.error('删除备份失败', error)
    }
  }

  /**
   * 保存配置
   */
  private async saveConfig() {
    try {
      this.logger.info('保存备份配置', this.backupConfig)
      // 这里应该保存配置到本地存储
      this.showConfigDialog = false
    } catch (error) {
      this.logger.error('保存配置失败', error)
    }
  }

  /**
   * 格式化文件大小
   */
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  /**
   * 格式化日期时间
   */
  private formatDateTime(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hour = String(date.getHours()).padStart(2, '0')
    const minute = String(date.getMinutes()).padStart(2, '0')
    const second = String(date.getSeconds()).padStart(2, '0')
    return `${year}${month}${day}_${hour}${minute}${second}`
  }

  /**
   * 格式化显示时间
   */
  private formatDisplayTime(date: Date): string {
    return date.toLocaleString('zh-CN')
  }

  /**
   * 获取状态文本
   */
  private getStatusText(status: BackupStatus): string {
    switch (status) {
      case BackupStatus.SUCCESS:
        return '成功'
      case BackupStatus.FAILED:
        return '失败'
      case BackupStatus.IN_PROGRESS:
        return '进行中'
      case BackupStatus.PENDING:
        return '等待中'
      default:
        return '未知'
    }
  }

  /**
   * 获取状态颜色
   */
  private getStatusColor(status: BackupStatus): string {
    switch (status) {
      case BackupStatus.SUCCESS:
        return '#34C759'
      case BackupStatus.FAILED:
        return '#FF3B30'
      case BackupStatus.IN_PROGRESS:
        return '#007AFF'
      case BackupStatus.PENDING:
        return '#FF9500'
      default:
        return '#666666'
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 标签切换
      this.buildTabBar()

      // 备份列表
      this.buildBackupList()

      // 配置对话框
      if (this.showConfigDialog) {
        this.buildConfigDialog()
      }

      // 备份确认对话框
      if (this.showBackupDialog) {
        ConfirmDialog({
          title: '创建备份',
          message: `确定要创建${this.currentTab === BackupType.LOCAL ? '本地' : '云端'}备份吗？`,
          confirmText: '备份',
          cancelText: '取消',
          onConfirm: () => this.executeBackup(),
          onCancel: () => this.showBackupDialog = false
        })
      }

      // 恢复确认对话框
      if (this.showRestoreDialog && this.selectedBackup) {
        ConfirmDialog({
          title: '恢复备份',
          message: `确定要恢复 ${this.formatDisplayTime(this.selectedBackup.createdAt)} 的备份吗？当前数据将被覆盖。`,
          confirmText: '恢复',
          cancelText: '取消',
          onConfirm: () => this.restoreBackup(this.selectedBackup),
          onCancel: () => {
            this.showRestoreDialog = false
            this.selectedBackup = null
          }
        })
      }

      // 删除确认对话框
      if (this.showDeleteDialog && this.selectedBackup) {
        ConfirmDialog({
          title: '删除备份',
          message: `确定要删除 ${this.formatDisplayTime(this.selectedBackup.createdAt)} 的备份吗？此操作不可恢复。`,
          confirmText: '删除',
          cancelText: '取消',
          onConfirm: () => this.deleteBackup(this.selectedBackup),
          onCancel: () => {
            this.showDeleteDialog = false
            this.selectedBackup = null
          }
        })
      }

      // 操作进度对话框
      if (this.operationInProgress) {
        this.buildOperationDialog()
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
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => router.back())

      // 标题
      Text(this.settingsTitle)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 操作按钮组
      Row({ space: 12 }) {
        // 配置按钮
        Button() {
          Image($r('app.media.ic_settings'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showConfigDialog = true)

        // 刷新按钮
        Button() {
          Image($r('app.media.ic_refresh'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(!this.isRefreshing)
        .onClick(() => this.refreshBackupData())
      }
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
   * 构建标签栏
   */
  @Builder
  private buildTabBar() {
    Row() {
      // 本地备份标签
      Column({ space: 4 }) {
        Text('本地备份')
          .fontSize(16)
          .fontColor(this.currentTab === BackupType.LOCAL ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === BackupType.LOCAL ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === BackupType.LOCAL) {
          Row()
            .width(40)
            .height(3)
            .backgroundColor('#007AFF')
            .borderRadius(2)
        }
      }
      .layoutWeight(1)
      .height(50)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.switchTab(BackupType.LOCAL))

      // 云端备份标签
      Column({ space: 4 }) {
        Text('云端备份')
          .fontSize(16)
          .fontColor(this.currentTab === BackupType.CLOUD ? '#007AFF' : '#666666')
          .fontWeight(this.currentTab === BackupType.CLOUD ? FontWeight.Bold : FontWeight.Normal)

        // 下划线
        if (this.currentTab === BackupType.CLOUD) {
          Row()
            .width(40)
            .height(3)
            .backgroundColor('#007AFF')
            .borderRadius(2)
        }
      }
      .layoutWeight(1)
      .height(50)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.switchTab(BackupType.CLOUD))
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建备份列表
   */
  @Builder
  private buildBackupList() {
    Column({ space: 12 }) {
      // 创建备份按钮
      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')

          Text(`创建${this.currentTab === BackupType.LOCAL ? '本地' : '云端'}备份`)
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
      }
      .width('90%')
      .height(48)
      .backgroundColor('#007AFF')
      .borderRadius(24)
      .margin({ top: 16 })
      .onClick(() => this.showBackupDialog = true)

      // 备份记录列表
      Refresh({ refreshing: $$isRefreshing, friction: 100 }) {
        if (this.backupRecords.length > 0) {
          List({ space: 12 }) {
            ForEach(
              this.backupRecords,
              (backup: BackupRecord) => {
                ListItem() {
                  this.buildBackupItem(backup)
                }
              },
              (backup: BackupRecord) => backup.id
            )
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ horizontal: 16 })
          .onRefresh(() => this.refreshBackupData())
        } else {
          Column() {
            Image($r('app.media.ic_empty_backup'))
              .width(64)
              .height(64)
              .fillColor('#CCCCCC')
              .margin({ bottom: 16 })

            Text('暂无备份记录')
              .fontSize(16)
              .fontColor('#666666')

            Text('点击上方按钮创建第一个备份')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .margin({ horizontal: 16 })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建备份项
   */
  @Builder
  private buildBackupItem(backup: BackupRecord) {
    Column({ space: 12 }) {
      // 备份头部信息
      Row({ space: 12 }) {
        // 备份图标
        Image(this.currentTab === BackupType.LOCAL ? $r('app.media.ic_storage') : $r('app.media.ic_cloud'))
          .width(24)
          .height(24)
          .fillColor('#666666')

        Column({ space: 4 }) {
          Row() {
            Text(backup.description || '备份')
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)

            Text(this.getStatusText(backup.status))
              .fontSize(12)
              .fontColor(this.getStatusColor(backup.status))
              .padding({ horizontal: 6, vertical: 2 })
              .backgroundColor(`${this.getStatusColor(backup.status)}20`)
              .borderRadius(8)
          }
          .width('100%')

          Row() {
            Text(`${backup.itemCount} 项`)
              .fontSize(14)
              .fontColor('#666666')

            Text('•')
              .fontSize(14)
              .fontColor('#CCCCCC')

            Text(this.formatFileSize(backup.size))
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 更多操作按钮
        Button() {
          Image($r('app.media.ic_more'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.selectedBackup = backup
          // 显示更多操作选项
        })
      }
      .width('100%')

      // 备份详情
      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text('创建时间')
            .fontSize(12)
            .fontColor('#999999')

          Text(this.formatDisplayTime(backup.createdAt))
            .fontSize(14)
            .fontColor('#333333')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (backup.completedAt) {
          Column({ space: 4 }) {
            Text('完成时间')
              .fontSize(12)
              .fontColor('#999999')

            Text(this.formatDisplayTime(backup.completedAt))
              .fontSize(14)
              .fontColor('#333333')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }

        Column({ space: 4 }) {
          Text('存储位置')
            .fontSize(12)
            .fontColor('#999999')

          Text(backup.location?.split('/').pop() || '未知')
            .fontSize(14)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 操作按钮
      Row({ space: 12 }) {
        Button('恢复')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#34C759')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.selectedBackup = backup
            this.showRestoreDialog = true
          })

        Button('删除')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF3B30')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.selectedBackup = backup
            this.showDeleteDialog = true
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建配置对话框
   */
  @Builder
  private buildConfigDialog() {
    Column() {
      // 对话框标题
      Row() {
        Text('备份配置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button() {
          Image($r('app.media.ic_close'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showConfigDialog = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      Scroll() {
        Column({ space: 20 }) {
          // 自动备份设置
          Column({ space: 12 }) {
            Text('自动备份')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)

            Row() {
              Text('启用自动备份')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.backupConfig.autoBackup })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  this.backupConfig.autoBackup = isOn
                })
            }
            .width('100%')

            if (this.backupConfig.autoBackup) {
              Column({ space: 8 }) {
                Row() {
                  Text('备份间隔')
                    .fontSize(14)
                    .fontColor('#333333')

                  Text(`${this.backupConfig.backupInterval} 小时`)
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                Slider({
                  value: this.backupConfig.backupInterval,
                  min: 1,
                  max: 168, // 一周
                  style: SliderStyle.InSet
                })
                .width('100%')
                .trackColor('#E0E0E0')
                .selectedColor('#007AFF')
                .blockColor('#007AFF')
                .onChange((value: number) => {
                  this.backupConfig.backupInterval = value
                })
              }
              .width('100%')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 备份内容设置
          Column({ space: 12 }) {
            Text('备份内容')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)

            Row() {
              Text('包含照片')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.backupConfig.includePhotos })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  this.backupConfig.includePhotos = isOn
                })
            }
            .width('100%')

            Row() {
              Text('包含数据库')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.backupConfig.includeDatabase })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  this.backupConfig.includeDatabase = isOn
                })
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 高级设置
          Column({ space: 12 }) {
            Text('高级设置')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)

            Row() {
              Text('启用压缩')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.backupConfig.compressionEnabled })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  this.backupConfig.compressionEnabled = isOn
                })
            }
            .width('100%')

            Row() {
              Text('启用加密')
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.backupConfig.encryptionEnabled })
                .selectedColor('#007AFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  this.backupConfig.encryptionEnabled = isOn
                })
            }
            .width('100%')

            Row() {
              Text('最大备份数量')
                .fontSize(14)
                .fontColor('#333333')

              Text(`${this.backupConfig.maxBackupCount}`)
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween')

            Slider({
              value: this.backupConfig.maxBackupCount,
              min: 1,
              max: 20,
              style: SliderStyle.InSet
            })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#007AFF')
            .blockColor('#007AFF')
            .onChange((value: number) => {
              this.backupConfig.maxBackupCount = value
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      // 底部操作栏
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showConfigDialog = false)

        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.saveConfig())
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('80%')
    .position({ x: 0, y: '20%' })
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: -4
    })
    .zIndex(10)
  }

  /**
   * 构建操作进度对话框
   */
  @Builder
  private buildOperationDialog() {
    Column({ space: 20 }) {
      // 进度指示器
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007AFF')

      // 操作描述
      Text('处理中，请稍候...')
        .fontSize(16)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)

      // 进度条
      Progress({
        value: this.operationProgress,
        total: 100,
        type: ProgressType.Linear
      })
      .width('80%')
      .color('#007AFF')
      .backgroundColor('#F0F0F0')

      // 进度百分比
      Text(`${this.operationProgress}%`)
        .fontSize(14)
        .fontColor('#666666')

      // 提示信息
      Text('请勿关闭应用或执行其他操作')
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 4
    })
    .zIndex(20)
    .position({ x: '10%', y: '40%' })
  }
}