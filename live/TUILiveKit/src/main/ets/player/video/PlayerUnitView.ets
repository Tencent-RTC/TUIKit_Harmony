import { LiveInfo, UnitInfo, DeviceStatus, SuspendStatus } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveSeat, LiveSeatState } from '../../common/theme/LiveSeat'
import { PlayerStatus } from '../PlayerView'

@Observed
export class PlayerUnitViewState extends LiveSeatState {
  isCoHostConnected: boolean = false
  get isRemoteHost(): boolean {
    return this.currentUnitInfo.userID.length > 0 && this.liveID.length > 0 && this.liveID !== this.liveInfo?.liveID
  }
  setCoHostConnected(connected: boolean): void {
    if (this.isCoHostConnected === connected) return
    this.isCoHostConnected = connected
    this.apply()
  }
  frame?: Area
  get liveID(): string { return this.currentUnitInfo.liveID }
  get index(): number { return this.currentUnitInfo.index }
  private liveInfo?: LiveInfo
  private currentUnitInfo: UnitInfo
  private currentStatus: PlayerStatus

  constructor(unitInfo: UnitInfo, liveInfo?: LiveInfo, playerStatus: PlayerStatus = PlayerStatus.idle) {
    super()
    this.liveInfo = liveInfo
    this.currentUnitInfo = unitInfo
    this.currentStatus = playerStatus
    this.apply()
  }

  setUnitInfo(unitInfo: UnitInfo): void {
    if (this.currentUnitInfo.userID !== unitInfo.userID || this.currentUnitInfo.liveID !== unitInfo.liveID) this.updateVolume(0)
    this.currentUnitInfo = unitInfo
    this.apply()
  }

  setPlayerStatus(status: PlayerStatus): void {
    if (this.currentStatus === status) {
      return
    }
    this.currentStatus = status
    if (status !== PlayerStatus.inRoom && status !== PlayerStatus.coGuest) this.updateVolume(0)
    this.apply()
  }

  updateSpeakingVolume(info: UnitInfo, volume: number): void {
    if (this.currentStatus !== PlayerStatus.inRoom && this.currentStatus !== PlayerStatus.coGuest) return
    if (this.currentUnitInfo.userID.length === 0 || this.currentUnitInfo.userID !== info.userID ||
      this.currentUnitInfo.liveID !== info.liveID) return
    this.updateVolume(volume)
  }

  private apply(): void {
    const info = this.currentUnitInfo
    const ownerID = this.liveInfo?.liveOwner.userID ?? ''
    const isOwner = ownerID.length > 0 && ownerID === info.userID
    const roomActive = this.currentStatus === PlayerStatus.inRoom || this.currentStatus === PlayerStatus.coGuest
    this.updateContent(info.userName.length === 0 ? info.userID : info.userName, info.avatarURL,
      info.microphoneStatus === DeviceStatus.on)
    this.updateVisibility(info.userID.length === 0,
      info.cameraStatus !== DeviceStatus.on || info.userSuspendStatus === SuspendStatus.IN_BACKGROUND,
      (!isOwner || this.isCoHostConnected) && roomActive)
  }
}

@Component
export struct PlayerUnitView {
  @ObjectLink unit: PlayerUnitViewState

  build() {
    LiveSeat({ seat: this.unit, emptyTitle: LiveKitResources.localizedString('tuilivekit.player.coguest.apply') })
  }
}
