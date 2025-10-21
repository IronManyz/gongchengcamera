/**
 * 列表渲染示例
 * 展示 ForEach, LazyForEach, List, Grid 的用法
 */

// ========== ForEach 基本用法 ==========
@Entry
@Component
struct ForEachExample {
  @State fruits: Array<{ id: string, name: string, price: number }> = [
    { id: '1', name: 'Apple', price: 5 },
    { id: '2', name: 'Banana', price: 3 },
    { id: '3', name: 'Orange', price: 4 },
    { id: '4', name: 'Grape', price: 8 }
  ]

  build() {
    Column() {
      Text('Fruit List')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      List({ space: 10 }) {
        ForEach(
          this.fruits,
          (fruit: { id: string, name: string, price: number }) => {
            ListItem() {
              Row() {
                Text(fruit.name)
                  .fontSize(18)
                  .layoutWeight(1)
                Text(`$${fruit.price}`)
                  .fontSize(18)
                  .fontColor(Color.Green)
              }
              .width('100%')
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(8)
            }
          },
          (fruit: { id: string, name: string, price: number }) => fruit.id  // 唯一键
        )
      }
      .width('100%')
      .layoutWeight(1)

      Row({ space: 10 }) {
        Button('Add Item')
          .onClick(() => {
            const newId = (this.fruits.length + 1).toString()
            this.fruits.push({
              id: newId,
              name: `Fruit ${newId}`,
              price: Math.floor(Math.random() * 10) + 1
            })
          })

        Button('Remove First')
          .onClick(() => {
            if (this.fruits.length > 0) {
              this.fruits.shift()
            }
          })
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }
}

// ========== LazyForEach 懒加载列表 ==========
class MyDataSource implements IDataSource {
  private list: string[] = []
  private listeners: DataChangeListener[] = []

  constructor(data: string[]) {
    this.list = data
  }

  totalCount(): number {
    return this.list.length
  }

  getData(index: number): string {
    return this.list[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index)
    })
  }

  addData(data: string): void {
    this.list.push(data)
    this.notifyDataAdd(this.list.length - 1)
  }
}

@Entry
@Component
struct LazyForEachExample {
  private data: MyDataSource = new MyDataSource(
    Array.from({ length: 100 }, (_, i) => `Item ${i + 1}`)
  )

  build() {
    Column() {
      Text('Lazy Loaded List')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      List({ space: 5 }) {
        LazyForEach(
          this.data,
          (item: string, index: number) => {
            ListItem() {
              Text(item)
                .width('100%')
                .padding(15)
                .backgroundColor(Color.White)
                .borderRadius(8)
            }
          },
          (item: string) => item
        )
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      Button('Add Item')
        .margin({ top: 10 })
        .onClick(() => {
          this.data.addData(`Item ${this.data.totalCount() + 1}`)
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}

// ========== Grid 网格布局 ==========
@Entry
@Component
struct GridExample {
  @State items: number[] = Array.from({ length: 20 }, (_, i) => i + 1)

  build() {
    Column() {
      Text('Grid Layout')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Grid() {
        ForEach(
          this.items,
          (item: number) => {
            GridItem() {
              Column() {
                Text(`${item}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .height(100)
              .backgroundColor(Color.Blue)
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
            }
          },
          (item: number) => item.toString()
        )
      }
      .columnsTemplate('1fr 1fr 1fr')  // 3列
      .rowsGap(10)
      .columnsGap(10)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }
}
