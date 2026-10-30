import {
  CoGuestLayoutTemplate,
  AtomicLiveViewChangeAdapter,
  DeviceStatus,
  LoginStore,
  SuspendStatus,
  UnitInfo
} from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../../../common/LiveKitResources'
import { LiveSeat, LiveSeatState } from '../../../../common/theme/LiveSeat'
import { LayoutInfo } from '../PusherCoGuestStore'

@Observed
class PusherCoGuestUnitState extends LiveSeatState {
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
    this.unitInfo = unitInfo
    this.updateContent(unitInfo.userName.length === 0 ? unitInfo.userID : unitInfo.userName, unitInfo.avatarURL,
      unitInfo.microphoneStatus === DeviceStatus.on)
    this.refreshVisibility()
  }

  setPresentation(isLiving: boolean, showsEmptySeats: boolean, hasGuests: boolean, showsHostOverlay: boolean,
    localCameraStatus?: DeviceStatus): void {
    this.isLiving = isLiving
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
  struct PusherCoGuestUnitView {
  @Prop @Watch('updateUnitInfo') unitInfo: UnitInfo = new UnitInfo()
  @Consume('pusherSeatProvider') provider: PusherCoGuestSeatViewProvider
  @State private unit: PusherCoGuestUnitState = new PusherCoGuestUnitState(new UnitInfo())

  aboutToAppear(): void {
    this.unit = new PusherCoGuestUnitState(this.unitInfo)
    this.provider.attach(this.unit)
  }

  aboutToDisappear(): void {
    this.provider.detach(this.unit)
  }

  private updateUnitInfo(): void {
    this.unit.setUnitInfo(this.unitInfo)
    this.provider.notifyGeometryChanged()
  }

  build() {
    LiveSeat(
      { seat: this.unit, emptyTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.invite_to_seat') })
      .visibility(this.unit.isHidden ? Visibility.Hidden : Visibility.Visible)
      .onAreaChange((_: Area, area: Area) => {
        this.unit.frame = area
        this.provider.notifyGeometryChanged()
      })
  }
}

@Builder
  function pusherCoGuestUnitBuilder(unitInfo: UnitInfo) {
  PusherCoGuestUnitView({ unitInfo: unitInfo })
}

export class PusherCoGuestSeatViewProvider extends AtomicLiveViewChangeAdapter {
  private readonly units: Set<PusherCoGuestUnitState> = new Set()
  private geometryTimer: number = -1
  private isReleased: boolean = false
  private isLiving: boolean = false
  private usesSmallWindows: boolean = false
  private connectedGuestCount: number = 0
  private showsEmptySeats: boolean = false
  private showsHostOverlay: boolean = false
  private localCameraStatus?: DeviceStatus
  private changed?: () => void

  set onGeometryChanged(callback: (() => void) | undefined) {
    this.changed = callback
  }

  get onGeometryChanged(): (() => void) | undefined {
    return this.changed
  }

  updateLocalCameraStatus(status: DeviceStatus): void {
    if (this.localCameraStatus === status) {
      return
    }
    this.localCameraStatus = status
    this.units.forEach((unit: PusherCoGuestUnitState) => this.updatePresentation(unit))
  }

  update(isLiving: boolean, layout: CoGuestLayoutTemplate, connectedGuestCount: number): void {
    this.isLiving = isLiving
    this.connectedGuestCount = connectedGuestCount
    this.showsEmptySeats = LayoutInfo.showsEmptySeats(layout)
    this.showsHostOverlay = layout.templateId === CoGuestLayoutTemplate.gridLayout.templateId ||
      (layout.templateId === CoGuestLayoutTemplate.dynamicLayout.templateId && connectedGuestCount > 0)
    this.usesSmallWindows = layout.templateId === CoGuestLayoutTemplate.floatLayout.templateId ||
      layout.templateId === CoGuestLayoutTemplate.columnLayout.templateId
    this.units.forEach((unit: PusherCoGuestUnitState) => this.updatePresentation(unit))
    this.notifyGeometryChanged()
  }

  onCreateUnitView(unitInfo: UnitInfo): WrappedBuilder<[UnitInfo]> | undefined {
    return this.isReleased ? undefined : wrapBuilder(pusherCoGuestUnitBuilder)
  }

  onUpdateUnitView(unitInfo: UnitInfo): void {
    this.findUnit(unitInfo)?.setUnitInfo(unitInfo)
    this.notifyGeometryChanged()
  }

  onVolumeChanged(unitInfo: UnitInfo, volume: number): void {
    this.findUnit(unitInfo)?.updateVolume(volume)
  }

  onVideoViewFrameChanged(left: number, top: number, right: number, bottom: number): void {
    this.notifyGeometryChanged()
  }

  guestUserID(x: number, y: number): string | undefined {
    if (!this.isLiving || this.connectedGuestCount <= 0) {
      return undefined
    }
    return Array.from(this.units.values()).reverse().find((unit: PusherCoGuestUnitState) => unit.isGuest &&
      !unit.isHidden && this.contains(unit.frame, x, y))?.unitInfo.userID
  }

  smallWindowRegions(): Area[] {
    if (!this.isLiving || !this.usesSmallWindows) {
      return []
    }
    return Array.from(this.units.values()).filter((unit: PusherCoGuestUnitState) => !unit.isHost && !unit.isHidden &&
      unit.frame !== undefined).map((unit: PusherCoGuestUnitState) => unit.frame!)
  }

  private contains(frame: Area | undefined, x: number, y: number): boolean {
    if (frame === undefined) {
      return false
    }
    const left = frame.globalPosition.x as number
    const top = frame.globalPosition.y as number
    return x >= left && x <= left + (frame.width as number) && y >= top && y <= top + (frame.height as number)
  }

  private updatePresentation(unit: PusherCoGuestUnitState): void {
    unit.setPresentation(this.isLiving, this.showsEmptySeats, this.connectedGuestCount > 0, this.showsHostOverlay,
      this.localCameraStatus)
  }

  attach(unit: PusherCoGuestUnitState): void {
    if (this.isReleased) {
      return
    }
    const previous = this.findUnit(unit.unitInfo)
    if (previous !== undefined) {
      previous.frame = undefined
      this.units.delete(previous)
    }
    this.units.add(unit)
    this.updatePresentation(unit)
    this.notifyGeometryChanged()
  }

  detach(unit: PusherCoGuestUnitState): void {
    unit.frame = undefined
    this.units.delete(unit)
    this.notifyGeometryChanged()
  }

  release(): void {
    this.isReleased = true
    clearTimeout(this.geometryTimer)
    this.geometryTimer = -1
    this.changed = undefined
    this.units.forEach((unit: PusherCoGuestUnitState) => unit.frame = undefined)
    this.units.clear()
  }

  private findUnit(info: UnitInfo): PusherCoGuestUnitState | undefined {
    return Array.from(this.units).find((unit: PusherCoGuestUnitState) =>
      unit.unitInfo.liveID === info.liveID && unit.unitInfo.index === info.index)
  }

  notifyGeometryChanged(): void {
    if (this.isReleased || this.geometryTimer >= 0) {
      return
    }
    this.geometryTimer = setTimeout(() => {
      this.geometryTimer = -1
      this.changed?.()
    }, 0)
  }
}
