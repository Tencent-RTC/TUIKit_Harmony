import { DeviceStore } from '@tencentcloud/atomicxcore'
import { RoomDialog, RoomDialogVariant } from '../../../base/dialog/RoomDialog'
import { RoomResources } from '../../../base/util/RoomResources'

export enum RoomScreenShareConfirmMode {
  START,
  STOP,
}

@Component
export struct RoomScreenShareConfirm {
  @Prop isPresented: boolean = false
  @Prop mode: RoomScreenShareConfirmMode = RoomScreenShareConfirmMode.START
  onDismiss?: () => void

  build() {
    RoomDialog({
      isPresented: this.isPresented,
      title: RoomResources.string(this.mode === RoomScreenShareConfirmMode.START ?
        'roomkit_screen_share_safety_title' : 'roomkit_screen_share_stop_title'),
      message: RoomResources.string(this.mode === RoomScreenShareConfirmMode.START ?
        'roomkit_screen_share_safety_message' : 'roomkit_screen_share_stop_message'),
      primaryText: RoomResources.string(this.mode === RoomScreenShareConfirmMode.START ?
        'roomkit_screen_share_continue' : 'roomkit_screen_share_stop_confirm'),
      primaryVariant: this.mode === RoomScreenShareConfirmMode.STOP ?
        RoomDialogVariant.DANGER : RoomDialogVariant.PRIMARY,
      secondaryText: RoomResources.string('roomkit_room_common_cancel'),
      onPrimary: () => {
        if (this.mode === RoomScreenShareConfirmMode.START) {
          DeviceStore.shared().startScreenShare()
        } else {
          DeviceStore.shared().stopScreenShare()
        }
      },
      onDismiss: () => this.onDismiss?.(),
    })
  }
}
