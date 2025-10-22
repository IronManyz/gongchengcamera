/**
 * 简单项目模型
 * 用于测试新组件功能
 */

import { ProjectStatus } from '../types/SimpleTypes'

// 导出ProjectStatus供其他模块使用
export { ProjectStatus }

@ObservedV2
export class SimpleProject {
  @Trace id: string = ''
  @Trace name: string = ''
  @Trace code: string = ''
  @Trace client: string = ''
  @Trace manager: string = ''
  @Trace status: ProjectStatus = ProjectStatus.ACTIVE
  @Trace siteCount: number = 0
  @Trace photoCount: number = 0
  @Trace createdAt: Date = new Date()
  @Trace updatedAt: Date = new Date()

  constructor(id?: string, name?: string, status?: ProjectStatus, manager?: string, siteCount?: number, photoCount?: number) {
    if (id) this.id = id
    if (name) this.name = name
    if (status) this.status = status
    if (manager) this.manager = manager
    if (siteCount) this.siteCount = siteCount
    if (photoCount) this.photoCount = photoCount
    if (!this.id) this.id = Date.now().toString()
  }

  /**
   * 获取项目显示名称
   */
  getDisplayName(): string {
    return this.name || this.code || '未命名项目'
  }

  /**
   * 获取项目状态显示文本
   */
  getStatusText(): string {
    switch (this.status) {
      case ProjectStatus.ACTIVE:
        return '进行中'
      case ProjectStatus.COMPLETED:
        return '已完成'
      case ProjectStatus.PAUSED:
        return '已暂停'
      case ProjectStatus.CANCELLED:
        return '已取消'
      default:
        return '未知状态'
    }
  }

  /**
   * 获取状态颜色
   */
  getStatusColor(): string {
    switch (this.status) {
      case ProjectStatus.ACTIVE:
        return '#4CAF50'
      case ProjectStatus.COMPLETED:
        return '#2196F3'
      case ProjectStatus.PAUSED:
        return '#FF9800'
      case ProjectStatus.CANCELLED:
        return '#F44336'
      default:
        return '#757575'
    }
  }
}