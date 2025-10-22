/**
 * 测试页面
 * 测试新组件功能
 */

import router from '@ohos.router'
import { StatCard } from '../components/common/StatCard'
import { SimpleProjectCard } from '../components/project/SimpleProjectCard'
import { SimpleProject } from '../models/SimpleProject'
import { ProjectStatus } from '../types/SimpleTypes'

@Entry
@ComponentV2
struct TestPage {
  @Local message: string = 'Hello World'
  @Local counter: number = 0
  @Local showCards: boolean = false
  @Local testProject: SimpleProject = new SimpleProject('测试项目', 'TEST001')

  aboutToAppear() {
    console.log('TestPage aboutToAppear')
    // Initialize the SimpleProject
    this.testProject = new SimpleProject('测试项目', 'TEST001')
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text(`计数器: ${this.counter}`)
        .fontSize(20)
        .margin({ bottom: 20 })

      // 测试按钮区域
      Column() {
        Button('点击我 +1')
          .fontSize(16)
          .width(180)
          .height(45)
          .backgroundColor('#007DFF')
          .margin({ bottom: 10 })
          .onClick(() => {
            this.counter++
            console.log(`Button clicked! Counter: ${this.counter}`)
          })

        Button('重置计数器')
          .fontSize(16)
          .width(180)
          .height(45)
          .backgroundColor('#FF6B6B')
          .margin({ bottom: 10 })
          .onClick(() => {
            this.counter = 0
            console.log('Counter reset!')
          })

        Button('改变文字')
          .fontSize(16)
          .width(180)
          .height(45)
          .backgroundColor('#52C41A')
          .margin({ bottom: 10 })
          .onClick(() => {
            this.message = this.message === 'Hello World' ? '你好，世界！' : 'Hello World'
            console.log('Message changed!')
          })

        Button(this.showCards ? '隐藏组件' : '显示组件')
          .fontSize(16)
          .width(180)
          .height(45)
          .backgroundColor('#9B59B6')
          .margin({ bottom: 10 })
          .onClick(() => {
            this.showCards = !this.showCards
            console.log(`Cards visibility: ${this.showCards}`)
          })

        Button('返回主页')
          .fontSize(16)
          .width(180)
          .height(45)
          .backgroundColor('#34495E')
          .onClick(() => {
            router.back()
          })
      }
      .margin({ bottom: 20 })

      // 组件测试区域
      if (this.showCards) {
        Column() {
          Text('🎯 组件测试区域')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 16 })

          // 统计卡片测试
          Row() {
            StatCard({
              title: '测试数值1',
              value: this.counter,
              icon: '📁',
              color: '#1890FF',
              trend: 'up'
            })
            .layoutWeight(1)

            StatCard({
              title: '测试数值2',
              value: this.counter * 2,
              icon: '📊',
              color: '#52C41A',
              trend: 'stable'
            })
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })

          Text('✅ StatCard 组件工作正常!')
            .fontSize(14)
            .fontColor('#52C41A')
            .margin({ bottom: 20 })

          // 项目卡片测试
          SimpleProjectCard({
            project: this.testProject,
            showStats: true,
            onTap: (project) => {
              console.log(`点击了项目: ${project.getDisplayName()}`)
            },
            onLongPress: (project) => {
              console.log(`长按了项目: ${project.getDisplayName()}`)
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          Text('✅ SimpleProjectCard 组件工作正常!')
            .fontSize(14)
            .fontColor('#52C41A')
            .margin({ bottom: 16 })

          Button('更新项目数据')
            .fontSize(14)
            .width(150)
            .height(40)
            .backgroundColor('#3498DB')
            .margin({ bottom: 16 })
            .onClick(() => {
              this.testProject.siteCount = this.counter
              this.testProject.photoCount = this.counter * 3
              this.testProject.client = '测试客户公司'
              this.testProject.manager = '张经理'
              console.log('项目数据已更新')
            })

          Button('跳转到项目列表测试')
            .fontSize(16)
            .width(200)
            .height(45)
            .backgroundColor('#E67E22')
            .onClick(() => {
              router.pushUrl({
                url: 'pages/project/ProjectListPage',
                params: {}
              }).catch((error: Error) => {
                console.error('跳转到项目列表失败:', error)
              })
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ left: 16, right: 16 })
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F5F5')
    .padding({ top: 20, bottom: 20 })
  }
}