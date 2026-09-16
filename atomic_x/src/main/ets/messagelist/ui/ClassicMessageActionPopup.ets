import { MessageInfo, MessageListStore, MessageType, MessageStatus, TextMessagePayload, AudioMessagePayload } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { ConversationType } from '@tencentcloud/atomicxcore';
import { ThemeState, AppBuilderConfig, MessageAction } from '../../basecomponent/Index';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';
import { ReactionEmojiPicker } from './ReactionEmojiPicker';
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { ChatbotMessageActionPolicy } from '../../chatbot/ChatbotMessageActionPolicy';

export const CLASSIC_MESSAGE_ACTION_POPUP_WIDTH: number = 228;
const ACTION_ICON_SIZE: number = 16;
const ACTION_LABEL_SIZE: number = 10;
const ACTION_ITEM_VERTICAL_PADDING: number = 11;
const ACTION_LABEL_MARGIN_TOP: number = 4;
const ACTION_GRID_HORIZONTAL_PADDING: number = 4;
const ACTION_GRID_BOTTOM_PADDING: number = 8;
const ACTION_DIVIDER_WIDTH: string = '90%';

/**
 * Message action item interface for classic popup menu
 */
export interface ClassicMessageActionItem {
  text: string | Resource;
  icon: Resource;
  action: string;
  color?: string | ResourceColor;
  iconColor?: string | ResourceColor;
  useIntrinsicIconColor?: boolean;
  strokeIcon?: boolean;
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
  onQuote?: () => void;
  onListenFromHere?: () => void;
  onEmojiReaction?: (emoji: EmojiItem) => void;
  onExpandEmojiPicker?: () => void;
  onClose?: () => void;
  customActions?: ClassicCustomActionItem[] = [];
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();
  @State private actionItems: ClassicMessageActionItem[] = [];
  @State private isReactionPickerVisible: boolean = false;

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.initializeActions();
  }

  private initializeActions() {
    const items: ClassicMessageActionItem[] = [];

    if (ChatbotMessageActionPolicy.isChatbotVisualMessage(this.message)) {
      this.actionItems = this.buildChatbotActions();
      return;
    }

    if (this.effectiveConfig.isSupportCopy && this.shouldShowCopy()) {
      items.push({
        text: $r('app.string.action_copy'),
        icon: $rawfile('messagelist/icon_extion_copy.svg'),
        action: 'copy'
      });
    }

    if (this.effectiveConfig.isSupportForward &&
        this.message.status !== MessageStatus.VIOLATION &&
        this.message.status !== MessageStatus.SEND_FAIL) {
      items.push({
        text: $r('app.string.action_forward'),
        icon: $rawfile('messagelist/icon_extion_forward.svg'),
        action: 'forward',
        strokeIcon: true
      });
    }

    if (this.shouldShowQuote()) {
      items.push({
        text: $r('app.string.action_quote'),
        icon: $rawfile('messagelist/icon_extion_quote.svg'),
        action: 'quote'
      });
    }

    if (this.effectiveConfig.isSupportMultiSelect) {
      items.push({
        text: $r('app.string.action_multiselect'),
        icon: $rawfile('messagelist/icon_extion_multi.svg'),
        action: 'multiselect'
      });
    }

    if (this.effectiveConfig.isSupportDelete) {
      items.push({
        text: $r('app.string.action_delete'),
        icon: $rawfile('messagelist/icon_extion_delete.svg'),
        action: 'delete'
      });
    }

    if (this.shouldShowRecall()) {
      items.push({
        text: $r('app.string.action_recall'),
        icon: $rawfile('messagelist/icon_extion_recall.svg'),
        action: 'recall'
      });
    }

    if (this.shouldShowConvertToText()) {
      items.push({
        text: $r('app.string.action_convert_to_text'),
        icon: $rawfile('messagelist/icon_extion_convert_to_text.svg'),
        action: 'convertToText'
      });
    }

    if (this.shouldShowTranslate()) {
      items.push({
        text: $r('app.string.action_translate'),
        icon: $rawfile('messagelist/icon_extion_translate.svg'),
        action: 'translate'
      });
    }

    if (this.shouldShowListenFromHere()) {
      items.push({
        text: $r('app.string.action_listen_from_here'),
        icon: $rawfile('messagelist/icon_extion_listen_from_here.svg'),
        action: 'listenFromHere'
      });
    }

    if (this.customActions && this.customActions.length > 0) {
      this.customActions.forEach((customAction: ClassicCustomActionItem, index: number) => {
        items.push({
          text: customAction.title,
          icon: customAction.iconName as Resource,
          action: `custom_${index}`
        });
      });
    }

    if (this.effectiveConfig.isSupportReaction && this.message.status !== MessageStatus.VIOLATION) {
      items.push({
        text: $r('app.string.action_reaction'),
        icon: $rawfile('messagelist/icon_extion_reaction.svg'),
        action: 'reaction'
      });
    }

    this.actionItems = items;
  }

  /**
   * Chatbot streaming answers only expose copy / forward / delete, and only once
   * the answer has completed. Mirrors the Android buildActionCapability() branch.
   */
  private buildChatbotActions(): ClassicMessageActionItem[] {
    const items: ClassicMessageActionItem[] = [];
    if (!ChatbotMessageActionPolicy.isComplete(this.message)) {
      return items;
    }
    if (this.effectiveConfig.isSupportCopy) {
      items.push({
        text: $r('app.string.action_copy'),
        icon: $rawfile('messagelist/icon_extion_copy.svg'),
        action: 'copy'
      });
    }
    if (this.effectiveConfig.isSupportForward && this.message.status === MessageStatus.SEND_SUCCESS) {
      items.push({
        text: $r('app.string.action_forward'),
        icon: $rawfile('messagelist/icon_extion_forward.svg'),
        action: 'forward',
        strokeIcon: true
      });
    }
    if (this.effectiveConfig.isSupportDelete) {
      items.push({
        text: $r('app.string.action_delete'),
        icon: $rawfile('messagelist/icon_extion_delete.svg'),
        action: 'delete'
      });
    }
    return items;
  }

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
    if (this.translationDisplayManager?.isTranslating(this.message.msgID) ?? false) {
      return false;
    }
    const hasTranslation = this.hasTranslationResult();
    const isExpanded = this.translationDisplayManager?.isExpanded(this.message.msgID) ?? true;
    return !hasTranslation || !isExpanded;
  }

  private hasTranslationResult(): boolean {
    const textPayload = this.message.messagePayload as TextMessagePayload | undefined;
    const translatedTextMap = textPayload?.translatedText;
    if (!translatedTextMap) {
      return false;
    }

    let hasTranslation = false;
    translatedTextMap.forEach((value: string) => {
      if (value && value.length > 0) {
        hasTranslation = true;
      }
    });
    return hasTranslation;
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

  private shouldShowListenFromHere(): boolean {
    if (!this.effectiveConfig.isSupportListenFromHere) {
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

  private handleAction(action: string) {
    if (action === 'reaction') {
      this.isReactionPickerVisible = true;
      return;
    }

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
    } else if (action === 'listenFromHere' && this.onListenFromHere) {
      this.onListenFromHere();
    } else if (action === 'translate' && this.onTranslate) {
      this.onTranslate();
    } else if (action === 'quote' && this.onQuote) {
      this.onQuote();
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

  private getStrokeColorMatrix(color: string): number[] {
    const rgb = this.parseHexColor(color);
    const r = Number.isNaN(rgb[0]) ? 255 : rgb[0];
    const g = Number.isNaN(rgb[1]) ? 255 : rgb[1];
    const b = Number.isNaN(rgb[2]) ? 255 : rgb[2];
    return [
      0, 0, 0, 0, r,
      0, 0, 0, 0, g,
      0, 0, 0, 0, b,
      0, 0, 0, 1, 0
    ];
  }

  private parseHexColor(color: string): number[] {
    let hex = color;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length === 8) {
      hex = hex.substring(2);
    }
    return [
      parseInt(hex.substring(0, 2), 16),
      parseInt(hex.substring(2, 4), 16),
      parseInt(hex.substring(4, 6), 16)
    ];
  }

  @Builder
  private ActionItem(item: ClassicMessageActionItem) {
    Column() {
      if (item.strokeIcon) {
        Image(item.icon)
          .width(ACTION_ICON_SIZE)
          .height(ACTION_ICON_SIZE)
          .objectFit(ImageFit.Contain)
          .colorFilter(this.getStrokeColorMatrix(item.iconColor?.toString() ?? this.themeState.colors.textColorPrimary))
      } else if (item.useIntrinsicIconColor) {
        Image(item.icon)
          .width(ACTION_ICON_SIZE)
          .height(ACTION_ICON_SIZE)
          .objectFit(ImageFit.Contain)
      } else {
        Image(item.icon)
          .width(ACTION_ICON_SIZE)
          .height(ACTION_ICON_SIZE)
          .objectFit(ImageFit.Contain)
          .fillColor(item.iconColor ?? this.themeState.colors.textColorPrimary)
      }

      Text(item.text)
        .fontSize(ACTION_LABEL_SIZE)
        .lineHeight(14)
        .fontColor(item.color ?? this.themeState.colors.textColorPrimary)
        .margin({ top: ACTION_LABEL_MARGIN_TOP })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('20%')
    .padding({ top: ACTION_ITEM_VERTICAL_PADDING, bottom: ACTION_ITEM_VERTICAL_PADDING })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.handleAction(item.action);
    })
  }

  build() {
    Column() {
      if (this.isReactionPickerVisible) {
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
          },
          onCollapseClick: () => {
            this.isReactionPickerVisible = false;
          }
        })
      } else {
        if (this.actionItems.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.actionItems.slice(0, 5), (item: ClassicMessageActionItem) => {
              this.ActionItem(item)
            }, (item: ClassicMessageActionItem, index: number) => `${item.action}_${index}`)
          }
          .width('100%')
          .padding({ left: ACTION_GRID_HORIZONTAL_PADDING, right: ACTION_GRID_HORIZONTAL_PADDING,
            bottom: ACTION_GRID_BOTTOM_PADDING })

          if (this.actionItems.length > 5) {
            Divider()
              .width(ACTION_DIVIDER_WIDTH)
              .height(0.5)
              .color(this.themeState.colors.strokeColorPrimary)
              .margin({ top: 2, bottom: 2 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.actionItems.slice(5, 10), (item: ClassicMessageActionItem) => {
                this.ActionItem(item)
              }, (item: ClassicMessageActionItem, index: number) => `${item.action}_${index + 5}`)
            }
            .width('100%')
            .padding({ left: ACTION_GRID_HORIZONTAL_PADDING, right: ACTION_GRID_HORIZONTAL_PADDING,
              bottom: ACTION_GRID_BOTTOM_PADDING })
          }
        }
      }
    }
    .width(CLASSIC_MESSAGE_ACTION_POPUP_WIDTH)
    .backgroundColor(this.themeState.colors.dropdownColorDefault)
    .borderRadius(7)
    .shadow({
      radius: 26,
      color: 'rgba(0, 0, 0, 0.06)',
      offsetX: 0,
      offsetY: 12
    })
  }
}
