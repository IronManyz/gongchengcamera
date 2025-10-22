import { Logger } from '../../utils/Logger'
import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { Photo } from '../../models/Photo'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { GalleryStore } from '../../store/gallery/GalleryStore'

/**
 * 照片管理流程集成测试
 */
export class PhotoManagementTest {
  private static readonly TAG = 'PhotoManagementTest'
  private projectStore: ProjectStore
  private siteStore: SiteStore
  private photoStore: PhotoStore
  private galleryStore: GalleryStore

  constructor() {
    this.projectStore = new ProjectStore()
    this.siteStore = new SiteStore()
    this.photoStore = new PhotoStore()
    this.galleryStore = new GalleryStore()
  }

  /**
   * 测试完整的照片管理流程
   */
  async testPhotoManagementFlow(): Promise<boolean> {
    try {
      Logger.info(PhotoManagementTest.TAG, '开始测试照片管理流程')

      // 步骤1: 准备测试数据
      const { project, site } = await this.setupTestEnvironment()
      if (!project || !site) {
        Logger.error(PhotoManagementTest.TAG, '测试环境准备失败')
        return false
      }

      // 步骤2: 批量创建照片
      const photos = await this.createBatchPhotos(project.id, site.id, 10)
      if (photos.length === 0) {
        Logger.error(PhotoManagementTest.TAG, '批量创建照片失败')
        return false
      }
      Logger.info(PhotoManagementTest.TAG, `成功创建 ${photos.length} 张照片`)

      // 步骤3: 测试照片查询功能
      const queryTestResult = await this.testPhotoQueries(project.id, photos)
      if (!queryTestResult) {
        Logger.error(PhotoManagementTest.TAG, '照片查询测试失败')
        return false
      }

      // 步骤4: 测试照片搜索功能
      const searchTestResult = await this.testPhotoSearch(photos)
      if (!searchTestResult) {
        Logger.error(PhotoManagementTest.TAG, '照片搜索测试失败')
        return false
      }

      // 步骤5: 测试照片批量操作
      const batchTestResult = await this.testBatchOperations(photos)
      if (!batchTestResult) {
        Logger.error(PhotoManagementTest.TAG, '批量操作测试失败')
        return false
      }

      // 步骤6: 测试照片分类管理
      const categoryTestResult = await this.testPhotoCategories(photos)
      if (!categoryTestResult) {
        Logger.error(PhotoManagementTest.TAG, '照片分类测试失败')
        return false
      }

      // 清理测试数据
      await this.cleanupTestEnvironment(project.id, site.id, photos)

      Logger.info(PhotoManagementTest.TAG, '照片管理流程测试完成')
      return true

    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `照片管理流程测试异常: ${error}`)
      return false
    }
  }

  /**
   * 准备测试环境
   */
  private async setupTestEnvironment(): Promise<{ project?: Project; site?: Site }> {
    try {
      // 创建测试项目
      const project = new Project()
      project.name = `照片管理测试项目_${Date.now()}`
      project.description = '用于照片管理流程测试'
      project.status = 'active'
      const createdProject = await this.projectStore.createProject(project)

      // 创建测试工点
      const site = new Site()
      site.projectId = createdProject!.id
      site.name = `照片管理测试工点_${Date.now()}`
      site.description = '用于照片管理流程测试'
      site.latitude = 39.9042
      site.longitude = 116.4074
      site.status = 'active'
      const createdSite = await this.siteStore.createSite(site)

      return { project: createdProject, site: createdSite }
    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `准备测试环境失败: ${error}`)
      return {}
    }
  }

  /**
   * 批量创建照片
   */
  private async createBatchPhotos(projectId: string, siteId: string, count: number): Promise<Photo[]> {
    const photos: Photo[] = []

    for (let i = 0; i < count; i++) {
      try {
        const photo = new Photo()
        photo.projectId = projectId
        photo.siteId = siteId
        photo.fileName = `test_photo_${Date.now()}_${i}.jpg`
        photo.filePath = `/test/path/${photo.fileName}`
        photo.fileSize = 1024 * 1024 * (1 + Math.random()) // 1-2MB
        photo.width = 1920
        photo.height = 1080
        photo.latitude = 39.9042 + (Math.random() - 0.5) * 0.01
        photo.longitude = 116.4074 + (Math.random() - 0.5) * 0.01
        photo.shootingTime = new Date(Date.now() - i * 60 * 60 * 1000) // 相差1小时
        photo.watermarkEnabled = i % 2 === 0
        photo.watermarkTemplate = i % 2 === 0 ? 'default' : 'simple'
        photo.tags = [`测试标签${i % 3}`, `批次${Math.floor(i / 3)}`]

        const createdPhoto = await this.photoStore.createPhoto(photo)
        photos.push(createdPhoto)
      } catch (error) {
        Logger.error(PhotoManagementTest.TAG, `创建照片 ${i} 失败: ${error}`)
      }
    }

    return photos
  }

  /**
   * 测试照片查询功能
   */
  private async testPhotoQueries(projectId: string, photos: Photo[]): Promise<boolean> {
    try {
      // 测试按项目ID查询
      const projectPhotos = await this.photoStore.getPhotosByProjectId(projectId)
      if (projectPhotos.length !== photos.length) {
        Logger.error(PhotoManagementTest.TAG, `项目照片数量不匹配: 期望${photos.length}, 实际${projectPhotos.length}`)
        return false
      }

      // 测试分页查询
      const page1 = await this.photoStore.getPhotosByPage(1, 5)
      if (page1.length > 5) {
        Logger.error(PhotoManagementTest.TAG, '分页查询结果超过限制')
        return false
      }

      // 测试按时间范围查询
      const now = new Date()
      const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)
      const recentPhotos = await this.photoStore.getPhotosByTimeRange(oneDayAgo, now)
      if (recentPhotos.length === 0) {
        Logger.error(PhotoManagementTest.TAG, '时间范围查询无结果')
        return false
      }

      Logger.info(PhotoManagementTest.TAG, '照片查询功能测试通过')
      return true
    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `照片查询测试异常: ${error}`)
      return false
    }
  }

  /**
   * 测试照片搜索功能
   */
  private async testPhotoSearch(photos: Photo[]): Promise<boolean> {
    try {
      // 测试按标签搜索
      const tagPhotos = await this.photoStore.searchPhotosByTag('测试标签0')
      if (tagPhotos.length === 0) {
        Logger.error(PhotoManagementTest.TAG, '标签搜索无结果')
        return false
      }

      // 测试按文件名搜索
      const fileNamePhotos = await this.photoStore.searchPhotosByFileName('test_photo_')
      if (fileNamePhotos.length === 0) {
        Logger.error(PhotoManagementTest.TAG, '文件名搜索无结果')
        return false
      }

      // 测试组合搜索
      const searchResults = await this.photoStore.searchPhotos({
        keyword: 'test',
        startDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        endDate: new Date(),
        tags: ['测试标签0']
      })
      if (searchResults.length === 0) {
        Logger.error(PhotoManagementTest.TAG, '组合搜索无结果')
        return false
      }

      Logger.info(PhotoManagementTest.TAG, '照片搜索功能测试通过')
      return true
    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `照片搜索测试异常: ${error}`)
      return false
    }
  }

  /**
   * 测试批量操作
   */
  private async testBatchOperations(photos: Photo[]): Promise<boolean> {
    try {
      const photoIds = photos.slice(0, 5).map(p => p.id)

      // 测试批量更新标签
      const newTags = ['批量更新', '测试']
      const updateResult = await this.photoStore.batchUpdateTags(photoIds, newTags)
      if (!updateResult) {
        Logger.error(PhotoManagementTest.TAG, '批量更新标签失败')
        return false
      }

      // 验证更新结果
      const updatedPhotos = await Promise.all(
        photoIds.map(id => this.photoStore.getPhotoById(id))
      )
      for (const photo of updatedPhotos) {
        if (photo && !photo.tags.includes('批量更新')) {
          Logger.error(PhotoManagementTest.TAG, '批量更新标签验证失败')
          return false
        }
      }

      // 测试批量删除
      const deleteResult = await this.photoStore.batchDeletePhotos(photoIds)
      if (!deleteResult) {
        Logger.error(PhotoManagementTest.TAG, '批量删除失败')
        return false
      }

      // 验证删除结果
      for (const photoId of photoIds) {
        const deletedPhoto = await this.photoStore.getPhotoById(photoId)
        if (deletedPhoto) {
          Logger.error(PhotoManagementTest.TAG, '批量删除验证失败')
          return false
        }
      }

      Logger.info(PhotoManagementTest.TAG, '批量操作测试通过')
      return true
    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `批量操作测试异常: ${error}`)
      return false
    }
  }

  /**
   * 测试照片分类管理
   */
  private async testPhotoCategories(photos: Photo[]): Promise<boolean> {
    try {
      const photoIds = photos.slice(0, 3).map(p => p.id)

      // 测试添加到相册
      const albumName = '测试相册'
      const addToAlbumResult = await this.galleryStore.addPhotosToAlbum(photoIds, albumName)
      if (!addToAlbumResult) {
        Logger.error(PhotoManagementTest.TAG, '添加照片到相册失败')
        return false
      }

      // 测试获取相册照片
      const albumPhotos = await this.galleryStore.getPhotosByAlbum(albumName)
      if (albumPhotos.length !== photoIds.length) {
        Logger.error(PhotoManagementTest.TAG, `相册照片数量不匹配: 期望${photoIds.length}, 实际${albumPhotos.length}`)
        return false
      }

      // 测试从相册移除
      const removeFromAlbumResult = await this.galleryStore.removePhotosFromAlbum(photoIds, albumName)
      if (!removeFromAlbumResult) {
        Logger.error(PhotoManagementTest.TAG, '从相册移除照片失败')
        return false
      }

      Logger.info(PhotoManagementTest.TAG, '照片分类管理测试通过')
      return true
    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `照片分类管理测试异常: ${error}`)
      return false
    }
  }

  /**
   * 清理测试环境
   */
  private async cleanupTestEnvironment(projectId: string, siteId: string, photos: Photo[]): Promise<void> {
    try {
      // 删除所有照片
      for (const photo of photos) {
        try {
          await this.photoStore.deletePhoto(photo.id)
        } catch (error) {
          Logger.error(PhotoManagementTest.TAG, `删除照片 ${photo.id} 失败: ${error}`)
        }
      }

      // 删除工点
      await this.siteStore.deleteSite(siteId)

      // 删除项目
      await this.projectStore.deleteProject(projectId)

      Logger.info(PhotoManagementTest.TAG, '测试环境清理完成')
    } catch (error) {
      Logger.error(PhotoManagementTest.TAG, `清理测试环境失败: ${error}`)
    }
  }
}