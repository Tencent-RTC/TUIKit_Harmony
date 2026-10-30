import { LiveInfo, LoginStore, UserProfile } from '@tencentcloud/atomicxcore'
import { AudienceWelcome, AudienceWelcomeView } from '../../common/audience/AudienceWelcomeView'
import { BarrageInputView } from '../../common/barrage/BarrageInputView'
import { BarrageUIState, BarrageUIStore, Comment } from '../../common/barrage/BarrageStore'
import { BarrageStreamView, defaultWidthRatio, Message } from '../../common/barrage/BarrageStreamView'
import { GiftDisplayController, GiftDisplayItem, GiftDisplayView } from '../../common/gift/display/GiftDisplayView'
import { GiftBarrageStore, LiveGiftBarrage } from '../../common/gift/GiftBarrageStore'
import { GiftSendComboButton } from '../../common/gift/send/GiftSendComboButton'
import { GiftSendPanelView } from '../../common/gift/send/GiftSendPanelView'
import { GiftCategoryGroup, GiftItem, GiftSendState, GiftSendStore } from '../../common/gift/send/GiftSendStore'
import { LikeAnimationController, LikeAnimationView } from '../../common/like/LikeAnimationView'
import { LiveUIState, LiveUIStore } from '../../common/like/LiveUIStore'
import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { LiveToast } from '../../common/theme/LiveToastView'
import { rgba, white } from '../../common/theme/LiveTheme'
import { AudienceListPanel } from './audience/AudienceListPanel'
import { AudienceView } from './audience/AudienceView'
import { CoGuestIcon, CoGuestIconController, CoGuestStatus } from './coguest/CoGuestIcon'
import { CoGuestingPanel } from './coguest/CoGuestingPanel'
import { applyForSeat, RequestingPanel } from './coguest/RequestingPanel'
import { Mode, SettingsPanel } from './coguest/SettingsPanel'
import { HostInfoView } from './hostinfo/HostInfoView'

const bottomBarBottomInset: number = 3
const bottomBarHeight: number = 39
const toolbarHorizontalInset: number = 12
const messageBottomSpacing: number = 12
const giftMessageSpacing: number = 4
const giftOverlayBaseOffset: number = bottomBarBottomInset + bottomBarHeight + messageBottomSpacing + giftMessageSpacing

@Observed
export class LivingViewController {
  onToast?: (message: string) => void
  readonly coGuest: CoGuestIconController = new CoGuestIconController()
  readonly likeAnimation: LikeAnimationController = new LikeAnimationController()
  giftDisplay?: GiftDisplayController
  liveInfo?: LiveInfo
  isJoinedChannel: boolean = false
  isCleanScreen: boolean = false
  cleanScreenProgress: number = 0
  messages: Message[] = []
  messageContentHeight: number = 0
  isCommentComposerPresented: boolean = false
  commentResetToken: number = 0
  isGiftPanelPresented: boolean = false
  isAudienceListPresented: boolean = false
  isGiftPanelAbove: boolean = false
  giftCategories: GiftCategoryGroup[] = []
  isGiftLoading: boolean = false
  likeCount: number = 0
  floatingCombo?: GiftItem
  floatingComboID: number = 0
  welcome?: AudienceWelcome
  welcomeResetToken: number = 0
  audienceListLiveID: string = ''
  likeButtonCenter: Position = { x: 0, y: 0 }
  viewWidth: number = 1
  private activatedRoomLiveID?: string
  private cleanScreenStateAtGestureStart: boolean = false
  private lastStageLikeTapTime: number = 0
  private readonly commentStore: BarrageUIStore = new BarrageUIStore()
  private readonly giftSendStore: GiftSendStore = new GiftSendStore()
  private readonly giftBarrageStore: GiftBarrageStore = new GiftBarrageStore()
  private readonly likeStore: LiveUIStore = new LiveUIStore()

  constructor() {
    this.commentStore.onSendError = (message: string) => {
      if (this.isJoinedChannel && this.activatedRoomLiveID === this.liveInfo?.liveID) {
        this.onToast?.(message)
      }
    }
    this.commentStore.onStateChanged = (state: BarrageUIState) => {
      if (this.liveInfo?.liveID === state.liveID) {
        this.messages = state.comments.map((comment: Comment) => new Message(comment.id, comment.senderName,
          comment.text, comment.level, comment.isHost, comment.gift))
      }
    }
    this.giftBarrageStore.onGiftBarrageSettled = (gift: LiveGiftBarrage) => this.commentStore.appendGiftBarrage(gift)
    this.giftSendStore.onStateChanged = (state: GiftSendState) => {
      this.giftCategories = state.categories
      this.isGiftLoading = state.isLoading
    }
    this.likeStore.onStateChanged = (state: LiveUIState) => this.likeCount = state.likeCount
  }

  set onCoGuestUiStateChanged(callback: ((state: CoGuestStatus) => void) | undefined) {
    this.coGuest.onUiStateChanged = callback
  }

  get onCoGuestUiStateChanged(): ((state: CoGuestStatus) => void) | undefined {
    return this.coGuest.onUiStateChanged
  }

  bind(liveInfo: LiveInfo): void {
    this.updateLiveInfo(liveInfo)
    this.messages = []
  }

  updateLiveInfo(liveInfo: LiveInfo): void {
    this.liveInfo = liveInfo
    this.coGuest.activate(liveInfo)
  }

  setJoinedChannel(joined: boolean): void {
    if (this.isJoinedChannel === joined) {
      return
    }
    this.isJoinedChannel = joined
    if (!joined) {
      this.dismissInteractionOverlays(true)
      if (this.isCleanScreen) {
        this.setCleanScreen(false, false)
      }
    }
  }

  deactivateCoGuest(): void {
    this.coGuest.deactivate()
  }

  invalidateCoGuestCameraRequests(allowRestore: boolean): boolean {
    return this.coGuest.invalidateCameraRequests(allowRestore)
  }

  invalidateCoGuestMicrophoneRequests(): void {
    this.coGuest.invalidateMicrophoneRequests()
  }

  activateRoomFeatures(liveID: string, hostUserID: string): void {
    if (this.activatedRoomLiveID === liveID) {
      return
    }
    this.deactivateRoomFeatures()
    this.commentStore.activate(liveID, hostUserID)
    this.giftDisplay = new GiftDisplayController(liveID)
    this.giftDisplay.updateMessageContentHeight(this.messageContentHeight)
    this.giftDisplay.updateToolbarAndMessageOffset(giftOverlayBaseOffset)
    this.giftSendStore.activate(liveID)
    this.giftBarrageStore.activate(liveID)
    this.audienceListLiveID = liveID
    this.likeStore.activate(liveID)
    this.likeAnimation.activate(liveID, () => this.likeButtonCenter)
    this.activatedRoomLiveID = liveID
    this.updateGiftPresentationState()
  }

  deactivateRoomFeatures(): void {
    if (this.activatedRoomLiveID === undefined) {
      return
    }
    this.commentStore.deactivate()
    this.giftBarrageStore.deactivate()
    this.giftSendStore.deactivate()
    this.giftDisplay = undefined
    this.audienceListLiveID = ''
    this.isAudienceListPresented = false
    this.likeStore.deactivate()
    this.likeAnimation.deactivate()
    this.welcomeResetToken++
    this.activatedRoomLiveID = undefined
  }

  prepareForReuse(): void {
    this.messages = []
    this.messageContentHeight = 0
    this.isCommentComposerPresented = false
    this.setCleanScreen(false, false)
    this.dismissInteractionOverlays(true)
    this.likeAnimation.removeAllAnimations()
    this.lastStageLikeTapTime = 0
    this.liveInfo = undefined
    this.isJoinedChannel = false
    this.coGuest.deactivate()
  }

  setCleanScreen(cleanScreen: boolean, animated: boolean, uiContext?: UIContext): void {
    this.isCleanScreen = cleanScreen
    this.updateGiftPresentationState()
    const target = cleanScreen ? 1 : 0
    if (animated && uiContext !== undefined) {
      uiContext.animateTo({ duration: 300, curve: Curve.EaseOut }, () => this.cleanScreenProgress = target)
    } else {
      this.cleanScreenProgress = target
    }
  }

  dismissInteractionOverlays(resetCommentDraft: boolean = false): void {
    if (resetCommentDraft) {
      this.commentResetToken++
    }
    this.isCommentComposerPresented = false
    this.isGiftPanelPresented = false
    this.isAudienceListPresented = false
  }

  presentCommentComposer(): void {
    if (this.commentStore.isSelfMessageBanned()) {
      LiveToast.show(BarrageUIStore.sendErrorMessage(10017))
      return
    }
    this.isAudienceListPresented = false
    this.isGiftPanelPresented = false
    this.isCommentComposerPresented = true
  }

  sendComment(text: string): void {
    this.commentStore.sendComment(text)
  }

  presentGiftSendPanel(): void {
    this.isAudienceListPresented = false
    this.isCommentComposerPresented = false
    this.isGiftPanelPresented = true
  }

  presentAudienceList(): void {
    this.isCommentComposerPresented = false
    this.isGiftPanelPresented = false
    this.isAudienceListPresented = true
  }

  updateGiftPanelPresentation(isPresented: boolean, heightAboveSafeArea: number): void {
    this.giftDisplay?.updateGiftPanelHeightAboveSafeArea(isPresented ? heightAboveSafeArea + giftMessageSpacing : undefined)
    this.isGiftPanelAbove = isPresented
  }

  updateMessageContentHeight(height: number): void {
    this.messageContentHeight = height
    this.giftDisplay?.updateMessageContentHeight(height)
  }

  enqueueWelcome(welcome: AudienceWelcome): void {
    if (this.isJoinedChannel && !this.isCleanScreen) {
      this.welcome = welcome
    }
  }

  sendLikeFromButton(origin?: Position): void {
    if (origin !== undefined) {
      this.likeAnimation.showButtonLike(origin)
    }
    this.likeStore.sendLike()
  }

  sendGift(gift: GiftItem, count: number): void {
    const normalizedCount = Math.max(1, count)
    const profile: UserProfile | undefined = LoginStore.shared().state.loginUserInfo
    const giftDisplay = this.giftDisplay
    const reservationID = profile === undefined ? undefined : giftDisplay?.reserveLocalGift(new GiftDisplayItem(gift.id,
      gift.name, gift.iconURL, gift.resourceURL, Math.max(0, gift.coins), normalizedCount, profile.userID,
      profile.nickname ?? '', profile.avatarURL ?? ''))
    this.giftSendStore.sendGift(gift.id, count, (isSuccess: boolean) => {
      if (reservationID === undefined) {
        return
      }
      isSuccess ? giftDisplay?.confirmLocalGift(reservationID) : giftDisplay?.cancelLocalGift(reservationID)
    })
  }

  beginFloatingGiftSendCombo(gift: GiftItem): void {
    this.floatingCombo = gift
    this.floatingComboID++
  }

  endFloatingGiftSendCombo(comboID: number): void {
    if (this.floatingComboID === comboID) {
      this.floatingCombo = undefined
    }
  }

  handleStageTap(x: number, y: number, height: number): void {
    if (!this.isJoinedChannel || this.isCleanScreen || this.liveInfo === undefined) {
      return
    }
    const now = Date.now() / 1000
    const isContinuousTap = now - this.lastStageLikeTapTime <= 0.42
    this.lastStageLikeTapTime = now
    if (!isContinuousTap) {
      return
    }
    const point: Position = {
      x: Math.min(Math.max(x, 28), Math.max(this.viewWidth - 28, 28)),
      y: Math.min(Math.max(y - 8, 62), Math.max(height - 24, 62)),
    }
    this.likeAnimation.showStageLike(point, this.likeButtonCenter)
    this.likeStore.sendLike()
  }

  resetStageTap(): void {
    this.lastStageLikeTapTime = 0
  }

  beginCleanScreenTransition(): void {
    this.dismissInteractionOverlays()
    this.lastStageLikeTapTime = 0
    this.cleanScreenStateAtGestureStart = this.isCleanScreen
  }

  updateCleanScreenTransition(translationX: number): void {
    const distance = Math.max(this.viewWidth, 1)
    const progress = this.cleanScreenStateAtGestureStart ? Math.min(Math.max(-translationX / distance, 0), 1) :
      Math.min(Math.max(translationX / distance, 0), 1)
    this.cleanScreenProgress = this.cleanScreenStateAtGestureStart ? 1 - progress : progress
  }

  endCleanScreenTransition(translationX: number, velocityX: number, uiContext: UIContext): void {
    const progress = Math.min(Math.abs(translationX) / Math.max(this.viewWidth, 1), 1)
    const shouldChange = this.cleanScreenStateAtGestureStart ? translationX < 0 && (progress >= 0.22 || velocityX <= -450) :
      translationX > 0 && (progress >= 0.22 || velocityX >= 450)
    this.setCleanScreen(shouldChange ? !this.cleanScreenStateAtGestureStart : this.cleanScreenStateAtGestureStart, true,
      uiContext)
  }

  private updateGiftPresentationState(): void {
    const isEnabled = this.activatedRoomLiveID !== undefined && !this.isCleanScreen
    this.giftBarrageStore.setCollectionEnabled(isEnabled)
    this.giftDisplay?.setPresentationEnabled(isEnabled)
  }
}

@Component
export struct LivingView {
  @ObjectLink controller: LivingViewController
  @ObjectLink coGuest: CoGuestIconController
  @StorageProp(LiveKitSafeArea.topKey) safeTop: number = 0
  @StorageProp(LiveKitSafeArea.bottomKey) @Watch('updateLikeButtonCenter') safeBottom: number = 0
  @StorageProp(LiveKitSafeArea.keyboardKey) keyboardHeight: number = 0
  @State private viewHeight: number = 0
  @State private commentScale: number = 1
  @State private giftScale: number = 1
  @State private likeScale: number = 1
  private likeLayerWidth: number = 0
  private likeLayerHeight: number = 0

  private updateLikeButtonCenter(): void {
    if (this.likeLayerWidth <= 0 || this.likeLayerHeight <= 0) {
      return
    }
    this.controller.likeButtonCenter = {
      x: this.likeLayerWidth - toolbarHorizontalInset - bottomBarHeight / 2,
      y: this.likeLayerHeight - this.bottomBarBottom() - bottomBarHeight / 2,
    }
  }

  private buttonLikeOrigin(): Position | undefined {
    if (this.likeLayerWidth <= 0 || this.likeLayerHeight <= 0) {
      return undefined
    }
    this.updateLikeButtonCenter()
    return {
      x: this.controller.likeButtonCenter.x as number,
      y: (this.controller.likeButtonCenter.y as number) - bottomBarHeight,
    }
  }

  private showBusiness(): boolean {
    return this.controller.isJoinedChannel && !this.controller.isCleanScreen
  }

  private movableVisible(): boolean {
    return this.controller.isJoinedChannel && (!this.controller.isCleanScreen || this.controller.cleanScreenProgress < 1)
  }

  private bottomBarBottom(): number {
    return this.safeBottom + bottomBarBottomInset
  }

  private messageListBottom(): number {
    return this.controller.isCommentComposerPresented ? Math.max(this.keyboardHeight, this.safeBottom) + 4 + 36 + 6 :
      this.bottomBarBottom() + bottomBarHeight + messageBottomSpacing
  }

  @Builder
  barButton(image: string, accessibilityKey: string, scale: number, onPress: (scale: number) => void, action: () => void) {
    Image(LiveKitResources.image(image))
      .width(39)
      .height(39)
      .objectFit(ImageFit.Contain)
      .scale({ x: scale, y: scale })
      .accessibilityText(LiveKitResources.localizedString(accessibilityKey))
      .onTouch((event: TouchEvent) => this.animatePress(event, 0.92, onPress))
      .onClick(action)
  }

  private animatePress(event: TouchEvent, scale: number, apply: (scale: number) => void): void {
    if (event.type === TouchType.Down) {
      this.getUIContext().animateTo({ duration: 120 }, () => apply(scale))
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.getUIContext().animateTo({ duration: 120 }, () => apply(1))
    }
  }

  @Builder
  bottomBar() {
    Row({ space: 8.5 }) {
      Text(LiveKitResources.localizedString('tuilivekit.player.comment_placeholder'))
        .fontSize(12.5)
        .fontColor(white(0.50))
        .maxLines(1)
        .layoutWeight(1)
        .height(39)
        .padding({ left: 15, right: 15 })
        .borderRadius(19.5)
        .borderWidth(1)
        .borderColor(white(0.06))
        .backgroundColor(rgba(0.04, 0.04, 0.06, 0.18))
        .shadow({ radius: 3, color: 'rgba(0,0,0,0.2)' })
        .scale({ x: this.commentScale, y: this.commentScale })
        .accessibilityText(LiveKitResources.localizedString('tuilivekit.player.comment'))
        .onTouch((event: TouchEvent) => this.animatePress(event, 0.99, (scale: number) => this.commentScale = scale))
        .onClick(() => this.controller.presentCommentComposer())
      CoGuestIcon({ controller: this.coGuest })
      this.barButton('livekit_player_gift', 'tuilivekit.player.gift', this.giftScale,
        (scale: number) => this.giftScale = scale, () => this.controller.presentGiftSendPanel())
      this.barButton('livekit_player_like', 'tuilivekit.player.like', this.likeScale,
        (scale: number) => this.likeScale = scale, () => this.controller.sendLikeFromButton(this.buttonLikeOrigin()))
    }
    .width('100%')
    .height(bottomBarHeight)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.movableVisible()) {
        Stack({ alignContent: Alignment.TopStart }) {
          HostInfoView({
            liveInfo: this.controller.liveInfo ?? new LiveInfo(),
            likeCount: this.controller.likeCount,
            onError: (message: string) => {
              if (this.controller.isJoinedChannel) {
                this.controller.onToast?.(message)
              }
            },
          })
            .position({ x: 20, y: this.safeTop + 10 })
          BarrageStreamView({
            messages: this.controller.messages,
            onVisibleContentHeightChanged: (height: number) => this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut },
              () => this.controller.updateMessageContentHeight(height)),
          })
            .width(`${defaultWidthRatio * 100}%`)
            .height(this.controller.isCommentComposerPresented ? 132 : 152)
            .position({ left: 12, bottom: this.messageListBottom() })
            .animation({ duration: 250, curve: Curve.EaseInOut })
          AudienceWelcomeView({
            welcome: this.controller.welcome,
            resetToken: this.controller.welcomeResetToken,
            onVisibilityChanged: (isVisible: boolean) => this.controller.giftDisplay?.updateAudienceWelcomeVisible(isVisible),
          })
            .width('100%')
            .height(28)
            .position({ left: 0, bottom: this.bottomBarBottom() + bottomBarHeight + 18 + this.controller.messageContentHeight })
          Row() {
            this.bottomBar()
          }
          .position({ left: toolbarHorizontalInset, bottom: this.bottomBarBottom() })
          .width(this.controller.viewWidth - toolbarHorizontalInset * 2)
          LikeAnimationView({ controller: this.controller.likeAnimation })
            .hitTestBehavior(HitTestMode.BLOCK_DESCENDANTS)
            .onAreaChange((_: Area, area: Area) => {
              this.likeLayerWidth = area.width as number
              this.likeLayerHeight = area.height as number
              this.updateLikeButtonCenter()
            })
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
        .enabled(this.showBusiness() && this.controller.cleanScreenProgress === 0)
        .opacity(1 - this.controller.cleanScreenProgress)
        .translate({ x: this.controller.viewWidth * this.controller.cleanScreenProgress })
      }
      if (this.controller.isJoinedChannel) {
        AudienceView({
          liveID: this.controller.liveInfo?.liveID ?? '',
          cleanScreenProgress: this.controller.cleanScreenProgress,
          travelDistance: this.controller.viewWidth,
          onToast: (message: string) => {
            if (this.controller.isJoinedChannel) {
              this.controller.onToast?.(message)
            }
          },
          onAudience: () => this.controller.presentAudienceList(),
          onAudienceEntered: (welcome: AudienceWelcome) => this.controller.enqueueWelcome(welcome),
        })
          .position({ right: 42, top: this.safeTop + 15 })
      }
      if (this.controller.isJoinedChannel && (this.controller.isCleanScreen || this.controller.cleanScreenProgress > 0)) {
        Image(LiveKitResources.image('livekit_ic_controls_restore'))
          .width(56)
          .height(56)
          .objectFit(ImageFit.Contain)
          .opacity(this.controller.cleanScreenProgress)
          .position({ right: 18, bottom: this.safeBottom + 10 })
          .accessibilityText(LiveKitResources.localizedString('tuilivekit.player.restore_controls_accessibility'))
          .onClick(() => this.controller.setCleanScreen(false, true, this.getUIContext()))
      }
      if (this.controller.giftDisplay !== undefined && !this.controller.isCleanScreen) {
        GiftDisplayView({ controller: this.controller.giftDisplay, safeAreaBottom: this.safeBottom })
          .zIndex(this.controller.isGiftPanelAbove ? 2 : 0)
          .hitTestBehavior(HitTestMode.None)
      }
      if (this.controller.floatingCombo !== undefined) {
        ForEach([this.controller.floatingComboID], (comboID: number) => {
          GiftSendComboButton({
            giftID: this.controller.floatingCombo!.id,
            iconURL: this.controller.floatingCombo!.iconURL,
            onSendOnce: () => this.controller.sendGift(this.controller.floatingCombo!, 1),
            onExpired: () => this.controller.endFloatingGiftSendCombo(comboID),
          })
            .width(72)
            .height(96)
            .position({ right: 16, bottom: this.bottomBarBottom() + bottomBarHeight + 30 })
        }, (comboID: number) => `${comboID}`)
      }
      BarrageInputView({
        isPresented: this.controller.isCommentComposerPresented,
        resetToken: this.controller.commentResetToken,
        onSend: (text: string) => this.controller.sendComment(text),
        onDismiss: () => this.controller.isCommentComposerPresented = false,
      })
        .zIndex(1)
        .hitTestBehavior(HitTestMode.None)
      GiftSendPanelView({
        isPresented: this.controller.isGiftPanelPresented,
        categories: this.controller.giftCategories,
        isLoading: this.controller.isGiftLoading,
        onDismiss: () => this.controller.isGiftPanelPresented = false,
        onSendGift: (gift: GiftItem, count: number) => this.controller.sendGift(gift, count),
        onPresentationChanged: (isPresented: boolean, height: number) =>
        this.controller.updateGiftPanelPresentation(isPresented, height),
        onAdvancedComboStart: (gift: GiftItem) => this.controller.beginFloatingGiftSendCombo(gift),
      })
        .zIndex(1)
        .hitTestBehavior(HitTestMode.None)
      AudienceListPanel({
        isPresented: this.controller.isAudienceListPresented,
        liveID: this.controller.audienceListLiveID,
        onDismiss: () => this.controller.isAudienceListPresented = false,
      })
        .zIndex(1)
        .hitTestBehavior(HitTestMode.None)
      RequestingPanel({
        controller: this.coGuest,
        liveInfo: this.controller.liveInfo ?? new LiveInfo(),
        onDismiss: () => this.coGuest.isApplyPanelPresented = false,
        onRequestSettings: () => this.coGuest.presentSettingsPanel(Mode.preview),
      })
        .zIndex(1)
        .hitTestBehavior(HitTestMode.None)
      CoGuestingPanel({
        isPresented: this.coGuest.isConnectedPanelPresented,
        liveID: this.controller.liveInfo?.liveID ?? '',
        openCameraAfterAccept: this.coGuest.openCameraAfterAccept,
        controller: this.coGuest.connectedPanel,
        onDismiss: () => this.coGuest.isConnectedPanelPresented = false,
        onShowSettings: () => {
          this.coGuest.isConnectedPanelPresented = false
          this.coGuest.presentSettingsPanel(Mode.connected)
        },
      })
        .zIndex(1)
        .hitTestBehavior(HitTestMode.None)
      SettingsPanel({
        isPresented: this.coGuest.isSettingsPanelPresented,
        mode: this.coGuest.settingsMode,
        onDismiss: () => this.coGuest.isSettingsPanelPresented = false,
        onDidDismiss: () => {
          if (this.coGuest.uiState === CoGuestStatus.coGuesting) {
            this.coGuest.isConnectedPanelPresented = true
          }
        },
        onApply: () => {
          applyForSeat(this.coGuest, true)
          this.coGuest.isSettingsPanelPresented = false
        },
      })
        .zIndex(1)
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_: Area, area: Area) => {
      this.controller.viewWidth = Math.max(area.width as number, 1)
      this.viewHeight = area.height as number
    })
    .gesture(GestureGroup(GestureMode.Parallel,
      TapGesture().onAction((event: GestureEvent) => {
        const finger = event.fingerList[0]
        this.controller.handleStageTap(finger.localX, finger.localY, this.viewHeight)
      }),
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionStart(() => {
          if (this.controller.isJoinedChannel) {
            this.controller.beginCleanScreenTransition()
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.controller.isJoinedChannel) {
            this.controller.updateCleanScreenTransition(event.offsetX)
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.controller.isJoinedChannel) {
            this.controller.endCleanScreenTransition(event.offsetX, event.velocityX, this.getUIContext())
          }
        })
        .onActionCancel(() => {
          if (this.controller.isJoinedChannel) {
            this.controller.setCleanScreen(this.controller.isCleanScreen, true, this.getUIContext())
          }
        })))
  }
}
