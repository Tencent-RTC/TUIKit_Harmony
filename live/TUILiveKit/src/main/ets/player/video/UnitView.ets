import { LiveInfo, UnitInfo, DeviceStatus, SuspendStatus } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveSeat, LiveSeatState } from '../../common/theme/LiveSeat'
import { PlayerStatus } from '../PlayerView'

@Observed
export class UnitViewState extends LiveSeatState {
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
    this.currentUnitInfo = unitInfo
    this.apply()
  }

  setPlayerStatus(status: PlayerStatus): void {
    if (this.currentStatus === status) {
      return
    }
    this.currentStatus = status
    this.apply()
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
      !isOwner && roomActive)
  }
}

@Component
export struct UnitView {
  @ObjectLink unit: UnitViewState

  build() {
    LiveSeat({ seat: this.unit, emptyTitle: LiveKitResources.localizedString('tuilivekit.player.coguest.apply') })
  }
}
