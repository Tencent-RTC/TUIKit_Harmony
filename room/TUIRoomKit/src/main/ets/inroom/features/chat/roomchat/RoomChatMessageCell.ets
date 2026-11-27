import { fileIo } from '@kit.CoreFileKit'
import {
  ImageMessagePayload,
  MessageInfo,
  MessageSenderInfo,
  MessageStatus,
  TextMessagePayload,
} from '@tencentcloud/atomicxcore'
import { RoomParticipant } from '@tencentcloud/atomicxcore'
import { RoomAvatar } from '../../../../base/avatar/RoomAvatar'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomChatActionPopoverView } from './RoomChatActionPopoverView'

export function roomChatDisplayName(sender: MessageSenderInfo, participant?: RoomParticipant): string {
  const values: (string | undefined)[] = [
    participant?.nameCard,
    participant?.userName,
    sender.nameCard,
    sender.nickname,
    sender.friendRemark,
    sender.userID,
  ]
  return values.find((value: string | undefined) => value !== undefined && value.trim().length > 0) ?? ''
}

export function roomChatImageUri(path: string): string {
  if (path.startsWith('/')) {
    return `file://${path}`
  }
  return path
}

@Component
export struct RoomChatMessageCell {
  @Prop @Watch('resetImageSource') message: MessageInfo
  @State private imageSourceIndex: number = 0
  @Prop previousMessage: MessageInfo | undefined = undefined
  @Prop participant: RoomParticipant | undefined = undefined
  @Prop isActionPopoverPresented: boolean = false
  onRetry?: (message: MessageInfo) => void
  onLongPress?: (message: MessageInfo) => void
  onImageClick?: (payload: ImageMessagePayload) => void
  onActionPopoverDismiss?: () => void
  @BuilderParam actionPopover: () => void

  private isStacked(): boolean {
    const previous = this.previousMessage
    return previous !== undefined && previous.from.userID === this.message.from.userID &&
      previous.isSentBySelf === this.message.isSentBySelf && previous.status !== MessageStatus.REVOKED
  }

  private hasFailed(): boolean {
    return this.message.isSentBySelf &&
      (this.message.status === MessageStatus.SEND_FAIL || this.message.status === MessageStatus.VIOLATION)
  }

  private messageTime(): string {
    const date = new Date((this.message.timestamp ?? 0) * 1000)
    return `${date.getHours()}`.padStart(2, '0') + ':' + `${date.getMinutes()}`.padStart(2, '0')
  }

  private resetImageSource(): void {
    this.imageSourceIndex = 0
  }

  private isAccessible(path: string | undefined): boolean {
    if (path === undefined || path.length === 0) {
      return false
    }
    try {
      return fileIo.accessSync(path)
    } catch (error) {
      return false
    }
  }

  private imageCandidates(payload: ImageMessagePayload): string[] {
    const localPaths: (string | undefined)[] = [
      payload.thumbImagePath,
      payload.largeImagePath,
      payload.originalImagePath,
    ]
    const remoteURLs: (string | undefined)[] = [
      payload.thumbImageURL,
      payload.largeImageURL,
      payload.originalImageURL,
    ]
    const locals = localPaths.filter((path: string | undefined) => this.isAccessible(path)) as string[]
    const remotes = remoteURLs.filter((url: string | undefined) => url !== undefined && url.length > 0) as string[]
    return locals.concat(remotes)
  }

  private imageSource(payload: ImageMessagePayload): string {
    return roomChatImageUri(this.imageCandidates(payload)[this.imageSourceIndex] ?? '')
  }

  private showNextImage(payload: ImageMessagePayload): void {
    if (this.imageSourceIndex < this.imageCandidates(payload).length - 1) {
      this.imageSourceIndex++
    }
  }

  private isLongImage(payload: ImageMessagePayload): boolean {
    const width = Math.max(payload.originalImageWidth, 1)
    const height = Math.max(payload.originalImageHeight, 1)
    return width * 16 < height * 9
  }

  private imageWidth(payload: ImageMessagePayload): number {
    if (this.isLongImage(payload)) {
      return 84.375
    }
    const width = Math.max(payload.originalImageWidth, 1)
    const height = Math.max(payload.originalImageHeight, 1)
    return Math.max(Math.floor(width * Math.min(190 / width, 150 / height)), 1)
  }

  private imageHeight(payload: ImageMessagePayload): number {
    if (this.isLongImage(payload)) {
      return 150
    }
    const width = Math.max(payload.originalImageWidth, 1)
    const height = Math.max(payload.originalImageHeight, 1)
    return Math.max(Math.floor(height * Math.min(190 / width, 150 / height)), 1)
  }

  private imageObjectFit(payload: ImageMessagePayload): ImageFit {
    return this.isLongImage(payload) ? ImageFit.Cover : ImageFit.Contain
  }

  @Builder
  private avatar() {
    RoomAvatar({
      text: roomChatDisplayName(this.message.from, this.participant),
      url: this.participant?.avatarURL?.trim().length ? this.participant.avatarURL : this.message.from.avatarURL ?? '',
      avatarSize: 28,
    })
      .visibility(this.isStacked() ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  private payloadView() {
    if (this.message.messagePayload instanceof TextMessagePayload) {
      Text((this.message.messagePayload as TextMessagePayload).text)
        .fontSize(15)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .wordBreak(WordBreak.BREAK_ALL)
    } else if (this.message.messagePayload instanceof ImageMessagePayload) {
      Image(this.imageSource(this.message.messagePayload as ImageMessagePayload))
        .width(this.imageWidth(this.message.messagePayload as ImageMessagePayload))
        .height(this.imageHeight(this.message.messagePayload as ImageMessagePayload))
        .objectFit(this.imageObjectFit(this.message.messagePayload as ImageMessagePayload))
        .borderRadius(8)
        .onClick(() => {
          if (!this.isActionPopoverPresented) {
            this.onImageClick?.(this.message.messagePayload as ImageMessagePayload)
          }
        })
        .onError(() => this.showNextImage(this.message.messagePayload as ImageMessagePayload))
    }
  }

  @Builder
  private bubbleContent() {
    Column() {
      this.payloadView()
    }
    .backgroundColor(this.message.isSentBySelf ? $r('app.color.roomkit_chat_own_bubble') :
      $r('app.color.roomkit_chat_other_bubble'))
    .borderRadius(12)
    .clip(true)
  }

  @Builder
  private messageContent() {
    Column({ space: 2 }) {
      if (!this.isStacked()) {
        Row({ space: 8 }) {
          Text(roomChatDisplayName(this.message.from, this.participant))
            .fontSize(11)
            .fontColor($r('app.color.roomkit_fg_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 160 })
          Text(this.messageTime())
            .fontSize(11)
            .fontColor($r('app.color.roomkit_fg_tertiary'))
        }
      }
      RoomChatActionPopoverView({
        isPresented: this.isActionPopoverPresented,
        onClose: () => this.onActionPopoverDismiss?.(),
        anchor: (): void => this.bubbleContent(),
        content: (): void => this.actionPopover(),
      })
      if (this.message.status === MessageStatus.SENDING) {
        Text(RoomResources.string('roomkit_room_chat_sending'))
          .fontSize(11)
          .fontColor($r('app.color.roomkit_fg_tertiary'))
      }
    }
    .alignItems(this.message.isSentBySelf ? HorizontalAlign.End : HorizontalAlign.Start)
    .constraintSize({ maxWidth: '72%' })
  }

  build() {
    Row({ space: 8 }) {
      if (this.message.isSentBySelf) {
        Blank().layoutWeight(1)
        if (this.hasFailed()) {
          Button('!')
            .width(16)
            .height(16)
            .padding(0)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.roomkit_fg_on_danger'))
            .backgroundColor($r('app.color.roomkit_danger'))
            .borderRadius(8)
            .onClick(() => this.onRetry?.(this.message))
        }
        this.messageContent()
        this.avatar()
      } else {
        this.avatar()
        this.messageContent()
        Blank().layoutWeight(1)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .parallelGesture(LongPressGesture().onAction(() => this.onLongPress?.(this.message)))
  }
}

@Component
export struct RoomChatRevokedCell {
  @Prop message: MessageInfo
  @Prop participant: RoomParticipant | undefined = undefined
  @Prop fallbackText: string = ''
  onReedit?: (text: string) => void

  private originalText(): string {
    const payload = this.message.messagePayload
    const payloadText = payload instanceof TextMessagePayload ? payload.text : ''
    return payloadText.length > 0 ? payloadText : this.fallbackText
  }

  build() {
    Column({ space: 2 }) {
      Text(this.message.isSentBySelf ? RoomResources.string('roomkit_room_chat_you_recalled') :
        RoomResources.string('roomkit_room_chat_recalled', roomChatDisplayName(this.message.from, this.participant)))
        .fontSize(11)
        .fontColor($r('app.color.roomkit_fg_tertiary'))
        .textAlign(TextAlign.Center)
      if (this.message.isSentBySelf && this.originalText().length > 0) {
        Text(RoomResources.string('roomkit_room_chat_reedit'))
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.roomkit_accent'))
          .onClick(() => this.onReedit?.(this.originalText()))
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }
}
