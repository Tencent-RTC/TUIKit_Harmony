import { ParticipantRole, RecordingStatus, RoomParticipantState, RoomParticipantStore, RoomState, RoomStore }
  from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../../base/util/RoomResources'
import { CloudRecordingConfirmMode } from '../CloudRecordingConfirm'

@Component
export struct RoomRecordingButton {
  @Prop roomID: string = ''
  @Prop showsTitle: boolean = true
  onRequestDismiss?: () => void
  onRequestConfirm?: (mode: CloudRecordingConfirmMode) => void
  @State private roomState: RoomState = RoomStore.shared().state
  @State private participantState?: RoomParticipantState = undefined

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomID).state
  }

  private isAvailable(): boolean {
    const role = this.participantState?.localParticipant?.role
    return role === ParticipantRole.owner || role === ParticipantRole.admin
  }

  private isRecording(): boolean {
    const room = this.roomState.currentRoom
    return room?.roomID === this.roomID && room.recordingInfo.status === RecordingStatus.recording
  }

  build() {
    if (this.isAvailable()) {
      Column({ space: this.showsTitle ? 7 : 0 }) {
        Stack() {
          Image(RoomResources.image(this.isRecording() ? 'roomkit_icon_recording' : 'roomkit_icon_record'))
            .width(this.showsTitle ? 21 : 20)
            .height(this.showsTitle ? 21 : 20)
        }
        .width(this.showsTitle ? 46 : 44)
        .height(this.showsTitle ? 46 : 44)
        .borderRadius(this.showsTitle ? 23 : 22)
        .backgroundColor($r('app.color.roomkit_bg_hover'))
        if (this.showsTitle) {
          Text(RoomResources.string(this.isRecording() ? 'roomkit_cloud_recording_stop_confirm' :
            'roomkit_cloud_recording_record_label'))
            .fontSize(11)
            .fontColor($r('app.color.roomkit_fg_secondary'))
            .textAlign(TextAlign.Center)
        }
      }
      .onClick(() => {
        if (!this.isAvailable()) {
          return
        }
        this.onRequestDismiss?.()
        this.onRequestConfirm?.(this.isRecording() ? CloudRecordingConfirmMode.STOP : CloudRecordingConfirmMode.START)
      })
    }
  }
}
