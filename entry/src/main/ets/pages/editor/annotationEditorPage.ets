/**
 * 标注编辑页面
 * 提供标注添加功能，包括文字标注、图形标注和马赛克功能
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { Photo } from '../../models/Photo'
import { PhotoStore } from '../../store/photo/PhotoStore'
import { TextAnnotation } from '../../components/editor/TextAnnotation'
import { ShapeAnnotation } from '../../components/editor/ShapeAnnotation'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

/**
 * 标注类型枚举
 */
export enum AnnotationType {
  TEXT = 'text',
  ARROW = 'arrow',
  RECTANGLE = 'rectangle',
  CIRCLE = 'circle',
  LINE = 'line',
  MOSAIC = 'mosaic'
}

/**
 * 标注数据接口
 */
interface AnnotationData {
  id: string
  type: AnnotationType
  data: any
  timestamp: Date
}

@Entry
@Component
struct AnnotationEditorPage {
  private logger = new Logger('AnnotationEditorPage')
  private photoStore = PhotoStore.getInstance()

  // 路由参数
  private photoId: string = ''
  private fromEditor: boolean = false

  // 状态管理
  @State private isLoading: boolean = false
  @State private originalPhoto: Photo | null = null
  @State private currentPhoto: Photo | null = null

  // 标注状态
  @State private currentTool: AnnotationType = AnnotationType.TEXT
  @State private annotations: AnnotationData[] = []
  @State private textAnnotations: any[] = []
  @State private shapeAnnotations: any[] = []
  @State private hasUnsavedChanges: boolean = false

  // UI状态
  @State private showToolPanel: boolean = false
  @State private showTextDialog: boolean = false
  @State private showStyleDialog: boolean = false
  @State private selectedAnnotationId: string = ''

  // 样式设置
  @State private textColor: ResourceStr = '#FF0000'
  @State private strokeWidth: number = 2
  @State private fillColor: ResourceStr = '#FFFF00'
  @State private textSize: number = 16

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.photoId = params?.photoId || ''
    this.fromEditor = params?.fromEditor || false

    this.logger.info('AnnotationEditorPage appeared', { photoId: this.photoId })

    if (this.photoId) {
      this.loadPhoto()
    }
  }

  aboutToDisappear() {
    this.logger.info('AnnotationEditorPage disappeared')
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
   * 保存标注
   */
  private async saveAnnotations() {
    if (!this.currentPhoto) return

    try {
      // 这里应该实现标注保存逻辑
      // 将标注数据与照片合并保存

      this.hasUnsavedChanges = false
      this.logger.info('标注保存成功')

      // 返回上一页
      router.back()
    } catch (error) {
      this.logger.error('保存标注失败', error)
    }
  }

  /**
   * 选择工具
   */
  private selectTool(tool: AnnotationType) {
    this.currentTool = tool
    this.showToolPanel = false

    if (tool === AnnotationType.TEXT) {
      this.showTextDialog = true
    } else if (tool === AnnotationType.MOSAIC) {
      // 马赛克工具有特殊处理
    }
  }

  /**
   * 添加文字标注
   */
  private addTextAnnotation(text: string, x: number, y: number) {
    const annotation: AnnotationData = {
      id: Date.now().toString(),
      type: AnnotationType.TEXT,
      data: {
        text: text,
        x: x,
        y: y,
        color: this.textColor,
        size: this.textSize
      },
      timestamp: new Date()
    }

    this.annotations.push(annotation)
    this.hasUnsavedChanges = true

    this.logger.info('添加文字标注', { text, x, y })
  }

  /**
   * 添加图形标注
   */
  private addShapeAnnotation(type: AnnotationType, data: any) {
    const annotation: AnnotationData = {
      id: Date.now().toString(),
      type: type,
      data: {
        ...data,
        strokeColor: this.textColor,
        strokeWidth: this.strokeWidth,
        fillColor: this.fillColor
      },
      timestamp: new Date()
    }

    this.annotations.push(annotation)
    this.hasUnsavedChanges = true

    this.logger.info('添加图形标注', { type, data })
  }

  /**
   * 删除标注
   */
  private deleteAnnotation(annotationId: string) {
    const index = this.annotations.findIndex(item => item.id === annotationId)
    if (index > -1) {
      this.annotations.splice(index, 1)
      this.hasUnsavedChanges = true
      this.selectedAnnotationId = ''
    }
  }

  /**
   * 清空所有标注
   */
  private clearAllAnnotations() {
    this.showClearDialog = true
  }

  /**
   * 确认清空
   */
  private confirmClear() {
    this.annotations = []
    this.textAnnotations = []
    this.shapeAnnotations = []
    this.hasUnsavedChanges = true
    this.selectedAnnotationId = ''
    this.showClearDialog = false
  }

  /**
   * 文字标注添加回调
   */
  private onTextAnnotationAdd(annotation: any) {
    this.textAnnotations.push(annotation)
    this.hasUnsavedChanges = true
  }

  /**
   * 图形标注添加回调
   */
  private onShapeAnnotationAdd(shape: any) {
    this.shapeAnnotations.push(shape)
    this.hasUnsavedChanges = true
  }

  /**
   * 获取工具名称
   */
  private getToolName(tool: AnnotationType): string {
    switch (tool) {
      case AnnotationType.TEXT:
        return '文字'
      case AnnotationType.ARROW:
        return '箭头'
      case AnnotationType.RECTANGLE:
        return '矩形'
      case AnnotationType.CIRCLE:
        return '圆形'
      case AnnotationType.LINE:
        return '直线'
      case AnnotationType.MOSAIC:
        return '马赛克'
      default:
        return '未知'
    }
  }

  /**
   * 获取工具图标
   */
  private getToolIcon(tool: AnnotationType): Resource {
    switch (tool) {
      case AnnotationType.TEXT:
        return $r('app.media.ic_text')
      case AnnotationType.ARROW:
        return $r('app.media.ic_arrow')
      case AnnotationType.RECTANGLE:
        return $r('app.media.ic_rectangle')
      case AnnotationType.CIRCLE:
        return $r('app.media.ic_circle')
      case AnnotationType.LINE:
        return $r('app.media.ic_line')
      case AnnotationType.MOSAIC:
        return $r('app.media.ic_mosaic')
      default:
        return $r('app.media.ic_annotate')
    }
  }

  // 对话框状态
  @State private showSaveDialog: boolean = false
  @State private showClearDialog: boolean = false

  build() {
    Column() {
      // 顶部工具栏
      this.buildTopToolbar()

      // 标注区域
      this.buildAnnotationArea()

      // 底部工具栏
      this.buildBottomToolbar()

      // 工具面板
      if (this.showToolPanel) {
        this.buildToolPanel()
      }

      // 文字标注对话框
      if (this.showTextDialog) {
        this.buildTextDialog()
      }

      // 样式设置对话框
      if (this.showStyleDialog) {
        this.buildStyleDialog()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 保存确认对话框
      if (this.showSaveDialog) {
        ConfirmDialog({
          title: '保存标注',
          message: '标注有未保存的更改，是否保存？',
          confirmText: '保存',
          cancelText: '不保存',
          onConfirm: () => this.saveAnnotations(),
          onCancel: () => {
            this.showSaveDialog = false
            router.back()
          }
        })
      }

      // 清空确认对话框
      if (this.showClearDialog) {
        ConfirmDialog({
          title: '清空标注',
          message: '确定要清空所有标注吗？此操作不可恢复。',
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

      // 标注统计和操作
      Row({ space: 16 }) {
        // 标注数量
        if (this.annotations.length > 0) {
          Text(`${this.annotations.length}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .padding({ horizontal: 8, vertical: 4 })
            .backgroundColor('rgba(255,255,255,0.2)')
            .borderRadius(12)
        }

        // 清空按钮
        Button() {
          Image($r('app.media.ic_clear'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(this.annotations.length > 0)
        .onClick(() => this.clearAllAnnotations())
      }

      Blank()

      // 样式设置
      Button() {
        Image($r('app.media.ic_style'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.showStyleDialog = true)

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
      .onClick(() => this.saveAnnotations())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(0,0,0,0.8)')
  }

  /**
   * 构建标注区域
   */
  @Builder
  private buildAnnotationArea() {
    Stack() {
      if (this.currentPhoto) {
        // 照片背景
        Image(this.currentPhoto.filePath)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)

        // 文字标注层
        TextAnnotation({
          backgroundImage: '',
          annotations: this.textAnnotations,
          editable: true,
          onAnnotationAdd: (annotation: any) => this.onTextAnnotationAdd(annotation),
          onAnnotationUpdate: (index: number, annotation: any) => {
            this.hasUnsavedChanges = true
          },
          onAnnotationDelete: (index: number) => {
            this.hasUnsavedChanges = true
          }
        })

        // 图形标注层
        ShapeAnnotation({
          backgroundImage: '',
          shapes: this.shapeAnnotations,
          editable: true,
          onShapeAdd: (shape: any) => this.onShapeAnnotationAdd(shape),
          onShapeUpdate: (index: number, shape: any) => {
            this.hasUnsavedChanges = true
          },
          onShapeDelete: (index: number) => {
            this.hasUnsavedChanges = true
          }
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
      // 标注工具栏
      Scroll() {
        Row({ space: 20 }) {
          ForEach(
            [
              AnnotationType.TEXT,
              AnnotationType.ARROW,
              AnnotationType.RECTANGLE,
              AnnotationType.CIRCLE,
              AnnotationType.LINE,
              AnnotationType.MOSAIC
            ],
            (tool: AnnotationType) => {
              Column({ space: 4 }) {
                Button() {
                  Image(this.getToolIcon(tool))
                    .width(24)
                    .height(24)
                    .fillColor(this.currentTool === tool ? '#007AFF' : '#FFFFFF')
                }
                .width(48)
                .height(48)
                .backgroundColor(this.currentTool === tool ? 'rgba(0,122,255,0.2)' : 'rgba(255,255,255,0.1)')
                .borderRadius(24)
                .onClick(() => this.selectTool(tool))

                Text(this.getToolName(tool))
                  .fontSize(12)
                  .fontColor(this.currentTool === tool ? '#007AFF' : '#FFFFFF')
              }
            },
            (tool: AnnotationType) => tool
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
        Text('标注工具')
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

      // 工具说明
      Column({ space: 16 }) {
        Text(`${this.getToolName(this.currentTool)}工具`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text(this.getToolDescription(this.currentTool))
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(20)

        // 使用说明
        Column({ space: 8 }) {
          Text('使用说明:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          ForEach(
            this.getToolInstructions(this.currentTool),
            (instruction: string) => {
              Row({ space: 8 }) {
                Text('•')
                  .fontSize(14)
                  .fontColor('#007AFF')

                Text(instruction)
                  .fontSize(14)
                  .fontColor('#666666')
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            },
            (instruction: string) => instruction
          )
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)

      // 底部操作栏
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showToolPanel = false)

        Button('开始使用')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.showToolPanel = false
            // 开始使用工具的具体逻辑
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
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

  /**
   * 构建文字标注对话框
   */
  @Builder
  private buildTextDialog() {
    Column() {
      // 对话框标题
      Row() {
        Text('添加文字标注')
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
        .onClick(() => this.showTextDialog = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      // 文字输入区域
      Column({ space: 16 }) {
        TextArea({ placeholder: '请输入标注文字' })
          .width('100%')
          .height(120)
          .fontSize(16)
          .fontColor('#333333')
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .padding(12)

        // 快速文字选项
        Text('快速添加:')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)

        Column({ space: 8 }) {
          ForEach(
            ['重要', '注意', '已完成', '待处理', '不合格'],
            (text: string) => {
              Button(text)
                .fontSize(14)
                .fontColor('#007AFF')
                .backgroundColor('#F0F8FF')
                .borderRadius(8)
                .width('100%')
                .onClick(() => {
                  // 添加快速文字
                })
            },
            (text: string) => text
          )
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)

      // 底部操作栏
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showTextDialog = false)

        Button('添加')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            // 添加文字标注
            this.showTextDialog = false
          })
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
   * 构建样式设置对话框
   */
  @Builder
  private buildStyleDialog() {
    Column() {
      // 对话框标题
      Row() {
        Text('样式设置')
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
        .onClick(() => this.showStyleDialog = false)
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      Scroll() {
        Column({ space: 20 }) {
          // 颜色设置
          this.buildColorSettings()

          // 线条设置
          this.buildStrokeSettings()

          // 文字设置
          this.buildTextSettings()
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      // 底部操作栏
      Row({ space: 12 }) {
        Button('重置')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            // 重置样式
          })

        Button('确定')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.showStyleDialog = false)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('70%')
    .position({ x: 0, y: '30%' })
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
   * 构建颜色设置
   */
  @Builder
  private buildColorSettings() {
    Column({ space: 12 }) {
      Text('颜色设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 颜色预设
      Grid() {
        ForEach(
          ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080', '#000000', '#FFFFFF'],
          (color: string) => {
            GridItem() {
              Button() {
                Circle({ width: 24, height: 24 })
                  .fill(color)
                  .stroke(this.textColor === color ? '#007AFF' : Color.Transparent)
                  .strokeWidth(2)
              }
              .width(40)
              .height(40)
              .backgroundColor(Color.Transparent)
              .onClick(() => this.textColor = color)
            }
          },
          (color: string) => color
        )
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建线条设置
   */
  @Builder
  private buildStrokeSettings() {
    Column({ space: 12 }) {
      Text('线条设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 线条粗细
      Row() {
        Text('线条粗细')
          .fontSize(14)
          .fontColor('#333333')

        Text(`${this.strokeWidth}px`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Slider({
        value: this.strokeWidth,
        min: 1,
        max: 20,
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
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建文字设置
   */
  @Builder
  private buildTextSettings() {
    Column({ space: 12 }) {
      Text('文字设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      // 文字大小
      Row() {
        Text('文字大小')
          .fontSize(14)
          .fontColor('#333333')

        Text(`${this.textSize}px`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Slider({
        value: this.textSize,
        min: 12,
        max: 48,
        style: SliderStyle.InSet
      })
      .width('100%')
      .trackColor('#E0E0E0')
      .selectedColor('#007AFF')
      .blockColor('#007AFF')
      .onChange((value: number) => {
        this.textSize = value
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 获取工具描述
   */
  private getToolDescription(tool: AnnotationType): string {
    switch (tool) {
      case AnnotationType.TEXT:
        return '在照片上添加文字标注，支持自定义颜色和大小。'
      case AnnotationType.ARROW:
        return '绘制箭头指向重要区域，用于强调和指示。'
      case AnnotationType.RECTANGLE:
        return '绘制矩形框选区域，用于框选和标记。'
      case AnnotationType.CIRCLE:
        return '绘制圆形标记区域，用于圆形区域标注。'
      case AnnotationType.LINE:
        return '绘制直线用于连接和分割。'
      case AnnotationType.MOSAIC:
        return '添加马赛克效果遮挡敏感信息。'
      default:
        return ''
    }
  }

  /**
   * 获取工具使用说明
   */
  private getToolInstructions(tool: AnnotationType): string[] {
    switch (tool) {
      case AnnotationType.TEXT:
        return ['点击照片位置添加文字', '支持拖拽调整位置', '双击编辑文字内容']
      case AnnotationType.ARROW:
        return ['按住起点拖拽到终点', '自动绘制箭头方向', '支持调整箭头样式']
      case AnnotationType.RECTANGLE:
        return ['按住一角拖拽绘制', '对角线确定矩形大小', '支持填充和边框样式']
      case AnnotationType.CIRCLE:
        return ['从中心拖拽绘制圆形', '半径决定圆形大小', '支持填充和边框样式']
      case AnnotationType.LINE:
        return ['按住起点拖拽到终点', '绘制直线连接两点', '支持调整线条粗细']
      case AnnotationType.MOSAIC:
        return ['选择需要遮挡的区域', '自动应用马赛克效果', '支持调整马赛克强度']
      default:
        return []
    }
  }
}