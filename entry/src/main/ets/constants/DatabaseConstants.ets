/**
 * 数据库常量定义
 * 包含数据库名称、版本、表名、字段名等常量
 */

/**
 * 数据库配置
 */
export const DATABASE_CONFIG = {
  NAME: 'engineering_camera.db',
  VERSION: 1,
  SECURITY_LEVEL: 'S1' as const, // 安全级别 S1-S4
  BACKUP_SUFFIX: '.backup',
  TEMP_SUFFIX: '.tmp'
}

/**
 * 数据表名称
 */
export const TABLE_NAMES = {
  PROJECTS: 'projects',
  SITES: 'sites',
  PHOTOS: 'photos',
  WATERMARK_TEMPLATES: 'watermark_templates',
  USERS: 'users',
  BACKUPS: 'backups',
  APP_SETTINGS: 'app_settings'
} as const

/**
 * 通用字段名称
 */
export const COMMON_FIELDS = {
  ID: 'id',
  CREATED_AT: 'created_at',
  UPDATED_AT: 'updated_at',
  VERSION: 'version'
} as const

/**
 * 项目表字段
 */
export const PROJECT_FIELDS = {
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
} as const

/**
 * 工点表字段
 */
export const SITE_FIELDS = {
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
} as const

/**
 * 照片表字段
 */
export const PHOTO_FIELDS = {
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
} as const

/**
 * 水印模板表字段
 */
export const WATERMARK_TEMPLATE_FIELDS = {
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
} as const

/**
 * 用户表字段
 */
export const USER_FIELDS = {
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
} as const

/**
 * 备份表字段
 */
export const BACKUP_FIELDS = {
  BACKUP_ID: 'backup_id',
  NAME: 'name',
  TYPE: 'type',
  SIZE: 'size',
  FILE_PATH: 'file_path',
  CREATED_AT: 'created_at',
  COMPLETED_AT: 'completed_at',
  STATUS: 'status',
  DESCRIPTION: 'description'
} as const

/**
 * 应用设置表字段
 */
export const APP_SETTINGS_FIELDS = {
  KEY: 'key',
  VALUE: 'value',
  TYPE: 'type',
  UPDATED_AT: 'updated_at'
} as const

/**
 * 数据类型常量
 */
export const DATA_TYPES = {
  TEXT: 'TEXT',
  INTEGER: 'INTEGER',
  REAL: 'REAL',
  BLOB: 'BLOB',
  BOOLEAN: 'INTEGER' // SQLite 没有布尔类型，使用 INTEGER 0/1
} as const

/**
 * 索引名称
 */
export const INDEX_NAMES = {
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
} as const

/**
 * 默认值常量
 */
export const DEFAULT_VALUES = {
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
} as const

/**
 * 约束名称
 */
export const CONSTRAINT_NAMES = {
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
} as const

/**
 * 查询参数占位符
 */
export const PLACEHOLDERS = {
  SINGLE: '?',
  NAMED: ':',
  ARRAY_PREFIX: 'array_'
} as const

/**
 * 分页查询常量
 */
export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,
  DEFAULT_PAGE: 1
} as const

/**
 * 排序方向常量
 */
export const SORT_DIRECTIONS = {
  ASC: 'ASC',
  DESC: 'DESC'
} as const

/**
 * 文件路径常量
 */
export const FILE_PATHS = {
  DATABASE_DIR: '/databases',
  BACKUP_DIR: '/backups',
  TEMP_DIR: '/temp',
  THUMBNAILS_DIR: '/thumbnails',
  PHOTOS_DIR: '/photos'
} as const

/**
 * 错误代码常量
 */
export const ERROR_CODES = {
  DATABASE_NOT_FOUND: 'DB_NOT_FOUND',
  TABLE_NOT_FOUND: 'TABLE_NOT_FOUND',
  COLUMN_NOT_FOUND: 'COLUMN_NOT_FOUND',
  CONSTRAINT_VIOLATION: 'CONSTRAINT_VIOLATION',
  FOREIGN_KEY_VIOLATION: 'FOREIGN_KEY_VIOLATION',
  UNIQUE_VIOLATION: 'UNIQUE_VIOLATION',
  TRANSACTION_FAILED: 'TRANSACTION_FAILED',
  CONNECTION_FAILED: 'CONNECTION_FAILED'
} as const