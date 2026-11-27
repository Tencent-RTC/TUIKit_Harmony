import { RoomChatButton } from '../features/chat/chatbutton/RoomChatButton'
import { ParticipantRole, RoomParticipantState, RoomParticipantStore } from '@tencentcloud/atomicxcore'
import { RoomMicButton } from '../features/device/micbutton/RoomMicButton'
import { RoomCameraButton } from '../features/device/camerabutton/RoomCameraButton'
import { RoomSpeakerButton } from '../features/device/speakerbutton/RoomSpeakerButton'
import { RoomParticipantButton } from '../features/participants/participantbutton/RoomParticipantButton'
import { RoomSettingsButton } from '../features/settings/RoomSettingsButton'
import { RoomSettingsPage } from '../features/settings/RoomSettingsPage'
import { RoomScreenShareButton } from '../features/screenshare/screensharebutton/RoomScreenShareButton'
import { RoomRecordingButton } from '../features/recording/cloudrecordingbutton/RoomRecordingButton'
import { CloudRecordingConfirm, CloudRecordingConfirmMode } from '../features/recording/CloudRecordingConfirm'
import { RoomPopup, RoomPopupContentHeight } from '../../base/popup/RoomPopup'
import { RoomResources } from '../../base/util/RoomResources'
import { RoomSafeArea } from '../../base/util/RoomSafeArea'

@Component
export struct MeetingToolBar {
  @Prop @Watch('bindRoom') roomID: string = ''
  @State private participantState?: RoomParticipantState = undefined
  @State private isMorePresented: boolean = false
  @State private isSettingsVisible: boolean = false
  @State private isRecordingConfirmPresented: boolean = false
  @State private recordingConfirmMode: CloudRecordingConfirmMode = CloudRecordingConfirmMode.START

  aboutToAppear(): void {
    this.bindRoom()
  }

  private bindRoom(): void {
    this.participantState = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID).state : undefined
  }

  private hasRecording(): boolean {
    const role = this.participantState?.localParticipant?.role
    return role === ParticipantRole.owner || role === ParticipantRole.admin
  }

  build() {
    Row({ space: 12 }) {
      RoomMicButton({ roomID: this.roomID })
      RoomCameraButton({ roomID: this.roomID })
      RoomSpeakerButton()
      RoomParticipantButton({ roomID: this.roomID })
      RoomChatButton({ roomID: this.roomID })
      Column({ space: 3 }) {
        Image(RoomResources.image('roomkit_icon_more')).width(20).height(20)
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.roomkit_bg_hover'))
      .borderRadius(22)
      .onClick(() => this.isMorePresented = true)
      RoomPopup({
        isPresented: this.isMorePresented,
        contentHeight: RoomPopupContentHeight.AUTO,
        onDismiss: () => this.isMorePresented = false,
      }) {
        Row() {
          Column() {
            RoomScreenShareButton({
              roomID: this.roomID,
              onConfirmDismiss: () => this.isMorePresented = false,
            })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 2, right: 2, top: 10, bottom: 10 })
          if (this.hasRecording()) {
            Column() {
              RoomRecordingButton({
                roomID: this.roomID,
                showsTitle: true,
                onRequestDismiss: () => this.isMorePresented = false,
                onRequestConfirm: (mode: CloudRecordingConfirmMode) => {
                  this.recordingConfirmMode = mode
                  this.isRecordingConfirmPresented = true
                },
              })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 2, right: 2, top: 10, bottom: 10 })
          }
          Column() {
            RoomSettingsButton({
              showsTitle: true,
              onRequestDismiss: () => this.isMorePresented = false,
              onShowSettings: () => this.isSettingsVisible = true,
            })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 2, right: 2, top: 10, bottom: 10 })
          Blank().layoutWeight(1)
          if (!this.hasRecording()) {
            Blank().layoutWeight(1)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 30, right: 30, top: 6, bottom: 14 })
      }
      CloudRecordingConfirm({
        roomID: this.roomID,
        mode: this.recordingConfirmMode,
        isPresented: this.isRecordingConfirmPresented,
        onDismiss: () => this.isRecordingConfirmPresented = false,
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: RoomSafeArea.bottomClearance() })
    .justifyContent(FlexAlign.Center)
    .bindContentCover(this.isSettingsVisible, this.settingsPage(), {
      modalTransition: ModalTransition.DEFAULT,
      onDisappear: () => this.isSettingsVisible = false,
    })
  }

  @Builder
  settingsPage() {
    RoomSettingsPage({
      onBack: () => {
        this.isSettingsVisible = false
      },
    })
  }
}
