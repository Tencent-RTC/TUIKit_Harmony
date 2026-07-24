import { MessageInfo, MessageListStore, MessageType, MessageStatus, TextMessagePayload, AudioMessagePayload } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { ConversationType } from '@tencentcloud/atomicxcore';
import { GetMessageView, MessageItem } from './MessageItem';
import { AppBuilderConfig, ThemeState, MessageAction, Toast } from '../../basecomponent/Index';
import { MessageCustomAction } from '../components/MessageList';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';
import clipboard from '@ohos.pasteboard';
import { ReactionEmojiPicker } from './ReactionEmojiPicker';
import { ReactionEmojiPickerSheet } from './ReactionEmojiPickerSheet';
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { MessageRenderContext } from '../context/MessageRenderContext';

interface ActionButtonConfig {
  text: string | Resource;
  action: string;
  icon?: Resource;
  color?: string;
  showDivider?: boolean;
}

@CustomDialog
export struct MessageActionDialog {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink message: MessageInfo;
  @ObjectLink messageListStore: MessageListStore;
  controller: CustomDialogController;
  onMessageDeleted?: (msgId: string) => void;
  onMessageRecalled?: (msgId: string) => void;
  onForward?: (message: MessageInfo) => void;
  onMultiSelect?: (message: MessageInfo) => void;
  onMessageDetail?: (message: MessageInfo) => void;
  onEmojiReaction?: (emoji: EmojiItem) => void;  // Handle emoji reaction
  onShowFullEmojiPicker?: () => void;  // Handle full emoji picker display
  onConvertToText?: (message: MessageInfo) => void;  // Handle convert voice to text
  onTranslateText?: (message: MessageInfo) => void;  // Handle translate text message
  onQuote?: (message: MessageInfo) => void;
  asrDisplayManager?: AsrDisplayManager;  // ASR display state manager
  translationDisplayManager?: TranslationDisplayManager;  // Translation display state manager
  customActions?: MessageCustomAction[] = []; // Custom actions from MessageList
  config?: MessageListStyleProtocol = undefined; // Style configuration
  @State showPrimaryMenu: boolean = true;
  @State showSecondaryMenu: boolean = false;
  @State primaryActions: ActionButtonConfig[] = [];
  @State secondaryActions: ActionButtonConfig[] = [];
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.initializeActions();
  }

  /**
   * Create MessageRenderContext for the message in action panel
   */
  private createRenderContext(message: MessageInfo): MessageRenderContext {
    return {
      message: message,
      messageListStore: this.messageListStore,
      config: this.effectiveConfig,
      isInMergedDetailView: false,
      asrDisplayManager: this.asrDisplayManager,
      onAsrBubbleLongPress: undefined,
      onRequestCloseParentDialog: () => {
        // Close the MessageActionDialog when child component requests it
        if (this.controller) {
          this.controller.close();
        }
      }
    };
  }

  @Builder
  buildActionMenu(actions: ActionButtonConfig[]) {
    Column() {
      ForEach(actions, (action: ActionButtonConfig) => {
        this.IconButton({
          text: action.text,
          action: action.action,
          icon: action.icon,
          color: action.color,
          showDivider: action.showDivider,
        })
      })
    }
  }

  @Builder
  MessageBubble(message: MessageInfo) {
    if (message.isSentBySelf) {
      if (message.messageType === MessageType.TEXT) {
        Column() {
          Scroll() {
            GetMessageView(this.createRenderContext(message));
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
        }
        .constraintSize({ maxHeight: 300 })
        .borderRadius({
          topLeft: 16,
          topRight: 16,
          bottomLeft: 16,
          bottomRight: 0
        })
        .backgroundColor(this.themeState.colors.bgColorBubbleOwn)
        .borderWidth(1)
        .borderColor(this.themeState.colors.bgColorBubbleOwn)
        .justifyContent(FlexAlign.End)
        .padding(8)
      } else {
        // Non-text message: keep natural size (avoid extra padding/height constraints)
        Column() {
          GetMessageView(this.createRenderContext(message));
        }
        .borderRadius({
          topLeft: 16,
          topRight: 16,
          bottomLeft: 16,
          bottomRight: 0
        })
        .backgroundColor(this.themeState.colors.bgColorBubbleOwn)
        .borderWidth(1)
        .borderColor(this.themeState.colors.bgColorBubbleOwn)
      }
    } else {
      if (message.messageType === MessageType.TEXT) {
        Column() {
          Scroll() {
            GetMessageView(this.createRenderContext(message));
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
        }
        .constraintSize({ maxHeight: 300 })
        .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
        .borderRadius({
          topLeft: 16,
          topRight: 16,
          bottomLeft: 0,
          bottomRight: 16
        })
        .flexShrink(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .padding(8)
      } else {
        // Non-text message: keep natural size (avoid extra padding/height constraints)
        Column() {
          GetMessageView(this.createRenderContext(message));
        }
        .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
        .borderRadius({
          topLeft: 16,
          topRight: 16,
          bottomLeft: 0,
          bottomRight: 16
        })
        .flexShrink(1)
        .alignItems(HorizontalAlign.Start)
      }
    }
  }

  build() {
    Column() {

      // Reaction emoji picker first (only show if reaction is supported and not violation)
      if (this.effectiveConfig.isSupportReaction && this.message.status !== MessageStatus.VIOLATION) {
        Row() {
          ReactionEmojiPicker({
            onEmojiClick: (emoji: EmojiItem) => {
              this.handleEmojiReactionCallback(emoji);
            },
            onExpandClick: () => {
              this.handleShowFullEmojiPickerCallback();
            }
          })
        }
        .width('100%')
        .justifyContent(this.message.isSentBySelf ? FlexAlign.End : FlexAlign.Start)
        .margin({ bottom: 8, left: this.message.isSentBySelf ? 0 : 36, right: this.message.isSentBySelf ? 0 : 0 })
      }

      if (this.message.isSentBySelf) {

        Row() {
          Row() {
            this.MessageBubble(this.message);
          }
          .width('80%')
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Top)
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: 8 })
      } else {

        Row() {
          Row() {
            this.MessageBubble(this.message);
          }
          .width('80%')
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Top)
        }
        .padding({ left: 36 })
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: 8 })
      }

      if (this.message.isSentBySelf) {

        Row() {
          if (this.showPrimaryMenu) {
            this.buildActionMenu(this.primaryActions)
          }
          if (this.showSecondaryMenu) {
            this.buildActionMenu(this.secondaryActions);
          }
        }
        .width(180)
        .backgroundColor(this.themeState.getCurrentTheme().dropdownColorDefault)
        .borderRadius(16)
        .justifyContent(FlexAlign.End)
        .margin({ right: 0 })
      } else {

        Row() {
          if (this.showPrimaryMenu) {
            this.buildActionMenu(this.primaryActions);
          }
          if (this.showSecondaryMenu) {
            this.buildActionMenu(this.secondaryActions);
          }
        }
        .width(180)
        .backgroundColor(this.themeState.getCurrentTheme().dropdownColorDefault)
        .borderRadius(16)
        .justifyContent(FlexAlign.Start)
        .margin({ left: 36 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(this.message.isSentBySelf ? HorizontalAlign.End : HorizontalAlign.Start)
    .backgroundColor('rgba(0, 0, 0, 0.6)')
    .backdropBlur(8)
    .onClick(() => this.handleAction('close'))
  }

  // Action configuration mapping
  private getActionConfig(action: MessageAction): ActionButtonConfig | null {
    switch (action) {
      case MessageAction.COPY:
        return {
          text: $r('app.string.action_copy'),
          action: 'copy',
          icon: $rawfile('messagelist/icon_extion_copy.svg')
        };
      case MessageAction.RECALL:
        return {
          text: $r('app.string.action_recall'),
          action: 'recall',
          icon: $rawfile('messagelist/icon_extion_recall.svg')
        };
      case MessageAction.DELETE:
        return {
          text: $r('app.string.action_delete'),
          action: 'delete',
          icon: $rawfile('messagelist/icon_extion_delete.svg'),
          color: this.themeState.colors.textColorError
        };
      case MessageAction.FORWARD:
        return {
          text: $r('app.string.action_forward'),
          action: 'forward',
          icon: $rawfile('messagelist/icon_extion_forward.svg')
        };
      case MessageAction.MULTISELECT:
        return {
          text: $r('app.string.action_multiselect'),
          action: 'multiselect',
          icon: $rawfile('messagelist/icon_extion_multi.svg')
        };
      default:
        return null;
    }
  }

  /**
   * Initialize action buttons based on style configuration and customActions
   * Priority: style configuration > AppBuilderConfig > defaults
   * Includes both system actions (COPY, RECALL, DELETE, FORWARD, MULTISELECT) and custom actions
   */
  private initializeActions() {
    const configuredActions: ActionButtonConfig[] = [];



    // Check which actions are supported based on style configuration
    // Priority: style > AppBuilderConfig
    // Violation messages cannot be copied
    // Merged, File, Video, Image messages cannot be copied
    if (this.effectiveConfig.isSupportCopy  &&
        this.shouldShowCopy()) {
      const actionConfig = this.getActionConfig(MessageAction.COPY);
      if (actionConfig) {
        configuredActions.push(actionConfig);
      }
    }

    // Failed and violation messages cannot be forwarded
    if (this.effectiveConfig.isSupportForward &&
        this.message.status !== MessageStatus.VIOLATION &&
        this.message.status !== MessageStatus.SEND_FAIL) {
      const actionConfig = this.getActionConfig(MessageAction.FORWARD);
      if (actionConfig) {
        configuredActions.push(actionConfig);
      }
    }

    if (this.effectiveConfig.isSupportMultiSelect) {
      const actionConfig = this.getActionConfig(MessageAction.MULTISELECT);
      if (actionConfig) {
        configuredActions.push(actionConfig);
      }
    }

    if (this.shouldShowRecall()) {
      const actionConfig = this.getActionConfig(MessageAction.RECALL);
      if (actionConfig) {
        configuredActions.push(actionConfig);
      }
    }

    if (this.effectiveConfig.isSupportDelete) {
      const actionConfig = this.getActionConfig(MessageAction.DELETE);
      if (actionConfig) {
        configuredActions.push(actionConfig);
      }
    }
    
   if (this.shouldShowReadReceiptDetail()) {
      configuredActions.push({
        text: $r('app.string.action_detail'),
        action: 'detail',
        icon: $rawfile('messagelist/icon_extion_info.svg')
      });
    }

    // Add convert to text action for sound messages
    if (this.shouldShowConvertToText()) {
      configuredActions.push({
        text: $r('app.string.action_convert_to_text'),
        action: 'convertToText',
        icon: $rawfile('messagelist/icon_extion_convert_to_text.svg')
      });
    }

    // Add translate action for text messages
    if (this.shouldShowTranslate()) {
      configuredActions.push({
        text: $r('app.string.action_translate'),
        action: 'translate',
        icon: $rawfile('messagelist/icon_extion_translate.svg')
      });
    }

    // Add quote action for messages
    if (this.shouldShowQuote()) {
      configuredActions.push({
        text: $r('app.string.action_quote'),
        action: 'quote',
        icon: $rawfile('messagelist/icon_extion_quote.svg')
      });
    }

    if (this.customActions && this.customActions.length > 0) {
      this.customActions.forEach((customAction: MessageCustomAction, index: number) => {
        configuredActions.push({
          text: customAction.title,
          action: `custom_${index}`,
          icon: customAction.iconName as Resource
        });
      });
    }

    const maxPrimaryActions = 4;

    if (configuredActions.length <= maxPrimaryActions) {
      this.primaryActions = Array.from(configuredActions);
      this.secondaryActions = [];
    } else {
      const moreItem: ActionButtonConfig = {
        text: $r('app.string.action_more'),
        action: 'more',
        icon: $rawfile('messagelist/icon_extion_more.png'),
        color: '#147AFF',
        showDivider: true,
      };
      const backItem: ActionButtonConfig = {
        text: $r('app.string.action_back'),
        action: 'back',
        icon: $rawfile('messagelist/icon_extion_more.png'),
        color: '#147AFF',
        showDivider: true,
      };
      this.primaryActions = configuredActions.slice(0, maxPrimaryActions - 1).concat([moreItem]);
      this.secondaryActions = configuredActions.slice(maxPrimaryActions - 1).concat([backItem]);
    }
  }

  /**
   * Check if "Copy" action should be shown
   * Only for text messages (not merged, file, video, image messages)
   */
  private shouldShowCopy(): boolean {
    if (this.message.messageType !== MessageType.TEXT) {
      return false;
    }

    const textPayload = this.message.messagePayload as TextMessagePayload | undefined;
    const hasTextContent = !!(textPayload?.text && textPayload.text.length > 0);
    return hasTextContent;
  }

  private shouldShowRecall(): boolean {
    if (!this.effectiveConfig.isSupportRecall) {
      return false;
    }

    if (!this.message.isSentBySelf) {
      return false;
    }

    if (this.message.status === MessageStatus.VIOLATION) {
      return false;
    }

    if (this.message.status !== MessageStatus.SEND_SUCCESS) {
      return false;
    }

    const currentTime = Math.floor(Date.now() / 1000);
    const messageTime = this.message.timestamp || 0;
    const timeLimit = 120;

    return (currentTime - messageTime) < timeLimit;
  }

  private shouldShowReadReceiptDetail(): boolean {
    return this.effectiveConfig.enableReadReceipt === true &&
      this.message.isSentBySelf === true &&
      this.message.conversationType === ConversationType.GROUP &&
      !!this.message.needReadReceipt;
  }

  private shouldShowConvertToText(): boolean {
    if (!this.effectiveConfig.isSupportConvertToText) {
      return false;
    }

    if (this.message.messageType !== MessageType.AUDIO) {
      return false;
    }

    if (this.message.status === MessageStatus.VIOLATION) {
      return false;
    }

    if (this.message.status !== MessageStatus.SEND_SUCCESS) {
      return false;
    }

    const audioPayload = this.message.messagePayload as AudioMessagePayload | undefined;
    const hasAsrText = (audioPayload?.asrText ?? '').length > 0;
    const isExpanded = this.asrDisplayManager?.isExpanded(this.message.msgID) ?? false;

    return !hasAsrText || !isExpanded;
  }

  private shouldShowTranslate(): boolean {
    if (!this.effectiveConfig.isSupportTranslate) {
      return false;
    }

    if (this.message.messageType !== MessageType.TEXT) {
      return false;
    }

    if (this.message.status === MessageStatus.VIOLATION) {
      return false;
    }

    if (this.message.status !== MessageStatus.SEND_SUCCESS) {
      return false;
    }

    return true;
  }

  private shouldShowQuote(): boolean {
    if (!this.effectiveConfig.isSupportQuote) {
      return false;
    }
    if (this.message.status !== MessageStatus.SEND_SUCCESS) {
      return false;
    }
    return true;
  }

  @Builder
  private IconButton(config: ActionButtonConfig) {

    if (config.showDivider) {
      Divider()
        .width('100%')
        .height(2)
        .color(this.themeState.getCurrentTheme().strokeColorPrimary)
    }
    Button() {
      Row() {

        Text(config.text)
          .fontSize(16)
          .fontFamily('PingFangSC-Regular')
          .fontWeight(500)
          .fontColor(config.color || this.themeState.getCurrentTheme().textColorPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)


        Image(config.icon)
          .width(17)
          .height(17)
          .fillColor(this.themeState.colors.textColorLink)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .backgroundColor(Color.Transparent)
    .padding({ left: 16, right: 16 })
    .onClick(() => this.handleAction(config.action))
    .width('100%')
    .height(44)
  }

  private handleAction(action: string) {
    console.log('执行操作:', action)
    if (action === 'more') {
      this.showPrimaryMenu = false
      this.showSecondaryMenu = true
    } else if (action === 'back') {
      this.showSecondaryMenu = false
      this.showPrimaryMenu = true
    } else if (action === 'copy') {
      this.copyMessageToClipboard()
    } else if (action === 'recall') {
      this.recallMessage()
    } else if (action === 'delete') {
      this.deleteMessage()
    } else if (action === 'forward') {
      this.forwardMessage()
    } else if (action === 'multiselect') {
      this.enterMultiSelectMode()
    } else if (action === 'detail') {
      this.openReadReceiptDetail();
    } else if (action === 'convertToText') {
      this.handleConvertToText();
    } else if (action === 'translate') {
      this.handleTranslateText();
    } else if (action === 'quote') {
      this.handleQuoteMessage();
    } else if (action.startsWith('custom_')) {
      // Handle custom actions
      this.handleCustomAction(action)
    }

    if (action !== 'more' && action !== 'back') {
      if (this.controller) {
        this.controller.close()
      }
    }
  }

  private openReadReceiptDetail() {
    if (this.onMessageDetail) {
      this.onMessageDetail(this.message);
    }
  }

  private forwardMessage() {
    if (this.onForward) {
      this.onForward(this.message);
    }
  }

  private enterMultiSelectMode() {
    if (this.onMultiSelect) {
      this.onMultiSelect(this.message);
    }
  }

  private handleConvertToText() {
    if (this.onConvertToText) {
      this.onConvertToText(this.message);
    }
  }

  private handleTranslateText() {
    if (this.onTranslateText) {
      this.onTranslateText(this.message);
    }
  }

  private handleQuoteMessage() {
    if (this.onQuote) {
      this.onQuote(this.message);
    }
  }

  // Handle custom action execution
  private handleCustomAction(action: string) {
    const indexStr = action.replace('custom_', '');
    const index = parseInt(indexStr, 10);
    
    if (isNaN(index) || !this.customActions || index < 0 || index >= this.customActions.length) {
      console.warn(`[MessageActionDialog] Invalid custom action index: ${indexStr}`);
      return;
    }
    
    const customAction = this.customActions[index];
    if (customAction && customAction.action) {
      try {
        customAction.action(this.message); // Pass the full MessageInfo object
        console.log(`[MessageActionDialog] Custom action executed at index: ${index}`);
      } catch (error) {
        console.error(`[MessageActionDialog] Failed to execute custom action at index ${index}:`, error);
      }
    } else {
      console.warn(`[MessageActionDialog] Custom action not found at index: ${index}`);
    }
  }

  private copyMessageToClipboard() {

    let messageContent = '';
    const textPayload = this.message.messagePayload as TextMessagePayload | undefined;
    if (textPayload?.text) {
      messageContent = textPayload.text;
    } else {
      Toast.info($r('app.string.messagelist_copy_unsupported'), this.getUIContext());
      return;
    }

    let pasteData = clipboard.createData(clipboard.MIMETYPE_TEXT_PLAIN, messageContent);
    let systemPasteboard = clipboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData, (err) => {
      if (err) {
        Toast.info($r('app.string.messagelist_copy_failed'), this.getUIContext());
      } else {
        Toast.info($r('app.string.messagelist_copied'), this.getUIContext());
      }
    });
  }

  private recallMessage() {

    if (!this.message.isSentBySelf) {
      Toast.info($r('app.string.messagelist_recall_only_own'), this.getUIContext());
      return;
    }


    if (this.onMessageRecalled) {
      this.onMessageRecalled(this.message.msgID);
    } else {
      Toast.info($r('app.string.messagelist_recall_failed_no_callback'), this.getUIContext());
    }
  }

  private deleteMessage() {
    if (this.onMessageDeleted) {

      this.onMessageDeleted(this.message.msgID);
    } else {
      Toast.info($r('app.string.messagelist_delete_failed_no_callback'), this.getUIContext());
    }
  }

  private handleEmojiReactionCallback(emoji: EmojiItem) {
    // Close dialog first
    if (this.controller) {
      this.controller.close();
    }
    
    // Delegate to external handler
    if (this.onEmojiReaction) {
      this.onEmojiReaction(emoji);
    }
  }

  private handleShowFullEmojiPickerCallback() {
    // Close dialog first
    if (this.controller) {
      this.controller.close();
    }
    
    // Delegate to external handler
    if (this.onShowFullEmojiPicker) {
      this.onShowFullEmojiPicker();
    }
  }
}
