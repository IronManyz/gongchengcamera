/**
 * 项目详情页面
 * 显示项目详细信息，管理工点列表，提供项目统计和操作功能
 */

import router from '@ohos.router'
import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { ProjectStatus } from '../../types/AppTypes'
import { projectStore } from '../../store/project/ProjectStore'
import { siteStore } from '../../store/site/SiteStore'
import { SearchBar } from '../../components/common/SearchBar'
import { EmptyView } from '../../components/common/EmptyView'
import { LoadingDialog } from '../../components/common/LoadingDialog'
import { ConfirmDialog } from '../../components/common/ConfirmDialog'

@Entry
@Component
struct ProjectDetailPage {
  // 状态管理
  @State private projectId: string = ''
  @State private isLoading: boolean = false
  @State private isRefreshing: boolean = false
  @State private searchQuery: string = ''
  @State private selectedSite: Site | null = null
  @State private showDeleteSiteDialog: boolean = false
  @State private showProjectActionDialog: boolean = false
  @State private currentTab: number = 0 // 0: 详情, 1: 工点, 2: 统计

  // 数据
  @State private project: Project | null = null
  @State private sites: Site[] = []
  @State private filteredSites: Site[] = []

  // Store
  private projectStore = projectStore
  private siteStore = siteStore

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>
    if (params?.projectId) {
      this.projectId = params.projectId as string
      this.loadProjectData()
    }
  }

  aboutToDisappear() {
    // 清理当前项目关联
    this.siteStore.setCurrentProject(null)
  }

  /**
   * 加载项目数据
   */
  private async loadProjectData() {
    this.isLoading = true
    try {
      // 加载项目详情
      this.project = await this.projectStore.getProjectById(this.projectId)

      if (this.project) {
        // 设置当前项目到工点Store
        this.siteStore.setCurrentProject(this.projectId)

        // 加载项目工��
        await this.siteStore.loadProjectSites(this.projectId)
        this.sites = [...this.siteStore.projectSites]
        this.filteredSites = [...this.sites]
      }
    } catch (error) {
      console.error('加载项目数据失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 下拉刷新
   */
  private async onRefresh() {
    this.isRefreshing = true
    try {
      if (this.project) {
        await this.projectStore.refresh()
        await this.siteStore.refresh()
        await this.loadProjectData()
      }
    } catch (error) {
      console.error('刷新项目数据失败:', error)
    } finally {
      this.isRefreshing = false
    }
  }

  /**
   * 搜索工点
   */
  private onSearch(query: string) {
    this.searchQuery = query
    this.siteStore.setSearchQuery(query)
    this.filteredSites = this.siteStore.filteredSites
  }

  /**
   * 跳转到编辑项目
   */
  private navigateToEditProject() {
    if (this.project) {
      router.pushUrl({
        url: 'pages/project/ProjectEditPage',
        params: {
          mode: 'edit',
          projectId: this.project.id
        }
      })
    }
  }

  /**
   * 跳转到创建工点
   */
  private navigateToCreateSite() {
    if (this.project) {
      router.pushUrl({
        url: 'pages/project/SiteManagePage',
        params: {
          mode: 'create',
          projectId: this.project.id
        }
      })
    }
  }

  /**
   * 跳转到工点详情
   */
  private navigateToSiteDetail(site: Site) {
    router.pushUrl({
      url: 'pages/project/SiteManagePage',
      params: {
        mode: 'view',
        siteId: site.id
      }
    })
  }

  /**
   * 跳转到编辑工点
   */
  private navigateToEditSite(site: Site) {
    router.pushUrl({
      url: 'pages/project/SiteManagePage',
      params: {
        mode: 'edit',
        siteId: site.id
      }
    })
  }

  /**
   * 跳转到相机页面拍照
   */
  private navigateToCamera(site?: Site) {
    router.pushUrl({
      url: 'pages/camera/CameraPage',
      params: {
        projectId: this.projectId,
        siteId: site?.id
      }
    })
  }

  /**
   * 跳转到项目相册
   */
  private navigateToProjectGallery() {
    if (this.project) {
      router.pushUrl({
        url: 'pages/gallery/GalleryPage',
        params: {
          projectId: this.project.id
        }
      })
    }
  }

  /**
   * 删除工点
   */
  private async deleteSite() {
    if (this.selectedSite) {
      const success = await this.siteStore.deleteSite(this.selectedSite.id)
      if (success) {
        this.selectedSite = null
        this.showDeleteSiteDialog = false
        // 重新加载工点列表
        this.sites = [...this.siteStore.projectSites]
        this.filteredSites = [...this.siteStore.filteredSites]
      }
    }
  }

  /**
   * 删除项目
   */
  private async deleteProject() {
    if (this.project) {
      const success = await this.projectStore.deleteProject(this.project.id)
      if (success) {
        router.back()
      }
    }
  }

  /**
   * 获取项目状态颜色
   */
  private getProjectStatusColor(status: ProjectStatus): string {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return '#4CAF50'
      case ProjectStatus.COMPLETED:
        return '#2196F3'
      case ProjectStatus.PAUSED:
        return '#FF9800'
      case ProjectStatus.CANCELLED:
        return '#F44336'
      default:
        return '#757575'
    }
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  }

  /**
   * 计算项目进度
   */
  private getProjectProgress(): number {
    if (!this.project) return 0
    return this.project.getProgressPercentage()
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // Tab切换栏
      this.buildTabBar()

      // 内容区域
      if (this.currentTab === 0) {
        this.buildProjectDetails()
      } else if (this.currentTab === 1) {
        this.buildSiteList()
      } else {
        this.buildProjectStatistics()
      }

      // 底部操作栏
      this.buildBottomActionBar()

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '加载中...' })
      }

      // 删除工点确认对话框
      if (this.showDeleteSiteDialog && this.selectedSite) {
        ConfirmDialog({
          title: '删除工点',
          message: `确定要删除工点"${this.selectedSite.getDisplayName()}"吗？此操作不可恢复。`,
          confirmText: '删除',
          cancelText: '取消',
          onConfirm: () => this.deleteSite(),
          onCancel: () => {
            this.showDeleteSiteDialog = false
            this.selectedSite = null
          }
        })
      }

      // 项目操作对话框
      if (this.showProjectActionDialog && this.project) {
        this.buildProjectActionDialog()
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
      .onClick(() => {
        router.back()
      })

      // 项目名称
      Text(this.project?.getDisplayName() || '项目详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 更多操作按钮
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
        this.showProjectActionDialog = true
      })
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
   * 构建Tab切换栏
   */
  @Builder
  private buildTabBar() {
    Row() {
      ForEach(
        [
          { key: 0, title: '项目详情', icon: $r('app.media.ic_info') },
          { key: 1, title: '工点管理', icon: $r('app.media.ic_location') },
          { key: 2, title: '项目统计', icon: $r('app.media.ic_chart') }
        ],
        (tab: { key: number, title: string, icon: Resource }) => {
          Column({ space: 4 }) {
            Image(tab.icon)
              .width(20)
              .height(20)
              .fillColor(this.currentTab === tab.key ? '#007AFF' : '#999999')

            Text(tab.title)
              .fontSize(12)
              .fontColor(this.currentTab === tab.key ? '#007AFF' : '#999999')
          }
          .height(56)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.currentTab = tab.key
          })
        },
        (tab: { key: number, title: string, icon: Resource }) => tab.key.toString()
      )
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  /**
   * 构建项目详情页面
   */
  @Builder
  private buildProjectDetails() {
    if (this.project) {
      Refresh({ refreshing: $$isRefreshing, friction: 100 }) {
        ScrollView() {
          Column({ space: 16 }) {
            // 项目基本信息卡片
            this.buildProjectInfoCard()

            // 项目进度卡片
            this.buildProjectProgressCard()

            // 项目描述卡片
            if (this.project.description) {
              this.buildProjectDescriptionCard()
            }

            // 项目标签卡片
            if (this.project.tags.length > 0) {
              this.buildProjectTagsCard()
            }

            // 快速操作卡片
            this.buildQuickActionsCard()
          }
          .width('100%')
          .padding({ horizontal: 16, vertical: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .onRefresh(() => this.onRefresh())
      }
    } else {
      EmptyView({
        icon: $r('app.media.ic_error'),
        message: '项目不存在',
        description: '请检查项目ID是否正确'
      })
        .layoutWeight(1)
        .margin({ horizontal: 16 })
    }
  }

  /**
   * 构建项目信息卡片
   */
  @Builder
  private buildProjectInfoCard() {
    Column({ space: 16 }) {
      // 项目名称和状态
      Row({ space: 12 }) {
        Text(this.project?.getDisplayName() || '')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(this.project?.getStatusText() || '')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding({ horizontal: 12, vertical: 6 })
          .backgroundColor(this.getProjectStatusColor(this.project?.status || ProjectStatus.ACTIVE))
          .borderRadius(16)
      }
      .width('100%')

      Divider().color('#F0F0F0')

      // 项目详细信息
      Column({ space: 12 }) {
        if (this.project?.code) {
          this.buildInfoItem('项目编号', this.project.code)
        }

        if (this.project?.client) {
          this.buildInfoItem('客户单位', this.project.client)
        }

        if (this.project?.manager) {
          this.buildInfoItem('项目经理', this.project.manager)
        }

        this.buildInfoItem('开始日期', this.formatDate(this.project?.startDate || new Date()))
        this.buildInfoItem('结束日期', this.formatDate(this.project?.endDate || new Date()))

        this.buildInfoItem('创建时间', this.formatDate(this.project?.createdAt || new Date()))
        this.buildInfoItem('更新时间', this.formatDate(this.project?.updatedAt || new Date()))
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
    }
    .width('100%')
  }

  /**
   * 构建项目进度卡片
   */
  @Builder
  private buildProjectProgressCard() {
    Column({ space: 12 }) {
      Row() {
        Text('项目进度')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text(`${this.getProjectProgress()}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#007AFF')
      }
      .width('100%')

      // 进度条
      Progress({
        value: this.getProjectProgress(),
        total: 100,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(8)
        .backgroundColor('#F0F0F0')
        .color('#007AFF')
        .borderRadius(4)

      // 工点和照片统计
      Row({ space: 24 }) {
        Column({ space: 4 }) {
          Text(`${this.project?.siteCount || 0}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Text('工点数量')
            .fontSize(12)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text(`${this.project?.photoCount || 0}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Text('照片数量')
            .fontSize(12)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text(`${this.project?.getDurationInDays() || 0}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Text('项目天数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 8 })
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
   * 构建项目描述卡片
   */
  @Builder
  private buildProjectDescriptionCard() {
    Column({ space: 12 }) {
      Text('项目描述')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Text(this.project?.description || '')
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(22)
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
   * 构建项目标签卡片
   */
  @Builder
  private buildProjectTagsCard() {
    Column({ space: 12 }) {
      Text('项目标签')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(
          this.project?.tags || [],
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
   * 构建快速操作卡片
   */
  @Builder
  private buildQuickActionsCard() {
    Column({ space: 12 }) {
      Text('快速操作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Grid() {
        GridItem() {
          this.buildQuickActionButton(
            $r('app.media.ic_camera'),
            '拍摄照片',
            () => this.navigateToCamera()
          )
        }

        GridItem() {
          this.buildQuickActionButton(
            $r('app.media.ic_gallery'),
            '查看相册',
            () => this.navigateToProjectGallery()
          )
        }

        GridItem() {
          this.buildQuickActionButton(
            $r('app.media.ic_edit'),
            '编辑项目',
            () => this.navigateToEditProject()
          )
        }

        GridItem() {
          this.buildQuickActionButton(
            $r('app.media.ic_export'),
            '导出数据',
            () => {
              // TODO: 实现导出功能
            }
          )
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
      .width('100%')
      .height(120)
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
   * 构建快速操作按钮
   */
  @Builder
  private buildQuickActionButton(icon: Resource, title: string, onClick: () => void) {
    Column({ space: 8 }) {
      Image(icon)
        .width(32)
        .height(32)
        .fillColor('#007AFF')

      Text(title)
        .fontSize(12)
        .fontColor('#333333')
    }
    .width('100%')
    .height(100%)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F8F9FA')
    .borderRadius(8)
    .onClick(onClick)
  }

  /**
   * 构建工点列表页面
   */
  @Builder
  private buildSiteList() {
    Column({ space: 12 }) {
      // 搜索栏
      SearchBar({
        query: this.searchQuery,
        placeholder: '搜索工点名称、地址...',
        onSearch: (query: string) => this.onSearch(query),
        onChange: (query: string) => {
          this.searchQuery = query
          // 实时搜索
          this.onSearch(query)
        }
      })

      // 工点列表
      if (this.filteredSites.length > 0) {
        List({ space: 12 }) {
          ForEach(
            this.filteredSites,
            (site: Site) => {
              ListItem() {
                this.buildSiteItem(site)
              }
            },
            (site: Site) => site.id
          )
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ horizontal: 16 })
      } else {
        EmptyView({
          icon: $r('app.media.ic_empty_sites'),
          message: this.searchQuery ? '未找到匹配的工点' : '暂无工点',
          description: this.searchQuery ? '尝试修改搜索条件' : '点击下方按钮创建第一个工点'
        })
          .layoutWeight(1)
          .margin({ horizontal: 16 })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ vertical: 12 })
  }

  /**
   * 构建工点项
   */
  @Builder
  private buildSiteItem(site: Site) {
    Column({ space: 12 }) {
      // 工点基本信息
      Row({ space: 12 }) {
        Column({ space: 8 }) {
          // 工点名称
          Text(site.getDisplayName())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 工点地址
          Text(site.getFullAddress())
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          // 工点描述（如果有）
          if (site.description) {
            Text(site.description)
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 位置图标和操作按钮
        Column({ space: 8 }) {
          if (site.hasValidLocation()) {
            Image($r('app.media.ic_location_on'))
              .width(20)
              .height(20)
              .fillColor('#4CAF50')
          }

          Button() {
            Image($r('app.media.ic_more'))
              .width(20)
              .height(20)
              .fillColor('#666666')
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            // 显示更多操作菜单
          })
        }
      }
      .width('100%')

      // 工点统计信息
      Row({ space: 16 }) {
        Text(`${site.photoCount} 张照片`)
          .fontSize(12)
          .fontColor('#666666')

        if (site.tags.length > 0) {
          Text(`${site.tags.length} 个标签`)
            .fontSize(12)
            .fontColor('#666666')
        }

        if (site.hasValidLocation()) {
          Text(site.getCoordinateText())
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.navigateToSiteDetail(site))
    .onLongPress(() => {
      this.selectedSite = site
      this.showDeleteSiteDialog = true
    })
  }

  /**
   * 构建项目统计页面
   */
  @Builder
  private buildProjectStatistics() {
    ScrollView() {
      Column({ space: 16 }) {
        // 项目概览统计
        this.buildOverviewStatistics()

        // 工点分布统计
        this.buildSiteStatistics()

        // 照片统计
        this.buildPhotoStatistics()

        // 时间统计
        this.buildTimeStatistics()
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /**
   * 构建概览统计
   */
  @Builder
  private buildOverviewStatistics() {
    Column({ space: 16 }) {
      Text('项目概览')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row({ space: 16 }) {
        Column({ space: 8 }) {
          Text(`${this.project?.siteCount || 0}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007AFF')

          Text('总工点数')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 8 }) {
          Text(`${this.project?.photoCount || 0}`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')

          Text('总照片数')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 8 }) {
          Text(`${this.getProjectProgress()}%`)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')

          Text('完成进度')
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
   * 构建工点统计
   */
  @Builder
  private buildSiteStatistics() {
    Column({ space: 16 }) {
      Text('工点分布')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      // 工点位置分布（简化版）
      Column({ space: 12 }) {
        Row() {
          Text('有位置信息')
            .fontSize(14)
            .fontColor('#666666')

          Text(`${this.sites.filter(s => s.hasValidLocation()).length}`)
            .fontSize(14)
            .fontColor('#333333')

          Blank()

          Text(`${Math.round((this.sites.filter(s => s.hasValidLocation()).length / Math.max(this.sites.length, 1)) * 100)}%`)
            .fontSize(14)
            .fontColor('#007AFF')
        }
        .width('100%')

        Progress({
          value: this.sites.filter(s => s.hasValidLocation()).length,
          total: Math.max(this.sites.length, 1),
          type: ProgressType.Linear
        })
          .width('100%')
          .height(6)
          .backgroundColor('#F0F0F0')
          .color('#007AFF')
          .borderRadius(3)
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
   * 构建照片统计
   */
  @Builder
  private buildPhotoStatistics() {
    Column({ space: 16 }) {
      Text('照片统计')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row({ space: 16 }) {
        Column({ space: 8 }) {
          Text(`${this.project?.photoCount || 0}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')

          Text('总照片数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 8 }) {
          Text(`${Math.round((this.project?.photoCount || 0) / Math.max(this.project?.siteCount || 1, 1))}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')

          Text('平均每工点')
            .fontSize(12)
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
   * 构建时间统计
   */
  @Builder
  private buildTimeStatistics() {
    if (!this.project) return

    Column({ space: 16 }) {
      Text('时间统计')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 12 }) {
        this.buildInfoItem('项目总天数', `${this.project.getDurationInDays()} 天`)
        this.buildInfoItem('已进行天数', `${Math.max(0, Math.min(this.project.getDurationInDays(), Math.floor((new Date().getTime() - this.project.startDate.getTime()) / (1000 * 60 * 60 * 24))))} 天`)
        this.buildInfoItem('剩余天数', `${Math.max(0, Math.floor((this.project.endDate.getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)))} 天`)
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
   * 构建底部操作栏
   */
  @Builder
  private buildBottomActionBar() {
    Row({ space: 12 }) {
      // 拍照按钮
      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_camera'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')

          Text('拍照')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
      }
      .height(48)
      .layoutWeight(1)
      .backgroundColor('#4CAF50')
      .borderRadius(24)
      .onClick(() => this.navigateToCamera())

      // 创建工点按钮
      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')

          Text('新建工点')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
      }
      .height(48)
      .layoutWeight(1)
      .backgroundColor('#007AFF')
      .borderRadius(24)
      .onClick(() => this.navigateToCreateSite())
    }
    .width('100%')
    .padding({ horizontal: 16, bottom: 20 })
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  /**
   * 构建项目操作对话框
   */
  @Builder
  private buildProjectActionDialog() {
    Column({ space: 0 }) {
      // 项目操作选项
      ForEach(
        [
          { key: 'edit', label: '编辑项目', icon: $r('app.media.ic_edit'), action: () => this.navigateToEditProject() },
          { key: 'gallery', label: '查看相册', icon: $r('app.media.ic_gallery'), action: () => this.navigateToProjectGallery() },
          { key: 'export', label: '导出数据', icon: $r('app.media.ic_export'), action: () => { /* TODO: 导出功能 */ } },
          { key: 'delete', label: '删除项目', icon: $r('app.media.ic_delete'), action: () => this.deleteProject(), isDestructive: true }
        ],
        (option: { key: string, label: string, icon: Resource, action: () => void, isDestructive?: boolean }) => {
          Row({ space: 12 }) {
            Image(option.icon)
              .width(20)
              .height(20)
              .fillColor(option.isDestructive ? '#F44336' : '#333333')

            Text(option.label)
              .fontSize(16)
              .fontColor(option.isDestructive ? '#F44336' : '#333333')
              .layoutWeight(1)

            if (option.isDestructive) {
              Text('删除后不可恢复')
                .fontSize(12)
                .fontColor('#999999')
            }
          }
          .width('100%')
          .height(48)
          .padding({ horizontal: 16 })
          .onClick(() => {
            this.showProjectActionDialog = false
            option.action()
          })

          if (option.key !== 'delete') {
            Divider().color('#F0F0F0')
          }
        },
        (option: { key: string, label: string, icon: Resource, action: () => void }) => option.key
      )

      // 取消按钮
      Button('取消')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor('#007AFF')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showProjectActionDialog = false
        })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ horizontal: 16 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 2
    })
    .zIndex(10)
  }
}