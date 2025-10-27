/**
 * 工程图标库
 * 基于 Tabler Icons 的专业 SVG 图标组件
 * 替换项目中的 emoji 图标，提供更专业的视觉效果
 */

@ComponentV2
export struct EngineeringIcon {
  @Param name: string = ''
  @Param size: number = 24
  @Param color: string = '#1890FF'
  @Param strokeWidth: number = 2

  // SVG 图标数据映射
  private getIconData(): string {
    switch (this.name) {
      // 基础图标
      case 'building':
        return 'M3 21h18v-6h-7v-6h4V3H7v6h4v6H3v6zm2-2v-2h5v2H5zm7 0v-2h5v2h-5zM9 9V5h6v4H9z'
      case 'photo':
        return 'M4 4h16a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1m1 2v12h14V6H5zm2 2l8 5-8 5V8zm2 2.8v4.4l3.5-2.2L9 10.8z'
      case 'settings':
        return 'M12 15a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm6.5-3.5l2.4-.8a1 1 0 0 0 0-1.9l-2.4-.8a7.5 7.5 0 0 0-1.4-2.4l.8-2.4a1 1 0 0 0-1.8-.8l-.8 2.4a7.5 7.5 0 0 0-2.4-1.4L11 2.5a1 1 0 0 0-1.9 0l-.8 2.4a7.5 7.5 0 0 0-2.4 1.4l-2.4-.8a1 1 0 0 0-1.8.8l.8 2.4a7.5 7.5 0 0 0-1.4 2.4L1.5 11a1 1 0 0 0 0 1.9l2.4.8a7.5 7.5 0 0 0 1.4 2.4l-.8 2.4a1 1 0 0 0 1.8.8l.8-2.4a7.5 7.5 0 0 0 2.4 1.4l.8 2.4a1 1 0 0 0 1.9 0l.8-2.4a7.5 7.5 0 0 0 2.4-1.4l2.4.8a1 1 0 0 0 1.8-.8l-.8-2.4a7.5 7.5 0 0 0 1.4-2.4z'
      case 'camera':
        return 'M12 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7zm0-1.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm9-6.5V3a1 1 0 0 0-1-1H4a1 1 0 0 0-1 1v4.5l2.4 1.8L7 10l2-1.5 2 1.5 2-1.5 2 1.5 2-1.5 2.6 1.2L21 7.5zM3 13l2.4-1.8L7 12l2-1.5 2 1.5 2-1.5 2 1.5 2-1.5 2.6 1.2L21 13v8a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-8z'
      case 'map-pin':
        return 'M12 2a7 7 0 0 0-7 7c0 1.93.78 3.68 2.05 4.95L12 22l4.95-8.05A6.98 6.98 0 0 0 19 9a7 7 0 0 0-7-7zm0 2a5 5 0 0 1 5 5c0 1.38-.56 2.63-1.46 3.54L12 17.66l-3.54-7.12A5 5 0 0 1 12 4z'
      case 'upload':
        return 'M12 4V1L8 5l4 4V6a3 3 0 1 1 0 6H9v2h3a5 5 0 0 0 0-10zm-7 8v2a5 5 0 0 0 5 5h5a5 5 0 0 0 5-5v-2h-2v2a3 3 0 0 1-3 3h-5a3 3 0 0 1-3-3v-2H5z'
      case 'refresh':
        return 'M4 12a8 8 0 0 1 8-8V2l4 4-4 4V6a6 6 0 1 0 6 6h2a8 8 0 0 1-8 8 8 8 0 0 1-8-8z'
      case 'edit':
        return 'M12 20h9M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z'
      case 'check':
        return 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
      case 'x':
        return 'M6 6l12 12M6 18L18 6'
      case 'alert-triangle':
        return 'M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0zM12 9l.01 4m-.01 3h.01'
      case 'search':
        return 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
      case 'world':
        return 'M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm1 17.93V15a1 1 0 0 0-2 0v4.93A8 8 0 0 1 4.07 14H9a1 1 0 0 0 0-2H4.07A8 8 0 0 1 11 4.07V9a1 1 0 0 0 2 0V4.07A8 8 0 0 1 19.93 12H15a1 1 0 0 0 0 2h4.93A8 8 0 0 1 13 19.93z'
      case 'lock':
        return 'M12 2a4 4 0 0 1 4 4v2h1a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1h1V6a4 4 0 0 1 4-2zm0 2a2 2 0 0 0-2 2v2h4V6a2 2 0 0 0-2-2z'
      case 'chart-bar':
        return 'M4 4h4v16H4V4zm6 0h4v10h-4V4zm6 0h4v4h-4V4z'
      case 'palette':
        return 'M12 2a10 10 0 0 0 0 20c1.3 0 2.5-.25 3.6-.7A4 4 0 0 0 20 12.4V12a10 10 0 0 0-8-9.8zm1 3.5a2.5 2.5 0 0 1 0 5 2.5 2.5 0 0 1 0-5z'
      case 'sun':
        return 'M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10zm0-2a7 7 0 1 1 0 14 7 7 0 0 1 0 14zM12 1v6m0 8v6M3.05 11h6m11.9 0h6M4.22 4.22l4.24 4.24m11.08 11.08l4.24 4.24M4.22 19.78l4.24-4.24M19.78 4.22l-4.24 4.24'
      case 'cloud':
        return 'M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z'
      case 'cloud-rain':
        return 'M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10zM7 15l2 4M11 15l2 4M15 15l2 4'
      case 'snowflake':
        return 'M12 2l2 6h6l-5 4 2 6-5-4-5 4 2-6-5-4h6l-2-6zM12 8v8M8 12h8M6 6l12 12M18 6L6 18'
      case 'mist':
        return 'M4 12h16M4 16h16M4 8h8'
      case 'info-circle':
        return 'M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zm1-11h-2v6h2v-6zm0-4h-2v2h2V7z'

      // 默认图标
      default:
        return 'M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zm1-11h-2v6h2v-6zm0-4h-2v2h2V7z'
    }
  }

  build() {
    Path()
      .commands(this.getIconData())
      .fill(Color.Transparent)
      .stroke(this.color)
      .strokeWidth(this.strokeWidth)
      .width(this.size)
      .height(this.size)
  }
}

/**
 * 创建图标的便捷函数
 */
export function createIcon(name: string, size: number = 24, color: string = '#1890FF', strokeWidth: number = 2): EngineeringIcon {
  EngineeringIcon({ name: name, size: size, color: color, strokeWidth: strokeWidth })
}