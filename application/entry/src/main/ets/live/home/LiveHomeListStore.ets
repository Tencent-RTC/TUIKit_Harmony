import { BasicDataSource, LiveInfo, LiveListStore, LiveUserInfo } from '@tencentcloud/atomicxcore'

export class LiveHomeListState {
  readonly items: LiveInfo[]
  readonly loading: boolean
  readonly loaded: boolean
  readonly error: string
  readonly hasMore: boolean
  readonly revision: number
  readonly refreshing: boolean

  constructor(items: LiveInfo[] = [], loading: boolean = false, loaded: boolean = false,
    error: string = '', hasMore: boolean = true, revision: number = 0, refreshing: boolean = false) {
    this.items = items
    this.loading = loading
    this.loaded = loaded
    this.error = error
    this.hasMore = hasMore
    this.revision = revision
    this.refreshing = refreshing
  }
}

export class LiveHomeListStore {
  readonly source: BasicDataSource<LiveInfo> = new BasicDataSource<LiveInfo>()
  state: LiveHomeListState = new LiveHomeListState()
  onChanged?: (state: LiveHomeListState) => void
  private sdk: LiveListStore = LiveListStore.shared()
  private cursor: string = ''
  private failedCursor: string = ''
  private active: boolean = true
  private generation: number = 0

  setActive(active: boolean): void {
    if (this.active === active) { return }
    this.active = active
    if (!active) {
      this.generation++
      this.emit(new LiveHomeListState(this.state.items, false, this.state.loaded, this.state.error,
        this.state.hasMore, this.state.revision))
    }
  }

  refresh(): void { this.fetch('') }
  loadMore(): void {
    if (this.state.loaded && this.state.hasMore && this.cursor.length > 0) { this.fetch(this.cursor) }
  }
  retry(): void { this.fetch(this.failedCursor) }

  independentCopy(): LiveHomeListStore {
    const copy = new LiveHomeListStore()
    copy.cursor = this.cursor
    const rows = this.state.items.map((info: LiveInfo) => this.snapshot(info))
    copy.state = new LiveHomeListState(rows, false, this.state.loaded, '', this.state.hasMore, this.state.revision)
    copy.source.setData(rows)
    return copy
  }

  private fetch(cursor: string): void {
    if (!this.active || this.state.loading) { return }
    const request = ++this.generation
    this.emit(new LiveHomeListState(this.state.items, true, this.state.loaded, '',
      this.state.hasMore, this.state.revision, cursor.length === 0))
    this.sdk.fetchLiveList(cursor, 6).then(() => {
      if (!this.active || request !== this.generation) { return }
      const sdkState = this.sdk.liveState
      const rows: Map<string, LiveInfo> = new Map<string, LiveInfo>()
      if (cursor.length > 0) { this.state.items.forEach((info: LiveInfo) => rows.set(info.liveID, info)) }
      sdkState.liveList.getAllData().forEach((info: LiveInfo) => {
        if (info.liveID.length > 0) { rows.set(info.liveID, this.snapshot(info)) }
      })
      this.cursor = sdkState.liveListCursor
      const items = Array.from(rows.values())
      this.source.setData(items)
      this.emit(new LiveHomeListState(items, false, true, '', this.cursor.length > 0, this.state.revision + 1))
    }).catch((error: Error) => {
      if (!this.active || request !== this.generation) { return }
      this.failedCursor = cursor
      this.emit(new LiveHomeListState(this.state.items, false, this.state.loaded, error.message,
        this.state.hasMore, this.state.revision))
    })
  }

  private emit(state: LiveHomeListState): void { this.state = state; this.onChanged?.(state) }

  private snapshot(info: LiveInfo): LiveInfo {
    const copy = new LiveInfo(info.seatTemplate)
    copy.ID = info.ID
    copy.liveID = info.liveID
    copy.liveName = info.liveName
    copy.status = info.status
    copy.notice = info.notice
    copy.isMessageDisable = info.isMessageDisable
    copy.isPublicVisible = info.isPublicVisible
    copy.keepOwnerOnSeat = info.keepOwnerOnSeat
    copy.seatMode = info.seatMode
    copy.coverURL = info.coverURL
    copy.backgroundURL = info.backgroundURL
    copy.categoryList = info.categoryList.slice()
    copy.activityStatus = info.activityStatus
    copy.createTime = info.createTime
    copy.totalViewerCount = info.totalViewerCount
    copy.isGiftEnabled = info.isGiftEnabled
    copy.metaData = new Map<string, string>(info.metaData)
    copy.isSeatEnabled = info.isSeatEnabled
    copy.maxSeatCount = info.maxSeatCount
    copy.seatLayoutTemplateID = info.seatLayoutTemplateID
    const owner = new LiveUserInfo()
    owner.ID = info.liveOwner.ID
    owner.userID = info.liveOwner.userID
    owner.userName = info.liveOwner.userName
    owner.avatarURL = info.liveOwner.avatarURL
    owner.level = info.liveOwner.level
    copy.liveOwner = owner
    return copy
  }
}
