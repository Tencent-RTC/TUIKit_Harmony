import {
  CoGuestStore,
  DeviceStore,
  GuestListener,
  LiveInfo,
  LiveUserInfo,
  LoginStore,
  NoResponseReason,
  SeatUserInfo,
} from '@tencentcloud/atomicxcore'
import { BeautyPreferences } from '../../../common/beauty/BeautyPanel'
import { LiveKitDataObserver, LiveKitResources } from '../../../common/LiveKitResources'
import { dismissAllBottomSheets } from '../../../common/theme/BottomSheetView'
import { LiveToast } from '../../../common/theme/LiveToastView'
import { CoGuestingPanelController } from './CoGuestingPanel'
import { Mode } from './SettingsPanel'

export enum CoGuestStatus {
  idle,
  requesting,
  coGuesting,
}

@Observed
export class CoGuestIconController {
  uiState: CoGuestStatus = CoGuestStatus.idle
  openCameraAfterAccept: boolean = true
  onUiStateChanged?: (state: CoGuestStatus) => void
  liveInfo?: LiveInfo
  isApplyPanelPresented: boolean = false
  isConnectedPanelPresented: boolean = false
  isSettingsPanelPresented: boolean = false
  settingsMode: Mode = Mode.preview
  isAttached: boolean = false
  readonly connectedPanel: CoGuestingPanelController = new CoGuestingPanelController()
  private subscribedLiveID?: string
  private connected: SeatUserInfo[] = []
  private isOpeningCamera: boolean = false
  private allowCameraRestore: boolean = false
  private isOpeningMicrophone: boolean = false
  private unobserve?: () => void
  private guestListener?: GuestListener

  updateUiState(state: CoGuestStatus): void {
    if (this.uiState === state) {
      return
    }
    if (this.uiState === CoGuestStatus.coGuesting && state === CoGuestStatus.idle) {
      this.invalidateMicrophoneRequests()
      DeviceStore.shared().closeLocalMicrophone()
    }
    this.uiState = state
    this.applyUiState(state)
    this.onUiStateChanged?.(state)
  }

  activate(liveInfo: LiveInfo): void {
    if (liveInfo.liveID.length === 0) {
      return
    }
    this.liveInfo = liveInfo
    this.subscribeCoGuestStore(liveInfo.liveID)
  }

  invalidateCameraRequests(allowRestore: boolean): boolean {
    const wasOpening = this.isOpeningCamera
    const panelWasOpening = this.connectedPanel.invalidateCameraRequest(allowRestore)
    this.isOpeningCamera = false
    this.allowCameraRestore = allowRestore
    return wasOpening || panelWasOpening
  }

  invalidateMicrophoneRequests(): void {
    this.isOpeningMicrophone = false
  }

  deactivate(): void {
    this.invalidateCameraRequests(false)
    this.invalidateMicrophoneRequests()
    this.unsubscribe()
    this.connected = []
    this.liveInfo = undefined
    this.updateUiState(CoGuestStatus.idle)
    this.openCameraAfterAccept = true
    dismissAllBottomSheets()
    DeviceStore.shared().closeLocalMicrophone()
    DeviceStore.shared().closeLocalCamera()
  }

  presentPanelForCurrentState(): void {
    if (this.uiState === CoGuestStatus.coGuesting) {
      this.isConnectedPanelPresented = true
    } else {
      this.isApplyPanelPresented = true
    }
  }

  presentSettingsPanel(mode: Mode): void {
    this.settingsMode = mode
    this.isSettingsPanelPresented = true
  }

  private unsubscribe(): void {
    this.unobserve?.()
    this.unobserve = undefined
    if (this.guestListener !== undefined && this.subscribedLiveID !== undefined) {
      CoGuestStore.create(this.subscribedLiveID).removeGuestListener(this.guestListener)
    }
    this.guestListener = undefined
    this.subscribedLiveID = undefined
  }

  private subscribeCoGuestStore(liveID: string): void {
    this.unsubscribe()
    const store = CoGuestStore.create(liveID)
    this.subscribedLiveID = liveID
    this.connected = store.coGuestState.connected.getAllData()
    this.unobserve = LiveKitDataObserver.observe(store.coGuestState.connected,
      () => this.applyCoGuestState(store.coGuestState.connected.getAllData()))
    const listener = new GuestListener()
    listener.onGuestApplicationResponded = (isAccept: boolean, hostUser: LiveUserInfo) => this.handleApplicationResponded(isAccept)
    listener.onGuestApplicationNoResponse = (reason: NoResponseReason) => {
      LiveToast.show(LiveKitResources.localizedString(reason === NoResponseReason.ALREADY_SEATED ?
        'tuilivekit.player.coguest.error.already_seated' : 'tuilivekit.player.coguest.error.timeout'))
      this.openCameraAfterAccept = true
      this.updateUiState(CoGuestStatus.idle)
    }
    listener.onKickedOffSeat = (seatIndex: number, hostUser: LiveUserInfo) => {
      this.invalidateMicrophoneRequests()
      LiveToast.show(LiveKitResources.localizedString('tuilivekit.player.coguest.error.kicked_off'))
      DeviceStore.shared().closeLocalMicrophone()
      DeviceStore.shared().closeLocalCamera()
      this.updateUiState(CoGuestStatus.idle)
    }
    this.guestListener = listener
    store.addGuestListener(listener)
  }

  private applyCoGuestState(connected: SeatUserInfo[]): void {
    if (this.uiState === CoGuestStatus.requesting) {
      return
    }
    const selfUserID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (selfUserID.length === 0) {
      return
    }
    const meConnected = connected.some((seat: SeatUserInfo) => seat.userID === selfUserID)
    this.updateUiState(meConnected ? CoGuestStatus.coGuesting : CoGuestStatus.idle)
    const lastSeatUserInfo = this.connected.find((seat: SeatUserInfo) => seat.userID === selfUserID)
    this.connected = connected
    const seatUserInfo = connected.find((seat: SeatUserInfo) => seat.userID === selfUserID)
    if (lastSeatUserInfo === undefined || seatUserInfo === undefined) {
      return
    }
    if (lastSeatUserInfo.allowOpenMicrophone !== seatUserInfo.allowOpenMicrophone) {
      LiveToast.show(LiveKitResources.localizedString(seatUserInfo.allowOpenMicrophone ?
        'tuilivekit.player.coguest.microphone_unlocked' : 'tuilivekit.player.coguest.microphone_locked'))
    }
  }

  private handleApplicationResponded(isAccept: boolean): void {
    if (!isAccept) {
      LiveToast.show(LiveKitResources.localizedString('tuilivekit.player.coguest.error.rejected'))
      this.openCameraAfterAccept = true
      this.updateUiState(CoGuestStatus.idle)
      return
    }
    dismissAllBottomSheets()
    this.updateUiState(CoGuestStatus.coGuesting)
    if (this.isAttached) {
      this.isOpeningMicrophone = true
      DeviceStore.shared().openLocalMicrophone().catch(() => {
      }).finally(() => {
        this.isOpeningMicrophone = false
        if (this.liveInfo === undefined || this.uiState !== CoGuestStatus.coGuesting) {
          DeviceStore.shared().closeLocalMicrophone()
        }
      })
    }
    if (this.openCameraAfterAccept && this.isAttached) {
      this.isOpeningCamera = true
      BeautyPreferences.restore()
      DeviceStore.shared().openLocalCamera(DeviceStore.shared().state.isFrontCamera).catch(() => {
      }).finally(() => {
        this.isOpeningCamera = false
        if ((!this.isAttached || this.liveInfo === undefined || this.uiState !== CoGuestStatus.coGuesting ||
          !this.openCameraAfterAccept) && !this.allowCameraRestore) {
          DeviceStore.shared().closeLocalCamera()
        }
      })
    }
  }

  private applyUiState(state: CoGuestStatus): void {
    if (state === CoGuestStatus.idle) {
      this.openCameraAfterAccept = true
    }
    if (state !== CoGuestStatus.coGuesting) {
      this.isConnectedPanelPresented = false
    }
  }
}

@Component
export struct CoGuestIcon {
  @ObjectLink controller: CoGuestIconController
  @State private pressScale: number = 1

  aboutToAppear(): void {
    this.controller.isAttached = true
  }

  aboutToDisappear(): void {
    this.controller.isAttached = false
  }

  private handleTap(): void {
    this.getUIContext().animateTo({
      duration: 120, onFinish: () => this.getUIContext().animateTo({ duration: 120 }, () => this.pressScale = 1)
    }, () => this.pressScale = 0.92)
    this.controller.presentPanelForCurrentState()
  }

  build() {
    Image(LiveKitResources.image(this.controller.uiState === CoGuestStatus.coGuesting ? 'livekit_coguest_wave' :
      'livekit_coguest_idle'))
      .width(39)
      .height(39)
      .objectFit(ImageFit.Contain)
      .borderRadius(19.5)
      .borderWidth(1)
      .borderColor('rgba(255, 255, 255, 0.06)')
      .backgroundColor('rgba(10, 10, 15, 0.18)')
      .scale({ x: this.pressScale, y: this.pressScale })
      .accessibilityText(LiveKitResources.localizedString('tuilivekit.player.coguest'))
      .onClick(() => this.handleTap())
  }
}
