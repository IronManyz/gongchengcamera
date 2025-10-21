/**
 * 照片数据服务
 * 提供照片的CRUD操作和业务逻辑处理
 */

import { hilog } from '@ohos.log'
import {
  databaseService,
  DatabaseError,
  QueryParams,
  PaginationParams,
  PaginationResult
} from './DatabaseService'
import { Photo } from '../../models/Photo'
import {
  TABLE_NAMES,
  PHOTO_FIELDS,
  PROJECT_FIELDS,
  SITE_FIELDS,
  DATA_TYPES,
  DEFAULT_VALUES,
  ERROR_CODES,
  PAGINATION,
  SORT_DIRECTIONS
} from '../../constants/DatabaseConstants'

/**
 * 照片查询条件接口
 */
export interface PhotoQueryParams extends QueryParams {
  projectId?: string
  siteId?: string
  templateId?: string
  tags?: string[]
  dateRange?: { start?: Date; end?: Date }
  hasLocation?: boolean
  isEdited?: boolean
  notesKeyword?: string
}

/**
 * 照片服务类
 */
export class PhotoService {
  private static instance: PhotoService | null = null
  private readonly TAG = 'PhotoService'

  static getInstance(): PhotoService {
    if (!PhotoService.instance) {
      PhotoService.instance = new PhotoService()
    }
    return PhotoService.instance
  }

  private constructor() {}

  /**
   * 创建新照片记录
   */
  async createPhoto(photo: Photo): Promise<Photo> {
    try {
      hilog.info(0x0000, this.TAG, `创建照片记录: ${photo.id}`)

      if (!photo.isValid()) {
        throw new DatabaseError('照片数据验证失败', ERROR_CODES.CONSTRAINT_VIOLATION)
      }

      // 验证项目和工点是否存在
      const [projectExists, siteExists] = await Promise.all([
        this.validateProjectExists(photo.projectId),
        this.validateSiteExists(photo.siteId)
      ])

      if (!projectExists) {
        throw new DatabaseError(`项目不存在: ${photo.projectId}`, ERROR_CODES.FOREIGN_KEY_VIOLATION)
      }

      if (!siteExists) {
        throw new DatabaseError(`工点不存在: ${photo.siteId}`, ERROR_CODES.FOREIGN_KEY_VIOLATION)
      }

      const now = Date.now()
      photo.createdAt = new Date(now)
      photo.updatedAt = new Date(now)

      const dbData = this.photoToDbData(photo)

      await databaseService.executeSql(`
        INSERT INTO ${TABLE_NAMES.PHOTOS} (
          ${PHOTO_FIELDS.PHOTO_ID},
          ${PHOTO_FIELDS.PROJECT_ID},
          ${PHOTO_FIELDS.SITE_ID},
          ${PHOTO_FIELDS.FILE_PATH},
          ${PHOTO_FIELDS.THUMBNAIL_PATH},
          ${PHOTO_FIELDS.TAKEN_AT},
          ${PHOTO_FIELDS.LATITUDE},
          ${PHOTO_FIELDS.LONGITUDE},
          ${PHOTO_FIELDS.ALTITUDE},
          ${PHOTO_FIELDS.AZIMUTH},
          ${PHOTO_FIELDS.ADDRESS},
          ${PHOTO_FIELDS.WEATHER},
          ${PHOTO_FIELDS.TEMPLATE_ID},
          ${PHOTO_FIELDS.NOTES},
          ${PHOTO_FIELDS.TAGS},
          ${PHOTO_FIELDS.FILE_SIZE},
          ${PHOTO_FIELDS.WIDTH},
          ${PHOTO_FIELDS.HEIGHT},
          ${PHOTO_FIELDS.EDITED},
          ${PHOTO_FIELDS.EXIF_DATA},
          ${PHOTO_FIELDS.ANNOTATIONS},
          created_at,
          updated_at,
          version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        dbData.photo_id,
        dbData.project_id,
        dbData.site_id,
        dbData.file_path,
        dbData.thumbnail_path,
        dbData.taken_at,
        dbData.latitude,
        dbData.longitude,
        dbData.altitude,
        dbData.azimuth,
        dbData.address,
        dbData.weather,
        dbData.template_id,
        dbData.notes,
        dbData.tags,
        dbData.file_size,
        dbData.width,
        dbData.height,
        dbData.edited,
        dbData.exif_data,
        dbData.annotations,
        dbData.created_at,
        dbData.updated_at,
        dbData.version
      ])

      // 更新项目和工点的照片数量
      await Promise.all([
        this.updateProjectPhotoCount(photo.projectId, 1),
        this.updateSitePhotoCount(photo.siteId, 1)
      ])

      hilog.info(0x0000, this.TAG, `照片记录���建成功: ${photo.id}`)
      return photo

    } catch (error) {
      hilog.error(0x0000, this.TAG, `创建照片记录失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `创建照片记录失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 根据ID获取照片
   */
  async getPhotoById(photoId: string): Promise<Photo | null> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT * FROM ${TABLE_NAMES.PHOTOS}
        WHERE ${PHOTO_FIELDS.PHOTO_ID} = ?
        LIMIT 1
      `, [photoId])

      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return null
      }

      const photo = this.dbDataToPhoto(resultSet)
      resultSet.close()

      return photo

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询照片失败: ${photoId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询照片失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 查询照片列表
   */
  async queryPhotos(params: PhotoQueryParams = {}): Promise<Photo[]> {
    try {
      let sql = `SELECT * FROM ${TABLE_NAMES.PHOTOS} WHERE 1=1`
      const args: any[] = []

      if (params.projectId) {
        sql += ` AND ${PHOTO_FIELDS.PROJECT_ID} = ?`
        args.push(params.projectId)
      }

      if (params.siteId) {
        sql += ` AND ${PHOTO_FIELDS.SITE_ID} = ?`
        args.push(params.siteId)
      }

      if (params.templateId) {
        sql += ` AND ${PHOTO_FIELDS.TEMPLATE_ID} = ?`
        args.push(params.templateId)
      }

      if (params.dateRange) {
        if (params.dateRange.start) {
          sql += ` AND ${PHOTO_FIELDS.TAKEN_AT} >= ?`
          args.push(params.dateRange.start.getTime())
        }
        if (params.dateRange.end) {
          sql += ` AND ${PHOTO_FIELDS.TAKEN_AT} <= ?`
          args.push(params.dateRange.end.getTime())
        }
      }

      if (params.hasLocation !== undefined) {
        if (params.hasLocation) {
          sql += ` AND (${PHOTO_FIELDS.LATITUDE} != 0 AND ${PHOTO_FIELDS.LONGITUDE} != 0)`
        } else {
          sql += ` AND (${PHOTO_FIELDS.LATITUDE} = 0 OR ${PHOTO_FIELDS.LONGITUDE} = 0)`
        }
      }

      if (params.isEdited !== undefined) {
        sql += ` AND ${PHOTO_FIELDS.EDITED} = ?`
        args.push(params.isEdited ? 1 : 0)
      }

      sql += ` ORDER BY ${params.orderBy || PHOTO_FIELDS.TAKEN_AT + ' DESC'}`

      if (params.limit) {
        sql += ` LIMIT ?`
        args.push(params.limit)
      }

      const resultSet = await databaseService.executeQuery(sql, args)
      const photos: Photo[] = []

      while (resultSet.goToNextRow()) {
        photos.push(this.dbDataToPhoto(resultSet))
      }

      resultSet.close()
      return photos

    } catch (error) {
      hilog.error(0x0000, this.TAG, `查询照片列表失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `查询照片列表失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 分页查询照片列表
   */
  async queryPhotosWithPagination(
    params: PhotoQueryParams = {},
    pagination: PaginationParams = { page: 1, pageSize: PAGINATION.DEFAULT_PAGE_SIZE }
  ): Promise<PaginationResult<Photo>> {
    try {
      const pageSize = Math.min(pagination.pageSize, PAGINATION.MAX_PAGE_SIZE)

      // 查询总数
      let countSql = `SELECT COUNT(*) as count FROM ${TABLE_NAMES.PHOTOS} WHERE 1=1`
      const countArgs: any[] = []

      if (params.projectId) {
        countSql += ` AND ${PHOTO_FIELDS.PROJECT_ID} = ?`
        countArgs.push(params.projectId)
      }

      if (params.siteId) {
        countSql += ` AND ${PHOTO_FIELDS.SITE_ID} = ?`
        countArgs.push(params.siteId)
      }

      if (params.dateRange) {
        if (params.dateRange.start) {
          countSql += ` AND ${PHOTO_FIELDS.TAKEN_AT} >= ?`
          countArgs.push(params.dateRange.start.getTime())
        }
        if (params.dateRange.end) {
          countSql += ` AND ${PHOTO_FIELDS.TAKEN_AT} <= ?`
          countArgs.push(params.dateRange.end.getTime())
        }
      }

      const countResultSet = await databaseService.executeQuery(countSql, countArgs)
      const total = countResultSet.getLong(0)
      countResultSet.close()

      // 查询数据
      const dataParams = { ...params, limit: pageSize, offset: (pagination.page - 1) * pageSize }
      const photos = await this.queryPhotos(dataParams)

      const totalPages = Math.ceil(total / pageSize)

      return {
        data: photos,
        total,
        page: pagination.page,
        pageSize,
        totalPages
      }

    } catch (error) {
      hilog.error(0x0000, this.TAG, `分页查询照片失败: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `分页查询照片失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 更新照片信息
   */
  async updatePhoto(photo: Photo): Promise<boolean> {
    try {
      photo.updatedAt = new Date()
      photo.version++

      const dbData = this.photoToDbData(photo)

      const result = await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.PHOTOS} SET
          ${PHOTO_FIELDS.NOTES} = ?,
          ${PHOTO_FIELDS.TAGS} = ?,
          ${PHOTO_FIELDS.EDITED} = ?,
          ${PHOTO_FIELDS.ANNOTATIONS} = ?,
          updated_at = ?,
          version = ?
        WHERE ${PHOTO_FIELDS.PHOTO_ID} = ?
      `, [
        dbData.notes,
        dbData.tags,
        dbData.edited,
        dbData.annotations,
        dbData.updated_at,
        dbData.version,
        photo.id
      ])

      return result > 0

    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新照片失败: ${photo.id}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `更新照片失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 删除照片
   */
  async deletePhoto(photoId: string): Promise<boolean> {
    try {
      // 获取照片信息（用于更新统计）
      const photo = await this.getPhotoById(photoId)
      let projectId: string | null = null
      let siteId: string | null = null

      if (photo) {
        projectId = photo.projectId
        siteId = photo.siteId
      }

      const result = await databaseService.executeSql(`
        DELETE FROM ${TABLE_NAMES.PHOTOS}
        WHERE ${PHOTO_FIELDS.PHOTO_ID} = ?
      `, [photoId])

      const success = result > 0
      if (success && projectId && siteId) {
        // 更新统计数量
        await Promise.all([
          this.updateProjectPhotoCount(projectId, -1),
          this.updateSitePhotoCount(siteId, -1)
        ])
      }

      return success

    } catch (error) {
      hilog.error(0x0000, this.TAG, `删除照片失败: ${photoId}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `删除照片失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  /**
   * 搜索照片
   */
  async searchPhotos(keyword: string, projectId?: string, limit: number = 50): Promise<Photo[]> {
    try {
      if (!keyword.trim()) {
        return []
      }

      let sql = `
        SELECT * FROM ${TABLE_NAMES.PHOTOS}
        WHERE (${PHOTO_FIELDS.NOTES} LIKE ?
           OR ${PHOTO_FIELDS.ADDRESS} LIKE ?
           OR ${PHOTO_FIELDS.TAGS} LIKE ?)
      `
      const args: any[] = [`%${keyword}%`, `%${keyword}%`, `%${keyword}%`]

      if (projectId) {
        sql += ` AND ${PHOTO_FIELDS.PROJECT_ID} = ?`
        args.push(projectId)
      }

      sql += ` ORDER BY ${PHOTO_FIELDS.TAKEN_AT} DESC LIMIT ?`
      args.push(limit)

      const resultSet = await databaseService.executeQuery(sql, args)
      const photos: Photo[] = []

      while (resultSet.goToNextRow()) {
        photos.push(this.dbDataToPhoto(resultSet))
      }

      resultSet.close()
      return photos

    } catch (error) {
      hilog.error(0x0000, this.TAG, `搜索照片失败: ${keyword}, 错误: ${JSON.stringify(error)}`)
      throw new DatabaseError(
        `搜索照片失败: ${error instanceof Error ? error.message : String(error)}`,
        ERROR_CODES.CONNECTION_FAILED,
        error instanceof Error ? error : undefined
      )
    }
  }

  // 私有辅助方法
  private async validateProjectExists(projectId: string): Promise<boolean> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.PROJECTS}
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [projectId])
      const count = resultSet.getLong(0)
      resultSet.close()
      return count > 0
    } catch (error) {
      return false
    }
  }

  private async validateSiteExists(siteId: string): Promise<boolean> {
    try {
      const resultSet = await databaseService.executeQuery(`
        SELECT COUNT(*) as count FROM ${TABLE_NAMES.SITES}
        WHERE ${SITE_FIELDS.SITE_ID} = ?
      `, [siteId])
      const count = resultSet.getLong(0)
      resultSet.close()
      return count > 0
    } catch (error) {
      return false
    }
  }

  private async updateProjectPhotoCount(projectId: string, increment: number): Promise<void> {
    try {
      await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.PROJECTS}
        SET ${PROJECT_FIELDS.PHOTO_COUNT} = ${PROJECT_FIELDS.PHOTO_COUNT} + ?,
            updated_at = ?
        WHERE ${PROJECT_FIELDS.PROJECT_ID} = ?
      `, [increment, Date.now(), projectId])
    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新项目照片数量失败: ${projectId}`)
    }
  }

  private async updateSitePhotoCount(siteId: string, increment: number): Promise<void> {
    try {
      await databaseService.executeSql(`
        UPDATE ${TABLE_NAMES.SITES}
        SET ${SITE_FIELDS.PHOTO_COUNT} = ${SITE_FIELDS.PHOTO_COUNT} + ?,
            updated_at = ?
        WHERE ${SITE_FIELDS.SITE_ID} = ?
      `, [increment, Date.now(), siteId])
    } catch (error) {
      hilog.error(0x0000, this.TAG, `更新工点照片数量失败: ${siteId}`)
    }
  }

  private photoToDbData(photo: Photo): Record<string, any> {
    return {
      photo_id: photo.id,
      project_id: photo.projectId,
      site_id: photo.siteId,
      file_path: photo.filePath,
      thumbnail_path: photo.thumbnailPath,
      taken_at: photo.takenAt.getTime(),
      latitude: photo.latitude,
      longitude: photo.longitude,
      altitude: photo.altitude,
      azimuth: photo.azimuth,
      address: photo.address,
      weather: photo.weather ? JSON.stringify(photo.weather) : null,
      template_id: photo.templateId,
      notes: photo.notes,
      tags: JSON.stringify(photo.tags),
      file_size: photo.fileSize,
      width: photo.width,
      height: photo.height,
      edited: photo.edited ? 1 : 0,
      exif_data: JSON.stringify(photo.exifData),
      annotations: JSON.stringify(photo.annotations),
      created_at: photo.createdAt.getTime(),
      updated_at: photo.updatedAt.getTime(),
      version: photo.version
    }
  }

  private dbDataToPhoto(resultSet: any): Photo {
    const photo = new Photo()

    photo.id = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.PHOTO_ID))
    photo.projectId = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.PROJECT_ID))
    photo.siteId = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.SITE_ID))
    photo.filePath = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.FILE_PATH))
    photo.thumbnailPath = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.THUMBNAIL_PATH))
    photo.takenAt = new Date(resultSet.getLong(resultSet.getColumnIndex(PHOTO_FIELDS.TAKEN_AT)))
    photo.latitude = resultSet.getDouble(resultSet.getColumnIndex(PHOTO_FIELDS.LATITUDE))
    photo.longitude = resultSet.getDouble(resultSet.getColumnIndex(PHOTO_FIELDS.LONGITUDE))
    photo.altitude = resultSet.getDouble(resultSet.getColumnIndex(PHOTO_FIELDS.ALTITUDE))
    photo.azimuth = resultSet.getDouble(resultSet.getColumnIndex(PHOTO_FIELDS.AZIMUTH))
    photo.address = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.ADDRESS))
    photo.templateId = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.TEMPLATE_ID))
    photo.notes = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.NOTES))
    photo.fileSize = resultSet.getLong(resultSet.getColumnIndex(PHOTO_FIELDS.FILE_SIZE))
    photo.width = resultSet.getLong(resultSet.getColumnIndex(PHOTO_FIELDS.WIDTH))
    photo.height = resultSet.getLong(resultSet.getColumnIndex(PHOTO_FIELDS.HEIGHT))
    photo.edited = resultSet.getInt(resultSet.getColumnIndex(PHOTO_FIELDS.EDITED)) === 1

    // 解析JSON字段
    try {
      const tagsJson = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.TAGS))
      photo.tags = tagsJson ? JSON.parse(tagsJson) : []
    } catch (e) {
      photo.tags = []
    }

    try {
      const weatherJson = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.WEATHER))
      photo.weather = weatherJson ? JSON.parse(weatherJson) : null
    } catch (e) {
      photo.weather = null
    }

    try {
      const exifJson = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.EXIF_DATA))
      photo.exifData = exifJson ? JSON.parse(exifJson) : {}
    } catch (e) {
      photo.exifData = {}
    }

    try {
      const annotationsJson = resultSet.getString(resultSet.getColumnIndex(PHOTO_FIELDS.ANNOTATIONS))
      photo.annotations = annotationsJson ? JSON.parse(annotationsJson) : []
    } catch (e) {
      photo.annotations = []
    }

    photo.createdAt = new Date(resultSet.getLong(resultSet.getColumnIndex('created_at')))
    photo.updatedAt = new Date(resultSet.getLong(resultSet.getColumnIndex('updated_at')))
    photo.version = resultSet.getLong(resultSet.getColumnIndex('version'))

    return photo
  }
}

export const photoService = PhotoService.getInstance()