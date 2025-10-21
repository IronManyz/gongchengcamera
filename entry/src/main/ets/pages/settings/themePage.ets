/**
 * 主题配置页面
 * 提供主题选择、预览和切换效果功能
 */

import router from '@ohos.router'
import { Logger } from '../../utils/Logger'
import { ThemeStore, ThemeType } from '../../store/theme/ThemeStore'
import { LoadingDialog } from '../../components/common/LoadingDialog'

/**
 * 主题预设接口
 */
interface ThemePreset {
  type: ThemeType
  name: string
  description: string
  preview: {
    primary: string
    background: string
    surface: string
    text: string
  }
  icon?: Resource
}

@Entry
@Component
struct ThemePage {
  private logger = new Logger('ThemePage')
  private themeStore = ThemeStore.getInstance()

  // 路由参数
  private settingsId: string = ''
  private settingsTitle: string = ''

  // 状态管理
  @State private isLoading: boolean = false
  @State private currentTheme: ThemeType = ThemeType.SYSTEM
  @State private selectedTheme: ThemeType = ThemeType.SYSTEM
  @State private showPreview: boolean = false
  @State private previewTheme: ThemeType = ThemeType.LIGHT

  // 主题预设
  @State private themePresets: ThemePreset[] = []

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as any
    this.settingsId = params?.settingsId || ''
    this.settingsTitle = params?.settingsTitle || '主题配置'

    this.logger.info('ThemePage appeared', { settingsId: this.settingsId })

    this.initializeThemePresets()
    this.loadCurrentTheme()
  }

  aboutToDisappear() {
    this.logger.info('ThemePage disappeared')
  }

  /**
   * 初始化主题预设
   */
  private initializeThemePresets() {
    this.themePresets = [
      {
        type: ThemeType.LIGHT,
        name: '浅色主题',
        description: '明亮清新的界面风格，适合白天使用',
        preview: {
          primary: '#007AFF',
          background: '#FFFFFF',
          surface: '#F2F2F7',
          text: '#000000'
        },
        icon: $r('app.media.ic_theme_light')
      },
      {
        type: ThemeType.DARK,
        name: '深色主题',
        description: '深邃护眼的界面风格，适合夜间使用',
        preview: {
          primary: '#0A84FF',
          background: '#000000',
          surface: '#1C1C1E',
          text: '#FFFFFF'
        },
        icon: $r('app.media.ic_theme_dark')
      },
      {
        type: ThemeType.SYSTEM,
        name: '跟随系统',
        description: '自动跟随系统深色模式设置',
        preview: {
          primary: '#007AFF',
          background: '#FFFFFF',
          surface: '#F2F2F7',
          text: '#000000'
        },
        icon: $r('app.media.ic_theme_system')
      }
    ]
  }

  /**
   * 加载当前主题
   */
  private async loadCurrentTheme() {
    this.isLoading = true
    try {
      this.currentTheme = this.themeStore.currentTheme
      this.selectedTheme = this.currentTheme
    } catch (error) {
      this.logger.error('加载当前主题失败', error)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 选择主题
   */
  private selectTheme(theme: ThemeType) {
    this.selectedTheme = theme
    this.logger.info('选择主题', { theme })
  }

  /**
   * 应用主题
   */
  private async applyTheme() {
    if (this.selectedTheme === this.currentTheme) {
      return
    }

    try {
      this.isLoading = true

      // 应用主题
      await this.themeStore.setTheme(this.selectedTheme)
      this.currentTheme = this.selectedTheme

      this.logger.info('主题应用成功', { theme: this.selectedTheme })
    } catch (error) {
      this.logger.error('应用主题失败', error)
      // 恢复选择状态
      this.selectedTheme = this.currentTheme
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 预览主题
   */
  private previewThemeEffect(theme: ThemeType) {
    this.previewTheme = theme
    this.showPreview = true
  }

  /**
   * 关闭预览
   */
  private closePreview() {
    this.showPreview = false
  }

  /**
   * 获取主题名称
   */
  private getThemeName(theme: ThemeType): string {
    const preset = this.themePresets.find(p => p.type === theme)
    return preset?.name || '未知主题'
  }

  /**
   * 获取主题描述
   */
  private getThemeDescription(theme: ThemeType): string {
    const preset = this.themePresets.find(p => p.type === theme)
    return preset?.description || ''
  }

  /**
   * 获取主题图标
   */
  private getThemeIcon(theme: ThemeType): Resource {
    const preset = this.themePresets.find(p => p.type === theme)
    return preset?.icon || $r('app.media.ic_theme')
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()

      // 主题列表
      this.buildThemeList()

      // 主题预览
      if (this.showPreview) {
        this.buildThemePreview()
      }

      // 加载对话框
      if (this.isLoading) {
        LoadingDialog({ message: '应用主题中...' })
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
      .onClick(() => router.back())

      // 标题
      Text(this.settingsTitle)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 应用按钮
      Button('应用')
        .fontSize(16)
        .fontColor(this.selectedTheme !== this.currentTheme ? '#007AFF' : '#CCCCCC')
        .backgroundColor(Color.Transparent)
        .enabled(this.selectedTheme !== this.currentTheme)
        .onClick(() => this.applyTheme())
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
   * 构建主题列表
   */
  @Builder
  private buildThemeList() {
    Scroll() {
      Column({ space: 16 }) {
        // 当前主题信息
        this.buildCurrentThemeInfo()

        // 主题选项
        ForEach(
          this.themePresets,
          (preset: ThemePreset) => {
            this.buildThemeCard(preset)
          },
          (preset: ThemePreset) => preset.type
        )

        // 主题说明
        this.buildThemeDescription()
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 16 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  /**
   * 构建当前主题信息
   */
  @Builder
  private buildCurrentThemeInfo() {
    Row({ space: 12 }) {
      Image(this.getThemeIcon(this.currentTheme))
        .width(32)
        .height(32)
        .fillColor('#007AFF')

      Column({ space: 4 }) {
        Text('当前主题')
          .fontSize(14)
          .fontColor('#666666')

        Text(this.getThemeName(this.currentTheme))
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
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
  }

  /**
   * 构建主题卡片
   */
  @Builder
  private buildThemeCard(preset: ThemePreset) {
    Column({ space: 12 }) {
      // 主题头部
      Row({ space: 12 }) {
        // 主题图标
        Button() {
          Image(preset.icon || $r('app.media.ic_theme'))
            .width(24)
            .height(24)
            .fillColor(this.selectedTheme === preset.type ? '#FFFFFF' : '#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(this.selectedTheme === preset.type ? preset.preview.primary : '#F0F0F0')
        .borderRadius(20)

        // 主题信息
        Column({ space: 4 }) {
          Text(preset.name)
            .fontSize(16)
            .fontColor(this.selectedTheme === preset.type ? preset.preview.primary : '#333333')
            .fontWeight(this.selectedTheme === preset.type ? FontWeight.Bold : FontWeight.Normal)

          Text(preset.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 选择状态
        if (this.selectedTheme === preset.type) {
          Image($r('app.media.ic_check'))
            .width(20)
            .height(20)
            .fillColor(preset.preview.primary)
        } else {
          // 预览按钮
          Button('预览')
            .fontSize(14)
            .fontColor('#666666')
            .backgroundColor('#F8F8F8')
            .borderRadius(16)
            .onClick(() => this.previewThemeEffect(preset.type))
        }
      }
      .width('100%')
      .onClick(() => this.selectTheme(preset.type))

      // 主题预览条
      Row() {
        ForEach(
          ['primary', 'background', 'surface', 'text'] as const,
          (colorType: keyof ThemePreset['preview']) => {
            Column({ space: 4 }) {
              Circle({ width: 24, height: 24 })
                .fill(preset.preview[colorType])
                .border({
                  width: 1,
                  color: '#E0E0E0'
                })

              Text(this.getColorName(colorType))
                .fontSize(10)
                .fontColor('#999999')
            }
          },
          (colorType: string) => colorType
        )
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ horizontal: 16, bottom: 12 })
    }
    .width('100%')
    .padding({ top: 16, left: 16, right: 16, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
    .border({
      width: this.selectedTheme === preset.type ? 2 : 0,
      color: preset.preview.primary
    })
  }

  /**
   * 构建主题说明
   */
  @Builder
  private buildThemeDescription() {
    Column({ space: 12 }) {
      Text('主题说明')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Column({ space: 8 }) {
        Text('• 浅色主题：适合在明亮环境下使用，减少眼睛疲劳')
        Text('• 深色主题：适合在暗光环境下使用，保护视力')
        Text('• 跟随系统：自动根据系统设置切换主题')
        Text('• 主题切换：实时生效，无需重启应用')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      ForEach(
        ['primary', 'background', 'surface', 'text'] as const,
        (colorType: string) => {
          Row({ space: 8 }) {
            Text(`${this.getColorName(colorType)}：`)
              .fontSize(14)
              .fontColor('#666666')

            Text(this.getColorDescription(colorType))
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)
          }
          .width('100%')
        },
        (colorType: string) => colorType
      )
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
  }

  /**
   * 构建主题预览
   */
  @Builder
  private buildThemePreview() {
    Column() {
      // 预览头部
      Row() {
        Text('主题预览')
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
        .onClick(() => this.closePreview())
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })
      .backgroundColor('#FFFFFF')

      Divider().color('#F0F0F0')

      // 预览内容
      Column({ space: 16 }) {
        // 模拟界面元素
        this.buildPreviewElement('导航栏', 56)
        this.buildPreviewElement('卡片', 120)
        this.buildPreviewElement('按钮组', 80)
        this.buildPreviewElement('列表项', 60)
        this.buildPreviewElement('底部栏', 60)
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)

      // 预览底部操作
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => this.closePreview())

        Button('应用此主题')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getPreviewThemeColor('primary'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.selectTheme(this.previewTheme)
            this.closePreview()
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('80%')
    .position({ x: 0, y: '20%' })
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
   * 构建预览元素
   */
  @Builder
  private buildPreviewElement(name: string, height: number) {
    Column({ space: 8 }) {
      Text(name)
        .fontSize(12)
        .fontColor('#666666')
        .alignSelf(ItemAlign.Start)

      Row()
        .width('100%')
        .height(height)
        .backgroundColor(this.getPreviewThemeColor('surface'))
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  /**
   * 获取预览主题颜色
   */
  private getPreviewThemeColor(type: string): string {
    const preset = this.themePresets.find(p => p.type === this.previewTheme)
    return preset?.preview[type as keyof ThemePreset['preview']] || '#FFFFFF'
  }

  /**
   * 获取颜色名称
   */
  private getColorName(colorType: string): string {
    switch (colorType) {
      case 'primary':
        return '主色'
      case 'background':
        return '背景'
      case 'surface':
        return '表面'
      case 'text':
        return '文字'
      default:
        return colorType
    }
  }

  /**
   * 获取颜色描述
   */
  private getColorDescription(colorType: string): string {
    switch (colorType) {
      case 'primary':
        return '主要按钮和链接颜色'
      case 'background':
        return '主要背景颜色'
      case 'surface':
        return '卡片和表面颜色'
      case 'text':
        return '主要文字颜色'
      default:
        return '界面元素颜色'
    }
  }
}