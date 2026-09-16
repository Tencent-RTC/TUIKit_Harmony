import { MessageInfo, CustomMessagePayload } from '@tencentcloud/atomicxcore';

export class MessageInfoDataSource implements IDataSource {
  private messages: MessageInfo[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.messages.length;
  }

  getData(index: number): MessageInfo {
    return this.messages[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  static canUpdateInPlace(previous: MessageInfo[], next: MessageInfo[]): boolean {
    if (previous.length !== next.length) {
      return false;
    }
    for (let i = 0; i < previous.length; i++) {
      if (previous[i].msgID !== next[i].msgID) {
        return false;
      }
    }
    return true;
  }

  setMessages(messages: MessageInfo[]): void {
    const previousMessages = this.messages;
    const previousByID: Map<string, MessageInfo> = new Map();
    previousMessages.forEach((message: MessageInfo) => {
      previousByID.set(message.msgID, message);
    });

    const changedIndexes: number[] = [];
    const nextMessages: MessageInfo[] = [];
    messages.forEach((source: MessageInfo, index: number) => {
      const target = previousByID.get(source.msgID);
      if (target && target !== source) {
        this.copyMessage(target, source);
        changedIndexes.push(index);
        nextMessages.push(target);
      } else {
        nextMessages.push(source);
      }
    });

    if (!MessageInfoDataSource.canUpdateInPlace(previousMessages, nextMessages)) {
      this.messages = nextMessages;
      this.listeners.forEach((listener: DataChangeListener) => listener.onDataReloaded());
      return;
    }

    this.messages = nextMessages;
    changedIndexes.forEach((index: number) => {
      this.listeners.forEach((listener: DataChangeListener) => listener.onDataChange(index));
    });
  }

  private copyMessage(target: MessageInfo, source: MessageInfo): void {
    target.msgID = source.msgID;
    target.status = source.status;
    target.timestamp = source.timestamp;
    target.sequence = source.sequence;
    target.from = source.from;
    target.to = source.to;
    target.isSentBySelf = source.isSentBySelf;
    target.conversationType = source.conversationType;
    target.messageType = source.messageType;
    this.copyMessagePayload(target, source);
    target.uploadMediaProgress = source.uploadMediaProgress;
    target.downloadMediaProgress = source.downloadMediaProgress;
    target.atUserList = source.atUserList;
    target.quoteInfo = source.quoteInfo;
    target.isPinned = source.isPinned;
    target.needReadReceipt = source.needReadReceipt;
    target.readReceiptInfo = source.readReceiptInfo;
    target.isExtensionEnabled = source.isExtensionEnabled;
    target.extensionList = source.extensionList;
    target.reactionList = source.reactionList;
    target.revokerInfo = source.revokerInfo;
    target.revokeReason = source.revokeReason;
    target.offlinePushInfo = source.offlinePushInfo;
    target.rawMessage = source.rawMessage;
  }

  private copyMessagePayload(target: MessageInfo, source: MessageInfo): void {
    const targetPayload = target.messagePayload;
    const sourcePayload = source.messagePayload;
    if (targetPayload instanceof CustomMessagePayload && sourcePayload instanceof CustomMessagePayload) {
      targetPayload.customData = sourcePayload.customData;
      targetPayload.description = sourcePayload.description;
      targetPayload.extensionInfo = sourcePayload.extensionInfo;
      return;
    }
    target.messagePayload = sourcePayload;
  }

  forceRefresh(index: number): void {
    if (index < 0 || index >= this.messages.length) {
      return;
    }
    this.listeners.forEach((listener: DataChangeListener) => listener.onDataChange(index));
  }

  getIndex(msgID: string): number {
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].msgID === msgID) {
        return i;
      }
    }
    return -1;
  }
}
