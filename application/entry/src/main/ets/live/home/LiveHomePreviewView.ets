import { LiveInfo, LoginStore } from '@tencentcloud/atomicxcore'
import { promptAction } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'
import { PlayerStatus, PlayerViewController } from 'tuilivekit'
import { LiveHomeListState, LiveHomeListStore } from './LiveHomeListStore'
import { LiveHomePreviewItemView } from './LiveHomePreviewItemView'

@Observed
export class LiveHomePlaybackSession {
  @Track info: LiveInfo
  @Track controller?: PlayerViewController
  @Track identity: string = util.generateRandomUUID()
  @Track renderKey: number = 0
  @Track status: PlayerStatus = PlayerStatus.idle
  @Track joining: boolean = false
  mounted: boolean = false
  retired: boolean = false
  joinBlocked: boolean = false
  generation: number = 0
  unsubscribe?: () => void

  constructor(info: LiveInfo) {
    this.info = info
  }

  release(): void {
    this.generation++
    this.retired = true
    this.controller?.setVolume(0)
    this.controller?.stopPlay()
    this.controller?.leaveChannel()
    this.unsubscribe?.()
    this.unsubscribe = undefined
    if (this.controller !== undefined) { this.controller.onCloseClicked = undefined }
    this.controller = undefined
    this.status = PlayerStatus.idle
  }
}

@Component
export struct LiveHomePreviewView {
  store: LiveHomeListStore = new LiveHomeListStore()
  @Prop @Watch('rowsChanged') state: LiveHomeListState = new LiveHomeListState()
  @Prop @Watch('updatePlayback') active: boolean = false
  @Prop canvasHeight: number = 1
  @Prop bottomInset: number = 0
  initialLiveID: string = ''
  direct: boolean = false
  onRoomChanged: (fullscreen: boolean) => void = () => {}
  onClose: () => void = () => {}
  onJoining: (joining: boolean) => void = () => {}
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0
  @StorageProp('app.active') @Watch('updatePlayback') private appActive: boolean = true
  @State private currentIndex: number = 0
  @State private automatic: boolean = false
  @State private locked: boolean = false
  @State private pending: number = 0
  @State private firstJoined: boolean = false
  private sessions: Map<string, LiveHomePlaybackSession> = new Map<string, LiveHomePlaybackSession>()
  private appeared: boolean = false
  private closing: boolean = false
  private selectedID: string = ''
  private renderedRevision: number = -1
  @Prop @Watch('backRequested') backToken: number = 0
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0

  aboutToAppear(): void {
    this.appeared = true
    this.closing = false
    this.automatic = this.direct
    this.selectedID = this.initialLiveID
    this.rowsChanged()
  }

  aboutToDisappear(): void {
    this.appeared = false
    this.sessions.forEach((session: LiveHomePlaybackSession) => session.release())
    this.sessions.clear()
  }

  private rowsChanged(): void {
    if (!this.appeared || this.closing) { return }
    if (this.renderedRevision !== this.state.revision) {
      this.renderedRevision = this.state.revision
      this.sessions.forEach((session: LiveHomePlaybackSession) => {
        const info = this.state.items.find((item: LiveInfo) => item.liveID === session.info.liveID)
        if (info !== undefined && info !== session.info) {
          session.info = info
          session.controller?.setLiveInfo(info)
        }
      })
    }
    const found = this.state.items.findIndex((info: LiveInfo) => info.liveID === this.selectedID)
    this.currentIndex = found >= 0 ? found : Math.min(this.currentIndex, Math.max(0, this.state.items.length - 1))
    this.updatePlayback()
  }

  private session(info: LiveInfo): LiveHomePlaybackSession {
    let session = this.sessions.get(info.liveID)
    if (session === undefined) {
      session = new LiveHomePlaybackSession(info)
      this.sessions.set(info.liveID, session)
    }
    return session
  }

  private mounted(session: LiveHomePlaybackSession): void {
    if (!this.appeared) { session.release(); return }
    const prior = this.sessions.get(session.info.liveID)
    if (prior !== undefined && prior !== session) { prior.release() }
    this.sessions.set(session.info.liveID, session)
    const info = this.state.items.find((item: LiveInfo) => item.liveID === session.info.liveID)
    if (info !== undefined) { session.info = info }
    session.mounted = true
    this.updatePlayback()
  }

  private activateController(session: LiveHomePlaybackSession): void {
    if (session.controller !== undefined) { return }
    const controller = new PlayerViewController()
    controller.joinLiveEntranceEnabled = false
    controller.setLiveInfo(session.info)
    session.retired = false
    session.controller = controller
    session.renderKey++
    controller.onCloseClicked = () => this.closeCurrent()
    session.unsubscribe = controller.status((status: PlayerStatus) => {
      if (session.controller !== controller || session.retired) { return }
      session.status = status
      if (session.info.liveID === this.selectedID) {
        this.locked = session.joining || status === PlayerStatus.coGuest || this.pending > 0
      }
    })
  }

  private unmounted(session: LiveHomePlaybackSession): void {
    session.mounted = false
    session.release()
    if (this.sessions.get(session.info.liveID) === session) { this.sessions.delete(session.info.liveID) }
  }

  private updatePlayback(): void {
    if (!this.appeared || this.closing) { return }
    const current = this.state.items[this.currentIndex]
    this.selectedID = current?.liveID ?? ''
    this.sessions.forEach((session: LiveHomePlaybackSession, liveID: string) => {
      const index = this.state.items.findIndex((info: LiveInfo) => info.liveID === liveID)
      const isCurrent = liveID === this.selectedID
      const joined = session.status === PlayerStatus.inRoom || session.status === PlayerStatus.coGuest
      if (index < 0 || Math.abs(index - this.currentIndex) > 1) {
        if (session.controller !== undefined) { session.release() }
        if (!session.mounted) { this.sessions.delete(liveID) }
        return
      }
      if (this.active && this.appActive && session.mounted) {
        this.activateController(session)
        session.controller?.setVolume(isCurrent ? 100 : 0)
        if (session.status !== PlayerStatus.end) { session.controller?.startPlay() }
        if (!isCurrent && joined) { session.controller?.leaveChannel() }
        if (isCurrent && this.automatic && !joined && session.status !== PlayerStatus.end) { this.enter(session) }
      } else {
        session.controller?.setVolume(0)
        // The room component owns background device policy. Room-outside preview releases its subscriptions.
        if (!joined || !isCurrent || !this.active) {
          if (session.controller !== undefined) { session.release() }
        }
      }
    })
  }

  private enter(session: LiveHomePlaybackSession): void {
    if (!this.active || !this.appActive || this.pending > 0 || session.joining || session.retired ||
      session.info.liveID !== this.selectedID || session.status === PlayerStatus.end ||
      session.status === PlayerStatus.inRoom || session.status === PlayerStatus.coGuest || session.joinBlocked) { return }
    if (session.info.liveOwner.userID === LoginStore.shared().state.loginUserInfo?.userID) {
      session.joinBlocked = true
      promptAction.showToast({ message: $r('app.string.app_own_live') })
      return
    }
    const controller = session.controller
    if (controller === undefined) { return }
    const request = ++session.generation
    session.joining = true
    this.pending++
    this.onJoining(true)
    this.locked = true
    controller.startPlay()
    controller.joinChannel().then(() => {
      if (session.retired || request !== session.generation || !this.active || !this.appeared ||
        session.info.liveID !== this.selectedID) {
        controller.leaveChannel()
        controller.stopPlay()
        return
      }
      this.automatic = true
      this.firstJoined = true
      this.onRoomChanged(true)
    }).catch((error: Error) => {
      if (session.retired || request !== session.generation || !this.appeared) { return }
      if (!this.direct && !this.automatic) { this.onRoomChanged(session.status === PlayerStatus.end) }
      promptAction.showToast({ message: error.message })
    }).finally(() => {
      session.joining = false
      this.pending = Math.max(0, this.pending - 1)
      this.onJoining(this.pending > 0)
      this.locked = this.pending > 0 || session.status === PlayerStatus.coGuest
      if (this.appeared) { this.updatePlayback() }
    })
  }

  private backRequested(): void { if (this.backToken > 0) { this.closeCurrent() } }

  private closeCurrent(): void {
    if (!this.appeared || this.closing) { return }
    if (this.direct) {
      this.closing = true
      this.sessions.forEach((session: LiveHomePlaybackSession) => session.release())
      this.onClose()
      return
    }
    if (this.pending > 0) { return }
    this.sessions.forEach((session: LiveHomePlaybackSession) => {
      session.generation++
      session.controller?.leaveChannel()
      session.controller?.stopPlay()
    })
    this.automatic = this.direct
    this.onRoomChanged(false)
    this.onClose()
    if (!this.direct) { this.updatePlayback() }
  }

  build() {
    Stack() {
      Refresh({ refreshing: this.state.loading && this.state.loaded && this.state.refreshing }) {
        Swiper() {
          LazyForEach(this.store.source, (info: LiveInfo) => {
            LiveHomePreviewItemView({ session: this.session(info), canvasHeight: this.canvasHeight,
              viewportHeight: Math.max(1, this.canvasHeight - (this.automatic || this.direct ? 0 : this.bottomInset)),
              showPreview: !this.automatic && !this.direct,
              coverUntilJoined: this.direct && !this.firstJoined,
              onEnter: (session: LiveHomePlaybackSession) => this.enter(session),
              onMounted: (session: LiveHomePlaybackSession) => this.mounted(session),
              onUnmounted: (session: LiveHomePlaybackSession) => this.unmounted(session) })
          }, (info: LiveInfo) => info.liveID)
        }.vertical(true).loop(false).indicator(false).index(this.currentIndex).cachedCount(1)
          .disableSwipe(this.locked).width('100%').height('100%')
          .onChange((index: number) => {
            this.currentIndex = index
            this.updatePlayback()
            if (index >= this.state.items.length - 2) { this.store.loadMore() }
          })
      }.pullToRefresh(!this.automatic && !this.direct).onRefreshing(() => this.store.refresh())
      if (this.state.items.length === 0) {
        Column({ space: 12 }) {
          Text(this.state.error || $r('app.string.app_empty')).fontSize(15).fontColor('#B3FFFFFF')
          Button($r('app.string.app_retry')).height(44).onClick(() => this.store.retry())
        }
      }
      if (this.state.error.length > 0 && this.state.items.length > 0 &&
        this.currentIndex >= this.state.items.length - 2 && this.pending === 0) {
        Button($r('app.string.app_retry')).height(44).backgroundColor('#CC20232C')
          .align(Alignment.Bottom).margin({ bottom: this.automatic ? 24 + this.safeBottom : 24 })
          .onClick(() => this.store.retry())
      }
      if (!this.direct && this.automatic &&
        this.sessions.get(this.selectedID)?.status !== PlayerStatus.inRoom &&
        this.sessions.get(this.selectedID)?.status !== PlayerStatus.coGuest) {
        Row() {
          Blank()
          Image($r('app.media.home_live_close')).width(44).height(44).padding(14.5)
            .objectFit(ImageFit.Contain).backgroundColor('#38000000').borderRadius(22)
            .margin({ right: 12 }).onClick(() => this.closeCurrent())
        }.width('100%').height(44).position({ x: 0, y: this.safeTop + 6 })
      }
    }.width('100%').height(Math.max(1, this.canvasHeight - (this.automatic || this.direct ? 0 : this.bottomInset)))
      .clip(true).backgroundColor(Color.Black)
  }
}
