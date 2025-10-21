/**
 * 路由导航示例
 * 展示页面跳转、参数传递、返回等导航功能
 */

import router from '@ohos.router'

// ========== 首页 ==========
@Entry
@Component
struct HomePage {
  @State items: Array<{ id: number, title: string, description: string }> = [
    { id: 1, title: 'Item 1', description: 'Description for item 1' },
    { id: 2, title: 'Item 2', description: 'Description for item 2' },
    { id: 3, title: 'Item 3', description: 'Description for item 3' }
  ]

  build() {
    Column() {
      Text('Home Page')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      List({ space: 10 }) {
        ForEach(
          this.items,
          (item: { id: number, title: string, description: string }) => {
            ListItem() {
              Row() {
                Column({ space: 5 }) {
                  Text(item.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                  Text(item.description)
                    .fontSize(14)
                    .fontColor(Color.Gray)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Button('View')
                  .onClick(() => {
                    // 跳转到详情页并传递参数
                    router.pushUrl({
                      url: 'pages/Detail',
                      params: {
                        id: item.id,
                        title: item.title,
                        description: item.description
                      }
                    })
                  })
              }
              .width('100%')
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(8)
            }
          },
          (item: { id: number, title: string, description: string }) => item.id.toString()
        )
      }
      .width('100%')
      .layoutWeight(1)

      Button('Go to Settings')
        .width('80%')
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/Settings' })
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }
}

// ========== 详情页 ==========
@Entry
@Component
struct DetailPage {
  @State itemId: number = 0
  @State itemTitle: string = ''
  @State itemDescription: string = ''

  aboutToAppear() {
    // 接收路由参数
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.itemId = params.id as number
      this.itemTitle = params.title as string
      this.itemDescription = params.description as string
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button('← Back')
          .onClick(() => {
            router.back()
          })
        Text('Detail Page')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        // 占位保持标题居中
        Button('').visibility(Visibility.Hidden)
      }
      .width('100%')
      .padding(10)
      .backgroundColor(Color.White)

      // 内容区域
      Column({ space: 20 }) {
        Text(`ID: ${this.itemId}`)
          .fontSize(16)
          .fontColor(Color.Gray)

        Text(this.itemTitle)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(this.itemDescription)
          .fontSize(16)
          .fontColor(Color.Gray)

        Divider()

        // 模拟详细内容
        Text('Detailed Information')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' +
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.')
          .fontSize(14)
          .lineHeight(22)
      }
      .width('100%')
      .padding(20)
      .layoutWeight(1)

      // 底部按钮
      Row({ space: 10 }) {
        Button('Edit')
          .layoutWeight(1)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/Edit',
              params: {
                id: this.itemId,
                title: this.itemTitle
              }
            })
          })

        Button('Delete')
          .layoutWeight(1)
          .backgroundColor(Color.Red)
          .onClick(() => {
            // 返回时传递结果
            router.back({
              url: 'pages/Home',
              params: {
                action: 'delete',
                id: this.itemId
              }
            })
          })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// ========== 设置页 ==========
@Entry
@Component
struct SettingsPage {
  @State isDarkMode: boolean = false
  @State fontSize: number = 16
  @State notificationsEnabled: boolean = true

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('← Back')
          .onClick(() => {
            router.back()
          })
        Text('Settings')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button('').visibility(Visibility.Hidden)
      }
      .width('100%')
      .padding(10)
      .backgroundColor(Color.White)

      // 设置项
      List() {
        ListItem() {
          Row() {
            Text('Dark Mode')
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.isDarkMode })
              .onChange((isOn: boolean) => {
                this.isDarkMode = isOn
              })
          }
          .width('100%')
          .padding(15)
        }

        ListItem() {
          Row() {
            Text('Font Size')
              .layoutWeight(1)
            Text(`${this.fontSize}`)
              .margin({ right: 10 })
            Button('+')
              .onClick(() => {
                this.fontSize++
              })
            Button('-')
              .margin({ left: 5 })
              .onClick(() => {
                if (this.fontSize > 12) {
                  this.fontSize--
                }
              })
          }
          .width('100%')
          .padding(15)
        }

        ListItem() {
          Row() {
            Text('Notifications')
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.notificationsEnabled })
              .onChange((isOn: boolean) => {
                this.notificationsEnabled = isOn
              })
          }
          .width('100%')
          .padding(15)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .divider({ strokeWidth: 1, color: '#F0F0F0' })

      Button('Save Settings')
        .width('80%')
        .margin({ top: 20, bottom: 20 })
        .onClick(() => {
          // 保存设置并返回
          console.log('Settings saved')
          router.back()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// ========== 使用 replace 替换页面（不保留历史） ==========
@Component
struct LoginPage {
  @State username: string = ''
  @State password: string = ''

  handleLogin() {
    // 登录成功后替换为首页，不允许返回登录页
    router.replaceUrl({
      url: 'pages/Home',
      params: {
        username: this.username
      }
    })
  }

  build() {
    Column({ space: 20 }) {
      Text('Login')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: 'Username', text: this.username })
        .width('80%')
        .onChange((value: string) => {
          this.username = value
        })

      TextInput({ placeholder: 'Password', text: this.password })
        .width('80%')
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value
        })

      Button('Login')
        .width('80%')
        .onClick(() => {
          this.handleLogin()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
