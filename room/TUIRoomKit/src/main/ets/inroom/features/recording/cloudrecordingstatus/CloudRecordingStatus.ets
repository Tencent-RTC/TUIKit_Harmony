import { ParticipantRole, RecordingStatus, RoomParticipantState, RoomParticipantStore, RoomState, RoomStore }
  from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../../base/util/RoomResources'
import { CloudRecordingConfirm, CloudRecordingConfirmMode } from '../CloudRecordingConfirm'

@Component
export struct CloudRecordingStatus {
  @Prop roomID: string = ''
  @State private roomState: RoomState = RoomStore.shared().state
  @State private participantState?: RoomParticipantState = undefined
  @State private dotOpacity: number = 1
  @State private isStopPresented: boolean = false
  private pulseTimer: number = -1

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomID).state
    this.pulseTimer = setInterval(() => {
      if (this.isRecording()) {
        this.dotOpacity = this.dotOpacity === 1 ? 0.35 : 1
      } else if (this.dotOpacity !== 1) {
        this.dotOpacity = 1
      }
    }, 600)
  }

  aboutToDisappear(): void {
    clearInterval(this.pulseTimer)
  }

  private isRecording(): boolean {
    const room = this.roomState.currentRoom
    return room?.roomID === this.roomID && room.recordingInfo.status === RecordingStatus.recording
  }

  private canManage(): boolean {
    const role = this.participantState?.localParticipant?.role
    return role === ParticipantRole.owner || role === ParticipantRole.admin
  }

  @Builder
  stopConfirm() {
    CloudRecordingConfirm({
      roomID: this.roomID,
      mode: CloudRecordingConfirmMode.STOP,
      isPresented: this.isStopPresented,
      onDismiss: () => this.isStopPresented = false,
    })
  }

  build() {
    Stack() {
      Row({ space: 6 }) {
        Column()
          .width(6)
          .height(6)
          .borderRadius(3)
          .backgroundColor($r('app.color.roomkit_danger'))
          .opacity(this.dotOpacity)
          .animation({ duration: 600 })
        Text(RoomResources.string('roomkit_cloud_recording_recording_label'))
          .fontSize(12)
          .fontColor($r('app.color.roomkit_danger'))
      }
      .visibility(this.isRecording() ? Visibility.Visible : Visibility.Hidden)
      .onClick(() => {
        if (this.isRecording() && this.canManage()) {
          this.isStopPresented = true
        }
      })
    }
    .bindContentCover(this.isStopPresented, this.stopConfirm(), { modalTransition: ModalTransition.NONE })
  }
}
