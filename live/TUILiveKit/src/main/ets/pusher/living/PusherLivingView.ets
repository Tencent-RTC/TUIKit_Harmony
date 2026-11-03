import { RectShape } from '@kit.ArkUI'
import { ApplicationStateChangeCallback } from '@kit.AbilityKit'
import {
  CoGuestLayoutTemplate, LikeListener, LikeStore, LiveAudienceState, LiveUserInfo, LoginStore
} from '@tencentcloud/atomicxcore'
import { AudienceWelcome, AudienceWelcomeView } from '../../common/audience/AudienceWelcomeView'
import { BarrageInputView } from '../../common/barrage/BarrageInputView'
import { BarrageUIState, BarrageUIStore, Comment } from '../../common/barrage/BarrageStore'
import { BarrageStreamView, defaultWidthRatio, LiveInteractionLayout, Message } from '../../common/barrage/BarrageStreamView'
import { GiftDisplayController, GiftDisplayView } from '../../common/gift/display/GiftDisplayView'
import { GiftBarrageStore, LiveGiftBarrage } from '../../common/gift/GiftBarrageStore'
import { LikeAnimationController, LikeAnimationView } from '../../common/like/LikeAnimationView'
import { LikeSender } from '../../common/like/LiveUIStore'
import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { LiveToast } from '../../common/theme/LiveToastView'
import { black } from '../../common/theme/LiveTheme'
import { PusherSettingsActionHandling, PusherSettingsState } from '../settings/PusherSettingsActionHandling'
import { Action, PusherAudienceStore, State as AudienceState, User } from './audience/PusherAudienceStore'
import { PusherAudienceListView } from './audience/PusherAudienceListView'
import { PusherAudienceManageView } from './audience/PusherAudienceManageView'
import { PusherCoGuestAudienceManageView } from './coguest/controlpanel/PusherCoGuestAudienceManageView'
import { PusherCoGuestSettingsView } from './coguest/controlpanel/PusherCoGuestSettingsView'
import {
  PusherCoGuestActionHandling,
  State as CoGuestState,
  User as CoGuestUser
} from './coguest/PusherCoGuestStore'
import { PusherEndConfirmationView } from './endconfirm/PusherEndConfirmationView'
import { LiveBottomToolbarView } from './LiveBottomToolbarView'
import { LiveHeaderView } from './LiveHeaderView'
import { PusherMusicView } from './music/PusherMusicView'
import { PusherPauseOverlayView } from './pause/PusherPauseOverlayView'
import { PusherLivingSettingsView } from './PusherLivingSettingsView'
import { Presentation, PusherDeviceStatusState } from './status/PusherDeviceStatusView'
import { PusherLiveStatusView } from './status/PusherLiveStatusView'

@Observed
export class PusherLivingViewController {
  @Track onShowBeauty?: () => void
  @Track onEnd?: () => void
  @Track onToggleMute?: () => void
  @Track onPause?: () => void
  @Track onResume?: () => void
  @Track onFlipCamera?: () => void
  @Track settingsActionHandler?: PusherSettingsActionHandling
  @Track coGuestActionHandler?: PusherCoGuestActionHandling
  @Track onCoGuestStageTap?: (x: number, y: number) => boolean
  @Track coGuestSmallWindowRegions?: () => Area[]
  @Track coGuestGridRegions?: () => Area[]
  @Track interactionLayout: LiveInteractionLayout = new LiveInteractionLayout(undefined, 0, 0, false, 0, 0)
  @Track interactionTop: number = -1
  @Track composerCommentHeight: number = 184
  // Welcome @Watch callbacks can calculate layout during UI dependency collection.
  @Track private composerNormalContentHeight: number = 0
  @Track private isWelcomeVisible: boolean = false
  @Track private viewHeight: number = 0
  @Track private viewOriginY: number = 0
  @Track private safeBottom: number = 0
  private hasAnnouncement: boolean = false

  @Track readonly liveID: string
  @Track readonly giftDisplay: GiftDisplayController
  @Track readonly likeAnimation: LikeAnimationController = new LikeAnimationController()
  @Track hostName: string = ''
  @Track hostAvatarURL: string = ''
  @Track settings: PusherSettingsState = new PusherSettingsState()
  @Track devicePresentation: Presentation = new Presentation()
  @Track elapsedSeconds: number = 0
  @Track isPaused: boolean = false
  @Track pausedSeconds: number = 0
  @Track likeCount: number = 0
  @Track audienceUsers: User[] = []
  @Track audienceCount: number = 0
  @Track networkQuality: number = 0
  @Track hasCoGuestUnread: boolean = false
  @Track audienceState: AudienceState = new AudienceState()
  @Track coGuestState: CoGuestState = new CoGuestState()
  @Track isCoGuestStageActive: boolean = false
  @Track messages: Message[] = []
  @Track messageContentHeight: number = 0
  @Track messageListWidth: number = 0
  @Track welcome?: AudienceWelcome
  @Track welcomeResetToken: number = 0
  @Track commentResetToken: number = 0
  @Track isMusicActive: boolean = false
  @Track isMusicSuspended: boolean = false
  @Track selectedAudienceUserID: string = ''
  @Track completedAudienceAction: string = ''
  @Track selectedCoGuestUserID: string = ''
  @Track isSettingsPresented: boolean = false
  @Track isCommentComposerPresented: boolean = false
  @Track isMusicPresented: boolean = false
  @Track isAudienceListPresented: boolean = false
  @Track isAudienceManagePresented: boolean = false
  @Track isEndConfirmationPresented: boolean = false
  @Track isCoGuestSettingsPresented: boolean = false
  @Track isLiveStatusPresented: boolean = false
  @Track isCoGuestAudienceManagePresented: boolean = false
  @Track likeAnimationOrigin: Position = { x: 0, y: 0 }
  @Track viewWidth: number = 0
  private readonly audienceStore?: PusherAudienceStore
  private readonly likeStore?: LikeStore
  private readonly likeSender: LikeSender = new LikeSender()
  private readonly commentStore: BarrageUIStore = new BarrageUIStore()
  private readonly giftBarrageStore: GiftBarrageStore = new GiftBarrageStore()
  private commentToast?: LiveToast
  private likeListener?: LikeListener
  private likeSessionID: number = 0
  private isLikeActive: boolean = false
  private isCommentActive: boolean = false
  private isMusicInBackground: boolean = false
  private musicLifecycleCallback?: ApplicationStateChangeCallback
  private lastStageTapTime: number = 0
  private actionSeed: number = 0
  private commentTop: number = 0
  private commentBottom: number = 0

  constructor(liveID: string) {
    this.liveID = liveID
    this.giftDisplay = new GiftDisplayController(liveID)
    if (liveID.length > 0) {
      this.audienceStore = new PusherAudienceStore(liveID)
      this.likeStore = LikeStore.create(liveID)
    }
    this.giftDisplay.setActive(false)
  }

  bindPresentationCallbacks(): void {
    // Called through @ObjectLink after construction so callbacks retain the observed proxy.
    this.giftDisplay.onNoticeContentHeightChanged = () => this.updateInteractionLayout()
    this.bindAudienceStore()
    this.updateInteractionLayout()
  }

  unbindPresentationCallbacks(): void {
    this.giftDisplay.onNoticeContentHeightChanged = undefined
    if (this.audienceStore !== undefined) {
      this.audienceStore.onStateChanged = undefined
      this.audienceStore.onAudienceEntered = undefined
      this.audienceStore.onActionCompleted = undefined
    }
  }

  get viewerCount(): number {
    return this.audienceCount
  }

  get audienceSDKStore(): PusherAudienceStore | undefined {
    return this.audienceStore
  }

  updateHost(name: string, avatarURL: string): void {
    this.hostName = name
    this.hostAvatarURL = avatarURL
  }

  updateSettings(settings: PusherSettingsState): void {
    if (this.settings.isMirrorEnabled !== settings.isMirrorEnabled || this.settings.isMuted !== settings.isMuted ||
      this.settings.captureVolume !== settings.captureVolume) {
      this.settings = new PusherSettingsState(settings.isMirrorEnabled, settings.isMuted, settings.captureVolume)
    }
  }

  updateDeviceStatus(status: PusherDeviceStatusState, isMuted: boolean, captureVolume: number): void {
    this.networkQuality = status.networkQuality
    if (this.devicePresentation.status.equals(status) && this.devicePresentation.isMuted === isMuted &&
      this.devicePresentation.captureVolume === captureVolume) {
      return
    }
    const presentation = new Presentation()
    presentation.status = status.copy()
    presentation.isMuted = isMuted
    presentation.captureVolume = captureVolume
    this.devicePresentation = presentation
  }

  updateElapsedSeconds(seconds: number): void {
    this.elapsedSeconds = seconds
  }

  updatePause(isPaused: boolean, seconds: number): void {
    this.isPaused = isPaused
    this.pausedSeconds = seconds
    this.giftDisplay.setPresentationEnabled(!isPaused)
    this.updateMusicSuspension()
  }

  activateAudience(): void {
    this.audienceStore?.activate()
  }

  refreshAudience(): void {
    this.audienceStore?.refresh()
  }

  deactivateAudience(resetState: boolean): void {
    this.audienceStore?.deactivate(resetState)
    this.resetAudienceWelcomes()
  }

  activateLikes(): void {
    const likeStore = this.likeStore
    if (likeStore === undefined || this.isLikeActive) {
      return
    }
    this.isLikeActive = true
    const sessionID = ++this.likeSessionID
    this.likeSender.activate((count: number) => {
      likeStore.sendLike(count).catch(() => {
      })
    })
    this.updateLikeCount(likeStore.likeState.totalLikeCount)
    const listener = new LikeListener()
    listener.onReceiveLikesMessage = (liveID: string, totalLikesReceived: number, sender: LiveUserInfo) => {
      if (this.isLikeActive && this.likeSessionID === sessionID && liveID === this.liveID) {
        this.updateLikeCount(totalLikesReceived)
      }
    }
    this.likeListener = listener
    likeStore.addLikeListener(listener)
    this.likeAnimation.activate(this.liveID, () => this.likeAnimationOrigin)
  }

  deactivateLikes(resetState: boolean, discardPending: boolean = false): void {
    this.likeSessionID++
    this.isLikeActive = false
    this.likeSender.deactivate(discardPending)
    if (this.likeListener !== undefined) {
      this.likeStore?.removeLikeListener(this.likeListener)
      this.likeListener = undefined
    }
    this.likeAnimation.deactivate()
    if (resetState) {
      this.likeCount = 0
    }
  }

  activateComments(): void {
    if (this.isCommentActive) {
      return
    }
    this.isCommentActive = true
    this.giftDisplay.setActive(true)
    this.commentStore.onStateChanged = (state: BarrageUIState) => {
      if (this.isCommentActive) {
        this.renderComments(state.comments)
      }
    }
    this.commentStore.onSendError = (message: string) => {
      if (this.isCommentActive) {
        this.commentToast = LiveToast.show(message)
      }
    }
    this.commentStore.activate(this.liveID, LoginStore.shared().state.loginUserInfo?.userID ?? '')
    this.giftBarrageStore.onGiftBarrageSettled = (gift: LiveGiftBarrage) => {
      if (this.isCommentActive) {
        this.commentStore.appendGiftBarrage(gift)
      }
    }
    this.giftBarrageStore.activate(this.liveID)
  }

  pauseComments(): void {
    if (this.isCommentActive) {
      this.giftBarrageStore.setCollectionEnabled(false)
    }
  }

  resumeComments(): void {
    if (this.isCommentActive) {
      this.giftBarrageStore.setCollectionEnabled(true)
    }
  }

  deactivateComments(resetState: boolean): void {
    this.isCommentActive = false
    if (resetState) this.hasAnnouncement = false
    this.giftDisplay.setActive(false)
    this.commentResetToken++
    this.commentStore.deactivate()
    this.commentToast?.dismiss()
    this.commentToast = undefined
    this.giftBarrageStore.onGiftBarrageSettled = undefined
    this.giftBarrageStore.deactivate()
    if (resetState) {
      this.renderComments([])
    }
  }

  activateMusic(): void {
    this.removeMusicLifecycle()
    this.isMusicInBackground = false
    this.isMusicActive = true
    this.updateMusicSuspension()
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => {
        this.isMusicInBackground = false
        this.updateMusicSuspension()
      },
      onApplicationBackground: () => {
        this.isMusicInBackground = true
        this.updateMusicSuspension()
      },
    }
    this.musicLifecycleCallback = callback
    getContext().getApplicationContext().on('applicationStateChange', callback)
  }

  deactivateMusic(): void {
    this.removeMusicLifecycle()
    this.isMusicActive = false
  }

  resetAfterStartFailure(): void {
    this.dismissCommentComposer()
    this.lastStageTapTime = 0
    this.deactivateAudience(true)
    this.deactivateLikes(true, true)
    this.deactivateComments(true)
    this.deactivateMusic()
    this.updatePause(false, 0)
    this.updateElapsedSeconds(0)
    this.isSettingsPresented = false
    this.isMusicPresented = false
    this.isAudienceListPresented = false
    this.isAudienceManagePresented = false
    this.isEndConfirmationPresented = false
    this.isCoGuestSettingsPresented = false
    this.isLiveStatusPresented = false
    this.isCoGuestAudienceManagePresented = false
  }

  resetAudienceWelcomes(): void {
    this.welcome = undefined
    this.welcomeResetToken++
  }

  updateCoGuest(state: CoGuestState): void {
    const needsLayoutUpdate =
      this.coGuestState.layout.templateId !== state.layout.templateId ||
      this.coGuestState.connected.length !== state.connected.length
    this.hasCoGuestUnread = state.hasUnreadApplicant
    if (!this.coGuestState.equals(state)) {
      this.coGuestState = state.copy()
    }
    if (needsLayoutUpdate) {
      this.updateCommentWidth()
    }
    if (state.hasUnreadApplicant && this.isCoGuestSettingsPresented) {
      this.coGuestActionHandler?.markApplicantsSeen()
    }
  }

  setCoGuestStageActive(isActive: boolean): void {
    this.isCoGuestStageActive = isActive
  }

  showCoGuestActions(userID: string): void {
    if (!this.coGuestState.connected.some((user: CoGuestUser) => user.userID === userID)) {
      return
    }
    this.selectedCoGuestUserID = userID
    this.isCoGuestAudienceManagePresented = true
  }

  showCoGuestSettings(): void {
    this.isCoGuestSettingsPresented = true
    this.coGuestActionHandler?.markApplicantsSeen()
  }

  sendComment(text: string): void {
    if (this.isCommentActive) {
      this.commentStore.sendComment(text)
    }
  }

  updateMessageContentHeight(height: number): void {
    this.messageContentHeight = height
    this.updateInteractionLayout()
  }

  updateCommentWidth(commentTop?: number, commentBottom?: number): void {
    this.updateInteractionLayout()
    if (commentTop !== undefined && commentBottom !== undefined && commentBottom > commentTop) {
      this.commentTop = commentTop
      this.commentBottom = commentBottom
    }
    if (this.viewWidth <= 0) {
      return
    }
    const defaultWidth = Math.min(this.viewWidth * defaultWidthRatio, this.viewWidth - 24)
    let width = defaultWidth
    if (this.coGuestState.layout.templateId === CoGuestLayoutTemplate.floatLayout.templateId ||
      this.coGuestState.layout.templateId === CoGuestLayoutTemplate.columnLayout.templateId) {
      const edges = (this.coGuestSmallWindowRegions?.() ?? []).filter((area: Area) => {
        const top = area.globalPosition.y as number
        return top + (area.height as number) > this.commentTop && top < this.commentBottom
      }).map((area: Area) => (area.globalPosition.x as number) - 8)
      if (edges.length > 0) {
        width = Math.min(defaultWidth, Math.min(...edges) - 12)
      }
    }
    const resolvedWidth = Math.max(17, width)
    if (Math.abs(resolvedWidth - this.messageListWidth) > 0.5) {
      this.messageListWidth = resolvedWidth
    }
  }

  handleStageTap(globalX: number, globalY: number, localX: number, localY: number): void {
    if (!this.canHandleStageLike) {
      this.lastStageTapTime = 0
      return
    }
    const now = Date.now() / 1000
    if (this.onCoGuestStageTap?.(globalX, globalY) === true) {
      this.lastStageTapTime = 0
      return
    }
    const isContinuousTap = now - this.lastStageTapTime <= 0.42
    this.lastStageTapTime = now
    if (!isContinuousTap) {
      return
    }
    this.likeAnimation.showStageLike({ x: localX, y: localY }, this.likeAnimationOrigin)
    if (this.isLikeActive && !this.isPaused) {
      this.likeSender.sendLike()
    }
  }

  private get canHandleStageLike(): boolean {
    return !this.isPaused && !this.isSettingsPresented && !this.isCommentComposerPresented && !this.isMusicPresented &&
      !this.isAudienceListPresented && !this.isAudienceManagePresented && !this.isEndConfirmationPresented &&
      !this.isCoGuestSettingsPresented && !this.isLiveStatusPresented && !this.isCoGuestAudienceManagePresented
  }

  private updateLikeCount(count: number): void {
    this.likeCount = Math.max(0, count)
  }

  showSystemAnnouncement(): void {
    if (this.hasAnnouncement) return
    this.hasAnnouncement = true
    this.messages = [new Message(`pusher-system-${this.liveID}`, '',
      LiveKitResources.localizedString('tuilivekit.pusher.system_announcement'), 0, false, undefined, true)]
      .concat(this.messages)
  }

  updateSafeBottom(value: number): void { this.safeBottom = value; this.updateInteractionLayout() }
  updateInteractionBounds(area: Area, safeBottom: number): void {
    this.viewHeight = area.height as number
    this.viewOriginY = area.globalPosition.y as number
    this.safeBottom = safeBottom
    this.updateInteractionLayout()
  }
  setWelcomeVisible(visible: boolean): void {
    this.isWelcomeVisible = visible
    this.updateInteractionLayout()
  }
  dismissCommentComposer(): void {
    this.isCommentComposerPresented = false
    this.updateInteractionLayout()
  }

  presentCommentComposer(): void {
    if (this.isCommentComposerPresented) return
    const layout = this.interactionLayout
    this.composerCommentHeight = Math.min(layout.commentHeight,
      layout.visibleCommentHeight < 0 ? layout.commentHeight : layout.visibleCommentHeight)
    this.composerNormalContentHeight = this.messageContentHeight
    this.isCommentComposerPresented = true
  }
  private updateInteractionLayout(): void {
    const template = this.coGuestState.layout.templateId
    const grid = template === CoGuestLayoutTemplate.gridLayout.templateId ||
      (template === CoGuestLayoutTemplate.dynamicLayout.templateId && this.coGuestState.connected.length > 0)
    let top: number | undefined = undefined
    if (grid) {
      const bottoms = (this.coGuestGridRegions?.() ?? []).filter((area: Area) =>
        (area.height as number) > 0 && (area.globalPosition.y as number) < this.viewOriginY + this.viewHeight &&
        (area.globalPosition.y as number) + (area.height as number) > this.viewOriginY)
        .map((area: Area) => (area.globalPosition.y as number) + (area.height as number) - this.viewOriginY)
      top = bottoms.length === 0 ? this.viewHeight : Math.min(this.viewHeight, Math.max(...bottoms) + 8)
    }
    this.interactionTop = top ?? -1
    const layout = new LiveInteractionLayout(top, this.viewHeight - this.safeBottom - 68 - 14,
      this.isCommentComposerPresented ? this.composerNormalContentHeight : this.messageContentHeight,
      this.isWelcomeVisible, this.giftDisplay.noticeContentHeight, this.viewHeight - this.safeBottom)
    const previous = this.interactionLayout
    if (layout.commentHeight !== previous.commentHeight || layout.visibleCommentHeight !== previous.visibleCommentHeight ||
      layout.welcomeTop !== previous.welcomeTop || layout.giftNoticeBottom !== previous.giftNoticeBottom) this.interactionLayout = layout
  }

  private renderComments(comments: Comment[]): void {
    const previous = new Map<string, Message>()
    this.messages.forEach((message: Message) => previous.set(message.id, message))
    const messages = comments.map((comment: Comment) => {
      const message = previous.get(comment.id)
      if (message !== undefined && message.userName === comment.senderName && message.content === comment.text &&
        message.level === comment.level && message.isHost === comment.isHost &&
        this.sameGift(message.gift, comment.gift)) {
        return message
      }
      const gift = comment.gift
      const snapshot = gift === undefined ? undefined : new LiveGiftBarrage(gift.giftID, gift.giftName,
        gift.giftIconURL, gift.count, gift.senderID, gift.senderName, gift.senderLevel, gift.id)
      return new Message(comment.id, comment.senderName, comment.text, comment.level, comment.isHost, snapshot)
    })
    if (this.hasAnnouncement) {
      messages.unshift(previous.get(`pusher-system-${this.liveID}`) ??
        new Message(`pusher-system-${this.liveID}`, '',
          LiveKitResources.localizedString('tuilivekit.pusher.system_announcement'), 0, false, undefined, true))
    }
    if (messages.length !== this.messages.length ||
      messages.some((message: Message, index: number) => message !== this.messages[index])) {
      this.messages = messages
    }
  }

  private sameGift(left: LiveGiftBarrage | undefined, right: LiveGiftBarrage | undefined): boolean {
    if (left === undefined || right === undefined) {
      return left === right
    }
    return left.id === right.id && left.giftID === right.giftID && left.giftName === right.giftName &&
      left.giftIconURL === right.giftIconURL && left.count === right.count && left.senderID === right.senderID &&
      left.senderName === right.senderName && left.senderLevel === right.senderLevel
  }

  private removeMusicLifecycle(): void {
    if (this.musicLifecycleCallback !== undefined) {
      getContext().getApplicationContext().off('applicationStateChange', this.musicLifecycleCallback)
      this.musicLifecycleCallback = undefined
    }
  }

  private updateMusicSuspension(): void {
    this.isMusicSuspended = this.isPaused || this.isMusicInBackground
  }

  private bindAudienceStore(): void {
    const audienceStore = this.audienceStore
    if (audienceStore === undefined) {
      return
    }
    audienceStore.onStateChanged = (state: AudienceState) => {
      this.audienceCount = state.count
      if (this.audienceUsers.length !== state.users.length ||
        this.audienceUsers.some((user: User, index: number) => !user.equals(state.users[index]))) {
        this.audienceUsers = state.users.map((user: User) =>
          new User(user.userID, user.userName, user.avatarURL, user.level))
      }
      if (!this.audienceState.equals(state)) {
        this.audienceState = state.copy()
      }
    }
    audienceStore.onAudienceEntered = (welcome: AudienceWelcome) => {
      if (!this.isPaused) {
        this.welcome = welcome
      }
    }
    audienceStore.onActionCompleted = (userID: string, action: Action, succeeded: boolean) => {
      this.completedAudienceAction = `${userID}|${action}|${succeeded ? 1 : 0}|${++this.actionSeed}`
      if (!succeeded || action === Action.follow || action === Action.unfollow) {
        return
      }
      const toastKey = action === Action.mute ? 'tuilivekit.pusher.audience.muted_toast' :
        action === Action.unmute ? 'tuilivekit.pusher.audience.unmuted_toast' :
          'tuilivekit.pusher.audience.removed_toast'
      const user = this.audienceState.users.find((item: User) => item.userID === userID)
      const name = user === undefined ? userID : (user.userName.length === 0 ? user.userID : user.userName)
      LiveToast.show(LiveKitResources.localizedFormat(toastKey, name))
    }
  }
}

@Component
export struct PusherLivingView {
  @ObjectLink controller: PusherLivingViewController
  @StorageProp(LiveKitSafeArea.topKey) safeTop: number = 0
  @StorageProp(LiveKitSafeArea.bottomKey) @Watch('onSafeBottomChanged') safeBottom: number = 0
  @StorageProp(LiveKitSafeArea.keyboardKey) keyboardHeight: number = 0
  @State @Watch('onAudienceCountChanged') private audienceSDKState: LiveAudienceState = new LiveAudienceState()
  private commentTop: number = 0
  private commentBottom: number = 0
  @State private hostHeight: number = 0
  private welcomeClipTop(): number {
    return this.controller.interactionTop < 0 ? 0 :
      Math.max(0, this.controller.interactionTop - this.controller.interactionLayout.welcomeTop)
  }

  aboutToAppear(): void {
    this.controller.bindPresentationCallbacks()
    const store = this.controller.audienceSDKStore
    if (store !== undefined) {
      this.audienceSDKState = store.sdkState
    }
  }

  aboutToDisappear(): void {
    this.controller.unbindPresentationCallbacks()
  }

  private onAudienceCountChanged(): void {
    this.controller.audienceSDKStore?.apply()
  }

  private toolbarHeight(): number {
    return this.safeBottom + 68
  }

  @State private composerHeight: number = 36

  private onSafeBottomChanged(): void { this.controller.updateSafeBottom(this.safeBottom) }
  private messageListBottom(): number {
    return this.controller.isCommentComposerPresented ?
      Math.max(this.keyboardHeight, this.safeBottom) + 4 + this.composerHeight + 6 :
      this.toolbarHeight() + 14
  }

  @Builder
  scrim(isTop: boolean) {
    Column()
      .width('100%')
      .height(isTop ? 170 : 186)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: isTop ? [[black(0.5), 0], [black(0), 1]] : [[black(0), 0], [black(0.58), 1]],
      })
      .hitTestBehavior(HitTestMode.None)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.scrim(true)
      Column() {
        this.scrim(false)
      }
        .position({ left: 0, bottom: 0 })
        .hitTestBehavior(HitTestMode.None)

      LiveHeaderView({
        hostName: this.controller.hostName,
        avatarURL: this.controller.hostAvatarURL,
        audience: this.controller.audienceUsers,
        audienceCount: this.controller.audienceCount,
        likeCount: this.controller.likeCount,
        elapsedSeconds: this.controller.elapsedSeconds,
        networkQuality: this.controller.networkQuality,
        onClose: () => this.controller.isEndConfirmationPresented = true,
        onAudience: () => this.controller.isAudienceListPresented = true,
        onStatus: () => this.controller.isLiveStatusPresented = true,
      })
        .width('calc(100% - 24vp)')
        .position({ x: 12, y: this.safeTop - 1 })
      BarrageStreamView({
        messages: this.controller.messages,
        maximumVisibleHeight: this.controller.isCommentComposerPresented ? -1 : this.controller.interactionLayout.visibleCommentHeight,
        onContentHeightChanged: (height: number) => this.controller.updateMessageContentHeight(height),
      })
        .width(this.controller.messageListWidth > 0 ? this.controller.messageListWidth : `${defaultWidthRatio * 100}%`)
        .height(this.controller.isCommentComposerPresented ? this.controller.composerCommentHeight :
          this.controller.interactionLayout.commentHeight)
        .position({ left: 12, bottom: this.messageListBottom() })
        .onAreaChange((_: Area, area: Area) => {
          this.commentTop = area.globalPosition.y as number
          this.commentBottom = this.commentTop + (area.height as number)
          this.controller.updateCommentWidth(this.commentTop, this.commentBottom)
        })
      AudienceWelcomeView({
        welcome: this.controller.welcome,
        resetToken: this.controller.welcomeResetToken,
        onVisibilityChanged: (isVisible: boolean) => this.controller.setWelcomeVisible(isVisible),
      })
        .width('100%')
        .height(28)
        .clipShape(new RectShape({ width: this.controller.viewWidth, height: Math.max(0, 28 - this.welcomeClipTop()) })
          .offset({ x: 0, y: this.welcomeClipTop() }))
        .position({ left: 0, top: this.controller.interactionLayout.welcomeTop })
      LiveBottomToolbarView({
        isCoGuestStageActive: this.controller.isCoGuestStageActive,
        hasCoGuestUnread: this.controller.hasCoGuestUnread,
        onPK: () => LiveToast.show(LiveKitResources.localizedString('tuilivekit.pusher.living.pk_developing')),
        onFlipCamera: () => this.controller.onFlipCamera?.(),
        onShowBackgroundMusic: () => this.controller.isMusicPresented = true,
        onCoGuest: () => this.controller.showCoGuestSettings(),
        onMore: () => this.controller.isSettingsPresented = true,
        onLikeAnimationOrigin: (origin: Position) => this.controller.likeAnimationOrigin = origin,
      })
        .width('100%')
        .height(this.toolbarHeight())
        .position({ left: 0, bottom: 0 })
      LikeAnimationView({ controller: this.controller.likeAnimation })
        .hitTestBehavior(HitTestMode.None)
      GiftDisplayView({ controller: this.controller.giftDisplay, safeAreaBottom: this.safeBottom,
        noticeBottom: this.hostHeight - this.controller.interactionLayout.giftNoticeBottom,
        noticeTopBoundary: this.controller.interactionTop })
        .hitTestBehavior(HitTestMode.None)
      PusherLivingSettingsView({
        isPresented: this.controller.isSettingsPresented,
        settings: this.controller.settings,
        settingsActionHandler: this.controller.settingsActionHandler,
        onDismiss: () => this.controller.isSettingsPresented = false,
        onToggleMute: () => this.controller.onToggleMute?.(),
        onPause: () => this.controller.onPause?.(),
        onShowBeauty: () => this.controller.onShowBeauty?.(),
        onShowComment: () => this.controller.presentCommentComposer(),
      })
      BarrageInputView({
        isPresented: this.controller.isCommentComposerPresented,
        resetToken: this.controller.commentResetToken,
        onSend: (text: string) => this.controller.sendComment(text),
        onHeightChanged: (height: number) => this.composerHeight = height,
        onDismiss: () => this.controller.dismissCommentComposer(),
      })
      PusherMusicView({
        isPresented: this.controller.isMusicPresented,
        liveID: this.controller.liveID,
        isActive: this.controller.isMusicActive,
        isSuspended: this.controller.isMusicSuspended,
        onDismiss: () => this.controller.isMusicPresented = false,
      })
      if (this.controller.isPaused) {
        PusherPauseOverlayView({ seconds: this.controller.pausedSeconds, onResume: () => this.controller.onResume?.() })
      }
      PusherAudienceListView({
        isPresented: this.controller.isAudienceListPresented,
        audience: this.controller.audienceUsers,
        onDismiss: () => this.controller.isAudienceListPresented = false,
        onRefresh: () => this.controller.refreshAudience(),
        onSelectAudience: (user: User) => {
          if (!this.controller.audienceState.users.some((current: User) => current.userID === user.userID)) {
            return
          }
          this.controller.selectedAudienceUserID = user.userID
          this.controller.isAudienceManagePresented = true
          this.controller.audienceSDKStore?.refreshFollowStatus(user.userID)
        },
      })
      PusherAudienceManageView({
        isPresented: this.controller.isAudienceManagePresented,
        state: this.controller.audienceState,
        selectedUserID: this.controller.selectedAudienceUserID,
        completedAction: this.controller.completedAudienceAction,
        onDismiss: () => this.controller.isAudienceManagePresented = false,
        onToggleFollow: (userID: string) => this.controller.audienceSDKStore?.toggleFollow(userID),
        onToggleMessagePermission: (userID: string) => this.controller.audienceSDKStore?.toggleMessagePermission(
          userID),
        onRemoveFromRoom: (userID: string) => this.controller.audienceSDKStore?.removeFromRoom(userID),
      })
      PusherEndConfirmationView({
        isPresented: this.controller.isEndConfirmationPresented,
        viewerCount: this.controller.audienceCount,
        onDismiss: () => this.controller.isEndConfirmationPresented = false,
        onConfirmEnd: () => this.controller.onEnd?.(),
      })
      PusherCoGuestSettingsView({
        isPresented: this.controller.isCoGuestSettingsPresented,
        state: this.controller.coGuestState,
        actionHandler: this.controller.coGuestActionHandler,
        onDismiss: () => this.controller.isCoGuestSettingsPresented = false,
      })
      PusherLiveStatusView({
        isPresented: this.controller.isLiveStatusPresented,
        liveID: this.controller.liveID,
        elapsedSeconds: this.controller.elapsedSeconds,
        onlineCount: this.controller.audienceCount,
        likeCount: this.controller.likeCount,
        devicePresentation: this.controller.devicePresentation,
        onDismiss: () => this.controller.isLiveStatusPresented = false,
        onSetCaptureVolume: (volume: number) => this.controller.settingsActionHandler?.setCaptureVolume(volume),
      })
      PusherCoGuestAudienceManageView({
        isPresented: this.controller.isCoGuestAudienceManagePresented,
        state: this.controller.coGuestState,
        selectedUserID: this.controller.selectedCoGuestUserID,
        actionHandler: this.controller.coGuestActionHandler,
        onDismiss: () => this.controller.isCoGuestAudienceManagePresented = false,
      })
    }
      .width('100%')
      .height('100%')
      .onAreaChange((_: Area, area: Area) => {
        this.hostHeight = area.height as number
        this.controller.updateInteractionBounds(area, this.safeBottom)
        this.controller.viewWidth = area.width as number
        this.controller.updateCommentWidth(this.commentTop, this.commentBottom)
      })
      .gesture(TapGesture().onAction((event: GestureEvent) => {
        const finger = event.fingerList[0]
        this.controller.handleStageTap(finger.globalX, finger.globalY, finger.localX, finger.localY)
      }), GestureMask.Normal)
  }
}
