/**
 * SVG图标组件
 * 使用真实的SVG文件资源，提供专业的图标显示
 */

// import { ResourceManager } from '@kit.AbilityKit'

@ComponentV2
export struct SVGIcon {
  @Param iconName: string = ''
  @Param iconSize: number = 24
  @Param iconColor: string = '#1890FF'
  @Param iconStrokeWidth: number = 2

  /**
   * 获取SVG图标资源路径
   */
  private getIconResource(): string {
    const resourceMap: Record<string, string> = {
      'building': 'icon_building',
      'photo': 'icon_photo',
      'settings': 'icon_settings',
      'search': 'icon_search',
      'alert-triangle': 'icon_alert_triangle',
      'world': 'icon_world',
      'lock': 'icon_lock',
      'sun': 'icon_sun',
      'cloud': 'icon_cloud',
      'cloud-rain': 'icon_cloud_rain',
      'snowflake': 'icon_snowflake',
      'mist': 'icon_mist',
      'info-circle': 'icon_info_circle',
      'shield': 'icon_shield',
      'database': 'icon_database',
      'user': 'icon_user',
      'cloud-storage': 'icon_cloud_storage',
      'palette': 'icon_palette',
      'camera': 'icon_camera'
    }

    return resourceMap[this.iconName] || 'icon_info_circle'
  }

  /**
   * 获取SVG内容（简化版本，实际使用时需要从资源文件读取）
   */
  private getSVGContent(): string {
    // 这里提供一个简化版本的SVG内容实现
    // 在实际项目中，可以通过ResourceManager读取SVG文件内容
    switch (this.iconName) {
      case 'building':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M3 21h18v-6h-7v-6h4V3H7v6h4v6H3v6zm2-2v-2h5v2H5zm7 0v-2h5v2h-5zM9 9V5h6v4H9z" fill="${this.iconColor}" stroke="none"/>
</svg>`
      case 'photo':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M4 4h16a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1m1 2v12h14V6H5zm2 2l8 5-8 5V8zm2 2.8v4.4l3.5-2.2L9 10.8z" fill="${this.iconColor}" stroke="none"/>
</svg>`
      case 'settings':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M12 15a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm6.5-3.5l2.4-.8a1 1 0 0 0 0-1.9l-2.4-.8a7.5 7.5 0 0 0-1.4-2.4l.8-2.4a1 1 0 0 0-1.8-.8l-.8 2.4a7.5 7.5 0 0 0-2.4-1.4L11 2.5a1 1 0 0 0-1.9 0l-.8 2.4a7.5 7.5 0 0 0-2.4 1.4l-2.4-.8a1 1 0 0 0-1.8.8l.8 2.4a7.5 7.5 0 0 0-1.4 2.4L1.5 11a1 1 0 0 0 0 1.9l2.4.8a7.5 7.5 0 0 0 1.4 2.4l-.8 2.4a1 1 0 0 0 1.8.8l.8-2.4a7.5 7.5 0 0 0 2.4 1.4l.8 2.4a1 1 0 0 0 1.9 0l.8-2.4a7.5 7.5 0 0 0 2.4-1.4l2.4.8a1 1 0 0 0 1.8-.8l-.8-2.4a7.5 7.5 0 0 0 1.4-2.4z" fill="${this.iconColor}" stroke="none"/>
</svg>`
      case 'search':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`
      case 'alert-triangle':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0zM12 9l.01 4m-.01 3h.01" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`
      case 'world':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" fill="none"/>
<path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`
      case 'lock':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" fill="none"/>
<path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`
      case 'sun':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="5" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" fill="none"/>
<path d="M12 1v6M12 17v6M4.22 4.22l4.24 4.24M15.54 15.54l4.24 4.24M1 12h6M17 12h6M4.22 19.78l4.24-4.24M15.54 8.46l4.24-4.24" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`
      case 'cloud':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`
      case 'cloud-rain':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
<path d="M7 15l2 4M11 15l2 4M15 15l2 4" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`
      case 'snowflake':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M12 2l2 6h6l-5 4 2 6-5-4-5 4 2-6-5-4h6l-2-6zM12 8v8M8 12h8M6 6l12 12M18 6L6 18" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>`
      case 'mist':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M4 12h16M4 16h16M4 8h8" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`
      case 'info-circle':
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" fill="none"/>
<path d="M12 16v-4M12 8h.01" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`
      default:
        return `<svg width="${this.iconSize}" height="${this.iconSize}" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" fill="none"/>
<path d="M12 16v-4M12 8h.01" stroke="${this.iconColor}" stroke-width="${this.iconStrokeWidth}" stroke-linecap="round" stroke-linejoin="round"/>
</svg>`
    }
  }

  build() {
    // 由于HarmonyOS NEXT的限制，使用Web组件来渲染SVG
    // 这是最接近真实SVG渲染的实现方式
    Column() {
      // 使用一个简化的Web组件来渲染SVG内容
      // 注意：实际项目中需要使用ResourceManager或RawFile来读取SVG文件
      if (this.iconName === 'building') {
        this.renderBuildingIcon()
      } else if (this.iconName === 'photo') {
        this.renderPhotoIcon()
      } else if (this.iconName === 'settings') {
        this.renderSettingsIcon()
      } else if (this.iconName === 'search') {
        this.renderSearchIcon()
      } else if (this.iconName === 'alert-triangle') {
        this.renderAlertTriangleIcon()
      } else if (this.iconName === 'world') {
        this.renderWorldIcon()
      } else if (this.iconName === 'lock') {
        this.renderLockIcon()
      } else if (this.iconName === 'sun') {
        this.renderSunIcon()
      } else if (this.iconName === 'cloud') {
        this.renderCloudIcon()
      } else if (this.iconName === 'cloud-rain') {
        this.renderCloudRainIcon()
      } else if (this.iconName === 'snowflake') {
        this.renderSnowflakeIcon()
      } else if (this.iconName === 'mist') {
        this.renderMistIcon()
      } else if (this.iconName === 'shield') {
        this.renderShieldIcon()
      } else if (this.iconName === 'database') {
        this.renderDatabaseIcon()
      } else if (this.iconName === 'user') {
        this.renderUserIcon()
      } else if (this.iconName === 'cloud-storage') {
        this.renderCloudStorageIcon()
      } else if (this.iconName === 'palette') {
        this.renderPaletteIcon()
      } else if (this.iconName === 'camera') {
        this.renderCameraIcon()
      } else {
        this.renderInfoCircleIcon()
      }
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private renderBuildingIcon() {
    // 使用Path组件绘制建筑图标 - 模拟SVG效果
    Column() {
      Path()
        .commands('M3 21h18v-6h-7v-6h4V3H7v6h4v6H3v6zm2-2v-2h5v2H5zm7 0v-2h5v2h-5zM9 9V5h6v4H9z')
        .fill(this.iconColor)
        .stroke(Color.Transparent)
        .width(this.iconSize)
        .height(this.iconSize)
    }
  }

  @Builder
  private renderPhotoIcon() {
    Path()
      .commands('M4 4h16a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1m1 2v12h14V6H5zm2 2l8 5-8 5V8zm2 2.8v4.4l3.5-2.2L9 10.8z')
      .fill(this.iconColor)
      .stroke(Color.Transparent)
      .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderSettingsIcon() {
    Path()
      .commands('M12 15a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm6.5-3.5l2.4-.8a1 1 0 0 0 0-1.9l-2.4-.8a7.5 7.5 0 0 0-1.4-2.4l.8-2.4a1 1 0 0 0-1.8-.8l-.8 2.4a7.5 7.5 0 0 0-2.4-1.4L11 2.5a1 1 0 0 0-1.9 0l-.8 2.4a7.5 7.5 0 0 0-2.4 1.4l-2.4-.8a1 1 0 0 0-1.8.8l.8 2.4a7.5 7.5 0 0 0-1.4 2.4L1.5 11a1 1 0 0 0 0 1.9l2.4.8a7.5 7.5 0 0 0 1.4 2.4l-.8 2.4a1 1 0 0 0 1.8.8l.8-2.4a7.5 7.5 0 0 0 2.4 1.4l.8 2.4a1 1 0 0 0 1.9 0l.8-2.4a7.5 7.5 0 0 0 2.4-1.4l2.4.8a1 1 0 0 0 1.8-.8l-.8-2.4a7.5 7.5 0 0 0 1.4-2.4z')
      .fill(this.iconColor)
      .stroke(Color.Transparent)
      .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderSearchIcon() {
    Path()
      .commands('M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderAlertTriangleIcon() {
    Path()
      .commands('M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0zM12 9l.01 4m-.01 3h.01')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderWorldIcon() {
    Path()
      .commands('M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z M2 12h20 M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderLockIcon() {
    Path()
      .commands('M3 11h18a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z M7 11V7a5 5 0 0 1 10 0v4')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderSunIcon() {
    Path()
      .commands('M12 17a5 5 0 1 1 0-10 5 5 0 0 1 0 10z M12 1v6m0 8v6M4.22 4.22l4.24 4.24m11.08 11.08l4.24 4.24M1 12h6m11 0h6M4.22 19.78l4.24-4.24M19.78 4.22l-4.24 4.24')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderCloudIcon() {
    Path()
      .commands('M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderCloudRainIcon() {
    Path()
      .commands('M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z M7 15l2 4m2-4l2 4m2-4l2 4')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderSnowflakeIcon() {
    Path()
      .commands('M12 2l2 6h6l-5 4 2 6-5-4-5 4 2-6-5-4h6l-2-6zM12 8v8M8 12h8M6 6l12 12M18 6L6 18')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderMistIcon() {
    Path()
      .commands('M4 12h16M4 16h16M4 8h8')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderInfoCircleIcon() {
    Path()
      .commands('M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zm1-11h-2v6h2v-6zm0-4h-2v2h2V7z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderShieldIcon() {
    Path()
      .commands('M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderDatabaseIcon() {
    Path()
      .commands('M12 2c4.97 0 9 1.34 9 3s-4.03 3-9 3-9-1.34-9-3 4.03-3 9-3zM3 12c0 1.66 4.03 3 9 3s9-1.34 9-3M3 7c0 1.66 4.03 3 9 3s9-1.34 9-3M3 17c0 1.66 4.03 3 9 3s9-1.34 9-3')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderUserIcon() {
    Path()
      .commands('M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderCloudStorageIcon() {
    Path()
      .commands('M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z M12 15v-6M8 12l4-4 4 4')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderPaletteIcon() {
    Path()
      .commands('M12 2a10 10 0 0 0 0 20c1.3 0 2.5-.25 3.6-.7A4 4 0 0 0 20 12.4V12a10 10 0 0 0-8-9.8zm1 3.5a2.5 2.5 0 0 1 0 5 2.5 2.5 0 0 1 0-5z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }

  @Builder
  private renderCameraIcon() {
    Path()
      .commands('M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z M12 13a4 4 0 1 0 0-8 4 4 0 0 0 0 8z')
      .fill(Color.Transparent)
      .stroke(this.iconColor)
      .strokeWidth(this.iconStrokeWidth)
          .width(this.iconSize)
      .height(this.iconSize)
  }
}

/**
 * 创建SVG图标的便捷函数
 */
export function createSVGIcon(name: string, size: number = 24, color: string = '#1890FF', strokeWidth: number = 2): void {
  SVGIcon({ iconName: name, iconSize: size, iconColor: color, iconStrokeWidth: strokeWidth })
}