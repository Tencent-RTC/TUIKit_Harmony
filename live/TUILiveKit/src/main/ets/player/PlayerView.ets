import { LiveInfo } from '@tencentcloud/atomicxcore'
import { PlayerViewImpl, PlayerViewImplController } from './PlayerViewImpl'

export enum PlayerStatus {
  idle,
  playing,
  inRoom,
  coGuest,
  end,
}

export class PlayerViewController {
  static readonly eventKeyPlayerView: string = 'PlayerView'
  static readonly eventSubKeyOnJoinChannelResult: string = 'onJoinChannelResult'
  static readonly eventSubKeyOnJoinChannelParamsKey: string = 'liveID'
  readonly impl: PlayerViewImplController = new PlayerViewImplController()

  get liveID(): string | undefined {
    return this.impl.liveID
  }

  status(listener: (status: PlayerStatus) => void): () => void {
    return this.impl.addStatusListener(listener)
  }

  setLiveInfo(liveInfo: LiveInfo): void {
    this.impl.setLiveInfo(liveInfo)
  }

  startPlay(): void {
    this.impl.startPlay()
  }

  stopPlay(): void {
    this.impl.stopPlay()
  }

  joinChannel(): Promise<LiveInfo> {
    return this.impl.joinChannel()
  }

  leaveChannel(): Promise<void> {
    return this.impl.leaveChannel()
  }

  setVolume(volume: number): void {
    this.impl.setVolume(volume)
  }

  get joinLiveEntranceEnabled(): boolean {
    return this.impl.joinLiveEntranceEnabled
  }

  set joinLiveEntranceEnabled(enabled: boolean) {
    this.impl.joinLiveEntranceEnabled = enabled
  }

  get onCloseClicked(): (() => void) | undefined {
    return this.impl.onCloseClicked
  }

  set onCloseClicked(callback: (() => void) | undefined) {
    this.impl.onCloseClicked = callback
  }

  get onJoinLiveClicked(): (() => void) | undefined {
    return this.impl.onJoinLiveClicked
  }

  set onJoinLiveClicked(callback: (() => void) | undefined) {
    this.impl.onJoinLiveClicked = callback
  }
}

@Component
export struct PlayerView {
  controller: PlayerViewController = new PlayerViewController()

  build() {
    PlayerViewImpl({ controller: this.controller.impl })
  }
}
