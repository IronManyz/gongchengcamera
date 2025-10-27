/**
 * Emoji 到图标映射工具
 * 提供便捷的 emoji 图标替换功能
 */

import { EngineeringIcon, Icons } from './EngineeringIcon'

export interface EmojiMapping {
  emoji: string
  iconName: string
  defaultColor?: string
  description?: string
}

/**
 * Emoji 图标映射表
 * 用于快速查找和替换 emoji 为专业图标
 */
export const EMOJI_TO_ICON_MAP: Record<string, EmojiMapping> = {
  // 导航图标
  '🏗️': { emoji: '🏗️', iconName: 'building', defaultColor: '#1890FF', description: '工程项目' },
  '📱': { emoji: '📱', iconName: 'photo', defaultColor: '#1890FF', description: '相册' },
  '⚙️': { emoji: '⚙️', iconName: 'settings', defaultColor: '#1890FF', description: '设置' },

  // 相机操作
  '📸': { emoji: '📸', iconName: 'camera', defaultColor: '#FF4D4F', description: '拍照' },
  '📤': { emoji: '📤', iconName: 'upload', defaultColor: '#52C41A', description: '导出/分享' },
  '🔄': { emoji: '🔄', iconName: 'refresh', defaultColor: '#1890FF', description: '刷新/同步' },
  '✏️': { emoji: '✏️', iconName: 'edit', defaultColor: '#FA8C16', description: '编辑' },
  '✓': { emoji: '✓', iconName: 'check', defaultColor: '#52C41A', description: '确认/完成' },

  // 位置相关
  '📍': { emoji: '📍', iconName: 'mapPin', defaultColor: '#F5222D', description: '位置/标记' },

  // 状态指示
  '✅': { emoji: '✅', iconName: 'check', defaultColor: '#52C41A', description: '完成/成功' },
  '❌': { emoji: '❌', iconName: 'x', defaultColor: '#FF4D4F', description: '错误/失败' },
  '⚠️': { emoji: '⚠️', iconName: 'alertTriangle', defaultColor: '#FA8C16', description: '警告' },
  '!': { emoji: '!', iconName: 'alertTriangle', defaultColor: '#FA8C16', description: '警告' },
  '⚠': { emoji: '⚠', iconName: 'alertTriangle', defaultColor: '#FA8C16', description: '警告' },
  'ℹ': { emoji: 'ℹ', iconName: 'infoCircle', defaultColor: '#1890FF', description: '信息' },
  'ℹ️': { emoji: 'ℹ️', iconName: 'infoCircle', defaultColor: '#1890FF', description: '信息' },

  // 空状态图标
  '🔍': { emoji: '🔍', iconName: 'search', defaultColor: '#8C8C8C', description: '搜索' },
  '🌐': { emoji: '🌐', iconName: 'world', defaultColor: '#1890FF', description: '网络' },
  '🔒': { emoji: '🔒', iconName: 'lock', defaultColor: '#8C8C8C', description: '权限' },
  '📭': { emoji: '📭', iconName: 'mail', defaultColor: '#8C8C8C', description: '邮箱/空状态' },

  // 功能图标
  '📊': { emoji: '📊', iconName: 'chartBar', defaultColor: '#1890FF', description: '统计/报表' },
  '🎨': { emoji: '🎨', iconName: 'palette', defaultColor: '#722ED1', description: '编辑/涂鸦' },
  '🖼️': { emoji: '🖼️', iconName: 'photo', defaultColor: '#1890FF', description: '图片' },

  // 天气图标
  '☀️': { emoji: '☀️', iconName: 'sun', defaultColor: '#FA8C16', description: '晴天' },
  '☁️': { emoji: '☁️', iconName: 'cloud', defaultColor: '#8C8C8C', description: '多云' },
  '🌦️': { emoji: '🌦️', iconName: 'cloudRain', defaultColor: '#1890FF', description: '小雨' },
  '🌧️': { emoji: '🌧️', iconName: 'cloudRain', defaultColor: '#1890FF', description: '中雨' },
  '⛈️': { emoji: '⛈️', iconName: 'cloudRain', defaultColor: '#434343', description: '雷雨' },
  '🌨️': { emoji: '🌨️', iconName: 'snowflake', defaultColor: '#1890FF', description: '小雪' },
  '❄️': { emoji: '❄️', iconName: 'snowflake', defaultColor: '#1890FF', description: '中雪' },
  '🌫️': { emoji: '🌫️', iconName: 'mist', defaultColor: '#8C8C8C', description: '雾/霾' },
  '🌤️': { emoji: '🌤️', iconName: 'sun', defaultColor: '#FA8C16', description: '晴间多云' },

  // 操作按钮
  '▶️': { emoji: '▶️', iconName: 'play', defaultColor: '#52C41A', description: '开始/播放' },
  '⏸️': { emoji: '⏸️', iconName: 'pause', defaultColor: '#FA8C16', description: '暂停' },
  '⏹️': { emoji: '⏹️', iconName: 'square', defaultColor: '#FF4D4F', description: '停止' },

  // 文件操作
  '📄': { emoji: '📄', iconName: 'file', defaultColor: '#8C8C8C', description: '文件' },
  '📁': { emoji: '📁', iconName: 'folder', defaultColor: '#FA8C16', description: '文件夹' },
  '🗑️': { emoji: '🗑️', iconName: 'trash', defaultColor: '#FF4D4F', description: '删除' },
  '📋': { emoji: '📋', iconName: 'clipboard', defaultColor: '#1890FF', description: '剪贴板' },
  '📝': { emoji: '📝', iconName: 'edit', defaultColor: '#1890FF', description: '编辑/笔记' },

  // 界面元素
  '🏠': { emoji: '🏠', iconName: 'home', defaultColor: '#1890FF', description: '首页' },
  '👤': { emoji: '👤', iconName: 'user', defaultColor: '#1890FF', description: '用户' },
  '🔔': { emoji: '🔔', iconName: 'bell', defaultColor: '#FA8C16', description: '通知' },
  '❤️': { emoji: '❤️', iconName: 'heart', defaultColor: '#FF4D4F', description: '收藏/喜欢' },
  '⭐': { emoji: '⭐', iconName: 'star', defaultColor: '#FAAD14', description: '收藏/重要' },
  '🔖': { emoji: '🔖', iconName: 'bookmark', defaultColor: '#1890FF', description: '书签' }
}

/**
 * 检查字符串是否为 emoji
 */
export function isEmoji(text: string): boolean {
  const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/u
  return emojiRegex.test(text)
}

/**
 * 获取 emoji 对应的图标映射
 */
export function getIconMapping(emoji: string): EmojiMapping | null {
  return EMOJI_TO_ICON_MAP[emoji] || null
}

/**
 * 将 emoji 转换为图标组件
 */
export function emojiToIcon(
  emoji: string,
  props?: { size?: number | string, color?: string, strokeWidth?: number }
): EngineeringIcon | null {
  const mapping = getIconMapping(emoji)
  if (!mapping) return null

  const color = props?.color || mapping.defaultColor || '#1890FF'
  const size = props?.size || 24
  const strokeWidth = props?.strokeWidth || 2

  return Icons[mapping.iconName as keyof typeof Icons]?.({
    size,
    color,
    strokeWidth
  }) || null
}

/**
 * 批量替换文本中的 emoji 为图标
 */
export function replaceEmojisInText(
  text: string,
  iconProps?: { size?: number | string, color?: string, strokeWidth?: number }
): string {
  return text.replace(/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/gu, (match) => {
    const mapping = getIconMapping(match)
    return mapping ? `[ICON:${mapping.iconName}]` : match
  })
}

/**
 * 图标替换工具类
 */
export class IconReplacer {
  private defaultProps: { size: number | string, color: string, strokeWidth: number }

  constructor(defaultProps?: { size?: number | string, color?: string, strokeWidth?: number }) {
    this.defaultProps = {
      size: 24,
      color: '#1890FF',
      strokeWidth: 2,
      ...defaultProps
    }
  }

  /**
   * 获取所有支持的 emoji 映射
   */
  getAllMappings(): Record<string, EmojiMapping> {
    return { ...EMOJI_TO_ICON_MAP }
  }

  /**
   * 按分类获取映射
   */
  getMappingsByCategory(): Record<string, EmojiMapping[]> {
    const categories: Record<string, EmojiMapping[]> = {
      navigation: [],
      camera: [],
      status: [],
      weather: [],
      file: [],
      interface: []
    }

    Object.values(EMOJI_TO_ICON_MAP).forEach(mapping => {
      const emoji = mapping.emoji

      if (['🏗️', '📱', '⚙️', '🏠'].includes(emoji)) {
        categories.navigation.push(mapping)
      } else if (['📸', '📤', '🔄', '✏️', '✓', '🎨', '🖼️'].includes(emoji)) {
        categories.camera.push(mapping)
      } else if (['✅', '❌', '⚠️', '!', '⚠', 'ℹ', 'ℹ️'].includes(emoji)) {
        categories.status.push(mapping)
      } else if (['☀️', '☁️', '🌦️', '🌧️', '⛈️', '🌨️', '❄️', '🌫️', '🌤️'].includes(emoji)) {
        categories.weather.push(mapping)
      } else if (['📄', '📁', '🗑️', '📋', '📝'].includes(emoji)) {
        categories.file.push(mapping)
      } else {
        categories.interface.push(mapping)
      }
    })

    return categories
  }

  /**
   * 创建图标组件
   */
  createIcon(emoji: string, props?: Partial<{ size: number | string, color: string, strokeWidth: number }>): EngineeringIcon | null {
    const finalProps = { ...this.defaultProps, ...props }
    return emojiToIcon(emoji, finalProps)
  }

  /**
   * 获取推荐的图标颜色
   */
  getRecommendedColor(emoji: string): string {
    const mapping = getIconMapping(emoji)
    return mapping?.defaultColor || this.defaultProps.color
  }

  /**
   * 检查 emoji 是否支持
   */
  isEmojiSupported(emoji: string): boolean {
    return emoji in EMOJI_TO_ICON_MAP
  }
}

/**
 * 默认图标替换器实例
 */
export const defaultIconReplacer = new IconReplacer()

/**
 * 便捷函数：快速创建图标
 */
export function createIconFromEmoji(
  emoji: string,
  props?: Partial<{ size: number | string, color: string, strokeWidth: number }>
): EngineeringIcon | null {
  return defaultIconReplacer.createIcon(emoji, props)
}