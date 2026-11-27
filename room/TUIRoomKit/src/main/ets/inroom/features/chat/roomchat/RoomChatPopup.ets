import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { fileIo } from '@kit.CoreFileKit'
import { inputMethod } from '@kit.IMEKit'
import { image } from '@kit.ImageKit'
import photoAccessHelper from '@ohos.file.photoAccessHelper'
import pasteboard from '@ohos.pasteboard'
import measure from '@ohos.measure'
import {
  CompletionHandler,
  ImageMessagePayload,
  MessageActionStore,
  MessageEvent,
  MessageInfo,
  MessageListStore,
  MessageStatus,
  OnMessageDeleted,
  OnMessageRevoked,
  OnReceiveNewMessage,
  RoomParticipant,
  RoomParticipantState,
  RoomParticipantStore,
  TextMessagePayload,
} from '@tencentcloud/atomicxcore'
import { RoomDialog } from '../../../../base/dialog/RoomDialog'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { RoomToast } from '../../../../base/toast/RoomToast'
import { RoomDataObserver } from '../../../../base/util/RoomDataObserver'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomChatImagePreviewView } from './RoomChatImagePreviewView'
import { RoomChatInputController, RoomChatInputView, roomChatIsMuted } from './RoomChatInputView'
import { RoomChatMessageCell, RoomChatRevokedCell } from './RoomChatMessageCell'

class SelectedImage {
  path: string
  width: number
  height: number

  constructor(path: string, width: number, height: number) {
    this.path = path
    this.width = width
    this.height = height
  }
}

@Component
export struct RoomChatPopup {
  @Prop roomID: string = ''
  @State private messages: MessageInfo[] = []
  @State private participants: RoomParticipant[] = []
  @State private participantState?: RoomParticipantState = undefined
  @State private isInitialLoading: boolean = true
  @State private isLoadingOlder: boolean = false
  @State private sendController: RoomChatInputController = new RoomChatInputController()
  @State private isPinnedToBottom: boolean = true
  @State private draft: string = ''
  @State private reeditRevision: number = 0
  @State private selectedMessage?: MessageInfo = undefined
  @State private previewImage?: ImageMessagePayload = undefined
  @State private isImagePreviewPresented: boolean = false
  @State private resendMessage?: MessageInfo = undefined
  @State private isResendConfirmPresented: boolean = false
  private messageListStore?: MessageListStore = undefined
  private unsubscribeMessage?: () => void = undefined
  private readonly scroller: Scroller = new Scroller()
  private readonly reeditTextByMessageID: Map<string, string> = new Map<string, string>()
  private readonly participantListObserver: RoomDataObserver = new RoomDataObserver(() => this.updateParticipants())
  private isMounted: boolean = false
  private lifecycleRevision: number = 0
  private firstVisibleIndex: number = -1
  private lastVisibleIndex: number = -1
  private olderAnchorMessageID?: string = undefined
  private olderAnchorPreviousIndex: number = -1
  private isRestoringOlderAnchor: boolean = false
  private bottomScrollRevision: number = 0
  private isOpeningScrollPending: boolean = true
  private previewPresentationRevision: number = 0

  aboutToAppear(): void {
    this.isMounted = true
    this.lifecycleRevision++
    this.isOpeningScrollPending = true
    this.isPinnedToBottom = true
    this.firstVisibleIndex = -1
    this.lastVisibleIndex = -1
    const conversationID = `group_${this.roomID}`
    this.messageListStore = MessageListStore.create(conversationID)
    this.sendController.bind(this.roomID)
    this.sendController.onSendStateChange = (sending: boolean) => {
      if (!this.isMounted) {
        return
      }
      this.isPinnedToBottom = true
      this.refreshMessages()
      if (!sending) {
        this.schedule(() => this.scrollToBottom(false))
      }
    }
    const participantStore = RoomParticipantStore.create(this.roomID)
    this.participantState = participantStore.state
    participantStore.state.participantList.registerDataChangeListener(this.participantListObserver)
    this.updateParticipants()
    this.unsubscribeMessage = this.messageListStore.messageEventFlow.subscribe(this, (event: MessageEvent) => {
      if (event instanceof OnReceiveNewMessage || event instanceof OnMessageRevoked ||
        event instanceof OnMessageDeleted) {
        this.refreshMessages()
      }
    })
    this.refreshMessages()
    this.loadInitialMessages()
  }

  aboutToDisappear(): void {
    this.isMounted = false
    this.lifecycleRevision++
    this.unsubscribeMessage?.()
    this.unsubscribeMessage = undefined
    this.participantState?.participantList.unregisterDataChangeListener(this.participantListObserver)
  }

  private schedule(action: () => void): void {
    this.scheduleAfter(0, action)
  }

  private scheduleAfter(milliseconds: number, action: () => void): void {
    const revision = this.lifecycleRevision
    setTimeout(() => {
      if (this.isMounted && revision === this.lifecycleRevision) {
        action()
      }
    }, milliseconds)
  }

  private updateParticipants(): void {
    this.participants = this.participantState?.participantList.toArray() ?? []
  }

  private participant(message: MessageInfo): RoomParticipant | undefined {
    return this.participants.find((participant: RoomParticipant) => participant.userID === message.from.userID)
  }

  private completion(callback: (code?: number, desc?: string) => void): CompletionHandler {
    return {
      onSuccess: () => {
        if (this.isMounted) {
          callback()
        }
      },
      onFailure: (code: number, desc: string) => {
        if (this.isMounted) {
          callback(code, desc)
        }
      },
    }
  }

  private showError(code: number, desc: string): void {
    const error = new Error(desc)
    Reflect.set(error, 'code', code)
    ErrorLocalized.showError(error)
  }

  private loadInitialMessages(): void {
    const store = this.messageListStore
    if (store === undefined) {
      return
    }
    this.isInitialLoading = true
    store.loadMessages(undefined, this.completion((code?: number, desc?: string) => {
      this.isInitialLoading = false
      this.refreshMessages()
      if (code !== undefined) {
        this.showError(code, desc ?? '')
      }
      this.schedule(() => {
        this.scrollToBottom(false)
        this.ensureHistoryFillsViewport()
      })
    }))
  }

  private refreshMessages(): void {
    const source = this.messageListStore?.state.messageList ?? []
    const filtered = source.filter((message: MessageInfo) => {
      if (message.status === MessageStatus.DELETED) {
        return false
      }
      return message.status === MessageStatus.REVOKED || message.messagePayload instanceof TextMessagePayload ||
        message.messagePayload instanceof ImageMessagePayload
    })
    const wasPinned = this.isPinnedToBottom
    const appendedBySelf = filtered.length > this.messages.length &&
      filtered[filtered.length - 1]?.isSentBySelf === true
    this.messages = filtered
    this.schedule(() => {
      if (!this.restoreOlderAnchor() && (wasPinned || appendedBySelf)) {
        if (appendedBySelf) {
          this.isPinnedToBottom = true
        }
        this.scrollToBottom(false)
      }
    })
  }

  private loadOlderMessages(): void {
    const store = this.messageListStore
    if (store === undefined || this.isInitialLoading || this.isLoadingOlder || this.messages.length === 0 ||
      !store.state.hasOlderMessages) {
      return
    }
    const anchor = this.messages[this.firstVisibleIndex]
    this.olderAnchorMessageID = anchor?.msgID
    this.olderAnchorPreviousIndex = this.firstVisibleIndex
    this.isLoadingOlder = true
    store.loadOlderMessages(this.completion((code?: number, desc?: string) => {
      this.isLoadingOlder = false
      if (code !== undefined) {
        this.olderAnchorMessageID = undefined
        this.showError(code, desc ?? '')
        return
      }
      this.refreshMessages()
      this.schedule(() => {
        this.restoreOlderAnchor()
        this.ensureHistoryFillsViewport()
      })
    }))
  }

  private restoreOlderAnchor(): boolean {
    const anchorID = this.olderAnchorMessageID
    if (anchorID === undefined) {
      return false
    }
    if (this.isRestoringOlderAnchor) {
      return true
    }
    const index = this.messages.findIndex((message: MessageInfo) => message.msgID === anchorID)
    if (index < 0 || index <= this.olderAnchorPreviousIndex) {
      return false
    }
    this.isRestoringOlderAnchor = true
    this.scroller.scrollToIndex(index, false, ScrollAlign.START)
    this.confirmOlderAnchor(anchorID, 0)
    return true
  }

  private confirmOlderAnchor(anchorID: string, attempt: number): void {
    this.scheduleAfter(32, () => {
      if (this.olderAnchorMessageID !== anchorID) {
        this.isRestoringOlderAnchor = false
        return
      }
      const index = this.messages.findIndex((message: MessageInfo) => message.msgID === anchorID)
      if (index >= 0 && this.firstVisibleIndex <= index && this.lastVisibleIndex >= index) {
        this.olderAnchorMessageID = undefined
        this.olderAnchorPreviousIndex = -1
        this.isRestoringOlderAnchor = false
        this.isPinnedToBottom = false
        this.ensureHistoryFillsViewport()
      } else if (index >= 0 && attempt < 4) {
        this.scroller.scrollToIndex(index, false, ScrollAlign.START)
        this.confirmOlderAnchor(anchorID, attempt + 1)
      } else {
        this.isRestoringOlderAnchor = false
        if (index < 0) {
          this.olderAnchorMessageID = undefined
          this.olderAnchorPreviousIndex = -1
        }
      }
    })
  }

  private ensureHistoryFillsViewport(): void {
    if (this.isInitialLoading || this.isLoadingOlder || this.isRestoringOlderAnchor || this.messages.length === 0 ||
      this.messageListStore?.state.hasOlderMessages !== true) {
      return
    }
    const allVisible = this.firstVisibleIndex === 0 && this.lastVisibleIndex >= this.messages.length - 1
    if (allVisible) {
      this.loadOlderMessages()
    }
  }

  private resend(message: MessageInfo): void {
    this.sendController.resend(message)
  }

  private requestResend(message: MessageInfo): void {
    this.resendMessage = message
    this.isResendConfirmPresented = true
  }

  private copyMessage(message: MessageInfo): void {
    if (!(message.messagePayload instanceof TextMessagePayload)) {
      return
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN,
      (message.messagePayload as TextMessagePayload).text)
    pasteboard.getSystemPasteboard().setData(data, (error) => {
      RoomToast.show(RoomResources.string(error ? 'roomkit_room_common_copy_failed' : 'roomkit_room_common_copied'))
    })
  }

  private revokeMessage(message: MessageInfo): void {
    const payload = message.messagePayload
    if (message.isSentBySelf && payload instanceof TextMessagePayload) {
      this.reeditTextByMessageID.set(message.msgID, payload.text)
    }
    MessageActionStore.create(message).revoke(this.completion((code?: number, desc?: string) => {
      if (code !== undefined) {
        this.showError(code, desc ?? '')
      }
      this.refreshMessages()
    }))
  }

  private reeditText(message: MessageInfo): string {
    const payload = message.messagePayload
    const payloadText = payload instanceof TextMessagePayload ? payload.text : ''
    return payloadText.length > 0 ? payloadText : this.reeditTextByMessageID.get(message.msgID) ?? ''
  }

  private deleteMessage(message: MessageInfo): void {
    MessageActionStore.create(message).delete(this.completion((code?: number, desc?: string) => {
      if (code !== undefined) {
        this.showError(code, desc ?? '')
      }
      this.refreshMessages()
    }))
  }

  private reedit(text: string): void {
    if (roomChatIsMuted(this.roomID)) {
      return
    }
    this.draft = text
    this.reeditRevision++
  }

  private presentImagePreview(payload: ImageMessagePayload): void {
    inputMethod.getController().stopInputSession()
    this.previewPresentationRevision++
    this.previewImage = payload
    this.isImagePreviewPresented = true
  }

  private dismissImagePreview(): void {
    if (!this.isImagePreviewPresented) return
    this.isImagePreviewPresented = false
    const revision = ++this.previewPresentationRevision
    this.scheduleAfter(200, () => {
      if (revision === this.previewPresentationRevision && !this.isImagePreviewPresented) {
        this.previewImage = undefined
      }
    })
  }

  private dismissKeyboard(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      inputMethod.getController().stopInputSession()
    }
  }

  private async presentImagePicker(): Promise<void> {
    if (this.sendController.isSending || roomChatIsMuted(this.roomID)) {
      return
    }
    try {
      const options = new photoAccessHelper.PhotoSelectOptions()
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 1
      const result = await new photoAccessHelper.PhotoViewPicker().select(options)
      const uri = result.photoUris[0]
      if (uri === undefined || uri.length === 0) {
        return
      }
      const selected = await this.copySelectedImage(uri)
      if (selected === undefined) {
        RoomToast.show(RoomResources.string('roomkit_room_chat_send_failed'))
      } else if (this.isMounted && !roomChatIsMuted(this.roomID)) {
        this.sendController.sendImage(selected.path, selected.width, selected.height)
      }
    } catch (error) {
    }
  }

  private async copySelectedImage(uri: string): Promise<SelectedImage | undefined> {
    const context = getContext() as common.UIAbilityContext
    const path = `${context.cacheDir}/room-chat-${util.generateRandomUUID()}`
    let sourceFile: fileIo.File | undefined = undefined
    let targetFile: fileIo.File | undefined = undefined
    let selectedImageSource: image.ImageSource | undefined = undefined
    try {
      sourceFile = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY)
      targetFile = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC)
      await fileIo.copyFile(sourceFile.fd, targetFile.fd, 0)
      selectedImageSource = image.createImageSource(path)
      const info = await selectedImageSource.getImageInfo()
      return new SelectedImage(path, info.size.width, info.size.height)
    } catch (error) {
      try {
        await fileIo.unlink(path)
      } catch (cleanupError) {
      }
      return undefined
    } finally {
      if (selectedImageSource !== undefined) {
        try {
          await selectedImageSource.release()
        } catch (releaseError) {
        }
      }
      if (sourceFile !== undefined) {
        await fileIo.close(sourceFile)
      }
      if (targetFile !== undefined) {
        await fileIo.close(targetFile)
      }
    }
  }

  private scrollToBottom(animated: boolean): void {
    const revision = ++this.bottomScrollRevision
    this.scrollToBottomWithRetry(animated, revision, 0)
  }

  private scrollToBottomWithRetry(animated: boolean, revision: number, attempt: number): void {
    if (this.messages.length === 0 || revision !== this.bottomScrollRevision) {
      return
    }
    this.scroller.scrollToIndex(this.messages.length - 1, animated, ScrollAlign.END)
    this.scheduleAfter(32, () => {
      if (revision !== this.bottomScrollRevision) {
        return
      }
      if (this.lastVisibleIndex >= this.messages.length - 1) {
        this.isOpeningScrollPending = false
        this.isPinnedToBottom = this.messages.length > 0
      } else if (attempt < 4) {
        this.scrollToBottomWithRetry(false, revision, attempt + 1)
      }
    })
  }

  private presentMessageActions(message: MessageInfo): void {
    if (message.status === MessageStatus.SENDING) {
      return
    }
    this.selectedMessage = message
  }

  @Builder
  private messageRow(message: MessageInfo, index: number) {
    if (message.status === MessageStatus.REVOKED) {
      RoomChatRevokedCell({
        message: message,
        participant: this.participant(message),
        fallbackText: this.reeditText(message),
        onReedit: (text: string) => this.reedit(text),
      })
    } else {
      RoomChatMessageCell({
        message: message,
        previousMessage: index > 0 ? this.messages[index - 1] : undefined,
        participant: this.participant(message),
        onRetry: (target: MessageInfo) => this.requestResend(target),
        onLongPress: (target: MessageInfo) => this.presentMessageActions(target),
        onImageClick: (payload: ImageMessagePayload) => this.presentImagePreview(payload),
        isActionPopoverPresented: this.selectedMessage?.msgID === message.msgID,
        onActionPopoverDismiss: () => this.selectedMessage = undefined,
        actionPopover: (): void => this.actionContent(message),
      })
    }
  }

  @Builder
  private messageList() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      List({ scroller: this.scroller }) {
        ForEach(this.messages, (message: MessageInfo, index: number) => {
          ListItem() {
            this.messageRow(message, index)
          }
        }, (message: MessageInfo) => `${message.msgID}:${message.status}`)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 10, bottom: 10 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .onReachStart(() => this.loadOlderMessages())
      .onReachEnd(() => {
        if (this.messages.length > 0) {
          this.isOpeningScrollPending = false
          this.isPinnedToBottom = true
        }
      })
      .onScrollIndex((first: number, last: number) => {
        this.selectedMessage = undefined
        this.firstVisibleIndex = first
        this.lastVisibleIndex = last
        const isAtBottom = this.messages.length > 0 && last >= this.messages.length - 1
        if (isAtBottom) this.isOpeningScrollPending = false
        this.isPinnedToBottom = isAtBottom
        this.ensureHistoryFillsViewport()
      })
      .onDidScroll(() => {
        if (this.selectedMessage !== undefined) this.selectedMessage = undefined
      })
      .onTouch((event: TouchEvent) => this.dismissKeyboard(event))
      if (this.messages.length === 0 && !this.isInitialLoading) {
        Column({ space: 10 }) {
          Image(RoomResources.image('roomkit_image_chat_empty'))
            .width(120)
            .height(96)
          Text(RoomResources.string('roomkit_room_chat_empty'))
            .fontSize(13)
            .fontColor($r('app.color.roomkit_fg_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onTouch((event: TouchEvent) => this.dismissKeyboard(event))
      }
      if (!this.isPinnedToBottom && this.messages.length > 0) {
        Button() {
          Image(RoomResources.image('roomkit_icon_collapse'))
            .width(14)
            .height(14)
        }
        .width(34)
        .height(34)
        .padding(8)
        .margin({ right: 16, bottom: 12 })
        .borderRadius(17)
        .backgroundColor($r('app.color.roomkit_bg_surface'))
        .border({ width: 1, color: $r('app.color.roomkit_border_strong') })
        .onClick(() => this.scrollToBottom(true))
      }
    }
    .width('100%')
    .layoutWeight(1)
    .onAreaChange((oldArea: Area, newArea: Area) => {
      const wasPinned = this.isPinnedToBottom || this.isOpeningScrollPending
      if (wasPinned && oldArea.height !== newArea.height) {
        this.schedule(() => this.scrollToBottom(false))
      }
    })
  }

  @Builder
  private imagePreviewContent() {
    if (this.previewImage !== undefined) {
      RoomChatImagePreviewView({ payload: this.previewImage as ImageMessagePayload })
    }
  }

  private actionTitles(message: MessageInfo): string[] {
    const titles: string[] = []
    if (message.messagePayload instanceof TextMessagePayload) {
      titles.push(RoomResources.string('roomkit_room_common_copy'))
    }
    if (message.isSentBySelf && (message.status === MessageStatus.SEND_FAIL ||
      message.status === MessageStatus.VIOLATION)) {
      titles.push(RoomResources.string('roomkit_room_chat_retry'))
    }
    if (message.isSentBySelf && message.status === MessageStatus.SEND_SUCCESS) {
      titles.push(RoomResources.string('roomkit_room_chat_recall'))
    }
    titles.push(RoomResources.string('roomkit_room_chat_delete'))
    return titles
  }

  private actionItemWidth(message: MessageInfo): number {
    const titles = this.actionTitles(message)
    const titleWidths = titles.map((title: string) => this.getUIContext().px2vp(measure.measureText({
      textContent: title,
      fontSize: 15,
      fontWeight: 400,
    })))
    return 38 + Math.ceil(Math.max(...titleWidths))
  }

  @Builder
  private actionContent(message: MessageInfo) {
    Row({ space: 0 }) {
      if (message.messagePayload instanceof TextMessagePayload) {
        Button() {
          Row({ space: 6 }) {
            Image(RoomResources.image('roomkit_icon_copy')).width(16).height(16)
              .fillColor($r('app.color.roomkit_fg_primary'))
            Text(RoomResources.string('roomkit_room_common_copy')).fontSize(15).maxLines(1)
              .fontColor($r('app.color.roomkit_fg_primary'))
          }
        }
        .width(this.actionItemWidth(message))
        .height(32)
        .padding({ left: 8, right: 8 })
        .stateStyles({
          normal: {
            .backgroundColor(Color.Transparent)
          },
          pressed: {
            .backgroundColor($r('app.color.roomkit_bg_press'))
          },
        })
        .onClick(() => {
          this.selectedMessage = undefined
          this.copyMessage(message)
        })
      }
      if (message.isSentBySelf && (message.status === MessageStatus.SEND_FAIL ||
        message.status === MessageStatus.VIOLATION)) {
        Button() {
          Row({ space: 6 }) {
            Image(RoomResources.image('roomkit_icon_retry')).width(16).height(16)
              .fillColor($r('app.color.roomkit_fg_primary'))
            Text(RoomResources.string('roomkit_room_chat_retry')).fontSize(15).maxLines(1)
              .fontColor($r('app.color.roomkit_fg_primary'))
          }
        }
        .width(this.actionItemWidth(message))
        .height(32)
        .padding({ left: 8, right: 8 })
        .stateStyles({
          normal: {
            .backgroundColor(Color.Transparent)
          },
          pressed: {
            .backgroundColor($r('app.color.roomkit_bg_press'))
          },
        })
        .onClick(() => {
          this.selectedMessage = undefined
          this.requestResend(message)
        })
      }
      if (message.isSentBySelf && message.status === MessageStatus.SEND_SUCCESS) {
        Button() {
          Row({ space: 6 }) {
            Image(RoomResources.image('roomkit_icon_recall')).width(16).height(16)
              .fillColor($r('app.color.roomkit_fg_primary'))
            Text(RoomResources.string('roomkit_room_chat_recall')).fontSize(15).maxLines(1)
              .fontColor($r('app.color.roomkit_fg_primary'))
          }
        }
        .width(this.actionItemWidth(message))
        .height(32)
        .padding({ left: 8, right: 8 })
        .stateStyles({
          normal: {
            .backgroundColor(Color.Transparent)
          },
          pressed: {
            .backgroundColor($r('app.color.roomkit_bg_press'))
          },
        })
        .onClick(() => {
          this.selectedMessage = undefined
          this.revokeMessage(message)
        })
      }
      Button() {
        Row({ space: 6 }) {
          Image(RoomResources.image('roomkit_icon_delete')).width(16).height(16)
            .fillColor($r('app.color.roomkit_danger'))
          Text(RoomResources.string('roomkit_room_chat_delete')).fontSize(15).maxLines(1)
            .fontColor($r('app.color.roomkit_danger'))
        }
      }
      .width(this.actionItemWidth(message))
        .height(32)
        .padding({ left: 8, right: 8 })
        .stateStyles({
          normal: {
            .backgroundColor(Color.Transparent)
          },
          pressed: {
            .backgroundColor($r('app.color.roomkit_bg_press'))
          },
        })
      .onClick(() => {
        this.selectedMessage = undefined
        this.deleteMessage(message)
      })
    }
  }

  build() {
    Stack() {
      Column() {
        Text(RoomResources.string('roomkit_room_chat_title'))
          .width('100%')
          .height(44)
          .margin({ top: 4 })
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .textAlign(TextAlign.Center)
        this.messageList()
        Column().width('100%').height(1).backgroundColor($r('app.color.roomkit_border'))
        RoomChatInputView({
          roomID: this.roomID,
          sendController: this.sendController,
          draft: $draft,
          reeditRevision: this.reeditRevision,
          onPickImage: () => this.presentImagePicker(),
          onLayoutChange: () => {
            if (this.isPinnedToBottom) {
              this.schedule(() => this.scrollToBottom(false))
            }
          },
        })
      }
      .width('100%')
      .height('100%')
      RoomDialog({
        isPresented: this.isImagePreviewPresented,
        title: RoomResources.string('roomkit_room_chat_image_preview'),
        closable: true,
        onDismiss: () => this.dismissImagePreview(),
        content: (): void => this.imagePreviewContent(),
      })
      RoomDialog({
        isPresented: this.isResendConfirmPresented,
        message: RoomResources.string('roomkit_room_chat_resend_confirm_message'),
        primaryText: RoomResources.string('roomkit_room_chat_retry'),
        secondaryText: RoomResources.string('roomkit_room_common_cancel'),
        onPrimary: () => {
          const message = this.resendMessage
          if (message !== undefined) {
            this.resend(message)
          }
        },
        onDismiss: () => {
          this.isResendConfirmPresented = false
          this.resendMessage = undefined
        },
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.roomkit_bg_surface'))
  }
}
