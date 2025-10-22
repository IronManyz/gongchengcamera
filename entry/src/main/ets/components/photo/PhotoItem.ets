/**
 * 照片项组件
 *
 * 功能描述：
 * 用于在网格视图或列表视图中展示单张照片的缩略图组件
 * 支持选择模式、信息显示、编辑标记等功能
 *
 * 主要特性：
 * - 显示照片缩略图，支持占位符
 * - 支持多选模式和选择状态指示
 * - 显示编辑状态标记
 * - 支持点击和长按事件
 * - 可选的照片信息展示
 *
 * 使用示例：
 * ```typescript
 * PhotoItem({
 *   photo: photoData,
 *   showSelection: true,
 *   isSelected: false,
 *   showInfo: true,
 *   onClick: (photo) => router.push({ uri: 'photoDetail', params: { photoId: photo.id } }),
 *   onLongPress: (photo) => showContextMenu(photo),
 *   onSelectionChange: (selected) => updateSelection(photo.id, selected)
 * })
 * ```
 *
 * @author EngineeringCamera Team
 * @version 1.0.0
 * @since 2025-10-22
 */

import { Photo } from '../../models/Photo'

/**
 * 照片项组件属性接口
 */
interface PhotoItemProps {
  /** 照片数据对象，包含照片的所有相关信息 */
  photo: Photo
  /** 是否显示选择框，用于批量操作模式 */
  showSelection: boolean
  /** 当前照片是否被选中 */
  isSelected: boolean
  /** 是否显示照片信息（如拍摄时间、位置等） */
  showInfo: boolean
  /** 点击事件回调函数 */
  onClick?: (photo: Photo) => void
  /** 长按事件回调函数，通常用于显示上下文菜单 */
  onLongPress?: (photo: Photo) => void
  /** 选择状态变化事件回调函数 */
  onSelectionChange?: (selected: boolean) => void
}

@ComponentV2
export struct PhotoItem {
  /**
   * 照片数据对象
   * 包含照片的路径、缩略图、拍摄时间、位置信息等
   */
  @Param photo: Photo = new Photo()

  /**
   * 是否显示选择框
   * 在批量操作模式下启用，允许用户选择多张照片
   */
  @Param showSelection: boolean = false

  /**
   * 当前照片的选中状态
   * 用于视觉反馈选择状态
   */
  @Param isSelected: boolean = false

  /**
   * 是否显示照片信息
   * 控制是否在照片下方显示拍摄时间、位置等详细信息
   */
  @Param showInfo: boolean = false

  /**
   * 照片点击事件回调
   * 通常用于导航到照片详情页面
   */
  @Param onClick?: (photo: Photo) => void

  /**
   * 照片长按事件回调
   * 通常用于显示上下文菜单或进入选择模式
   */
  @Param onLongPress?: (photo: Photo) => void

  /**
   * 选择状态变化事件回调
   * 当用户点击选择框时触发，用于更新选择状态
   */
  @Param onSelectionChange?: (selected: boolean) => void

  /**
   * 组件构建方法
   * 构建照片项的UI界面，包括照片缩略图、选择框、编辑标记等信息显示
   */
  build() {
    Column() {
      // 照片主容器 - 使用Stack布局实现层叠效果
      Stack() {
        // 照片缩略图显示
        // 优先使用缩略图路径，如果没有则使用原图路径
        Image(this.photo.thumbnailPath || this.photo.filePath)
          .width('100%')                    // 占满容器宽度
          .aspectRatio(1)                   // 保持1:1的宽高比
          .objectFit(ImageFit.Cover)        // 裁剪模式：保持比例裁剪
          .borderRadius(8)                  // 圆角边框
          .alt($r('app.media.ic_photo_placeholder')) // 加载失败时的占位图
          .onClick(() => {
            // 触发点击事件回调，传递当前照片对象
            this.onClick?.(this.photo)
          })
          .gesture(
            // 长按手势识别，用于触发长按事件
            LongPressGesture({
              repeat: false,     // 不重复触发
              duration: 500      // 长按持续时间500ms
            })
              .onAction(() => {
                // 长按触发时调用长按事件回调
                this.onLongPress?.(this.photo)
              })
          )

        // 选择框层 - 仅在选择模式下显示
        if (this.showSelection) {
          Row() {
            Blank() // 左侧空白，将选择框推到右上角
            Column() {
              // 复选框组件，用于多选操作
              Checkbox({
                group: 'photo_selection',  // 选择组名称
                name: this.photo.id,        // 唯一标识
                selected: this.isSelected   // 当前选中状态
              })
                .select(false)                              // 默认未选中
                .selectedColor($r('app.color.primary'))     // 选中时的颜色
                .onChange((selected: boolean) => {
                  // 选择状态变化时的回调
                  this.onSelectionChange?.(selected)
                })
            }
            .padding(8) // 选择框周围的内边距
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.End)  // 右对齐
          .alignItems(VerticalAlign.Top)  // 顶部对齐
        }

        // 编辑标记层 - 显示在左上角，标识照片已编辑
        if (this.photo.edited) {
          Row() {
            Column() {
              // 编辑图标
              Image($r('app.media.ic_edit'))
                .width(16)
                .height(16)
                .fillColor(Color.White) // 图标颜色为白色
            }
            .width(24)    // 标记容器宽度
            .height(24)   // 标记容器高度
            .backgroundColor($r('app.color.primary')) // 背景色
            .borderRadius(12)  // 圆形
            .justifyContent(FlexAlign.Center)   // 水平居中
            .alignItems(HorizontalAlign.Center) // 垂直居中
            .margin(8) // 外边距，距离边缘8像素
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Start) // 左对齐
          .alignItems(VerticalAlign.Start)   // 顶部对齐
        }

        // 加载失败占位图 - 当照片路径为空时显示
        if (!this.photo.thumbnailPath && !this.photo.filePath) {
          Column() {
            // 占位图标
            Image($r('app.media.ic_photo_placeholder'))
              .width(48)
              .height(48)
              .fillColor($r('app.color.text_tertiary')) // 使用第三等级文本颜色
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center) // 水平居中
          .alignItems(HorizontalAlign.Center) // 垂直居中
          .backgroundColor($r('app.color.surface')) // 背景色
          .borderRadius(8) // 圆角边框
        }
      }

      // 照片信息区域 - 可选显示
      if (this.showInfo) {
        Column() {
          // 拍摄时间显示
          Text(this.formatDate(this.photo.takenAt))
            .fontSize(12) // 较小的字体尺寸
            .fontColor($r('app.color.text_secondary')) // 次要文本颜色
            .maxLines(1) // 最多显示1行
            .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出时显示省略号

          // 项目名称显示（如果有项目信息）
          if (this.photo.project?.name) {
            Text(this.photo.project.name)
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary')) // 第三等级文本颜色
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start) // 左对齐
        .margin({ top: 8 }) // 顶部边距
      }
    }
    .width('100%')
  }

  /**
   * 格式化日期显示
   * 将日期转换为相对时间格式，提高用户体验
   *
   * @param date 要格式化的日期
   * @returns 格式化后的日期字符串
   *
   * 示例：
   * - 今天：返回"今天"
   * - 昨天：返回"昨天"
   * - 7天内：返回"X天前"
   * - 超过7天：返回具体日期
   */
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
 *
 * 功能描述：
 * 用于在列表视图中以横向布局展示单张照片的详细信息
 * 适用于需要显示更多照片信息的场景
 *
 * 布局特点：
 * - 左侧显示照片缩略图（固定尺寸）
 * - 中间显示照片详细信息（文件名、时间、项目等）
 * - 右侧显示选择框（可选）
 *
 * @author EngineeringCamera Team
 * @version 1.0.0
 * @since 2025-10-22
 */
@ComponentV2
export struct PhotoListItem {
  /**
   * 照片数据对象
   */
  @Param photo: Photo = new Photo()

  /**
   * 是否显示选择框
   */
  @Param showSelection: boolean = false

  /**
   * 当前照片的选中状态
   */
  @Param isSelected: boolean = false

  /**
   * 点击事件回调
   */
  @Param onClick?: (photo: Photo) => void

  /**
   * 选择状态变化事件回调
   */
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
 *
 * 功能描述：
 * 用于展示单张照片的完整详细信息，包括大图预览和所有元数据
 * 适用于照片详情页面或模态弹窗展示
 *
 * 主要功能：
 * - 原始尺寸照片预览
 * - 完整的拍摄信息展示（时间、位置、项目、工点等）
 * - 文件信息展示（尺寸、大小等）
 * - 备注信息显示
 * - 操作按钮（编辑、分享、删除）
 *
 * @author EngineeringCamera Team
 * @version 1.0.0
 * @since 2025-10-22
 */
@ComponentV2
export struct PhotoDetailItem {
  /**
   * 照片数据对象，包含完整的照片信息
   */
  @Param photo: Photo = new Photo()

  /**
   * 编辑操作回调
   * 点击编辑按钮时触发，通常用于进入照片编辑页面
   */
  @Param onEdit?: () => void

  /**
   * 分享操作回调
   * 点击分享按钮时触发，通常调用系统分享功能
   */
  @Param onShare?: () => void

  /**
   * 删除操作回调
   * 点击删除按钮时触发，通常显示确认对话框后删除
   */
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