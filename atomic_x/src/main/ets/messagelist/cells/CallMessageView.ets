import { MessageInfo, MessageStatus, MessagePayload } from '@tencentcloud/atomicxcore';
import { ThemeState, LanguageState } from '../../basecomponent/Index';
import { AtomicCallEventPublisher } from '../../common/AtomicCallEventPublisher';
import { CallMessageClickContext, MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageRenderContext } from '../context/MessageRenderContext';
import {
  CallingMessageDataProvider,
  CallParticipantType,
  CallStreamMediaType,
  CallMessageDirection,
  CallProtocolType
} from '../utils/CallingMessageDataProvider';

@Component
export struct CallMessageSystemViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: MessagePayload;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    if (!this.shouldHide()) {
      Text(this.getCallText())
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorSecondary)
        .fontWeight(400)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        })
    }
  }

  private getCallText(): string {
    if (!this.message) {
      return '';
    }
    const callingProvider = new CallingMessageDataProvider(this.message);
    if (callingProvider.isCallingSignal && !callingProvider.excludeFromHistory) {
      return callingProvider.content;
    }
    return '';
  }

  private shouldHide(): boolean {
    if (!this.message) {
      return true;
    }
    const callingProvider = new CallingMessageDataProvider(this.message);
    if (!callingProvider.isCallingSignal) {
      return true;
    }
    if (callingProvider.excludeFromHistory) {
      return true;
    }
    if (callingProvider.participantType === CallParticipantType.unknown) {
      return true;
    }
    if (isIntermediateCallingSignal(callingProvider.protocolType)) {
      return true;
    }
    if (callingProvider.content.length === 0) {
      return true;
    }
    return false;
  }
}
@Component
export struct CallMessageBubbleViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: MessagePayload;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  config?: MessageListStyleProtocol = undefined;

  private getEffectiveIsSelf(): boolean {
    if (this.message) {
      const callingProvider = new CallingMessageDataProvider(this.message);
      if (callingProvider.isCallingSignal) {
        return callingProvider.direction === CallMessageDirection.outcoming;
      }
    }
    return this.message?.isSentBySelf ?? false;
  }

  build() {
    Row() {
      if (this.isIconAfterText()) {
        this.CallText()
        this.CallIcon(true)
      } else {
        this.CallIcon(false)
        this.CallText()
      }
    }
    .alignItems(VerticalAlign.Center)
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8
    })
    .onClick(() => {
      this.handleClick();
    })
  }

  private handleClick(): void {
    const listener = this.config?.callMessageClickListener;
    const message = this.message;
    if (!listener || !message) {
      return;
    }
    const callingProvider = new CallingMessageDataProvider(message);
    const mediaType = callingProvider.streamMediaType;
    if (mediaType !== CallStreamMediaType.audio && mediaType !== CallStreamMediaType.video) {
      return;
    }
    listener(new CallMessageClickContext(message, callingProvider, (targetUserId: string) => {
      AtomicCallEventPublisher.publishStartCall([targetUserId],
        mediaType === CallStreamMediaType.video ? AtomicCallEventPublisher.MEDIA_TYPE_VIDEO :
        AtomicCallEventPublisher.MEDIA_TYPE_AUDIO);
    }));
  }

  @Builder
  private CallText() {
    Text(this.getCallText())
      .fontSize(16)
      .fontColor(this.getContentColor())
      .fontWeight(FontWeight.Normal)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  private CallIcon(isAfterText: boolean) {
    if (this.hasCallIcon()) {
      Image(this.getCallIconResource())
        .width(22)
        .height(this.getCallIconHeight())
        .margin(isAfterText ? { left: 8 } : { right: 8 })
        .fillColor(this.getContentColor())
        .scale({ x: this.shouldMirrorCallIcon() ? -1 : 1, y: 1 })
    }
  }

  private getCallIconResource(): Resource {
    if (!this.message) {
      return $rawfile('messagelist/call_icon.svg');
    }
    const callingProvider = new CallingMessageDataProvider(this.message);
    if (callingProvider.streamMediaType === CallStreamMediaType.video) {
      return $rawfile('messagelist/video_icon.svg');
    }
    return $rawfile('messagelist/call_icon.svg');
  }

  private hasCallIcon(): boolean {
    if (!this.message) {
      return false;
    }
    const callingProvider = new CallingMessageDataProvider(this.message);
    return callingProvider.streamMediaType === CallStreamMediaType.audio ||
      callingProvider.streamMediaType === CallStreamMediaType.video;
  }

  private getCallIconHeight(): number {
    if (!this.message) {
      return 8;
    }
    const callingProvider = new CallingMessageDataProvider(this.message);
    return callingProvider.streamMediaType === CallStreamMediaType.video ? 15 : 8;
  }

  private getContentColor(): string {
    return this.getEffectiveIsSelf()
      ? this.themeState.colors.textColorAntiPrimary
      : this.themeState.colors.textColorPrimary;
  }

  private isIconAfterText(): boolean {
    const isRtl = this.languageState.getLayoutDirection() === LayoutDirection.RTL;
    return this.getEffectiveIsSelf() !== isRtl;
  }

  private shouldMirrorCallIcon(): boolean {
    const isRtl = this.languageState.getLayoutDirection() === LayoutDirection.RTL;
    return this.getEffectiveIsSelf() === isRtl;
  }

  private getCallText(): string {
    if (!this.message) {
      return '';
    }
    const callingProvider = new CallingMessageDataProvider(this.message);
    if (callingProvider.isCallingSignal && !callingProvider.excludeFromHistory) {
      return callingProvider.content;
    }
    return '';
  }
}

function isIntermediateCallingSignal(protocolType: CallProtocolType): boolean {
  return protocolType === CallProtocolType.accept ||
    protocolType === CallProtocolType.switchToAudio ||
    protocolType === CallProtocolType.switchToAudioConfirm;
}

export function shouldHideCallingMessage(message: MessageInfo): boolean {
  const callingProvider = new CallingMessageDataProvider(message);
  if (!callingProvider.isCallingSignal) {
    return false;
  }
  if (callingProvider.excludeFromHistory) {
    return true;
  }
  if (callingProvider.participantType === CallParticipantType.unknown) {
    return true;
  }
  if (isIntermediateCallingSignal(callingProvider.protocolType)) {
    return true;
  }
  if (callingProvider.content.length === 0) {
    return true;
  }
  return false;
}

@Builder
export function CallMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    CallMessageSystemViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload
    })
  }
}

@Builder
export function CallMessageBubbleView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    CallMessageBubbleViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload,
      config: context.config
    })
  }
}