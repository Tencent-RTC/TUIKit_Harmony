import { KeyboardAvoidMode } from '@kit.ArkUI'
import { LiveKitResources, LiveKitSafeArea } from '../LiveKitResources'
import { LiveTextInputView } from '../theme/LiveTextInputView'
import { LiveTheme, rgba, white } from '../theme/LiveTheme'
import { LiveToast } from '../theme/LiveToastView'

const characterLimit: number = 200
const inputID: string = 'tuilivekit_barrage_input'

@Component
export struct BarrageInputView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop @Watch('reset') resetToken: number = 0
  onDismiss?: () => void
  onSend?: (text: string) => void
  onPresentationChanged?: (isPresented: boolean) => void
  onHeightChanged?: (height: number) => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @StorageProp(LiveKitSafeArea.keyboardKey) keyboardHeight: number = 0
  @State private text: string = ''
  private focusTask: number = -1
  private hasRequestedFocus: boolean = false
  private previousKeyboardAvoidMode: KeyboardAvoidMode | undefined = undefined

  aboutToAppear(): void {
    this.onPresentedChanged()
  }

  aboutToDisappear(): void {
    this.releaseFocus()
    this.restoreKeyboardAvoidMode()
  }

  private restoreKeyboardAvoidMode(): void {
    if (this.previousKeyboardAvoidMode !== undefined) {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode)
      this.previousKeyboardAvoidMode = undefined
    }
  }

  private releaseFocus(): void {
    clearTimeout(this.focusTask)
    this.focusTask = -1
    if (this.hasRequestedFocus) {
      this.getUIContext().getFocusController().clearFocus()
    }
    this.hasRequestedFocus = false
  }

  private requestInputFocus(): void {
    if (!this.isPresented || this.hasRequestedFocus || this.focusTask !== -1) {
      return
    }
    this.focusTask = setTimeout(() => {
      this.focusTask = -1
      if (this.isPresented) {
        this.hasRequestedFocus = true
        this.getUIContext().getFocusController().requestFocus(inputID)
      }
    }, 0)
  }

  private hasText(): boolean {
    return this.text.trim().length > 0
  }

  private onPresentedChanged(): void {
    this.onPresentationChanged?.(this.isPresented)
    if (this.isPresented) {
      if (this.previousKeyboardAvoidMode === undefined) {
        this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
        // The composer and message list already follow the reported keyboard height.
        this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)
      }
    } else {
      this.releaseFocus()
      this.restoreKeyboardAvoidMode()
    }
  }

  reset(): void {
    this.text = ''
  }

  private send(): void {
    const value = this.text.trim()
    if (value.length === 0) {
      return
    }
    this.onSend?.(value)
    this.text = ''
    this.onDismiss?.()
  }

  build() {
    if (this.isPresented) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column().width('100%').height('100%').onClick(() => this.onDismiss?.())
        Row() {
          Text('×')
            .fontSize(18)
            .fontColor(white(0.58))
            .textAlign(TextAlign.Center)
            .width(22)
            .height(24)
            .margin({ left: 8, right: 6 })
            .hitTestBehavior(HitTestMode.Block)
            .responseRegion({
              x: -11,
              y: -6,
              width: 44,
              height: 36
            })
            .accessibilityText(LiveKitResources.localizedString('tuilivekit.comment.cancel'))
            .onClick(() => this.onDismiss?.())
          LiveTextInputView({
            text: $text,
            placeholder: LiveKitResources.localizedString('tuilivekit.comment.friendly_placeholder'),
            fontSize: 14,
            fontWeight: 600,
            inputLimit: characterLimit,
            maximumLines: 4,
            minimumHeight: 20,
            inputID: inputID,
            enterKey: EnterKeyType.Send,
            onSubmit: () => this.send(),
            onLimitExceeded: () => LiveToast.show(
              LiveKitResources.localizedFormat('tuilivekit.comment.character_limit', characterLimit)),
          })
            .layoutWeight(1)
            .margin({ top: 8, bottom: 8, right: 8 })
          Text(LiveKitResources.localizedString('tuilivekit.common.send'))
            .fontSize(12)
            .fontWeight(600)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(60)
            .height(28)
            .borderRadius(14)
            .linearGradient({
              direction: GradientDirection.RightTop,
              colors: [[LiveTheme.Color.brandBlue, 0], [rgba(0.35, 0.42, 1), 1]]
            })
            .opacity(this.hasText() ? 1 : 0.45)
            .enabled(this.hasText())
            .margin({ right: 6 })
            .onClick(() => this.send())
        }
        .alignItems(VerticalAlign.Center)
        .constraintSize({ minHeight: 36 })
        .onAreaChange((_: Area, area: Area) => {
          this.onHeightChanged?.(area.height as number)
          this.requestInputFocus()
        })
        .margin({ left: 12, right: 12, bottom: (this.keyboardHeight > 0 ? this.keyboardHeight : this.safeBottom) + 4 })
        .backgroundColor(rgba(0.047, 0.051, 0.071, 0.878))
        .borderRadius(18)
        .borderWidth(1)
        .borderColor(white(0.08))
        .shadow({ radius: 14, color: 'rgba(0,0,0,0.3)', offsetY: 9 })
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD])
      .onAppear(() => LiveKitSafeArea.observe())
    }
  }
}
