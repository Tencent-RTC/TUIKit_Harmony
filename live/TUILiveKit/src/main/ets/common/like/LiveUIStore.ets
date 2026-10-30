import { LikeListener, LikeStore, LiveUserInfo } from '@tencentcloud/atomicxcore'

export class LiveUIState {
  liveID: string = ''
  likeCount: number = 0
}

export class LiveUIStore {
  private stateChanged?: (state: LiveUIState) => void
  state: LiveUIState = new LiveUIState()
  private likeStore?: LikeStore
  private likeListener?: LikeListener
  private readonly likeSender: LikeSender = new LikeSender()

  set onStateChanged(callback: ((state: LiveUIState) => void) | undefined) {
    this.stateChanged = callback
    callback?.(this.state)
  }

  get onStateChanged(): ((state: LiveUIState) => void) | undefined {
    return this.stateChanged
  }

  activate(liveID: string): void {
    if (liveID.length === 0) {
      this.deactivate()
      return
    }
    if (this.state.liveID === liveID && this.likeStore !== undefined) {
      return
    }
    this.deactivate()
    this.state.liveID = liveID
    const likeStore = LikeStore.create(liveID)
    this.likeStore = likeStore
    this.likeSender.activate((count: number) => {
      likeStore.sendLike(count).catch(() => {
      })
    })
    const listener = new LikeListener()
    listener.onReceiveLikesMessage = (eventLiveID: string, totalLikesReceived: number, sender: LiveUserInfo) => {
      if (this.likeListener === listener && this.state.liveID === liveID && eventLiveID === liveID) {
        this.state.likeCount = totalLikesReceived
        this.notify()
      }
    }
    this.likeListener = listener
    likeStore.addLikeListener(listener)
    this.state.likeCount = likeStore.likeState.totalLikeCount
    this.notify()
  }

  deactivate(): void {
    this.likeSender.deactivate()
    if (this.likeListener !== undefined) {
      this.likeStore?.removeLikeListener(this.likeListener)
      this.likeListener = undefined
    }
    this.likeStore = undefined
    this.state = new LiveUIState()
    this.notify()
  }

  sendLike(): void {
    this.likeSender.sendLike()
  }

  private notify(): void {
    this.stateChanged?.(this.state)
  }
}

export class LikeSender {
  private now: () => number
  private send?: (count: number) => void
  private pendingCount: number = 0
  private lastSendTime?: number
  private timer: number = -1

  constructor(now: () => number = () => Date.now() / 1000) {
    this.now = now
  }

  activate(send: (count: number) => void): void {
    this.deactivate()
    this.send = send
  }

  sendLike(): void {
    if (this.send === undefined) {
      return
    }
    this.pendingCount += 1
    const elapsed = this.lastSendTime === undefined ? 6 : this.now() - this.lastSendTime
    if (elapsed >= 6) {
      this.flush()
    } else if (this.timer < 0) {
      this.timer = setTimeout(() => this.flush(), (6 - elapsed) * 1000)
    }
  }

  deactivate(discardPending: boolean = false): void {
    clearTimeout(this.timer)
    this.timer = -1
    const action = this.send
    const count = this.pendingCount
    this.send = undefined
    this.pendingCount = 0
    this.lastSendTime = undefined
    if (!discardPending && count > 0) {
      action?.(count)
    }
  }

  private flush(): void {
    clearTimeout(this.timer)
    this.timer = -1
    if (this.pendingCount <= 0) {
      return
    }
    const count = this.pendingCount
    this.pendingCount = 0
    this.lastSendTime = this.now()
    this.send?.(count)
  }
}
