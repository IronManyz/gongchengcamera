/**
 * 应用间距和尺寸系统
 * 统一管理边距、内边距、组件尺寸等
 */

/**
 * 基础间距单位 (4px)
 */
const BASE_UNIT = 4

/**
 * 间距定义
 */
export const Spacing = {
  // 极小间距
  xxs: BASE_UNIT * 0.5,    // 2px
  xs: BASE_UNIT,             // 4px

  // 小间距
  sm: BASE_UNIT * 2,        // 8px
  md: BASE_UNIT * 3,        // 12px

  // 中等间距
  lg: BASE_UNIT * 4,         // 16px
  xl: BASE_UNIT * 5,         // 20px

  // 大间距
  xxl: BASE_UNIT * 6,       // 24px
  xxxl: BASE_UNIT * 8,      // 32px

  // 超大间距
  huge: BASE_UNIT * 10,      // 40px
  massive: BASE_UNIT * 12,   // 48px
}

/**
 * 内边距定义
 */
export const Padding = {
  // 无内边距
  none: 0,

  // 极小内边距
  xxs: Spacing.xs,
  xs: Spacing.xs,

  // 小内边距
  sm: Spacing.sm,
  md: Spacing.md,

  // 中等内边距
  lg: Spacing.lg,
  xl: Spacing.xl,

  // 大内边距
  xxl: Spacing.xxl,
  xxxl: Spacing.xxxl,

  // 超大内边距
  huge: Spacing.huge,
  massive: Spacing.massive,

  // 方向内边距
  vertical: {
    xs: Spacing.xs,
    sm: Spacing.sm,
    md: Spacing.md,
    lg: Spacing.lg,
    xl: Spacing.xl,
    xxl: Spacing.xxl,
    xxxl: Spacing.xxxl
  },

  horizontal: {
    xs: Spacing.xs,
    sm: Spacing.sm,
    md: Spacing.md,
    lg: Spacing.lg,
    xl: Spacing.xl,
    xxl: Spacing.xxl,
    xxxl: Spacing.xxxl
  }
}

/**
 * 外边距定义
 */
export const Margin = {
  // 无外边距
  none: 0,

  // 极小外边距
  xxs: Spacing.xs,
  xs: Spacing.xs,

  // 小外边距
  sm: Spacing.sm,
  md: Spacing.md,

  // 中等外边距
  lg: Spacing.lg,
  xl: Spacing.xl,

  // 大外边距
  xxl: Spacing.xxl,
  xxxl: Spacing.xxxl,

  // 超大外边距
  huge: Spacing.huge,
  massive: Spacing.massive,

  // 方向外边距
  vertical: {
    xs: Spacing.xs,
    sm: Spacing.sm,
    md: Spacing.md,
    lg: Spacing.lg,
    xl: Spacing.xl,
    xxl: Spacing.xxl,
    xxxl: Spacing.xxxl
  },

  horizontal: {
    xs: Spacing.xs,
    sm: Spacing.sm,
    md: Spacing.md,
    lg: Spacing.lg,
    xl: Spacing.xl,
    xxl: Spacing.xxl,
    xxxl: Spacing.xxxl
  }
}

/**
 * 组件尺寸定义
 */
export const Sizes = {
  // 小尺寸组件
  xs: 24,    // 小按钮、小图标
  sm: 32,    // 中小按钮
  md: 40,    // 中等按钮
  lg: 48,    // 大按钮

  // 标准尺寸
  xl: 56,    // 标准按钮
  xxl: 64,   // 大按钮

  // 大尺寸组件
  xxxl: 72,  // 超大按钮
  huge: 96,   // 巨大按钮
  massive: 120, // 超大按钮

  // 卡片尺寸
  cardSmall: 320,
  cardMedium: 360,
  cardLarge: 400,
  cardXLarge: 440,

  // 容器尺寸
  container: {
    xs: 320,
    sm: 480,
    md: 640,
    lg: 768,
    xl: 1024,
    xxl: 1280,
    xxxl: 1440
  },

  // 网格系统
  grid: {
    xs: 1,
    sm: 2,
    md: 3,
    lg: 4,
    xl: 6,
    xxl: 8
  },

  // 图标尺寸
  icon: {
    xs: 12,
    sm: 16,
    md: 20,
    lg: 24,
    xl: 32,
    xxl: 40,
    xxxl: 48
  },

  // 圆形组件
  circle: {
    xs: 24,
    sm: 32,
    md: 40,
    lg: 48,
    xl: 56,
    xxl: 64,
    xxxl: 72
  }
}

/**
 * 响应式断点
 */
export const Breakpoints = {
  xs: 320,    // 超小屏幕
  sm: 480,    // 小屏幕
  md: 640,    // 中等屏幕
  lg: 768,    // 大屏幕
  xl: 1024,   // 超大屏幕
  xxl: 1280,  // 超大屏幕
  xxxl: 1440  // 超大屏幕
}

/**
 * 设备类型
 */
export const DeviceTypes = {
  mobile: {
    max: Breakpoints.sm - 1
  },
  tablet: {
    min: Breakpoints.sm,
    max: Breakpoints.lg - 1
  },
  desktop: {
    min: Breakpoints.lg
  }
}

/**
 * 间距工具函数
 */
export const SpacingUtils = {
  /**
   * 获取自定义间距
   */
  custom: (units: number): number => {
    return BASE_UNIT * units
  },

  /**
   * 应用间距样式
   */
  apply: (component: any, spacing: { top?: number, bottom?: number, left?: number, right?: number, all?: number }) => {
    const style: any = {}

    if (spacing.all !== undefined) {
      style.padding = spacing.all
    } else {
      if (spacing.top !== undefined) style.paddingTop = spacing.top
      if (spacing.bottom !== undefined) style.paddingBottom = spacing.bottom
      if (spacing.left !== undefined) style.paddingLeft = spacing.left
      if (spacing.right !== undefined) style.paddingRight = spacing.right
    }

    Object.assign(component, style)
  },

  /**
   * 获取边距样式
   */
  getMarginStyle: (spacing: { top?: number, bottom?: number, left?: number, right?: number, all?: number }) => {
    const style: any = {}

    if (spacing.all !== undefined) {
      style.margin = spacing.all
    } else {
      if (spacing.top !== undefined) style.marginTop = spacing.top
      if (spacing.bottom !== undefined) style.marginBottom = spacing.bottom
      if (spacing.left !== undefined) style.marginLeft = spacing.left
      if (spacing.right !== undefined) style.marginRight = spacing.right
    }

    return style
  },

  /**
   * 获取内边距样式
   */
  getPaddingStyle: (spacing: { top?: number, bottom?: number, left?: number, right?: number, all?: number }) => {
    const style: any = {}

    if (spacing.all !== undefined) {
      style.padding = spacing.all
    } else {
      if (spacing.top !== undefined) style.paddingTop = spacing.top
      if (spacing.bottom !== undefined) style.paddingBottom = spacing.bottom
      if (spacing.left !== undefined) style.paddingLeft = spacing.left
      if (spacing.right !== undefined) style.paddingRight = spacing.right
    }

    return style
  },

  /**
   * 获取响应式间距
   */
  getResponsiveSpacing: (screenWidth: number, baseSpacing: number): number => {
    if (screenWidth < Breakpoints.sm) return Math.max(Spacing.xs, baseSpacing - BASE_UNIT)
    if (screenWidth < Breakpoints.md) return baseSpacing
    return baseSpacing
  },

  /**
   * 创建对称间距
   */
  symmetric: (size: number) => {
    return {
      top: size,
      bottom: size
    }
  },

  /**
   * 创建水平对称间距
   */
  horizontal: (size: number) => {
    return {
      left: size,
      right: size
    }
  },

  /**
   * 创建垂直对称间距
   */
  vertical: (size: number) => {
    return {
      top: size,
      bottom: size
    }
  },

  /**
   * 创建全方向间距
   */
  all: (size: number) => {
    return size
  }
}

/**
 * 尺寸工具函数
 */
export const SizeUtils = {
  /**
   * 获取组件尺寸样式
   */
  getComponentSize: (width?: number, height?: number) => {
    const style: any = {}

    if (width !== undefined) style.width = width
    if (height !== undefined) style.height = height

    return style
  },

  /**
   * 获取圆形样式
   */
  getCircleStyle: (size: number) => {
    return {
      width: size,
      height: size,
      borderRadius: size / 2
    }
  },

  /**
   * 获取正方形样式
   */
  getSquareStyle: (size: number) => {
    return {
      width: size,
      height: size
    }
  },

  /**
   * 获取响应式尺寸
   */
  getResponsiveSize: (screenWidth: number, baseSize: number, maxSize?: number, minSize?: number): number => {
    let size = baseSize

    // 根据屏幕宽度调整
    if (screenWidth < Breakpoints.sm) {
      size = Math.max(minSize || 0, baseSize - BASE_UNIT * 2)
    } else if (screenWidth < Breakpoints.md) {
      size = baseSize
    } else if (screenWidth >= Breakpoints.lg && maxSize) {
      size = Math.min(maxSize, baseSize + BASE_UNIT * 2)
    }

    return size
  },

  /**
   * 创建圆角样式
   */
  getRadiusStyle: (radius: number, corners?: { topLeft?: number, topRight?: number, bottomRight?: number, bottomLeft?: number }) => {
    if (corners) {
      return {
        borderRadius: {
          topLeft: corners.topLeft || radius,
          topRight: corners.topRight || radius,
          bottomRight: corners.bottomRight || radius,
          bottomLeft: corners.bottomLeft || radius
        }
      }
    }

    return {
      borderRadius: radius
    }
  },

  /**
   * 创建阴影样式
   */
  getShadowStyle: (elevation: number) => {
    const shadowMap = {
      1: {
        radius: 2,
        offsetX: 0,
        offsetY: 1,
        color: '#00000010'
      },
      2: {
        radius: 4,
        offsetX: 0,
        offsetY: 2,
        color: '#00000015'
      },
      3: {
        radius: 6,
        offsetX: 0,
        offsetY: 4,
        color: '#00000025'
      },
      4: {
        radius: 8,
        offsetX: 0,
        offsetY: 8,
        color: '#00000040'
      }
    }

    const shadow = shadowMap[elevation] || shadowMap[2]
    return {
      shadow: {
        radius: shadow.radius,
        color: shadow.color,
        offsetX: shadow.offsetX,
        offsetY: shadow.offsetY
      }
    }
  }
}