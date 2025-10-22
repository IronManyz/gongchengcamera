/**
 * 相册页面
 * 提供照片浏览、搜索、筛选和管理功能
 */

import router from '@ohos.router'

interface PhotoItem {
  id: string
  name: string
  project: string
  site: string
  date: string
  size: string
  thumbnail?: string
}

@Entry
@Component
struct GalleryPage {
  @State private viewMode: 'grid' | 'list' = 'grid'
  @State private selectedPhotos: string[] = []
  @State private searchQuery: string = ''
  @State private selectedFilter: string = '全部'

  private filters = ['全部', '今天', '本周', '本月', '工程A', '工程B']

  // 模拟照片数据
  private photos: PhotoItem[] = [
    {
      id: '1',
      name: 'IMG_001.jpg',
      project: '工程A',
      site: '工点1',
      date: '2024-01-15',
      size: '2.4 MB'
    },
    {
      id: '2',
      name: 'IMG_002.jpg',
      project: '工程A',
      site: '工点2',
      date: '2024-01-15',
      size: '1.8 MB'
    },
    {
      id: '3',
      name: 'IMG_003.jpg',
      project: '工程B',
      site: '工点1',
      date: '2024-01-14',
      size: '3.1 MB'
    },
    {
      id: '4',
      name: 'IMG_004.jpg',
      project: '工程B',
      site: '工点3',
      date: '2024-01-14',
      size: '2.7 MB'
    },
    {
      id: '5',
      name: 'IMG_005.jpg',
      project: '工程C',
      site: '工点1',
      date: '2024-01-13',
      size: '2.2 MB'
    },
    {
      id: '6',
      name: 'IMG_006.jpg',
      project: '工程C',
      site: '工点2',
      date: '2024-01-13',
      size: '2.9 MB'
    }
  ]

  build() {
    Column() {
      // 头部导航
      Row() {
        Button('← 返回')
          .fontSize(16)
          .fontColor('#1890FF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back()
          })

        Text('相册')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 视图切换
        Row({ space: 12 }) {
          Text(this.viewMode === 'grid' ? '📱' : '📋')
            .fontSize(20)
            .fontColor('#1890FF')
            .onClick(() => {
              this.viewMode = this.viewMode === 'grid' ? 'list' : 'grid'
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 搜索和筛选栏
      Column() {
        // 搜索框
        Row() {
          Text('🔍')
            .fontSize(16)
            .fontColor('#8C8C8C')
            .margin({ right: 8 })

          TextInput({ placeholder: '搜索照片、工程或工点...' })
            .fontSize(14)
            .fontColor('#262626')
            .placeholderColor('#C0C0C0')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 8, right: 8 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchQuery = value
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .margin({ bottom: 12 })

        // 筛选标签
        Row({ space: 8 }) {
          ForEach(this.filters, (filter: string) => {
            Text(filter)
              .fontSize(14)
              .fontColor(this.selectedFilter === filter ? '#FFFFFF' : '#1890FF')
              .backgroundColor(this.selectedFilter === filter ? '#1890FF' : '#F0F9FF')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => {
                this.selectedFilter = filter
              })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 统计信息
      Row() {
        Text(`${this.photos.length} 张照片`)
          .fontSize(14)
          .fontColor('#8C8C8C')

        Blank()

        if (this.selectedPhotos.length > 0) {
          Text(`已选择 ${this.selectedPhotos.length} 张`)
            .fontSize(14)
            .fontColor('#1890FF')
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // 照片展示区域
      Scroll() {
        if (this.viewMode === 'grid') {
          // 网格视图
          Grid() {
            ForEach(this.photos, (photo: PhotoItem) => {
              GridItem() {
                Column() {
                  // 照片缩略图占位符
                  Stack() {
                    Text('📷')
                      .fontSize(24)
                      .fontColor('#C0C0C0')

                    // 选择框
                    if (this.selectedPhotos.includes(photo.id)) {
                      Stack() {
                        Circle({ width: 20, height: 20 })
                          .fill('#1890FF')
                        Text('✓')
                          .fontSize(12)
                          .fontColor('#FFFFFF')
                      }
                      .position({ x: 8, y: 8 })
                    }
                  }
                  .width('100%')
                  .height(120)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .margin({ bottom: 8 })
                  .onClick(() => {
                    if (this.selectedPhotos.includes(photo.id)) {
                      this.selectedPhotos = this.selectedPhotos.filter(id => id !== photo.id)
                    } else {
                      this.selectedPhotos.push(photo.id)
                    }
                  })

                  // 照片信息
                  Column() {
                    Text(photo.name)
                      .fontSize(12)
                      .fontColor('#262626')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')

                    Text(`${photo.project} - ${photo.site}`)
                      .fontSize(10)
                      .fontColor('#8C8C8C')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .margin({ top: 2 })

                    Text(photo.date)
                      .fontSize(10)
                      .fontColor('#C0C0C0')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                }
                .padding(8)
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .padding({ left: 16, right: 16, bottom: 16 })
        } else {
          // 列表视图
          Column({ space: 1 }) {
            ForEach(this.photos, (photo: PhotoItem) => {
              Row() {
                // 照片缩略图占位符
                Text('📷')
                  .fontSize(20)
                  .fontColor('#C0C0C0')
                  .margin({ right: 12 })
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(4)

                Column() {
                  Text(photo.name)
                    .fontSize(14)
                    .fontColor('#262626')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row() {
                    Text(`${photo.project} - ${photo.site}`)
                      .fontSize(12)
                      .fontColor('#8C8C8C')
                    Blank()
                    Text(photo.size)
                      .fontSize(12)
                      .fontColor('#C0C0C0')
                  }
                  .width('100%')
                  .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(photo.date)
                  .fontSize(12)
                  .fontColor('#C0C0C0')
              }
              .width('100%')
              .padding(16)
              .alignItems(VerticalAlign.Center)
              .backgroundColor('#FFFFFF')
              .onClick(() => {
                console.log('Photo clicked:', photo.name)
              })
            })
          }
          .width('100%')
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 底部操作栏
      if (this.selectedPhotos.length > 0) {
        Row() {
          Button('全选')
            .fontSize(14)
            .fontColor('#1890FF')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (this.selectedPhotos.length === this.photos.length) {
                this.selectedPhotos = []
              } else {
                this.selectedPhotos = this.photos.map(photo => photo.id)
              }
            })

          Blank()

          Button('删除')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF4D4F')
            .borderRadius(8)
            .onClick(() => {
              console.log('Delete selected photos:', this.selectedPhotos)
              this.selectedPhotos = []
            })

          Button('分享')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .borderRadius(8)
            .margin({ left: 12 })
            .onClick(() => {
              console.log('Share selected photos:', this.selectedPhotos)
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 20 })
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}