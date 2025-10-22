/**
 * 照片预览页面
 * 提供照片全屏预览、编辑和管理功能
 */

import router from '@ohos.router'
import { SimplePhoto, PhotoFilter, PresetPhotoFilters, PhotoFilterType } from '../../models/SimplePhoto'

@Entry
@ComponentV2
struct PhotoPreviewPage {
  @Local private photo: SimplePhoto = new SimplePhoto()
  @Local private isEditMode: boolean = false
  @Local private currentFilter: PhotoFilter = PresetPhotoFilters.getOriginal()
  @Local private brightnessValue: number = 0
  @Local private contrastValue: number = 0
  @Local private saturationValue: number = 0
  @Local private rotationValue: number = 0
  @Local private scaleValue: number = 1.0
  @Local private offsetXValue: number = 0
  @Local private offsetYValue: number = 0
  @Local private showInfo: boolean = false
  @Local private isLoading: boolean = false

  aboutToAppear(): void {
    this.loadRouteParams()
    this.initPhotoData()
  }

  /**
   * 加载路由参数
   */
  private loadRouteParams(): void {
    try {
      const params = router.getParams() as Record<string, Object>
      if (params && params.photo) {
        this.photo = params.photo as SimplePhoto
      } else if (params && params.photoId) {
        // TODO: 根据photoId从数据库加载照片
        this.loadMockPhotoData(params.photoId as string)
      }
    } catch (error) {
      console.error('Failed to load route params:', error)
    }
  }

  /**
   * 初始化照片数据
   */
  private initPhotoData(): void {
    // 重置编辑参数
    this.brightnessValue = 0
    this.contrastValue = 0
    this.saturationValue = 0
    this.rotationValue = 0
    this.scaleValue = 1.0
    this.offsetXValue = 0
    this.offsetYValue = 0
    this.currentFilter = PresetPhotoFilters.getOriginal()
  }

  /**
   * 加载模拟照片数据
   */
  private loadMockPhotoData(photoId: string): void {
    this.photo = new SimplePhoto(photoId, '/mock/path/' + photoId + '.jpg')
    this.photo.name = '工程照片_' + photoId
    this.photo.width = 1920
    this.photo.height = 1080
    this.photo.fileSize = 2048000
    this.photo.takenAt = new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000)
    this.photo.addTag('工程')
    this.photo.addTag('建筑')
  }

  /**
   * 返回上一页
   */
  private navigateBack(): void {
    router.back()
  }

  /**
   * 切换编辑模式
   */
  private toggleEditMode(): void {
    this.isEditMode = !this.isEditMode
    if (!this.isEditMode) {
      this.initPhotoData()
    }
  }

  /**
   * 切换信息显示
   */
  private toggleInfoDisplay(): void {
    this.showInfo = !this.showInfo
  }

  /**
   * 应用滤镜
   */
  private applyFilter(filter: PhotoFilter): void {
    this.currentFilter = filter
    // 重置其他调整参数
    this.brightnessValue = 0
    this.contrastValue = 0
    this.saturationValue = 0

    // 应用预设滤镜的强度
    switch (filter.type) {
      case PhotoFilterType.BRIGHTNESS:
        this.brightnessValue = filter.intensity / 2
        break
      case PhotoFilterType.CONTRAST:
        this.contrastValue = filter.intensity / 2
        break
      case PhotoFilterType.SATURATION:
        this.saturationValue = filter.intensity / 2
        break
      // 其他滤镜类型的实现
    }
  }

  /**
   * 旋转照片
   */
  private rotatePhoto(): void {
    this.rotationValue = (this.rotationValue + 90) % 360
  }

  /**
   * 重置编辑
   */
  private resetEdits(): void {
    this.initPhotoData()
  }

  /**
   * 保存编辑
   */
  private async saveEdits(): Promise<void> {
    this.isLoading = true
    try {
      // TODO: 实际保存编辑后的照片
      this.photo.markAsEdited()
      console.log('Photo edits saved')

      // 退出编辑模式
      this.isEditMode = false
    } catch (error) {
      console.error('Failed to save edits:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 分享照片
   */
  private sharePhoto(): void {
    console.log('Sharing photo:', this.photo.getDisplayName())
    // TODO: 实现照片分享功能
  }

  /**
   * 删除照片
   */
  private deletePhoto(): void {
    // TODO: 实现照片删除确认和删除逻辑
    console.log('Deleting photo:', this.photo.getDisplayName())
  }

  build() {
    Stack() {
      if (this.isLoading) {
        // 加载状态
        Column() {
          Text('⏳')
            .fontSize(48)
            .fontColor('#FFFFFF')
            .margin({ bottom: 16 })

          Text('保存中...')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#000000')
      } else {
        // 主内容
        Column() {
          // 顶部工具栏
          this.buildTopToolbar()

          // 照片显示区域
          Stack() {
            // 照片内容
            this.buildPhotoDisplay()

            // 信息覆盖层
            if (this.showInfo) {
              this.buildInfoOverlay()
            }

            // 编辑工具
            if (this.isEditMode) {
              this.buildEditTools()
            }
          }
          .layoutWeight(1)

          // 底部工具栏
          this.buildBottomToolbar()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
      }
    }
  }

  /**
   * 构建顶部工具栏
   */
  @Builder
  private buildTopToolbar() {
    Row() {
      // 返回按钮
      Button('←')
        .fontSize(20)
        .fontColor('#FFFFFF')
        .backgroundColor('transparent')
        .onClick(() => {
          this.navigateBack()
        })

      Blank()

      // 照片标题
      Text(this.photo.getDisplayName())
        .fontSize(16)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()

      // 功能按钮
      Row({ space: 16 }) {
        Button(this.showInfo ? 'ℹ️' : 'ℹ️')
          .fontSize(20)
          .fontColor(this.showInfo ? '#1890FF' : '#FFFFFF')
          .backgroundColor('transparent')
          .onClick(() => {
            this.toggleInfoDisplay()
          })

        Button(this.isEditMode ? '✓' : '✏️')
          .fontSize(20)
          .fontColor(this.isEditMode ? '#52C41A' : '#FFFFFF')
          .backgroundColor('transparent')
          .onClick(() => {
            if (this.isEditMode) {
              this.saveEdits()
            } else {
              this.toggleEditMode()
            }
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建照片显示
   */
  @Builder
  private buildPhotoDisplay() {
    // 模拟照片显示
    Column() {
      Text('🖼️')
        .fontSize(120)
        .fontColor('#666666')
        .margin({ bottom: 16 })

      Text(this.photo.getDisplayName())
        .fontSize(18)
        .fontColor('#FFFFFF')
        .margin({ bottom: 8 })

      Text(this.photo.getDimensionsText())
        .fontSize(14)
        .fontColor('#CCCCCC')
        .margin({ bottom: 4 })

      Text(this.photo.getFileSizeText())
        .fontSize(14)
        .fontColor('#CCCCCC')

      if (this.photo.isEdited) {
        Text('已编辑')
          .fontSize(12)
          .fontColor('#1890FF')
          .backgroundColor('#1890FF20')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .rotate({ angle: this.rotationValue })
    .scale({ x: this.scaleValue, y: this.scaleValue })
  }

  /**
   * 构建信息覆盖层
   */
  @Builder
  private buildInfoOverlay() {
    Column() {
      // 半透明背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000080')

      // 信息内容
      Column({ space: 12 }) {
        Text('📷 照片信息')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)

        // 基本信息
        Row() {
          Text('文件名:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)
          Text(this.photo.getDisplayName())
            .fontSize(14)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('尺寸:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)
          Text(this.photo.getDimensionsText())
            .fontSize(14)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('大小:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)
          Text(this.photo.getFileSizeText())
            .fontSize(14)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('拍摄时间:')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .width(80)
          Text(this.photo.getTakenTimeText())
            .fontSize(14)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('100%')

        // 位置信息
        if (this.photo.hasLocation()) {
          Row() {
            Text('位置:')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .width(80)
            Text(this.photo.getCoordinatesString())
              .fontSize(14)
              .fontColor('#FFFFFF')
              .layoutWeight(1)
          }
          .width('100%')

          if (this.photo.address) {
            Row() {
              Text('地址:')
                .fontSize(14)
                .fontColor('#CCCCCC')
                .width(80)
              Text(this.photo.address)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .layoutWeight(1)
            }
            .width('100%')
          }
        }

        // 标签
        if (this.photo.hasTags()) {
          Row() {
            Text('标签:')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .width(80)
            Row({ space: 8 }) {
              ForEach(this.photo.tags, (tag: string) => {
                Text(tag)
                  .fontSize(12)
                  .fontColor('#1890FF')
                  .backgroundColor('#1890FF20')
                  .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                  .borderRadius(8)
              })
            }
            .layoutWeight(1)
          }
          .width('100%')
        }

        // 编辑状态
        if (this.photo.isEdited) {
          Row() {
            Text('状态:')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .width(80)
            Text(this.photo.getEditedStatusText())
              .fontSize(14)
              .fontColor('#FFA500')
              .layoutWeight(1)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#00000090')
      .borderRadius(12)
      .margin(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建编辑工具
   */
  @Builder
  private buildEditTools() {
    Column() {
      Blank()

      // 编辑工具栏
      Column({ space: 16 }) {
        // 滤镜选择
        Column() {
          Text('滤镜')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ bottom: 12 })

          Scroll() {
            Row({ space: 12 }) {
              ForEach(PresetPhotoFilters.getAllPresets(), (filter: PhotoFilter) => {
                Column({ space: 4 }) {
                  Text(this.getFilterIcon(filter.type))
                    .fontSize(24)
                    .fontColor(this.currentFilter.id === filter.id ? '#1890FF' : '#FFFFFF')
                    .backgroundColor(this.currentFilter.id === filter.id ? '#FFFFFF20' : '#333333')
                    .width(50)
                    .height(50)
                    .borderRadius(25)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.applyFilter(filter)
                    })

                  Text(filter.getDisplayName())
                    .fontSize(12)
                    .fontColor(this.currentFilter.id === filter.id ? '#1890FF' : '#CCCCCC')
                    .maxLines(1)
                }
              })
            }
            .padding({ left: 20, right: 20 })
          }
          .scrollable(ScrollDirection.Horizontal)
        }

        // 调整工具
        Column({ space: 12 }) {
          // 亮度调整
          Row() {
            Text('☀️')
              .fontSize(20)
              .width(30)
            Text('亮度')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .width(60)
            Slider({
              value: this.brightnessValue,
              min: -100,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .onChange((value: number) => {
                this.brightnessValue = value
              })
            Text(`${this.brightnessValue}`)
              .fontSize(12)
              .fontColor('#CCCCCC')
              .width(40)
          }
          .width('100%')

          // 对比度调整
          Row() {
            Text('◐')
              .fontSize(20)
              .width(30)
            Text('对比度')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .width(60)
            Slider({
              value: this.contrastValue,
              min: -100,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .onChange((value: number) => {
                this.contrastValue = value
              })
            Text(`${this.contrastValue}`)
              .fontSize(12)
              .fontColor('#CCCCCC')
              .width(40)
          }
          .width('100%')

          // 饱和度调整
          Row() {
            Text('🎨')
              .fontSize(20)
              .width(30)
            Text('饱和度')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .width(60)
            Slider({
              value: this.saturationValue,
              min: -100,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .onChange((value: number) => {
                this.saturationValue = value
              })
            Text(`${this.saturationValue}`)
              .fontSize(12)
              .fontColor('#CCCCCC')
              .width(40)
          }
          .width('100%')
        }

        // 操作按钮
        Row({ space: 12 }) {
          Button('旋转')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#666666')
            .onClick(() => {
              this.rotatePhoto()
            })

          Button('重置')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF4444')
            .onClick(() => {
              this.resetEdits()
            })
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#00000090')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建底部工具栏
   */
  @Builder
  private buildBottomToolbar() {
    Column() {
      if (this.isEditMode) {
        // 编辑模式工具栏
        Row({ space: 20 }) {
          Button('取消')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#666666')
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .borderRadius(8)
            .onClick(() => {
              this.toggleEditMode()
            })

          Button('保存')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .borderRadius(8)
            .onClick(() => {
              this.saveEdits()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 20, right: 20, bottom: 20 })
      } else {
        // 查看模式工具栏
        Row({ space: 20 }) {
          Button('🔄')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .backgroundColor('#333333')
            .width(50)
            .height(50)
            .borderRadius(25)
            .onClick(() => {
              this.rotatePhoto()
            })

          Button('✏️')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .width(50)
            .height(50)
            .borderRadius(25)
            .onClick(() => {
              this.toggleEditMode()
            })

          Button('📤')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .backgroundColor('#52C41A')
            .width(50)
            .height(50)
            .borderRadius(25)
            .onClick(() => {
              this.sharePhoto()
            })

          Button('🗑️')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF4444')
            .width(50)
            .height(50)
            .borderRadius(25)
            .onClick(() => {
              this.deletePhoto()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 20, right: 20, bottom: 20 })
      }
    }
    .width('100%')
    .backgroundColor('#00000080')
  }

  /**
   * 获取滤镜图标
   */
  private getFilterIcon(filterType: PhotoFilterType): string {
    switch (filterType) {
      case PhotoFilterType.NONE:
        return '🎨'
      case PhotoFilterType.BRIGHTNESS:
        return '☀️'
      case PhotoFilterType.CONTRAST:
        return '◐'
      case PhotoFilterType.SATURATION:
        return '🌈'
      case PhotoFilterType.SEPIA:
        return '📜'
      case PhotoFilterType.GRAYSCALE:
        return '⚫'
      case PhotoFilterType.BLUR:
        return '💨'
      case PhotoFilterType.VINTAGE:
        return '📷'
      case PhotoFilterType.COLD:
        return '❄️'
      case PhotoFilterType.WARM:
        return '🔥'
      default:
        return '🎨'
    }
  }
}