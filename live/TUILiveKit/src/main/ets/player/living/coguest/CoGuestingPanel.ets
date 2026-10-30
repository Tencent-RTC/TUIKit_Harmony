import { CoGuestStore, DeviceStatus, DeviceStore, LiveSeatStore, LoginStore, SeatUserInfo } from '@tencentcloud/atomicxcore'
import { BeautyPreferences } from '../../../common/beauty/BeautyPanel'
import { LiveKitDataObserver, LiveKitResources } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { rgba, white } from '../../../common/theme/LiveTheme'
import { LiveToast } from '../../../common/theme/LiveToastView'

const buttonSize: number = 48
const iconSize: number = 22

@Component
struct CoGuestControlButton {
  @Prop imageName: string = ''
  @Prop fillColor: string = ''
  @Prop isEnabled: boolean = true
  @Prop isDanger: boolean = false
  onTap?: () => void

  build() {
    Stack() {
      Image(LiveKitResources.image(this.imageName))
        .width(iconSize)
        .height(iconSize)
        .objectFit(ImageFit.Contain)
    }
    .width(buttonSize)
    .height(buttonSize)
    .borderRadius(buttonSize / 2)
    .backgroundColor(this.fillColor)
    .shadow(this.isDanger ? { radius: 9, color: rgba(1, 0.216, 0.263, 0.25), offsetY: 7 } :
      { radius: 0, color: 'rgba(0,0,0,0)' })
    .enabled(this.isEnabled)
    .onClick(() => this.onTap?.())
  }
}

@Observed
export class CoGuestingPanelController {
  isCameraRequesting: boolean = false
  allowCameraRestore: boolean = false

  invalidateCameraRequest(allowRestore: boolean): boolean {
    const wasOpening = this.isCameraRequesting
    this.isCameraRequesting = false
    this.allowCameraRestore = allowRestore
    return wasOpening
  }
}

@Component
export struct CoGuestingPanel {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop @Watch('onLiveIDChanged') liveID: string = ''
  @Prop openCameraAfterAccept: boolean = true
  @ObjectLink controller: CoGuestingPanelController
  onDismiss?: () => void
  onShowSettings?: () => void
  @State private microphoneStatus: DeviceStatus = DeviceStatus.on
  @State private cameraStatus: DeviceStatus = DeviceStatus.on
  @State private isBusy: boolean = false
  private unobserve?: () => void

  aboutToAppear(): void {
    if (this.isPresented) {
      this.observeSeatState()
    }
  }

  aboutToDisappear(): void {
    this.unobserve?.()
  }

  private onPresentedChanged(): void {
    if (this.isPresented) {
      this.observeSeatState()
    }
  }

  private onLiveIDChanged(): void {
    if (this.isPresented) {
      this.observeSeatState()
    }
  }

  private sheetDidDismiss(): void {
    this.controller.invalidateCameraRequest(this.controller.allowCameraRestore)
    this.unobserve?.()
    this.unobserve = undefined
    this.isBusy = false
  }

  private selfSeat(): SeatUserInfo | undefined {
    const selfUserID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    return CoGuestStore.create(this.liveID).coGuestState.connected.getAllData()
      .find((seat: SeatUserInfo) => seat.userID === selfUserID)
  }

  private observeSeatState(): void {
    this.unobserve?.()
    if (this.liveID.length === 0) {
      return
    }
    const apply = () => {
      const seat = this.selfSeat()
      if (seat !== undefined) {
        this.microphoneStatus = seat.microphoneStatus
        this.cameraStatus = seat.cameraStatus
      }
    }
    this.unobserve = LiveKitDataObserver.observe(CoGuestStore.create(this.liveID).coGuestState.connected, apply)
    apply()
  }

  private toggleMic(): void {
    if (this.liveID.length === 0) {
      return
    }
    const seatInfo = this.selfSeat()
    if (seatInfo?.microphoneStatus === DeviceStatus.on) {
      LiveSeatStore.create(this.liveID).muteMicrophone()
    } else if (seatInfo?.allowOpenMicrophone === true) {
      LiveSeatStore.create(this.liveID).unmuteMicrophone().catch(() => {
      })
    } else if (seatInfo?.allowOpenMicrophone === false) {
      LiveToast.show(LiveKitResources.localizedString('tuilivekit.player.coguest.microphone_locked'))
    }
  }

  private toggleCamera(): void {
    if (this.liveID.length === 0) {
      return
    }
    if (this.selfSeat()?.cameraStatus === DeviceStatus.on) {
      this.controller.isCameraRequesting = false
      this.controller.allowCameraRestore = false
      DeviceStore.shared().closeLocalCamera()
      return
    }
    this.controller.isCameraRequesting = true
    BeautyPreferences.restore()
    DeviceStore.shared().openLocalCamera(DeviceStore.shared().state.isFrontCamera).catch(() => {
    }).finally(() => {
      if (this.controller.isCameraRequesting) {
        this.controller.isCameraRequesting = false
        if (this.liveID.length === 0) {
          DeviceStore.shared().closeLocalCamera()
        }
      } else if (!this.controller.allowCameraRestore) {
        DeviceStore.shared().closeLocalCamera()
      }
    })
  }

  private disconnect(): void {
    if (this.isBusy || this.liveID.length === 0) {
      return
    }
    this.isBusy = true
    CoGuestStore.create(this.liveID).disconnect().catch(() => {
    }).finally(() => {
      this.isBusy = false
      this.onDismiss?.()
    })
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: 160,
      onDismiss: () => this.onDismiss?.(),
      sheetDidDismiss: () => this.sheetDidDismiss(),
    }) {
      Row() {
        CoGuestControlButton({
          imageName: this.microphoneStatus === DeviceStatus.on ? 'livekit_player_connected_mic_on' :
            'livekit_player_connected_mic_off',
          fillColor: white(this.microphoneStatus === DeviceStatus.on ? 0.09 : 0.96),
          onTap: () => this.toggleMic(),
        })
        if (this.openCameraAfterAccept) {
          CoGuestControlButton({
            imageName: this.cameraStatus === DeviceStatus.on ? 'livekit_player_connected_camera_on' :
              'livekit_player_connected_camera_off',
            fillColor: white(this.cameraStatus === DeviceStatus.on ? 0.09 : 0.96),
            onTap: () => this.toggleCamera(),
          })
          CoGuestControlButton({ imageName: 'livekit_player_connected_adjust', fillColor: white(0.09),
            onTap: () => this.onShowSettings?.() })
        }
        CoGuestControlButton({
          imageName: 'livekit_player_connected_disconnect',
          fillColor: rgba(1, 0.318, 0.345),
          isEnabled: !this.isBusy,
          isDanger: true,
          onTap: () => this.disconnect(),
        })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
  }
}
