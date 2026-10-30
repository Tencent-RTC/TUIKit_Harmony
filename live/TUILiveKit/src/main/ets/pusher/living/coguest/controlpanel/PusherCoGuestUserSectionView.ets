import { BasicData, BasicDataSource } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../../../common/LiveKitResources'
import { LiveText } from '../../../../common/theme/LiveText'
import { LiveTheme, rgba, white } from '../../../../common/theme/LiveTheme'
import { User } from '../PusherCoGuestStore'

export enum ActionStyle {
  primary,
  destructive,
}

@Observed
export class UserRow extends BasicData {
  user: User
  actionTitle: string
  actionStyle: ActionStyle
  isPending: boolean
  isEnabled: boolean

  constructor(user: User, actionTitle: string, actionStyle: ActionStyle, isPending: boolean, isEnabled: boolean) {
    super()
    this.ID = user.userID
    this.user = user
    this.actionTitle = actionTitle
    this.actionStyle = actionStyle
    this.isPending = isPending
    this.isEnabled = isEnabled
  }
}

export class PusherCoGuestGroupStyle {
  static readonly background: string = 'rgba(0, 0, 0, 0.278)'
  static readonly cornerRadius: number = 16
}

const rowsTop: number = 50
const rowHeight: number = 52
const bottomInset: number = 16
const emptyHeight: number = 152

export function preferredHeight(rows: UserRow[]): number {
  return rows.length === 0 ? emptyHeight : rowsTop + rows.length * rowHeight + bottomInset
}

@Component
export struct PusherCoGuestUserSectionView {
  @Prop sectionTitle: string = ''
  @Prop emptyText: string = ''
  @Prop showsCount: boolean = false
  @Prop @Watch('updateRows') rows: UserRow[] = []
  private readonly data: BasicDataSource<UserRow> = new BasicDataSource()

  aboutToAppear(): void {
    this.updateRows()
  }

  private updateRows(): void {
    const current = new Map<string, UserRow>()
    this.data.getAllData().forEach((row: UserRow) => current.set(row.ID, row))
    this.data.setData(this.rows.map((next: UserRow) => {
      const row = current.get(next.ID)
      if (row === undefined) {
        return next
      }
      row.user = next.user
      row.actionTitle = next.actionTitle
      row.actionStyle = next.actionStyle
      row.isPending = next.isPending
      row.isEnabled = next.isEnabled
      return row
    }))
  }

  onAction?: (userID: string) => void

  @Builder
  sectionHeader() {
    Column() {
      Text(this.showsCount && this.rows.length > 0 ? `${this.sectionTitle}（${this.rows.length}）` : this.sectionTitle)
        .attributeModifier(new LiveText(LiveTheme.TextRole.sectionTitle, LiveTheme.TextTone.secondary))
        .width('100%')
        .height(15)
        .margin({ top: 16 })
      if (this.rows.length > 0) {
        Divider().strokeWidth(1).color(white(0.07)).margin({ top: 12 })
      }
    }
    .height(rowsTop)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  sectionFooter() {
    Blank().height(bottomInset)
  }

  build() {
    ListItemGroup({ header: this.sectionHeader(), footer: this.sectionFooter() }) {
      if (this.rows.length === 0) {
        ListItem() {
          Text(this.emptyText)
            .attributeModifier(new LiveText(LiveTheme.TextRole.body, LiveTheme.TextTone.secondary, TextAlign.Center))
            .width('100%')
            .height(emptyHeight - rowsTop - bottomInset)
            .padding({ left: 16, right: 16 })
        }
      } else {
        LazyForEach(this.data, (row: UserRow) => {
          ListItem() {
            PusherCoGuestUserRowView({ row: row, onAction: this.onAction })
          }.padding({ left: 16, right: 16 })
        }, (row: UserRow) => row.ID)
      }
    }
    .borderRadius(PusherCoGuestGroupStyle.cornerRadius)
    .backgroundColor(PusherCoGuestGroupStyle.background)
    .clip(true)
  }
}

@Component
struct PusherCoGuestUserRowView {
  @ObjectLink row: UserRow
  onAction?: (userID: string) => void

  build() {
    Row() {
      Image(this.row.user.avatarURL)
        .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
        .width(34)
        .height(34)
        .borderRadius(17)
        .borderWidth(1)
        .borderColor(LiveTheme.Color.brand(0.22))
        .objectFit(ImageFit.Cover)
      Text(this.row.user.userName)
        .attributeModifier(new LiveText(LiveTheme.TextRole.itemTitle, LiveTheme.TextTone.secondary))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .flexShrink(1)
        .margin({ left: 10, right: 10 })
      Blank()
      Text(this.row.isPending ? LiveKitResources.localizedString('tuilivekit.common.processing') : this.row.actionTitle)
        .fontSize(12)
        .fontColor(this.row.actionStyle === ActionStyle.primary ? Color.White : rgba(1, 0.439, 0.463))
        .textAlign(TextAlign.Center)
        .height(36)
        .constraintSize({ minWidth: 68 })
        .padding({ left: 8, right: 8 })
        .borderRadius(10)
        .borderWidth(1)
        .borderColor(
          this.row.actionStyle === ActionStyle.primary ? rgba(0.412, 0.682, 1, 0.338) : rgba(1, 0.31, 0.34, 0.22))
        .backgroundColor(this.row.actionStyle === ActionStyle.primary ? rgba(0.133, 0.416, 0.871, 0.393) :
          rgba(1, 0.31, 0.34, 0.1))
        .enabled(this.row.isEnabled && !this.row.isPending)
        .opacity(this.row.isEnabled && !this.row.isPending ? 1 : 0.46)
        .onClick(() => this.onAction?.(this.row.user.userID))
    }
    .width('100%')
    .height(rowHeight)
  }
}
