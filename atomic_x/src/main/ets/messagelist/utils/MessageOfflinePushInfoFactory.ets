import {
  ConversationInfo,
  LoginStore,
  MessageInfo,
  MessageType,
  OfflinePushInfo,
  TextMessagePayload
} from '@tencentcloud/atomicxcore';

const GROUP_CONVERSATION_PREFIX: string = 'group_';
const PUSH_DESCRIPTION_MAX_LENGTH: number = 50;

interface BusinessInfo {
  content: string;
  sender: string;
  nickname: string;
  chatType: number;
  faceUrl?: string;
}

interface ConfigInfo {
  fcmPushType: number;
  fcmNotificationType: number;
}

interface ExtJson {
  entity: BusinessInfo;
  timPushFeatures: ConfigInfo;
}

/**
 * Builds the OfflinePushInfo payload attached to messages that the message list
 * sends on the user's behalf (forwarding, ASR text, translated text).
 */
export class MessageOfflinePushInfoFactory {
  static create(conversationID: string, conversationTitle?: string): OfflinePushInfo {
    const loginUserInfo = LoginStore.shared().state.loginUserInfo;
    const selfUserId = loginUserInfo?.userID ?? '';
    const selfName = loginUserInfo?.nickname ?? selfUserId;

    const isGroup = conversationID.startsWith(GROUP_CONVERSATION_PREFIX);
    const groupId = isGroup ? conversationID.substring(GROUP_CONVERSATION_PREFIX.length) : '';

    const title = isGroup ? (conversationTitle || groupId) : selfName;
    const description = '';

    const ext = MessageOfflinePushInfoFactory.createExtJson(
      isGroup,
      description,
      isGroup ? groupId : selfUserId,
      title,
      loginUserInfo?.avatarURL
    );

    const pushInfo = new OfflinePushInfo();
    pushInfo.title = title;
    pushInfo.description = MessageOfflinePushInfoFactory.trimDescription(description);
    pushInfo.extensionInfo.set('ext', ext);
    pushInfo.extensionInfo.set('AndroidOPPOChannelID', 'tuikit');
    pushInfo.extensionInfo.set('AndroidHuaWeiCategory', 'IM');
    pushInfo.extensionInfo.set('AndroidVIVOCategory', 'IM');
    pushInfo.extensionInfo.set('AndroidHonorImportance', 'NORMAL');
    pushInfo.extensionInfo.set('AndroidMeizuNotifyType', 1);
    pushInfo.extensionInfo.set('iOSInterruptionLevel', 'time-sensitive');
    pushInfo.extensionInfo.set('enableIOSBackgroundNotification', false);

    return pushInfo;
  }

  static resolveConversationTitle(conversations: ConversationInfo[], conversationID: string): string | undefined {
    for (const conversation of conversations) {
      if (conversation.conversationID === conversationID && conversation.title) {
        return conversation.title;
      }
    }
    return undefined;
  }

  static getMessageTypeAbstract(message: MessageInfo): string {
    switch (message.messageType) {
      case MessageType.TEXT:
        return (message.messagePayload as TextMessagePayload | undefined)?.text ?? '';
      case MessageType.IMAGE:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_image').id);
      case MessageType.VIDEO:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_video').id);
      case MessageType.FILE:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_file').id);
      case MessageType.AUDIO:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_voice').id);
      case MessageType.FACE:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_animate_emoji').id);
      default:
        return '';
    }
  }

  static trimDescription(text: string, maxLength: number = PUSH_DESCRIPTION_MAX_LENGTH): string {
    if (typeof text !== 'string') {
      return '';
    }
    const normalized = text.trim().replace(/\n/g, ' ').replace(/\r/g, ' ');
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  private static createExtJson(isGroup: boolean, description: string, senderId: string,
    senderNickName: string, faceUrl?: string): string {
    const businessInfo: BusinessInfo = {
      content: description,
      sender: senderId,
      nickname: senderNickName,
      chatType: isGroup ? 2 : 1
    };

    if (faceUrl) {
      businessInfo.faceUrl = faceUrl;
    }

    const configInfo: ConfigInfo = {
      fcmPushType: 0,
      fcmNotificationType: 0
    };

    const extJson: ExtJson = {
      entity: businessInfo,
      timPushFeatures: configInfo
    };

    return JSON.stringify(extJson);
  }
}
