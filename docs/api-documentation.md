# EngineeringCamera API 文档

> **版本**: v1.0.0
> **更新日期**: 2025-10-22
> **API类型**: HarmonyOS ArkTS 内部API

## 📋 目录

1. [API概述](#1-api概述)
2. [数据模型API](#2-数据模型api)
3. [数据库服务API](#3-数据库服务api)
4. [业务服务API](#4-业务服务api)
5. [Store状态管理API](#5-store状态管理api)
6. [工具类API](#6-工具类api)
7. [组件API](#7-组件api)
8. [错误处理](#8-错误处理)
9. [使用示例](#9-使用示例)
10. [API变更日志](#10-api变更日志)

---

## 1. API概述

### 1.1 架构设计

EngineeringCamera 采用分层架构设计，API分为以下层次：

```
┌─────────────────────────────────────┐
│           UI层 (Pages/Components)    │
├─────────────────────────────────────┤
│        Store层 (状态管理)            │
├─────────────────────────────────────┤
│      Service层 (业务逻辑)            │
├─────────────────────────────────────┤
│        Model层 (数据模型)            │
├─────────────────────────────────────┤
│     Database层 (数据持久化)          │
└─────────────────────────────────────┘
```

### 1.2 技术栈

- **开发语言**: ArkTS
- **UI框架**: ArkUI
- **状态管理**: V2响应式 (@ObservedV2 + @Trace)
- **数据库**: HarmonyOS关系型数据库
- **架构模式**: MVVM + 单例模式

### 1.3 设计原则

- **单一职责**: 每个类和接口职责明确
- **依赖注入**: 通过构造函数注入依赖
- **响应式编程**: 使用V2响应式装饰器
- **错误处理**: 统一的错误处理机制
- **类型安全**: 强类型约束和接口定义

---

## 2. 数据模型API

### 2.1 BaseModel 基础模型

#### 2.1.1 接口定义

```typescript
@ObservedV2
export class BaseModel {
  @Trace id: string = ''
  @Trace createdAt: Date = new Date()
  @Trace updatedAt: Date = new Date()
  @Trace version: number = 1

  // 核心方法
  isValid(): boolean
  updateTimestamp(): void
  toJSON(): Record<string, any>
  static fromJSON(data: Record<string, any>): BaseModel
  clone(): BaseModel
  static generateId(): string
}
```

#### 2.1.2 使用方法

```typescript
// 创建基础模型实例
const model = new BaseModel()

// 生成唯一ID
const uniqueId = BaseModel.generateId()

// 验证模型有效性
const isValid = model.isValid()

// 更新时间戳
model.updateTimestamp()

// 转换为JSON
const jsonData = model.toJSON()
```

### 2.2 Project 项目模型

#### 2.2.1 接口定义

```typescript
@ObservedV2
export class Project extends BaseModel {
  @Trace name: string = ''
  @Trace code: string = ''
  @Trace client: string = ''
  @Trace manager: string = ''
  @Trace startDate: Date = new Date()
  @Trace endDate: Date = new Date()
  @Trace description: string = ''
  @Trace tags: string[] = []
  @Trace status: ProjectStatus = ProjectStatus.ACTIVE
  @Trace siteCount: number = 0
  @Trace photoCount: number = 0
  @Local metadata: Record<string, any> = {}

  // 关联数据
  sites: Site[] = []
  photos: Photo[] = []

  // 业务方法
  getDurationInDays(): number
  isExpired(): boolean
  isActive(): boolean
  getProgressPercentage(): number
  addTag(tag: string): void
  removeTag(tag: string): void
  setStatus(status: ProjectStatus): void
  matchesSearch(query: string): boolean
  getDisplayName(): string
  getStatusText(): string
}
```

#### 2.2.2 使用示例

```typescript
// 创建项目
const project = new Project()
project.name = '城市道路改造工程'
project.code = 'PRJ-2025-001'
project.client = '市政建设局'
project.manager = '张工'
project.startDate = new Date('2025-01-01')
project.endDate = new Date('2025-12-31')

// 添加标签
project.addTag('市政工程')
project.addTag('道路建设')

// 检查项目状态
if (project.isActive()) {
  console.log('项目正在进行中')
}

// 获取项目进度
const progress = project.getProgressPercentage()
console.log(`项目进度: ${progress}%`)
```

### 2.3 Site 工点模型

#### 2.3.1 接口定义

```typescript
@ObservedV2
export class Site extends BaseModel {
  @Trace projectId: string = ''
  @Trace name: string = ''
  @Trace address: string = ''
  @Trace latitude: number = 0
  @Trace longitude: number = 0
  @Trace altitude: number = 0
  @Trace description: string = ''
  @Trace category: string = ''
  @Trace status: SiteStatus = SiteStatus.ACTIVE
  @Trace photoCount: number = 0

  // 业务方法
  getLocationString(): string
  distanceTo(otherSite: Site): number
  isValidLocation(): boolean
  setAddress(address: string): void
  setCoordinates(lat: number, lng: number, alt?: number): void
  matchesSearch(query: string): boolean
}
```

### 2.4 Photo 照片模型

#### 2.4.1 接口定义

```typescript
@ObservedV2
export class Photo extends BaseModel {
  @Trace projectId: string = ''
  @Trace siteId: string = ''
  @Trace filename: string = ''
  @Trace filepath: string = ''
  @Trace thumbnail: string = ''
  @Trace fileSize: number = 0
  @Trace width: number = 0
  @Trace height: number = 0
  @Trace captureTime: Date = new Date()
  @Trace latitude: number = 0
  @Trace longitude: number = 0
  @Trace altitude: number = 0
  @Trace address: string = ''
  @Trace weather: string = ''
  @Trace photographer: string = ''
  @Trace watermarkTemplate: string = ''
  @Trace description: string = ''
  @Trace tags: string[] = []
  @Trace edited: boolean = false

  // 业务方法
  getLocationInfo(): LocationInfo
  getDisplaySize(): string
  getFormattedFileSize(): string
  getThumbnailUrl(): string
  getFullUrl(): string
  addTag(tag: string): void
  removeTag(tag: string): void
  matchesSearch(query: string): boolean
}
```

### 2.5 WatermarkTemplate 水印模板模型

#### 2.5.1 接口定义

```typescript
@ObservedV2
export class WatermarkTemplate extends BaseModel {
  @Trace name: string = ''
  @Trace category: string = ''
  @Trace description: string = ''
  @Trace layout: WatermarkLayout
  @Trace elements: WatermarkElement[]
  @Trace style: WatermarkStyle
  @Trace isDefault: boolean = false
  @Trace isBuiltIn: boolean = false

  // 业务方法
  preview(): string
  applyToPhoto(photo: Photo): Promise<string>
  isValid(): boolean
  duplicate(): WatermarkTemplate
  matchesSearch(query: string): boolean
}
```

---

## 3. 数据库服务API

### 3.1 DatabaseService 数据库服务

#### 3.1.1 接口定义

```typescript
export class DatabaseService {
  // 单例模式
  static getInstance(): DatabaseService

  // 初始化
  async initialize(context: Context, config?: Partial<DatabaseConfig>): Promise<DatabaseInitResult>

  // 连接管理
  getStore(): relationalStore.RdbStore
  isReady(): boolean
  async close(): Promise<void>

  // 执行操作
  async executeTransaction<T>(callback: TransactionCallback<T>): Promise<T>
  async executeQuery(sql: string, args?: any[]): Promise<relationalStore.ResultSet>
  async executeSql(sql: string, args?: any[]): Promise<number>

  // 维护操作
  async optimize(): Promise<void>
  async rebuildIndexes(): Promise<{ success: boolean; rebuiltCount: number; totalCount: number }>
  async getDatabaseStats(): Promise<DatabaseStats>

  // 版本管理
  async getCurrentVersion(): Promise<number>
  async tableExists(tableName: string): Promise<boolean>
}
```

#### 3.1.2 使用示例

```typescript
// 初始化数据库服务
const dbService = DatabaseService.getInstance()
const result = await dbService.initialize(context, {
  name: 'engineering_camera.db',
  securityLevel: relationalStore.SecurityLevel.S1,
  encrypt: true
})

// 检查初始化结果
if (result.success) {
  console.log(`数据库初始化成功，创建了${result.tablesCreated}个表`)
}

// 执行事务
const result = await dbService.executeTransaction(async (store) => {
  await store.executeSql('INSERT INTO projects (name, code) VALUES (?, ?)', ['测试项目', 'TEST-001'])
  await store.executeSql('INSERT INTO sites (project_id, name) VALUES (?, ?)', [projectId, '测试工点'])
  return { success: true }
})

// 执行查询
const resultSet = await dbService.executeQuery(
  'SELECT * FROM projects WHERE status = ? ORDER BY created_at DESC',
  [ProjectStatus.ACTIVE]
)
```

### 3.2 ProjectService 项目数据服务

#### 3.2.1 接口定义

```typescript
export class ProjectService {
  // CRUD操作
  async create(project: Project): Promise<string>
  async getById(id: string): Promise<Project | null>
  async getAll(): Promise<Project[]>
  async update(project: Project): Promise<boolean>
  async delete(id: string): Promise<boolean>
  async deleteByIds(ids: string[]): Promise<boolean>

  // 查询操作
  async findByName(name: string): Promise<Project[]>
  async findByStatus(status: ProjectStatus): Promise<Project[]>
  async searchProjects(query: string, filters?: ProjectSearchFilters): Promise<Project[]>
  async getProjectsByDateRange(startDate: Date, endDate: Date): Promise<Project[]>

  // 分页操作
  async getProjectsByPage(params: PaginationParams): Promise<PaginationResult<Project>>

  // 统计操作
  async getProjectCount(): Promise<number>
  async getProjectStatistics(): Promise<ProjectStatistics>

  // 业务操作
  async updateProjectStatus(id: string, status: ProjectStatus): Promise<boolean>
  async updateProjectCounts(id: string, siteCount: number, photoCount: number): Promise<boolean>
}
```

#### 3.2.2 使用示例

```typescript
const projectService = new ProjectService()

// 创建项目
const project = new Project()
project.name = '城市道路改造工程'
project.code = 'PRJ-2025-001'
const projectId = await projectService.create(project)

// 查询项目
const projects = await projectService.searchProjects('道路', {
  status: ProjectStatus.ACTIVE,
  startDate: new Date('2025-01-01'),
  endDate: new Date('2025-12-31')
})

// 分页查询
const pageResult = await projectService.getProjectsByPage({
  page: 1,
  pageSize: 20
})

// 更新项目状态
await projectService.updateProjectStatus(projectId, ProjectStatus.COMPLETED)
```

### 3.3 PhotoService 照片数据服务

#### 3.3.1 接口定义

```typescript
export class PhotoService {
  // CRUD操作
  async create(photo: Photo): Promise<string>
  async getById(id: string): Promise<Photo | null>
  async getByProjectId(projectId: string): Promise<Photo[]>
  async getBySiteId(siteId: string): Promise<Photo[]>
  async update(photo: Photo): Promise<boolean>
  async delete(id: string): Promise<boolean>
  async deleteByIds(ids: string[]): Promise<boolean>

  // 查询操作
  async searchPhotos(query: string, filters?: PhotoSearchFilters): Promise<Photo[]>
  async getPhotosByDateRange(startDate: Date, endDate: Date): Promise<Photo[]>
  async getPhotosByLocation(latitude: number, longitude: number, radius: number): Promise<Photo[]>
  async getPhotosByTag(tag: string): Promise<Photo[]>

  // 分页操作
  async getPhotosByPage(params: PhotoPaginationParams): Promise<PaginationResult<Photo>>

  // 业务操作
  async movePhotos(photoIds: string[], targetProjectId: string, targetSiteId?: string): Promise<boolean>
  async addPhotoTags(photoId: string, tags: string[]): Promise<boolean>
  async removePhotoTags(photoId: string, tags: string[]): Promise<boolean>
  async updatePhotoDescription(photoId: string, description: string): Promise<boolean>

  // 统计操作
  async getPhotoCount(projectId?: string, siteId?: string): Promise<number>
  async getPhotoStatistics(projectId?: string): Promise<PhotoStatistics>
}
```

---

## 4. 业务服务API

### 4.1 CameraService 相机服务

#### 4.1.1 接口定义

```typescript
export class CameraService {
  // 初始化
  async initialize(): Promise<boolean>
  async release(): Promise<void>

  // 相机控制
  async startPreview(surfaceId: string): Promise<boolean>
  async stopPreview(): Promise<void>
  async capturePhoto(config?: CaptureConfig): Promise<CaptureResult>
  async switchCamera(cameraId?: string): Promise<boolean>

  // 参数配置
  async setFlashMode(mode: FlashMode): Promise<boolean>
  async setFocusMode(mode: FocusMode): Promise<boolean>
  async setExposureCompensation(value: number): Promise<boolean>
  async setZoomRatio(ratio: number): Promise<boolean>

  // 状态查询
  async getSupportedCameras(): Promise<CameraDevice[]>
  async getCameraCapabilities(): Promise<CameraCapabilities>
  async getCurrentCameraState(): Promise<CameraState>

  // 事件监听
  onCameraStateChange(callback: (state: CameraState) => void): void
  onPreviewFrame(callback: (frame: PreviewFrame) => void): void
  onError(callback: (error: CameraError) => void): void
}
```

#### 4.1.2 使用示例

```typescript
const cameraService = new CameraService()

// 初始化相机
await cameraService.initialize()

// 开始预览
await cameraService.startPreview(surfaceId)

// 拍照
const captureConfig: CaptureConfig = {
  quality: 'high',
  flashMode: FlashMode.AUTO,
  saveToGallery: true
}
const result = await cameraService.capturePhoto(captureConfig)

if (result.success) {
  console.log(`照片已保存: ${result.filePath}`)
}
```

### 4.2 LocationService 定位服务

#### 4.2.1 接口定义

```typescript
export class LocationService {
  // 定位控制
  async startLocationUpdates(): Promise<boolean>
  async stopLocationUpdates(): Promise<void>
  async getCurrentLocation(): Promise<LocationInfo | null>

  // 地理编码
  async geocode(address: string): Promise<LocationInfo[]>
  async reverseGeocode(latitude: number, longitude: number): Promise<AddressInfo>

  // 状态查询
  async isLocationEnabled(): Promise<boolean>
  async getLocationAccuracy(): Promise<LocationAccuracy>

  // 事件监听
  onLocationChange(callback: (location: LocationInfo) => void): void
  onLocationError(callback: (error: LocationError) => void): void
}
```

### 4.3 WatermarkService 水印服务

#### 4.3.1 接口定义

```typescript
export class WatermarkService {
  // 模板管理
  async getTemplates(category?: string): Promise<WatermarkTemplate[]>
  async getTemplate(id: string): Promise<WatermarkTemplate | null>
  async saveTemplate(template: WatermarkTemplate): Promise<boolean>
  async deleteTemplate(id: string): Promise<boolean>

  // 水印生成
  async generateWatermark(photo: Photo, template: WatermarkTemplate): Promise<Buffer>
  async applyWatermark(photoPath: string, watermarkPath: string): Promise<string>
  async previewWatermark(photo: Photo, template: WatermarkTemplate): Promise<string>

  // 自动信息获取
  async getCurrentWeather(): Promise<WeatherInfo>
  async getCurrentAddress(latitude: number, longitude: number): Promise<string>
  async getDeviceOrientation(): Promise<OrientationInfo>

  // 样式配置
  async createCustomTemplate(config: CustomTemplateConfig): Promise<WatermarkTemplate>
  async updateTemplateStyle(templateId: string, style: WatermarkStyle): Promise<boolean>
}
```

---

## 5. Store状态管理API

### 5.1 BaseStore 基础Store

#### 5.1.1 接口定义

```typescript
@ObservedV2
export abstract class BaseStore<T> {
  @Trace protected items: T[] = []
  @Trace protected loading: boolean = false
  @Trace protected error: string = ''

  // 状态管理
  setLoading(loading: boolean): void
  setError(error: string): void
  clearError(): void

  // 数据管理
  setItems(items: T[]): void
  addItem(item: T): void
  updateItem(id: string, updates: Partial<T>): void
  removeItem(id: string): void
  clearItems(): void

  // 查询方法
  getItems(): T[]
  getItemById(id: string): T | null
  getLoading(): boolean
  getError(): string

  // 抽象方法
  abstract loadItems(): Promise<void>
  abstract saveItem(item: T): Promise<boolean>
  abstract deleteItem(id: string): Promise<boolean>
}
```

### 5.2 ProjectStore 项目状态管理

#### 5.2.1 接口定义

```typescript
@ObservedV2
export class ProjectStore extends BaseStore<Project> {
  @Trace currentProject: Project | null = null
  @Trace searchQuery: string = ''
  @Trace selectedStatus: ProjectStatus = ProjectStatus.ALL
  @Trace sortBy: ProjectSortBy = ProjectSortBy.CREATED_AT
  @Trace sortOrder: SortOrder = SortOrder.DESC

  // 项目操作
  async createProject(projectData: Partial<Project>): Promise<string>
  async updateProject(id: string, updates: Partial<Project>): Promise<boolean>
  async deleteProject(id: string): Promise<boolean>
  async duplicateProject(id: string): Promise<string>

  // 查询操作
  async loadProjects(): Promise<void>
  async searchProjects(query: string): Promise<void>
  async filterByStatus(status: ProjectStatus): Promise<void>
  async sortProjects(sortBy: ProjectSortBy, order: SortOrder): Promise<void>

  // 状态管理
  setCurrentProject(project: Project | null): void
  getCurrentProject(): Project | null

  // 计算属性
  get activeProjects(): Project[]
  get completedProjects(): Project[]
  get filteredProjects(): Project[]
  get projectStatistics(): ProjectStatistics
}
```

#### 5.2.2 使用示例

```typescript
const projectStore = new ProjectStore()

// 加载项目列表
await projectStore.loadProjects()

// 创建新项目
const projectId = await projectStore.createProject({
  name: '新工程项目',
  code: 'PRJ-NEW-001',
  client: '客户名称'
})

// 搜索项目
projectStore.setSearchQuery('道路')
await projectStore.searchProjects('道路')

// 设置当前项目
const project = projectStore.getItemById(projectId)
projectStore.setCurrentProject(project)

// 获取统计信息
const stats = projectStore.projectStatistics
console.log(`总项目数: ${stats.totalCount}`)
console.log(`进行中: ${stats.activeCount}`)
```

### 5.3 PhotoStore 照片状态管理

#### 5.3.1 接口定义

```typescript
@ObservedV2
export class PhotoStore extends BaseStore<Photo> {
  @Trace currentPhoto: Photo | null = null
  @Trace selectedPhotos: Photo[] = []
  @Trace currentProjectId: string = ''
  @Trace currentSiteId: string = ''
  @Trace viewMode: PhotoViewMode = PhotoViewMode.GRID
  @Trace sortBy: PhotoSortBy = PhotoSortBy.CAPTURE_TIME
  @Trace sortOrder: SortOrder = SortOrder.DESC

  // 照片操作
  async loadPhotos(projectId?: string, siteId?: string): Promise<void>
  async capturePhoto(config?: CaptureConfig): Promise<string>
  async deletePhoto(id: string): Promise<boolean>
  async deleteSelectedPhotos(): Promise<boolean>
  async movePhotos(photoIds: string[], targetProjectId: string, targetSiteId?: string): Promise<boolean>

  // 选择操作
  selectPhoto(photo: Photo): void
  deselectPhoto(photo: Photo): void
  selectAllPhotos(): void
  clearSelection(): void

  // 批量操作
  async addTagsToSelected(tags: string[]): Promise<boolean>
  async removeTagsFromSelected(tags: string[]): Promise<boolean>
  async setProjectForSelected(projectId: string): Promise<boolean>
  async setSiteForSelected(siteId: string): Promise<boolean>

  // 视图控制
  setViewMode(mode: PhotoViewMode): void
  setSorting(sortBy: PhotoSortBy, order: SortOrder): void

  // 计算属性
  get selectedCount(): number
  get filteredPhotos(): Photo[]
  get photoStatistics(): PhotoStatistics
}
```

---

## 6. 工具类API

### 6.1 Logger 日志工具

#### 6.1.1 接口定义

```typescript
export class Logger {
  static debug(tag: string, message: string, ...args: any[]): void
  static info(tag: string, message: string, ...args: any[]): void
  static warn(tag: string, message: string, ...args: any[]): void
  static error(tag: string, message: string, error?: Error, ...args: any[]): void

  static setLevel(level: LogLevel): void
  static getLevel(): LogLevel
  static enableFileLogging(enabled: boolean): void
  static async getLogs(): Promise<LogEntry[]>
  static async clearLogs(): Promise<void>
}
```

#### 6.1.2 使用示例

```typescript
// 基础日志
Logger.info('ProjectService', '创建项目成功', { projectId, name })
Logger.error('PhotoService', '照片保存失败', error, { photoId, path })

// 设置日志级别
Logger.setLevel(LogLevel.DEBUG)

// 启用文件日志
Logger.enableFileLogging(true)
```

### 6.2 PermissionUtils 权限工具

#### 6.2.1 接口定义

```typescript
export class PermissionUtils {
  // 权限检查
  static async checkPermission(permission: Permissions): Promise<boolean>
  static async checkPermissions(permissions: Permissions[]): Promise<PermissionResult[]>

  // 权限申请
  static async requestPermission(permission: Permissions): Promise<PermissionStatus>
  static async requestPermissions(permissions: Permissions[]): Promise<PermissionRequestResult>

  // 权限设置
  static async openPermissionSettings(): Promise<boolean>

  // 系统权限
  static async canUseCamera(): Promise<boolean>
  static async canUseLocation(): Promise<boolean>
  static async canUseStorage(): Promise<boolean>
  static async canUseMicrophone(): Promise<boolean>

  // 便捷方法
  static async requestCameraPermission(): Promise<boolean>
  static async requestLocationPermission(): Promise<boolean>
  static async requestStoragePermission(): Promise<boolean>
  static async requestAllPermissions(): Promise<boolean>
}
```

### 6.3 FileService 文件工具

#### 6.3.1 接口定义

```typescript
export class FileService {
  // 文件操作
  static async saveFile(data: ArrayBuffer | string, path: string): Promise<boolean>
  static async loadFile(path: string): Promise<ArrayBuffer | null>
  static async deleteFile(path: string): Promise<boolean>
  static async fileExists(path: string): Promise<boolean>
  static async getFileSize(path: string): Promise<number>

  // 目录操作
  static async createDirectory(path: string): Promise<boolean>
  static async deleteDirectory(path: string, recursive?: boolean): Promise<boolean>
  static async listFiles(path: string): Promise<FileInfo[]>
  static async copyFile(sourcePath: string, targetPath: string): Promise<boolean>
  static async moveFile(sourcePath: string, targetPath: string): Promise<boolean>

  // 路径操作
  static getAppDataDir(): string
  static getTempDir(): string
  static getCacheDir(): string
  static getPhotoDir(): string
  static getBackupDir(): string

  // 照片操作
  static async savePhoto(data: ArrayBuffer, filename: string): Promise<string>
  static async loadPhoto(path: string): Promise<ArrayBuffer | null>
  static async generateThumbnail(photoPath: string, maxSize?: number): Promise<string>
  static async compressPhoto(photoPath: string, quality: number): Promise<string>
}
```

---

## 7. 组件API

### 7.1 通用组件

#### 7.1.1 LoadingDialog 加载对话框

```typescript
interface LoadingDialogProps {
  show: boolean
  message?: string
  progress?: number
  cancellable?: boolean
  onCancel?: () => void
}

@Component
export struct LoadingDialog {
  @Prop show: boolean = false
  @Prop message: string = '加载中...'
  @Prop progress: number = -1
  @Prop cancellable: boolean = false
  onCancel?: () => void

  build() {
    // 组件实现
  }
}
```

#### 7.1.2 SearchBar 搜索栏

```typescript
interface SearchBarProps {
  placeholder?: string
  value?: string
  showClear?: boolean
  autoFocus?: boolean
  onSearch?: (query: string) => void
  onChange?: (query: string) => void
  onClear?: () => void
}

@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索...'
  @Prop value: string = ''
  @Prop showClear: boolean = true
  @Prop autoFocus: boolean = false
  onSearch?: (query: string) => void
  onChange?: (query: string) => void
  onClear?: () => void

  build() {
    // 组件实现
  }
}
```

### 7.2 照片组件

#### 7.2.1 PhotoGrid 照片网格

```typescript
interface PhotoGridProps {
  photos: Photo[]
  columns?: number
  spacing?: number
  aspectRatio?: number
  showSelection?: boolean
  selectedPhotos?: Photo[]
  onPhotoClick?: (photo: Photo) => void
  onPhotoLongPress?: (photo: Photo) => void
  onLoadMore?: () => void
  loading?: boolean
}

@Component
export struct PhotoGrid {
  @Prop photos: Photo[] = []
  @Prop columns: number = 3
  @Prop spacing: number = 8
  @Prop aspectRatio: number = 1
  @Prop showSelection: boolean = false
  @Prop selectedPhotos: Photo[] = []
  onPhotoClick?: (photo: Photo) => void
  onPhotoLongPress?: (photo: Photo) => void
  onLoadMore?: () => void
  @Prop loading: boolean = false

  build() {
    // 组件实现
  }
}
```

#### 7.2.2 PhotoViewer 照片查看器

```typescript
interface PhotoViewerProps {
  photo: Photo
  show: boolean
  showInfo?: boolean
  showControls?: boolean
  allowEdit?: boolean
  allowShare?: boolean
  onClose?: () => void
  onEdit?: (photo: Photo) => void
  onShare?: (photo: Photo) => void
}

@Component
export struct PhotoViewer {
  @Prop photo: Photo
  @Prop show: boolean = false
  @Prop showInfo: boolean = true
  @Prop showControls: boolean = true
  @Prop allowEdit: boolean = true
  @Prop allowShare: boolean = true
  onClose?: () => void
  onEdit?: (photo: Photo) => void
  onShare?: (photo: Photo) => void

  build() {
    // 组件实现
  }
}
```

---

## 8. 错误处理

### 8.1 错误类型定义

```typescript
// 基础错误类
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public cause?: Error
  ) {
    super(message)
    this.name = 'AppError'
  }
}

// 数据库错误
export class DatabaseError extends AppError {
  constructor(message: string, code: string, cause?: Error) {
    super(message, code, cause)
    this.name = 'DatabaseError'
  }
}

// 网络错误
export class NetworkError extends AppError {
  constructor(message: string, code: string, cause?: Error) {
    super(message, code, cause)
    this.name = 'NetworkError'
  }
}

// 权限错误
export class PermissionError extends AppError {
  constructor(message: string, code: string, cause?: Error) {
    super(message, code, cause)
    this.name = 'PermissionError'
  }
}

// 验证错误
export class ValidationError extends AppError {
  constructor(message: string, code: string, public field?: string) {
    super(message, code)
    this.name = 'ValidationError'
  }
}
```

### 8.2 错误码定义

```typescript
export enum ERROR_CODES {
  // 通用错误
  UNKNOWN_ERROR = 'UNKNOWN_ERROR',
  INVALID_PARAMETER = 'INVALID_PARAMETER',
  OPERATION_FAILED = 'OPERATION_FAILED',

  // 数据库错误
  DATABASE_NOT_FOUND = 'DATABASE_NOT_FOUND',
  CONNECTION_FAILED = 'CONNECTION_FAILED',
  TRANSACTION_FAILED = 'TRANSACTION_FAILED',
  QUERY_FAILED = 'QUERY_FAILED',

  // 权限错误
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  PERMISSION_NOT_GRANTED = 'PERMISSION_NOT_GRANTED',

  // 文件错误
  FILE_NOT_FOUND = 'FILE_NOT_FOUND',
  FILE_ACCESS_DENIED = 'FILE_ACCESS_DENIED',
  STORAGE_FULL = 'STORAGE_FULL',

  // 网络错误
  NETWORK_UNAVAILABLE = 'NETWORK_UNAVAILABLE',
  NETWORK_TIMEOUT = 'NETWORK_TIMEOUT',

  // 业务错误
  PROJECT_NOT_FOUND = 'PROJECT_NOT_FOUND',
  SITE_NOT_FOUND = 'SITE_NOT_FOUND',
  PHOTO_NOT_FOUND = 'PHOTO_NOT_FOUND',
  DUPLICATE_NAME = 'DUPLICATE_NAME'
}
```

### 8.3 错误处理示例

```typescript
// 使用try-catch处理错误
try {
  const projectId = await projectService.createProject(projectData)
  Logger.info('ProjectService', '项目创建成功', { projectId })
} catch (error) {
  if (error instanceof DatabaseError) {
    Logger.error('ProjectService', '数据库错误', error)
    // 显示错误提示给用户
    showToast('数据库操作失败，请重试')
  } else if (error instanceof ValidationError) {
    Logger.warn('ProjectService', '验证错误', error)
    // 高亮错误的字段
    highlightField(error.field)
  } else {
    Logger.error('ProjectService', '未知错误', error)
    showToast('操作失败，请联系技术支持')
  }
}

// 统一错误处理中间件
export class ErrorHandler {
  static handle(error: Error): void {
    if (error instanceof AppError) {
      this.handleAppError(error)
    } else {
      this.handleUnknownError(error)
    }
  }

  private static handleAppError(error: AppError): void {
    Logger.error('ErrorHandler', error.message, error)

    switch (error.code) {
      case ERROR_CODES.PERMISSION_DENIED:
        this.showPermissionError(error.message)
        break
      case ERROR_CODES.NETWORK_UNAVAILABLE:
        this.showNetworkError(error.message)
        break
      case ERROR_CODES.STORAGE_FULL:
        this.showStorageError(error.message)
        break
      default:
        this.showGenericError(error.message)
    }
  }

  private static handleUnknownError(error: Error): void {
    Logger.error('ErrorHandler', '未知错误', error)
    this.showGenericError('发生了未知错误，请重试')
  }
}
```

---

## 9. 使用示例

### 9.1 完整的项目创建流程

```typescript
async function createNewProject() {
  try {
    // 1. 检查权限
    const hasPermission = await PermissionUtils.requestStoragePermission()
    if (!hasPermission) {
      throw new PermissionError('需要存储权限', ERROR_CODES.PERMISSION_DENIED)
    }

    // 2. 创建项目数据
    const project = new Project()
    project.name = '城市道路改造工程'
    project.code = 'PRJ-2025-001'
    project.client = '市政建设局'
    project.manager = '张工'
    project.startDate = new Date('2025-01-01')
    project.endDate = new Date('2025-12-31')
    project.description = '城市主干道改造及配套设施建设工程'

    // 3. 验证数据
    if (!project.isValid()) {
      throw new ValidationError('项目数据无效', ERROR_CODES.INVALID_PARAMETER)
    }

    // 4. 保存到数据库
    const projectService = new ProjectService()
    const projectId = await projectService.create(project)

    // 5. 更新UI状态
    const projectStore = new ProjectStore()
    await projectStore.loadProjects()
    projectStore.setCurrentProject(project)

    // 6. 记录日志
    Logger.info('ProjectService', '项目创建成功', {
      projectId,
      projectName: project.name
    })

    // 7. 显示成功提示
    showToast('项目创建成功')

    return projectId

  } catch (error) {
    ErrorHandler.handle(error)
    throw error
  }
}
```

### 9.2 照片拍摄和处理流程

```typescript
async function capturePhotoWithWatermark() {
  try {
    // 1. 检查相机权限
    const hasCameraPermission = await PermissionUtils.requestCameraPermission()
    if (!hasCameraPermission) {
      throw new PermissionError('需要相机权限', ERROR_CODES.PERMISSION_DENIED)
    }

    // 2. 检查位置权限
    const hasLocationPermission = await PermissionUtils.requestLocationPermission()

    // 3. 初始化相机
    const cameraService = new CameraService()
    await cameraService.initialize()

    // 4. 获取当前位置
    let locationInfo: LocationInfo | null = null
    if (hasLocationPermission) {
      const locationService = new LocationService()
      locationInfo = await locationService.getCurrentLocation()
    }

    // 5. 配置拍照参数
    const captureConfig: CaptureConfig = {
      quality: 'high',
      flashMode: FlashMode.AUTO,
      saveToGallery: false
    }

    // 6. 拍摄照片
    const captureResult = await cameraService.capturePhoto(captureConfig)
    if (!captureResult.success) {
      throw new AppError('拍照失败', ERROR_CODES.OPERATION_FAILED)
    }

    // 7. 获取天气信息
    const watermarkService = new WatermarkService()
    const weatherInfo = await watermarkService.getCurrentWeather()

    // 8. 创建照片记录
    const photo = new Photo()
    photo.projectId = getCurrentProjectId()
    photo.siteId = getCurrentSiteId()
    photo.filepath = captureResult.filePath!
    photo.captureTime = new Date()
    photo.width = captureResult.width!
    photo.height = captureResult.height!
    photo.fileSize = captureResult.fileSize!
    photo.photographer = getCurrentUser().name

    // 9. 设置位置信息
    if (locationInfo) {
      photo.latitude = locationInfo.latitude
      photo.longitude = locationInfo.longitude
      photo.altitude = locationInfo.altitude || 0
      photo.address = await watermarkService.getCurrentAddress(
        locationInfo.latitude,
        locationInfo.longitude
      )
    }

    // 10. 设置天气信息
    if (weatherInfo) {
      photo.weather = `${weatherInfo.weather} ${weatherInfo.temperature}°C`
    }

    // 11. 应用水印
    const watermarkTemplate = await watermarkService.getTemplate('default-engineering')
    const watermarkedPhotoPath = await watermarkService.applyWatermark(
      photo.filepath,
      watermarkTemplate
    )

    // 12. 保存照片记录
    const photoService = new PhotoService()
    const photoId = await photoService.create(photo)

    // 13. 更新UI状态
    const photoStore = new PhotoStore()
    await photoStore.loadPhotos(photo.projectId, photo.siteId)

    // 14. 释放相机资源
    await cameraService.release()

    Logger.info('PhotoService', '照片拍摄成功', {
      photoId,
      filePath: watermarkedPhotoPath
    })

    showToast('照片拍摄成功')

    return photoId

  } catch (error) {
    ErrorHandler.handle(error)
    throw error
  }
}
```

---

## 10. API变更日志

### v1.0.0 (2025-10-22)

#### 新增功能
- 完整的数据模型API (BaseModel, Project, Site, Photo, WatermarkTemplate)
- 数据库服务API (DatabaseService, ProjectService, PhotoService, SiteService, UserService)
- 业务服务API (CameraService, LocationService, WatermarkService)
- Store状态管理API (BaseStore, ProjectStore, PhotoStore, GalleryStore)
- 工具类API (Logger, PermissionUtils, FileService, CacheService, BackupService)
- 通用组件API (LoadingDialog, ConfirmDialog, SearchBar, EmptyView)
- 照片组件API (PhotoGrid, PhotoItem, PhotoViewer)
- 水印组件API (WatermarkPreview, WatermarkTemplate, WatermarkEditor)
- 编辑组件API (DoodleCanvas, TextAnnotation, ShapeAnnotation)

#### 技术特性
- 基于HarmonyOS NEXT和ArkTS开发
- 使用V2响应式状态管理 (@ObservedV2 + @Trace)
- 支持单例模式和依赖注入
- 完整的错误处理机制
- 统一的日志记录系统
- 类型安全的API设计

#### 规范说明
- 遵循HarmonyOS开发规范
- 使用TypeScript强类型约束
- 采用MVVM架构模式
- 支持组件化开发
- 完整的API文档和示例

---

## 🔗 相关文档

- [用户使用手册](./user-manual.md)
- [功能说明文档](./features.md)
- [常见问题解答](./faq.md)
- [应用商店描述](./app-store-description.md)
- [部署指南](./deployment-guide.md)
- [维护手册](./maintenance-manual.md)

---

## 📞 技术支持

如果您在使用API时遇到问题，可以通过以下方式获取帮助：

- **技术文档**: [docs.engineeringcamera.com](https://docs.engineeringcamera.com)
- **API参考**: [api.engineeringcamera.com](https://api.engineeringcamera.com)
- **开发者社区**: [dev.engineeringcamera.com](https://dev.engineeringcamera.com)
- **技术支持邮箱**: dev-support@engineeringcamera.com

---

*API文档最后更新: 2025年10月22日*