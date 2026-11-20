import { BasicData, BasicDataSource } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { CoHostState, CoHostUser } from './PusherCoHostStore'
import { PusherCoHostRandomConnectionView } from './PusherCoHostRandomConnectionView'

@Observed
class CandidateRow extends BasicData {
  user?: CoHostUser
  title: string = ''
  connected: boolean = false
  busy: boolean = false
  invited: boolean = false
  spacer: number = 0
  constructor(id: string) { super(); this.ID = id }
}

@Component
struct CandidateUserRow {
  @ObjectLink row: CandidateRow
  onAction?: (id: string, cancel: boolean) => void
  build() {
    Row() {
      Image(this.row.user?.avatarURL || LiveKitResources.image('livekit_livelist_default_avatar'))
        .alt(LiveKitResources.image('livekit_livelist_default_avatar')).width(44).height(44)
        .borderRadius(22).objectFit(ImageFit.Cover).clip(true)
      Text(this.row.user?.userName ?? '').fontSize(13).fontColor(Color.White).layoutWeight(1)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ left: 11, right: 8 })
      Text(LiveKitResources.localizedString(this.row.connected ? 'tuilivekit.pusher.cohost.connected' :
        (this.row.busy ? 'tuilivekit.common.processing' : (this.row.invited ?
          'tuilivekit.pusher.cohost.cancel_invitation' : 'tuilivekit.pusher.cohost.invite'))))
        .fontSize(12).fontColor(this.row.connected ? '#47FFFFFF' : '#FFFFFFFF')
        .height(34).width(94).borderRadius(10).textAlign(TextAlign.Center).maxLines(1)
        .minFontSize(9).maxFontSize(12).backgroundColor(this.row.connected ? '#0AFFFFFF' : '#771963DD')
        .border({ width: 1, color: this.row.connected ? '#0DFFFFFF' : '#6462ABFF' })
        .enabled(!this.row.connected && !this.row.busy)
        .onClick(() => this.onAction?.(this.row.user?.liveID ?? '', this.row.invited))
    }.width('100%').height(66).padding({ left: 4, right: 4 })
      .border({ width: { bottom: px2vp(1) }, color: '#12FFFFFF' })
  }
}

@Component
export struct PusherCoHostCandidateListView {
  @Prop @Watch('presentationChanged') isPresented: boolean = false
  @Prop @Watch('updateRows') state: CoHostState = new CoHostState()
  @Prop @Watch('updateRows') isAdding: boolean = false
  @Prop active: boolean = true
  @Prop hostAvatar: string = ''
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  onDismiss?: () => void
  onDidDismiss?: () => void
  onBack?: () => void
  onInvite?: (id: string) => void
  onCancel?: (id: string) => void
  onRefresh?: () => void
  onLoadMore?: () => void
  @State private containerHeight: number = 0
  @State private radarVisible: boolean = true
  @State private refreshing: boolean = false
  private readonly rows: BasicDataSource<CandidateRow> = new BasicDataSource()
  private readonly scroller: Scroller = new Scroller()
  aboutToAppear(): void { this.updateRows() }
  private presentationChanged(): void {
    if (this.isPresented) {
      this.scroller.scrollToIndex(0)
      this.radarVisible = true
      this.onRefresh?.()
    }
  }
  private updateRows(): void {
    if (!this.state.isLoading) this.refreshing = false
    const previous = new Map<string, CandidateRow>()
    this.rows.getAllData().forEach((row: CandidateRow) => previous.set(row.ID, row))
    const result: CandidateRow[] = []
    const groups: CoHostUser[][] = [[], []]
    this.state.candidates.forEach((user: CoHostUser) => {
      const followed = this.isAdding ? user.followType === 3 : (user.followType === 1 || user.followType === 3)
      groups[followed ? 0 : 1].push(user)
    })
    for (let group = 0; group < groups.length; group++) {
      if (!groups[group].length) continue
      const header = new CandidateRow(`header:${group}`)
      header.title = LiveKitResources.localizedString(group === 1 ? 'tuilivekit.pusher.cohost.recommended' :
        (this.isAdding ? 'tuilivekit.pusher.cohost.mutual' : 'tuilivekit.pusher.cohost.following'))
      result.push(header)
      groups[group].forEach((user: CoHostUser) => {
        const row = previous.get(user.liveID) ?? new CandidateRow(user.liveID)
        if (row.user?.userName !== user.userName || row.user?.avatarURL !== user.avatarURL ||
          row.user?.userID !== user.userID) row.user = user
        row.connected = this.state.connected.some((item: CoHostUser) => item.liveID === user.liveID)
        row.busy = this.state.isBusy(user.liveID)
        row.invited = this.state.isInvited(user.liveID)
        result.push(row)
      })
      const spacer = new CandidateRow(`spacer:${group}`)
      spacer.spacer = !this.isAdding && group === 0 ? 26 : 14
      result.push(spacer)
    }
    this.rows.setData(result)
  }
  private sheetHeight(): number {
    return Math.min(550 + this.safeBottom,
      this.containerHeight > 0 ? Math.max(0, this.containerHeight - 80) : 550 + this.safeBottom)
  }
  private retry(): void {
    if (this.state.isLoading) return
    if (this.state.loadError || !this.state.candidates.length) this.onRefresh?.()
    else this.onLoadMore?.()
  }
  build() {
    Stack() {
      BottomSheetView({ isPresented: this.isPresented, sheetHeight: this.sheetHeight(),
        onDismiss: this.onDismiss, sheetDidDismiss: this.onDidDismiss }) {
        Column() {
          Row() {
            if (this.isAdding) {
              Image(LiveKitResources.image('livekit_cohost_back')).objectFit(ImageFit.Contain)
                .width(44).height(44).padding(11).onClick(() => this.onBack?.())
                .accessibilityText(LiveKitResources.localizedString('tuilivekit.common.back'))
            }
            Text(LiveKitResources.localizedString(this.isAdding ? 'tuilivekit.pusher.cohost.invite_title' :
              'tuilivekit.pusher.cohost.interaction_title')).fontSize(15).fontWeight(600)
              .fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          }.height(34).width('100%').margin({ top: this.isAdding ? 46 : 30, bottom: this.isAdding ? 18 : 14 })
            .padding({ left: this.isAdding ? 8 : 18, right: 18 })
          Refresh({ refreshing: this.refreshing }) {
            List({ scroller: this.scroller }) {
              if (!this.isAdding) {
                ListItem() {
                  PusherCoHostRandomConnectionView({ active: this.isPresented && this.active && this.radarVisible,
                    hostAvatar: this.hostAvatar, candidates: this.state.candidates }).margin({ bottom: 12, right: 2 })
                }
              }
              LazyForEach(this.rows, (row: CandidateRow) => {
                ListItem() {
                  if (row.user) {
                    CandidateUserRow({ row: row, onAction: (id: string, cancel: boolean) => {
                      if (cancel) this.onCancel?.(id)
                      else this.onInvite?.(id)
                    } })
                  } else if (row.title) {
                    Text(row.title).fontSize(13).fontColor('#C7FFFFFF').width('100%').height(!this.isAdding && row.ID === 'header:0' ? 32 : 31)
                      .padding({ top: 4, left: 2, right: 2 }).textAlign(TextAlign.Start)
                  } else { Blank().height(row.spacer) }
                }
              }, (row: CandidateRow) => row.ID)
              if (!this.state.candidates.length && !this.state.isLoading && !this.state.loadError) {
                ListItem() {
                  Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.empty'))
                    .fontSize(13).fontColor('#7AFFFFFF').width('100%').height(60).textAlign(TextAlign.Center)
                }
              }
              if (this.state.isLoading || this.state.hasMore || this.state.loadError) {
                ListItem() {
                  Text(LiveKitResources.localizedString(this.state.isLoading ? 'tuilivekit.common.processing' :
                    (this.state.loadError ? 'tuilivekit.pusher.cohost.retry' : 'tuilivekit.pusher.cohost.load_more')))
                    .fontSize(13).fontColor('#C7FFFFFF').width('100%').height(44).textAlign(TextAlign.Center)
                    .enabled(!this.state.isLoading).onClick(() => this.retry())
                }
              }
            }.width('100%').height('100%').scrollBar(BarState.Off)
              .onScrollIndex((first: number) => this.radarVisible = first === 0)
              .onReachEnd(() => {
                if (this.isPresented && this.state.hasMore && !this.state.isLoading && !this.state.loadError) {
                  this.onLoadMore?.()
                }
              })
          }.layoutWeight(1).width('100%').padding({ left: 16, right: 16, bottom: 16 + this.safeBottom })
            .onRefreshing(() => { this.refreshing = true; this.onRefresh?.() })
        }.width('100%').height('100%')
      }
    }.width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .onAreaChange((_: Area, area: Area) => this.containerHeight = Number(area.height))
  }
}
