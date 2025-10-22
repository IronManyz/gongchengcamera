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
  @Param onSearch?: (query: string) => void = () => {}
  @Param onChange?: (query: string) => void = () => {}
  @Param onCancel?: () => void = () => {}
  @Param onFocusEvent?: () => void = () => {}
  @Param onBlurEvent?: () => void = () => {}

  @Local private isFocused: boolean = false
  @Local private internalQuery: string = ''

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
      Text('🔍')
        .fontSize(20)
        .fontColor('#999999')
        .margin({ left: 12, right: 8 })

      // 输入框
      TextInput({
        placeholder: this.placeholder,
        text: this.internalQuery
      })
        .fontSize(16)
        .fontColor('#333333')
        .placeholderColor('#999999')
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(40)
        .maxLength(this.maxLength)
        .type(InputType.Normal)
        .caretColor('#007AFF')
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
          this.onFocusEvent?.()
        })
        .onBlur(() => {
          this.isFocused = false
          this.onBlurEvent?.()
        })

      // 清除按钮
      if (this.internalQuery.length > 0) {
        Button() {
          Text('✕')
            .fontSize(16)
            .fontColor('#999999')
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
          .fontColor('#007AFF')
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
    .backgroundColor('#F8F9FA')
    .borderRadius(24)
    .border({
      width: this.isFocused ? 1 : 0,
      color: '#007AFF'
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
  @Param onSearch?: (query: string, filter?: SearchFilter) => void = () => {}
  @Param onChange?: (query: string) => void = () => {}
  @Param onFilterChange?: (filter: SearchFilter | null) => void = () => {}

  @Local private showFilters: boolean = false
  @Local private isFocused: boolean = false

  build() {
    Column() {
      // 主搜索栏
      Row() {
        // 搜索图标
        Text('🔍')
          .fontSize(20)
          .fontColor('#999999')
          .margin({ left: 12, right: 8 })

        // 输入框
        TextInput({
          placeholder: this.placeholder,
          text: this.query
        })
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#999999')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(40)
          .maxLength(100)
          .type(InputType.Normal)
          .caretColor('#007AFF')
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
            Text('⚙')
              .fontSize(20)
              .fontColor(this.selectedFilter ? '#007AFF' : '#999999')
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
            Text('✕')
              .fontSize(16)
              .fontColor('#999999')
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
      .backgroundColor('#F8F9FA')
      .borderRadius(24)
      .border({
        width: this.isFocused ? 1 : 0,
        color: '#007AFF'
      })

      // 筛选选项
      if (this.showFilters && this.filters.length > 0) {
        Column() {
          // 全部选项
          Row() {
            Text('全部')
              .fontSize(14)
              .fontColor(!this.selectedFilter ? '#007AFF' : '#666666')
              .layoutWeight(1)
              .padding(12)
              .onClick(() => {
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
                  .fontColor(this.selectedFilter?.key === filter.key ? '#007AFF' : '#666666')
                  .layoutWeight(1)
                  .padding(12)
                  .onClick(() => {
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
        .backgroundColor('#FFFFFF')
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
  @Require @Param onSuggestionClick: (suggestion: string) => void
  @Require @Param onSearch: (query: string) => void

  @Local private showSuggestions: boolean = false
  @Local private query: string = ''

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
                Text('📋')
                  .fontSize(16)
                  .fontColor('#999999')
                  .margin({ right: 8 })

                Text(suggestion)
                  .fontSize(14)
                  .fontColor('#666666')
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
        .backgroundColor('#FFFFFF')
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
  value?: Object
}