/**
 * 主界面 - 工程列表
 * 根据原型设计实现的工程管理主界面
 * 包含统计概览、工程列表和底部导航
 */

import router from '@ohos.router'
import { StatCard } from '../components/common/StatCard'
import { SimpleProjectCard } from '../components/project/SimpleProjectCard'
import { SimpleProject, ProjectStatus } from '../models/SimpleProject'

@Entry
@Component
struct MainPage {
  @State private currentTab: string = 'projects'
  @State private searchQuery: string = ''
  @State private selectedProjectCount: number = 3
  @State private selectedSiteCount: number = 12
  @State private selectedPhotoCount: number = 156

  // 模拟工程数据
  private projects: SimpleProject[] = [
    new SimpleProject('P2025-001', '市政道路改造工程', ProjectStatus.ACTIVE, '张三', 4, 52),
    new SimpleProject('P2025-002', '电力线路巡检工程', ProjectStatus.COMPLETED, '李四', 6, 89),
    new SimpleProject('P2025-003', '园林绿化项目', ProjectStatus.PAUSED, '王五', 2, 15)
  ]

  aboutToAppear(): void {
    console.log('MainPage aboutToAppear')
  }

  /**
   * 处理项目卡片点击
   */
  private handleProjectClick(project: SimpleProject): void {
    console.log('Project clicked:', project.name)
    // TODO: 跳转到项目详情页面
    router.pushUrl({
      url: 'pages/project/ProjectDetailPage',
      params: { projectId: project.id }
    }).catch((error: Error) => {
      console.error('跳转到项目详情失败:', error)
    })
  }

  /**
   * 处理项目卡片长按
   */
  private handleProjectLongPress(project: SimpleProject): void {
    console.log('Project long pressed:', project.name)
    // TODO: 显示项目操作菜单
  }

  /**
   * 跳转到拍照页面
   */
  private navigateToCamera(): void {
    console.log('Navigate to camera - Starting navigation')
    try {
      router.pushUrl({
        url: 'pages/camera/CameraPage_Simple',
        params: {}
      }).then(() => {
        console.log('Successfully navigated to camera page')
      }).catch((error: Error) => {
        console.error('跳转到相机页面失败:', error)
      })
    } catch (error) {
      console.error('Navigation to camera failed with exception:', error)
    }
  }

  /**
   * 跳转到相册页面
   */
  private navigateToGallery(): void {
    console.log('Navigate to gallery - Starting navigation')
    try {
      router.pushUrl({
        url: 'pages/gallery/GalleryPlaceholderPage',
        params: {}
      }).then(() => {
        console.log('Successfully navigated to gallery page')
      }).catch((error: Error) => {
        console.error('跳转到相册页面失败:', error)
      })
    } catch (error) {
      console.error('Navigation to gallery failed with exception:', error)
    }
  }

  /**
   * 跳转到设置页面
   */
  private navigateToSettings(): void {
    console.log('Navigate to settings - Starting navigation')
    try {
      router.pushUrl({
        url: 'pages/settings/SettingsPlaceholderPage',
        params: {}
      }).then(() => {
        console.log('Successfully navigated to settings page')
      }).catch((error: Error) => {
        console.error('跳转到设置页面失败:', error)
      })
    } catch (error) {
      console.error('Navigation to settings failed with exception:', error)
    }
  }

  /**
   * 创建新工程
   */
  private createNewProject(): void {
    console.log('Create new project')
    // TODO: 显示创建工程对话框
  }

  /**
   * 搜索项目
   */
  private searchProjects(): void {
    console.log('Search projects:', this.searchQuery)
    // TODO: 实现搜索功能
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 侧边菜单按钮
        Text('☰')
          .fontSize(20)
          .fontColor('#1890FF')
          .onClick(() => {
            console.log('Menu clicked')
            // TODO: 显示侧边菜单
          })

        Blank()

        // 应用标题
        Text('工程相机')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#262626')

        Blank()

        // 搜索按钮
        Text('🔍')
          .fontSize(20)
          .fontColor('#1890FF')
          .backgroundColor('#E6F7FF')
          .borderRadius(12)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .margin({ right: 16 })
          .animation({ duration: 150, curve: Curve.EaseInOut })
          .onClick(() => {
            console.log('Search clicked')
            // TODO: 显示搜索界面
          })

        // 新建按钮
        Text('⊕')
          .fontSize(20)
          .fontColor('#1890FF')
          .backgroundColor('#E6F7FF')
          .borderRadius(12)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .animation({ duration: 150, curve: Curve.EaseInOut })
          .onClick(() => {
            console.log('Create project button clicked')
            this.createNewProject()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E8E8E8' })

      // 主内容区域
      Scroll() {
        Column() {
          // 统计概览
          Column() {
            Text('📊 统计概览')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 12 })

            // 统计卡片行
            Row({ space: 12 }) {
              StatCard({
                title: '工程数',
                value: this.selectedProjectCount.toString(),
                icon: '📁',
                color: '#1890FF'
              })

              StatCard({
                title: '工点数',
                value: this.selectedSiteCount.toString(),
                icon: '📍',
                color: '#52C41A'
              })

              StatCard({
                title: '照片数',
                value: this.selectedPhotoCount.toString(),
                icon: '📷',
                color: '#FAAD14'
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 12 })
          .borderRadius(8)

          // 工程列表标题
          Row() {
            Text('🏗️ 我的工程')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')

            Blank()

            Text(`${this.projects.length}个工程`)
              .fontSize(14)
              .fontColor('#8C8C8C')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })
          .alignItems(VerticalAlign.Center)

          // 工程列表
          Column({ space: 12 }) {
            ForEach(this.projects, (project: SimpleProject, index?: number) => {
              SimpleProjectCard({
                project: project,
                showStats: true,
                onTap: (p: SimpleProject) => this.handleProjectClick(p),
                onLongPress: (p: SimpleProject) => this.handleProjectLongPress(p)
              })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 80 }) // 底部留出导航栏空间
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 底部导航栏
      Row() {
        // 工程导航
        Column() {
          Text('🏗️')
            .fontSize(24)
            .fontColor(this.currentTab === 'projects' ? '#1890FF' : '#8C8C8C')
          Text('工程')
            .fontSize(12)
            .fontColor(this.currentTab === 'projects' ? '#1890FF' : '#8C8C8C')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentTab === 'projects' ? '#E6F7FF' : Color.Transparent)
        .borderRadius(8)
        .padding({ top: 4, bottom: 4 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .onClick(() => {
          console.log('Projects tab clicked')
          this.currentTab = 'projects'
          // 添加触觉反馈效果
          // TODO: 添加触觉反馈
        })

        // 相册导航
        Column() {
          Text('📱')
            .fontSize(24)
            .fontColor(this.currentTab === 'gallery' ? '#1890FF' : '#8C8C8C')
          Text('相册')
            .fontSize(12)
            .fontColor(this.currentTab === 'gallery' ? '#1890FF' : '#8C8C8C')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentTab === 'gallery' ? '#E6F7FF' : Color.Transparent)
        .borderRadius(8)
        .padding({ top: 4, bottom: 4 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .onClick(() => {
          console.log('Gallery tab clicked')
          this.currentTab = 'gallery'
          this.navigateToGallery()
        })

        // 设置导航
        Column() {
          Text('⚙️')
            .fontSize(24)
            .fontColor(this.currentTab === 'settings' ? '#1890FF' : '#8C8C8C')
          Text('设置')
            .fontSize(12)
            .fontColor(this.currentTab === 'settings' ? '#1890FF' : '#8C8C8C')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentTab === 'settings' ? '#E6F7FF' : Color.Transparent)
        .borderRadius(8)
        .padding({ top: 4, bottom: 4 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .onClick(() => {
          console.log('Settings tab clicked')
          this.currentTab = 'settings'
          this.navigateToSettings()
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#E8E8E8' })
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ bottom: 8 }) // 为安全区域留出空间
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}