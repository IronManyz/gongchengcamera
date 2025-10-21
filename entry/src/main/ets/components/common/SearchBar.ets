/**
 * 搜索栏组件
 * 提供统一的搜索输入界面
 */

@ComponentV2
export struct SearchBar {
  @Param query: string = ''
  @Param placeholder: string = '搜索...'
  @Param showCancel: boolean = false
  @Param autoFocus: boolean = false
  @Param maxLength: number = 100
  @Param onSearch?: (query: string) => void
  @Param onChange?: (query: string) => void
  @Param onCancel?: () => void
  @Param onFocus?: () => void
  @Param onBlur?: () => void

  @State private isFocused: boolean = false
  @State private internalQuery: string = ''

  aboutToAppear() {
    this.internalQuery = this.query
  }

  @Monitor('query')
  onQueryChange() {
    this.internalQuery = this.query
  }

  build() {
    Row() {
      // 搜索图标
      Image($r('app.media.ic_search'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_tertiary'))
        .margin({ left: 12, right: 8 })

      // 输入框
      TextInput({
        placeholder: this.placeholder,
        text: this.internalQuery
      })
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(40)
        .maxLength(this.maxLength)
        .type(InputType.Normal)
        .caretColor($r('app.color.primary'))
        .enableAutoFill(false)
        .onChange((value: string) => {
          this.internalQuery = value
          this.onChange?.(value)
        })
        .onSubmit(() => {
          this.onSearch?.(this.internalQuery)
        })
        .onFocus(() => {
          this.isFocused = true
          this.onFocus?.()
        })
        .onBlur(() => {
          this.isFocused = false
          this.onBlur?.()
        })

      // 清除按钮
      if (this.internalQuery.length > 0) {
        Button() {
          Image($r('app.media.ic_close'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.text_tertiary'))
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .margin({ right: 8 })
        .onClick(() => {
          this.internalQuery = ''
          this.onChange?.('')
          this.onSearch?.('')
        })
      }

      // 取消按钮
      if (this.showCancel && this.isFocused) {
        Button('取消')
          .fontSize(16)
          .fontColor($r('app.color.primary'))
          .backgroundColor(Color.Transparent)
          .margin({ left: 8, right: 12 })
          .onClick(() => {
            this.internalQuery = ''
            this.onChange?.('')
            this.onCancel?.()
          })
      }
    }
    .width('100%')
    .height(48)
    .backgroundColor($r('app.color.search_background'))
    .borderRadius(24)
    .border({
      width: this.isFocused ? 1 : 0,
      color: $r('app.color.primary')
    })
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }
}

/**
 * 高级搜索栏组件
 */
@ComponentV2
export struct AdvancedSearchBar {
  @Param query: string = ''
  @Param placeholder: string = '搜索...'
  @Param filters: SearchFilter[] = []
  @Param selectedFilter: SearchFilter | null = null
  @Param onSearch?: (query: string, filter?: SearchFilter) => void
  @Param onChange?: (query: string) => void
  @Param onFilterChange?: (filter: SearchFilter | null) => void

  @State private showFilters: boolean = false
  @State private isFocused: boolean = false

  build() {
    Column() {
      // 主搜索栏
      Row() {
        // 搜索图标
        Image($r('app.media.ic_search'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_tertiary'))
          .margin({ left: 12, right: 8 })

        // 输入框
        TextInput({
          placeholder: this.placeholder,
          text: this.query
        })
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(40)
          .maxLength(100)
          .type(InputType.Normal)
          .caretColor($r('app.color.primary'))
          .enableAutoFill(false)
          .onChange((value: string) => {
            this.onChange?.(value)
          })
          .onSubmit(() => {
            this.onSearch?.(this.query, this.selectedFilter || undefined)
          })
          .onFocus(() => {
            this.isFocused = true
          })
          .onBlur(() => {
            this.isFocused = false
          })

        // 筛选按钮
        if (this.filters.length > 0) {
          Button() {
            Image($r('app.media.ic_filter'))
              .width(20)
              .height(20)
              .fillColor(this.selectedFilter ? $r('app.color.primary') : $r('app.color.text_tertiary'))
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .margin({ right: 8 })
          .onClick(() => {
            this.showFilters = !this.showFilters
          })
        }

        // 清除按钮
        if (this.query.length > 0) {
          Button() {
            Image($r('app.media.ic_close'))
              .width(16)
              .height(16)
              .fillColor($r('app.color.text_tertiary'))
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .margin({ right: 8 })
          .onClick(() => {
            this.onChange?.('')
            this.onSearch?.('', this.selectedFilter || undefined)
          })
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.search_background'))
      .borderRadius(24)
      .border({
        width: this.isFocused ? 1 : 0,
        color: $r('app.color.primary')
      })

      // 筛选选项
      if (this.showFilters && this.filters.length > 0) {
        Column() {
          // 全部选项
          Row() {
            Text('全部')
              .fontSize(14)
              .fontColor(!this.selectedFilter ? $r('app.color.primary') : $r('app.color.text_secondary'))
              .layoutWeight(1)
              .padding(12)
              .onClick(() => {
                this.selectedFilter = null
                this.onFilterChange?.(null)
                this.showFilters = false
                this.onSearch?.(this.query)
              })
          }
          .width('100%')

          Divider()

          // 筛选选项列表
          ForEach(
            this.filters,
            (filter: SearchFilter) => {
              Row() {
                Text(filter.label)
                  .fontSize(14)
                  .fontColor(this.selectedFilter?.key === filter.key ? $r('app.color.primary') : $r('app.color.text_secondary'))
                  .layoutWeight(1)
                  .padding(12)
                  .onClick(() => {
                    this.selectedFilter = filter
                    this.onFilterChange?.(filter)
                    this.showFilters = false
                    this.onSearch?.(this.query, filter)
                  })
              }
              .width('100%')
            },
            (filter: SearchFilter) => filter.key
          )
        }
        .width('100%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius(8)
        .margin({ top: 8 })
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetX: 0,
          offsetY: 2
        })
      }
    }
  }
}

/**
 * 快速搜索组件
 */
@ComponentV2
export struct QuickSearch {
  @Param suggestions: string[] = []
  @Param onSuggestionClick?: (suggestion: string) => void
  @Param onSearch?: (query: string) => void

  @State private showSuggestions: boolean = false
  @State private query: string = ''

  build() {
    Column() {
      // 搜索输入
      SearchBar({
        query: this.query,
        placeholder: '快速搜索...',
        onChange: (value: string) => {
          this.query = value
          this.showSuggestions = value.length > 0
        },
        onSearch: (value: string) => {
          this.showSuggestions = false
          this.onSearch?.(value)
        }
      })

      // 搜索建议
      if (this.showSuggestions && this.suggestions.length > 0) {
        Column() {
          ForEach(
            this.suggestions.filter(suggestion =>
              suggestion.toLowerCase().includes(this.query.toLowerCase())
            ).slice(0, 5),
            (suggestion: string) => {
              Row() {
                Image($r('app.media.ic_history'))
                  .width(16)
                  .height(16)
                  .fillColor($r('app.color.text_tertiary'))
                  .margin({ right: 8 })

                Text(suggestion)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(12)
              .onClick(() => {
                this.query = suggestion
                this.showSuggestions = false
                this.onSuggestionClick?.(suggestion)
                this.onSearch?.(suggestion)
              })
            },
            (suggestion: string) => suggestion
          )
        }
        .width('100%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius(8)
        .margin({ top: 8 })
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetX: 0,
          offsetY: 2
        })
      }
    }
  }
}

export interface SearchFilter {
  key: string
  label: string
  value?: any
}