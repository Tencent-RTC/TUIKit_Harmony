import {
  CustomMessagePayload,
  CustomSendMessagePayload,
  MessageInfo,
  MessageInputStore,
  MessageType,
  SendMessageOption
} from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../basecomponent/utils/CompletionHandlers';
import { AIConstants } from './AIConstants';

interface VoiceSessionPayload {
  action?: string;
}

export class AIAssistantControlMessages {
  static readonly VOICE_ENTER_ACTION: string = AIConstants.VOICE_ENTER_ACTION;
  static readonly VOICE_LEAVE_ACTION: string = AIConstants.VOICE_LEAVE_ACTION;
  static readonly VOICE_SESSION_DESCRIPTION: string = AIConstants.VOICE_SESSION_DESCRIPTION;

  static enterVoiceCall(conversationID: string): void {
    AIAssistantControlMessages.sendVoiceSession(conversationID, AIConstants.VOICE_ENTER_ACTION);
  }

  static leaveVoiceCall(conversationID: string): void {
    AIAssistantControlMessages.sendVoiceSession(conversationID, AIConstants.VOICE_LEAVE_ACTION);
  }

  static isControlMessage(message: MessageInfo): boolean {
    if (message.messageType !== MessageType.CUSTOM) {
      return false;
    }
    const payload = message.messagePayload as CustomMessagePayload | undefined;
    if (!payload) {
      return false;
    }
    return AIAssistantControlMessages.isControlPayload(payload.customData, payload.description);
  }

  static isControlPayload(customData?: string, description?: string): boolean {
    if (description?.trim() === AIConstants.VOICE_SESSION_DESCRIPTION) {
      return true;
    }
    if (!customData || customData.length === 0) {
      return false;
    }
    try {
      const parsed = JSON.parse(customData) as VoiceSessionPayload;
      const action = parsed?.action;
      return action === AIConstants.VOICE_ENTER_ACTION || action === AIConstants.VOICE_LEAVE_ACTION;
    } catch (e) {
      return false;
    }
  }

  private static sendVoiceSession(conversationID: string, action: string): void {
    const payload: VoiceSessionPayload = { action: action };
    const option = new SendMessageOption();
    option.onlineUserOnly = true;
    MessageInputStore.create(conversationID).sendMessage(
      new CustomSendMessagePayload(JSON.stringify(payload), AIConstants.VOICE_SESSION_DESCRIPTION),
      option,
      new CompletionHandlerAdapter()
    );
  }
}
