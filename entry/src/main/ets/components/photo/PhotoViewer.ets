/**
 * 照片查看器组件
 * 提供照片的全屏查看和缩放功能
 */

import { Photo } from '../../models/Photo'

@ComponentV2
export struct PhotoViewer {
  @Param show: boolean = false
  @Param photos: Photo[] = []
  @Param currentIndex: number = 0
  @Param showInfo: boolean = false
  @Param onIndexChange?: (index: number) => void
  @Param onClose?: () => void
  @Param onEdit?: (photo: Photo) => void
  @Param onShare?: (photo: Photo) => void
  @Param onDelete?: (photo: Photo) => void

  @State private scale: number = 1
  @State private offsetX: number = 0
  @State private offsetY: number = 0
  @State private minScale: number = 1
  @State private maxScale: number = 3
  @State private currentPhoto: Photo = new Photo()

  aboutToAppear() {
    if (this.photos.length > 0 && this.currentIndex >= 0) {
      this.currentPhoto = this.photos[this.currentIndex]
    }
  }

  @Monitor('currentIndex')
  onCurrentIndexChange() {
    if (this.photos.length > 0 && this.currentIndex >= 0 && this.currentIndex < this.photos.length) {
      this.currentPhoto = this.photos[this.currentIndex]
      this.resetTransform()
    }
  }

  build() {
    if (this.show) {
      Stack() {
        // 背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)

        // 照片内容
        Column() {
          // 顶部栏
          Row() {
            // 返回按钮
            Button() {
              Image($r('app.media.ic_back'))
                .width(24)
                .height(24)
                .fillColor(Color.White)
            }
            .width(40)
            .height(40)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.onClose?.()
            })

            Blank()

            // 索引信息
            if (this.photos.length > 1) {
              Text(`${this.currentIndex + 1} / ${this.photos.length}`)
                .fontSize(16)
                .fontColor(Color.White)
            }

            Blank()

            // 更多按钮
            Button() {
              Image($r('app.media.ic_more'))
                .width(24)
                .height(24)
                .fillColor(Color.White)
            }
            .width(40)
            .height(40)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.showMoreOptions()
            })
          }
          .width('100%')
          .height(56)
          .padding({ left: 8, right: 8 })
          .zIndex(10)

          // 照片显示区域
          Stack() {
            if (this.photos.length > 0) {
              Swiper() {
                ForEach(
                  this.photos,
                  (photo: Photo, index: number) => {
                    this.buildPhotoItem(photo, index)
                  },
                  (photo: Photo, index: number) => `viewer_photo_${photo.id}_${index}`
                )
              }
              .width('100%')
              .height('100%')
              .index(this.currentIndex)
              .loop(false)
              .indicator(false)
              .itemSpace(20)
              .onChange((index: number) => {
                this.currentIndex = index
                this.onIndexChange?.(index)
              })
            }
          }
          .layoutWeight(1)

          // 底部信息栏
          if (this.showInfo && this.currentPhoto) {
            this.buildInfoBar()
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(2000)
    }
  }

  @Builder
  private buildPhotoItem(photo: Photo, index: number) {
    Stack() {
      // 照片图片
      Image(photo.filePath)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .alt($r('app.media.ic_photo_placeholder'))
        .scale({ x: this.scale, y: this.scale })
        .translate({ x: this.offsetX, y: this.offsetY })
        .gesture(
          // 缩放手势
          PinchGesture({ fingers: 2 })
            .onActionStart(() => {
              // 记录开始缩放
            })
            .onActionUpdate((event: GestureEvent) => {
              if (event.scale) {
                const newScale = this.scale * event.scale
                this.scale = Math.max(this.minScale, Math.min(this.maxScale, newScale))
              }
            })
            .onActionEnd(() => {
              // 缩放结束，检查是否需要重置
              if (this.scale < this.minScale) {
                this.scale = this.minScale
                this.resetTransform()
              }
            })
        )
        .gesture(
          // 拖拽手势
          PanGesture()
            .onActionUpdate((event: GestureEvent) => {
              if (this.scale > this.minScale) {
                this.offsetX += event.offsetX
                this.offsetY += event.offsetY
              }
            })
            .onActionEnd(() => {
              // 拖拽结束，检查边界
              this.checkBounds()
            })
        )
        .gesture(
          // 双击缩放
          TapGesture({ count: 2 })
            .onAction(() => {
              if (this.scale === this.minScale) {
                this.scale = 2
              } else {
                this.scale = this.minScale
                this.resetTransform()
              }
            })
        )
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildInfoBar() {
    Column() {
      // 拍摄信息
      Row() {
        Column() {
          Text(this.currentPhoto.takenAt.toLocaleString())
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)

          if (this.currentPhoto.project?.name) {
            Text(this.currentPhoto.project.name)
              .fontSize(14)
              .fontColor('rgba(255, 255, 255, 0.8)')
              .margin({ top: 4 })
          }

          if (this.currentPhoto.address) {
            Text(this.currentPhoto.address)
              .fontSize(12)
              .fontColor('rgba(255, 255, 255, 0.6)')
              .margin({ top: 2 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row() {
          // 编辑按钮
          Button() {
            Image($r('app.media.ic_edit'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
          }
          .width(40)
          .height(40)
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .borderRadius(20)
          .margin({ right: 8 })
          .onClick(() => {
            this.onEdit?.(this.currentPhoto)
          })

          // 分享按钮
          Button() {
            Image($r('app.media.ic_share'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
          }
          .width(40)
          .height(40)
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .borderRadius(20)
          .onClick(() => {
            this.onShare?.(this.currentPhoto)
          })
        }
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .backgroundColor('rgba(0, 0, 0, 0.8)')
  }

  private resetTransform() {
    this.scale = this.minScale
    this.offsetX = 0
    this.offsetY = 0
  }

  private checkBounds() {
    // 这里可以添加边界检查逻辑
    // 防止图片缩放后拖拽超出边界
  }

  private showMoreOptions() {
    // 显示更多选项，如删除、查看详情等
    const options = [
      { text: '查看详情', action: () => this.showPhotoDetails() },
      { text: '删除', action: () => this.deletePhoto() },
      { text: '设为封面', action: () => this.setAsCover() }
    ]

    // 这里可以使用系统选择器或自定义弹窗
  }

  private showPhotoDetails() {
    // 显示照片详情页面
  }

  private deletePhoto() {
    // 删除照片
    AlertDialog.show({
      title: '删除确认',
      message: '确定要删除这张照片吗？',
      primaryButton: {
        value: '删除',
        action: () => {
          this.onDelete?.(this.currentPhoto)
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    })
  }

  private setAsCover() {
    // 设置为封面
  }
}

/**
 * 简化版照片查看器
 */
@ComponentV2
export struct SimplePhotoViewer {
  @Param show: boolean = false
  @Param photo: Photo = new Photo()
  @Param onClose?: () => void

  build() {
    if (this.show) {
      Stack() {
        // 背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)
          .onClick(() => {
            this.onClose?.()
          })

        // 照片
        Image(this.photo.filePath)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .alt($r('app.media.ic_photo_placeholder'))

        // 关闭按钮
        Button() {
          Image($r('app.media.ic_close'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .borderRadius(20)
        .position({ x: 16, y: 60 })
        .onClick(() => {
          this.onClose?.()
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(2000)
    }
  }
}

/**
 * 照片预览组件（用于缩略图预览）
 */
@ComponentV2
export struct PhotoPreview {
  @Param show: boolean = false
  @Param photo: Photo = new Photo()
  @Param onClose?: () => void
  @Param onFullView?: (photo: Photo) => void

  build() {
    if (this.show) {
      Stack() {
        // 遮罩背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.8)')
          .onClick(() => {
            this.onClose?.()
          })

        // 照片预览
        Column() {
          Image(this.photo.filePath)
            .width(300)
            .height(400)
            .objectFit(ImageFit.Contain)
            .borderRadius(8)
            .shadow({
              radius: 20,
              color: 'rgba(0, 0, 0, 0.5)',
              offsetX: 0,
              offsetY: 10
            })
            .onClick(() => {
              this.onFullView?.(this.photo)
            })

          // 照片信息
          if (this.photo.project?.name) {
            Text(this.photo.project.name)
              .fontSize(14)
              .fontColor(Color.White)
              .margin({ top: 12 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          Text(this.photo.takenAt.toLocaleDateString())
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.8)')
            .margin({ top: 4 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1500)
    }
  }
}