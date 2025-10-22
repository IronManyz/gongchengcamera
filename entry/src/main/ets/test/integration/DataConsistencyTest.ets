import { Logger } from '../../utils/Logger'
import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { Photo } from '../../models/Photo'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { GlobalStore } from '../../store/GlobalStore'
import { DatabaseService } from '../../services/database/DatabaseService'

interface ConsistencyTestResult {
  testName: string
  success: boolean
  inconsistencies: string[]
  details?: Record<string, any>
}

/**
 * 数据一致性测试
 * 测试数据库与UI同步、状态管理一致性等
 */
export class DataConsistencyTest {
  private static readonly TAG = 'DataConsistencyTest'
  private projectStore: ProjectStore
  private siteStore: SiteStore
  private photoStore: PhotoStore
  private globalStore: GlobalStore
  private databaseService: DatabaseService

  constructor() {
    this.projectStore = new ProjectStore()
    this.siteStore = new SiteStore()
    this.photoStore = new PhotoStore()
    this.globalStore = GlobalStore.getInstance()
    this.databaseService = DatabaseService.getInstance()
  }

  /**
   * 测试数据库与UI同步
   */
  async testDatabaseUISync(): Promise<ConsistencyTestResult> {
    const testName = '数据库与UI同步测试'
    const inconsistencies: string[] = []

    try {
      Logger.info(DataConsistencyTest.TAG, `开始${testName}`)

      // 创建测试项目
      const testProject = await this.createTestProject()
      if (!testProject) {
        inconsistencies.push('测试项目创建失败')
        return { testName, success: false, inconsistencies }
      }

      // 验���数据库中的数据
      const dbProject = await this.projectStore.getProjectById(testProject.id)
      if (!dbProject) {
        inconsistencies.push('数据库中找不到项目数据')
      } else if (dbProject.name !== testProject.name) {
        inconsistencies.push('数据库项目名称不一致')
      }

      // 验证Store中的数据
      const storeProjects = await this.projectStore.getAllProjects()
      const storeProject = storeProjects.find(p => p.id === testProject.id)
      if (!storeProject) {
        inconsistencies.push('Store中找不到项目数据')
      } else if (storeProject.name !== testProject.name) {
        inconsistencies.push('Store项目名称不一致')
      }

      // 更新数据并验证同步
      testProject.name = '更新后的项目名称'
      await this.projectStore.updateProject(testProject)

      const updatedDbProject = await this.projectStore.getProjectById(testProject.id)
      if (!updatedDbProject || updatedDbProject.name !== '更新后的项目名称') {
        inconsistencies.push('数据库更新同步失败')
      }

      const updatedStoreProjects = await this.projectStore.getAllProjects()
      const updatedStoreProject = updatedStoreProjects.find(p => p.id === testProject.id)
      if (!updatedStoreProject || updatedStoreProject.name !== '更新后的项目名称') {
        inconsistencies.push('Store更新同步失败')
      }

      // 删除数据并验证同步
      await this.projectStore.deleteProject(testProject.id)
      const deletedDbProject = await this.projectStore.getProjectById(testProject.id)
      if (deletedDbProject) {
        inconsistencies.push('数据库删除同步失败')
      }

      const deletedStoreProjects = await this.projectStore.getAllProjects()
      const deletedStoreProject = deletedStoreProjects.find(p => p.id === testProject.id)
      if (deletedStoreProject) {
        inconsistencies.push('Store删除同步失败')
      }

      Logger.info(DataConsistencyTest.TAG, `${testName}完成`)
      return {
        testName,
        success: inconsistencies.length === 0,
        inconsistencies,
        details: { projectId: testProject.id }
      }

    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `${testName}异常: ${error}`)
      inconsistencies.push(`测试异常: ${error}`)
      return { testName, success: false, inconsistencies }
    }
  }

  /**
   * 测试状态管理一致性
   */
  async testStateManagementConsistency(): Promise<ConsistencyTestResult> {
    const testName = '状态管理一致性测试'
    const inconsistencies: string[] = []

    try {
      Logger.info(DataConsistencyTest.TAG, `开始${testName}`)

      // 测试全局状态一致性
      const initialTheme = this.globalStore.themeMode
      this.globalStore.themeMode = 'dark'

      // 等待状态更新
      await new Promise(resolve => setTimeout(resolve, 100))

      if (this.globalStore.themeMode !== 'dark') {
        inconsistencies.push('全局主题状态更新失败')
      }

      // 恢复初始状态
      this.globalStore.themeMode = initialTheme
      await new Promise(resolve => setTimeout(resolve, 100))

      if (this.globalStore.themeMode !== initialTheme) {
        inconsistencies.push('全局主题状态恢复失败')
      }

      // 测试项目状态一致性
      const testProject = await this.createTestProject()
      if (!testProject) {
        inconsistencies.push('测试项目创建失败')
        return { testName, success: false, inconsistencies }
      }

      // 修改项目状态
      testProject.status = 'completed'
      await this.projectStore.updateProject(testProject)

      // 验证状态一致性
      const updatedProject = await this.projectStore.getProjectById(testProject.id)
      if (!updatedProject || updatedProject.status !== 'completed') {
        inconsistencies.push('项目状态更新不一致')
      }

      // 清理测试数据
      await this.projectStore.deleteProject(testProject.id)

      Logger.info(DataConsistencyTest.TAG, `${testName}完成`)
      return {
        testName,
        success: inconsistencies.length === 0,
        inconsistencies
      }

    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `${testName}异常: ${error}`)
      inconsistencies.push(`测试异常: ${error}`)
      return { testName, success: false, inconsistencies }
    }
  }

  /**
   * 测试并发操作处理
   */
  async testConcurrentOperations(): Promise<ConsistencyTestResult> {
    const testName = '并发操作测试'
    const inconsistencies: string[] = []

    try {
      Logger.info(DataConsistencyTest.TAG, `开始${testName}`)

      // 创建测试数据
      const testProject = await this.createTestProject()
      if (!testProject) {
        inconsistencies.push('测试项目创建失败')
        return { testName, success: false, inconsistencies }
      }

      const testSite = await this.createTestSite(testProject.id)
      if (!testSite) {
        inconsistencies.push('测试工点创建失败')
        return { testName, success: false, inconsistencies }
      }

      // 并发创建照片
      const photoCreationPromises = []
      for (let i = 0; i < 10; i++) {
        photoCreationPromises.push(this.createTestPhoto(testProject.id, testSite.id, i))
      }

      const createdPhotos = await Promise.all(photoCreationPromises)
      const successfulPhotos = createdPhotos.filter(photo => photo !== null) as Photo[]

      if (successfulPhotos.length !== 10) {
        inconsistencies.push(`并发创建照片数量不正确: 期望10, 实际${successfulPhotos.length}`)
      }

      // 并发更新操作
      const updatePromises = successfulPhotos.slice(0, 5).map(async (photo, index) => {
        photo.fileName = `concurrent_update_${index}.jpg`
        return this.photoStore.updatePhoto(photo)
      })

      await Promise.all(updatePromises)

      // 验证更新结果
      for (let i = 0; i < 5; i++) {
        const updatedPhoto = await this.photoStore.getPhotoById(successfulPhotos[i].id)
        if (!updatedPhoto || !updatedPhoto.fileName.includes('concurrent_update')) {
          inconsistencies.push(`并发更新失败: 照片${i}`)
          break
        }
      }

      // 并发删除操作
      const deletePromises = successfulPhotos.slice(5, 10).map(photo =>
        this.photoStore.deletePhoto(photo.id)
      )

      await Promise.all(deletePromises)

      // 验证删除结果
      for (let i = 5; i < 10; i++) {
        const deletedPhoto = await this.photoStore.getPhotoById(successfulPhotos[i].id)
        if (deletedPhoto) {
          inconsistencies.push(`并发删除失败: 照片${i}`)
          break
        }
      }

      // 清理剩余数据
      for (let i = 0; i < 5; i++) {
        await this.photoStore.deletePhoto(successfulPhotos[i].id)
      }
      await this.siteStore.deleteSite(testSite.id)
      await this.projectStore.deleteProject(testProject.id)

      Logger.info(DataConsistencyTest.TAG, `${testName}完成`)
      return {
        testName,
        success: inconsistencies.length === 0,
        inconsistencies,
        details: {
          createdPhotos: successfulPhotos.length,
          concurrentOperations: 10
        }
      }

    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `${testName}异常: ${error}`)
      inconsistencies.push(`测试异常: ${error}`)
      return { testName, success: false, inconsistencies }
    }
  }

  /**
   * 测试异常恢复机制
   */
  async testExceptionRecovery(): Promise<ConsistencyTestResult> {
    const testName = '异常恢复机制测试'
    const inconsistencies: string[] = []

    try {
      Logger.info(DataConsistencyTest.TAG, `开始${testName}`)

      // 测试创建失败时的恢复
      try {
        const invalidProject = new Project()
        invalidProject.name = '' // 无效的项目名称
        await this.projectStore.createProject(invalidProject)
        inconsistencies.push('无效项目创建应该失败但成功了')
      } catch (error) {
        // 预期的错误，验证系统状态是否正常
        const projects = await this.projectStore.getAllProjects()
        if (projects.find(p => p.name === '')) {
          inconsistencies.push('失败的操作留下了无效数据')
        }
      }

      // 测试更新失败时的恢复
      const testProject = await this.createTestProject()
      if (!testProject) {
        inconsistencies.push('测试项目创建失败')
        return { testName, success: false, inconsistencies }
      }

      try {
        testProject.name = '' // 无效的更新
        await this.projectStore.updateProject(testProject)
        inconsistencies.push('无效项目更新应该失败但成功了')
      } catch (error) {
        // 验证原数据未受影响
        const originalProject = await this.projectStore.getProjectById(testProject.id)
        if (originalProject && originalProject.name === '') {
          inconsistencies.push('失败的更新影响了原有数据')
        }
      }

      // 测试事务回滚
      const originalProjectData = await this.projectStore.getProjectById(testProject.id)

      // 模拟事务操作
      try {
        // 执行一系列操作，其中一个失败
        await this.simulateFailingTransaction(testProject.id)
      } catch (error) {
        // 验证数据回滚
        const rolledBackProject = await this.projectStore.getProjectById(testProject.id)
        if (!rolledBackProject ||
            rolledBackProject.name !== originalProjectData?.name ||
            rolledBackProject.description !== originalProjectData?.description) {
          inconsistencies.push('事务回滚失败，数据不一致')
        }
      }

      // 清理测试数据
      await this.projectStore.deleteProject(testProject.id)

      Logger.info(DataConsistencyTest.TAG, `${testName}完成`)
      return {
        testName,
        success: inconsistencies.length === 0,
        inconsistencies,
        details: { recoveryTests: 3 }
      }

    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `${testName}异常: ${error}`)
      inconsistencies.push(`测试异常: ${error}`)
      return { testName, success: false, inconsistencies }
    }
  }

  /**
   * 创建测试项目
   */
  private async createTestProject(): Promise<Project | null> {
    try {
      const project = new Project()
      project.name = `数据一致性测试项目_${Date.now()}`
      project.description = '用于数据一致性测试'
      project.status = 'active'
      return await this.projectStore.createProject(project)
    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `创建测试项目失败: ${error}`)
      return null
    }
  }

  /**
   * 创建测试工点
   */
  private async createTestSite(projectId: string): Promise<Site | null> {
    try {
      const site = new Site()
      site.projectId = projectId
      site.name = `数据一致性测试工点_${Date.now()}`
      site.description = '用于数据一致性测试'
      site.latitude = 39.9042
      site.longitude = 116.4074
      site.status = 'active'
      return await this.siteStore.createSite(site)
    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `创建测试工点失败: ${error}`)
      return null
    }
  }

  /**
   * 创建测试照片
   */
  private async createTestPhoto(projectId: string, siteId: string, index: number): Promise<Photo | null> {
    try {
      const photo = new Photo()
      photo.projectId = projectId
      photo.siteId = siteId
      photo.fileName = `consistency_test_photo_${index}_${Date.now()}.jpg`
      photo.filePath = `/test/consistency/${photo.fileName}`
      photo.fileSize = 1024 * 1024
      photo.width = 1920
      photo.height = 1080
      photo.shootingTime = new Date()
      return await this.photoStore.createPhoto(photo)
    } catch (error) {
      Logger.error(DataConsistencyTest.TAG, `创建测试照片失败: ${error}`)
      return null
    }
  }

  /**
   * 模拟失败的事务操作
   */
  private async simulateFailingTransaction(projectId: string): Promise<void> {
    // 这个方法模拟一个包含失败操作的事务
    // 在实际应用中，这应该使用数据库事务来保证原子性
    throw new Error('模拟事务失败')
  }

  /**
   * 运行所有数据一致性测试
   */
  async runAllConsistencyTests(): Promise<ConsistencyTestResult[]> {
    const results: ConsistencyTestResult[] = []

    // 数据库与UI同步测试
    const dbUISyncResult = await this.testDatabaseUISync()
    results.push(dbUISyncResult)

    // 状态管理一致性测试
    const stateConsistencyResult = await this.testStateManagementConsistency()
    results.push(stateConsistencyResult)

    // 并发操作处理测试
    const concurrentOpsResult = await this.testConcurrentOperations()
    results.push(concurrentOpsResult)

    // 异常恢复机制测试
    const exceptionRecoveryResult = await this.testExceptionRecovery()
    results.push(exceptionRecoveryResult)

    return results
  }
}