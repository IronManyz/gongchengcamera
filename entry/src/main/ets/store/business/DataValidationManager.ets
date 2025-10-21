/**
 * DataValidationManager.ets
 * 数据验证管理器
 * 负责业务数据的完整性验证、规则检查和数据质量保证
 */

import { Project } from '../../models/Project'
import { Site } from '../../models/Site'
import { Photo } from '../../models/Photo'
import { ProjectStatus } from '../../types/AppTypes'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'DataValidationManager'

/**
 * 验证结果接口
 */
export interface ValidationResult {
  valid: boolean
  errors: ValidationError[]
  warnings: ValidationWarning[]
  score: number // 数据质量评分 0-100
}

/**
 * 验证错误接��
 */
export interface ValidationError {
  code: string
  message: string
  field?: string
  severity: 'error' | 'critical'
  fixable: boolean
  fixSuggestion?: string
}

/**
 * 验证警告接口
 */
export interface ValidationWarning {
  code: string
  message: string
  field?: string
  suggestion?: string
}

/**
 * 验证规则配置
 */
export interface ValidationRule {
  code: string
  name: string
  description: string
  validator: (data: any) => ValidationError | null
  enabled: boolean
  priority: number
}

/**
 * 批量验证结果
 */
export interface BatchValidationResult {
  total: number
  valid: number
  invalid: number
  warnings: number
  errors: ValidationError[]
  warnings: ValidationWarning[]
  averageScore: number
  details: Array<{
    id: string
    type: 'project' | 'site' | 'photo'
    result: ValidationResult
  }>
}

/**
 * 数据验证管理器
 */
export class DataValidationManager {
  private static instance: DataValidationManager | null = null

  // 项目验证规则
  private readonly projectValidationRules: ValidationRule[] = [
    {
      code: 'PROJECT_001',
      name: '项目基本信息完整性',
      description: '检查项目基本信息是否完整',
      validator: (project: Project) => {
        if (!project.name || project.name.trim().length === 0) {
          return {
            code: 'PROJECT_001',
            message: '项目名称不能为空',
            field: 'name',
            severity: 'critical',
            fixable: true,
            fixSuggestion: '请设置项目名称'
          }
        }
        return null
      },
      enabled: true,
      priority: 10
    },
    {
      code: 'PROJECT_002',
      name: '项目日期合理性',
      description: '检查项目开始和结束日期的合理性',
      validator: (project: Project) => {
        if (project.startDate > project.endDate) {
          return {
            code: 'PROJECT_002',
            message: '项目开始日期不能晚于结束日期',
            field: 'startDate',
            severity: 'error',
            fixable: true,
            fixSuggestion: '请修正项目日期设置'
          }
        }
        return null
      },
      enabled: true,
      priority: 9
    },
    {
      code: 'PROJECT_003',
      name: '项目状态一致性',
      description: '检查项目状态与日期的一致性',
      validator: (project: Project) => {
        const now = new Date()
        if (project.status === ProjectStatus.ACTIVE && project.endDate < now) {
          return {
            code: 'PROJECT_003',
            message: '项目已过期但状态仍为进行中',
            field: 'status',
            severity: 'warning',
            fixable: true,
            fixSuggestion: '建议将项目状态更新为已完成'
          }
        }
        return null
      },
      enabled: true,
      priority: 7
    },
    {
      code: 'PROJECT_004',
      name: '项目数据完整性',
      description: '检查项目是否有关联的工点和照片',
      validator: (project: Project) => {
        if (project.siteCount === 0) {
          return {
            code: 'PROJECT_004',
            message: '项目没有关联的工点',
            field: 'sites',
            severity: 'warning',
            fixable: true,
            fixSuggestion: '请为项目添加工点'
          }
        }
        return null
      },
      enabled: true,
      priority: 6
    },
    {
      code: 'PROJECT_005',
      name: '项目编号唯一性',
      description: '检查项目编号是否唯一',
      validator: (project: Project) => {
        if (!project.code || project.code.trim().length === 0) {
          return {
            code: 'PROJECT_005',
            message: '项目编号不能为空',
            field: 'code',
            severity: 'error',
            fixable: true,
            fixSuggestion: '请设置项目编号'
          }
        }
        return null // 在实际应用中需要检查数据库中的唯一性
      },
      enabled: true,
      priority: 8
    }
  ]

  // 工点验证规则
  private readonly siteValidationRules: ValidationRule[] = [
    {
      code: 'SITE_001',
      name: '工点基本信息完整性',
      description: '检查工点基本信息是否完整',
      validator: (site: Site) => {
        if (!site.name || site.name.trim().length === 0) {
          return {
            code: 'SITE_001',
            message: '工点名称不能为空',
            field: 'name',
            severity: 'critical',
            fixable: true,
            fixSuggestion: '请设置工点名称'
          }
        }
        return null
      },
      enabled: true,
      priority: 10
    },
    {
      code: 'SITE_002',
      name: '工点项目关联',
      description: '检查工点是否关联到有效项目',
      validator: (site: Site) => {
        if (!site.projectId || site.projectId.trim().length === 0) {
          return {
            code: 'SITE_002',
            message: '工点必须关联到项目',
            field: 'projectId',
            severity: 'critical',
            fixable: true,
            fixSuggestion: '请为工点选择关联项目'
          }
        }
        return null
      },
      enabled: true,
      priority: 10
    },
    {
      code: 'SITE_003',
      name: '工点位置信息',
      description: '检查工点位置信息的有效性',
      validator: (site: Site) => {
        if (!site.hasValidLocation() && !site.address) {
          return {
            code: 'SITE_003',
            message: '工点没有位置信息或地址',
            field: 'location',
            severity: 'warning',
            fixable: true,
            fixSuggestion: '请添加工点位置信息或详细地址'
          }
        }
        return null
      },
      enabled: true,
      priority: 5
    },
    {
      code: 'SITE_004',
      name: '工点坐标有效性',
      description: '检查工点坐标是否在有效范围内',
      validator: (site: Site) => {
        if (site.hasValidLocation()) {
          if (Math.abs(site.latitude) > 90 || Math.abs(site.longitude) > 180) {
            return {
              code: 'SITE_004',
              message: '工点坐标超出有效范围',
              field: 'coordinates',
              severity: 'error',
              fixable: true,
              fixSuggestion: '请检查并修正工点坐标'
            }
          }
        }
        return null
      },
      enabled: true,
      priority: 8
    }
  ]

  // 照片验证规则
  private readonly photoValidationRules: ValidationRule[] = [
    {
      code: 'PHOTO_001',
      name: '照片基本信息完整性',
      description: '检查照片基本信息是否完整',
      validator: (photo: Photo) => {
        if (!photo.filePath || photo.filePath.trim().length === 0) {
          return {
            code: 'PHOTO_001',
            message: '照片文件路径不能为空',
            field: 'filePath',
            severity: 'critical',
            fixable: false,
            fixSuggestion: '照片文件可能已丢失'
          }
        }
        return null
      },
      enabled: true,
      priority: 10
    },
    {
      code: 'PHOTO_002',
      name: '照片关联信息',
      description: '检查照片是否关联到项目和工点',
      validator: (photo: Photo) => {
        if (!photo.projectId || photo.projectId.trim().length === 0) {
          return {
            code: 'PHOTO_002',
            message: '照片必须关联到项目',
            field: 'projectId',
            severity: 'error',
            fixable: true,
            fixSuggestion: '请为照片选择关联项目'
          }
        }
        return null
      },
      enabled: true,
      priority: 9
    },
    {
      code: 'PHOTO_003',
      name: '照片时间戳合理性',
      description: '检查照片拍摄时间是否合理',
      validator: (photo: Photo) => {
        const now = new Date()
        if (photo.takenAt > now) {
          return {
            code: 'PHOTO_003',
            message: '照片拍摄时间晚于当前时间',
            field: 'takenAt',
            severity: 'warning',
            fixable: true,
            fixSuggestion: '请检查照片拍摄时间设置'
          }
        }
        return null
      },
      enabled: true,
      priority: 6
    }
  ]

  /**
   * 获取单例实例
   */
  static getInstance(): DataValidationManager {
    if (!DataValidationManager.instance) {
      DataValidationManager.instance = new DataValidationManager()
    }
    return DataValidationManager.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 验证项目数据
   */
  validateProject(project: Project): ValidationResult {
    const errors: ValidationError[] = []
    const warnings: ValidationWarning[] = []
    let totalScore = 100

    // 执行启用的验证规则
    const enabledRules = this.projectValidationRules.filter(rule => rule.enabled)
      .sort((a, b) => b.priority - a.priority)

    for (const rule of enabledRules) {
      try {
        const error = rule.validator(project)
        if (error) {
          if (error.severity === 'critical') {
            errors.push(error)
            totalScore -= 20
          } else if (error.severity === 'error') {
            errors.push(error)
            totalScore -= 10
          }
        }
      } catch (e) {
        hilog.error(0x0000, TAG, `验证规则执行失败: ${rule.code}, 错误: ${JSON.stringify(e)}`)
      }
    }

    // 添加额外检查
    const additionalWarnings = this.getAdditionalProjectWarnings(project)
    warnings.push(...additionalWarnings)

    // 确保分数在有效范围内
    totalScore = Math.max(0, Math.min(100, totalScore))

    return {
      valid: errors.length === 0,
      errors,
      warnings,
      score: totalScore
    }
  }

  /**
   * 验证工点数据
   */
  validateSite(site: Site): ValidationResult {
    const errors: ValidationError[] = []
    const warnings: ValidationWarning[] = []
    let totalScore = 100

    // 执行启用的验证规则
    const enabledRules = this.siteValidationRules.filter(rule => rule.enabled)
      .sort((a, b) => b.priority - a.priority)

    for (const rule of enabledRules) {
      try {
        const error = rule.validator(site)
        if (error) {
          if (error.severity === 'critical') {
            errors.push(error)
            totalScore -= 20
          } else if (error.severity === 'error') {
            errors.push(error)
            totalScore -= 10
          }
        }
      } catch (e) {
        hilog.error(0x0000, TAG, `验证规则执行失败: ${rule.code}, 错误: ${JSON.stringify(e)}`)
      }
    }

    // 添加额外检查
    const additionalWarnings = this.getAdditionalSiteWarnings(site)
    warnings.push(...additionalWarnings)

    // 确保分数在有效范围内
    totalScore = Math.max(0, Math.min(100, totalScore))

    return {
      valid: errors.length === 0,
      errors,
      warnings,
      score: totalScore
    }
  }

  /**
   * 验证照片数据
   */
  validatePhoto(photo: Photo): ValidationResult {
    const errors: ValidationError[] = []
    const warnings: ValidationWarning[] = []
    let totalScore = 100

    // 执行启用的验证规则
    const enabledRules = this.photoValidationRules.filter(rule => rule.enabled)
      .sort((a, b) => b.priority - a.priority)

    for (const rule of enabledRules) {
      try {
        const error = rule.validator(photo)
        if (error) {
          if (error.severity === 'critical') {
            errors.push(error)
            totalScore -= 20
          } else if (error.severity === 'error') {
            errors.push(error)
            totalScore -= 10
          }
        }
      } catch (e) {
        hilog.error(0x0000, TAG, `验证规则执行失败: ${rule.code}, 错误: ${JSON.stringify(e)}`)
      }
    }

    // 添加额外检查
    const additionalWarnings = this.getAdditionalPhotoWarnings(photo)
    warnings.push(...additionalWarnings)

    // 确保分数在有效范围内
    totalScore = Math.max(0, Math.min(100, totalScore))

    return {
      valid: errors.length === 0,
      errors,
      warnings,
      score: totalScore
    }
  }

  /**
   * 批量验证数据
   */
  async batchValidateData(
    projects: Project[] = [],
    sites: Site[] = [],
    photos: Photo[] = []
  ): Promise<BatchValidationResult> {
    const details: BatchValidationResult['details'] = []
    let totalErrors: ValidationError[] = []
    let totalWarnings: ValidationWarning[] = []
    let totalScore = 0
    let validCount = 0
    let invalidCount = 0

    // 验证项目
    for (const project of projects) {
      const result = this.validateProject(project)
      details.push({
        id: project.id,
        type: 'project',
        result
      })

      totalErrors.push(...result.errors)
      totalWarnings.push(...result.warnings)
      totalScore += result.score

      if (result.valid) {
        validCount++
      } else {
        invalidCount++
      }
    }

    // 验证工点
    for (const site of sites) {
      const result = this.validateSite(site)
      details.push({
        id: site.id,
        type: 'site',
        result
      })

      totalErrors.push(...result.errors)
      totalWarnings.push(...result.warnings)
      totalScore += result.score

      if (result.valid) {
        validCount++
      } else {
        invalidCount++
      }
    }

    // 验证照片
    for (const photo of photos) {
      const result = this.validatePhoto(photo)
      details.push({
        id: photo.id,
        type: 'photo',
        result
      })

      totalErrors.push(...result.errors)
      totalWarnings.push(...result.warnings)
      totalScore += result.score

      if (result.valid) {
        validCount++
      } else {
        invalidCount++
      }
    }

    const totalCount = projects.length + sites.length + photos.length
    const averageScore = totalCount > 0 ? Math.round(totalScore / totalCount) : 0

    return {
      total: totalCount,
      valid: validCount,
      invalid: invalidCount,
      warnings: totalWarnings.length,
      errors: totalErrors,
      warnings: totalWarnings,
      averageScore,
      details
    }
  }

  /**
   * 修复数据问题
   */
  async fixDataIssues(
    errors: ValidationError[],
    projects: Project[],
    sites: Site[],
    photos: Photo[]
  ): Promise<{
    fixed: number
    failed: number
    errors: string[]
  }> {
    let fixed = 0
    let failed = 0
    const fixErrors: string[] = []

    for (const error of errors) {
      if (!error.fixable) {
        failed++
        continue
      }

      try {
        // 根据错误代码执行相应的修复逻辑
        switch (error.code) {
          case 'PROJECT_001':
            // 修复项目名称为空的问题
            const project = projects.find(p => error.field === 'name')
            if (project) {
              project.name = `未命名项目_${Date.now()}`
              fixed++
            }
            break

          case 'PROJECT_002':
            // 修复项目日期问题
            const dateProject = projects.find(p => error.field === 'startDate')
            if (dateProject && dateProject.startDate > dateProject.endDate) {
              dateProject.endDate = new Date(dateProject.startDate.getTime() + 30 * 24 * 60 * 60 * 1000)
              fixed++
            }
            break

          case 'SITE_001':
            // 修复工点名称为空的问题
            const site = sites.find(s => error.field === 'name')
            if (site) {
              site.name = `未命名工点_${Date.now()}`
              fixed++
            }
            break

          default:
            failed++
            fixErrors.push(`无法修复错误: ${error.code}`)
        }
      } catch (e) {
        failed++
        fixErrors.push(`修复错误失败: ${error.code} - ${e}`)
      }
    }

    hilog.info(0x0000, TAG, `数据修复完成: 修复${fixed}个，失败${failed}个`)
    return { fixed, failed, errors: fixErrors }
  }

  /**
   * 获取数据质量报告
   */
  getDataQualityReport(batchResult: BatchValidationResult): {
    grade: 'A' | 'B' | 'C' | 'D' | 'F'
    summary: string
    recommendations: string[]
  } {
    const { averageScore, valid, invalid, errors, warnings } = batchResult

    // 计算等级
    let grade: 'A' | 'B' | 'C' | 'D' | 'F'
    if (averageScore >= 90) {
      grade = 'A'
    } else if (averageScore >= 80) {
      grade = 'B'
    } else if (averageScore >= 70) {
      grade = 'C'
    } else if (averageScore >= 60) {
      grade = 'D'
    } else {
      grade = 'F'
    }

    // 生成摘要
    const summary = `数据质量评分: ${averageScore}/100 (${grade}级)。
      共${batchResult.total}项数据，其中${valid}项验证通过，${invalid}项存在问题。
      发现${errors.length}个错误和${warnings.length}个警告。`

    // 生成建议
    const recommendations: string[] = []

    if (errors.length > 0) {
      recommendations.push('优先处理关键错误，确保数据完整性')
    }

    if (warnings.length > 5) {
      recommendations.push('存在较多警告，建议优化数据质量')
    }

    if (averageScore < 80) {
      recommendations.push('整体数据质量需要改善，建议进行全面的数据清理')
    }

    const criticalErrors = errors.filter(e => e.severity === 'critical')
    if (criticalErrors.length > 0) {
      recommendations.push(`存在${criticalErrors.length}个关键错误，需要立即处理`)
    }

    return { grade, summary, recommendations }
  }

  /**
   * 获取项目额外警告
   */
  private getAdditionalProjectWarnings(project: Project): ValidationWarning[] {
    const warnings: ValidationWarning[] = []

    // 检查项目标签
    if (project.tags.length === 0) {
      warnings.push({
        code: 'PROJECT_W001',
        message: '项目没有设置标签',
        field: 'tags',
        suggestion: '添加项目标签有助于分类管理'
      })
    }

    // 检查项目描述
    if (!project.description || project.description.trim().length === 0) {
      warnings.push({
        code: 'PROJECT_W002',
        message: '项目缺少描述信息',
        field: 'description',
        suggestion: '添加项目描述有助于理解项目内容'
      })
    }

    return warnings
  }

  /**
   * 获取工点额外警告
   */
  private getAdditionalSiteWarnings(site: Site): ValidationWarning[] {
    const warnings: ValidationWarning[] = []

    // 检查工点标签
    if (site.tags.length === 0) {
      warnings.push({
        code: 'SITE_W001',
        message: '工点没有设置标签',
        field: 'tags',
        suggestion: '添加工点标签有助于分类管理'
      })
    }

    // 检查工点描述
    if (!site.description || site.description.trim().length === 0) {
      warnings.push({
        code: 'SITE_W002',
        message: '工点缺少描述信息',
        field: 'description',
        suggestion: '添加工点描述有助于理解工点内容'
      })
    }

    return warnings
  }

  /**
   * 获取照片额外警告
   */
  private getAdditionalPhotoWarnings(photo: Photo): ValidationWarning[] {
    const warnings: ValidationWarning[] = []

    // 检查照片标签
    if (photo.tags.length === 0) {
      warnings.push({
        code: 'PHOTO_W001',
        message: '照片没有设置标签',
        field: 'tags',
        suggestion: '添加照片标签有助于分类搜索'
      })
    }

    // 检查照片描述
    if (!photo.description || photo.description.trim().length === 0) {
      warnings.push({
        code: 'PHOTO_W002',
        message: '照片缺少描述信息',
        field: 'description',
        suggestion: '添加照片描述有助于理解照片内容'
      })
    }

    return warnings
  }

  /**
   * 获取验证规则列表
   */
  getValidationRules(type: 'project' | 'site' | 'photo'): ValidationRule[] {
    switch (type) {
      case 'project':
        return this.projectValidationRules
      case 'site':
        return this.siteValidationRules
      case 'photo':
        return this.photoValidationRules
      default:
        return []
    }
  }

  /**
   * 启用/禁用验证规则
   */
  toggleValidationRule(type: 'project' | 'site' | 'photo', code: string, enabled: boolean): void {
    let rules: ValidationRule[]
    switch (type) {
      case 'project':
        rules = this.projectValidationRules
        break
      case 'site':
        rules = this.siteValidationRules
        break
      case 'photo':
        rules = this.photoValidationRules
        break
      default:
        return
    }

    const rule = rules.find(r => r.code === code)
    if (rule) {
      rule.enabled = enabled
      hilog.info(0x0000, TAG, `${enabled ? '启用' : '禁用'}验证规则: ${code}`)
    }
  }
}

/**
 * 导出单例实例
 */
export const dataValidationManager = DataValidationManager.getInstance()