/**
 * 确认对话框组件
 * 提供统一的确认操作界面
 */

@ComponentV2
export struct ConfirmDialog {
  @Param show: boolean = false
  @Param title: string = '确认'
  @Param message: string = '确定要执行此操作吗？'
  @Param confirmText: string = '确定'
  @Param cancelText: string = '取消'
  @Param showCancel: boolean = true
  @Param danger: boolean = false
  @Param onConfirm?: () => void
  @Param onCancel?: () => void
  @Param onClose?: () => void

  build() {
    if (this.show) {
      Stack() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose?.()
          })

        // 对话框内容
        Column() {
          // 标题
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
            .margin({ top: 24, left: 24, right: 24 })

          // 消息内容
          Text(this.message)
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .margin({ top: 16, left: 24, right: 24 })
            .lineHeight(22)

          // 分割线
          Divider()
            .color($r('app.color.border_default'))
            .margin({ top: 24 })

          // 按钮区域
          Row() {
            // 取消按钮
            if (this.showCancel) {
              Button(this.cancelText)
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(48)
                .onClick(() => {
                  this.onCancel?.()
                  this.onClose?.()
                })
            }

            // 确定按钮
            Button(this.confirmText)
              .fontSize(16)
              .fontColor(this.danger ? $r('app.color.error') : $r('app.color.primary'))
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .height(48)
              .onClick(() => {
                this.onConfirm?.()
                this.onClose?.()
              })
          }
          .width('100%')
        }
        .backgroundColor($r('app.color.dialog_background'))
        .borderRadius(12)
        .margin({ left: 40, right: 40, top: 100, bottom: 100 })
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }
}

/**
 * 删除确认对话框
 */
@ComponentV2
export struct DeleteConfirmDialog {
  @Param show: boolean = false
  @Param title: string = '删除确认'
  @Param message: string = '确定要删除吗？此操作不可恢复。'
  @Param itemName: string = ''
  @Param onConfirm?: () => void
  @Param onCancel?: () => void
  @Param onClose?: () => void

  build() {
    ConfirmDialog({
      show: this.show,
      title: this.title,
      message: this.itemName ? `确定要删除"${this.itemName}"吗？此操作不可恢复。` : this.message,
      confirmText: '删除',
      cancelText: '取消',
      showCancel: true,
      danger: true,
      onConfirm: this.onConfirm,
      onCancel: this.onCancel,
      onClose: this.onClose
    })
  }
}

/**
 * 退出确认对话框
 */
@ComponentV2
export struct ExitConfirmDialog {
  @Param show: boolean = false
  @Param message: string = '确定要退出吗？未保存的更改将会丢失。'
  @Param onConfirm?: () => void
  @Param onCancel?: () => void
  @Param onClose?: () => void

  build() {
    ConfirmDialog({
      show: this.show,
      title: '退出确认',
      message: this.message,
      confirmText: '退出',
      cancelText: '取消',
      showCancel: true,
      danger: false,
      onConfirm: this.onConfirm,
      onCancel: this.onCancel,
      onClose: this.onClose
    })
  }
}

/**
 * 权限确认对话框
 */
@ComponentV2
export struct PermissionConfirmDialog {
  @Param show: boolean = false
  @Param permission: string = ''
  @Param description: string = ''
  @Param onConfirm?: () => void
  @Param onCancel?: () => void
  @Param onClose?: () => void

  build() {
    ConfirmDialog({
      show: this.show,
      title: '权限请求',
      message: this.description || `应用需要${this.permission}权限才能正常工作，是否授权？`,
      confirmText: '授权',
      cancelText: '拒绝',
      showCancel: true,
      danger: false,
      onConfirm: this.onConfirm,
      onCancel: this.onCancel,
      onClose: this.onClose
    })
  }
}