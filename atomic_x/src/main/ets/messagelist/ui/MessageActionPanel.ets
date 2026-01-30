import { MessageInfo, MessageListStore, LoginStore, ErrorInfo, MessageType, MessageStatus } from '@tencentcloud/atomicxcore';
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
    if (message.isSelf) {
      // Text message: allow scrolling for long content
      if (message.messageType === MessageType.Text) {
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
      // Text message: allow scrolling for long content
      if (message.messageType === MessageType.Text) {
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
      if (this.effectiveConfig.isSupportReaction && this.message.status !== MessageStatus.violation) {
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
        .justifyContent(this.message.isSelf ? FlexAlign.End : FlexAlign.Start)
        .margin({ bottom: 8, left: this.message.isSelf ? 0 : 36, right: this.message.isSelf ? 0 : 0 })
      }

      // Message bubble second
      if (this.message.isSelf) {

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

      // Action menu last
      if (this.message.isSelf) {

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
    .alignItems(this.message.isSelf ? HorizontalAlign.End : HorizontalAlign.Start)
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
        this.message.status !== MessageStatus.violation &&
        this.message.status !== MessageStatus.sendFail) {
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

    // Add custom actions from MessageList
    if (this.customActions && this.customActions.length > 0) {
      this.customActions.forEach((customAction, index) => {
        configuredActions.push({
          text: customAction.title,
          action: `custom_${index}`, // Use index to distinguish custom actions
          icon: customAction.iconName as Resource
        });
      });
    }

    // Setup actions based on configured actions only
    const maxPrimaryActions = 4;

    if (configuredActions.length <= maxPrimaryActions) {
      // All actions fit in primary menu
      this.primaryActions = [...configuredActions];
      this.secondaryActions = [];
    } else {
      // Need secondary menu for overflow actions
      this.primaryActions = [
        ...configuredActions.slice(0, maxPrimaryActions - 1),
        {
          text: $r('app.string.action_more'),
          action: 'more',
          icon: $rawfile('messagelist/icon_extion_more.png'),
          color: '#147AFF',
          showDivider: true,
        }
      ];

      // Setup secondary actions menu with remaining configured actions
      this.secondaryActions = [
        ...configuredActions.slice(maxPrimaryActions - 1),
        {
          text: $r('app.string.action_back'),
          action: 'back',
          icon: $rawfile('messagelist/icon_extion_more.png'),
          color: '#147AFF',
          showDivider: true,
        }
      ];
    }
  }

  /**
   * Check if "Copy" action should be shown
   * Only for text messages (not merged, file, video, image messages)
   */
  private shouldShowCopy(): boolean {
    // Only text messages can be copied
    if (this.message.messageType !== MessageType.Text) {
      return false;
    }
    
    // Must have text content to copy
    const hasTextContent = !!(this.message.messageBody?.text && this.message.messageBody.text.length > 0);
    return hasTextContent;
  }

  private shouldShowRecall(): boolean {
    if (!this.effectiveConfig.isSupportRecall) {
      return false;
    }

    if (!this.message.isSelf) {
      return false;
    }

    // Violation messages cannot be recalled
    if (this.message.status === MessageStatus.violation) {
      return false;
    }

    if (this.message.status !== MessageStatus.sendSuccess) {
      return false;
    }

    // Recall is only allowed within 2 minutes (120 seconds)
    const currentTime = Math.floor(Date.now() / 1000);
    const messageTime = this.message.timestamp || 0;
    const timeLimit = 120; // 2 minutes

    return (currentTime - messageTime) < timeLimit;
  }

  private shouldShowReadReceiptDetail(): boolean {
    return this.effectiveConfig.enableReadReceipt === true &&
      this.message.isSelf === true &&
      !!this.message.groupID &&
      this.message.groupID.length > 0 &&
      !!this.message.needReadReceipt;
  }

  /**
   * Check if "Convert to Text" action should be shown
   * Only for sound messages that are sent successfully and not already showing ASR text
   */
  private shouldShowConvertToText(): boolean {
    // Check if feature is enabled
    if (!this.effectiveConfig.isSupportConvertToText) {
      return false;
    }
    
    // Only for sound messages
    if (this.message.messageType !== MessageType.Sound) {
      return false;
    }
    
    // Violation messages cannot be converted to text
    if (this.message.status === MessageStatus.violation) {
      return false;
    }
    
    // Only for successfully sent messages
    if (this.message.status !== MessageStatus.sendSuccess) {
      return false;
    }
    
    // Check if ASR text is already showing
    const hasAsrText = (this.message.messageBody?.asrText ?? '').length > 0;
    const isExpanded = this.asrDisplayManager?.isExpanded(this.message.msgID) ?? false;
    
    // Show if no ASR text or ASR bubble is hidden
    return !hasAsrText || !isExpanded;
  }

  /**
   * Check if "Translate" action should be shown
   * Only for text messages that are sent successfully and not already showing translation
   */
  private shouldShowTranslate(): boolean {
    // Check if feature is enabled
    if (!this.effectiveConfig.isSupportTranslate) {
      return false;
    }
    
    // Only for text messages
    if (this.message.messageType !== MessageType.Text) {
      return false;
    }
    
    // Violation messages cannot be translated
    if (this.message.status === MessageStatus.violation) {
      return false;
    }
    
    // Only for successfully sent messages
    if (this.message.status !== MessageStatus.sendSuccess) {
      return false;
    }
    
    // Check if translation text is already showing - Convert Map to Record
    const translatedTextMapRaw = this.message.messageBody?.translatedText;
    let hasTranslatedText: boolean = false;
    if (translatedTextMapRaw) {
      hasTranslatedText = translatedTextMapRaw.size > 0;
    }
    const isExpanded = this.translationDisplayManager?.isExpanded(this.message.msgID) ?? false;
    
    // Show if no translated text or translation bubble is hidden
    return !hasTranslatedText || !isExpanded;
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
    if (this.message.messageBody?.text) {
      messageContent = this.message.messageBody.text;
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

    if (!this.message.isSelf) {
      Toast.info($r('app.string.messagelist_recall_only_own'), this.getUIContext());
      return;
    }


    if (this.onMessageRecalled) {
      this.onMessageRecalled(this.message.ID);
    } else {
      Toast.info($r('app.string.messagelist_recall_failed_no_callback'), this.getUIContext());
    }
  }

  private deleteMessage() {
    if (this.onMessageDeleted) {

      this.onMessageDeleted(this.message.ID);
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
