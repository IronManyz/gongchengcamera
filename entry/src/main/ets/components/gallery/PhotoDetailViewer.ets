/**
 * 照片详情查看器组件
 * 提供全��查看、信息展示、操作按钮等功能
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { Photo } from '../../models/Photo'

export interface PhotoDetail {
  id: string
  name: string
  path: string
  thumbnailPath: string
  size: number
  takenAt?: Date
  location?: { latitude: number, longitude: number, address?: string }
  description?: string
  tags?: string[]
  projectId?: string
  projectName?: string
  siteId?: string
  siteName?: string
  cameraSettings?: any
  exif?: any
}

export interface PhotoOperation {
  key: string
  label: string
  icon: string
  action: () => void
  type?: 'primary' | 'secondary' | 'danger'
}

@ComponentV2
export struct PhotoDetailViewer {
  @Param photo?: PhotoDetail
  @Param showControls: boolean = true
  @Param enableFullscreen: boolean = true
  @Param onEdit?: (photo: PhotoDetail) => void
  @Param onDelete?: (photo: PhotoDetail) => void
  @Param onShare?: (photo: PhotoDetail) => void
  @Param onDownload?: (photo: PhotoDetail) => void
  @Param onClose?: () => void

  @State private isFullscreen: boolean = false
  @State private currentIndex: number = 0
  @State private showInfo: boolean = false
  @State private currentZoom: number = 1.0
  @State private showOperations: boolean = false

  private get photo(): PhotoDetail {
    return this.photo || {
      id: '',
      name: '未知照片',
      path: '',
      thumbnailPath: '',
      size: 0,
      tags: [],
      cameraSettings: {}
    }
  }

  /**
   * 格式化文件大小
   */
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  /**
   * 格式化日期
   */
  private formatDate(date?: Date): string {
    if (!date) return '未知时间'

    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (days === 0) {
      return '今天 ' + date.toLocaleTimeString()
    } else if (days === 1) {
      return '昨天 ' + date.toLocaleTimeString()
    } else if (days < 7) {
      return date.toLocaleDateString() + ' ' + date.toLocaleTimeString()
    } else {
      return date.toLocaleDateString()
    }
  }

  /**
   * 获取操作按钮列表
   */
  private getOperationButtons(): PhotoOperation[] {
    const operations: PhotoOperation[] = [
      {
        key: 'edit',
        label: '编辑',
        icon: '✏️',
        action: () => this.onEdit?.(this.photo),
        type: 'primary'
      },
      {
        key: 'share',
        label: '分享',
        icon: '📤',
        action: () => this.onShare?.(this.photo),
        type: 'secondary'
      },
      {
        key: 'download',
        label: '下载',
        icon: '📥',
        action: () => this.onDownload?.(this.photo),
        type: 'secondary'
      },
      {
        key: 'delete',
        label: '删除',
        icon: '🗑️',
        action: () => this.onDelete?.(this.photo),
        type: 'danger'
      }
    ]

    return operations
  }

  /**
   * 切换全屏模式
   */
  private toggleFullscreen(): void {
    this.isFullscreen = !this.isFullscreen
  }

  /**
   * 缩放控制
   */
  private zoomIn(): void {
    if (this.currentZoom < 3.0) {
      this.currentZoom = Math.min(this.currentZoom + 0.5, 3.0)
    }
  }

  private zoomOut(): void {
    if (this.currentZoom > 0.5) {
      this.currentZoom = Math.max(this.currentZoom - 0.5, 0.5)
    }
  }

  private resetZoom(): void {
    this.currentZoom = 1.0
  }

  /**
   * 控制栏
   */
  @Builder
  private ControlBar() {
    Row({ space: 8 }) {
      // 缩放控制
      Row({ space: 4 }) {
        Button('−')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .backgroundColor('#00000080')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => this.zoomOut())

        Text(`${Math.round(this.currentZoom * 100)}%`)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .minWidth(60)
          .textAlign(TextAlign.Center)
          .backgroundColor('#00000080')
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .borderRadius(4)

        Button('+')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .backgroundColor('#00000080')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => this.zoomIn())

        Button('1:1')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor(this.currentZoom === 1.0 ? ThemeManager.getCurrentPrimaryColor() : '#00000080')
          .width(36)
          .height(36)
          .borderRadius(18)
          .onClick(() => this.resetZoom())
      }
      .borderRadius(18)
      .backgroundColor('#00000080')

      Spacer()

      // 操作按钮
      Button(this.showInfo ? '收起' : '详情')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor(this.showInfo ? '#666666' : ThemeManager.getCurrentPrimaryColor())
        .borderRadius(16)
        .padding({ left: 12, right: 12 })
        .onClick(() => {
          this.showInfo = !this.showInfo
        })

      if (this.enableFullscreen) {
        Button(this.isFullscreen ? '退出全屏' : '全屏')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#00000080')
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .onClick(() => this.toggleFullscreen())
      }

      Button('关闭')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF4D4F')
        .borderRadius(16)
        .padding({ left: 12, right: 12 })
        .onClick(() => this.onClose?.())
      }
    }
    .width('100%')
    .padding({ horizontal: 16, vertical: 12 })
    .backgroundColor('rgba(0, 0, 0, 0.7)')
    .justifyContent(FlexAlign.SpaceAround)
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
    .zIndex(1000)
  }

  /**
   * 信息面板
   */
  @Builder
  private InfoPanel() {
    Column({ space: 16 }) {
      // 照片基本信息
      Column({ space: 12 }) {
        Text('照片信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text('文件名')
              .fontSize(14)
              .fontColor('#666666')

            Text(this.photo.name)
              .fontSize(14)
              .fontColor('#333333')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)

          Text(this.formatFileSize(this.photo.size))
            .fontSize(14)
            .fontColor('#333333')
          .textAlign(TextAlign.End)
        }
        .width('100%')

        Divider().color('#E0E0E0')
      }

      // 时间信息
      if (this.photo.takenAt) {
        Row({ space: 16 }) {
          Text('拍摄时间')
            .fontSize(14)
            .fontColor('#666666')

          Text(this.formatDate(this.photo.takenAt))
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('100%')
      }

      // 位置信息
      if (this.photo.location) {
        Row({ space: 16 }) {
          Text('拍摄位置')
            .fontSize(14)
            .fontColor('#666666')

          Text(this.photo.location.address ||
            `${this.photo.location.latitude.toFixed(6)}, ${this.photo.location.longitude.toFixed(6)}`)
            .fontSize(14)
            .fontColor('#333333')
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }

      // 工程信息
      if (this.photo.projectName) {
        Row({ space: 16 }) {
          Text('所属工程')
            .fontSize(14)
            .fontColor('#666666')

          Text(this.photo.projectName)
            .fontSize(14)
            .fontColor('#333333')
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }

      // 工点信息
      if (this.photo.siteName) {
        Row({ space: 16 }) {
          Text('所属工点')
            .fontSize(14)
            .fontColor('#666666')

          Text(this.photo.siteName)
            .fontSize(14)
            .fontColor('#333333')
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }

      // 标签信息
      if (this.photo.tags && this.photo.tags.length > 0) {
        Column({ space: 8 }) {
          Text('照片标签')
            .fontSize(14)
            .fontColor('#666666')

          Row({ space: 8 }) {
            ForEach(this.photo.tags, (tag: string) => {
              Text(tag)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor(ThemeManager.getCurrentPrimaryColor())
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(12)
            })
          }
        }
      }

      // 描述信息
      if (this.photo.description) {
        Column({ space: 8 }) {
          Text('照片描述')
            .fontSize(14)
            .fontColor('#666666')

          Text(this.photo.description)
            .fontSize(14)
            .fontColor('#333333')
            .lineHeight(20)
          .backgroundColor('#F5F5F5')
            .padding(12)
            .borderRadius(8)
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  /**
   * 操作按钮面板
   */
  @Builder
  private OperationsPanel() {
    Column({ space: 12 }) {
      Text('快捷操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Row({ space: 12 }) {
        ForEach(this.getOperationButtons(), (operation: PhotoOperation) => {
          Button() {
            Column({ space: 6 }) {
              Text(operation.icon)
                .fontSize(20)
                .fontColor(
                  operation.type === 'primary' ? '#FFFFFF' :
                  operation.type === 'danger' ? '#FFFFFF' : '#666666'
                )

              Text(operation.label)
                .fontSize(14)
                .fontColor(
                  operation.type === 'primary' ? '#FFFFFF' :
                  operation.type === 'danger' ? '#FFFFFF' : '#666666'
                )
            }
          }
          .width(80)
          .height(60)
          .backgroundColor(
            operation.type === 'primary' ? ThemeManager.getCurrentPrimaryColor() :
            operation.type === 'danger' ? '#FF4D4F' : '#F5F5F5'
          )
          .borderRadius(8)
          .onClick(() => operation.action())
        })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
  }

  build() {
    Stack() {
      // 主显示区域
      if (this.isFullscreen) {
        Image(this.photo.path || this.photo.thumbnailPath)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .scale({ x: this.currentZoom, y: this.currentZoom })
          .backgroundColor('#000000')
          .onClick(() => {
            this.showOperations = !this.showOperations
          })
      } else {
        Image(this.photo.path || this.photo.thumbnailPath)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .scale({ x: this.currentZoom, y: this.currentZoom })
          .onClick(() => {
            this.showOperations = !this.showOperations
          })
      }

      // 信息面板
      if (this.showInfo) {
        Column() {
          this.InfoPanel()
          this.OperationsPanel()
        }
        .width('80%')
        .height('60%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({
          radius: 12,
          color: '#00000030',
          offsetX: 0,
          offsetY: 4
        })
        .position({ x: '10%', y: '20%' })
        .zIndex(1001)
      }

      // 控制栏
      if (this.showControls) {
        this.ControlBar()
      }

      // 操作浮动按钮
      if (this.showOperations) {
        Row({ space: 8 }) {
          ForEach(this.getOperationButtons().slice(0, 3), (operation: PhotoOperation) => {
            Button() {
              Text(operation.icon)
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width(40)
            .height(40)
            .backgroundColor(ThemeManager.getCurrentPrimaryColor())
            .borderRadius(20)
            .onClick(() => operation.action())
          }
        }
        .position({ x: '50%', y: '70%' })
        .translate({ x: '-50%' })
        .zIndex(999)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}