import { window } from '@kit.ArkUI'
import { MeetingView } from 'tuiroomkit'

@Component
export struct RoomMainPage {
  @Prop roomID: string = ''
  @Prop roomName: string = ''
  @Prop isCreate: boolean = false
  @Prop autoEnableMicrophone: boolean = false
  @Prop autoEnableCamera: boolean = false
  @Prop autoEnableSpeaker: boolean = false
  onClose?: () => void
  private target?: window.Window
  private previousKeepScreenOn?: boolean

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((target: window.Window) => {
      this.target = target
      this.previousKeepScreenOn = target.getWindowProperties().isKeepScreenOn
      target.setWindowKeepScreenOn(true)
    }).catch(() => {
    })
  }

  aboutToDisappear(): void {
    if (this.target !== undefined && this.previousKeepScreenOn !== undefined) {
      this.target.setWindowKeepScreenOn(this.previousKeepScreenOn)
    }
  }

  build() {
    MeetingView({ roomID: this.roomID, roomName: this.roomName, isCreate: this.isCreate,
      autoEnableMicrophone: this.autoEnableMicrophone, autoEnableCamera: this.autoEnableCamera,
      autoEnableSpeaker: this.autoEnableSpeaker, onClose: () => this.onClose?.() })
  }
}
