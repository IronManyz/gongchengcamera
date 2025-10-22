/**
 * 工程卡片组件
 * 展示工程概要信息，符合原型设计
 */

import { Project } from '../../models/Project'
import { ProjectStatus } from '../../types/AppTypes'
import router from '@ohos.router'

@ComponentV2
export struct ProjectCard {
  @Require @Param project: Project = new Project()
  @Param showStats: boolean = true
  @Param onTap: (project: Project) => void = () => {}
  @Require @Param onLongPress: (project: Project) => void = () => {}
  @Param showTeamMember?: boolean = true // 新增团队成员显示
  @Param compact?: boolean = false // 新增紧凑布局模式
  @Param elevation?: boolean = false // 新增高程效果

  // 状态颜色映射
  private getStatusColor(status: ProjectStatus): string {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return '#52C41A' // 绿色 - 进行中
      case ProjectStatus.COMPLETED:
        return '#1890FF' // 蓝色 - 已完成
      case ProjectStatus.PAUSED:
        return '#FAAD14' // 橙色 - 暂停
      case ProjectStatus.CANCELLED:
        return '#FF4D4F' // 红色 - 已取消
      default:
        return '#8C8C8C' // 灰色 - 未知
    }
  }

  // 状态文本映射
  private getStatusText(status: ProjectStatus): string {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return '进行中'
      case ProjectStatus.COMPLETED:
        return '已完成'
      case ProjectStatus.PAUSED:
        return '暂停中'
      case ProjectStatus.CANCELLED:
        return '已取消'
      default:
        return '未知'
    }
  }

  // 项目健康状态文本映射
  private getHealthStatusText(project: Project): string {
    if (project.progress >= 100) {
      return '项目完成'
    } else if (project.progress >= 75) {
      return '即将完成'
    } else if (project.progress >= 50) {
      return '进展良好'
    } else if (project.progress >= 25) {
      return '需要关注'
    } else {
      return '需要启动'
    }
  }

  // 优先级文本映射
  private getPriorityText(priority: string): string {
    switch (priority.toLowerCase()) {
      case 'high':
      case '高':
        return '高优先级'
      case 'medium':
      case '中':
        return '中优先级'
      case 'low':
      case '低':
        return '低优先级'
      default:
        return priority
    }
  }

  // 优先级颜色映射
  private getPriorityColor(priority: string): string {
    switch (priority.toLowerCase()) {
      case 'high':
      case '高':
        return '#FF4D4F' // 红色
      case 'medium':
      case '中':
        return '#FAAD14' // 橙色
      case 'low':
      case '低':
        return '#52C41A' // 绿色
      default:
        return '#8C8C8C' // 灰色
    }
  }

  build() {
    Column() {
      // 主要内容区域
      Row() {
        // 左侧信息
        Column() {
          // 项目编号和名称
          Row() {
            Text(`📁 ${this.project.code}`)
              .fontSize(14)
              .fontColor('#1890FF')
              .fontWeight(FontWeight.Medium)

            Blank()

            // 状态标签
            Text(this.getStatusText(this.project.status))
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor(this.getStatusColor(this.project.status))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(4)
          }
          .width('100%')

          // 项目名称
          Text(this.project.getDisplayName())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262626')
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          // 负责人信息
          Row() {
            Text(`👤 ${this.project.manager || '未指定'}`)
              .fontSize(14)
              .fontColor('#595959')
              .margin({ top: 6 })

            Blank()

            // 项目优先级或类型标签
            if (this.project.priority) {
              Text(this.getPriorityText(this.project.priority))
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor(this.getPriorityColor(this.project.priority))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(3)
                .margin({ top: 6 })
            }
          }
          .width('100%')

          // 统计信息
          if (this.showStats) {
            Column() {
              // 统计数据行
              Row() {
                // 工点统计
                Row() {
                  Text('📍')
                    .fontSize(14)
                    .fontColor('#1890FF')
                  Text(`${this.project.siteCount || 0}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#262626')
                    .margin({ left: 4 })
                  Text('个工点')
                    .fontSize(12)
                    .fontColor('#8C8C8C')
                    .margin({ left: 2 })
                }
                .layoutWeight(1)

                // 照片统计
                Row() {
                  Text('📷')
                    .fontSize(14)
                    .fontColor('#722ED1')
                  Text(`${this.project.photoCount || 0}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#262626')
                    .margin({ left: 4 })
                  Text('张照片')
                    .fontSize(12)
                    .fontColor('#8C8C8C')
                    .margin({ left: 2 })
                }
                .layoutWeight(1)
              }
              .width('100%')

              // 进度条（如果有的话）
              if (this.project.progress !== undefined) {
                Row() {
                  Text('完成进度')
                    .fontSize(12)
                    .fontColor('#8C8C8C')
                    .margin({ right: 8 })

                  Progress({
                    value: this.project.progress,
                    total: 100,
                    type: ProgressType.Linear
                  })
                    .layoutWeight(1)
                    .color('#1890FF')
                    .backgroundColor('#F0F0F0')
                    .height(6)

                  Text(`${this.project.progress}%`)
                    .fontSize(12)
                    .fontColor('#1890FF')
                    .fontWeight(FontWeight.Medium)
                    .margin({ left: 8 })
                }
                .width('100%')
                .margin({ top: 8 })
              }

              // 时间信息
              Text(this.getRelativeTime(this.project.updatedAt))
                .fontSize(12)
                .fontColor('#BFBFBF')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 6 })
            }
            .width('100%')
            .margin({ top: 8 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ right: 12 })

        // 右侧操作按钮
        Column() {
          Text('⋮')
            .fontSize(20)
            .fontColor('#8C8C8C')
            .onClick(() => {
              if (this.onLongPress) {
                this.onLongPress(this.project)
              }
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.project)
      }
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          if (this.onLongPress) {
            this.onLongPress(this.project)
          }
        })
    )
  }

  /**
   * 获取相对时间显示
   */
  private getRelativeTime(date: Date): string {
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMinutes = Math.floor(diffMs / (1000 * 60))
    const diffHours = Math.floor(diffMinutes / 60)
    const diffDays = Math.floor(diffHours / 24)

    if (diffMinutes < 1) {
      return '刚刚'
    } else if (diffMinutes < 60) {
      return `${diffMinutes}分钟前`
    } else if (diffHours < 24) {
      return `${diffHours}小时前`
    } else if (diffDays < 7) {
      return `${diffDays}天前`
    } else {
      return this.formatDate(date)
    }
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getMonth() + 1}-${date.getDate()}`
  }
}