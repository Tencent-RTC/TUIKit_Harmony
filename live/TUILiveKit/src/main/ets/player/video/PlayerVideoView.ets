import {
  AtomicLiveController,
  AtomicLiveView,
  AtomicLiveViewChangeAdapter,
  AtomicLiveViewImpl,
  AtomicLiveViewType,
  LiveInfo,
  UnitInfo,
} from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../common/LiveKitResources'
import { PlayerStatus } from '../PlayerView'
import { PlayerUnitView, PlayerUnitViewState } from './PlayerUnitView'

function unitKey(unitInfo: UnitInfo): string { return `${unitInfo.liveID}_${unitInfo.index}` }

@Component
struct PlayerUnitHost {
  @Prop @Watch('updateInfo') unitInfo: UnitInfo = new UnitInfo()
  @Consume('playerUnitAdapter') adapter: LiveVideoViewAdapter
  @State private unit: PlayerUnitViewState = new PlayerUnitViewState(new UnitInfo())
  aboutToAppear(): void { this.unit = this.adapter.attach(this.unitInfo) }
  aboutToDisappear(): void { this.adapter.detach(this.unit) }
  private updateInfo(): void { this.unit.setUnitInfo(this.unitInfo); this.adapter.notifyGeometryChanged() }
  build() {
    PlayerUnitView({ unit: this.unit }).onAreaChange((_: Area, area: Area) => {
      this.unit.frame = area
      this.adapter.notifyGeometryChanged()
    })
  }
}

@Builder
function unitViewBuilder(unitInfo: UnitInfo) { PlayerUnitHost({ unitInfo: unitInfo }) }

class LiveVideoViewAdapter extends AtomicLiveViewChangeAdapter {
  liveInfo: LiveInfo = new LiveInfo()
  private session: number = 0
  onGeometryChanged?: () => void
  isCoHostConnected: boolean = false
  private currentStatus: PlayerStatus = PlayerStatus.idle
  private readonly units: Map<string, PlayerUnitViewState> = new Map()
  private geometryTask: number = -1
  setStatus(status: PlayerStatus): void {
    if (this.currentStatus === status) return
    this.currentStatus = status
    this.units.forEach((unit: PlayerUnitViewState) => unit.setPlayerStatus(status))
    this.notifyGeometryChanged()
  }
  attach(info: UnitInfo): PlayerUnitViewState {
    const unit = new PlayerUnitViewState(info, this.liveInfo, this.currentStatus)
    this.units.set(unitKey(info), unit)
    this.notifyGeometryChanged()
    return unit
  }
  detach(unit: PlayerUnitViewState): void {
    const key = `${unit.liveID}_${unit.index}`
    if (this.units.get(key) === unit) this.units.delete(key)
    unit.frame = undefined
    this.notifyGeometryChanged()
  }
  seatRegions(): Area[] {
    return Array.from(this.units.values()).filter((unit: PlayerUnitViewState) =>
      unit.frame !== undefined && (unit.liveID === this.liveInfo.liveID || unit.isRemoteHost))
      .map((unit: PlayerUnitViewState) => unit.frame!)
  }
  clearGeometry(): void {
    this.session++
    clearTimeout(this.geometryTask)
    this.geometryTask = -1
    this.isCoHostConnected = false
    this.units.forEach((unit: PlayerUnitViewState) => unit.frame = undefined)
    this.units.clear()
    this.notifyGeometryChanged()
  }
  notifyGeometryChanged(): void {
    if (this.geometryTask >= 0) return
    const session = this.session
    this.geometryTask = setTimeout(() => {
      if (session !== this.session) return
      this.geometryTask = -1
      this.isCoHostConnected =
        (this.currentStatus === PlayerStatus.inRoom || this.currentStatus === PlayerStatus.coGuest) &&
        Array.from(this.units.values()).some((unit: PlayerUnitViewState) =>
          unit.isRemoteHost && unit.frame !== undefined)
      this.units.forEach((unit: PlayerUnitViewState) => unit.setCoHostConnected(this.isCoHostConnected))
      this.onGeometryChanged?.()
    }, 0)
  }
  onCreateUnitView(unitInfo: UnitInfo): WrappedBuilder<[UnitInfo]> | undefined { return wrapBuilder(unitViewBuilder) }
  onUpdateUnitView(unitInfo: UnitInfo): void { this.units.get(unitKey(unitInfo))?.setUnitInfo(unitInfo); this.notifyGeometryChanged() }
  onVolumeChanged(unitInfo: UnitInfo, volume: number): void {
    this.units.get(unitKey(unitInfo))?.updateSpeakingVolume(unitInfo, volume)
  }
  onVideoViewFrameChanged(left: number, top: number, right: number, bottom: number): void { this.notifyGeometryChanged() }
}

@Observed
export class PlayerVideoViewController {
  readonly coreView: AtomicLiveView = new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.playView))
  backgroundURL: string = LiveKitResources.defaultBackgroundURL
  isHidden: boolean = false
  isCoHostConnected: boolean = false
  private liveInfo: LiveInfo = new LiveInfo()
  readonly unitAdapter: LiveVideoViewAdapter = new LiveVideoViewAdapter()

  constructor() {
    this.coreView.controller.setViewChangeAdapter(this.unitAdapter)
  }

  setLiveInfo(liveInfo: LiveInfo): void {
    if (this.liveInfo.liveID !== liveInfo.liveID) {
      this.unitAdapter.clearGeometry()
      this.isCoHostConnected = false
    }
    this.liveInfo = liveInfo
    this.unitAdapter.liveInfo = liveInfo
    this.backgroundURL = liveInfo.backgroundURL.length > 0 ? liveInfo.backgroundURL
      : liveInfo.coverURL.length > 0 ? liveInfo.coverURL : LiveKitResources.defaultBackgroundURL
  }

  setPlayerStatus(status: PlayerStatus): void {
    this.unitAdapter.setStatus(status)
  }
}

@Component
export struct PlayerVideoView {
  @ObjectLink controller: PlayerVideoViewController
  @Provide('playerUnitAdapter') adapter: LiveVideoViewAdapter = new LiveVideoViewAdapter()
  aboutToAppear(): void { this.adapter = this.controller.unitAdapter }

  build() {
    Stack() {
      Image(this.controller.backgroundURL)
        .alt(LiveKitResources.image('livekit_livelist_default_cover'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(80)
      if (this.controller.isCoHostConnected) {
        Image(LiveKitResources.image('livekit_pusher_coguest_background')).width('100%').height('100%')
          .objectFit(ImageFit.Fill).hitTestBehavior(HitTestMode.None)
      }
      AtomicLiveViewImpl({ view: this.controller.coreView }).backgroundColor(Color.Transparent)
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .visibility(this.controller.isHidden ? Visibility.Hidden : Visibility.Visible)
  }
}
