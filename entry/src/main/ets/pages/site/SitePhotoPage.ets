/**
 * 工点照片页面
 * 显示指定工点的所有照片列表
 */

import router from '@ohos.router'
import { SimplePhoto } from '../../models/SimplePhoto'

@Entry
@ComponentV2
struct SitePhotoPage {
  @Local private siteId: string = ''
  @Local private siteName: string = ''
  @Local private projectId: string = ''
  @Local private photos: SimplePhoto[] = []
  @Local private isLoading: boolean = false
  @Local private selectedPhotos: SimplePhoto[] = []
  @Local private isSelectionMode: boolean = false
  @Local private sortBy: 'date' | 'name' | 'size' = 'date'
  @Local private sortOrder: 'asc' | 'desc' = 'desc'

  aboutToAppear(): void {
    this.loadRouteParams()
    this.loadPhotos()
  }

  /**
   * 加载路由参数
   */
  private loadRouteParams(): void {
    try {
      const params = router.getParams() as Record<string, Object>
      if (params) {
        this.siteId = (params.siteId as string) || ''
        this.siteName = (params.siteName as string) || ''
        this.projectId = (params.projectId as string) || ''
      }
    } catch (error) {
      console.error('Failed to load route params:', error)
    }
  }

  /**
   * 加载照片列表
   */
  private async loadPhotos(): Promise<void> {
    this.isLoading = true
    try {
      // TODO: 从数据库加载工点照片
      // 临时使用模拟数据
      this.photos = this.generateMockPhotos()
      this.sortPhotos()
    } catch (error) {
      console.error('Failed to load photos:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 生成模拟照片数据
   */
  private generateMockPhotos(): SimplePhoto[] {
    const mockPhotos: SimplePhoto[] = []
    const photoCount = Math.floor(Math.random() * 20) + 5

    for (let i = 0; i < photoCount; i++) {
      const photo = new SimplePhoto(
        `photo_${i + 1}`,
        `/mock/path/site_${this.siteId}/photo_${i + 1}.jpg`,
        this.projectId,
        this.siteId
      )

      photo.name = `${this.siteName}_照片_${i + 1}`
      photo.width = 1920
      photo.height = 1080
      photo.fileSize = Math.floor(Math.random() * 5000000) + 1000000
      photo.takenAt = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000)

      // 随机位置信息
      if (Math.random() > 0.3) {
        photo.latitude = 39.915 + Math.random() * 0.1
        photo.longitude = 116.404 + Math.random() * 0.1
        photo.address = `${this.siteName}附近`
      }

      // 随机标签
      const tags = ['工程', '建筑', '施工', '质量', '安全', '进度']
      photo.addTag(tags[Math.floor(Math.random() * tags.length)])

      // 随机编辑状态
      if (Math.random() > 0.7) {
        photo.markAsEdited()
      }

      mockPhotos.push(photo)
    }

    return mockPhotos
  }

  /**
   * 排序照片
   */
  private sortPhotos(): void {
    this.photos.sort((a, b) => {
      let result = 0

      switch (this.sortBy) {
        case 'date':
          result = a.takenAt.getTime() - b.takenAt.getTime()
          break
        case 'name':
          result = a.getDisplayName().localeCompare(b.getDisplayName())
          break
        case 'size':
          result = a.fileSize - b.fileSize
          break
      }

      return this.sortOrder === 'asc' ? result : -result
    })
  }

  /**
   * 返回上一页
   */
  private navigateBack(): void {
    router.back()
  }

  /**
   * 切换选择模式
   */
  private toggleSelectionMode(): void {
    this.isSelectionMode = !this.isSelectionMode
    if (!this.isSelectionMode) {
      this.selectedPhotos = []
    }
  }

  /**
   * 选择/取消选择照片
   */
  private togglePhotoSelection(photo: SimplePhoto): void {
    const index = this.selectedPhotos.findIndex(p => p.id === photo.id)
    if (index > -1) {
      this.selectedPhotos.splice(index, 1)
    } else {
      this.selectedPhotos.push(photo)
    }
  }

  /**
   * 检查照片是否被选中
   */
  private isPhotoSelected(photo: SimplePhoto): boolean {
    return this.selectedPhotos.some(p => p.id === photo.id)
  }

  /**
   * 选择所有照片
   */
  private selectAllPhotos(): void {
    this.selectedPhotos = [...this.photos]
  }

  /**
   * 取消选择所有照片
   */
  private deselectAllPhotos(): void {
    this.selectedPhotos = []
  }

  /**
   * 删除选中的照片
   */
  private deleteSelectedPhotos(): void {
    if (this.selectedPhotos.length === 0) return

    // TODO: 实现照片删除确认和删除逻辑
    console.log(`Deleting ${this.selectedPhotos.length} photos`)

    // 从列表中移除
    this.photos = this.photos.filter(photo =>
      !this.selectedPhotos.some(selected => selected.id === photo.id)
    )

    // 清空选择
    this.selectedPhotos = []
    this.isSelectionMode = false
  }

  /**
   * 分享选中的照片
   */
  private shareSelectedPhotos(): void {
    if (this.selectedPhotos.length === 0) return

    console.log(`Sharing ${this.selectedPhotos.length} photos`)
    // TODO: 实现照片分享功能
  }

  /**
   * 预览照片
   */
  private previewPhoto(photo: SimplePhoto): void {
    router.pushUrl({
      url: 'pages/photo/PhotoPreviewPage',
      params: {
        photo: photo
      }
    }).catch((error: Error) => {
      console.error('跳转到照片预览失败:', error)
    })
  }

  /**
   * 拍照
   */
  private takePhoto(): void {
    router.pushUrl({
      url: 'pages/camera/CameraPage_Simple',
      params: {
        projectId: this.projectId,
        siteId: this.siteId,
        siteName: this.siteName
      }
    }).catch((error: Error) => {
      console.error('跳转到相机失败:', error)
    })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        if (this.isSelectionMode) {
          // 选择模式导航栏
          Button('✕')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .backgroundColor('transparent')
            .onClick(() => {
              this.toggleSelectionMode()
            })

          Blank()

          Text(`已选择 ${this.selectedPhotos.length} 张`)
            .fontSize(16)
            .fontColor('#FFFFFF')

          Blank()

          if (this.selectedPhotos.length > 0) {
            Row({ space: 12 }) {
              Button('🗑️')
                .fontSize(20)
                .fontColor('#FF4444')
                .backgroundColor('transparent')
                .onClick(() => {
                  this.deleteSelectedPhotos()
                })

              Button('📤')
                .fontSize(20)
                .fontColor('#1890FF')
                .backgroundColor('transparent')
                .onClick(() => {
                  this.shareSelectedPhotos()
                })
            }
          }
        } else {
          // 查看模式导航栏
          Button('←')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .backgroundColor('transparent')
            .onClick(() => {
              this.navigateBack()
            })

          Blank()

          Text(this.siteName || '工点照片')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()

          Row({ space: 12 }) {
            Button('📸')
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('transparent')
              .onClick(() => {
                this.takePhoto()
              })

            Button('☑️')
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('transparent')
              .onClick(() => {
                this.toggleSelectionMode()
              })
          }
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E8E8E8' })

      // 工点信息区域
      if (!this.isSelectionMode) {
        Row() {
          Column() {
            Text('📍')
              .fontSize(16)
              .margin({ bottom: 4 })

            Text(`${this.photos.length} 张照片`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .layoutWeight(1)

          // 排序选项
          Row({ space: 8 }) {
            Text('排序:')
              .fontSize(14)
              .fontColor('#666666')

            Button(this.sortBy === 'date' ? '时间' : this.sortBy === 'name' ? '名称' : '大小')
              .fontSize(14)
              .fontColor('#1890FF')
              .backgroundColor('#F5F5F5')
              .onClick(() => {
                if (this.sortBy === 'date') {
                  this.sortBy = 'name'
                } else if (this.sortBy === 'name') {
                  this.sortBy = 'size'
                } else {
                  this.sortBy = 'date'
                }
                this.sortPhotos()
              })

            Button(this.sortOrder === 'desc' ? '↓' : '↑')
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .width(24)
              .height(24)
              .onClick(() => {
                this.sortOrder = this.sortOrder === 'desc' ? 'asc' : 'desc'
                this.sortPhotos()
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')
      }

      // 照片列表
      if (this.isLoading) {
        Column() {
          Text('⏳')
            .fontSize(48)
            .fontColor('#C0C0C0')
            .margin({ bottom: 16 })

          Text('加载照片中...')
            .fontSize(16)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F5F5')
      } else if (this.photos.length === 0) {
        Column() {
          Text('📷')
            .fontSize(64)
            .fontColor('#C0C0C0')
            .margin({ bottom: 16 })

          Text('暂无照片')
            .fontSize(18)
            .fontColor('#8C8C8C')
            .margin({ bottom: 8 })

          Text('点击相机按钮拍摄第一张照片')
            .fontSize(14)
            .fontColor('#BFBFBF')
            .margin({ bottom: 20 })

          Button('📸 开始拍照')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .borderRadius(8)
            .onClick(() => {
              this.takePhoto()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F5F5')
      } else {
        this.buildPhotoGrid()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建照片网格
   */
  @Builder
  private buildPhotoGrid() {
    Grid() {
      ForEach(this.photos, (photo: SimplePhoto) => {
        GridItem() {
          this.buildPhotoItem(photo)
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .padding(12)
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建照片项
   */
  @Builder
  private buildPhotoItem(photo: SimplePhoto) {
    Stack() {
      // 照片缩略图
      Column() {
        // 模拟照片显示
        Column() {
          Text('🖼️')
            .fontSize(32)
            .fontColor('#CCCCCC')
            .margin({ bottom: 4 })

          Text(photo.getRelativeTimeText())
            .fontSize(10)
            .fontColor('#999999')
            .maxLines(1)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
      }

      // 选择指示器
      if (this.isSelectionMode) {
        Row() {
          Blank()
          Column() {
            Circle({ width: 20, height: 20 })
              .fill(this.isPhotoSelected(photo) ? '#1890FF' : '#00000060')
              .stroke(Color.White)
              .strokeWidth(2)
              .margin(8)

            if (this.isPhotoSelected(photo)) {
              Text('✓')
                .fontSize(12)
                .fontColor(Color.White)
                .position({ x: 0, y: -15 })
                .width(20)
                .textAlign(TextAlign.Center)
            }
          }
        }
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.togglePhotoSelection(photo)
        })
      } else {
        Stack()
          .onClick(() => {
            this.previewPhoto(photo)
          })
      }

      // 状态指示器
      if (photo.isEdited) {
        Text('✏️')
          .fontSize(12)
          .fontColor('#1890FF')
          .backgroundColor('#FFFFFF')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(4)
          .position({ x: 4, y: 4 })
      }

      if (photo.hasLocation()) {
        Text('📍')
          .fontSize(12)
          .fontColor('#52C41A')
          .backgroundColor('#FFFFFF')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(4)
          .position({ x: 4, y: 20 })
      }
    }
    .width('100%')
    .aspectRatio(1)
  }
}