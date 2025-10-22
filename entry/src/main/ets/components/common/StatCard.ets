/**
 * 统计卡片组件
 * 用于展示数据统计信息
 */

@ComponentV2
export struct StatCard {
  @Param title: string = ''
  @Param value: string | number = ''
  @Param icon: string = '📁'
  @Param color: string = '#1890FF'
  @Param trend?: 'up' | 'down' | 'stable' = 'stable'
  @Param subtitle?: string = ''
  @Param progress?: number = undefined // 新增进度参数
  @Param showLoading?: boolean = false // 新增加载状态
  @Param onTap?: () => void = () => {} // 新增点击回调

  build() {
    Column() {
      // 图标和数值
      Row() {
        // 图标
        if (this.showLoading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(this.color)
            .margin({ right: 12 })
        } else {
          Text(this.icon)
            .fontSize(20)
            .fontColor(this.color)
            .margin({ right: 12 })
        }

        Column() {
          // 数值
          if (this.showLoading) {
            Text('...')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#999999')
          } else {
            Text(typeof this.value === 'number' ? this.value.toString() : this.value)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#262626')
          }

          // 标题
          Text(this.title)
            .fontSize(14)
            .fontColor('#8C8C8C')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 趋势指示器
        if (this.trend) {
          this.buildTrendIndicator()
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 副标题
      if (this.subtitle) {
        Text(this.subtitle)
          .fontSize(12)
          .fontColor('#A6A6A6')
          .margin({ top: 8 })
          .textAlign(TextAlign.Start)
          .width('100%')
      }

      // 进度条（如果有的话）
      if (this.progress !== undefined) {
        this.buildProgressBar()
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      if (this.onTap && !this.showLoading) {
        this.onTap()
      }
    })
  }

  /**
   * 构建进度条
   */
  @Builder
  private buildProgressBar(): void {
    Column({ space: 8 }) {
      // 进度条标签
      Row() {
        Text('完成进度')
          .fontSize(12)
          .fontColor('#666666')

        Text(`${this.progress}%`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')

      // 进度条
      Progress({
        value: this.progress || 0,
        total: 100,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(6)
        .backgroundColor('#F0F0F0')
        .color(this.color)
        .borderRadius(3)

      // 进度描述
      if (this.progress && this.progress >= 100) {
        Text('任务完成')
          .fontSize(12)
          .fontColor('#52C41A')
          .margin({ top: 4 })
          .textAlign(TextAlign.Center)
          .width('100%')
      } else if (this.progress && this.progress >= 75) {
        Text('即将完成')
          .fontSize(12)
          .fontColor('#FAAD14')
          .margin({ top: 4 })
          .textAlign(TextAlign.Center)
          .width('100%')
      } else if (this.progress && this.progress >= 50) {
        Text('进行中')
          .fontSize(12)
          .fontColor('#1890FF')
          .margin({ top: 4 })
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F8F9FA')
    .borderRadius(6)
  }

  /**
   * 构建趋势指示器
   */
  @Builder
  private buildTrendIndicator() {
    Row() {
      if (this.trend === 'up') {
        Text('↑')
          .fontSize(16)
          .fontColor('#52C41A')
      } else if (this.trend === 'down') {
        Text('↓')
          .fontSize(16)
          .fontColor('#FF4D4F')
      }

      if (this.trend !== 'stable') {
        Text(this.trend === 'up' ? '上升' : '下降')
          .fontSize(12)
          .fontColor(this.trend === 'up' ? '#52C41A' : '#FF4D4F')
          .margin({ left: 4 })
      }
    }
  }
}