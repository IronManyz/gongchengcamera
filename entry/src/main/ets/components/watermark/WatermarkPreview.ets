/**
 * 水印预览组件
 * 用于实时预览水印效果
 */

import { WatermarkTemplate, WatermarkField, WatermarkStyle } from '../../models/WatermarkTemplate'

@ComponentV2
export struct WatermarkPreview {
  @Param template: WatermarkTemplate = new WatermarkTemplate()
  @Param showTime: Date = new Date()
  @Param location: LocationInfo | null = null
  @Param projectInfo: ProjectInfo | null = null
  @Param weather: WeatherInfo | null = null
  @Param customFields: Record<string, string> = {}
  @Param width: number = 300
  @Param height: number = 200
  @Param backgroundOpacity: number = 0.9

  build() {
    Stack() {
      // 背景图片（预览用）
      Image($r('app.media.ic_watermark_preview'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      // 水印内容
      this.buildWatermarkContent()
    }
    .width(this.width)
    .height(this.height)
    .borderRadius(8)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  private buildWatermarkContent() {
    Column() {
      ForEach(
        this.template.fields.filter(field => field.enabled),
        (field: WatermarkField) => {
          this.buildFieldContent(field)
        },
        (field: WatermarkField) => field.key
      )
    }
    .width('100%')
    .height('100%')
    .padding(this.template.style.padding || 12)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(this.template.style.borderRadius || 8)
    .justifyContent(this.getJustifyContent())
    .alignItems(this.getAlignItems())
    .opacity(this.backgroundOpacity)
  }

  @Builder
  private buildFieldContent(field: WatermarkField) {
    const value = this.getFieldValue(field.key)
    if (value && value.trim()) {
      Text(value)
        .fontSize(this.template.style.fontSize || 14)
        .fontColor(this.template.style.textColor || '#FFFFFF')
        .fontFamily(this.template.style.fontFamily || 'HarmonyOS Sans')
        .fontWeight(field.key === 'projectName' ? FontWeight.Medium : FontWeight.Normal)
        .textAlign(TextAlign.Start)
        .width('100%')
        .margin({ bottom: 4 })
    }
  }

  private getFieldValue(fieldKey: string): string {
    switch (fieldKey) {
      case 'time':
        return this.formatTime(this.showTime)
      case 'date':
        return this.formatDate(this.showTime)
      case 'projectName':
        return this.projectInfo?.name || ''
      case 'projectCode':
        return this.projectInfo?.code || ''
      case 'siteName':
        return this.projectInfo?.siteName || ''
      case 'address':
        return this.location?.address || ''
      case 'coordinates':
        return this.formatCoordinates(this.location)
      case 'weather':
        return this.formatWeather(this.weather)
      case 'temperature':
        return this.weather?.temperature ? `${this.weather.temperature}°C` : ''
      case 'humidity':
        return this.weather?.humidity ? `${this.weather.humidity}%` : ''
      default:
        return this.customFields[fieldKey] || ''
    }
  }

  private formatTime(date: Date): string {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  }

  private formatDate(date: Date): string {
    return date.toLocaleDateString()
  }

  private formatCoordinates(location: LocationInfo | null): string {
    if (!location) return ''
    const lat = Math.abs(location.latitude).toFixed(6)
    const lng = Math.abs(location.longitude).toFixed(6)
    const latDir = location.latitude >= 0 ? 'N' : 'S'
    const lngDir = location.longitude >= 0 ? 'E' : 'W'
    return `${lat}°${latDir} ${lng}°${lngDir}`
  }

  private formatWeather(weather: WeatherInfo | null): string {
    return weather?.condition || ''
  }

  private getBackgroundColor(): ResourceStr {
    const color = this.template.style.backgroundColor || 'rgba(0, 0, 0, 0.6)'
    return color
  }

  private getJustifyContent(): FlexAlign {
    const position = this.template.style.position || 'bottom-left'
    switch (position) {
      case 'top-left':
      case 'top-right':
        return FlexAlign.Start
      case 'bottom-left':
      case 'bottom-right':
        return FlexAlign.End
      case 'center':
        return FlexAlign.Center
      default:
        return FlexAlign.End
    }
  }

  private getAlignItems(): HorizontalAlign {
    const position = this.template.style.position || 'bottom-left'
    switch (position) {
      case 'top-left':
      case 'bottom-left':
        return HorizontalAlign.Start
      case 'top-right':
      case 'bottom-right':
        return HorizontalAlign.End
      case 'center':
        return HorizontalAlign.Center
      default:
        return HorizontalAlign.Start
    }
  }
}

/**
 * 实时水印预览组件
 */
@ComponentV2
export struct LiveWatermarkPreview {
  @Param template: WatermarkTemplate = new WatermarkTemplate()
  @Param showPreview: boolean = true
  @Param location: LocationInfo | null = null
  @Param projectInfo: ProjectInfo | null = null
  @Param onTemplateChange?: (template: WatermarkTemplate) => void

  @State private currentTime: Date = new Date()
  @State private weather: WeatherInfo | null = null

  aboutToAppear() {
    this.startTimeUpdate()
    this.loadWeather()
  }

  aboutToDisappear() {
    this.stopTimeUpdate()
  }

  private timeUpdateInterval?: number

  private startTimeUpdate() {
    this.timeUpdateInterval = setInterval(() => {
      this.currentTime = new Date()
    }, 1000)
  }

  private stopTimeUpdate() {
    if (this.timeUpdateInterval) {
      clearInterval(this.timeUpdateInterval)
      this.timeUpdateInterval = undefined
    }
  }

  private async loadWeather() {
    // 这里应该调用天气服务获取实时天气
    // this.weather = await weatherService.getCurrentWeather(this.location)
  }

  build() {
    if (this.showPreview) {
      WatermarkPreview({
        template: this.template,
        showTime: this.currentTime,
        location: this.location,
        projectInfo: this.projectInfo,
        weather: this.weather,
        width: 280,
        height: 180
      })
    }
  }
}

/**
 * 水印样式预览组件
 */
@ComponentV2
export struct WatermarkStylePreview {
  @Param style: WatermarkStyle = {}
  @Param isSelected: boolean = false
  @Param onClick?: () => void

  build() {
    Column() {
      // 预览区域
      Stack() {
        // 模拟背景
        Column()
          .width('100%')
          .height(120)
          .backgroundColor($r('app.color.surface'))
          .borderRadius(8)

        // 水印样式预览
        Column() {
          Text('工程项目名称')
            .fontSize(this.style.fontSize || 14)
            .fontColor(this.style.textColor || '#FFFFFF')
            .fontWeight(FontWeight.Medium)

          Text('2024-01-15 14:30:25')
            .fontSize((this.style.fontSize || 14) - 2)
            .fontColor(this.style.textColor || '#FFFFFF')
            .margin({ top: 4 })

          Text('地址：某某省某某市某某区')
            .fontSize((this.style.fontSize || 14) - 2)
            .fontColor(this.style.textColor || '#FFFFFF')
            .margin({ top: 2 })
        }
        .width('100%')
        .padding(this.style.padding || 12)
        .backgroundColor(this.style.backgroundColor || 'rgba(0, 0, 0, 0.6)')
        .borderRadius(this.style.borderRadius || 8)
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Start)
        .margin(8)
      }

      // 样式名称
      Text(this.getStyleName())
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)

      // 选中标记
      if (this.isSelected) {
        Row() {
          Blank()
          Image($r('app.media.ic_check'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.primary'))
        }
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor(this.isSelected ? $r('app.color.primary_container') : $r('app.color.background'))
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? $r('app.color.primary') : $r('app.color.border_default')
    })
    .onClick(() => {
      this.onClick?.()
    })
  }

  private getStyleName(): string {
    // 根据样式特征返回样式名称
    if (this.style.backgroundColor?.includes('rgba(0, 0, 0')) {
      return '经典黑色'
    } else if (this.style.backgroundColor?.includes('rgba(255, 255, 255')) {
      return '纯净白色'
    } else if (this.style.backgroundColor?.includes('rgba(33, 150, 243')) {
      return '科技蓝色'
    } else {
      return '自定义样式'
    }
  }
}

/**
 * 水印字段预览组件
 */
@ComponentV2
export struct WatermarkFieldPreview {
  @Param field: WatermarkField = { key: '', label: '', enabled: true }
  @Param previewValue: string = ''
  @Param onToggle?: (enabled: boolean) => void

  build() {
    Row() {
      // 字段名称
      Text(this.field.label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      // 预览值
      if (this.field.enabled && this.previewValue) {
        Text(this.previewValue)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ right: 12 })
      }

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: this.field.enabled })
        .onChange((isOn: boolean) => {
          this.onToggle?.(isOn)
        })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 16, right: 16 })
    .backgroundColor($r('app.color.background'))
    .borderRadius(8)
    .margin({ bottom: 8 })
  }
}

// 接口定义
export interface LocationInfo {
  latitude: number
  longitude: number
  address?: string
  altitude?: number
}

export interface ProjectInfo {
  name: string
  code?: string
  siteName?: string
}

export interface WeatherInfo {
  temperature: number
  humidity: number
  condition: string
  windSpeed?: number
}