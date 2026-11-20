import { promptAction, window } from '@kit.ArkUI'

export enum RoomToastDuration {
  SHORT = 2000,
  LONG = 3500,
}

export class RoomToast {
  static show(text: string, duration: RoomToastDuration = RoomToastDuration.SHORT): void {
    if (text.trim().length === 0) {
      return
    }
    window.getLastWindow(getContext()).then((target: window.Window) => {
      target.getUIContext().getPromptAction().showToast({
        message: text,
        duration: duration,
        alignment: Alignment.Center,
        showMode: promptAction.ToastShowMode.TOP_MOST,
        backgroundColor: $r('app.color.roomkit_toast_bg'),
        textColor: $r('app.color.roomkit_fg_on_accent'),
        backgroundBlurStyle: BlurStyle.NONE,
      })
    }).catch(() => {
    })
  }
}
