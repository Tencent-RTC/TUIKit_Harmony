import { ApplicationStateChangeCallback } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { Gift, GiftListener, GiftStore, LiveUserInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../LiveKitResources'
import { GiftAnimationController, GiftAnimationView } from './GiftAnimationView'
import { GiftNoticeController, GiftNoticeView } from './GiftNoticeView'

const channelHeight: number = 44
const channelSpacing: number = 4
const defaultToolbarAndMessageOffset: number = 86
const welcomeReservedHeight: number = 32

export class GiftDisplayItem {
  giftID: string
  name: string
  iconURL: string
  resourceURL: string
  coins: number
  count: number
  senderID: string
  senderName: string
  senderAvatarURL: string

  constructor(giftID: string, name: string, iconURL: string, resourceURL: string, coins: number, count: number,
    senderID: string, senderName: string, senderAvatarURL: string) {
    this.giftID = giftID
    this.name = name
    this.iconURL = iconURL
    this.resourceURL = resourceURL
    this.coins = coins
    this.count = count
    this.senderID = senderID
    this.senderName = senderName
    this.senderAvatarURL = senderAvatarURL
  }

  get comboKey(): string {
    return `${this.senderID}_${this.giftID}`
  }

  get isAdvanced(): boolean {
    return this.resourceURL.length > 0
  }

  copy(count: number): GiftDisplayItem {
    return new GiftDisplayItem(this.giftID, this.name, this.iconURL, this.resourceURL, this.coins, count,
      this.senderID, this.senderName, this.senderAvatarURL)
  }
}

class LocalGiftReservation {
  id: string = util.generateRandomUUID()
  comboKey: string
  gift: GiftDisplayItem
  presentationID?: number
  remainingCount: number
  isDisplayed: boolean = false

  constructor(gift: GiftDisplayItem, presentationID: number | undefined) {
    this.comboKey = gift.comboKey
    this.gift = gift
    this.presentationID = presentationID
    this.remainingCount = gift.count
  }
}

@Observed
export class GiftDisplayController {
  noticeBottomOffset: number = defaultToolbarAndMessageOffset
  readonly noticeController: GiftNoticeController = new GiftNoticeController()
  readonly animationController: GiftAnimationController = new GiftAnimationController()
  private liveID: string
  private messageContentHeight: number = 0
  private toolbarAndMessageOffset: number = defaultToolbarAndMessageOffset
  private isAudienceWelcomeVisible: boolean = false
  private giftStore?: GiftStore
  private giftListener?: GiftListener
  private activatedLiveID?: string
  private presentationGeneration: number = 0
  private isPresentationEnabled: boolean = true
  private isInBackground: boolean = false
  private isActive: boolean = true
  private isAttached: boolean = false
  private giftPanelHeightAboveSafeArea?: number
  private localGiftReservations: LocalGiftReservation[] = []
  private applicationStateCallback?: ApplicationStateChangeCallback

  constructor(liveID: string) {
    this.liveID = liveID
  }

  attach(): void {
    this.isAttached = true
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => {
        if (this.isInBackground) {
          this.isInBackground = false
          this.resetPresentation()
        }
      },
      onApplicationBackground: () => {
        this.isInBackground = true
        this.resetPresentation()
      },
    }
    this.applicationStateCallback = callback
    getContext().getApplicationContext().on('applicationStateChange', callback)
    this.activate()
  }

  detach(): void {
    this.isAttached = false
    if (this.applicationStateCallback !== undefined) {
      getContext().getApplicationContext().off('applicationStateChange', this.applicationStateCallback)
      this.applicationStateCallback = undefined
    }
    this.deactivate()
  }

  setActive(active: boolean): void {
    this.isActive = active
    active && this.isAttached ? this.activate() : this.deactivate()
  }

  setPresentationEnabled(enabled: boolean): void {
    if (this.isPresentationEnabled === enabled) {
      return
    }
    this.isPresentationEnabled = enabled
    this.resetPresentation()
  }

  private get canPresent(): boolean {
    return this.isActive && this.activatedLiveID !== undefined && this.isAttached && this.isPresentationEnabled &&
      !this.isInBackground
  }

  show(gift: GiftDisplayItem): void {
    if (!this.canPresent) {
      return
    }
    this.noticeController.enqueue(gift)
    if (gift.isAdvanced) {
      this.animationController.enqueue(gift.resourceURL)
    }
  }

  reserveLocalGift(gift: GiftDisplayItem): string | undefined {
    if (!this.isActive || this.activatedLiveID === undefined || gift.count <= 0) {
      return undefined
    }
    const reservation = new LocalGiftReservation(gift, this.canPresent ? this.presentationGeneration : undefined)
    this.localGiftReservations.push(reservation)
    return reservation.id
  }

  confirmLocalGift(id: string): void {
    const reservation = this.localGiftReservations.find((item: LocalGiftReservation) => item.id === id)
    if (reservation === undefined || reservation.isDisplayed || reservation.remainingCount <= 0) {
      return
    }
    reservation.isDisplayed = true
    if (reservation.presentationID === this.presentationGeneration) {
      this.show(reservation.gift.copy(reservation.remainingCount))
    }
  }

  cancelLocalGift(id: string): void {
    this.localGiftReservations = this.localGiftReservations.filter((item: LocalGiftReservation) => item.id !== id)
  }

  updateMessageContentHeight(height: number): void {
    this.messageContentHeight = Math.max(0, height)
    this.updateNoticeBottomConstraint()
  }

  updateToolbarAndMessageOffset(offset: number): void {
    this.toolbarAndMessageOffset = Math.max(0, offset)
    this.updateNoticeBottomConstraint()
  }

  updateAudienceWelcomeVisible(isVisible: boolean): void {
    if (this.isAudienceWelcomeVisible === isVisible) {
      return
    }
    this.isAudienceWelcomeVisible = isVisible
    this.updateNoticeBottomConstraint()
  }

  updateGiftPanelHeightAboveSafeArea(height: number | undefined): void {
    this.giftPanelHeightAboveSafeArea = height === undefined ? undefined : Math.max(0, height)
    this.updateNoticeBottomConstraint()
  }

  resetNotices(): void {
    this.noticeController.reset()
  }

  resetPresentation(): void {
    this.presentationGeneration++
    this.resetNotices()
    this.animationController.reset()
  }

  private activate(): void {
    if (!this.isActive || this.liveID.length === 0 || this.activatedLiveID === this.liveID) {
      return
    }
    this.deactivate()
    this.activatedLiveID = this.liveID
    const giftStore = GiftStore.create(this.liveID)
    this.giftStore = giftStore
    giftStore.setLanguage(LiveKitResources.giftLanguageCode)
    const listener = new GiftListener()
    listener.onReceiveGift = (liveID: string, gift: Gift, count: number, sender: LiveUserInfo) => {
      if (this.giftListener === listener) {
        this.receive(liveID, gift, count, sender, this.presentationGeneration)
      }
    }
    this.giftListener = listener
    giftStore.addGiftListener(listener)
  }

  private deactivate(): void {
    if (this.giftListener !== undefined) {
      this.giftStore?.removeGiftListener(this.giftListener)
      this.giftListener = undefined
    }
    this.giftStore = undefined
    this.activatedLiveID = undefined
    this.localGiftReservations = []
    this.resetPresentation()
  }

  private receive(eventLiveID: string, gift: Gift, count: number, sender: LiveUserInfo, presentationID: number): void {
    if (eventLiveID !== this.activatedLiveID || count <= 0) {
      return
    }
    const receivedGift = new GiftDisplayItem(gift.giftID, gift.name, gift.iconURL, gift.resourceURL, gift.coins, count,
      sender.userID, sender.userName, sender.avatarURL)
    const visibleCounts = this.consumeLocalGiftReservations(receivedGift.comboKey, receivedGift.count)
    if (presentationID !== this.presentationGeneration) {
      return
    }
    visibleCounts.forEach((visibleCount: number) => this.show(receivedGift.copy(visibleCount)))
  }

  private updateNoticeBottomConstraint(): void {
    if (this.giftPanelHeightAboveSafeArea !== undefined) {
      this.noticeBottomOffset = this.giftPanelHeightAboveSafeArea
      return
    }
    this.noticeBottomOffset = this.toolbarAndMessageOffset + this.messageContentHeight +
      (this.isAudienceWelcomeVisible ? welcomeReservedHeight : 0)
  }

  private consumeLocalGiftReservations(comboKey: string, count: number): number[] {
    let unconsumedCount = count
    const visibleCounts: number[] = []
    let index = 0
    while (index < this.localGiftReservations.length && unconsumedCount > 0) {
      const reservation = this.localGiftReservations[index]
      if (reservation.comboKey !== comboKey) {
        index += 1
        continue
      }
      const consumed = Math.min(unconsumedCount, reservation.remainingCount)
      if (!reservation.isDisplayed && reservation.presentationID === this.presentationGeneration && consumed > 0) {
        visibleCounts.push(consumed)
      }
      unconsumedCount -= consumed
      reservation.remainingCount -= consumed
      if (reservation.remainingCount === 0) {
        this.localGiftReservations.splice(index, 1)
      } else {
        index += 1
      }
    }
    if (unconsumedCount > 0) {
      visibleCounts.push(unconsumedCount)
    }
    return visibleCounts
  }
}

@Component
export struct GiftDisplayView {
  @ObjectLink controller: GiftDisplayController
  @Prop safeAreaBottom: number = 0

  aboutToAppear(): void {
    this.controller.attach()
  }

  aboutToDisappear(): void {
    this.controller.detach()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      GiftNoticeView({ controller: this.controller.noticeController })
        .height(channelHeight * 2 + channelSpacing)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: this.safeAreaBottom + this.controller.noticeBottomOffset })
      GiftAnimationView({ controller: this.controller.animationController })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
