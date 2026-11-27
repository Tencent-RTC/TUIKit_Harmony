import {
  DeviceStatus,
  ParticipantRole,
  RoomParticipantState,
  RoomParticipantStore,
  RoomState,
  RoomStore,
} from '@tencentcloud/atomicxcore'
import { RoomToast } from '../../../../base/toast/RoomToast'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomScreenShareConfirm, RoomScreenShareConfirmMode } from '../RoomScreenShareConfirm'

@Component
export struct RoomScreenShareButton {
  @Prop @Watch('bindRoom') roomID: string = ''
  @State private participantState?: RoomParticipantState = undefined
  @State private roomState: RoomState = RoomStore.shared().state
  @State private isPressed: boolean = false
  @State private isConfirmPresented: boolean = false
  @State private confirmMode: RoomScreenShareConfirmMode = RoomScreenShareConfirmMode.START
  onConfirmDismiss?: () => void

  aboutToAppear(): void {
    this.bindRoom()
  }

  private bindRoom(): void {
    this.participantState = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID).state : undefined
  }

  private isSharing(): boolean {
    return this.participantState?.localParticipant?.screenShareStatus === DeviceStatus.on
  }

  private isRestricted(): boolean {
    const room = this.roomState.currentRoom
    const role = this.participantState?.localParticipant?.role
    const isPrivileged = role === ParticipantRole.owner || role === ParticipantRole.admin
    return room?.roomID === this.roomID && room.isAllScreenShareDisabled && !isPrivileged
  }

  private handleTap(): void {
    if (this.participantState === undefined) {
      return
    }
    if (this.isSharing()) {
      this.confirmMode = RoomScreenShareConfirmMode.STOP
      this.isConfirmPresented = true
      return
    }
    if (this.isRestricted()) {
      RoomToast.show(RoomResources.string('roomkit_screen_share_owner_admin_only'))
      return
    }
    const sharer = this.participantState.participantWithScreen
    if (sharer !== undefined && sharer.userID.length > 0) {
      RoomToast.show(RoomResources.string('roomkit_screen_share_failure_remotemsharing'))
      return
    }
    this.confirmMode = RoomScreenShareConfirmMode.START
    this.isConfirmPresented = true
  }

  build() {
    Stack() {
      Image(RoomResources.image(this.isSharing() ? 'roomkit_icon_screen_share_stop' :
        'roomkit_icon_screen_share_start'))
        .width(20)
        .height(20)
      RoomScreenShareConfirm({
        mode: this.confirmMode,
        isPresented: this.isConfirmPresented,
        onDismiss: () => {
          this.isConfirmPresented = false
          this.onConfirmDismiss?.()
        },
      })
    }
    .width(44)
    .height(44)
    .backgroundColor($r('app.color.roomkit_bg_hover'))
    .borderRadius(22)
    .opacity(this.isRestricted() ? 0.45 : 1)
    .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
    .animation({ duration: 80 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => this.handleTap())
  }
}
