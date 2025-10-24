/**
 * 简单项目卡片组件
 * 用于测试项目卡片功能
 */

import { SimpleProject } from '../../models/SimpleProject'

@ComponentV2
export struct SimpleProjectCard {
  @Param project: SimpleProject = new SimpleProject()
  @Param showStats: boolean = true
  @Require @Param onTap?: (project: SimpleProject) => void
  @Require @Param onLongPress?: (project: SimpleProject) => void

  build() {
    Column() {
      // 项目头部信息
      Row() {
        Column() {
          // 项目名称
          Text(this.project.getDisplayName())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262626')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
            .width('100%')

          // 项目代码
          if (this.project.code) {
            Text(this.project.code)
              .fontSize(14)
              .fontColor('#8C8C8C')
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Start)
              .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 状态标签
        Text(this.project.getStatusText())
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor(this.project.getStatusColor())
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(12)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 客户信息
      if (this.project.client) {
        Row() {
          Text('客户:')
            .fontSize(14)
            .fontColor('#8C8C8C')
          Text(this.project.client)
            .fontSize(14)
            .fontColor('#595959')
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ bottom: 8 })
      }

      // 管理员信息
      if (this.project.manager) {
        Row() {
          Text('负责人:')
            .fontSize(14)
            .fontColor('#8C8C8C')
          Text(this.project.manager)
            .fontSize(14)
            .fontColor('#595959')
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ bottom: 12 })
      }

      // 统计信息
      if (this.showStats) {
        Row() {
          Column() {
            Text(this.project.siteCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
            Text('工点')
              .fontSize(12)
              .fontColor('#8C8C8C')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          Column() {
            Text(this.project.photoCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#262626')
            Text('照片')
              .fontSize(12)
              .fontColor('#8C8C8C')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          Column() {
            Text(this.formatDate(this.project.updatedAt))
              .fontSize(12)
              .fontColor('#8C8C8C')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.End)
          .layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: '#00000008',
      offsetX: 0,
      offsetY: 3
    })
    .animation({ duration: 150, curve: Curve.EaseInOut })
    .onClick(() => {
      console.log('Project card clicked:', this.project.name, 'ID:', this.project.id)
      if (this.onTap) {
        this.onTap(this.project)
      } else {
        console.warn('Project card: onTap callback is not defined')
      }
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          console.log('Project card long pressed:', this.project.name)
          this.onLongPress?.(this.project)
        })
    )
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (days === 0) {
      return '今天'
    } else if (days === 1) {
      return '昨天'
    } else if (days < 7) {
      return `${days}天前`
    } else {
      return `${date.getMonth() + 1}-${date.getDate()}`
    }
  }
}