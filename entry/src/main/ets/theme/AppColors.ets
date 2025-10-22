/**
 * 应用主题颜色定义
 * 统一管理应用的颜色系统
 */

/**
 * 主色调
 */
export const AppColors = {
  // 主品牌色 - 蓝色系
  primary: '#1890FF',
  primaryLight: '#40A9FF',
  primaryDark: '#096DD9',
  primaryBg: '#E6F7FF',
  primaryBgLight: '#F0F9FF',

  // 辅助色
  success: '#52C41A',
  successLight: '#73D13D',
  successDark: '#389E0D',
  successBg: '#F6FFED',

  warning: '#FAAD14',
  warningLight: '#FFC53D',
  warningDark: '#D48806',
  warningBg: '#FFFBE6',

  error: '#FF4D4F',
  errorLight: '#FF7875',
  errorDark: '#D32029',
  errorBg: '#FFF2F0',

  info: '#1890FF',
  infoLight: '#40A9FF',
  infoDark: '#096DD9',
  infoBg: '#E6F7FF',

  // 中性色
  textPrimary: '#262626',
  textSecondary: '#595959',
  textTertiary: '#8C8C8C',
  textQuaternary: '#BFBFBF',
  textDisabled: '#D9D9D9',

  // 背景色
  bgPrimary: '#FFFFFF',
  bgSecondary: '#FAFAFA',
  bgTertiary: '#F5F5F5',
  bgQuaternary: '#FAFAFA',
  bgDisabled: '#F5F5F5',

  // 边框色
  borderPrimary: '#D9D9D9',
  borderSecondary: '#E8E8E8',
  borderTertiary: '#F0F0F0',
  borderLight: '#F0F0F0',

  // 分割线
  divider: '#E8E8E8',
  dividerLight: '#F0F0F0',

  // 阴影色
  shadow: '#00000015',
  shadowLight: '#0000000A',
  shadowMedium: '#00000025',
  shadowDark: '#00000040',

  // 覆盖层
  overlay: '#00000040',
  overlayLight: '#00000020',
  overlayDark: '#00000060',

  // 工程主题色
  engineering: {
    // 安全相关
    safetyGreen: '#52C41A',
    safetyYellow: '#FAAD14',
    safetyRed: '#FF4D4F',
    safetyBlue: '#1890FF',

    // 项目状态
    active: '#52C41A',
    completed: '#1890FF',
    paused: '#FAAD14',
    cancelled: '#FF4D4F',

    // 优先级
    high: '#FF4D4F',
    medium: '#FAAD14',
    low: '#1890FF',

    // 进度
    excellent: '#52C41A',
    good: '#73D13D',
    average: '#FAAD14',
    poor: '#FF7875',
    critical: '#FF4D4F'
  }
}

/**
 * 语义化颜色工具类
 */
export const SemanticColors = {
  // 状态相关
  getStatusColor: (status: string): string => {
    switch (status) {
      case 'active':
      case '进行中':
        return AppColors.engineering.active
      case 'completed':
      case '已完成':
        return AppColors.engineering.completed
      case 'paused':
      case '已暂停':
        return AppColors.engineering.paused
      case 'cancelled':
      case '已取消':
        return AppColors.engineering.cancelled
      default:
        return AppColors.textTertiary
    }
  },

  getPriorityColor: (priority: string): string => {
    switch (priority) {
      case 'high':
      case '高':
        return AppColors.engineering.high
      case 'medium':
      case '中':
        return AppColors.engineering.medium
      case 'low':
      case '低':
        return AppColors.engineering.low
      default:
        return AppColors.textTertiary
    }
  },

  getProgressColor: (progress: number): string => {
    if (progress >= 90) return AppColors.engineering.excellent
    if (progress >= 75) return AppColors.engineering.good
    if (progress >= 60) return AppColors.engineering.average
    if (progress >= 40) return AppColors.engineering.poor
    return AppColors.engineering.critical
  },

  // 照片数量状态
  getPhotoCountColor: (count: number): string => {
    if (count === 0) return AppColors.textQuaternary
    if (count < 10) return AppColors.warning
    return AppColors.success
  },

  // 天气相关
  getWeatherColor: (weather: string): string => {
    switch (weather?.toLowerCase()) {
      case 'sunny':
      case '晴':
        return '#FFD700'
      case 'cloudy':
      case '多云':
        return '#87CEEB'
      case 'rainy':
      case '雨':
        return '#4682B4'
      case 'snowy':
      case '雪':
        return '#B0E0E6'
      default:
        return AppColors.textTertiary
    }
  }
}

/**
 * 渐变色定义
 */
export const Gradients = {
  // 主品牌渐变
  primary: {
    start: AppColors.primary,
    end: AppColors.primaryDark
  },

  // 成功渐变
  success: {
    start: AppColors.success,
    end: AppColors.successDark
  },

  // 警告渐变
  warning: {
    start: AppColors.warning,
    end: AppColors.warningDark
  },

  // 错误渐变
  error: {
    start: AppColors.error,
    end: AppColors.errorDark
  },

  // 工程主题渐变
  engineering: {
    safe: {
      start: '#52C41A',
      end: '#389E0D'
    },
    warning: {
      start: '#FAAD14',
      end: '#D48806'
    },
    danger: {
      start: '#FF4D4F',
      end: '#D32029'
    },
    progress: {
      start: '#1890FF',
      end: '#096DD9'
    }
  },

  // 背景渐变
  background: {
    light: {
      start: '#FFFFFF',
      end: '#F5F5F5'
    },
    dark: {
      start: '#FAFAFA',
      end: '#E8E8E8'
    },
    card: {
      start: '#FFFFFF',
      end: '#F8F9FA'
    }
  }
}

/**
 * 主题色彩搭配
 */
export const ColorPalettes = {
  // 工程主题
  engineering: {
    primary: AppColors.primary,
    secondary: AppColors.success,
    accent: AppColors.warning,
    background: AppColors.bgPrimary,
    surface: AppColors.bgSecondary,
    text: AppColors.textPrimary,
    border: AppColors.borderPrimary,
    shadow: AppColors.shadow
  },

  // 安全主题
  safety: {
    primary: AppColors.engineering.safetyGreen,
    secondary: AppColors.engineering.safetyYellow,
    accent: AppColors.engineering.safetyRed,
    background: AppColors.bgPrimary,
    surface: AppColors.bgSecondary,
    text: AppColors.textPrimary,
    border: AppColors.borderPrimary,
    shadow: AppColors.shadow
  },

  // 专业主题
  professional: {
    primary: '#2C3E50',
    secondary: '#34495E',
    accent: AppColors.primary,
    background: '#FFFFFF',
    surface: '#F8F9FA',
    text: '#2C3E50',
    border: '#E1E8ED',
    shadow: AppColors.shadow
  }
}

/**
 * 颜色工具函数
 */
export const ColorUtils = {
  /**
   * 获取对比色（黑白）
   */
  getContrastColor: (bgColor: string): string => {
    // 简单的对比度计算
    const hex = bgColor.replace('#', '')
    const r = parseInt(hex.substr(0, 2), 16)
    const g = parseInt(hex.substr(2, 2), 16)
    const b = parseInt(hex.substr(4, 2), 16)
    const brightness = (r * 299 + g * 587 + b * 114) / 1000
    return brightness > 128 ? '#000000' : '#FFFFFF'
  },

  /**
   * 获取带透明度的颜色
   */
  withAlpha: (color: string, alpha: number): string => {
    const hex = color.replace('#', '')
    const r = parseInt(hex.substr(0, 2), 16)
    const g = parseInt(hex.substr(2, 2), 16)
    const b = parseInt(hex.substr(4, 2), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  },

  /**
   * 混合颜色
   */
  mix: (color1: string, color2: string, ratio: number = 0.5): string => {
    const hex1 = color1.replace('#', '')
    const hex2 = color2.replace('#', '')

    const r1 = parseInt(hex1.substr(0, 2), 16)
    const g1 = parseInt(hex1.substr(2, 2), 16)
    const b1 = parseInt(hex1.substr(4, 2), 16)

    const r2 = parseInt(hex2.substr(0, 2), 16)
    const g2 = parseInt(hex2.substr(2, 2), 16)
    const b2 = parseInt(hex2.substr(4, 2), 16)

    const r = Math.round(r1 * (1 - ratio) + r2 * ratio)
    const g = Math.round(g1 * (1 - ratio) + g2 * ratio)
    const b = Math.round(b1 * (1 - ratio) + b2 * ratio)

    return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
  },

  /**
   * 调整颜色亮度
   */
  adjustBrightness: (color: string, amount: number): string => {
    const hex = color.replace('#', '')
    const r = Math.max(0, Math.min(255, parseInt(hex.substr(0, 2), 16) + amount))
    const g = Math.max(0, Math.min(255, parseInt(hex.substr(2, 2), 16) + amount))
    const b = Math.max(0, Math.min(255, parseInt(hex.substr(4, 2), 16) + amount))

    return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
  }
}