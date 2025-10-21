/**
 * 照片项组件
 * 用于在列表中展示单张照片
 */

import { Photo } from '../../models/Photo'

@ComponentV2
export struct PhotoItem {
  @Param photo: Photo = new Photo()
  @Param showSelection: boolean = false
  @Param isSelected: boolean = false
  @Param showInfo: boolean = false
  @Param onClick?: (photo: Photo) => void
  @Param onLongPress?: (photo: Photo) => void
  @Param onSelectionChange?: (selected: boolean) => void

  build() {
    Column() {
      // 照片容器
      Stack() {
        // 照片缩略图
        Image(this.photo.thumbnailPath || this.photo.filePath)
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .alt($r('app.media.ic_photo_placeholder'))
          .onClick(() => {
            this.onClick?.(this.photo)
          })
          .gesture(
            LongPressGesture({
              repeat: false,
              duration: 500
            })
              .onAction(() => {
                this.onLongPress?.(this.photo)
              })
          )

        // 选择框
        if (this.showSelection) {
          Row() {
            Blank()
            Column() {
              Checkbox({
                group: 'photo_selection',
                name: this.photo.id,
                selected: this.isSelected
              })
                .select(false)
                .selectedColor($r('app.color.primary'))
                .onChange((selected: boolean) => {
                  this.onSelectionChange?.(selected)
                })
            }
            .padding(8)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Top)
        }

        // 编辑标记
        if (this.photo.edited) {
          Row() {
            Column() {
              Image($r('app.media.ic_edit'))
                .width(16)
                .height(16)
                .fillColor(Color.White)
            }
            .width(24)
            .height(24)
            .backgroundColor($r('app.color.primary'))
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin(8)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Start)
        }

        // 加载失败占位图
        if (!this.photo.thumbnailPath && !this.photo.filePath) {
          Column() {
            Image($r('app.media.ic_photo_placeholder'))
              .width(48)
              .height(48)
              .fillColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.surface'))
          .borderRadius(8)
        }
      }

      // 照片信息
      if (this.showInfo) {
        Column() {
          // 拍摄时间
          Text(this.formatDate(this.photo.takenAt))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 项目名称
          if (this.photo.project?.name) {
            Text(this.photo.project.name)
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  private formatDate(date: Date): string {
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (days === 0) {
      return '今天'
    } else if (days === 1) {
      return '昨天'
    } else if (days < 7) {
      return `${days}天前`
    } else {
      return date.toLocaleDateString()
    }
  }
}

/**
 * 照片列表项组件（横向布局）
 */
@ComponentV2
export struct PhotoListItem {
  @Param photo: Photo = new Photo()
  @Param showSelection: boolean = false
  @Param isSelected: boolean = false
  @Param onClick?: (photo: Photo) => void
  @Param onSelectionChange?: (selected: boolean) => void

  build() {
    Row() {
      // 照片缩略图
      Image(this.photo.thumbnailPath || this.photo.filePath)
        .width(80)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .alt($r('app.media.ic_photo_placeholder'))
        .onClick(() => {
          this.onClick?.(this.photo)
        })

      // 照片信息
      Column() {
        // 文件名
        Text(this.getFileName())
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })

        // 拍摄信息
        Row() {
          Text(this.formatDate(this.photo.takenAt))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          if (this.photo.project?.name) {
            Text('·')
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ left: 4, right: 4 })
            Text(this.photo.project.name)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .margin({ bottom: 4 })

        // 文件大小
        Text(this.formatFileSize(this.photo.fileSize))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 选择框
      if (this.showSelection) {
        Checkbox({
          group: 'photo_selection',
          name: this.photo.id,
          selected: this.isSelected
        })
          .select(false)
          .selectedColor($r('app.color.primary'))
          .onChange((selected: boolean) => {
            this.onSelectionChange?.(selected)
          })
          .margin({ left: 12 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.background'))
    .borderRadius(8)
    .margin({ bottom: 8 })
  }

  private getFileName(): string {
    const path = this.photo.filePath || this.photo.thumbnailPath || ''
    return path.split('/').pop() || '未知文件'
  }

  private formatDate(date: Date): string {
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (days === 0) {
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    } else if (days === 1) {
      return '昨天'
    } else if (days < 7) {
      return `${days}天前`
    } else {
      return date.toLocaleDateString()
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
}

/**
 * 照片详情项组件
 */
@ComponentV2
export struct PhotoDetailItem {
  @Param photo: Photo = new Photo()
  @Param onEdit?: () => void
  @Param onShare?: () => void
  @Param onDelete?: () => void

  build() {
    Column() {
      // 照片预览
      Image(this.photo.filePath)
        .width('100%')
        .aspectRatio(this.photo.width / this.photo.height || 1)
        .objectFit(ImageFit.Contain)
        .backgroundColor($r('app.color.surface'))
        .alt($r('app.media.ic_photo_placeholder'))

      // 照片信息
      Column() {
        // 基本信息
        Row() {
          Text('拍摄时间')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width(80)
          Text(this.photo.takenAt.toLocaleString())
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)

        if (this.photo.project?.name) {
          Row() {
            Text('项目')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width(80)
            Text(this.photo.project.name)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(40)
          .alignItems(VerticalAlign.Center)
        }

        if (this.photo.site?.name) {
          Row() {
            Text('工点')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width(80)
            Text(this.photo.site.name)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(40)
          .alignItems(VerticalAlign.Center)
        }

        if (this.photo.address) {
          Row() {
            Text('地址')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width(80)
            Text(this.photo.address)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 4, bottom: 4 })
        }

        // 文件信息
        Divider()
          .margin({ top: 16, bottom: 16 })

        Row() {
          Text('尺寸')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width(80)
          Text(`${this.photo.width} × ${this.photo.height}`)
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)

        Row() {
          Text('大小')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width(80)
          Text(this.formatFileSize(this.photo.fileSize))
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)

        // 备注
        if (this.photo.notes) {
          Divider()
            .margin({ top: 16, bottom: 16 })

          Text('备注')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: 8 })

          Text(this.photo.notes)
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .lineHeight(20)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.background'))
      .borderRadius({ topLeft: 16, topRight: 16 })
      .margin({ top: -16 })
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
}