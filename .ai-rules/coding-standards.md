---
title: Coding Standards
description: "EngineeringCamera项目编码规范：ArkTS开发标准、代码风格、最佳实践和性能优化指南"
inclusion: always
---

# 工程相机 (Engineering Camera) 编码规范

## 概述

本文档定义了EngineeringCamera项目的编码规范和最佳实践。所有开发人员必须严格遵守这些规范，确保代码质量、一致性和可维护性。

**强制要求：必须使用 ArkTS 与 V2 响应式状态管理**

## 1. 语言和框架规范

### 1.1 ArkTS 编码标准

#### 基本语法要求
```typescript
// ✅ 正确：使用 ArkTS 严格类型注解
@Entry
@Component
struct CameraPage {
  @State photos: PhotoModel[] = []  // 明确类型注解
  @State isLoading: boolean = false

  build() {
    // 组件构建逻辑
  }
}

// ❌ 错误：使用 any 类型或缺少类型注解
@State photos: any = []
```

#### 变量命名规范
- **文件名**: camelCase (如: `cameraPage.ets`, `userService.ets`)
- **组件名**: PascalCase (如: `CameraPage`, `PhotoCard`)
- **变量名**: camelCase (如: `photoCount`, `isLoading`)
- **常量名**: UPPER_SNAKE_CASE (如: `MAX_PHOTO_COUNT`)
- **类名**: PascalCase (如: `PhotoModel`, `DatabaseService`)

#### 导入顺序
```typescript
// 1. 系统模块导入
import { UIAbility } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@ohos.router'

// 2. 第三方库导入
import { Preferences } from '@ohos.data.preferences'

// 3. 项目内部导入
import { PhotoModel } from '../models/PhotoModel'
import { CameraService } from '../services/CameraService'
```

### 1.2 V2 响应式状态管理规范

#### 装饰器选择指南
```typescript
// ✅ 组件内部状态 - 使用 @State
@State currentPage: number = 1
@State searchQuery: string = ''

// ✅ 父子组件单向传递 - 使用 @Prop
@Component
struct PhotoItem {
  @Prop photo: PhotoModel
  @Prop index: number
}

// ✅ 父子组件双向同步 - 使用 @Link
@Component
struct PhotoEditor {
  @Link currentPhoto: PhotoModel
}

// ✅ 复杂对象深度观察 - 使用 @Observed + @ObjectLink
@Observed
class PhotoModel {
  @Track id: string
  @Track filePath: string
  @Track metadata: PhotoMetadata

  constructor(id: string, filePath: string) {
    this.id = id
    this.filePath = filePath
    this.metadata = new PhotoMetadata()
  }
}

@Component
struct PhotoCard {
  @ObjectLink photo: PhotoModel
}

// ✅ 跨层级数据共享 - 使用 @Provide + @Consume
@Entry
@Component
struct AppRoot {
  @Provide('appTheme') theme: AppTheme = new AppTheme()
}

// ✅ 状态监听 - 使用 @Watch
@State @Watch('onPhotosChange') photos: PhotoModel[] = []

onPhotosChange() {
  // 处理照片列表变化
}
```

#### V2 高级装饰器使用
```typescript
// API 12+ 精细化控制
@Component
struct AdvancedComponent {
  @Local private internalState: string = 'default'  // 本地状态，不被父组件覆盖
  @Param config: ComponentConfig = {}               // 组件参数
  @Monitor('dataChange') private dataMonitor: void = () => {}  // 监控数据变化
}
```

#### ComponentV2 @Require 装饰器使用规范
```typescript
// ✅ 正确：@Require 装饰的 @Param 必须提供默认值
@ComponentV2
export struct ConfirmDialog {
  @Param show: boolean = false
  @Param title: string = '确认'
  @Require @Param onConfirm: () => void = () => {}  // 必须提供默认值
  @Require @Param onCancel: () => void = () => {}    // 必须提供默认值
  @Require @Param onClose: () => void = () => {}      // 必须提供默认值

  build() {
    // 组件构建逻辑
  }
}

// ✅ 正确：使用组件时传递所有必需参数
ConfirmDialog({
  show: this.showDialog,
  title: '删除确认',
  onConfirm: () => this.handleConfirm(),
  onCancel: () => this.handleCancel(),
  onClose: () => this.handleClose()
})

// ❌ 错误：@Require 装饰器没有默认值
@ComponentV2
export struct BadDialog {
  @Require @Param onConfirm?: () => void  // 编译错误：必须提供默认值
}
```

#### CustomComponent 属性命名规范
```typescript
// ✅ 正确：避免与 CustomComponent 内置属性冲突
@ComponentV2
export struct LoadingIndicator {
  @Param loading: boolean = false
  @Param indicatorSize: number = 24      // 避免使用 'size' (内置属性)
  @Param bgColor: string = '#F5F5F5'     // 避免使用 'backgroundColor' (内置属性)
  @Param message: string = ''

  build() {
    LoadingProgress()
      .width(this.indicatorSize)         // 使用自定义属性名
      .height(this.indicatorSize)
      .color('#007AFF')
  }
}

// ❌ 错误：与内置属性名冲突
@ComponentV2
export struct BadIndicator {
  @Param size: number = 24              // 编译错误：与内置 size 属性冲突
  @Param backgroundColor: string = '#FFF' // 编译错误：与内置 backgroundColor 属性冲突
}
```

#### ArkTS 结构化类型限制
```typescript
// ✅ 正确：使用具体类而不是接口类型转换
export class PaginatedResponseImpl<T> implements PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
  hasNext: boolean
  hasPrev: boolean

  constructor(data: T[], total: number, page: number, pageSize: number) {
    this.data = data
    this.total = total
    this.page = page
    this.pageSize = pageSize
    this.totalPages = Math.ceil(total / pageSize)
    this.hasNext = page < this.totalPages
    this.hasPrev = page > 1
  }
}

// 服务返回具体类型
async queryProjectsWithPagination(): Promise<PaginatedResponseImpl<Project>> {
  return new PaginatedResponseImpl(projects, total, page, pageSize)
}

// ❌ 错误：ArkTS 不支持结构化类型转换
const result: PaginatedResponse<Project> = serviceResult as PaginatedResponse<Project>  // 编译错误
```

## 2. 组件开发规范

### 2.1 页面组件结构
```typescript
@Entry
@Component
struct ProjectManagePage {
  // 1. 状态变量定义
  @State projects: ProjectModel[] = []
  @State isLoading: boolean = false
  @State selectedProject: ProjectModel | null = null

  // 2. 生命周期方法
  aboutToAppear() {
    this.loadProjects()
  }

  aboutToDisappear() {
    this.cleanup()
  }

  // 3. 私有方法
  private async loadProjects() {
    this.isLoading = true
    try {
      this.projects = await ProjectService.getAllProjects()
    } catch (error) {
      // 错误处理
    } finally {
      this.isLoading = false
    }
  }

  // 4. 事件处理方法
  private onProjectClick(project: ProjectModel) {
    this.selectedProject = project
    router.pushUrl({
      url: 'pages/ProjectDetail',
      params: { projectId: project.id }
    })
  }

  // 5. UI构建
  build() {
    Column() {
      // 页面内容
    }
    .width('100%')
    .height('100%')
  }
}
```

### 2.2 可复用组件规范
```typescript
@Component
struct PhotoCard {
  @Prop photo: PhotoModel
  @Prop index: number = 0
  @Prop showDate: boolean = true
  private onClick?: (photo: PhotoModel) => void

  build() {
    Column() {
      Image(this.photo.filePath)
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.onClick?.(this.photo)
        })

      if (this.showDate) {
        Text(this.formatDate(this.photo.takenAt))
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
    }
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
  }

  private formatDate(timestamp: number): string {
    // 格式化日期逻辑
  }
}
```

### 2.3 @Reusable 组件规范
```typescript
@Reusable
@Component
struct PhotoListItem {
  @State photo: PhotoModel = new PhotoModel()

  aboutToReuse(params: ESObject) {
    this.photo = params.photo
  }

  build() {
    // 组件内容
  }
}
```

## 3. 数据模型规范

### 3.1 数据模型定义
```typescript
@Observed
export class PhotoModel {
  @Track id: string = ''
  @Track filePath: string = ''
  @Track projectId: string = ''
  @Track siteId: string = ''
  @Track takenAt: number = 0
  @Track latitude: number = 0
  @Track longitude: number = 0
  @Track altitude: number = 0
  @Track azimuth: number = 0
  @Track address: string = ''
  @Track weather: string = ''
  @Track watermarkTemplateId: string = ''
  @Track notes: string = ''
  @Track tags: string[] = []
  @Track createdAt: number = 0
  @Track updatedAt: number = 0

  constructor(data?: Partial<PhotoModel>) {
    if (data) {
      Object.assign(this, data)
    }
  }

  // 计算属性
  get displayDate(): string {
    return new Date(this.takenAt).toLocaleDateString()
  }

  get locationText(): string {
    return `${this.latitude.toFixed(6)}, ${this.longitude.toFixed(6)}`
  }
}
```

### 3.2 枚举定义
```typescript
export enum PhotoStatus {
  NORMAL = 'normal',
  DELETED = 'deleted',
  ARCHIVED = 'archived'
}

export enum UserRole {
  OWNER = 'owner',
  EDITOR = 'editor',
  VIEWER = 'viewer'
}

export enum WatermarkPosition {
  TOP_LEFT = 'top_left',
  TOP_RIGHT = 'top_right',
  BOTTOM_LEFT = 'bottom_left',
  BOTTOM_RIGHT = 'bottom_right'
}
```

## 4. 服务层规范

### 4.1 服务类结构
```typescript
export class PhotoService {
  private static instance: PhotoService

  // 单例模式
  static getInstance(): PhotoService {
    if (!PhotoService.instance) {
      PhotoService.instance = new PhotoService()
    }
    return PhotoService.instance
  }

  // 私有构造函数
  private constructor() {}

  // CRUD 操作
  async createPhoto(photoData: Partial<PhotoModel>): Promise<PhotoModel> {
    const photo = new PhotoModel(photoData)
    photo.id = this.generateId()
    photo.createdAt = Date.now()
    photo.updatedAt = Date.now()

    await DatabaseService.insert('photos', photo)
    return photo
  }

  async getPhotosByProject(projectId: string): Promise<PhotoModel[]> {
    return await DatabaseService.query('photos', { projectId })
  }

  async updatePhoto(photoId: string, updates: Partial<PhotoModel>): Promise<PhotoModel> {
    const photo = await this.getPhotoById(photoId)
    if (photo) {
      Object.assign(photo, updates)
      photo.updatedAt = Date.now()
      await DatabaseService.update('photos', photo)
    }
    return photo
  }

  async deletePhoto(photoId: string): Promise<boolean> {
    return await DatabaseService.delete('photos', { id: photoId })
  }

  // 私有工具方法
  private generateId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9)
  }
}
```

### 4.2 数据库服务规范
```typescript
export class DatabaseService {
  private static instance: DatabaseService
  private db: relationalStore.RdbStore | null = null

  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService()
    }
    return DatabaseService.instance
  }

  async initialize(): Promise<void> {
    // 数据库初始化逻辑
  }

  async insert(table: string, data: ESObject): Promise<void> {
    if (!this.db) {
      throw new Error('Database not initialized')
    }

    const values = relationalStore.createValueBucket(data)
    await this.db.insert(table, values)
  }

  async query(table: string, where?: ESObject): Promise<any[]> {
    // 查询逻辑
  }

  async update(table: string, data: ESObject): Promise<number> {
    // 更新逻辑
  }

  async delete(table: string, where: ESObject): Promise<number> {
    // 删除逻辑
  }
}
```

## 5. 错误处理规范

### 5.1 异常处理模式
```typescript
// ✅ 推荐的错误处理方式
async function loadPhotos(): Promise<PhotoModel[]> {
  try {
    const photos = await PhotoService.getPhotosByProject(currentProjectId)
    return photos
  } catch (error) {
    hilog.error(0x0000, 'PhotoService', 'Failed to load photos: %{public}s', JSON.stringify(error))

    // 显示用户友好的错误信息
    showToast('加载照片失败，请重试')

    // 返回空数组作为默认值
    return []
  }
}

// ✅ 自定义错误类
export class CameraError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: any
  ) {
    super(message)
    this.name = 'CameraError'
  }
}

// 使用自定义错误
async function takePhoto(): Promise<PhotoModel> {
  try {
    const photo = await CameraService.capture()
    return photo
  } catch (error) {
    throw new CameraError(
      '拍照失败',
      'CAMERA_CAPTURE_ERROR',
      { originalError: error }
    )
  }
}
```

### 5.2 日志记录规范
```typescript
// 日志级别和标签定义
const TAG = 'EngineeringCamera'
const DOMAIN = 0x0000

// 不同级别的日志记录
hilog.info(DOMAIN, TAG, 'User action: %{public}s', 'photo_taken')
hilog.warn(DOMAIN, TAG, 'Storage space low: %{public}d MB', remainingSpace)
hilog.error(DOMAIN, TAG, 'Database operation failed: %{public}s', errorMessage)

// 结构化日志记录
function logUserAction(action: string, details?: ESObject): void {
  hilog.info(DOMAIN, TAG, 'UserAction: %{public}s | Details: %{public}s',
    action, JSON.stringify(details))
}
```

## 6. 性能优化规范

### 6.1 列表渲染优化
```typescript
// ✅ 大列表使用 LazyForEach
@Entry
@Component
struct PhotoGalleryPage {
  @State dataSource: PhotoDataSource = new PhotoDataSource()

  build() {
    List() {
      LazyForEach(
        this.dataSource,
        (photo: PhotoModel) => {
          ListItem() {
            PhotoListItem({ photo: photo })
          }
        },
        (photo: PhotoModel) => photo.id  // 重要：提供唯一键
      )
    }
    .cachedCount(10)  // 缓存预渲染项数
  }
}

// ✅ 数据源实现
class PhotoDataSource implements IDataSource {
  private photos: PhotoModel[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.photos.length
  }

  getData(index: number): PhotoModel {
    return this.photos[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }
}
```

### 6.2 内存管理
```typescript
@Component
struct ImagePreview {
  @State imagePath: string = ''
  private imagePixelMap: image.PixelMap | null = null

  aboutToAppear() {
    this.loadImage()
  }

  aboutToDisappear() {
    // 释放图片资源
    if (this.imagePixelMap) {
      this.imagePixelMap.release()
      this.imagePixelMap = null
    }
  }

  private async loadImage() {
    try {
      this.imagePixelMap = await ImageUtils.loadPixelMap(this.imagePath)
    } catch (error) {
      hilog.error(0x0000, 'ImagePreview', 'Failed to load image: %{public}s', error)
    }
  }
}
```

### 6.3 异步操作优化
```typescript
// ✅ 并发控制
class TaskManager {
  private static MAX_CONCURRENT = 3
  private runningCount = 0
  private queue: (() => void)[] = []

  async execute<T>(task: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      const wrappedTask = async () => {
        this.runningCount++
        try {
          const result = await task()
          resolve(result)
        } catch (error) {
          reject(error)
        } finally {
          this.runningCount--
          this.processQueue()
        }
      }

      if (this.runningCount < TaskManager.MAX_CONCURRENT) {
        wrappedTask()
      } else {
        this.queue.push(wrappedTask)
      }
    })
  }

  private processQueue() {
    if (this.queue.length > 0 && this.runningCount < TaskManager.MAX_CONCURRENT) {
      const task = this.queue.shift()!
      task()
    }
  }
}
```

## 7. 测试规范

### 7.1 单元测试
```typescript
// 单元测试示例
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'

describe('PhotoService', () => {
  let photoService: PhotoService

  beforeAll(async () => {
    photoService = PhotoService.getInstance()
    await photoService.initialize()
  })

  afterAll(async () => {
    await photoService.cleanup()
  })

  it('should create photo successfully', async () => {
    const photoData = {
      filePath: '/test/path.jpg',
      projectId: 'project123'
    }

    const photo = await photoService.createPhoto(photoData)

    expect(photo.id).not.toBe('')
    expect(photo.filePath).toBe(photoData.filePath)
    expect(photo.projectId).toBe(photoData.projectId)
    expect(photo.createdAt).toBeGreaterThan(0)
  })

  it('should throw error for invalid data', async () => {
    await expect(photoService.createPhoto({})).rejects.toThrow()
  })
})
```

### 7.2 UI测试
```typescript
// UI测试示例
describe('PhotoGalleryPage', () => {
  it('should display photos correctly', async () => {
    const driver = Driver.create()
    await driver.delayMs(1000)

    const photoItems = await driver.findComponent(ComponentStub.byKey('photo_item'))
    expect(photoItems.length).toBeGreaterThan(0)
  })

  it('should handle photo click', async () => {
    const driver = Driver.create()
    const photoItem = await driver.findComponent(ComponentStub.byKey('photo_item_0'))

    await photoItem.click()
    await driver.delayMs(500)

    const previewPage = await driver.findComponent(ComponentStub.byKey('photo_preview'))
    expect(previewPage).not.toBeNull()
  })
})
```

## 8. 安全规范

### 8.1 数据安全
```typescript
// 敏感数据加密
export class SecureStorage {
  private static readonly ENCRYPTION_KEY = 'user_encryption_key'

  static async saveSecureData(key: string, data: string): Promise<void> {
    const encryptedData = await CryptoUtils.encrypt(data, this.ENCRYPTION_KEY)
    await PreferencesService.save(key, encryptedData)
  }

  static async getSecureData(key: string): Promise<string> {
    const encryptedData = await PreferencesService.get(key)
    return await CryptoUtils.decrypt(encryptedData, this.ENCRYPTION_KEY)
  }
}

// 权限检查
export class PermissionChecker {
  static async checkCameraPermission(): Promise<boolean> {
    const permission = 'ohos.permission.CAMERA'
    const status = await bundleManager.requestPermissionFromUser(getContext(), [permission])
    return status.grantedStatus.includes(bundleManager.GrantStatus.PERMISSION_GRANTED)
  }
}
```

### 8.2 输入验证
```typescript
// 数据验证
export class PhotoValidator {
  static validatePhotoData(data: Partial<PhotoModel>): string[] {
    const errors: string[] = []

    if (!data.filePath || data.filePath.trim() === '') {
      errors.push('文件路径不能为空')
    }

    if (data.projectId && ! /^[a-zA-Z0-9_-]+$/.test(data.projectId)) {
      errors.push('项目ID格式无效')
    }

    if (data.latitude && (data.latitude < -90 || data.latitude > 90)) {
      errors.push('纬度值超出范围')
    }

    return errors
  }
}
```

## 9. 代码注释规范

### 9.1 文件头注释
```typescript
/**
 * PhotoService - 照片管理服务
 *
 * 功能描述：
 * - 照片的CRUD操作
 * - 照片元数据管理
 * - 照片文件存储管理
 *
 * @author EngineeringCamera Team
 * @version 1.0.0
 * @since 2024-01-01
 */
```

### 9.2 函数注释
```typescript
/**
 * 创建新照片记录
 *
 * @param photoData 照片数据，包含文件路径、项目ID等
 * @returns Promise<PhotoModel> 创建成功的照片模型
 * @throws {CameraError} 当文件不存在或数据无效时抛出异常
 *
 * @example
 * ```typescript
 * const photo = await PhotoService.createPhoto({
 *   filePath: '/path/to/photo.jpg',
 *   projectId: 'project123'
 * })
 * ```
 */
async createPhoto(photoData: Partial<PhotoModel>): Promise<PhotoModel> {
  // 实现逻辑
}
```

### 9.3 复杂逻辑注释
```typescript
build() {
  Column() {
    // 顶部操作栏：包含返回按钮和标题
    Row() {
      Button('返回')
        .onClick(() => router.back())

      Text('照片管理')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ horizontal: 16 })

    // 照片列表：使用LazyForEach优化大列表性能
    List() {
      LazyForEach(
        this.photoDataSource,
        (photo: PhotoModel) => {
          ListItem() {
            PhotoCard({ photo: photo })
          }
        },
        (photo: PhotoModel) => photo.id  // 使用照片ID作为唯一键
      )
    }
    .cachedCount(10)  // 预缓存10项提升滑动流畅性
  }
}
```

## 10. 代码审查清单

### 10.1 强制要求
- [ ] 使用ArkTS严格类型注解
- [ ] 遵循V2响应式状态管理规范
- [ ] 所有异步操作都有错误处理
- [ ] 资源在组件销毁时正确释放
- [ ] 列表渲染提供唯一键
- [ ] 敏感操作有权限检查

### 10.2 质量检查
- [ ] 函数和类的命名清晰明确
- [ ] 代码逻辑简洁，无重复代码
- [ ] 有适当的单元测试覆盖
- [ ] 日志记录完整且规范
- [ ] 性能敏感代码有优化措施
- [ ] 安全敏感操作有防护措施

### 10.3 文档要求
- [ ] 公共API有完整注释
- [ ] 复杂业务逻辑有说明
- [ ] 配置项和使用示例清晰
- [ ] 变更记录及时更新

---

**注意**: 本规范文档是项目开发的强制性要求，所有开发人员必须严格遵守。违反规范可能会导致代码被拒绝合并。