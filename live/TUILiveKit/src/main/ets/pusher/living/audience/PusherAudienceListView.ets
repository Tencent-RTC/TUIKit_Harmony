import measure from '@ohos.measure'
import { BasicData, BasicDataSource } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { LevelBadgeView } from '../../../common/theme/LevelBadgeView'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveAudienceRowStyle, LiveTheme } from '../../../common/theme/LiveTheme'
import { User } from './PusherAudienceStore'

@Observed
class AudienceRow extends BasicData {
  user: User
  rank: number

  constructor(user: User, rank: number) {
    super()
    this.ID = user.userID
    this.user = user
    this.rank = rank
  }
}

@Component
export struct PusherAudienceListView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop @Watch('updateRows') audience: User[] = []
  private readonly data: BasicDataSource<AudienceRow> = new BasicDataSource()
  @State private rankWidth: number = LiveAudienceRowStyle.rankWidth

  aboutToAppear(): void {
    this.updateRows()
  }

  private updateRows(): void {
    const current = new Map<string, AudienceRow>()
    this.data.getAllData().forEach((row: AudienceRow) => current.set(row.ID, row))
    this.data.setData(this.audience.map((user: User, index: number) => {
      const row = current.get(user.userID) ?? new AudienceRow(user, index + 1)
      row.user = user
      row.rank = index + 1
      return row
    }))
    const digits = `${Math.max(1, this.audience.length)}`.length
    const widths = Array.from<number>({ length: 10 }).map((_: number, digit: number) =>
    measure.measureText(
      { textContent: `${digit}`.repeat(digits), fontSize: LiveTheme.Typography.size(LiveTheme.TextRole.listTitle) }))
    this.rankWidth = Math.max(LiveAudienceRowStyle.rankWidth, this.getUIContext().px2vp(Math.max(...widths)))
  }

  onDismiss?: () => void
  onRefresh?: () => void
  onSelectAudience?: (user: User) => void
  private selectedAudience?: User

  private onPresentedChanged(): void {
    if (this.isPresented) {
      this.selectedAudience = undefined
      this.onRefresh?.()
    }
  }

  cancelPendingSelection(): void {
    this.selectedAudience = undefined
  }

  private sheetDidDismiss(): void {
    const selected = this.selectedAudience
    this.selectedAudience = undefined
    if (selected !== undefined) {
      this.onSelectAudience?.(selected)
    }
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: 422,
      sheetTitle: LiveKitResources.localizedString('tuilivekit.player.online_audience'),
      onDismiss: () => this.onDismiss?.(),
      sheetDidDismiss: () => this.sheetDidDismiss(),
    }) {
      List() {
        LazyForEach(this.data, (row: AudienceRow) => {
          ListItem() {
            PusherAudienceRowView({
              row: row, rankWidth: this.rankWidth, onSelect: (user: User) => {
                this.selectedAudience = user
                this.onDismiss?.()
              }
            })
          }
        }, (row: AudienceRow) => row.ID)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height(422 - 58 - 24)
      .margin({ top: 58 })
      .padding({ left: 16, right: 16 })
    }
  }
}

@Component
struct PusherAudienceRowView {
  @ObjectLink row: AudienceRow
  @Prop rankWidth: number = LiveAudienceRowStyle.rankWidth
  onSelect?: (user: User) => void

  build() {
    Row() {
      Text(`${this.row.rank}`)
        .attributeModifier(new LiveText(LiveTheme.TextRole.listTitle, LiveTheme.TextTone.disabled, TextAlign.Center))
        .width(this.rankWidth)
        .height(LiveAudienceRowStyle.rankHeight)
      Image(this.row.user.avatarURL)
        .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
        .width(LiveAudienceRowStyle.avatarSize)
        .height(LiveAudienceRowStyle.avatarSize)
        .borderRadius(LiveAudienceRowStyle.avatarRadius)
        .objectFit(ImageFit.Cover)
        .margin({
          left: LiveAudienceRowStyle.avatarLeading - LiveAudienceRowStyle.edgeInset - LiveAudienceRowStyle.rankWidth
        })
      Text(this.row.user.userName.length === 0 ? this.row.user.userID : this.row.user.userName)
        .attributeModifier(new LiveText(LiveTheme.TextRole.listTitle, LiveTheme.TextTone.secondary))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .height(21)
        .flexShrink(1)
        .margin({
          left: LiveAudienceRowStyle.nameLeading - LiveAudienceRowStyle.avatarLeading - LiveAudienceRowStyle.avatarSize
        })
      LevelBadgeView({ level: this.row.user.level }).margin({ left: 8, right: 12 })
      Blank()
      Text('0')
        .fontSize(LiveAudienceRowStyle.giftValueFontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(LiveTheme.Color.audienceGiftValue)
        .textAlign(TextAlign.End)
        .width(LiveAudienceRowStyle.giftValueWidth)
        .height(LiveAudienceRowStyle.giftValueHeight)
    }
    .width('100%')
    .height(64)
    .padding({ left: LiveAudienceRowStyle.edgeInset, right: LiveAudienceRowStyle.edgeInset })
    .border({ width: { bottom: 0.5 }, color: { bottom: LiveAudienceRowStyle.separator } })
    .onClick(() => {
      this.onSelect?.(this.row.user)
    })
  }
}
