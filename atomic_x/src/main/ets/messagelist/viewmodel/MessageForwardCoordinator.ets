import { MergedForwardInfo, MessageInfo, MessageListStore, MessageForwardType,
  ForwardMessageOption, SendMessageOption, OfflinePushInfo } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { ChatbotForwardTargetPolicy, ChatbotForwardTargetPartition } from '../../chatbot/ChatbotForwardTargetPolicy';
import { TextUtils } from '../../basecomponent/Index';
import { MessageUtils } from '../utils/MessageUtils';

const GROUP_CONVERSATION_PREFIX: string = 'group_';
const MAX_ABSTRACT_COUNT: number = 4;
const MAX_TITLE_SENDER_COUNT: number = 2;

export interface MessageForwardFlowHost {
  getStore(): MessageListStore | undefined;

  getSelectedMessages(): MessageInfo[];

  getForwardType(): MessageForwardType;

  isMultiSelectMode(): boolean;

  clearTransientSelection(): void;

  exitMultiSelectMode(): void;

  createOfflinePushInfo(conversationID: string): OfflinePushInfo;

  showWarningToast(resource: Resource): void;

  showSuccessToast(resource: Resource): void;

  showInfoToast(resource: Resource): void;
}

export class MessageForwardFlow {
  private host?: MessageForwardFlowHost;

  attach(host: MessageForwardFlowHost): void {
    this.host = host;
  }

  forwardToConversations(conversationID: string, targetConversationIDs: string[]): void {
    const host = this.host;
    if (!host) {
      return;
    }
    const selectedMessages = host.getSelectedMessages();
    const partition: ChatbotForwardTargetPartition = ChatbotForwardTargetPolicy.partition(targetConversationIDs);
    if (partition.rejectedChatbotTargets.length > 0) {
      host.showWarningToast($r('app.string.message_list_chatbot_forward_not_supported'));
    }
    const allowedConversationIDs = partition.allowedTargets;
    if (selectedMessages.length === 0 || allowedConversationIDs.length === 0) {
      if (!host.isMultiSelectMode()) {
        host.clearTransientSelection();
      }
      return;
    }

    const forwardType = host.getForwardType();
    let successCount = 0;
    let failureCount = 0;
    const totalCount = allowedConversationIDs.length;

    const onComplete = () => {
      if (successCount + failureCount >= totalCount) {
        if (failureCount === 0) {
          host.showSuccessToast($r('app.string.forward_success'));
          if (host.isMultiSelectMode()) {
            host.exitMultiSelectMode();
          } else {
            host.clearTransientSelection();
          }
        } else {
          console.error(`[MessageForwardFlow] ${failureCount}/${totalCount} forwards failed`);
          host.showInfoToast($r('app.string.forward_failed'));
        }
      }
    };

    for (const targetConversationID of allowedConversationIDs) {
      const forwardOption = new ForwardMessageOption();
      forwardOption.forwardType = forwardType;
      if (forwardType === MessageForwardType.MERGED) {
        forwardOption.mergedForwardInfo = MessageForwardCoordinator.buildMergedForwardInfo(selectedMessages,
          conversationID);
      }
      const sendMessageOption = new SendMessageOption();
      sendMessageOption.needReadReceipt = AppBuilderConfig.getInstance().enableReadReceipt ?? false;
      sendMessageOption.offlinePushInfo = host.createOfflinePushInfo(targetConversationID);
      forwardOption.sendMessageOption = sendMessageOption;

      host.getStore()?.forwardMessages(selectedMessages, forwardOption, targetConversationID,
        new CompletionHandlerAdapter(() => {
          successCount++;
          onComplete();
        }, (code: number, desc: string) => {
          failureCount++;
          console.error(`[MessageForwardFlow] Forward to ${targetConversationID} failed:`, code, desc);
          onComplete();
        }));
    }
  }
}

/**
 * Builds the MergedForwardInfo (title / abstract lines / compatible text) used
 * when several messages are forwarded as a single merged bundle.
 * Mirrors the Android MessageForwardCoordinator merged-title logic.
 */
export class MessageForwardCoordinator {
  static buildMergedForwardInfo(messages: MessageInfo[], conversationID: string): MergedForwardInfo {
    const mergedInfo = new MergedForwardInfo();
    mergedInfo.title = MessageForwardCoordinator.buildMergedTitle(messages, conversationID);
    mergedInfo.abstractList = MessageForwardCoordinator.buildAbstractList(messages);
    mergedInfo.compatibleText = TextUtils.getResourceString($r('app.string.forward_compatible_text'));
    return mergedInfo;
  }

  private static buildAbstractList(messages: MessageInfo[]): string[] {
    const abstractList: string[] = [];
    const maxAbstractCount = Math.min(messages.length, MAX_ABSTRACT_COUNT);
    for (let index = 0; index < maxAbstractCount; index++) {
      const message = messages[index];
      const senderName: string = message.from?.nickname || message.from?.userID || '';
      const abstract = MessageUtils.getMessageAbstract(message);
      const abstractStr = typeof abstract === 'string' ? abstract : TextUtils.getResourceString(abstract);
      abstractList.push(`${senderName}: ${abstractStr}`);
    }
    return abstractList;
  }

  private static buildMergedTitle(messages: MessageInfo[], conversationID: string): string {
    if (conversationID.startsWith(GROUP_CONVERSATION_PREFIX)) {
      return TextUtils.getResourceString($r('app.string.forward_group_chat_history'));
    }

    const senderNames: string[] = [];
    const seenSenders: Set<string> = new Set();
    for (const message of messages) {
      const sender = message.from?.userID || '';
      if (sender && !seenSenders.has(sender)) {
        seenSenders.add(sender);
        senderNames.push(message.from?.nickname || sender);
      }
      if (senderNames.length >= MAX_TITLE_SENDER_COUNT) {
        break;
      }
    }

    const andText = TextUtils.getResourceString($r('app.string.forward_and_text'));
    const historySuffix = TextUtils.getResourceString($r('app.string.forward_chat_history_c2c'));

    if (senderNames.length === 2) {
      return `${senderNames[0]}${andText}${senderNames[1]}${historySuffix}`;
    }
    if (senderNames.length === 1) {
      return `${senderNames[0]}${historySuffix}`;
    }
    return TextUtils.getResourceString($r('app.string.forward_group_chat_history'));
  }
}
