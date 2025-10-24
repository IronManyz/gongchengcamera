/**
 * 项目详情页面
 * 根据原型设计实现的项目管理和工点管理界面
 */

import router from '@ohos.router'
import { SimpleProject, ProjectStatus } from '../../models/SimpleProject'
import { SimpleSite } from '../../models/SimpleSite'
import { SiteCard } from '../../components/site/SiteCard'
import { StatCard } from '../../components/common/StatCard'

@Entry
@ComponentV2
struct ProjectDetailPage_Simple {
  @Local private currentTab: string = 'sites'
  @Local private project: SimpleProject = new SimpleProject()
  @Local private sites: SimpleSite[] = []
  @Local private isLoading: boolean = false

  aboutToAppear(): void {
    this.loadProjectData()
    this.loadSites()
  }

  /**
   * 加载项目数据
   */
  private loadProjectData(): void {
    console.log('=== ProjectDetailPage_Simple.loadProjectData() ===')

    // 从路由参数获取项目ID
    const params = router.getParams() as Record<string, Object>
    const projectId = params?.projectId as string
    console.log('Received projectId:', projectId)

    if (projectId) {
      // 模拟数据库查询 - 根据ID查找项目
      const mockProjects = this.createMockProjects()
      const foundProject = mockProjects.find(p => p.id === projectId)

      if (foundProject) {
        this.project = foundProject
        console.log('Project found:', this.project.name)
      } else {
        // 如果没找到，使用默认数据
        console.log('Project not found, using default data')
        this.project = new SimpleProject(
          projectId,
          '市政道路改造工程',
          ProjectStatus.ACTIVE,
          '张三',
          4,
          52
        )
        this.project.code = 'P2025-001'
        this.project.client = '市建集团'
        this.project.description = '城市主干道改造工程，包括路面翻新、排水系统升级等'
      }
    } else {
      console.error('No projectId provided in navigation parameters')
    }

    console.log('Project data loaded - Name:', this.project.name, 'Status:', this.project.status)
    console.log('=== End loadProjectData ===')
  }

  /**
   * 创建模拟项目数据
   */
  private createMockProjects(): SimpleProject[] {
    const projectA = new SimpleProject('P2025-001', '市政道路改造工程', ProjectStatus.ACTIVE, '张三', 4, 52)
    projectA.code = 'P2025-001'
    projectA.client = '市政建设局'
    projectA.description = '市区��干道改造，一期覆盖 4 个工点，持续优化排水系统与道路铺装。'

    const projectB = new SimpleProject('P2025-002', '电力线路巡检工程', ProjectStatus.COMPLETED, '李四', 6, 89)
    projectB.code = 'P2025-002'
    projectB.client = '国家电网'
    projectB.description = '城区高压线路巡检与隐患排查，输出巡检照片与整改单。'

    const projectC = new SimpleProject('P2025-003', '园林绿化项目', ProjectStatus.PAUSED, '王五', 2, 15)
    projectC.code = 'P2025-003'
    projectC.client = '城市园林管理处'
    projectC.description = '城区绿化提升工程，当前因设计调整暂缓施工。'

    return [projectA, projectB, projectC]
  }

  /**
   * 加载工点列表
   */
  private async loadSites(): Promise<void> {
    this.isLoading = true

    try {
      // TODO: 从数据库加载工点数据
      // 临时使用模拟数据
      this.sites = [
        this.createMockSite('1', '北环路段 K3+200', 116.404, 39.915, 58, 24),
        this.createMockSite('2', '南环路段 K5+800', 116.408, 39.910, 62, 15),
        this.createMockSite('3', '东环立交桥', 116.420, 39.920, 55, 8),
        this.createMockSite('4', '西环路交叉口', 116.395, 39.925, 48, 5)
      ]
    } catch (error) {
      console.error('加载工点失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 创建模拟工点数据
   */
  private createMockSite(id: string, name: string, lng: number, lat: number, alt: number, photoCount: number): SimpleSite {
    const site = new SimpleSite(id, name, this.project.id)
    site.longitude = lng
    site.latitude = lat
    site.altitude = alt
    site.photoCount = photoCount
    site.address = `${name}附近`
    site.description = `${name}施工区域`
    site.lastPhotoTime = new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000) // 随机时间
    return site
  }

  /**
   * 返回上一页
   */
  private navigateBack(): void {
    router.back()
  }

  /**
   * 处理工点拍照
   */
  private handleSiteCamera(site: SimpleSite): void {
    console.log('Site camera:', site.name)
    // TODO: 跳转到相机页面，并传入工点信息
    router.pushUrl({
      url: 'pages/camera/CameraPage_Simple',
      params: {
        projectId: this.project.id,
        siteId: site.id,
        siteName: site.name
      }
    }).catch((error: Error) => {
      console.error('跳转到相机失败:', error)
    })
  }

  /**
   * 查看工点照片
   */
  private handleSiteView(site: SimpleSite): void {
    console.log('View site photos:', site.name)
    router.pushUrl({
      url: 'pages/site/SitePhotoPage',
      params: {
        projectId: this.project.id,
        siteId: site.id,
        siteName: site.name
      }
    }).catch((error: Error) => {
      console.error('跳转到工点照片失败:', error)
    })
  }

  /**
   * 创建新工点
   */
  private createNewSite(): void {
    console.log('Create new site')
    // TODO: 显示创建工点对话框
    // 支持手动输入或地图选点
  }

  /**
   * 导出数据
   * 注意: 此方法不再被快捷操作调用，但保留供其他功能使用
   */
  private exportData(): void {
    console.log('Export project data')
    // TODO: 导出项目数据和照片
  }

  /**
   * 生成报告
   * 注意: 此方法不再被快捷操作调用，但保留供其他功能使用
   */
  private generateReport(): void {
    console.log('Generate report')
    // TODO: 生成项目报告
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 返回按钮
        Text('←')
          .fontSize(24)
          .fontColor('#1890FF')
          .onClick(() => {
            this.navigateBack()
          })

        Blank()

        // 项目名称
        Text(this.project.getDisplayName())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        // 操作按钮
        Row({ space: 12 }) {
          Text('📤')
            .fontSize(20)
            .fontColor('#1890FF')
            .onClick(() => {
              this.exportData()
            })

          Text('⋮')
            .fontSize(20)
            .fontColor('#1890FF')
            .onClick(() => {
              console.log('More options')
              // TODO: 显示更多操作菜单
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E8E8E8' })

      // 项目信息区域
      Column() {
        Row() {
          // 项目状态
          Text(this.project.getStatusText())
            .fontSize(14)
            .fontColor(this.project.getStatusColor())
            .backgroundColor(this.project.getStatusColor() + '15')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(10)

          Blank()

          // 项目编号
          Text(this.project.code)
            .fontSize(14)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 项目基本信息
        Row() {
          Column() {
            Text('负责人')
              .fontSize(12)
              .fontColor('#8C8C8C')
            Text(this.project.manager)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .margin({ top: 4 })
          }
          .layoutWeight(1)

          Column() {
            Text('客户')
              .fontSize(12)
              .fontColor('#8C8C8C')
            Text(this.project.client)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .margin({ top: 4 })
          }
          .layoutWeight(1)

          Column() {
            Text('工点数')
              .fontSize(12)
              .fontColor('#8C8C8C')
            Text(this.project.siteCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .margin({ top: 4 })
          }
          .layoutWeight(1)

          Column() {
            Text('照片数')
              .fontSize(12)
              .fontColor('#8C8C8C')
            Text(this.project.photoCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
        }
        .width('100%')

        // 项目描述
        if (this.project.description) {
          Text(this.project.description)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 12 })
            .width('100%')
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .margin({ bottom: 12 })

      // Tab导航
      Row() {
        TabBar({ tab: '概况', current: this.currentTab === 'overview', onTap: () => { this.currentTab = 'overview' } })

        TabBar({ tab: '工点', current: this.currentTab === 'sites', onTap: () => { this.currentTab = 'sites' } })

        TabBar({ tab: '相册', current: this.currentTab === 'photos', onTap: () => { this.currentTab = 'photos' } })

        TabBar({ tab: '团队', current: this.currentTab === 'team', onTap: () => { this.currentTab = 'team' } })

        TabBar({ tab: '设置', current: this.currentTab === 'settings', onTap: () => { this.currentTab = 'settings' } })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 2 }, color: '#E8E8E8' })

      // 内容区域
      Scroll() {
        Column() {
          if (this.currentTab === 'sites') {
            this.buildSitesTab()
          } else {
            // TODO: 实现其他Tab页面
            this.buildComingSoonTab()
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建工点Tab内容
   */
  @Builder
  private buildSitesTab() {
    Column() {
      // 工点列表标题
      Row() {
        Text('📍 工点列表')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#262626')

        Blank()

        Text(`${this.sites.length}个工点`)
          .fontSize(14)
          .fontColor('#8C8C8C')

        Button('+ 新建')
          .fontSize(14)
          .fontColor('#1890FF')
          .backgroundColor('transparent')
          .onClick(() => {
            this.createNewSite()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 工点列表
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#8C8C8C')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.sites.length === 0) {
        Column() {
          Text('📍')
            .fontSize(48)
            .fontColor('#C0C0C0')
            .margin({ bottom: 16 })

          Text('暂无工点')
            .fontSize(16)
            .fontColor('#8C8C8C')
            .margin({ bottom: 8 })

          Text('点击上方"新建"按钮创建第一个工点')
            .fontSize(14)
            .fontColor('#BFBFBF')
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 12 }) {
          ForEach(this.sites, (site: SimpleSite) => {
            SiteCard({
              site: site,
              showThumbnails: true,
              showLocation: true,
              onCamera: (s: SimpleSite) => this.handleSiteCamera(s),
              onView: (s: SimpleSite) => this.handleSiteView(s),
              onTap: (s: SimpleSite) => this.handleSiteView(s),
              onLongPress: (s: SimpleSite) => {
                console.log('Site long press:', s.name)
                // TODO: 显示工点操作菜单
              }
            })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 80 })
      }
    }
  }

  /**
   * 构建开发中Tab内容
   */
  @Builder
  private buildComingSoonTab() {
    Column() {
      Text('⏳')
        .fontSize(48)
        .fontColor('#C0C0C0')
        .margin({ bottom: 16 })

      Text('功能开发中')
        .fontSize(16)
        .fontColor('#8C8C8C')
        .margin({ bottom: 8 })

      Text('该功能正在开发中，敬请期待')
        .fontSize(14)
        .fontColor('#BFBFBF')
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * Tab栏组件
 */
@ComponentV2
struct TabBar {
  @Param tab: string = ''
  @Param current: boolean = false
  @Param onTap: () => void = () => {}

  build() {
    Column() {
      Text(this.tab)
        .fontSize(14)
        .fontWeight(this.current ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.current ? '#1890FF' : '#8C8C8C')
        .padding({ top: 12, bottom: 12 })

      if (this.current) {
        Divider()
          .strokeWidth(2)
          .color('#1890FF')
          .width('80%')
      }
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onTap()
    })
  }
}