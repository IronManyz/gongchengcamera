/**
   * 构建地图选择器对话框
   */
  @Builder
  private buildLocationPickerDialog() {
    Column() {
      // 头部
      Row() {
        Text('选择位置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Button('关闭')
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showLocationPicker = false
          })
      }
      .width('100%')
      .padding(16)
      .borderRadius({ topLeft: 8, topRight: 8 })

      Divider().color('#F0F0F0')

      // 位置信息显示
      Column() {
        Text('当前选择的位置')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })

        // 坐标显示
        Row() {
          Column({ space: 4 }) {
            Text('纬度')
              .fontSize(14)
              .fontColor('#333333')
            Text(`${this.tempLatitude.toFixed(6)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#007AFF')
          }
          .layoutWeight(1)

          Column({ space: 4 }) {
            Text('经度')
              .fontSize(14)
              .fontColor('#333333')
            Text(`${this.tempLongitude.toFixed(6)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#007AFF')
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .margin({ bottom: 16 })

        // 简单地图预览（使用网��模拟地图）
        this.buildSimpleMapPreview()

        // 操作按钮
        Row({ space: 12 }) {
          Button('重新定位')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#E0E0E0' })
            .borderRadius(8)
            .onClick(() => {
              this.tempLatitude = 39.9042
              this.tempLongitude = 116.4074
            })

          Button('确认选择')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .onClick(() => {
              this.confirmLocationSelection()
            })
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ horizontal: 20 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 2
    })
    .zIndex(20)
  }

  /**
   * 构建简单地图预览（网格模拟）
   */
  @Builder
  private buildSimpleMapPreview() {
    Column() {
      Text('地图预览（点击网格选择位置）')
        .fontSize(14)
        .fontColor('#666666')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      // 模拟地图网格
      Grid() {
        ForEach(Array.from({ length: 25 }), (index: number) => {
          GridItem() {
            Column() {
              Text(`${index + 1}`)
                .fontSize(12)
                .fontColor('#999999')
                .textAlign(TextAlign.Center)
            }
            .width(60)
            .height(60)
            .backgroundColor('#F0F0F0')
            .border({ width: 1, color: '#E0E0E0' })
            .onClick(() => {
              // 模拟点击地图不同位置
              const latOffset = (Math.floor(index / 5) - 2) * 0.01
              const lngOffset = (index % 5 - 2) * 0.01
              this.tempLatitude = this.tempLatitude + latOffset
              this.tempLongitude = this.tempLongitude + lngOffset
            })
          }
        }, (index: number) => index.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(1)
      .columnsGap(1)
      .padding(16)
      .width('100%')
      .backgroundColor('#FAFAFA')
      .borderRadius(8)
    }
    .width('100%')
    .layoutWeight(1)
  }