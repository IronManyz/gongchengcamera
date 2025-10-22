/**
 * 数据库常量定义
 * 包含数据库名称、版本、表名、字段名等常量
 */

/**
 * 数据库配置接口
 */
interface DatabaseConfig {
  NAME: string
  VERSION: number
  SECURITY_LEVEL: string
  BACKUP_SUFFIX: string
  TEMP_SUFFIX: string
}

/**
 * 数据库配置
 */
export const DATABASE_CONFIG: DatabaseConfig = {
  NAME: 'engineering_camera.db',
  VERSION: 1,
  SECURITY_LEVEL: 'S1', // 安全级别 S1-S4
  BACKUP_SUFFIX: '.backup',
  TEMP_SUFFIX: '.tmp'
}

/**
 * 数据表名称接口
 */
interface TableNames {
  PROJECTS: string
  SITES: string
  PHOTOS: string
  WATERMARK_TEMPLATES: string
  USERS: string
  BACKUPS: string
  APP_SETTINGS: string
}

/**
 * 数据表名称
 */
export const TABLE_NAMES: TableNames = {
  PROJECTS: 'projects',
  SITES: 'sites',
  PHOTOS: 'photos',
  WATERMARK_TEMPLATES: 'watermark_templates',
  USERS: 'users',
  BACKUPS: 'backups',
  APP_SETTINGS: 'app_settings'
}

/**
 * 通用字段名称接口
 */
interface CommonFields {
  ID: string
  CREATED_AT: string
  UPDATED_AT: string
  VERSION: string
}

/**
 * 通用字段名称
 */
export const COMMON_FIELDS: CommonFields = {
  ID: 'id',
  CREATED_AT: 'created_at',
  UPDATED_AT: 'updated_at',
  VERSION: 'version'
}

/**
 * 项目表字段接口
 */
interface ProjectFields {
  PROJECT_ID: string
  NAME: string
  CODE: string
  CLIENT: string
  MANAGER: string
  START_DATE: string
  END_DATE: string
  DESCRIPTION: string
  TAGS: string
  STATUS: string
  SITE_COUNT: string
  PHOTO_COUNT: string
  METADATA: string
}

/**
 * 项目表字段
 */
export const PROJECT_FIELDS: ProjectFields = {
  PROJECT_ID: 'project_id',
  NAME: 'name',
  CODE: 'code',
  CLIENT: 'client',
  MANAGER: 'manager',
  START_DATE: 'start_date',
  END_DATE: 'end_date',
  DESCRIPTION: 'description',
  TAGS: 'tags',
  STATUS: 'status',
  SITE_COUNT: 'site_count',
  PHOTO_COUNT: 'photo_count',
  METADATA: 'metadata'
}

/**
 * 工点表字段接口
 */
interface SiteFields {
  SITE_ID: string
  PROJECT_ID: string
  NAME: string
  ADDRESS: string
  LATITUDE: string
  LONGITUDE: string
  ALTITUDE: string
  DESCRIPTION: string
  TAGS: string
  LOCATION_DATA: string
  PHOTO_COUNT: string
}

/**
 * 工点表字段
 */
export const SITE_FIELDS: SiteFields = {
  SITE_ID: 'site_id',
  PROJECT_ID: 'project_id',
  NAME: 'name',
  ADDRESS: 'address',
  LATITUDE: 'latitude',
  LONGITUDE: 'longitude',
  ALTITUDE: 'altitude',
  DESCRIPTION: 'description',
  TAGS: 'tags',
  LOCATION_DATA: 'location_data',
  PHOTO_COUNT: 'photo_count'
}

/**
 * 照片表字段接口
 */
interface PhotoFields {
  PHOTO_ID: string
  PROJECT_ID: string
  SITE_ID: string
  FILE_PATH: string
  THUMBNAIL_PATH: string
  TAKEN_AT: string
  LATITUDE: string
  LONGITUDE: string
  ALTITUDE: string
  AZIMUTH: string
  ADDRESS: string
  WEATHER: string
  TEMPLATE_ID: string
  NOTES: string
  TAGS: string
  FILE_SIZE: string
  WIDTH: string
  HEIGHT: string
  EDITED: string
  EXIF_DATA: string
  ANNOTATIONS: string
}

/**
 * 照片表字段
 */
export const PHOTO_FIELDS: PhotoFields = {
  PHOTO_ID: 'photo_id',
  PROJECT_ID: 'project_id',
  SITE_ID: 'site_id',
  FILE_PATH: 'file_path',
  THUMBNAIL_PATH: 'thumbnail_path',
  TAKEN_AT: 'taken_at',
  LATITUDE: 'latitude',
  LONGITUDE: 'longitude',
  ALTITUDE: 'altitude',
  AZIMUTH: 'azimuth',
  ADDRESS: 'address',
  WEATHER: 'weather',
  TEMPLATE_ID: 'template_id',
  NOTES: 'notes',
  TAGS: 'tags',
  FILE_SIZE: 'file_size',
  WIDTH: 'width',
  HEIGHT: 'height',
  EDITED: 'edited',
  EXIF_DATA: 'exif_data',
  ANNOTATIONS: 'annotations'
}

/**
 * 水印模板表字段接口
 */
interface WatermarkTemplateFields {
  TEMPLATE_ID: string
  NAME: string
  DESCRIPTION: string
  CATEGORY: string
  FIELDS: string
  STYLE: string
  PREVIEW: string
  IS_DEFAULT: string
  IS_SYSTEM: string
  USAGE_COUNT: string
  CONFIG: string
}

/**
 * 水印模板表字段
 */
export const WATERMARK_TEMPLATE_FIELDS: WatermarkTemplateFields = {
  TEMPLATE_ID: 'template_id',
  NAME: 'name',
  DESCRIPTION: 'description',
  CATEGORY: 'category',
  FIELDS: 'fields',
  STYLE: 'style',
  PREVIEW: 'preview',
  IS_DEFAULT: 'is_default',
  IS_SYSTEM: 'is_system',
  USAGE_COUNT: 'usage_count',
  CONFIG: 'config'
}

/**
 * 用户表字段接口
 */
interface UserFields {
  USER_ID: string
  USERNAME: string
  EMAIL: string
  DISPLAY_NAME: string
  AVATAR: string
  PHONE: string
  DEPARTMENT: string
  POSITION: string
  ROLE: string
  PERMISSIONS: string
  IS_ACTIVE: string
  LAST_LOGIN_AT: string
  PHOTO_COUNT: string
  PROJECT_COUNT: string
  PREFERENCES: string
  SETTINGS: string
}

/**
 * 用户表字段
 */
export const USER_FIELDS: UserFields = {
  USER_ID: 'user_id',
  USERNAME: 'username',
  EMAIL: 'email',
  DISPLAY_NAME: 'display_name',
  AVATAR: 'avatar',
  PHONE: 'phone',
  DEPARTMENT: 'department',
  POSITION: 'position',
  ROLE: 'role',
  PERMISSIONS: 'permissions',
  IS_ACTIVE: 'is_active',
  LAST_LOGIN_AT: 'last_login_at',
  PHOTO_COUNT: 'photo_count',
  PROJECT_COUNT: 'project_count',
  PREFERENCES: 'preferences',
  SETTINGS: 'settings'
}

/**
 * 备份表字段接口
 */
interface BackupFields {
  BACKUP_ID: string
  NAME: string
  TYPE: string
  SIZE: string
  FILE_PATH: string
  CREATED_AT: string
  COMPLETED_AT: string
  STATUS: string
  DESCRIPTION: string
}

/**
 * 备份表字段
 */
export const BACKUP_FIELDS: BackupFields = {
  BACKUP_ID: 'backup_id',
  NAME: 'name',
  TYPE: 'type',
  SIZE: 'size',
  FILE_PATH: 'file_path',
  CREATED_AT: 'created_at',
  COMPLETED_AT: 'completed_at',
  STATUS: 'status',
  DESCRIPTION: 'description'
}

/**
 * 应用设置表字段接口
 */
interface AppSettingsFields {
  KEY: string
  VALUE: string
  TYPE: string
  UPDATED_AT: string
}

/**
 * 应用设置表字段
 */
export const APP_SETTINGS_FIELDS: AppSettingsFields = {
  KEY: 'key',
  VALUE: 'value',
  TYPE: 'type',
  UPDATED_AT: 'updated_at'
}

/**
 * 数据类型常量接口
 */
interface DataTypes {
  TEXT: string
  INTEGER: string
  REAL: string
  BLOB: string
  BOOLEAN: string // SQLite 没有布尔类型，使用 INTEGER 0/1
}

/**
 * 数据类型常量
 */
export const DATA_TYPES: DataTypes = {
  TEXT: 'TEXT',
  INTEGER: 'INTEGER',
  REAL: 'REAL',
  BLOB: 'BLOB',
  BOOLEAN: 'INTEGER' // SQLite 没有布尔类型，使用 INTEGER 0/1
}

/**
 * 索引名称接口
 */
interface IndexNames {
  // 项目表索引
  PROJECTS_NAME: string
  PROJECTS_STATUS: string
  PROJECTS_DATES: string
  PROJECTS_CODE: string

  // 工点表索引
  SITES_PROJECT_ID: string
  SITES_LOCATION: string
  SITES_NAME: string

  // 照片表索引
  PHOTOS_PROJECT_ID: string
  PHOTOS_SITE_ID: string
  PHOTOS_TAKEN_AT: string
  PHOTOS_LOCATION: string
  PHOTOS_TAGS: string
  PHOTOS_TEMPLATE_ID: string

  // 水印模板表索引
  TEMPLATES_CATEGORY: string
  TEMPLATES_DEFAULT: string
  TEMPLATES_SYSTEM: string
  TEMPLATES_USAGE: string

  // 用户表索引
  USERS_USERNAME: string
  USERS_EMAIL: string
  USERS_ROLE: string
  USERS_ACTIVE: string
  USERS_LAST_LOGIN: string

  // 备份表索引
  BACKUPS_TYPE: string
  BACKUPS_STATUS: string
  BACKUPS_CREATED: string

  // 应用设置索引
  SETTINGS_KEY: string
}

/**
 * 索引名称
 */
export const INDEX_NAMES: IndexNames = {
  // 项目表索引
  PROJECTS_NAME: 'idx_projects_name',
  PROJECTS_STATUS: 'idx_projects_status',
  PROJECTS_DATES: 'idx_projects_dates',
  PROJECTS_CODE: 'idx_projects_code',

  // 工点表索引
  SITES_PROJECT_ID: 'idx_sites_project_id',
  SITES_LOCATION: 'idx_sites_location',
  SITES_NAME: 'idx_sites_name',

  // 照片表索引
  PHOTOS_PROJECT_ID: 'idx_photos_project_id',
  PHOTOS_SITE_ID: 'idx_photos_site_id',
  PHOTOS_TAKEN_AT: 'idx_photos_taken_at',
  PHOTOS_LOCATION: 'idx_photos_location',
  PHOTOS_TAGS: 'idx_photos_tags',
  PHOTOS_TEMPLATE_ID: 'idx_photos_template_id',

  // 水印模板表索引
  TEMPLATES_CATEGORY: 'idx_templates_category',
  TEMPLATES_DEFAULT: 'idx_templates_default',
  TEMPLATES_SYSTEM: 'idx_templates_system',
  TEMPLATES_USAGE: 'idx_templates_usage',

  // 用户表索引
  USERS_USERNAME: 'idx_users_username',
  USERS_EMAIL: 'idx_users_email',
  USERS_ROLE: 'idx_users_role',
  USERS_ACTIVE: 'idx_users_active',
  USERS_LAST_LOGIN: 'idx_users_last_login',

  // 备份表索引
  BACKUPS_TYPE: 'idx_backups_type',
  BACKUPS_STATUS: 'idx_backups_status',
  BACKUPS_CREATED: 'idx_backups_created',

  // 应用设置索引
  SETTINGS_KEY: 'idx_settings_key'
}

/**
 * 默认值常量接口
 */
interface DefaultValues {
  PROJECT_STATUS: string
  SITE_PHOTO_COUNT: number
  PROJECT_PHOTO_COUNT: number
  PROJECT_SITE_COUNT: number
  TEMPLATE_USAGE_COUNT: number
  USER_PHOTO_COUNT: number
  USER_PROJECT_COUNT: number
  BOOLEAN_FALSE: number
  BOOLEAN_TRUE: number
  VERSION: number
}

/**
 * 默认值常量
 */
export const DEFAULT_VALUES: DefaultValues = {
  PROJECT_STATUS: 'active',
  SITE_PHOTO_COUNT: 0,
  PROJECT_PHOTO_COUNT: 0,
  PROJECT_SITE_COUNT: 0,
  TEMPLATE_USAGE_COUNT: 0,
  USER_PHOTO_COUNT: 0,
  USER_PROJECT_COUNT: 0,
  BOOLEAN_FALSE: 0,
  BOOLEAN_TRUE: 1,
  VERSION: 1
}

/**
 * 约束名称接口
 */
interface ConstraintNames {
  // 主键约束
  PK_PROJECTS: string
  PK_SITES: string
  PK_PHOTOS: string
  PK_TEMPLATES: string
  PK_USERS: string
  PK_BACKUPS: string

  // 外键约束
  FK_SITES_PROJECT: string
  FK_PHOTOS_PROJECT: string
  FK_PHOTOS_SITE: string
  FK_PHOTOS_TEMPLATE: string

  // 唯一约束
  UK_USERS_USERNAME: string
  UK_USERS_EMAIL: string
  UK_TEMPLATES_NAME: string
  UK_SETTINGS_KEY: string
}

/**
 * 约束名称
 */
export const CONSTRAINT_NAMES: ConstraintNames = {
  // 主键约束
  PK_PROJECTS: 'pk_projects',
  PK_SITES: 'pk_sites',
  PK_PHOTOS: 'pk_photos',
  PK_TEMPLATES: 'pk_templates',
  PK_USERS: 'pk_users',
  PK_BACKUPS: 'pk_backups',

  // 外键约束
  FK_SITES_PROJECT: 'fk_sites_project',
  FK_PHOTOS_PROJECT: 'fk_photos_project',
  FK_PHOTOS_SITE: 'fk_photos_site',
  FK_PHOTOS_TEMPLATE: 'fk_photos_template',

  // 唯一约束
  UK_USERS_USERNAME: 'uk_users_username',
  UK_USERS_EMAIL: 'uk_users_email',
  UK_TEMPLATES_NAME: 'uk_templates_name',
  UK_SETTINGS_KEY: 'uk_settings_key'
}

/**
 * 查询参数占位符接口
 */
interface Placeholders {
  SINGLE: string
  NAMED: string
  ARRAY_PREFIX: string
}

/**
 * 查询参数占位符
 */
export const PLACEHOLDERS: Placeholders = {
  SINGLE: '?',
  NAMED: ':',
  ARRAY_PREFIX: 'array_'
}

/**
 * 分页查询常量接口
 */
interface Pagination {
  DEFAULT_PAGE_SIZE: number
  MAX_PAGE_SIZE: number
  DEFAULT_PAGE: number
}

/**
 * 分页查询常量
 */
export const PAGINATION: Pagination = {
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,
  DEFAULT_PAGE: 1
}

/**
 * 排序方向常量接口
 */
interface SortDirections {
  ASC: string
  DESC: string
}

/**
 * 排序方向常量
 */
export const SORT_DIRECTIONS: SortDirections = {
  ASC: 'ASC',
  DESC: 'DESC'
}

/**
 * 文件路径常量接口
 */
interface FilePaths {
  DATABASE_DIR: string
  BACKUP_DIR: string
  TEMP_DIR: string
  THUMBNAILS_DIR: string
  PHOTOS_DIR: string
}

/**
 * 文件路径常量
 */
export const FILE_PATHS: FilePaths = {
  DATABASE_DIR: '/databases',
  BACKUP_DIR: '/backups',
  TEMP_DIR: '/temp',
  THUMBNAILS_DIR: '/thumbnails',
  PHOTOS_DIR: '/photos'
}

/**
 * 错误代码常量接口
 */
interface ErrorCodes {
  DATABASE_NOT_FOUND: string
  TABLE_NOT_FOUND: string
  COLUMN_NOT_FOUND: string
  CONSTRAINT_VIOLATION: string
  FOREIGN_KEY_VIOLATION: string
  UNIQUE_VIOLATION: string
  TRANSACTION_FAILED: string
  CONNECTION_FAILED: string
}

/**
 * 错误代码常量
 */
export const ERROR_CODES: ErrorCodes = {
  DATABASE_NOT_FOUND: 'DB_NOT_FOUND',
  TABLE_NOT_FOUND: 'TABLE_NOT_FOUND',
  COLUMN_NOT_FOUND: 'COLUMN_NOT_FOUND',
  CONSTRAINT_VIOLATION: 'CONSTRAINT_VIOLATION',
  FOREIGN_KEY_VIOLATION: 'FOREIGN_KEY_VIOLATION',
  UNIQUE_VIOLATION: 'UNIQUE_VIOLATION',
  TRANSACTION_FAILED: 'TRANSACTION_FAILED',
  CONNECTION_FAILED: 'CONNECTION_FAILED'
}