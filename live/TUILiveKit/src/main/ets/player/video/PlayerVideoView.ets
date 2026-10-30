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

const unitStates: Map<string, UnitViewState> = new Map()

function unitKey(unitInfo: UnitInfo): string {
  return `${unitInfo.liveID}_${unitInfo.index}`
}

@Builder
function unitViewBuilder(unitInfo: UnitInfo) {
  if (unitStates.has(unitKey(unitInfo))) {
    UnitView({ unit: unitStates.get(unitKey(unitInfo))! })
  }
}

class LiveVideoViewAdapter extends AtomicLiveViewChangeAdapter {
  liveInfo: LiveInfo = new LiveInfo()
  private currentStatus: PlayerStatus = PlayerStatus.idle
  private activeUnits: Set<string> = new Set()

  setStatus(status: PlayerStatus): void {
    if (this.currentStatus === status) {
      return
    }
    this.currentStatus = status
    this.activeUnits.forEach((key: string) => unitStates.get(key)?.setPlayerStatus(status))
  }

  onCreateUnitView(unitInfo: UnitInfo): WrappedBuilder<[UnitInfo]> | undefined {
    const key = unitKey(unitInfo)
    unitStates.set(key, new UnitViewState(unitInfo, this.liveInfo, this.currentStatus))
    this.activeUnits.add(key)
    return wrapBuilder(unitViewBuilder)
  }

  onUpdateUnitView(unitInfo: UnitInfo): void {
    unitStates.get(unitKey(unitInfo))?.setUnitInfo(unitInfo)
  }

  onVolumeChanged(unitInfo: UnitInfo, volume: number): void {
    unitStates.get(unitKey(unitInfo))?.updateVolume(volume)
  }

  onVideoViewFrameChanged(left: number, top: number, right: number, bottom: number): void {
  }
}

@Observed
export class PlayerVideoViewController {
  readonly coreView: AtomicLiveView = new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.playView))
  backgroundURL: string = LiveKitResources.defaultBackgroundURL
  isHidden: boolean = false
  private liveInfo: LiveInfo = new LiveInfo()
  private readonly unitAdapter: LiveVideoViewAdapter = new LiveVideoViewAdapter()

  constructor() {
    this.coreView.controller.setViewChangeAdapter(this.unitAdapter)
  }

  setLiveInfo(liveInfo: LiveInfo): void {
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
