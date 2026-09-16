import { MessageInfo, MessageListStore, MessageListState, MessageLoadDirection,
  MessageLoadOption } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';

const PAGE_COUNT: number = 20;
const LOCATE_SCROLL_DELAY_MS: number = 100;

export class MessageListPagingState {
  isLoadingMore: boolean = false;
  loadDirection: MessageLoadDirection = MessageLoadDirection.OLDER;
  initialMessagesLoaded: boolean = false;

  constructor(isLoadingMore: boolean, loadDirection: MessageLoadDirection, initialMessagesLoaded: boolean) {
    this.isLoadingMore = isLoadingMore;
    this.loadDirection = loadDirection;
    this.initialMessagesLoaded = initialMessagesLoaded;
  }
}

export interface MessageListPagingHost {
  getStore(): MessageListStore | undefined;

  getState(): MessageListState | undefined;

  getDisplayedCount(): number;

  getLocateMessage(): MessageInfo | undefined;

  refreshDataSource(): void;

  locateToMessage(messageID: string): void;

  restoreScrollPosition(): void;

  onStateChanged(state: MessageListPagingState): void;

  onInitialLatestAnchorPending(): void;
}

export class MessageListPagingController {
  private host?: MessageListPagingHost;
  private isLoadingMore: boolean = false;
  private currentLoadDirection: MessageLoadDirection = MessageLoadDirection.OLDER;
  private initialMessagesLoaded: boolean = false;
  private loadingAroundTargetMessage: boolean = false;
  private scrollPositionBeforeLoad: number = -1;
  private messageCountBeforeLoad: number = 0;

  attach(host: MessageListPagingHost): void {
    this.host = host;
  }

  reset(): void {
    this.isLoadingMore = false;
    this.currentLoadDirection = MessageLoadDirection.OLDER;
    this.initialMessagesLoaded = false;
    this.loadingAroundTargetMessage = false;
    this.scrollPositionBeforeLoad = -1;
    this.messageCountBeforeLoad = 0;
    this.notifyStateChanged();
  }

  get isLoading(): boolean {
    return this.isLoadingMore;
  }

  get loadDirection(): MessageLoadDirection {
    return this.currentLoadDirection;
  }

  get hasLoadedInitialMessages(): boolean {
    return this.initialMessagesLoaded;
  }

  get isLoadingAroundTargetMessage(): boolean {
    return this.loadingAroundTargetMessage;
  }

  get anchorScrollOffset(): number {
    return this.scrollPositionBeforeLoad;
  }

  get anchorMessageCount(): number {
    return this.messageCountBeforeLoad;
  }

  clearLoadingAroundTargetMessage(reason: string): void {
    if (!this.loadingAroundTargetMessage) {
      return;
    }
    this.loadingAroundTargetMessage = false;
    console.info(`[MessageListPagingController] Reset isLoadingAroundTargetMessage = false (${reason})`);
  }

  clearAnchor(): void {
    this.scrollPositionBeforeLoad = -1;
    this.messageCountBeforeLoad = 0;
  }

  loadInitialMessages(): void {
    if (this.host?.getLocateMessage()) {
      this.loadMessagesAroundTargetMessage();
    } else {
      this.loadHistoryMessages();
    }
  }

  loadHistoryMessages(): void {
    const host = this.host;
    const store = host?.getStore();
    if (!host || !store) {
      return;
    }

    const option = new MessageLoadOption();
    option.direction = MessageLoadDirection.OLDER;
    option.pageCount = PAGE_COUNT;

    store.loadMessages(option, new CompletionHandlerAdapter(() => {
      host.refreshDataSource();
      const locateMessage = host.getLocateMessage();
      if (!locateMessage) {
        host.onInitialLatestAnchorPending();
      }
      this.markInitialLoaded();
      if (locateMessage?.msgID) {
        host.locateToMessage(locateMessage.msgID);
      }
    }, () => {
      this.markInitialLoaded();
    }));
  }

  loadMessagesAroundTargetMessage(): void {
    const host = this.host;
    const store = host?.getStore();
    if (!host || !store) {
      return;
    }

    const locateMessage = host.getLocateMessage();
    if (!locateMessage) {
      this.loadHistoryMessages();
      return;
    }

    this.loadingAroundTargetMessage = true;

    const option = new MessageLoadOption();
    option.cursor = locateMessage;
    option.direction = MessageLoadDirection.BOTH;
    option.pageCount = PAGE_COUNT;

    store.loadMessages(option, new CompletionHandlerAdapter(() => {
      host.refreshDataSource();
      this.markInitialLoaded();
      const targetMessageID = host.getLocateMessage()?.msgID;
      if (targetMessageID) {
        setTimeout(() => {
          host.locateToMessage(targetMessageID);
        }, LOCATE_SCROLL_DELAY_MS);
      } else {
        this.clearLoadingAroundTargetMessage('no locateMessage');
      }
    }, () => {
      this.clearLoadingAroundTargetMessage('error case');
      this.loadHistoryMessages();
    }));
  }

  loadMoreHistoryMessages(): void {
    this.loadMoreMessages(MessageLoadDirection.OLDER);
  }

  loadMoreNewerMessages(): void {
    this.loadMoreMessages(MessageLoadDirection.NEWER);
  }

  canLoadMore(direction: MessageLoadDirection): boolean {
    const host = this.host;
    const state = host?.getState();
    if (!host || !state || this.isLoadingMore || this.loadingAroundTargetMessage) {
      return false;
    }
    if (host.getDisplayedCount() <= 0) {
      return false;
    }
    return direction === MessageLoadDirection.OLDER ? state.hasOlderMessages : state.hasNewerMessages;
  }

  captureAnchor(direction: MessageLoadDirection, scrollOffset: number): void {
    const host = this.host;
    if (!host) {
      return;
    }
    this.messageCountBeforeLoad = host.getDisplayedCount();
    this.scrollPositionBeforeLoad = scrollOffset;
    this.currentLoadDirection = direction;
  }

  private loadMoreMessages(direction: MessageLoadDirection): void {
    const host = this.host;
    const store = host?.getStore();
    const state = host?.getState();
    const isOlder = direction === MessageLoadDirection.OLDER;

    if (!host || !store || !state || this.isLoadingMore) {
      return;
    }

    const hasMoreMessages = isOlder ? state.hasOlderMessages : state.hasNewerMessages;
    if (!hasMoreMessages) {
      return;
    }

    this.isLoadingMore = true;
    this.currentLoadDirection = direction;
    this.notifyStateChanged();

    const completion = new CompletionHandlerAdapter(() => {
      host.refreshDataSource();
      this.isLoadingMore = false;
      this.notifyStateChanged();
      host.restoreScrollPosition();
    }, () => {
      this.isLoadingMore = false;
      this.notifyStateChanged();
    });

    if (isOlder) {
      store.loadOlderMessages(completion);
    } else {
      store.loadNewerMessages(completion);
    }
  }

  private markInitialLoaded(): void {
    this.initialMessagesLoaded = true;
    this.notifyStateChanged();
  }

  private notifyStateChanged(): void {
    this.host?.onStateChanged(
      new MessageListPagingState(this.isLoadingMore, this.currentLoadDirection, this.initialMessagesLoaded));
  }
}
