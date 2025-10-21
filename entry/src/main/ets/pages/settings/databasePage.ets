/**
 * 数据库管理页面
 * 提供数���库管理功能，包括数据备份、恢复和清理
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { DatabaseService } from '../../services/database/DatabaseService'
import { DatabaseConstants } from '../../constants/DatabaseConstants'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 数据库统计信息接口
 */
interface DatabaseStats {
  totalSize: number
  projectsCount: number
  sitesCount: number
  photosCount: number
  annotationsCount: number
  lastBackupTime?: Date
  version: number
}

/**
 * 数据库操作类型
 */
enum DatabaseOperation {
  BACKUP = 'backup',
  RESTORE = 'restore',
  CLEANUP = 'cleanup',
  OPTIMIZE = 'optimize',
  RESET = 'reset'
}

@Entry
@Component
struct DatabasePage {
  private logger = new Logger('DatabasePage')
  private databaseService = DatabaseService.getInstance()

  // 路由参数
  private settingsId: string = ''
  private settingsTitle: string = ''

  // 状态管理
  @State private isLoading: boolean = false
  @State private isRefreshing: boolean = false
  @State private databaseStats: DatabaseStats | null = null
  @State private showBackupDialog: boolean = false
  @State private showRestoreDialog: boolean = false
  @State private showCleanupDialog: boolean = false
  @State private showResetDialog: boolean = false

  // 操作状态
  @State private operationInProgress: DatabaseOperation | null = null
  @State private operationProgress: number = 0

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.settingsId = params?.settingsId || ''
    this.settingsTitle = params?.settingsTitle || '数据库管理'

    this.logger.info('DatabasePage appeared', { settingsId: this.settingsId })

    this.loadDatabaseStats()
  }

  aboutToDisappear() {
    this.logger.info('DatabasePage disappeared')
  }

  /**
   * 加载数据库统计信息
   */
  private async loadDatabaseStats() {
    this.isLoading = true
    try {
      // 这里应该调用DatabaseService获取统计信息
      this.databaseStats = {
        totalSize: 1024 * 1024 * 50, // 50MB 示例
        projectsCount: 12,
        sitesCount: 45,
        photosCount: 1234,
        annotationsCount: 567,
        lastBackupTime: new Date('2025-01-20T10:30:00'),
        version: 1
      }
    } catch (error) {
      this.logger.error('加载数据库统计失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 刷新统计信息
   */
  private async refreshStats() {
    this.isRefreshing = true
    try {
      await this.loadDatabaseStats()
    } catch (error) {
      this.logger.error('刷新统计信息失败', error)
    } finally {
      this.isRefreshing = false
    }
  }

  /**
   * 执行数据库备份
   */
  private async executeBackup() {
    this.operationInProgress = DatabaseOperation.BACKUP
    this.operationProgress = 0

    try {
      this.logger.info('开始数据库备份')

      // 模拟备份进度
      for (let i = 0; i <= 100; i += 10) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      this.logger.info('数据库备份完成')
      this.showBackupDialog = false

      // 更新备份时间
      if (this.databaseStats) {
        this.databaseStats.lastBackupTime = new Date()
      }
    } catch (error) {
      this.logger.error('数据库备份失败', error)
    } finally {
      this.operationInProgress = null
      this.operationProgress = 0
    }
  }

  /**
   * 执行数据库恢复
   */
  private async executeRestore() {
    this.operationInProgress = DatabaseOperation.RESTORE
    this.operationProgress = 0

    try {
      this.logger.info('开始数据库恢复')

      // 模拟恢复进度
      for (let i = 0; i <= 100; i += 10) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      this.logger.info('数据库恢复完成')
      this.showRestoreDialog = false

      // 重新加载统计信息
      await this.loadDatabaseStats()
    } catch (error) {
      this.logger.error('数据库恢复失败', error)
    } finally {
      this.operationInProgress = null
      this.operationProgress = 0
    }
  }

  /**
   * 执行数据库清理
   */
  private async executeCleanup() {
    this.operationInProgress = DatabaseOperation.CLEANUP
    this.operationProgress = 0

    try {
      this.logger.info('开始数据库清理')

      // 模拟清理进度
      for (let i = 0; i <= 100; i += 10) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 50))
      }

      this.logger.info('数据库清理完成')
      this.showCleanupDialog = false

      // 重新加载统计信息
      await this.loadDatabaseStats()
    } catch (error) {
      this.logger.error('数据库清理失败', error)
    } finally {
      this.operationInProgress = null
      this.operationProgress = 0
    }
  }

  /**
   * 执行数据库优化
   */
  private async executeOptimize() {
    this.operationInProgress = DatabaseOperation.OPTIMIZE
    this.operationProgress = 0

    try {
      this.logger.info('开始数据库优化')

      // 模拟优化进度
      for (let i = 0; i <= 100; i += 10) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 80))
      }

      this.logger.info('数据库优化完成')
    } catch (error) {
      this.logger.error('数据库优化失败', error)
    } finally {
      this.operationInProgress = null
      this.operationProgress = 0
    }
  }

  /**
   * 执行数据库重置
   */
  private async executeReset() {
    this.operationInProgress = DatabaseOperation.RESET
    this.operationProgress = 0

    try {
      this.logger.info('开始数据库重置')

      // 模拟重置进度
      for (let i = 0; i <= 100; i += 20) {
        this.operationProgress = i
        await new Promise(resolve => setTimeout(resolve, 200))
      }

      this.logger.info('数据库重置完成')
      this.showResetDialog = false

      // 重新加载统计信息
      await this.loadDatabaseStats()
    } catch (error) {
      this.logger.error('数据库重置失败', error)
    } finally {
      this.operationInProgress = null
      this.operationProgress = 0
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
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return date.toLocaleDateString('zh-CN') + ' ' + date.toLocaleTimeString('zh-CN')
  }

  /**
   * 获取操作描述
   */
  private getOperationDescription(operation: DatabaseOperation): string {
    switch (operation) {
      case DatabaseOperation.BACKUP:
        return '备份数据库中...'
      case DatabaseOperation.RESTORE:
        return '恢复数据库中...'
      case DatabaseOperation.CLEANUP:
        return '清理数据库中...'
      case DatabaseOperation.OPTIMIZE:
        return '优化数据库中...'
      case DatabaseOperation.RESET:
        return '重置数据库中...'
      default:
        return '处理中...'
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 数据库统计信息
      this.buildDatabaseStats()

      // 数据库操作
      this.buildDatabaseOperations()

      // 高级选项
      this.buildAdvancedOptions()

      // 备份确认对话框
      if (this.showBackupDialog) {
        ConfirmDialog({
          title: '备份数据库',
          message: '确定要备份数据库吗？备份过程可能需要一些时间。',
          confirmText: '备份',
          cancelText: '取消',
          onConfirm: () => this.executeBackup(),
          onCancel: () => this.showBackupDialog = false
        })
      }

      // 恢复确认对话框
      if (this.showRestoreDialog) {
        ConfirmDialog({
          title: '恢复数据库',
          message: '确定要恢复数据库吗？当前数据将被覆盖，此操作不可恢复。',
          confirmText: '恢复',
          cancelText: '取消',
          onConfirm: () => this.executeRestore(),
          onCancel: () => this.showRestoreDialog = false
        })
      }

      // 清理确认对话框
      if (this.showCleanupDialog) {
        ConfirmDialog({
          title: '清理数据库',
          message: '确定要清理数据库吗？将删除无效数据并优化存储空间。',
          confirmText: '清理',
          cancelText: '取消',
          onConfirm: () => this.executeCleanup(),
          onCancel: () => this.showCleanupDialog = false
        })
      }

      // 重置确认对话框
      if (this.showResetDialog) {
        ConfirmDialog({
          title: '重置数据库',
          message: '确定要重置数据库吗？所有数据将被删除，此操作不可恢复！',
          confirmText: '重置',
          cancelText: '取消',
          onConfirm: () => this.executeReset(),
          onCancel: () => this.showResetDialog = false
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
      .onClick(() => this.refreshStats())
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
   * 构建数据库统计信息
   */
  @Builder
  private buildDatabaseStats() {
    Refresh({ refreshing: $$isRefreshing, friction: 100 }) {
      if (this.databaseStats) {
        Column({ space: 16 }) {
          // 总体信息卡片
          this.buildStatsCard('总体信息', [
            { label: '数据库大小', value: this.formatFileSize(this.databaseStats.totalSize) },
            { label: '数据库版本', value: `v${this.databaseStats.version}` },
            {
              label: '最后备份',
              value: this.databaseStats.lastBackupTime
                ? this.formatDate(this.databaseStats.lastBackupTime)
                : '从未备份'
            }
          ])

          // 数据统计卡片
          this.buildStatsCard('数据统计', [
            { label: '项目数量', value: `${this.databaseStats.projectsCount}` },
            { label: '工点数量', value: `${this.databaseStats.sitesCount}` },
            { label: '照片数量', value: `${this.databaseStats.photosCount}` },
            { label: '标注数量', value: `${this.databaseStats.annotationsCount}` }
          ])
        }
        .width('100%')
        .padding({ horizontal: 16, vertical: 16 })
      } else {
        Column() {
          Text('加载统计信息中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .layoutWeight(1)
    .onRefresh(() => this.refreshStats())
  }

  /**
   * 构建统计卡片
   */
  @Builder
  private buildStatsCard(title: string, items: { label: string, value: string }[]) {
    Column() {
      // 卡片标题
      Row() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank()

        Image($r('app.media.ic_info'))
          .width(16)
          .height(16)
          .fillColor('#999999')
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })

      Divider().color('#F0F0F0')

      // 统计项
      Column({ space: 12 }) {
        ForEach(
          items,
          (item: { label: string, value: string }) => {
            Row() {
              Text(item.label)
                .fontSize(14)
                .fontColor('#666666')

              Text(item.value)
                .fontSize(14)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (item !== items[items.length - 1]) {
              Divider().color('#F8F8F8')
            }
          },
          (item: { label: string, value: string }) => item.label
        )
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
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

  /**
   * 构建数据库操作
   */
  @Builder
  private buildDatabaseOperations() {
    Column({ space: 12 }) {
      Text('数据库操作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .padding({ horizontal: 16 })

      Column({ space: 1 }) {
        // 备份按钮
        this.buildOperationButton(
          '备份数据库',
          '将所有数据备份到本地存储',
          $r('app.media.ic_backup'),
          '#007AFF',
          () => this.showBackupDialog = true
        )

        // 恢复按钮
        this.buildOperationButton(
          '恢复数据库',
          '从备份文件恢复数据',
          $r('app.media.ic_restore'),
          '#34C759',
          () => this.showRestoreDialog = true
        )

        // 清理按钮
        this.buildOperationButton(
          '清理数据库',
          '删除无效数据并优化存储',
          $r('app.media.ic_cleanup'),
          '#FF9500',
          () => this.showCleanupDialog = true
        )

        // 优化按钮
        this.buildOperationButton(
          '优化数据库',
          '重建索引并优化查询性能',
          $r('app.media.ic_optimize'),
          '#AF52DE',
          () => this.executeOptimize()
        )
      }
    }
    .width('100%')
    .padding({ horizontal: 16, bottom: 16 })
  }

  /**
   * 构建操作按钮
   */
  @Builder
  private buildOperationButton(
    title: string,
    description: string,
    icon: Resource,
    color: string,
    action: () => void
  ) {
    Row({ space: 12 }) {
      Button() {
        Image(icon)
          .width(20)
          .height(20)
          .fillColor(color)
      }
      .width(40)
      .height(40)
      .backgroundColor(`${color}20`)
      .borderRadius(8)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')
          .textAlign(TextAlign.Start)

        Text(description)
          .fontSize(12)
          .fontColor('#999999')
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .height(64)
    .padding({ horizontal: 16, vertical: 12 })
    .backgroundColor('#FFFFFF')
    .onClick(action)
  }

  /**
   * 构建高级选项
   */
  @Builder
  private buildAdvancedOptions() {
    Column({ space: 12 }) {
      Text('高级选项')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .padding({ horizontal: 16 })

      // 危险操作
      Column() {
        Row({ space: 12 }) {
          Button() {
            Image($r('app.media.ic_warning'))
              .width(20)
              .height(20)
              .fillColor('#FF3B30')
          }
          .width(40)
          .height(40)
          .backgroundColor('#FF3B3020')
          .borderRadius(8)

          Column({ space: 4 }) {
            Text('重置数据库')
              .fontSize(16)
              .fontColor('#333333')
              .textAlign(TextAlign.Start)

            Text('删除所有数据并重置为初始状态')
              .fontSize(12)
              .fontColor('#999999')
              .textAlign(TextAlign.Start)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Image($r('app.media.ic_arrow_right'))
            .width(16)
            .height(16)
            .fillColor('#CCCCCC')
        }
        .width('100%')
        .height(64)
        .padding({ horizontal: 16, vertical: 12 })
        .backgroundColor('#FFFFFF')
        .onClick(() => this.showResetDialog = true)
      }
    }
    .width('100%')
    .padding({ horizontal: 16, bottom: 20 })
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
      Text(this.getOperationDescription(this.operationInProgress!))
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