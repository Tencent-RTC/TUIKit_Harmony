import { LiveAudienceStore, LiveUserInfo, LoginStore } from '@tencentcloud/atomicxcore'
import { LiveKitDataObserver, LiveKitResources } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { LevelBadgeView } from '../../../common/theme/LevelBadgeView'
import { LiveAudienceRowStyle, LiveTheme, white } from '../../../common/theme/LiveTheme'
import { AudienceProfilePanel } from './AudienceProfilePanel'

export class Item {
  id: string
  name: string
  avatarURL: string
  level: number
  giftValue: string

  constructor(audience: LiveUserInfo) {
    this.id = audience.userID
    this.name = audience.userName
    this.avatarURL = audience.avatarURL
    this.level = audience.level
    this.giftValue = '0'
  }
}

@Component
export struct AudienceListPanel {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop liveID: string = ''
  onDismiss?: () => void
  @State private items: Item[] = []
  @State private profileItem: Item | undefined = undefined
  @State private isProfilePresented: boolean = false
  private unobserve?: () => void

  aboutToDisappear(): void {
    this.unobserve?.()
  }

  private onPresentedChanged(): void {
    if (!this.isPresented || this.liveID.length === 0) {
      return
    }
    this.unobserve?.()
    const subscribedLiveID = this.liveID
    const store = LiveAudienceStore.create(subscribedLiveID)
    const apply = () => {
      if (this.liveID === subscribedLiveID) {
        this.items = store.liveAudienceState.audienceList.getAllData().map((audience: LiveUserInfo) => new Item(audience))
      }
    }
    this.unobserve = LiveKitDataObserver.observe(store.liveAudienceState.audienceList, apply)
    apply()
    store.fetchAudienceList().catch(() => {
    })
  }

  private sheetDidDismiss(): void {
    this.unobserve?.()
    this.unobserve = undefined
  }

  private select(item: Item): void {
    const selfUserID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (item.id.length === 0 || item.id === selfUserID) {
      return
    }
    this.profileItem = item
    this.isProfilePresented = true
    this.onDismiss?.()
  }

  @Builder
  audienceListCell(item: Item, rank: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      Text(`${rank}`)
        .fontSize(15)
        .fontColor(white(0.38))
        .textAlign(TextAlign.Center)
        .width(LiveAudienceRowStyle.rankWidth)
        .height(LiveAudienceRowStyle.rankHeight)
        .position({ x: LiveAudienceRowStyle.edgeInset, y: (64 - LiveAudienceRowStyle.rankHeight) / 2 })
      Image(item.avatarURL)
        .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
        .width(LiveAudienceRowStyle.avatarSize)
        .height(LiveAudienceRowStyle.avatarSize)
        .borderRadius(LiveAudienceRowStyle.avatarRadius)
        .objectFit(ImageFit.Cover)
        .position({ x: LiveAudienceRowStyle.avatarLeading, y: LiveAudienceRowStyle.avatarTop })
      Row({ space: 6 }) {
        Text(this.displayName(item))
          .fontSize(15)
          .fontColor(white(0.88))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 100 })
          .height(21)
        LevelBadgeView({ level: item.level })
      }
      .height(64)
      .position({ x: LiveAudienceRowStyle.nameLeading, y: 0 })
      Text(item.giftValue)
        .fontSize(LiveAudienceRowStyle.giftValueFontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(LiveTheme.Color.audienceGiftValue)
        .textAlign(TextAlign.End)
        .width(LiveAudienceRowStyle.giftValueWidth)
        .height(LiveAudienceRowStyle.giftValueHeight)
        .position({ right: LiveAudienceRowStyle.edgeInset, top: (64 - LiveAudienceRowStyle.giftValueHeight) / 2 })
      Divider()
        .strokeWidth(0.5)
        .color(LiveAudienceRowStyle.separator)
        .position({ left: LiveAudienceRowStyle.edgeInset, bottom: 0 })
        .width('94%')
    }
    .width('100%')
    .height(64)
    .onClick(() => this.select(item))
  }

  private displayName(item: Item): string {
    const name = item.name.length === 0 ? item.id : item.name
    const characters = Array.from(name)
    return characters.length > 10 ? characters.slice(0, 10).join('') + '…' : name
  }

  build() {
    Stack() {
      BottomSheetView({
        isPresented: this.isPresented,
        sheetHeight: 422,
        sheetTitle: LiveKitResources.localizedString('tuilivekit.player.online_audience'),
        onDismiss: () => this.onDismiss?.(),
        sheetDidDismiss: () => this.sheetDidDismiss(),
      }) {
        List() {
          ForEach(this.items, (item: Item, index: number) => {
            ListItem() {
              this.audienceListCell(item, index + 1)
            }
          }, (item: Item) => item.id)
        }
        .scrollBar(BarState.Off)
        .margin({ top: 58, bottom: 24 })
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
        .height(422 - 58 - 24)
      }
      if (this.profileItem !== undefined) {
        AudienceProfilePanel({
          isPresented: this.isProfilePresented,
          userID: this.profileItem.id,
          userName: this.profileItem.name,
          avatarURL: this.profileItem.avatarURL,
          onDismiss: () => this.isProfilePresented = false,
        })
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
