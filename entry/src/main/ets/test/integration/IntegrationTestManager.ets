import { Logger } from '../../utils/Logger'
import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { Photo } from '../../models/Photo'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { CameraService } from '../../services/camera/CameraService'
import { LocationService } from '../../services/location/LocationService'
import { WatermarkService } from '../../services/camera/WatermarkService'
import { DatabaseService } from '../../services/database/DatabaseService'
import { PhotoManagementTest } from './PhotoManagementTest'
import { DataConsistencyTest } from './DataConsistencyTest'
import { PerformanceTestManager } from '../performance/PerformanceTestManager'
import { EditingExportTest } from './EditingExportTest'

/**
 * 集成测试管理器
 * 负责端到端功能测试
 */
export class IntegrationTestManager {
  private static readonly TAG = 'IntegrationTestManager'
  private projectStore: ProjectStore
  private siteStore: SiteStore
  private photoStore: PhotoStore
  private cameraService: CameraService
  private locationService: LocationService
  private watermarkService: WatermarkService
  private databaseService: DatabaseService
  private photoManagementTest: PhotoManagementTest
  private dataConsistencyTest: DataConsistencyTest
  private performanceTestManager: PerformanceTestManager
  private editingExportTest: EditingExportTest

  constructor() {
    this.projectStore = new ProjectStore()
    this.siteStore = new SiteStore()
    this.photoStore = new PhotoStore()
    this.cameraService = new CameraService()
    this.locationService = new LocationService()
    this.watermarkService = new WatermarkService()
    this.databaseService = DatabaseService.getInstance()
    this.photoManagementTest = new PhotoManagementTest()
    this.dataConsistencyTest = new DataConsistencyTest()
    this.performanceTestManager = new PerformanceTestManager()
    this.editingExportTest = new EditingExportTest()
  }

  /**
   * 测试完整的项目创建到拍照流程
   */
  async testProjectToPhotoFlow(): Promise<boolean> {
    try {
      Logger.info(IntegrationTestManager.TAG, '开始测试项目创建到拍照流程')

      // 步骤1: 创建项目
      const project = await this.createTestProject()
      if (!project) {
        Logger.error(IntegrationTestManager.TAG, '项目创建失败')
        return false
      }
      Logger.info(IntegrationTestManager.TAG, `项目创建成功: ${project.name}`)

      // 步骤2: 创建工点
      const site = await this.createTestSite(project.id)
      if (!site) {
        Logger.error(IntegrationTestManager.TAG, '工点创建失败')
        return false
      }
      Logger.info(IntegrationTestManager.TAG, `工点创建成功: ${site.name}`)

      // 步骤3: 初始化相机
      const cameraInitialized = await this.initializeCamera()
      if (!cameraInitialized) {
        Logger.error(IntegrationTestManager.TAG, '相机初始化失败')
        return false
      }
      Logger.info(IntegrationTestManager.TAG, '相机初始化成功')

      // 步骤4: 获取位置信息
      const location = await this.getCurrentLocation()
      if (!location) {
        Logger.error(IntegrationTestManager.TAG, '位置获取失败')
        return false
      }
      Logger.info(IntegrationTestManager.TAG, `位置获取成功: ${location.latitude}, ${location.longitude}`)

      // 步骤5: 模拟拍照（由于是测试环境，创建模拟照片数据）
      const photo = await this.createTestPhoto(project.id, site.id, location)
      if (!photo) {
        Logger.error(IntegrationTestManager.TAG, '照片创建失败')
        return false
      }
      Logger.info(IntegrationTestManager.TAG, `照片创建成功: ${photo.fileName}`)

      // 步骤6: 验证数据完整性
      const dataIntegrityValid = await this.verifyDataIntegrity(project, site, photo)
      if (!dataIntegrityValid) {
        Logger.error(IntegrationTestManager.TAG, '数据完整性验证失败')
        return false
      }
      Logger.info(IntegrationTestManager.TAG, '数据完整性验证成功')

      // 清理测试数据
      await this.cleanupTestData(project.id, site.id, photo.id)

      Logger.info(IntegrationTestManager.TAG, '项目创建到拍照流程测试完成')
      return true

    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `测试流程异常: ${error}`)
      return false
    }
  }

  /**
   * 创建测试项目
   */
  private async createTestProject(): Promise<Project | null> {
    try {
      const testProject = new Project()
      testProject.name = `测试项目_${Date.now()}`
      testProject.description = '集成测试项目'
      testProject.startDate = new Date()
      testProject.endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30天后
      testProject.status = 'active'
      testProject.tags = ['���试', '集成']

      const createdProject = await this.projectStore.createProject(testProject)
      return createdProject
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `创建测试项目失败: ${error}`)
      return null
    }
  }

  /**
   * 创建测试工点
   */
  private async createTestSite(projectId: string): Promise<Site | null> {
    try {
      const testSite = new Site()
      testSite.projectId = projectId
      testSite.name = `测试工点_${Date.now()}`
      testSite.description = '集成测试工点'
      testSite.latitude = 39.9042
      testSite.longitude = 116.4074
      testSite.address = '北京市朝阳区测试地址'
      testSite.type = 'construction'
      testSite.status = 'active'

      const createdSite = await this.siteStore.createSite(testSite)
      return createdSite
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `创建测试工点失败: ${error}`)
      return null
    }
  }

  /**
   * 初始化相机
   */
  private async initializeCamera(): Promise<boolean> {
    try {
      const result = await this.cameraService.initialize()
      return result
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `相机初始化失败: ${error}`)
      return false
    }
  }

  /**
   * 获取当前位置
   */
  private async getCurrentLocation(): Promise<{ latitude: number; longitude: number; altitude?: number } | null> {
    try {
      const location = await this.locationService.getCurrentLocation()
      if (location) {
        return {
          latitude: location.latitude,
          longitude: location.longitude,
          altitude: location.altitude
        }
      }
      return null
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `获取位置失败: ${error}`)
      return null
    }
  }

  /**
   * 创建测试照片
   */
  private async createTestPhoto(projectId: string, siteId: string, location: { latitude: number; longitude: number; altitude?: number }): Promise<Photo | null> {
    try {
      const testPhoto = new Photo()
      testPhoto.projectId = projectId
      testPhoto.siteId = siteId
      testPhoto.fileName = `test_photo_${Date.now()}.jpg`
      testPhoto.filePath = `/test/path/${testPhoto.fileName}`
      testPhoto.fileSize = 1024 * 1024 // 1MB
      testPhoto.width = 1920
      testPhoto.height = 1080
      testPhoto.latitude = location.latitude
      testPhoto.longitude = location.longitude
      testPhoto.altitude = location.altitude
      testPhoto.shootingTime = new Date()
      testPhoto.watermarkEnabled = true
      testPhoto.watermarkTemplate = 'default'
      testPhoto.tags = ['测试照片']

      const createdPhoto = await this.photoStore.createPhoto(testPhoto)
      return createdPhoto
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `创建测试照片失败: ${error}`)
      return null
    }
  }

  /**
   * 验证数据完整性
   */
  private async verifyDataIntegrity(project: Project, site: Site, photo: Photo): Promise<boolean> {
    try {
      // 验证项目数据
      const retrievedProject = await this.projectStore.getProjectById(project.id)
      if (!retrievedProject || retrievedProject.id !== project.id) {
        Logger.error(IntegrationTestManager.TAG, '项目数据验证失败')
        return false
      }

      // 验证工点数据
      const retrievedSite = await this.siteStore.getSiteById(site.id)
      if (!retrievedSite || retrievedSite.projectId !== project.id) {
        Logger.error(IntegrationTestManager.TAG, '工点数据验证失败')
        return false
      }

      // 验证照片数据
      const retrievedPhoto = await this.photoStore.getPhotoById(photo.id)
      if (!retrievedPhoto || retrievedPhoto.projectId !== project.id || retrievedPhoto.siteId !== site.id) {
        Logger.error(IntegrationTestManager.TAG, '照片数据验证失败')
        return false
      }

      // 验证关联关系
      const projectPhotos = await this.photoStore.getPhotosByProjectId(project.id)
      if (projectPhotos.length === 0 || !projectPhotos.some(p => p.id === photo.id)) {
        Logger.error(IntegrationTestManager.TAG, '项目照片关联验证失败')
        return false
      }

      return true
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `数据完整性验证异常: ${error}`)
      return false
    }
  }

  /**
   * 清理测试数据
   */
  private async cleanupTestData(projectId: string, siteId: string, photoId: string): Promise<void> {
    try {
      // 删除照片
      await this.photoStore.deletePhoto(photoId)

      // 删除工点
      await this.siteStore.deleteSite(siteId)

      // 删除项目
      await this.projectStore.deleteProject(projectId)

      Logger.info(IntegrationTestManager.TAG, '测试数据清理完成')
    } catch (error) {
      Logger.error(IntegrationTestManager.TAG, `清理测试数据失败: ${error}`)
    }
  }

  /**
   * 执行所有集成测试
   */
  async runAllTests(): Promise<{ testName: string; success: boolean; duration: number }[]> {
    const results: { testName: string; success: boolean; duration: number }[] = []

    // 测试项目到拍照流程
    let startTime = Date.now()
    const success1 = await this.testProjectToPhotoFlow()
    results.push({
      testName: '项目创建到拍照流程',
      success: success1,
      duration: Date.now() - startTime
    })

    // 测试照片管理流程
    startTime = Date.now()
    const success2 = await this.photoManagementTest.testPhotoManagementFlow()
    results.push({
      testName: '照片管理流程',
      success: success2,
      duration: Date.now() - startTime
    })

    // 数据一致性测试
    startTime = Date.now()
    const consistencyResults = await this.dataConsistencyTest.runAllConsistencyTests()
    consistencyResults.forEach(result => {
      results.push({
        testName: result.testName,
        success: result.success,
        duration: Date.now() - startTime
      })
    })

    // 性能测试
    startTime = Date.now()
    const performanceResults = await this.performanceTestManager.runAllPerformanceTests()
    performanceResults.forEach(result => {
      results.push({
        testName: result.testName,
        success: result.success,
        duration: result.duration
      })
    })

    // 编辑导出测试
    startTime = Date.now()
    const editingExportResults = await this.editingExportTest.runAllEditingExportTests()
    editingExportResults.forEach(result => {
      results.push(result)
    })

    return results
  }
}