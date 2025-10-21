/**
 * ProjectStateManager.ets
 * 项目状态管理器
 * 负责项目的状态转换、生命周期管理和业务规则
 */

import { Project } from '../../models/Project'
import { ProjectStatus } from '../../types/AppTypes'
import { projectService } from '../../services/database/ProjectService'
import { siteService } from '../../services/database/SiteService'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ProjectStateManager'

/**
 * 项目状态转换规则接口
 */
export interface StatusTransitionRule {
  from: ProjectStatus
  to: ProjectStatus
  validator?: (project: Project) => boolean
  description: string
}

/**
 * 项目状态管理器
 */
export class ProjectStateManager {
  private static instance: ProjectStateManager | null = null

  // 状态转换规则
  private readonly statusTransitions: StatusTransitionRule[] = [
    {
      from: ProjectStatus.ACTIVE,
      to: ProjectStatus.COMPLETED,
      validator: (project) => {
        // 检查项目是否有工点和照片
        return project.siteCount > 0 && project.photoCount > 0
      },
      description: '项目完成需要至少有一个工点和照片'
    },
    {
      from: ProjectStatus.ACTIVE,
      to: ProjectStatus.PAUSED,
      description: '暂停进行中的项目'
    },
    {
      from: ProjectStatus.ACTIVE,
      to: ProjectStatus.CANCELLED,
      description: '取消进行中的项目'
    },
    {
      from: ProjectStatus.PAUSED,
      to: ProjectStatus.ACTIVE,
      description: '恢复暂停的项目'
    },
    {
      from: ProjectStatus.PAUSED,
      to: ProjectStatus.CANCELLED,
      description: '取消暂停的项目'
    },
    {
      from: ProjectStatus.COMPLETED,
      to: ProjectStatus.ACTIVE,
      validator: (project) => {
        // 已完成的项目需要���理员确认才能重新激活
        return true // 这里可以添加权限检查
      },
      description: '重新激活已完成的项目需要管理员权限'
    }
  ]

  /**
   * 获取单例实例
   */
  static getInstance(): ProjectStateManager {
    if (!ProjectStateManager.instance) {
      ProjectStateManager.instance = new ProjectStateManager()
    }
    return ProjectStateManager.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 检查状态转换是否允许
   */
  canTransitionStatus(project: Project, newStatus: ProjectStatus): {
    allowed: boolean
    reason?: string
    rule?: StatusTransitionRule
  } {
    // 如果状态相同，允许转换
    if (project.status === newStatus) {
      return { allowed: true }
    }

    // 查找对应的转换规则
    const rule = this.statusTransitions.find(
      transition => transition.from === project.status && transition.to === newStatus
    )

    if (!rule) {
      return {
        allowed: false,
        reason: `不支持从 ${this.getStatusText(project.status)} 转换到 ${this.getStatusText(newStatus)}`
      }
    }

    // 执行验证器
    if (rule.validator && !rule.validator(project)) {
      return {
        allowed: false,
        reason: rule.description
      }
    }

    return { allowed: true, rule }
  }

  /**
   * 转换项目状态
   */
  async changeProjectStatus(project: Project, newStatus: ProjectStatus): Promise<{
    success: boolean
    reason?: string
    updatedProject?: Project
  }> {
    try {
      hilog.info(0x0000, TAG, `尝试转换项目状态: ${project.id} ${project.status} -> ${newStatus}`)

      // 检查转换是否允许
      const transition = this.canTransitionStatus(project, newStatus)
      if (!transition.allowed) {
        return {
          success: false,
          reason: transition.reason || '状态转换不被允许'
        }
      }

      // 更新项目状态
      const updatedProject = project.clone()
      updatedProject.setStatus(newStatus)

      // 保存到数据库
      const success = await projectService.updateProject(updatedProject)

      if (success) {
        hilog.info(0x0000, TAG, `项目状态转换成功: ${project.id} -> ${newStatus}`)
        return {
          success: true,
          updatedProject
        }
      } else {
        return {
          success: false,
          reason: '保存项目状态失败'
        }
      }

    } catch (error) {
      hilog.error(0x0000, TAG, `项目状态转换失败: ${JSON.stringify(error)}`)
      return {
        success: false,
        reason: error instanceof Error ? error.message : '未知错误'
      }
    }
  }

  /**
   * 获取项目的可能状态转换
   */
  getAvailableStatusTransitions(project: Project): StatusTransitionRule[] {
    return this.statusTransitions.filter(
      transition => transition.from === project.status
    )
  }

  /**
   * 自动检查和更新项目状态
   */
  async autoUpdateProjectStatus(project: Project): Promise<ProjectStatus> {
    try {
      hilog.debug(0x0000, TAG, `自动检查项目状态: ${project.id}`)

      let newStatus = project.status

      // 根据项目日期自动设置状态
      const now = new Date()

      if (project.status === ProjectStatus.ACTIVE) {
        // 检查项目是否过期
        if (project.endDate < now) {
          newStatus = ProjectStatus.COMPLETED
          hilog.info(0x0000, TAG, `项目已过期，自动标记为完成: ${project.id}`)
        }
      }

      // 检查项目是否应该激活
      if (project.status === ProjectStatus.PAUSED) {
        if (project.startDate <= now && project.endDate >= now) {
          const transition = this.canTransitionStatus(project, ProjectStatus.ACTIVE)
          if (transition.allowed) {
            newStatus = ProjectStatus.ACTIVE
            hilog.info(0x0000, TAG, `项目已到开始时间，自动激活: ${project.id}`)
          }
        }
      }

      // 如果状态需要更新
      if (newStatus !== project.status) {
        const result = await this.changeProjectStatus(project, newStatus)
        if (result.success) {
          return newStatus
        }
      }

      return project.status

    } catch (error) {
      hilog.error(0x0000, TAG, `自动更新项目状态失败: ${JSON.stringify(error)}`)
      return project.status
    }
  }

  /**
   * 批量自动更新项目状态
   */
  async batchUpdateProjectStatuses(projectIds?: string[]): Promise<{
    updated: number
    failed: number
    errors: string[]
  }> {
    try {
      hilog.info(0x0000, TAG, `批量自动更新项目状态: ${projectIds?.length || '全部'}`)

      const projects = projectIds
        ? await Promise.all(projectIds.map(id => projectService.getProjectById(id)))
        : await projectService.queryProjects()

      const validProjects = projects.filter(p => p !== null) as Project[]

      let updated = 0
      let failed = 0
      const errors: string[] = []

      for (const project of validProjects) {
        try {
          const newStatus = await this.autoUpdateProjectStatus(project)
          if (newStatus !== project.status) {
            updated++
          }
        } catch (error) {
          failed++
          errors.push(`项目 ${project.name}: ${error instanceof Error ? error.message : '未知错误'}`)
        }
      }

      hilog.info(0x0000, TAG, `批量更新完成: 更新${updated}个，失败${failed}个`)
      return { updated, failed, errors }

    } catch (error) {
      hilog.error(0x0000, TAG, `批量更新项目状态失败: ${JSON.stringify(error)}`)
      return { updated: 0, failed: 0, errors: ['批量更新失败'] }
    }
  }

  /**
   * 获取项目健康状态
   */
  getProjectHealthStatus(project: Project): {
    status: 'healthy' | 'warning' | 'error'
    issues: string[]
    recommendations: string[]
  } {
    const issues: string[] = []
    const recommendations: string[] = []

    // 检查基本信息
    if (!project.name || project.name.trim().length === 0) {
      issues.push('项目名称为空')
      recommendations.push('设置项目名称')
    }

    if (!project.client || project.client.trim().length === 0) {
      issues.push('客户信息为空')
      recommendations.push('设置客户信息')
    }

    // 检查日期设置
    const now = new Date()
    if (project.startDate > project.endDate) {
      issues.push('开始日期晚于结束日期')
      recommendations.push('修正项目日期设置')
    }

    if (project.status === ProjectStatus.ACTIVE && project.endDate < now) {
      issues.push('项目已过期但仍在进行状态')
      recommendations.push('将项目标记为完成或延长项目时间')
    }

    // 检查数据完整性
    if (project.siteCount === 0) {
      issues.push('项目没有工点')
      recommendations.push('添加项目工点')
    }

    if (project.photoCount === 0) {
      issues.push('项目没有照片')
      recommendations.push('添加项目照片')
    }

    if (project.tags.length === 0) {
      recommendations.push('添加项目标签以便分类管理')
    }

    // 检查项目进度
    const progress = project.getProgressPercentage()
    if (progress > 80 && project.photoCount === 0) {
      issues.push('项目进度较高但没有照片记录')
      recommendations.push('及时添加项目照片记录')
    }

    // 确定健康状态
    let status: 'healthy' | 'warning' | 'error' = 'healthy'
    if (issues.length > 0) {
      status = issues.length > 3 ? 'error' : 'warning'
    }

    return { status, issues, recommendations }
  }

  /**
   * 获取状态文本
   */
  private getStatusText(status: ProjectStatus): string {
    switch (status) {
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
   * 检查项目是否可以被删除
   */
  canDeleteProject(project: Project): {
    allowed: boolean
    reason?: string
    warnings: string[]
  } {
    const warnings: string[] = []

    // 检查项目状态
    if (project.status === ProjectStatus.ACTIVE) {
      return {
        allowed: false,
        reason: '不能删除进行中的项目',
        warnings
      }
    }

    // 检查数据量
    if (project.siteCount > 0) {
      warnings.push(`项目包含 ${project.siteCount} 个工点，删除后将一并删除`)
    }

    if (project.photoCount > 0) {
      warnings.push(`项目包含 ${project.photoCount} 张照片，删除后将一并删除`)
    }

    return {
      allowed: true,
      warnings
    }
  }

  /**
   * 删除项目前的清理工作
   */
  async cleanupProjectBeforeDeletion(project: Project): Promise<{
    success: boolean
    errors: string[]
  }> {
    const errors: string[] = []

    try {
      hilog.info(0x0000, TAG, `开始清理项目数据: ${project.id}`)

      // 删除所有相关工点
      const sites = await siteService.getSitesByProjectId(project.id)
      if (sites.length > 0) {
        const siteIds = sites.map(site => site.id)
        await siteService.deleteSites(siteIds)
        hilog.info(0x0000, TAG, `删除了 ${siteIds.length} 个工点`)
      }

      hilog.info(0x0000, TAG, `项目数据清理完成: ${project.id}`)
      return { success: true, errors }

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : '未知错误'
      errors.push(errorMsg)
      hilog.error(0x0000, TAG, `项目数据清理失败: ${errorMsg}`)
      return { success: false, errors }
    }
  }
}

/**
 * 导出单例实例
 */
export const projectStateManager = ProjectStateManager.getInstance()