/**
 * 骨架屏加载组件
 * 提供多种骨架屏效果，提升内容加载时的用户体验
 */

import { ThemeManager } from '../../theme/ThemeManager'

export type SkeletonType =
  | 'text'         // 文本骨架
  | 'avatar'       // 头像骨架
  | 'image'         // 图片骨架
  | 'card'          // 卡片骨架
  | 'list'          // 列表骨架
  | 'table'         // 表格骨架
  | 'custom'        // 自定义骨架

export type SkeletonAnimation =
  | 'wave'          // 波浪动画
  | 'pulse'         // 脉冲动画
  | 'shimmer'       // 闪光效果
  | 'fade'          // 淡入淡出
  | 'none'          // 无动画

@ComponentV2
export struct SkeletonLoading {
  @Param isLoading: boolean = false
  @Param type: SkeletonType = 'text'
  @Param animation: SkeletonAnimation = 'wave'
  @Param rows: number = 3
  @Param width: string = '100%'
  @Param height: string = 'auto'
  @Param borderRadius: number = 4
  @Param showAvatar: boolean = false
  @Param avatarSize: number = 40
  @Param theme: 'light' | 'dark' = 'light'
  @Param shimmerColor: string = 'rgba(255, 255, 255, 0.3)'

  @State private shimmerPosition: number = 0

  aboutToAppear() {
    if (this.animation === 'wave' || this.animation === 'shimmer') {
      this.startShimmerAnimation()
    }
  }

  /**
   * 启动闪光动画
   */
  private startShimmerAnimation() {
    animateTo({
      duration: 2000,
      curve: Curve.Linear,
      iterations: -1
    }, () => {
      this.shimmerPosition = (this.shimmerPosition + 200) % 400
    })
  }

  build() {
    if (this.isLoading) {
      Column() {
        switch (this.type) {
          case 'text':
            this.buildTextSkeleton()
            break
          case 'avatar':
            this.buildAvatarSkeleton()
            break
          case 'image':
            this.buildImageSkeleton()
            break
          case 'card':
            this.buildCardSkeleton()
            break
          case 'list':
            this.buildListSkeleton()
            break
          case 'table':
            this.buildTableSkeleton()
            break
          default:
            this.buildTextSkeleton()
            break
        }
      }
      .width(this.width)
      .height(this.height)
      .animation(
        this.animation !== 'none' ? {
          duration: 300,
          curve: Curve.EaseInOut
        } : undefined
      )
    }
  }

  /**
   * 构建文本骨架
   */
  @Builder
  private buildTextSkeleton() {
    Column({ space: 8 }) {
      ForEach(Array.from({ length: this.rows }), () => {
        Row()
          .width('100%')
          .height(16)
          .backgroundColor(this.getSkeletonColor())
          .borderRadius(this.borderRadius)
          .position({ relative: 'absolute' })
          .linearGradient({
            direction: GradientDirection.Right,
            colors: this.getShimmerGradient()
          })
          .translate({ x: this.getShimmerOffset() })
      })
    }
  }

  /**
   * 构建头像骨架
   */
  @Builder
  private buildAvatarSkeleton() {
    Column({ space: 12 }) {
      // 头像骨架
      Circle({ width: this.avatarSize, height: this.avatarSize })
        .fill(this.getSkeletonColor())
        .position({ relative: 'absolute' })
        .linearGradient({
          direction: GradientDirection.Right,
          colors: this.getShimmerGradient()
        })
        .translate({ x: this.getShimmerOffset() })

      // 信息骨架
      Column({ space: 6 }) {
        Row()
          .width(80)
          .height(12)
          .backgroundColor(this.getSkeletonColor())
          .borderRadius(this.borderRadius)

        Row()
          .width(120)
          .height(8)
          .backgroundColor(this.getSkeletonColor())
          .borderRadius(this.borderRadius)
      }
      .alignItems(HorizontalAlign.Start)
    }
  }

  /**
   * 构建图片骨架
   */
  @Builder
  private buildImageSkeleton() {
    Column()
      .width(this.width)
      .height(this.height)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.getSkeletonColor())
      .borderRadius(this.borderRadius)
      .position({ relative: 'absolute' })
      .linearGradient({
        direction: GradientDirection.Right,
        colors: this.getShimmerGradient()
      })
      .translate({ x: this.getShimmerOffset() })

    // 图片占位符
    Text('🖼️')
      .fontSize(24)
      .fontColor('#CCCCCC')
  }

  /**
   * 构建卡片骨架
   */
  @Builder
  private buildCardSkeleton() {
    Column({ space: 16 }) {
      // 卡片头部
      Row()
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 12 }) {

        Circle({ width: 16, height: 16 })
          .fill(this.getSkeletonColor())
          .borderRadius(8)

        Row({ space: 8 }) {
          Row()
            .width(60)
            .height(12)
            .backgroundColor(this.getSkeletonColor())
            .borderRadius(this.borderRadius)

          Row()
            .width(40)
            .height(8)
            .backgroundColor(this.getSkeletonColor())
            .borderRadius(this.borderRadius)
        }
      }

      // 卡片内容
      ForEach(Array.from({ length: 3 }), () => {
        Row()
          .width('100%')
          .height(14)
          .backgroundColor(this.getSkeletonColor())
          .borderRadius(this.borderRadius)
          .margin({ bottom: 8 })
      })

      // 卡片底部
      Row({ space: 12 }) {
        Row()
          .width(80)
          .height(10)
          .backgroundColor(this.getSkeletonColor())
          .borderRadius(this.borderRadius)

        Row()
          .width(60)
          .height(10)
          .backgroundColor(this.getSkeletonColor())
          .borderRadius(this.borderRadius)
      }
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeManager.getCurrentSurfaceColor())
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建列表骨架
   */
  @Builder
  private buildListSkeleton() {
    Column({ space: 12 }) {
      ForEach(Array.from({ length: this.rows }), (index: number) => {
        Row({ space: 12 }) {
          // 列表项头像
          if (this.showAvatar) {
            Circle({ width: this.avatarSize, height: this.avatarSize })
              .fill(this.getSkeletonColor())
              .borderRadius(this.avatarSize / 2)
          }

          // 列表项内容
          Column({ space: 8 }) {
            Row()
              .width('80%')
              .height(16)
              .backgroundColor(this.getSkeletonColor())
              .borderRadius(this.borderRadius)

            Row()
              .width('60%')
              .height(12)
              .backgroundColor(this.getSkeletonColor())
              .borderRadius(this.borderRadius)

            Row()
              .width('40%')
              .height(8)
              .backgroundColor(this.getSkeletonColor())
              .borderRadius(this.borderRadius)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ThemeManager.getCurrentSurfaceColor())
        .borderRadius(8)
        .shadow({
          radius: 2,
          color: ThemeManager.getCurrentShadowColor(),
          offsetX: 0,
          offsetY: 1
        })
      })
    }
  }

  /**
   * 构建表格骨架
   */
  @Builder
  private buildTableSkeleton() {
    Column() {
      // 表头
      Row({ space: 8 }) {
        ForEach(Array.from({ length: 4 }), () => {
          Row()
            .width('100%')
            .height(16)
            .backgroundColor(this.getSkeletonColor())
            .borderRadius(this.borderRadius)
        })
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ bottom: 12 })
      .border({ width: { bottom: 1 }, color: ThemeManager.getCurrentBorderColor() })

      // 表格内容
      ForEach(Array.from({ length: this.rows }), () => {
        Row({ space: 8 }) {
          ForEach(Array.from({ length: 4 }), () => {
            Row()
              .width('100%')
              .height(12)
              .backgroundColor(this.getSkeletonColor())
              .borderRadius(this.borderRadius)
          })
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ vertical: 8 })
        .border({ width: { bottom: 1 }, color: ThemeManager.getCurrentBorderColor() })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeManager.getCurrentSurfaceColor())
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: ThemeManager.getCurrentShadowColor(),
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 获取骨架颜色
   */
  private getSkeletonColor(): string {
    return this.theme === 'dark' ? '#2C2C2C' : '#F0F0F0'
  }

  /**
   * 获取闪光渐变颜色
   */
  private getShimmerGradient(): ResourceStr[] {
    const baseColor = this.getSkeletonColor()
    return [
      baseColor,
      this.shimmerColor,
      baseColor
    ]
  }

  /**
   * 获取闪光偏移量
   */
  private getShimmerOffset(): number {
    switch (this.animation) {
      case 'wave':
        return this.shimmerPosition - 200
      case 'shimmer':
        return this.shimmerPosition - 200
      case 'pulse':
        return Math.sin(Date.now() / 500) * 10
      default:
        return 0
    }
  }
}

/**
 * 骨架屏容器组件
 * 为页面提供完整的骨架屏效果
 */
@ComponentV2
export struct SkeletonScreen {
  @Param isLoading: boolean = false
  @Param hasHeader: boolean = true
  @Param hasFooter: boolean = true
  @Param backgroundColor: string = '#F5F5F5'
  @Param children: () => void = () => {}

  build() {
    Stack() {
      // 骨架屏
      if (this.isLoading) {
        Column() {
          // 头部骨架
          if (this.hasHeader) {
            Row()
              .width('100%')
              .height(56)
              .backgroundColor('#FFFFFF')
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
              .padding({ left: 16, right: 16 }) {

              Row()
                .width(120)
                .height(16)
                .backgroundColor('#F0F0F0')
                .borderRadius(4)

              Row({ space: 8 }) {
                Circle({ width: 32, height: 32 })
                  .fill('#F0F0F0')
                  .borderRadius(16)

                Row()
                  .width(80)
                  .height(8)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(4)
              }
            }
          }

          // 内容骨架
          Column() {
            // 标题骨架
            Row()
              .width('60%')
              .height(24)
              .backgroundColor('#F0F0F0')
              .borderRadius(4)
              .margin({ bottom: 16 })

            // 内容列表骨架
            ForEach(Array.from({ length: 5 }), (index: number) => {
              Row({ space: 12 }) {
                Circle({ width: 48, height: 48 })
                  .fill('#F0F0F0')
                  .borderRadius(24)

                Column({ space: 8 }) {
                  Row()
                    .width('70%')
                    .height(16)
                    .backgroundColor('#F0F0F0')
                    .borderRadius(4)

                  Row()
                    .width('50%')
                    .height(12)
                    .backgroundColor('#F0F0F0')
                    .borderRadius(4)

                  Row()
                    .width('80%')
                    .height(8)
                    .backgroundColor('#F0F0F0')
                    .borderRadius(4)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 12 })
              .shadow({
                radius: 2,
                color: 'rgba(0, 0, 0, 0.1)',
                offsetX: 0,
                offsetY: 1
              })
            })
          }
          .layoutWeight(1)

          // 底部骨架
          if (this.hasFooter) {
            Row()
              .width('100%')
              .height(60)
              .backgroundColor('#FFFFFF')
              .justifyContent(FlexAlign.SpaceAround)
              .alignItems(VerticalAlign.Center)
              .border({ width: { top: 1 }, color: '#F0F0F0' }) {

              Row()
                .width(60)
                .height(8)
                .backgroundColor('#F0F0F0')
                .borderRadius(4)

              Row()
                .width(80)
                .height(8)
                .backgroundColor('#F0F0F0')
                .borderRadius(4)

              Row()
                .width(60)
                .height(8)
                .backgroundColor('#F0F0F0')
                .borderRadius(4)
            }
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.backgroundColor)
        .zIndex(1000)
      }

      // 实际内容
      if (!this.isLoading) {
        Column() {
          this.children()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}