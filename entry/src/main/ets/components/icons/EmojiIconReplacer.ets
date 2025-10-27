/**
 * Emoji 图标批量替换工具
 * 提供便捷的 emoji 到图标替换功能
 */

import { EngineeringIcon, Icons } from './EngineeringIcon'
import { EMOJI_TO_ICON_MAP, getIconMapping } from './EmojiToIconMapper'

/**
 * Emoji 图标替换器
 * 用于批量替换项目中的 emoji 图标
 */
export class EmojiIconReplacer {
  private static instance: EmojiIconReplacer

  static getInstance(): EmojiIconReplacer {
    if (!EmojiIconReplacer.instance) {
      EmojiIconReplacer.instance = new EmojiIconReplacer()
    }
    return EmojiIconReplacer.instance
  }

  /**
   * 检查文本是否包含 emoji
   */
  hasEmoji(text: string): boolean {
    const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/u
    return emojiRegex.test(text)
  }

  /**
   * 获取文本中所有的 emoji
   */
  extractEmojis(text: string): string[] {
    const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/gu
    const matches = text.match(emojiRegex)
    return matches ? [...new Set(matches)] : []
  }

  /**
   * 将 emoji 转换为图标组件
   */
  emojiToIconComponent(
    emoji: string,
    props?: { size?: number | string, color?: string, strokeWidth?: number }
  ): EngineeringIcon | null {
    const mapping = getIconMapping(emoji)
    if (!mapping) return null

    const iconName = mapping.iconName as keyof typeof Icons
    const color = props?.color || mapping.defaultColor || '#1890FF'
    const size = props?.size || 24
    const strokeWidth = props?.strokeWidth || 2

    if (Icons[iconName]) {
      return Icons[iconName]({ size, color, strokeWidth })
    }

    return null
  }

  /**
   * 创建图标构建器
   */
  createIconBuilder(emoji: string, defaultProps?: { size?: number | string, color?: string, strokeWidth?: number }) {
    return (props?: { size?: number | string, color?: string, strokeWidth?: number }) => {
      const finalProps = { ...defaultProps, ...props }
      return this.emojiToIconComponent(emoji, finalProps)
    }
  }

  /**
   * 批量替换组件中的 emoji
   */
  replaceEmojisInComponent<T extends Record<string, any>>(
    component: T,
    emojiFields: (keyof T)[],
    iconProps?: { size?: number | string, color?: string, strokeWidth?: number }
  ): Partial<T> {
    const result: Partial<T> = {}

    emojiFields.forEach(field => {
      const value = component[field]
      if (typeof value === 'string' && this.hasEmoji(value)) {
        const iconComponent = this.emojiToIconComponent(value, iconProps)
        if (iconComponent) {
          result[field] = iconComponent as any
        }
      }
    })

    return result
  }

  /**
   * 获取常用图标的快捷创建器
   */
  static get IconCreators() {
    const replacer = EmojiIconReplacer.getInstance()

    return {
      // 导航图标
      building: (props?: any) => Icons.building(props),
      photo: (props?: any) => Icons.photo(props),
      settings: (props?: any) => Icons.settings(props),
      home: (props?: any) => Icons.home(props),

      // 操作图标
      camera: (props?: any) => Icons.camera(props),
      mapPin: (props?: any) => Icons.mapPin(props),
      upload: (props?: any) => Icons.upload(props),
      refresh: (props?: any) => Icons.refresh(props),
      edit: (props?: any) => Icons.edit(props),
      search: (props?: any) => Icons.search(props),

      // 状态图标
      check: (props?: any) => Icons.check(props),
      x: (props?: any) => Icons.x(props),
      alertTriangle: (props?: any) => Icons.alertTriangle(props),
      infoCircle: (props?: any) => Icons.infoCircle(props),

      // 天气图标
      sun: (props?: any) => Icons.sun(props),
      cloud: (props?: any) => Icons.cloud(props),
      cloudRain: (props?: any) => Icons.cloudRain(props),
      snowflake: (props?: any) => Icons.snowflake(props),
      mist: (props?: any) => Icons.mist(props),

      // 其他图标
      chartBar: (props?: any) => Icons.chartBar(props),
      palette: (props?: any) => Icons.palette(props),
      world: (props?: any) => Icons.world(props),
      lock: (props?: any) => Icons.lock(props),

      // Emoji 到图标的快速转换
      fromEmoji: (emoji: string, props?: any) => replacer.emojiToIconComponent(emoji, props)
    }
  }

  /**
   * 获取所有支持的 emoji 映射
   */
  getAllSupportedEmojis(): Record<string, { iconName: string, description: string }> {
    const result: Record<string, { iconName: string, description: string }> = {}

    Object.entries(EMOJI_TO_ICON_MAP).forEach(([emoji, mapping]) => {
      result[emoji] = {
        iconName: mapping.iconName,
        description: mapping.description || ''
      }
    })

    return result
  }

  /**
   * 根据用途分类获取图标
   */
  getIconsByPurpose(): Record<string, Array<{ emoji: string, iconName: string, description: string }>> {
    const categories: Record<string, Array<{ emoji: string, iconName: string, description: string }>> = {
      navigation: [],
      actions: [],
      status: [],
      weather: [],
      ui: []
    }

    Object.entries(EMOJI_TO_ICON_MAP).forEach(([emoji, mapping]) => {
      const item = {
        emoji,
        iconName: mapping.iconName,
        description: mapping.description || ''
      }

      if (['🏗️', '📱', '⚙️', '🏠', '📍'].includes(emoji)) {
        categories.navigation.push(item)
      } else if (['📸', '📤', '🔄', '✏️', '✓', '🎨', '🖼️', '🔍', '📊', '📝'].includes(emoji)) {
        categories.actions.push(item)
      } else if (['✅', '❌', '⚠️', '!', '⚠', 'ℹ', 'ℹ️'].includes(emoji)) {
        categories.status.push(item)
      } else if (['☀️', '☁️', '🌦️', '🌧️', '⛈️', '🌨️', '❄️', '🌫️', '🌤️'].includes(emoji)) {
        categories.weather.push(item)
      } else {
        categories.ui.push(item)
      }
    })

    return categories
  }
}

/**
 * 全局默认图标替换器实例
 */
export const iconReplacer = EmojiIconReplacer.getInstance()

/**
 * 便捷函数：快速创建图标
 */
export function createIcon(emojiOrIconName: string, props?: { size?: number | string, color?: string, strokeWidth?: number }) {
  return iconReplacer.emojiToIconComponent(emojiOrIconName, props)
}

/**
 * 便捷函数：检查是否支持某个 emoji
 */
export function isEmojiSupported(emoji: string): boolean {
  return emoji in EMOJI_TO_ICON_MAP
}

/**
 * 便捷函数：获取推荐的图标颜色
 */
export function getRecommendedIconColor(emoji: string): string {
  const mapping = getIconMapping(emoji)
  return mapping?.defaultColor || '#1890FF'
}