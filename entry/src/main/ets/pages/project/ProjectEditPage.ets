/**
 * 项目编辑页面
 * 提供项目信息的创建和编辑功能，包含表单验证
 */

import router from '@ohos.router'
import { Project } from '../../models/Project'
import { ProjectStatus } from '../../types/AppTypes'
import { projectStore } from '../../store/project/ProjectStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

interface FormErrors {
  name: string
  code: string
  client: string
  manager: string
  startDate: string
  endDate: string
  description: string
}

@Entry
@Component
struct ProjectEditPage {
  // 表单状态
  @State private mode: 'create' | 'edit' = 'create'
  @State private projectId: string = ''
  @State private isLoading: boolean = false
  @State private isSaving: boolean = false
  @State private hasUnsavedChanges: boolean = false
  @State private showUnsavedDialog: boolean = false

  // 表单字段
  @State private name: string = ''
  @State private code: string = ''
  @State private client: string = ''
  @State private manager: string = ''
  @State private description: string = ''
  @State private startDate: Date = new Date()
  @State private endDate: Date = new Date()
  @State private status: ProjectStatus = ProjectStatus.ACTIVE
  @State private tags: string[] = []
  @State private currentTag: string = ''

  // 表单错误
  @State private errors: FormErrors = {
    name: '',
    code: '',
    client: '',
    manager: '',
    startDate: '',
    endDate: '',
    description: ''
  }

  // UI状态
  @State private showStartDatePicker: boolean = false
  @State private showEndDatePicker: boolean = false
  @State private showStatusSelector: boolean = false

  // Store
  private projectStore = projectStore

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>
    if (params?.mode) {
      this.mode = params.mode as 'create' | 'edit'
    }

    if (params?.projectId && this.mode === 'edit') {
      this.projectId = params.projectId as string
      this.loadProjectData()
    } else if (this.mode === 'create') {
      // 设置默认值
      const today = new Date()
      const tomorrow = new Date(today)
      tomorrow.setDate(tomorrow.getDate() + 30)

      this.startDate = today
      this.endDate = tomorrow
    }
  }

  /**
   * 加载项目数据（编辑模式）
   */
  private async loadProjectData() {
    this.isLoading = true
    try {
      const project = await this.projectStore.getProjectById(this.projectId)
      if (project) {
        this.name = project.name
        this.code = project.code
        this.client = project.client
        this.manager = project.manager
        this.description = project.description
        this.startDate = new Date(project.startDate)
        this.endDate = new Date(project.endDate)
        this.status = project.status
        this.tags = [...project.tags]
      }
    } catch (error) {
      console.error('加载项目数据失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 验证项目名称
   */
  private validateName(): boolean {
    if (this.name.trim() === '') {
      this.errors.name = '项目名称不能为空'
      return false
    } else if (this.name.trim().length < 2) {
      this.errors.name = '项目名称至少需要2个字符'
      return false
    } else if (this.name.trim().length > 50) {
      this.errors.name = '项目名称不能超过50个字符'
      return false
    } else {
      this.errors.name = ''
      return true
    }
  }

  /**
   * 验证项目编号
   */
  private validateCode(): boolean {
    if (this.code.trim() === '') {
      this.errors.code = ''
      return true // 编号不是必填项
    } else if (this.code.trim().length > 20) {
      this.errors.code = '项目编号不能超过20个字符'
      return false
    } else if (!/^[A-Za-z0-9-_]+$/.test(this.code.trim())) {
      this.errors.code = '项目编号只能包含字母、数字、横线和下划线'
      return false
    } else {
      this.errors.code = ''
      return true
    }
  }

  /**
   * 验证客户单位
   */
  private validateClient(): boolean {
    if (this.client.trim() === '') {
      this.errors.client = ''
      return true // 客户不是必填项
    } else if (this.client.trim().length > 50) {
      this.errors.client = '客户单位不能超过50个字符'
      return false
    } else {
      this.errors.client = ''
      return true
    }
  }

  /**
   * 验证项目经理
   */
  private validateManager(): boolean {
    if (this.manager.trim() === '') {
      this.errors.manager = ''
      return true // 项目经理不是必填项
    } else if (this.manager.trim().length > 20) {
      this.errors.manager = '项目经理姓名不能超过20个字符'
      return false
    } else {
      this.errors.manager = ''
      return true
    }
  }

  /**
   * 验证开始日期
   */
  private validateStartDate(): boolean {
    if (!this.startDate) {
      this.errors.startDate = '请选择开始日期'
      return false
    } else if (this.startDate > this.endDate) {
      this.errors.startDate = '开始日期不能晚于结束日期'
      return false
    } else {
      this.errors.startDate = ''
      return true
    }
  }

  /**
   * 验证结束日期
   */
  private validateEndDate(): boolean {
    if (!this.endDate) {
      this.errors.endDate = '请选择结束日期'
      return false
    } else if (this.endDate < this.startDate) {
      this.errors.endDate = '结束日期不能早于开始日期'
      return false
    } else {
      this.errors.endDate = ''
      return true
    }
  }

  /**
   * 验证项目描述
   */
  private validateDescription(): boolean {
    if (this.description.trim() === '') {
      this.errors.description = ''
      return true // 描述不是必填项
    } else if (this.description.trim().length > 500) {
      this.errors.description = '项目描述不能超过500个字符'
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
    const isCodeValid = this.validateCode()
    const isClientValid = this.validateClient()
    const isManagerValid = this.validateManager()
    const isStartDateValid = this.validateStartDate()
    const isEndDateValid = this.validateEndDate()
    const isDescriptionValid = this.validateDescription()

    return isNameValid && isCodeValid && isClientValid &&
           isManagerValid && isStartDateValid && isEndDateValid && isDescriptionValid
  }

  /**
   * 清空所有错误信息
   */
  private clearErrors(): void {
    this.errors = {
      name: '',
      code: '',
      client: '',
      manager: '',
      startDate: '',
      endDate: '',
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
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  }

  /**
   * 解析日期字符串
   */
  private parseDate(dateString: string): Date {
    const [year, month, day] = dateString.split('-').map(Number)
    return new Date(year, month - 1, day)
  }

  /**
   * 保存项目
   */
  private async saveProject(): Promise<void> {
    if (!this.validateAll()) {
      return
    }

    this.isSaving = true
    try {
      const projectData: Partial<Project> = {
        name: this.name.trim(),
        code: this.code.trim(),
        client: this.client.trim(),
        manager: this.manager.trim(),
        description: this.description.trim(),
        startDate: this.startDate,
        endDate: this.endDate,
        status: this.status,
        tags: [...this.tags]
      }

      if (this.mode === 'create') {
        await this.projectStore.createProject(projectData)
      } else {
        const existingProject = await this.projectStore.getProjectById(this.projectId)
        if (existingProject) {
          Object.assign(existingProject, projectData)
          await this.projectStore.updateProject(existingProject)
        }
      }

      this.hasUnsavedChanges = false
      router.back()
    } catch (error) {
      console.error('保存项目失败:', error)
    } finally {
      this.isSaving = false
    }
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    if (this.hasUnsavedChanges) {
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

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 表单内容
      this.buildFormContent()

      // 底部操作栏
      this.buildBottomActionBar()

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 保存对话框
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
      Text(this.mode === 'create' ? '新建项目' : '编辑项目')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位保持标题居中
      Button('')
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .visibility(Visibility.Hidden)
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
   * 构建表单内容
   */
  @Builder
  private buildFormContent() {
    ScrollView() {
      Column({ space: 16 }) {
        // 基本信息
        this.buildBasicInfoSection()

        // 时间设置
        this.buildTimeSection()

        // 项目状态
        this.buildStatusSection()

        // 项目标签
        this.buildTagsSection()

        // 项目描述
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

      // 项目名称
      this.buildTextInputField(
        '项目名称 *',
        this.name,
        (value: string) => {
          this.name = value
          this.hasUnsavedChanges = true
          this.validateName()
        },
        this.errors.name,
        '请输入项目名称',
        50
      )

      // 项目编号
      this.buildTextInputField(
        '项目编号',
        this.code,
        (value: string) => {
          this.code = value
          this.hasUnsavedChanges = true
          this.validateCode()
        },
        this.errors.code,
        '请输入项目编号',
        20
      )

      // 客户单位
      this.buildTextInputField(
        '客户单位',
        this.client,
        (value: string) => {
          this.client = value
          this.hasUnsavedChanges = true
          this.validateClient()
        },
        this.errors.client,
        '请输入客户单位',
        50
      )

      // 项目经理
      this.buildTextInputField(
        '项目经理',
        this.manager,
        (value: string) => {
          this.manager = value
          this.hasUnsavedChanges = true
          this.validateManager()
        },
        this.errors.manager,
        '请输入项目经理姓名',
        20
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
   * 构建时间设置部分
   */
  @Builder
  private buildTimeSection() {
    Column({ space: 16 }) {
      Text('时间设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 开始日期
      this.buildDateField(
        '开始日期 *',
        this.startDate,
        (date: Date) => {
          this.startDate = date
          this.hasUnsavedChanges = true
          this.validateStartDate()
          this.validateEndDate() // 重新验证结束日期
        },
        this.errors.startDate
      )

      // 结束日期
      this.buildDateField(
        '结束日期 *',
        this.endDate,
        (date: Date) => {
          this.endDate = date
          this.hasUnsavedChanges = true
          this.validateEndDate()
          this.validateStartDate() // 重新验证开始日期
        },
        this.errors.endDate
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
   * 构建日期字段
   */
  @Builder
  private buildDateField(
    label: string,
    date: Date,
    onChange: (date: Date) => void,
    error: string
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

      Button() {
        Row({ space: 12 }) {
          Image($r('app.media.ic_calendar'))
            .width(20)
            .height(20)
            .fillColor('#666666')

          Text(this.formatDate(date))
            .fontSize(16)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Image($r('app.media.ic_arrow_down'))
            .width(16)
            .height(16)
            .fillColor('#666666')
        }
        .width('100%')
        .padding({ horizontal: 12, vertical: 12 })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#F8F9FA')
      .borderRadius(8)
      .border({
        width: error ? 1 : 0,
        color: '#F44336'
      })
      .onClick(() => {
        if (label.includes('开始')) {
          this.showStartDatePicker = true
        } else {
          this.showEndDatePicker = true
        }
      })
    }
    .width('100%')
  }

  /**
   * 构建项目状态部分
   */
  @Builder
  private buildStatusSection() {
    Column({ space: 16 }) {
      Text('项目状态')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Button() {
        Row({ space: 12 }) {
          Image($r('app.media.ic_status'))
            .width(20)
            .height(20)
            .fillColor('#666666')

          Text(this.getStatusText(this.status))
            .fontSize(16)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Image($r('app.media.ic_arrow_down'))
            .width(16)
            .height(16)
            .fillColor('#666666')
        }
        .width('100%')
        .padding({ horizontal: 12, vertical: 12 })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#F8F9FA')
      .borderRadius(8)
      .onClick(() => {
        this.showStatusSelector = true
      })

      // 状态选择器
      if (this.showStatusSelector) {
        this.buildStatusSelector()
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
   * 构建状态选择器
   */
  @Builder
  private buildStatusSelector() {
    Column({ space: 0 }) {
      ForEach(
        [
          { key: ProjectStatus.ACTIVE, label: '进行中', color: '#4CAF50' },
          { key: ProjectStatus.COMPLETED, label: '已完成', color: '#2196F3' },
          { key: ProjectStatus.PAUSED, label: '已暂停', color: '#FF9800' },
          { key: ProjectStatus.CANCELLED, label: '已取消', color: '#F44336' }
        ],
        (status: { key: ProjectStatus, label: string, color: string }) => {
          Row() {
            Row({ space: 8 }) {
              Circle({ width: 8, height: 8 })
                .fill(status.color)

              Text(status.label)
                .fontSize(16)
                .fontColor(this.status === status.key ? '#007AFF' : '#333333')
                .layoutWeight(1)
            }
            .layoutWeight(1)

            if (this.status === status.key) {
              Image($r('app.media.ic_check'))
                .width(20)
                .height(20)
                .fillColor('#007AFF')
            }
          }
          .width('100%')
          .height(48)
          .padding({ horizontal: 16 })
          .onClick(() => {
            this.status = status.key
            this.showStatusSelector = false
            this.hasUnsavedChanges = true
          })

          if (status.key !== ProjectStatus.CANCELLED) {
            Divider().color('#F0F0F0')
          }
        },
        (status: { key: ProjectStatus, label: string, color: string }) => status.key
      )
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ top: 8 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 2
    })
    .zIndex(10)
  }

  /**
   * 构建项目标签部分
   */
  @Builder
  private buildTagsSection() {
    Column({ space: 16 }) {
      Text('项目标签')
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
   * 构建项目描述部分
   */
  @Builder
  private buildDescriptionSection() {
    Column({ space: 16 }) {
      Text('项目描述')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      TextArea({
        placeholder: '请输入项目描述...',
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
      // 取消按钮
      Button('取消')
        .height(48)
        .layoutWeight(1)
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor('#F0F0F0')
        .borderRadius(24)
        .onClick(() => this.goBack())

      // 保存按钮
      Button(this.mode === 'create' ? '创建' : '保存')
        .height(48)
        .layoutWeight(1)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(24)
        .onClick(() => this.saveProject())
    }
    .width('100%')
    .padding({ horizontal: 16, bottom: 20 })
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  /**
   * 获取状态文本
   */
  private getStatusText(status: ProjectStatus): string {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return '进行中'
      case ProjectStatus.COMPLETED:
        return '已完成'
      case ProjectStatus.PAUSED:
        return '已暂停'
      case ProjectStatus.CANCELLED:
        return '已取消'
      default:
        return '未知状态'
    }
  }
}