import { MessageInfo, MessageActionStore, MessageType, AudioMessagePayload } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';

export interface MessageListAsrHost {
  showInfoToast(resource: Resource): void;

  scrollToBottomIfLastMessage(message: MessageInfo): void;
}

export class MessageListAsrCoordinator {
  private host?: MessageListAsrHost;

  attach(host: MessageListAsrHost): void {
    this.host = host;
  }

  convertVoiceToText(message: MessageInfo, displayManager: AsrDisplayManager): void {
    if (!message || message.messageType !== MessageType.AUDIO) {
      return;
    }

    displayManager.setConverting(message.msgID, true);
    displayManager.expand(message.msgID);

    const messageActionStore = MessageActionStore.create(message);
    messageActionStore.convertVoiceToText('', new CompletionHandlerAdapter(() => {
      displayManager.setConverting(message.msgID, false);

      const audioPayload = message.messagePayload as AudioMessagePayload | undefined;
      const asrText = audioPayload?.asrText ?? '';
      if (asrText.length === 0) {
        this.host?.showInfoToast($r('app.string.messagelist_convert_to_text_failed'));
        displayManager.collapse(message.msgID);
      } else {
        this.host?.scrollToBottomIfLastMessage(message);
      }
    }, (code: number, desc: string) => {
      console.error(`[MessageListAsrCoordinator] voice to text failed:`, code, desc);
      displayManager.setConverting(message.msgID, false);
      displayManager.collapse(message.msgID);
      this.host?.showInfoToast($r('app.string.messagelist_convert_to_text_failed'));
    }));
  }
}
