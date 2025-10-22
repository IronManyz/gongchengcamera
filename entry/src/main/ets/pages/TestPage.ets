/**
 * 测试页面
 * 最简单的交互测试
 */

@Entry
@Component
struct TestPage {
  @State message: string = 'Hello World'
  @State counter: number = 0

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100, bottom: 20 })

      Text(`计数器: ${this.counter}`)
        .fontSize(20)
        .margin({ bottom: 30 })

      Button('点击我 +1')
        .fontSize(18)
        .width(200)
        .height(50)
        .backgroundColor('#007DFF')
        .margin({ bottom: 20 })
        .onClick(() => {
          this.counter++
          console.log(`Button clicked! Counter: ${this.counter}`)
        })

      Button('重置计数器')
        .fontSize(18)
        .width(200)
        .height(50)
        .backgroundColor('#FF6B6B')
        .margin({ bottom: 20 })
        .onClick(() => {
          this.counter = 0
          console.log('Counter reset!')
        })

      Button('改变文字')
        .fontSize(18)
        .width(200)
        .height(50)
        .backgroundColor('#52C41A')
        .margin({ bottom: 20 })
        .onClick(() => {
          this.message = this.message === 'Hello World' ? '你好，世界！' : 'Hello World'
          console.log('Message changed!')
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}