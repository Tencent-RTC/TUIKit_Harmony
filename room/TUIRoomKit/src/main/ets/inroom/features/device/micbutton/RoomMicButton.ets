import { common } from '@kit.AbilityKit'
import { DeviceStatus, ParticipantRole, RoomParticipantState, RoomParticipantStore, RoomState, RoomStore }
  from '@tencentcloud/atomicxcore'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { RoomDevicePermission } from '../../../../base/util/RoomDevicePermission'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomToast } from '../../../../base/toast/RoomToast'
import { RoomMicLevelView } from './RoomMicLevelView'

@Component
export struct RoomMicButton {
  @Prop roomID: string = ''
  @State private participantState?: RoomParticipantState = undefined
  @State private roomState: RoomState = RoomStore.shared().state
  @State private hasPermission: boolean = false
  @State private isPressed: boolean = false
  @State private level: number = 0
  private levelTimer: number = -1
  private permissionGrantedListener?: () => void

  aboutToAppear(): void {
    const store = RoomParticipantStore.create(this.roomID)
    this.participantState = store.state
    RoomDevicePermission.hasMicrophonePermission().then((granted: boolean) => {
      this.hasPermission = granted
    })
    const listener = () => {
      this.hasPermission = true
    }
    this.permissionGrantedListener = listener
    RoomDevicePermission.addMicrophonePermissionListener(listener)
    this.levelTimer = setInterval(() => {
      this.level = this.isMicrophoneOn() ? this.participantState?.speakingUsers.get('') ?? 0 : 0
    }, 200)
  }

  aboutToDisappear(): void {
    clearInterval(this.levelTimer)
    if (this.permissionGrantedListener !== undefined) {
      RoomDevicePermission.removeMicrophonePermissionListener(this.permissionGrantedListener)
      this.permissionGrantedListener = undefined
    }
  }

  private isMicrophoneOn(): boolean {
    return this.participantState?.localParticipant?.microphoneStatus === DeviceStatus.on
  }

  private isRoomDisabled(): boolean {
    const room = this.roomState.currentRoom
    const role = this.participantState?.localParticipant?.role
    return room?.roomID === this.roomID && room.isAllMicrophoneDisabled && role === ParticipantRole.generalUser
  }

  private async toggle(): Promise<void> {
    const store = RoomParticipantStore.create(this.roomID)
    if (this.isMicrophoneOn()) {
      store.muteMicrophone()
      this.level = 0
      return
    }
    if (this.isRoomDisabled()) {
      RoomToast.show(RoomResources.string('roomkit_device_all_mic_disabled'))
      return
    }
    const context = getContext(this) as common.UIAbilityContext
    const granted = await RoomDevicePermission.requestMicrophonePermission(context)
    if (granted) {
      try {
        await store.unmuteMicrophone()
      } catch (error) {
        ErrorLocalized.showError(error as Error)
      }
    } else {
      RoomToast.show(RoomResources.string('roomkit_device_mic_no_permission'))
    }
  }

  build() {
    Stack() {
      RoomMicLevelView({ level: this.level }).opacity(this.isMicrophoneOn() ? 1 : 0)
      Image(RoomResources.image(this.isMicrophoneOn() ? 'roomkit_icon_microphone_on' : 'roomkit_icon_microphone_off'))
        .width(20)
        .height(20)
      if (!this.hasPermission && !this.isRoomDisabled()) {
        Image(RoomResources.image('roomkit_icon_permission_badge'))
          .width(14)
          .height(14)
          .position({ right: 4, top: 6 })
      }
    }
    .width(44)
    .height(44)
    .backgroundColor($r('app.color.roomkit_bg_hover'))
    .borderRadius(22)
    .opacity(!this.isMicrophoneOn() && this.isRoomDisabled() ? 0.45 : 1)
    .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
    .animation({ duration: 80 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => this.toggle())
  }
}
