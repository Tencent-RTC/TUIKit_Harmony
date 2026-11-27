import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveToast } from '../../common/theme/LiveToastView'
import { FloatingPlayerManager } from '../../player/floating/FloatingPlayerManager'
import { PlayerViewController } from '../../player/PlayerView'
import { SwipeBehavior } from './PagerView'

export class PageCell {
  readonly playerView: PlayerViewController
  private liveInfo: LiveInfo
  private ownsPlayer: boolean = true
  private restoring: boolean = false
  private floatingPending: boolean = false
  private readonly getSwipeBehavior: () => SwipeBehavior
  private readonly onDidSlideIn: (pageCell: PageCell) => void
  private readonly onDidSlideOut: (pageCell: PageCell) => void
  private readonly onJoinChannelStart: () => void
  private readonly onJoinChannelResult: (pageCell: PageCell, liveInfo?: LiveInfo) => void

  constructor(liveInfo: LiveInfo, getSwipeBehavior: () => SwipeBehavior, onCloseClicked: () => void,
    onJoinClicked: () => void, onDidSlideIn: (pageCell: PageCell) => void, onDidSlideOut: (pageCell: PageCell) => void,
    onJoinChannelStart: () => void, onJoinChannelResult: (pageCell: PageCell, liveInfo?: LiveInfo) => void,
    restoreID: string, canFloat: () => boolean, onFloatingTransition: (pending: boolean) => void) {
    const restored = FloatingPlayerManager.claim(liveInfo.liveID, restoreID)
    this.playerView = restored ?? new PlayerViewController()
    this.restoring = restored !== undefined
    this.liveInfo = this.restoring ? (this.playerView.impl.liveInfo ?? liveInfo) : liveInfo
    this.getSwipeBehavior = getSwipeBehavior
    this.onDidSlideIn = onDidSlideIn
    this.onDidSlideOut = onDidSlideOut
    this.onJoinChannelStart = onJoinChannelStart
    this.onJoinChannelResult = onJoinChannelResult
    this.playerView.setLiveInfo(this.liveInfo)
    this.playerView.joinLiveEntranceEnabled = !this.restoring && getSwipeBehavior() === SwipeBehavior.previewOnly
    this.playerView.onCloseClicked = () => { if (this.ownsPlayer) onCloseClicked() }
    this.playerView.onJoinLiveClicked = () => { if (this.ownsPlayer) onJoinClicked() }
    this.playerView.impl.onFloatingWindowRequested = (uiContext: UIContext) => {
      if (this.floatingPending || !this.ownsPlayer || !canFloat()) return
      this.floatingPending = true
      onFloatingTransition(true)
      FloatingPlayerManager.enterFloatingView(this.playerView, uiContext, () => this.ownsPlayer && canFloat(), () => {
        this.ownsPlayer = false
      }).then((entered: boolean) => {
        if (!entered && this.ownsPlayer && canFloat()) {
          LiveToast.show(LiveKitResources.localizedString('tuilivekit.player.floating_failed'))
        }
      }).catch((error: Error) => {
        if (this.ownsPlayer && canFloat()) {
          LiveToast.show(LiveKitResources.localizedString('tuilivekit.player.floating_failed'))
        }
      }).finally(() => {
        this.floatingPending = false
        onFloatingTransition(false)
      })
    }
  }

  get liveID(): string {
    return this.liveInfo.liveID
  }

  updateData(liveInfo: LiveInfo): void {
    if (!this.ownsPlayer) return
    if (liveInfo.liveOwner.userID.length === 0 && this.liveInfo.liveOwner.userID.length > 0) return
    this.liveInfo = liveInfo
    this.playerView.setLiveInfo(liveInfo)
  }

  startPreview(): void {
    if (!this.ownsPlayer || this.restoring) return
    this.playerView.setVolume(0)
    this.playerView.startPlay()
  }

  stopPreview(): void {
    if (!this.ownsPlayer || this.restoring) return
    this.playerView.stopPlay()
  }

  joinChannel(): void {
    if (!this.ownsPlayer) return
    this.playerView.setVolume(100)
    this.onDidSlideIn(this)
    if (this.restoring) {
      this.restoring = false
      this.playerView.onJoinLiveClicked?.()
      return
    }
    if (this.getSwipeBehavior() !== SwipeBehavior.autoEnterRoom) return
    this.onJoinChannelStart()
    this.playerView.joinChannel().then((liveInfo: LiveInfo) => {
      if (this.ownsPlayer) this.onJoinChannelResult(this, liveInfo)
    }).catch(() => {
      if (this.ownsPlayer) this.onJoinChannelResult(this, undefined)
    })
  }

  leaveChannel(): void {
    if (!this.ownsPlayer) return
    this.playerView.stopPlay()
    if (this.getSwipeBehavior() === SwipeBehavior.autoEnterRoom) this.playerView.leaveChannel()
    this.onDidSlideOut(this)
  }

  stopAndLeaveChannel(): void {
    if (!this.ownsPlayer) return
    this.ownsPlayer = false
    this.playerView.stopPlay()
    this.playerView.leaveChannel()
    this.playerView.onCloseClicked = undefined
    this.playerView.onJoinLiveClicked = undefined
    this.playerView.impl.onFloatingWindowRequested = undefined
  }

  setJoinLiveEntranceEnabled(enabled: boolean): void {
    if (this.ownsPlayer) this.playerView.joinLiveEntranceEnabled = enabled
  }
}
