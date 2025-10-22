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

  build() {
    Column() {
      // 图标和数值
      Row() {
        // 图标
        Text(this.icon)
          .fontSize(20)
          .fontColor(this.color)
          .margin({ right: 12 })

        Column() {
          // 数值
          Text(typeof this.value === 'number' ? this.value.toString() : this.value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262626')

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
  }

  @Builder
  private buildTrendIndicator(): void {
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