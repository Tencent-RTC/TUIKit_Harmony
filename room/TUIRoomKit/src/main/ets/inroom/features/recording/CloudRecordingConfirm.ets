import { ParticipantRole, RecordingStatus, RoomParticipantState, RoomParticipantStore, RoomState, RoomStore }
  from '@tencentcloud/atomicxcore'
import { RoomDialog, RoomDialogVariant } from '../../../base/dialog/RoomDialog'
import { ErrorLocalized } from '../../../base/error/ErrorLocalized'
import { RoomResources } from '../../../base/util/RoomResources'

export enum CloudRecordingConfirmMode {
  START,
  STOP,
}

@Component
export struct CloudRecordingConfirm {
  @Prop roomID: string = ''
  @Prop mode: CloudRecordingConfirmMode = CloudRecordingConfirmMode.START
  @Prop @Watch('onPresentationChanged') isPresented: boolean = false
  onDismiss?: () => void
  @State private roomState: RoomState = RoomStore.shared().state
  @State private participantState?: RoomParticipantState = undefined
  private validationTimer: number = -1

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomID).state
    if (this.isPresented) {
      this.startValidation()
    }
  }

  aboutToDisappear(): void {
    clearInterval(this.validationTimer)
  }

  private onPresentationChanged(): void {
    if (this.isPresented) {
      this.startValidation()
    } else {
      clearInterval(this.validationTimer)
    }
  }

  private startValidation(): void {
    clearInterval(this.validationTimer)
    this.validationTimer = setInterval(() => this.validate(), 200)
  }

  private isRecording(): boolean {
    const room = this.roomState.currentRoom
    return room?.roomID === this.roomID && room.recordingInfo.status === RecordingStatus.recording
  }

  private canManage(): boolean {
    const role = this.participantState?.localParticipant?.role
    return role === ParticipantRole.owner || role === ParticipantRole.admin
  }

  private validate(): void {
    if (!this.isPresented) {
      return
    }
    if (!this.canManage() || (this.mode === CloudRecordingConfirmMode.START && this.isRecording()) ||
      (this.mode === CloudRecordingConfirmMode.STOP && !this.isRecording())) {
      this.onDismiss?.()
    }
  }

  private async submit(): Promise<void> {
    if (!this.canManage() || this.roomState.currentRoom?.roomID !== this.roomID) {
      this.onDismiss?.()
      return
    }
    this.onDismiss?.()
    try {
      if (this.mode === CloudRecordingConfirmMode.START) {
        await RoomStore.shared().startRecording()
      } else {
        await RoomStore.shared().stopRecording()
      }
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  build() {
    RoomDialog({
      isPresented: this.isPresented,
      title: RoomResources.string(this.mode === CloudRecordingConfirmMode.START ?
        'roomkit_cloud_recording_start_title' : 'roomkit_cloud_recording_stop_title'),
      message: RoomResources.string(this.mode === CloudRecordingConfirmMode.START ?
        'roomkit_cloud_recording_start_content' : 'roomkit_cloud_recording_stop_content'),
      primaryText: RoomResources.string(this.mode === CloudRecordingConfirmMode.START ?
        'roomkit_cloud_recording_start_confirm' : 'roomkit_cloud_recording_stop_confirm'),
      primaryVariant: this.mode === CloudRecordingConfirmMode.START ? RoomDialogVariant.PRIMARY : RoomDialogVariant.DANGER,
      secondaryText: RoomResources.string('roomkit_room_common_cancel'),
      onPrimary: () => this.submit(),
      onSecondary: () => this.onDismiss?.(),
      onDismiss: () => this.onDismiss?.(),
    })
  }
}
