import { ApplicationStateChangeCallback } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { Gift, GiftListener, GiftStore, LiveUserInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../LiveKitResources'

export class LiveGiftBarrage {
  id: string
  giftID: string
  giftName: string
  giftIconURL: string
  count: number
  senderID: string
  senderName: string
  senderLevel: number

  constructor(giftID: string, giftName: string, giftIconURL: string, count: number, senderID: string,
    senderName: string, senderLevel: number, id: string = util.generateRandomUUID()) {
    this.id = id
    this.giftID = giftID
    this.giftName = giftName
    this.giftIconURL = giftIconURL
    this.count = count
    this.senderID = senderID
    this.senderName = senderName
    this.senderLevel = senderLevel
  }
}

class PendingBarrage {
  barrage: LiveGiftBarrage
  timer: number

  constructor(barrage: LiveGiftBarrage, timer: number) {
    this.barrage = barrage
    this.timer = timer
  }
}

export class GiftBarrageStore {
  onGiftBarrageSettled?: (barrage: LiveGiftBarrage) => void
  private liveID?: string
  private giftStore?: GiftStore
  private giftListener?: GiftListener
  private pendingBarrages: Map<string, PendingBarrage> = new Map()
  private isCollectionEnabled: boolean = false
  private isApplicationActive: boolean = false
  private applicationStateCallback?: ApplicationStateChangeCallback

  activate(liveID: string): void {
    if (this.liveID === liveID) {
      return
    }
    this.deactivate()
    if (liveID.length === 0) {
      return
    }
    this.liveID = liveID
    this.isCollectionEnabled = true
    this.isApplicationActive = true
    this.giftStore = GiftStore.create(liveID)
    this.giftStore.setLanguage(LiveKitResources.giftLanguageCode)
    this.updateCollection()
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => this.setApplicationActive(true),
      onApplicationBackground: () => this.setApplicationActive(false),
    }
    this.applicationStateCallback = callback
    getContext().getApplicationContext().on('applicationStateChange', callback)
  }

  deactivate(): void {
    if (this.applicationStateCallback !== undefined) {
      getContext().getApplicationContext().off('applicationStateChange', this.applicationStateCallback)
      this.applicationStateCallback = undefined
    }
    this.isCollectionEnabled = false
    this.isApplicationActive = false
    this.updateCollection()
    this.giftStore = undefined
    this.liveID = undefined
  }

  setCollectionEnabled(enabled: boolean): void {
    if (this.isCollectionEnabled === enabled) {
      return
    }
    this.isCollectionEnabled = enabled
    this.updateCollection()
  }

  private setApplicationActive(isActive: boolean): void {
    if (this.isApplicationActive === isActive) {
      return
    }
    this.isApplicationActive = isActive
    this.updateCollection()
  }

  private updateCollection(): void {
    if (this.giftListener !== undefined) {
      this.giftStore?.removeGiftListener(this.giftListener)
      this.giftListener = undefined
    }
    this.pendingBarrages.forEach((pending: PendingBarrage) => clearTimeout(pending.timer))
    this.pendingBarrages.clear()
    if (!this.isCollectionEnabled || !this.isApplicationActive || this.giftStore === undefined) {
      return
    }
    const listener = new GiftListener()
    listener.onReceiveGift = (liveID: string, gift: Gift, count: number, sender: LiveUserInfo) => {
      if (this.giftListener === listener) {
        this.receive(liveID, gift, count, sender)
      }
    }
    this.giftListener = listener
    this.giftStore.addGiftListener(listener)
  }

  private receive(eventLiveID: string, gift: Gift, count: number, sender: LiveUserInfo): void {
    if (eventLiveID !== this.liveID || count <= 0) {
      return
    }
    const key = `${sender.userID}\u0000${gift.giftID}`
    const pending = this.pendingBarrages.get(key)
    const barrage = pending?.barrage ?? new LiveGiftBarrage(gift.giftID, gift.name, gift.iconURL, 0, sender.userID,
      sender.userName, sender.level)
    barrage.count = Math.min(Number.MAX_SAFE_INTEGER, barrage.count + count)
    if (pending !== undefined) {
      clearTimeout(pending.timer)
    }
    const timer = setTimeout(() => {
      const settled = this.pendingBarrages.get(key)
      if (settled?.timer !== timer) {
        return
      }
      this.pendingBarrages.delete(key)
      this.onGiftBarrageSettled?.(settled.barrage)
    }, 2000)
    this.pendingBarrages.set(key, new PendingBarrage(barrage, timer))
  }
}
