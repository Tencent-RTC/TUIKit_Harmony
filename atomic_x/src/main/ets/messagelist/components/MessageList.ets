import { LoginStore } from '@tencentcloud/atomicxcore';
import { MessageListStore, MessageInfo, MessageType, MessageLoadDirection, MessageLoadOption, MessageEvent, OnReceiveNewMessage, OnMessageReactionUpdated, OnMessageRevoked, OnMessageDeleted, MessageStatus, MessageListState, MessageForwardType, ForwardMessageOption, MergedForwardInfo, TextMessagePayload, AudioMessagePayload, CustomMessagePayload, OfflinePushInfo } from '@tencentcloud/atomicxcore';
import { MessageActionStore } from '@tencentcloud/atomicxcore';
import { ConversationListStore, ConversationListState, ConversationInfo, ConversationMarkType, ConversationType } from '@tencentcloud/atomicxcore';
import { MessageInputStore, TextSendMessagePayload, SendMessageOption } from '@tencentcloud/atomicxcore';
import { AppBuilderConfig, ThemeState, TextUtils, ActionItem, Toast, EventBus } from '../../basecomponent/Index';
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
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { TranslationTextParser } from '../utils/TranslationTextParser';
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

class MessageInfoDataSource implements IDataSource {
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

  setMessages(messages: MessageInfo[]): void {
    this.messages = Array.from(messages);
    this.listeners.forEach((listener: DataChangeListener) => listener.onDataReloaded());
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
  forward: () => void;
}

@Component
export struct MessageList {
  private static readonly TIME_INTERVAL_THRESHOLD: number = 5 * 60;
  private static readonly MAX_SEPARATE_FORWARD_COUNT: number = 30;
  private static readonly GROUP_CONVERSATION_PREFIX: string = 'group_';
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State messageListStore?: MessageListStore = undefined;
  @State conversationListStore?: ConversationListStore = undefined;
  @State messageListState?: MessageListState = undefined;
  @State messageDataSource: MessageInfoDataSource = new MessageInfoDataSource();
  @State isLoading: boolean = true;
  @State isLoadingMore: boolean = false;
  @State lastFirstIndex: number = -1;
  @State lastLastIndex: number = -1;
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
  private scrollPositionBeforeLoad: number = -1;
  private messageCountBeforeLoad: number = 0;
  private currentLoadDirection: MessageLoadDirection = MessageLoadDirection.OLDER;
  private isLoadingAroundTargetMessage: boolean = false;
  private lastScrollToBottomTime: number = 0;
  private floatingEntryStateController: MessageListFloatingEntryStateController = new MessageListFloatingEntryStateController();
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();
  @State private floatingEntry?: MessageListFloatingEntry = undefined;

  // ASR Display Manager for voice-to-text feature
  @State private asrDisplayManager: AsrDisplayManager = new AsrDisplayManager();
  
  // Translation Display Manager for text translation feature
  @State private translationDisplayManager: TranslationDisplayManager = new TranslationDisplayManager();

  private pendingReceiptMessageIDs: Set<string> = new Set();
  private sentReceiptMessageIDs: Set<string> = new Set();
  private receiptTimer?: number = undefined;

  aboutToDisappear(): void {
    if (this.receiptTimer !== undefined) {
      clearTimeout(this.receiptTimer);
      this.receiptTimer = undefined;
    }

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
  }

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    console.info(`[MessageList] aboutToAppear with conversationID: ${this.conversationID}, locateMessage: ${this.locateMessage?.msgID ||
      'none'}`);
    
    if (this.conversationID) {
      this.loadMessages();
      this.clearMessageUnreadCount();
    } else {
      console.error('[MessageList] No valid conversationID provided');
      this.isLoading = false;
    }

    EventBus.getInstance().on(MessageQuoteEvent.LOCATE_QUOTED_MESSAGE, (eventData: emitter.EventData) => {
      this.handleLocateQuotedMessage(eventData);
    });
  }

  loadMessages() {
    this.isLoading = true;
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

    if (this.locateMessage) {
      this.loadMessagesAroundTargetMessage();
    } else {
      this.loadHistoryMessages();
    }
  }

  private refreshDataSource(): void {
    if (!this.messageListState) {
      return;
    }
    const filtered = this.messageListState.messageList.filter(
      (m: MessageInfo) => !MessageUtils.isMentionMirrorMessage(m)
    );
    const msgsWithReactions = this.messageListState.messageList.filter((m: MessageInfo) => m.reactionList.length > 0)
    if (msgsWithReactions.length > 0) {
      console.log(`[UI-refreshDataSource] messages with reactions: ${msgsWithReactions.length}, first msgID=${msgsWithReactions[0].msgID}, reactionCount=${msgsWithReactions[0].reactionList.length}`)
    }
    this.messageDataSource.setMessages(filtered);
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
    this.loadMoreMessages(MessageLoadDirection.OLDER);
  }

  loadMoreNewerMessages() {
    this.loadMoreMessages(MessageLoadDirection.NEWER);
  }

  @Builder
  MessageItemBuilder(message: MessageInfo, index: number) {
    this.NormalMessageItemBuilder(message, index);
  }

  @Builder
  NormalMessageItemBuilder(message: MessageInfo, index: number) {
    Column() {
      if (this.effectiveConfig.isShowTimeMessage && this.getMessageTimeString(index)) {
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
            .borderRadius(4)
            .backgroundColor('rgba(0, 0, 0, 0.05)')
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
      top: this.checkPreviousMessageIsAggregation(index) ? (this.effectiveConfig.cellSpacing ) : (this.effectiveConfig.cellSpacing??2 * 5),
      bottom: this.checkNextMessageIsAggregation(index) ? (this.effectiveConfig.cellSpacing ) : (this.effectiveConfig.cellSpacing??2 * 5)
    })
  }

  /**
   * Generate stable key for LazyForEach
   * Computes a safe state hash that excludes non-serializable SDK objects
   */
  private getMessageKey(message: MessageInfo, index: number): string {
    return `${message.msgID}_${MessageUtils.getMessageStateHash(message)}_${index}`;
  }

  private shouldShowAvatar(message: MessageInfo, index: number): boolean {
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return true;
    }
    
    if (message.isSentBySelf) {
      return this.effectiveConfig.isShowRightAvatar ?? false;
    } else {
      const showLeftAvatar = this.effectiveConfig.isShowLeftAvatar ?? true;
      return showLeftAvatar && !this.checkNextMessageIsAggregation(index);
    }
  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeState.colors.textColorPrimary)

      Text($r('app.string.messagelist_loading'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorTertiary)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    if (this.isLoading) {
      // Loading
      this.LoadingStateBuilder()
    } else {
      Column() {
        this.NormalListBuilder()
      }
      .width('100%')
      .height('100%')
    }
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
        onCancel: () => {
          this.exitMultiSelectMode();
        },
        onDelete: () => {
          this.deleteSelectedMessages();
        },
        onForward: () => {
          // Validate messages before forwarding
          if (this.validateMessagesForForward()) {
            this.showForwardTargetSelector();
          }
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
    if (this.messageListStore && this.messageListState) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {

        if (this.isLoadingMore && this.currentLoadDirection === MessageLoadDirection.OLDER) {
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
          }, (message: MessageInfo, index: number) => this.getMessageKey(message, index))
        }
        .padding({ left: this.effectiveConfig.horizontalPadding, right: this.effectiveConfig.horizontalPadding })
        .width('100%')
        .layoutWeight(1)
        .onReachStart(() => {

          console.info('[MessageList] Reached start of list');


          if (this.messageListState?.hasOlderMessages &&
            !this.isLoadingMore &&
            this.messageDataSource.totalCount() > 0 &&
            !this.isLoadingAroundTargetMessage) {


            this.messageCountBeforeLoad = this.messageDataSource.totalCount();
            this.scrollPositionBeforeLoad = this.scroller.currentOffset().yOffset;
            this.currentLoadDirection = MessageLoadDirection.OLDER;

            console.info('[MessageList] Loading more history messages from onReachStart', {
              messageCountBefore: this.messageCountBeforeLoad,
              scrollPositionBefore: this.scrollPositionBeforeLoad
            });

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

          const timeSinceLastScroll = Date.now() - this.lastScrollToBottomTime;
          if (timeSinceLastScroll < 500) {
            console.info('[MessageList] Skip loading on onReachEnd - just scrolled to bottom');
            return;
          }

          if (this.messageListState?.hasNewerMessages &&
            !this.isLoadingMore &&
            this.messageDataSource.totalCount() > 0 &&
            !this.isLoadingAroundTargetMessage) {

            this.messageCountBeforeLoad = this.messageDataSource.totalCount();
            this.scrollPositionBeforeLoad = this.scroller.currentOffset().yOffset;
            this.currentLoadDirection = MessageLoadDirection.NEWER;

            console.info('[MessageList] Loading more newer messages from onReachEnd', {
              messageCountBefore: this.messageCountBeforeLoad,
              scrollPositionBefore: this.scrollPositionBeforeLoad
            });

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

          console.info(`[MessageList] Scroll index changed: first=${firstIndex}, last=${lastIndex}, prevFirst=${this.lastFirstIndex}, userScrolling: ${this.userScrolling}`);


          this.lastFirstIndex = firstIndex;
          this.lastLastIndex = lastIndex;
          this.updateFloatingEntryForScroll();
        })
        .onScrollStart(() => {

          this.userScrolling = true;
          console.info('[MessageList] User scroll started');
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


        if (this.isLoadingMore && this.currentLoadDirection === MessageLoadDirection.NEWER) {
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
        this.FloatingEntryBuilder(this.floatingEntry)
      }
    }
    .width('100%')
    .layoutWeight(1)
    }
  }

  @Builder
  private FloatingEntryBuilder(entry: MessageListFloatingEntry) {
    Row({ space: 6 }) {
      Text(entry.type === MessageListFloatingEntryType.MENTION ? '↑' : '↓')
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Bold)

      Text(this.getFloatingEntryText(entry))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
    }
    .height(35)
    .padding({ left: 10, right: 10 })
    .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(7)
    .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 2 })
    .margin({ right: 16, bottom: 16 })
    .onClick(() => {
      this.handleFloatingEntryClick(entry);
    })
  }

  scrollToBottom() {
    this.lastScrollToBottomTime = Date.now();
    setTimeout(() => {
      this.scroller?.scrollEdge(Edge.End);
    }, 100);
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
      this.loadMessagesAroundTargetMessage();
    }
  }

  locateToMessage(messageID: string) {
    if (!this.messageListState || !messageID) {


      if (this.isLoadingAroundTargetMessage) {
        this.isLoadingAroundTargetMessage = false;
        console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (invalid params)`);
      }
      return;
    }


    const messageIndex = this.messageDataSource.getIndex(messageID);

    if (messageIndex !== -1) {


      this.highlightedMessageID = messageID;


      setTimeout(() => {
        this.scroller.scrollToIndex(messageIndex, true, ScrollAlign.CENTER);


        if (this.isLoadingAroundTargetMessage) {
          this.isLoadingAroundTargetMessage = false;
          console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false after successful locate`);
        }


        setTimeout(() => {
          this.highlightedMessageID = '';
        }, 3000);
      }, 200);
    } else {
      console.warn(`[MessageList] 未找到消息ID: ${messageID}`);

      if (this.isLoadingAroundTargetMessage) {
        this.isLoadingAroundTargetMessage = false;
        console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (message not found)`);
      }
    }
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
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return false;
    }
    
    const message = this.messageDataSource.getData(currentIndex);
    const prevMessage = this.getPreviousMessage(currentIndex);

    if (!message || !prevMessage) {
      return false;
    }


    if (message.isSentBySelf !== prevMessage.isSentBySelf) {
      return false;
    }


    if (prevMessage.status === MessageStatus.REVOKED) {
      return false;
    }


    if (message.timestamp && prevMessage.timestamp &&
      message.timestamp > 0 && prevMessage.timestamp > 0) {
      const timeInterval = this.getIntervalSeconds(message.timestamp, prevMessage.timestamp);
      if (timeInterval > MessageList.TIME_INTERVAL_THRESHOLD) {
        return false;
      }
    }

    return true;
  }

  private checkNextMessageIsAggregation(currentIndex: number): boolean {
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return false;
    }
    
    const message = this.messageDataSource.getData(currentIndex);
    const nextMessage = this.getNextMessage(currentIndex);

    if (!message || !nextMessage) {
      return false;
    }


    if (message.isSentBySelf !== nextMessage.isSentBySelf) {
      return false;
    }


    if (nextMessage.status === MessageStatus.REVOKED) {
      return false;
    }


    if (message.timestamp && nextMessage.timestamp &&
      message.timestamp > 0 && nextMessage.timestamp > 0) {
      const timeInterval = this.getIntervalSeconds(message.timestamp, nextMessage.timestamp);
      if (timeInterval > MessageList.TIME_INTERVAL_THRESHOLD) {
        return false;
      }
    }

    return true;
  }

  private getMessageTimeString(currentIndex: number): string |null| Resource {
    const message = this.messageDataSource.getData(currentIndex);

    if (!message || !message.timestamp) {
      return null;
    }


    if (!message.timestamp || message.timestamp === 0 || message.timestamp < 0 ||
    isNaN(message.timestamp)) {
      console.warn(`[MessageList] Invalid message dateTime: ${message.timestamp}, messageID: ${message.msgID}`);
      return null;
    }


    if (currentIndex === 0) {
      console.info(`[MessageList] First message, showing time for message ${message.msgID}`);
      return this.getTimeString(message.timestamp);
    }

    const prevMessage = this.getPreviousMessage(currentIndex);
    if (message && prevMessage && prevMessage.timestamp) {
      const timeInterval = this.getIntervalSeconds(message.timestamp, prevMessage.timestamp);
      console.info(`[MessageList] Message ${currentIndex} time interval: ${timeInterval}s, threshold: ${MessageList.TIME_INTERVAL_THRESHOLD}s`);
      if (timeInterval > MessageList.TIME_INTERVAL_THRESHOLD) {
        return this.getTimeString(message.timestamp);
      }
    }

    return null;
  }

  private getTimeString(timestamp?: number): string | null | Resource{
    if (!timestamp || timestamp <= 0 || isNaN(timestamp)) {
      return null;
    }
    const date = new Date(timestamp * 1000);
    const now = new Date();


    const nowYear = now.getFullYear();
    const nowMonth = now.getMonth();
    const nowDay = now.getDate();


    const dateYear = date.getFullYear();
    const dateMonth = date.getMonth();
    const dateDay = date.getDate();


    const getWeekOfMonth = (targetDate: Date): number => {
      const firstDayOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
      let firstDayOfWeek = firstDayOfMonth.getDay(); // 0=Sunday, 6=Saturday


      firstDayOfWeek = (firstDayOfWeek + 1) % 7;


      const dayOfMonth = targetDate.getDate();
      return Math.ceil((dayOfMonth + firstDayOfWeek) / 7);
    };

    const nowWeekOfMonth = getWeekOfMonth(now);
    const dateWeekOfMonth = getWeekOfMonth(date);

    if (nowYear === dateYear) {
      if (nowMonth === dateMonth) {
        if (nowWeekOfMonth === dateWeekOfMonth) {
          if (nowDay === dateDay) {

            return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
          } else {

            return this.getLocalizedWeekday(date.getDay());
          }
        } else {

          return `${(dateMonth + 1).toString().padStart(2, '0')}/${dateDay.toString().padStart(2, '0')}`;
        }
      } else {

        return `${(dateMonth + 1).toString().padStart(2, '0')}/${dateDay.toString().padStart(2, '0')}`;
      }
    } else {

      return `${dateYear}/${(dateMonth + 1).toString().padStart(2, '0')}/${dateDay.toString().padStart(2, '0')}`;
    }
  }

  private getIntervalSeconds(timestamp1?: number, timestamp2?: number): number {
    if (!timestamp1 || !timestamp2) {
      return Number.MAX_SAFE_INTEGER;
    }
    return Math.abs(timestamp2 - timestamp1);
  }

  private getLocalizedWeekday(dayOfWeek: number): string | Resource {
    switch (dayOfWeek) {
      case 0:
        return $r('app.string.sunday');
      case 1:
        return $r('app.string.monday');
      case 2:
        return $r('app.string.tuesday');
      case 3:
        return $r('app.string.wednesday');
      case 4:
        return $r('app.string.thursday');
      case 5:
        return $r('app.string.friday');
      case 6:
        return $r('app.string.saturday');
      default:
        return $r('app.string.unknown');
    }
  }

  private loadHistoryMessages() {
    const option = new MessageLoadOption();
    option.direction = MessageLoadDirection.OLDER;
    option.pageCount = 20;

    this.messageListStore!.loadMessages(option, new CompletionHandlerAdapter(() => {
      this.isLoading = false;
      this.refreshDataSource();
      if (this.locateMessage?.msgID) {
        this.locateToMessage(this.locateMessage.msgID);
      }
    }, () => {
      this.isLoading = false;
    }));
  }

  private loadMessagesAroundTargetMessage() {
    if (!this.locateMessage) {
      this.loadHistoryMessages();
      return;
    }

    this.isLoadingAroundTargetMessage = true;
    console.info(`[MessageList] Set isLoadingAroundTargetMessage = true`);

    const option = new MessageLoadOption();
    option.cursor = this.locateMessage;
    option.direction = MessageLoadDirection.BOTH;
    option.pageCount = 20;

    this.messageListStore!.loadMessages(option, new CompletionHandlerAdapter(() => {
      this.refreshDataSource();
      if (this.locateMessage?.msgID) {
        const targetMessageID = this.locateMessage.msgID;
        setTimeout(() => {
          this.locateToMessage(targetMessageID);
          this.isLoading = false;
        }, 100);
      } else {
        this.isLoading = false;
        this.isLoadingAroundTargetMessage = false;
        console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (no locateMessage)`);
      }
    }, () => {
      this.isLoading = false;
      this.isLoadingAroundTargetMessage = false;
      console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (error case)`);
      this.loadHistoryMessages();
    }));
  }

  private loadMoreMessages(direction: MessageLoadDirection) {
    const isOlder = direction === MessageLoadDirection.OLDER;
    const directionName = isOlder ? 'history' : 'newer';

    console.info(`[MessageList] loadMore${isOlder ? 'History' : 'Newer'}Messages called - checking conditions`);

    if (!this.messageListStore || !this.messageListState || this.isLoadingMore) {
      console.info(`[MessageList] Skip loading more ${directionName} messages - already loading`);
      return;
    }

    const hasMoreMessages = isOlder ?
      this.messageListState.hasOlderMessages :
      this.messageListState.hasNewerMessages;

    if (!hasMoreMessages) {
      console.info(`[MessageList] No more ${directionName} messages available`);
      return;
    }

    console.info(`[MessageList] Loading more ${directionName} messages...`);
    this.isLoadingMore = true;
    this.currentLoadDirection = direction;

    const completion = new CompletionHandlerAdapter(() => {
      this.refreshDataSource();
      console.info(`[MessageList] Successfully loaded more ${directionName} messages, count:`,
        this.messageDataSource.totalCount());
      this.isLoadingMore = false;
      this.restoreScrollPosition();
    }, () => {
      this.isLoadingMore = false;
    });

    if (isOlder) {
      this.messageListStore.loadOlderMessages(completion);
    } else {
      this.messageListStore.loadNewerMessages(completion);
    }
  }

  private handleMessageEvent(event: MessageEvent) {
    if (event instanceof OnReceiveNewMessage) {
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
    this.scrollToBottom();
  }

  private getFloatingEntryText(entry: MessageListFloatingEntry): Resource | string {
    if (entry.type === MessageListFloatingEntryType.NEW_MESSAGES) {
      return `${entry.count}${this.getString($r('app.string.messagelist_floating_new_messages'))}`;
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
    if (this.lastFirstIndex < 0 || this.lastLastIndex < 0) {
      return MessageListMentionTargetVisibility.UNKNOWN;
    }
    return this.isIndexVisible(index) ? MessageListMentionTargetVisibility.VISIBLE : MessageListMentionTargetVisibility.HIDDEN;
  }

  private locateToSequence(sequence: number): void {
    const index = this.findMessageIndexBySequence(sequence);
    if (index >= 0) {
      const message = this.messageDataSource.getData(index);
      if (message) {
        this.locateToMessage(message.msgID);
      }
      return;
    }
    const cursor = new MessageInfo();
    cursor.sequence = sequence;
    this.locateMessage = cursor;
    this.loadMessagesAroundTargetMessage();
  }

  private findMessageIndexBySequence(sequence: number): number {
    for (let i = 0; i < this.messageDataSource.totalCount(); i++) {
      const message = this.messageDataSource.getData(i);
      if (message && message.sequence === sequence) {
        return i;
      }
    }
    return -1;
  }

  private getLatestMessage(): MessageInfo | undefined {
    const count = this.messageDataSource.totalCount();
    if (count <= 0) {
      return undefined;
    }
    return this.messageDataSource.getData(count - 1);
  }

  private isLatestMessageVisible(): boolean {
    const count = this.messageDataSource.totalCount();
    if (count <= 0) {
      return true;
    }
    if (this.lastLastIndex < 0) {
      return true;
    }
    return this.lastLastIndex >= count - 1;
  }

  private isIndexVisible(index: number): boolean {
    if (index < 0) {
      return false;
    }
    if (this.lastFirstIndex < 0 || this.lastLastIndex < 0) {
      return false;
    }
    return index >= this.lastFirstIndex && index <= this.lastLastIndex;
  }

  private visibleItemCount(): number {
    if (this.lastFirstIndex < 0 || this.lastLastIndex < 0) {
      return 0;
    }
    return Math.max(0, this.lastLastIndex - this.lastFirstIndex + 1);
  }

  private distanceFromLatestItems(): number {
    const count = this.messageDataSource.totalCount();
    if (count <= 0) {
      return 0;
    }
    if (this.lastLastIndex < 0) {
      return 0;
    }
    return Math.max(0, count - 1 - this.lastLastIndex);
  }

  private getString(resource: Resource): string {
    try {
      return getContext(this).resourceManager.getStringSync(resource);
    } catch (_e) {
      return '';
    }
  }

  private restoreScrollPosition() {

    if (this.isLoadingAroundTargetMessage) {
      console.info('[MessageList] Skip restoreScrollPosition for loadMessagesAroundTargetMessage');
      return;
    }

    console.info(`[MessageList] restoreScrollPosition called, isLoadingAroundTargetMessage: ${this.isLoadingAroundTargetMessage}`);

    if (this.scrollPositionBeforeLoad === -1 || !this.messageListStore) {
      console.info('[MessageList] No scroll position to restore');
      return;
    }

    const currentMessageCount = this.messageDataSource.totalCount();
    const newMessagesCount = currentMessageCount - this.messageCountBeforeLoad;

    console.info('[MessageList] Restoring scroll position:', {
      messageCountBefore: this.messageCountBeforeLoad,
      currentMessageCount: currentMessageCount,
      newMessagesCount: newMessagesCount,
      scrollPositionBefore: this.scrollPositionBeforeLoad,
      loadDirection: this.currentLoadDirection === MessageLoadDirection.OLDER ? 'older' : 'newer'
    });

    if (newMessagesCount > 0) {
      if (this.currentLoadDirection === MessageLoadDirection.OLDER) {

        console.info('[MessageList] Restoring position after loading older messages');
        this.scroller.scrollToIndex(newMessagesCount, false, ScrollAlign.START);
        console.info(`[MessageList] Scrolled to index ${newMessagesCount} to maintain position`);
      } else {

        console.info('[MessageList] Restoring position after loading newer messages');

        const targetIndex = this.messageCountBeforeLoad - 1;
        if (targetIndex >= 0 && targetIndex < this.messageDataSource.totalCount()) {
          this.scroller.scrollToIndex(targetIndex, false, ScrollAlign.END);
          console.info(`[MessageList] Scrolled to index ${targetIndex} to maintain viewing position`);
        }
      }
    }


    this.scrollPositionBeforeLoad = -1;
    this.messageCountBeforeLoad = 0;
  }

  private handleMessageAppear(message: MessageInfo) {
    if (!this.messageListStore || !this.messageListState) {
      return;
    }

    if (!this.effectiveConfig.enableReadReceipt) {
      return;
    }

    if (!message || message.isSentBySelf) {
      return;
    }

    if (!message.needReadReceipt) {
      return;
    }

    if (message.status !== MessageStatus.SEND_SUCCESS) {
      return;
    }

    if (message.messageType === MessageType.TIPS) {
      return;
    }

    const messageID = message.msgID;
    if (!messageID) {
      return;
    }

    if (this.sentReceiptMessageIDs.has(messageID) || this.pendingReceiptMessageIDs.has(messageID)) {
      return;
    }

    this.pendingReceiptMessageIDs.add(messageID);
    this.debounceReadReceipt();
  }

  private debounceReadReceipt() {
    if (this.receiptTimer !== undefined) {
      clearTimeout(this.receiptTimer);
    }

    this.receiptTimer = setTimeout(() => {
      this.sendBatchReadReceipts();
    }, 1000);
  }

  private sendBatchReadReceipts() {
    if (!this.messageListStore || !this.messageListState) {
      return;
    }

    this.receiptTimer = undefined;

    const pendingIDs = Array.from(this.pendingReceiptMessageIDs);
    if (pendingIDs.length === 0) {
      return;
    }

    const messages: MessageInfo[] = [];
    const messageIDsToSend: string[] = [];

    pendingIDs.forEach((id: string) => {
      const msg = this.messageListState!.messageList.find((m: MessageInfo) => m.msgID === id);
      if (msg && msg.rawMessage) {
        messages.push(msg);
        messageIDsToSend.push(id);
      }
    });

    if (messages.length === 0) {
      return;
    }

    const completion = new CompletionHandlerAdapter(() => {
      messageIDsToSend.forEach((id: string) => {
        this.sentReceiptMessageIDs.add(id);
        this.pendingReceiptMessageIDs.delete(id);
      });
    }, (code: number, desc: string) => {
      console.error('[MessageList] sendMessageReadReceipts failed:', code, desc);
    });
    this.messageListStore.sendMessageReadReceipts(messages, completion);
  }

  // ============ Multi-select Mode Methods ============

  /**
   * Enter multi-select mode with an initial selected message
   */
  private enterMultiSelectMode(initialMessage?: MessageInfo) {
    this.isMultiSelectMode = true;
    this.selectedMessageIDs = new Set();
    if (initialMessage && this.canSelectMessage(initialMessage)) {
      this.selectedMessageIDs.add(initialMessage.ID);
    }
    console.info('[MessageList] Entered multi-select mode');
    this.notifyMultiSelectModeChange();
  }

  /**
   * Exit multi-select mode and clear selections
   */
  private exitMultiSelectMode() {
    this.isMultiSelectMode = false;
    this.selectedMessageIDs = new Set();
    console.info('[MessageList] Exited multi-select mode');
    this.notifyMultiSelectModeChange();
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
          this.deleteSelectedMessages();
        },
        forward: () => {
          // Validate messages before forwarding
          if (this.validateMessagesForForward()) {
            this.showForwardTypeSelector();
          }
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
    if (message.status === MessageStatus.REVOKED) {
      return false;
    }
    if (message.messageType === MessageType.TIPS) {
      return false;
    }
    if (message.messageType === MessageType.CUSTOM) {
      return false;
    }
    return true;
  }

  private validateMessagesForForward(): boolean {
    const selectedMessages = this.getSelectedMessages();
    
    const hasFailedMessages = selectedMessages.some(msg => msg.status === MessageStatus.SEND_FAIL);
    if (hasFailedMessages) {
      Toast.error($r('app.string.forward_failed_message_tip'), this.getUIContext());
      return false;
    }
    
    const hasViolationMessages = selectedMessages.some(msg => msg.status === MessageStatus.VIOLATION);
    if (hasViolationMessages) {
      Toast.error($r('app.string.forward_violation_message_tip'), this.getUIContext());
      return false;
    }
    
    return true;
  }

  private toggleMessageSelection(message: MessageInfo) {
    if (!this.canSelectMessage(message)) {
      return;
    }
    
    if (this.selectedMessageIDs.has(message.msgID)) {
      this.selectedMessageIDs.delete(message.msgID);
    } else {
      this.selectedMessageIDs.add(message.msgID);
    }
    this.selectedMessageIDs = new Set(this.selectedMessageIDs);
    this.notifyMultiSelectModeChange();
  }

  private getSelectedMessages(): MessageInfo[] {
    if (!this.messageListState) {
      return [];
    }
    
    const selectedMessages: MessageInfo[] = [];
    this.messageListState.messageList.forEach((message: MessageInfo) => {
      if (this.selectedMessageIDs.has(message.msgID)) {
        selectedMessages.push(message);
      }
    });
    
    return selectedMessages.sort((a, b) => (a.timestamp ?? 0) - (b.timestamp ?? 0));
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
    
    this.selectedMessageIDs = new Set([message.msgID]);
    
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
          // If not in multi-select mode, clear selected message IDs
          if (!this.isMultiSelectMode) {
            this.selectedMessageIDs.clear();
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    
    this.forwardDialogController.open();
  }

  private forwardMessagesToConversations(targetConversationIDs: string[]) {
    const selectedMessages = this.getSelectedMessages();
    if (selectedMessages.length === 0 || targetConversationIDs.length === 0) {
      if (!this.isMultiSelectMode) {
        this.selectedMessageIDs.clear();
      } else {
        this.exitMultiSelectMode();
      }
      return;
    }
    
    console.info(`[MessageList] Forwarding ${selectedMessages.length} messages to ${targetConversationIDs.length} conversations, type: ${this.forwardType}`);
    
    if (this.isMultiSelectMode) {
      this.exitMultiSelectMode();
    } else {
      this.selectedMessageIDs.clear();
    }
    
    let successCount = 0;
    let failureCount = 0;
    const totalCount = targetConversationIDs.length;

    const onComplete = () => {
      if (successCount + failureCount >= totalCount) {
        if (failureCount === 0) {
          Toast.success($r('app.string.forward_success'), this.getUIContext());
        } else {
          console.error(`[MessageList] ${failureCount}/${totalCount} forwards failed`);
          Toast.info($r('app.string.forward_failed'), this.getUIContext());
        }
      }
    };

    for (const targetConversationID of targetConversationIDs) {
      const forwardOption = new ForwardMessageOption();
      forwardOption.forwardType = this.forwardType;
      if (this.forwardType === MessageForwardType.MERGED) {
        forwardOption.mergedForwardInfo = this.generateMergedForwardInfo(selectedMessages);
      }
      const sendMessageOption = new SendMessageOption();
      sendMessageOption.needReadReceipt = AppBuilderConfig.getInstance().enableReadReceipt ?? false;
      sendMessageOption.offlinePushInfo = this.createOfflinePushInfoForConversation(targetConversationID);
      forwardOption.sendMessageOption = sendMessageOption;

      this.messageListStore?.forwardMessages(selectedMessages, forwardOption, targetConversationID, new CompletionHandlerAdapter(() => {
        successCount++;
        console.info(`[MessageList] Forward to ${targetConversationID} succeeded`);
        onComplete();
      }, (code: number, desc: string) => {
        failureCount++;
        console.error(`[MessageList] Forward to ${targetConversationID} failed:`, code, desc);
        onComplete();
      }));
    }
  }

  private generateMergedForwardInfo(messages: MessageInfo[]): MergedForwardInfo {
    const mergedInfo = new MergedForwardInfo();
    
    mergedInfo.title = this.generateMergedTitle(messages);
    
    const abstractList: string[] = [];
    const maxAbstractCount = Math.min(messages.length, 4);
    for (let i = 0; i < maxAbstractCount; i++) {
      const msg = messages[i];
      const senderName: string = msg.from?.nickname || msg.from?.userID || '';
      const abstract = MessageUtils.getMessageAbstract(msg);
      const abstractStr = typeof abstract === 'string' ? abstract : TextUtils.getResourceString(abstract);
      abstractList.push(`${senderName}: ${abstractStr}`);
    }
    mergedInfo.abstractList = abstractList;
    
    mergedInfo.compatibleText = TextUtils.getResourceString($r('app.string.forward_compatible_text'));
    
    return mergedInfo;
  }

  private generateMergedTitle(messages: MessageInfo[]): string {
    const isGroupChat = this.conversationID.startsWith('group_');
    
    if (isGroupChat) {
      return TextUtils.getResourceString($r('app.string.forward_group_chat_history'));
    } else {
      const senderNames: string[] = [];
      const seenSenders: Set<string> = new Set();
      
      for (const message of messages) {
        const sender = message.from?.userID || '';
        if (sender && !seenSenders.has(sender)) {
          seenSenders.add(sender);
          const name = message.from?.nickname || sender;
          senderNames.push(name);
        }
        if (senderNames.length >= 2) {
          break;
        }
      }
      
      const andText = TextUtils.getResourceString($r('app.string.forward_and_text'));
      const historySuffix = TextUtils.getResourceString($r('app.string.forward_chat_history_c2c'));
      
      if (senderNames.length === 2) {
        return `${senderNames[0]}${andText}${senderNames[1]}${historySuffix}`;
      } else if (senderNames.length === 1) {
        return `${senderNames[0]}${historySuffix}`;
      } else {
        return TextUtils.getResourceString($r('app.string.forward_group_chat_history'));
      }
    }
  }

  // ============ Voice to Text Methods ============

  private handleConvertVoiceToText(message: MessageInfo) {
    if (!message || message.messageType !== MessageType.AUDIO) {
      return;
    }

    console.log(`[MessageList] 🎤 Starting voice to text conversion for message: ${message.msgID}`);

    this.asrDisplayManager.setConverting(message.msgID, true);
    this.asrDisplayManager.expand(message.msgID);

    const messageActionStore = MessageActionStore.create(message);
    messageActionStore.convertVoiceToText('', new CompletionHandlerAdapter(() => {
      console.log(`[MessageList] ✅ Voice to text conversion succeeded`);
      this.asrDisplayManager.setConverting(message.msgID, false);

      const audioPayload = message.messagePayload as AudioMessagePayload | undefined;
      const asrText = audioPayload?.asrText ?? '';
      if (asrText.length === 0) {
        console.log(`[MessageList] ⚠️ asrText is empty after conversion`);
        Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
        this.asrDisplayManager.collapse(message.msgID);
      } else {
        this.scrollToBottomIfLastMessage(message);
      }
    }, (code: number, desc: string) => {
      console.error(`[MessageList] ❌ Voice to text conversion failed:`, code, desc);
      this.asrDisplayManager.setConverting(message.msgID, false);
      this.asrDisplayManager.collapse(message.msgID);

      Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
    }));
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
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.forwardDialogController.open();
  }

  private sendAsrTextToConversations(asrText: string, targetConversationIDs: string[]) {
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
          console.error(`[MessageList] ${failureCount}/${totalCount} ASR text sends failed`);
          Toast.info($r('app.string.forward_failed'), this.getUIContext());
        }
      }
    };

    for (const targetConversationID of targetConversationIDs) {
      const messageInputStore = MessageInputStore.create(targetConversationID);
      const payload = new TextSendMessagePayload(asrText);
      const option = new SendMessageOption();
      option.needReadReceipt = AppBuilderConfig.getInstance().enableReadReceipt ?? false;
      option.offlinePushInfo = this.createOfflinePushInfoForConversation(targetConversationID);

      messageInputStore.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
        successCount++;
        console.info(`[MessageList] ASR text sent to ${targetConversationID}`);
        onComplete();
      }, (code: number, desc: string) => {
        failureCount++;
        console.error(`[MessageList] Failed to send ASR text to ${targetConversationID}:`, code, desc);
        onComplete();
      }));
    }
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
    if (!message || message.messageType !== MessageType.TEXT) {
      return;
    }

    console.log(`[MessageList] 🌐 Starting text translation for message: ${message.msgID}`);

    this.translationDisplayManager.setTranslating(message.msgID, true);
    this.translationDisplayManager.expand(message.msgID);

    const textPayload = message.messagePayload as TextMessagePayload | undefined;
    const originalText = textPayload?.text ?? '';
    if (originalText.length === 0) {
      console.log(`[MessageList]  Original text is empty`);
      this.translationDisplayManager.setTranslating(message.msgID, false);
      return;
    }

    try {
      const atUserNames = await TranslationTextParser.getAtUserNames(message);
      console.log(`[MessageList]  @ user names:`, atUserNames);

      const splitResult = TranslationTextParser.splitTextByEmojiAndAtUsers(originalText, atUserNames ?? undefined);
      
      if (!splitResult) {
        console.log(`[MessageList]  Split result is null`);
        this.translationDisplayManager.setTranslating(message.msgID, false);
        this.translationDisplayManager.collapse(message.msgID);
        return;
      }

      const textArray = splitResult.text;
      const textIndexArray = splitResult.textIndex;
      const resultArray = splitResult.result;

      console.log(`[MessageList]  Split result - Text array:`, textArray);
      console.log(`[MessageList]  Split result - Text indices:`, textIndexArray);
      console.log(`[MessageList]  Split result - Full array:`, resultArray);

      if (textArray.length === 0 || textArray.every(text => text.trim().length === 0)) {
        console.log(`[MessageList]  No plain text to translate (only emojis/mentions)`);
        this.translationDisplayManager.setTranslating(message.msgID, false);
        this.translationDisplayManager.collapse(message.msgID);
        return;
      }

      const targetLanguage = AppBuilderConfig.getInstance().getTranslateTargetLanguage();
      console.log(`[MessageList]  Using target language: ${targetLanguage}`);
      console.log(`[MessageList]  Original text: ${originalText}`);
      console.log(`[MessageList]  Text fragments to translate:`, textArray);

      await new Promise<void>((resolve, reject) => {
        const messageActionStore = MessageActionStore.create(message);
        const completion = new CompletionHandlerAdapter(() => {
          resolve();
        }, (code: number, desc: string) => {
          reject(new Error(`translateText failed: ${code} ${desc}`));
        });
        messageActionStore.translateText(textArray, undefined, targetLanguage, completion);
      });

      console.log(`[MessageList]  Text translation succeeded`);
      this.translationDisplayManager.setTranslating(message.msgID, false);

      const latestMessage = this.messageListState?.messageList.find((item: MessageInfo) => item.msgID === message.msgID) ?? message;
      const latestTextPayload = latestMessage.messagePayload as TextMessagePayload | undefined;
      const fallbackTextPayload = message.messagePayload as TextMessagePayload | undefined;
      const translatedTextMap: Record<string, string> = {};
      latestTextPayload?.translatedText?.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });
      fallbackTextPayload?.translatedText?.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });

      console.log(`[MessageList]  Translation map:`, translatedTextMap);

      const translatedFullText = TranslationTextParser.replacedStringWithArray(
        resultArray,
        textIndexArray,
        translatedTextMap
      );

      if (!translatedFullText || translatedFullText.length === 0) {
        console.log(`[MessageList]  Reconstructed translated text is empty`);
        this.translationDisplayManager.collapse(message.msgID);
        Toast.info($r('app.string.messagelist_translate_failed'), this.getUIContext());
      } else {
        console.log(`[MessageList]  Final translated text: ${translatedFullText}`);
        
        if (latestTextPayload) {
          if (!latestTextPayload.translatedText) {
            latestTextPayload.translatedText = new Map<string, string>();
          }
          latestTextPayload.translatedText.set(originalText, translatedFullText);
        }
        this.refreshDataSource();
        const refreshIndex = this.messageDataSource.getIndex(message.msgID);
        if (refreshIndex >= 0) {
          this.messageDataSource.forceRefresh(refreshIndex);
        }
        this.scrollToBottomIfLastMessage(latestMessage);
      }
    } catch (error) {
      console.error(`[MessageList]  Text translation failed:`, error);
      this.translationDisplayManager.setTranslating(message.msgID, false);
      this.translationDisplayManager.collapse(message.msgID);
      
      Toast.info($r('app.string.messagelist_translate_failed'), this.getUIContext());
    }
  }

  private getTranslatedText(message: MessageInfo): string {
    const textPayload = message.messagePayload as TextMessagePayload | undefined;
    const translatedTextMapRaw = textPayload?.translatedText;
    const translatedTextMap: Record<string, string> = {};
    if (translatedTextMapRaw) {
      translatedTextMapRaw.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });
    }
    const originalText = textPayload?.text ?? '';
    if (originalText.length === 0) {
      return '';
    }
    const translated = translatedTextMap[originalText];
    if (translated && translated.length > 0) {
      return translated;
    }
    const splitResult = TranslationTextParser.splitTextByEmojiAndAtUsers(originalText, undefined);
    if (!splitResult) {
      return '';
    }
    const hasTranslatedFragment = splitResult.text.some((text: string) => translatedTextMap[text] !== undefined);
    if (!hasTranslatedFragment) {
      return '';
    }
    const replacedText = TranslationTextParser.replacedStringWithArray(
      splitResult.result,
      splitResult.textIndex,
      translatedTextMap
    );
    return replacedText ?? '';
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
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.forwardDialogController.open();
  }

  private sendTranslatedTextToConversations(translatedText: string, targetConversationIDs: string[]) {
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
          console.error(`[MessageList] ${failureCount}/${totalCount} translated text sends failed`);
          Toast.info($r('app.string.forward_failed'), this.getUIContext());
        }
      }
    };

    for (const targetConversationID of targetConversationIDs) {
      const messageInputStore = MessageInputStore.create(targetConversationID);
      const payload = new TextSendMessagePayload(translatedText);
      const option = new SendMessageOption();
      option.needReadReceipt = AppBuilderConfig.getInstance().enableReadReceipt ?? false;
      option.offlinePushInfo = this.createOfflinePushInfoForConversation(targetConversationID);

      messageInputStore.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
        successCount++;
        console.info(`[MessageList] ✅ Translated text sent to ${targetConversationID}`);
        onComplete();
      }, (code: number, desc: string) => {
        failureCount++;
        console.error(`[MessageList] ❌ Failed to send translated text to ${targetConversationID}:`, code, desc);
        onComplete();
      }));
    }
  }

  // MARK: - Offline Push Info Creation

  private createOfflinePushInfoForConversation(conversationID: string): OfflinePushInfo {
    const loginUserInfo = LoginStore.shared().state.loginUserInfo;
    const selfUserId = loginUserInfo?.userID ?? '';
    const selfName = loginUserInfo?.nickname ?? selfUserId;

    const isGroup = conversationID.startsWith('group_');
    const groupId = isGroup ? conversationID.substring(6) : '';

    let chatName: string | undefined = undefined;
    const conversationDataSource = this.conversationListStore?.state.conversationList;
    if (conversationDataSource) {
      const conversationCount = conversationDataSource.totalCount();
      for (let i = 0; i < conversationCount; i++) {
        const conversation = conversationDataSource.getData(i);
        if (conversation && conversation.conversationID === conversationID && conversation.title) {
          chatName = conversation.title;
          break;
        }
      }
    }

    const title = isGroup ? (chatName || groupId) : selfName;
    const description = '';

    const ext = this.createOfflinePushExtJson(
      isGroup,
      description,
      isGroup ? groupId : selfUserId,
      title,
      loginUserInfo?.avatarURL
    );

    const pushInfo = new OfflinePushInfo();
    pushInfo.title = title;
    pushInfo.description = this.trimPushDescription(description);
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

  private getMessageTypeAbstract(message: MessageInfo): string {
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

  /**
   * Trim push description to max length
   */
  private trimPushDescription(text: string, maxLength: number = 50): string {
    if (typeof text !== 'string') {
      return '';
    }
    const normalized = text.trim().replace(/\n/g, ' ').replace(/\r/g, ' ');
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  /**
   * Create offline push ext JSON
   */
  private createOfflinePushExtJson(
    isGroup: boolean,
    description: string,
    senderId: string,
    senderNickName: string,
    faceUrl?: string
  ): string {
    interface BusinessInfo {
      content: string;
      sender: string;
      nickname: string;
      chatType: number;
      faceUrl?: string;
    }

    const businessInfo: BusinessInfo = {
      content: description,
      sender: senderId,
      nickname: senderNickName,
      chatType: isGroup ? 2 : 1
    };

    if (faceUrl) {
      businessInfo.faceUrl = faceUrl;
    }

    interface ConfigInfo {
      fcmPushType: number;
      fcmNotificationType: number;
    }

    const configInfo: ConfigInfo = {
      fcmPushType: 0,
      fcmNotificationType: 0
    };

    interface ExtJson {
      entity: BusinessInfo;
      timPushFeatures: ConfigInfo;
    }

    const extJson: ExtJson = {
      entity: businessInfo,
      timPushFeatures: configInfo
    };

    return JSON.stringify(extJson);
  }

  // ============ Classic Popup Action Methods ============

  private handlePopupCopy(message: MessageInfo) {
    const textPayload = message.messagePayload as TextMessagePayload | undefined;
    const messageContent = textPayload?.text ?? '';
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