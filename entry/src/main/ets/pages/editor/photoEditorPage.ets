/**
 * 照片编辑主页��
 * 提供照片编辑主界面，包括编辑工具栏、历史管理和撤销重做功能
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { Photo } from '../../models/Photo'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 编辑工具类型枚举
 */
export enum EditTool {
  ADJUST = 'adjust',
  CROP = 'crop',
  ROTATE = 'rotate',
  FILTER = 'filter',
  DOODLE = 'doodle',
  ANNOTATE = 'annotate',
  TEXT = 'text',
  MOSAIC = 'mosaic'
}

/**
 * 编辑历史项接口
 */
interface EditHistoryItem {
  id: string
  tool: EditTool
  name: string
  timestamp: Date
  thumbnail?: string
  data?: any
}

@Entry
@Component
struct PhotoEditorPage {
  private logger = new Logger('PhotoEditorPage')
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private photoId: string = ''
  private fromDetail: boolean = false

  // 状态管理
  @State private isLoading: boolean = false
  @State private originalPhoto: Photo | null = null
  @State private currentPhoto: Photo | null = null
  @State private selectedTool: EditTool = EditTool.ADJUST
  @State private showToolPanel: boolean = false
  @State private showHistoryPanel: boolean = false
  @State private showSaveDialog: boolean = false
  @State private showExitDialog: boolean = false

  // 编辑状态
  @State private editHistory: EditHistoryItem[] = []
  @State private currentHistoryIndex: number = -1
  @State private hasUnsavedChanges: boolean = false
  @State private isProcessing: boolean = false

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.photoId = params?.photoId || ''
    this.fromDetail = params?.fromDetail || false

    this.logger.info('PhotoEditorPage appeared', { photoId: this.photoId })

    if (this.photoId) {
      this.loadPhoto()
    }
  }

  aboutToDisappear() {
    this.logger.info('PhotoEditorPage disappeared')
  }

  /**
   * 加载照片
   */
  private async loadPhoto() {
    this.isLoading = true
    try {
      this.originalPhoto = await this.photoStore.getPhotoById(this.photoId)
      this.currentPhoto = { ...this.originalPhoto }

      if (!this.originalPhoto) {
        this.logger.error('照片未找到', { photoId: this.photoId })
        router.back()
      }
    } catch (error) {
      this.logger.error('加载照片失败', error)
      router.back()
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 选择编辑工具
   */
  private selectTool(tool: EditTool) {
    this.selectedTool = tool
    this.showToolPanel = true
    this.logger.info('选择编辑工具', { tool })
  }

  /**
   * 应用编辑
   */
  private async applyEdit(tool: EditTool, data?: any) {
    if (this.isProcessing) return

    this.isProcessing = true
    try {
      // 根据工具类型执行相应的编辑操作
      let result: Photo | null = null

      switch (tool) {
        case EditTool.ADJUST:
          result = await this.applyAdjustment(data)
          break
        case EditTool.CROP:
          result = await this.applyCrop(data)
          break
        case EditTool.ROTATE:
          result = await this.applyRotate(data)
          break
        case EditTool.FILTER:
          result = await this.applyFilter(data)
          break
        case EditTool.DOODLE:
          router.pushUrl({
            url: 'pages/editor/DoodleEditorPage',
            params: {
              photoId: this.photoId,
              fromEditor: true
            }
          })
          return
        case EditTool.ANNOTATE:
          router.pushUrl({
            url: 'pages/editor/AnnotationEditorPage',
            params: {
              photoId: this.photoId,
              fromEditor: true
            }
          })
          return
        default:
          this.logger.error('不支持的编辑工具', { tool })
          return
      }

      if (result) {
        this.currentPhoto = result
        this.addToHistory(tool, data)
        this.hasUnsavedChanges = true
      }
    } catch (error) {
      this.logger.error('应用编辑失败', error)
    } finally {
      this.isProcessing = false
    }
  }

  /**
   * 应用调整
   */
  private async applyAdjustment(data: any): Promise<Photo> {
    // 实现亮度、对比度、饱和度等调整
    this.logger.info('应用调整', data)
    return this.currentPhoto!
  }

  /**
   * 应用裁剪
   */
  private async applyCrop(data: any): Promise<Photo> {
    // 实现照片裁剪
    this.logger.info('应用裁剪', data)
    return this.currentPhoto!
  }

  /**
   * 应用旋转
   */
  private async applyRotate(data: any): Promise<Photo> {
    // 实现照片旋转
    this.logger.info('应用旋转', data)
    return this.currentPhoto!
  }

  /**
   * 应用滤镜
   */
  private async applyFilter(data: any): Promise<Photo> {
    // 实现照片滤镜
    this.logger.info('应用滤镜', data)
    return this.currentPhoto!
  }

  /**
   * 添加到历史记录
   */
  private addToHistory(tool: EditTool, data?: any) {
    const historyItem: EditHistoryItem = {
      id: Date.now().toString(),
      tool: tool,
      name: this.getToolName(tool),
      timestamp: new Date(),
      data: data
    }

    // 如果当前不在历史记录末尾，删除后面的记录
    if (this.currentHistoryIndex < this.editHistory.length - 1) {
      this.editHistory = this.editHistory.slice(0, this.currentHistoryIndex + 1)
    }

    this.editHistory.push(historyItem)
    this.currentHistoryIndex = this.editHistory.length - 1

    this.logger.info('添加编辑历史', { tool, historyIndex: this.currentHistoryIndex })
  }

  /**
   * 撤销
   */
  private async undo() {
    if (this.canUndo()) {
      this.currentHistoryIndex--
      await this.loadHistoryState(this.editHistory[this.currentHistoryIndex])
      this.hasUnsavedChanges = true
    }
  }

  /**
   * 重做
   */
  private async redo() {
    if (this.canRedo()) {
      this.currentHistoryIndex++
      await this.loadHistoryState(this.editHistory[this.currentHistoryIndex])
      this.hasUnsavedChanges = true
    }
  }

  /**
   * 加载历史状态
   */
  private async loadHistoryState(historyItem: EditHistoryItem) {
    // 实现历史状态加载
    this.logger.info('加载历史状态', { historyItem })
  }

  /**
   * 检查是否可以撤销
   */
  private canUndo(): boolean {
    return this.currentHistoryIndex > 0
  }

  /**
   * 检查是否可以重做
   */
  private canRedo(): boolean {
    return this.currentHistoryIndex < this.editHistory.length - 1
  }

  /**
   * 保存照片
   */
  private async savePhoto() {
    if (!this.currentPhoto || this.isProcessing) return

    this.isProcessing = true
    try {
      await this.photoStore.updatePhoto(this.currentPhoto.id, {
        edited: true,
        lastEditedAt: new Date()
      })

      this.hasUnsavedChanges = false
      this.showSaveDialog = false

      this.logger.info('照片保存成功')
    } catch (error) {
      this.logger.error('保存照片失败', error)
    } finally {
      this.isProcessing = false
    }
  }

  /**
   * 导出照片
   */
  private exportPhoto() {
    if (!this.currentPhoto) return

    router.pushUrl({
      url: 'pages/export/ExportPage',
      params: {
        photoIds: [this.currentPhoto.id]
      }
    })
  }

  /**
   * 返回处理
   */
  private onBack() {
    if (this.hasUnsavedChanges) {
      this.showExitDialog = true
    } else {
      router.back()
    }
  }

  /**
   * 强制返回
   */
  private forceBack() {
    this.showExitDialog = false
    router.back()
  }

  /**
   * 获取工具名称
   */
  private getToolName(tool: EditTool): string {
    switch (tool) {
      case EditTool.ADJUST:
        return '调整'
      case EditTool.CROP:
        return '裁剪'
      case EditTool.ROTATE:
        return '旋转'
      case EditTool.FILTER:
        return '滤镜'
      case EditTool.DOODLE:
        return '涂鸦'
      case EditTool.ANNOTATE:
        return '标注'
      case EditTool.TEXT:
        return '文字'
      case EditTool.MOSAIC:
        return '马赛克'
      default:
        return '未知'
    }
  }

  /**
   * 获取工具图标
   */
  private getToolIcon(tool: EditTool): Resource {
    switch (tool) {
      case EditTool.ADJUST:
        return $r('app.media.ic_adjust')
      case EditTool.CROP:
        return $r('app.media.ic_crop')
      case EditTool.ROTATE:
        return $r('app.media.ic_rotate')
      case EditTool.FILTER:
        return $r('app.media.ic_filter')
      case EditTool.DOODLE:
        return $r('app.media.ic_doodle')
      case EditTool.ANNOTATE:
        return $r('app.media.ic_annotate')
      case EditTool.TEXT:
        return $r('app.media.ic_text')
      case EditTool.MOSAIC:
        return $r('app.media.ic_mosaic')
      default:
        return $r('app.media.ic_edit')
    }
  }

  build() {
    Column() {
      // 顶部工具栏
      this.buildTopToolbar()

      // 编辑区域
      this.buildEditArea()

      // 底部工具栏
      this.buildBottomToolbar()

      // 工具面板
      if (this.showToolPanel) {
        this.buildToolPanel()
      }

      // 历史面板
      if (this.showHistoryPanel) {
        this.buildHistoryPanel()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 保存确认对话框
      if (this.showSaveDialog) {
        ConfirmDialog({
          title: '保存照片',
          message: '确定要保存当前编辑的照片吗？',
          confirmText: '保存',
          cancelText: '取消',
          onConfirm: () => this.savePhoto(),
          onCancel: () => this.showSaveDialog = false
        })
      }

      // 退出确认对话框
      if (this.showExitDialog) {
        ConfirmDialog({
          title: '放弃更改',
          message: '照片有未保存的更改，确定要放弃吗？',
          confirmText: '放弃',
          cancelText: '取消',
          onConfirm: () => this.forceBack(),
          onCancel: () => this.showExitDialog = false
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  /**
   * 构建顶部工具栏
   */
  @Builder
  private buildTopToolbar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.onBack())

      Blank()

      // 撤销/重做按钮
      Row({ space: 16 }) {
        // 撤销
        Button() {
          Image($r('app.media.ic_undo'))
            .width(24)
            .height(24)
            .fillColor(this.canUndo() ? '#FFFFFF' : '#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(this.canUndo())
        .onClick(() => this.undo())

        // 重做
        Button() {
          Image($r('app.media.ic_redo'))
            .width(24)
            .height(24)
            .fillColor(this.canRedo() ? '#FFFFFF' : '#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(this.canRedo())
        .onClick(() => this.redo())

        // 历史
        Button() {
          Image($r('app.media.ic_history'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showHistoryPanel = !this.showHistoryPanel)
      }

      Blank()

      // 保存和导出
      Row({ space: 16 }) {
        // 导出
        Button() {
          Image($r('app.media.ic_export'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.exportPhoto())

        // 保存
        Button() {
          Image($r('app.media.ic_save'))
            .width(24)
            .height(24)
            .fillColor(this.hasUnsavedChanges ? '#FFD700' : '#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showSaveDialog = true)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(0,0,0,0.8)')
  }

  /**
   * 构建编辑区域
   */
  @Builder
  private buildEditArea() {
    Column() {
      if (this.currentPhoto) {
        // 照片显示区域
        Image(this.currentPhoto.filePath)
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .onComplete(() => {
            this.logger.info('照片加载完成')
          })
          .onError((error) => {
            this.logger.error('照片加载失败', error)
          })
      } else {
        // 占位区域
        Column() {
          Text('照片加载中...')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建底部工具栏
   */
  @Builder
  private buildBottomToolbar() {
    Column() {
      // 工具分类标签
      Scroll() {
        Row({ space: 24 }) {
          ForEach(
            [
              EditTool.ADJUST,
              EditTool.CROP,
              EditTool.ROTATE,
              EditTool.FILTER,
              EditTool.DOODLE,
              EditTool.ANNOTATE
            ],
            (tool: EditTool) => {
              Column({ space: 4 }) {
                Button() {
                  Image(this.getToolIcon(tool))
                    .width(24)
                    .height(24)
                    .fillColor(this.selectedTool === tool ? '#007AFF' : '#FFFFFF')
                }
                .width(48)
                .height(48)
                .backgroundColor(this.selectedTool === tool ? 'rgba(0,122,255,0.2)' : 'rgba(255,255,255,0.1)')
                .borderRadius(24)
                .onClick(() => this.selectTool(tool))

                Text(this.getToolName(tool))
                  .fontSize(12)
                  .fontColor(this.selectedTool === tool ? '#007AFF' : '#FFFFFF')
              }
            },
            (tool: EditTool) => tool
          )
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ horizontal: 16, vertical: 16 })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .backgroundColor('rgba(0,0,0,0.8)')
    }
    .width('100%')
  }

  /**
   * 构建工具面板
   */
  @Builder
  private buildToolPanel() {
    Column() {
      // 面板标题
      Row() {
        Text(this.getToolName(this.selectedTool))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button() {
          Image($r('app.media.ic_close'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showToolPanel = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      // 工具选项
      Scroll() {
        Column({ space: 16 }) {
          // 根据选中的工具显示不同的选项
          this.buildToolOptions()
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      // 底部操作栏
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showToolPanel = false)

        Button('应用')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.applyEdit(this.selectedTool))
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('60%')
    .position({ x: 0, y: '40%' })
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: -4
    })
    .zIndex(10)
  }

  /**
   * 构建工具选项
   */
  @Builder
  private buildToolOptions() {
    switch (this.selectedTool) {
      case EditTool.ADJUST:
        this.buildAdjustOptions()
        break
      case EditTool.CROP:
        this.buildCropOptions()
        break
      case EditTool.ROTATE:
        this.buildRotateOptions()
        break
      case EditTool.FILTER:
        this.buildFilterOptions()
        break
      default:
        Text('该工具选项待实现')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ vertical: 40 })
    }
  }

  /**
   * 构建调整选项
   */
  @Builder
  private buildAdjustOptions() {
    Column({ space: 20 }) {
      // 亮度调整
      this.buildSliderOption('亮度', -100, 100, 0)

      // 对比度调整
      this.buildSliderOption('对比度', -100, 100, 0)

      // 饱和度调整
      this.buildSliderOption('饱和度', -100, 100, 0)

      // 色温调整
      this.buildSliderOption('色温', -100, 100, 0)
    }
  }

  /**
   * 构建裁剪选项
   */
  @Builder
  private buildCropOptions() {
    Column({ space: 20 }) {
      Text('裁剪选项')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 裁剪比例选项
      Column({ space: 12 }) {
        ForEach(
          [
            { label: '自由', ratio: 'free' },
            { label: '1:1', ratio: '1:1' },
            { label: '4:3', ratio: '4:3' },
            { label: '16:9', ratio: '16:9' },
            { label: '3:2', ratio: '3:2' }
          ],
          (option: { label: string, ratio: string }) => {
            Row() {
              Text(option.label)
                .fontSize(14)
                .fontColor('#333333')
                .layoutWeight(1)

              Image($r('app.media.ic_check'))
                .width(16)
                .height(16)
                .fillColor('#007AFF')
                .opacity(0) // 隐藏选中状态
            }
            .width('100%')
            .height(44)
            .padding({ horizontal: 12 })
            .borderRadius(8)
            .backgroundColor('#F8F8F8')
            .onClick(() => {
              // 选择裁剪比例
            })
          },
          (option: { label: string, ratio: string }) => option.ratio
        )
      }
    }
  }

  /**
   * 构建旋转选项
   */
  @Builder
  private buildRotateOptions() {
    Column({ space: 20 }) {
      Text('旋转选项')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 旋转角度按钮
      Row({ space: 12 }) {
        ForEach(
          [
            { label: '左转90°', angle: -90 },
            { label: '右转90°', angle: 90 },
            { label: '180°', angle: 180 },
            { label: '翻转', angle: 'flip' }
          ],
          (option: { label: string, angle: number | string }) => {
            Button(option.label)
              .fontSize(14)
              .fontColor('#333333')
              .backgroundColor('#F8F8F8')
              .borderRadius(8)
              .layoutWeight(1)
              .onClick(() => {
                this.applyEdit(EditTool.ROTATE, { angle: option.angle })
              })
          },
          (option: { label: string, angle: number | string }) => option.label
        )
      }
    }
  }

  /**
   * 构建滤镜选项
   */
  @Builder
  private buildFilterOptions() {
    Column({ space: 20 }) {
      Text('滤镜效果')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 滤镜网格
      Grid() {
        ForEach(
          [
            { name: '原图', id: 'original' },
            { name: '黑白', id: 'grayscale' },
            { name: '复古', id: 'vintage' },
            { name: '暖色', id: 'warm' },
            { name: '冷色', id: 'cold' },
            { name: '高对比', id: 'contrast' }
          ],
          (filter: { name: string, id: string }) => {
            GridItem() {
              Column({ space: 8 }) {
                // 滤镜预览图
                Image(this.currentPhoto?.filePath || '')
                  .width(60)
                  .height(60)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)

                Text(filter.name)
                  .fontSize(12)
                  .fontColor('#333333')
              }
            }
            .onClick(() => {
              this.applyEdit(EditTool.FILTER, { filterId: filter.id })
            })
          },
          (filter: { name: string, id: string }) => filter.id
        )
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
  }

  /**
   * 构建滑块选项
   */
  @Builder
  private buildSliderOption(label: string, min: number, max: number, value: number) {
    Column({ space: 8 }) {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor('#333333')

        Text(`${value}`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Slider({
        value: value,
        min: min,
        max: max,
        style: SliderStyle.InSet
      })
      .width('100%')
      .trackColor('#E0E0E0')
      .selectedColor('#007AFF')
      .blockColor('#007AFF')
      .onChange((value: number) => {
        // 更新滑块值
      })
    }
    .width('100%')
  }

  /**
   * 构建历史面板
   */
  @Builder
  private buildHistoryPanel() {
    Column() {
      // 面板标题
      Row() {
        Text('编辑历史')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button() {
          Image($r('app.media.ic_close'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.showHistoryPanel = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      // 历史记录列表
      Scroll() {
        Column({ space: 8 }) {
          ForEach(
            this.editHistory,
            (item: EditHistoryItem, index: number) => {
              Row() {
                // 历史项图标
                Image(this.getToolIcon(item.tool))
                  .width(20)
                  .height(20)
                  .fillColor('#666666')
                  .margin({ right: 12 })

                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(14)
                    .fontColor(index === this.currentHistoryIndex ? '#007AFF' : '#333333')

                  Text(this.formatTime(item.timestamp))
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                if (index === this.currentHistoryIndex) {
                  Image($r('app.media.ic_check'))
                    .width(16)
                    .height(16)
                    .fillColor('#007AFF')
                }
              }
              .width('100%')
              .height(56)
              .padding({ horizontal: 16 })
              .backgroundColor(index === this.currentHistoryIndex ? '#F0F8FF' : Color.Transparent)
              .borderRadius(8)
              .onClick(() => {
                this.currentHistoryIndex = index
                this.loadHistoryState(item)
              })
            },
            (item: EditHistoryItem) => item.id
          )
        }
        .width('100%')
        .padding(8)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('60%')
    .position({ x: 0, y: '40%' })
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: -4
    })
    .zIndex(10)
  }

  /**
   * 格式化时间
   */
  private formatTime(date: Date): string {
    return date.toLocaleTimeString('zh-CN', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  }
}