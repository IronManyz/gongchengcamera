/**
 * 文件操作服务
 * 提供照片存储、缩略图生成、文件清理等功能
 */

import { fileIo } from '@ohos.file.fs'
import { photoAccessHelper } from '@ohos.file.photoAccessHelper'
import { image } from '@kit.ImageKit'
import { picker } from '@ohos.file.picker'
import { BusinessError } from '@kit.BasicServicesKit'
import { Context } from '@ohos.abilityAccessCtrl'
import { Photo } from '../../models/Photo'
import { Logger } from '../../utils/Logger'

/**
 * 文件操作结果
 */
export interface FileOperationResult {
  success: boolean
  path?: string
  error?: string
  size?: number
}

/**
 * 缩略图配置
 */
export interface ThumbnailConfig {
  width: number
  height: number
  quality: number // 0-100
  format: 'jpeg' | 'png' | 'webp'
}

/**
 * 文件信息
 */
export interface FileInfo {
  uri: string
  path: string
  name: string
  size: number
  mimeType: string
  createdAt: Date
  modifiedAt: Date
}

/**
 * 文件清理配置
 */
export interface CleanupConfig {
  maxAge: number // 文件最大保存天数
  maxSize: number // 文件最大大小(MB)
  maxCount: number // 最大文件数量
  deleteThumbnails: boolean // 是否删除缩略图
}

export class FileService {
  private static instance: FileService | null = null
  private context: Context | null = null
  private readonly logger = new Logger('FileService')

  // 默认缩略图配置
  private readonly defaultThumbnailConfig: ThumbnailConfig = {
    width: 200,
    height: 200,
    quality: 85,
    format: 'jpeg'
  }

  // 应用文件目录
  private appDir: string = ''
  private photoDir: string = ''
  private thumbnailDir: string = ''
  private tempDir: string = ''
  private backupDir: string = ''

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): FileService {
    if (!FileService.instance) {
      FileService.instance = new FileService()
    }
    return FileService.instance
  }

  /**
   * 初始化文件服务
   */
  async initialize(context: Context): Promise<void> {
    this.context = context
    await this.initializeDirectories()
    this.logger.info('FileService initialized successfully')
  }

  /**
   * 初始化文件目录
   */
  private async initializeDirectories(): Promise<void> {
    if (!this.context) {
      throw new Error('Context not initialized')
    }

    try {
      // 获取应用文件目录
      this.appDir = this.context.filesDir

      // 创建子目录
      this.photoDir = `${this.appDir}/photos`
      this.thumbnailDir = `${this.appDir}/thumbnails`
      this.tempDir = `${this.appDir}/temp`
      this.backupDir = `${this.appDir}/backup`

      // 确保目录存在
      await this.ensureDirectoryExists(this.photoDir)
      await this.ensureDirectoryExists(this.thumbnailDir)
      await this.ensureDirectoryExists(this.tempDir)
      await this.ensureDirectoryExists(this.backupDir)

      this.logger.info('Directories initialized', {
        appDir: this.appDir,
        photoDir: this.photoDir,
        thumbnailDir: this.thumbnailDir,
        tempDir: this.tempDir,
        backupDir: this.backupDir
      })
    } catch (error) {
      this.logger.error('Failed to initialize directories', error)
      throw error
    }
  }

  /**
   * 确保目录存在
   */
  private async ensureDirectoryExists(dirPath: string): Promise<void> {
    try {
      await fileIo.mkdir(dirPath)
    } catch (error) {
      const err = error as BusinessError
      if (err.code !== 201800) { // 201800: 目录已存在
        this.logger.error(`Failed to create directory: ${dirPath}`, error)
        throw error
      }
    }
  }

  /**
   * 保存照片文件
   */
  async savePhoto(sourceUri: string, projectId: string, siteId: string): Promise<FileOperationResult> {
    try {
      this.logger.info('Saving photo', { sourceUri, projectId, siteId })

      // 生成文件名
      const fileName = this.generatePhotoFileName(projectId, siteId)
      const targetPath = `${this.photoDir}/${fileName}`

      // 复制文件
      const copyResult = await this.copyFile(sourceUri, targetPath)
      if (!copyResult.success) {
        return copyResult
      }

      // 获取文件信息
      const fileInfo = await this.getFileInfo(targetPath)

      this.logger.info('Photo saved successfully', {
        path: targetPath,
        size: fileInfo.size
      })

      return {
        success: true,
        path: targetPath,
        size: fileInfo.size
      }
    } catch (error) {
      this.logger.error('Failed to save photo', error)
      return {
        success: false,
        error: `保存照片失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 生成照片文件名
   */
  private generatePhotoFileName(projectId: string, siteId: string): string {
    const now = new Date()
    const timestamp = now.getTime()
    const dateStr = now.toISOString().split('T')[0] // YYYY-MM-DD
    const randomStr = Math.random().toString(36).substring(2, 8)

    return `${dateStr}_${projectId}_${siteId}_${timestamp}_${randomStr}.jpg`
  }

  /**
   * 复制文件
   */
  private async copyFile(sourceUri: string, targetPath: string): Promise<FileOperationResult> {
    try {
      // 打开源文件
      const sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)

      // 创建目标文件
      const targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)

      // 复制内容
      const buffer = new ArrayBuffer(4096)
      let readSize = 0

      do {
        readSize = fileIo.readSync(sourceFile.fd, buffer)
        if (readSize > 0) {
          fileIo.writeSync(targetFile.fd, buffer, { length: readSize })
        }
      } while (readSize > 0)

      // 关闭文件
      fileIo.closeSync(sourceFile)
      fileIo.closeSync(targetFile)

      return { success: true, path: targetPath }
    } catch (error) {
      this.logger.error('Failed to copy file', { sourceUri, targetPath, error })
      return {
        success: false,
        error: `文件复制失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 生成缩略图
   */
  async generateThumbnail(
    sourcePath: string,
    config: Partial<ThumbnailConfig> = {}
  ): Promise<FileOperationResult> {
    try {
      const finalConfig = { ...this.defaultThumbnailConfig, ...config }
      this.logger.info('Generating thumbnail', { sourcePath, config: finalConfig })

      // 生成缩略图文件名
      const fileName = this.getFileName(sourcePath)
      const thumbnailName = `thumb_${fileName}`
      const thumbnailPath = `${this.thumbnailDir}/${thumbnailName}`

      // 使用ImageKit生成缩略图
      const imagePackerApi = image.createImagePacker()
      const imageSourceApi = image.createImageSource(sourcePath)

      // 获取原始图片信息
      const imageInfo = await imageSourceApi.getImageInfo()
      this.logger.info('Original image info', imageInfo)

      // 创建缩略图
      const packOpts: image.PackingOption = {
        format: finalConfig.format === 'jpeg' ? 'image/jpeg' :
                finalConfig.format === 'png' ? 'image/png' : 'image/webp',
        quality: finalConfig.quality
      }

      // 计算缩略图尺寸（保持宽高比）
      const { width, height } = this.calculateThumbnailSize(
        imageInfo.size.width,
        imageInfo.size.height,
        finalConfig.width,
        finalConfig.height
      )

      // 生成像素数据
      const pixelMap = await imageSourceApi.createPixelMap({
        desiredSize: { width, height }
      })

      // 打包缩略图
      const data = await imagePackerApi.packing(pixelMap, packOpts)

      // 保存缩略图
      const targetFile = fileIo.openSync(thumbnailPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      fileIo.writeSync(targetFile.fd, data)
      fileIo.closeSync(targetFile)

      // 释放资源
      await pixelMap.release()
      imagePackerApi.release()

      const fileInfo = await this.getFileInfo(thumbnailPath)

      this.logger.info('Thumbnail generated successfully', {
        path: thumbnailPath,
        size: fileInfo.size,
        dimensions: `${width}x${height}`
      })

      return {
        success: true,
        path: thumbnailPath,
        size: fileInfo.size
      }
    } catch (error) {
      this.logger.error('Failed to generate thumbnail', { sourcePath, error })
      return {
        success: false,
        error: `生成缩略图失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 计算缩略图尺寸（保持宽高比）
   */
  private calculateThumbnailSize(
    originalWidth: number,
    originalHeight: number,
    maxWidth: number,
    maxHeight: number
  ): { width: number; height: number } {
    const aspectRatio = originalWidth / originalHeight

    let width = originalWidth
    let height = originalHeight

    // 按宽度缩放
    if (width > maxWidth) {
      width = maxWidth
      height = Math.round(width / aspectRatio)
    }

    // 按高度缩放
    if (height > maxHeight) {
      height = maxHeight
      width = Math.round(height * aspectRatio)
    }

    return { width, height }
  }

  /**
   * 获取文件名（不含路径）
   */
  private getFileName(filePath: string): string {
    return filePath.split('/').pop() || 'unknown'
  }

  /**
   * 获取文件信息
   */
  async getFileInfo(filePath: string): Promise<FileInfo> {
    try {
      const stat = fileIo.statSync(filePath)
      const uri = `file://${filePath}`
      const name = this.getFileName(filePath)

      // 简单的MIME类型判断
      let mimeType = 'application/octet-stream'
      if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
        mimeType = 'image/jpeg'
      } else if (name.endsWith('.png')) {
        mimeType = 'image/png'
      } else if (name.endsWith('.webp')) {
        mimeType = 'image/webp'
      }

      return {
        uri,
        path: filePath,
        name,
        size: stat.size,
        mimeType,
        createdAt: new Date(stat.ctime * 1000),
        modifiedAt: new Date(stat.mtime * 1000)
      }
    } catch (error) {
      this.logger.error('Failed to get file info', { filePath, error })
      throw error
    }
  }

  /**
   * 删除文件
   */
  async deleteFile(filePath: string): Promise<boolean> {
    try {
      fileIo.unlinkSync(filePath)
      this.logger.info('File deleted successfully', { filePath })
      return true
    } catch (error) {
      this.logger.error('Failed to delete file', { filePath, error })
      return false
    }
  }

  /**
   * 批量删除文件
   */
  async deleteFiles(filePaths: string[]): Promise<{ success: number; failed: number }> {
    let success = 0
    let failed = 0

    for (const filePath of filePaths) {
      const result = await this.deleteFile(filePath)
      if (result) {
        success++
      } else {
        failed++
      }
    }

    this.logger.info('Batch delete completed', { total: filePaths.length, success, failed })
    return { success, failed }
  }

  /**
   * 清理过期文件
   */
  async cleanupFiles(config: CleanupConfig): Promise<FileOperationResult> {
    try {
      this.logger.info('Starting file cleanup', config)

      const photosToDelete: string[] = []
      const thumbnailsToDelete: string[] = []
      let totalSizeFreed = 0

      // 扫描照片目录
      const photoFiles = await this.scanDirectory(this.photoDir)
      const now = new Date()

      for (const file of photoFiles) {
        const ageInDays = (now.getTime() - file.createdAt.getTime()) / (1000 * 60 * 60 * 24)
        const ageInYears = ageInDays / 365
        const sizeInMB = file.size / (1024 * 1024)

        // 检查是否需要删除
        if (ageInYears > config.maxAge ||
            sizeInMB > config.maxSize ||
            photoFiles.length > config.maxCount) {
          photosToDelete.push(file.path)
          totalSizeFreed += file.size

          // 如果配置要求删除缩略图，添加到删除列表
          if (config.deleteThumbnails) {
            const thumbnailPath = `${this.thumbnailDir}/thumb_${file.name}`
            thumbnailsToDelete.push(thumbnailPath)
          }
        }
      }

      // 删除照片文件
      const photoDeleteResult = await this.deleteFiles(photosToDelete)

      // 删除缩略图文件
      const thumbnailDeleteResult = await this.deleteFiles(thumbnailsToDelete)

      this.logger.info('Cleanup completed', {
        photosDeleted: photoDeleteResult.success,
        thumbnailsDeleted: thumbnailDeleteResult.success,
        sizeFreed: totalSizeFreed
      })

      return {
        success: true,
        error: `清理完成: 删除了 ${photoDeleteResult.success} 张照片和 ${thumbnailDeleteResult.success} 个缩略图，释放了 ${(totalSizeFreed / 1024 / 1024).toFixed(2)} MB 空间`
      }
    } catch (error) {
      this.logger.error('Failed to cleanup files', error)
      return {
        success: false,
        error: `文件清理失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 扫描目录
   */
  private async scanDirectory(dirPath: string): Promise<FileInfo[]> {
    const files: FileInfo[] = []

    try {
      const entries = fileIo.listFileSync(dirPath)

      for (const entry of entries) {
        const fullPath = `${dirPath}/${entry}`
        try {
          const fileInfo = await this.getFileInfo(fullPath)
          // 只包含文件，不包含目录
          if (fileInfo.size > 0) {
            files.push(fileInfo)
          }
        } catch (error) {
          this.logger.warn('Failed to get file info during scan', { path: fullPath, error })
        }
      }
    } catch (error) {
      this.logger.error('Failed to scan directory', { dirPath, error })
    }

    return files
  }

  /**
   * 检查文件是否存在
   */
  fileExists(filePath: string): boolean {
    try {
      fileIo.accessSync(filePath)
      return true
    } catch {
      return false
    }
  }

  /**
   * 获取目录大小
   */
  async getDirectorySize(dirPath: string): Promise<number> {
    try {
      const files = await this.scanDirectory(dirPath)
      return files.reduce((total, file) => total + file.size, 0)
    } catch (error) {
      this.logger.error('Failed to get directory size', { dirPath, error })
      return 0
    }
  }

  /**
   * 创建临时文件
   */
  async createTempFile(fileName: string): Promise<string> {
    const tempPath = `${this.tempDir}/${fileName}`

    try {
      const tempFile = fileIo.openSync(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      fileIo.closeSync(tempFile)
      return tempPath
    } catch (error) {
      this.logger.error('Failed to create temp file', { fileName, error })
      throw error
    }
  }

  /**
   * 清理临时文件
   */
  async cleanupTempFiles(): Promise<void> {
    try {
      const tempFiles = await this.scanDirectory(this.tempDir)
      const filePaths = tempFiles.map(file => file.path)
      await this.deleteFiles(filePaths)
      this.logger.info('Temp files cleaned up', { count: filePaths.length })
    } catch (error) {
      this.logger.error('Failed to cleanup temp files', error)
    }
  }

  /**
   * 移动文件
   */
  async moveFile(sourcePath: string, targetPath: string): Promise<FileOperationResult> {
    try {
      fileIo.moveFileSync(sourcePath, targetPath)
      this.logger.info('File moved successfully', { from: sourcePath, to: targetPath })

      const fileInfo = await this.getFileInfo(targetPath)
      return {
        success: true,
        path: targetPath,
        size: fileInfo.size
      }
    } catch (error) {
      this.logger.error('Failed to move file', { sourcePath, targetPath, error })
      return {
        success: false,
        error: `文件移动失败: ${error instanceof Error ? error.message : String(error)}`
      }
    }
  }

  /**
   * 获取存储统计信息
   */
  async getStorageStats(): Promise<{
    totalSize: number
    photoCount: number
    thumbnailCount: number
    tempCount: number
    photoSize: number
    thumbnailSize: number
    tempSize: number
  }> {
    try {
      const photoFiles = await this.scanDirectory(this.photoDir)
      const thumbnailFiles = await this.scanDirectory(this.thumbnailDir)
      const tempFiles = await this.scanDirectory(this.tempDir)

      const photoSize = photoFiles.reduce((total, file) => total + file.size, 0)
      const thumbnailSize = thumbnailFiles.reduce((total, file) => total + file.size, 0)
      const tempSize = tempFiles.reduce((total, file) => total + file.size, 0)

      return {
        totalSize: photoSize + thumbnailSize + tempSize,
        photoCount: photoFiles.length,
        thumbnailCount: thumbnailFiles.length,
        tempCount: tempFiles.length,
        photoSize,
        thumbnailSize,
        tempSize
      }
    } catch (error) {
      this.logger.error('Failed to get storage stats', error)
      return {
        totalSize: 0,
        photoCount: 0,
        thumbnailCount: 0,
        tempCount: 0,
        photoSize: 0,
        thumbnailSize: 0,
        tempSize: 0
      }
    }
  }

  /**
   * 验证照片文件完整性
   */
  async validatePhotoFile(filePath: string): Promise<boolean> {
    try {
      // 检查文件是否存在
      if (!this.fileExists(filePath)) {
        return false
      }

      // 尝试创建图片源来验证文件完整性
      const imageSource = image.createImageSource(filePath)
      const imageInfo = await imageSource.getImageInfo()

      // 检查基本的图片信息
      return !!(imageInfo.size.width > 0 && imageInfo.size.height > 0)
    } catch (error) {
      this.logger.warn('Photo file validation failed', { filePath, error })
      return false
    }
  }

  /**
   * 修复文件路径（如果文件不存在）
   */
  async fixPhotoFilePath(photo: Photo): Promise<boolean> {
    if (this.fileExists(photo.filePath)) {
      return true
    }

    this.logger.warn('Photo file not found, attempting to fix', {
      photoId: photo.id,
      originalPath: photo.filePath
    })

    try {
      // 如果缩略图存在但原图不存在，可以从缩略图恢复基本信息
      if (photo.hasThumbnail() && this.fileExists(photo.thumbnailPath)) {
        this.logger.info('Thumbnail exists but original file lost', {
          photoId: photo.id,
          thumbnailPath: photo.thumbnailPath
        })
        // 这里可以添加从缩略图恢复的逻辑
        return false
      }

      return false
    } catch (error) {
      this.logger.error('Failed to fix photo file path', { photoId: photo.id, error })
      return false
    }
  }

  /**
   * 获取文件扩展名
   */
  private getFileExtension(fileName: string): string {
    const lastDot = fileName.lastIndexOf('.')
    return lastDot > -1 ? fileName.substring(lastDot + 1).toLowerCase() : ''
  }
}