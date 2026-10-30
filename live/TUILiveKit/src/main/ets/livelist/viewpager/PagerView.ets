import { LiveInfo, LiveListStore } from '@tencentcloud/atomicxcore'
import { LiveKitLog } from '../../common/log/LiveKitLog'
import { LiveTheme } from '../../common/theme/LiveTheme'
import { PlayerStatus, PlayerView } from '../../player/PlayerView'
import { PageCell } from './PageCell'

export enum SwipeBehavior {
  previewOnly,
  autoEnterRoom,
}

const loadMoreThreshold: number = 2

@Component
export struct PagerView {
  initialLiveID: string = ''
  @Prop @Watch('setData') liveList: LiveInfo[] = []
  onClose?: () => void
  onLoadMore?: () => void
  @State private dataList: LiveInfo[] = []
  @State private currentIndex: number = 0
  @State private isUserInputEnabled: boolean = true
  private pageCache: Map<string, PageCell> = new Map()
  private currentItemID?: string
  private pendingSlideInItemID?: string
  private didEmitWillSlideOut: boolean = false
  private swipeBehavior: SwipeBehavior = SwipeBehavior.previewOnly
  private swipeDisabledByJoin: boolean = false
  private swipeDisabledByCoGuest: boolean = false
  private stopObservingStatus?: () => void
  private currentPageCell?: PageCell
  private slidingInPageCell?: PageCell
  private slidingOutPageCell?: PageCell

  aboutToAppear(): void {
    this.prependInitialLiveIDIfNeeded()
    this.setData()
  }

  aboutToDisappear(): void {
    this.onDetached()
  }

  private setData(): void {
    const merged = this.mergeWithInitialLiveID(this.deduplicated(this.liveList))
    if (merged.length === 0 && this.initialLiveID.length > 0) {
      return
    }
    const liveIDs = new Set(merged.map((info: LiveInfo) => info.liveID))
    Array.from(this.pageCache.keys()).filter((key: string) => !liveIDs.has(key)).forEach((key: string) => {
      this.pageCache.get(key)?.stopAndLeaveChannel()
      this.pageCache.delete(key)
    })
    merged.forEach((info: LiveInfo) => this.pageCache.get(info.liveID)?.updateData(info))
    this.dataList = merged
    if (merged.length === 0) {
      this.currentItemID = undefined
      return
    }
    this.resyncCurrentItemIDIfMissing()
    this.settleInitialPageIfNeeded()
  }

  onDetached(): void {
    this.pageCache.forEach((pageCell: PageCell) => pageCell.stopAndLeaveChannel())
    this.currentPageCell = undefined
    this.slidingInPageCell = undefined
    this.slidingOutPageCell = undefined
    this.stopObservingCurrentPlayerStatus()
    this.setSwipeBehavior(SwipeBehavior.previewOnly)
  }

  private setSwipeBehavior(behavior: SwipeBehavior): void {
    if (this.swipeBehavior === behavior) {
      return
    }
    this.swipeBehavior = behavior
    this.pageCache.forEach((pageCell: PageCell) => pageCell.setJoinLiveEntranceEnabled(behavior === SwipeBehavior.previewOnly))
  }

  private makePageCell(liveInfo: LiveInfo): PageCell {
    const pageCell = new PageCell(liveInfo, () => this.swipeBehavior, () => this.handleCloseClicked(),
      () => this.handleJoinClicked(), (cell: PageCell) => this.handleDidSlideIn(cell),
      (cell: PageCell) => this.handleDidSlideOut(cell), () => this.handleJoinChannelStart(),
      (cell: PageCell, info?: LiveInfo) => this.handleJoinChannelResult(cell, info))
    this.logFeed('onCreatePlayerView', pageCell)
    return pageCell
  }

  private pageCellFor(liveInfo: LiveInfo): PageCell {
    let pageCell = this.pageCache.get(liveInfo.liveID)
    if (pageCell === undefined) {
      pageCell = this.makePageCell(liveInfo)
      if (liveInfo.liveID.length > 0) {
        this.pageCache.set(liveInfo.liveID, pageCell)
      }
    }
    return pageCell
  }

  private initialLiveInfo(): LiveInfo {
    const cached = LiveListStore.shared().liveState.liveList.getAllData()
      .find((info: LiveInfo) => info.liveID === this.initialLiveID)
    const info = cached ?? new LiveInfo()
    info.liveID = this.initialLiveID
    return info
  }

  private prependInitialLiveIDIfNeeded(): void {
    if (this.initialLiveID.length > 0) {
      this.dataList = [this.initialLiveInfo()]
      this.settleInitialPageIfNeeded()
    }
  }

  private mergeWithInitialLiveID(list: LiveInfo[]): LiveInfo[] {
    if (this.initialLiveID.length === 0) {
      return list
    }
    const index = list.findIndex((info: LiveInfo) => info.liveID === this.initialLiveID)
    if (index >= 0) {
      return [list[index]].concat(list.filter((_: LiveInfo, position: number) => position !== index))
    }
    const initial = this.initialLiveInfo()
    if (initial.liveName.length === 0) {
      initial.liveName = this.initialLiveID
    }
    return [initial].concat(list)
  }

  private deduplicated(list: LiveInfo[]): LiveInfo[] {
    const liveIDs = new Set<string>()
    return list.filter((info: LiveInfo) => {
      if (liveIDs.has(info.liveID)) {
        return false
      }
      liveIDs.add(info.liveID)
      return true
    })
  }

  private positionOfItem(itemID: string): number {
    return this.dataList.findIndex((info: LiveInfo) => info.liveID === itemID)
  }

  private itemID(position: number): string | undefined {
    const liveID = this.dataList[position]?.liveID ?? ''
    return liveID.length === 0 ? undefined : liveID
  }

  private resyncCurrentItemIDIfMissing(): void {
    if (this.currentItemID === undefined) {
      return
    }
    const position = this.positionOfItem(this.currentItemID)
    if (position >= 0) {
      this.currentIndex = position
      return
    }
    this.currentIndex = Math.min(this.currentIndex, this.dataList.length - 1)
    this.currentItemID = this.itemID(this.currentIndex)
  }

  private settleInitialPageIfNeeded(): void {
    if (this.currentItemID !== undefined || this.dataList.length === 0) {
      return
    }
    const itemID = this.itemID(0)
    if (itemID === undefined) {
      return
    }
    this.currentItemID = itemID
    this.currentIndex = 0
    setTimeout(() => {
      this.notifyWillSlideIn(itemID)
      this.notifyDidSlideIn(itemID)
    }, 0)
  }

  private observeCurrentPlayerStatus(pageCell: PageCell): void {
    this.stopObservingStatus?.()
    this.swipeDisabledByCoGuest = false
    this.updateSwipeEnabled()
    this.stopObservingStatus = pageCell.playerView.status((status: PlayerStatus) => {
      this.swipeDisabledByCoGuest = status === PlayerStatus.coGuest
      this.updateSwipeEnabled()
    })
  }

  private stopObservingCurrentPlayerStatus(): void {
    this.stopObservingStatus?.()
    this.stopObservingStatus = undefined
    this.swipeDisabledByCoGuest = false
    this.updateSwipeEnabled()
  }

  private updateSwipeEnabled(): void {
    this.isUserInputEnabled = !(this.swipeDisabledByJoin || this.swipeDisabledByCoGuest)
  }

  private handleDidSlideIn(pageCell: PageCell): void {
    this.slidingInPageCell = undefined
    this.currentPageCell = pageCell
    this.observeCurrentPlayerStatus(pageCell)
    const position = this.positionOfItem(pageCell.liveID)
    if (position >= 0 && this.dataList.length - 1 - position <= loadMoreThreshold) {
      this.onLoadMore?.()
    }
  }

  private handleDidSlideOut(pageCell: PageCell): void {
    this.slidingOutPageCell = undefined
    if (this.currentPageCell === pageCell) {
      this.currentPageCell = undefined
    }
  }

  private handleCloseClicked(): void {
    this.setSwipeBehavior(SwipeBehavior.previewOnly)
    this.onClose?.()
  }

  private handleJoinClicked(): void {
    this.setSwipeBehavior(SwipeBehavior.autoEnterRoom)
  }

  private handleJoinChannelStart(): void {
    this.swipeDisabledByJoin = true
    this.updateSwipeEnabled()
  }

  private handleJoinChannelResult(pageCell: PageCell, liveInfo?: LiveInfo): void {
    this.swipeDisabledByJoin = false
    this.updateSwipeEnabled()
    if (liveInfo === undefined || pageCell.liveID !== liveInfo.liveID || this.pageCache.get(liveInfo.liveID) !== pageCell) {
      return
    }
    const index = this.positionOfItem(liveInfo.liveID)
    if (index >= 0) {
      this.dataList[index] = liveInfo
      pageCell.updateData(liveInfo)
    }
  }

  private handleGestureSwipe(index: number, offset: number): void {
    if (!this.didEmitWillSlideOut && this.currentItemID !== undefined) {
      this.didEmitWillSlideOut = true
      this.notifyWillSlideOut(this.currentItemID)
    }
    const neighbor = this.itemID(offset < 0 ? index + 1 : index - 1)
    if (neighbor === undefined || neighbor === this.pendingSlideInItemID) {
      return
    }
    if (this.pendingSlideInItemID !== undefined) {
      this.notifySlideInCancelled(this.pendingSlideInItemID)
    }
    this.pendingSlideInItemID = neighbor
    this.notifyWillSlideIn(neighbor)
  }

  private settleScroll(index: number): void {
    const targetItemID = this.itemID(index)
    const pending = this.pendingSlideInItemID
    this.pendingSlideInItemID = undefined
    if (targetItemID !== undefined && targetItemID !== this.currentItemID) {
      this.notifyDidSlideOut(this.currentItemID)
      this.notifyDidSlideIn(targetItemID)
      this.currentItemID = targetItemID
    } else if (this.didEmitWillSlideOut) {
      this.notifySlideOutCancelled(this.currentItemID)
    }
    if (pending !== undefined && pending !== targetItemID) {
      this.notifySlideInCancelled(pending)
    }
    this.currentIndex = index
    this.didEmitWillSlideOut = false
  }

  private notifyWillSlideIn(itemID?: string): void {
    const pageCell = this.pageCell(itemID)
    if (pageCell === undefined) {
      return
    }
    this.logFeed('onWillSlideIn', pageCell)
    if (this.slidingInPageCell === pageCell) {
      return
    }
    this.slidingInPageCell = pageCell
    pageCell.startPreview()
  }

  private notifyDidSlideIn(itemID?: string): void {
    const pageCell = this.pageCell(itemID)
    const position = pageCell === undefined ? -1 : this.positionOfItem(pageCell.liveID)
    if (pageCell === undefined || position < 0) {
      return
    }
    this.logFeed('onDidSlideIn', pageCell, `remainingCount=${this.dataList.length - 1 - position}`)
    pageCell.joinChannel()
  }

  private notifySlideInCancelled(itemID?: string): void {
    const pageCell = this.pageCell(itemID)
    if (pageCell === undefined) {
      return
    }
    this.logFeed('onSlideInCancelled', pageCell)
    this.slidingInPageCell = undefined
    pageCell.stopPreview()
  }

  private notifyWillSlideOut(itemID?: string): void {
    const pageCell = this.pageCell(itemID)
    if (pageCell === undefined) {
      return
    }
    this.logFeed('onWillSlideOut', pageCell)
    this.slidingOutPageCell = pageCell
  }

  private notifyDidSlideOut(itemID?: string): void {
    const pageCell = this.pageCell(itemID)
    if (pageCell === undefined) {
      return
    }
    this.logFeed('onDidSlideOut', pageCell, `behavior=${this.swipeBehavior}`)
    pageCell.leaveChannel()
  }

  private notifySlideOutCancelled(itemID?: string): void {
    const pageCell = this.pageCell(itemID)
    if (pageCell === undefined) {
      return
    }
    this.logFeed('onSlideOutCancelled', pageCell)
    this.slidingOutPageCell = undefined
  }

  private pageCell(itemID?: string): PageCell | undefined {
    if (itemID === undefined) {
      return undefined
    }
    const info = this.dataList.find((item: LiveInfo) => item.liveID === itemID)
    return info === undefined ? this.pageCache.get(itemID) : this.pageCellFor(info)
  }

  private logFeed(event: string, pageCell: PageCell, extra?: string): void {
    const position = pageCell.liveID.length === 0 ? -1 : this.positionOfItem(pageCell.liveID)
    LiveKitLog.info(`[LiveListView] feedAdapter ${event}: ${pageCell.liveID.length === 0 ? '-' : pageCell.liveID}, ` +
      `position: ${position < 0 ? '-' : position}/${this.dataList.length}${extra === undefined ? '' : ` ${extra}`}`)
  }

  build() {
    Swiper() {
      ForEach(this.dataList, (liveInfo: LiveInfo) => {
        PlayerView({ controller: this.pageCellFor(liveInfo).playerView })
      }, (liveInfo: LiveInfo) => liveInfo.liveID)
    }
    .vertical(true)
    .loop(false)
    .indicator(false)
    .cachedCount(1)
    .index(this.currentIndex)
    .disableSwipe(!this.isUserInputEnabled)
    .effectMode(EdgeEffect.None)
    .width('100%')
    .height('100%')
    .backgroundColor(LiveTheme.Color.canvasBackground)
    .expandSafeArea([SafeAreaType.SYSTEM])
    .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => this.handleGestureSwipe(index, extraInfo.currentOffset))
    .onAnimationEnd((index: number) => this.settleScroll(index))
  }
}
