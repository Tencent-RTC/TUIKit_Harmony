import { MessageInfo, MessageListStore, MessageStatus, MessageType } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../../basecomponent/utils/CompletionHandlers';

const RECEIPT_DEBOUNCE_MS: number = 1000;
const RECEIPT_REFRESH_INTERVAL_MS: number = 1000;

export interface MessageListReadReceiptHost {
  getMessages(): MessageInfo[] | undefined;

  shouldShowReadReceipt(message: MessageInfo): boolean;

  getMessageIndex(msgID: string): number;

  forceRefresh(index: number): void;
}

/**
 * Batches "message became visible" signals into debounced read-receipt reports.
 * Mirrors the Android MessageListReadReceiptController.
 */
export class MessageListReadReceiptController {
  private pendingMessageIDs: Set<string> = new Set();
  private sentMessageIDs: Set<string> = new Set();
  private debounceTimer?: number;
  private indicatorSnapshots: Map<string, string> = new Map();
  private refreshTimer?: number;
  private host?: MessageListReadReceiptHost;

  /**
   * Records a message that just became visible. Returns false when the message
   * is not eligible for a read receipt.
   */
  onMessageAppear(message: MessageInfo | undefined, enableReadReceipt: boolean): boolean {
    if (!enableReadReceipt) {
      return false;
    }
    if (!message || message.isSentBySelf) {
      return false;
    }
    if (!message.needReadReceipt) {
      return false;
    }
    if (message.status !== MessageStatus.SEND_SUCCESS) {
      return false;
    }
    if (message.messageType === MessageType.TIPS) {
      return false;
    }

    const messageID = message.msgID;
    if (!messageID) {
      return false;
    }
    if (this.sentMessageIDs.has(messageID) || this.pendingMessageIDs.has(messageID)) {
      return false;
    }

    this.pendingMessageIDs.add(messageID);
    return true;
  }

  scheduleFlush(store: MessageListStore | undefined, messages: MessageInfo[]): void {
    if (this.debounceTimer !== undefined) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(() => {
      this.flush(store, messages);
    }, RECEIPT_DEBOUNCE_MS);
  }

  flush(store: MessageListStore | undefined, messages: MessageInfo[]): void {
    this.debounceTimer = undefined;
    if (!store) {
      return;
    }

    const pendingIDs = Array.from(this.pendingMessageIDs);
    if (pendingIDs.length === 0) {
      return;
    }

    const targets: MessageInfo[] = [];
    const targetIDs: string[] = [];
    for (const id of pendingIDs) {
      const message = messages.find((item: MessageInfo) => item.msgID === id);
      if (message && message.rawMessage) {
        targets.push(message);
        targetIDs.push(id);
      }
    }

    if (targets.length === 0) {
      return;
    }

    const completion = new CompletionHandlerAdapter(() => {
      for (const id of targetIDs) {
        this.sentMessageIDs.add(id);
        this.pendingMessageIDs.delete(id);
      }
    }, (code: number, desc: string) => {
      console.error('[MessageListReadReceiptController] sendMessageReadReceipts failed:', code, desc);
    });
    store.sendMessageReadReceipts(targets, completion);
  }

  reset(): void {
    this.cancelPendingFlush();
    this.pendingMessageIDs.clear();
    this.sentMessageIDs.clear();
  }

  cancelPendingFlush(): void {
    if (this.debounceTimer !== undefined) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = undefined;
    }
  }

  attachHost(host: MessageListReadReceiptHost): void {
    this.host = host;
    this.stopAutoRefresh();
    this.refreshTimer = setInterval(() => {
      this.syncReadReceiptIndicators();
    }, RECEIPT_REFRESH_INTERVAL_MS);
  }

  detachHost(): void {
    this.stopAutoRefresh();
    this.indicatorSnapshots.clear();
    this.host = undefined;
  }

  syncReadReceiptIndicators(): void {
    this.scanIndicators(true);
  }

  markIndicatorsRendered(): void {
    this.scanIndicators(false);
  }

  private scanIndicators(refreshOnChange: boolean): void {
    const host = this.host;
    if (!host) {
      return;
    }
    const messages = host.getMessages();
    if (!messages) {
      return;
    }
    for (const message of messages) {
      const receipt = message.readReceiptInfo;
      if (!receipt || !host.shouldShowReadReceipt(message)) {
        continue;
      }
      const snapshot = MessageListReadReceiptController.buildIndicatorSnapshot(message);
      const previous = this.indicatorSnapshots.get(message.msgID);
      this.indicatorSnapshots.set(message.msgID, snapshot);
      if (!refreshOnChange || previous === undefined || previous === snapshot) {
        continue;
      }
      const index = host.getMessageIndex(message.msgID);
      if (index >= 0) {
        host.forceRefresh(index);
      }
    }
  }

  private stopAutoRefresh(): void {
    if (this.refreshTimer !== undefined) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = undefined;
    }
  }

  private static buildIndicatorSnapshot(message: MessageInfo): string {
    const receipt = message.readReceiptInfo;
    return `${message.status}#${receipt?.isPeerRead ?? false}#${receipt?.readCount ?? 0}#${receipt?.unreadCount ?? 0}`;
  }
}
