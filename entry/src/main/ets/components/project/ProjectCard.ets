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
  @Param elevation?: boolean = true // 改为默认开启高程效果
  @Local private isPressed: boolean = false // 改为Local状态

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

  // 获取状态图标
  private getStatusIcon(status: ProjectStatus): string {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return '🟢' // 绿色圆圈
      case ProjectStatus.COMPLETED:
        return '✅' // 完成标记
      case ProjectStatus.PAUSED:
        return '⏸️' // 暂停符号
      case ProjectStatus.CANCELLED:
        return '❌' // 取消标记
      default:
        return '⚪' // 空白圆圈
    }
  }

  // 获取健康状态颜色
  private getHealthStatusColor(progress: number): string {
    if (progress >= 75) {
      return '#52C41A' // 绿色 - 良好
    } else if (progress >= 50) {
      return '#FAAD14' // 橙色 - 中等
    } else if (progress >= 25) {
      return '#FA8C16' // 深橙色 - 需要关注
    } else {
      return '#FF4D4F' // 红色 - 紧急
    }
  }

  // 获取卡片背景颜色
  private getCardBackgroundColor(status: ProjectStatus): string {
    const color = this.getStatusColor(status)
    return `${color}05` // 简单的背景色
  }

  build() {
    Column() {
      // 顶部状态指示条
      Row()
        .width('100%')
        .height(3)
        .backgroundColor(this.getStatusColor(this.project.status))
        .borderRadius({ topLeft: 8, topRight: 8 })

      // 主要内容区域
      Row() {
        // 左侧状态指示器
        Column() {
          Text(this.getStatusIcon(this.project.status))
            .fontSize(20)
            .margin({ bottom: 8 })

          // 进度环
          Stack() {
            Circle({ width: 40, height: 40 })
              .fill(this.getHealthStatusColor(this.project.progress) + '20')
              .stroke(this.getHealthStatusColor(this.project.progress))
              .strokeWidth(2)

            Text(`${this.project.progress}%`)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getHealthStatusColor(this.project.progress))
          }
        }
        .width(50)
        .alignItems(HorizontalAlign.Center)

        // 中间信息区域
        Column() {
          // 项目编号
          Text(this.project.code)
            .fontSize(12)
            .fontColor('#1890FF')
            .fontWeight(FontWeight.Medium)
            .fontStyle(FontStyle.Italic)
            .margin({ top: 4 })

          // 项目名称
          Text(this.project.getDisplayName())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          // 负责人和客户信息
          Row({ space: 12 }) {
            // 负责人
            Row({ space: 4 }) {
              Text('👤')
                .fontSize(12)
                .fontColor('#595959')
              Text(this.project.manager || '未指定')
                .fontSize(12)
                .fontColor('#595959')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .layoutWeight(1)

            // 客户
            Row({ space: 4 }) {
              Text('🏢')
                .fontSize(12)
                .fontColor('#595959')
              Text(this.project.client)
                .fontSize(12)
                .fontColor('#595959')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 6 })

          // 标签行
          Row({ space: 8 }) {
            // 优先级标签
            if (this.project.priority) {
              Text(this.getPriorityText(this.project.priority))
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor(this.getPriorityColor(this.project.priority))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(10)
                .maxLines(1)
            }

            // 状态标签
            Text(this.getStatusText(this.project.status))
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor(this.getStatusColor(this.project.status))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(10)
              .maxLines(1)

            // 时间标签
            Text(this.getRelativeTime(this.project.updatedAt))
              .fontSize(10)
              .fontColor('#8C8C8C')
              .backgroundColor('#F5F5F5')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(10)
              .maxLines(1)
          }
          .width('100%')
          .margin({ top: 8 })

          // 统计信息
          if (this.showStats) {
            Column() {
              // 统计数据行
              Row({ space: 16 }) {
                // 工点统计
                Column({ space: 4 }) {
                  Text(`${this.project.siteCount || 0}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1890FF')
                  Text('工点')
                    .fontSize(10)
                    .fontColor('#8C8C8C')
                }
                .layoutWeight(1)
                .backgroundColor('#F0F8FF')
                .padding({ top: 8, bottom: 8 })
                .borderRadius(8)

                // 照片统计
                Column({ space: 4 }) {
                  Text(`${this.project.photoCount || 0}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#722ED1')
                  Text('照片')
                    .fontSize(10)
                    .fontColor('#8C8C8C')
                }
                .layoutWeight(1)
                .backgroundColor('#F9F0FF')
                .padding({ top: 8, bottom: 8 })
                .borderRadius(8)

                // 进度指示
                Column({ space: 4 }) {
                  Text(`${this.project.progress}%`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getHealthStatusColor(this.project.progress))
                  Text('进度')
                    .fontSize(10)
                    .fontColor('#8C8C8C')
                }
                .layoutWeight(1)
                .backgroundColor(`${this.getHealthStatusColor(this.project.progress)}15`)
                .padding({ top: 8, bottom: 8 })
                .borderRadius(8)
              }
              .width('100%')
              .margin({ top: 8 })
            }
            .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ right: 12 })

        // 右侧操作区域
        Column({ space: 8 }) {
          // 更多操作按钮
          Button() {
            Text('⋮')
              .fontSize(16)
              .fontColor('#8C8C8C')
          }
          .width(32)
          .height(32)
          .backgroundColor('#F5F5F5')
          .borderRadius(16)
          .onClick(() => {
            if (this.onLongPress) {
              this.onLongPress(this.project)
            }
          })

          Blank()

          // 状态指示器
          if (this.project.status === ProjectStatus.ACTIVE) {
            Column({ space: 2 }) {
              Circle({ width: 8, height: 8 })
                .fill(this.getStatusColor(this.project.status))
              Text('活跃')
                .fontSize(8)
                .fontColor(this.getStatusColor(this.project.status))
            }
          }
        }
        .width(40)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow(this.elevation ? {
      radius: this.isPressed ? 2 : 8,
      color: this.isPressed ? '#00000015' : '#00000020',
      offsetX: 0,
      offsetY: this.isPressed ? 1 : 4
    } : undefined)
    .scale({ x: this.isPressed ? 0.98 : 1.0, y: this.isPressed ? 0.98 : 1.0 })
    .animation({
      duration: 150,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.project)
      }
    })
    .gesture(
      // 按压手势
      TapGesture({ count: 1 })
        .onAction(() => {
          // 点击时的按压效果
          this.isPressed = true
          setTimeout(() => {
            this.isPressed = false
          }, 150)
        })
    )
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          if (this.onLongPress) {
            this.onLongPress(this.project)
          }
        })
        .onAction(() => {
          // 长按时的视觉反馈
          this.isPressed = false
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