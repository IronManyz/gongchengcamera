---
title: Architecture Guide
description: "EngineeringCamera项目架构指导：系统架构设计、模块划分、数据流设计和技术选型说明"
inclusion: always
---

# 工程相机 (Engineering Camera) 架构指南

## 概述

EngineeringCamera采用分层架构设计，基于HarmonyOS NEXT平台，使用ArkTS开发语言和V2响应式状态管理。本架构确保应用的高性能、可扩展性和可维护性。

**核心原则：离线优先、本地存储、响应式驱动、模块化设计**

## 1. 整体架构设计

### 1.1 架构分层

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (表现层)                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Pages         │  │   Components    │  │   Resources  │ │
│  │   (页面组件)     │  │   (可复用组件)   │  │   (资源文件)   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  State Layer (状态层)                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   V2 Stores     │  │   Models        │  │   Utils      │ │
│  │   (响应式状态)   │  │   (数据模型)     │  │   (工具函数)   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                Service Layer (业务层)                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Business      │  │   Storage       │  │   Device     │ │
│  │   (业务服务)     │  │   (存储服务)     │  │   (设备服务)   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Data Layer (数据层)                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   RDB Store     │  │   File System   │  │   Preferences│ │
│  │   (关系数据库)   │  │   (文件存储)     │  │   (配置存储)   │ │
│  └─────────────────┘  └─────���───────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 技术架构

```typescript
// 技术栈架构
├── Platform (平台层)
│   ├── HarmonyOS NEXT
│   ├── ArkTS (开发语言)
│   └── ArkUI (UI框架)
├── State Management (状态管理层)
│   ├── V2 Reactive (@ObservedV2, @Trace, @Local, @Param, @Monitor)
│   ├── Component State (@State, @Prop, @Link)
│   └── Global State (@Provide/@Consume)
├── Data Storage (数据存储层)
│   ├── RDB Store (关系型数据库)
│   ├── File System (文件系统)
│   └── Preferences (键值对存储)
├── Device APIs (设备API层)
│   ├── Camera (相机)
│   ├── Location (定位)
│   ├── Network (网络)
│   └── File IO (文件操作)
└── Build System (构建系统)
    ├── Hvigor (构建工具)
    ├── ohpm (包管理)
    └── DevEco Studio (IDE)
```

## 2. 模块架构设计

### 2.1 目录结构

```
entry/src/main/ets/
├── app.ets                          # 应用入口
├── entryability/                    # 应用能力
│   └── EntryAbility.ets
├── entrybackupability/              # 备份能力
│   └── EntryBackupAbility.ets
├── pages/                           # 页面组件
│   ├── Index.ets                    # 首页
│   ├── project/                     # 项目管理页面
│   │   ├── ProjectListPage.ets
│   │   ├── ProjectDetailPage.ets
│   │   └── ProjectEditPage.ets
│   ├── camera/                      # 相机页面
│   │   ├── CameraPage.ets
│   │   ├── CameraSettingsPage.ets
│   │   └── WatermarkEditPage.ets
│   ├── gallery/                     # 相册页面
│   │   ├── GalleryPage.ets
│   │   ├── PhotoPreviewPage.ets
│   │   └── PhotoEditPage.ets
│   └── settings/                    # 设置页面
│       ├── SettingsPage.ets
│       ├── DatabaseManagePage.ets
│       └── TeamManagePage.ets
├── components/                      # 可复用组件
│   ├── common/                      # 通用组件
│   │   ├── LoadingComponent.ets
│   │   ├── EmptyComponent.ets
│   │   └── ErrorComponent.ets
│   ├── photo/                       # 照片相关组件
│   │   ├── PhotoCard.ets
│   │   ├── PhotoGrid.ets
│   │   └── PhotoList.ets
│   ├── watermark/                   # 水印组件
│   │   ├── WatermarkPreview.ets
│   │   └── WatermarkTemplate.ets
│   └── forms/                       # 表单组件
│       ├── ProjectForm.ets
│       └── SearchBar.ets
├── stores/                          # V2状态管理
│   ├── app/                         # 应用级状态
│   │   ├── AppStore.ets
│   │   ├── ThemeStore.ets
│   │   └── UserStore.ets
│   ├── project/                     # 项目相关状态
│   │   ├── ProjectStore.ets
│   │   └── SiteStore.ets
│   ├── photo/                       # 照片相关状态
│   │   ├── PhotoStore.ets
│   │   ├── GalleryStore.ets
│   │   └── CameraStore.ets
│   └── settings/                    # 设置相关状态
│       ├── SettingsStore.ets
│       └── DatabaseStore.ets
├── models/                          # 数据模型
│   ├── ProjectModel.ets
│   ├── SiteModel.ets
│   ├── PhotoModel.ets
│   ├── WatermarkModel.ets
│   ├── UserModel.ets
│   └── BaseModel.ets
├── services/                        # 业务服务
│   ├── database/                    # 数据库服务
│   │   ├── DatabaseService.ets
│   │   ├── ProjectRepository.ets
│   │   ├── PhotoRepository.ets
│   │   └── UserRepository.ets
│   ├── storage/                     # 存储服务
│   │   ├── FileStorageService.ets
│   │   ├── PhotoStorageService.ets
│   │   └── BackupService.ets
│   ├── device/                      # 设备服务
│   │   ├── CameraService.ets
│   │   ├── LocationService.ets
│   │   ├── WeatherService.ets
│   │   └── PermissionService.ets
│   ├── business/                    # 业务服务
│   │   ├── ProjectService.ets
│   │   ├── PhotoService.ets
│   │   ├── WatermarkService.ets
│   │   └── ExportService.ets
│   └── network/                     # 网络服务
│       ├── CloudSyncService.ets
│       ├── TeamService.ets
│       └── WeatherApiService.ets
├── utils/                           # 工具函数
│   ├── DateUtils.ets
│   ├── GeoUtils.ets
│   ├── FileUtils.ets
│   ├── ImageUtils.ets
│   ├── ValidationUtils.ets
│   └── Constants.ets
└── constants/                       # 常量定义
    ├── AppConstants.ets
    ├── DatabaseConstants.ets
    ├── ApiConstants.ets
    ��── UIConstants.ets
```

### 2.2 核心模块设计

#### AppStore (应用级状态管理)
```typescript
@ObservedV2
export class AppStore {
  // 应用主题
  @Track theme: 'light' | 'dark' | 'system' = 'system'

  // 用户信息
  @Track currentUser: UserModel | null = null

  // 应用状态
  @Track isLoading: boolean = false
  @Track networkStatus: 'online' | 'offline' = 'online'

  // 权限状态
  @Track permissions: Record<string, boolean> = {
    camera: false,
    location: false,
    storage: false
  }

  constructor() {
    this.initializeApp()
  }

  private async initializeApp() {
    await this.checkPermissions()
    await this.loadUserPreferences()
    this.setupNetworkListener()
  }

  // 主题管理
  @Monitor('theme')
  onThemeChange() {
    ThemeService.applyTheme(this.theme)
  }

  // 网络状态监控
  private setupNetworkListener() {
    // 监听网络状态变化
  }

  // 权限检查
  async checkPermissions() {
    this.permissions.camera = await PermissionChecker.checkCamera()
    this.permissions.location = await PermissionChecker.checkLocation()
    this.permissions.storage = await PermissionChecker.checkStorage()
  }
}
```

#### ProjectStore (项目管理状态)
```typescript
@ObservedV2
export class ProjectStore {
  @Track currentProject: ProjectModel | null = null
  @Track projects: ProjectModel[] = []
  @Track sites: SiteModel[] = []
  @Track isLoading: boolean = false
  @Track error: string | null = null

  constructor() {
    this.loadProjects()
  }

  async loadProjects() {
    this.isLoading = true
    this.error = null

    try {
      this.projects = await ProjectService.getAllProjects()
    } catch (error) {
      this.error = '加载项目失败'
      hilog.error(0x0000, 'ProjectStore', 'Load projects failed: %{public}s', error)
    } finally {
      this.isLoading = false
    }
  }

  async createProject(projectData: Partial<ProjectModel>) {
    const project = await ProjectService.createProject(projectData)
    this.projects.unshift(project)
    return project
  }

  async selectProject(projectId: string) {
    const project = this.projects.find(p => p.id === projectId)
    if (project) {
      this.currentProject = project
      await this.loadSites(project.id)
    }
  }

  private async loadSites(projectId: string) {
    this.sites = await SiteService.getSitesByProject(projectId)
  }
}
```

## 3. 数据流架构

### 3.1 单向数据流设计

```
User Action → Service → Repository → Database → Store → UI Update
     ↑                                                           ↓
     └───────────────────── Event/Callback ←─────────────────────┘
```

### 3.2 数据流示例 (拍照流程)

```typescript
// 1. 用户点击拍照按钮
CameraPage.onTakePhoto()
  ↓
// 2. 调用相机服务
CameraService.capturePhoto()
  ↓
// 3. 获取位置和设备信息
LocationService.getCurrentLocation()
WeatherService.getCurrentWeather()
  ↓
// 4. 保存照片文件
FileStorageService.savePhotoFile()
  ↓
// 5. 保存到数据库
PhotoRepository.create(photoData)
  ↓
// 6. 更新状态管理
PhotoStore.addPhoto(photo)
  ↓
// 7. UI自动更新
GalleryPage.refresh()
```

### 3.3 V2响应式数据流

```typescript
// 深度嵌套的响应式数据
@ObservedV2
class PhotoMetadata {
  @Track location: LocationInfo = new LocationInfo()
  @Track weather: WeatherInfo = new WeatherInfo()
  @Track device: DeviceInfo = new DeviceInfo()
}

@ObservedV2
class PhotoModel {
  @Track id: string = ''
  @Track filePath: string = ''
  @Track metadata: PhotoMetadata = new PhotoMetadata()
}

@ObservedV2
class PhotoStore {
  @Track photos: PhotoModel[] = []
  @Track selectedPhoto: PhotoModel | null = null
}

// 任意深度的属性变化都会触发UI更新
@Component
struct PhotoCard {
  @ObjectLink photo: PhotoModel

  build() {
    Column() {
      Text(this.photo.metadata.location.address)  // 位置变化会自动更新
      Text(this.photo.metadata.weather.temperature)  // 天气变化会自动更新
    }
  }
}
```

## 4. 数据库架构

### 4.1 数据库设计

```sql
-- 项目表
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT,
  client TEXT,
  manager TEXT,
  start_date INTEGER,
  end_date INTEGER,
  metadata TEXT,  -- JSON格式
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 工点表
CREATE TABLE sites (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  address TEXT,
  latitude REAL,
  longitude REAL,
  altitude REAL,
  tags TEXT,  -- JSON数组
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- 照片表
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  site_id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  file_path TEXT NOT NULL,
  taken_at INTEGER NOT NULL,
  latitude REAL,
  longitude REAL,
  altitude REAL,
  azimuth REAL,
  address TEXT,
  weather TEXT,
  watermark_template_id TEXT,
  notes TEXT,
  tags TEXT,  -- JSON数组
  status TEXT DEFAULT 'normal',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (site_id) REFERENCES sites(id),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- 水印模板表
CREATE TABLE watermark_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  fields TEXT NOT NULL,  -- JSON格式
  style TEXT NOT NULL,   -- JSON格式
  is_default INTEGER DEFAULT 0,
  created_by TEXT,
  created_at INTEGER NOT NULL
);

-- 团队成员表
CREATE TABLE team_members (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  role TEXT NOT NULL,  -- owner, editor, viewer
  joined_at INTEGER NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- 备份记录表
CREATE TABLE backups (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,  -- local, cloud
  path TEXT,
  file_size INTEGER,
  status TEXT DEFAULT 'pending',  -- pending, success, failed
  created_at INTEGER NOT NULL
);
```

### 4.2 数据访问层设计

```typescript
// 基础Repository接口
interface IRepository<T> {
  create(data: Partial<T>): Promise<T>
  getById(id: string): Promise<T | null>
  update(id: string, data: Partial<T>): Promise<T>
  delete(id: string): Promise<boolean>
  query(filter?: Partial<T>): Promise<T[]>
  count(filter?: Partial<T>): Promise<number>
}

// 照片Repository实现
export class PhotoRepository implements IRepository<PhotoModel> {
  private static readonly TABLE_NAME = 'photos'

  async create(data: Partial<PhotoModel>): Promise<PhotoModel> {
    const photo = new PhotoModel(data)
    photo.id = this.generateId()
    photo.createdAt = Date.now()
    photo.updatedAt = Date.now()

    const values = relationalStore.createValueBucket(photo)
    await DatabaseService.insert(PhotoRepository.TABLE_NAME, values)

    return photo
  }

  async getById(id: string): Promise<PhotoModel | null> {
    const result = await DatabaseService.query(PhotoRepository.TABLE_NAME, { id })
    return result.length > 0 ? new PhotoModel(result[0]) : null
  }

  async getByProject(projectId: string): Promise<PhotoModel[]> {
    const results = await DatabaseService.query(
      PhotoRepository.TABLE_NAME,
      { project_id: projectId }
    )
    return results.map(item => new PhotoModel(item))
  }

  async update(id: string, data: Partial<PhotoModel>): Promise<PhotoModel> {
    const existing = await this.getById(id)
    if (!existing) {
      throw new Error('Photo not found')
    }

    const updated = { ...existing, ...data, updatedAt: Date.now() }
    const values = relationalStore.createValueBucket(updated)
    await DatabaseService.update(PhotoRepository.TABLE_NAME, values, { id })

    return new PhotoModel(updated)
  }

  // 事务操作示例
  async createWithTransaction(photoData: Partial<PhotoModel>, tags: string[]): Promise<PhotoModel> {
    return await DatabaseService.transaction(async () => {
      const photo = await this.create(photoData)

      // 创建标签关联
      for (const tag of tags) {
        await PhotoTagRepository.create({ photoId: photo.id, tag })
      }

      return photo
    })
  }
}
```

## 5. 组件架构模式

### 5.1 容器-展示组件模式

```typescript
// 容器组件：处理业务逻辑和状态
@Entry
@Component
struct GalleryPage {
  @Consumer('photoStore') photoStore: PhotoStore
  @Consumer('projectStore') projectStore: ProjectStore
  @State selectedPhotos: string[] = []

  aboutToAppear() {
    this.loadPhotos()
  }

  private async loadPhotos() {
    if (this.photoStore.currentProject) {
      await this.photoStore.loadPhotos(this.photoStore.currentProject.id)
    }
  }

  private onPhotoSelect(photoId: string) {
    // 处理照片选择逻辑
  }

  private onPhotoEdit(photo: PhotoModel) {
    router.pushUrl({
      url: 'pages/PhotoEditPage',
      params: { photoId: photo.id }
    })
  }

  build() {
    Column() {
      // 状态指示器
      if (this.photoStore.isLoading) {
        LoadingComponent()
      } else {
        // 展示组件：纯UI渲染
        PhotoGallery({
          photos: this.photoStore.photos,
          selectedPhotos: this.selectedPhotos,
          onPhotoSelect: this.onPhotoSelect.bind(this),
          onPhotoEdit: this.onPhotoEdit.bind(this)
        })
      }
    }
  }
}

// 展示组件：纯UI，无业务逻辑
@Component
struct PhotoGallery {
  @Prop photos: PhotoModel[]
  @Prop selectedPhotos: string[]
  @Prop onPhotoSelect: (photoId: string) => void
  @Prop onPhotoEdit: (photo: PhotoModel) => void

  build() {
    Grid() {
      ForEach(this.photos, (photo: PhotoModel) => {
        GridItem() {
          PhotoCard({
            photo: photo,
            isSelected: this.selectedPhotos.includes(photo.id),
            onSelect: () => this.onPhotoSelect(photo.id),
            onEdit: () => this.onPhotoEdit(photo)
          })
        }
      }, (photo: PhotoModel) => photo.id)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .padding(16)
  }
}
```

### 5.2 状态提升模式

```typescript
// 父组件管理状态
@Entry
@Component
struct PhotoEditPage {
  @State currentPhoto: PhotoModel = new PhotoModel()
  @State editMode: 'view' | 'edit' = 'view'
  @State hasUnsavedChanges: boolean = false

  aboutToAppear() {
    const params = router.getParams() as { photoId: string }
    this.loadPhoto(params.photoId)
  }

  private async loadPhoto(photoId: string) {
    this.currentPhoto = await PhotoService.getPhotoById(photoId)
  }

  private onPhotoUpdate(updatedPhoto: PhotoModel) {
    this.currentPhoto = updatedPhoto
    this.hasUnsavedChanges = true
  }

  private async onSave() {
    await PhotoService.updatePhoto(this.currentPhoto.id, this.currentPhoto)
    this.hasUnsavedChanges = false
    this.editMode = 'view'
  }

  build() {
    Column() {
      // 工具栏
      PhotoEditToolbar({
        editMode: this.editMode,
        hasUnsavedChanges: this.hasUnsavedChanges,
        onEdit: () => this.editMode = 'edit',
        onSave: this.onSave.bind(this),
        onCancel: () => router.back()
      })

      // 编辑器
      PhotoEditor({
        photo: this.currentPhoto,
        editMode: this.editMode,
        onPhotoUpdate: this.onPhotoUpdate.bind(this)
      })
    }
  }
}

// 子组件通过回调与父组件通信
@Component
struct PhotoEditor {
  @Prop photo: PhotoModel
  @Prop editMode: 'view' | 'edit'
  @Prop onPhotoUpdate: (photo: PhotoModel) => void

  build() {
    if (this.editMode === 'edit') {
      PhotoEditCanvas({
        photo: this.photo,
        onPhotoUpdate: this.onPhotoUpdate
      })
    } else {
      PhotoViewCanvas({
        photo: this.photo
      })
    }
  }
}
```

## 6. 性能优化架构

### 6.1 列表渲染优化

```typescript
// 使用LazyForEach进行虚拟化渲染
@Entry
@Component
struct PhotoGalleryPage {
  @State dataSource: PhotoDataSource = new PhotoDataSource()

  build() {
    List() {
      LazyForEach(
        this.dataSource,
        (photo: PhotoModel, index: number) => {
          ListItem() {
            PhotoListItem({ photo: photo, index: index })
          }
          .height(200)
        },
        (photo: PhotoModel) => photo.id  // 稳定的key
      )
    }
    .cachedCount(10)  // 预渲染缓存
    .listDirection(Axis.Vertical)
    .scrollBar(BarState.Off)
  }
}

// 数据源实现
class PhotoDataSource implements IDataSource {
  private photos: PhotoModel[] = []
  private listeners: DataChangeListener[] = []

  constructor() {
    this.loadData()
  }

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

  async loadData() {
    // 分页加载数据
    const photos = await PhotoService.getPhotos(0, 50)
    this.photos = photos
    this.notifyDataReload()
  }

  private notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }
}
```

### 6.2 图片加载优化

```typescript
// 图片缓存和异步加载
export class ImageLoader {
  private static cache = new Map<string, image.PixelMap>()
  private static loading = new Map<string, Promise<image.PixelMap>>()

  static async loadImage(path: string): Promise<image.PixelMap> {
    // 缓存命中
    if (ImageLoader.cache.has(path)) {
      return ImageLoader.cache.get(path)!
    }

    // 正在加载中，返回相同的Promise
    if (ImageLoader.loading.has(path)) {
      return ImageLoader.loading.get(path)!
    }

    // 开始加载
    const loadingPromise = ImageLoader.loadFromFile(path)
    ImageLoader.loading.set(path, loadingPromise)

    try {
      const pixelMap = await loadingPromise
      ImageLoader.cache.set(path, pixelMap)
      return pixelMap
    } finally {
      ImageLoader.loading.delete(path)
    }
  }

  private static async loadFromFile(path: string): Promise<image.PixelMap> {
    // 文件读取和图片解码
  }

  static clearCache() {
    ImageLoader.cache.forEach(pixelMap => {
      pixelMap.release()
    })
    ImageLoader.cache.clear()
  }
}

// 组件中使用
@Component
struct PhotoImage {
  @Prop imagePath: string
  @State pixelMap: image.PixelMap | null = null

  aboutToAppear() {
    this.loadImage()
  }

  aboutToDisappear() {
    if (this.pixelMap) {
      this.pixelMap.release()
    }
  }

  private async loadImage() {
    this.pixelMap = await ImageLoader.loadImage(this.imagePath)
  }

  build() {
    if (this.pixelMap) {
      Image(this.pixelMap)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    } else {
      // 加载占位符
      Image($r('app.media.image_placeholder'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
  }
}
```

## 7. 安全架构

### 7.1 数据安全设计

```typescript
// 数据加密服务
export class EncryptionService {
  private static readonly ALGORITHM = 'AES256'
  private static readonly KEY_ALIAS = 'engineering_camera_key'

  static async encryptData(data: string): Promise<string> {
    const key = await this.getEncryptionKey()
    return await crypto.encrypt(data, key, EncryptionService.ALGORITHM)
  }

  static async decryptData(encryptedData: string): Promise<string> {
    const key = await this.getEncryptionKey()
    return await crypto.decrypt(encryptedData, key, EncryptionService.ALGORITHM)
  }

  private static async getEncryptionKey(): Promise<Uint8Array> {
    // 从密钥库获取或生成密钥
  }
}

// 权限管理
export class PermissionManager {
  private static readonly REQUIRED_PERMISSIONS = [
    'ohos.permission.CAMERA',
    'ohos.permission.LOCATION',
    'ohos.permission.READ_WRITE_MEDIA'
  ]

  static async requestAllPermissions(): Promise<boolean> {
    for (const permission of PermissionManager.REQUIRED_PERMISSIONS) {
      const granted = await PermissionManager.requestPermission(permission)
      if (!granted) {
        return false
      }
    }
    return true
  }

  static async requestPermission(permission: string): Promise<boolean> {
    try {
      const status = await bundleManager.requestPermissionFromUser(
        getContext(), [permission]
      )
      return status.grantedStatus[0] === bundleManager.GrantStatus.PERMISSION_GRANTED
    } catch (error) {
      hilog.error(0x0000, 'PermissionManager', 'Permission request failed: %{public}s', error)
      return false
    }
  }
}
```

### 7.2 文件安全

```typescript
// 安全文件存储
export class SecureFileStorage {
  private static readonly BASE_PATH = '/data/storage/el2/base/haps/entry/files'

  static async savePhotoSecurely(photoData: ArrayBuffer, fileName: string): Promise<string> {
    // 生成安全的文件名
    const safeFileName = this.generateSafeFileName(fileName)
    const filePath = `${SecureFileStorage.BASE_PATH}/photos/${safeFileName}`

    try {
      // 确保目录存在
      await fs.mkdir(`${SecureFileStorage.BASE_PATH}/photos`, true)

      // 写入文件
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      await fs.write(file.fd, photoData)
      await fs.close(file.fd)

      // 设置文件权限
      await this.setFilePermissions(filePath)

      return filePath
    } catch (error) {
      hilog.error(0x0000, 'SecureFileStorage', 'Failed to save photo: %{public}s', error)
      throw new Error('Photo save failed')
    }
  }

  private static generateSafeFileName(originalName: string): string {
    const timestamp = Date.now()
    const random = Math.random().toString(36).substring(2, 15)
    const extension = originalName.split('.').pop() || 'jpg'
    return `${timestamp}_${random}.${extension}`
  }

  private static async setFilePermissions(filePath: string) {
    // 设置文件权限，只有应用可以访问
  }
}
```

## 8. 扩展性架构

### 8.1 插件化设计

```typescript
// 插件接口定义
interface IWatermarkPlugin {
  name: string
  version: string
  render(metadata: PhotoMetadata, style: WatermarkStyle): Promise<image.PixelMap>
}

// 插件管理器
export class PluginManager {
  private static plugins = new Map<string, IWatermarkPlugin>()

  static registerPlugin(plugin: IWatermarkPlugin) {
    PluginManager.plugins.set(plugin.name, plugin)
  }

  static getPlugin(name: string): IWatermarkPlugin | null {
    return PluginManager.plugins.get(name) || null
  }

  static async renderWatermark(
    pluginName: string,
    metadata: PhotoMetadata,
    style: WatermarkStyle
  ): Promise<image.PixelMap> {
    const plugin = PluginManager.getPlugin(pluginName)
    if (!plugin) {
      throw new Error(`Plugin not found: ${pluginName}`)
    }

    return await plugin.render(metadata, style)
  }
}

// 示例插件实现
class StandardWatermarkPlugin implements IWatermarkPlugin {
  name = 'standard_watermark'
  version = '1.0.0'

  async render(metadata: PhotoMetadata, style: WatermarkStyle): Promise<image.PixelMap> {
    // 实现标准水印渲染
  }
}

// 注册插件
PluginManager.registerPlugin(new StandardWatermarkPlugin())
```

### 8.2 配置化架构

```typescript
// 配置管理
export class ConfigManager {
  private static config: AppConfig = new AppConfig()

  static getConfig(): AppConfig {
    return ConfigManager.config
  }

  static async loadConfig() {
    try {
      const configData = await PreferencesService.get('app_config')
      if (configData) {
        ConfigManager.config = JSON.parse(configData)
      }
    } catch (error) {
      hilog.warn(0x0000, 'ConfigManager', 'Failed to load config, using defaults')
    }
  }

  static async saveConfig() {
    try {
      await PreferencesService.save('app_config', JSON.stringify(ConfigManager.config))
    } catch (error) {
      hilog.error(0x0000, 'ConfigManager', 'Failed to save config: %{public}s', error)
    }
  }
}

// 配置模型
@Observed
export class AppConfig {
  @Track watermarkTemplates: WatermarkTemplate[] = []
  @Track defaultWatermarkId: string = ''
  @Track photoQuality: 'low' | 'medium' | 'high' = 'high'
  @Track autoBackup: boolean = true
  @Track theme: 'light' | 'dark' | 'system' = 'system'
  @Track language: string = 'zh-CN'
}
```

## 9. 架构决策记录

### 9.1 为什么选择V2响应式状态管理？

**决策**：使用V2响应式 (@ObservedV2, @Trace, @Local, @Param, @Monitor)

**理由**：
1. **深度观察能力**：适合复杂嵌套对象（项目->工点->照片->元数据）
2. **性能优化**：@Track提供精细化控制，减少不必要的渲染
3. **类型安全**：与ArkTS类型系统完全兼容
4. **未来兼容**：HarmonyOS NEXT官方推荐的状态管理方案

### 9.2 为什么选择关系型数据库？

**决策**：使用HarmonyOS关系型数据库 (RDB Store)

**理由**：
1. **复杂关系**：项目、工点、照片之间存在复杂的外键关系
2. **查询性能**：支持索引和复杂查询，适合大量照片数据
3. **事务支持**：确保数据一致性
4. **系统兼容**：与HarmonyOS备份机制完全兼容

### 9.3 为什么选择离线优先架构？

**决策**：核心功能支持离线使用，网络为可选

**理由**：
1. **工程现场需求**：施工现场经常网络信号不好
2. **数据安全**：敏感工程数据本地存储，不上传云端
3. **用户体验**：不受网络状况影响，保证功能可用性
4. **隐私保护**：用户数据完全掌控在自己设备上

---

**注意**: 本架构设计基于HarmonyOS NEXT平台特性，严格遵循ArkTS和V2响应式状态管理规范。任何架构修改都需要经过团队评审并更新此文档。