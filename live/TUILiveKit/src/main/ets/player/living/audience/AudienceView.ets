import {
  LiveAudienceListener,
  LiveAudienceState,
  LiveAudienceStore,
  LiveUserInfo,
  LoginStore,
} from '@tencentcloud/atomicxcore'
import { AudienceWelcome } from '../../../common/audience/AudienceWelcomeView'
import { LiveKitDataObserver, LiveKitResources } from '../../../common/LiveKitResources'
import { LiveVideoOverlayStyle } from '../../../common/theme/LiveTheme'

const maxShowAvatarCount: number = 3
const avatarSize: number = 26
const avatarStep: number = 17

export class AudienceAvatarItem {
  id: string
  avatarURL: string

  constructor(id: string, avatarURL: string) {
    this.id = id
    this.avatarURL = avatarURL
  }
}

@Component
export struct AudienceView {
  @Prop @Watch('bind') liveID: string = ''
  @Prop cleanScreenProgress: number = 0
  @Prop travelDistance: number = 0
  onToast?: (message: string) => void
  onAudience?: () => void
  onAudienceEntered?: (welcome: AudienceWelcome) => void
  @State private audienceState: LiveAudienceState = new LiveAudienceState()
  @State private items: AudienceAvatarItem[] = []
  private unobserve?: () => void
  private listener?: LiveAudienceListener
  private store?: LiveAudienceStore
  private lastTapTime: number = 0

  aboutToAppear(): void {
    this.bind()
  }

  aboutToDisappear(): void {
    this.unbind()
  }

  private bind(): void {
    this.unbind()
    if (this.liveID.length === 0) {
      return
    }
    const subscribedLiveID = this.liveID
    const store = LiveAudienceStore.create(subscribedLiveID)
    this.store = store
    this.audienceState = store.liveAudienceState
    this.unobserve = LiveKitDataObserver.observe(store.liveAudienceState.audienceList, () => this.renderAudienceList())
    this.renderAudienceList()
    const listener = new LiveAudienceListener()
    listener.onAudienceMessageDisabled = (audience: LiveUserInfo, isDisable: boolean) => {
      if (this.liveID === subscribedLiveID && audience.userID === LoginStore.shared().state.loginUserInfo?.userID) {
        this.onToast?.(LiveKitResources.localizedString(isDisable ? 'tuilivekit.player.audience.message_disabled' :
          'tuilivekit.player.audience.message_enabled'))
      }
    }
    listener.onAudienceJoined = (audience: LiveUserInfo) => {
      if (this.liveID === subscribedLiveID && audience.userID.length > 0) {
        this.onAudienceEntered?.(new AudienceWelcome(audience.userID,
          audience.userName.length === 0 ? audience.userID : audience.userName, Math.max(0, audience.level)))
      }
    }
    this.listener = listener
    store.addLiveAudienceListener(listener)
    store.fetchAudienceList().catch(() => {
    })
  }

  private unbind(): void {
    this.unobserve?.()
    this.unobserve = undefined
    if (this.listener !== undefined) {
      this.store?.removeLiveAudienceListener(this.listener)
      this.listener = undefined
    }
    this.store = undefined
    this.lastTapTime = 0
    this.audienceState = new LiveAudienceState()
    this.items = []
  }

  private renderAudienceList(): void {
    const next = (this.store?.liveAudienceState.audienceList.getAllData() ?? []).slice(0, maxShowAvatarCount)
      .map((audience: LiveUserInfo) => new AudienceAvatarItem(audience.userID, audience.avatarURL))
    if (next.length === this.items.length && next.every((item: AudienceAvatarItem, index: number) =>
      item.id === this.items[index].id && item.avatarURL === this.items[index].avatarURL)) {
      return
    }
    this.items = next
  }

  private handleTap(): void {
    if (this.liveID.length === 0) {
      return
    }
    const now = Date.now() / 1000
    if (now - this.lastTapTime < 1) {
      return
    }
    this.lastTapTime = now
    this.onAudience?.()
  }

  build() {
    Row({ space: 4 }) {
      if (this.items.length > 0) {
        Stack({ alignContent: Alignment.TopStart }) {
          ForEach(this.items, (item: AudienceAvatarItem, index: number) => {
            Image(item.avatarURL)
              .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
              .width(avatarSize)
              .height(avatarSize)
              .borderRadius(avatarSize / 2)
              .objectFit(ImageFit.Cover)
              .position({ x: index * avatarStep, y: 0 })
              .zIndex(this.items.length - index)
          }, (item: AudienceAvatarItem) => item.id)
        }
        .width(avatarSize + Math.max(this.items.length - 1, 0) * avatarStep)
        .height(avatarSize)
      }
      Text(`${this.audienceState.audienceCount}`)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .minFontSize(9.6)
        .maxFontSize(12)
        .maxLines(1)
        .height(26)
        .constraintSize({ minWidth: 26 })
        .padding({ left: 8, right: 8 })
        .borderRadius(13)
        .backgroundColor(LiveVideoOverlayStyle.capsuleBackground)
    }
    .height(26)
    .translate({ x: this.travelDistance * Math.min(Math.max(this.cleanScreenProgress, 0), 1) })
    .opacity(1 - Math.min(Math.max(this.cleanScreenProgress, 0), 1))
    .enabled(this.cleanScreenProgress === 0)
    .accessibilityText(LiveKitResources.localizedFormat('tuilivekit.player.audience_count', this.audienceState.audienceCount))
    .onClick(() => this.handleTap())
  }
}
