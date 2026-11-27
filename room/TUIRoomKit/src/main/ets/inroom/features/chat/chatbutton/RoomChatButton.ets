import {
  CompletionHandler,
  ConversationInfo,
  ConversationListStore,
  GetConversationInfoCompletionHandler,
  MessageEvent,
  MessageListStore,
  OnReceiveNewMessage,
} from '@tencentcloud/atomicxcore'
import { RoomPopup } from '../../../../base/popup/RoomPopup'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomChatPopup } from '../roomchat/RoomChatPopup'

@Component
export struct RoomChatButton {
  @Prop @Watch('bindRoom') roomID: string = ''
  @State private isPressed: boolean = false
  @State private isChatPresented: boolean = false
  @State private unreadCount: number = 0
  private messageListStore?: MessageListStore = undefined
  private readonly conversationStore: ConversationListStore = ConversationListStore.create()
  private unsubscribeMessage?: () => void = undefined
  private unreadRequestID: number = 0

  aboutToAppear(): void {
    this.bindRoom()
  }

  aboutToDisappear(): void {
    this.unreadRequestID++
    this.unsubscribeMessage?.()
    this.unsubscribeMessage = undefined
  }

  private bindRoom(): void {
    if (this.roomID.length === 0) {
      return
    }
    this.unsubscribeMessage?.()
    this.messageListStore = MessageListStore.create(`group_${this.roomID}`)
    this.unsubscribeMessage = this.messageListStore.messageEventFlow.subscribe(this, (event: MessageEvent) => {
      if (event instanceof OnReceiveNewMessage) {
        if (this.isChatPresented) {
          this.clearUnreadCount()
        } else {
          this.refreshUnreadCount()
        }
      }
    })
    this.refreshUnreadCount()
  }

  private refreshUnreadCount(): void {
    if (this.roomID.length === 0) {
      return
    }
    if (this.isChatPresented) {
      this.clearUnreadCount()
      return
    }
    const requestID = ++this.unreadRequestID
    const handler: GetConversationInfoCompletionHandler = {
      onSuccess: (info: ConversationInfo) => {
        if (requestID !== this.unreadRequestID || this.isChatPresented) {
          return
        }
        this.unreadCount = info.unreadCount
      },
      onFailure: (_code: number, _desc: string) => {
      },
    }
    this.conversationStore.getConversationInfo(`group_${this.roomID}`, handler)
  }

  private clearUnreadCount(): void {
    if (this.roomID.length === 0) {
      return
    }
    const requestID = ++this.unreadRequestID
    const handler: CompletionHandler = {
      onSuccess: () => {
        if (requestID === this.unreadRequestID) {
          this.unreadCount = 0
        }
      },
      onFailure: (_code: number, _desc: string) => {
      },
    }
    this.conversationStore.clearConversationUnreadCount(`group_${this.roomID}`, handler)
  }

  private handleDismiss(): void {
    this.isChatPresented = false
    this.refreshUnreadCount()
  }

  build() {
    Stack() {
      Image(RoomResources.image('roomkit_icon_chat'))
        .width(20)
        .height(20)
        .fillColor(this.isChatPresented ? $r('app.color.roomkit_accent') : $r('app.color.roomkit_fg_icon'))
      if (this.unreadCount > 0) {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor($r('app.color.roomkit_danger'))
          .position({ right: 2, top: 2 })
      }
      RoomPopup({
        isPresented: this.isChatPresented,
        dismissKeyboardOnTouch: false,
        onDismiss: () => this.handleDismiss(),
      }) {
        RoomChatPopup({ roomID: this.roomID })
      }
    }
    .width(44)
    .height(44)
    .backgroundColor(this.isChatPresented ? $r('app.color.roomkit_accent_soft') : $r('app.color.roomkit_bg_hover'))
    .borderRadius(22)
    .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
    .animation({ duration: 80 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => {
      this.isChatPresented = true
      this.clearUnreadCount()
    })
  }
}
