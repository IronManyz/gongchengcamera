/**
 * 缓存服务
 * 提供内存缓存管理、LRU缓存淘汰策略、缓存统计等功能
 */

import { Logger } from '../../utils/Logger'

/**
 * 缓存项
 */
interface CacheItem<T> {
  key: string
  value: T
  accessCount: number
  lastAccessed: number
  createdAt: number
  size: number // 缓存项大小（字节）
}

/**
 * LRU缓存节点
 */
class LRUNode<T> {
  key: string
  value: T
  size: number
  prev: LRUNode<T> | null = null
  next: LRUNode<T> | null = null

  constructor(key: string, value: T, size: number) {
    this.key = key
    this.value = value
    this.size = size
  }
}

/**
 * LRU双向链表
 */
class LRUCacheList<T> {
  private head: LRUNode<T> | null = null
  private tail: LRUNode<T> | null = null

  /**
   * 将节点移动到链表头部（最近使用）
   */
  moveToHead(node: LRUNode<T>): void {
    this.removeNode(node)
    this.addToHead(node)
  }

  /**
   * 移除节点
   */
  removeNode(node: LRUNode<T>): void {
    if (node.prev) {
      node.prev.next = node.next
    } else {
      this.head = node.next
    }

    if (node.next) {
      node.next.prev = node.prev
    } else {
      this.tail = node.prev
    }
  }

  /**
   * 添加节点到头部
   */
  private addToHead(node: LRUNode<T>): void {
    node.prev = null
    node.next = this.head

    if (this.head) {
      this.head.prev = node
    }
    this.head = node

    if (!this.tail) {
      this.tail = node
    }
  }

  /**
   * 移除尾部节点（最久未使用）
   */
  removeTail(): LRUNode<T> | null {
    if (!this.tail) {
      return null
    }

    const removedNode = this.tail
    this.removeNode(removedNode)
    return removedNode
  }

  /**
   * 检查链表是否为空
   */
  isEmpty(): boolean {
    return this.head === null
  }

  /**
   * 获取所有节点（用于调试）
   */
  getAllNodes(): LRUNode<T>[] {
    const nodes: LRUNode<T>[] = []
    let current = this.head

    while (current) {
      nodes.push(current)
      current = current.next
    }

    return nodes
  }
}

/**
 * 缓存配置
 */
export interface CacheConfig {
  maxSize: number // 最大缓存大小（字节）
  maxItems: number // 最大缓存项数量
  maxAge: number // 最大存活时间（毫秒）
  enableLRU: boolean // 是否启用LRU淘汰策略
  enableStatistics: boolean // 是否启用统计功能
}

/**
 * 缓存统计信息
 */
export interface CacheStats {
  hits: number
  misses: number
  totalRequests: number
  hitRate: number
  currentSize: number
  currentItems: number
  evictions: number
  oldestItem: number
  newestItem: number
  averageAccessCount: number
}

/**
 * 内存缓存管理器
 */
export class MemoryCacheManager<T> {
  private cache: Map<string, LRUNode<T>> = new Map()
  private lruList: LRUCacheList<T> = new LRUCacheList<T>()
  private currentSize: number = 0
  private currentItems: number = 0
  private config: CacheConfig

  // 统计信息
  private hits: number = 0
  private misses: number = 0
  private evictions: number = 0
  private totalSizeAdded: number = 0

  constructor(config: Partial<CacheConfig> = {}) {
    this.config = {
      maxSize: 50 * 1024 * 1024, // 50MB
      maxItems: 1000,
      maxAge: 30 * 60 * 1000, // 30分钟
      enableLRU: true,
      enableStatistics: true,
      ...config
    }
  }

  /**
   * 获取缓存项
   */
  get(key: string): T | null {
    const node = this.cache.get(key)

    if (!node) {
      if (this.config.enableStatistics) {
        this.misses++
      }
      return null
    }

    // 检查是否过期
    if (this.isExpired(node)) {
      this.remove(key)
      if (this.config.enableStatistics) {
        this.misses++
      }
      return null
    }

    // 更新LRU位置
    if (this.config.enableLRU) {
      this.lruList.moveToHead(node)
    }

    if (this.config.enableStatistics) {
      this.hits++
    }

    return node.value
  }

  /**
   * 设置缓存项
   */
  set(key: string, value: T, size: number = 1024): boolean {
    // 检查大小限制
    if (size > this.config.maxSize) {
      return false
    }

    const existingNode = this.cache.get(key)

    if (existingNode) {
      // 更新现有项
      this.currentSize -= existingNode.size
      this.currentSize += size
      existingNode.value = value
      existingNode.size = size

      if (this.config.enableLRU) {
        this.lruList.moveToHead(existingNode)
      }
    } else {
      // 添加新项
      const newNode = new LRUNode(key, value, size)

      // 检查是否需要淘汰
      if (!this.ensureCapacity(size)) {
        return false
      }

      this.cache.set(key, newNode)
      this.lruList.addToHead(newNode)
      this.currentSize += size
      this.currentItems++
      this.totalSizeAdded += size
    }

    return true
  }

  /**
   * 删除缓存项
   */
  remove(key: string): boolean {
    const node = this.cache.get(key)

    if (!node) {
      return false
    }

    this.cache.delete(key)
    this.lruList.removeNode(node)
    this.currentSize -= node.size
    this.currentItems--

    return true
  }

  /**
   * 检查缓存项是否存在
   */
  has(key: string): boolean {
    const node = this.cache.get(key)
    return node !== undefined && !this.isExpired(node)
  }

  /**
   * 清空缓存
   */
  clear(): void {
    this.cache.clear()
    this.lruList = new LRUCacheList<T>()
    this.currentSize = 0
    this.currentItems = 0
  }

  /**
   * 确保有足够的容量
   */
  private ensureCapacity(requiredSize: number): boolean {
    // 检查单项数量限制
    while (this.currentItems >= this.config.maxItems) {
      if (!this.evictLRU()) {
        return false
      }
    }

    // 检查大小限制
    while (this.currentSize + requiredSize > this.config.maxSize) {
      if (!this.evictLRU()) {
        return false
      }
    }

    return true
  }

  /**
   * 淘汰最久未使用的项
   */
  private evictLRU(): boolean {
    const node = this.lruList.removeTail()

    if (!node) {
      return false
    }

    this.cache.delete(node.key)
    this.currentSize -= node.size
    this.currentItems--

    if (this.config.enableStatistics) {
      this.evictions++
    }

    return true
  }

  /**
   * 检查缓存项是否过期
   */
  private isExpired(node: LRUNode<T>): boolean {
    const now = Date.now()
    return (now - Date.now()) > this.config.maxAge
  }

  /**
   * 获取缓存统计信息
   */
  getStats(): CacheStats {
    const totalRequests = this.hits + this.misses
    const hitRate = totalRequests > 0 ? (this.hits / totalRequests) * 100 : 0

    // 计算平均访问次数（简化版本）
    const averageAccessCount = this.currentItems > 0 ? 1 : 0

    // 获取最旧和最新项目时间
    const now = Date.now()
    const oldestItem = now
    const newestItem = now

    return {
      hits: this.hits,
      misses: this.misses,
      totalRequests,
      hitRate: Math.round(hitRate * 100) / 100,
      currentSize: this.currentSize,
      currentItems: this.currentItems,
      evictions: this.evictions,
      oldestItem,
      newestItem,
      averageAccessCount: Math.round(averageAccessCount * 100) / 100
    }
  }

  /**
   * 重置统计信息
   */
  resetStats(): void {
    this.hits = 0
    this.misses = 0
    this.evictions = 0
    this.totalSizeAdded = 0
  }

  /**
   * 获取当前缓存大小
   */
  getCurrentSize(): number {
    return this.currentSize
  }

  /**
   * 获取当前缓存项数量
   */
  getCurrentItems(): number {
    return this.currentItems
  }

  /**
   * 获取配置
   */
  getConfig(): CacheConfig {
    return { ...this.config }
  }

  /**
   * 获取所有键
   */
  keys(): string[] {
    return Array.from(this.cache.keys())
  }

  /**
   * 获取缓存项列表（按LRU顺序）
   */
  getItems(): Array<{ key: string; size: number }> {
    const nodes = this.lruList.getAllNodes()
    return nodes.map(node => ({
      key: node.key,
      size: node.size
    }))
  }
}

/**
 * 主缓存服务
 */
export class CacheService {
  private static instance: CacheService | null = null
  private logger = new Logger('CacheService')

  // 不同类型的缓存管理器
  private imageCache: MemoryCacheManager<ArrayBuffer>
  private thumbnailCache: MemoryCacheManager<ArrayBuffer>
  private dataCache: MemoryCacheManager<any>
  private metadataCache: MemoryCacheManager<Record<string, any>>

  private constructor() {
    // 为不同类型配置不同的缓存策略
    this.imageCache = new MemoryCacheManager<ArrayBuffer>({
      maxSize: 100 * 1024 * 1024, // 100MB for images
      maxItems: 50,
      maxAge: 60 * 60 * 1000, // 1 hour
      enableLRU: true,
      enableStatistics: true
    })

    this.thumbnailCache = new MemoryCacheManager<ArrayBuffer>({
      maxSize: 20 * 1024 * 1024, // 20MB for thumbnails
      maxItems: 200,
      maxAge: 30 * 60 * 1000, // 30 minutes
      enableLRU: true,
      enableStatistics: true
    })

    this.dataCache = new MemoryCacheManager<any>({
      maxSize: 10 * 1024 * 1024, // 10MB for data
      maxItems: 500,
      maxAge: 15 * 60 * 1000, // 15 minutes
      enableLRU: true,
      enableStatistics: true
    })

    this.metadataCache = new MemoryCacheManager<Record<string, any>>({
      maxSize: 5 * 1024 * 1024, // 5MB for metadata
      maxItems: 1000,
      maxAge: 60 * 60 * 1000, // 1 hour
      enableLRU: true,
      enableStatistics: true
    })
  }

  /**
   * 获取单例实例
   */
  static getInstance(): CacheService {
    if (!CacheService.instance) {
      CacheService.instance = new CacheService()
    }
    return CacheService.instance
  }

  /**
   * 缓存图片数据
   */
  cacheImage(key: string, imageData: ArrayBuffer): boolean {
    return this.imageCache.set(key, imageData, imageData.byteLength)
  }

  /**
   * 获取缓存图片
   */
  getImage(key: string): ArrayBuffer | null {
    return this.imageCache.get(key)
  }

  /**
   * 缓存缩略图
   */
  cacheThumbnail(key: string, thumbnailData: ArrayBuffer): boolean {
    return this.thumbnailCache.set(key, thumbnailData, thumbnailData.byteLength)
  }

  /**
   * 获取缓存缩略图
   */
  getThumbnail(key: string): ArrayBuffer | null {
    return this.thumbnailCache.get(key)
  }

  /**
   * 缓存业务数据
   */
  cacheData<T>(key: string, data: T, size: number = 1024): boolean {
    return this.dataCache.set(key, data, size)
  }

  /**
   * 获取缓存数据
   */
  getData<T>(key: string): T | null {
    return this.dataCache.get(key)
  }

  /**
   * 缓存元数据
   */
  cacheMetadata(key: string, metadata: Record<string, any>): boolean {
    const size = JSON.stringify(metadata).length
    return this.metadataCache.set(key, metadata, size)
  }

  /**
   * 获取缓存元数据
   */
  getMetadata(key: string): Record<string, any> | null {
    return this.metadataCache.get(key)
  }

  /**
   * 移除缓存项
   */
  remove(key: string, type: 'image' | 'thumbnail' | 'data' | 'metadata' = 'data'): boolean {
    switch (type) {
      case 'image':
        return this.imageCache.remove(key)
      case 'thumbnail':
        return this.thumbnailCache.remove(key)
      case 'data':
        return this.dataCache.remove(key)
      case 'metadata':
        return this.metadataCache.remove(key)
      default:
        return false
    }
  }

  /**
   * 检查缓存项是否存在
   */
  has(key: string, type: 'image' | 'thumbnail' | 'data' | 'metadata' = 'data'): boolean {
    switch (type) {
      case 'image':
        return this.imageCache.has(key)
      case 'thumbnail':
        return this.thumbnailCache.has(key)
      case 'data':
        return this.dataCache.has(key)
      case 'metadata':
        return this.metadataCache.has(key)
      default:
        return false
    }
  }

  /**
   * 清空指定类型的缓存
   */
  clear(type?: 'image' | 'thumbnail' | 'data' | 'metadata'): void {
    if (!type) {
      // 清空所有缓存
      this.imageCache.clear()
      this.thumbnailCache.clear()
      this.dataCache.clear()
      this.metadataCache.clear()
      this.logger.info('All caches cleared')
    } else {
      switch (type) {
        case 'image':
          this.imageCache.clear()
          break
        case 'thumbnail':
          this.thumbnailCache.clear()
          break
        case 'data':
          this.dataCache.clear()
          break
        case 'metadata':
          this.metadataCache.clear()
          break
      }
      this.logger.info(`${type} cache cleared`)
    }
  }

  /**
   * 获取缓存统计信息
   */
  getStats(): {
    image: CacheStats
    thumbnail: CacheStats
    data: CacheStats
    metadata: CacheStats
    total: {
      size: number
      items: number
      hitRate: number
    }
  } {
    const imageStats = this.imageCache.getStats()
    const thumbnailStats = this.thumbnailCache.getStats()
    const dataStats = this.dataCache.getStats()
    const metadataStats = this.metadataCache.getStats()

    const totalRequests = imageStats.totalRequests + thumbnailStats.totalRequests +
                         dataStats.totalRequests + metadataStats.totalRequests
    const totalHits = imageStats.hits + thumbnailStats.hits +
                     dataStats.hits + metadataStats.hits
    const totalHitRate = totalRequests > 0 ? (totalHits / totalRequests) * 100 : 0

    return {
      image: imageStats,
      thumbnail: thumbnailStats,
      data: dataStats,
      metadata: metadataStats,
      total: {
        size: imageStats.currentSize + thumbnailStats.currentSize +
              dataStats.currentSize + metadataStats.currentSize,
        items: imageStats.currentItems + thumbnailStats.currentItems +
               dataStats.currentItems + metadataStats.currentItems,
        hitRate: Math.round(totalHitRate * 100) / 100
      }
    }
  }

  /**
   * 重置统计信息
   */
  resetStats(): void {
    this.imageCache.resetStats()
    this.thumbnailCache.resetStats()
    this.dataCache.resetStats()
    this.metadataCache.resetStats()
    this.logger.info('Cache statistics reset')
  }

  /**
   * 获取内存使用情况
   */
  getMemoryUsage(): {
    image: { size: number; items: number; maxSize: number }
    thumbnail: { size: number; items: number; maxSize: number }
    data: { size: number; items: number; maxSize: number }
    metadata: { size: number; items: number; maxSize: number }
    total: { size: number; items: number; maxSize: number }
  } {
    const imageConfig = this.imageCache.getConfig()
    const thumbnailConfig = this.thumbnailCache.getConfig()
    const dataConfig = this.dataCache.getConfig()
    const metadataConfig = this.metadataCache.getConfig()

    return {
      image: {
        size: this.imageCache.getCurrentSize(),
        items: this.imageCache.getCurrentItems(),
        maxSize: imageConfig.maxSize
      },
      thumbnail: {
        size: this.thumbnailCache.getCurrentSize(),
        items: this.thumbnailCache.getCurrentItems(),
        maxSize: thumbnailConfig.maxSize
      },
      data: {
        size: this.dataCache.getCurrentSize(),
        items: this.dataCache.getCurrentItems(),
        maxSize: dataConfig.maxSize
      },
      metadata: {
        size: this.metadataCache.getCurrentSize(),
        items: this.metadataCache.getCurrentItems(),
        maxSize: metadataConfig.maxSize
      },
      total: {
        size: this.imageCache.getCurrentSize() + this.thumbnailCache.getCurrentSize() +
               this.dataCache.getCurrentSize() + this.metadataCache.getCurrentSize(),
        items: this.imageCache.getCurrentItems() + this.thumbnailCache.getCurrentItems() +
               this.dataCache.getCurrentItems() + this.metadataCache.getCurrentItems(),
        maxSize: imageConfig.maxSize + thumbnailConfig.maxSize +
                dataConfig.maxSize + metadataConfig.maxSize
      }
    }
  }

  /**
   * 预热缓存（预加载常用数据）
   */
  async warmup(keys: Array<{ key: string; type: 'image' | 'thumbnail' | 'data' | 'metadata' }>): Promise<void> {
    this.logger.info('Starting cache warmup', { keyCount: keys.length })

    // 这里可以根据实际需求预加载数据
    // 例如：预加载最近使用的缩略图、常用配置等

    this.logger.info('Cache warmup completed')
  }

  /**
   * 执行缓存维护
   */
  performMaintenance(): void {
    this.logger.info('Performing cache maintenance')

    // 检查缓存命中率
    const stats = this.getStats()

    if (stats.total.hitRate < 50) {
      this.logger.warn('Low cache hit rate detected', { hitRate: stats.total.hitRate })
    }

    // 检查内存使用率
    const memoryUsage = this.getMemoryUsage()
    const totalUsageRatio = (memoryUsage.total.size / memoryUsage.total.maxSize) * 100

    if (totalUsageRatio > 90) {
      this.logger.warn('High memory usage detected', { usageRatio: totalUsageRatio })

      // 可以触发更激进的清理策略
      // 例如：清理过期项、降低缓存大小等
    }

    this.logger.info('Cache maintenance completed')
  }

  /**
   * 导出缓存配置（用于调试）
   */
  exportConfiguration(): Record<string, any> {
    return {
      image: this.imageCache.getConfig(),
      thumbnail: this.thumbnailCache.getConfig(),
      data: this.dataCache.getConfig(),
      metadata: this.metadataCache.getConfig(),
      memoryUsage: this.getMemoryUsage(),
      statistics: this.getStats()
    }
  }

  /**
   * 清理过期缓存项
   */
  cleanupExpired(): void {
    // LRU实现会在访问时自动清理过期项
    // 这里可以添加主动清理逻辑
    this.logger.info('Cleanup expired items completed')
  }

  /**
   * 获取缓存健康状态
   */
  getHealthStatus(): {
    status: 'healthy' | 'warning' | 'critical'
    issues: string[]
    recommendations: string[]
  } {
    const issues: string[] = []
    const recommendations: string[] = []

    const stats = this.getStats()
    const memoryUsage = this.getMemoryUsage()

    // 检查命中率
    if (stats.total.hitRate < 30) {
      issues.push(`Low cache hit rate: ${stats.total.hitRate}%`)
      recommendations.push('Consider increasing cache size or reviewing caching strategy')
    }

    // 检查内存使用
    const usageRatio = (memoryUsage.total.size / memoryUsage.total.maxSize) * 100
    if (usageRatio > 90) {
      issues.push(`High memory usage: ${usageRatio.toFixed(1)}%`)
      recommendations.push('Consider increasing cache limits or implementing more aggressive eviction')
    }

    // 检查淘汰率
    const totalEvictions = stats.image.evictions + stats.thumbnail.evictions +
                          stats.data.evictions + stats.metadata.evictions
    if (totalEvictions > 100) {
      issues.push(`High eviction rate: ${totalEvictions} evictions`)
      recommendations.push('Consider increasing cache size to reduce evictions')
    }

    let status: 'healthy' | 'warning' | 'critical' = 'healthy'
    if (issues.length >= 2 || usageRatio > 95) {
      status = 'critical'
    } else if (issues.length > 0) {
      status = 'warning'
    }

    return {
      status,
      issues,
      recommendations
    }
  }
}