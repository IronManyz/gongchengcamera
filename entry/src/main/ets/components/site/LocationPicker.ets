/**
 * 位置选择器组件
 * 提供地图选点和经纬度输入功能
 */

import { ThemeManager } from '../../theme/ThemeManager'

export interface LocationData {
  latitude: number
  longitude: number
  altitude?: number
  address?: string
}

@ComponentV2
export struct LocationPicker {
  @Require @Param onLocationSelected: (location: LocationData) => void = () => {}
  @Param initialLocation?: LocationData
  @Param showAltitude: boolean = true
  @Param showAddress: boolean = true
  @Param title: string = '选择位置'

  @State private latitude: string = ''
  @State private longitude: string = ''
  @State private altitude: string = ''
  @State private address: string = ''
  @State private showMapDialog: boolean = false
  @State private selectedLocation: LocationData = {
    latitude: 0,
    longitude: 0,
    altitude: 0
  }

  aboutToAppear() {
    if (this.initialLocation) {
      this.latitude = this.initialLocation.latitude.toString()
      this.longitude = this.initialLocation.longitude.toString()
      this.altitude = this.initialLocation.altitude?.toString() || '0'
      this.address = this.initialLocation.address || ''
      this.selectedLocation = this.initialLocation
    }
  }

  /**
   * 验证位置数据
   */
  private validateLocation(): boolean {
    const lat = parseFloat(this.latitude)
    const lng = parseFloat(this.longitude)
    const alt = parseFloat(this.altitude)

    return !isNaN(lat) && !isNaN(lng) && !isNaN(alt) &&
           lat >= -90 && lat <= 90 &&
           lng >= -180 && lng <= 180 &&
           alt >= -1000 && alt <= 10000
  }

  /**
   * 确认位置选择
   */
  private confirmLocation(): void {
    if (!this.validateLocation()) {
      console.warn('位置数据无效')
      return
    }

    this.selectedLocation = {
      latitude: parseFloat(this.latitude),
      longitude: parseFloat(this.longitude),
      altitude: parseFloat(this.altitude),
      address: this.address.trim() || undefined
    }

    if (this.onLocationSelected) {
      this.onLocationSelected(this.selectedLocation)
    }

    this.showMapDialog = false
  }

  /**
   * 简单地图预览
   */
  @Builder
  private SimpleMapPreview() {
    Column() {
      Text('📍')
        .fontSize(24)
        .fontColor('#1890FF')
        .margin({ bottom: 8 })

      Text('点击选择地图位置')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      if (this.validateLocation()) {
        Row({ space: 16 }) {
          Column() {
            Text('📍')
              .fontSize(16)
              .fontColor('#52C41A')

            Text(`${this.latitude.toFixed(4)}°`)
              .fontSize(12)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
          }

          Column() {
            Text('🌐')
              .fontSize(16)
              .fontColor('#1890FF')

            Text(`${this.longitude.toFixed(4)}°`)
              .fontSize(12)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
          }

          if (this.showAltitude) {
            Column() {
              Text('⛰️')
                .fontSize(16)
                .fontColor('#FAAD14')

              Text(`${this.altitude}m`)
                .fontSize(12)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
            }
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .margin({ top: 16 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 手动输入位置
   */
  @Builder
  private ManualLocationInput() {
    Column({ space: 16 }) {
      Text('手动输入坐标')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.getCurrentTextColor())
        .margin({ bottom: 12 })

      // 纬度输入
      Row({ space: 12 }) {
        Text('纬度')
          .fontSize(14)
          .fontColor('#666666')
          .width(60)

        TextInput({ placeholder: '例: 39.9042' })
          .width('100%')
          .height(44)
          .fontSize(14)
          .fontColor('#333333')
          .backgroundColor('#FFFFFF')
          .borderRadius(6)
          .border({ width: 1, color: '#E0E0E0' })
          .onChange((value: string) => {
            this.latitude = value
          })
      }
      .width('100%')
    }

      // 经度输入
      Row({ space: 12 }) {
        Text('经度')
          .fontSize(14)
          .fontColor('#666666')
          .width(60)

        TextInput({ placeholder: '例: 116.4074' })
          .width('100%')
          .height(44)
          .fontSize(14)
          .fontColor('#333333')
          .backgroundColor('#FFFFFF')
          .borderRadius(6)
          .border({ width: 1, color: '#E0E0E0' })
          .onChange((value: string) => {
            this.longitude = value
          })
      }
      .width('100%')
    }

      // 海拔输入
      if (this.showAltitude) {
        Row({ space: 12 }) {
          Text('海拔')
            .fontSize(14)
            .fontColor('#666666')
            .width(60)

          TextInput({ placeholder: '例: 50' })
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor('#FFFFFF')
            .borderRadius(6)
            .border({ width: 1, color: '#E0E0E0' })
            .onChange((value: string) => {
              this.altitude = value
            })
        }
        .width('100%')
      }

      // 地址输入
      if (this.showAddress) {
        Row({ space: 12 }) {
          Text('地址')
            .fontSize(14)
            .fontColor('#666666')
            .width(60)

          TextInput({ placeholder: '详细地址' })
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor('#333333')
            .backgroundColor('#FFFFFF')
            .borderRadius(6)
            .border({ width: 1, color: '#E0E0E0' })
            .onChange((value: string) => {
              this.address = value
            })
        }
        .width('100%')
      }
    }
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.getCurrentTextColor())
          .layoutWeight(1)

        Button('关闭')
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(Color.Transparent)
          .onClick(() => this.showMapDialog = false)
      }
      .width('100%')
      .padding({ top: 16, left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      if (this.showMapDialog) {
        // 地图选择对话框
        Column() {
          // 简单地图预览
          this.SimpleMapPreview()

          // 输入切换按钮
          Row() {
            Button('地图选择')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#1890FF')
              .borderRadius(6)
              .margin({ right: 8 })
              .onClick(() => {
                // 这里可以集成真实的地图组件
                console.log('打开地图选择器')
              })

            Button('手动输入')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#52C41A')
              .borderRadius(6)
              .onClick(() => {
                this.showMapDialog = false
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FAFAFA')
          .borderRadius(8)
        }

        // 手动输入区域
        this.ManualLocationInput()

        // 确认按钮
        Row() {
          Blank()

          Button() {
            Text('确认选择')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
          .height(44)
          .padding({ left: 24, right: 24 })
          .backgroundColor('#1890FF')
          .borderRadius(22)
          .onClick(() => this.confirmLocation())
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: '#00000020',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ top: 16, left: 16, right: 16 })
    }

    // 触发按钮
    Button() {
      Text('选择位置')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
    }
    .height(44)
    .padding({ left: 20, right: 20 })
    .backgroundColor(ThemeManager.getCurrentPrimaryColor())
    .borderRadius(22)
    .onClick(() => {
      this.showMapDialog = true
    })
    .width('100%')
    .margin(16)
    .shadow({
      radius: 6,
      color: '#00000015',
      offsetX: 0,
      offsetY: 2
    })
  }
}