import { Logger } from '../utils/Logger'
import { UIOptimizer } from './UIOptimizer'
import { PerformanceOptimizer } from './PerformanceOptimizer'
import { StabilityOptimizer } from './StabilityOptimizer'

interface OptimizationResult {
  category: string
  taskName: string
  success: boolean
  duration: number
  details?: Record<string, any>
}

/**
 * 优化管理器
 * 负责统筹所有优化任务
 */
export class OptimizationManager {
  private static readonly TAG = 'OptimizationManager'

  /**
   * 运行所有优化任务
   */
  static async runAllOptimizations(): Promise<OptimizationResult[]> {
    const results: OptimizationResult[] = []

    try {
      Logger.info(OptimizationManager.TAG, '开始执行全面优化')

      // UI优化
      const uiStartTime = Date.now()
      const uiResults = UIOptimizer.runAllUIOptimizations()
      uiResults.forEach(result => {
        results.push({
          category: 'UI优化',
          taskName: result.taskName,
          success: result.success,
          duration: Date.now() - uiStartTime
        })
      })

      // 性能优化
      const perfStartTime = Date.now()
      const perfResults = PerformanceOptimizer.runAllPerformanceOptimizations()
      perfResults.forEach(result => {
        results.push({
          category: '性能优化',
          taskName: result.taskName,
          success: result.success,
          duration: Date.now() - perfStartTime
        })
      })

      // 稳定性优化
      const stabilityStartTime = Date.now()
      const stabilityResults = StabilityOptimizer.runAllStabilityOptimizations()
      stabilityResults.forEach(result => {
        results.push({
          category: '稳定性优化',
          taskName: result.taskName,
          success: result.success,
          duration: Date.now() - stabilityStartTime
        })
      })

      // 系统诊断
      const diagnosticStartTime = Date.now()
      const diagnostics = StabilityOptimizer.performSystemDiagnostics()
      results.push({
        category: '系统诊断',
        taskName: '系统健康检查',
        success: diagnostics.failed === 0,
        duration: Date.now() - diagnosticStartTime,
        details: {
          passed: diagnostics.passed,
          failed: diagnostics.failed,
          total: diagnostics.total
        }
      })

      // 内存状态检查
      const memoryStartTime = Date.now()
      const memoryUsage = PerformanceOptimizer.getMemoryUsage()
      results.push({
        category: '性能监控',
        taskName: '内存使用检查',
        success: memoryUsage.percentage < 80,
        duration: Date.now() - memoryStartTime,
        details: {
          used: memoryUsage.used,
          total: memoryUsage.total,
          percentage: memoryUsage.percentage
        }
      })

      // 系统健康状态检查
      const healthStartTime = Date.now()
      const healthStatus = StabilityOptimizer.getSystemHealthStatus()
      results.push({
        category: '稳定性监控',
        taskName: '系统健康状态',
        success: healthStatus.overall !== 'critical',
        duration: Date.now() - healthStartTime,
        details: healthStatus
      })

      Logger.info(OptimizationManager.TAG, `全面优化完成: ${results.length} 个任务`)
      return results

    } catch (error) {
      Logger.error(OptimizationManager.TAG, `全面优化失败: ${error}`)
      return []
    }
  }

  /**
   * 获取优化建议
   */
  static getOptimizationSuggestions(): {
    category: string
    priority: 'high' | 'medium' | 'low'
    suggestion: string
    action: string
  }[] {
    const suggestions: {
      category: string
      priority: 'high' | 'medium' | 'low'
      suggestion: string
      action: string
    }[] = []

    try {
      // 检查内存使用情况
      const memoryUsage = PerformanceOptimizer.getMemoryUsage()
      if (memoryUsage.percentage > 80) {
        suggestions.push({
          category: '内存优化',
          priority: 'high',
          suggestion: '内存使用率过高',
          action: '清理缓存并压缩内存'
        })
      } else if (memoryUsage.percentage > 60) {
        suggestions.push({
          category: '内存优化',
          priority: 'medium',
          suggestion: '内存使用率偏高',
          action: '考虑清理不必要的缓存'
        })
      }

      // 检查系统健康状态
      const healthStatus = StabilityOptimizer.getSystemHealthStatus()
      if (healthStatus.overall === 'critical') {
        suggestions.push({
          category: '系统稳定性',
          priority: 'high',
          suggestion: '系统状态严重',
          action: '立即执行系统诊断和修复'
        })
      } else if (healthStatus.overall === 'warning') {
        suggestions.push({
          category: '系统稳定性',
          priority: 'medium',
          suggestion: '系统状态警告',
          action: '检查系统性能指标'
        })
      }

      // 检查各个组件状态
      if (healthStatus.memory === 'critical') {
        suggestions.push({
          category: '内存管理',
          priority: 'high',
          suggestion: '内存状态严重',
          action: '启用内存泄漏防护'
        })
      }

      if (healthStatus.performance === 'critical') {
        suggestions.push({
          category: '性能优化',
          priority: 'high',
          suggestion: '性能状态严重',
          action: '优化图片加载和列表滚动'
        })
      }

      if (healthStatus.stability === 'critical') {
        suggestions.push({
          category: '稳定性优化',
          priority: 'high',
          suggestion: '稳定性状态严重',
          action: '完善异常处理机制'
        })
      }

      // 通用建议
      if (suggestions.length === 0) {
        suggestions.push({
          category: '预防性维护',
          priority: 'low',
          suggestion: '系统运行良好',
          action: '定期执行系统优化'
        })
      }

      return suggestions

    } catch (error) {
      Logger.error(OptimizationManager.TAG, `获取优化建议失败: ${error}`)
      return [{
        category: '错误处理',
        priority: 'high',
        suggestion: '无法获取系统状态',
        action: '重启应用并检查日志'
      }]
    }
  }

  /**
   * 执行一键优化
   */
  static async performQuickOptimization(): Promise<{
    success: boolean
    tasksCompleted: number
    tasksTotal: number
    duration: number
    improvements: string[]
  }> {
    const startTime = Date.now()
    const improvements: string[] = []

    try {
      Logger.info(OptimizationManager.TAG, '开始一键优化')

      let tasksCompleted = 0
      const tasksTotal = 4

      // 清理缓存
      if (PerformanceOptimizer.clearCache()) {
        improvements.push('缓存清理完成')
        tasksCompleted++
      }

      // 压缩内存
      if (PerformanceOptimizer.compressMemory()) {
        improvements.push('内存压缩完成')
        tasksCompleted++
      }

      // 优化图片加载
      if (PerformanceOptimizer.optimizeImageLoadingPerformance()) {
        improvements.push('图片加载优化完成')
        tasksCompleted++
      }

      // 优化列表滚动
      if (PerformanceOptimizer.optimizeListScrollingPerformance()) {
        improvements.push('列表滚动优化完成')
        tasksCompleted++
      }

      const duration = Date.now() - startTime
      const success = tasksCompleted >= tasksTotal * 0.5 // 至少完成50%的任务

      Logger.info(OptimizationManager.TAG, `一键优化完成: ${tasksCompleted}/${tasksTotal} 任务`)
      return { success, tasksCompleted, tasksTotal, duration, improvements }
    } catch (error) {
      Logger.error(OptimizationManager.TAG, `一键优化失败: ${error}`)
      return { success: false, tasksCompleted: 0, tasksTotal, duration: Date.now() - startTime, improvements: [] }
    }
  }

  /**
   * 获取系统性能报告
   */
  static getPerformanceReport(): {
    timestamp: Date
    memory: { used: number; total: number; percentage: number }
    health: { overall: string; memory: string; performance: string; stability: string }
    diagnostics: { passed: number; failed: number; total: number }
    recommendations: string[]
  } {
    try {
      const memoryUsage = PerformanceOptimizer.getMemoryUsage()
      const healthStatus = StabilityOptimizer.getSystemHealthStatus()
      const diagnostics = StabilityOptimizer.performSystemDiagnostics()
      const suggestions = this.getOptimizationSuggestions()

      const recommendations = suggestions
        .filter(s => s.priority === 'high' || s.priority === 'medium')
        .map(s => s.suggestion)

      return {
        timestamp: new Date(),
        memory: memoryUsage,
        health: healthStatus,
        diagnostics: {
          passed: diagnostics.passed,
          failed: diagnostics.failed,
          total: diagnostics.total
        },
        recommendations
      }
    } catch (error) {
      Logger.error(OptimizationManager.TAG, `获取性能报告失败: ${error}`)
      return {
        timestamp: new Date(),
        memory: { used: 0, total: 0, percentage: 0 },
        health: { overall: 'critical', memory: 'critical', performance: 'critical', stability: 'critical' },
        diagnostics: { passed: 0, failed: 1, total: 1 },
        recommendations: ['无法获取系统状态，请重启应用']
      }
    }
  }
}