import { util } from '@kit.ArkTS'
import { Barrage, BarrageStore, LiveAudienceStore, LiveUserInfo, LoginStore } from '@tencentcloud/atomicxcore'
import { LiveGiftBarrage } from '../gift/GiftBarrageStore'
import { LiveKitErrorText } from '../LiveKitErrorText'
import { LiveKitDataObserver, LiveKitResources } from '../LiveKitResources'
import { LiveKitLog } from '../log/LiveKitLog'

export class Comment {
  id: string
  senderName: string
  text: string
  level: number
  isHost: boolean
  gift?: LiveGiftBarrage
  timestamp: number

  constructor(id: string, senderName: string, text: string, level: number, isHost: boolean, timestamp: number,
    gift?: LiveGiftBarrage) {
    this.id = id
    this.senderName = senderName
    this.text = text
    this.level = level
    this.isHost = isHost
    this.timestamp = timestamp
    this.gift = gift
  }
}

export class BarrageUIState {
  liveID: string = ''
  comments: Comment[] = []
}

export class BarrageUIStore {
  onSendError?: (message: string) => void
  private stateChanged?: (state: BarrageUIState) => void
  private sessionID: string = util.generateRandomUUID()
  private pendingSends: Set<string> = new Set()
  state: BarrageUIState = new BarrageUIState()
  private barrageStore?: BarrageStore
  private unobserve?: () => void
  private hostUserID: string = ''
  private textComments: Comment[] = []
  private giftBarrages: Comment[] = []

  set onStateChanged(callback: ((state: BarrageUIState) => void) | undefined) {
    this.stateChanged = callback
    callback?.(this.state)
  }

  get onStateChanged(): ((state: BarrageUIState) => void) | undefined {
    return this.stateChanged
  }

  activate(liveID: string, hostUserID: string): void {
    if (liveID.length === 0) {
      this.deactivate()
      return
    }
    if (this.state.liveID === liveID && this.hostUserID === hostUserID && this.barrageStore !== undefined) {
      return
    }
    this.deactivate()
    this.state.liveID = liveID
    this.hostUserID = hostUserID
    const sessionID = this.sessionID
    const barrageStore = BarrageStore.create(liveID)
    this.barrageStore = barrageStore
    this.unobserve = LiveKitDataObserver.observe(barrageStore.barrageState.messageList, () => {
      if (this.sessionID === sessionID && this.state.liveID === liveID) {
        this.apply(barrageStore.barrageState.messageList.getAllData())
      }
    })
    this.apply(barrageStore.barrageState.messageList.getAllData())
  }

  deactivate(): void {
    this.sessionID = util.generateRandomUUID()
    this.pendingSends.clear()
    this.unobserve?.()
    this.unobserve = undefined
    this.barrageStore = undefined
    this.hostUserID = ''
    this.textComments = []
    this.giftBarrages = []
    this.state = new BarrageUIState()
    this.notify()
  }

  sendComment(text: string): void {
    const value = text.trim()
    const barrageStore = this.barrageStore
    if (value.length === 0 || barrageStore === undefined) {
      return
    }
    if (this.isSelfMessageBanned()) {
      this.onSendError?.(BarrageUIStore.sendErrorMessage(10017))
      return
    }
    const sessionID = this.sessionID
    const requestID = util.generateRandomUUID()
    const liveID = this.state.liveID
    this.pendingSends.add(requestID)
    barrageStore.sendTextMessage(value, new Map()).then(() => {
      this.pendingSends.delete(requestID)
    }).catch((error: Error) => {
      if (this.sessionID !== sessionID || !this.pendingSends.delete(requestID)) {
        return
      }
      const code = LiveKitErrorText.code(error)
      LiveKitLog.error(`[BarrageUIStore] send comment failed liveID=${liveID} code=${code} message=${error.message}`)
      this.onSendError?.(BarrageUIStore.sendErrorMessage(code))
    })
  }

  isSelfMessageBanned(): boolean {
    const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (this.state.liveID.length === 0 || userID.length === 0) {
      return false
    }
    return LiveAudienceStore.create(this.state.liveID).liveAudienceState.messageBannedUserList.getAllData()
      .some((user: LiveUserInfo) => user.userID === userID)
  }

  static sendErrorMessage(code: number): string {
    let key = 'send_failed'
    if (code === 10017 || code === -2381) {
      key = 'muted'
    } else if (code === -2380) {
      key = 'all_muted'
    } else if ([10023, 10006, 7008, 9506, -2].includes(code)) {
      key = 'too_frequent'
    } else if (code === 7015 || code === 80001) {
      key = 'content_rejected'
    } else if (code === 8001 || code === 80002) {
      key = 'too_long'
    } else if ([6014, 6206, -1002].includes(code)) {
      key = 'login_expired'
    } else if (code === 6208) {
      key = 'login_elsewhere'
    } else if (code === -2101) {
      key = 'not_joined'
    } else if (code === 10010) {
      key = 'room_unavailable'
    } else if (code === 10007) {
      key = 'no_permission'
    } else if (code === 9508 || code === 9512) {
      key = 'network_error'
    } else if (code === 9510 || (code >= 9518 && code <= 9521) || (code >= 9523 && code <= 9525)) {
      key = 'timeout'
    } else if (code === 10016) {
      key = 'send_rejected'
    }
    return LiveKitResources.localizedString(`tuilivekit.comment.${key}`)
  }

  appendGiftBarrage(gift: LiveGiftBarrage): void {
    if (this.state.liveID.length === 0 || this.giftBarrages.some((item: Comment) => item.id === `gift-${gift.id}`)) {
      return
    }
    const senderName = gift.senderName.length === 0 ? gift.senderID : gift.senderName
    this.giftBarrages.push(new Comment(`gift-${gift.id}`,
      senderName.length === 0 ? LiveKitResources.localizedString('tuilivekit.common.viewer') : senderName, '',
      gift.senderLevel, false, Date.now() / 1000, gift))
    this.giftBarrages = this.giftBarrages.slice(-100)
    this.rebuildComments()
  }

  private apply(messageList: Barrage[]): void {
    this.textComments = messageList.slice(-100).map((barrage: Barrage) => {
      const senderName = barrage.sender.userName.length === 0 ? barrage.sender.userID : barrage.sender.userName
      return new Comment(`${barrage.sequence}-${barrage.timestampInSecond}`,
        senderName.length === 0 ? LiveKitResources.localizedString('tuilivekit.common.viewer') : senderName,
        barrage.textContent, barrage.sender.level,
        this.hostUserID.length > 0 && barrage.sender.userID === this.hostUserID, barrage.timestampInSecond)
    })
    this.rebuildComments()
  }

  private rebuildComments(): void {
    this.state.comments = this.textComments.concat(this.giftBarrages).sort((lhs: Comment, rhs: Comment) =>
      lhs.timestamp === rhs.timestamp ? (lhs.id < rhs.id ? -1 : lhs.id > rhs.id ? 1 : 0) : lhs.timestamp - rhs.timestamp)
      .slice(-100)
    this.notify()
  }

  private notify(): void {
    this.stateChanged?.(this.state)
  }
}
