/**
 * 空状态管理器
 * 统一管理应用中的所有空状态显示逻辑
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { EmptyStateType, EmptyStateSize } from './EmptyStates'

export interface EmptyStateConfig {
  type?: EmptyStateType
  title?: string
  description?: string
  icon?: string
  image?: string
  size?: EmptyStateSize
  showButton?: boolean
  buttonText?: string
  buttonType?: 'primary' | 'secondary' | 'outline' | 'text'
  onButtonPress?: () => void
  autoHideDelay?: number
  animationType?: 'fade' | 'slide' | 'bounce' | 'none'
}

export interface EmptyStateRule {
  condition: () => boolean
  config: EmptyStateConfig
  priority: number  // 优先级，数字越小优先级越高
}

/**
 * 空状态规则管理器
 * 提供智能空状态显示决策
 */
export class EmptyStateManager {
  private static instance: EmptyStateManager
  private rules: EmptyStateRule[] = []
  private currentState?: EmptyStateConfig

  static getInstance(): EmptyStateManager {
    if (!EmptyStateManager.instance) {
      EmptyStateManager.instance = new EmptyStateManager()
    }
    return EmptyStateManager.instance
  }

  /**
   * 注册空状态规则
   */
  registerRule(rule: EmptyStateRule): void {
    this.rules.push(rule)
    // 按优先级排序
    this.rules.sort((a, b) => a.priority - b.priority)
  }

  /**
   * 清除所有规则
   */
  clearRules(): void {
    this.rules = []
    this.currentState = undefined
  }

  /**
   * 评估并获取当前空状态
   */
  evaluateState(data: any = {}): EmptyStateConfig | null {
    for (const rule of this.rules) {
      if (rule.condition(data)) {
        this.currentState = rule.config
        return rule.config
      }
    }
    return null
  }

  /**
   * 手动设置空状态
   */
  setManualState(config: EmptyStateConfig): void {
    this.currentState = config
  }

  /**
   * 清除当前空状态
   */
  clearState(): void {
    this.currentState = undefined
  }

  /**
   * 获取当前空状态
   */
  getCurrentState(): EmptyStateConfig | undefined {
    return this.currentState
  }

  /**
   * 检查是否显示空状态
   */
  isShowingEmptyState(): boolean {
    return this.currentState !== undefined
  }

  /**
   * 获取推荐的空状态配置
   */
  getRecommendedConfig(type: EmptyStateType, data?: any): EmptyStateConfig {
    const configs: Record<EmptyStateType, EmptyStateConfig> = {
      'no-data': {
        type: 'no-data',
        title: '暂无数据',
        description: '当前页面没有显示的内容',
        icon: '📦',
        size: 'medium',
        showButton: false
      },
      'no-results': {
        type: 'no-results',
        title: '未找到结果',
        description: '没有找到相关的内容，请尝试其他搜索条件',
        icon: '🔍',
        size: 'medium',
        showButton: true,
        buttonText: '重新搜索'
      },
      'no-network': {
        type: 'no-network',
        title: '网络连接失败',
        description: '请检查您的网络连接并重试',
        icon: '📶',
        size: 'medium',
        showButton: true,
        buttonText: '重试',
        animationType: 'bounce'
      },
      'error': {
        type: 'error',
        title: '操作失败',
        description: '执行操作时发生了错误，请稍后重试',
        icon: '❌',
        size: 'medium',
        showButton: true,
        buttonText: '重试',
        buttonType: 'outline'
      },
      'loading': {
        type: 'loading',
        title: '正在加载',
        description: '请稍候，数据正在加载中...',
        icon: '⏳',
        size: 'medium',
        showButton: false,
        animationType: 'pulse'
      },
      'empty-list': {
        type: 'empty-list',
        title: '列表为空',
        description: '暂无列表项目，点击下方按钮创建',
        icon: '📋',
        size: 'large',
        showButton: true,
        buttonText: '创建项目'
      },
      'empty-favorites': {
        type: 'empty-favorites',
        title: '暂无收藏',
        description: '您还没有收藏任何项目，点击项目卡片上的收藏按钮来添加',
        icon: '⭐',
        size: 'medium',
        showButton: false
      },
      'no-permission': {
        type: 'no-permission',
        title: '权限不足',
        description: '您没有权限访问此功能，请联系管理员',
        icon: '🔒',
        size: 'medium',
        showButton: true,
        buttonText: '申请权限',
        buttonType: 'outline'
      },
      'not-found': {
        type: 'not-found',
        title: '页面未找到',
        description: '抱歉，您访问的页面不存在或已被移除',
        icon: '🔍',
        size: 'medium',
        showButton: true,
        buttonText: '返回首页'
      },
      'maintenance': {
        type: 'maintenance',
        title: '系统维护中',
        description: '系统正在进行维护升级，预计很快完成，请稍后重试',
        icon: '🔧',
        size: 'large',
        showButton: false,
        animationType: 'bounce'
      },
      'first-use': {
        type: 'first-use',
        title: '欢迎使用',
        description: '让我们开始您的第一个工程项目',
        icon: '👋',
        size: 'large',
        showButton: true,
        buttonText: '创建项目'
      }
    }

    const config = configs[type] || configs['no-data']

    // 根据数据动态调整配置
    if (data) {
      return this.enhanceConfigWithData(config, data)
    }

    return config
  }

  /**
   * 根据数据增强配置
   */
  private enhanceConfigWithData(config: EmptyStateConfig, data: any): EmptyStateConfig {
    const enhanced = { ...config }

    // 根据数据类型调整描述
    if (data.itemCount !== undefined && data.itemType) {
      enhanced.description = `暂无${data.itemType}，${data.createAction || '点击创建'}第一个${data.itemType}开始使用`
    }

    // 根据搜索状态调整配置
    if (data.isSearching) {
      enhanced.title = '搜索中'
      enhanced.description = '正在搜索相关内容，请稍候...'
      enhanced.icon = '🔍'
      enhanced.animationType = 'pulse'
    }

    // 根据网络状态调整配置
    if (data.networkStatus) {
      switch (data.networkStatus) {
        case 'slow':
          enhanced.title = '网络较慢'
          enhanced.description = '网络连接较慢，加载可能需要更长时间'
          enhanced.icon = '🐢'
          break
        case 'timeout':
          enhanced.title = '请求超时'
          enhanced.description = '网络请求超时，请检查网络连接'
          enhanced.icon = '⏰'
          break
      }
    }

    return enhanced
  }

  /**
   * 创建基于数据的规则
   */
  createDataBasedRule(
    name: string,
    condition: (data: any) => boolean,
    config?: Partial<EmptyStateConfig>,
    priority: number = 10
  ): EmptyStateRule {
    return {
      name,
      condition,
      config: {
        ...config,
        type: config?.type || 'no-data'
      },
      priority
    }
  }

  /**
   * 创建列表空状态规则
   */
  createEmptyListRule(
    listData: any[],
    config?: Partial<EmptyStateConfig>
  ): EmptyStateRule {
    return {
      name: 'empty-list',
      condition: (data: any) => {
        const list = data[listData.key] || []
        return !Array.isArray(list) || list.length === 0
      },
      config: {
        type: 'empty-list',
        title: `暂无${data.itemType || '项目'}`,
        description: `还没有${data.itemType || '项目'}，${data.createAction || '点击创建'}第一个${data.itemType || '项目'}开始使用`,
        ...config
      },
      priority: 5
    }
  }

  /**
   * 创建网络错误规则
   */
  createNetworkErrorRule(
    config?: Partial<EmptyStateConfig>
  ): EmptyStateRule {
    return {
      name: 'network-error',
      condition: (data: any) => {
        return data.networkError === true || data.isOffline === true
      },
      config: {
        type: 'no-network',
        ...config
      },
      priority: 2
    }
  }

  /**
   * 创建权限错误规则
   */
  createPermissionErrorRule(
    config?: Partial<EmptyStateConfig>
  ): EmptyStateRule {
    return {
      name: 'permission-error',
      condition: (data: any) => {
        return data.permissionDenied === true || data.isUnauthorized === true
      },
      config: {
        type: 'no-permission',
        ...config
      },
      priority: 3
    }
  }
}

/**
 * 空状态容器组件
 * 智能显示各种空状态
 */
@ComponentV2
export struct EmptyStateContainer {
  @Param data: any = {}
  @Param rules?: EmptyStateRule[]
  @Param manualConfig?: EmptyStateConfig
  @Param manager?: EmptyStateManager
  @Param children: () => void = () => {}

  @State private currentConfig?: EmptyStateConfig
  @State private isVisible: boolean = false

  aboutToAppear() {
    this.setupEmptyState()
  }

  /**
   * 设置空状态
   */
  private setupEmptyState(): void {
    // 使用手动配置
    if (this.manualConfig) {
      this.currentConfig = this.manualConfig
      this.isVisible = true
      return
    }

    // 使用管理器
    if (this.manager) {
      const config = this.manager.evaluateState(this.data)
      if (config) {
        this.currentConfig = config
        this.isVisible = true
        return
      }
    }

    // 使用传入的规则
    if (this.rules && this.rules.length > 0) {
      for (const rule of this.rules) {
        if (rule.condition(this.data)) {
          this.currentConfig = rule.config
          this.isVisible = true
          return
        }
      }
    }

    // 默认状态：不显示空状态
    this.currentConfig = undefined
    this.isVisible = false
  }

  build() {
    Stack() {
      // 正常内容
      if (!this.isVisible && this.currentConfig?.type !== 'loading') {
        this.children()
      }

      // 空状态内容
      if (this.isVisible && this.currentConfig) {
        this.buildEmptyState()
      }
    }
    .width('100%')
    .height('100%')
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 构建空状态内容
   */
  @Builder
  private buildEmptyState() {
    if (!this.currentConfig) return

    const animationType = this.currentConfig.animationType || 'fade'

    Column() {
      // 动画图标
      if (this.currentConfig.icon || this.currentConfig.image) {
        Row() {
          if (this.currentConfig.type === 'loading') {
            LoadingProgress()
              .width(48)
              .height(48)
              .color(ThemeManager.getCurrentPrimaryColor())
          } else if (this.currentConfig.image) {
            Image(this.currentConfig.image)
              .width(80)
              .height(80)
              .objectFit(ImageFit.Contain)
          } else {
            Text(this.currentConfig.icon!)
              .fontSize(this.getIconSize())
          }
        }
        .margin({ bottom: 24 })
      }

      // 标题
      if (this.currentConfig.title) {
        Text(this.currentConfig.title)
          .fontSize(this.getTitleSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.getCurrentTextColor())
          .margin({ bottom: 12 })
          .textAlign(TextAlign.Center)
      }

      // 描述
      if (this.currentConfig.description) {
        Text(this.currentConfig.description)
          .fontSize(this.getDescriptionSize())
          .fontColor(ThemeManager.getCurrentTextSecondaryColor())
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(24)
      }

      // 操作按钮
      if (this.currentConfig.showButton && this.currentConfig.buttonText) {
        Button(this.currentConfig.buttonText)
          .fontSize(16)
          .fontColor(this.getButtonTextColor())
          .fontWeight(FontWeight.Medium)
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .borderRadius(this.getButtonBorderRadius())
          .backgroundColor(this.getButtonBackgroundColor())
          .border({
            width: this.currentConfig.buttonType === 'outline' ? 1 : 0,
            color: this.getButtonTextColor()
          })
          .onClick(() => {
            this.currentConfig.onButtonPress?.()
          })
          .margin({ top: 32 })
      }
    }
    .width(this.getContentWidth())
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ThemeManager.getCurrentBackgroundColor())
    .transform(this.getTransformByAnimation(animationType))
  }

  /**
   * 获取图标尺寸
   */
  private getIconSize(): number {
    const sizes: Record<string, number> = {
      'small': 48,
      'medium': 64,
      'large': 80,
      'full': 96
    }
    return sizes[this.currentConfig?.size || 'medium']
  }

  /**
   * 获取标题字体大小
   */
  private getTitleSize(): number {
    const sizes: Record<string, number> = {
      'small': 18,
      'medium': 20,
      'large': 24,
      'full': 28
    }
    return sizes[this.currentConfig?.size || 'medium']
  }

  /**
   * 获取描述字体大小
   */
  private getDescriptionSize(): number {
    const sizes: Record<string, number> = {
      'small': 14,
      'medium': 16,
      'large': 18,
      'full': 20
    }
    return sizes[this.currentConfig?.size || 'medium']
  }

  /**
   * 获取内容宽度
   */
  private getContentWidth(): string {
    const widths: Record<string, string> = {
      'small': '280',
      'medium': '320',
      'large': '400',
      'full': '80%'
    }
    return widths[this.currentConfig?.size || 'medium']
  }

  /**
   * 获取按钮背景颜色
   */
  private getButtonBackgroundColor(): string {
    switch (this.currentConfig?.buttonType) {
      case 'primary':
        return ThemeManager.getCurrentPrimaryColor()
      case 'secondary':
        return ThemeManager.getCurrentSecondaryColor()
      case 'outline':
        return ThemeManager.getCurrentBackgroundColor()
      case 'text':
        return Color.Transparent
      default:
        return ThemeManager.getCurrentPrimaryColor()
    }
  }

  /**
   * 获取按钮文字颜色
   */
  private getButtonTextColor(): string {
    switch (this.currentConfig?.buttonType) {
      case 'primary':
      case 'secondary':
        return '#FFFFFF'
      case 'outline':
        return ThemeManager.getCurrentPrimaryColor()
      case 'text':
        return ThemeManager.getCurrentPrimaryColor()
      default:
        return '#FFFFFF'
    }
  }

  /**
   * 获取按钮圆角
   */
  private getButtonBorderRadius(): number {
    return this.currentConfig?.buttonType === 'icon' ? 50 : 8
  }

  /**
   * 根据动画类型获取变换
   */
  private getTransformByAnimation(animationType: string): { [key: string]: string | number } {
    switch (animationType) {
      case 'fade':
        return { opacity: this.isVisible ? 1 : 0 }
      case 'slide':
        return { translateY: this.isVisible ? 0 : -50 }
      case 'bounce':
        return { scale: { x: this.isVisible ? 1 : 0.8, y: this.isVisible ? 1 : 0.8 } }
      default:
        return {}
    }
  }
}