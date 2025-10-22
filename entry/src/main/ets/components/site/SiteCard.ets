/**
 * 工点卡片组件
 * 根据原型设计实现的工点信息展示卡片
 */

import { SimpleSite } from '../../models/SimpleSite'

@ComponentV2
export struct SiteCard {
  @Param site: SimpleSite = new SimpleSite()
  @Param showThumbnails: boolean = true
  @Param showLocation: boolean = true
  @Param onCamera: (site: SimpleSite) => void = () => {}
  @Param onView: (site: SimpleSite) => void = () => {}
  @Param onTap: (site: SimpleSite) => void = () => {}
  @Param onLongPress: (site: SimpleSite) => void = () => {}

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
    return ` ⛰️ ${this.site.altitude}m`
  }

  /**
   * 获取状态指示器
   */
  @Builder
  private StatusIndicator() {
    Text(this.site.getStatusText())
      .fontSize(12)
      .fontColor(this.site.getStatusColor())
      .backgroundColor(this.site.getStatusColor() + '15')
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(10)
  }

  /**
   * 缩略图预览区域
   */
  @Builder
  private ThumbnailPreview() {
    if (this.showThumbnails && this.site.hasPhotos()) {
      Row() {
        ForEach([1, 2, 3, 4], (index: number) => {
          if (index <= Math.min(this.site.photoCount, 4)) {
            Text('🖼')
              .fontSize(16)
              .backgroundColor('#F5F5F5')
              .padding(4)
              .borderRadius(4)
          } else if (index === 4 && this.site.photoCount > 4) {
            Text(`+${this.site.photoCount - 3}`)
              .fontSize(12)
              .fontColor('#8C8C8C')
              .backgroundColor('#F5F5F5')
              .padding(4)
              .borderRadius(4)
          }
        })
      }
      .margin({ top: 8 })
    }
  }

  /**
   * 位置信息区域
   */
  @Builder
  private LocationInfo() {
    if (this.showLocation && this.site.hasLocation()) {
      Text(`📌 ${this.site.getCoordinatesString()}${this.getAltitudeText()}`)
        .fontSize(12)
        .fontColor('#8C8C8C')
        .margin({ top: 4 })
    }
  }

  build() {
    Column() {
      // 主要内容区域
      Column() {
        // 工点名称
        Row() {
          Text('📍')
            .fontSize(16)
            .margin({ right: 8 })

          Text(this.site.getDisplayName())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262626')
            .layoutWeight(1)

          // 状态指示器
          this.StatusIndicator()
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 工点描述（如果有）
        if (this.site.description) {
          Text(this.site.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .width('100%')
        }

        // 地址信息
        Text(this.site.getFullAddress())
          .fontSize(12)
          .fontColor('#8C8C8C')
          .margin({ top: 4 })
          .width('100%')

        // 位置信息
        this.LocationInfo()

        // 缩略图预览
        this.ThumbnailPreview()

        // 统计信息和最后更新时间
        Row() {
          Text(`📷 ${this.site.photoCount}张照片`)
            .fontSize(12)
            .fontColor('#666666')

          Blank()

          Text(`最新: ${this.site.getLastUpdateTime()}`)
            .fontSize(12)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮区域
      Row() {
        Button('📸 拍照')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#1890FF')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(6)
          .onClick(() => {
            this.onCamera(this.site)
          })

        Blank()

        Button('👁️ 查看')
          .fontSize(14)
          .fontColor('#1890FF')
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#1890FF' })
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(6)
          .onClick(() => {
            this.onView(this.site)
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 6,
      color: '#00000015',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.handleCardClick()
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          this.handleLongPress()
        })
    )
  }
}