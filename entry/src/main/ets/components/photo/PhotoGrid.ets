/**
 * 照片网格组件
 * 用于展示��片网格布局
 */

import { Photo } from '../../models/Photo'

@ComponentV2
export struct PhotoGrid {
  @Param photos: Photo[] = []
  @Param columns: number = 3
  @Param spacing: number = 8
  @Param showSelection: boolean = false
  @Param selectedPhotos: Set<string> = new Set()
  @Param onPhotoClick?: (photo: Photo, index: number) => void
  @Param onPhotoLongPress?: (photo: Photo, index: number) => void
  @Param onSelectionChange?: (photoId: string, selected: boolean) => void
  @Param onLoadMore?: () => void
  @Param isLoading: boolean = false
  @Param hasMore: boolean = true

  @State private scrollOffset: number = 0

  build() {
    Column() {
      // 照片网格
      Grid() {
        ForEach(
          this.photos,
          (photo: Photo, index: number) => {
            GridItem() {
              PhotoItem({
                photo: photo,
                showSelection: this.showSelection,
                isSelected: this.selectedPhotos.has(photo.id),
                onClick: (clickedPhoto: Photo) => {
                  if (this.showSelection) {
                    const selected = this.selectedPhotos.has(photo.id)
                    this.onSelectionChange?.(photo.id, !selected)
                  } else {
                    this.onPhotoClick?.(clickedPhoto, index)
                  }
                },
                onLongPress: (pressedPhoto: Photo) => {
                  this.onPhotoLongPress?.(pressedPhoto, index)
                },
                onSelectionChange: (selected: boolean) => {
                  this.onSelectionChange?.(photo.id, selected)
                }
              })
            }
            .borderRadius(8)
            .onClick(() => {
              // 处理点击事件
            })
          },
          (photo: Photo, index: number) => `photo_${photo.id}_${index}`
        )
      }
      .columnsTemplate(`1fr `.repeat(this.columns))
      .rowsGap(this.spacing)
      .columnsGap(this.spacing)
      .padding(this.spacing)
      .onScroll((xOffset: number, yOffset: number) => {
        this.scrollOffset = yOffset
        // 检查是否接近底部
        const scrollThreshold = 100
        if (yOffset + 400 > this.photos.length / this.columns * 120 &&
            !this.isLoading && this.hasMore && this.onLoadMore) {
          this.onLoadMore()
        }
      })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 加载更多指示器
      if (this.isLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color($r('app.color.primary'))
            .margin({ right: 8 })

          Text('加载更多...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 16 })
      } else if (!this.hasMore && this.photos.length > 0) {
        Text('已加载全部照片')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}

/**
 * 自适应照片网格组件
 */
@ComponentV2
export struct AdaptivePhotoGrid {
  @Param photos: Photo[] = []
  @Param minItemWidth: number = 120
  @Param spacing: number = 8
  @Param showSelection: boolean = false
  @Param selectedPhotos: Set<string> = new Set()
  @Param onPhotoClick?: (photo: Photo, index: number) => void
  @Param onPhotoLongPress?: (photo: Photo, index: number) => void
  @Param onSelectionChange?: (photoId: string, selected: boolean) => void
  @Param onLoadMore?: () => void
  @Param isLoading: boolean = false
  @Param hasMore: boolean = true

  @State private containerWidth: number = 0
  @State private columns: number = 3

  build() {
    Column() {
      // 照片网格
      WaterFlow() {
        ForEach(
          this.photos,
          (photo: Photo, index: number) => {
            FlowItem() {
              PhotoItem({
                photo: photo,
                showSelection: this.showSelection,
                isSelected: this.selectedPhotos.has(photo.id),
                onClick: (clickedPhoto: Photo) => {
                  if (this.showSelection) {
                    const selected = this.selectedPhotos.has(photo.id)
                    this.onSelectionChange?.(photo.id, !selected)
                  } else {
                    this.onPhotoClick?.(clickedPhoto, index)
                  }
                },
                onLongPress: (pressedPhoto: Photo) => {
                  this.onPhotoLongPress?.(pressedPhoto, index)
                },
                onSelectionChange: (selected: boolean) => {
                  this.onSelectionChange?.(photo.id, selected)
                }
              })
            }
            .width('100%')
          },
          (photo: Photo, index: number) => `photo_${photo.id}_${index}`
        )
      }
      .columns('1fr')
      .rowsGap(this.spacing)
      .columnsGap(this.spacing)
      .padding(this.spacing)
      .layoutDirection(FlexDirection.Row)
      .onScroll((xOffset: number, yOffset: number) => {
        // 检查是否接近底部
        if (!this.isLoading && this.hasMore && this.onLoadMore) {
          this.onLoadMore()
        }
      })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.containerWidth = Number(newValue.width)
      this.columns = Math.max(1, Math.floor(this.containerWidth / this.minItemWidth))
    })
  }
}

/**
 * 时间线照片网格组件
 */
@ComponentV2
export struct TimelinePhotoGrid {
  @Param photos: Photo[] = []
  @Param showSelection: boolean = false
  @Param selectedPhotos: Set<string> = new Set()
  @Param onPhotoClick?: (photo: Photo, index: number) => void
  @Param onPhotoLongPress?: (photo: Photo, index: number) => void
  @Param onSelectionChange?: (photoId: string, selected: boolean) => void
  @Param onLoadMore?: () => void
  @Param isLoading: boolean = false
  @Param hasMore: boolean = true

  private getGroupedPhotos(): Map<string, Photo[]> {
    const grouped = new Map<string, Photo[]>()

    this.photos.forEach(photo => {
      const date = this.formatDateKey(photo.takenAt)
      if (!grouped.has(date)) {
        grouped.set(date, [])
      }
      grouped.get(date)?.push(photo)
    })

    return grouped
  }

  private formatDateKey(date: Date): string {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const photoDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    const diffTime = today.getTime() - photoDate.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays === 0) {
      return '今天'
    } else if (diffDays === 1) {
      return '昨天'
    } else if (diffDays < 7) {
      return `${diffDays}天前`
    } else {
      return date.toLocaleDateString()
    }
  }

  build() {
    Column() {
      // 时间线列表
      List() {
        ForEach(
          Array.from(this.getGroupedPhotos().entries()),
          ([date, photos]) => {
            ListItem() {
              Column() {
                // 日期标题
                Row() {
                  Text(date)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))

                  Blank()

                  Text(`${photos.length}张`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 16, bottom: 8 })

                // 照片网格
                Grid() {
                  ForEach(
                    photos,
                    (photo: Photo, photoIndex: number) => {
                      GridItem() {
                        PhotoItem({
                          photo: photo,
                          showSelection: this.showSelection,
                          isSelected: this.selectedPhotos.has(photo.id),
                          onClick: (clickedPhoto: Photo) => {
                            if (this.showSelection) {
                              const selected = this.selectedPhotos.has(photo.id)
                              this.onSelectionChange?.(photo.id, !selected)
                            } else {
                              const globalIndex = this.photos.indexOf(photo)
                              this.onPhotoClick?.(clickedPhoto, globalIndex)
                            }
                          },
                          onLongPress: (pressedPhoto: Photo) => {
                            const globalIndex = this.photos.indexOf(pressedPhoto)
                            this.onPhotoLongPress?.(pressedPhoto, globalIndex)
                          },
                          onSelectionChange: (selected: boolean) => {
                            this.onSelectionChange?.(photo.id, selected)
                          }
                        })
                      }
                    },
                    (photo: Photo) => `timeline_photo_${photo.id}`
                  )
                }
                .columnsTemplate('1fr 1fr 1fr')
                .rowsGap(8)
                .columnsGap(8)
                .padding({ left: 16, right: 16, bottom: 16 })
              }
            }
          },
          ([date]) => `timeline_group_${date}`
        )

        // 加载更多
        if (this.isLoading || !this.hasMore) {
          ListItem() {
            Row() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color($r('app.color.primary'))
                  .margin({ right: 8 })

                Text('加载更多...')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
              } else {
                Text('已加载全部照片')
                  .fontSize(12)
                  .fontColor($r('app.color.text_tertiary'))
              }
            }
            .width('100%')
            .height(48)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}

/**
 * 瀑布流照片网格组件
 */
@ComponentV2
export struct WaterfallPhotoGrid {
  @Param photos: Photo[] = []
  @Param columns: number = 2
  @Param spacing: number = 8
  @Param showSelection: boolean = false
  @Param selectedPhotos: Set<string> = new Set()
  @Param onPhotoClick?: (photo: Photo, index: number) => void
  @Param onPhotoLongPress?: (photo: Photo, index: number) => void
  @Param onSelectionChange?: (photoId: string, selected: boolean) => void
  @Param onLoadMore?: () => void
  @Param isLoading: boolean = false
  @Param hasMore: boolean = true

  build() {
    Column() {
      // 瀑布流网格
      Grid() {
        ForEach(
          this.photos,
          (photo: Photo, index: number) => {
            GridItem() {
              PhotoItem({
                photo: photo,
                showInfo: true,
                showSelection: this.showSelection,
                isSelected: this.selectedPhotos.has(photo.id),
                onClick: (clickedPhoto: Photo) => {
                  if (this.showSelection) {
                    const selected = this.selectedPhotos.has(photo.id)
                    this.onSelectionChange?.(photo.id, !selected)
                  } else {
                    this.onPhotoClick?.(clickedPhoto, index)
                  }
                },
                onLongPress: (pressedPhoto: Photo) => {
                  this.onPhotoLongPress?.(pressedPhoto, index)
                },
                onSelectionChange: (selected: boolean) => {
                  this.onSelectionChange?.(photo.id, selected)
                }
              })
            }
            .columnStart(index % this.columns)
            .columnSpan(1)
          },
          (photo: Photo, index: number) => `waterfall_photo_${photo.id}_${index}`
        )
      }
      .columnsTemplate(`1fr `.repeat(this.columns))
      .rowsGap(this.spacing)
      .columnsGap(this.spacing)
      .padding(this.spacing)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}