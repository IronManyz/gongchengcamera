/**
 * 拍摄结果页面
 * 提供拍摄结果预览、快速编辑、保存和重拍功能
 */

import { router } from '@ohos.router'
import { image } from '@kit.ImageKit'
import { Logger } from '../../utils/Logger'
import { PhotoInfo } from '../../services/camera/PhotoCaptureService'
import { WatermarkService } from '../../services/camera/WatermarkService'
import { GlobalStore } from '../../store/GlobalStore'
import { UserStore } from '../../store/user/UserStore'
import { ProjectStore } from '../../store/project/ProjectStore'
import { SiteStore } from '../../store/site/SiteStore'
import { PhotoStore } from '../../store/photo/PhotoStore'

/**
 * 页面参数接口
 */
interface CaptureResultPageParams {
  photoInfo: PhotoInfo
  fromCamera?: boolean
  projectId?: string
  siteId?: string
}

/**
 * 编辑模式枚举
 */
enum EditMode {
  NONE = 'none',
  WATERMARK = 'watermark',
  ANNOTATION = 'annotation',
  FILTER = 'filter'
}

/**
 * 快速编辑选项接口
 */
interface QuickEditOption {
  id: string
  name: string
  icon: Resource
  enabled: boolean
  action: () => void
}

@Entry
@Component
struct CaptureResultPage {
  private logger = new Logger('CaptureResultPage')
  private watermarkService: WatermarkService = WatermarkService.getInstance()
  private globalStore = GlobalStore.getInstance()
  private userStore = UserStore.getInstance()
  private projectStore = ProjectStore.getInstance()
  private siteStore = SiteStore.getInstance()
  private photoStore = PhotoStore.getInstance()

  // 页面参数
  @State private pageParams: CaptureResultPageParams = {
    photoInfo: {} as PhotoInfo
  }

  // 照片信息
  @State private photoInfo: PhotoInfo | null = null
  @State private photoImage: image.PixelMap | null = null
  @State private isProcessing: boolean = false

  // 编辑状态
  @State private editMode: EditMode = EditMode.NONE
  @State private editedPhotoUri: string = ''
  @State private hasUnsavedChanges: boolean = false

  // UI状态
  @State private showInfo: boolean = false
  @State private showEditOptions: boolean = false
  @State private showSaveDialog: boolean = false
  @State private showEditDialog: boolean = false
  @State private errorMessage: string = ''
  @State private showError: boolean = false
  @State private showSaveSuccess: boolean = false

  // 照片信息编辑
  @State private photoDescription: string = ''
  @State private photoTags: string[] = []

  // 快速编辑选项
  @State private quickEditOptions: QuickEditOption[] = []

  aboutToAppear() {
    this.logger.info('CaptureResultPage aboutToAppear')
    this.initializePage()
  }

  aboutToDisappear() {
    this.logger.info('CaptureResultPage aboutToDisappear')
    this.cleanupResources()
  }

  /**
   * 初始化页面
   */
  private async initializePage(): Promise<void> {
    try {
      // 获取页面参数
      this.parsePageParams()

      // 验证照片信息
      if (!this.pageParams.photoInfo) {
        throw new Error('照片信息无效')
      }

      this.photoInfo = this.pageParams.photoInfo
      this.photoDescription = this.photoInfo.metadata.user?.description || ''
      this.photoTags = this.photoInfo.metadata.user?.tags || []

      // 加载照片图像
      await this.loadPhotoImage()

      // 初始化快速编辑选项
      this.initializeQuickEditOptions()

      this.logger.info('CaptureResultPage initialized successfully', {
        photoId: this.photoInfo.id,
        photoName: this.photoInfo.name
      })

    } catch (error) {
      this.logger.error('Failed to initialize CaptureResultPage', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 解析页面参数
   */
  private parsePageParams(): void {
    try {
      const params = router.getParams() as CaptureResultPageParams
      if (params && params.photoInfo) {
        this.pageParams = { ...params }
        this.logger.info('Page params parsed', { photoId: params.photoInfo.id })
      }
    } catch (error) {
      this.logger.error('Failed to parse page params', error)
      throw new Error('页面参数无效')
    }
  }

  /**
   * 加载照片图像
   */
  private async loadPhotoImage(): Promise<void> {
    if (!this.photoInfo) {
      return
    }

    try {
      this.isProcessing = true

      // 这里应该根据photoInfo.uri加载图像
      // 由于API限制，这里使用占位符逻辑
      this.logger.info('Loading photo image...', { uri: this.photoInfo.uri })

      // 模拟加载过程
      await new Promise(resolve => setTimeout(resolve, 500))

      // 在实际实现中，这里应该使用ImageSource创建PixelMap
      // this.photoImage = await this.createPixelMapFromUri(this.photoInfo.uri)

      this.isProcessing = false
    } catch (error) {
      this.isProcessing = false
      this.logger.error('Failed to load photo image', error)
      throw error
    }
  }

  /**
   * 初始化快速编辑选项
   */
  private initializeQuickEditOptions(): void {
    this.quickEditOptions = [
      {
        id: 'watermark',
        name: '水印',
        icon: $r('app.media.ic_watermark'),
        enabled: true,
        action: () => this.editWatermark()
      },
      {
        id: 'annotation',
        name: '标注',
        icon: $r('app.media.ic_annotation'),
        enabled: true,
        action: () => this.editAnnotation()
      },
      {
        id: 'filter',
        name: '滤镜',
        icon: $r('app.media.ic_filter'),
        enabled: true,
        action: () => this.editFilter()
      },
      {
        id: 'crop',
        name: '裁剪',
        icon: $r('app.media.ic_crop'),
        enabled: true,
        action: () => this.editCrop()
      },
      {
        id: 'rotate',
        name: '旋转',
        icon: $r('app.media.ic_rotate'),
        enabled: true,
        action: () => this.editRotate()
      },
      {
        id: 'adjust',
        name: '调色',
        icon: $r('app.media.ic_adjust'),
        enabled: true,
        action: () => this.editAdjust()
      }
    ]
  }

  /**
   * 编辑水印
   */
  private editWatermark(): void {
    this.editMode = EditMode.WATERMARK
    router.pushUrl({
      url: 'pages/camera/watermarkConfigPage',
      params: {
        photoId: this.photoInfo?.id,
        returnToResult: true
      }
    })
  }

  /**
   * 编辑标注
   */
  private editAnnotation(): void {
    this.editMode = EditMode.ANNOTATION
    router.pushUrl({
      url: 'pages/editor/annotationEditorPage',
      params: {
        photoInfo: this.photoInfo,
        returnToResult: true
      }
    })
  }

  /**
   * 编辑滤镜
   */
  private editFilter(): void {
    this.editMode = EditMode.FILTER
    this.showEditDialog = true
  }

  /**
   * 编辑裁剪
   */
  private editCrop(): void {
    router.pushUrl({
      url: 'pages/editor/cropEditorPage',
      params: {
        photoInfo: this.photoInfo,
        returnToResult: true
      }
    })
  }

  /**
   * 编辑旋转
   */
  private editRotate(): void {
    // 这里可以实现旋转功能
    this.logger.info('Rotate photo')
  }

  /**
   * 编辑调色
   */
  private editAdjust(): void {
    router.pushUrl({
      url: 'pages/editor/adjustEditorPage',
      params: {
        photoInfo: this.photoInfo,
        returnToResult: true
      }
    })
  }

  /**
   * 保存照片
   */
  private async savePhoto(): Promise<void> {
    if (!this.photoInfo) {
      return
    }

    try {
      this.isProcessing = true

      // 更新照片元数据
      const updatedPhoto = { ...this.photoInfo }
      if (updatedPhoto.metadata.user) {
        updatedPhoto.metadata.user.description = this.photoDescription
        updatedPhoto.metadata.user.tags = this.photoTags
      }

      // 保存到照片存储
      await this.photoStore.updatePhoto(updatedPhoto)

      this.hasUnsavedChanges = false
      this.showSaveSuccess = true
      this.isProcessing = false

      this.logger.info('Photo saved successfully', { photoId: updatedPhoto.id })

      // 3秒后自动关闭成功提示
      setTimeout(() => {
        this.showSaveSuccess = false
      }, 3000)

    } catch (error) {
      this.isProcessing = false
      this.logger.error('Failed to save photo', error)
      this.handleError(error instanceof Error ? error : new Error(String(error)))
    }
  }

  /**
   * 重新拍摄
   */
  private retakePhoto(): void {
    if (this.hasUnsavedChanges) {
      this.showSaveDialog = true
    } else {
      this.navigateToCamera()
    }
  }

  /**
   * 导航到相机页面
   */
  private navigateToCamera(): void {
    if (this.pageParams.fromCamera) {
      router.back()
    } else {
      router.replaceUrl({
        url: 'pages/camera/cameraPage',
        params: {
          projectId: this.pageParams.projectId,
          siteId: this.pageParams.siteId
        }
      })
    }
  }

  /**
   * 查看照片详情
   */
  private viewPhotoDetail(): void {
    if (!this.photoInfo) {
      return
    }

    router.pushUrl({
      url: 'pages/gallery/photoDetailPage',
      params: {
        photoId: this.photoInfo.id,
        fromCamera: true
      }
    })
  }

  /**
   * 分享照片
   */
  private sharePhoto(): void {
    if (!this.photoInfo) {
      return
    }

    router.pushUrl({
      url: 'pages/export/sharePage',
      params: {
        photoInfo: this.photoInfo,
        fromCamera: true
      }
    })
  }

  /**
   * 导出照片
   */
  private exportPhoto(): void {
    if (!this.photoInfo) {
      return
    }

    router.pushUrl({
      url: 'pages/export/exportPage',
      params: {
        photoInfo: this.photoInfo,
        fromCamera: true
      }
    })
  }

  /**
   * 添加标签
   */
  private addTag(tag: string): void {
    if (tag.trim() && !this.photoTags.includes(tag.trim())) {
      this.photoTags.push(tag.trim())
      this.hasUnsavedChanges = true
    }
  }

  /**
   * 删除标签
   */
  private removeTag(index: number): void {
    this.photoTags.splice(index, 1)
    this.hasUnsavedChanges = true
  }

  /**
   * 处理错误
   */
  private handleError(error: Error): void {
    this.errorMessage = error.message
    this.showError = true
    this.logger.error('Capture result page error', error)
  }

  /**
   * 关闭错误提示
   */
  private dismissError(): void {
    this.showError = false
    this.errorMessage = ''
  }

  /**
   * 关闭成功提示
   */
  private dismissSuccess(): void {
    this.showSaveSuccess = false
  }

  /**
   * 确认放弃更改
   */
  private confirmDiscardChanges(): void {
    this.hasUnsavedChanges = false
    this.navigateToCamera()
  }

  /**
   * 清理资源
   */
  private cleanupResources(): void {
    if (this.photoImage) {
      this.photoImage.release()
      this.photoImage = null
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 主要内容区
      Column() {
        // 照片预览区
        this.buildPhotoPreview()

        // 快速编辑选项
        this.buildQuickEditOptions()

        // 照片信息编辑
        this.buildPhotoInfoEdit()
      }
      .layoutWeight(1)
      .width('100%')

      // 底部操作栏
      this.buildBottomActionBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  buildTopBar() {
    Row() {
      // 返回按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => this.retakePhoto())

      Blank()

      Text('拍摄结果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Blank()

      // 更多选项
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_more'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => {
        this.showInfo = !this.showInfo
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 构建照片预览区
   */
  @Builder
  buildPhotoPreview() {
    Stack() {
      // 照片图像
      if (this.photoInfo) {
        Image(this.editedPhotoUri || this.photoInfo.uri)
          .width('100%')
          .height('60%')
          .objectFit(ImageFit.Contain)
          .backgroundColor(Color.Black)
      }

      // 处理中提示
      if (this.isProcessing) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(Color.White)
          .position({ x: '50%', y: '50%' })
          .markAnchor({ x: '50%', y: '50%' })
      }

      // 照片信息浮层
      if (this.showInfo && this.photoInfo) {
        this.buildPhotoInfoOverlay()
      }
    }
    .width('100%')
    .height('60%')
    .backgroundColor(Color.Black)
  }

  /**
   * 构建照片信息浮层
   */
  @Builder
  buildPhotoInfoOverlay() {
    Column() {
      Text(this.photoInfo?.name || '')
        .fontSize(14)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)

      Text(`${this.photoInfo?.width} × ${this.photoInfo?.height} | ${this.photoInfo?.format.toUpperCase()}`)
        .fontSize(12)
        .fontColor(Color.White)
        .opacity(0.8)
        .margin({ top: 4 })

      Text(this.photoInfo?.timestamp.toLocaleString() || '')
        .fontSize(12)
        .fontColor(Color.White)
        .opacity(0.8)
        .margin({ top: 4 })

      if (this.photoInfo?.metadata.cameraSettings) {
        Text(`ISO ${this.photoInfo.metadata.cameraSettings.iso} | ${this.photoInfo.metadata.cameraSettings.focalLength} | f/${this.photoInfo.metadata.cameraSettings.aperture}`)
          .fontSize(10)
          .fontColor(Color.White)
          .opacity(0.6)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('rgba(0,0,0,0.7)')
    .position({ x: 0, y: 0 })
  }

  /**
   * 构建快速编辑选项
   */
  @Builder
  buildQuickEditOptions() {
    Column() {
      Text('快速编辑')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 编辑选项网格
      Grid() {
        ForEach(
          this.quickEditOptions,
          (option: QuickEditOption) => {
            GridItem() {
              Column() {
                Button({ type: ButtonType.Circle }) {
                  Image(option.icon)
                    .width(24)
                    .height(24)
                    .fillColor(Color.White)
                }
                .width(50)
                .height(50)
                .backgroundColor('rgba(255,255,255,0.2)')
                .enabled(option.enabled)
                .onClick(() => option.action())

                Text(option.name)
                  .fontSize(12)
                  .fontColor(Color.White)
                  .margin({ top: 8 })
              }
              .width(60)
              .justifyContent(FlexAlign.Center)
              .opacity(option.enabled ? 1 : 0.5)
            }
          },
          (option: QuickEditOption) => option.id
        )
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .margin({ top: 20 })
  }

  /**
   * 构建照片信息编辑
   */
  @Builder
  buildPhotoInfoEdit() {
    Column() {
      Text('照片信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 描述输入
      TextArea({ placeholder: '添加照片描述...' })
        .width('100%')
        .height(80)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('rgba(255,255,255,0.1)')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.photoDescription = value
          this.hasUnsavedChanges = true
        })

      // 标签输入
      Row() {
        TextInput({ placeholder: '添加标签...' })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(8)
          .margin({ right: 8 })

        Button('添加')
          .height(40)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(Color.Blue)
          .borderRadius(8)
          .onClick(() => {
            // 这里应该从输入框获取标签文本
            this.addTag('新标签')
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 标签列表
      if (this.photoTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
          ForEach(
            this.photoTags,
            (tag: string, index: number) => {
              Text(tag)
                .fontSize(12)
                .fontColor(Color.White)
                .padding(8)
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(16)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.removeTag(index)
                })
            },
            (tag: string, index: number) => `${tag}_${index}`
          )
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
  }

  /**
   * 构建底部操作栏
   */
  @Builder
  buildBottomActionBar() {
    Row() {
      // 重新拍摄
      Button('重拍')
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor('rgba(255,255,255,0.2)')
        .borderRadius(8)
        .width(80)
        .onClick(() => this.retakePhoto())

      Blank()

      // 快速操作按钮组
      Row() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_share'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255,255,255,0.2)')
        .onClick(() => this.sharePhoto())

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_export'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255,255,255,0.2)')
        .margin({ left: 12 })
        .onClick(() => this.exportPhoto())

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_info'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255,255,255,0.2)')
        .margin({ left: 12 })
        .onClick(() => this.viewPhotoDetail())
      }

      Blank()

      // 保存按钮
      Button('保存��片')
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(this.hasUnsavedChanges ? Color.Red : Color.Blue)
        .borderRadius(8)
        .width(100)
        .onClick(() => this.savePhoto())
    }
    .width('100%')
    .padding(16)
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('rgba(0,0,0,0.8)')
  }

  /**
   * 构建保存确认对话框
   */
  @Builder
  buildSaveDialog() {
    if (this.showSaveDialog) {
      Column() {
        Text('未保存的更改')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })

        Text('您有未保存的更改，确定要离开吗？')
          .fontSize(14)
          .fontColor(Color.Black)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        Row() {
          Button('保存')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(Color.Blue)
            .borderRadius(8)
            .width(100)
            .onClick(() => {
              this.showSaveDialog = false
              this.savePhoto()
            })

          Blank()

          Button('放弃')
            .fontSize(16)
            .fontColor(Color.Black)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .width(100)
            .onClick(() => {
              this.showSaveDialog = false
              this.confirmDiscardChanges()
            })

          Blank()

          Button('取消')
            .fontSize(16)
            .fontColor(Color.Black)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .width(100)
            .onClick(() => {
              this.showSaveDialog = false
            })
        }
        .width('100%')
      }
      .width(300)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  /**
   * 构建错误提示
   */
  @Builder
  buildErrorDialog() {
    if (this.showError) {
      Column() {
        Text('错误')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
          .margin({ bottom: 12 })

        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Black)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        Button('确定')
          .fontSize(16)
          .onClick(() => this.dismissError())
      }
      .width(280)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }

  /**
   * 构建成功提示
   */
  @Builder
  buildSuccessDialog() {
    if (this.showSaveSuccess) {
      Column() {
        Image($r('app.media.ic_success'))
          .width(40)
          .height(40)
          .fillColor(Color.Green)
          .margin({ bottom: 12 })

        Text('保存成功')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 8 })

        Text('照片已保存到相册')
          .fontSize(14)
          .fontColor(Color.White)
          .opacity(0.8)
      }
      .width(200)
      .padding(20)
      .backgroundColor('rgba(0,0,0,0.8)')
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
    }
  }

  /**
   * 构建滤镜选择对话框
   */
  @Builder
  buildFilterDialog() {
    if (this.showEditDialog && this.editMode === EditMode.FILTER) {
      Column() {
        Text('选择滤镜')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ bottom: 20 })

        // 滤镜预览网格
        Grid() {
          ForEach(
            ['原图', '黑白', '复古', '鲜艳', '暖色', '冷色'],
            (filterName: string, index: number) => {
              GridItem() {
                Column() {
                  // 滤镜预览图
                  Image($r('app.media.preview_placeholder'))
                    .width(80)
                    .height(80)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)

                  Text(filterName)
                    .fontSize(12)
                    .fontColor(Color.Black)
                    .margin({ top: 8 })
                }
                .onClick(() => {
                  // 应用滤镜
                  this.showEditDialog = false
                  this.editMode = EditMode.NONE
                })
              }
            }
          )
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(16)
        .columnsGap(16)
        .width('100%')
        .layoutWeight(1)

        Button('取消')
          .fontSize(16)
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .width('100%')
          .onClick(() => {
            this.showEditDialog = false
            this.editMode = EditMode.NONE
          })
      }
      .width('90%')
      .height('70%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .position({ x: '50%', y: '50%' })
      .markAnchor({ x: '50%', y: '50%' })
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
  }
}