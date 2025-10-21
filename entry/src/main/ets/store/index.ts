/**
 * store/index.ts
 * Store统一入口文件
 * 提供所有Store的统一访问接口和初始化管理
 */

import { BaseStore } from './BaseStore'
import { GlobalStore, globalStore, GlobalAppState } from './GlobalStore'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'StoreIndex'

/**
 * 导出所有Store相关的类和实例
 */
export { BaseStore } from './BaseStore'
export { GlobalStore, globalStore, GlobalAppState } from './GlobalStore'
export {
  StoreInitializer,
  storeInitializer,
  initializeAppStores,
  areStoresInitialized
} from './StoreInitializer'

// ThemeStore
export { ThemeStore, themeStore, ThemeState, AppTheme } from './theme/ThemeStore'
export { ThemeType, ThemeColors, FontSizes, FontWeights, BorderRadius, Spacing, Shadows, DefaultThemeConfig } from './theme/ThemeConstants'
export { systemThemeMonitor, SystemThemeListener } from './theme/SystemThemeMonitor'

// UserStore
export { UserStore, userStore, UserState, UserPreferences, UserRole, UserPermission, PermissionManager } from './user/UserStore'

/**
 * Store管理器类
 * 负责所有Store的初始化、销毁和管理
 */
export class StoreManager {
  private static instance: StoreManager | null = null

  /**
   * 所有已注册的Store实例
   */
  private stores: Map<string, BaseStore> = new Map()

  /**
   * 获取Store管理器单例
   */
  static getInstance(): StoreManager {
    if (!StoreManager.instance) {
      StoreManager.instance = new StoreManager()
    }
    return StoreManager.instance
  }

  /**
   * 私有构造函数，确保单例模式
   */
  private constructor() {
    this.registerDefaultStores()
  }

  /**
   * 注册默认的Store实例
   */
  private registerDefaultStores(): void {
    // 注册全局Store
    this.registerStore('global', globalStore)

    // 注册主题Store
    this.registerStore('theme', themeStore)

    // 注册用户Store
    this.registerStore('user', userStore)

    hilog.info(0x0000, TAG, 'Default stores registered')
  }

  /**
   * 注册Store实例
   */
  registerStore(name: string, store: BaseStore): void {
    if (this.stores.has(name)) {
      hilog.warn(0x0000, TAG, `Store '${name}' already registered, skipping`)
      return
    }

    this.stores.set(name, store)
    hilog.info(0x0000, TAG, `Store '${name}' registered`)
  }

  /**
   * 获取Store实例
   */
  getStore<T extends BaseStore>(name: string): T | null {
    const store = this.stores.get(name) as T
    if (!store) {
      hilog.error(0x0000, TAG, `Store '${name}' not found`)
    }
    return store || null
  }

  /**
   * 初始化所有Store
   */
  async initializeAll(): Promise<void> {
    hilog.info(0x0000, TAG, 'Initializing all stores...')

    const initPromises: Promise<void>[] = []

    this.stores.forEach((store, name) => {
      initPromises.push(
        this.initializeStore(name, store)
      )
    })

    try {
      await Promise.all(initPromises)
      hilog.info(0x0000, TAG, 'All stores initialized successfully')
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize stores: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 初始化单个Store
   */
  private async initializeStore(name: string, store: BaseStore): Promise<void> {
    try {
      await store.initialize()
      hilog.info(0x0000, TAG, `Store '${name}' initialized`)
    } catch (error) {
      hilog.error(0x0000, TAG, `Store '${name}' initialization failed: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 销毁所有Store
   */
  async destroyAll(): Promise<void> {
    hilog.info(0x0000, TAG, 'Destroying all stores...')

    const destroyPromises: Promise<void>[] = []

    this.stores.forEach((store, name) => {
      destroyPromises.push(
        this.destroyStore(name, store)
      )
    })

    try {
      await Promise.all(destroyPromises)
      this.stores.clear()
      hilog.info(0x0000, TAG, 'All stores destroyed successfully')
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to destroy stores: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 销毁单个Store
   */
  private async destroyStore(name: string, store: BaseStore): Promise<void> {
    try {
      await store.destroy()
      hilog.info(0x0000, TAG, `Store '${name}' destroyed`)
    } catch (error) {
      hilog.error(0x0000, TAG, `Store '${name}' destruction failed: ${JSON.stringify(error)}`)
      // 销毁失败不应该阻止其他Store的销毁
    }
  }

  /**
   * 获取所有已注册的Store名称
   */
  getStoreNames(): string[] {
    return Array.from(this.stores.keys())
  }

  /**
   * 检查Store是否已注册
   */
  hasStore(name: string): boolean {
    return this.stores.has(name)
  }

  /**
   * 获取所有Store的初始化状态
   */
  getInitializationStatus(): Record<string, boolean> {
    const status: Record<string, boolean> = {}

    this.stores.forEach((store, name) => {
      status[name] = store.isInitialized
    })

    return status
  }
}

/**
 * Store管理器单例实例
 */
export const storeManager = StoreManager.getInstance()

/**
 * 便捷的Store访问函数
 */
export const getGlobalStore = (): GlobalStore => {
  const store = storeManager.getStore<GlobalStore>('global')
  if (!store) {
    throw new Error('GlobalStore not found')
  }
  return store
}

/**
 * 便捷的全局状态访问函数
 */
export const getGlobalState = (): GlobalAppState => {
  return getGlobalStore().appState
}

/**
 * Store初始化函数
 * 在应用启动时调用
 */
export const initializeStores = async (): Promise<void> => {
  await storeManager.initializeAll()
}

/**
 * Store销毁函数
 * 在应用退出时调用
 */
export const destroyStores = async (): Promise<void> => {
  await storeManager.destroyAll()
}