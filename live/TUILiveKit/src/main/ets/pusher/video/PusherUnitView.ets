import { DeviceStatus, LoginStore, SuspendStatus, UnitInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveSeat, LiveSeatState } from '../../common/theme/LiveSeat'

@Observed
export class PusherUnitViewState extends LiveSeatState {
  unitInfo: UnitInfo
  isHidden: boolean = false
  frame?: Area
  private isLiving: boolean = false
  private showsEmptySeats: boolean = false
  private hasGuests: boolean = false
  private showsHostOverlay: boolean = false
  private localCameraStatus?: DeviceStatus

  constructor(unitInfo: UnitInfo) {
    super()
    this.unitInfo = unitInfo
    this.setUnitInfo(unitInfo)
  }

  get isHost(): boolean {
    return this.unitInfo.userID.length > 0 && this.unitInfo.userID === LoginStore.shared().state.loginUserInfo?.userID
  }

  get isGuest(): boolean {
    return this.unitInfo.userID.length > 0 && !this.isHost
  }

  setUnitInfo(unitInfo: UnitInfo): void {
    if (this.unitInfo.userID !== unitInfo.userID || this.unitInfo.liveID !== unitInfo.liveID) this.updateVolume(0)
    this.unitInfo = unitInfo
    this.updateContent(unitInfo.userName.length === 0 ? unitInfo.userID : unitInfo.userName, unitInfo.avatarURL,
      unitInfo.microphoneStatus === DeviceStatus.on)
    this.refreshVisibility()
  }

  setPresentation(isLiving: boolean, showsEmptySeats: boolean, hasGuests: boolean, showsHostOverlay: boolean,
    localCameraStatus?: DeviceStatus): void {
    this.isLiving = isLiving
    if (!isLiving) this.updateVolume(0)
    this.showsEmptySeats = showsEmptySeats
    this.hasGuests = hasGuests
    this.showsHostOverlay = showsHostOverlay
    this.localCameraStatus = localCameraStatus
    this.refreshVisibility()
  }

  private refreshVisibility(): void {
    const isEmpty = this.unitInfo.userID.length === 0
    const cameraStatus = this.isHost ? this.localCameraStatus : this.unitInfo.cameraStatus
    const isGuestInBackground = this.isGuest && this.unitInfo.userSuspendStatus === SuspendStatus.IN_BACKGROUND
    this.isHidden = !this.isLiving || (isEmpty && !this.showsEmptySeats)
    this.updateVisibility(isEmpty,
      isGuestInBackground || (cameraStatus !== undefined && cameraStatus !== DeviceStatus.on),
      (this.isGuest && this.hasGuests) || (this.isHost && this.showsHostOverlay))
  }
}

@Component
export struct PusherUnitView {
  @ObjectLink unit: PusherUnitViewState

  build() {
    LiveSeat(
      { seat: this.unit, emptyTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.invite_to_seat') })
      .visibility(this.unit.isHidden ? Visibility.Hidden : Visibility.Visible)
  }
}
