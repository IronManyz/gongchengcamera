/**
 * 简化版项目列表页面
 * 用于解决启动白屏问题
 */

import router from '@ohos.router'

interface Project {
  id: number
  name: string
  status: string
  description: string
}

@Entry
@Component
struct SimpleProjectListPage {
  @State private projects: Array<Project> = [
    { id: 1, name: '示例项目1', status: '进行中', description: '这是一个示例项目' },
    { id: 2, name: '示例项目2', status: '已完成', description: '这是另一个示例项目' }
  ]

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('项目列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Blank()

        Button('新建项目')
          .fontSize(14)
          .height(36)
          .onClick(() => {
            console.log('新建项目')
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 项目列表
      List({ space: 12 }) {
        ForEach(this.projects, (project: Project) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Text(project.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')

                  Text(project.description)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(project.status)
                  .fontSize(12)
                  .fontColor(project.status === '进行中' ? '#007DFF' : '#52C41A')
                  .backgroundColor(project.status === '进行中' ? '#E6F7FF' : '#F6FFED')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(4)
              }
              .width('100%')
              .padding(16)
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .shadow({
              radius: 4,
              color: '#00000010',
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              console.log('点击项目:', project.name)
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16 })

      // 底部导航提示
      Row() {
        Text('工程拍记 v1.0.0')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}