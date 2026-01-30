import { MessageInfo, MessageListStore, MessageType, MessageStatus, LoginStore } from '@tencentcloud/atomicxcore';
import { ThemeState, AppBuilderConfig, MessageAction } from '../../basecomponent/Index';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';
import { ReactionEmojiPicker, RecentEmojiManager } from './ReactionEmojiPicker';
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';

/**
 * Message action item interface for classic popup menu
 */
export interface ClassicMessageActionItem {
  text: string | Resource;
  icon: Resource;
  action: string;
  color?: string | ResourceColor;
}

/**
 * Custom action item interface for classic popup menu
 */
export interface ClassicCustomActionItem {
  title: string | Resource;
  iconName?: string | Resource;
  action: (message: MessageInfo) => void;
}

/**
 * Classic Message Action Popup Component
 * A floating popup menu for message actions (classic style using bindPopup)
 * Features:
 * - Reaction emoji picker at the top (inside popup)
 * - 5-column grid layout for action buttons
 * - Icon + text style for each action
 */
@Component
export struct ClassicMessageActionPopup {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink message: MessageInfo;
  @ObjectLink messageListStore: MessageListStore;
  config?: MessageListStyleProtocol = undefined;
  asrDisplayManager?: AsrDisplayManager;
  translationDisplayManager?: TranslationDisplayManager;
  // Action callbacks
  onCopy?: () => void;
  onRecall?: () => void;
  onDelete?: () => void;
  onForward?: () => void;
  onMultiSelect?: () => void;
  onDetail?: () => void;
  onConvertToText?: () => void;
  onTranslate?: () => void;
  onEmojiReaction?: (emoji: EmojiItem) => void;
  onExpandEmojiPicker?: () => void;
  onClose?: () => void;
  customActions?: ClassicCustomActionItem[] = [];
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();
  @State private actionItems: ClassicMessageActionItem[] = [];

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.initializeActions();
  }

  private initializeActions() {
    const items: ClassicMessageActionItem[] = [];

    // Copy action - only for text messages
    if (this.effectiveConfig.isSupportCopy  &&
        this.shouldShowCopy()) {
      items.push({
        text: $r('app.string.action_copy'),
        icon: $rawfile('messagelist/icon_extion_copy.svg'),
        action: 'copy'
      });
    }

    // Forward action - exclude failed and violation messages
    if (this.effectiveConfig.isSupportForward && 
        this.message.status !== MessageStatus.violation &&
        this.message.status !== MessageStatus.sendFail) {
      items.push({
        text: $r('app.string.action_forward'),
        icon: $rawfile('messagelist/icon_extion_forward.svg'),
        action: 'forward'
      });
    }

    // Multi-select action
    if (this.effectiveConfig.isSupportMultiSelect) {
      items.push({
        text: $r('app.string.action_multiselect'),
        icon: $rawfile('messagelist/icon_extion_multi.svg'),
        action: 'multiselect'
      });
    }

    // Recall action - only for own messages within time limit
    if (this.shouldShowRecall()) {
      items.push({
        text: $r('app.string.action_recall'),
        icon: $rawfile('messagelist/icon_extion_recall.svg'),
        action: 'recall'
      });
    }

    // Delete action
    if (this.effectiveConfig.isSupportDelete) {
      items.push({
        text: $r('app.string.action_delete'),
        icon: $rawfile('messagelist/icon_extion_delete.svg'),
        action: 'delete',
      });
    }

    // Read receipt detail action
    if (this.shouldShowReadReceiptDetail()) {
      items.push({
        text: $r('app.string.action_detail'),
        icon: $rawfile('messagelist/icon_extion_info.svg'),
        action: 'detail'
      });
    }

    // Convert to text action - only for sound messages
    if (this.shouldShowConvertToText()) {
      items.push({
        text: $r('app.string.action_convert_to_text'),
        icon: $rawfile('messagelist/icon_extion_convert_to_text.svg'),
        action: 'convertToText'
      });
    }

    // Translate action - only for text messages
    if (this.shouldShowTranslate()) {
      items.push({
        text: $r('app.string.action_translate'),
        icon: $rawfile('messagelist/icon_extion_translate.svg'),
        action: 'translate'
      });
    }

    // Custom actions
    if (this.customActions && this.customActions.length > 0) {
      this.customActions.forEach((customAction, index) => {
        items.push({
          text: customAction.title,
          icon: customAction.iconName as Resource,
          action: `custom_${index}`
        });
      });
    }

    this.actionItems = items;
  }

  private shouldShowCopy(): boolean {
    if (this.message.messageType !== MessageType.Text) {
      return false;
    }
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
    if (this.message.status === MessageStatus.violation) {
      return false;
    }
    if (this.message.status !== MessageStatus.sendSuccess) {
      return false;
    }
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

  private shouldShowConvertToText(): boolean {
    if (!this.effectiveConfig.isSupportConvertToText) {
      return false;
    }
    if (this.message.messageType !== MessageType.Sound) {
      return false;
    }
    if (this.message.status === MessageStatus.violation) {
      return false;
    }
    if (this.message.status !== MessageStatus.sendSuccess) {
      return false;
    }
    const hasAsrText = (this.message.messageBody?.asrText ?? '').length > 0;
    const isExpanded = this.asrDisplayManager?.isExpanded(this.message.msgID) ?? false;
    return !hasAsrText || !isExpanded;
  }

  private shouldShowTranslate(): boolean {
    if (!this.effectiveConfig.isSupportTranslate) {
      return false;
    }
    if (this.message.messageType !== MessageType.Text) {
      return false;
    }
    if (this.message.status === MessageStatus.violation) {
      return false;
    }
    if (this.message.status !== MessageStatus.sendSuccess) {
      return false;
    }
    const translatedTextMapRaw = this.message.messageBody?.translatedText;
    let hasTranslatedText: boolean = false;
    if (translatedTextMapRaw) {
      hasTranslatedText = translatedTextMapRaw.size > 0;
    }
    const isExpanded = this.translationDisplayManager?.isExpanded(this.message.msgID) ?? false;
    return !hasTranslatedText || !isExpanded;
  }

  private handleAction(action: string) {
    // Close popup first
    if (this.onClose) {
      this.onClose();
    }

    if (action === 'copy' && this.onCopy) {
      this.onCopy();
    } else if (action === 'recall' && this.onRecall) {
      this.onRecall();
    } else if (action === 'delete' && this.onDelete) {
      this.onDelete();
    } else if (action === 'forward' && this.onForward) {
      this.onForward();
    } else if (action === 'multiselect' && this.onMultiSelect) {
      this.onMultiSelect();
    } else if (action === 'detail' && this.onDetail) {
      this.onDetail();
    } else if (action === 'convertToText' && this.onConvertToText) {
      this.onConvertToText();
    } else if (action === 'translate' && this.onTranslate) {
      this.onTranslate();
    } else if (action.startsWith('custom_')) {
      this.handleCustomAction(action);
    }
  }

  private handleCustomAction(action: string) {
    const indexStr = action.replace('custom_', '');
    const index = parseInt(indexStr, 10);
    if (isNaN(index) || !this.customActions || index < 0 || index >= this.customActions.length) {
      return;
    }
    const customAction = this.customActions[index];
    if (customAction && customAction.action) {
      customAction.action(this.message);
    }
  }

  build() {
    Column() {
      // Reaction emoji picker at the top (inside popup)
      if (this.effectiveConfig.isSupportReaction && this.message.status !== MessageStatus.violation) {
        Row() {
          ReactionEmojiPicker({
            onEmojiClick: (emoji: EmojiItem) => {
              if (this.onClose) {
                this.onClose();
              }
              if (this.onEmojiReaction) {
                this.onEmojiReaction(emoji);
              }
            },
            onExpandClick: () => {
              if (this.onClose) {
                this.onClose();
              }
              if (this.onExpandEmojiPicker) {
                this.onExpandEmojiPicker();
              }
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 12, bottom: 8 })
      }

      // Divider line
      if (this.effectiveConfig.isSupportReaction && this.message.status !== MessageStatus.violation && this.actionItems.length > 0) {
        Divider()
          .width('90%')
          .height(0.5)
          .color(this.themeState.colors.strokeColorPrimary)
          .margin({ bottom: 8 })
      }

      // Action buttons using Flex layout (auto height)
      if (this.actionItems.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.actionItems, (item: ClassicMessageActionItem) => {
            Column() {
              Image(item.icon)
                .width(16)
                .height(16)
                .fillColor(this.themeState.colors.textColorSecondary)

              Text(item.text)
                .fontSize(11)
                .fontColor(this.themeState.colors.textColorPrimary)
                .margin({ top: 6 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('20%')
            .padding({ top: 8, bottom: 8 })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.handleAction(item.action);
            })
          }, (item: ClassicMessageActionItem, index: number) => `${item.action}_${index}`)
        }
        .width('100%')
        .padding({ left: 8, right: 8, bottom: 12 })
      }
    }
    .width(280)
    .backgroundColor(this.themeState.colors.dropdownColorDefault)
    .borderRadius(14)
    .shadow({
      radius: 26,
      color: 'rgba(0, 0, 0, 0.06)',
      offsetX: 0,
      offsetY: 12
    })
  }
}
