/**
 * 加载对话框组件
 * 提供统一的加载状态展示
 */

@ComponentV2
export struct LoadingDialog {
  @Param show: boolean = false
  @Param message: string = '加载中...'
  @Param showCancel: boolean = false
  @Require @Param onCancel?: () => void

  build() {
    if (this.show) {
      Stack() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            // 点击遮罩层不关闭对话框
          })

        // 加载内容
        Column() {
          // 加载动画
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#007AFF')

          // 加载文字
          Text(this.message)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ top: 16 })
            .textAlign(TextAlign.Center)

          // 取消按钮（可选）
          if (this.showCancel && this.onCancel) {
            Button('取消')
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor(Color.Transparent)
              .margin({ top: 20 })
              .onClick(() => {
                this.onCancel?.()
              })
          }
        }
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 40, right: 40 })
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }
}

/**
 * 简化的加载指示器组件
 */
@ComponentV2
export struct LoadingIndicator {
  @Param loading: boolean = false
  @Param message: string = ''
  @Param size: number = 24
  @Param color: string = '#007AFF'

  build() {
    if (this.loading) {
      Row() {
        LoadingProgress()
          .width(this.size)
          .height(this.size)
          .color(this.color)

        if (this.message) {
          Text(this.message)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding(12)
    }
  }
}

/**
 * 全屏加载组件
 */
@ComponentV2
export struct FullScreenLoading {
  @Param show: boolean = false
  @Param message: string = '加载中...'
  @Param backgroundColor: string = '#F5F5F5'

  build() {
    if (this.show) {
      Column() {
        LoadingProgress()
          .width(56)
          .height(56)
          .color('#007AFF')

        Text(this.message)
          .fontSize(18)
          .fontColor('#666666')
          .margin({ top: 16 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.backgroundColor)
      .zIndex(999)
    }
  }
}