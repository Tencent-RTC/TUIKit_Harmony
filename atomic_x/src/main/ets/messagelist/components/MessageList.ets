import { LoginStore } from '@tencentcloud/atomicxcore';
import { MessageListStore, MessageInfo, MessageType, MessageLoadDirection, MessageEvent, OnReceiveNewMessage, OnMessageReactionUpdated, OnMessageRevoked, OnMessageDeleted, MessageStatus, MessageListState, MessageForwardType, ForwardMessageOption, MergedForwardInfo, TextMessagePayload, AudioMessagePayload, CustomMessagePayload, TipsMessagePayload, OfflinePushInfo } from '@tencentcloud/atomicxcore';
import { MessageActionStore } from '@tencentcloud/atomicxcore';
import { ConversationListStore, ConversationListState, ConversationInfo, ConversationMarkType, ConversationType } from '@tencentcloud/atomicxcore';
import { MessageInputStore, TextSendMessagePayload, SendMessageOption } from '@tencentcloud/atomicxcore';
import { AlertDialog, AppBuilderConfig, ThemeState, TextUtils, ActionItem, Toast, EventBus, TUIEventBus, TUIObserver, NotifyParams } from '../../basecomponent/Index';
import { MessageItem } from '../ui/MessageItem';
import { MessageActionDialog } from '../ui/MessageActionPanel';
import { MessageQuoteEvent } from '../ui/MessageQuoteEvent';
import emitter from '@ohos.events.emitter';
import { MultiSelectBottomBar } from '../ui/MultiSelectBottomBar';
import { ForwardTargetSelector } from '../ui/ForwardTargetSelector';
import { ForwardTypeDialog } from '../ui/ForwardTypeDialog';
import { MessageReadReceiptDetailPage } from '../ui/MessageReadReceiptDetailPage';
import { MessageCheckBox } from '../ui/MessageCheckBox';
import { ReactionEmojiPickerSheet } from '../ui/ReactionEmojiPickerSheet';
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { TextMessageView } from '../cells/TextMessageView';
import { MessageAlignment } from '../../basecomponent/utils/AppBuilderHelper';
import { util } from '@kit.ArkTS';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { MessageItemDisplayPolicy } from '../adapter/MessageItemDisplayPolicy';
import { shouldHideCallingMessage } from '../cells/CallMessageView';
import { CallingMessageDataProvider, CallParticipantType } from '../utils/CallingMessageDataProvider';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { CompletionHandlerAdapter, GetConversationInfoCompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { MentionInfo } from '../../messageinput/components/MentionInfo';
import {
  MessageListFloatingEntry,
  MessageListFloatingEntryPolicy,
  MessageListFloatingEntryStateController,
  MessageListFloatingEntryType,
  MessageListMentionKind,
  MessageListMentionTarget,
  MessageListMentionTargetVisibility
} from '../ui/MessageListFloatingEntryPolicy';
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';
import pasteboard from '@ohos.pasteboard';
import { ChatBackgroundStore } from '../background/ChatBackgroundStore';
import { ListenFromHereController, ListenPlaybackState } from '../listen/ListenFromHereController';
import { buildListenPlan, ListenPlanResources, ListenItem } from '../listen/ListenFromHere';
import { ListenPlaybackBar } from '../listen/ListenPlaybackBar';
import { ChatbotMessageActionPolicy } from '../../chatbot/ChatbotMessageActionPolicy';
import { TypingMessageProtocol } from '../typing/TypingIndicatorController';
import { MessageListTimeGroupingPolicy } from '../viewmodel/MessageListTimeGroupingPolicy';
import { MessageOfflinePushInfoFactory } from '../utils/MessageOfflinePushInfoFactory';
import { MessageForwardCoordinator } from '../viewmodel/MessageForwardCoordinator';
import { MessageListReadReceiptController, MessageListReadReceiptHost } from '../ui/readreceipts/MessageListReadReceiptController';
import { MessageInfoDataSource } from '../adapter/MessageListAdapter';
import { MessageListPagingController, MessageListPagingHost,
  MessageListPagingState } from '../viewmodel/MessageListPagingController';
import { MessageListLocateCoordinator, MessageListLocateHost } from '../ui/layout/MessageListLocateCoordinator';
import { MessageListSelectionController, MessageListSelectionHost,
  MessageListSelectionState } from '../ui/selection/MessageListSelectionController';
import { MessageListStateWatcher } from '../ui/layout/MessageListStateWatcher';
import { MessageListTranslateCoordinator, MessageListTranslateHost } from '../viewmodel/MessageListTranslateCoordinator';
import { MessageListChatbotCoordinator, MessageListChatbotHost } from '../viewmodel/MessageListChatbotCoordinator';
import { MessageListAsrCoordinator, MessageListAsrHost } from '../viewmodel/MessageListAsrCoordinator';
import { MessageForwardFlow, MessageForwardFlowHost } from '../viewmodel/MessageForwardCoordinator';

function isGroupCallingMessage(message: MessageInfo): boolean {
  const callingProvider = new CallingMessageDataProvider(message);
  return callingProvider.isCallingSignal && callingProvider.participantType === CallParticipantType.group;
}

// Custom action interface for MessageList
export interface MessageCustomAction {
  title: string | Resource;
  iconName?: string | Resource;
  action: (message: MessageInfo) => void;
}

// Multi-select mode actions interface
export interface MultiSelectActions {
  cancel: () => void;
  deleteMessages: () => void;
  forwardSeparately: () => void;
  forwardMerged: () => void;
}

class PagingHostAdapter implements MessageListPagingHost {
  getStore: () => MessageListStore | undefined;
  getState: () => MessageListState | undefined;
  getDisplayedCount: () => number;
  getLocateMessage: () => MessageInfo | undefined;
  refreshDataSource: () => void;
  locateToMessage: (messageID: string) => void;
  restoreScrollPosition: () => void;
  onStateChanged: (state: MessageListPagingState) => void;
  onInitialLatestAnchorPending: () => void;

  constructor(getStore: () => MessageListStore | undefined, getState: () => MessageListState | undefined,
    getDisplayedCount: () => number, getLocateMessage: () => MessageInfo | undefined, refreshDataSource: () => void,
    locateToMessage: (messageID: string) => void, restoreScrollPosition: () => void,
    onStateChanged: (state: MessageListPagingState) => void, onInitialLatestAnchorPending: () => void) {
    this.getStore = getStore;
    this.getState = getState;
    this.getDisplayedCount = getDisplayedCount;
    this.getLocateMessage = getLocateMessage;
    this.refreshDataSource = refreshDataSource;
    this.locateToMessage = locateToMessage;
    this.restoreScrollPosition = restoreScrollPosition;
    this.onStateChanged = onStateChanged;
    this.onInitialLatestAnchorPending = onInitialLatestAnchorPending;
  }
}

class LocateHostAdapter implements MessageListLocateHost {
  getScroller: () => Scroller;
  getDataSource: () => MessageInfoDataSource;
  onHighlightChanged: (messageID: string) => void;
  loadMessagesAround: (cursor: MessageInfo) => void;
  clearLoadingAroundTargetMessage: (reason: string) => void;
  isLoadingAroundTargetMessage: () => boolean;

  constructor(getScroller: () => Scroller, getDataSource: () => MessageInfoDataSource,
    onHighlightChanged: (messageID: string) => void, loadMessagesAround: (cursor: MessageInfo) => void,
    clearLoadingAroundTargetMessage: (reason: string) => void, isLoadingAroundTargetMessage: () => boolean) {
    this.getScroller = getScroller;
    this.getDataSource = getDataSource;
    this.onHighlightChanged = onHighlightChanged;
    this.loadMessagesAround = loadMessagesAround;
    this.clearLoadingAroundTargetMessage = clearLoadingAroundTargetMessage;
    this.isLoadingAroundTargetMessage = isLoadingAroundTargetMessage;
  }
}

class SelectionHostAdapter implements MessageListSelectionHost {
  getState: () => MessageListState | undefined;
  onSelectionChanged: (state: MessageListSelectionState) => void;

  constructor(getState: () => MessageListState | undefined,
    onSelectionChanged: (state: MessageListSelectionState) => void) {
    this.getState = getState;
    this.onSelectionChanged = onSelectionChanged;
  }
}

class TranslateHostAdapter implements MessageListTranslateHost {
  findLatestMessage: (msgID: string) => MessageInfo | undefined;
  refreshDataSource: () => void;
  getMessageIndex: (msgID: string) => number;
  forceRefresh: (index: number) => void;
  scrollToBottomIfLastMessage: (message: MessageInfo) => void;
  showInfoToast: (resource: Resource) => void;

  constructor(findLatestMessage: (msgID: string) => MessageInfo | undefined,
    refreshDataSource: () => void, getMessageIndex: (msgID: string) => number,
    forceRefresh: (index: number) => void, scrollToBottomIfLastMessage: (message: MessageInfo) => void,
    showInfoToast: (resource: Resource) => void) {
    this.findLatestMessage = findLatestMessage;
    this.refreshDataSource = refreshDataSource;
    this.getMessageIndex = getMessageIndex;
    this.forceRefresh = forceRefresh;
    this.scrollToBottomIfLastMessage = scrollToBottomIfLastMessage;
    this.showInfoToast = showInfoToast;
  }
}

class ReadReceiptHostAdapter implements MessageListReadReceiptHost {
  getMessages: () => MessageInfo[] | undefined;
  shouldShowReadReceipt: (message: MessageInfo) => boolean;
  getMessageIndex: (msgID: string) => number;
  forceRefresh: (index: number) => void;

  constructor(getMessages: () => MessageInfo[] | undefined, shouldShowReadReceipt: (message: MessageInfo) => boolean,
    getMessageIndex: (msgID: string) => number, forceRefresh: (index: number) => void) {
    this.getMessages = getMessages;
    this.shouldShowReadReceipt = shouldShowReadReceipt;
    this.getMessageIndex = getMessageIndex;
    this.forceRefresh = forceRefresh;
  }
}

class ChatbotHostAdapter implements MessageListChatbotHost {
  getRawMessages: () => MessageInfo[] | undefined;
  getConversationInfo: (conversationID: string) => ConversationInfo | undefined;
  setDisplayMessages: (messages: MessageInfo[]) => void;
  refreshDataSource: () => void;
  onStreamContentUpdated: () => void;

  constructor(getRawMessages: () => MessageInfo[] | undefined,
    getConversationInfo: (conversationID: string) => ConversationInfo | undefined,
    setDisplayMessages: (messages: MessageInfo[]) => void, refreshDataSource: () => void,
    onStreamContentUpdated: () => void) {
    this.getRawMessages = getRawMessages;
    this.getConversationInfo = getConversationInfo;
    this.setDisplayMessages = setDisplayMessages;
    this.refreshDataSource = refreshDataSource;
    this.onStreamContentUpdated = onStreamContentUpdated;
  }
}

class AsrHostAdapter implements MessageListAsrHost {
  showInfoToast: (resource: Resource) => void;
  scrollToBottomIfLastMessage: (message: MessageInfo) => void;
  refreshMessages: () => void;

  constructor(showInfoToast: (resource: Resource) => void,
    scrollToBottomIfLastMessage: (message: MessageInfo) => void,
    refreshMessages: () => void) {
    this.showInfoToast = showInfoToast;
    this.scrollToBottomIfLastMessage = scrollToBottomIfLastMessage;
    this.refreshMessages = refreshMessages;
  }
}

class ForwardFlowHostAdapter implements MessageForwardFlowHost {
  getStore: () => MessageListStore | undefined;
  getSelectedMessages: () => MessageInfo[];
  getForwardType: () => MessageForwardType;
  isMultiSelectMode: () => boolean;
  clearTransientSelection: () => void;
  exitMultiSelectMode: () => void;
  createOfflinePushInfo: (conversationID: string) => OfflinePushInfo;
  showWarningToast: (resource: Resource) => void;
  showSuccessToast: (resource: Resource) => void;
  showInfoToast: (resource: Resource) => void;

  constructor(getStore: () => MessageListStore | undefined, getSelectedMessages: () => MessageInfo[],
    getForwardType: () => MessageForwardType, isMultiSelectMode: () => boolean,
    clearTransientSelection: () => void, exitMultiSelectMode: () => void,
    createOfflinePushInfo: (conversationID: string) => OfflinePushInfo,
    showWarningToast: (resource: Resource) => void, showSuccessToast: (resource: Resource) => void,
    showInfoToast: (resource: Resource) => void) {
    this.getStore = getStore;
    this.getSelectedMessages = getSelectedMessages;
    this.getForwardType = getForwardType;
    this.isMultiSelectMode = isMultiSelectMode;
    this.clearTransientSelection = clearTransientSelection;
    this.exitMultiSelectMode = exitMultiSelectMode;
    this.createOfflinePushInfo = createOfflinePushInfo;
    this.showWarningToast = showWarningToast;
    this.showSuccessToast = showSuccessToast;
    this.showInfoToast = showInfoToast;
  }
}

@Component
export struct MessageList {
  private static readonly MAX_SEPARATE_FORWARD_COUNT: number = 30;
  private static readonly GROUP_CONVERSATION_PREFIX: string = 'group_';
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State messageListStore?: MessageListStore = undefined;
  @State conversationListStore?: ConversationListStore = undefined;
  @State messageListState?: MessageListState = undefined;
  @State messageDataSource: MessageInfoDataSource = new MessageInfoDataSource();
  @State private initialMessagesLoaded: boolean = false;
  @State isLoadingMore: boolean = false;
  @State private loadingDirection: MessageLoadDirection = MessageLoadDirection.OLDER;
  @State userScrolling: boolean = false;
  @Watch('onSelectedMessageChanged')
  @State selectedMessage?: MessageInfo = undefined;
  // Multi-select mode states
  @State isMultiSelectMode: boolean = false;
  @State selectedMessageIDs: Set<string> = new Set();
  // Forward type selection state
  @State private forwardType: MessageForwardType = MessageForwardType.SEPARATE;
  dialogController: CustomDialogController | null = null;
  forwardDialogController: CustomDialogController | null = null;
  forwardTypeDialogController: CustomDialogController | null = null;
  readReceiptDialogController: CustomDialogController | null = null;
  emojiPickerController: CustomDialogController | null = null;
  conversationID: string = '';
  locateMessage?: MessageInfo = undefined;
  @State highlightedMessageID: string = '';
  scroller: Scroller = new Scroller();
  onMessageLongPress?: (message: MessageInfo) => void;
  onUserClick?: (userID: string) => void;
  onUserLongPress?: (userID: string, nickname: string) => void;
  onMultiSelectModeChange?: (isMultiSelectMode: boolean, selectedCount: number, actions?: MultiSelectActions) => void;
  customActions?: MessageCustomAction[] = [];
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop bottomContentInset: number = 0;
  private pagingController: MessageListPagingController = new MessageListPagingController();
  private locateCoordinator: MessageListLocateCoordinator = new MessageListLocateCoordinator();
  private selectionController: MessageListSelectionController = new MessageListSelectionController();
  private translateCoordinator: MessageListTranslateCoordinator = new MessageListTranslateCoordinator();
  private pendingInitialLatestAnchor: boolean = false;
  private floatingEntryStateController: MessageListFloatingEntryStateController = new MessageListFloatingEntryStateController();
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();
  @State private floatingEntry?: MessageListFloatingEntry = undefined;
  @State private chatBackgroundImageUri: string | null = null;
  private listenController: ListenFromHereController = new ListenFromHereController();
  @State private listenState: ListenPlaybackState = { isActive: false, isLoading: false, currentText: '' };
  private chatbotCoordinator: MessageListChatbotCoordinator = new MessageListChatbotCoordinator();
  private asrCoordinator: MessageListAsrCoordinator = new MessageListAsrCoordinator();
  private forwardFlow: MessageForwardFlow = new MessageForwardFlow();

  // ASR Display Manager for voice-to-text feature
  @State private asrDisplayManager: AsrDisplayManager = new AsrDisplayManager();
  
  // Translation Display Manager for text translation feature
  @State private translationDisplayManager: TranslationDisplayManager = new TranslationDisplayManager();

  private readReceiptController: MessageListReadReceiptController = new MessageListReadReceiptController();
  private chatHistoryClearedObserver?: TUIObserver;
  private static readonly EVENT_CHAT_HISTORY_CLEARED: string = 'chat.messageList.chatHistoryCleared';

  aboutToDisappear(): void {
    this.listenController.stop();
    this.locateCoordinator.cancelPendingTimers();
    this.detachChatbotController();
    this.readReceiptController.cancelPendingFlush();
    this.readReceiptController.detachHost();

    // Auxiliary text (ASR / Translation) state is session-only.
    // Clear here to ensure it does not leak across leaving/re-entering the message list.
    this.asrDisplayManager.clear();
    this.translationDisplayManager.clear();

    if (this.conversationID) {
      this.clearMessageUnreadCount();
    }

    this.floatingEntryStateController.reset();
    this.floatingEntry = undefined;

    EventBus.getInstance().off(MessageQuoteEvent.LOCATE_QUOTED_MESSAGE);
    EventBus.getInstance().off('onInputFocus');
    if (this.conversationID) {
      EventBus.getInstance().off(ChatBackgroundStore.eventName(this.conversationID));
    }
    if (this.chatHistoryClearedObserver) {
      TUIEventBus.getInstance().unsubscribe(MessageList.EVENT_CHAT_HISTORY_CLEARED, null, this.chatHistoryClearedObserver);
      this.chatHistoryClearedObserver = undefined;
    }
  }

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.attachControllers();
    console.info(`[MessageList] aboutToAppear with conversationID: ${this.conversationID}, locateMessage: ${this.locateMessage?.msgID ||
      'none'}`);
    
    if (this.conversationID) {
      this.chatBackgroundImageUri = ChatBackgroundStore.getImageUri(this.conversationID);
      this.attachChatbotControllerIfNeeded();
      this.loadMessages();
      this.clearMessageUnreadCount();
    } else {
      console.error('[MessageList] No valid conversationID provided');
    }

    EventBus.getInstance().on(MessageQuoteEvent.LOCATE_QUOTED_MESSAGE, (eventData: emitter.EventData) => {
      this.handleLocateQuotedMessage(eventData);
    });

    EventBus.getInstance().on('onInputFocus', (_eventData: emitter.EventData) => {
      this.scrollToBottom();
    });

    if (this.conversationID) {
      EventBus.getInstance().on(ChatBackgroundStore.eventName(this.conversationID), (_eventData: emitter.EventData) => {
        this.chatBackgroundImageUri = ChatBackgroundStore.getImageUri(this.conversationID);
      });
    }

    this.chatHistoryClearedObserver = new MessageListChatHistoryClearedObserver(this);
    TUIEventBus.getInstance().subscribe(MessageList.EVENT_CHAT_HISTORY_CLEARED, null, this.chatHistoryClearedObserver);
  }

  private attachControllers(): void {
    this.pagingController.attach(new PagingHostAdapter(
      (): MessageListStore | undefined => this.messageListStore,
      (): MessageListState | undefined => this.messageListState,
      (): number => this.messageDataSource.totalCount(),
      (): MessageInfo | undefined => this.locateMessage,
      (): void => this.refreshDataSource(),
      (messageID: string): void => this.locateToMessage(messageID),
      (): void => this.restoreScrollPosition(),
      (state: MessageListPagingState): void => {
        this.isLoadingMore = state.isLoadingMore;
        this.loadingDirection = state.loadDirection;
        this.initialMessagesLoaded = state.initialMessagesLoaded;
      },
      (): void => {
        this.pendingInitialLatestAnchor = true;
      }
    ));

    this.locateCoordinator.attach(new LocateHostAdapter(
      (): Scroller => this.scroller,
      (): MessageInfoDataSource => this.messageDataSource,
      (messageID: string): void => {
        this.highlightedMessageID = messageID;
      },
      (cursor: MessageInfo): void => {
        this.locateMessage = cursor;
        this.pagingController.loadMessagesAroundTargetMessage();
      },
      (reason: string): void => this.pagingController.clearLoadingAroundTargetMessage(reason),
      (): boolean => this.pagingController.isLoadingAroundTargetMessage
    ));

    this.selectionController.attach(new SelectionHostAdapter(
      (): MessageListState | undefined => this.messageListState,
      (state: MessageListSelectionState): void => {
        this.isMultiSelectMode = state.isMultiSelectMode;
        this.selectedMessageIDs = state.selectedMessageIDs;
        this.notifyMultiSelectModeChange();
      }
    ));

    this.translateCoordinator.attach(new TranslateHostAdapter(
      (msgID: string): MessageInfo | undefined =>
        this.messageListState?.messageList.find((item: MessageInfo): boolean => item.msgID === msgID),
      (): void => this.refreshDataSource(),
      (msgID: string): number => this.messageDataSource.getIndex(msgID),
      (index: number): void => this.messageDataSource.forceRefresh(index),
      (message: MessageInfo): void => this.scrollToBottomIfLastMessage(message),
      (resource: Resource): void => Toast.info(resource, this.getUIContext())
    ));

    this.chatbotCoordinator.attach(new ChatbotHostAdapter(
      (): MessageInfo[] | undefined => this.messageListState?.messageList,
      (conversationID: string): ConversationInfo | undefined => this.findConversationInfo(conversationID),
      (messages: MessageInfo[]): void => this.messageDataSource.setMessages(messages),
      (): void => this.refreshDataSource(),
      (): void => this.keepStreamAtBottom()
    ));

    this.asrCoordinator.attach(new AsrHostAdapter(
      (resource: Resource): void => Toast.info(resource, this.getUIContext()),
      (message: MessageInfo): void => this.scrollToBottomIfLastMessage(message),
      (): void => this.refreshDataSource()
    ));

    this.forwardFlow.attach(new ForwardFlowHostAdapter(
      (): MessageListStore | undefined => this.messageListStore,
      (): MessageInfo[] => this.getSelectedMessages(),
      (): MessageForwardType => this.forwardType,
      (): boolean => this.isMultiSelectMode,
      (): void => this.selectionController.clearTransientSelection(),
      (): void => this.exitMultiSelectMode(),
      (conversationID: string): OfflinePushInfo => this.createOfflinePushInfoForConversation(conversationID),
      (resource: Resource): void => Toast.warning(resource, this.getUIContext()),
      (resource: Resource): void => Toast.success(resource, this.getUIContext()),
      (resource: Resource): void => Toast.info(resource, this.getUIContext())
    ));

    this.readReceiptController.attachHost(new ReadReceiptHostAdapter(
      (): MessageInfo[] | undefined => this.messageListState?.messageList,
      (message: MessageInfo): boolean => MessageUtils.shouldShowReadReceipt(message,
        this.effectiveConfig.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt),
      (msgID: string): number => this.messageDataSource.getIndex(msgID),
      (index: number): void => this.messageDataSource.forceRefresh(index)
    ));
  }

  loadMessages() {
    this.pagingController.reset();
    this.locateCoordinator.reset();
    this.pendingInitialLatestAnchor = false;
    this.floatingEntryStateController.reset();
    this.floatingEntry = undefined;
    this.messageListStore = MessageListStore.create(this.conversationID);
    this.messageListState = this.messageListStore.state;
    this.refreshDataSource();

    this.messageListStore.messageEventFlow.subscribe(this, (event: MessageEvent) => {
      this.handleMessageEvent(event);
    });

    this.conversationListStore = ConversationListStore.create();
    this.requestInitialMentionEntry();

    this.pagingController.loadInitialMessages();
  }

  private refreshDataSource(): void {
    if (!this.messageListState) {
      return;
    }
    const filtered = this.messageListState.messageList.filter(
      (m: MessageInfo) => MessageUtils.shouldDisplayInMessageList(m)
    );
    this.chatbotCoordinator.activeController?.onMessagesChanged(filtered);
    this.messageDataSource.setMessages(this.chatbotCoordinator.buildDisplayMessages(this.conversationID, filtered));
    this.readReceiptController.markIndicatorsRendered();
  }

  onChatHistoryClearedNotification(conversationID: string): void {
    if (!conversationID || conversationID !== this.conversationID) {
      return;
    }
    console.info(`[MessageList] onChatHistoryClearedNotification. conversationID=${conversationID}`);
    this.refreshDataSource();
    this.floatingEntryStateController.reset();
    this.floatingEntry = this.floatingEntryStateController.currentEntry();
  }

  private rebuildChatbotDisplay(): void {
    this.chatbotCoordinator.rebuildChatbotDisplay(this.conversationID);
  }

  private findConversationInfo(conversationID: string): ConversationInfo | undefined {
    const dataSource = this.conversationListStore?.state.conversationList;
    if (!dataSource) {
      return undefined;
    }
    const total = dataSource.totalCount();
    for (let index = 0; index < total; index++) {
      const conversation = dataSource.getData(index);
      if (conversation && conversation.conversationID === conversationID) {
        return conversation;
      }
    }
    return undefined;
  }

  private refreshChatbotMessagesIfChanged(): void {
    this.chatbotCoordinator.refreshMessagesIfChanged(this.conversationID);
  }

  private keepStreamAtBottom(): void {
    if (this.isLatestMessageVisible()) {
      this.scrollToBottom();
    }
  }

  private attachChatbotControllerIfNeeded(): void {
    this.chatbotCoordinator.attachControllerIfNeeded(this.conversationID);
  }

  private detachChatbotController(): void {
    this.chatbotCoordinator.detachController(this.conversationID);
  }

  showMessageActionDialog(message: MessageInfo) {
    if (!message) {

      return;
    }

    this.selectedMessage = message;

    this.dialogController = new CustomDialogController({
      builder: MessageActionDialog({
        message: this.selectedMessage,
        messageListStore: this.messageListStore,
        customActions: this.customActions, // Pass customActions to MessageActionDialog
        config: this.effectiveConfig, // Pass style configuration
        asrDisplayManager: this.asrDisplayManager, // Pass ASR display manager
        translationDisplayManager: this.translationDisplayManager, // Pass Translation display manager
        onMessageDeleted: (msgId: string) => {
          this.handleMessageDeleted(msgId);
        },
        onMessageRecalled: (msgId: string) => {
          this.recallMessage(msgId);
        },
        onForward: (msg: MessageInfo) => {
          this.handleForwardSingleMessage(msg);
        },
        onMultiSelect: (msg: MessageInfo) => {
          this.enterMultiSelectMode(msg);
        },
        onMessageDetail: (msg: MessageInfo) => {
          this.showReadReceiptDetail(msg);
        },
        onEmojiReaction: (emoji: EmojiItem) => {
          this.handleEmojiReaction(emoji, this.selectedMessage!);
        },
        onShowFullEmojiPicker: () => {
          this.showFullEmojiPicker();
        },
        onConvertToText: (msg: MessageInfo) => {
          this.handleConvertVoiceToText(msg);
        },
        onListenFromHere: (msg: MessageInfo) => {
          this.handleListenFromHere(msg);
        },
        onTranslateText: (msg: MessageInfo) => {
          this.handleTranslateText(msg);
        },
        onQuote: (msg: MessageInfo) => {
          this.handleQuoteMessage(msg);
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.dialogController.open();
  }

  /**
   * Watch callback for selectedMessage changes
   * Auto-close dialog when message status becomes recalled or violation
   */
  private onSelectedMessageChanged(): void {
    if (this.selectedMessage && 
        (this.selectedMessage.status === MessageStatus.REVOKED || this.selectedMessage.status === MessageStatus.VIOLATION)) {
      if (this.dialogController) {
        this.dialogController.close();
        this.dialogController = null;
      }
      this.selectedMessage = undefined;
    }
  }

  clearMessageUnreadCount() {
    if (this.conversationID) {
      // Clear unread mark
      this.conversationListStore?.markConversation([this.conversationID], ConversationMarkType.unread, false);
      // Clear unread count
      this.conversationListStore?.clearConversationUnreadCount(this.conversationID);
    }
  }

  handleMessageDeleted(msgId: string) {
    AlertDialog.show(
      undefined,
      $r('app.string.messagelist_delete_confirm'),
      $r('app.string.cancel'),
      $r('app.string.confirm'),
      undefined,
      undefined,
      () => {
        this.performDeleteMessage(msgId);
      },
      this.getUIContext(),
      true
    );
  }

  private performDeleteMessage(msgId: string) {
    if (!this.messageListStore || !this.messageListState) {
      Toast.info($r('app.string.messagelist_delete_failed_invalid_state'), this.getUIContext());
      return;
    }

    try {
      const message = this.messageListState.messageList.find((m: MessageInfo) => m.msgID === msgId);
      if (message) {
        MessageActionStore.create(message).delete(new CompletionHandlerAdapter(() => {
          Toast.info($r('app.string.messagelist_message_deleted'), this.getUIContext());
        }, () => {
          Toast.info($r('app.string.messagelist_delete_message_failed'), this.getUIContext());
        }));
      } else {
        Toast.info($r('app.string.messagelist_delete_failed_not_found'), this.getUIContext());
      }
    } catch (error) {
      Toast.info($r('app.string.messagelist_delete_message_failed'), this.getUIContext());
    }
  }

  recallMessage(msgId: string) {
    if (!this.messageListState) {
      Toast.info($r('app.string.messagelist_recall_failed_invalid_state'), this.getUIContext());
      return;
    }
    try {
      const message = this.messageListState.messageList.find((m: MessageInfo) => m.msgID === msgId);
      if (message) {
        if (!message.isSentBySelf) {
          Toast.info($r('app.string.messagelist_recall_only_own'), this.getUIContext());
          return;
        }
        MessageActionStore.create(message).revoke(new CompletionHandlerAdapter(() => {
          this.refreshDataSource();
          Toast.info($r('app.string.message_tips_normal_recall'), this.getUIContext());
        }, () => {
          Toast.info($r('app.string.messagelist_recall_failed'), this.getUIContext());
        }));
      } else {
        Toast.info($r('app.string.messagelist_recall_failed_not_found'), this.getUIContext());
      }
    } catch (error) {
      Toast.info($r('app.string.messagelist_recall_failed'), this.getUIContext());
    }
  }

  loadMoreHistoryMessages() {
    this.pagingController.loadMoreHistoryMessages();
  }

  loadMoreNewerMessages() {
    this.pagingController.loadMoreNewerMessages();
  }

  @Builder
  MessageItemBuilder(message: MessageInfo, index: number) {
    this.NormalMessageItemBuilder(message, index);
  }

  @Builder
  NormalMessageItemBuilder(message: MessageInfo, index: number) {
    Column() {
      if (this.shouldRenderMessageRow(message) &&
        message.messageType !== MessageType.TIPS &&
        !isGroupCallingMessage(message) &&
        !MessageItemDisplayPolicy.isGroupCreatedMessage(message) &&
        this.effectiveConfig.isShowTimeMessage && this.getMessageTimeString(index)) {
        Row() {
          Text(this.getMessageTimeString(index))
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorSecondary)
            .padding({
              left: 8,
              right: 8,
              top: 2,
              bottom: 2
            })
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8, top: 8 })
      }
      
      Row() {
        // Checkbox for multi-select mode (only show for selectable messages)
        if (this.isMultiSelectMode && this.canSelectMessage(message)) {
          MessageCheckBox({
            isSelected: this.selectedMessageIDs.has(message.msgID),
            isEnabled: true,
            onTap: () => {
              this.toggleMessageSelection(message);
            }
          })
            .margin({ right: 12 })
        }
        
        MessageItem({
          message: message,
          initialShowAvatar: this.shouldShowAvatar(message, index),
          isHighlighted: this.highlightedMessageID === message.msgID,
          config: this.effectiveConfig,
          isMultiSelectMode: this.isMultiSelectMode,
          onLongPress: (message: MessageInfo) => {
            if (!this.isMultiSelectMode) {
              this.showMessageActionDialog(message);
              if (this.onMessageLongPress) {
                this.onMessageLongPress(message);
              }
            }
          },
          onUserClick: (userID: string) => {
            if (this.onUserClick) {
              this.onUserClick(userID);
            }
          },
          onUserLongPress: (userID: string, nickname: string) => {
            // Post event via EventBus (Android style)
            console.log(`[MessageList] 📤 Posting onUserLongPress event: userID=${userID}, nickname=${nickname}`);
            
            const eventData: Record<string, Object> = {};
            eventData['source'] = 'MessageList';
            eventData['event'] = 'onUserLongPress';
            eventData['userID'] = userID;
            eventData['nickname'] = nickname;
            
            EventBus.getInstance().post('onUserLongPress', eventData);
            
            // Also call the callback if provided (backward compatibility)
            if (this.onUserLongPress) {
              this.onUserLongPress(userID, nickname);
            }
          },
          messageListStore: this.messageListStore,
          asrDisplayManager: this.asrDisplayManager,
          translationDisplayManager: this.translationDisplayManager,
          customActions: this.customActions,
          onAsrBubbleLongPress: (message: MessageInfo) => {
            const audioPayload = message.messagePayload as AudioMessagePayload | undefined;
            const asrText = audioPayload?.asrText ?? '';
            if (asrText.length > 0) {
              this.forwardAsrText(asrText);
            }
          },
          onTranslationBubbleLongPress: (message: MessageInfo) => {
            const translatedText = this.getTranslatedText(message);
            if (translatedText.length > 0) {
              this.forwardTranslatedText(translatedText);
            }
          },
          // Classic popup style callbacks
          onCopy: (msg: MessageInfo) => {
            this.handlePopupCopy(msg);
          },
          onRecall: (msg: MessageInfo) => {
            this.recallMessage(msg.msgID);
          },
          onDelete: (msg: MessageInfo) => {
            this.handleMessageDeleted(msg.msgID);
          },
          onForward: (msg: MessageInfo) => {
            this.handleForwardSingleMessage(msg);
          },
          onMultiSelect: (msg: MessageInfo) => {
            this.enterMultiSelectMode(msg);
          },
          onDetail: (msg: MessageInfo) => {
            this.showReadReceiptDetail(msg);
          },
          onConvertToText: (msg: MessageInfo) => {
            this.handleConvertVoiceToText(msg);
          },
          onListenFromHere: (msg: MessageInfo) => {
            this.handleListenFromHere(msg);
          },
          onTranslate: (msg: MessageInfo) => {
            this.handleTranslateText(msg);
          },
          onQuote: (msg: MessageInfo) => {
            this.handleQuoteMessage(msg);
          },
          onEmojiReaction: (emoji: EmojiItem, msg: MessageInfo) => {
            this.handleEmojiReaction(emoji, msg);
          },
          onExpandEmojiPicker: (msg: MessageInfo) => {
            this.selectedMessage = msg;
            this.showFullEmojiPicker();
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        // Handle click for multi-select mode at the Row level
        if (this.isMultiSelectMode && this.canSelectMessage(message)) {
          this.toggleMessageSelection(message);
        }
      })
    }
    .padding({
      top: this.shouldRenderMessageRow(message)
        ? this.getMessageVerticalSpacing(this.checkPreviousMessageIsAggregation(index)) : 0,
      bottom: this.shouldRenderMessageRow(message)
        ? this.getMessageVerticalSpacing(this.checkNextMessageIsAggregation(index)) : 0
    })
  }

  private getMessageVerticalSpacing(isAggregated: boolean): number {
    const baseSpacing = this.effectiveConfig.cellSpacing ?? 2;
    return isAggregated ? baseSpacing : baseSpacing * 5;
  }

  private shouldRenderMessageRow(message: MessageInfo): boolean {
    if (message.messageType === MessageType.TIPS) {
      return this.shouldRenderTipsRow(message);
    }
    if (shouldHideCallingMessage(message)) {
      return false;
    }
    const isCentered = message.messageType === MessageType.CUSTOM &&
      !MessageItemDisplayPolicy.isCallingC2C(message) &&
      !MessageItemDisplayPolicy.isBusinessCustomMessage(message);
    if (!isCentered) {
      return true;
    }
    return !MessageItemDisplayPolicy.shouldHideMessageEntirely(message);
  }

  private shouldRenderTipsRow(message: MessageInfo): boolean {
    if (this.effectiveConfig.isShowSystemMessage !== true) {
      return false;
    }
    if (message.status === MessageStatus.REVOKED) {
      return true;
    }
    if (message.messagePayload === undefined) {
      return false;
    }
    const tips = (message.messagePayload as TipsMessagePayload).groupTips;
    if (tips === undefined || tips.length === 0) {
      return true;
    }
    return MessageUtils.getSystemInfoDisplayString(tips[0]) !== '';
  }

  private getMessageKey(message: MessageInfo, index: number): string {
    return `${message.msgID}_${MessageUtils.getMessageStateHash(message)}_${index}`;
  }

  private shouldShowAvatar(message: MessageInfo, index: number): boolean {
    return true;
  }

  build() {
    Stack() {
      if (this.chatBackgroundImageUri) {
        Image(this.chatBackgroundImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover);
      }

      Column() {
        this.NormalListBuilder()
      }
      .width('100%')
      .height('100%');

      if (this.messageListState) {
        MessageListStateWatcher({
          messageListState: this.messageListState,
          onMessageListChanged: (): void => {
            this.refreshChatbotMessagesIfChanged();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * Get the MultiSelectBottomBar builder for parent component to display
   * This allows the bottom bar to replace the InputBar in the parent layout
   */
  @Builder
  MultiSelectBottomBarBuilder() {
    if (this.isMultiSelectMode) {
      MultiSelectBottomBar({
        selectedCount: this.selectedMessageIDs.size,
        onDelete: () => {
          this.confirmDeleteSelectedMessages();
        },
        onSeparateForward: () => {
          this.forwardSelectedMessages(MessageForwardType.SEPARATE);
        },
        onMergedForward: () => {
          this.forwardSelectedMessages(MessageForwardType.MERGED);
        }
      })
    }
  }

  /**
   * Check if currently in multi-select mode
   */
  getIsMultiSelectMode(): boolean {
    return this.isMultiSelectMode;
  }

  @Builder
  NormalListBuilder() {
    if (this.messageListStore && this.messageListState && this.initialMessagesLoaded) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {

        if (this.isLoadingMore && this.loadingDirection === MessageLoadDirection.OLDER) {
          Row() {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(this.themeState.colors.textColorPrimary)

            Text($r('app.string.messagelist_loading_history'))
              .fontSize(12)
              .fontColor(this.themeState.colors.textColorSecondary)
              .margin({ left: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })
        }

        List({
          space: 0,
          scroller: this.scroller,
          initialIndex: (this.messageDataSource.totalCount() ?? 1) - 1
        }) {
          LazyForEach(this.messageDataSource, (message: MessageInfo, index: number) => {
            ListItem() {
              this.MessageItemBuilder(message, index)
            }
            .onAppear(() => {
              this.handleMessageAppear(message);
            })
            .visibility(this.shouldRenderMessageRow(message) ? Visibility.Visible : Visibility.None)
          }, (message: MessageInfo, index: number) => this.getMessageKey(message, index))
        }
        .padding({
          left: this.effectiveConfig.horizontalPadding,
          right: this.effectiveConfig.horizontalPadding,
          bottom: this.bottomContentInset
        })
        .width('100%')
        .layoutWeight(1)
        .onAreaChange((_old: Area, area: Area): void => {
          if (this.pendingInitialLatestAnchor && Number(area.height) > 0) {
            this.pendingInitialLatestAnchor = false;
            this.locateCoordinator.anchorToLatest();
          }
        })
        .onReachStart(() => {
          console.info('[MessageList] Reached start of list');

          if (this.pagingController.canLoadMore(MessageLoadDirection.OLDER)) {
            this.pagingController.captureAnchor(MessageLoadDirection.OLDER,
              this.scroller.currentOffset().yOffset);
            this.loadMoreHistoryMessages();
          } else {
            console.info('[MessageList] Cannot load more messages:', {
              hasOlderMessages: this.messageListState?.hasOlderMessages,
              isLoadingMore: this.isLoadingMore,
              messageCount: this.messageDataSource.totalCount()
            });
          }
        })
        .onReachEnd(() => {
          console.info('[MessageList] Reached end of list');

          if (this.locateCoordinator.isWithinScrollToBottomGuard()) {
            console.info('[MessageList] Skip loading on onReachEnd - just scrolled to bottom');
            return;
          }

          if (this.pagingController.canLoadMore(MessageLoadDirection.NEWER)) {
            this.pagingController.captureAnchor(MessageLoadDirection.NEWER,
              this.scroller.currentOffset().yOffset);
            this.loadMoreNewerMessages();
          } else {
            console.info('[MessageList] Cannot load more newer messages from onReachEnd:', {
              hasNewerMessages: this.messageListState?.hasNewerMessages,
              isLoadingMore: this.isLoadingMore,
              messageCount: this.messageDataSource.totalCount()
            });
          }
        })
        .onScrollIndex((firstIndex: number, lastIndex: number, _centerIndex: number) => {
          console.info(`[MessageList] Scroll index changed: first=${firstIndex}, last=${lastIndex}, prevFirst=${this.locateCoordinator.firstIndex}, userScrolling: ${this.userScrolling}`);

          this.locateCoordinator.onScrollIndexChanged(firstIndex, lastIndex);
          this.updateFloatingEntryForScroll();
        })
        .onScrollStart(() => {

          this.userScrolling = true;
          const scrollEventData: Record<string, Object> = {};
          scrollEventData['source'] = 'MessageList';
          scrollEventData['event'] = 'onBlankAreaClick';
          scrollEventData['reason'] = 'scrollStart';
          EventBus.getInstance().post('onBlankAreaClick', scrollEventData);
        })
        .onScrollStop(() => {

          setTimeout(() => {
            this.userScrolling = false;
            console.info('[MessageList] User scroll stopped');
          }, 200);
        })
        .onClick(() => {
          console.log('[MessageList] 📤 Posting onBlankAreaClick event');
          const eventData: Record<string, Object> = {};
          eventData['source'] = 'MessageList';
          eventData['event'] = 'onBlankAreaClick';
          EventBus.getInstance().post('onBlankAreaClick', eventData);
        })


        if (this.isLoadingMore && this.loadingDirection === MessageLoadDirection.NEWER) {
          Row() {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(this.themeState.colors.textColorPrimary)

            Text($r('app.string.messagelist_loading_new'))
              .fontSize(12)
              .fontColor(this.themeState.colors.textColorSecondary)
              .margin({ left: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })
        }
      }
      .width('100%')
      .layoutWeight(1)

      if (this.floatingEntry) {
        this.FloatingEntryBuilder()
      }

      if (this.listenState.isActive) {
        Column() {
          ListenPlaybackBar({
            isLoading: this.listenState.isLoading,
            currentText: this.listenState.currentText,
            onClose: () => {
              this.listenController.stop();
            }
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .padding({ top: 12 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%')
    .layoutWeight(1)
    }
  }

  @Builder
  private FloatingEntryBuilder() {
    Row({ space: 6 }) {
      Image($rawfile('messagelist/floating_entry_arrow.svg'))
        .width(12)
        .height(11)
        .fillColor(this.themeState.colors.textColorLink)
        .rotate({
          angle: this.floatingEntry?.type === MessageListFloatingEntryType.MENTION ? 180 : 0
        })
        .draggable(false)

      Text(this.floatingEntryText())
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorLink)
        .maxLines(1)
    }
    .height(35)
    .constraintSize({ minWidth: 94 })
    .padding({ left: 10, right: 10 })
    .backgroundColor(this.themeState.colors.floatingColorDefault)
    .borderRadius(7)
    .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 2 })
    .margin({ right: 16, bottom: 16 })
    .onClick(() => {
      this.handleCurrentFloatingEntryClick();
    })
  }

  private floatingEntryText(): string | Resource {
    return this.floatingEntry ? this.getFloatingEntryText(this.floatingEntry) : '';
  }

  private handleCurrentFloatingEntryClick(): void {
    if (this.floatingEntry) {
      this.handleFloatingEntryClick(this.floatingEntry);
    }
  }

  scrollToBottom() {
    this.locateCoordinator.scrollToBottom();
  }

  private handleQuoteMessage(message: MessageInfo) {
    EventBus.getInstance().post(MessageQuoteEvent.QUOTE_MESSAGE, {
      'conversationID': this.conversationID,
      'message': message
    });
  }

  private handleLocateQuotedMessage(eventData: emitter.EventData) {
    if (!this.messageListState) {
      return;
    }
    const data = eventData.data as Record<string, Object> | undefined;
    if (!data) {
      return;
    }
    const msgID = data['msgID'] as string | undefined;
    const sequence = data['sequence'] as number | undefined;
    const timestamp = data['timestamp'] as number | undefined;
    const returnMsgID = data['returnMsgID'] as string | undefined;
    if (returnMsgID && returnMsgID.length > 0) {
      this.floatingEntryStateController.onQuoteNavigated(returnMsgID);
      this.refreshFloatingEntry();
    }
    if (!msgID && (!sequence || sequence <= 0)) {
      return;
    }
    const messages = this.messageListState.messageList;
    let target: string | undefined = undefined;
    if (msgID && msgID.length > 0) {
      const found = messages.find((m: MessageInfo): boolean => m.msgID === msgID);
      if (found) {
        target = found.msgID;
      }
    }
    if (!target && sequence && sequence > 0) {
      const found = messages.find((m: MessageInfo): boolean => m.sequence === sequence);
      if (found && found.msgID && found.msgID.length > 0) {
        target = found.msgID;
      }
    }
    if (target) {
      this.locateToMessage(target);
      return;
    }
    if (sequence && sequence > 0) {
      const cursor = new MessageInfo();
      cursor.msgID = msgID ?? '';
      cursor.sequence = sequence;
      cursor.timestamp = timestamp ?? 0;
      this.locateMessage = cursor;
      this.pagingController.loadMessagesAroundTargetMessage();
    }
  }

  locateToMessage(messageID: string, shouldHighlight: boolean = true) {
    if (!this.messageListState) {
      this.pagingController.clearLoadingAroundTargetMessage('store not ready');
      return;
    }
    this.locateCoordinator.locateToMessage(messageID, shouldHighlight);
  }

  private getPreviousMessage(currentIndex: number): MessageInfo | undefined {
    if (currentIndex <= 0) {
      return undefined;
    }

    return this.messageDataSource.getData(currentIndex - 1);
  }

  private getNextMessage(currentIndex: number): MessageInfo | undefined {
    if (currentIndex >= this.messageDataSource.totalCount() - 1) {
      return undefined;
    }

    return this.messageDataSource.getData(currentIndex + 1);
  }

  private checkPreviousMessageIsAggregation(currentIndex: number): boolean {
    return false;
  }

  private checkNextMessageIsAggregation(currentIndex: number): boolean {
    return false;
  }

  private getMessageTimeString(currentIndex: number): string |null| Resource {
    const message = this.messageDataSource.getData(currentIndex);
    const previousMessage = currentIndex === 0 ? undefined : this.getPreviousMessage(currentIndex);
    return MessageListTimeGroupingPolicy.resolveTimeString(message, previousMessage, currentIndex === 0);
  }

  private getIntervalSeconds(timestamp1?: number, timestamp2?: number): number {
    return MessageListTimeGroupingPolicy.getIntervalSeconds(timestamp1, timestamp2);
  }

  private handleMessageEvent(event: MessageEvent) {
    if (event instanceof OnReceiveNewMessage) {
      if (TypingMessageProtocol.isTypingMessage(event.message)) {
        return;
      }
      const wasLatestVisible = this.isLatestMessageVisible();
      this.refreshDataSource();
      const latestMessage = this.getLatestMessage();
      const isSentBySelf = event.message?.isSentBySelf === true;
      if (isSentBySelf || wasLatestVisible) {
        this.scrollToBottom();
      } else if (latestMessage) {
        this.floatingEntryStateController.onNewMessage(latestMessage.msgID, false);
        this.tryUpdateMentionTargetByNewMessage(event.message);
        this.refreshFloatingEntry();
      }
    } else if (event instanceof OnMessageReactionUpdated) {
      console.log(`[UI-ReactionEvent] received, messageList.length=${this.messageListState?.messageList?.length ?? 0}`)
      this.refreshDataSource();
      if (event.message) {
        const targetID = event.message.msgID
        for (let i = 0; i < this.messageDataSource.totalCount(); i++) {
          const data = this.messageDataSource.getData(i) as MessageInfo
          if (data.msgID === targetID) {
            this.messageDataSource.forceRefresh(i)
            break
          }
        }
      }
      this.refreshFloatingEntry();
    } else if (event instanceof OnMessageRevoked) {
      this.floatingEntryStateController.onMessageRevoked(event.messageID);
      this.refreshDataSource();
      this.refreshFloatingEntry();
    } else if (event instanceof OnMessageDeleted) {
      this.refreshDataSource();
      this.refreshFloatingEntry();
    }
  }

  private tryUpdateMentionTargetByNewMessage(message?: MessageInfo): void {
    if (!message) {
      return;
    }
    if (!this.conversationID || !this.conversationID.startsWith(MessageList.GROUP_CONVERSATION_PREFIX)) {
      return;
    }
    const atUserList: string[] = message.atUserList ?? [];
    if (atUserList.length === 0) {
      return;
    }
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    const hasAtAll = atUserList.indexOf(MentionInfo.AT_ALL_USER_ID) >= 0;
    const hasAtMe = loginUserID.length > 0 && atUserList.indexOf(loginUserID) >= 0;
    if (!hasAtAll && !hasAtMe) {
      return;
    }
    const existingTarget = this.floatingEntryStateController.currentMentionTarget();
    const msgSeq = message.sequence ?? 0;
    if (existingTarget && existingTarget.sequence > 0 && msgSeq >= existingTarget.sequence) {
      return;
    }
    const kind = hasAtMe ? MessageListMentionKind.AT_ME : MessageListMentionKind.AT_ALL;
    const target = new MessageListMentionTarget(msgSeq, kind);
    this.floatingEntryStateController.onInitialMentionTarget(target, MessageListMentionTargetVisibility.HIDDEN);
  }

  private requestInitialMentionEntry(): void {
    if (!this.conversationListStore || !this.conversationID) {
      return;
    }
    if (!this.conversationID.startsWith(MessageList.GROUP_CONVERSATION_PREFIX)) {
      return;
    }
    const requestedConversationID = this.conversationID;
    this.conversationListStore.getConversationInfo(this.conversationID, new GetConversationInfoCompletionHandlerAdapter(
      (conversationInfo: ConversationInfo) => {
        if (this.conversationID !== requestedConversationID) {
          return;
        }
        const mentionTarget = MessageListFloatingEntryPolicy.findOldestMentionTarget(conversationInfo.groupAtInfoList);
        const visibility = mentionTarget ?
          this.mentionTargetVisibility(mentionTarget) :
          MessageListMentionTargetVisibility.UNKNOWN;
        this.floatingEntryStateController.onInitialMentionTarget(mentionTarget, visibility);
        this.refreshFloatingEntry();
      },
      (_code: number, _desc: string) => {
        this.refreshFloatingEntry();
      }
    ));
  }

  private updateFloatingEntryForScroll(): void {
    this.floatingEntryStateController.onMentionTargetVisibilityChanged(this.currentMentionTargetVisibility());
    this.floatingEntryStateController.onReturnMessageVisibilityChanged(this.isReturnMessageVisible());
    this.floatingEntryStateController.onScroll(
      this.distanceFromLatestItems(),
      this.visibleItemCount(),
      this.isLatestMessageVisible()
    );
    this.refreshFloatingEntry();
  }

  private refreshFloatingEntry(): void {
    this.floatingEntry = this.floatingEntryStateController.currentEntry();
  }

  private isReturnMessageVisible(): boolean {
    const returnMessageId = this.floatingEntryStateController.currentBackToQuoteReturnMessageId();
    if (!returnMessageId) {
      return false;
    }
    const index = this.messageDataSource.getIndex(returnMessageId);
    return index >= 0 && this.isIndexVisible(index);
  }

  private handleFloatingEntryClick(entry: MessageListFloatingEntry): void {
    this.floatingEntryStateController.consume(entry);
    this.refreshFloatingEntry();
    if (entry.type === MessageListFloatingEntryType.NEW_MESSAGES && entry.firstMessageId.length > 0) {
      this.locateToMessage(entry.firstMessageId);
      return;
    }
    if (entry.type === MessageListFloatingEntryType.MENTION && entry.target) {
      this.locateToSequence(entry.target.sequence);
      return;
    }
    if (entry.type === MessageListFloatingEntryType.BACK_TO_QUOTE && entry.returnMessageId.length > 0) {
      this.locateToMessage(entry.returnMessageId, false);
      return;
    }
    this.scrollToBottom();
  }

  private getFloatingEntryText(entry: MessageListFloatingEntry): Resource | string {
    if (entry.type === MessageListFloatingEntryType.NEW_MESSAGES) {
      return `${entry.count}${this.getString($r('app.string.messagelist_floating_new_messages'))}`;
    }
    if (entry.type === MessageListFloatingEntryType.BACK_TO_QUOTE) {
      return $r('app.string.messagelist_floating_back_to_quote');
    }
    if (entry.type === MessageListFloatingEntryType.MENTION) {
      if (entry.target?.kind === MessageListMentionKind.AT_ALL) {
        return $r('app.string.messagelist_floating_at_all');
      }
      return $r('app.string.messagelist_floating_someone_mentioned_me');
    }
    return $r('app.string.messagelist_floating_back_to_latest');
  }

  private currentMentionTargetVisibility(): MessageListMentionTargetVisibility {
    return this.mentionTargetVisibility(this.floatingEntryStateController.currentMentionTarget());
  }

  private mentionTargetVisibility(target?: MessageListMentionTarget): MessageListMentionTargetVisibility {
    if (!target || !this.messageListState) {
      return MessageListMentionTargetVisibility.UNKNOWN;
    }
    const messageCount = this.messageDataSource.totalCount();
    if (messageCount <= 0) {
      return MessageListMentionTargetVisibility.UNKNOWN;
    }
    const index = this.findMessageIndexBySequence(target.sequence);
    if (index < 0) {
      return MessageListMentionTargetVisibility.HIDDEN;
    }
    if (this.locateCoordinator.firstIndex < 0 || this.locateCoordinator.lastIndex < 0) {
      return MessageListMentionTargetVisibility.UNKNOWN;
    }
    return this.isIndexVisible(index) ? MessageListMentionTargetVisibility.VISIBLE : MessageListMentionTargetVisibility.HIDDEN;
  }

  private locateToSequence(sequence: number): void {
    this.locateCoordinator.locateToSequence(sequence);
  }

  private findMessageIndexBySequence(sequence: number): number {
    return this.locateCoordinator.findMessageIndexBySequence(sequence);
  }

  private getLatestMessage(): MessageInfo | undefined {
    return this.locateCoordinator.getLatestMessage();
  }

  private isLatestMessageVisible(): boolean {
    return this.locateCoordinator.isLatestMessageVisible();
  }

  private isIndexVisible(index: number): boolean {
    return this.locateCoordinator.isIndexVisible(index);
  }

  private visibleItemCount(): number {
    return this.locateCoordinator.visibleItemCount();
  }

  private distanceFromLatestItems(): number {
    return this.locateCoordinator.distanceFromLatestItems();
  }

  private getString(resource: Resource): string {
    try {
      return getContext(this).resourceManager.getStringSync(resource);
    } catch (_e) {
      return '';
    }
  }

  private restoreScrollPosition() {
    if (!this.messageListStore) {
      return;
    }
    const restored = this.locateCoordinator.restoreScrollPosition(
      this.pagingController.loadDirection,
      this.pagingController.anchorScrollOffset,
      this.pagingController.anchorMessageCount
    );
    if (restored) {
      this.pagingController.clearAnchor();
    }
  }

  private handleMessageAppear(message: MessageInfo) {
    if (!this.messageListStore || !this.messageListState) {
      return;
    }
    const accepted = this.readReceiptController.onMessageAppear(message,
      this.effectiveConfig.enableReadReceipt === true);
    if (!accepted) {
      return;
    }
    this.readReceiptController.scheduleFlush(this.messageListStore, this.messageListState.messageList);
  }

  // ============ Multi-select Mode Methods ============

  /**
   * Enter multi-select mode with an initial selected message
   */
  private enterMultiSelectMode(initialMessage?: MessageInfo) {
    this.selectionController.enterMultiSelectMode(initialMessage);
  }

  /**
   * Exit multi-select mode and clear selections
   */
  private exitMultiSelectMode() {
    this.selectionController.exitMultiSelectMode();
  }

  /**
   * Notify parent about multi-select mode change
   */
  private notifyMultiSelectModeChange() {
    if (this.onMultiSelectModeChange) {
      const actions: MultiSelectActions | undefined = this.isMultiSelectMode ? {
        cancel: () => {
          this.exitMultiSelectMode();
        },
        deleteMessages: () => {
          this.confirmDeleteSelectedMessages();
        },
        forwardSeparately: () => {
          this.forwardSelectedMessages(MessageForwardType.SEPARATE);
        },
        forwardMerged: () => {
          this.forwardSelectedMessages(MessageForwardType.MERGED);
        }
      } : undefined;
      this.onMultiSelectModeChange(this.isMultiSelectMode, this.selectedMessageIDs.size, actions);
    }
  }

  /**
   * Show read receipt detail dialog
   */
  private showReadReceiptDetail(message: MessageInfo) {
    if (!message || !this.messageListStore) {
      return;
    }

    this.readReceiptDialogController = new CustomDialogController({
      builder: MessageReadReceiptDetailPage({
        message: message,
        messageListStore: this.messageListStore
      }),
      autoCancel: false,
      customStyle: true,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
    });
    this.readReceiptDialogController.open();
  }

  /**
   * Handle emoji reaction on a message
   */
  private handleEmojiReaction(emoji: EmojiItem, message: MessageInfo) {
    const messageActionStore = MessageActionStore.create(message);
    const reactionID = emoji.name;
    const existingReaction = message.reactionList?.find(r => r.reactionID === reactionID);

    const refreshAfterReaction = () => {
      this.refreshDataSource();
      setTimeout(() => {
        this.refreshDataSource();
      }, 500);
    };

    if (existingReaction && (existingReaction.reactedByMyself ?? false)) {
      // Remove reaction if already reacted
      const removeCompletion = new CompletionHandlerAdapter(() => {
        Toast.info($r('app.string.messagelist_reaction_removed'), this.getUIContext());
        refreshAfterReaction();
      }, (code: number, desc: string) => {
        console.error('[MessageList] Failed to remove reaction:', code, desc);
      });
      messageActionStore.removeReaction(reactionID, removeCompletion);
    } else {
      // Add reaction
      const addCompletion = new CompletionHandlerAdapter(() => {
        Toast.info($r('app.string.messagelist_reaction_added'), this.getUIContext());
        refreshAfterReaction();
      }, (code: number, desc: string) => {
        console.error('[MessageList] Failed to add reaction:', code, desc);
      });
      messageActionStore.addReaction(reactionID, addCompletion);
    }
  }

  /**
   * Show full emoji picker sheet
   */
  private showFullEmojiPicker() {
    if (!this.selectedMessage) {
      return;
    }

    this.emojiPickerController = new CustomDialogController({
      builder: ReactionEmojiPickerSheet({
        onEmojiSelect: (emoji: EmojiItem) => {
          this.handleEmojiReaction(emoji, this.selectedMessage!);
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.emojiPickerController.open();
  }

  private canSelectMessage(message: MessageInfo): boolean {
    return this.selectionController.canSelectMessage(message);
  }

  private validateMessagesForForward(): boolean {
    if (this.selectionController.hasFailedMessages()) {
      Toast.error($r('app.string.forward_failed_message_tip'), this.getUIContext());
      return false;
    }

    if (this.selectionController.hasViolationMessages()) {
      Toast.error($r('app.string.forward_violation_message_tip'), this.getUIContext());
      return false;
    }

    return true;
  }

  private toggleMessageSelection(message: MessageInfo) {
    this.selectionController.toggleMessageSelection(message);
  }

  private getSelectedMessages(): MessageInfo[] {
    return this.selectionController.getSelectedMessages();
  }

  private confirmDeleteSelectedMessages(): void {
    if (this.selectedMessageIDs.size === 0) {
      return;
    }
    AlertDialog.show(
      undefined,
      $r('app.string.multiselect_delete_confirm'),
      $r('app.string.cancel'),
      $r('app.string.confirm'),
      undefined,
      undefined,
      (): void => {
        this.deleteSelectedMessages();
      },
      this.getUIContext(),
      true
    );
  }

  private forwardSelectedMessages(type: MessageForwardType): void {
    if (!this.validateMessagesForForward()) {
      return;
    }
    if (type === MessageForwardType.SEPARATE && this.selectedMessageIDs.size > MessageList.MAX_SEPARATE_FORWARD_COUNT) {
      Toast.info($r('app.string.forward_limit_tip'), this.getUIContext());
      return;
    }
    this.forwardType = type;
    this.showForwardTargetSelector();
  }

  deleteSelectedMessages() {
    const selectedMessages = this.getSelectedMessages();
    if (selectedMessages.length === 0) {
      return;
    }
    
    this.messageListStore?.deleteMessages(selectedMessages, new CompletionHandlerAdapter(() => {
      this.refreshDataSource();
      Toast.info($r('app.string.messagelist_messages_deleted'), this.getUIContext());
      this.exitMultiSelectMode();
    }, (code: number, desc: string) => {
      console.error('[MessageList] Failed to delete messages:', code, desc);
      Toast.info($r('app.string.messagelist_delete_message_failed'), this.getUIContext());
    }));
  }

  /**
   * Cancel multi-select mode (public method for parent component)
   */
  cancelMultiSelect() {
    this.exitMultiSelectMode();
  }

  // ============ Forward Methods ============

  private handleForwardSingleMessage(message: MessageInfo) {
    this.forwardType = MessageForwardType.SEPARATE;

    this.selectionController.selectSingleMessage(message);

    this.showForwardTargetSelector();
  }

  /**
   * Show the forward type selector (ActionSheet)
   * Allows user to choose between separate forward and merged forward
   */
  showForwardTypeSelector() {
    const selectedCount = this.selectedMessageIDs.size;
    const exceedsLimit = selectedCount > MessageList.MAX_SEPARATE_FORWARD_COUNT;
    
    this.forwardTypeDialogController = new CustomDialogController({
      builder: ForwardTypeDialog({
        showSeparateOption: !exceedsLimit,
        limitTip: $r('app.string.forward_limit_tip'),
        onForwardTypeSelected: (type: MessageForwardType) => {
          this.forwardType = type;
          this.showForwardTargetSelector();
        },
        onCancel: () => {
          console.info('[MessageList] Forward type selection cancelled');
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    
    this.forwardTypeDialogController.open();
  }

  /**
   * Show the forward target selector dialog (public method for parent component)
   */
  showForwardTargetSelector() {
    this.forwardDialogController = new CustomDialogController({
      builder: ForwardTargetSelector({
        currentConversationID: this.conversationID,
        onConfirm: (conversationIDs: string[]) => {
          this.forwardMessagesToConversations(conversationIDs);
        },
        onCancel: () => {
          this.selectionController.clearTransientSelection();
        }
      }),
      alignment: DialogAlignment.Default,
      autoCancel: false,
      customStyle: true,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      maskColor: Color.Transparent
    });
    
    this.forwardDialogController.open();
  }

  private forwardMessagesToConversations(targetConversationIDs: string[]) {
    this.forwardFlow.forwardToConversations(this.conversationID, targetConversationIDs);
  }

  private generateMergedForwardInfo(messages: MessageInfo[]): MergedForwardInfo {
    return MessageForwardCoordinator.buildMergedForwardInfo(messages, this.conversationID);
  }

  // ============ Voice to Text Methods ============

  private buildListenResources(): ListenPlanResources {
    return {
      selfSpeaker: TextUtils.getResourceString($r('app.string.listen_speaker_self')),
      says: (name: string) => TextUtils.getResourceStringWithArgs($r('app.string.listen_says'), name),
      sentImage: (name: string) => TextUtils.getResourceStringWithArgs($r('app.string.listen_sent_image'), name),
      sentVideo: (name: string) => TextUtils.getResourceStringWithArgs($r('app.string.listen_sent_video'), name),
      sentFile: (name: string) => TextUtils.getResourceStringWithArgs($r('app.string.listen_sent_file'), name),
      sentMerged: (name: string, title: string) =>
        TextUtils.getResourceStringWithArgs($r('app.string.listen_sent_merged'), name, title),
    };
  }

  private handleListenFromHere(message: MessageInfo) {
    if (!message || !this.messageListState) {
      return;
    }
    const list = this.messageListState.messageList;
    const startIndex = list.findIndex((m: MessageInfo) => m.msgID === message.msgID);
    if (startIndex < 0) {
      return;
    }
    const slice = list.slice(startIndex);
    const plan: ListenItem[] = buildListenPlan(slice, this.buildListenResources());
    if (plan.length === 0) {
      Toast.info($r('app.string.listen_from_here_empty'), this.getUIContext());
      return;
    }
    this.listenController.setStateListener((state: ListenPlaybackState) => {
      this.listenState = { isActive: state.isActive, isLoading: state.isLoading, currentText: state.currentText };
    });
    this.listenController.start(plan);
  }

  private handleConvertVoiceToText(message: MessageInfo) {
    this.asrCoordinator.convertVoiceToText(message, this.asrDisplayManager);
  }

  /**
   * Forward ASR text as a text message
   */
  private forwardAsrText(asrText: string) {
    if (!asrText || asrText.length === 0) {
      return;
    }

    // Show forward target selector
    this.forwardDialogController = new CustomDialogController({
      builder: ForwardTargetSelector({
        currentConversationID: this.conversationID,
        onConfirm: (conversationIDs: string[]) => {
          this.sendAsrTextToConversations(asrText, conversationIDs);
        },
        onCancel: () => {
          console.info('[MessageList] ASR text forward cancelled');
        }
      }),
      alignment: DialogAlignment.Default,
      autoCancel: false,
      customStyle: true,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      maskColor: Color.Transparent
    });

    this.forwardDialogController.open();
  }

  private sendAsrTextToConversations(asrText: string, targetConversationIDs: string[]) {
    this.sendTextToConversations(asrText, targetConversationIDs);
  }

  private scrollToBottomIfLastMessage(message: MessageInfo) {
    if (!this.messageListState) {
      return;
    }

    const list = this.messageListState.messageList;
    if (list.length === 0) {
      return;
    }

    const lastMessage = list[list.length - 1];
    if (lastMessage && lastMessage.msgID === message.msgID) {
      console.log(`[MessageList] 📜 Scrolling to bottom after ASR conversion`);
      this.scrollToBottom();
    }
  }

  /**
   * Get the ASR display manager instance
   * Used by MessageItem to pass to SoundMessageView
   */
  getAsrDisplayManager(): AsrDisplayManager {
    return this.asrDisplayManager;
  }

  // ============ Text Translation Methods ============

  private async handleTranslateText(message: MessageInfo) {
    await this.translateCoordinator.translate(message, this.translationDisplayManager);
  }

  private getTranslatedText(message: MessageInfo): string {
    return MessageListTranslateCoordinator.getTranslatedText(message);
  }

  /**
   * Forward translated text to other conversations
   * Called from MessageItem's translation menu
   */
  forwardTranslatedText(translatedText: string) {
    if (!translatedText || translatedText.length === 0) {
      return;
    }

    console.log(`[MessageList] 📤 Forwarding translated text`);

    // Show forward target selector
    this.forwardDialogController = new CustomDialogController({
      builder: ForwardTargetSelector({
        currentConversationID: this.conversationID,
        onConfirm: (conversationIDs: string[]) => {
          this.sendTranslatedTextToConversations(translatedText, conversationIDs);
        },
        onCancel: () => {
          console.info('[MessageList] Translated text forward cancelled');
        }
      }),
      alignment: DialogAlignment.Default,
      autoCancel: false,
      customStyle: true,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      maskColor: Color.Transparent
    });

    this.forwardDialogController.open();
  }

  private sendTranslatedTextToConversations(translatedText: string, targetConversationIDs: string[]) {
    this.sendTextToConversations(translatedText, targetConversationIDs);
  }

  private sendTextToConversations(text: string, targetConversationIDs: string[]) {
    if (targetConversationIDs.length === 0) {
      return;
    }

    let successCount = 0;
    let failureCount = 0;
    const totalCount = targetConversationIDs.length;

    const onComplete = () => {
      if (successCount + failureCount >= totalCount) {
        if (failureCount === 0) {
          Toast.success($r('app.string.forward_success'), this.getUIContext());
        } else {
          console.error(`[MessageList] ${failureCount}/${totalCount} text sends failed`);
          Toast.info($r('app.string.forward_failed'), this.getUIContext());
        }
      }
    };

    for (const targetConversationID of targetConversationIDs) {
      const messageInputStore = MessageInputStore.create(targetConversationID);
      const payload = new TextSendMessagePayload(text);
      const option = new SendMessageOption();
      option.needReadReceipt = AppBuilderConfig.getInstance().enableReadReceipt ?? false;
      option.offlinePushInfo = this.createOfflinePushInfoForConversation(targetConversationID);

      messageInputStore.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
        successCount++;
        console.info(`[MessageList] Text sent to ${targetConversationID}`);
        onComplete();
      }, (code: number, desc: string) => {
        failureCount++;
        console.error(`[MessageList] Failed to send text to ${targetConversationID}:`, code, desc);
        onComplete();
      }));
    }
  }

  // MARK: - Offline Push Info Creation

  private createOfflinePushInfoForConversation(conversationID: string): OfflinePushInfo {
    const conversation = this.findConversationInfo(conversationID);
    return MessageOfflinePushInfoFactory.create(conversationID, conversation?.title);
  }

  private getMessageTypeAbstract(message: MessageInfo): string {
    return MessageOfflinePushInfoFactory.getMessageTypeAbstract(message);
  }

  // ============ Classic Popup Action Methods ============

  private handlePopupCopy(message: MessageInfo) {
    const textPayload = message.messagePayload as TextMessagePayload | undefined;
    let messageContent = textPayload?.text ?? '';
    if (messageContent.length === 0) {
      messageContent = ChatbotMessageActionPolicy.displayText(message);
    }
    if (!messageContent || messageContent.length === 0) {
      Toast.info($r('app.string.messagelist_copy_unsupported'), this.getUIContext());
      return;
    }

    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, messageContent);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData, (err) => {
      if (err) {
        Toast.info($r('app.string.messagelist_copy_failed'), this.getUIContext());
      } else {
        Toast.info($r('app.string.messagelist_copied'), this.getUIContext());
      }
    });
  }
}

class MessageListChatHistoryClearedObserver implements TUIObserver {
  private readonly host: MessageList;

  constructor(host: MessageList) {
    this.host = host;
  }

  onNotify(event: string, key: string | null, params: NotifyParams | null): void {
    const data: Record<string, Object> | null | undefined = params?.data;
    if (!data) {
      return;
    }
    const conversationIDValue: Object | undefined = data['conversationID'];
    if (!conversationIDValue) {
      return;
    }
    const conversationID: string = conversationIDValue as string;
    this.host.onChatHistoryClearedNotification(conversationID);
  }
}