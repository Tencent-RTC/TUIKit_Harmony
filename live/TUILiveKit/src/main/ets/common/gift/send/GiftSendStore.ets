import { GiftCategory, GiftStore, Gift } from '@tencentcloud/atomicxcore'
import { LiveKitDataObserver, LiveKitResources } from '../../LiveKitResources'
import { LiveKitLog } from '../../log/LiveKitLog'

export class GiftItem {
  id: string
  name: string
  coins: number
  iconURL: string
  resourceURL: string
  categoryID: string
  categoryName: string

  constructor(gift: Gift, category: GiftCategory) {
    this.id = gift.giftID
    this.name = gift.name
    this.coins = gift.coins
    this.iconURL = gift.iconURL
    this.resourceURL = gift.resourceURL
    this.categoryID = category.categoryID
    this.categoryName = category.name
  }
}

export class GiftCategoryGroup {
  id: string
  name: string
  gifts: GiftItem[]

  constructor(id: string, name: string, gifts: GiftItem[]) {
    this.id = id
    this.name = name
    this.gifts = gifts
  }
}

export class GiftSendState {
  liveID?: string
  gifts: GiftItem[] = []
  categories: GiftCategoryGroup[] = []
  isLoading: boolean = false
}

export class GiftSendStore {
  onStateChanged?: (state: GiftSendState) => void
  private state: GiftSendState = new GiftSendState()
  private giftStore?: GiftStore
  private unobserve?: () => void
  private activationID: number = 0

  activate(liveID: string): void {
    if (this.state.liveID === liveID) {
      return
    }
    this.deactivate()
    const activationID = ++this.activationID
    this.state.liveID = liveID
    this.state.isLoading = true
    const store = GiftStore.create(liveID)
    this.giftStore = store
    store.setLanguage(LiveKitResources.giftLanguageCode)
    this.unobserve = LiveKitDataObserver.observe(store.giftState.usableGifts, () => this.applyGiftState())
    this.applyGiftState()
    store.refreshUsableGifts().catch(() => {
    }).finally(() => {
      if (this.activationID === activationID && this.state.liveID === liveID) {
        this.state.isLoading = false
        this.notify()
      }
    })
  }

  deactivate(): void {
    this.activationID++
    this.unobserve?.()
    this.unobserve = undefined
    this.giftStore = undefined
    this.state = new GiftSendState()
    this.notify()
  }

  sendGift(id: string, count: number = 1, completion?: (success: boolean) => void): void {
    const store = this.giftStore
    if (store === undefined) {
      completion?.(false)
      return
    }
    store.sendGift(id, Math.max(1, count), '').then(() => completion?.(true)).catch((error: Error) => {
      LiveKitLog.error(`Gift send failed: gift=${id}, error=${error.message}`)
      completion?.(false)
    })
  }

  private applyGiftState(): void {
    const usableGifts = this.giftStore?.giftState.usableGifts.getAllData() ?? []
    this.state.categories = usableGifts.map((category: GiftCategory) => new GiftCategoryGroup(category.categoryID,
      category.name, category.giftList.map((gift: Gift) => new GiftItem(gift, category))))
    this.state.gifts = this.state.categories.flatMap((group: GiftCategoryGroup) => group.gifts)
    if (usableGifts.length > 0) {
      this.state.isLoading = false
    }
    this.notify()
  }

  private notify(): void {
    this.onStateChanged?.(this.state)
  }
}
