import { LiveInfo, LiveListStore } from '@tencentcloud/atomicxcore'

export class State {
  liveList: LiveInfo[] = []
  isLoading: boolean = false
  canLoadMore: boolean = true
  errorMessage?: string
}

export class LiveSelectListStore {
  state: State = new State()
  private stateChanged?: (state: State) => void
  private readonly liveListStore: LiveListStore = LiveListStore.shared()
  private readonly pageSize: number = 6
  private requestID: number = 0

  set onStateChanged(callback: ((state: State) => void) | undefined) {
    this.stateChanged = callback
    callback?.(this.state)
  }

  get onStateChanged(): ((state: State) => void) | undefined {
    return this.stateChanged
  }

  refresh(): void {
    this.fetch('')
  }

  loadMore(): void {
    if (!this.state.canLoadMore || this.state.isLoading) {
      return
    }
    const cursor = this.liveListStore.liveState.liveListCursor
    if (cursor.length === 0) {
      this.state.canLoadMore = false
      this.notify()
      return
    }
    this.fetch(cursor)
  }

  private fetch(cursor: string): void {
    if (this.state.isLoading) {
      return
    }
    this.state.isLoading = true
    this.state.errorMessage = undefined
    const currentRequestID = ++this.requestID
    this.notify()
    this.liveListStore.fetchLiveList(cursor, this.pageSize).then(() => {
      if (this.requestID !== currentRequestID) {
        return
      }
      const sdkState = this.liveListStore.liveState
      const liveIDs = new Set<string>()
      this.state.liveList = sdkState.liveList.getAllData().filter((liveInfo: LiveInfo) => {
        const isNew = !liveIDs.has(liveInfo.liveID)
        liveIDs.add(liveInfo.liveID)
        return isNew
      })
      this.state.canLoadMore = sdkState.liveListCursor.length > 0
      this.state.isLoading = false
      this.notify()
    }).catch((error: Error) => {
      if (this.requestID !== currentRequestID) {
        return
      }
      const detail = (error.message ?? '').trim()
      this.state.errorMessage = detail.length === 0 ? `AtomicXCore error (${Reflect.get(error, 'code') ?? -1})` : detail
      this.state.isLoading = false
      this.notify()
    })
  }

  private notify(): void {
    this.stateChanged?.(this.state)
  }
}
