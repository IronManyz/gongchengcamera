/**
 * 涂鸦编辑页面
 * 提供涂鸦绘制功能，包括画笔设置、颜色选择和橡皮擦功能
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { Photo } from '../../models/Photo'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { DoodleCanvas } from '../../components/editor/DoodleCanvas'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 画笔类型枚举
 */
export enum BrushType {
  NORMAL = 'normal',
  HIGHLIGHTER = 'highlighter',
  MARKER = 'marker',
  PENCIL = 'pencil'
}

/**
 * 颜色预设
 */
const COLOR_PRESETS = [
  '#FF0000', // 红色
  '#00FF00', // 绿色
  '#0000FF', // 蓝色
  '#FFFF00', // 黄色
  '#FF00FF', // 品红
  '#00FFFF', // 青色
  '#FFA500', // 橙��
  '#800080', // 紫色
  '#FFC0CB', // 粉色
  '#000000', // 黑色
  '#FFFFFF', // 白色
  '#808080'  // 灰色
]

@Entry
@Component
struct DoodleEditorPage {
  private logger = new Logger('DoodleEditorPage')
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private photoId: string = ''
  private fromEditor: boolean = false

  // 状态管理
  @State private isLoading: boolean = false
  @State private originalPhoto: Photo | null = null
  @State private currentPhoto: Photo | null = null

  // 涂鸦状态
  @State private strokeWidth: number = 3
  @State private strokeColor: ResourceStr = '#FF0000'
  @State private brushType: BrushType = BrushType.NORMAL
  @State private isEraserMode: boolean = false
  @State private showColorPicker: boolean = false
  @State private showBrushSettings: boolean = false
  @State private hasUnsavedChanges: boolean = false

  // 历史管理
  @State private drawingPaths: any[] = []
  @State private undoStack: any[] = []
  @State private canUndo: boolean = false
  @State private canRedo: boolean = false

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.photoId = params?.photoId || ''
    this.fromEditor = params?.fromEditor || false

    this.logger.info('DoodleEditorPage appeared', { photoId: this.photoId })

    if (this.photoId) {
      this.loadPhoto()
    }
  }

  aboutToDisappear() {
    this.logger.info('DoodleEditorPage disappeared')
  }

  /**
   * 加载照片
   */
  private async loadPhoto() {
    this.isLoading = true
    try {
      this.originalPhoto = await this.photoStore.getPhotoById(this.photoId)
      this.currentPhoto = this.originalPhoto

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
   * 返回处理
   */
  private onBack() {
    if (this.hasUnsavedChanges) {
      this.showSaveDialog = true
    } else {
      router.back()
    }
  }

  /**
   * 保存涂鸦
   */
  private async saveDoodle() {
    if (!this.currentPhoto) return

    try {
      // 这里应该实现涂鸦保存逻辑
      // 将涂鸦数据与照片合并保存

      this.hasUnsavedChanges = false
      this.logger.info('涂鸦保存成功')

      // 返回上一页
      router.back()
    } catch (error) {
      this.logger.error('保存涂鸦失败', error)
    }
  }

  /**
   * 撤销
   */
  private undo() {
    if (this.canUndo) {
      this.logger.info('撤销涂鸦')
      // 实现撤销逻辑
    }
  }

  /**
   * 重做
   */
  private redo() {
    if (this.canRedo) {
      this.logger.info('重做涂鸦')
      // 实现重做逻辑
    }
  }

  /**
   * 清空画布
   */
  private clearCanvas() {
    this.showClearDialog = true
  }

  /**
   * 确认清空
   */
  private confirmClear() {
    this.drawingPaths = []
    this.undoStack = []
    this.canUndo = false
    this.canRedo = false
    this.hasUnsavedChanges = true
    this.showClearDialog = false
  }

  /**
   * 切换橡皮擦模式
   */
  private toggleEraser() {
    this.isEraserMode = !this.isEraserMode
    this.logger.info('切换橡皮擦模式', { isEraserMode: this.isEraserMode })
  }

  /**
   * 选择颜色
   */
  private selectColor(color: ResourceStr) {
    this.strokeColor = color
    this.isEraserMode = false
    this.showColorPicker = false
  }

  /**
   * 调整画笔大小
   */
  private adjustStrokeWidth(delta: number) {
    this.strokeWidth = Math.max(1, Math.min(50, this.strokeWidth + delta))
  }

  /**
   * 选择画笔类型
   */
  private selectBrushType(type: BrushType) {
    this.brushType = type
    this.isEraserMode = false
    this.showBrushSettings = false

    // 根据画笔类型调整默认参数
    switch (type) {
      case BrushType.HIGHLIGHTER:
        this.strokeWidth = 15
        break
      case BrushType.MARKER:
        this.strokeWidth = 8
        break
      case BrushType.PENCIL:
        this.strokeWidth = 2
        break
      default:
        this.strokeWidth = 3
    }
  }

  /**
   * 绘制变化处理
   */
  private onDrawingChange(paths: any[]) {
    this.drawingPaths = paths
    this.hasUnsavedChanges = true
    this.canUndo = paths.length > 0
  }

  /**
   * 获取画笔类型名称
   */
  private getBrushTypeName(type: BrushType): string {
    switch (type) {
      case BrushType.NORMAL:
        return '普通画笔'
      case BrushType.HIGHLIGHTER:
        return '荧光笔'
      case BrushType.MARKER:
        return '马克笔'
      case BrushType.PENCIL:
        return '铅笔'
      default:
        return '普通画笔'
    }
  }

  // 对话框状态
  @State private showSaveDialog: boolean = false
  @State private showClearDialog: boolean = false

  build() {
    Column() {
      // 顶部工具栏
      this.buildTopToolbar()

      // 绘制区域
      this.buildDrawingArea()

      // 底部工具栏
      this.buildBottomToolbar()

      // 颜色选择器
      if (this.showColorPicker) {
        this.buildColorPicker()
      }

      // 画笔设置面板
      if (this.showBrushSettings) {
        this.buildBrushSettings()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 保存确认对话框
      if (this.showSaveDialog) {
        ConfirmDialog({
          title: '保存涂鸦',
          message: '涂鸦有未保存的更改，是否保存？',
          confirmText: '保存',
          cancelText: '不保存',
          onConfirm: () => this.saveDoodle(),
          onCancel: () => {
            this.showSaveDialog = false
            router.back()
          }
        })
      }

      // 清空确认对话框
      if (this.showClearDialog) {
        ConfirmDialog({
          title: '清空画布',
          message: '确定要清空所有涂鸦吗？此操作不可恢复。',
          confirmText: '清空',
          cancelText: '取消',
          onConfirm: () => this.confirmClear(),
          onCancel: () => this.showClearDialog = false
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

      // 撤销/重做/清空按钮
      Row({ space: 16 }) {
        // 撤销
        Button() {
          Image($r('app.media.ic_undo'))
            .width(24)
            .height(24)
            .fillColor(this.canUndo ? '#FFFFFF' : '#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(this.canUndo)
        .onClick(() => this.undo())

        // 重做
        Button() {
          Image($r('app.media.ic_redo'))
            .width(24)
            .height(24)
            .fillColor(this.canRedo ? '#FFFFFF' : '#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(this.canRedo)
        .onClick(() => this.redo())

        // 清空
        Button() {
          Image($r('app.media.ic_clear'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(this.drawingPaths.length > 0)
        .onClick(() => this.clearCanvas())
      }

      Blank()

      // 保存按钮
      Button() {
        Image($r('app.media.ic_save'))
          .width(24)
          .height(24)
          .fillColor(this.hasUnsavedChanges ? '#FFD700' : '#FFFFFF')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.saveDoodle())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(0,0,0,0.8)')
  }

  /**
   * 构建绘制区域
   */
  @Builder
  private buildDrawingArea() {
    Column() {
      if (this.currentPhoto) {
        DoodleCanvas({
          backgroundImage: this.currentPhoto.filePath,
          strokeWidth: this.strokeWidth,
          strokeColor: this.strokeColor,
          enableEraser: this.isEraserMode,
          onDrawingChange: (paths: any[]) => this.onDrawingChange(paths),
          onUndo: () => this.undo(),
          onRedo: () => this.redo()
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
      // 画笔工具栏
      Row({ space: 20 }) {
        // 画笔类型
        Column({ space: 4 }) {
          Button() {
            Image($r('app.media.ic_brush'))
              .width(24)
              .height(24)
              .fillColor(!this.isEraserMode ? '#007AFF' : '#FFFFFF')
          }
          .width(48)
          .height(48)
          .backgroundColor(!this.isEraserMode ? 'rgba(0,122,255,0.2)' : 'rgba(255,255,255,0.1)')
          .borderRadius(24)
          .onClick(() => {
            this.isEraserMode = false
            this.showBrushSettings = !this.showBrushSettings
            this.showColorPicker = false
          })

          Text('画笔')
            .fontSize(12)
            .fontColor(!this.isEraserMode ? '#007AFF' : '#FFFFFF')
        }

        // 橡皮擦
        Column({ space: 4 }) {
          Button() {
            Image($r('app.media.ic_eraser'))
              .width(24)
              .height(24)
              .fillColor(this.isEraserMode ? '#007AFF' : '#FFFFFF')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isEraserMode ? 'rgba(0,122,255,0.2)' : 'rgba(255,255,255,0.1)')
          .borderRadius(24)
          .onClick(() => {
            this.toggleEraser()
            this.showBrushSettings = false
            this.showColorPicker = false
          })

          Text('橡皮')
            .fontSize(12)
            .fontColor(this.isEraserMode ? '#007AFF' : '#FFFFFF')
        }

        // 颜色选择
        Column({ space: 4 }) {
          Button() {
            Row({ space: 4 }) {
              // 当前颜色
              Circle({ width: 16, height: 16 })
                .fill(this.isEraserMode ? Color.Gray : this.strokeColor)
                .stroke(Color.White)
                .strokeWidth(2)

              Image($r('app.media.ic_arrow_down'))
                .width(12)
                .height(12)
                .fillColor('#FFFFFF')
            }
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(24)
          .onClick(() => {
            if (!this.isEraserMode) {
              this.showColorPicker = !this.showColorPicker
              this.showBrushSettings = false
            }
          })

          Text('颜色')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }

        // 画笔大小
        Column({ space: 4 }) {
          Button() {
            Text(`${this.strokeWidth}`)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(24)
          .onClick(() => {
            this.showBrushSettings = !this.showBrushSettings
            this.showColorPicker = false
          })

          Text('大小')
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ vertical: 16 })
      .backgroundColor('rgba(0,0,0,0.8)')
    }
    .width('100%')
  }

  /**
   * 构建颜色选择器
   */
  @Builder
  private buildColorPicker() {
    Column() {
      // 面板标题
      Row() {
        Text('选择颜色')
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
        .onClick(() => this.showColorPicker = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      // 颜色网格
      Grid() {
        ForEach(
          COLOR_PRESETS,
          (color: string) => {
            GridItem() {
              Button() {
                Circle({ width: 32, height: 32 })
                  .fill(color)
                  .stroke(this.strokeColor === color ? '#007AFF' : Color.Transparent)
                  .strokeWidth(3)
              }
              .width(48)
              .height(48)
              .backgroundColor(Color.Transparent)
              .onClick(() => this.selectColor(color))
            }
          },
          (color: string) => color
        )
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
      .padding(16)

      // 自定义颜色
      Column({ space: 12 }) {
        Text('自定义颜色')
          .fontSize(14)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)

        // 颜色滑块（这里简化实现）
        Row({ space: 12 }) {
          Text('R')
            .fontSize(14)
            .fontColor('#666666')

          Slider({
            value: 255,
            min: 0,
            max: 255,
            style: SliderStyle.InSet
          })
          .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ horizontal: 16, bottom: 16 })
    }
    .width('100%')
    .height('40%')
    .position({ x: 0, y: '60%' })
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
   * 构建画笔设置面板
   */
  @Builder
  private buildBrushSettings() {
    Column() {
      // 面板标题
      Row() {
        Text('画笔设置')
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
        .onClick(() => this.showBrushSettings = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      Scroll() {
        Column({ space: 20 }) {
          // 画笔类型选择
          Column({ space: 12 }) {
            Text('画笔类型')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            Column({ space: 8 }) {
              ForEach(
                [
                  BrushType.NORMAL,
                  BrushType.HIGHLIGHTER,
                  BrushType.MARKER,
                  BrushType.PENCIL
                ],
                (type: BrushType) => {
                  Row() {
                    Text(this.getBrushTypeName(type))
                      .fontSize(14)
                      .fontColor('#333333')
                      .layoutWeight(1)

                    if (this.brushType === type) {
                      Image($r('app.media.ic_check'))
                        .width(16)
                        .height(16)
                        .fillColor('#007AFF')
                    }
                  }
                  .width('100%')
                  .height(44)
                  .padding({ horizontal: 12 })
                  .borderRadius(8)
                  .backgroundColor(this.brushType === type ? '#F0F8FF' : Color.Transparent)
                  .onClick(() => this.selectBrushType(type))
                },
                (type: BrushType) => type
              )
            }
          }

          // 画笔大小调整
          Column({ space: 12 }) {
            Row() {
              Text('画笔大小')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')

              Text(`${this.strokeWidth}px`)
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            // 大小调整按钮
            Row({ space: 12 }) {
              Button('-')
                .fontSize(16)
                .fontColor('#007AFF')
                .backgroundColor('#F0F8FF')
                .borderRadius(8)
                .width(40)
                .height(40)
                .onClick(() => this.adjustStrokeWidth(-1))

              // 当前大小显示
              Row() {
                Circle({ width: this.strokeWidth * 2, height: this.strokeWidth * 2 })
                  .fill(this.strokeColor)
                  .backgroundColor('#F8F8F8')
                  .borderRadius(4)
                  .padding(8)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)

              Button('+')
                .fontSize(16)
                .fontColor('#007AFF')
                .backgroundColor('#F0F8FF')
                .borderRadius(8)
                .width(40)
                .height(40)
                .onClick(() => this.adjustStrokeWidth(1))
            }
            .width('100%')

            // 大小滑块
            Slider({
              value: this.strokeWidth,
              min: 1,
              max: 50,
              style: SliderStyle.InSet
            })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#007AFF')
            .blockColor('#007AFF')
            .onChange((value: number) => {
              this.strokeWidth = value
            })
          }

          // 预览
          Column({ space: 12 }) {
            Text('预览')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            // 预览区域
            Row() {
              Text('Aa')
                .fontSize(24)
                .fontColor(this.strokeColor)
                .fontWeight(this.brushType === BrushType.MARKER ? FontWeight.Bold : FontWeight.Normal)
                .opacity(this.brushType === BrushType.HIGHLIGHTER ? 0.5 : 1)
                .fontStyle(this.brushType === BrushType.PENCIL ? FontStyle.Italic : FontStyle.Normal)
            }
            .width('100%')
            .height(60)
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('50%')
    .position({ x: 0, y: '50%' })
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: -4
    })
    .zIndex(10)
  }
}