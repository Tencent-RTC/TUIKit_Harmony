import { common } from '@kit.AbilityKit'
import { DeviceStatus, DeviceStore, ParticipantRole, RoomParticipantState, RoomParticipantStore, RoomState, RoomStore }
  from '@tencentcloud/atomicxcore'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { RoomDevicePermission } from '../../../../base/util/RoomDevicePermission'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomToast } from '../../../../base/toast/RoomToast'

@Component
export struct RoomCameraButton {
  @Prop roomID: string = ''
  @State private participantState?: RoomParticipantState = undefined
  @State private roomState: RoomState = RoomStore.shared().state
  @State private hasPermission: boolean = false
  @State private isPressed: boolean = false
  private permissionGrantedListener?: () => void

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomID).state
    RoomDevicePermission.hasCameraPermission().then((granted: boolean) => {
      this.hasPermission = granted
    })
    const listener = () => {
      this.hasPermission = true
    }
    this.permissionGrantedListener = listener
    RoomDevicePermission.addCameraPermissionListener(listener)
  }

  aboutToDisappear(): void {
    if (this.permissionGrantedListener !== undefined) {
      RoomDevicePermission.removeCameraPermissionListener(this.permissionGrantedListener)
      this.permissionGrantedListener = undefined
    }
  }

  private isCameraOn(): boolean {
    return this.participantState?.localParticipant?.cameraStatus === DeviceStatus.on
  }

  private isRoomDisabled(): boolean {
    const room = this.roomState.currentRoom
    const role = this.participantState?.localParticipant?.role
    return room?.roomID === this.roomID && room.isAllCameraDisabled && role === ParticipantRole.generalUser
  }

  private async toggle(): Promise<void> {
    if (this.isCameraOn()) {
      DeviceStore.shared().closeLocalCamera()
      return
    }
    if (this.isRoomDisabled()) {
      RoomToast.show(RoomResources.string('roomkit_device_all_cam_disabled'))
      return
    }
    const context = getContext(this) as common.UIAbilityContext
    const granted = await RoomDevicePermission.requestCameraPermission(context)
    if (granted) {
      try {
        await DeviceStore.shared().openLocalCamera(DeviceStore.shared().state.isFrontCamera)
      } catch (error) {
        ErrorLocalized.showError(error as Error)
      }
    } else {
      RoomToast.show(RoomResources.string('roomkit_device_camera_no_permission'))
    }
  }

  build() {
    Stack() {
      Image(RoomResources.image(this.isCameraOn() ? 'roomkit_icon_camera_on' : 'roomkit_icon_camera_off'))
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
    .opacity(!this.isCameraOn() && this.isRoomDisabled() ? 0.45 : 1)
    .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
    .animation({ duration: 80 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => this.toggle())
  }
}
