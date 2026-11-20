import {
  CoGuestLayoutTemplate,
  AtomicLiveController,
  AtomicLiveView,
  AtomicLiveViewChangeAdapter,
  AtomicLiveViewImpl,
  AtomicLiveViewType,
  DeviceStatus,
  LoginStore,
  UnitInfo
} from '@tencentcloud/atomicxcore'
import { LiveKitLog } from '../../common/log/LiveKitLog'
import { LayoutInfo } from '../living/coguest/PusherCoGuestStore'
import { PusherUnitView, PusherUnitViewState } from './PusherUnitView'

export const pusherVideoBottomInset: number = 102

const idleBackground: string = 'rgba(31, 31, 31, 1)'

@Component
struct PusherUnitHost {
  @Prop @Watch('updateUnitInfo') unitInfo: UnitInfo = new UnitInfo()
  @Consume('pusherUnitAdapter') adapter: LiveVideoViewAdapter
  @State private unit: PusherUnitViewState = new PusherUnitViewState(new UnitInfo())

  aboutToAppear(): void {
    this.unit = new PusherUnitViewState(this.unitInfo)
    this.adapter.attach(this.unit)
  }

  aboutToDisappear(): void {
    this.adapter.detach(this.unit)
  }

  private updateUnitInfo(): void {
    this.unit.setUnitInfo(this.unitInfo)
    this.adapter.notifyGeometryChanged()
  }

  build() {
    PusherUnitView({ unit: this.unit }).onAreaChange((_: Area, area: Area) => {
      this.unit.frame = area
      this.adapter.notifyGeometryChanged()
    })
  }
}

@Builder
function unitViewBuilder(unitInfo: UnitInfo) { PusherUnitHost({ unitInfo: unitInfo }) }

export class LiveVideoViewAdapter extends AtomicLiveViewChangeAdapter {
  private readonly units: Set<PusherUnitViewState> = new Set()
  private geometryTimer: number = -1
  private isReleased: boolean = false
  isCoHostConnected: boolean = false
  private isLiving: boolean = false
  private usesSmallWindows: boolean = false
  private connectedGuestCount: number = 0
  private showsEmptySeats: boolean = false
  private showsHostOverlay: boolean = false
  private localCameraStatus?: DeviceStatus
  private changed?: () => void
  private volumeLogArmed: boolean = false
  private volumeCallbacks: number = 0
  private volumePositiveCallbacks: number = 0
  private volumeGuestCallbacks: number = 0
  private volumeGuestPositiveCallbacks: number = 0
  private volumeRoutedCallbacks: number = 0
  private volumeUnmatchedCallbacks: number = 0
  private volumePeak: number = 0
  private volumeLastLogAt: number = 0

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
    this.units.forEach((unit: PusherUnitViewState) => this.updatePresentation(unit))
  }

  update(isLiving: boolean, layout: CoGuestLayoutTemplate, connectedGuestCount: number): void {
    this.isLiving = isLiving
    if (isLiving && !this.volumeLogArmed) {
      this.volumeLogArmed = true
      LiveKitLog.info('[PusherVolume] event=armed waitingForSdkCallback=true')
    }
    this.connectedGuestCount = connectedGuestCount
    this.showsEmptySeats = !this.isCoHostConnected && LayoutInfo.showsEmptySeats(layout)
    this.showsHostOverlay = this.isCoHostConnected ||
      layout.templateId === CoGuestLayoutTemplate.gridLayout.templateId ||
      (layout.templateId === CoGuestLayoutTemplate.dynamicLayout.templateId && connectedGuestCount > 0)
    this.usesSmallWindows = !this.isCoHostConnected &&
      (layout.templateId === CoGuestLayoutTemplate.floatLayout.templateId ||
      layout.templateId === CoGuestLayoutTemplate.columnLayout.templateId)
    this.units.forEach((unit: PusherUnitViewState) => this.updatePresentation(unit))
    this.notifyGeometryChanged()
  }

  onCreateUnitView(unitInfo: UnitInfo): WrappedBuilder<[UnitInfo]> | undefined {
    return this.isReleased ? undefined : wrapBuilder(unitViewBuilder)
  }

  onUpdateUnitView(unitInfo: UnitInfo): void {
    this.findUnit(unitInfo)?.setUnitInfo(unitInfo)
    this.notifyGeometryChanged()
  }

  onVolumeChanged(unitInfo: UnitInfo, volume: number): void {
    const unit = this.findUnit(unitInfo)
    const routed = !this.isReleased && this.isLiving && unit !== undefined && unit.unitInfo.userID.length > 0 &&
      unit.unitInfo.userID === unitInfo.userID
    if (routed && unit !== undefined) unit.updateVolume(volume)
    const localUserID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    const isGuest = unitInfo.userID.length > 0 && unitInfo.userID !== localUserID
    this.logVolumeCallback(unitInfo.index, volume, unit, routed, isGuest)
  }

  private logVolumeCallback(index: number, volume: number, unit: PusherUnitViewState | undefined,
    routed: boolean, isGuest: boolean): void {
    this.volumeCallbacks++
    if (volume > 0) this.volumePositiveCallbacks++
    if (isGuest) this.volumeGuestCallbacks++
    if (isGuest && volume > 0) this.volumeGuestPositiveCallbacks++
    if (routed) this.volumeRoutedCallbacks++
    if (unit === undefined) this.volumeUnmatchedCallbacks++
    this.volumePeak = Math.max(this.volumePeak, volume)
    const now = Date.now()
    const first = this.volumeCallbacks === 1
    const firstPositive = volume > 0 && this.volumePositiveCallbacks === 1
    const firstGuestPositive = isGuest && volume > 0 && this.volumeGuestPositiveCallbacks === 1
    if (!first && !firstPositive && !firstGuestPositive && now - this.volumeLastLogAt < 10000) return
    this.volumeLastLogAt = now
    const event = first ? 'first' : (firstPositive ? 'firstPositive' :
      (firstGuestPositive ? 'firstGuestPositive' : 'summary'))
    LiveKitLog.info(`[PusherVolume] event=${event} callbacks=${this.volumeCallbacks}` +
      ` positive=${this.volumePositiveCallbacks} routed=${this.volumeRoutedCallbacks}` +
      ` guest=${this.volumeGuestCallbacks} guestPositive=${this.volumeGuestPositiveCallbacks}` +
      ` noSeat=${this.volumeUnmatchedCallbacks} seats=${this.units.size} peak=${this.volumePeak}` +
      ` index=${index} isGuest=${isGuest} input=${volume}` +
      ` output=${unit?.volume ?? 0} matched=${unit !== undefined} mic=${unit?.microphoneOn ?? false}` +
      ` noVideo=${unit?.showsNoVideo ?? false} living=${this.isLiving} released=${this.isReleased}`)
  }

  onVideoViewFrameChanged(left: number, top: number, right: number, bottom: number): void {
    this.notifyGeometryChanged()
  }

  guestUserID(x: number, y: number): string | undefined {
    if (!this.isLiving || this.isCoHostConnected || this.connectedGuestCount <= 0) {
      return undefined
    }
    return Array.from(this.units.values()).reverse().find((unit: PusherUnitViewState) => unit.isGuest &&
      !unit.isHidden && this.contains(unit.frame, x, y))?.unitInfo.userID
  }

  gridRegions(): Area[] {
    if (!this.isLiving || this.usesSmallWindows) return []
    return Array.from(this.units.values()).filter((unit: PusherUnitViewState) => !unit.isHidden && unit.frame !== undefined)
      .map((unit: PusherUnitViewState) => unit.frame!)
  }

  smallWindowRegions(): Area[] {
    if (!this.isLiving || !this.usesSmallWindows) {
      return []
    }
    return Array.from(this.units.values()).filter((unit: PusherUnitViewState) => !unit.isHost && !unit.isHidden &&
      unit.frame !== undefined).map((unit: PusherUnitViewState) => unit.frame!)
  }

  private contains(frame: Area | undefined, x: number, y: number): boolean {
    if (frame === undefined) {
      return false
    }
    const left = frame.globalPosition.x as number
    const top = frame.globalPosition.y as number
    return x >= left && x <= left + (frame.width as number) && y >= top && y <= top + (frame.height as number)
  }

  private updatePresentation(unit: PusherUnitViewState): void {
    unit.setPresentation(this.isLiving, this.showsEmptySeats, this.connectedGuestCount > 0 || this.isCoHostConnected, this.showsHostOverlay,
      this.localCameraStatus)
  }

  attach(unit: PusherUnitViewState): void {
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

  detach(unit: PusherUnitViewState): void {
    unit.frame = undefined
    this.units.delete(unit)
    this.notifyGeometryChanged()
  }

  release(): void {
    if (!this.isReleased) {
      LiveKitLog.info(`[PusherVolume] event=release callbacks=${this.volumeCallbacks}` +
        ` positive=${this.volumePositiveCallbacks} routed=${this.volumeRoutedCallbacks}` +
        ` guest=${this.volumeGuestCallbacks} guestPositive=${this.volumeGuestPositiveCallbacks}` +
        ` noSeat=${this.volumeUnmatchedCallbacks} peak=${this.volumePeak}`)
    }
    this.isReleased = true
    clearTimeout(this.geometryTimer)
    this.geometryTimer = -1
    this.changed = undefined
    this.units.forEach((unit: PusherUnitViewState) => unit.frame = undefined)
    this.units.clear()
  }

  private findUnit(info: UnitInfo): PusherUnitViewState | undefined {
    return Array.from(this.units).find((unit: PusherUnitViewState) =>
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

@Observed
export class PusherVideoViewController {
  @Track readonly coreView: AtomicLiveView =
    new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.pushView))
  @Track isCoHostConnected: boolean = false
  @Track isCoGuestStageVisible: boolean = false
  @Track readonly unitAdapter: LiveVideoViewAdapter = new LiveVideoViewAdapter()

  constructor() {
    this.coreView.controller.setViewChangeAdapter(this.unitAdapter)
  }

  updateCoGuestVideoState(isLiving: boolean, layout: CoGuestLayoutTemplate, connectedGuestCount: number): void {
    this.unitAdapter.isCoHostConnected = this.isCoHostConnected
    this.unitAdapter.update(isLiving, layout, connectedGuestCount)
    this.isCoGuestStageVisible = isLiving && (this.isCoHostConnected || connectedGuestCount > 0 ||
      layout.templateId !== CoGuestLayoutTemplate.floatLayout.templateId)
  }

  updateLocalCameraStatus(status: DeviceStatus): void {
    this.unitAdapter.updateLocalCameraStatus(status)
  }

  set onCoGuestGeometryChanged(callback: (() => void) | undefined) {
    this.unitAdapter.onGeometryChanged = callback
  }

  get onCoGuestGeometryChanged(): (() => void) | undefined {
    return this.unitAdapter.onGeometryChanged
  }

  coGuestGridRegions(): Area[] { return this.unitAdapter.gridRegions() }

  coGuestSmallWindowRegions(): Area[] {
    return this.unitAdapter.smallWindowRegions()
  }

  coGuestUserID(x: number, y: number): string | undefined {
    return this.unitAdapter.guestUserID(x, y)
  }
}

@Component
export struct PusherVideoView {
  @ObjectLink controller: PusherVideoViewController
  @Provide('pusherUnitAdapter') adapter: LiveVideoViewAdapter = this.controller.unitAdapter

  build() {
    Stack() {
      AtomicLiveViewImpl({ view: this.controller.coreView })
    }
      .width('100%')
      .height('100%')
      .backgroundColor(this.controller.isCoGuestStageVisible ? Color.Transparent : idleBackground)
  }
}
