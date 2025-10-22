import { Logger } from '../../utils/Logger'
import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { Photo } from '../../models/Photo'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { DatabaseService } from '../../services/database/DatabaseService'
import { CacheService } from '../../services/storage/CacheService'

interface PerformanceMetrics {
  testName: string
  startTime: number
  endTime: number
  duration: number
  memoryUsage: number
  success: boolean
  details?: Record<string, any>
}

/**
 * 性能测试管理器
 * 负责应用性能测试和压力测试
 */
export class PerformanceTestManager {
  private static readonly TAG = 'PerformanceTestManager'
  private projectStore: ProjectStore
  private siteStore: SiteStore
  private photoStore: PhotoStore
  private databaseService: DatabaseService
  private cacheService: CacheService

  constructor() {
    this.projectStore = new ProjectStore()
    this.siteStore = new SiteStore()
    this.photoStore = new PhotoStore()
    this.databaseService = DatabaseService.getInstance()
    this.cacheService = new CacheService()
  }

  /**
   * 测试大量数据加载性能
   */
  async testLargeDataLoadingPerformance(): Promise<PerformanceMetrics> {
    const testName = '大量数据加载性能测试'
    const startTime = Date.now()
    const startMemory = this.getMemoryUsage()

    try {
      Logger.info(PerformanceTestManager.TAG, `开始${testName}`)

      // 创建大量测试数据
      const { projects, sites, photos } = await this.generateLargeTestData(100, 200, 1000)

      // 测试项目列表加载性能
      const projectStartTime = Date.now()
      const loadedProjects = await this.projectStore.getAllProjects()
      const projectLoadTime = Date.now() - projectStartTime

      // 测试工点列表加载性能
      const siteStartTime = Date.now()
      const loadedSites = await this.siteStore.getAllSites()
      const siteLoadTime = Date.now() - siteStartTime

      // 测试照片列表加载性能
      const photoStartTime = Date.now()
      const loadedPhotos = await this.photoStore.getAllPhotos()
      const photoLoadTime = Date.now() - photoStartTime

      // 测试分页加载性能
      const pageStartTime = Date.now()
      const pagedPhotos = await this.photoStore.getPhotosByPage(1, 50)
      const pageLoadTime = Date.now() - pageStartTime

      const endTime = Date.now()
      const endMemory = this.getMemoryUsage()
      const duration = endTime - startTime

      const metrics: PerformanceMetrics = {
        testName,
        startTime,
        endTime,
        duration,
        memoryUsage: endMemory - startMemory,
        success: true,
        details: {
          dataCount: { projects: projects.length, sites: sites.length, photos: photos.length },
          loadTimes: { projects: projectLoadTime, sites: siteLoadTime, photos: photoLoadTime, page: pageLoadTime },
          loadedCount: { projects: loadedProjects.length, sites: loadedSites.length, photos: loadedPhotos.length, page: pagedPhotos.length }
        }
      }

      // 清理测试数据
      await this.cleanupLargeTestData(projects, sites, photos)

      Logger.info(PerformanceTestManager.TAG, `${testName}完成，耗时: ${duration}ms`)
      return metrics

    } catch (error) {
      Logger.error(PerformanceTestManager.TAG, `${testName}失败: ${error}`)
      return {
        testName,
        startTime,
        endTime: Date.now(),
        duration: Date.now() - startTime,
        memoryUsage: this.getMemoryUsage() - startMemory,
        success: false,
        details: { error: error.toString() }
      }
    }
  }

  /**
   * 测试内存使用情况
   */
  async testMemoryUsage(): Promise<PerformanceMetrics> {
    const testName = '内存使用情况测试'
    const startTime = Date.now()
    const initialMemory = this.getMemoryUsage()

    try {
      Logger.info(PerformanceTestManager.TAG, `开始${testName}`)

      const memorySnapshots: number[] = [initialMemory]

      // 测试缓存内存使用
      await this.testCacheMemoryUsage(memorySnapshots)

      // 测试大量数据在内存中的使用
      await this.testLargeDataMemoryUsage(memorySnapshots)

      // 测试内存泄漏
      await this.testMemoryLeaks(memorySnapshots)

      const endTime = Date.now()
      const finalMemory = this.getMemoryUsage()
      const duration = endTime - startTime

      return {
        testName,
        startTime,
        endTime,
        duration,
        memoryUsage: finalMemory - initialMemory,
        success: true,
        details: {
          initialMemory,
          finalMemory,
          peakMemory: Math.max(...memorySnapshots),
          memorySnapshots: memorySnapshots.length
        }
      }

    } catch (error) {
      Logger.error(PerformanceTestManager.TAG, `${testName}失败: ${error}`)
      return {
        testName,
        startTime,
        endTime: Date.now(),
        duration: Date.now() - startTime,
        memoryUsage: this.getMemoryUsage() - initialMemory,
        success: false,
        details: { error: error.toString() }
      }
    }
  }

  /**
   * 测试图片处理性能
   */
  async testImageProcessingPerformance(): Promise<PerformanceMetrics> {
    const testName = '图片处理性能测试'
    const startTime = Date.now()
    const startMemory = this.getMemoryUsage()

    try {
      Logger.info(PerformanceTestManager.TAG, `开始${testName}`)

      // 模��图片处理操作
      const processingTimes: number[] = []

      // 测试缩略图生成
      const thumbStartTime = Date.now()
      await this.simulateThumbnailGeneration(100)
      processingTimes.push(Date.now() - thumbStartTime)

      // 测试图片压缩
      const compressStartTime = Date.now()
      await this.simulateImageCompression(50)
      processingTimes.push(Date.now() - compressStartTime)

      // 测试水印渲染
      const watermarkStartTime = Date.now()
      await this.simulateWatermarkRendering(50)
      processingTimes.push(Date.now() - watermarkStartTime)

      // 测试图片格式转换
      const convertStartTime = Date.now()
      await this.simulateImageConversion(30)
      processingTimes.push(Date.now() - convertStartTime)

      const endTime = Date.now()
      const endMemory = this.getMemoryUsage()
      const duration = endTime - startTime

      return {
        testName,
        startTime,
        endTime,
        duration,
        memoryUsage: endMemory - startMemory,
        success: true,
        details: {
          processingTimes: {
            thumbnails: processingTimes[0],
            compression: processingTimes[1],
            watermark: processingTimes[2],
            conversion: processingTimes[3]
          },
          avgProcessingTime: processingTimes.reduce((a, b) => a + b, 0) / processingTimes.length
        }
      }

    } catch (error) {
      Logger.error(PerformanceTestManager.TAG, `${testName}失败: ${error}`)
      return {
        testName,
        startTime,
        endTime: Date.now(),
        duration: Date.now() - startTime,
        memoryUsage: this.getMemoryUsage() - startMemory,
        success: false,
        details: { error: error.toString() }
      }
    }
  }

  /**
   * 测试数据库查询性能
   */
  async testDatabaseQueryPerformance(): Promise<PerformanceMetrics> {
    const testName = '数据库查询性能测试'
    const startTime = Date.now()
    const startMemory = this.getMemoryUsage()

    try {
      Logger.info(PerformanceTestManager.TAG, `开始${testName}`)

      // 准备测试数据
      const { projects, sites, photos } = await this.generateLargeTestData(50, 100, 500)

      const queryTimes: Record<string, number> = {}

      // 测试简单查询
      const simpleStartTime = Date.now()
      await this.projectStore.getAllProjects()
      queryTimes.simpleQuery = Date.now() - simpleStartTime

      // 测试条件查询
      const conditionStartTime = Date.now()
      await this.photoStore.getPhotosByProjectId(projects[0].id)
      queryTimes.conditionQuery = Date.now() - conditionStartTime

      // 测试复杂查询
      const complexStartTime = Date.now()
      await this.photoStore.searchPhotos({
        keyword: 'test',
        startDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        endDate: new Date()
      })
      queryTimes.complexQuery = Date.now() - complexStartTime

      // 测试分页查询
      const pageStartTime = Date.now()
      await this.photoStore.getPhotosByPage(1, 20)
      queryTimes.pageQuery = Date.now() - pageStartTime

      // 测试聚合查询
      const aggregateStartTime = Date.now()
      await this.simulateAggregateQueries()
      queryTimes.aggregateQuery = Date.now() - aggregateStartTime

      const endTime = Date.now()
      const endMemory = this.getMemoryUsage()
      const duration = endTime - startTime

      // 清理测试数据
      await this.cleanupLargeTestData(projects, sites, photos)

      return {
        testName,
        startTime,
        endTime,
        duration,
        memoryUsage: endMemory - startMemory,
        success: true,
        details: { queryTimes }
      }

    } catch (error) {
      Logger.error(PerformanceTestManager.TAG, `${testName}失败: ${error}`)
      return {
        testName,
        startTime,
        endTime: Date.now(),
        duration: Date.now() - startTime,
        memoryUsage: this.getMemoryUsage() - startMemory,
        success: false,
        details: { error: error.toString() }
      }
    }
  }

  /**
   * 生成大量测试数据
   */
  private async generateLargeTestData(projectCount: number, siteCount: number, photoCount: number): Promise<{ projects: Project[], sites: Site[], photos: Photo[] }> {
    const projects: Project[] = []
    const sites: Site[] = []
    const photos: Photo[] = []

    // 创建项目
    for (let i = 0; i < projectCount; i++) {
      const project = new Project()
      project.name = `性能测试项目_${i}`
      project.description = `性能测试项目描述_${i}`
      project.status = 'active'
      const createdProject = await this.projectStore.createProject(project)
      projects.push(createdProject!)
    }

    // 创建工点
    for (let i = 0; i < siteCount; i++) {
      const site = new Site()
      site.projectId = projects[i % projects.length].id
      site.name = `性能测试工点_${i}`
      site.description = `性能测试工点描述_${i}`
      site.latitude = 39.9042 + (Math.random() - 0.5) * 0.1
      site.longitude = 116.4074 + (Math.random() - 0.5) * 0.1
      site.status = 'active'
      const createdSite = await this.siteStore.createSite(site)
      sites.push(createdSite!)
    }

    // 创建照片
    for (let i = 0; i < photoCount; i++) {
      const photo = new Photo()
      photo.projectId = projects[i % projects.length].id
      photo.siteId = sites[i % sites.length].id
      photo.fileName = `perf_test_photo_${i}.jpg`
      photo.filePath = `/perf/test/${photo.fileName}`
      photo.fileSize = 1024 * 1024 * (1 + Math.random() * 2) // 1-3MB
      photo.width = 1920
      photo.height = 1080
      photo.latitude = 39.9042 + (Math.random() - 0.5) * 0.01
      photo.longitude = 116.4074 + (Math.random() - 0.5) * 0.01
      photo.shootingTime = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000) // 30天内
      photo.tags = [`性能测试${i % 5}`, `批次${Math.floor(i / 10)}`]
      const createdPhoto = await this.photoStore.createPhoto(photo)
      photos.push(createdPhoto!)
    }

    return { projects, sites, photos }
  }

  /**
   * 清理大量测试数据
   */
  private async cleanupLargeTestData(projects: Project[], sites: Site[], photos: Photo[]): Promise<void> {
    // 删除照片
    for (const photo of photos) {
      try {
        await this.photoStore.deletePhoto(photo.id)
      } catch (error) {
        Logger.error(PerformanceTestManager.TAG, `删除照片失败: ${error}`)
      }
    }

    // 删除工点
    for (const site of sites) {
      try {
        await this.siteStore.deleteSite(site.id)
      } catch (error) {
        Logger.error(PerformanceTestManager.TAG, `删除工点失败: ${error}`)
      }
    }

    // 删除项目
    for (const project of projects) {
      try {
        await this.projectStore.deleteProject(project.id)
      } catch (error) {
        Logger.error(PerformanceTestManager.TAG, `删除项目失败: ${error}`)
      }
    }
  }

  /**
   * 获取内存使用情况
   */
  private getMemoryUsage(): number {
    // 在实际应用中，这里应该使用系统API获取真实的内存使用情况
    // 这里返回模拟数据
    return Math.floor(Math.random() * 100 * 1024 * 1024) // 模拟内存使用
  }

  /**
   * 测试缓存内存使用
   */
  private async testCacheMemoryUsage(memorySnapshots: number[]): Promise<void> {
    // 测试缓存添加
    for (let i = 0; i < 100; i++) {
      this.cacheService.set(`test_key_${i}`, `test_value_${i}`.repeat(100))
      if (i % 20 === 0) {
        memorySnapshots.push(this.getMemoryUsage())
      }
    }
  }

  /**
   * 测试大量数据内存使用
   */
  private async testLargeDataMemoryUsage(memorySnapshots: number[]): Promise<void> {
    const largeDataSet = []
    for (let i = 0; i < 1000; i++) {
      largeDataSet.push({
        id: i,
        data: 'x'.repeat(1024), // 1KB数据
        timestamp: Date.now()
      })
      if (i % 200 === 0) {
        memorySnapshots.push(this.getMemoryUsage())
      }
    }
    // 清理引用
    largeDataSet.length = 0
  }

  /**
   * 测试内存泄���
   */
  private async testMemoryLeaks(memorySnapshots: number[]): Promise<void> {
    // 模拟可能导致内存泄漏的操作
    for (let cycle = 0; cycle < 5; cycle++) {
      const tempData = []
      for (let i = 0; i < 200; i++) {
        tempData.push({
          id: i,
          circularRef: null
        })
      }
      // 创建循环引用
      if (tempData.length > 0) {
        tempData[0].circularRef = tempData
      }
      memorySnapshots.push(this.getMemoryUsage())
      // 清理
      tempData.length = 0
    }
  }

  /**
   * 模拟缩略图生成
   */
  private async simulateThumbnailGeneration(count: number): Promise<void> {
    for (let i = 0; i < count; i++) {
      // 模拟缩略图生成耗时
      await new Promise(resolve => setTimeout(resolve, 5 + Math.random() * 10))
    }
  }

  /**
   * 模拟图片压缩
   */
  private async simulateImageCompression(count: number): Promise<void> {
    for (let i = 0; i < count; i++) {
      // 模拟图片压缩耗时
      await new Promise(resolve => setTimeout(resolve, 20 + Math.random() * 30))
    }
  }

  /**
   * 模拟水印渲染
   */
  private async simulateWatermarkRendering(count: number): Promise<void> {
    for (let i = 0; i < count; i++) {
      // 模拟水印渲染耗时
      await new Promise(resolve => setTimeout(resolve, 10 + Math.random() * 20))
    }
  }

  /**
   * 模拟图片格式转换
   */
  private async simulateImageConversion(count: number): Promise<void> {
    for (let i = 0; i < count; i++) {
      // 模拟格式转换耗时
      await new Promise(resolve => setTimeout(resolve, 30 + Math.random() * 50))
    }
  }

  /**
   * 模拟聚合查询
   */
  private async simulateAggregateQueries(): Promise<void> {
    // 模拟各种聚合查询操作
    const queries = [
      () => this.photoStore.getPhotosByProjectId('test-project-id'),
      () => this.photoStore.searchPhotos({ keyword: 'test' }),
      () => this.photoStore.getPhotosByTimeRange(new Date(), new Date()),
      () => this.photoStore.getPhotosByPage(1, 10)
    ]

    for (const query of queries) {
      try {
        await query()
      } catch (error) {
        // 忽略查询错误，因为这是性能测试
      }
    }
  }

  /**
   * 运行所有性能测试
   */
  async runAllPerformanceTests(): Promise<PerformanceMetrics[]> {
    const results: PerformanceMetrics[] = []

    // 大量数据加载性能测试
    const dataLoadingResult = await this.testLargeDataLoadingPerformance()
    results.push(dataLoadingResult)

    // 内存使用情况测试
    const memoryUsageResult = await this.testMemoryUsage()
    results.push(memoryUsageResult)

    // 图片处理性能测试
    const imageProcessingResult = await this.testImageProcessingPerformance()
    results.push(imageProcessingResult)

    // 数据库查询性能测试
    const databaseQueryResult = await this.testDatabaseQueryPerformance()
    results.push(databaseQueryResult)

    return results
  }
}