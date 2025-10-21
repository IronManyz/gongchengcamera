/**
 * 基础组件示例
 * 展示 HarmonyOS ArkTS 的基本组件结构和用法
 */

@Entry
@Component
struct BasicComponentExample {
  @State message: string = 'Hello HarmonyOS'
  @State count: number = 0

  build() {
    Column({ space: 20 }) {
      // 文本组件
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Blue)

      // 按钮组件
      Button('Click Me')
        .width(200)
        .onClick(() => {
          this.count++
          this.message = `Clicked ${this.count} times`
        })

      // 图片组件
      Image($r('app.media.startIcon'))
        .width(100)
        .height(100)
        .objectFit(ImageFit.Contain)

      // 文本输入框
      TextInput({ placeholder: 'Enter text here' })
        .width('80%')
        .onChange((value: string) => {
          console.log('Input value:', value)
        })

      // 分隔线
      Divider()
        .width('80%')
        .color(Color.Gray)

      // 进度条
      Progress({ value: this.count, total: 10, type: ProgressType.Linear })
        .width('80%')
        .color(Color.Green)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }
}
