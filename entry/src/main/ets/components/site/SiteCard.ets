/**
 * 工点卡片组件
 * 根据原型设计实现的工点信息展示卡片，支持多种布局模式和交互效果
 */

import { SimpleSite } from '../../models/SimpleSite'
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct SiteCard {
  @Require @Param site: SimpleSite = new SimpleSite()
  @Param showThumbnails: boolean = true
  @Param showLocation: boolean = true
  @Param showTags: boolean = true // 新增标签显示
  @Param compact: boolean = false // 新增紧凑布局模式
  @Param elevation: boolean = false // 新增高程效果
  @Param showWeather: boolean = false // 新增天气显示
  @Param actionButtons: boolean = true // 新增操作按钮显示控制

  // 回调函数
  @Param onTap: (site: SimpleSite) => void = () => {}
  @Param onLongPress: (site: SimpleSite) => void = () => {}
  @Param onCamera: (site: SimpleSite) => void = () => {}
  @Param onView: (site: SimpleSite) => void = () => {}
  @Param onNavigate: (site: SimpleSite) => void = () => {} // 新增导航回调

  /**
   * 处理卡片点击
   */
  private handleCardClick(): void {
    if (this.onTap) {
      this.onTap(this.site)
    } else {
      this.onView(this.site)
    }
  }

  /**
   * 获取工点优先级颜色
   */
  private getSitePriorityColor(): string {
    // 根据照片数量确定优先级颜色
    if (this.site.photoCount === 0) return '#8C8C8C' // 灰色 - 暂无照片
    if (this.site.photoCount < 5) return '#FAAD14' // 橙色 - 需要关注
    if (this.site.photoCount < 10) return '#1890FF' // 蓝色 - 照片适中
    return '#52C41A' // 绿色 - 照片充足
  }

  /**
   * 获取工点健康状态文本
   */
  private getHealthStatusText(): string {
    if (this.site.photoCount === 0) return '需要拍摄'
    if (this.site.photoCount < 5) return '照片较少'
    if (this.site.photoCount < 10) return '照片适中'
    if (this.site.photoCount < 20) return '照片充足'
    return '照片丰富'
  }

  /**
   * 处理卡片长按
   */
  private handleLongPress(): void {
    if (this.onLongPress) {
      this.onLongPress(this.site)
    }
  }

  /**
   * 获取海拔显示文本
   */
  private getAltitudeText(): string {
    if (this.site.altitude === 0) return ''
    return `⛰️ ${this.site.altitude}m`
  }

  /**
   * 获取相对时间显示
   */
  private getRelativeTime(): string {
    const now = new Date()
    const diffMs = now.getTime() - this.site.updatedAt.getTime()
    const diffMinutes = Math.floor(diffMs / (1000 * 60))
    const diffHours = Math.floor(diffMinutes / 60)
    const diffDays = Math.floor(diffHours / 24)

    if (diffMinutes < 1) return '刚刚更新'
    else if (diffMinutes < 60) return `${diffMinutes}分钟前更新`
    else if (diffHours < 24) return `${diffHours}小时前更新`
    else if (diffDays < 7) return `${diffDays}天前更新`
    else {
      return `${this.site.updatedAt.getMonth() + 1}-${this.site.updatedAt.getDate()}更新`
    }
  }

  /**
   * 获取状态指示器
   */
  @Builder
  private StatusIndicator() {
    Row({ space: 4 }) {
      Circle({ width: 6, height: 6 })
        .fill(this.site.getStatusColor())

      Text(this.site.getStatusText())
        .fontSize(12)
        .fontColor(this.site.getStatusColor())
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(this.site.getStatusColor() + '15')
    .borderRadius(10)
  }

  /**
   * 标签区域
   */
  @Builder
  private TagsArea() {
    if (this.showTags && this.site.tags.length > 0) {
      Row({ space: 6 }) {
        ForEach(this.site.tags.slice(0, 3), (tag: string) => {
          Text(tag)
            .fontSize(10)
            .fontColor('#1890FF')
            .backgroundColor('#E6F7FF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(10)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        })

        // 如果标签数量超过3个，显示更多指示
        if (this.site.tags.length > 3) {
          Text(`+${this.site.tags.length - 3}`)
            .fontSize(10)
            .fontColor('#8C8C8C')
            .backgroundColor('#F0F0F0')
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(10)
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
  }

  /**
   * 缩略图预览区域
   */
  @Builder
  private ThumbnailPreview() {
    if (this.showThumbnails && this.site.hasPhotos()) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          ForEach([1, 2, 3, 4], (index: number) => {
            if (index <= Math.min(this.site.photoCount, 4)) {
              Column() {
                Text('🖼️')
                  .fontSize(20)
                  .fontColor('#8C8C8C')

                Text('照片')
                  .fontSize(8)
                  .fontColor('#999999')
              }
              .width(this.compact ? 40 : 50)
              .height(this.compact ? 40 : 50)
              .backgroundColor('#F8F9FA')
              .justifyContent(FlexAlign.Center)
              .borderRadius(6)
              .border({ width: 1, color: '#F0F0F0' })
            } else if (index === 4 && this.site.photoCount > 4) {
              Column() {
                Text(`+${this.site.photoCount - 3}`)
                  .fontSize(12)
                  .fontColor('#1890FF')
                  .fontWeight(FontWeight.Medium)

                Text('更多')
                  .fontSize(8)
                  .fontColor('#1890FF')
              }
              .width(this.compact ? 40 : 50)
              .height(this.compact ? 40 : 50)
              .backgroundColor('#E6F7FF')
              .justifyContent(FlexAlign.Center)
              .borderRadius(6)
              .border({ width: 1, color: '#1890FF' })
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 照片统计
        Text(`共 ${this.site.photoCount} 张照片`)
          .fontSize(10)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
      }
      .margin({ top: 8 })
      .padding(12)
      .backgroundColor('#FAFBFC')
      .borderRadius(8)
    }
  }

  /**
   * 位置信息区域
   */
  @Builder
  private LocationInfo() {
    if (this.showLocation) {
      Column({ space: 6 }) {
        // 地址信息
        Row() {
          Text('📍')
            .fontSize(12)
            .fontColor('#1890FF')

          Text(this.site.getFullAddress())
            .fontSize(12)
            .fontColor('#666666')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')

        // 坐标和海拔信息
        if (this.site.hasLocation()) {
          Row({ space: 16 }) {
            Text(`🗺️ ${this.site.getCoordinatesString()}`)
              .fontSize(10)
              .fontColor('#8C8C8C')

            if (this.site.altitude > 0) {
              Text(this.getAltitudeText())
                .fontSize(10)
                .fontColor('#8C8C8C')
            }

            // 导航按钮
            if (this.onNavigate) {
              Button('🧭')
                .fontSize(10)
                .fontColor('#1890FF')
                .backgroundColor('#E6F7FF')
                .borderRadius(10)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .onClick(() => this.onNavigate(this.site))
            }
          }
          .width('100%')
        }
      }
      .margin({ top: 8 })
      .padding(8)
      .backgroundColor('#F8F9FA')
      .borderRadius(6)
    }
  }

  build() {
    Column() {
      // 主要内容区域
      Column() {
        // 工点头部信息
        Row() {
          // 工点图标和名称
          Row() {
            Column() {
              Text('🏗️')
                .fontSize(this.compact ? 16 : 20)
                .fontColor(this.getSitePriorityColor())
            }
            .width(this.compact ? 24 : 30)
            .height(this.compact ? 24 : 30)
            .backgroundColor(this.getSitePriorityColor() + '15')
            .borderRadius(6)
            .justifyContent(FlexAlign.Center)

            Column({ space: 2 }) {
              Text(this.site.getDisplayName())
                .fontSize(this.compact ? 14 : 16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#262626')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 健康状态
              Text(this.getHealthStatusText())
                .fontSize(10)
                .fontColor(this.getSitePriorityColor())
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1)
          }
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)

          // 状态指示器
          this.StatusIndicator()
        }
        .width('100%')
        .margin({ bottom: this.compact ? 8 : 12 })

        // 工点描述（如果有）
        if (this.site.description && !this.compact) {
          Text(this.site.description)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8 })
            .width('100%')
        }

        // 位置信息
        this.LocationInfo()

        // 标签区域
        this.TagsArea()

        // 缩略图预览
        if (!this.compact) {
          this.ThumbnailPreview()
        }

        // 统计信息行
        if (!this.compact) {
          Row() {
            // 照片统计
            Row({ space: 4 }) {
              Text('📷')
                .fontSize(12)
                .fontColor('#722ED1')
              Text(`${this.site.photoCount}`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#262626')
              Text('张照片')
                .fontSize(12)
                .fontColor('#8C8C8C')
            }

            Blank()

            // 更新时间
            Text(this.getRelativeTime())
              .fontSize(10)
              .fontColor('#BFBFBF')
          }
          .width('100%')
          .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding(this.compact ? 12 : 16)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮区域
      if (this.actionButtons && !this.compact) {
        Divider()
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })
          .color('#F0F0F0')

        Row() {
          // 主要操作按钮 - 拍照
          Button() {
            Row({ space: 6 }) {
              Text('📸')
                .fontSize(14)
              Text('拍照')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(36)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#1890FF')
          .fontColor('#FFFFFF')
          .borderRadius(18)
          .onClick(() => this.onCamera(this.site))

          Blank()

          // 次要操作按钮 - 查看
          Button() {
            Row({ space: 6 }) {
              Text('👁️')
                .fontSize(14)
              Text('查看')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(36)
          .padding({ left: 16, right: 16 })
          .backgroundColor(Color.Transparent)
          .fontColor('#1890FF')
          .border({ width: 1, color: '#1890FF' })
          .borderRadius(18)
          .onClick(() => this.onView(this.site))

          // 导航按钮（如果有导航回调）
          if (this.onNavigate) {
            Button() {
              Text('🧭')
                .fontSize(14)
            }
            .width(36)
            .height(36)
            .backgroundColor('#52C41A')
            .fontColor('#FFFFFF')
            .borderRadius(18)
            .onClick(() => this.onNavigate(this.site))
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .backgroundColor(ThemeManager.getCurrentSurfaceColor())
    .borderRadius(8)
    .shadow(
      this.elevation ? {
        radius: 8,
        color: ThemeManager.getCurrentShadowColor(),
        offsetX: 0,
        offsetY: 4
      } : {
        radius: 4,
        color: '#00000015',
        offsetX: 0,
        offsetY: 2
      }
    )
    .onClick(() => {
      this.handleCardClick()
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.handleLongPress()
        })
    )
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }
}