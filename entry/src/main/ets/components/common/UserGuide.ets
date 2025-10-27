/**
 * 用户引导组件
 * 提供分步骤的用户引导和帮助系统
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface GuideStep {
  id: string
  title: string
  content: string
  target?: string // 目标组件ID或选择器
  position?: 'top' | 'bottom' | 'left' | 'right' | 'center'
  image?: string
  actionText?: string
  onAction?: () => void
  skipable?: boolean
}

export interface UserGuideConfig {
  steps: GuideStep[]
  showSkip?: boolean
  showProgress?: boolean
  autoStart?: boolean
  onComplete?: () => void
  onSkip?: () => void
  maskOpacity?: number
}

@ComponentV2
export struct UserGuide {
  @Param config?: UserGuideConfig = {}
  @State private currentStepIndex: number = 0
  @State private isVisible: boolean = false
  @State private targetPosition?: { x: number, y: number, width: number, height: number }

  private get guideConfig(): UserGuideConfig {
    return {
      showSkip: true,
      showProgress: true,
      autoStart: true,
      maskOpacity: 0.6,
      ...this.config
    }
  }

  private get currentStep(): GuideStep | undefined {
    return this.guideConfig.steps[this.currentStepIndex]
  }

  private get isLastStep(): boolean {
    return this.currentStepIndex >= this.guideConfig.steps.length - 1
  }

  aboutToAppear() {
    if (this.guideConfig.autoStart && this.guideConfig.steps.length > 0) {
      this.startGuide()
    }
  }

  /**
   * 开始引导
   */
  startGuide(): void {
    this.isVisible = true
    this.currentStepIndex = 0
  }

  /**
   * 结束引导
   */
  endGuide(): void {
    this.isVisible = false
    this.guideConfig.onComplete?.()
  }

  /**
   * 下一步
   */
  nextStep(): void {
    if (this.isLastStep) {
      this.endGuide()
    } else {
      this.currentStepIndex++
    }
  }

  /**
   * 上一步
   */
  previousStep(): void {
    if (this.currentStepIndex > 0) {
      this.currentStepIndex--
    }
  }

  /**
   * 跳过引导
   */
  skipGuide(): void {
    this.isVisible = false
    this.guideConfig.onSkip?.()
  }

  /**
   * 获取高亮区域位置
   */
  private getHighlightPosition(): { x: number, y: number, width: number, height: number } {
    // 这里应该根据target查询实际组件位置
    // 暂时返回默认值
    return this.targetPosition || { x: '50%', y: '50%', width: 100, height: 100 }
  }

  /**
   * 高亮遮罩层
   */
  @Builder
  private HighlightMask() {
    Stack() {
      // 全屏遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(`rgba(0, 0, 0, ${this.guideConfig.maskOpacity})`)
        .onClick(() => {
          // 点击遮罩区域可以跳过当前步骤
          if (this.currentStep?.skipable !== false) {
            this.nextStep()
          }
        })

      // 高亮区域（挖孔）
      if (this.currentStep?.target) {
        const pos = this.getHighlightPosition()
        Column()
          .width(pos.width)
          .height(pos.height)
          .position({ x: pos.x, y: pos.y })
          .borderRadius(8)
          .border({ width: 2, color: ThemeManager.getCurrentPrimaryColor() })
          .shadow({
            radius: 8,
            color: `${ThemeManager.getCurrentPrimaryColor()}40`,
            offsetX: 0,
            offsetY: 0
          })
      }
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }

  /**
   * 引导内容卡片
   */
  @Builder
  private GuideContent() {
    Column({ space: 16 }) {
      // 进度指示器
      if (this.guideConfig.showProgress && this.guideConfig.steps.length > 1) {
        Row() {
          ForEach(this.guideConfig.steps, (_, index) => {
            Circle({ width: 8, height: 8 })
              .fill(index <= this.currentStepIndex ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0')
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      }

      // 引导图片
      if (this.currentStep?.image) {
        Image(this.currentStep.image)
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .backgroundColor('#FAFAFA')
          .margin({ bottom: 8 })
      }

      // 标题
      Text(this.currentStep?.title || '')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)
        .maxLines(2)

      // 内容
      Text(this.currentStep?.content || '')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 操作按钮
      Row({ space: 12 }) {
        // 上一步按钮
        if (this.currentStepIndex > 0) {
          Button('上一步')
            .fontSize(14)
            .fontColor('#666666')
            .backgroundColor('#F0F0F0')
            .borderRadius(20)
            .padding({ left: 16, right: 16 })
            .onClick(() => this.previousStep())
        }

        Blank()

        // 下一步/完成按钮
        if (this.isLastStep) {
          Button('开始使用')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(ThemeManager.getCurrentPrimaryColor())
            .borderRadius(20)
            .padding({ left: 24, right: 24 })
            .onClick(() => this.endGuide())
        } else {
          Button('下一步')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(ThemeManager.getCurrentPrimaryColor())
            .borderRadius(20)
            .padding({ left: 24, right: 24 })
            .onClick(() => this.nextStep())
        }

        // 自定义操作按钮
        if (this.currentStep?.actionText && this.currentStep?.onAction) {
          Button(this.currentStep.actionText)
            .fontSize(14)
            .fontColor(ThemeManager.getCurrentPrimaryColor())
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: ThemeManager.getCurrentPrimaryColor() })
            .borderRadius(20)
            .padding({ left: 16, right: 16 })
            .onClick(() => this.currentStep.onAction?.())
        }
      }
      .width('100%')
      .margin({ top: 8 })

      // 跳过按钮
      if (this.guideConfig.showSkip) {
        Button('跳过引导')
          .fontSize(12)
          .fontColor('#999999')
          .backgroundColor(Color.Transparent)
          .margin({ top: 8 })
          .onClick(() => this.skipGuide())
      }
    }
    .width(280)
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 12,
      color: '#00000030',
      offsetX: 0,
      offsetY: 8
    })
    .position({ x: '50%', y: '50%' })
    .translate({ x: '-50%', y: '-50%' })
    .zIndex(1001)
  }

  build() {
    if (this.isVisible && this.currentStep) {
      Stack() {
        this.HighlightMask()
        this.GuideContent()
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }
}

// 引导管理器
export class GuideManager {
  private static instance: GuideManager
  private guides: Map<string, GuideStep[]> = new Map()

  static getInstance(): GuideManager {
    if (!GuideManager.instance) {
      GuideManager.instance = new GuideManager()
    }
    return GuideManager.instance
  }

  /**
   * 注册引导流程
   */
  registerGuide(key: string, steps: GuideStep[]): void {
    this.guides.set(key, steps)
  }

  /**
   * 获取引导步骤
   */
  getGuide(key: string): GuideStep[] | undefined {
    return this.guides.get(key)
  }

  /**
   * 检查是否需要显示引导
   */
  shouldShowGuide(key: string): boolean {
    // 这里可以检查本地存储或用户设置
    const storageKey = `guide_shown_${key}`
    // return !localStorage.getItem(storageKey)
    return true // 暂时总是返回true
  }

  /**
   * 标记引导已完成
   */
  markGuideCompleted(key: string): void {
    const storageKey = `guide_shown_${key}`
    // localStorage.setItem(storageKey, 'true')
  }
}