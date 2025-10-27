/**
 * 照片搜索管理组件
 * 提供按关键词、标签、时间的搜索功能
 */

import { ThemeManager } from '../../theme/ThemeManager'
import { Photo } from '../../models/Photo'

export interface SearchFilter {
  keyword?: string
  tags?: string[]
  dateRange?: { start: Date, end: Date }
  projectIds?: string[]
  siteIds?: string[]
}

export interface SearchResult {
  photos: Photo[]
  totalCount: number
  hasMore: boolean
}

export interface SearchSuggestion {
  id: string
  text: string
  type: 'keyword' | 'tag' | 'date' | 'project' | 'site'
  icon?: string
  count?: number
}

@ComponentV2
export struct PhotoSearchManager {
  @Param onFilterChange?: (filter: SearchFilter) => void
  @Param onSearch?: (result: SearchResult) => void

  @State private searchQuery: string = ''
  @State private showAdvancedSearch: boolean = false
  @State private selectedTags: string[] = []
  @State private dateRange: { start: Date, end: Date } = { start: new Date(), end: new Date() }
  @State private suggestions: SearchSuggestion[] = []
  @State private searchHistory: string[] = []
  @State private isSearching: boolean = false

  private readonly quickTags = [
    '质量问题', '安全检查', '进度记录', '验收通过',
    '材料进场', '施工照片', '完成报告', '设备调试',
    '人员签到', '安全会议', '技术交底', '变更申请'
  ]

  private readonly dateRanges = [
    { label: '今天', value: 1 },
    { label: '昨天', value: 2 },
    { label: '本周', value: 3 },
    { label: '本月', value: 4 },
    { label: '近三月', value: 5 },
    { label: '本年', value: 6 },
    { label: '自定义', value: 0 }
  ]

  /**
   * 获取搜索建议
   */
  private getSearchSuggestions(): SearchSuggestion[] {
    const suggestions: SearchSuggestion[] = []

    // 搜索历史建议
    this.searchHistory.forEach((query, index) => {
      suggestions.push({
        id: `history_${index}`,
        text: query,
        type: 'keyword',
        icon: '🕐'
      })
    })

    // 标签建议
    if (this.searchQuery) {
      this.quickTags.forEach(tag => {
        if (tag.toLowerCase().includes(this.searchQuery.toLowerCase())) {
          suggestions.push({
            id: tag,
            text: tag,
            type: 'tag',
            icon: '🏷️'
          })
        }
      })
    }

    // 快速日期范围建议
    if (this.searchQuery.toLowerCase().includes('日期') ||
        this.searchQuery.toLowerCase().includes('今天') ||
        this.searchQuery.toLowerCase().includes('昨天')) {
      this.dateRanges.forEach(range => {
        if (range.label.toLowerCase().includes(this.searchQuery.toLowerCase())) {
          suggestions.push({
            id: range.label,
            text: range.label,
            type: 'date',
            icon: '📅'
          })
        }
      })
    }

    return suggestions.slice(0, 8)
  }

  /**
   * 执行搜索
   */
  private async performSearch(): Promise<void> {
    if (!this.searchQuery.trim()) {
      return
    }

    this.isSearching = true

    try {
      const filter: SearchFilter = {
        keyword: this.searchQuery,
        tags: this.selectedTags,
        dateRange: this.dateRange.start && this.dateRange.end ? this.dateRange : undefined,
        projectIds: undefined,
        siteIds: undefined
      }

      // 调用搜索回调
      this.onSearch?.({
        photos: [], // 这里应该调用实际的搜索逻辑
        totalCount: 0,
        hasMore: false
      })

      // 添加到搜索历史
      if (!this.searchHistory.includes(this.searchQuery)) {
        this.searchHistory = [this.searchQuery, ...this.searchHistory.slice(0, 9)]
      }

    } catch (error) {
      console.error('搜索失败:', error)
    } finally {
      this.isSearching = false
    }
  }

  /**
   * 清除搜索
   */
  private clearSearch(): void {
    this.searchQuery = ''
    this.selectedTags = []
    this.suggestions = []
  }

  /**
   * 应用搜索建议
   */
  private applySuggestion(suggestion: SearchSuggestion): void {
    if (suggestion.type === 'keyword') {
      this.searchQuery = suggestion.text
    } else if (suggestion.type === 'tag') {
      this.selectedTags = [suggestion.text]
    }
    this.suggestions = []
    this.performSearch()
  }

  /**
   * 搜索输入栏
   */
  @Builder
  private SearchInputBar() {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        // 搜索输入框
        Row({ space: 8 }) {
          TextInput({
            placeholder: '搜索照片、标签、日期...',
            text: this.searchQuery
          })
          .width('100%')
          .height(40)
          .fontSize(14)
          .fontColor('#333333')
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .border({ width: 1, color: '#E0E0E0' })
          .padding({ left: 16, right: 8 })
          .onChange((value: string) => {
            this.searchQuery = value
            this.suggestions = this.getSearchSuggestions()
          })
          .onSubmit(() => {
            this.performSearch()
          })

          // 清除按钮
          if (this.searchQuery) {
            Button('✕')
              .fontSize(16)
              .fontColor('#999999')
              .backgroundColor(Color.Transparent)
              .width(32)
              .height(32)
              .onClick(() => this.clearSearch())
          }
        }

        // 搜索按钮
        Button() {
          Text('🔍')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(ThemeManager.getCurrentPrimaryColor())
        .borderRadius(20)
        .onClick(() => this.performSearch())
      }
    }
    .width('100%')

    // 高级搜索切换
    Row() {
      Blank()

      Button(this.showAdvancedSearch ? '收起' : '高级搜索')
        .fontSize(14)
        .fontColor('#666666')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showAdvancedSearch = !this.showAdvancedSearch
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ right: 16 })
  }

  /**
   * 快速标签选择
   */
  @Builder
  private QuickTagSelector() {
    Column({ space: 12 }) {
      Text('快速标签')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.quickTags, (tag: string) => {
            Button(tag)
              .fontSize(12)
              .fontColor(
                this.selectedTags.includes(tag) ? '#FFFFFF' : '#333333'
              )
              .backgroundColor(
                this.selectedTags.includes(tag) ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5'
              )
              .borderRadius(16)
              .padding({ left: 12, right: 12 })
              .border({
                width: 1,
                color: this.selectedTags.includes(tag) ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
              })
              .onClick(() => {
                if (this.selectedTags.includes(tag)) {
                  this.selectedTags = this.selectedTags.filter(t => t !== tag)
                } else {
                  this.selectedTags.push(tag)
                }
              })
          })
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 日期范围选择器
   */
  @Builder
  private DateRangeSelector() {
    Column({ space: 12 }) {
      Text('日期范围')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Grid() {
        ForEach(this.dateRanges, (range) => {
          GridItem() {
            Button(range.label)
              .fontSize(12)
              .fontColor(
                this.dateRange.value === range.value ? '#FFFFFF' : '#333333'
              )
              .backgroundColor(
                this.dateRange.value === range.value ? ThemeManager.getCurrentPrimaryColor() : '#F5F5F5'
              )
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .border({
                width: 1,
                color: this.dateRange.value === range.value ? ThemeManager.getCurrentPrimaryColor() : '#E0E0E0'
              })
              .onClick(() => {
                if (range.value === 0) {
                  // 自定义日期范围
                  this.showCustomDatePicker()
                } else {
                  const today = new Date()
                  const days = range.value
                  const startDate = new Date(today.getTime() - (days * 24 * 60 * 60 * 1000))
                  this.dateRange = { start: startDate, end: today }
                }
              })
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 搜索建议列表
   */
  @Builder
  private SearchSuggestions() {
    if (this.suggestions.length > 0) {
      Column({ space: 4 }) {
        ForEach(this.suggestions, (suggestion: SearchSuggestion) => {
          Row({ space: 8 }) {
            Text(suggestion.icon || '🔍')
              .fontSize(16)

            Text(suggestion.text)
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)

            if (suggestion.count) {
              Text(`${suggestion.count}`)
                .fontSize(12)
                .fontColor('#999999')
            }
          }
          .width('100%')
          .padding(12)
          .borderRadius(8)
          .backgroundColor('#F8F9FA')
          .onClick(() => this.applySuggestion(suggestion))
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
  }

  /**
   * 搜索状态指示器
   */
  @Builder
  private SearchIndicator() {
    if (this.isSearching) {
      Row({ space: 8 }) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color(ThemeManager.getCurrentPrimaryColor())

        Text('搜索中...')
          .fontSize(14)
          .fontColor('#666666')
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }

  build() {
    Column({ space: 16 }) {
      this.SearchInputBar()

      if (this.showAdvancedSearch) {
        Column({ space: 16 }) {
          this.QuickTagSelector()
          this.DateRangeSelector()
        }
      }

      this.SearchSuggestions()

      if (this.isSearching) {
        this.SearchIndicator()
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#00000010',
      offsetX: 0,
      offsetY: 4
    })
  }

  /**
   * 显示自定义日期选择器
   */
  private showCustomDatePicker(): void {
    // 这里可以显示一个自定义的日期选择器
    console.log('显示自定义日期选择器')
  }
}