/**
 * 实时水印覆盖层组件
 * 用于相机预览中实时显示水印效果
 */

import { WatermarkTemplate } from '../../models/WatermarkTemplate'
import { ThemeManager } from '../../theme/ThemeManager'
import { LocationData, WeatherInfo } from '../../types/AppTypes'

export interface WatermarkOverlayData {
  time?: Date
  location?: GPSLocationData
  projectInfo?: ProjectBasicInfo
  weatherInfo?: WeatherInfo
  customFields?: Record<string, string>
}

export interface GPSLocationData {
  latitude: number
  longitude: number
  address?: string
  altitude?: number
  accuracy?: number
  bearing?: number
}

export interface ProjectBasicInfo {
  name: string
  code?: string
  siteName?: string
  manager?: string
  status?: string
}

export type WatermarkPosition =
  | 'top-left' | 'top-center' | 'top-right'
  | 'center-left' | 'center' | 'center-right'
  | 'bottom-left' | 'bottom-center' | 'bottom-right'

export type WatermarkAnimation =
  | 'none' | 'fadeIn' | 'slideIn' | 'bounce'
  | 'pulse' | 'glow' | 'typing'

@ComponentV2
export struct WatermarkOverlay {
  @Require @Param template: WatermarkTemplate = new WatermarkTemplate()
  @Param overlayData: WatermarkOverlayData = {}
  @Param position: WatermarkPosition = 'bottom-right'
  @Param isVisible: boolean = true
  @Param opacity: number = 1.0
  @Param scale: number = 1.0
  @Param animation: WatermarkAnimation = 'fadeIn'
  @Param autoUpdate: boolean = true
  @Param showBackground: boolean = true
  @Param enableGestures: boolean = false
  @Param onPositionChange?: (position: WatermarkPosition) => void
  @Param onTap?: (event: ClickEvent) => void
  @Param onLongPress?: (event: LongPressEvent) => void

  @State private currentTime: Date = new Date()
  @State private currentOpacity: number = 0
  @State private currentPosition: WatermarkPosition = 'bottom-right'
  @State private isDragging: boolean = false

  private timeUpdateInterval?: number

  aboutToAppear() {
    this.currentPosition = this.position
    if (this.autoUpdate) {
      this.startTimeUpdate()
    }
    this.startAnimation()
  }

  aboutToDisappear() {
    this.stopTimeUpdate()
  }

  /**
   * 启动时间更新
   */
  private startTimeUpdate() {
    this.timeUpdateInterval = setInterval(() => {
      this.currentTime = new Date()
    }, 1000)
  }

  /**
   * 停止时间更新
   */
  private stopTimeUpdate() {
    if (this.timeUpdateInterval) {
      clearInterval(this.timeUpdateInterval)
      this.timeUpdateInterval = undefined
    }
  }

  /**
   * 启动动画效果
   */
  private startAnimation() {
    switch (this.animation) {
      case 'fadeIn':
        this.fadeInAnimation()
        break
      case 'slideIn':
        this.slideInAnimation()
        break
      case 'pulse':
        this.pulseAnimation()
        break
      case 'glow':
        this.glowAnimation()
        break
      default:
        this.currentOpacity = this.opacity
    }
  }

  /**
   * 淡入动画
   */
  private fadeInAnimation() {
    animateTo({
      duration: 500,
      curve: Curve.EaseInOut
    }, () => {
      this.currentOpacity = this.opacity
    })
  }

  /**
   * 滑入动画
   */
  private slideInAnimation() {
    animateTo({
      duration: 600,
      curve: Curve.EaseOutCubic
    }, () => {
      this.currentOpacity = this.opacity
    })
  }

  /**
   * 脉冲动画
   */
  private pulseAnimation() {
    animateTo({
      duration: 1000,
      curve: Curve.EaseInOut
    }, () => {
      this.currentOpacity = this.opacity * 0.8
    })
  }

  /**
   * 发光动画
   */
  private glowAnimation() {
    animateTo({
      duration: 1500,
      curve: Curve.EaseInOut
    }, () => {
      this.currentOpacity = this.opacity
    })
  }

  /**
   * 获取位置样式
   */
  private getPositionStyle(): { [key: string]: string | number } {
    const positions = {
      'top-left': { left: 12, top: 12, right: 'auto', bottom: 'auto' },
      'top-center': { left: '50%', top: 12, right: 'auto', bottom: 'auto', transform: 'translateX(-50%)' },
      'top-right': { right: 12, top: 12, left: 'auto', bottom: 'auto' },
      'center-left': { left: 12, top: '50%', right: 'auto', bottom: 'auto', transform: 'translateY(-50%)' },
      'center': { left: '50%', top: '50%', right: 'auto', bottom: 'auto', transform: 'translate(-50%, -50%)' },
      'center-right': { right: 12, top: '50%', left: 'auto', bottom: 'auto', transform: 'translateY(-50%)' },
      'bottom-left': { left: 12, bottom: 12, right: 'auto', top: 'auto' },
      'bottom-center': { left: '50%', bottom: 12, right: 'auto', top: 'auto', transform: 'translateX(-50%)' },
      'bottom-right': { right: 12, bottom: 12, left: 'auto', top: 'auto' }
    }
    return positions[this.currentPosition] || positions['bottom-right']
  }

  /**
   * 获取字段值
   */
  private getFieldValue(fieldKey: string): string {
    const data = this.overlayData
    const time = data.time || this.currentTime

    switch (fieldKey) {
      case 'time':
        return this.formatTime(time)
      case 'date':
        return this.formatDate(time)
      case 'datetime':
        return this.formatDateTime(time)
      case 'projectName':
        return data.projectInfo?.name || ''
      case 'projectCode':
        return data.projectInfo?.code || ''
      case 'siteName':
        return data.projectInfo?.siteName || ''
      case 'manager':
        return data.projectInfo?.manager || ''
      case 'status':
        return data.projectInfo?.status || ''
      case 'address':
        return data.location?.address || ''
      case 'coordinates':
        return this.formatCoordinates(data.location)
      case 'altitude':
        return data.location?.altitude ? `${data.location.altitude}m` : ''
      case 'accuracy':
        return data.location?.accuracy ? `±${data.location.accuracy}m` : ''
      case 'bearing':
        return data.location?.bearing ? this.formatBearing(data.location.bearing) : ''
      case 'weather':
        return data.weatherInfo?.condition || ''
      case 'temperature':
        return data.weatherInfo?.temperature ? `${data.weatherInfo.temperature}°C` : ''
      case 'humidity':
        return data.weatherInfo?.humidity ? `${data.weatherInfo?.humidity}%` : ''
      case 'windSpeed':
        return data.weatherInfo?.windSpeed ? `${data.weatherInfo.windSpeed}m/s` : ''
      case 'visibility':
        return data.weatherInfo?.visibility ? `${data.weatherInfo.visibility}km` : ''
      default:
        return data.customFields?.[fieldKey] || ''
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(date: Date): string {
    return date.toLocaleTimeString('zh-CN', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    })
  }

  /**
   * 格式化日期时间
   */
  private formatDateTime(date: Date): string {
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  }

  /**
   * 格式化坐标
   */
  private formatCoordinates(location?: LocationData): string {
    if (!location) return ''
    const lat = Math.abs(location.latitude).toFixed(6)
    const lng = Math.abs(location.longitude).toFixed(6)
    const latDir = location.latitude >= 0 ? 'N' : 'S'
    const lngDir = location.longitude >= 0 ? 'E' : 'W'
    return `${lat}°${latDir} ${lng}°${lngDir}`
  }

  /**
   * 格式化方位角
   */
  private formatBearing(bearing: number): string {
    const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北']
    const index = Math.round(bearing / 45) % 8
    return directions[index]
  }

  /**
   * 构建水印内容
   */
  @Builder
  private buildWatermarkContent() {
    Column() {
      ForEach(
        this.template.fields.filter(field => field.enabled),
        (field) => {
          const value = this.getFieldValue(field.key)
          if (value && value.trim()) {
            this.buildFieldComponent(field, value)
          }
        },
        (field) => field.key
      )
    }
    .width('100%')
    .alignItems(this.getTextAlign())
    .justifyContent(this.getFlexAlign())
    .padding(this.template.style.padding || 12)
    .backgroundColor(this.showBackground ? this.template.style.backgroundColor : Color.Transparent)
    .borderRadius(this.template.style.borderRadius || 8)
    .scale({ x: this.scale, y: this.scale })
  }

  /**
   * 构建单个字段组件
   */
  @Builder
  private buildFieldComponent(field: any, value: string) {
    Text(value)
      .fontSize(this.template.style.fontSize || 14)
      .fontColor(this.template.style.textColor || '#FFFFFF')
      .fontFamily(this.template.style.fontFamily || 'HarmonyOS Sans')
      .fontWeight(field.key === 'projectName' ? FontWeight.Medium : FontWeight.Normal)
      .textAlign(this.getTextAlign())
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .margin({ bottom: 2 })
      .opacity(this.currentOpacity)
  }

  /**
   * 获取文本对齐方式
   */
  private getTextAlign(): TextAlign {
    const position = this.currentPosition
    if (position.includes('center')) return TextAlign.Center
    if (position.includes('right')) return TextAlign.End
    return TextAlign.Start
  }

  /**
   * 获取Flex对齐方式
   */
  private getFlexAlign(): FlexAlign {
    const position = this.currentPosition
    if (position.includes('top')) return FlexAlign.Start
    if (position.includes('bottom')) return FlexAlign.End
    return FlexAlign.Center
  }

  /**
   * 处理点击事件
   */
  private handleTap() {
    if (this.onTap) {
      this.onTap({} as ClickEvent)
    }
  }

  /**
   * 处理长按事件
   */
  private handleLongPress() {
    if (this.onLongPress) {
      this.onLongPress({} as LongPressEvent)
    }
  }

  build() {
    if (this.isVisible && this.template.fields.some(field => field.enabled)) {
      Stack() {
        // 水印内容
        this.buildWatermarkContent()
          .position(this.getPositionStyle())
          .onClick(() => this.handleTap())
          .gesture(
            this.enableGestures ?
            PanGesture({ fingers: 1 })
              .onActionStart(() => {
                this.isDragging = true
              })
              .onActionUpdate((event: GestureEvent) => {
                // 这里可以实现拖拽功能
              })
              .onActionEnd(() => {
                this.isDragging = false
              }) : null
          )
          .gesture(
            LongPressGesture({ repeat: false, duration: 500 })
              .onAction(() => {
                this.handleLongPress()
              })
          )

        // 发光效果（如果启用）
        if (this.animation === 'glow') {
          this.buildGlowEffect()
        }
      }
      .width('100%')
      .height('100%')
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
    }
  }

  /**
   * 构建发光效果
   */
  @Builder
  private buildGlowEffect() {
    Column()
      .width('100%')
      .height('100%')
      .padding(this.template.style.padding || 12)
      .backgroundColor(this.template.style.textColor || '#FFFFFF')
      .borderRadius(this.template.style.borderRadius || 8)
      .opacity(0.1)
      .blur(8)
      .position(this.getPositionStyle())
      .scale({ x: this.scale * 1.2, y: this.scale * 1.2 })
  }
}

/**
 * 简化版水印覆盖层组件
 * 用于快速显示基本水印信息
 */
@ComponentV2
export struct SimpleWatermarkOverlay {
  @Param text: string = ''
  @Param position: WatermarkPosition = 'bottom-right'
  @Param backgroundColor: string = 'rgba(0, 0, 0, 0.7)'
  @Param textColor: string = '#FFFFFF'
  @Param fontSize: number = 14
  @Param isVisible: boolean = true
  @Param opacity: number = 1.0

  build() {
    if (this.isVisible && this.text.trim()) {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor(this.backgroundColor)
        .borderRadius(6)
        .opacity(this.opacity)
        .position(this.getPositionStyle())
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
    }
  }

  private getPositionStyle(): { [key: string]: string | number } {
    const positions = {
      'top-left': { left: 12, top: 12 },
      'top-center': { left: '50%', top: 12, transform: 'translateX(-50%)' },
      'top-right': { right: 12, top: 12 },
      'center-left': { left: 12, top: '50%', transform: 'translateY(-50%)' },
      'center': { left: '50%', top: '50%', transform: 'translate(-50%, -50%)' },
      'center-right': { right: 12, top: '50%', transform: 'translateY(-50%)' },
      'bottom-left': { left: 12, bottom: 12 },
      'bottom-center': { left: '50%', bottom: 12, transform: 'translateX(-50%)' },
      'bottom-right': { right: 12, bottom: 12 }
    }
    return positions[this.position] || positions['bottom-right']
  }
}