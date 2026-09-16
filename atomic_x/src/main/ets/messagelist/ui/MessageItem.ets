import { MessageInfo, MessageType, MessageListStore, MessageStatus, TextMessagePayload, AudioMessagePayload } from '@tencentcloud/atomicxcore';
import { MessageInputStore, SendMessagePayload, SendMessageOption } from '@tencentcloud/atomicxcore';
import { MessageActionStore, MediaQuality } from '@tencentcloud/atomicxcore';
import { ConversationType } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';

import { TextMessageView } from '../cells/TextMessageView';
import { ImageMessageView } from '../cells/ImageMessageView';
import { FaceMessageView } from '../cells/FaceMessageView';
import { FileMessageView } from '../cells/FileMessageView';
import { SoundMessageView } from '../cells/SoundMessageView';
import { VideoMessageView } from '../cells/VideoMessageView';
import { MergedMessageView } from '../cells/MergedMessageView';
import { Avatar, AvatarSize, AvatarContentType, TextUtils, ThemeState, ActionSheet, ActionItem,
  Toast } from '../../basecomponent/Index';
import { AppBuilderConfig, MessageAlignment } from '../../basecomponent/utils/AppBuilderHelper';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { SystemMessageView } from '../cells/SystemMessageView';
import { CreateGroupMessageView } from '../cells/CreateGroupMessageView';
import { CustomMessageView } from '../cells/CustomMessageView';
import clipboard from '@ohos.pasteboard';
import { IMErrorCode } from '../../basecomponent/utils/IMErrorCode';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';
import { MessageReactionBar } from './MessageReactionBar';
import { ReactionDetailSheet } from './ReactionDetailSheet';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { AuxiliaryTextPopupMenu, AuxiliaryTextMenuItemConfig } from './AuxiliaryTextPopupMenu';
import { ClassicMessageActionPopup, ClassicCustomActionItem, CLASSIC_MESSAGE_ACTION_POPUP_WIDTH } from './ClassicMessageActionPopup';
import { MessageQuoteBubbleView } from '../cells/MessageQuoteBubbleView';
import { EventBus } from '../../basecomponent/utils/EventBus';
import { MessageQuoteEvent } from './MessageQuoteEvent';
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';
import { MessageUtils, ReadReceiptLabelInfo } from '../utils/MessageUtils';
import { TranslationTextParser } from '../utils/TranslationTextParser';
import { CallMessageView, CallMessageBubbleView } from '../cells/CallMessageView';
import { CallingMessageDataProvider, CallMessageDirection } from '../utils/CallingMessageDataProvider';
import { ChatbotMessageView } from '../../chatbot/ChatbotMessageView';
import { ChatbotMessageActionPolicy } from '../../chatbot/ChatbotMessageActionPolicy';
import { MessageItemDisplayPolicy } from '../adapter/MessageItemDisplayPolicy';
import { MessageBubbleBackgroundFactory } from '../adapter/MessageBubbleBackgroundFactory';
import { MessageResendPayloadFactory } from '../adapter/MessageResendPayloadFactory';

/**
 * Display mode for MessageItem
 */
export enum MessageDisplayMode {
  Normal = 'normal',   // Normal chat list mode
  Merged = 'merged'    // Merged message detail mode (all messages left-aligned with same bubble color)
}

@Builder
export function GetMessageView(context: MessageRenderContext) {
  if (context.message.messageType == MessageType.TEXT) {
    TextMessageView(context);
  } else if (context.message.messageType == MessageType.IMAGE) {
    ImageMessageView(context);
  } else if (context.message.messageType == MessageType.FILE) {
    FileMessageView(context);
  } else if (context.message.messageType == MessageType.AUDIO) {
    SoundMessageView(context);
  } else if (context.message.messageType == MessageType.VIDEO) {
    VideoMessageView(context);
  } else if (context.message.messageType == MessageType.FACE) {
    FaceMessageView(context);
  } else if (context.message.messageType == MessageType.MERGED) {
    MergedMessageView(context);
  } else if (context.message.messageType == MessageType.TIPS) {
    SystemMessageView(context);
  } else if (context.message.messageType == MessageType.CUSTOM) {
    if (isGroupCreatedMessage(context.message)) {
      CreateGroupMessageView(context);
    } else if (isChatbotVisualMessage(context.message)) {
      ChatbotMessageView(context);
    } else if (isChatbotInterruptMessage(context.message)) {
    } else if (isCallingC2C(context.message)) {
      CallMessageBubbleView(context);
    } else if (isCallingGroup(context.message)) {
      CallMessageView(context);
    } else if (isCallingSignal(context.message)) {
    } else {
      CustomMessageView(context);
    }
  } else {
    if ((context.config ?? new ChatMessageListConfig()).isShowUnsupportMessage) {
      TextMessageView(context);
    }
  }
}

function isGroupCreatedMessage(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isGroupCreatedMessage(message);
}

function isChatbotVisualMessage(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isChatbotVisualMessage(message);
}

function isChatbotInterruptMessage(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isChatbotInterruptMessage(message);
}

function shouldHideMessageEntirely(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.shouldHideMessageEntirely(message);
}

function isBusinessCustomMessage(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isBusinessCustomMessage(message);
}

function isCallingSignal(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isCallingSignal(message);
}

function isCallingC2C(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isCallingC2C(message);
}

function isCallingGroup(message: MessageInfo): boolean {
  return MessageItemDisplayPolicy.isCallingGroup(message);
}

@Component
export struct MessageItem {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink message: MessageInfo;
  @Watch('onInitialShowAvatarChanged')
  @Prop initialShowAvatar: boolean = true;
  @State showAvatar: boolean = true;
  @Prop isHighlighted: boolean = false;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isMultiSelectMode: boolean = false;
  @Prop displayMode: MessageDisplayMode = MessageDisplayMode.Normal;
  onLongPress?: (message: MessageInfo) => void;
  onUserClick?: (userID: string) => void;
  onUserLongPress?: (userID: string, nickname: string) => void;
  // ASR related properties
  @ObjectLink asrDisplayManager: AsrDisplayManager;
  onAsrBubbleLongPress?: (message: MessageInfo) => void;
  // Translation related properties
  @ObjectLink translationDisplayManager: TranslationDisplayManager;
  onTranslationBubbleLongPress?: (message: MessageInfo) => void;
  @ObjectLink messageListStore: MessageListStore;
  @State private shouldShowAvatarValue: boolean = true;
  @State private messageBubbleWidth: number = 0;
  @State private inputStore?: MessageInputStore = undefined;
  @State private messageActionStore?: MessageActionStore = undefined;
  private resendDialogController?: CustomDialogController;
  private reactionDetailController?: CustomDialogController;
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();
  // ASR menu popup state
  @State private showAsrMenu: boolean = false;
  @State private asrMenuMessage?: MessageInfo = undefined;
  // Translation menu popup state
  @State private showTranslationMenu: boolean = false;
  @State private translationMenuMessage?: MessageInfo = undefined;
  // Classic action popup state (for popup style)
  @State private showClassicActionPopup: boolean = false;
  // Custom actions for classic popup
  customActions?: ClassicCustomActionItem[] = [];
  // Classic popup action callbacks
  onCopy?: (message: MessageInfo) => void;
  onRecall?: (message: MessageInfo) => void;
  onDelete?: (message: MessageInfo) => void;
  onForward?: (message: MessageInfo) => void;
  onMultiSelect?: (message: MessageInfo) => void;
  onDetail?: (message: MessageInfo) => void;
  onConvertToText?: (message: MessageInfo) => void;
  onTranslate?: (message: MessageInfo) => void;
  onQuote?: (message: MessageInfo) => void;
  onListenFromHere?: (message: MessageInfo) => void;
  onEmojiReaction?: (emoji: EmojiItem, message: MessageInfo) => void;
  onExpandEmojiPicker?: (message: MessageInfo) => void;

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.showAvatar = this.initialShowAvatar;
    this.updateAvatarVisibility();
    this.downloadMessageViewSource(this.message);

    if ((this.message.status === MessageStatus.REVOKED || this.message.status === MessageStatus.VIOLATION)
      && this.showClassicActionPopup) {
      this.showClassicActionPopup = false;
    }
    // Initialize MessageInputStore for resending messages
    const conversationID = this.getConversationID();
    if (conversationID.length > 0) {
      this.inputStore = MessageInputStore.create(conversationID);
      this.messageActionStore = MessageActionStore.create(this.message);
    }
  }

  public refreshConfig(): void {
    this.updateAvatarVisibility();
  }

  private onInitialShowAvatarChanged(): void {
    this.showAvatar = this.initialShowAvatar;
    this.updateAvatarVisibility();
  }

  private getConversationID(): string {
    if (this.message.conversationType === ConversationType.GROUP) {
      return `group_${this.message.to}`;
    }
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    const peerID = this.message.isSentBySelf ? this.message.to : this.message.from.userID;
    if (peerID.length === 0 || peerID === currentUserID) {
      return '';
    }
    return `c2c_${peerID}`;
  }

  /**
   * Create MessageRenderContext for the current message
   */
  private createRenderContext(msg?: MessageInfo, isInMergedDetailView?: boolean): MessageRenderContext {
    return {
      message: msg ?? this.message,
      messageListStore: this.messageListStore,
      config: this.effectiveConfig,
      isInMergedDetailView: isInMergedDetailView ?? (this.displayMode === MessageDisplayMode.Merged),
      asrDisplayManager: this.asrDisplayManager,
      onAsrBubbleLongPress: this.onAsrBubbleLongPress
    };
  }

  downloadMessageViewSource(message: MessageInfo) {
    if (!message) {
      return;
    }

    try {
      if (message.messageType === MessageType.IMAGE) {
        MessageActionStore.create(message).downloadMedia(MediaQuality.THUMBNAIL, new CompletionHandlerAdapter(() => {
          console.info('[MessageItem] Successfully downloaded thumb image');
        }, (code: number, desc: string) => {
          console.error('[MessageItem] Failed to download thumb image:', code, desc);
        }));
      } else if (message.messageType === MessageType.VIDEO) {
        MessageActionStore.create(message).downloadMedia(MediaQuality.THUMBNAIL, new CompletionHandlerAdapter(() => {
          console.info('[MessageItem] Successfully downloaded video snapshot');
        }, (code: number, desc: string) => {
          console.error('[MessageItem] Failed to download video snapshot:', code, desc);
        }));
      } else if (message.messageType === MessageType.AUDIO) {
        MessageActionStore.create(message).downloadMedia(MediaQuality.ORIGINAL, new CompletionHandlerAdapter(() => {
          console.info('[MessageItem] Successfully downloaded sound');
        }, (code: number, desc: string) => {
          console.error('[MessageItem] Failed to download sound:', code, desc);
        }));
      } else if (message.messageType === MessageType.FILE) {
        console.info('[MessageItem] File message, not downloading automatically');
      }
    } catch (error) {
      console.error('[MessageItem] Error in downloadMessageViewSource:', error);
    }
  }

  @Builder
  AvatarView(url?: string, sideName?: string) {
    if (this.shouldShowAvatarValue) {
      Stack() {
        Avatar({
          content: {
            type: AvatarContentType.Image,
            name: sideName ?? (this.message.from?.userID || ''),
            url: url || '',
          },
          avatarSize: AvatarSize.M
        })
      }
      .width(40)
      .height(40)
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          LongPressGesture({ repeat: false, duration: 300 })
            .onAction(() => {
              if (!this.getEffectiveIsSelf() && this.onUserLongPress && this.message.from?.userID) {
                const userID = this.message.from.userID;
                const nickname = this.message.from.nickname || userID;
                this.onUserLongPress(userID, nickname);
              }
            }),
          TapGesture({ count: 1 })
            .onAction(() => {
              if (!this.getEffectiveIsSelf() && this.onUserClick && this.message.from?.userID) {
                this.onUserClick(this.message.from.userID);
              }
            })
        )
      )
    }
  }

  @Builder
  NicknameView() {
    Text(this.message.from?.nickname || this.message.from?.userID || '')
      .fontSize(12)
      .fontColor(this.themeState.colors.textColorSecondary)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .margin({ bottom: 4 })
  }

  @Builder
  TimeInBubbleView() {
    if (this.shouldShowTimeInBubble(this.message) && this.message.timestamp) {
      Text(this.formatTimeInBubble(this.message.timestamp))
        .fontSize(10)
        .fontColor(this.message.isSentBySelf ?
        this.themeState.colors.textColorTertiary:
          this.themeState.colors.textColorTertiary)
        .margin({ top: 4 })
        .padding({right:4})
        .alignSelf(ItemAlign.End)
    }
  }

  private formatTimeInBubble(timestamp: number): string {
    const date = new Date(timestamp * 1000);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  private shouldShowTimeInBubble(message: MessageInfo): boolean {
    return (this.effectiveConfig.isShowTimeInBubble ?? false) && message.messageType === MessageType.TEXT;
  }

  private shouldHideBubbleBackground(): boolean {
    return MessageBubbleBackgroundFactory.shouldHideBubbleBackground(this.message);
  }

  /**
   * Get bubble background color based on message type and display mode
   */
  private getBubbleBackgroundColor(): ResourceColor {
    return MessageBubbleBackgroundFactory.resolveBackgroundColor(this.message, this.getEffectiveIsSelf(),
      this.themeState.colors);
  }

  /**
   * Get bubble border color (same as background color)
   */
  private getBubbleBorderColor(): ResourceColor {
    return MessageBubbleBackgroundFactory.resolveBorderColor(this.message, this.getEffectiveIsSelf(),
      this.themeState.colors);
  }

  /**
   * Get bubble border width
   */
  private getBubbleBorderWidth(): number {
    return MessageBubbleBackgroundFactory.resolveBorderWidth(this.message);
  }

  /**
   * Get bubble corner radiuses based on the side where the avatar is shown.
   */
  private getBubbleBorderRadiuses(isRightSide: boolean): LocalizedBorderRadiuses {
    return MessageBubbleBackgroundFactory.resolveBorderRadiuses(this.message, isRightSide);
  }

  /**
   * Handle long press based on message action style
   * For 'popup' style: show classic popup
   * For 'dialog' style: call onLongPress callback (default behavior)
   */
  private handleMessageLongPress() {
    // Streaming chatbot answers and interrupt signals are not interactive until finished.
    if (!ChatbotMessageActionPolicy.isInteractionEnabled(this.message)) {
      return;
    }
    if (this.effectiveConfig.messageActionStyle === 'popup') {
      // Show classic popup
      this.showClassicActionPopup = true;
    } else {
      // Default: call onLongPress callback
      if (this.onLongPress) {
        this.onLongPress(this.message);
      }
    }
  }

  private handleItemTapForDismiss() {
    const eventData: Record<string, Object> = {};
    eventData['source'] = 'MessageItem';
    eventData['event'] = 'onBlankAreaClick';
    eventData['reason'] = 'tapMessageRow';
    EventBus.getInstance().post('onBlankAreaClick', eventData);
  }

  /**
   * Classic Action Popup Builder for bindPopup
   */
  @Builder
  ClassicActionPopupBuilder() {
    ClassicMessageActionPopup({
      message: this.message,
      messageListStore: this.messageListStore,
      config: this.effectiveConfig,
      asrDisplayManager: this.asrDisplayManager,
      translationDisplayManager: this.translationDisplayManager,
      customActions: this.customActions,
      onCopy: () => {
        if (this.onCopy) {
          this.onCopy(this.message);
        }
      },
      onRecall: () => {
        if (this.onRecall) {
          this.onRecall(this.message);
        }
      },
      onDelete: () => {
        if (this.onDelete) {
          this.onDelete(this.message);
        }
      },
      onForward: () => {
        if (this.onForward) {
          this.onForward(this.message);
        }
      },
      onMultiSelect: () => {
        if (this.onMultiSelect) {
          this.onMultiSelect(this.message);
        }
      },
      onDetail: () => {
        if (this.onDetail) {
          this.onDetail(this.message);
        }
      },
      onConvertToText: () => {
        if (this.onConvertToText) {
          this.onConvertToText(this.message);
        }
      },
      onListenFromHere: () => {
        if (this.onListenFromHere) {
          this.onListenFromHere(this.message);
        }
      },
      onTranslate: () => {
        if (this.onTranslate) {
          this.onTranslate(this.message);
        }
      },
      onQuote: () => {
        if (this.onQuote) {
          this.onQuote(this.message);
        }
      },
      onEmojiReaction: (emoji: EmojiItem) => {
        if (this.onEmojiReaction) {
          this.onEmojiReaction(emoji, this.message);
        }
      },
      onExpandEmojiPicker: () => {
        if (this.onExpandEmojiPicker) {
          this.onExpandEmojiPicker(this.message);
        }
      },
      onClose: () => {
        this.showClassicActionPopup = false;
      }
    })
  }

  private shouldShowOutsideReadReceipt(): boolean {
    const isMerged = this.displayMode === MessageDisplayMode.Merged;
    if (isMerged) return false;
    return MessageUtils.shouldShowReadReceipt(
      this.message,
      this.effectiveConfig.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
      isMerged
    );
  }

  @Builder
  ReadReceiptLabel() {
    if (this.shouldShowOutsideReadReceipt()) {
      Text(this.getReadReceiptText())
        .fontSize(12)
        .fontColor(this.getReadReceiptColor())
        .fontWeight(FontWeight.Regular)
        .margin({ left: 4, right: 4 })
        .onClick(() => {
          const isGroup = this.message.conversationType === ConversationType.GROUP;
          if (isGroup && this.onDetail) {
            this.onDetail(this.message);
          }
        })
    }
  }

  private shouldShowAudioSendingIndicator(): boolean {
    return this.getEffectiveIsSelf() &&
      this.message.messageType === MessageType.AUDIO &&
      this.message.status === MessageStatus.SENDING;
  }

  private getReadReceiptText(): string {
    const labelInfo: ReadReceiptLabelInfo | null = MessageUtils.getReadReceiptLabelInfo(this.message);
    return labelInfo?.text ?? '';
  }

  private getReadReceiptColor(): ResourceColor {
    const labelInfo: ReadReceiptLabelInfo | null = MessageUtils.getReadReceiptLabelInfo(this.message);
    if (labelInfo?.isHighlight) {
      return this.themeState.colors.textColorLink;
    }
    return this.themeState.colors.textColorSecondary;
  }

  private getMessageEffectiveIsSelf(message: MessageInfo): boolean {
    if (isCallingC2C(message)) {
      const callingProvider = new CallingMessageDataProvider(message);
      return callingProvider.direction === CallMessageDirection.outcoming;
    }
    return message.isSentBySelf ?? false;
  }

  private updateMessageBubbleWidth(area: Area): void {
    const width = Number(area.width);
    if (!Number.isNaN(width) && width > 0 && width !== this.messageBubbleWidth) {
      this.messageBubbleWidth = width;
    }
  }

  private getActionPopupArrowOffset(): number {
    const avatarPlaceholder = this.shouldShowAvatarValue
      ? 40 + (this.effectiveConfig.avatarSpacing ?? 8)
      : 0;
    const bubbleHalfWidth = this.messageBubbleWidth / 2;
    return this.getEffectiveIsSelf()
      ? Math.max(0, CLASSIC_MESSAGE_ACTION_POPUP_WIDTH - avatarPlaceholder - bubbleHalfWidth)
      : Math.max(0, avatarPlaceholder + bubbleHalfWidth);
  }

  @Builder
  MessageBubble(message: MessageInfo) {

    if (message.messageType === MessageType.TIPS ||
      (message.messageType === MessageType.CUSTOM && !isCallingC2C(message) && !isBusinessCustomMessage(message))) {

      Text("")
        .width(0)
        .height(0)
    } else if (message.messageType === MessageType.IMAGE || message.messageType === MessageType.VIDEO) {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
        if (this.effectiveConfig.isSupportReaction && message.reactionList && message.reactionList.length > 0) {
          MessageReactionBar({
            reactionList: message.reactionList,
            isSentBySelf: this.getMessageEffectiveIsSelf(message),
            onClickCallback: () => {
              this.showReactionDetail();
            }
          })
        }
      }
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
      .onAreaChange((_old: Area, area: Area): void => {
        this.updateMessageBubbleWidth(area);
      })
    } else if (this.getMessageEffectiveIsSelf(message)) {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
        if (this.effectiveConfig.isSupportReaction && message.reactionList && message.reactionList.length > 0) {
          MessageReactionBar({
            reactionList: message.reactionList,
            isSentBySelf: this.getMessageEffectiveIsSelf(message),
            onClickCallback: () => {
              this.showReactionDetail();
            }
          })
        }
      }
      .flexShrink(1)
      .borderRadius(this.getBubbleBorderRadiuses(true))
      .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.55)' : this.themeState.colors.bgColorBubbleOwn)
      .borderColor(this.themeState.colors.bgColorBubbleOwn)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
      .alignItems(HorizontalAlign.End)
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
      .onAreaChange((_old: Area, area: Area): void => {
        this.updateMessageBubbleWidth(area);
      })
    } else {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
        if (this.effectiveConfig.isSupportReaction && message.reactionList && message.reactionList.length > 0) {
          MessageReactionBar({
            reactionList: message.reactionList,
            isSentBySelf: this.getMessageEffectiveIsSelf(message),
            onClickCallback: () => {
              this.showReactionDetail();
            }
          })
        }
      }
      .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.55)' : this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius(this.getBubbleBorderRadiuses(false))
      .flexShrink(1)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
      .alignItems(HorizontalAlign.Start)
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
      .onAreaChange((_old: Area, area: Area): void => {
        this.updateMessageBubbleWidth(area);
      })
    }
  }

  @Builder
  QuoteBubble(message: MessageInfo, isLeftSide: boolean) {
    if (message.quoteInfo) {
      Column() {
        MessageQuoteBubbleView({
          quoteInfo: message.quoteInfo,
          onQuoteClick: () => {
            EventBus.getInstance().post(MessageQuoteEvent.LOCATE_QUOTED_MESSAGE, {
              'msgID': message.quoteInfo!.msgID,
              'sequence': message.quoteInfo!.sequence,
              'timestamp': message.quoteInfo!.timestamp,
              'returnMsgID': message.msgID
            });
          }
        })
      }
      .margin({ top: 4 })
      .alignItems(isLeftSide ? HorizontalAlign.Start : HorizontalAlign.End)
    }
  }

  /**
   * Check if ASR text bubble should be shown
   * Returns true if converting or if has asrText and is expanded
   */
  private shouldShowAsrBubble(message: MessageInfo): boolean {
    if (message.messageType !== MessageType.AUDIO) {
      return false;
    }
    
    const _ = this.asrDisplayManager.version;
    
    const isConverting = this.asrDisplayManager.isConverting(message.msgID);
    if (isConverting) {
      return true;
    }
    
    const isExpanded = this.asrDisplayManager.isExpanded(message.msgID);
    if (!isExpanded) {
      return false;
    }
    
    const audioPayload = message.messagePayload as AudioMessagePayload | undefined;
    const asrText = audioPayload?.asrText ?? '';
    return asrText.length > 0;
  }

  /**
   * Check if translation text bubble should be shown
   * Returns true if translating or if has translatedText and is expanded
   */
  private shouldShowTranslationBubble(message: MessageInfo): boolean {
    if (message.messageType !== MessageType.TEXT) {
      return false;
    }
    
    const _ = this.translationDisplayManager.version;
    
    const isTranslating = this.translationDisplayManager.isTranslating(message.msgID);
    if (isTranslating) {
      return true;
    }
    
    const isExpanded = this.translationDisplayManager.isExpanded(message.msgID);
    if (!isExpanded) {
      return false;
    }
    
    const translatedText = this.getTranslatedText(message);
    return translatedText.length > 0;
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
   * ASR Text Bubble - Separate bubble below voice message
   */
  @Builder
  AsrTextBubble(message: MessageInfo) {
    Column() {
      if (this.asrDisplayManager?.isConverting(message.msgID) ?? false) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color(message.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
      } else {
        Text((message.messagePayload as AudioMessagePayload | undefined)?.asrText ?? '')
          .fontSize(14)
          .fontColor(message.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
      }
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(message.isSentBySelf ? this.themeState.colors.bgColorBubbleOwn :
    this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(12)
    .margin({ top: 10 })
    .bindPopup(this.showAsrMenu && this.asrMenuMessage?.msgID === message.msgID, {
      builder: this.AsrTextMenuBuilder,
      placement: message.isSentBySelf ? Placement.TopRight : Placement.TopLeft,
      enableArrow: false,
      radius: 5,
      popupColor: Color.Transparent,
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 },
      onStateChange: (e) => {
        if (!e.isVisible) {
          this.showAsrMenu = false;
          this.asrMenuMessage = undefined;
        }
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (!this.asrDisplayManager.isConverting(message.msgID)) {
            this.asrMenuMessage = message;
            this.showAsrMenu = true;
          }
        })
    )
  }

  /**
   * Translation Text Bubble - Separate bubble below text message
   * Mirrors SwiftUI implementation with translation tips at bottom
   */
  @Builder
  TranslationTextBubble(message: MessageInfo) {
    Column() {
      if (this.translationDisplayManager?.isTranslating(message.msgID) ?? false) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color(message.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
      } else {
        Column({ space: 6 }) {
          Text() {
            ForEach(EmojiDataManager.parseEmojiText(this.getTranslatedText(message)), 
              (segment: EmojiTextSegment, index: number) => {
              if (segment.type === 'text') {
                Span(segment.content)
              } else if (segment.type === 'emoji' && segment.imageFile) {
                ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
                  .width(20)
                  .height(20)
                  .objectFit(ImageFit.Contain)
                  .verticalAlign(ImageSpanAlignment.CENTER)
              }
            }, (segment: EmojiTextSegment, index: number) => `${segment.type}_${index}_${segment.content}`)
          }
          .fontSize(14)
          .fontColor(message.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
            this.themeState.colors.textColorPrimary)
          .textOverflow({ overflow: TextOverflow.None })
          .maxLines(999)
          .wordBreak(WordBreak.BREAK_ALL)
          
          Row({ space: 4 }) {
            Image($rawfile('basecomponent/check_circle_filled.svg'))
              .width(10)
              .height(10)
              .fillColor(message.isSentBySelf ? 
                this.themeState.colors.textColorAntiPrimary :
                this.themeState.colors.textColorSecondary)
            
            Text($r('app.string.messagelist_translation_tips'))
              .fontSize(10)
              .fontColor(message.isSentBySelf ? 
                this.themeState.colors.textColorAntiPrimary :
                this.themeState.colors.textColorSecondary)
              .opacity(0.6)
          }
          .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
      }
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(message.isSentBySelf ? this.themeState.colors.bgColorBubbleOwn :
    this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(12)
    .margin({ top: 10 })
    .bindPopup(this.showTranslationMenu && this.translationMenuMessage?.msgID === message.msgID, {
      builder: this.TranslationTextMenuBuilder,
      placement: message.isSentBySelf ? Placement.TopRight : Placement.TopLeft,
      enableArrow: false,
      radius: 5,
      popupColor: Color.Transparent,
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 },
      onStateChange: (e) => {
        if (!e.isVisible) {
          this.showTranslationMenu = false;
          this.translationMenuMessage = undefined;
        }
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (!this.translationDisplayManager.isTranslating(message.msgID)) {
            this.translationMenuMessage = message;
            this.showTranslationMenu = true;
          }
        })
    )
  }

  /**
   * ASR Text Menu Builder - Floating menu for ASR text bubble
   */
  @Builder
  AsrTextMenuBuilder() {
    AuxiliaryTextPopupMenu({
      menuItems: [
        // Hide button - temporarily hidden, will be re-enabled in future version
        {
          text: $r('app.string.action_hide'),
          icon: $rawfile('messagelist/icon_extion_delete.svg'),
          hidden: true,
          onClick: () => {
            if (this.asrMenuMessage) {
              this.asrDisplayManager.collapse(this.asrMenuMessage.msgID);
            }
            this.showAsrMenu = false;
            this.asrMenuMessage = undefined;
          }
        },
        // Forward button
        {
          text: $r('app.string.action_forward'),
          icon: $rawfile('messagelist/icon_extion_forward.svg'),
          useIntrinsicIconColor: true,
          onClick: () => {
            if (this.asrMenuMessage && this.onAsrBubbleLongPress) {
              this.onAsrBubbleLongPress(this.asrMenuMessage);
            }
            this.showAsrMenu = false;
            this.asrMenuMessage = undefined;
          }
        },
        // Copy button
        {
          text: $r('app.string.action_copy'),
          icon: $rawfile('messagelist/icon_extion_copy.svg'),
          onClick: () => {
            if (this.asrMenuMessage) {
              const audioPayload = this.asrMenuMessage.messagePayload as AudioMessagePayload | undefined;
              const asrText = audioPayload?.asrText ?? '';
              if (asrText.length > 0) {
                this.copyAsrText(asrText);
              }
            }
            this.showAsrMenu = false;
            this.asrMenuMessage = undefined;
          }
        }
      ]
    })
  }

  /**
   * Copy ASR text to clipboard
   */
  private copyAsrText(asrText: string) {
    if (!asrText || asrText.length === 0) {
      return;
    }

    let pasteData = clipboard.createData(clipboard.MIMETYPE_TEXT_PLAIN, asrText);
    let systemPasteboard = clipboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData, (err) => {
      if (err) {
        console.error('[MessageItem] Copy ASR text failed:', err);
        Toast.info($r('app.string.messagelist_copy_failed'), this.getUIContext());
      } else {
        Toast.info($r('app.string.messagelist_copied'), this.getUIContext());
      }
    });
  }

  /**
   * Translation Text Menu Builder - Floating menu for translation text bubble
   */
  @Builder
  TranslationTextMenuBuilder() {
    AuxiliaryTextPopupMenu({
      menuItems: [
        // Hide button - temporarily hidden, will be re-enabled in future version
        {
          text: $r('app.string.action_hide'),
          icon: $rawfile('messagelist/icon_extion_delete.svg'),
          hidden: true,
          onClick: () => {
            if (this.translationMenuMessage) {
              // Collapse translation display
              this.translationDisplayManager.collapse(this.translationMenuMessage.msgID);
            }
            this.showTranslationMenu = false;
            this.translationMenuMessage = undefined;
          }
        },
        // Forward button
        {
          text: $r('app.string.action_forward'),
          icon: $rawfile('messagelist/icon_extion_forward.svg'),
          useIntrinsicIconColor: true,
          onClick: () => {
            if (this.translationMenuMessage && this.onTranslationBubbleLongPress) {
              // Forward translated text - need to call MessageList method
              this.onTranslationBubbleLongPress(this.translationMenuMessage);
            }
            this.showTranslationMenu = false;
            this.translationMenuMessage = undefined;
          }
        },
        // Copy button
        {
          text: $r('app.string.action_copy'),
          icon: $rawfile('messagelist/icon_extion_copy.svg'),
          onClick: () => {
            if (this.translationMenuMessage) {
              const translatedText = this.getTranslatedText(this.translationMenuMessage);
              if (translatedText.length > 0) {
                this.copyTranslatedText(translatedText);
              }
            }
            this.showTranslationMenu = false;
            this.translationMenuMessage = undefined;
          }
        }
      ]
    })
  }

  /**
   * Copy translated text to clipboard
   */
  private copyTranslatedText(translatedText: string) {
    if (!translatedText || translatedText.length === 0) {
      return;
    }

    let pasteData = clipboard.createData(clipboard.MIMETYPE_TEXT_PLAIN, translatedText);
    let systemPasteboard = clipboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData, (err) => {
      if (err) {
        console.error('[MessageItem] Copy translated text failed:', err);
        Toast.info($r('app.string.messagelist_copy_failed'), this.getUIContext());
      } else {
        Toast.info($r('app.string.messagelist_copied'), this.getUIContext());
      }
    });
  }

  private getEffectiveIsSelf(): boolean {
    if (isCallingC2C(this.message)) {
      const callingProvider = new CallingMessageDataProvider(this.message);
      return callingProvider.direction === CallMessageDirection.outcoming;
    }
    return this.message?.isSentBySelf ?? false;
  }

  private getSideFaceURL(isSelfSide: boolean): string {
    const rawFaceURL = this.message?.rawMessage?.faceURL ?? '';
    if (!isCallingC2C(this.message)) {
      return rawFaceURL;
    }
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    const loginAvatar = LoginStore.shared().state.loginUserInfo?.avatarURL ?? '';
    if (isSelfSide) {
      return loginAvatar;
    }
    const list: MessageInfo[] = this.messageListStore?.state?.messageList ?? [];
    for (let i = list.length - 1; i >= 0; i--) {
      const m: MessageInfo = list[i];
      if (!m) {
        continue;
      }
      const fromID = m.from?.userID ?? '';
      if (fromID.length > 0 && fromID !== loginUserID) {
        const url: string | undefined = m.rawMessage?.faceURL;
        if (url && url.length > 0) {
          return url;
        }
      }
    }
    if (this.message?.from?.userID && this.message.from.userID !== loginUserID && rawFaceURL.length > 0) {
      return rawFaceURL;
    }
    return rawFaceURL;
  }

  private getSideUserID(isSelfSide: boolean): string {
    const fromUserID = this.message?.from?.userID ?? '';
    if (!isCallingC2C(this.message)) {
      return fromUserID;
    }
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    if (isSelfSide) {
      return loginUserID;
    }
    if (fromUserID.length > 0 && fromUserID !== loginUserID) {
      return fromUserID;
    }
    const list: MessageInfo[] = this.messageListStore?.state?.messageList ?? [];
    for (let i = list.length - 1; i >= 0; i--) {
      const m: MessageInfo = list[i];
      if (!m) {
        continue;
      }
      const id = m.from?.userID ?? '';
      if (id.length > 0 && id !== loginUserID) {
        return id;
      }
    }
    return fromUserID;
  }

  build() {
    Column() {
      if (this.effectiveConfig.alignment === MessageAlignment.LEFT) {
        this.MessageItemRow(true);
      } else if (this.effectiveConfig.alignment === MessageAlignment.RIGHT) {
        this.MessageItemRow(false);
      } else {
        this.MessageItemRow(!this.getEffectiveIsSelf());
      }
    }
    .enabled(!this.isMultiSelectMode)
  }

  private isCenteredStandaloneMessage(): boolean {
    if (this.message.messageType === MessageType.TIPS) {
      return true;
    }
    return this.message.messageType === MessageType.CUSTOM && !isCallingC2C(this.message) &&
      !isBusinessCustomMessage(this.message);
  }

  private shouldRenderCenteredStandaloneMessage(): boolean {
    if (this.message.messageType === MessageType.TIPS) {
      return this.effectiveConfig.isShowSystemMessage === true;
    }
    return !shouldHideMessageEntirely(this.message);
  }

  @Builder
  CenteredStandaloneMessage() {
    if (this.shouldRenderCenteredStandaloneMessage()) {
      Row() {
        GetMessageView(this.createRenderContext());
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 8 })
      .onClick(() => {
        this.handleItemTapForDismiss();
      })
    }
  }

  @Builder
  MessageItemRow(isLeftSide: boolean) {
    Column() {
      if (this.isCenteredStandaloneMessage()) {
        this.CenteredStandaloneMessage()
      } else {
        Row() {
          if (isLeftSide) {
            this.LeftAvatarSlot()
          }

          Column() {
            if (isLeftSide ? this.effectiveConfig.isShowLeftNickname : this.effectiveConfig.isShowRightNickname) {
              this.NicknameView()
            }

            Row() {
              if (!isLeftSide) {
                this.RightSideStatusCluster()
              }
              this.MessageBubble(this.message)
            }
            .alignItems(VerticalAlign.Bottom)
            .alignSelf(isLeftSide ? ItemAlign.Start : ItemAlign.End)

            this.QuoteBubble(this.message, isLeftSide)

            if (this.shouldShowAsrBubble(this.message)) {
              this.AsrTextBubble(this.message)
            }

            if (this.shouldShowTranslationBubble(this.message)) {
              this.TranslationTextBubble(this.message)
            }

            if (this.message.status === MessageStatus.VIOLATION) {
              Text($r('app.string.messagelist_violation_warning'))
                .fontSize(12)
                .fontColor(this.themeState.colors.textColorError)
                .margin({ top: 4 })
            }
          }
          .flexShrink(1)
          .alignItems(isLeftSide ? HorizontalAlign.Start : HorizontalAlign.End)

          if (!isLeftSide) {
            this.RightAvatarSlot()
          }
        }
        .alignItems(VerticalAlign.Top)
        .width('100%')
        .justifyContent(isLeftSide ? FlexAlign.Start : FlexAlign.End)
        .onClick(() => {
          this.handleItemTapForDismiss();
        })
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction((event: GestureEvent) => {
              console.log('[MessageItem] LongPress detected');
              this.handleMessageLongPress();
            })
        )
        .bindPopup(
          this.showClassicActionPopup &&
          this.effectiveConfig.messageActionStyle === 'popup' &&
          this.message.status !== MessageStatus.REVOKED &&
          this.message.status !== MessageStatus.VIOLATION,
          {
            builder: this.ClassicActionPopupBuilder,
            placement: this.getEffectiveIsSelf() ? Placement.TopRight : Placement.TopLeft,
            arrowOffset: this.getActionPopupArrowOffset(),
            offset: { x: 0, y: 0 },
            enableArrow: true,
            mask: false,
            radius: 7,
            popupColor: this.themeState.colors.dropdownColorDefault,
            backgroundBlurStyle: BlurStyle.NONE,
            shadow: { radius: 8, color: '#33000000', offsetX: 0, offsetY: 2 },
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.showClassicActionPopup = false;
              }
            }
          })
      }
    }
  }

  @Builder
  LeftAvatarSlot() {
    if (this.shouldShowAvatarValue) {
      Stack() {
        this.AvatarView(this.getSideFaceURL(false), this.getSideUserID(false))
      }
      .margin({ right: this.effectiveConfig.avatarSpacing ?? 8 })
    } else if (this.effectiveConfig.isShowLeftAvatar ?? true) {
      Stack() {}
        .width(40)
        .height(40)
        .margin({ right: this.effectiveConfig.avatarSpacing ?? 8 })
    }
  }

  @Builder
  RightAvatarSlot() {
    if (this.shouldShowAvatarValue) {
      Stack() {
        this.AvatarView(this.getSideFaceURL(true), this.getSideUserID(true))
      }
      .margin({ left: this.effectiveConfig.avatarSpacing ?? 8, top: -1 })
    }
  }

  @Builder
  RightSideStatusCluster() {
    if (this.shouldShowAudioSendingIndicator()) {
      LoadingProgress()
        .width(12)
        .height(12)
        .margin({ right: 4 })
    }

    if (this.message.status === MessageStatus.SEND_FAIL || this.message.status === MessageStatus.VIOLATION) {
      Image($rawfile('messagelist/icon_message_send_error.svg'))
        .width(16)
        .height(16)
        .margin({ right: 4 })
        .onClick(() => {
          if (this.message.status === MessageStatus.SEND_FAIL) {
            this.showResendConfirmDialog();
          }
        })
    }

    this.ReadReceiptLabel()
  }

  private updateAvatarVisibility(): void {
    const newValue = this.shouldShowAvatar(this.effectiveConfig.alignment ?? MessageAlignment.LEFT);
    this.shouldShowAvatarValue = newValue;
  }

  private shouldShowAvatar(alignment: MessageAlignment): boolean {
    return true;
  }

  private showResendConfirmDialog(): void {
    const actionItems: ActionItem[] = [
      {
        text: $r('app.string.action_resend'),
        value: 'resend'
      }
    ];

    this.resendDialogController = new CustomDialogController({
      builder: ActionSheet({
        title: $r('app.string.resend_confirm_title'),
        options: actionItems,
        showCancel: true,
        cancelText: $r('app.string.cancel'),
        onActionSelected: (item: ActionItem) => {
          if (item.value === 'resend') {
            this.handleResendMessage();
          }
        },
        onDismiss: () => {
          console.log('[MessageItem] Resend dialog dismissed');
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.resendDialogController.open();
  }

  private handleResendMessage(): void {
    if (!this.inputStore || !this.message) {
      console.error('[MessageItem] Cannot resend message: inputStore or message is null');
      Toast.info($r('app.string.messagelist_resend_failed'), this.getUIContext());
      return;
    }

    console.info('[MessageItem] Resending original message:', this.message.msgID);

    const payload = this.buildSendMessagePayload(this.message);
    if (!payload) {
      Toast.info($r('app.string.messagelist_resend_failed'), this.getUIContext());
      return;
    }
    const option = this.buildSendMessageOption(this.message);

    const sendNewMessage = (): void => {
      this.inputStore!.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
        console.info('[MessageItem] Message resent successfully');
        Toast.info($r('app.string.messagelist_resend_success'), this.getUIContext());
      }, (code: number, desc: string) => {
        const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + (desc ?? ''));
        Toast.info(localizedMessage, this.getUIContext());
      }));
    };

    if (this.message.rawMessage) {
      MessageActionStore.create(this.message).delete(new CompletionHandlerAdapter(() => {
        sendNewMessage();
      }, (code: number, desc: string) => {
        console.warn('[MessageItem] Delete failed message before resend failed:', code, desc);
        sendNewMessage();
      }));
    } else {
      sendNewMessage();
    }
  }

  private buildSendMessagePayload(message: MessageInfo): SendMessagePayload | undefined {
    return MessageResendPayloadFactory.buildPayload(message);
  }

  private buildSendMessageOption(message: MessageInfo): SendMessageOption {
    return MessageResendPayloadFactory.buildOption(message);
  }

  private showReactionDetail() {
    if (!this.message.reactionList || this.message.reactionList.length === 0) {
      return;
    }

    if (this.displayMode === MessageDisplayMode.Merged) {
      console.info('[MessageItem] Reaction click ignored in merged message detail view');
      return;
    }

    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID ?? '';

    this.reactionDetailController = new CustomDialogController({
      builder: ReactionDetailSheet({
        reactionList: this.message.reactionList,
        currentUserID: currentUserID,
        onFetchUsers: (reactionID: string) => {
          if (this.messageActionStore) {
            this.messageActionStore.loadReactionUsers(reactionID, 50);
          }
        },
        onRemoveReaction: (reactionID: string) => {
          if (this.messageActionStore) {
            this.messageActionStore.removeReaction(reactionID);
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.reactionDetailController.open();
  }
}