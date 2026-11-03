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
import { UnitView, UnitViewState } from './UnitView'

function unitKey(unitInfo: UnitInfo): string { return `${unitInfo.liveID}_${unitInfo.index}` }

@Component
struct PlayerUnitHost {
  @Prop @Watch('updateInfo') unitInfo: UnitInfo = new UnitInfo()
  @Consume('playerUnitAdapter') adapter: LiveVideoViewAdapter
  @State private unit: UnitViewState = new UnitViewState(new UnitInfo())
  aboutToAppear(): void { this.unit = this.adapter.attach(this.unitInfo) }
  aboutToDisappear(): void { this.adapter.detach(this.unit) }
  private updateInfo(): void { this.unit.setUnitInfo(this.unitInfo); this.adapter.notifyGeometryChanged() }
  build() {
    UnitView({ unit: this.unit }).onAreaChange((_: Area, area: Area) => {
      this.unit.frame = area
      this.adapter.notifyGeometryChanged()
    })
  }
}

@Builder
function unitViewBuilder(unitInfo: UnitInfo) { PlayerUnitHost({ unitInfo: unitInfo }) }

class LiveVideoViewAdapter extends AtomicLiveViewChangeAdapter {
  liveInfo: LiveInfo = new LiveInfo()
  onGeometryChanged?: () => void
  private currentStatus: PlayerStatus = PlayerStatus.idle
  private readonly units: Map<string, UnitViewState> = new Map()
  private geometryTask: number = -1
  setStatus(status: PlayerStatus): void {
    if (this.currentStatus === status) return
    this.currentStatus = status
    this.units.forEach((unit: UnitViewState) => unit.setPlayerStatus(status))
    this.notifyGeometryChanged()
  }
  attach(info: UnitInfo): UnitViewState {
    const unit = new UnitViewState(info, this.liveInfo, this.currentStatus)
    this.units.set(unitKey(info), unit)
    this.notifyGeometryChanged()
    return unit
  }
  detach(unit: UnitViewState): void {
    const key = `${unit.liveID}_${unit.index}`
    if (this.units.get(key) === unit) this.units.delete(key)
    unit.frame = undefined
    this.notifyGeometryChanged()
  }
  seatRegions(): Area[] {
    return Array.from(this.units.values()).filter((unit: UnitViewState) => unit.liveID === this.liveInfo.liveID && unit.frame !== undefined)
      .map((unit: UnitViewState) => unit.frame!)
  }
  clearGeometry(): void {
    this.units.forEach((unit: UnitViewState) => unit.frame = undefined)
    this.notifyGeometryChanged()
  }
  notifyGeometryChanged(): void {
    if (this.geometryTask >= 0) return
    this.geometryTask = setTimeout(() => { this.geometryTask = -1; this.onGeometryChanged?.() }, 0)
  }
  onCreateUnitView(unitInfo: UnitInfo): WrappedBuilder<[UnitInfo]> | undefined { return wrapBuilder(unitViewBuilder) }
  onUpdateUnitView(unitInfo: UnitInfo): void { this.units.get(unitKey(unitInfo))?.setUnitInfo(unitInfo); this.notifyGeometryChanged() }
  onVolumeChanged(unitInfo: UnitInfo, volume: number): void { this.units.get(unitKey(unitInfo))?.updateVolume(volume) }
  onVideoViewFrameChanged(left: number, top: number, right: number, bottom: number): void { this.notifyGeometryChanged() }
}

@Observed
export class PlayerVideoViewController {
  readonly coreView: AtomicLiveView = new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.playView))
  backgroundURL: string = LiveKitResources.defaultBackgroundURL
  isHidden: boolean = false
  private liveInfo: LiveInfo = new LiveInfo()
  readonly unitAdapter: LiveVideoViewAdapter = new LiveVideoViewAdapter()

  constructor() {
    this.coreView.controller.setViewChangeAdapter(this.unitAdapter)
  }

  setLiveInfo(liveInfo: LiveInfo): void {
    if (this.liveInfo.liveID !== liveInfo.liveID) this.unitAdapter.clearGeometry()
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
      AtomicLiveViewImpl({ view: this.controller.coreView })
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .visibility(this.controller.isHidden ? Visibility.Hidden : Visibility.Visible)
  }
}
