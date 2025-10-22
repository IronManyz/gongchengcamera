/**
 * 应用全局类型定义
 * 包含项目中使用的基础类型、接口和枚举
 */

/**
 * 项目状态枚举
 */
export enum ProjectStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  PAUSED = 'paused',
  CANCELLED = 'cancelled'
}

/**
 * 项目过滤器枚举
 */
export enum ProjectFilter {
  ALL = 'all',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  PAUSED = 'paused',
  CANCELLED = 'cancelled'
}

/**
 * 项目排序枚举
 */
export enum ProjectSortOrder {
  NAME_ASC = 'name_asc',
  NAME_DESC = 'name_desc',
  CREATED_ASC = 'created_asc',
  CREATED_DESC = 'created_desc',
  UPDATED_ASC = 'updated_asc',
  UPDATED_DESC = 'updated_desc'
}

/**
 * 水印模板分类枚举
 */
export enum TemplateCategory {
  SYSTEM = 'system',
  CONSTRUCTION = 'construction',
  QUALITY = 'quality',
  SAFETY = 'safety',
  CUSTOM = 'custom'
}

/**
 * 照片过滤器枚举
 */
export enum PhotoFilter {
  ALL = 'all',
  RECENT = 'recent',
  TODAY = 'today',
  THIS_WEEK = 'this_week',
  THIS_MONTH = 'this_month',
  EDITED = 'edited',
  FAVORITE = 'favorite'
}

/**
 * 照片排序枚举
 */
export enum PhotoSortOrder {
  TAKEN_ASC = 'taken_asc',
  TAKEN_DESC = 'taken_desc',
  CREATED_ASC = 'created_asc',
  CREATED_DESC = 'created_desc',
  NAME_ASC = 'name_asc',
  NAME_DESC = 'name_desc',
  SIZE_ASC = 'size_asc',
  SIZE_DESC = 'size_desc'
}

/**
 * 主题模式枚举
 */
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

/**
 * 用户角色枚举
 */
export enum UserRole {
  OWNER = 'owner',
  EDITOR = 'editor',
  VIEWER = 'viewer'
}

/**
 * 权限枚举
 */
export enum Permission {
  READ = 'read',
  WRITE = 'write',
  DELETE = 'delete',
  SHARE = 'share',
  MANAGE = 'manage'
}

/**
 * 文件类型枚举
 */
export enum FileType {
  IMAGE = 'image',
  VIDEO = 'video',
  DOCUMENT = 'document',
  ARCHIVE = 'archive'
}

/**
 * 数据库操作类型枚举
 */
export enum DatabaseOperation {
  CREATE = 'create',
  READ = 'read',
  UPDATE = 'update',
  DELETE = 'delete'
}

/**
 * 位置数据接口
 */
export interface LocationData {
  country: string
  province: string
  city: string
  district: string
  street: string
  postalCode: string
}

/**
 * 天气信息接口
 */
export interface WeatherInfo {
  temperature: number
  humidity: number
  condition: string
  icon: string
}

/**
 * 标注信息接口
 */
export interface Annotation {
  id: string
  type: 'text' | 'shape' | 'doodle' | 'mosaic'
  content: Object
  position: Position
  style: WatermarkStyle
  createdAt: Date
}

/**
 * 位置接口
 */
export interface Position {
  x: number
  y: number
}

/**
 * 水印字段接口
 */
export interface WatermarkField {
  key: string
  label: string
  enabled: boolean
  format?: string
  position?: Position
}

/**
 * 水印样式接口
 */
export interface WatermarkStyle {
  backgroundColor: string
  textColor: string
  fontSize: number
  fontFamily: string
  opacity: number
  borderRadius: number
  padding: number
  position: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'center'
}

/**
 * 文本颜色接口
 */
export interface TextColors {
  primary: string
  secondary: string
  disabled: string
}

/**
 * 边框颜色接口
 */
export interface BorderColors {
  default: string
  focus: string
  error: string
}

/**
 * 主题颜色接口
 */
export interface ThemeColors {
  primary: string
  secondary: string
  background: string
  surface: string
  error: string
  onPrimary: string
  onSecondary: string
  onBackground: string
  onSurface: string
  onError: string
  text: TextColors
  border: BorderColors
}

/**
 * 字体大小接口
 */
export interface FontSizes {
  small: number
  medium: number
  large: number
  xlarge: number
}

/**
 * 字体粗细接口
 */
export interface FontWeights {
  normal: FontWeight
  medium: FontWeight
  bold: FontWeight
}

/**
 * 行高接口
 */
export interface LineHeights {
  tight: number
  normal: number
  relaxed: number
}

/**
 * 主题字体接口
 */
export interface ThemeTypography {
  fontSize: FontSizes
  fontWeight: FontWeights
  lineHeight: LineHeights
}

/**
 * 主题间距接口
 */
export interface ThemeSpacing {
  xs: number
  sm: number
  md: number
  lg: number
  xl: number
  xxl: number
}

/**
 * 主题接口
 */
export interface Theme {
  colors: ThemeColors
  typography: ThemeTypography
  spacing: ThemeSpacing
}

/**
 * 数据库配置接口
 */
export interface DatabaseConfig {
  name: string
  version: number
  securityLevel: 'S1' | 'S2' | 'S3' | 'S4'
}

/**
 * 数据库表结构接口
 */
export interface TableSchema {
  name: string
  columns: ColumnSchema[]
  indexes?: IndexSchema[]
}

/**
 * 数据库列结构接口
 */
export interface ColumnSchema {
  name: string
  type: 'TEXT' | 'INTEGER' | 'REAL' | 'BLOB'
  nullable: boolean
  primaryKey?: boolean
  autoIncrement?: boolean
  defaultValue?: string | number | boolean
  unique?: boolean
}

/**
 * 数据库索引结构接口
 */
export interface IndexSchema {
  name: string
  columns: string[]
  unique?: boolean
}

/**
 * API响应接口
 */
export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  code?: number
}

/**
 * 分页请求参数接口
 */
export interface PaginationParams {
  page: number
  pageSize: number
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

/**
 * 分页响应接口
 */
export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
  hasNext: boolean
  hasPrev: boolean
}

/**
 * 分页结果接口（别名）
 */
export type PaginationResult<T> = PaginatedResponse<T>

/**
 * 搜索参数接口
 */
export interface SearchParams {
  query?: string
  filters?: Map<string, Object>
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
  pagination?: PaginationParams
}

/**
 * 应用配置接口
 */
export interface AppConfig {
  version: string
  buildNumber: string
  environment: 'development' | 'production' | 'testing'
  features: Map<string, boolean>
}

/**
 * 用户偏好设置接口
 */
export interface UserPreferences {
  theme: ThemeMode
  language: string
  autoBackup: boolean
  compressImages: boolean
  defaultTemplate?: string
  locationServices: boolean
}

/**
 * 错误信息接口
 */
export interface ErrorInfo {
  code: string
  message: string
  details?: Object
  timestamp: Date
}

/**
 * 日志级别枚举
 */
export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error'
}

/**
 * 日志信息接口
 */
export interface LogInfo {
  level: LogLevel
  message: string
  timestamp: Date
  tag?: string
  data?: Object
}

/**
 * BaseModel JSON接口
 */
export interface BaseModelJSON {
  id: string
  createdAt: number
  updatedAt: number
  version: number
}

/**
 * 水印模板导出配置接口
 */
export interface ExportConfig {
  name: string
  description: string
  category: TemplateCategory
  fields: WatermarkField[]
  style: WatermarkStyle
  config: Record<string, string | number | boolean>
}

/**
 * EXIF数据类
 */
@ObservedV2
export class ExifData {
  @Trace data: Map<string, string | number | boolean | null> = new Map()

  set(key: string, value: string | number | boolean | null): void {
    this.data.set(key, value)
  }

  get(key: string): string | number | boolean | null {
    return this.data.get(key) ?? null
  }

  has(key: string): boolean {
    return this.data.has(key)
  }

  delete(key: string): boolean {
    return this.data.delete(key)
  }

  clear(): void {
    this.data.clear()
  }

  keys(): string[] {
    return Array.from(this.data.keys())
  }

  entries: Array<[string, string | number | boolean | null]> = []

  updateEntries(): void {
    this.entries = Array.from(this.data.entries())
  }
}

/**
 * 照片JSON数据接口
 */
export interface PhotoJSON {
  id: string
  createdAt: number
  updatedAt: number
  version: number
  projectId: string
  siteId: string
  filePath: string
  thumbnailPath: string
  takenAt: number
  latitude: number
  longitude: number
  altitude: number
  azimuth: number
  address: string
  weather: WeatherInfo | null
  templateId: string
  notes: string
  tags: string[]
  fileSize: number
  width: number
  height: number
  edited: boolean
  exifData: Record<string, string | number | boolean | null>
  annotations: Annotation[]
}

/**
 * 工点JSON数据接口
 */
export interface SiteJSON {
  id: string
  createdAt: number
  updatedAt: number
  version: number
  projectId: string
  name: string
  address: string
  latitude: number
  longitude: number
  altitude: number
  description: string
  tags: string[]
  photoCount: number
  locationData: LocationData | null
}

/**
 * 项目JSON数据接口
 */
export interface ProjectJSON {
  id: string
  createdAt: number
  updatedAt: number
  version: number
  name: string
  code: string
  client: string
  manager: string
  startDate: number
  endDate: number
  description: string
  tags: string[]
  status: ProjectStatus
  siteCount: number
  photoCount: number
  metadata: Map<string, Object>
}

/**
 * 水印模板JSON数据接口
 */
export interface WatermarkTemplateJSON {
  id: string
  createdAt: number
  updatedAt: number
  version: number
  name: string
  description: string
  category: TemplateCategory
  fields: WatermarkField[]
  style: WatermarkStyle
  preview: string
  isDefault: boolean
  isSystem: boolean
  usageCount: number
  config: Record<string, string | number | boolean>
}