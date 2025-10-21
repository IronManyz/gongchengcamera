/**
 * 组件生命周期示例
 * 展示 aboutToAppear, aboutToDisappear, aboutToReuse 等生命周期方法
 */

import http from '@ohos.net.http'

// ========== 基本生命周期 ==========
@Entry
@Component
struct LifecycleExample {
  @State data: string[] = []
  @State isLoading: boolean = false
  private timer: number = -1

  // 1. 组件即将出现 - 初始化数据
  aboutToAppear() {
    console.log('Component is about to appear')
    this.loadData()
    this.startTimer()
  }

  // 2. 组件即将消失 - 清理资源
  aboutToDisappear() {
    console.log('Component is about to disappear')
    this.stopTimer()
  }

  async loadData() {
    this.isLoading = true
    try {
      // 模拟异步数据加载
      await new Promise(resolve => setTimeout(resolve, 1000))
      this.data = ['Item 1', 'Item 2', 'Item 3']
    } finally {
      this.isLoading = false
    }
  }

  startTimer() {
    this.timer = setInterval(() => {
      console.log('Timer tick:', new Date().toISOString())
    }, 1000)
  }

  stopTimer() {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
      console.log('Timer stopped')
    }
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
      } else {
        List({ space: 10 }) {
          ForEach(this.data, (item: string) => {
            ListItem() {
              Text(item)
                .padding(15)
                .backgroundColor(Color.White)
                .borderRadius(8)
            }
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }
}

// ========== @Reusable 组件复用 ==========
@Reusable
@Component
struct ReusableListItem {
  @State item: string = ''
  @State timestamp: string = ''

  // 组件首次创建时调用
  aboutToAppear() {
    console.log(`ReusableListItem created: ${this.item}`)
    this.timestamp = new Date().toISOString()
  }

  // 组件被复用时调用
  aboutToReuse(params: ESObject) {
    console.log(`ReusableListItem reused from ${this.item} to ${params.item}`)
    this.item = params.item
    this.timestamp = new Date().toISOString()
  }

  // 组件回收时调用
  aboutToRecycle() {
    console.log(`ReusableListItem recycled: ${this.item}`)
  }

  build() {
    Row() {
      Column({ space: 5 }) {
        Text(this.item)
          .fontSize(18)
        Text(this.timestamp)
          .fontSize(12)
          .fontColor(Color.Gray)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}

@Entry
@Component
struct ReusableExample {
  @State items: string[] = Array.from({ length: 10 }, (_, i) => `Item ${i + 1}`)

  build() {
    Column() {
      Text('Reusable Components')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      List({ space: 10 }) {
        ForEach(
          this.items,
          (item: string) => {
            ListItem() {
              ReusableListItem({ item: item })
                .reuseId(item)  // 设置复用 ID
            }
          },
          (item: string) => item
        )
      }
      .width('100%')
      .layoutWeight(1)

      Row({ space: 10 }) {
        Button('Add Item')
          .onClick(() => {
            this.items.push(`Item ${this.items.length + 1}`)
          })

        Button('Remove First')
          .onClick(() => {
            if (this.items.length > 0) {
              this.items.shift()
            }
          })

        Button('Shuffle')
          .onClick(() => {
            this.items = [...this.items].sort(() => Math.random() - 0.5)
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

// ========== 网络请求生命周期 ==========
@Entry
@Component
struct NetworkExample {
  @State users: Array<{ id: number, name: string }> = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''

  aboutToAppear() {
    this.fetchUsers()
  }

  async fetchUsers() {
    this.isLoading = true
    this.errorMessage = ''

    const httpRequest = http.createHttp()

    try {
      const response = await httpRequest.request(
        'https://jsonplaceholder.typicode.com/users',
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          },
          connectTimeout: 60000,
          readTimeout: 60000
        }
      )

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string)
        this.users = data.map((user: any) => ({
          id: user.id,
          name: user.name
        }))
      } else {
        this.errorMessage = `Error: ${response.responseCode}`
      }
    } catch (error) {
      console.error('Network error:', error)
      this.errorMessage = 'Network request failed'
    } finally {
      httpRequest.destroy()
      this.isLoading = false
    }
  }

  build() {
    Column() {
      Text('Network Request Example')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
          Text('Loading...')
            .margin({ top: 10 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        Column() {
          Text(this.errorMessage)
            .fontColor(Color.Red)
          Button('Retry')
            .margin({ top: 20 })
            .onClick(() => {
              this.fetchUsers()
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(
            this.users,
            (user: { id: number, name: string }) => {
              ListItem() {
                Text(user.name)
                  .width('100%')
                  .padding(15)
                  .backgroundColor(Color.White)
                  .borderRadius(8)
              }
            },
            (user: { id: number, name: string }) => user.id.toString()
          )
        }
        .width('100%')
        .layoutWeight(1)
      }

      Button('Refresh')
        .width('80%')
        .margin({ top: 20 })
        .onClick(() => {
          this.fetchUsers()
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }
}

// ========== 监听页面显示/隐藏 ==========
@Entry
@Component
struct PageLifecycleExample {
  @State isPageVisible: boolean = true
  @State visitCount: number = 0

  onPageShow() {
    console.log('Page is now visible')
    this.isPageVisible = true
    this.visitCount++
  }

  onPageHide() {
    console.log('Page is now hidden')
    this.isPageVisible = false
  }

  build() {
    Column() {
      Text('Page Lifecycle')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Text(`Page is ${this.isPageVisible ? 'Visible' : 'Hidden'}`)
        .fontSize(18)
        .margin({ bottom: 10 })

      Text(`Visit count: ${this.visitCount}`)
        .fontSize(18)

      Text('Navigate to another page and come back to see the lifecycle in action')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
  }
}
