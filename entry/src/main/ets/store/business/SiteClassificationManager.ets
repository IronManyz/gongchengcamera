/**
 * SiteClassificationManager.ets
 * 工点分类管理器
 * 负责工点的分类、标签管理和自动分类逻辑
 */

import { Site } from '../../models/Site'
import { LocationData } from '../../types/AppTypes'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'SiteClassificationManager'

/**
 * 工点分类类型
 */
export enum SiteCategory {
  STRUCTURE = 'structure',      // 结构工程
  FOUNDATION = 'foundation',    // 基础工程
  EXCAVATION = 'excavation',    // 开挖工程
  CONCRETE = 'concrete',        // 混凝土工程
  STEEL = 'steel',              // 钢结构工程
  ELECTRICAL = 'electrical',    // 电气工程
  PLUMBING = 'plumbing',        // 管道工程
  FINISHING = 'finishing',      // 装修工程
  LANDSCAPE = 'landscape',      // 景观工程
  SAFETY = 'safety',            // 安全工程
  QUALITY = 'quality',          // 质量检查
  OTHER = 'other'               // 其他
}

/**
 * 工点分类配置
 */
export interface SiteCategoryConfig {
  type: SiteCategory
  name: string
  description: string
  color: string
  keywords: string[]
  defaultTags: string[]
}

/**
 * 工点分类规则
 */
export interface ClassificationRule {
  category: SiteCategory
  condition: (site: Site) => boolean
  priority: number // 优先级，数字越大优先级越高
}

/**
 * 地理区域分类
 */
export interface GeographicRegion {
  id: string
  name: string
  type: 'province' | 'city' | 'district' | 'zone'
  bounds: {
    minLat: number
    maxLat: number
    minLng: number
    maxLng: number
  }
  defaultCategory?: SiteCategory
  defaultTags?: string[]
}

/**
 * 工点分类管理器
 */
export class SiteClassificationManager {
  private static instance: SiteClassificationManager | null = null

  // 分类配置
  private readonly categoryConfigs: Record<SiteCategory, SiteCategoryConfig> = {
    [SiteCategory.STRUCTURE]: {
      type: SiteCategory.STRUCTURE,
      name: '结构工程',
      description: '建筑主体结构、承重结构等工程',
      color: '#FF6B6B',
      keywords: ['结构', '主体', '承重', '梁', '柱', '板', '墙', '框架'],
      defaultTags: ['结构', '主体工程']
    },
    [SiteCategory.FOUNDATION]: {
      type: SiteCategory.FOUNDATION,
      name: '基础工程',
      description: '地基、桩基、地下工程等',
      color: '#4ECDC4',
      keywords: ['基础', '地基', '桩基', '地下', '基坑', '开挖'],
      defaultTags: ['基础', '地基']
    },
    [SiteCategory.EXCAVATION]: {
      type: SiteCategory.EXCAVATION,
      name: '开挖工程',
      description: '土方开挖、石方爆破等',
      color: '#45B7D1',
      keywords: ['开挖', '土方', '爆破', '石方', '挖掘'],
      defaultTags: ['开挖', '土方']
    },
    [SiteCategory.CONCRETE]: {
      type: SiteCategory.CONCRETE,
      name: '混凝土工程',
      description: '混凝土浇筑、养护等',
      color: '#96CEB4',
      keywords: ['混凝土', '砼', '浇筑', '养护', '搅拌'],
      defaultTags: ['混凝土', '浇筑']
    },
    [SiteCategory.STEEL]: {
      type: SiteCategory.STEEL,
      name: '钢结构工程',
      description: '钢结构安装、焊接等',
      color: '#DDA0DD',
      keywords: ['钢结构', '钢梁', '钢柱', '焊接', '螺栓'],
      defaultTags: ['钢结构', '安装']
    },
    [SiteCategory.ELECTRICAL]: {
      type: SiteCategory.ELECTRICAL,
      name: '电气工程',
      description: '电气设备安装、线路敷设等',
      color: '#FFD700',
      keywords: ['电气', '电线', '电缆', '配电', '照明'],
      defaultTags: ['电气', '安装']
    },
    [SiteCategory.PLUMBING]: {
      type: SiteCategory.PLUMBING,
      name: '管道工程',
      description: '给排水、暖通管道等',
      color: '#87CEEB',
      keywords: ['管道', '给水', '排水', '暖通', '空调'],
      defaultTags: ['管道', '安装']
    },
    [SiteCategory.FINISHING]: {
      type: SiteCategory.FINISHING,
      name: '装修工��',
      description: '室内外装修、装饰工程等',
      color: '#FFA07A',
      keywords: ['装修', '装饰', '涂料', '瓷砖', '地板'],
      defaultTags: ['装修', '装饰']
    },
    [SiteCategory.LANDSCAPE]: {
      type: SiteCategory.LANDSCAPE,
      name: '景观工程',
      description: '园林绿化、景观小品等',
      color: '#98FB98',
      keywords: ['景观', '绿化', '园林', '花草', '树木'],
      defaultTags: ['景观', '绿化']
    },
    [SiteCategory.SAFETY]: {
      type: SiteCategory.SAFETY,
      name: '安全工程',
      description: '安全防护、消防设施等',
      color: '#FF69B4',
      keywords: ['安全', '消防', '防护', '监控', '报警'],
      defaultTags: ['安全', '防护']
    },
    [SiteCategory.QUALITY]: {
      type: SiteCategory.QUALITY,
      name: '质量检查',
      description: '质量检查、验收测试等',
      color: '#FFB6C1',
      keywords: ['质量', '检查', '验收', '测试', '检测'],
      defaultTags: ['质量', '检查']
    },
    [SiteCategory.OTHER]: {
      type: SiteCategory.OTHER,
      name: '其他',
      description: '其他类型的工点',
      color: '#D3D3D3',
      keywords: [],
      defaultTags: ['其他']
    }
  }

  // 分类规则
  private readonly classificationRules: ClassificationRule[] = [
    {
      category: SiteCategory.FOUNDATION,
      condition: (site) => this.matchesKeywords(site, ['基础', '地基', '桩基', '地下']),
      priority: 9
    },
    {
      category: SiteCategory.EXCAVATION,
      condition: (site) => this.matchesKeywords(site, ['开挖', '土方', '爆破', '挖掘']),
      priority: 8
    },
    {
      category: SiteCategory.STRUCTURE,
      condition: (site) => this.matchesKeywords(site, ['结构', '主体', '承重', '梁', '柱', '板']),
      priority: 10
    },
    {
      category: SiteCategory.CONCRETE,
      condition: (site) => this.matchesKeywords(site, ['混凝土', '砼', '浇筑']),
      priority: 7
    },
    {
      category: SiteCategory.STEEL,
      condition: (site) => this.matchesKeywords(site, ['钢结构', '钢梁', '钢柱', '焊接']),
      priority: 6
    },
    {
      category: SiteCategory.ELECTRICAL,
      condition: (site) => this.matchesKeywords(site, ['电气', '电线', '电缆', '配电']),
      priority: 5
    },
    {
      category: SiteCategory.PLUMBING,
      condition: (site) => this.matchesKeywords(site, ['管道', '给水', '排水', '暖通']),
      priority: 4
    },
    {
      category: SiteCategory.FINISHING,
      condition: (site) => this.matchesKeywords(site, ['装修', '装饰', '涂料', '瓷砖']),
      priority: 3
    },
    {
      category: SiteCategory.LANDSCAPE,
      condition: (site) => this.matchesKeywords(site, ['景观', '绿化', '园林', '花草']),
      priority: 2
    },
    {
      category: SiteCategory.SAFETY,
      condition: (site) => this.matchesKeywords(site, ['安全', '消防', '防护', '监控']),
      priority: 1
    },
    {
      category: SiteCategory.QUALITY,
      condition: (site) => this.matchesKeywords(site, ['质量', '检查', '验收', '测试']),
      priority: 1
    }
  ]

  // 地理区域定义（示例）
  private readonly geographicRegions: GeographicRegion[] = [
    {
      id: 'beijing-urban',
      name: '北京市区',
      type: 'city',
      bounds: { minLat: 39.8, maxLat: 40.0, minLng: 116.3, maxLng: 116.5 },
      defaultCategory: SiteCategory.STRUCTURE,
      defaultTags: ['市区', '建筑']
    },
    {
      id: 'beijing-suburban',
      name: '北京郊区',
      type: 'zone',
      bounds: { minLat: 39.5, maxLat: 40.2, minLng: 116.0, maxLng: 117.0 },
      defaultCategory: SiteCategory.LANDSCAPE,
      defaultTags: ['郊区', '绿化']
    }
  ]

  /**
   * 获取单例实例
   */
  static getInstance(): SiteClassificationManager {
    if (!SiteClassificationManager.instance) {
      SiteClassificationManager.instance = new SiteClassificationManager()
    }
    return SiteClassificationManager.instance
  }

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 自动分类工点
   */
  classifySite(site: Site): {
    category: SiteCategory
    confidence: number // 置信度 0-1
    reason: string
  } {
    // 按优先级检查分类规则
    const matchedRules = this.classificationRules
      .filter(rule => rule.condition(site))
      .sort((a, b) => b.priority - a.priority)

    if (matchedRules.length > 0) {
      const bestRule = matchedRules[0]
      const confidence = this.calculateConfidence(site, bestRule.category)

      return {
        category: bestRule.category,
        confidence,
        reason: `基于关键词匹配规则`
      }
    }

    // 基于地理位置分类
    const geoCategory = this.classifyByLocation(site)
    if (geoCategory) {
      return {
        category: geoCategory,
        confidence: 0.6,
        reason: '基于地理位置分类'
      }
    }

    // 默认分类
    return {
      category: SiteCategory.OTHER,
      confidence: 0.1,
      reason: '无法自动分类，归类为其他'
    }
  }

  /**
   * 批量自动分类
   */
  batchClassifySites(sites: Site[]): Array<{
    site: Site
    classification: ReturnType<typeof this.classifySite>
    suggestedTags: string[]
  }> {
    return sites.map(site => {
      const classification = this.classifySite(site)
      const suggestedTags = this.getSuggestedTags(site, classification.category)

      return {
        site,
        classification,
        suggestedTags
      }
    })
  }

  /**
   * 获取建议标签
   */
  getSuggestedTags(site: Site, category: SiteCategory): string[] {
    const config = this.categoryConfigs[category]
    const suggestedTags = [...config.defaultTags]

    // 基于地理位置添加标签
    const locationTags = this.getLocationTags(site)
    suggestedTags.push(...locationTags)

    // 去重
    return [...new Set(suggestedTags)]
  }

  /**
   * 手动添加分类标签
   */
  addCategoryTag(site: Site, category: SiteCategory): void {
    const config = this.categoryConfigs[category]
    const tags = this.getSuggestedTags(site, category)

    tags.forEach(tag => site.addTag(tag))

    hilog.info(0x0000, TAG, `为工点添加分类标签: ${site.name} -> ${config.name}`)
  }

  /**
   * 获取所有分类配置
   */
  getAllCategories(): SiteCategoryConfig[] {
    return Object.values(this.categoryConfigs)
  }

  /**
   * 根据类型获取分类配置
   */
  getCategoryConfig(type: SiteCategory): SiteCategoryConfig | null {
    return this.categoryConfigs[type] || null
  }

  /**
   * 获取分类统计信息
   */
  getCategoryStats(sites: Site[]): Record<SiteCategory, {
    count: number
    percentage: number
    totalPhotos: number
    avgPhotosPerSite: number
  }> {
    const stats: Record<SiteCategory, any> = {}

    // 初始化统计对象
    Object.values(SiteCategory).forEach(category => {
      stats[category] = {
        count: 0,
        percentage: 0,
        totalPhotos: 0,
        avgPhotosPerSite: 0
      }
    })

    // 统计各分类数量
    sites.forEach(site => {
      const classification = this.classifySite(site)
      stats[classification.category].count++
      stats[classification.category].totalPhotos += site.photoCount
    })

    // 计算百分比和平均值
    const totalSites = sites.length
    Object.values(SiteCategory).forEach(category => {
      const stat = stats[category]
      stat.percentage = totalSites > 0 ? Math.round((stat.count / totalSites) * 100) : 0
      stat.avgPhotosPerSite = stat.count > 0 ? Math.round(stat.totalPhotos / stat.count) : 0
    })

    return stats
  }

  /**
   * 检查关键词匹配
   */
  private matchesKeywords(site: Site, keywords: string[]): boolean {
    const searchText = [
      site.name,
      site.description,
      site.address,
      ...site.tags
    ].join(' ').toLowerCase()

    return keywords.some(keyword =>
      searchText.includes(keyword.toLowerCase())
    )
  }

  /**
   * 计算分类置信度
   */
  private calculateConfidence(site: Site, category: SiteCategory): number {
    const config = this.categoryConfigs[category]
    const searchText = [
      site.name,
      site.description,
      site.address,
      ...site.tags
    ].join(' ').toLowerCase()

    let matchCount = 0
    config.keywords.forEach(keyword => {
      if (searchText.includes(keyword.toLowerCase())) {
        matchCount++
      }
    })

    // 基于匹配关键词数量计算置信度
    const keywordConfidence = config.keywords.length > 0
      ? matchCount / config.keywords.length
      : 0

    // 如果已有相关标签，提高置信度
    const tagConfidence = config.defaultTags.some(tag =>
      site.tags.includes(tag)
    ) ? 0.3 : 0

    return Math.min(1, keywordConfidence + tagConfidence)
  }

  /**
   * 基于地理位置分类
   */
  private classifyByLocation(site: Site): SiteCategory | null {
    if (!site.hasValidLocation()) {
      return null
    }

    for (const region of this.geographicRegions) {
      if (this.isLocationInRegion(site.latitude, site.longitude, region)) {
        return region.defaultCategory || null
      }
    }

    return null
  }

  /**
   * 检查位置是否在区域内
   */
  private isLocationInRegion(
    lat: number,
    lng: number,
    region: GeographicRegion
  ): boolean {
    return lat >= region.bounds.minLat &&
           lat <= region.bounds.maxLat &&
           lng >= region.bounds.minLng &&
           lng <= region.bounds.maxLng
  }

  /**
   * 获取位置相关标签
   */
  private getLocationTags(site: Site): string[] {
    const tags: string[] = []

    if (!site.hasValidLocation()) {
      tags.push('无位置信息')
      return tags
    }

    // 基于地理区域添加标签
    for (const region of this.geographicRegions) {
      if (this.isLocationInRegion(site.latitude, site.longitude, region)) {
        tags.push(region.name)
        if (region.defaultTags) {
          tags.push(...region.defaultTags)
        }
        break
      }
    }

    return tags
  }

  /**
   * 搜索相似工点
   */
  findSimilarSites(site: Site, allSites: Site[], limit: number = 5): Array<{
    site: Site
    similarity: number
    reasons: string[]
  }> {
    const similarities = allSites
      .filter(s => s.id !== site.id)
      .map(otherSite => {
        const similarity = this.calculateSimilarity(site, otherSite)
        return {
          site: otherSite,
          similarity,
          reasons: this.getSimilarityReasons(site, otherSite)
        }
      })
      .filter(item => item.similarity > 0.3) // 只返回相似度大于30%的
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, limit)

    return similarities
  }

  /**
   * 计算工点相似度
   */
  private calculateSimilarity(site1: Site, site2: Site): number {
    let score = 0
    let maxScore = 0

    // 名称相似度
    maxScore += 30
    if (site1.name && site2.name) {
      const nameSimilarity = this.stringSimilarity(site1.name, site2.name)
      score += nameSimilarity * 30
    }

    // 分类相似度
    maxScore += 25
    const class1 = this.classifySite(site1)
    const class2 = this.classifySite(site2)
    if (class1.category === class2.category) {
      score += 25
    }

    // 标签相似度
    maxScore += 20
    const commonTags = site1.tags.filter(tag => site2.tags.includes(tag))
    const tagSimilarity = (commonTags.length / Math.max(site1.tags.length, site2.tags.length, 1))
    score += tagSimilarity * 20

    // 地理位置相似度
    maxScore += 25
    if (site1.hasValidLocation() && site2.hasValidLocation()) {
      const distance = site1.distanceTo(site2.latitude, site2.longitude)
      if (distance < 1000) { // 1km内
        score += 25 * (1 - distance / 1000)
      }
    }

    return maxScore > 0 ? score / maxScore : 0
  }

  /**
   * 字符串相似度计算
   */
  private stringSimilarity(str1: string, str2: string): number {
    const longer = str1.length > str2.length ? str1 : str2
    const shorter = str1.length > str2.length ? str2 : str1

    if (longer.length === 0) return 1.0

    const editDistance = this.levenshteinDistance(longer, shorter)
    return (longer.length - editDistance) / longer.length
  }

  /**
   * 计算编辑距离
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const matrix = []

    for (let i = 0; i <= str2.length; i++) {
      matrix[i] = [i]
    }

    for (let j = 0; j <= str1.length; j++) {
      matrix[0][j] = j
    }

    for (let i = 1; i <= str2.length; i++) {
      for (let j = 1; j <= str1.length; j++) {
        if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1]
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1
          )
        }
      }
    }

    return matrix[str2.length][str1.length]
  }

  /**
   * 获取相似性原因
   */
  private getSimilarityReasons(site1: Site, site2: Site): string[] {
    const reasons: string[] = []

    // 分类相同
    const class1 = this.classifySite(site1)
    const class2 = this.classifySite(site2)
    if (class1.category === class2.category) {
      reasons.push(`同属${this.categoryConfigs[class1.category].name}`)
    }

    // 共同标签
    const commonTags = site1.tags.filter(tag => site2.tags.includes(tag))
    if (commonTags.length > 0) {
      reasons.push(`共同标签: ${commonTags.join(', ')}`)
    }

    // 地理位置相近
    if (site1.hasValidLocation() && site2.hasValidLocation()) {
      const distance = site1.distanceTo(site2.latitude, site2.longitude)
      if (distance < 1000) {
        reasons.push(`地理位置相近 (${site1.getDistanceText(site2.latitude, site2.longitude)})`)
      }
    }

    return reasons
  }
}

/**
 * 导出单例实例
 */
export const siteClassificationManager = SiteClassificationManager.getInstance()