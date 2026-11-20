import {
  DeviceStatus,
  NetworkInfo,
  NetworkQuality,
  RoomParticipant,
  RoomParticipantState,
  RoomParticipantStore,
} from '@tencentcloud/atomicxcore'
import { RoomDataObserver } from '../../../base/util/RoomDataObserver'
import {
  RoomParticipantCell,
  RoomParticipantGridCell,
  RoomParticipantGridItem,
} from './RoomParticipantCell'
import { RoomParticipantFloatView } from './RoomParticipantFloatView'
import { RoomPageIndicatorView } from './RoomPageIndicatorView'
import {
  RoomFloatingPosition,
  RoomFloatingSide,
  RoomGridMetrics,
  RoomParticipantLayout,
} from './RoomParticipantLayout'

class RoomParticipantPage {
  readonly key: string
  readonly isScreen: boolean
  items: RoomParticipant[]

  constructor(key: string, isScreen: boolean, items: RoomParticipant[]) {
    this.key = key
    this.isScreen = isScreen
    this.items = items
  }
}

@Component
struct RoomParticipantPageView {
  @Prop roomID: string = ''
  @Prop page: RoomParticipantPage = new RoomParticipantPage('', false, [])
  @Prop @Watch('scheduleSyncGridItems') stageWidth: number = 0
  @Prop @Watch('scheduleSyncGridItems') stageHeight: number = 0
  @Prop @Watch('scheduleSyncGridItems') localParticipantID: string = ''
  @Prop @Watch('scheduleSyncGridItems') volumes: Map<string, number> = new Map()
  @Prop @Watch('scheduleSyncGridItems') networkQualities: Map<string, NetworkInfo> = new Map()
  @Prop @Watch('scheduleSyncGridItems') isPlaying: boolean = false
  @State private items: RoomParticipant[] = []
  @State private hasPagination: boolean = false
  @State private gridItems: RoomParticipantGridItem[] = []
  private store?: RoomParticipantStore
  private unsubscribeParticipants?: () => void
  private syncTimer: number = -1
  private gridSyncTimer: number = -1

  aboutToAppear(): void {
    this.items = this.page.items
    this.store = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID) : undefined
    if (this.store !== undefined) {
      this.unsubscribeParticipants = RoomDataObserver.observe(this.store.state.participantList,
        () => this.scheduleSyncItems())
    }
    this.syncItems()
  }

  aboutToDisappear(): void {
    this.unsubscribeParticipants?.()
    clearTimeout(this.syncTimer)
    clearTimeout(this.gridSyncTimer)
  }

  private scheduleSyncItems(): void {
    clearTimeout(this.syncTimer)
    this.syncTimer = setTimeout(() => this.syncItems(), 0)
  }

  private scheduleSyncGridItems(): void {
    clearTimeout(this.gridSyncTimer)
    this.gridSyncTimer = setTimeout(() => this.syncGridItems(this.items), 0)
  }

  private syncItems(): void {
    const state = this.store?.state
    if (state === undefined) {
      return
    }
    if (this.page.isScreen) {
      const screen = state.participantWithScreen
      this.items = screen !== undefined && screen.userID.length > 0 ? [screen] : []
      this.gridItems = []
      return
    }
    const seen = new Set<string>()
    const participants = state.participantList.toArray().filter((item: RoomParticipant) => {
      if (item.userID.length === 0 || seen.has(item.userID)) {
        return false
      }
      seen.add(item.userID)
      return true
    })
    this.hasPagination = participants.length > RoomParticipantLayout.pageCapacity
    const prefix = 'participants:'
    const pageIndex = this.page.key.startsWith(prefix) ? Number(this.page.key.substring(prefix.length)) : 0
    const start = pageIndex * RoomParticipantLayout.pageCapacity
    this.items = participants.slice(start, start + RoomParticipantLayout.pageCapacity)
    this.syncGridItems(this.items)
  }

  private syncGridItems(participants: RoomParticipant[]): void {
    const current = new Map<string, RoomParticipantGridItem>()
    const rects = RoomParticipantLayout.participantRects(participants.length, this.hasPagination,
      { width: this.stageWidth, height: this.stageHeight })
    this.gridItems.forEach((item: RoomParticipantGridItem) => current.set(item.userID, item))
    this.gridItems = participants.map((participant: RoomParticipant, index: number) => {
      const item = current.get(participant.userID) ?? new RoomParticipantGridItem(participant)
      const rect = rects[index]
      item.participant = participant
      item.isLocal = participant.userID === this.localParticipantID
      item.volume = this.volumes.get(participant.userID) ?? 0
      item.networkQuality = this.networkQualities.get(participant.userID)?.quality ?? NetworkQuality.unknown
      item.isPlaying = this.isPlaying
      item.x = rect.x
      item.y = rect.y
      item.width = rect.width
      item.height = rect.height
      return item
    })
  }

  private metrics(): RoomGridMetrics {
    return RoomParticipantLayout.gridMetrics(this.items.length, this.hasPagination,
      { width: this.stageWidth, height: this.stageHeight })
  }

  build() {
    Stack() {
      if (this.page.isScreen && this.items.length > 0) {
        ForEach(this.items, (item: RoomParticipant) => {
          RoomParticipantCell({
            roomID: this.roomID,
            participant: item,
            isScreenStream: this.page.isScreen,
            isLocal: item.userID === this.localParticipantID,
            volume: this.volumes.get(item.userID) ?? 0,
            networkQuality: this.networkQualities.get(item.userID)?.quality ?? NetworkQuality.unknown,
            isPlaying: this.isPlaying,
          })
            .width('100%')
            .height('100%')
        }, (item: RoomParticipant) => item.userID)
      } else {
        ForEach(this.gridItems, (item: RoomParticipantGridItem) => {
          RoomParticipantGridCell({ roomID: this.roomID, item: item })
        }, (item: RoomParticipantGridItem) => item.userID)
      }
    }
    .width('100%')
    .height('100%')
    .padding(this.page.isScreen ? this.metrics().contentInset : 0)
  }
}

@Component
export struct RoomView {
  @Prop @Watch('bindRoom') roomID: string = ''
  private participantState?: RoomParticipantState = undefined
  private participants: RoomParticipant[] = []
  @State private pages: RoomParticipantPage[] = []
  @State private volumes: Map<string, number> = new Map()
  @State private networkQualities: Map<string, NetworkInfo> = new Map()
  @State private pageIndex: number = 0
  @State private pageIndicatorTapRevision: number = 0
  @State private stageWidth: number = 0
  @State private stageHeight: number = 0
  @State private isStageVisible: boolean = false
  @State private floatingParticipant?: RoomParticipant = undefined
  @State private floatingPosition: RoomFloatingPosition =
    { side: RoomFloatingSide.RIGHT, verticalFraction: 0 }
  private store?: RoomParticipantStore
  private unsubscribe?: () => void
  private swiperController: SwiperController = new SwiperController()
  private localParticipantID?: string
  private screenParticipant?: RoomParticipant
  private speakerID?: string
  private pollTimer: number = -1
  private participantSyncTimer: number = -1
  private lastDerivedContext: string = ''

  aboutToAppear(): void {
    this.bindRoom()
    this.pollTimer = setInterval(() => this.pollLevels(), 200)
  }

  aboutToDisappear(): void {
    this.unsubscribe?.()
    clearInterval(this.pollTimer)
    clearTimeout(this.participantSyncTimer)
  }

  private bindRoom(): void {
    this.unsubscribe?.()
    clearTimeout(this.participantSyncTimer)
    this.participants = []
    this.pages = []
    this.lastDerivedContext = ''
    this.volumes = new Map()
    this.networkQualities = new Map()
    this.floatingParticipant = undefined
    this.floatingPosition = { side: RoomFloatingSide.RIGHT, verticalFraction: 0 }
    this.speakerID = undefined
    this.localParticipantID = undefined
    this.screenParticipant = undefined
    this.pageIndex = 0
    this.store = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID) : undefined
    this.participantState = this.store?.state
    if (this.store !== undefined) {
      this.unsubscribe = RoomDataObserver.observe(this.store.state.participantList, () => {
        this.scheduleParticipantSync()
      })
      this.participants = this.deduplicate(this.store.state.participantList.toArray())
    }
    this.updateDerived()
  }

  private scheduleParticipantSync(): void {
    clearTimeout(this.participantSyncTimer)
    this.participantSyncTimer = setTimeout(() => {
      this.participants = this.deduplicate(this.store?.state.participantList.toArray() ?? [])
      this.updateDerived()
    }, 0)
  }

  private deduplicate(participants: RoomParticipant[]): RoomParticipant[] {
    const seen = new Set<string>()
    return participants.filter((item: RoomParticipant) => {
      if (item.userID.length === 0 || seen.has(item.userID)) {
        return false
      }
      seen.add(item.userID)
      return true
    })
  }

  private validParticipant(participant?: RoomParticipant): RoomParticipant | undefined {
    return participant !== undefined && participant.userID.length > 0 ? participant : undefined
  }

  private pollLevels(): void {
    const state = this.participantState
    if (state === undefined) {
      return
    }
    const nextVolumes = new Map<string, number>()
    state.speakingUsers.forEach((value: number, key: string) => {
      nextVolumes.set(key, value)
    })
    const localID = this.localParticipantID
    if (localID !== undefined && localID.length > 0 && nextVolumes.has('')) {
      nextVolumes.set(localID, nextVolumes.get('') ?? 0)
    }
    const volumesChanged = !this.numberMapsEqual(this.volumes, nextVolumes)
    if (volumesChanged) {
      this.volumes = nextVolumes
    }
    const nextNetworks = new Map<string, NetworkInfo>()
    state.networkQualities.forEach((value: NetworkInfo, key: string) => {
      nextNetworks.set(key, value)
    })
    if (!this.networkMapsEqual(this.networkQualities, nextNetworks)) {
      this.networkQualities = nextNetworks
    }
    const context = this.derivedContext(this.validParticipant(state.localParticipant),
      this.validParticipant(state.participantWithScreen))
    if (context !== this.lastDerivedContext) {
      this.updateDerived()
    } else if (volumesChanged && this.screenParticipant !== undefined) {
      this.updateFloatingParticipant()
    }
  }

  private numberMapsEqual(left: Map<string, number>, right: Map<string, number>): boolean {
    if (left.size !== right.size) {
      return false
    }
    let equal = true
    left.forEach((value: number, key: string) => {
      if (right.get(key) !== value) {
        equal = false
      }
    })
    return equal
  }

  private networkMapsEqual(left: Map<string, NetworkInfo>, right: Map<string, NetworkInfo>): boolean {
    if (left.size !== right.size) {
      return false
    }
    let equal = true
    left.forEach((value: NetworkInfo, key: string) => {
      const other = right.get(key)
      if (other === undefined || other.quality !== value.quality || other.upLoss !== value.upLoss ||
        other.downLoss !== value.downLoss || other.delay !== value.delay) {
        equal = false
      }
    })
    return equal
  }

  private updateDerived(): void {
    const local = this.validParticipant(this.participantState?.localParticipant)
    const screen = this.validParticipant(this.participantState?.participantWithScreen)
    this.localParticipantID = local?.userID
    this.lastDerivedContext = this.derivedContext(local, screen)
    const startedSharing = screen !== undefined && this.screenParticipant?.userID !== screen.userID
    this.screenParticipant = screen
    this.updateFloatingParticipant(local)
    this.syncPages(screen, startedSharing)
    if (startedSharing) {
      this.floatingPosition = { side: RoomFloatingSide.RIGHT, verticalFraction: 0 }
    }
  }

  private derivedContext(local?: RoomParticipant, screen?: RoomParticipant): string {
    return `${this.participantSnapshot(local)}|${this.participantSnapshot(screen)}`
  }

  private updateFloatingParticipant(local?: RoomParticipant): void {
    const actualLocal = local ?? this.validParticipant(this.participantState?.localParticipant)
    const speaker = this.selectSpeaker(this.participants, actualLocal)
    this.speakerID = speaker?.userID
    const floating = speaker ?? actualLocal
    const next = this.screenParticipant !== undefined && floating !== undefined ? floating : undefined
    if (!this.hasSameFloatingParticipant(this.floatingParticipant, next)) {
      this.floatingParticipant = next
    }
  }

  private hasSameFloatingParticipant(first?: RoomParticipant, second?: RoomParticipant): boolean {
    if (first === undefined || second === undefined) {
      return first === second
    }
    return first.userID === second.userID && first.userName === second.userName &&
      first.avatarURL === second.avatarURL && first.role === second.role &&
      first.microphoneStatus === second.microphoneStatus && first.cameraStatus === second.cameraStatus &&
      first.screenShareStatus === second.screenShareStatus
  }

  private syncPages(screen: RoomParticipant | undefined, startedSharing: boolean): void {
    const previousPages = this.pages
    const currentKey = this.pageIndex < previousPages.length ? previousPages[this.pageIndex].key : undefined
    const nextPages: RoomParticipantPage[] = []
    if (screen !== undefined) {
      nextPages.push(new RoomParticipantPage(`screen:${screen.userID}`, true, [screen]))
    }
    for (let start = 0; start < this.participants.length; start += RoomParticipantLayout.pageCapacity) {
      const key = `participants:${start / RoomParticipantLayout.pageCapacity}`
      const items = this.participants.slice(start, start + RoomParticipantLayout.pageCapacity)
      nextPages.push(new RoomParticipantPage(key, false, items))
    }
    this.pages = nextPages

    let nextIndex = currentKey !== undefined ?
      nextPages.findIndex((page: RoomParticipantPage) => page.key === currentKey) : -1
    if (startedSharing) {
      nextIndex = 0
    } else if (nextIndex < 0) {
      nextIndex = Math.min(this.pageIndex, Math.max(nextPages.length - 1, 0))
    }
    this.pageIndex = nextIndex
  }

  private participantSnapshot(participant?: RoomParticipant): string {
    if (participant === undefined) {
      return 'nil'
    }
    return `${participant.userID}(mic=${participant.microphoneStatus},camera=${participant.cameraStatus},` +
      `screen=${participant.screenShareStatus})`
  }

  private selectSpeaker(participants: RoomParticipant[], local?: RoomParticipant): RoomParticipant | undefined {
    const seen = new Set<string>()
    const candidates = (local !== undefined ? [...participants, local] : [...participants]).filter(
      (item: RoomParticipant) => {
        if (item.userID.length === 0 || seen.has(item.userID) || item.microphoneStatus !== DeviceStatus.on) {
          return false
        }
        seen.add(item.userID)
        return true
      })
    const current = candidates.find((item: RoomParticipant) => item.userID === this.speakerID)
    let loudest: RoomParticipant | undefined
    candidates.forEach((item: RoomParticipant) => {
      const volume = this.volumes.get(item.userID) ?? 0
      if (volume > 0 && volume > (loudest !== undefined ? this.volumes.get(loudest.userID) ?? 0 : 0)) {
        loudest = item
      }
    })
    if (current === undefined) {
      return loudest
    }
    return (this.volumes.get(current.userID) ?? 0) > 0 ? current : (loudest ?? current)
  }

  private isPlayingPage(page: RoomParticipantPage): boolean {
    return this.isStageVisible && this.pageIndex < this.pages.length &&
      this.pages[this.pageIndex].key === page.key
  }

  private scrollToPage(index: number): void {
    const target = Math.min(Math.max(index, 0), Math.max(this.pages.length - 1, 0))
    this.pageIndex = target
    this.swiperController.changeIndex(target, true)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.pages.length === 0) {
        Column()
          .width('100%')
          .height('100%')
      } else {
        Swiper(this.swiperController) {
          ForEach(this.pages, (page: RoomParticipantPage) => {
            RoomParticipantPageView({
              roomID: this.roomID,
              page: page,
              stageWidth: this.stageWidth,
              stageHeight: this.stageHeight,
              localParticipantID: this.localParticipantID ?? '',
              volumes: this.volumes,
              networkQualities: this.networkQualities,
              isPlaying: this.isPlayingPage(page),
            })
          }, (page: RoomParticipantPage) => page.key)
        }
        .width('100%')
        .height('100%')
        .index(this.pageIndex)
        .loop(false)
        .indicator(false)
        .effectMode(EdgeEffect.None)
        .onChange((index: number) => {
          this.pageIndex = index
        })
        .onClick(() => {
          this.pageIndicatorTapRevision++
        })
      }

      RoomPageIndicatorView({
        currentPage: this.pageIndex,
        pageCount: this.pages.length,
        stageTapRevision: this.pageIndicatorTapRevision,
        onPreviousPage: () => this.scrollToPage(this.pageIndex - 1),
        onNextPage: () => this.scrollToPage(this.pageIndex + 1),
      })

      if (this.floatingParticipant !== undefined && this.pages.length > 0 &&
        this.pages[Math.min(this.pageIndex, this.pages.length - 1)].isScreen) {
        RoomParticipantFloatView({
          roomID: this.roomID,
          participant: this.floatingParticipant,
          isLocal: this.floatingParticipant.userID === this.localParticipantID,
          volume: this.volumes.get(this.floatingParticipant.userID) ?? 0,
          networkQuality: this.networkQualities.get(this.floatingParticipant.userID)?.quality ??
            NetworkQuality.unknown,
          isPlaying: this.isStageVisible,
          stageWidth: this.stageWidth,
          stageHeight: this.stageHeight,
          settledPosition: this.floatingPosition,
          onPositionChange: (position: RoomFloatingPosition) => {
            this.floatingPosition = position
          },
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.roomkit_bg_surface'))
    .onAreaChange((_: Area, area: Area) => {
      this.stageWidth = area.width as number
      this.stageHeight = area.height as number
    })
    .onVisibleAreaChange([0.01], (visible: boolean) => {
      this.isStageVisible = visible
    })
  }
}
