import { ComponentContent, window } from '@kit.ArkUI'
import { LiveText } from './LiveText'
import { LiveTheme, rgba, white } from './LiveTheme'

class ToastParams {
  text: string

  constructor(text: string) {
    this.text = text
  }
}

@Builder
function liveToastView(params: ToastParams) {
  Column() {
    Text(params.text)
      .attributeModifier(new LiveText(LiveTheme.TextRole.sectionTitle, LiveTheme.TextTone.primary, TextAlign.Center, false, 16))
      .wordBreak(WordBreak.BREAK_WORD)
      .padding({ left: 16, right: 16, top: 9, bottom: 9 })
      .constraintSize({ minHeight: 34 })
      .borderRadius(17)
      .borderWidth(1)
      .borderColor(white(0.08))
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [[rgba(0.02, 0.16, 0.39, 0.92), 0], [rgba(0.10, 0.28, 0.49, 0.90), 0.5], [rgba(0.20, 0.39, 0.50, 0.88), 1]],
      })
      .shadow({ radius: 24, color: rgba(0, 0.32, 0.85, 0.4), offsetY: 8 })
      .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
  }
  .width('100%')
  .height('100%')
  .padding({ left: 24, right: 24 })
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .hitTestBehavior(HitTestMode.None)
}

export class LiveToast {
  private static current?: LiveToast
  private uiContext?: UIContext
  private view?: ComponentContent<ToastParams>
  private dismissTask: number = -1
  private isDismissed: boolean = false

  private constructor() {
  }

  static show(text: string, duration: number = 2): LiveToast {
    const handle = new LiveToast()
    if (text.trim().length === 0) {
      return handle
    }
    window.getLastWindow(getContext()).then((target: window.Window) => {
      if (handle.isDismissed) {
        return
      }
      LiveToast.current?.dismiss()
      const uiContext = target.getUIContext()
      handle.uiContext = uiContext
      handle.view = new ComponentContent(uiContext, wrapBuilder(liveToastView), new ToastParams(text))
      uiContext.getOverlayManager().addComponentContent(handle.view, 10000)
      LiveToast.current = handle
      const seconds = Number.isFinite(duration) && duration > 0 ? duration : 2
      handle.dismissTask = setTimeout(() => handle.dismiss(), seconds * 1000)
    }).catch(() => {
    })
    return handle
  }

  dismiss(): void {
    this.isDismissed = true
    clearTimeout(this.dismissTask)
    if (this.view !== undefined) {
      this.uiContext?.getOverlayManager().removeComponentContent(this.view)
      this.view.dispose()
      this.view = undefined
    }
    if (LiveToast.current === this) {
      LiveToast.current = undefined
    }
  }
}
