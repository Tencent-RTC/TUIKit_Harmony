import { MessageInfo, MessageLoadDirection } from '@tencentcloud/atomicxcore';
import { MessageInfoDataSource } from '../../adapter/MessageListAdapter';

const LOCATE_SCROLL_DELAY_MS: number = 200;
const HIGHLIGHT_DURATION_MS: number = 3000;
const SCROLL_TO_BOTTOM_GUARD_MS: number = 500;
const SCROLL_TO_BOTTOM_DELAY_MS: number = 100;

export interface MessageListLocateHost {
  getScroller(): Scroller;

  getDataSource(): MessageInfoDataSource;

  onHighlightChanged(messageID: string): void;

  loadMessagesAround(cursor: MessageInfo): void;

  clearLoadingAroundTargetMessage(reason: string): void;

  isLoadingAroundTargetMessage(): boolean;
}

export class MessageListLocateCoordinator {
  private host?: MessageListLocateHost;
  private firstVisibleIndex: number = -1;
  private lastVisibleIndex: number = -1;
  private lastScrollToBottomTime: number = 0;
  private highlightTimer?: number;
  private locateTimer?: number;
  private scrollToBottomTimer?: number;

  attach(host: MessageListLocateHost): void {
    this.host = host;
  }

  reset(): void {
    this.firstVisibleIndex = -1;
    this.lastVisibleIndex = -1;
    this.lastScrollToBottomTime = 0;
    this.cancelPendingTimers();
  }

  cancelPendingTimers(): void {
    if (this.highlightTimer !== undefined) {
      clearTimeout(this.highlightTimer);
      this.highlightTimer = undefined;
    }
    if (this.locateTimer !== undefined) {
      clearTimeout(this.locateTimer);
      this.locateTimer = undefined;
    }
    if (this.scrollToBottomTimer !== undefined) {
      clearTimeout(this.scrollToBottomTimer);
      this.scrollToBottomTimer = undefined;
    }
  }

  onScrollIndexChanged(firstIndex: number, lastIndex: number): void {
    this.firstVisibleIndex = firstIndex;
    this.lastVisibleIndex = lastIndex;
  }

  get firstIndex(): number {
    return this.firstVisibleIndex;
  }

  get lastIndex(): number {
    return this.lastVisibleIndex;
  }

  isIndexVisible(index: number): boolean {
    if (index < 0) {
      return false;
    }
    if (this.firstVisibleIndex < 0 || this.lastVisibleIndex < 0) {
      return false;
    }
    return index >= this.firstVisibleIndex && index <= this.lastVisibleIndex;
  }

  visibleItemCount(): number {
    if (this.firstVisibleIndex < 0 || this.lastVisibleIndex < 0) {
      return 0;
    }
    return Math.max(0, this.lastVisibleIndex - this.firstVisibleIndex + 1);
  }

  isLatestMessageVisible(): boolean {
    const count = this.host?.getDataSource().totalCount() ?? 0;
    if (count <= 0) {
      return true;
    }
    if (this.lastVisibleIndex < 0) {
      return true;
    }
    return this.lastVisibleIndex >= count - 1;
  }

  distanceFromLatestItems(): number {
    const count = this.host?.getDataSource().totalCount() ?? 0;
    if (count <= 0) {
      return 0;
    }
    if (this.lastVisibleIndex < 0) {
      return 0;
    }
    return Math.max(0, count - 1 - this.lastVisibleIndex);
  }

  getLatestMessage(): MessageInfo | undefined {
    const source = this.host?.getDataSource();
    const count = source?.totalCount() ?? 0;
    if (!source || count <= 0) {
      return undefined;
    }
    return source.getData(count - 1);
  }

  scrollToBottom(): void {
    this.lastScrollToBottomTime = Date.now();
    if (this.scrollToBottomTimer !== undefined) {
      clearTimeout(this.scrollToBottomTimer);
    }
    this.scrollToBottomTimer = setTimeout(() => {
      this.scrollToBottomTimer = undefined;
      this.host?.getScroller().scrollEdge(Edge.End);
    }, SCROLL_TO_BOTTOM_DELAY_MS);
  }

  anchorToLatest(): void {
    this.lastScrollToBottomTime = Date.now();
    this.host?.getScroller().scrollEdge(Edge.End);
  }

  isWithinScrollToBottomGuard(): boolean {
    return Date.now() - this.lastScrollToBottomTime < SCROLL_TO_BOTTOM_GUARD_MS;
  }

  locateToMessage(messageID: string, shouldHighlight: boolean = true): void {
    const host = this.host;
    if (!host || !messageID) {
      host?.clearLoadingAroundTargetMessage('invalid params');
      return;
    }

    const messageIndex = host.getDataSource().getIndex(messageID);
    if (messageIndex === -1) {
      console.warn(`[MessageListLocateCoordinator] Message not found: ${messageID}`);
      host.clearLoadingAroundTargetMessage('message not found');
      return;
    }

    host.onHighlightChanged(shouldHighlight ? messageID : '');

    if (this.locateTimer !== undefined) {
      clearTimeout(this.locateTimer);
    }
    this.locateTimer = setTimeout(() => {
      this.locateTimer = undefined;
      host.getScroller().scrollToIndex(messageIndex, true, ScrollAlign.CENTER);
      host.clearLoadingAroundTargetMessage('successful locate');

      if (shouldHighlight) {
        if (this.highlightTimer !== undefined) {
          clearTimeout(this.highlightTimer);
        }
        this.highlightTimer = setTimeout(() => {
          this.highlightTimer = undefined;
          host.onHighlightChanged('');
        }, HIGHLIGHT_DURATION_MS);
      }
    }, LOCATE_SCROLL_DELAY_MS);
  }

  locateToSequence(sequence: number): void {
    const host = this.host;
    if (!host) {
      return;
    }

    const index = this.findMessageIndexBySequence(sequence);
    if (index >= 0) {
      const message = host.getDataSource().getData(index);
      if (message) {
        this.locateToMessage(message.msgID);
      }
      return;
    }

    const cursor = new MessageInfo();
    cursor.sequence = sequence;
    host.loadMessagesAround(cursor);
  }

  findMessageIndexBySequence(sequence: number): number {
    const source = this.host?.getDataSource();
    if (!source) {
      return -1;
    }
    for (let i = 0; i < source.totalCount(); i++) {
      const message = source.getData(i);
      if (message && message.sequence === sequence) {
        return i;
      }
    }
    return -1;
  }

  restoreScrollPosition(direction: MessageLoadDirection, anchorScrollOffset: number,
    anchorMessageCount: number): boolean {
    const host = this.host;
    if (!host) {
      return false;
    }
    if (host.isLoadingAroundTargetMessage()) {
      return false;
    }
    if (anchorScrollOffset === -1) {
      return false;
    }

    const currentMessageCount = host.getDataSource().totalCount();
    const newMessagesCount = currentMessageCount - anchorMessageCount;

    if (newMessagesCount <= 0) {
      return true;
    }

    if (direction === MessageLoadDirection.OLDER) {
      host.getScroller().scrollToIndex(newMessagesCount, false, ScrollAlign.START);
    } else {
      const targetIndex = anchorMessageCount - 1;
      if (targetIndex >= 0 && targetIndex < currentMessageCount) {
        host.getScroller().scrollToIndex(targetIndex, false, ScrollAlign.END);
      }
    }
    return true;
  }
}
