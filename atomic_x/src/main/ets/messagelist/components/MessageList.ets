import {
  LoginStore,
  MessageListStore,
  MessageInfo,
  MessageType,
  MessageListType,
  MessageFetchOption,
  MessageFetchDirection,
  ErrorInfo,
  MessageEvent,
  MessageActionStore,
  MessageStatus,
  MessageDataSource,
  MessageListState,
  ConversationListStore,
  ConversationListState,
  ConversationInfo,
  ConversationMarkType,
  MessageInputStore,
  MessageForwardType,
  MessageForwardOption,
  MergedForwardInfo,
  MessageBody,
  OfflinePushInfo
} from '@tencentcloud/atomicxcore';
import { AppBuilderConfig, ThemeState, TextUtils, ActionItem, Toast, EventBus } from '../../basecomponent/Index';
import { MessageItem } from '../ui/MessageItem';
import { MessageActionDialog } from '../ui/MessageActionPanel';
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
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';
import pasteboard from '@ohos.pasteboard';

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
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State messageListStore?: MessageListStore = undefined;
  @State conversationListStore?: ConversationListStore = undefined;
  @State messageListState?: MessageListState = undefined;
  @State messageDataSource?: MessageDataSource = undefined;
  @State isLoading: boolean = true;
  @State isLoadingMore: boolean = false;
  @State lastFirstIndex: number = -1;
  @State userScrolling: boolean = false;
  @Watch('onSelectedMessageChanged')
  @State selectedMessage?: MessageInfo = undefined;
  // Multi-select mode states
  @State isMultiSelectMode: boolean = false;
  @State selectedMessageIDs: Set<string> = new Set();
  // Forward type selection state
  @State private forwardType: MessageForwardType = MessageForwardType.separate;
  dialogController: CustomDialogController | null = null;
  forwardDialogController: CustomDialogController | null = null;
  forwardTypeDialogController: CustomDialogController | null = null;
  readReceiptDialogController: CustomDialogController | null = null;
  emojiPickerController: CustomDialogController | null = null;
  conversationID: string = '';
  @Prop locateMessage?: MessageInfo = undefined;
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
  private currentLoadDirection: number = MessageFetchDirection.Older;
  private isLoadingAroundTargetMessage: boolean = false;
  private lastScrollToBottomTime: number = 0;
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();

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
  }

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    console.info(`[MessageList] aboutToAppear with conversationID: ${this.conversationID}, locateMessage: ${this.locateMessage?.ID ||
      'none'}`);
    
    if (this.conversationID) {
      this.loadMessages();
      this.clearMessageUnreadCount();
    } else {
      console.error('[MessageList] No valid conversationID provided');
      this.isLoading = false;
    }
  }

  loadMessages() {
    this.isLoading = true;
    this.messageListStore = MessageListStore.create(this.conversationID, MessageListType.history);
    this.messageListState = this.messageListStore.state;
    this.messageDataSource = this.messageListState.messageDataSource;

    // Subscribe to message events (with WeakRef to this component)
    this.messageListStore.messageEventEmitter.subscribe(this, (event: MessageEvent) => {
      this.handleMessageEvent(event);
    });

    this.conversationListStore = ConversationListStore.create();

    if (this.locateMessage) {
      this.loadMessagesAroundTargetMessage();
    } else {
      this.loadHistoryMessages();
    }
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
        (this.selectedMessage.status === MessageStatus.recalled || this.selectedMessage.status === MessageStatus.violation)) {
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
      this.conversationListStore?.markConversation([this.conversationID], ConversationMarkType.UNREAD, false);
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

      const index = this.messageListState.messageDataSource.getIndex(msgId);

      if (index !== -1) {
        const message = this.messageListState.messageDataSource.getData(index);
        if (message) {

          MessageActionStore.create(message).deleteMessage()
            .then(() => {
              Toast.info($r('app.string.messagelist_message_deleted'), this.getUIContext());
            })
            .catch((error: ErrorInfo) => {
              Toast.info($r('app.string.messagelist_delete_message_failed'), this.getUIContext());
            });
        }
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
      const index = this.messageListState.messageDataSource.getIndex(msgId);
      if (index !== -1) {
        const message = this.messageListState.messageDataSource.getData(index);
        if (message) {
          if (!message.isSelf) {
            Toast.info($r('app.string.messagelist_recall_only_own'), this.getUIContext());
            return;
          }
          MessageActionStore.create(message).recallMessage()
            .then(() => {
              Toast.info($r('app.string.message_tips_normal_recall'), this.getUIContext());
            })
            .catch((error: ErrorInfo) => {
              Toast.info($r('app.string.messagelist_recall_failed'), this.getUIContext());
            });
        }
      } else {
        Toast.info($r('app.string.messagelist_recall_failed_not_found'), this.getUIContext());
      }
    } catch (error) {
      Toast.info($r('app.string.messagelist_recall_failed'), this.getUIContext());
    }
  }

  loadMoreHistoryMessages() {
    this.loadMoreMessages(MessageFetchDirection.Older);
  }

  loadMoreNewerMessages() {
    this.loadMoreMessages(MessageFetchDirection.Newer);
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
            isSelected: this.selectedMessageIDs.has(message.ID),
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
            // Forward ASR text
            const asrText = message.messageBody?.asrText ?? '';
            if (asrText.length > 0) {
              this.forwardAsrText(asrText);
            }
          },
          onTranslationBubbleLongPress: (message: MessageInfo) => {
            // Forward translated text
            const translatedTextMapRaw = message.messageBody?.translatedText;
            const translatedTextMap: Record<string, string> = {};
            if (translatedTextMapRaw) {
              translatedTextMapRaw.forEach((value: string, key: string) => {
                translatedTextMap[key] = value;
              });
            }
            const originalText = message.messageBody?.text ?? '';
            const translatedText = translatedTextMap[originalText] ?? '';
            if (translatedText.length > 0) {
              this.forwardTranslatedText(translatedText);
            }
          },
          // Classic popup style callbacks
          onCopy: (msg: MessageInfo) => {
            this.handlePopupCopy(msg);
          },
          onRecall: (msg: MessageInfo) => {
            this.recallMessage(msg.ID);
          },
          onDelete: (msg: MessageInfo) => {
            this.handleMessageDeleted(msg.ID);
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
    return `${message.ID}_${MessageUtils.getMessageStateHash(message)}_${index}`;
  }

  /**
   * Determine if avatar should be shown for a message
   * Based on style configuration and message position
   */
  private shouldShowAvatar(message: MessageInfo, index: number): boolean {
    // In classic UI mode, always show avatars for both sender and receiver
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return true;
    }
    
    if (message.isSelf) {
      // For self messages, check right avatar configuration
      return this.effectiveConfig.isShowRightAvatar ?? false;
    } else {
      // For other messages, check left avatar configuration
      const showLeftAvatar = this.effectiveConfig.isShowLeftAvatar ?? true;
      // Only show if configured and not aggregated with next message
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
      Column() {

        if (this.isLoadingMore && this.currentLoadDirection === MessageFetchDirection.Older) {
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
          initialIndex: (this.messageListState?.messageDataSource.totalCount() ?? 1) - 1
        }) {
          LazyForEach(this.messageListState.messageDataSource, (message: MessageInfo, index: number) => {
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


          if (this.messageListState?.hasMoreOlderMessage &&
            !this.isLoadingMore &&
            this.messageListState?.messageDataSource.totalCount() > 0 &&
            !this.isLoadingAroundTargetMessage) {


            this.messageCountBeforeLoad = this.messageListState.messageDataSource.totalCount();
            this.scrollPositionBeforeLoad = this.scroller.currentOffset().yOffset;
            this.currentLoadDirection = MessageFetchDirection.Older;

            console.info('[MessageList] Loading more history messages from onReachStart', {
              messageCountBefore: this.messageCountBeforeLoad,
              scrollPositionBefore: this.scrollPositionBeforeLoad
            });

            this.loadMoreHistoryMessages();
          } else {
            console.info('[MessageList] Cannot load more messages:', {
              hasMoreOlderMessage: this.messageListState?.hasMoreOlderMessage,
              isLoadingMore: this.isLoadingMore,
              messageCount: this.messageListState?.messageDataSource.totalCount()
            });
          }
        })
        .onReachEnd(() => {
          console.info('[MessageList] Reached end of list');

          // Skip loading if just scrolled to bottom (within 500ms)
          // This prevents auto-loading when sending/receiving messages
          const timeSinceLastScroll = Date.now() - this.lastScrollToBottomTime;
          if (timeSinceLastScroll < 500) {
            console.info('[MessageList] Skip loading on onReachEnd - just scrolled to bottom');
            return;
          }

          if (this.messageListState?.hasMoreNewerMessage &&
            !this.isLoadingMore &&
            this.messageListState?.messageDataSource.totalCount() > 0 &&
            !this.isLoadingAroundTargetMessage) {

            this.messageCountBeforeLoad = this.messageListState.messageDataSource.totalCount();
            this.scrollPositionBeforeLoad = this.scroller.currentOffset().yOffset;
            this.currentLoadDirection = MessageFetchDirection.Newer;

            console.info('[MessageList] Loading more newer messages from onReachEnd', {
              messageCountBefore: this.messageCountBeforeLoad,
              scrollPositionBefore: this.scrollPositionBeforeLoad
            });

            this.loadMoreNewerMessages();
          } else {
            console.info('[MessageList] Cannot load more newer messages from onReachEnd:', {
              hasMoreNewerMessage: this.messageListState?.hasMoreNewerMessage,
              isLoadingMore: this.isLoadingMore,
              messageCount: this.messageListState?.messageDataSource.totalCount()
            });
          }
        })
        .onScrollIndex((firstIndex: number) => {

          console.info(`[MessageList] Scroll index changed: ${firstIndex}, last: ${this.lastFirstIndex}, userScrolling: ${this.userScrolling}`);


          this.lastFirstIndex = firstIndex;
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
          // Post event to dismiss keyboard when clicking on message list blank area
          console.log('[MessageList] 📤 Posting onBlankAreaClick event');
          const eventData: Record<string, Object> = {};
          eventData['source'] = 'MessageList';
          eventData['event'] = 'onBlankAreaClick';
          EventBus.getInstance().post('onBlankAreaClick', eventData);
        })


        if (this.isLoadingMore && this.currentLoadDirection === MessageFetchDirection.Newer) {
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
    }
  }

  scrollToBottom() {
    this.lastScrollToBottomTime = Date.now();
    setTimeout(() => {
      this.scroller?.scrollEdge(Edge.End);
    }, 100);
  }

  locateToMessage(messageID: string) {
    if (!this.messageListState || !messageID) {


      if (this.isLoadingAroundTargetMessage) {
        this.isLoadingAroundTargetMessage = false;
        console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (invalid params)`);
      }
      return;
    }


    const messageIndex = this.messageListState.messageDataSource.getIndex(messageID);

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
    if (!this.messageListState?.messageDataSource || currentIndex <= 0) {
      return undefined;
    }

    return this.messageDataSource?.getData(currentIndex - 1) as MessageInfo;
  }

  private getNextMessage(currentIndex: number): MessageInfo | undefined {
    if (!this.messageDataSource ||
      currentIndex >= this.messageDataSource?.totalCount() - 1) {
      return undefined;
    }

    return this.messageDataSource?.getData(currentIndex + 1) as MessageInfo;
  }

  private checkPreviousMessageIsAggregation(currentIndex: number): boolean {
    // In classic UI mode, disable message aggregation (always show full spacing and avatars)
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return false;
    }
    
    const message = this.messageListState?.messageDataSource.getData(currentIndex);
    const prevMessage = this.getPreviousMessage(currentIndex);

    if (!message || !prevMessage) {
      return false;
    }


    if (message.isSelf !== prevMessage.isSelf) {
      return false;
    }


    if (prevMessage.status === MessageStatus.recalled) {
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
    // In classic UI mode, disable message aggregation (always show full spacing and avatars)
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return false;
    }
    
    const message = this.messageListState?.messageDataSource.getData(currentIndex);
    const nextMessage = this.getNextMessage(currentIndex);

    if (!message || !nextMessage) {
      return false;
    }


    if (message.isSelf !== nextMessage.isSelf) {
      return false;
    }


    if (nextMessage.status === MessageStatus.recalled) {
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
    const message = this.messageListState?.messageDataSource.getData(currentIndex);

    if (!message || !message.timestamp) {
      return null;
    }


    if (!message.timestamp || message.timestamp === 0 || message.timestamp < 0 ||
    isNaN(message.timestamp)) {
      console.warn(`[MessageList] Invalid message dateTime: ${message.timestamp}, messageID: ${message.ID}`);
      return null;
    }


    if (currentIndex === 0) {
      console.info(`[MessageList] First message, showing time for message ${message.ID}`);
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

    const option: MessageFetchOption = {
      direction: MessageFetchDirection.Older,
      pageCount: 20
    };

    this.messageListStore!.fetchMessageList(option)
      .then(() => {
        this.isLoading = false;

        if (this.locateMessage?.ID) {
          this.locateToMessage(this.locateMessage.ID);
        }
      })
      .catch((error: ErrorInfo) => {
        this.isLoading = false;

      });
  }

  private loadMessagesAroundTargetMessage() {
    if (!this.locateMessage) {

      this.loadHistoryMessages();
      return;
    }


    this.isLoadingAroundTargetMessage = true;
    console.info(`[MessageList] Set isLoadingAroundTargetMessage = true`);


    const option: MessageFetchOption = {
      message: this.locateMessage,
      pageCount: 20
    };

    this.messageListStore!.fetchMessageList(option)
      .then(() => {

        if (this.locateMessage?.ID) {
          const targetMessageID = this.locateMessage.ID;
          setTimeout(() => {
            this.locateToMessage(targetMessageID);
            this.isLoading = false;
          }, 100);
        } else {
          this.isLoading = false;

          this.isLoadingAroundTargetMessage = false;
          console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (no locateMessage)`);
        }
      })
      .catch((error: ErrorInfo) => {
        this.isLoading = false;

        this.isLoadingAroundTargetMessage = false;
        console.info(`[MessageList] Reset isLoadingAroundTargetMessage = false (error case)`);


        this.loadHistoryMessages();
      });
  }

  private loadMoreMessages(direction: number) {
    const isOlder = direction === MessageFetchDirection.Older;
    const directionName = isOlder ? 'history' : 'newer';

    console.info(`[MessageList] loadMore${isOlder ? 'History' : 'Newer'}Messages called - checking conditions`);

    if (!this.messageListStore || !this.messageListState || this.isLoadingMore) {
      console.info(`[MessageList] Skip loading more ${directionName} messages - already loading`);
      return;
    }


    const hasMoreMessages = isOlder ?
    this.messageListState.hasMoreOlderMessage :
    this.messageListState.hasMoreNewerMessage;

    if (!hasMoreMessages) {
      console.info(`[MessageList] No more ${directionName} messages available`);
      return;
    }

    console.info(`[MessageList] Loading more ${directionName} messages...`);
    this.isLoadingMore = true;

    this.currentLoadDirection = direction;

    this.messageListStore.fetchMoreMessageList(direction)
      .then(() => {
        console.info(`[MessageList] Successfully loaded more ${directionName} messages, count:`,
          this.messageListState?.messageDataSource.totalCount());
        this.isLoadingMore = false;
      })
      .catch((error: ErrorInfo) => {

        this.isLoadingMore = false;

      });
  }

  private handleMessageEvent(event: MessageEvent) {
    switch (event.type) {
      case 'fetchMessages':
        // Fetch reactions for initially loaded messages
        this.fetchMessageReactions(event.messageList || []);
        break;
      case 'sendMessage':
        this.scrollToBottom();
        break;
      case 'recvMessage':
        // Fetch reactions for new received message
        if (event.message) {
          this.fetchMessageReactions([event.message]);
        }
        this.scrollToBottom();
        break;
      case 'fetchMoreMessages':
        // Fetch reactions for newly loaded messages
        this.fetchMessageReactions(event.messageList || []);
        this.restoreScrollPosition();
        break;
      case 'deleteMessages':
        break;
      default:
        break;
    }
  }

  private fetchMessageReactions(messages: MessageInfo[]) {
    if (!this.effectiveConfig.isSupportReaction || !this.messageListStore) {
      return;
    }
    
    if (messages.length === 0) {
      return;
    }

    // Fetch reactions with max 3 users per reaction
    this.messageListStore.fetchMessageReactions(messages, 3);
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

    const currentMessageCount = this.messageListState?.messageDataSource.totalCount() ?? 0;
    const newMessagesCount = currentMessageCount - this.messageCountBeforeLoad;

    console.info('[MessageList] Restoring scroll position:', {
      messageCountBefore: this.messageCountBeforeLoad,
      currentMessageCount: currentMessageCount,
      newMessagesCount: newMessagesCount,
      scrollPositionBefore: this.scrollPositionBeforeLoad,
      loadDirection: this.currentLoadDirection === MessageFetchDirection.Older ? 'older' : 'newer'
    });

    if (newMessagesCount > 0) {
      if (this.currentLoadDirection === MessageFetchDirection.Older) {

        console.info('[MessageList] Restoring position after loading older messages');
        this.scroller.scrollToIndex(newMessagesCount, false, ScrollAlign.START);
        console.info(`[MessageList] Scrolled to index ${newMessagesCount} to maintain position`);
      } else {

        console.info('[MessageList] Restoring position after loading newer messages');

        const targetIndex = this.messageCountBeforeLoad - 1;
        if (targetIndex >= 0 && targetIndex < (this.messageListState?.messageDataSource.totalCount() ?? 0)) {
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

    if (!message || message.isSelf) {
      return;
    }

    if (!message.needReadReceipt) {
      return;
    }

    if (message.status !== MessageStatus.sendSuccess) {
      return;
    }

    if (message.messageType === MessageType.System) {
      return;
    }

    const messageID = message.msgID || message.ID;
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
      const index = this.messageListState!.messageDataSource.getIndex(id);
      if (index !== -1) {
        const msg = this.messageListState!.messageDataSource.getData(index);
        if (msg && msg.rawMessage) {
          messages.push(msg);
          messageIDsToSend.push(id);
        }
      }
    });

    if (messages.length === 0) {
      return;
    }

    this.messageListStore.sendMessageReadReceipts(messages)
      .then(() => {
        messageIDsToSend.forEach((id: string) => {
          this.sentReceiptMessageIDs.add(id);
          this.pendingReceiptMessageIDs.delete(id);
        });
      })
      .catch((error: ErrorInfo) => {
        console.error('[MessageList] sendMessageReadReceipts failed:', error.code, error.message);
      });
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
    
    if (existingReaction && (existingReaction.reactedByMyself ?? false)) {
      // Remove reaction if already reacted
      messageActionStore.removeMessageReaction(reactionID)
        .then(() => {
          Toast.info($r('app.string.messagelist_reaction_removed'), this.getUIContext());
        })
        .catch((error: ErrorInfo) => {
          console.error('[MessageList] Failed to remove reaction:', error);
        });
    } else {
      // Add reaction
      messageActionStore.addMessageReaction(reactionID)
        .then(() => {
          Toast.info($r('app.string.messagelist_reaction_added'), this.getUIContext());
        })
        .catch((error: ErrorInfo) => {
          console.error('[MessageList] Failed to add reaction:', error);
        });
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

  /**
   * Check if a message can be selected in multi-select mode
   * Note: Failed and violation messages can be selected (for deletion)
   * but will be filtered out when forwarding
   */
  private canSelectMessage(message: MessageInfo): boolean {
    // Cannot select recalled messages
    if (message.status === MessageStatus.recalled) {
      return false;
    }
    // Cannot select system messages
    if (message.messageType === MessageType.System) {
      return false;
    }
    // Cannot select custom/tips messages
    if (message.messageType === MessageType.Custom) {
      return false;
    }
    return true;
  }

  /**
   * Validate selected messages for forwarding
   * @returns true if all messages can be forwarded, false otherwise
   */
  private validateMessagesForForward(): boolean {
    const selectedMessages = this.getSelectedMessages();
    
    // Check for failed messages
    const hasFailedMessages = selectedMessages.some(msg => msg.status === MessageStatus.sendFail);
    if (hasFailedMessages) {
      Toast.error($r('app.string.forward_failed_message_tip'), this.getUIContext());
      return false;
    }
    
    // Check for violation messages
    const hasViolationMessages = selectedMessages.some(msg => msg.status === MessageStatus.violation);
    if (hasViolationMessages) {
      Toast.error($r('app.string.forward_violation_message_tip'), this.getUIContext());
      return false;
    }
    
    return true;
  }

  /**
   * Toggle selection state of a message
   */
  private toggleMessageSelection(message: MessageInfo) {
    if (!this.canSelectMessage(message)) {
      return;
    }
    
    if (this.selectedMessageIDs.has(message.ID)) {
      this.selectedMessageIDs.delete(message.ID);
    } else {
      this.selectedMessageIDs.add(message.ID);
    }
    // Trigger UI update
    this.selectedMessageIDs = new Set(this.selectedMessageIDs);
    // Notify parent about selection change
    this.notifyMultiSelectModeChange();
  }

  /**
   * Get selected messages sorted by timestamp
   */
  private getSelectedMessages(): MessageInfo[] {
    if (!this.messageListState?.messageDataSource) {
      return [];
    }
    
    const selectedMessages: MessageInfo[] = [];
    const totalCount = this.messageListState.messageDataSource.totalCount();
    
    for (let i = 0; i < totalCount; i++) {
      const message = this.messageListState.messageDataSource.getData(i) as MessageInfo;
      if (message && this.selectedMessageIDs.has(message.ID)) {
        selectedMessages.push(message);
      }
    }
    
    // Sort by timestamp
    return selectedMessages.sort((a, b) => (a.timestamp ?? 0) - (b.timestamp ?? 0));
  }

  /**
   * Delete selected messages
   */
  deleteSelectedMessages() {
    const selectedMessages = this.getSelectedMessages();
    if (selectedMessages.length === 0) {
      return;
    }
    
    // Use batch delete API
    this.messageListStore?.deleteMessages(selectedMessages)
      .then(() => {
        Toast.info($r('app.string.messagelist_messages_deleted'), this.getUIContext());
        this.exitMultiSelectMode();
      })
      .catch((error: ErrorInfo) => {
        console.error('[MessageList] Failed to delete messages:', error);
        Toast.info($r('app.string.messagelist_delete_message_failed'), this.getUIContext());
      });
  }

  /**
   * Cancel multi-select mode (public method for parent component)
   */
  cancelMultiSelect() {
    this.exitMultiSelectMode();
  }

  // ============ Forward Methods ============

  /**
   * Handle forwarding a single message (from action menu)
   */
  private handleForwardSingleMessage(message: MessageInfo) {
    // For single message forward, directly show forward target selector without entering multi-select mode
    // Set default forward type to separate
    this.forwardType = MessageForwardType.separate;
    
    // Store the message to forward
    this.selectedMessageIDs = new Set([message.ID]);
    
    // Show forward target selector directly
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

  /**
   * Forward selected messages to multiple target conversations
   * Loops through each conversation and calls forwardMessages API
   */
  private forwardMessagesToConversations(targetConversationIDs: string[]) {
    const selectedMessages = this.getSelectedMessages();
    if (selectedMessages.length === 0 || targetConversationIDs.length === 0) {
      // Clear selection if not in multi-select mode
      if (!this.isMultiSelectMode) {
        this.selectedMessageIDs.clear();
      } else {
        this.exitMultiSelectMode();
      }
      return;
    }
    
    console.info(`[MessageList] Forwarding ${selectedMessages.length} messages to ${targetConversationIDs.length} conversations, type: ${this.forwardType}`);
    
    // Build forward option
    const forwardOption = new MessageForwardOption();
    forwardOption.forwardType = this.forwardType;
    
    if (this.forwardType === MessageForwardType.merged) {
      // Generate merged forward info
      forwardOption.mergedForwardInfo = this.generateMergedForwardInfo(selectedMessages);
    }
    
    // Exit multi-select mode only if we're actually in it
    if (this.isMultiSelectMode) {
      this.exitMultiSelectMode();
    } else {
      // Clear temporary selection for single message forward
      this.selectedMessageIDs.clear();
    }
    
    // Forward to each conversation sequentially
    const forwardPromises: Promise<void>[] = [];
    for (const targetConversationID of targetConversationIDs) {
      const promise = this.messageListStore?.forwardMessages(selectedMessages, forwardOption, targetConversationID)
        .then(() => {
          console.info(`[MessageList] Forward to ${targetConversationID} succeeded`);
        })
        .catch((error: ErrorInfo) => {
          console.error(`[MessageList] Forward to ${targetConversationID} failed:`, error);
          throw error;
        });
      if (promise) {
        forwardPromises.push(promise);
      }
    }
    
    // Wait for all forwards to complete (in background)
    Promise.all(forwardPromises)
      .then(() => {
        Toast.success($r('app.string.forward_success'), this.getUIContext());
      })
      .catch((error: ErrorInfo) => {
        console.error('[MessageList] Some forwards failed:', error);
        Toast.info($r('app.string.forward_failed'), this.getUIContext());
      });
  }

  /**
   * Generate merged forward info from selected messages
   */
  private generateMergedForwardInfo(messages: MessageInfo[]): MergedForwardInfo {
    const mergedInfo = new MergedForwardInfo();
    
    // Generate title based on conversation type
    mergedInfo.title = this.generateMergedTitle(messages);
    
    // Generate abstract list (up to 4 messages)
    const abstractList: string[] = [];
    const maxAbstractCount = Math.min(messages.length, 4);
    for (let i = 0; i < maxAbstractCount; i++) {
      const msg = messages[i];
      const senderName: string = msg.sender?.nickname || msg.sender?.userID || '';
      const abstract = MessageUtils.getMessageAbstract(msg);
      const abstractStr = typeof abstract === 'string' ? abstract : TextUtils.getResourceString(abstract);
      abstractList.push(`${senderName}: ${abstractStr}`);
    }
    mergedInfo.abstractList = abstractList;
    
    // Compatible text for older clients
    mergedInfo.compatibleText = TextUtils.getResourceString($r('app.string.forward_compatible_text'));
    
    // Set needReadReceipt to true for merged messages
    mergedInfo.needReadReceipt = true;
    
    return mergedInfo;
  }

  /**
   * Generate merged forward message title based on conversation type
   * Returns formatted string directly (matches Kotlin implementation)
   */
  private generateMergedTitle(messages: MessageInfo[]): string {
    // Check if it's a group chat (conversationID starts with "group_")
    const isGroupChat = this.conversationID.startsWith('group_');
    
    if (isGroupChat) {
      return TextUtils.getResourceString($r('app.string.forward_group_chat_history'));
    } else {
      // C2C chat: collect unique senders in order of appearance
      const senderNames: string[] = [];
      const seenSenders: Set<string> = new Set();
      
      for (const message of messages) {
        const sender = message.sender?.userID || '';
        if (sender && !seenSenders.has(sender)) {
          seenSenders.add(sender);
          // Use nickname, fallback to sender ID
          const name = message.sender?.nickname || sender;
          senderNames.push(name);
        }
        // Only need at most 2 senders for C2C
        if (senderNames.length >= 2) {
          break;
        }
      }
      
      // Build title using localized strings (like Kotlin)
      const andText = TextUtils.getResourceString($r('app.string.forward_and_text')); // "和" / "and" / "و"
      const historySuffix = TextUtils.getResourceString($r('app.string.forward_chat_history_c2c')); // "的聊天记录" / "'s Chat History"
      
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

  /**
   * Handle convert voice to text action
   * Called when user clicks "Convert to Text" in message action menu
   */
  private handleConvertVoiceToText(message: MessageInfo) {
    if (!message || message.messageType !== MessageType.Sound) {
      return;
    }

    console.log(`[MessageList] 🎤 Starting voice to text conversion for message: ${message.msgID}`);

    // Set converting state
    this.asrDisplayManager.setConverting(message.msgID, true);
    this.asrDisplayManager.expand(message.msgID);

    // Call API
    const messageActionStore = MessageActionStore.create(message);
    messageActionStore.convertVoiceToText('')
      .then(() => {
        console.log(`[MessageList] ✅ Voice to text conversion succeeded`);
        this.asrDisplayManager.setConverting(message.msgID, false);

        // Check if asrText is empty after conversion
        const asrText = message.messageBody?.asrText ?? '';
        if (asrText.length === 0) {
          console.log(`[MessageList] ⚠️ asrText is empty after conversion`);
          Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
          this.asrDisplayManager.collapse(message.msgID);
        } else {
          // Scroll to bottom if this is the last message
          this.scrollToBottomIfLastMessage(message);
        }
      })
      .catch((error: ErrorInfo) => {
        console.error(`[MessageList] ❌ Voice to text conversion failed:`, error);
        this.asrDisplayManager.setConverting(message.msgID, false);
        this.asrDisplayManager.collapse(message.msgID);

        Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
      });
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

  /**
   * Send ASR text as text message to selected conversations
   */
  private sendAsrTextToConversations(asrText: string, targetConversationIDs: string[]) {
    if (targetConversationIDs.length === 0) {
      return;
    }

    const sendPromises: Promise<void>[] = [];

    for (const targetConversationID of targetConversationIDs) {
      const messageInputStore = MessageInputStore.create(targetConversationID);
      
      const message = new MessageInfo();
      message.messageType = MessageType.Text;
      const body = new MessageBody();
      body.text = asrText;
      message.messageBody = body;

      // Create offline push info for forwarding
      message.offlinePushInfo = this.createOfflinePushInfoForConversation(targetConversationID, message);

      const promise: Promise<void> = messageInputStore.sendMessage(message)
        .then(() => {
          console.info(`[MessageList] ASR text sent to ${targetConversationID}`);
        })
        .catch((error: ErrorInfo) => {
          console.error(`[MessageList] Failed to send ASR text to ${targetConversationID}:`, error);
          throw error;
        });
      sendPromises.push(promise);
    }

    Promise.all(sendPromises)
      .then(() => {
        Toast.success($r('app.string.forward_success'), this.getUIContext());
      })
      .catch((error: ErrorInfo) => {
        console.error('[MessageList] Some ASR text sends failed:', error);
        Toast.info($r('app.string.forward_failed'), this.getUIContext());
      });
  }

  /**
   * Scroll to bottom if the given message is the last message
   */
  private scrollToBottomIfLastMessage(message: MessageInfo) {
    if (!this.messageListState?.messageDataSource) {
      return;
    }

    const totalCount = this.messageListState.messageDataSource.totalCount();
    if (totalCount === 0) {
      return;
    }

    const lastMessage = this.messageListState.messageDataSource.getData(totalCount - 1) as MessageInfo;
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

  /**
   * Handle translate text message action
   * Called when user clicks "Translate" in message action menu
   */
  private async handleTranslateText(message: MessageInfo) {
    if (!message || message.messageType !== MessageType.Text) {
      return;
    }

    console.log(`[MessageList] 🌐 Starting text translation for message: ${message.msgID}`);

    // Set translating state
    this.translationDisplayManager.setTranslating(message.msgID, true);
    this.translationDisplayManager.expand(message.msgID);

    // Get original text
    const originalText = message.messageBody?.text ?? '';
    if (originalText.length === 0) {
      console.log(`[MessageList]  Original text is empty`);
      this.translationDisplayManager.setTranslating(message.msgID, false);
      return;
    }

    try {
      // Get @ user names from message
      const atUserNames = await TranslationTextParser.getAtUserNames(message);
      console.log(`[MessageList]  @ user names:`, atUserNames);

      // Split text by emoji and @ users
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

      // If no plain text to translate (only emojis/mentions), don't call translation API
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
      
      const messageActionStore = MessageActionStore.create(message);
      await messageActionStore.translateText(textArray, undefined, targetLanguage);

      console.log(`[MessageList]  Text translation succeeded`);
      this.translationDisplayManager.setTranslating(message.msgID, false);

      // Convert Map to Record
      const translatedTextMapRaw = message.messageBody?.translatedText;
      const translatedTextMap: Record<string, string> = {};
      if (translatedTextMapRaw) {
        translatedTextMapRaw.forEach((value: string, key: string) => {
          translatedTextMap[key] = value;
        });
      }

      console.log(`[MessageList]  Translation map:`, translatedTextMap);

      // Reconstruct translated text with emoji and @ mentions
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
        
        // Update translation map with the full text (for display)
        if (message.messageBody && message.messageBody.translatedText) {
          message.messageBody.translatedText.set(originalText, translatedFullText);
        }
        
        // Scroll to bottom if this is the last message
        this.scrollToBottomIfLastMessage(message);
      }
    } catch (error) {
      console.error(`[MessageList]  Text translation failed:`, error);
      this.translationDisplayManager.setTranslating(message.msgID, false);
      this.translationDisplayManager.collapse(message.msgID);
      
      Toast.info($r('app.string.messagelist_translate_failed'), this.getUIContext());
    }
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

  /**
   * Send translated text as text message to selected conversations
   */
  private sendTranslatedTextToConversations(translatedText: string, targetConversationIDs: string[]) {
    if (targetConversationIDs.length === 0) {
      return;
    }

    const sendPromises: Promise<void>[] = [];

    for (const targetConversationID of targetConversationIDs) {
      const messageInputStore = MessageInputStore.create(targetConversationID);
      
      const message = new MessageInfo();
      message.messageType = MessageType.Text;
      const body = new MessageBody();
      body.text = translatedText;
      message.messageBody = body;

      // Create offline push info for forwarding
      message.offlinePushInfo = this.createOfflinePushInfoForConversation(targetConversationID, message);

      const promise: Promise<void> = messageInputStore.sendMessage(message)
        .then(() => {
          console.info(`[MessageList] ✅ Translated text sent to ${targetConversationID}`);
        })
        .catch((error: ErrorInfo) => {
          console.error(`[MessageList] ❌ Failed to send translated text to ${targetConversationID}:`, error);
          throw error;
        });
      sendPromises.push(promise);
    }

    Promise.all(sendPromises)
      .then(() => {
        Toast.success($r('app.string.forward_success'), this.getUIContext());
      })
      .catch((error: ErrorInfo) => {
        console.error('[MessageList] Some translated text sends failed:', error);
        Toast.info($r('app.string.forward_failed'), this.getUIContext());
      });
  }

  // MARK: - Offline Push Info Creation

  /**
   * Create offline push info for forwarding messages
   * Reference: Android Compose & iOS SwiftUI implementation
   */
  private createOfflinePushInfoForConversation(conversationID: string, message: MessageInfo): OfflinePushInfo {
    const loginUserInfo = LoginStore.shared().state?.loginUserInfo;
    const selfUserId = loginUserInfo?.userID ?? '';
    const selfName = loginUserInfo?.nickname ?? selfUserId;

    const isGroup = conversationID.startsWith('group_');
    const groupId = isGroup ? conversationID.substring(6) : '';

    // Get conversation title from conversationListStore
    let chatName: string | undefined = undefined;
    const conversationDataSource = this.conversationListStore?.state.conversationDataSource;
    if (conversationDataSource) {
      const conversationCount = conversationDataSource.totalCount();
      for (let i = 0; i < conversationCount; i++) {
        const conversation = conversationDataSource.getData(i);
        if (conversation && conversation.ID === conversationID && conversation.title) {
          chatName = conversation.title;
          break;
        }
      }
    }

    const title = isGroup ? (chatName || groupId) : selfName;
    const description = this.getMessageTypeAbstract(message);

    // Create ext JSON
    const ext = this.createOfflinePushExtJson(
      isGroup,
      description,
      isGroup ? groupId : selfUserId,
      title,
      loginUserInfo?.avatarURL
    );

    const extensionInfo = new Map<string, Object>();
    extensionInfo.set('ext', ext);
    extensionInfo.set('AndroidOPPOChannelID', 'tuikit');
    extensionInfo.set('AndroidHuaWeiCategory', 'IM');
    extensionInfo.set('AndroidVIVOCategory', 'IM');
    extensionInfo.set('AndroidHonorImportance', 'NORMAL');
    extensionInfo.set('AndroidMeizuNotifyType', 1);
    extensionInfo.set('iOSInterruptionLevel', 'time-sensitive');
    extensionInfo.set('enableIOSBackgroundNotification', false);

    const pushInfo: OfflinePushInfo = {
      title: title,
      description: this.trimPushDescription(description),
      extensionInfo: extensionInfo
    };

    return pushInfo;
  }

  /**
   * Get message type abstract for offline push
   */
  private getMessageTypeAbstract(message: MessageInfo): string {
    switch (message.messageType) {
      case MessageType.Text:
        return message.messageBody?.text ?? '';
      case MessageType.Image:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_image').id);
      case MessageType.Video:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_video').id);
      case MessageType.File:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_file').id);
      case MessageType.Sound:
        return getContext().resourceManager.getStringSync($r('app.string.message_type_voice').id);
      case MessageType.Face:
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

  /**
   * Handle copy action for classic popup style
   */
  private handlePopupCopy(message: MessageInfo) {
    if (!message.messageBody?.text || message.messageBody.text.length === 0) {
      Toast.info($r('app.string.messagelist_copy_unsupported'), this.getUIContext());
      return;
    }

    const messageContent = message.messageBody.text;
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