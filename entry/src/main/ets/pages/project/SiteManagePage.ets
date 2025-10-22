/**
 * 工点管理页面
 * 提供工点的创建、查看、编辑功能，包含地图位置选择和���址解析
 */

import router from '@ohos.router'
import { Site } from '../../models/Site'
import { LocationData } from '../../types/AppTypes'
import { siteStore } from '../../store/site/SiteStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

interface FormErrors {
  name: string
  address: string
  description: string
}

@Entry
@Component
struct SiteManagePage {
  // 页面模式
  @State private mode: 'create' | 'view' | 'edit' = 'create'
  @State private siteId: string = ''
  @State private projectId: string = ''
  @State private isLoading: boolean = false
  @State private isSaving: boolean = false
  @State private hasUnsavedChanges: boolean = false
  @State private showUnsavedDialog: boolean = false

  // 表单字段
  @State private name: string = ''
  @State private address: string = ''
  @State private latitude: number = 0
  @State private longitude: number = 0
  @State private altitude: number = 0
  @State private description: string = ''
  @State private tags: string[] = []
  @State private currentTag: string = ''

  // 表单错误
  @State private errors: FormErrors = {
    name: '',
    address: '',
    description: ''
  }

  // 位置相关状态
  @State private isGettingLocation: boolean = false
  @State private locationError: string = ''
  @State private showLocationPicker: boolean = false
  @State private tempLatitude: number = 0
  @State private tempLongitude: number = 0
  @State private mapZoomLevel: number = 15
  @State private showMapPreview: boolean = false

  // 当前工点数据（查看模式）
  @State private currentSite: Site | null = null

  // Store
  private siteStore = siteStore

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>
    if (params?.mode) {
      this.mode = params.mode as 'create' | 'view' | 'edit'
    }

    if (params?.projectId) {
      this.projectId = params.projectId as string
    }

    if (params?.siteId && (this.mode === 'view' || this.mode === 'edit')) {
      this.siteId = params.siteId as string
      this.loadSiteData()
    }

    // 尝试获取当前位置
    if (this.mode === 'create') {
      this.getCurrentLocation()
    }
  }

  /**
   * 加载工点数据（查看/编辑模式）
   */
  private async loadSiteData() {
    this.isLoading = true
    try {
      const site = await this.siteStore.getSiteById(this.siteId)
      if (site) {
        this.currentSite = site
        this.name = site.name
        this.address = site.address
        this.latitude = site.latitude
        this.longitude = site.longitude
        this.altitude = site.altitude
        this.description = site.description
        this.tags = [...site.tags]
      }
    } catch (error) {
      console.error('加载工点数据失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 获取当前位置
   */
  private async getCurrentLocation() {
    this.isGettingLocation = true
    this.locationError = ''

    try {
      const location = await this.siteStore.getCurrentLocation()
      if (location) {
        this.latitude = location.latitude
        this.longitude = location.longitude
        this.hasUnsavedChanges = true
      } else {
        this.locationError = '无法获取当前位置'
      }
    } catch (error) {
      this.locationError = '获取位置失败'
      console.error('获取位置失败:', error)
    } finally {
      this.isGettingLocation = false
    }
  }

  /**
   * 验证工点名称
   */
  private validateName(): boolean {
    if (this.name.trim() === '') {
      this.errors.name = '工点名称不能为空'
      return false
    } else if (this.name.trim().length < 2) {
      this.errors.name = '工点名称至少需要2个字符'
      return false
    } else if (this.name.trim().length > 50) {
      this.errors.name = '工点名称不能超过50个字符'
      return false
    } else {
      this.errors.name = ''
      return true
    }
  }

  /**
   * 验证地址
   */
  private validateAddress(): boolean {
    if (this.address.trim() === '') {
      this.errors.address = ''
      return true // 地址不是必填项
    } else if (this.address.trim().length > 200) {
      this.errors.address = '地址不能超过200个字符'
      return false
    } else {
      this.errors.address = ''
      return true
    }
  }

  /**
   * 验证描述
   */
  private validateDescription(): boolean {
    if (this.description.trim() === '') {
      this.errors.description = ''
      return true // 描述不是必填项
    } else if (this.description.trim().length > 500) {
      this.errors.description = '描述不能超过500个字符'
      return false
    } else {
      this.errors.description = ''
      return true
    }
  }

  /**
   * 验证所有表单字段
   */
  private validateAll(): boolean {
    const isNameValid = this.validateName()
    const isAddressValid = this.validateAddress()
    const isDescriptionValid = this.validateDescription()

    return isNameValid && isAddressValid && isDescriptionValid
  }

  /**
   * 清空所有错误信息
   */
  private clearErrors(): void {
    this.errors = {
      name: '',
      address: '',
      description: ''
    }
  }

  /**
   * 添加标签
   */
  private addTag(): void {
    const trimmedTag = this.currentTag.trim()
    if (trimmedTag && !this.tags.includes(trimmedTag)) {
      if (this.tags.length >= 10) {
        console.warn('标签数量不能超过10个')
        return
      }
      this.tags.push(trimmedTag)
      this.currentTag = ''
      this.hasUnsavedChanges = true
    }
  }

  /**
   * 移除标签
   */
  private removeTag(tag: string): void {
    const index = this.tags.indexOf(tag)
    if (index > -1) {
      this.tags.splice(index, 1)
      this.hasUnsavedChanges = true
    }
  }

  /**
   * 在地图上选择位置
   */
  private selectLocationOnMap() {
    // 初始化临时坐标为当前值
    this.tempLatitude = this.latitude || 39.9042 // 默认北京坐标
    this.tempLongitude = this.longitude || 116.4074
    this.showLocationPicker = true
    console.log('打开地图选择位置')
  }

  /**
   * 更新位置信息
   */
  private updateLocation(lat: number, lng: number, alt?: number) {
    this.latitude = lat
    this.longitude = lng
    if (alt !== undefined) {
      this.altitude = alt
    }
    this.hasUnsavedChanges = true
  }

  /**
   * 解析地址获取坐标
   */
  private async geocodeAddress(address: string) {
    // TODO: 实现地址解析功能
    console.log('解析地址:', address)
  }

  /**
   * 保存工点
   */
  private async saveSite(): Promise<void> {
    if (!this.validateAll()) {
      return
    }

    if (!this.projectId && this.mode === 'create') {
      console.error('项目ID不能为空')
      return
    }

    this.isSaving = true
    try {
      const siteData: Partial<Site> = {
        projectId: this.projectId,
        name: this.name.trim(),
        address: this.address.trim(),
        latitude: this.latitude,
        longitude: this.longitude,
        altitude: this.altitude,
        description: this.description.trim(),
        tags: [...this.tags]
      }

      if (this.mode === 'create') {
        await this.siteStore.createSite(siteData)
      } else {
        const existingSite = await this.siteStore.getSiteById(this.siteId)
        if (existingSite) {
          Object.assign(existingSite, siteData)
          await this.siteStore.updateSite(existingSite)
        }
      }

      this.hasUnsavedChanges = false
      router.back()
    } catch (error) {
      console.error('保存工点失败:', error)
    } finally {
      this.isSaving = false
    }
  }

  /**
   * 删除工点
   */
  private async deleteSite(): Promise<void> {
    if (this.siteId) {
      const success = await this.siteStore.deleteSite(this.siteId)
      if (success) {
        router.back()
      }
    }
  }

  /**
   * 编辑工点
   */
  private navigateToEdit() {
    if (this.currentSite) {
      router.replaceUrl({
        url: 'pages/project/SiteManagePage',
        params: {
          mode: 'edit',
          siteId: this.siteId
        }
      })
    }
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    if (this.hasUnsavedChanges && (this.mode === 'create' || this.mode === 'edit')) {
      this.showUnsavedDialog = true
    } else {
      router.back()
    }
  }

  /**
   * 确认返回
   */
  private confirmGoBack(): void {
    this.showUnsavedDialog = false
    router.back()
  }

  /**
   * 取消返回
   */
  private cancelGoBack(): void {
    this.showUnsavedDialog = false
  }

  /**
   * 获取位置显示文本
   */
  private getLocationText(): string {
    if (this.latitude === 0 && this.longitude === 0) {
      return '未设置位置'
    }
    return `${this.latitude.toFixed(6)}, ${this.longitude.toFixed(6)}`
  }

  /**
   * 获取海拔显示文本
   */
  private getAltitudeText(): string {
    if (this.altitude === 0) {
      return '海平面'
    }
    return `${this.altitude.toFixed(1)}米`
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 内容区域
      if (this.mode === 'view') {
        this.buildViewContent()
      } else {
        this.buildFormContent()
      }

      // 底部操作栏
      this.buildBottomActionBar()

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 保存对话��
      if (this.isSaving) {
        LoadingDialog({ message: this.mode === 'create' ? '创建中...' : '保存中...' })
      }

      // 未保存更改确认对话框
      if (this.showUnsavedDialog) {
        ConfirmDialog({
          title: '确认离开',
          message: '您有未保存的更改，确定要离开吗？',
          confirmText: '离开',
          cancelText: '取消',
          onConfirm: () => this.confirmGoBack(),
          onCancel: () => this.cancelGoBack()
        })
      }

      // 地图选择器对话框
      if (this.showLocationPicker) {
        this.buildLocationPickerDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建顶部导航栏
   */
  @Builder
  private buildTopBar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.goBack())

      // 标题
      Text(this.getPageTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 更多操作按钮（查看模式）
      if (this.mode === 'view') {
        Button() {
          Image($r('app.media.ic_more'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 显示更多操作菜单
        })
      } else {
        // 占位保持标题居中
        Button('')
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .visibility(Visibility.Hidden)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 2,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 1
    })
  }

  /**
   * 获取页面标题
   */
  private getPageTitle(): string {
    switch (this.mode) {
      case 'create':
        return '新建工点'
      case 'view':
        return this.currentSite?.getDisplayName() || '工点详情'
      case 'edit':
        return '编辑工点'
      default:
        return '工点管理'
    }
  }

  /**
   * 构建查看模式内容
   */
  @Builder
  private buildViewContent() {
    if (this.currentSite) {
      ScrollView() {
        Column({ space: 16 }) {
          // 工点基本信息
          this.buildSiteInfoCard()

          // 位置信息
          this.buildLocationInfoCard()

          // 工点描述
          if (this.currentSite.description) {
            this.buildDescriptionCard()
          }

          // 工点标签
          if (this.currentSite.tags.length > 0) {
            this.buildTagsCard()
          }

          // 统计信息
          this.buildStatisticsCard()
        }
        .width('100%')
        .padding({ horizontal: 16, vertical: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
  }

  /**
   * 构建工点信息卡片
   */
  @Builder
  private buildSiteInfoCard() {
    Column({ space: 16 }) {
      // 工点名称
      Text(this.currentSite?.getDisplayName() || '')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')

      Divider().color('#F0F0F0')

      // 基本信息
      Column({ space: 12 }) {
        this.buildInfoItem('工点ID', this.currentSite?.id || '')
        this.buildInfoItem('项目ID', this.currentSite?.projectId || '')
        this.buildInfoItem('创建时间', this.currentSite?.createdAt.toLocaleString() || '')
        this.buildInfoItem('更新时间', this.currentSite?.updatedAt.toLocaleString() || '')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建信息项
   */
  @Builder
  private buildInfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  /**
   * 构建位置信息卡片
   */
  @Builder
  private buildLocationInfoCard() {
    Column({ space: 16 }) {
      Text('位置信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 地址
      if (this.currentSite?.address) {
        Column({ space: 8 }) {
          Text('详细地址')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)

          Text(this.currentSite.address)
            .fontSize(16)
            .fontColor('#333333')
            .lineHeight(24)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 坐标信息
      if (this.currentSite?.hasValidLocation()) {
        Column({ space: 12 }) {
          this.buildInfoItem('纬度', this.currentSite.latitude.toString())
          this.buildInfoItem('经度', this.currentSite.longitude.toString())
          this.buildInfoItem('海拔', `${this.currentSite.altitude}米`)
          this.buildInfoItem('坐标', this.currentSite.getCoordinateText())
        }
        .width('100%')
      }

      // 地图预览按钮
      if (this.currentSite?.hasValidLocation()) {
        Button() {
          Row({ space: 8 }) {
            Image($r('app.media.ic_map'))
              .width(20)
              .height(20)
              .fillColor('#007AFF')

            Text('查看地图')
              .fontSize(16)
              .fontColor('#007AFF')
          }
        }
        .width('100%')
        .height(48)
        .backgroundColor('#007AFF20')
        .borderRadius(8)
        .onClick(() => {
          this.showMapPreview = true
        })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建描述卡片
   */
  @Builder
  private buildDescriptionCard() {
    Column({ space: 12 }) {
      Text('工点描述')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Text(this.currentSite?.description || '')
        .fontSize(16)
        .fontColor('#333333')
        .lineHeight(24)
        .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建标签卡片
   */
  @Builder
  private buildTagsCard() {
    Column({ space: 12 }) {
      Text('工点标签')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(
          this.currentSite?.tags || [],
          (tag: string) => {
            Text(tag)
              .fontSize(14)
              .fontColor('#007AFF')
              .padding({ horizontal: 12, vertical: 6 })
              .backgroundColor('#007AFF20')
              .borderRadius(16)
              .margin({ right: 8, bottom: 8 })
          },
          (tag: string) => tag
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建统计信息卡片
   */
  @Builder
  private buildStatisticsCard() {
    Column({ space: 16 }) {
      Text('统计信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row({ space: 24 }) {
        Column({ space: 8 }) {
          Text(`${this.currentSite?.photoCount || 0}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')

          Text('照片数量')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 8 }) {
          Text(this.currentSite?.hasValidLocation() ? '已设置' : '未设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentSite?.hasValidLocation() ? '#2196F3' : '#FF9800')

          Text('位置信息')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建表单内容
   */
  @Builder
  private buildFormContent() {
    ScrollView() {
      Column({ space: 16 }) {
        // 基本信息
        this.buildBasicInfoSection()

        // 位置信息
        this.buildLocationSection()

        // 工点标签
        this.buildTagsSection()

        // 工点描述
        this.buildDescriptionSection()
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /**
   * 构建基本信息部分
   */
  @Builder
  private buildBasicInfoSection() {
    Column({ space: 16 }) {
      Text('基本信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 工点名称
      this.buildTextInputField(
        '工点名称 *',
        this.name,
        (value: string) => {
          this.name = value
          this.hasUnsavedChanges = true
          this.validateName()
        },
        this.errors.name,
        '请输入工点名称',
        50
      )
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建文本输入字段
   */
  @Builder
  private buildTextInputField(
    label: string,
    value: string,
    onChange: (value: string) => void,
    error: string,
    placeholder: string,
    maxLength: number
  ) {
    Column({ space: 8 }) {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor('#333333')

        if (error) {
          Text(error)
            .fontSize(12)
            .fontColor('#F44336')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      TextInput({
        placeholder: placeholder,
        text: value
      })
        .fontSize(16)
        .fontColor('#333333')
        .placeholderColor('#999999')
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .padding({ horizontal: 12, vertical: 12 })
        .width('100%')
        .height(48)
        .maxLength(maxLength)
        .type(InputType.Normal)
        .caretColor('#007AFF')
        .border({
          width: error ? 1 : 0,
          color: '#F44336'
        })
        .onChange(onChange)
    }
    .width('100%')
  }

  /**
   * 构建位置信息部分
   */
  @Builder
  private buildLocationSection() {
    Column({ space: 16 }) {
      Text('位置信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 地址输入
      this.buildTextInputField(
        '详细地址',
        this.address,
        (value: string) => {
          this.address = value
          this.hasUnsavedChanges = true
          this.validateAddress()
          // 自动解析地址
          if (value.trim().length > 5) {
            this.geocodeAddress(value.trim())
          }
        },
        this.errors.address,
        '请输入详细地址',
        200
      )

      // 当前位置按钮
      Button() {
        Row({ space: 8 }) {
          if (this.isGettingLocation) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color('#007AFF')
          } else {
            Image($r('app.media.ic_location'))
              .width(20)
              .height(20)
              .fillColor('#007AFF')
          }

          Text(this.isGettingLocation ? '获取中...' : '获取当前位置')
            .fontSize(16)
            .fontColor('#007AFF')
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor('#007AFF20')
      .borderRadius(8)
      .enabled(!this.isGettingLocation)
      .onClick(() => this.getCurrentLocation())

      // 位置信息显示
      if (this.latitude !== 0 || this.longitude !== 0) {
        Column({ space: 12 }) {
          Row() {
            Text('当前位置坐标')
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getLocationText())
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')

          Row() {
            Text('海拔')
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getAltitudeText())
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')

          if (this.locationError) {
            Text(this.locationError)
              .fontSize(12)
              .fontColor('#F44336')
              .width('100%')
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
      }

      // 地图选择按钮
      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_map'))
            .width(20)
            .height(20)
            .fillColor('#007AFF')

          Text('在地图上选择位置')
            .fontSize(16)
            .fontColor('#007AFF')
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor('#007AFF20')
      .borderRadius(8)
      .onClick(() => this.selectLocationOnMap())
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建工点标签部分
   */
  @Builder
  private buildTagsSection() {
    Column({ space: 16 }) {
      Text('工点标签')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 标签输入
      Row({ space: 8 }) {
        TextInput({
          placeholder: '输入标签名称',
          text: this.currentTag
        })
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#999999')
          .backgroundColor('#F8F9FA')
          .borderRadius(8)
          .padding({ horizontal: 12, vertical: 12 })
          .layoutWeight(1)
          .height(48)
          .maxLength(20)
          .type(InputType.Normal)
          .caretColor('#007AFF')
          .onChange((value: string) => {
            this.currentTag = value
          })
          .onSubmit(() => this.addTag())

        Button('添加')
          .height(48)
          .padding({ horizontal: 16 })
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .onClick(() => this.addTag())
      }
      .width('100%')

      // 标签列表
      if (this.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(
            this.tags,
            (tag: string) => {
              Row({ space: 6 }) {
                Text(tag)
                  .fontSize(14)
                  .fontColor('#007AFF')

                Button() {
                  Image($r('app.media.ic_close'))
                    .width(14)
                    .height(14)
                    .fillColor('#007AFF')
                }
                .width(20)
                .height(20)
                .backgroundColor(Color.Transparent)
                .onClick(() => this.removeTag(tag))
              }
              .padding({ horizontal: 10, vertical: 6 })
              .backgroundColor('#007AFF20')
              .borderRadius(16)
              .margin({ right: 8, bottom: 8 })
            },
            (tag: string) => tag
          )
        }
        .width('100%')
      }

      Text(`${this.tags.length}/10 个标签`)
        .fontSize(12)
        .fontColor('#999999')
        .alignSelf(ItemAlign.End)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建工点描述部分
   */
  @Builder
  private buildDescriptionSection() {
    Column({ space: 16 }) {
      Text('工点描述')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      TextArea({
        placeholder: '请输入工点描述...',
        text: this.description
      })
        .fontSize(16)
        .fontColor('#333333')
        .placeholderColor('#999999')
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .padding({ horizontal: 12, vertical: 12 })
        .width('100%')
        .height(120)
        .maxLength(500)
        .type(InputType.Normal)
        .caretColor('#007AFF')
        .border({
          width: this.errors.description ? 1 : 0,
          color: '#F44336'
        })
        .onChange((value: string) => {
          this.description = value
          this.hasUnsavedChanges = true
          this.validateDescription()
        })

      Row() {
        Text('字符数：')
          .fontSize(12)
          .fontColor('#999999')

        Text(`${this.description.length}/500`)
          .fontSize(12)
          .fontColor(this.description.length > 500 ? '#F44336' : '#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

      if (this.errors.description) {
        Text(this.errors.description)
          .fontSize(12)
          .fontColor('#F44336')
          .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建底部操作栏
   */
  @Builder
  private buildBottomActionBar() {
    Row({ space: 12 }) {
      // 查看模式的操作按钮
      if (this.mode === 'view') {
        Button('编辑')
          .height(48)
          .layoutWeight(1)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(24)
          .onClick(() => this.navigateToEdit())

        Button('删除')
          .height(48)
          .layoutWeight(1)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#F44336')
          .borderRadius(24)
          .onClick(() => {
            // TODO: 显示删除确认对话框
          })
      } else {
        // 创建/编辑模式的操作按钮
        Button('取消')
          .height(48)
          .layoutWeight(1)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(24)
          .onClick(() => this.goBack())

        Button(this.mode === 'create' ? '创建' : '保存')
          .height(48)
          .layoutWeight(1)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(24)
          .onClick(() => this.saveSite())
      }
    }
    .width('100%')
    .padding({ horizontal: 16, bottom: 20 })
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}