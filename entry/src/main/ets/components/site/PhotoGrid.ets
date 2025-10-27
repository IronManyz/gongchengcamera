/**
 * 照片网格组件
 * 用于展示工点的照片缩略图，支持网格布局和点击交互
 */

import { photoStore } from '../../store/photo/PhotoStore'
import { Photo } from '../../models/Photo'
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct PhotoGrid {
  @Require @Param siteId: string = ''
  @Param maxPhotos: number = 4
  @Param onPhotoClick: (photo: Photo) => void = () => {}
  @Param onMoreClick: () => void = () => {}
  @Param compact: boolean = false
  @State private photos: Photo[] = []
  @State private isLoading: boolean = false

  async aboutToAppear() {
    await this.loadPhotos()
  }

  /**
   * 加载工点照片
   */
  private async loadPhotos(): Promise<void> {
    if (!this.siteId) {
      return
    }

    this.isLoading = true
    try {
      this.photos = await photoStore.getPhotosBySite(this.siteId, this.maxPhotos)
    } catch (error) {
      console.error('加载工点照片失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 处理照片点击
   */
  private handlePhotoClick(photo: Photo): void {
    if (this.onPhotoClick) {
      this.onPhotoClick(photo)
    }
  }

  /**
   * 处理更多点击
   */
  private handleMoreClick(): void {
    if (this.onMoreClick) {
      this.onMoreClick()
    }
  }

  build() {
    Column() {
      // 网格标题
      Row() {
        Text('现场照片')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.getCurrentTextColor())

        Blank()

        if (this.photos.length > this.maxPhotos && this.onMoreClick) {
          Text(`查看全部 (${this.photos.length})`)
            .fontSize(12)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .onClick(() => this.handleMoreClick())
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 照片网格
      if (this.isLoading) {
        // 加载状态
        Column() {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(ThemeManager.getCurrentPrimaryColor())

            Text('加载照片中...')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 32, bottom: 32 })
        }
        .width('100%')
        .height(160)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
      } else if (this.photos.length === 0) {
        // 空状态
        Column() {
          Text('📷')
            .fontSize(32)
            .fontColor('#C0C0C0')
            .margin({ bottom: 12 })

          Text('暂无照片')
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 24, bottom: 24 })
        .height(160)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
      } else {
        // 照片网格布局
        Grid() {
          ForEach(this.photos, (photo: Photo, index?: number) => {
            GridItem() {
              Column() {
                // 照片容器
                Stack() {
                  // 照片背景
                  if (index === 0) {
                    // 第一张大图展示
                    Image(photo.getThumbnailPath())
                      .width('100%')
                      .height(120)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                      .onClick(() => this.handlePhotoClick(photo))
                  }
                }
                .width('100%')
                .aspectRatio(1)
                .margin({ bottom: 8 })
                .borderRadius(8)
                .backgroundColor('#FFFFFF')
                .shadow({
                  radius: 4,
                  color: '#00000015',
                  offsetX: 0,
                  offsetY: 2
                })
              }

              // 照片编号（如果是缩略图）
              if (this.compact && index && index > 0) {
                Text(`${index + 1}`)
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
                  .position({ x: '8%', y: '8%' })
                  .textAlign(TextAlign.Center)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .backgroundColor('#00000080')
                  .borderRadius(8)
              }
            }
            .onClick(() => this.handlePhotoClick(photo))
          }
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width('100%')
        .height(this.compact ? 80 : 160)
        .padding({ left: 0, right: 0, top: 0, bottom: 12 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}