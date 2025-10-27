/**
 * 照片分组管理组件
 * 提供按日期、工程、工点、标签的分组功能
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { Photo } from '../../models/Photo'

export interface GroupOption {
  key: string
  label: string
  count: number
  icon: string
  type: 'date' | 'project' | 'site' | 'tag'
  subItems?: GroupOption[]
}

export interface GroupFilter {
  dates?: string[]
  projectIds?: string[]
  siteIds?: string[]
  tags?: string[]
  dateRange?: { start: Date, end: Date }
  sortBy?: 'date' | 'name'
  sortOrder?: 'asc' | 'desc'
}

@ComponentV2
export struct PhotoGroupManager {
  @Param photos: Photo[] = []
  @Param selectedFilter?: GroupFilter
  @Param onFilterChange?: (filter: GroupFilter) => void
  @Param onGroupSelect?: (group: GroupOption) => void

  @State private expandedGroups: Set<string> = new Set()
  @State private showProjectSelector: boolean = false
  @State private showSiteSelector: boolean = false
  @State private showTagSelector: boolean = false
  @State private showCalendarSelector: boolean = false

  /**
   * 获取分组选项
   */
  private getGroupOptions(): GroupOption[] {
    const groups: GroupOption[] = []

    // 日期分组
    groups.push(...this.getDateGroups())

    // 工程分组
    groups.push(...this.getProjectGroups())

    // 工点分组
    groups.push(...this.getSiteGroups())

    // 标签分组
    groups.push(...this.getTagGroups())

    return groups
  }

  /**
   * 获取日期分组
   */
  private getDateGroups(): GroupOption[] {
    const dateGroups = new Map<string, number>()
    const today = new Date()

    this.photos.forEach(photo => {
      if (!photo.takenAt) return

      const photoDate = new Date(photo.takenAt)
      const dateKey = this.getDateGroupKey(photoDate, today)

      dateGroups.set(dateKey, (dateGroups.get(dateKey) || 0) + 1)
    })

    return Array.from(dateGroups.entries()).map(([key, count]) => ({
      key,
      label: key,
      count,
      icon: '📅',
      type: 'date'
    }))
  }

  /**
   * 获取日期分组键
   */
  private getDateGroupKey(date: Date, today: Date): string {
    const diffTime = today.getTime() - date.getTime()
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays === 0) {
      return '今天'
    } else if (diffDays === 1) {
      return '昨天'
    } else if (diffDays < 7) {
      return '本周'
    } else if (diffDays < 30) {
      return '本月'
    } else if (diffDays < 90) {
      return '近三月'
    } else if (diffDays < 365) {
      return date.getFullYear().toString()
    } else {
      return '更早'
    }
  }

  /**
   * 获取工程分组
   */
  private getProjectGroups(): GroupOption[] {
    const projectGroups = new Map<string, number>()
    const projectIdCounts = new Map<string, number>()

    // 统计每个工程的照片数量
    this.photos.forEach(photo => {
      if (photo.projectId) {
        const count = projectIdCounts.get(photo.projectId) || 0
        projectIdCounts.set(photo.projectId, count + 1)
      }
    })

    // 从Photo对象中提取工程信息（假设Photo有projectName属性）
    this.photos.forEach(photo => {
      if (photo.projectId && photo.projectName) {
        projectGroups.set(photo.projectName, projectIdCounts.get(photo.projectId) || 0)
      }
    })

    return Array.from(projectGroups.entries()).map(([name, count]) => ({
      key: name,
      label: name,
      count,
      icon: '🏗️',
      type: 'project'
    }))
  }

  /**
   * 获取工点分组
   */
  private getSiteGroups(): GroupOption[] {
    const siteGroups = new Map<string, number>()
    const siteIdCounts = new Map<string, number>()

    // 统计每个工点的照片数量
    this.photos.forEach(photo => {
      if (photo.siteId) {
        const count = siteIdCounts.get(photo.siteId) || 0
        siteIdCounts.set(photo.siteId, count + 1)
      }
    })

    // 从Photo对象中提取工点信息（假设Photo有siteName属性）
    this.photos.forEach(photo => {
      if (photo.siteId && photo.siteName) {
        siteGroups.set(photo.siteName, siteIdCounts.get(photo.siteId) || 0)
      }
    })

    return Array.from(siteGroups.entries()).map(([name, count]) => ({
      key: name,
      label: name,
      count,
      icon: '📍',
      type: 'site'
    }))
  }

  /**
   * 获取标签分组
   */
  private getTagGroups(): GroupOption[] {
    const tagGroups = new Map<string, number>()
    const allTags: string[] = []

    // 收集所有标签
    this.photos.forEach(photo => {
      if (photo.tags && photo.tags.length > 0) {
        photo.tags.forEach(tag => {
          allTags.push(tag)
          const count = tagGroups.get(tag) || 0
          tagGroups.set(tag, count + 1)
        })
      }
    })

    return Array.from(tagGroups.entries()).map(([tag, count]) => ({
      key: tag,
      label: tag,
      count,
      icon: '🏷️',
      type: 'tag'
    }))
  }

  /**
   * 切换分组展开状态
   */
  private toggleGroupExpand(groupKey: string): void {
    if (this.expandedGroups.has(groupKey)) {
      this.expandedGroups.delete(groupKey)
    } else {
      this.expandedGroups.add(groupKey)
    }
  }

  /**
   * 获取分组项数量文本
   */
  private getCountText(count: number): string {
    if (count === 0) return ''
    if (count === 1) return '1张'
    if (count < 100) return `${count}张`
    return `${Math.floor(count / 100)}00+张`
  }

  /**
   * 日期分组组件
   */
  @Builder
  private DateGroupItem(group: GroupOption) {
    Column() {
      // 分组标题
      Row({ space: 8 }) {
        Text(group.label)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text(this.getCountText(group.count))
          .fontSize(12)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8)

        Spacer()

        Button() {
          Text(this.expandedGroups.has(group.key) ? '▲' : '▼')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(24)
        .height(24)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.toggleGroupExpand(group.key))
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .onClick(() => this.onGroupSelect?.(group))

      // 子项（如果是展开的）
      if (this.expandedGroups.has(group.key) && group.subItems) {
        Column() {
          ForEach(group.subItems, (subItem: GroupOption) => {
            Row({ space: 8 }) {
              Text(subItem.label)
                .fontSize(14)
                .fontColor('#666666')
                .layoutWeight(1)

              Text(this.getCountText(subItem.count))
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 28, right: 12, top: 8, bottom: 8 })
            .onClick(() => this.onGroupSelect?.(subItem))
          }
        })
        .width('100%')
        .padding({ left: 16, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#FAFAFA')
      }
    }
    .width('100%')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 工程分组组件
   */
  @Builder
  private ProjectGroupItem(group: GroupOption) {
    Column() {
      // 分组标题
      Row({ space: 8 }) {
        Text(group.icon)
          .fontSize(16)

        Text(group.label)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(this.getCountText(group.count))
          .fontSize(12)
          .fontColor('#666666')
          .backgroundColor('#E8F4FD')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(8)

        Spacer()

        Button() {
          Text(this.expandedGroups.has(group.key) ? '▲' : '▼')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(24)
        .height(24)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.toggleGroupExpand(group.key))
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .onClick(() => this.onGroupSelect?.(group))

      // 子项（如果是展开的）
      if (this.expandedGroups.has(group.key) && group.subItems) {
        Column() {
          ForEach(group.subItems, (subItem: GroupOption) => {
            Row({ space: 8 }) {
              Text(subItem.label)
                .fontSize(14)
                .fontColor('#666666')
                .layoutWeight(1)

              Text(this.getCountText(subItem.count))
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 28, right: 12, top: 8, bottom: 8 })
            .onClick(() => this.onGroupSelect?.(subItem))
          })
        }
        .width('100%')
        .padding({ left: 16, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#FAFAFA')
      }
    }
    .width('100%')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .shadow({
      radius: 4,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 通用分组项
   */
  @Builder
  private GenericGroupItem(group: GroupOption) {
    Row({ space: 12 }) {
      Text(group.icon)
        .fontSize(20)

      Column({ space: 4 }) {
        Text(group.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text(this.getCountText(group.count))
          .fontSize(12)
          .fontColor('#999999')
      }

      Text(this.getCountText(group.count))
        .fontSize(12)
        .fontColor('#666666')
        .backgroundColor(group.type === 'tag' ? '#FFF7E6' : '#F0F0F0')
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(8)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 2,
      color: '#00000008',
      offsetX: 0,
      offsetY: 1
    })
    .onClick(() => this.onGroupSelect?.(group))
  }

  build() {
    Column({ space: 16 }) {
      // 标题栏
      Row() {
        Text('照片分组')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Spacer()

        Button('查看全部')
          .fontSize(14)
          .fontColor(ThemeManager.getCurrentPrimaryColor())
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            // 查看全部照片
          })
      }
      .width('100%')
      .padding({ horizontal: 16, vertical: 12 })

      // 分组列表
      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.getGroupOptions(), (group: GroupOption) => {
            if (group.type === 'date') {
              this.DateGroupItem(group)
            } else if (group.type === 'project') {
              this.ProjectGroupItem(group)
            } else {
              this.GenericGroupItem(group)
            }
          })
        }
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#00000015',
      offsetX: 0,
      offsetY: 4
    })
  }
}