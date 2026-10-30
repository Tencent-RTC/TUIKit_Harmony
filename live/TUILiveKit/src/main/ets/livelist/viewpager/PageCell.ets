import { LiveInfo } from '@tencentcloud/atomicxcore'
import { PlayerViewController } from '../../player/PlayerView'
import { SwipeBehavior } from './PagerView'

export class PageCell {
  readonly playerView: PlayerViewController = new PlayerViewController()
  private liveInfo: LiveInfo
  private readonly getSwipeBehavior: () => SwipeBehavior
  private readonly onDidSlideIn: (pageCell: PageCell) => void
  private readonly onDidSlideOut: (pageCell: PageCell) => void
  private readonly onJoinChannelStart: () => void
  private readonly onJoinChannelResult: (pageCell: PageCell, liveInfo?: LiveInfo) => void

  constructor(liveInfo: LiveInfo, getSwipeBehavior: () => SwipeBehavior, onCloseClicked: () => void,
    onJoinClicked: () => void, onDidSlideIn: (pageCell: PageCell) => void, onDidSlideOut: (pageCell: PageCell) => void,
    onJoinChannelStart: () => void, onJoinChannelResult: (pageCell: PageCell, liveInfo?: LiveInfo) => void) {
    this.liveInfo = liveInfo
    this.getSwipeBehavior = getSwipeBehavior
    this.onDidSlideIn = onDidSlideIn
    this.onDidSlideOut = onDidSlideOut
    this.onJoinChannelStart = onJoinChannelStart
    this.onJoinChannelResult = onJoinChannelResult
    this.playerView.setLiveInfo(liveInfo)
    this.playerView.joinLiveEntranceEnabled = getSwipeBehavior() === SwipeBehavior.previewOnly
    this.playerView.onCloseClicked = onCloseClicked
    this.playerView.onJoinLiveClicked = onJoinClicked
  }

  get liveID(): string {
    return this.liveInfo.liveID
  }

  updateData(liveInfo: LiveInfo): void {
    this.liveInfo = liveInfo
    this.playerView.setLiveInfo(liveInfo)
  }

  startPreview(): void {
    this.playerView.setVolume(0)
    this.playerView.startPlay()
  }

  stopPreview(): void {
    this.playerView.stopPlay()
  }

  joinChannel(): void {
    this.playerView.setVolume(100)
    this.onDidSlideIn(this)
    if (this.getSwipeBehavior() !== SwipeBehavior.autoEnterRoom) {
      return
    }
    this.onJoinChannelStart()
    this.playerView.joinChannel().then((liveInfo: LiveInfo) => this.onJoinChannelResult(this, liveInfo))
      .catch(() => this.onJoinChannelResult(this, undefined))
  }

  leaveChannel(): void {
    this.playerView.stopPlay()
    if (this.getSwipeBehavior() === SwipeBehavior.autoEnterRoom) {
      this.playerView.leaveChannel()
    }
    this.onDidSlideOut(this)
  }

  stopAndLeaveChannel(): void {
    this.playerView.stopPlay()
    this.playerView.leaveChannel()
  }

  setJoinLiveEntranceEnabled(enabled: boolean): void {
    this.playerView.joinLiveEntranceEnabled = enabled
  }
}
