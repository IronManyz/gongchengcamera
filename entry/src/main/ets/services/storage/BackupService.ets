/**
 * 备份服务
 * 提供本地备份功能、数据恢复功能、备份验证功能
 */

import { fileIo } from '@ohos.file.fs'
import { Context } from '@ohos.abilityAccessCtrl'
import { BusinessError } from '@kit.BasicServicesKit'
import { Logger } from '../../utils/Logger'
import { FileService } from './FileService'
import { DatabaseService } from '../database/DatabaseService'
import { Photo } from '../../models/Photo'
import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { User } from '../../models/User'

/**
 * 备份类型
 */
export enum BackupType {
  FULL = 'full',        // 完整备份
  INCREMENTAL = 'incremental',  // 增量备份
  DIFFERENTIAL = 'differential' // 差异备份
}

/**
 * 备份选项
 */
export interface BackupOptions {
  type: BackupType
  includePhotos: boolean
  includeThumbnails: boolean
  includeDatabase: boolean
  includeSettings: boolean
  compression: boolean
  encryption: boolean
  password?: string
}

/**
 * 备份信息
 */
export interface BackupInfo {
  id: string
  type: BackupType
  name: string
  description: string
  createdAt: Date
  size: number
  path: string
  version: string
  checksum: string
  itemCounts: {
    photos: number
    thumbnails: number
    databaseRecords: number
  }
  options: BackupOptions
}

/**
 * 恢复选项
 */
export interface RestoreOptions {
  overwriteExisting: boolean
  restorePhotos: boolean
  restoreThumbnails: boolean
  restoreDatabase: boolean
  restoreSettings: boolean
  skipConflicts: boolean
}

/**
 * 恢复结果
 */
export interface RestoreResult {
  success: boolean
  restoredItems: {
    photos: number
    thumbnails: number
    databaseRecords: number
    settings: number
  }
  skippedItems: {
    photos: number
    thumbnails: number
    databaseRecords: number
  }
  errors: string[]
}

/**
 * 备份验证结果
 */
export interface ValidationResult {
  valid: boolean
  issues: string[]
  warnings: string[]
  missingFiles: string[]
  corruptedFiles: string[]
  checksumMatch: boolean
}

/**
 * 备份配置文件
 */
interface BackupConfig {
  version: string
  createdAt: string
  type: BackupType
  options: BackupOptions
  itemCounts: {
    photos: number
    thumbnails: number
    databaseRecords: number
  }
  checksums: {
    config: string
    database: string
    photos: string[]
    thumbnails: string[]
  }
}

export class BackupService {
  private static instance: BackupService | null = null
  private context: Context | null = null
  private logger = new Logger('BackupService')
  private fileService = FileService.getInstance()
  private databaseService = DatabaseService.getInstance()

  // 备份目录
  private backupDir: string = ''
  private readonly BACKUP_VERSION = '1.0.0'
  private readonly CONFIG_FILE_NAME = 'backup_config.json'
  private readonly DATABASE_FILE_NAME = 'database.db'
  private readonly PHOTOS_DIR_NAME = 'photos'
  private readonly THUMBNAILS_DIR_NAME = 'thumbnails'
  private readonly SETTINGS_FILE_NAME = 'settings.json'

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): BackupService {
    if (!BackupService.instance) {
      BackupService.instance = new BackupService()
    }
    return BackupService.instance
  }

  /**
   * 初始化备份服务
   */
  async initialize(context: Context): Promise<void> {
    this.context = context
    this.backupDir = `${context.filesDir}/backup`

    // 确保备份目录存在
    try {
      await fileIo.mkdir(this.backupDir)
    } catch (error) {
      const err = error as BusinessError
      if (err.code !== 201800) { // 201800: 目录已存在
        this.logger.error('Failed to create backup directory', error)
        throw error
      }
    }

    this.logger.info('BackupService initialized', { backupDir: this.backupDir })
  }

  /**
   * 创建备份
   */
  async createBackup(
    name: string,
    description: string,
    options: BackupOptions
  ): Promise<BackupInfo> {
    const backupId = this.generateBackupId()
    const backupPath = `${this.backupDir}/${backupId}`

    try {
      this.logger.info('Starting backup creation', {
        backupId,
        name,
        type: options.type,
        options
      })

      // 创建备份目录
      await this.ensureDirectoryExists(backupPath)

      // 备份数据库
      let databaseSize = 0
      let databaseRecordCount = 0
      if (options.includeDatabase) {
        const dbResult = await this.backupDatabase(backupPath)
        databaseSize = dbResult.size
        databaseRecordCount = dbResult.recordCount
      }

      // 备份照片
      let photoCount = 0
      let photosChecksum: string[] = []
      if (options.includePhotos) {
        const photoResult = await this.backupPhotos(backupPath, options.type)
        photoCount = photoResult.count
        photosChecksum = photoResult.checksums
      }

      // 备份缩略图
      let thumbnailCount = 0
      let thumbnailsChecksum: string[] = []
      if (options.includeThumbnails) {
        const thumbnailResult = await this.backupThumbnails(backupPath, options.type)
        thumbnailCount = thumbnailResult.count
        thumbnailsChecksum = thumbnailResult.checksums
      }

      // 备份设置
      if (options.includeSettings) {
        await this.backupSettings(backupPath)
      }

      // 创建备份配置文件
      const config: BackupConfig = {
        version: this.BACKUP_VERSION,
        createdAt: new Date().toISOString(),
        type: options.type,
        options,
        itemCounts: {
          photos: photoCount,
          thumbnails: thumbnailCount,
          databaseRecords: databaseRecordCount
        },
        checksums: {
          config: '', // 将在计算后填入
          database: '', // 将在计算后填入
          photos: photosChecksum,
          thumbnails: thumbnailsChecksum
        }
      }

      // 保存配置文件
      const configPath = `${backupPath}/${this.CONFIG_FILE_NAME}`
      await this.saveBackupConfig(config, configPath)
      config.checksums.config = await this.calculateFileChecksum(configPath)

      if (options.includeDatabase) {
        const dbPath = `${backupPath}/${this.DATABASE_FILE_NAME}`
        config.checksums.database = await this.calculateFileChecksum(dbPath)
      }

      // 重新保存配置文件（包含校验和）
      await this.saveBackupConfig(config, configPath)

      // 计算总大小
      const totalSize = await this.calculateDirectorySize(backupPath)

      // 创建备份信息
      const backupInfo: BackupInfo = {
        id: backupId,
        type: options.type,
        name,
        description,
        createdAt: new Date(),
        size: totalSize,
        path: backupPath,
        version: this.BACKUP_VERSION,
        checksum: config.checksums.config,
        itemCounts: {
          photos: photoCount,
          thumbnails: thumbnailCount,
          databaseRecords: databaseRecordCount
        },
        options
      }

      this.logger.info('Backup created successfully', {
        backupId,
        size: totalSize,
        itemCounts: backupInfo.itemCounts
      })

      return backupInfo

    } catch (error) {
      this.logger.error('Failed to create backup', { backupId, error })
      // 清理失败的备份目录
      await this.cleanupFailedBackup(backupPath)
      throw error
    }
  }

  /**
   * 生成备份ID
   */
  private generateBackupId(): string {
    const timestamp = Date.now()
    const random = Math.random().toString(36).substring(2, 8)
    return `backup_${timestamp}_${random}`
  }

  /**
   * 确保目录存在
   */
  private async ensureDirectoryExists(dirPath: string): Promise<void> {
    try {
      await fileIo.mkdir(dirPath)
    } catch (error) {
      const err = error as BusinessError
      if (err.code !== 201800) {
        throw error
      }
    }
  }

  /**
   * 备份数据库
   */
  private async backupDatabase(backupPath: string): Promise<{ size: number; recordCount: number }> {
    try {
      this.logger.info('Backing up database')

      const databasePath = this.databaseService.getDatabasePath()
      const backupDatabasePath = `${backupPath}/${this.DATABASE_FILE_NAME}`

      // 复制数据库文件
      const result = await this.fileService.moveFile(databasePath, backupDatabasePath)
      if (!result.success) {
        throw new Error(`Failed to backup database: ${result.error}`)
      }

      // 获取记录数量
      const recordCount = await this.getDatabaseRecordCount()

      // 恢复原数据库文件（从备份位置）
      await this.fileService.moveFile(backupDatabasePath, databasePath)

      // 再次复制到备份位置
      await this.fileService.moveFile(databasePath, backupDatabasePath)

      this.logger.info('Database backup completed', {
        size: result.size,
        recordCount
      })

      return {
        size: result.size || 0,
        recordCount
      }
    } catch (error) {
      this.logger.error('Failed to backup database', error)
      throw error
    }
  }

  /**
   * 获取数据库记录数量
   */
  private async getDatabaseRecordCount(): Promise<number> {
    try {
      const photoCount = await this.databaseService.getCount('photos')
      const projectCount = await this.databaseService.getCount('projects')
      const siteCount = await this.databaseService.getCount('sites')
      const userCount = await this.databaseService.getCount('users')

      return photoCount + projectCount + siteCount + userCount
    } catch (error) {
      this.logger.error('Failed to get database record count', error)
      return 0
    }
  }

  /**
   * 备份照片
   */
  private async backupPhotos(
    backupPath: string,
    type: BackupType
  ): Promise<{ count: number; checksums: string[] }> {
    try {
      this.logger.info('Backing up photos', { type })

      const photosDir = `${backupPath}/${this.PHOTOS_DIR_NAME}`
      await this.ensureDirectoryExists(photosDir)

      // 获取所有照片记录
      const photos = await this.databaseService.getAll('photos') as Photo[]
      let count = 0
      const checksums: string[] = []

      for (const photo of photos) {
        if (photo.filePath && this.fileService.fileExists(photo.filePath)) {
          const fileName = `${photo.id}_${this.getFileName(photo.filePath)}`
          const backupPhotoPath = `${photosDir}/${fileName}`

          // 复制照片文件
          const result = await this.fileService.moveFile(photo.filePath, backupPhotoPath)
          if (result.success) {
            count++
            const checksum = await this.calculateFileChecksum(backupPhotoPath)
            checksums.push(checksum)

            // 恢复原文件
            await this.fileService.moveFile(backupPhotoPath, photo.filePath)

            // 再次复制到备份位置
            await this.fileService.moveFile(photo.filePath, backupPhotoPath)
          }
        }
      }

      this.logger.info('Photos backup completed', { count })

      return { count, checksums }
    } catch (error) {
      this.logger.error('Failed to backup photos', error)
      throw error
    }
  }

  /**
   * 备份缩略图
   */
  private async backupThumbnails(
    backupPath: string,
    type: BackupType
  ): Promise<{ count: number; checksums: string[] }> {
    try {
      this.logger.info('Backing up thumbnails', { type })

      const thumbnailsDir = `${backupPath}/${this.THUMBNAILS_DIR_NAME}`
      await this.ensureDirectoryExists(thumbnailsDir)

      // 获取所有照片记录（包含缩略图信息）
      const photos = await this.databaseService.getAll('photos') as Photo[]
      let count = 0
      const checksums: string[] = []

      for (const photo of photos) {
        if (photo.thumbnailPath && this.fileService.fileExists(photo.thumbnailPath)) {
          const fileName = `${photo.id}_${this.getFileName(photo.thumbnailPath)}`
          const backupThumbnailPath = `${thumbnailsDir}/${fileName}`

          // 复制缩略图文件
          const result = await this.fileService.moveFile(photo.thumbnailPath, backupThumbnailPath)
          if (result.success) {
            count++
            const checksum = await this.calculateFileChecksum(backupThumbnailPath)
            checksums.push(checksum)

            // 恢复原文件
            await this.fileService.moveFile(backupThumbnailPath, photo.thumbnailPath)

            // 再次复制到备份位置
            await this.fileService.moveFile(photo.thumbnailPath, backupThumbnailPath)
          }
        }
      }

      this.logger.info('Thumbnails backup completed', { count })

      return { count, checksums }
    } catch (error) {
      this.logger.error('Failed to backup thumbnails', error)
      throw error
    }
  }

  /**
   * 备份设置
   */
  private async backupSettings(backupPath: string): Promise<void> {
    try {
      this.logger.info('Backing up settings')

      const settingsPath = `${backupPath}/${this.SETTINGS_FILE_NAME}`
      const settings = await this.exportSettings()

      const settingsData = JSON.stringify(settings, null, 2)
      const settingsFile = fileIo.openSync(settingsPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      fileIo.writeSync(settingsFile.fd, settingsData)
      fileIo.closeSync(settingsFile)

      this.logger.info('Settings backup completed')
    } catch (error) {
      this.logger.error('Failed to backup settings', error)
      throw error
    }
  }

  /**
   * 导出设置
   */
  private async exportSettings(): Promise<Record<string, any>> {
    // 这里可以从GlobalStore或其他地方获取设置
    // 暂时返回空对象
    return {
      version: this.BACKUP_VERSION,
      exportedAt: new Date().toISOString(),
      settings: {}
    }
  }

  /**
   * 保存备份配置
   */
  private async saveBackupConfig(config: BackupConfig, configPath: string): Promise<void> {
    const configData = JSON.stringify(config, null, 2)
    const configFile = fileIo.openSync(configPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
    fileIo.writeSync(configFile.fd, configData)
    fileIo.closeSync(configFile)
  }

  /**
   * 计算文件校验和
   */
  private async calculateFileChecksum(filePath: string): Promise<string> {
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      const buffer = new ArrayBuffer(4096)
      let hash = 0

      let readSize = 0
      do {
        readSize = fileIo.readSync(file.fd, buffer)
        if (readSize > 0) {
          // 简单的哈希算法（实际应用中应使用更强的算法如SHA-256）
          const data = new Uint8Array(buffer, 0, readSize)
          for (let i = 0; i < data.length; i++) {
            hash = ((hash << 5) - hash + data[i]) & 0xffffffff
          }
        }
      } while (readSize > 0)

      fileIo.closeSync(file)
      return Math.abs(hash).toString(16)
    } catch (error) {
      this.logger.error('Failed to calculate file checksum', { filePath, error })
      return ''
    }
  }

  /**
   * 计算目录大小
   */
  private async calculateDirectorySize(dirPath: string): Promise<number> {
    try {
      let totalSize = 0
      const entries = fileIo.listFileSync(dirPath)

      for (const entry of entries) {
        const fullPath = `${dirPath}/${entry}`
        try {
          const stat = fileIo.statSync(fullPath)
          if (stat.size > 0) {
            totalSize += stat.size
          }
        } catch (error) {
          this.logger.warn('Failed to get file stat', { path: fullPath, error })
        }
      }

      return totalSize
    } catch (error) {
      this.logger.error('Failed to calculate directory size', { dirPath, error })
      return 0
    }
  }

  /**
   * 获取文件名
   */
  private getFileName(filePath: string): string {
    return filePath.split('/').pop() || 'unknown'
  }

  /**
   * 清理失败的备份
   */
  private async cleanupFailedBackup(backupPath: string): Promise<void> {
    try {
      const entries = fileIo.listFileSync(backupPath)
      for (const entry of entries) {
        const fullPath = `${backupPath}/${entry}`
        fileIo.unlinkSync(fullPath)
      }
      fileIo.rmdirSync(backupPath)
      this.logger.info('Failed backup cleaned up', { backupPath })
    } catch (error) {
      this.logger.error('Failed to cleanup backup directory', { backupPath, error })
    }
  }

  /**
   * 恢复数据
   */
  async restoreFromBackup(
    backupPath: string,
    options: RestoreOptions
  ): Promise<RestoreResult> {
    try {
      this.logger.info('Starting restore from backup', { backupPath, options })

      // 验证备份
      const validation = await this.validateBackup(backupPath)
      if (!validation.valid) {
        throw new Error(`Backup validation failed: ${validation.issues.join(', ')}`)
      }

      // 加载备份配置
      const config = await this.loadBackupConfig(backupPath)
      if (!config) {
        throw new Error('Failed to load backup configuration')
      }

      const result: RestoreResult = {
        success: true,
        restoredItems: {
          photos: 0,
          thumbnails: 0,
          databaseRecords: 0,
          settings: 0
        },
        skippedItems: {
          photos: 0,
          thumbnails: 0,
          databaseRecords: 0
        },
        errors: []
      }

      // 恢复数据库
      if (options.restoreDatabase && config.options.includeDatabase) {
        const dbResult = await this.restoreDatabase(backupPath, options.overwriteExisting)
        result.restoredItems.databaseRecords = dbResult.recordsRestored
        result.errors.push(...dbResult.errors)
      }

      // 恢复照片
      if (options.restorePhotos && config.options.includePhotos) {
        const photoResult = await this.restorePhotos(backupPath, options)
        result.restoredItems.photos = photoResult.restored
        result.skippedItems.photos = photoResult.skipped
        result.errors.push(...photoResult.errors)
      }

      // 恢复缩略图
      if (options.restoreThumbnails && config.options.includeThumbnails) {
        const thumbnailResult = await this.restoreThumbnails(backupPath, options)
        result.restoredItems.thumbnails = thumbnailResult.restored
        result.skippedItems.thumbnails = thumbnailResult.skipped
        result.errors.push(...thumbnailResult.errors)
      }

      // 恢复设置
      if (options.restoreSettings && config.options.includeSettings) {
        const settingsResult = await this.restoreSettings(backupPath)
        result.restoredItems.settings = settingsResult.count
        result.errors.push(...settingsResult.errors)
      }

      result.success = result.errors.length === 0

      this.logger.info('Restore completed', {
        success: result.success,
        restoredItems: result.restoredItems,
        errorsCount: result.errors.length
      })

      return result

    } catch (error) {
      this.logger.error('Failed to restore from backup', { backupPath, error })
      return {
        success: false,
        restoredItems: { photos: 0, thumbnails: 0, databaseRecords: 0, settings: 0 },
        skippedItems: { photos: 0, thumbnails: 0, databaseRecords: 0 },
        errors: [error instanceof Error ? error.message : String(error)]
      }
    }
  }

  /**
   * 验证备份
   */
  async validateBackup(backupPath: string): Promise<ValidationResult> {
    const result: ValidationResult = {
      valid: true,
      issues: [],
      warnings: [],
      missingFiles: [],
      corruptedFiles: [],
      checksumMatch: true
    }

    try {
      this.logger.info('Validating backup', { backupPath })

      // 检查配置文件
      const configPath = `${backupPath}/${this.CONFIG_FILE_NAME}`
      if (!this.fileService.fileExists(configPath)) {
        result.valid = false
        result.issues.push('Backup configuration file is missing')
        result.missingFiles.push(this.CONFIG_FILE_NAME)
        return result
      }

      // 加载配置
      const config = await this.loadBackupConfig(backupPath)
      if (!config) {
        result.valid = false
        result.issues.push('Failed to load backup configuration')
        return result
      }

      // 检查版本兼容性
      if (config.version !== this.BACKUP_VERSION) {
        result.warnings.push(`Backup version ${config.version} may not be compatible with current version ${this.BACKUP_VERSION}`)
      }

      // 验证文件校验和
      if (config.checksums.config) {
        const actualChecksum = await this.calculateFileChecksum(configPath)
        if (actualChecksum !== config.checksums.config) {
          result.valid = false
          result.issues.push('Configuration file checksum mismatch')
          result.corruptedFiles.push(this.CONFIG_FILE_NAME)
          result.checksumMatch = false
        }
      }

      // 验证数据库文件
      if (config.options.includeDatabase) {
        const dbPath = `${backupPath}/${this.DATABASE_FILE_NAME}`
        if (!this.fileService.fileExists(dbPath)) {
          result.valid = false
          result.issues.push('Database file is missing')
          result.missingFiles.push(this.DATABASE_FILE_NAME)
        } else if (config.checksums.database) {
          const actualChecksum = await this.calculateFileChecksum(dbPath)
          if (actualChecksum !== config.checksums.database) {
            result.valid = false
            result.issues.push('Database file checksum mismatch')
            result.corruptedFiles.push(this.DATABASE_FILE_NAME)
          }
        }
      }

      // 验证照片目录
      if (config.options.includePhotos) {
        const photosDir = `${backupPath}/${this.PHOTOS_DIR_NAME}`
        if (!this.fileService.fileExists(photosDir)) {
          result.valid = false
          result.issues.push('Photos directory is missing')
          result.missingFiles.push(this.PHOTOS_DIR_NAME)
        }
      }

      // 验证缩略图目录
      if (config.options.includeThumbnails) {
        const thumbnailsDir = `${backupPath}/${this.THUMBNAILS_DIR_NAME}`
        if (!this.fileService.fileExists(thumbnailsDir)) {
          result.valid = false
          result.issues.push('Thumbnails directory is missing')
          result.missingFiles.push(this.THUMBNAILS_DIR_NAME)
        }
      }

      this.logger.info('Backup validation completed', {
        valid: result.valid,
        issuesCount: result.issues.length,
        warningsCount: result.warnings.length
      })

    } catch (error) {
      this.logger.error('Backup validation failed', error)
      result.valid = false
      result.issues.push(`Validation error: ${error instanceof Error ? error.message : String(error)}`)
    }

    return result
  }

  /**
   * 加载备份配置
   */
  private async loadBackupConfig(backupPath: string): Promise<BackupConfig | null> {
    try {
      const configPath = `${backupPath}/${this.CONFIG_FILE_NAME}`
      const configFile = fileIo.openSync(configPath, fileIo.OpenMode.READ_ONLY)
      const buffer = new ArrayBuffer(fileIo.statSync(configPath).size)
      fileIo.readSync(configFile.fd, buffer)
      fileIo.closeSync(configFile)

      const configData = new Uint8Array(buffer)
      const configString = String.fromCharCode(...configData)
      return JSON.parse(configString) as BackupConfig
    } catch (error) {
      this.logger.error('Failed to load backup config', error)
      return null
    }
  }

  /**
   * 恢复数据库
   */
  private async restoreDatabase(
    backupPath: string,
    overwrite: boolean
  ): Promise<{ recordsRestored: number; errors: string[] }> {
    try {
      this.logger.info('Restoring database')

      const backupDbPath = `${backupPath}/${this.DATABASE_FILE_NAME}`
      const currentDbPath = this.databaseService.getDatabasePath()

      if (!overwrite && this.fileService.fileExists(currentDbPath)) {
        return { recordsRestored: 0, errors: ['Database already exists and overwrite is disabled'] }
      }

      // 关闭当前数据库连接
      await this.databaseService.close()

      // 备份当前数据库（如果存在）
      if (this.fileService.fileExists(currentDbPath)) {
        const backupCurrentDbPath = `${currentDbPath}.backup_${Date.now()}`
        await this.fileService.moveFile(currentDbPath, backupCurrentDbPath)
      }

      // 恢复数据库
      const result = await this.fileService.moveFile(backupDbPath, currentDbPath)
      if (!result.success) {
        return { recordsRestored: 0, errors: [result.error || 'Unknown error'] }
      }

      // 重新打开数据库连接
      await this.databaseService.initialize()

      const recordCount = await this.getDatabaseRecordCount()

      this.logger.info('Database restore completed', { recordsRestored: recordCount })

      return { recordsRestored: recordCount, errors: [] }
    } catch (error) {
      this.logger.error('Failed to restore database', error)
      return { recordsRestored: 0, errors: [error instanceof Error ? error.message : String(error)] }
    }
  }

  /**
   * 恢复照片
   */
  private async restorePhotos(
    backupPath: string,
    options: RestoreOptions
  ): Promise<{ restored: number; skipped: number; errors: string[] }> {
    try {
      this.logger.info('Restoring photos')

      const photosDir = `${backupPath}/${this.PHOTOS_DIR_NAME}`
      const appPhotosDir = this.fileService['photoDir'] || `${this.context?.filesDir}/photos`

      let restored = 0
      let skipped = 0
      const errors: string[] = []

      if (!fileIo.accessSync(photosDir)) {
        return { restored: 0, skipped: 0, errors: ['Photos directory not found in backup'] }
      }

      const entries = fileIo.listFileSync(photosDir)

      for (const entry of entries) {
        try {
          const backupPhotoPath = `${photosDir}/${entry}`
          const targetPhotoPath = `${appPhotosDir}/${entry}`

          // 检查目标文件是否已存在
          if (!options.overwriteExisting && this.fileService.fileExists(targetPhotoPath)) {
            skipped++
            continue
          }

          // 恢复照片文件
          const result = await this.fileService.moveFile(backupPhotoPath, targetPhotoPath)
          if (result.success) {
            restored++
          } else {
            errors.push(`Failed to restore photo ${entry}: ${result.error}`)
          }
        } catch (error) {
          errors.push(`Error restoring photo ${entry}: ${error instanceof Error ? error.message : String(error)}`)
        }
      }

      this.logger.info('Photos restore completed', { restored, skipped, errorsCount: errors.length })

      return { restored, skipped, errors }
    } catch (error) {
      this.logger.error('Failed to restore photos', error)
      return { restored: 0, skipped: 0, errors: [error instanceof Error ? error.message : String(error)] }
    }
  }

  /**
   * 恢复缩略图
   */
  private async restoreThumbnails(
    backupPath: string,
    options: RestoreOptions
  ): Promise<{ restored: number; skipped: number; errors: string[] }> {
    try {
      this.logger.info('Restoring thumbnails')

      const thumbnailsDir = `${backupPath}/${this.THUMBNAILS_DIR_NAME}`
      const appThumbnailsDir = this.fileService['thumbnailDir'] || `${this.context?.filesDir}/thumbnails`

      let restored = 0
      let skipped = 0
      const errors: string[] = []

      if (!fileIo.accessSync(thumbnailsDir)) {
        return { restored: 0, skipped: 0, errors: ['Thumbnails directory not found in backup'] }
      }

      const entries = fileIo.listFileSync(thumbnailsDir)

      for (const entry of entries) {
        try {
          const backupThumbnailPath = `${thumbnailsDir}/${entry}`
          const targetThumbnailPath = `${appThumbnailsDir}/${entry}`

          // 检查目标文件是否已存在
          if (!options.overwriteExisting && this.fileService.fileExists(targetThumbnailPath)) {
            skipped++
            continue
          }

          // 恢复缩略图文件
          const result = await this.fileService.moveFile(backupThumbnailPath, targetThumbnailPath)
          if (result.success) {
            restored++
          } else {
            errors.push(`Failed to restore thumbnail ${entry}: ${result.error}`)
          }
        } catch (error) {
          errors.push(`Error restoring thumbnail ${entry}: ${error instanceof Error ? error.message : String(error)}`)
        }
      }

      this.logger.info('Thumbnails restore completed', { restored, skipped, errorsCount: errors.length })

      return { restored, skipped, errors }
    } catch (error) {
      this.logger.error('Failed to restore thumbnails', error)
      return { restored: 0, skipped: 0, errors: [error instanceof Error ? error.message : String(error)] }
    }
  }

  /**
   * 恢复设置
   */
  private async restoreSettings(backupPath: string): Promise<{ count: number; errors: string[] }> {
    try {
      this.logger.info('Restoring settings')

      const settingsPath = `${backupPath}/${this.SETTINGS_FILE_NAME}`
      const errors: string[] = []

      if (!this.fileService.fileExists(settingsPath)) {
        return { count: 0, errors: ['Settings file not found in backup'] }
      }

      const settingsFile = fileIo.openSync(settingsPath, fileIo.OpenMode.READ_ONLY)
      const buffer = new ArrayBuffer(fileIo.statSync(settingsPath).size)
      fileIo.readSync(settingsFile.fd, buffer)
      fileIo.closeSync(settingsFile)

      const settingsData = new Uint8Array(buffer)
      const settingsString = String.fromCharCode(...settingsData)
      const settings = JSON.parse(settingsString)

      // 这里应该将设置应用到GlobalStore或其他地方
      // 暂时只记录日志
      this.logger.info('Settings restored', { settings })

      return { count: 1, errors }
    } catch (error) {
      this.logger.error('Failed to restore settings', error)
      return { count: 0, errors: [error instanceof Error ? error.message : String(error)] }
    }
  }

  /**
   * 获取所有备份列表
   */
  async getBackupList(): Promise<BackupInfo[]> {
    try {
      const backups: BackupInfo[] = []
      const entries = fileIo.listFileSync(this.backupDir)

      for (const entry of entries) {
        const backupPath = `${this.backupDir}/${entry}`
        try {
          const config = await this.loadBackupConfig(backupPath)
          if (config) {
            const size = await this.calculateDirectorySize(backupPath)
            const backupInfo: BackupInfo = {
              id: entry,
              type: config.type,
              name: `Backup ${entry}`,
              description: '',
              createdAt: new Date(config.createdAt),
              size,
              path: backupPath,
              version: config.version,
              checksum: config.checksums.config,
              itemCounts: config.itemCounts,
              options: config.options
            }
            backups.push(backupInfo)
          }
        } catch (error) {
          this.logger.warn('Failed to load backup info', { entry, error })
        }
      }

      // 按创建时间排序（最新的在前）
      backups.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())

      return backups
    } catch (error) {
      this.logger.error('Failed to get backup list', error)
      return []
    }
  }

  /**
   * 删除备份
   */
  async deleteBackup(backupId: string): Promise<boolean> {
    try {
      const backupPath = `${this.backupDir}/${backupId}`

      if (!this.fileService.fileExists(backupPath)) {
        return false
      }

      // 递归删除目录内容
      const entries = fileIo.listFileSync(backupPath)
      for (const entry of entries) {
        const filePath = `${backupPath}/${entry}`
        fileIo.unlinkSync(filePath)
      }

      // 删除目录
      fileIo.rmdirSync(backupPath)

      this.logger.info('Backup deleted', { backupId })
      return true
    } catch (error) {
      this.logger.error('Failed to delete backup', { backupId, error })
      return false
    }
  }

  /**
   * 获取备份统计信息
   */
  async getBackupStats(): Promise<{
    totalBackups: number
    totalSize: number
    oldestBackup: Date | null
    newestBackup: Date | null
    backupTypes: Record<BackupType, number>
  }> {
    try {
      const backups = await this.getBackupList()
      const totalBackups = backups.length
      const totalSize = backups.reduce((sum, backup) => sum + backup.size, 0)

      const backupTypes: Record<BackupType, number> = {
        [BackupType.FULL]: 0,
        [BackupType.INCREMENTAL]: 0,
        [BackupType.DIFFERENTIAL]: 0
      }

      let oldestBackup: Date | null = null
      let newestBackup: Date | null = null

      for (const backup of backups) {
        backupTypes[backup.type]++

        if (!oldestBackup || backup.createdAt < oldestBackup) {
          oldestBackup = backup.createdAt
        }

        if (!newestBackup || backup.createdAt > newestBackup) {
          newestBackup = backup.createdAt
        }
      }

      return {
        totalBackups,
        totalSize,
        oldestBackup,
        newestBackup,
        backupTypes
      }
    } catch (error) {
      this.logger.error('Failed to get backup stats', error)
      return {
        totalBackups: 0,
        totalSize: 0,
        oldestBackup: null,
        newestBackup: null,
        backupTypes: {
          [BackupType.FULL]: 0,
          [BackupType.INCREMENTAL]: 0,
          [BackupType.DIFFERENTIAL]: 0
        }
      }
    }
  }
}