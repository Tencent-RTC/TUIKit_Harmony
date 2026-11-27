import { fileIo } from '@kit.CoreFileKit'
import { inputMethod } from '@kit.IMEKit'
import {
  CompletionHandler,
  ImageMessagePayload,
  ImageSendMessagePayload,
  MessageActionStore,
  MessageInfo,
  MessageInputStore,
  ParticipantRole,
  RoomParticipantState,
  RoomParticipantStore,
  RoomState,
  RoomStore,
  SendMessagePayload,
  TextMessagePayload,
  TextSendMessagePayload,
} from '@tencentcloud/atomicxcore'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { RoomSafeArea } from '../../../../base/util/RoomSafeArea'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomChatEmojiView } from './RoomChatEmojiView'

function resolveChatMuted(roomID: string, participantState?: RoomParticipantState, roomState?: RoomState): boolean {
  const role = participantState?.localParticipant?.role
  const isPrivileged = role === ParticipantRole.owner || role === ParticipantRole.admin
  const locallyMuted = participantState?.localParticipant?.isMessageDisabled ?? false
  const allMuted = roomState?.currentRoom?.roomID === roomID &&
    (roomState?.currentRoom?.isAllMessageDisabled ?? false)
  return locallyMuted || (allMuted && !isPrivileged)
}

export function roomChatIsMuted(roomID: string): boolean {
  if (roomID.length === 0) {
    return false
  }
  return resolveChatMuted(roomID, RoomParticipantStore.create(roomID).state, RoomStore.shared().state)
}

@Observed
export class RoomChatInputController {
  isSending: boolean = false
  onSendStateChange?: (sending: boolean) => void
  private roomID: string = ''
  private messageInputStore?: MessageInputStore = undefined

  bind(roomID: string): void {
    if (this.roomID === roomID) {
      return
    }
    this.roomID = roomID
    this.messageInputStore = MessageInputStore.create(`group_${roomID}`)
  }

  sendText(text: string): void {
    this.send(new TextSendMessagePayload(text))
  }

  sendImage(path: string, width: number, height: number): void {
    this.send(new ImageSendMessagePayload(path, width, height))
  }

  resend(message: MessageInfo): void {
    const payload = this.sendPayload(message)
    if (payload === undefined || this.isSending || roomChatIsMuted(this.roomID)) {
      return
    }
    this.beginSending()
    MessageActionStore.create(message).delete({
      onSuccess: () => this.performSend(payload),
      onFailure: (code: number, desc: string) => {
        this.finishSending()
        this.showError(code, desc)
      },
    })
  }

  private send(payload: SendMessagePayload): void {
    if (this.isSending || roomChatIsMuted(this.roomID)) {
      return
    }
    this.beginSending()
    this.performSend(payload)
  }

  private beginSending(): void {
    this.isSending = true
    this.onSendStateChange?.(true)
  }

  private performSend(payload: SendMessagePayload): void {
    const store = this.messageInputStore
    if (store === undefined) {
      this.finishSending()
      return
    }
    store.sendMessage(payload, undefined, this.completion((code?: number, desc?: string) => {
      this.finishSending()
      if (code !== undefined) {
        this.showError(code, desc ?? '')
      }
    }))
  }

  private finishSending(): void {
    this.isSending = false
    this.onSendStateChange?.(false)
  }

  private sendPayload(message: MessageInfo): SendMessagePayload | undefined {
    if (message.messagePayload instanceof TextMessagePayload) {
      return new TextSendMessagePayload((message.messagePayload as TextMessagePayload).text)
    }
    if (message.messagePayload instanceof ImageMessagePayload) {
      const payload = message.messagePayload as ImageMessagePayload
      const path = payload.originalImagePath ?? ''
      if (path.length === 0 || !fileIo.accessSync(path)) {
        return undefined
      }
      return new ImageSendMessagePayload(path, payload.originalImageWidth, payload.originalImageHeight)
    }
    return undefined
  }

  private completion(callback: (code?: number, desc?: string) => void): CompletionHandler {
    return {
      onSuccess: () => callback(),
      onFailure: (code: number, desc: string) => callback(code, desc),
    }
  }

  private showError(code: number, desc: string): void {
    const error = new Error(desc)
    Reflect.set(error, 'code', code)
    ErrorLocalized.showError(error)
  }
}

@Component
export struct RoomChatInputView {
  @Link draft: string
  @ObjectLink @Watch('setSending') sendController: RoomChatInputController
  @Prop @Watch('bindRoom') roomID: string = ''
  @Prop @Watch('focusForReedit') reeditRevision: number = 0
  @State @Watch('setMuted') private participantState?: RoomParticipantState = undefined
  @State @Watch('setMuted') private roomState: RoomState = RoomStore.shared().state
  @State private isEmojiPresented: boolean = false
  @StorageProp(RoomSafeArea.keyboardKey) @Watch('onKeyboardChanged') private keyboardHeight: number = 0
  @StorageProp(RoomSafeArea.bottomKey) private safeBottom: number = 0
  onPickImage?: () => void
  onLayoutChange?: () => void
  private readonly inputID: string = 'room_chat_message_input'
  private readonly inputController: TextAreaController = new TextAreaController()

  aboutToAppear(): void {
    this.bindRoom()
  }

  private bindRoom(): void {
    this.sendController.bind(this.roomID)
    this.participantState = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID).state : undefined
  }

  private isChatMuted(): boolean {
    return resolveChatMuted(this.roomID, this.participantState, this.roomState)
  }

  private isAllMutedForInput(): boolean {
    const role = this.participantState?.localParticipant?.role
    const isPrivileged = role === ParticipantRole.owner || role === ParticipantRole.admin
    return this.roomState.currentRoom?.roomID === this.roomID &&
      (this.roomState.currentRoom?.isAllMessageDisabled ?? false) && !isPrivileged
  }

  private setMuted(): void {
    if (this.isChatMuted()) {
      this.hideEmoji()
      inputMethod.getController().stopInputSession()
    }
  }

  private setSending(): void {
    if (this.sendController.isSending) {
      this.hideEmoji()
    }
  }

  private focusForReedit(): void {
    if (this.reeditRevision <= 0 || this.isChatMuted()) {
      return
    }
    this.hideEmoji()
    setTimeout(() => {
      this.inputController.caretPosition(this.draft.length)
      this.getUIContext().getFocusController().requestFocus(this.inputID)
      this.onLayoutChange?.()
    }, 0)
  }

  private placeholder(): string {
    if (!this.isChatMuted()) {
      return RoomResources.string('roomkit_room_chat_input_placeholder')
    }
    return RoomResources.string(this.isAllMutedForInput() ? 'roomkit_room_chat_muted_all_placeholder' :
      'roomkit_room_chat_muted_placeholder')
  }

  private canSend(): boolean {
    return this.draft.trim().length > 0 && !this.isChatMuted() && !this.sendController.isSending
  }

  private sendCurrentText(): void {
    const text = this.draft.trim()
    if (text.length === 0 || this.isChatMuted() || this.sendController.isSending) {
      return
    }
    this.draft = ''
    this.hideEmoji()
    this.sendController.sendText(text)
  }

  private insertEmoji(emoji: string): void {
    if (this.isChatMuted() || this.sendController.isSending) {
      return
    }
    this.draft += emoji
    this.onLayoutChange?.()
  }

  private toggleEmoji(): void {
    if (this.isChatMuted() || this.sendController.isSending) {
      return
    }
    this.isEmojiPresented = !this.isEmojiPresented
    if (this.isEmojiPresented) {
      inputMethod.getController().stopInputSession()
    } else {
      this.getUIContext().getFocusController().requestFocus(this.inputID)
    }
    this.onLayoutChange?.()
  }

  private hideEmoji(): void {
    if (!this.isEmojiPresented) {
      return
    }
    this.isEmojiPresented = false
    this.onLayoutChange?.()
  }

  private editingChanged(isEditing: boolean): void {
    if (isEditing) {
      this.hideEmoji()
      this.onLayoutChange?.()
    }
  }

  private keyboardOverlap(): number {
    return Math.max(this.keyboardHeight - this.safeBottom, 0)
  }

  private onKeyboardChanged(): void {
    this.onLayoutChange?.()
  }

  build() {
    Column() {
      Row({ space: 6 }) {
        Button() {
          Image(RoomResources.image('roomkit_icon_emoji')).width(16).height(16)
        }
        .width(24)
        .height(24)
        .padding(0)
        .backgroundColor(Color.Transparent)
        .enabled(!this.isChatMuted() && !this.sendController.isSending)
        .onClick(() => this.toggleEmoji())
        Button() {
          Image(RoomResources.image('roomkit_icon_paperclip')).width(16).height(16)
        }
        .width(24)
        .height(24)
        .padding(0)
        .backgroundColor(Color.Transparent)
        .enabled(!this.isChatMuted() && !this.sendController.isSending)
        .onClick(() => {
          this.hideEmoji()
          inputMethod.getController().stopInputSession()
          this.onPickImage?.()
        })
        TextArea({ text: $$this.draft, placeholder: this.placeholder(), controller: this.inputController })
          .id(this.inputID)
          .layoutWeight(1)
          .constraintSize({ minHeight: 34, maxHeight: 96 })
          .maxLines(4)
          .fontSize(15)
          .lineHeight(18)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .placeholderColor($r('app.color.roomkit_fg_tertiary'))
          .placeholderFont({ size: 15 })
          .backgroundColor($r('app.color.roomkit_bg_hover'))
          .borderRadius(17)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .enterKeyType(EnterKeyType.Send)
          .enabled(!this.isChatMuted() && !this.sendController.isSending)
          .onChange((value: string) => {
            this.draft = value
            this.onLayoutChange?.()
          })
          .onSubmit(() => this.sendCurrentText())
          .onEditChange((isEditing: boolean) => this.editingChanged(isEditing))
        Button() {
          Image(RoomResources.image('roomkit_icon_send'))
            .width(18)
            .height(18)
            .fillColor($r('app.color.roomkit_fg_on_accent'))
        }
        .width(34)
        .height(34)
        .padding(8)
        .borderRadius(17)
        .backgroundColor($r('app.color.roomkit_accent'))
        .opacity(this.canSend() ? 1 : 0.38)
        .enabled(this.canSend())
        .onClick(() => this.sendCurrentText())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8, right: 16, top: 8, bottom: 12 })
      if (this.isEmojiPresented) {
        RoomChatEmojiView({ onSelect: (emoji: string) => this.insertEmoji(emoji) })
      }
    }
    .width('100%')
    .padding({ bottom: this.keyboardOverlap() })
    .backgroundColor($r('app.color.roomkit_bg_surface'))
    .opacity(this.isChatMuted() ? 0.6 : 1)
  }
}
