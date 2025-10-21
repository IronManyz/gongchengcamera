/**
 * StoreInitializer.ets
 * Store初始化逻辑
 * 负责在应用启动时按正确的顺序初始化所有Store
 */

import { storeManager, globalStore, themeStore, userStore } from './index'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'StoreInitializer'

/**
 * Store初始化配置
 */
interface StoreInitConfig {
  /** Store名称 */
  name: string
  /** 优先级，数字越小越先初始化 */
  priority: number
  /** 是否必需初始化 */
  required: boolean
  /** 初始化超时时间（毫秒） */
  timeout?: number
  /** 依赖的其他Store */
  dependencies?: string[]
}

/**
 * Store初始化器
 * 负责管理Store的初始化顺序和依赖关系
 */
export class StoreInitializer {
  private static instance: StoreInitializer | null = null

  /**
   * 初始化配置列表
   */
  private initConfigs: StoreInitConfig[] = []

  /**
   * 初始化状态
   */
  private isInitialized: boolean = false

  /**
   * 获取单例实例
   */
  static getInstance(): StoreInitializer {
    if (!StoreInitializer.instance) {
      StoreInitializer.instance = new StoreInitializer()
    }
    return StoreInitializer.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.setupDefaultConfigs()
  }

  /**
   * 设置默认的初始化配置
   */
  private setupDefaultConfigs(): void {
    // GlobalStore 优先级最高，无依赖
    this.addStoreConfig({
      name: 'global',
      priority: 1,
      required: true,
      timeout: 5000
    })

    // ThemeStore 依赖 GlobalStore
    this.addStoreConfig({
      name: 'theme',
      priority: 2,
      required: true,
      timeout: 3000,
      dependencies: ['global']
    })

    // UserStore 依赖 GlobalStore
    this.addStoreConfig({
      name: 'user',
      priority: 2,
      required: true,
      timeout: 5000,
      dependencies: ['global']
    })

    hilog.info(0x0000, TAG, 'Default store initialization configs setup completed')
  }

  /**
   * 添加Store初始化配置
   */
  addStoreConfig(config: StoreInitConfig): void {
    if (this.isInitialized) {
      hilog.warn(0x0000, TAG, 'Cannot add config after initialization')
      return
    }

    this.initConfigs.push(config)
    hilog.debug(0x0000, TAG, `Added init config for store: ${config.name}`)
  }

  /**
   * 移除Store初始化配置
   */
  removeStoreConfig(name: string): void {
    if (this.isInitialized) {
      hilog.warn(0x0000, TAG, 'Cannot remove config after initialization')
      return
    }

    const index = this.initConfigs.findIndex(config => config.name === name)
    if (index >= 0) {
      this.initConfigs.splice(index, 1)
      hilog.debug(0x0000, TAG, `Removed init config for store: ${name}`)
    }
  }

  /**
   * 初始化所有Store
   */
  async initializeStores(): Promise<void> {
    if (this.isInitialized) {
      hilog.warn(0x0000, TAG, 'Stores already initialized')
      return
    }

    hilog.info(0x0000, TAG, 'Starting store initialization...')

    try {
      // 验证依赖关系
      this.validateDependencies()

      // 按优先级排序
      const sortedConfigs = this.sortConfigsByPriority()

      // 按顺序初始化
      await this.initializeStoresInOrder(sortedConfigs)

      this.isInitialized = true
      hilog.info(0x0000, TAG, 'All stores initialized successfully')

    } catch (error) {
      hilog.error(0x0000, TAG, `Store initialization failed: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 验证依赖关系
   */
  private validateDependencies(): void {
    hilog.debug(0x0000, TAG, 'Validating store dependencies...')

    for (const config of this.initConfigs) {
      if (config.dependencies) {
        for (const dep of config.dependencies) {
          const depConfig = this.initConfigs.find(c => c.name === dep)
          if (!depConfig) {
            throw new Error(`Store '${config.name}' depends on '${dep}' which is not configured`)
          }

          if (depConfig.priority >= config.priority) {
            throw new Error(`Dependency priority error: '${dep}' (${depConfig.priority}) must be lower than '${config.name}' (${config.priority})`)
          }
        }
      }
    }

    hilog.debug(0x0000, TAG, 'Dependencies validation passed')
  }

  /**
   * 按优先级排序配置
   */
  private sortConfigsByPriority(): StoreInitConfig[] {
    const sorted = [...this.initConfigs].sort((a, b) => a.priority - b.priority)
    hilog.debug(0x0000, TAG, `Store initialization order: ${sorted.map(c => c.name).join(' -> ')}`)
    return sorted
  }

  /**
   * 按顺序初始化Store
   */
  private async initializeStoresInOrder(configs: StoreInitConfig[]): Promise<void> {
    for (const config of configs) {
      await this.initializeSingleStore(config)
    }
  }

  /**
   * 初始化单个Store
   */
  private async initializeSingleStore(config: StoreInitConfig): Promise<void> {
    hilog.info(0x0000, TAG, `Initializing store: ${config.name}`)

    try {
      const store = storeManager.getStore(config.name)
      if (!store) {
        if (config.required) {
          throw new Error(`Required store '${config.name}' not found`)
        } else {
          hilog.warn(0x0000, TAG, `Optional store '${config.name}' not found, skipping`)
          return
        }
      }

      // 设置超时
      const timeout = config.timeout || 5000
      await this.withTimeout(store.initialize(), timeout, `Store '${config.name}' initialization timeout`)

      hilog.info(0x0000, TAG, `Store '${config.name}' initialized successfully`)

    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize store '${config.name}': ${JSON.stringify(error)}`)

      if (config.required) {
        throw new Error(`Required store '${config.name}' initialization failed: ${error}`)
      } else {
        hilog.warn(0x0000, TAG, `Optional store '${config.name}' initialization failed, continuing`)
      }
    }
  }

  /**
   * 为Promise设置超时
   */
  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number, errorMessage: string): Promise<T> {
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error(errorMessage)), timeoutMs)
    })

    return Promise.race([promise, timeoutPromise])
  }

  /**
   * 获取初始化状态
   */
  getIsInitialized(): boolean {
    return this.isInitialized
  }

  /**
   * 获取初始化配置
   */
  getInitConfigs(): StoreInitConfig[] {
    return [...this.initConfigs]
  }

  /**
   * 重置初始化状态（主要用于测试）
   */
  reset(): void {
    this.isInitialized = false
    hilog.info(0x0000, TAG, 'StoreInitializer reset')
  }
}

/**
 * Store初始化器单例
 */
export const storeInitializer = StoreInitializer.getInstance()

/**
 * 便捷的初始化函数
 * 在应用启动时调用
 */
export const initializeAppStores = async (): Promise<void> => {
  await storeInitializer.initializeStores()
}

/**
 * 检查Store是否已初始化
 */
export const areStoresInitialized = (): boolean => {
  return storeInitializer.getIsInitialized()
}