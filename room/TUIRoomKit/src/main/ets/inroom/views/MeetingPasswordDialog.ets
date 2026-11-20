import { RoomDialog } from '../../base/dialog/RoomDialog'
import { RoomResources } from '../../base/util/RoomResources'

const passwordInputID: string = 'roomkit_meeting_password_input'

@Component
export struct MeetingPasswordDialog {
  @Prop @Watch('onPresentationChanged') isPresented: boolean = false
  @Prop wrongPassword: boolean = false
  onSubmit?: (password: string) => void
  onCancel?: () => void
  @State private password: string = ''
  @State private plainText: boolean = false
  @State private errorMessage: string = ''

  private onPresentationChanged(): void {
    if (this.isPresented) {
      this.password = ''
      this.errorMessage = this.wrongPassword ? RoomResources.string('roomkit_room_entry_wrong_password') : ''
    }
  }

  private submit(): void {
    const password = this.password.trim()
    if (password.length !== 6) {
      this.errorMessage = RoomResources.string('roomkit_join_password_placeholder')
      return
    }
    this.onSubmit?.(password)
  }

  build() {
    RoomDialog({
      isPresented: this.isPresented,
      title: RoomResources.string('roomkit_room_entry_password_title'),
      primaryText: RoomResources.string('roomkit_room_common_confirm'),
      secondaryText: RoomResources.string('roomkit_room_common_cancel'),
      cancelable: false,
      keepsOpenOnPrimary: true,
      inputFocusID: passwordInputID,
      onPrimary: () => this.submit(),
      onSecondary: () => this.onCancel?.(),
      onDismiss: () => this.onCancel?.(),
    }) {
      Column() {
        Row() {
          TextInput({ text: $$this.password, placeholder: RoomResources.string('roomkit_join_password_placeholder') })
            .id(passwordInputID)
            .layoutWeight(1)
            .fontSize(15)
            .fontColor($r('app.color.roomkit_fg_primary'))
            .placeholderFont({ size: 15 })
            .placeholderColor($r('app.color.roomkit_fg_tertiary'))
            .maxLength(6)
            .inputFilter('[0-9]')
            .type(this.plainText ? InputType.Number : InputType.Password)
            .backgroundColor(Color.Transparent)
            .onChange(() => this.errorMessage = '')
            .onSubmit(() => this.submit())
          Button() {
            Image(RoomResources.image(this.plainText ? 'roomkit_icon_eye' : 'roomkit_icon_eye_off'))
              .width(20)
              .height(20)
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.plainText = !this.plainText)
        }
        .width('100%')
        .height(44)
        .padding({ left: 12, right: 6 })
        .border({ width: 1, color: this.errorMessage.length > 0 ? $r('app.color.roomkit_danger') :
          $r('app.color.roomkit_border_strong') })
        .borderRadius(8)
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .width('100%')
            .fontSize(12)
            .fontColor($r('app.color.roomkit_danger'))
            .margin({ top: 6 })
        }
      }
    }
  }
}
