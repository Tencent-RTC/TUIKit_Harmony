import { MessageInfo, MessageListStore, MessageStatus, MessageType } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../../basecomponent/utils/CompletionHandlers';

const RECEIPT_DEBOUNCE_MS: number = 1000;

/**
 * Batches "message became visible" signals into debounced read-receipt reports.
 * Mirrors the Android MessageListReadReceiptController.
 */
export class MessageListReadReceiptController {
  private pendingMessageIDs: Set<string> = new Set();
  private sentMessageIDs: Set<string> = new Set();
  private debounceTimer?: number;

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
}
