import { ThemeState } from '../theme/ThemeState'
import { BusinessError } from '@kit.BasicServicesKit'
import { ComponentContent, promptAction } from '@kit.ArkUI'
import { UIContext } from '@ohos.arkui.UIContext'
interface SingleButtonAlertDialogParams {
  message?: string | Resource
  confirmText?: string | Resource
  onDismiss?: () => void
  onConfirm?: () => void
  dialogId?: string
}
interface DoubleButtonAlertDialogParams {
  title?: string | Resource
  message?: string | Resource
  cancelText?: string | Resource
  confirmText?: string | Resource
  onDismiss?: () => void
  onCancel?: () => void
  onConfirm?: () => void
  dialogId?: string
}
@Component
struct SingleButtonAlertDialog {
  @Prop message?: string | Resource
  @Prop confirmText: string | Resource = 'Done'
  onDismiss?: () => void
  onConfirm?: () => void
  @Prop dialogId?: string
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()

  build() {
    Column() {
      
      Column() {
        if (this.message) {
          Text(this.message)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
            .lineHeight(24)
            .width('100%')
        }
      }
      .width('100%')
      .constraintSize({
        minHeight: 88,
        maxHeight: 424
      })
      .padding({
        left: 24,
        right: 24,
        top: 32,
        bottom: 20
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)

      
      Column() {
        // Divider
        Row()
          .width('100%')
          .height(0.5)
          .backgroundColor(this.themeState.colors.strokeColorModule)

        
        Text(this.confirmText)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeState.colors.textColorLink)
          .textAlign(TextAlign.Center)
          .lineHeight(24)
          .width('100%')
          .height(56)
          .padding({
            top: 16,
            bottom: 16,
            left: 20,
            right: 20
          })
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm()
            }
            if (this.onDismiss) {
              this.onDismiss()
            }
            AlertDialog.closeDialog(this.dialogId)
          })
      }
      .width('100%')
    }
    .width(327)
    .constraintSize({
      minHeight: 134,
      maxHeight: 480
    })
    .backgroundColor(this.themeState.colors.bgColorDialog)
    .borderRadius(20)
    .alignItems(HorizontalAlign.Center)
  }
}
@Component
struct DoubleButtonAlertDialog {
  @Prop title?: string | Resource
  @Prop message?: string | Resource
  @Prop cancelText: string | Resource = 'cancel'
  @Prop confirmText: string | Resource = 'confirm'
  onDismiss?: () => void
  onCancel?: () => void
  onConfirm?: () => void
  @Prop dialogId?: string
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()

  build() {
    Column() {
      
      Column() {
        if (this.title) {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
            .lineHeight(26)
            .width('100%')

          if (this.message) {
            Row().height(12) // Spacer
          }
        }

        if (this.message) {
          Text(this.message)
            .fontSize(16)
            .fontWeight(FontWeight.Normal)
            .fontColor(this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
            .lineHeight(24)
            .width('100%')
        }
      }
      .width('100%')
      .constraintSize({
        minHeight: 134,
        maxHeight: 424
      })
      .padding({
        left: 24,
        right: 24,
        top: 32,
        bottom: 20
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      
      Column() {
        // Divider
        Row()
          .width('100%')
          .height(0.5)
          .backgroundColor(this.themeState.colors.strokeColorModule)

        
        Row() {
          
          Text(this.cancelText)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
            .lineHeight(24)
            .width('50%')
            .height(56)
            .padding({
              top: 16,
              bottom: 16,
              left: 20,
              right: 20
            })
            .onClick(() => {
              if (this.onCancel) {
                this.onCancel()
              }
              if (this.onDismiss) {
                this.onDismiss()
              }
              AlertDialog.closeDialog(this.dialogId)
            })

          
          Row()
            .width(0.5)
            .height(56)
            .backgroundColor(this.themeState.colors.strokeColorModule)

          
          Text(this.confirmText)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeState.colors.textColorLink)
            .textAlign(TextAlign.Center)
            .lineHeight(24)
            .width('50%')
            .height(56)
            .padding({
              top: 16,
              bottom: 16,
              left: 20,
              right: 20
            })
            .onClick(() => {
              if (this.onConfirm) {
                this.onConfirm()
              }
              if (this.onDismiss) {
                this.onDismiss()
              }
              AlertDialog.closeDialog(this.dialogId)
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(56)
    }
    .width(327)
    .constraintSize({
      minHeight: 190,
      maxHeight: 480
    })
    .backgroundColor(this.themeState.colors.bgColorDialog)
    .borderRadius(20)
    .alignItems(HorizontalAlign.Center)
  }
}
@Component
struct SingleButtonAlertDialogComponent {
  @Prop message?: string | Resource
  @Prop confirmText: string | Resource = 'Done'
  onDismiss?: () => void
  onConfirm?: () => void
  @Prop dialogId?: string

  build() {
    SingleButtonAlertDialog({
      message: this.message,
      confirmText: this.confirmText,
      onDismiss: this.onDismiss,
      onConfirm: this.onConfirm,
      dialogId: this.dialogId
    })
  }
}

@Component
struct DoubleButtonAlertDialogComponent {
  @Prop title?: string | Resource
  @Prop message?: string | Resource
  @Prop cancelText: string | Resource = 'Cancel'
  @Prop confirmText: string | Resource = 'Done'
  onDismiss?: () => void
  onCancel?: () => void
  onConfirm?: () => void
  @Prop dialogId?: string

  build() {
    DoubleButtonAlertDialog({
      title: this.title,
      message: this.message,
      cancelText: this.cancelText,
      confirmText: this.confirmText,
      onDismiss: this.onDismiss,
      onCancel: this.onCancel,
      onConfirm: this.onConfirm,
      dialogId: this.dialogId
    })
  }
}
@Builder
function SingleButtonAlertDialogBuilder(params: SingleButtonAlertDialogParams) {
  SingleButtonAlertDialogComponent({
    message: params.message,
    confirmText: params.confirmText ?? 'Done',
    onDismiss: params.onDismiss,
    onConfirm: params.onConfirm,
    dialogId: params.dialogId
  })
}

@Builder
function DoubleButtonAlertDialogBuilder(params: DoubleButtonAlertDialogParams) {
  DoubleButtonAlertDialogComponent({
    title: params.title,
    message: params.message,
    cancelText: params.cancelText ?? 'Cancel',
    confirmText: params.confirmText ?? 'Done',
    onDismiss: params.onDismiss,
    onCancel: params.onCancel,
    onConfirm: params.onConfirm,
    dialogId: params.dialogId
  })
}
export class AlertDialog {
  private static dialogMap: Map<string, ComponentContent<SingleButtonAlertDialogParams | DoubleButtonAlertDialogParams>> =
    new Map()
  private static dialogIdList: string[] = []
  private static ctx: UIContext
  private static idCounter: number = 0

  
  static show(
    message?: string | Resource,
    confirmText?: string | Resource,
    onDismiss?: () => void,
    onConfirm?: () => void,
    context?: UIContext
  ): string
  
  static show(
    title?: string | Resource,
    message?: string | Resource,
    cancelText?: string | Resource,
    confirmText?: string | Resource,
    onDismiss?: () => void,
    onCancel?: () => void,
    onConfirm?: () => void,
    context?: UIContext
  ): string
  static show(
    param1?: string | Resource,
    param2?: string | Resource,
    param3?: string | Resource | (() => void),
    param4?: string | Resource | (() => void),
    param5?: (() => void) | UIContext,
    param6?: (() => void) | UIContext,
    param7?: (() => void),
    param8?: UIContext
  ): string {
    
    if (arguments.length <= 5) {
      
      const message = param1
      const confirmText = param2
      const onDismiss = typeof param3 === 'function' ? param3 : undefined
      const onConfirm = typeof param4 === 'function' ? param4 : (typeof param3 === 'function' ? param3 : undefined)
      const context = (param5 && typeof param5 !== 'function') ? param5 as UIContext : undefined

      return AlertDialog.showSingleButton(message, confirmText, onDismiss, onConfirm, context)
    } else {
      
      const title = param1
      const message = param2
      const cancelText = (typeof param3 === 'string' || typeof param3 === 'object') ? param3 as (string | Resource) : undefined
      const confirmText = (typeof param4 === 'string' || typeof param4 === 'object') ? param4 as (string | Resource) : undefined
      const onDismiss = typeof param5 === 'function' ? param5 : undefined
      const onCancel = typeof param6 === 'function' ? param6 : undefined
      const onConfirm = typeof param7 === 'function' ? param7 : undefined
      const context = param8 as UIContext

      return AlertDialog.showDoubleButton(title, message, cancelText, confirmText, onDismiss, onCancel, onConfirm, context)
    }
  }

  
  private static generateId(): string {
    return `alert_${++AlertDialog.idCounter}`
  }

  
  private static showSingleButton(
    message?: string | Resource,
    confirmText?: string | Resource,
    onDismiss?: () => void,
    onConfirm?: () => void,
    context?: UIContext
  ): string {
    if (context) {
      AlertDialog.ctx = context
    }
    if (!AlertDialog.ctx) {
      console.error('AlertDialog: UIContext not initialized, please pass context parameter.')
      return ''
    }

    const id = AlertDialog.generateId()

    const params: SingleButtonAlertDialogParams = {
      message: message,
      confirmText: confirmText ?? 'Done',
      onDismiss: onDismiss,
      onConfirm: onConfirm ?? onDismiss,
      dialogId: id
    }

    const contentNode = new ComponentContent(
      AlertDialog.ctx,
      wrapBuilder(SingleButtonAlertDialogBuilder),
      params
    )

    AlertDialog.dialogMap.set(id, contentNode)
    AlertDialog.dialogIdList.push(id)

    const options: promptAction.BaseDialogOptions = {
      alignment: DialogAlignment.Center,
      autoCancel: false,
      maskColor: 'rgba(0, 0, 0, 0.6)'
    }

    AlertDialog.ctx.getPromptAction()
      .openCustomDialog(contentNode, options)
      .then(() => {
        console.info('SingleButtonAlertDialog openCustomDialog complete.')
      })
      .catch((error: BusinessError) => {
        let message = (error as BusinessError).message
        let code = (error as BusinessError).code
        console.error(`SingleButtonAlertDialog openCustomDialog error code is ${code}, message is ${message}`)
        AlertDialog.dialogMap.delete(id)
        AlertDialog.removeFromList(id)
      })

    return id
  }

  
  private static showDoubleButton(
    title?: string | Resource,
    message?: string | Resource,
    cancelText?: string | Resource,
    confirmText?: string | Resource,
    onDismiss?: () => void,
    onCancel?: () => void,
    onConfirm?: () => void,
    context?: UIContext
  ): string {
    if (context) {
      AlertDialog.ctx = context
    }
    if (!AlertDialog.ctx) {
      console.error('AlertDialog: UIContext not initialized, please pass context parameter.')
      return ''
    }

    const id = AlertDialog.generateId()

    const params: DoubleButtonAlertDialogParams = {
      title: title,
      message: message,
      cancelText: cancelText ?? 'Cancel',
      confirmText: confirmText ?? 'Done',
      onDismiss: onDismiss,
      onCancel: onCancel,
      onConfirm: onConfirm,
      dialogId: id
    }

    const contentNode = new ComponentContent(
      AlertDialog.ctx,
      wrapBuilder(DoubleButtonAlertDialogBuilder),
      params
    )

    AlertDialog.dialogMap.set(id, contentNode)
    AlertDialog.dialogIdList.push(id)

    const options: promptAction.BaseDialogOptions = {
      alignment: DialogAlignment.Center,
      autoCancel: false,
      maskColor: 'rgba(0, 0, 0, 0.6)'
    }

    AlertDialog.ctx.getPromptAction()
      .openCustomDialog(contentNode, options)
      .then(() => {
        console.info('DoubleButtonAlertDialog openCustomDialog complete.')
      })
      .catch((error: BusinessError) => {
        let message = (error as BusinessError).message
        let code = (error as BusinessError).code
        console.error(`DoubleButtonAlertDialog openCustomDialog error code is ${code}, message is ${message}`)
        AlertDialog.dialogMap.delete(id)
        AlertDialog.removeFromList(id)
      })

    return id
  }

  
  static closeDialog(dialogId?: string): void {
    const id = dialogId ?? AlertDialog.dialogIdList[AlertDialog.dialogIdList.length - 1]
    if (id) {
      AlertDialog.removeDialog(id)
    }
  }

  static closeAllDialogs(): void {
    const ids = [...AlertDialog.dialogIdList]
    for (const id of ids) {
      AlertDialog.removeDialog(id)
    }
  }

  
  private static removeDialog(id: string): void {
    const contentNode = AlertDialog.dialogMap.get(id)
    if (!contentNode) {
      return
    }
    AlertDialog.dialogMap.delete(id)
    AlertDialog.removeFromList(id)
    if (AlertDialog.ctx) {
      AlertDialog.ctx.getPromptAction()
        .closeCustomDialog(contentNode)
        .then(() => {
          console.info('AlertDialog closeCustomDialog complete.')
        })
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message
          let code = (error as BusinessError).code
          console.error(`AlertDialog closeCustomDialog error code is ${code}, message is ${message}`)
        })
    }
  }

  private static removeFromList(id: string): void {
    const index = AlertDialog.dialogIdList.indexOf(id)
    if (index >= 0) {
      AlertDialog.dialogIdList.splice(index, 1)
    }
  }
}
export default AlertDialog
