/**
 * 空状态视图组件
 * 提供统一的空状态展示界面
 */

@ComponentV2
export struct EmptyView {
  @Param icon: Resource = $r('app.media.ic_empty')
  @Param title: string = '暂无数据'
  @Param description: string = ''
  @Param showButton: boolean = false
  @Param buttonText: string = '添加'
  @Param onButtonClick?: () => void
  @Param type: EmptyType = EmptyType.DEFAULT

  build() {
    Column() {
      // 空状态图标
      Image(this.icon)
        .width(120)
        .height(120)
        .fillColor(this.getIconColor())
        .margin({ bottom: 16 })

      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 8 })

      // 描述
      if (this.description) {
        Text(this.description)
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
          .textAlign(TextAlign.Center)
          .lineHeight(20)
          .margin({ bottom: 24 })
          .padding({ left: 32, right: 32 })
      }

      // 操作按钮
      if (this.showButton) {
        Button(this.buttonText)
          .fontSize(16)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .padding({ left: 24, right: 24 })
          .height(40)
          .borderRadius(20)
          .onClick(() => {
            this.onButtonClick?.()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
  }

  private getIconColor(): Resource {
    switch (this.type) {
      case EmptyType.SEARCH:
        return $r('app.color.text_tertiary')
      case EmptyType.ERROR:
        return $r('app.color.error')
      case EmptyType.NETWORK:
        return $r('app.color.text_tertiary')
      case EmptyType.PERMISSION:
        return $r('app.color.warning')
      default:
        return $r('app.color.text_tertiary')
    }
  }
}

/**
 * 列表空状态组件
 */
@ComponentV2
export struct ListEmptyView {
  @Param type: ListEmptyType = ListEmptyType.DEFAULT
  @Param onRefresh?: () => void
  @Param onAdd?: () => void

  private getEmptyConfig(): EmptyConfig {
    switch (this.type) {
      case ListEmptyType.PROJECT:
        return {
          icon: $r('app.media.ic_project_empty'),
          title: '暂无项目',
          description: '点击下方按钮创建您的第一个项目',
          buttonText: '创建项目',
          showButton: true,
          onButtonClick: this.onAdd
        }
      case ListEmptyType.PHOTO:
        return {
          icon: $r('app.media.ic_photo_empty'),
          title: '暂无照片',
          description: '开始拍摄第一张工程照片',
          buttonText: '拍照',
          showButton: true,
          onButtonClick: this.onAdd
        }
      case ListEmptyType.SEARCH:
        return {
          icon: $r('app.media.ic_search_empty'),
          title: '未找到相关内容',
          description: '尝试使用其他关键词搜索',
          buttonText: '清空搜索',
          showButton: true,
          onButtonClick: this.onRefresh
        }
      case ListEmptyType.FILTER:
        return {
          icon: $r('app.media.ic_filter_empty'),
          title: '筛选结果为空',
          description: '尝试调整筛选条件',
          buttonText: '重置筛选',
          showButton: true,
          onButtonClick: this.onRefresh
        }
      case ListEmptyType.NETWORK:
        return {
          icon: $r('app.media.ic_network_error'),
          title: '网络连接失败',
          description: '请检查网络连接后重试',
          buttonText: '重试',
          showButton: true,
          onButtonClick: this.onRefresh
        }
      case ListEmptyType.ERROR:
        return {
          icon: $r('app.media.ic_error'),
          title: '出错了',
          description: '加载失败，请重试',
          buttonText: '重试',
          showButton: true,
          onButtonClick: this.onRefresh
        }
      default:
        return {
          icon: $r('app.media.ic_empty'),
          title: '暂无数据',
          description: '',
          buttonText: '刷新',
          showButton: true,
          onButtonClick: this.onRefresh
        }
    }
  }

  build() {
    let config = this.getEmptyConfig()

    EmptyView({
      icon: config.icon,
      title: config.title,
      description: config.description,
      showButton: config.showButton,
      buttonText: config.buttonText,
      onButtonClick: config.onButtonClick,
      type: this.type === ListEmptyType.ERROR ? EmptyType.ERROR :
            this.type === ListEmptyType.NETWORK ? EmptyType.NETWORK : EmptyType.DEFAULT
    })
  }
}

/**
 * 页面空状态组件
 */
@ComponentV2
export struct PageEmptyView {
  @Param type: PageEmptyType = PageEmptyType.DEFAULT
  @Param onAction?: () => void

  private getPageConfig(): EmptyConfig {
    switch (this.type) {
      case PageEmptyType.FIRST_USE:
        return {
          icon: $r('app.media.ic_welcome'),
          title: '欢迎使用工程相机',
          description: '开始管理您的工程项目和照片',
          buttonText: '开始使用',
          showButton: true,
          onButtonClick: this.onAction
        }
      case PageEmptyType.NO_PERMISSION:
        return {
          icon: $r('app.media.ic_permission'),
          title: '需要权限',
          description: '请授予必要权限以使用应用功能',
          buttonText: '授权',
          showButton: true,
          onButtonClick: this.onAction
        }
      case PageEmptyType.NOT_FOUND:
        return {
          icon: $r('app.media.ic_not_found'),
          title: '页面不存在',
          description: '请返回上一页',
          buttonText: '返回',
          showButton: true,
          onButtonClick: this.onAction
        }
      default:
        return {
          icon: $r('app.media.ic_empty'),
          title: '页面空白',
          description: '',
          buttonText: '刷新',
          showButton: true,
          onButtonClick: this.onAction
        }
    }
  }

  build() {
    let config = this.getPageConfig()

    Column() {
      Blank()

      EmptyView({
        icon: config.icon,
        title: config.title,
        description: config.description,
        showButton: config.showButton,
        buttonText: config.buttonText,
        onButtonClick: config.onButtonClick
      })

      Blank()
    }
    .width('100%')
    .height('100%')
  }
}

/**
 * 加载失败视图
 */
@ComponentV2
export struct ErrorView {
  @Param title: string = '加载失败'
  @Param description: string = '请检查网络连接后重试'
  @Param showRetry: boolean = true
  @Param retryText: string = '重试'
  @Param onRetry?: () => void

  build() {
    Column() {
      // 错误图标
      Image($r('app.media.ic_error'))
        .width(80)
        .height(80)
        .fillColor($r('app.color.error'))
        .margin({ bottom: 16 })

      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 8 })

      // 描述
      Text(this.description)
        .fontSize(14)
        .fontColor($r('app.color.text_tertiary'))
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .margin({ bottom: 24 })
        .padding({ left: 32, right: 32 })

      // 重试按钮
      if (this.showRetry) {
        Button(this.retryText)
          .fontSize(16)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .padding({ left: 24, right: 24 })
          .height(40)
          .borderRadius(20)
          .onClick(() => {
            this.onRetry?.()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
  }
}

export enum EmptyType {
  DEFAULT = 'default',
  SEARCH = 'search',
  ERROR = 'error',
  NETWORK = 'network',
  PERMISSION = 'permission'
}

export enum ListEmptyType {
  DEFAULT = 'default',
  PROJECT = 'project',
  PHOTO = 'photo',
  SEARCH = 'search',
  FILTER = 'filter',
  NETWORK = 'network',
  ERROR = 'error'
}

export enum PageEmptyType {
  DEFAULT = 'default',
  FIRST_USE = 'first_use',
  NO_PERMISSION = 'no_permission',
  NOT_FOUND = 'not_found'
}

interface EmptyConfig {
  icon: Resource
  title: string
  description: string
  buttonText: string
  showButton: boolean
  onButtonClick?: () => void
}