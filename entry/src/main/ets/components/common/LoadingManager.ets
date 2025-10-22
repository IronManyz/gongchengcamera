/**
 * 加载管理器
 * 统一管理应用中的所有加载状态和动画效果
 */

import { PageLoading, LoadingManager, LoadingType, LoadingSize, LoadingPosition } from './PageLoading'
import { SkeletonLoading, SkeletonType, SkeletonAnimation } from './SkeletonLoading'

export type LoadingContext =
  | 'page-transition'    // 页面切换
  | 'data-loading'       // 数据加载
  | 'form-submit'       // 表单提交
  | 'image-upload'      // 图片上传
  | 'file-processing'    // 文件处理
  | 'sync-data'        // 数据同步
  | 'camera-init'       // 相机初始化
  | 'location-gps'      // GPS定位
  | 'weather-fetch'     // 天气获取

export interface LoadingConfig {
  type?: LoadingType
  skeletonType?: SkeletonType
  skeletonAnimation?: SkeletonAnimation
  message?: string
  timeout?: number
  showProgress?: boolean
  size?: LoadingSize
  position?: LoadingPosition
  color?: string
  backgroundColor?: string
  onCancel?: () => void
  onTimeout?: () => void
}

export interface LoadingState {
  id: string
  context: LoadingContext
  isLoading: boolean
  config?: LoadingConfig
  startTime?: number
  timeoutId?: number
}

/**
 * 全局加载管理器
 * 提供统一的加载状态管理和动画控制
 */
@ComponentV2
export struct GlobalLoadingManager {
  @State private loadingStates: Map<string, LoadingState> = new Map()

  /**
   * 开始加载
   */
  startLoading(id: string, context: LoadingContext, config?: LoadingConfig): void {
    const loadingState: LoadingState = {
      id,
      context,
      isLoading: true,
      config,
      startTime: Date.now()
    }

    this.loadingStates.set(id, loadingState)

    // 设置超时处理
    if (config?.timeout && config.timeout > 0) {
      const timeoutId = setTimeout(() => {
        this.stopLoading(id)
        config?.onTimeout?.()
      }, config.timeout)

      this.loadingStates.set(id, {
        ...loadingState,
        timeoutId: timeoutId
      })
    }
  }

  /**
   * 停止加载
   */
  stopLoading(id: string): void {
    const state = this.loadingStates.get(id)
    if (state) {
      // 清除超时定时器
      if (state.timeoutId) {
        clearTimeout(state.timeoutId)
      }

      // 更新状态
      this.loadingStates.set(id, {
        ...state,
        isLoading: false,
        timeoutId: undefined
      })

      // 延迟移除状态（用于动画展示）
      setTimeout(() => {
        this.loadingStates.delete(id)
      }, 300)
    }
  }

  /**
   * 检查是否正在加载
   */
  isLoading(id?: string): boolean {
    if (id) {
      const state = this.loadingStates.get(id)
      return state?.isLoading || false
    } else {
      return Array.from(this.loadingStates.values()).some(state => state.isLoading)
    }
  }

  /**
   * 获取指定上下文的加载状态
   */
  getContextLoading(context: LoadingContext): LoadingState[] {
    return Array.from(this.loadingStates.values())
      .filter(state => state.context === context)
  }

  /**
   * 清除所有加载状态
   */
  clearAllLoading(): void {
    // 清除所有超时定时器
    for (const [id, state] of this.loadingStates.entries()) {
      if (state.timeoutId) {
        clearTimeout(state.timeoutId)
      }
    }

    this.loadingStates.clear()
  }

  /**
   * 获取所有加载状态
   */
  getAllLoadingStates(): LoadingState[] {
    return Array.from(this.loadingStates.values())
  }

  /**
   * 获取加载统计信息
   */
  getLoadingStats(): {
    total: number
    active: number
    byContext: Record<LoadingContext, number>
  } {
    const allStates = Array.from(this.loadingStates.values())
    const activeStates = allStates.filter(state => state.isLoading)

    const stats = {
      total: allStates.length,
      active: activeStates.length,
      byContext: {} as Record<LoadingContext, number>
    }

    // 按上下文统计
    for (const state of activeStates) {
      stats.byContext[state.context] = (stats.byContext[state.context] || 0) + 1
    }

    return stats
  }

  /**
   * 获取推荐加载配置
   */
  getRecommendedConfig(context: LoadingContext): LoadingConfig {
    const configs: Record<LoadingContext, LoadingConfig> = {
      'page-transition': {
        type: 'fade',
        duration: 500,
        message: '页面切换中...'
      },
      'data-loading': {
        type: 'spinner',
        size: 'medium',
        message: '数据加载中...'
      },
      'form-submit': {
        type: 'dots',
        size: 'small',
        message: '提交中...',
        timeout: 30000
      },
      'image-upload': {
        type: 'progress',
        showProgress: true,
        message: '上传中...',
        color: '#52C41A'
      },
      'file-processing': {
        type: 'wave',
        size: 'large',
        message: '处理中...',
        timeout: 60000
      },
      'sync-data': {
        type: 'pulse',
        size: 'medium',
        message: '同步中...',
        timeout: 120000
      },
      'camera-init': {
        type: 'bounce',
        size: 'large',
        message: '相机初始化中...'
      },
      'location-gps': {
        type: 'dots',
        size: 'small',
        message: '获取位置中...',
        timeout: 15000
      },
      'weather-fetch': {
        type: 'wave',
        size: 'small',
        message: '获取天气中...',
        timeout: 10000
      }
    }

    return configs[context] || {}
  }

  build() {
    Stack() {
      // 渲染所有加载状态
      ForEach(Array.from(this.loadingStates.values()), (state: LoadingState) => {
        if (state.isLoading) {
          this.buildLoadingComponent(state)
        }
      }, (state: LoadingState) => state.id)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(9999)
  }

  /**
   * 构建加载组件
   */
  @Builder
  private buildLoadingComponent(state: LoadingState) {
    const config = state.config || this.getRecommendedConfig(state.context)

    switch (state.context) {
      case 'page-transition':
        this.buildPageTransition(config)
        break
      case 'data-loading':
        if (config.skeletonType) {
          this.buildSkeletonLoading(config)
        } else {
          this.buildStandardLoading(config)
        }
        break
      default:
        this.buildStandardLoading(config)
        break
    }
  }

  /**
   * 构建页面过渡效果
   */
  @Builder
  private buildPageTransition(config: LoadingConfig) {
    // 这里可以集成自定义的页面过渡组件
    // 目前使用简单的淡入淡出效果
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(config.backgroundColor || 'rgba(0, 0, 0, 0.3)')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })

    if (config.message) {
      Text(config.message)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .margin({ top: 20 })
    }
  }

  /**
   * 构建骨架屏加载
   */
  @Builder
  private buildSkeletonLoading(config: LoadingConfig) {
    SkeletonLoading({
      isLoading: true,
      type: config.skeletonType || 'text',
      animation: config.skeletonAnimation || 'wave',
      rows: 3,
      theme: 'light'
    })
      .width('100%')
      .height('100%')
  }

  /**
   * 构建标准加载
   */
  @Builder
  private buildStandardLoading(config: LoadingConfig) {
    PageLoading({
      isLoading: true,
      type: config.type || 'spinner',
      message: config.message || '加载中...',
      size: config.size || 'medium',
      color: config.color,
      bgColor: config.backgroundColor,
      showProgress: config.showProgress,
      progress: 0,
      duration: config.timeout,
      onCancel: config.onCancel
    })
      .width('100%')
      .height('100%')
  }
}

/**
 * 加载上下文提供者
 * 用于在组件树中提供加载上下文
 */
export const LoadingContextProvider = Symbol('LoadingContextProvider')

/**
 * 使用加载上下文的Hook
 */
export function useLoadingManager() {
  return {
    startLoading: (id: string, context: LoadingContext, config?: LoadingConfig) => {
      // 这里应该通过全局状态管理来调用
      console.info(`Start loading: ${id} in context: ${context}`)
    },
    stopLoading: (id: string) => {
      console.info(`Stop loading: ${id}`)
    },
    isLoading: (id?: string) => {
      console.info(`Check loading: ${id}`)
      return false
    }
  }
}