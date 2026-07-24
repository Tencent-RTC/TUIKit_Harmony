import { MessageInfo, MessageStatus, MessagePayload } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
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
      this.CallIcon()
      Text(this.getCallText())
        .fontSize(15)
        .fontColor(this.getEffectiveIsSelf() ?
          this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Medium)
        .maxLines(999)
        .textOverflow({ overflow: TextOverflow.None })
    }
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8
    })
  }

  @Builder
  CallIcon() {
    Image(this.getCallIconResource())
      .width(16)
      .height(16)
      .margin({ right: 8 })
      .fillColor(this.getEffectiveIsSelf() ?
        this.themeState.colors.textColorAntiPrimary :
        this.themeState.colors.textColorSecondary)
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
      messagePayload: context.message.messagePayload
    })
  }
}