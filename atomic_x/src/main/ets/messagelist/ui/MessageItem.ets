import { MessageInfo, MessageType, MessageListStore, MessageStatus, CustomMessagePayload, TextMessagePayload, AudioMessagePayload, ImageMessagePayload, VideoMessagePayload, FileMessagePayload, FaceMessagePayload } from '@tencentcloud/atomicxcore';
import { MessageInputStore, SendMessagePayload, TextSendMessagePayload, ImageSendMessagePayload, VideoSendMessagePayload, AudioSendMessagePayload, FileSendMessagePayload, FaceSendMessagePayload, CustomSendMessagePayload, SendMessageOption } from '@tencentcloud/atomicxcore';
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
import { LengthMetrics } from '@kit.ArkUI';
import clipboard from '@ohos.pasteboard';
import { IMErrorCode } from '../../basecomponent/utils/IMErrorCode';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';
import { MessageReactionBar } from './MessageReactionBar';
import { ReactionDetailSheet } from './ReactionDetailSheet';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { AuxiliaryTextPopupMenu, AuxiliaryTextMenuItemConfig } from './AuxiliaryTextPopupMenu';
import { ClassicMessageActionPopup, ClassicCustomActionItem } from './ClassicMessageActionPopup';
import { MessageQuoteBubbleView } from '../cells/MessageQuoteBubbleView';
import { EventBus } from '../../basecomponent/utils/EventBus';
import { MessageQuoteEvent } from './MessageQuoteEvent';
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';
import { MessageUtils, ReadReceiptLabelInfo } from '../utils/MessageUtils';
import { TranslationTextParser } from '../utils/TranslationTextParser';
import { CallMessageView, CallMessageBubbleView, shouldHideCallingMessage } from '../cells/CallMessageView';
import { CallingMessageDataProvider, CallParticipantType, CallMessageDirection } from '../utils/CallingMessageDataProvider';

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
  const customPayload = message.messagePayload as CustomMessagePayload | undefined;
  if (!customPayload) {
    return false;
  }
  return isGroupCreated(customPayload);
}

function isBusinessCustomMessage(message: MessageInfo): boolean {
  if (message.messageType !== MessageType.CUSTOM) {
    return false;
  }
  if (isGroupCreatedMessage(message)) {
    return false;
  }
  if (isCallingC2C(message) || isCallingGroup(message) || isCallingSignal(message)) {
    return false;
  }
  return true;
}

function isGroupCreated(customPayload: CustomMessagePayload): boolean {
  const dataStr = customPayload.customData;
  if (dataStr) {
    try {
      const customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
      if (customInfo["businessID"] === 'group_create') {
        return true;
      }
      return false;
    } catch (error) {
      console.error('[MessageItem] isGroupCreated error:', error);
      return false;
    }
  }
  return false;
}

function isCallingSignal(message: MessageInfo): boolean {
  const callingProvider = new CallingMessageDataProvider(message);
  return callingProvider.isCallingSignal;
}

function isCallingC2C(message: MessageInfo): boolean {
  const callingProvider = new CallingMessageDataProvider(message);
  return callingProvider.isCallingSignal && callingProvider.participantType === CallParticipantType.c2c;
}

function isCallingGroup(message: MessageInfo): boolean {
  const callingProvider = new CallingMessageDataProvider(message);
  return callingProvider.isCallingSignal && callingProvider.participantType === CallParticipantType.group;
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
          avatarSize: AvatarSize.S
        })
      }
      .width(32)
      .height(32)
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
    return this.message.messageType === MessageType.IMAGE || this.message.messageType === MessageType.VIDEO;
  }

  /**
   * Get bubble background color based on message type and display mode
   */
  private getBubbleBackgroundColor(): ResourceColor {
    if (this.shouldHideBubbleBackground()) {
      return Color.Transparent;
    }

    return this.getEffectiveIsSelf() ?
      this.themeState.colors.bgColorBubbleOwn :
      this.themeState.colors.bgColorBubbleReciprocal;
  }

  /**
   * Get bubble border color (same as background color)
   */
  private getBubbleBorderColor(): ResourceColor {
    return this.shouldHideBubbleBackground() ? Color.Transparent : this.getBubbleBackgroundColor();
  }

  /**
   * Get bubble border width
   */
  private getBubbleBorderWidth(): number {
    return this.shouldHideBubbleBackground() ? 0 : 1;
  }

  /**
   * Get bubble border radius
   */
  private getBubbleBorderRadius(): number {
    return this.shouldHideBubbleBackground() ? 0 : 16;
  }

  /**
   * Handle long press based on message action style
   * For 'popup' style: show classic popup
   * For 'dialog' style: call onLongPress callback (default behavior)
   */
  private handleMessageLongPress() {
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
      }
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
    } else if (this.getMessageEffectiveIsSelf(message)) {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
      }
      .flexShrink(1)
      .borderRadius({
        topStart: LengthMetrics.vp(16),
        topEnd: LengthMetrics.vp(16),
        bottomStart: LengthMetrics.vp(16),
        bottomEnd: LengthMetrics.vp(0)
      } as LocalizedBorderRadiuses)
      .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.55)' : this.themeState.colors.bgColorBubbleOwn)
      .borderColor(this.themeState.colors.bgColorBubbleOwn)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
    } else {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
      }
      .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.55)' : this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius({
        topStart: LengthMetrics.vp(16),
        topEnd: LengthMetrics.vp(16),
        bottomStart: LengthMetrics.vp(0),
        bottomEnd: LengthMetrics.vp(16)
      } as LocalizedBorderRadiuses)
      .flexShrink(1)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
    }
  }

  @Builder
  QuoteBubble(message: MessageInfo) {
    if (message.quoteInfo) {
      Column() {
        MessageQuoteBubbleView({
          quoteInfo: message.quoteInfo,
          onQuoteClick: () => {
            EventBus.getInstance().post(MessageQuoteEvent.LOCATE_QUOTED_MESSAGE, {
              'msgID': message.quoteInfo!.msgID,
              'sequence': message.quoteInfo!.sequence,
              'timestamp': message.quoteInfo!.timestamp
            });
          }
        })
      }
      .margin({ top: 4 })
      .alignItems(message.isSentBySelf ? HorizontalAlign.End : HorizontalAlign.Start)
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
        this.messageAlignmentLeftStyle();
      } else if (this.effectiveConfig.alignment === MessageAlignment.RIGHT) {
        this.messageAlignmentRightStyle();
      } else {
        this.messageAlignmentTwosideStyle();
      }
    }
    .enabled(!this.isMultiSelectMode)
  }

  @Builder
  messageAlignmentLeftStyle() {
    Column() {
      if (this.message.messageType === MessageType.TIPS) {
        if (this.effectiveConfig.isShowSystemMessage) {
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
      } else if (this.message.messageType === MessageType.CUSTOM && !isCallingC2C(this.message) && !isBusinessCustomMessage(this.message)) {
        if (!shouldHideCallingMessage(this.message)) {
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
      } else {
        Row() {
          if (this.shouldShowAvatarValue) {
            Stack() {
              this.AvatarView(this.getSideFaceURL(this.getEffectiveIsSelf()), this.getSideUserID(this.getEffectiveIsSelf()))
            }
            .margin({ right: this.effectiveConfig.avatarSpacing ?? 6 })
          }

          Column() {
            // In merged mode, always show nickname above bubble for all messages
            // In normal LEFT mode, only show nickname for non-self messages above bubble
            if (this.displayMode === MessageDisplayMode.Merged) {
              // Merged mode: show nickname above bubble for all messages
              if (this.getEffectiveIsSelf() ? this.effectiveConfig.isShowRightNickname : this.effectiveConfig.isShowLeftNickname) {
                this.NicknameView()
              }
            } else {
              // Normal LEFT mode: only show nickname for non-self messages
              if (!this.getEffectiveIsSelf() && this.effectiveConfig.isShowLeftNickname) {
                this.NicknameView()
              }
            }
            
            Column() {
              GetMessageView(this.createRenderContext());
            }
            .borderRadius(this.getBubbleBorderRadius())
            .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.55)' : this.getBubbleBackgroundColor())
            .borderWidth(this.getBubbleBorderWidth())
            .borderColor(this.getBubbleBorderColor())
            .flexShrink(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Start)
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
            
            // ASR text bubble (separate from voice bubble)
            if (this.shouldShowAsrBubble(this.message)) {
              this.AsrTextBubble(this.message)
            }
            
            // Translation text bubble (separate from text bubble)
            if (this.shouldShowTranslationBubble(this.message)) {
              this.TranslationTextBubble(this.message)
            }
            
            // Show reaction bar
            if (this.effectiveConfig.isSupportReaction && this.message.reactionList && this.message.reactionList.length > 0) {
              MessageReactionBar({
                reactionList: this.message.reactionList,
                onClickCallback: () => {
                  this.showReactionDetail();
                }
              })
            }
            
            // Show violation warning for sensitive content
      if (this.message.status === MessageStatus.VIOLATION) {
              Text($r('app.string.messagelist_violation_warning'))
                .fontSize(12)
                .fontColor(this.themeState.colors.textColorError)
                .margin({ top: 4 })
            }
            
            // In normal LEFT mode, show nickname below bubble for self messages
            if (this.displayMode !== MessageDisplayMode.Merged) {
              if (this.getEffectiveIsSelf() && this.effectiveConfig.isShowRightNickname) {
                this.NicknameView()
              }
            }
          }
          .flexShrink(1)
          .alignItems(HorizontalAlign.Start)

          if (this.shouldShowAudioSendingIndicator()) {
            LoadingProgress()
              .width(12)
              .height(12)
              .margin({ left: 4 })
          }

      if (this.getEffectiveIsSelf() && (this.message.status === MessageStatus.SEND_FAIL || this.message.status === MessageStatus.VIOLATION)) {
            Image($rawfile('messagelist/icon_message_send_error.svg'))
              .width(16)
              .height(16)
              .margin({ left: 4 })
              .onClick(() => {
                // Only show resend dialog for sendFail, not for violation
      if (this.message.status === MessageStatus.SEND_FAIL) {
                  this.showResendConfirmDialog();
                }
              })
          }

          // Read receipt label outside bubble
          if (this.getEffectiveIsSelf()) {
            this.ReadReceiptLabel()
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)
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
          enableArrow: false,
          mask: false,
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.showClassicActionPopup = false;
            }
          }
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  messageAlignmentRightStyle() {
    Column() {
      if (this.message.messageType === MessageType.TIPS) {
        if (this.effectiveConfig.isShowSystemMessage) {
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
      } else if (this.message.messageType === MessageType.CUSTOM && !isCallingC2C(this.message) && !isBusinessCustomMessage(this.message)) {
        if (!shouldHideCallingMessage(this.message)) {
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
      } else {
        Row() {
          // Read receipt label outside bubble
          if (this.getEffectiveIsSelf()) {
            this.ReadReceiptLabel()
          }

          if (this.shouldShowAudioSendingIndicator()) {
            LoadingProgress()
              .width(12)
              .height(12)
              .margin({ right: 4 })
          }

      if (this.getEffectiveIsSelf() && (this.message.status === MessageStatus.SEND_FAIL || this.message.status === MessageStatus.VIOLATION)) {
            Image($rawfile('messagelist/icon_message_send_error.svg'))
              .width(16)
              .height(16)
              .margin({ right: 4 })
              .onClick(() => {
                // Only show resend dialog for sendFail, not for violation
      if (this.message.status === MessageStatus.SEND_FAIL) {
                  this.showResendConfirmDialog();
                }
              })
          }
          Column() {
            // Show nickname for left messages (others)
            if (!this.getEffectiveIsSelf() && this.effectiveConfig.isShowLeftNickname) {
              this.NicknameView()
            }
            
            Column() {
              GetMessageView(this.createRenderContext());
            }
            .borderRadius(this.getBubbleBorderRadius())
            .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.55)' : this.getBubbleBackgroundColor())
            .borderWidth(this.getBubbleBorderWidth())
            .borderColor(this.getBubbleBorderColor())
            .flexShrink(1)
            .alignItems(HorizontalAlign.End)
            .justifyContent(FlexAlign.End)
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
            
            // ASR text bubble (separate from voice bubble)
            if (this.shouldShowAsrBubble(this.message)) {
              this.AsrTextBubble(this.message)
            }
            
            // Translation text bubble (separate from text bubble)
            if (this.shouldShowTranslationBubble(this.message)) {
              this.TranslationTextBubble(this.message)
            }
            
            // Show reaction bar
            if (this.effectiveConfig.isSupportReaction && this.message.reactionList && this.message.reactionList.length > 0) {
              MessageReactionBar({
                reactionList: this.message.reactionList,
                onClickCallback: () => {
                  this.showReactionDetail();
                }
              })
            }
            
            // Show nickname for right messages (self)
            if (this.getEffectiveIsSelf() && this.effectiveConfig.isShowRightNickname) {
              this.NicknameView()
            }
          }
          .flexShrink(1)
          .alignItems(HorizontalAlign.End)

          if (this.shouldShowAvatarValue) {
            Stack() {
              this.AvatarView(this.getSideFaceURL(this.getEffectiveIsSelf()), this.getSideUserID(this.getEffectiveIsSelf()))
            }
            .margin({ left: this.effectiveConfig.avatarSpacing ?? 6 })
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.End)
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
          enableArrow: false,
          mask: false,
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.showClassicActionPopup = false;
            }
          }
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  messageAlignmentTwosideStyle() {
    Column() {
      if (this.message.messageType === MessageType.TIPS) {
        if (this.effectiveConfig.isShowSystemMessage) {
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
      } else if (this.message.messageType === MessageType.CUSTOM && !isCallingC2C(this.message) && !isBusinessCustomMessage(this.message)) {
        if (!shouldHideCallingMessage(this.message)) {
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
      } else {
        Row() {
          if (this.getEffectiveIsSelf()) {
            // Sender's message (right side)
            Row() {
              Column() {
                // Show nickname for right messages (self)
                if (this.effectiveConfig.isShowRightNickname) {
                  this.NicknameView()
                }

                // Read receipt + main bubble in the same row, bottom-aligned
                // so the read label sticks to the bottom-left of the main bubble,
                // not to the bottom of the whole stack (bubble + quote + reaction).
                Row() {
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
                        // Only show resend dialog for sendFail, not for violation
                        if (this.message.status === MessageStatus.SEND_FAIL) {
                          this.showResendConfirmDialog();
                        }
                      })
                  }

                  this.ReadReceiptLabel()

                  this.MessageBubble(this.message)
                }
                .alignItems(VerticalAlign.Bottom)
                .alignSelf(ItemAlign.End)

                this.QuoteBubble(this.message)

                // ASR text bubble (separate from voice bubble)
                if (this.shouldShowAsrBubble(this.message)) {
                  this.AsrTextBubble(this.message)
                }
                
                // Translation text bubble (separate from text bubble)
                if (this.shouldShowTranslationBubble(this.message)) {
                  this.TranslationTextBubble(this.message)
                }
                
                // Show reaction bar
                if (this.effectiveConfig.isSupportReaction && this.message.reactionList && this.message.reactionList.length > 0) {
                  MessageReactionBar({
                    reactionList: this.message.reactionList,
                    onClickCallback: () => {
                      this.showReactionDetail();
                    }
                  })
                }
                
                // Show violation warning for sensitive content
      if (this.message.status === MessageStatus.VIOLATION) {
                  Text($r('app.string.messagelist_violation_warning'))
                    .fontSize(12)
                    .fontColor(this.themeState.colors.textColorError)
                    .margin({ top: 4 })
                }
              }
              .flexShrink(1)
              .alignItems(HorizontalAlign.End)

              // Avatar on the right side for sender
              if (this.shouldShowAvatarValue) {
                Stack() {
                  this.AvatarView(this.getSideFaceURL(true), this.getSideUserID(true))
                }
                .margin({ left: this.effectiveConfig.avatarSpacing ?? 6 })
              }
            }
            .width('90%')
            .justifyContent(FlexAlign.End)
          } else {
            Row() {
              // Avatar or placeholder for alignment in grouped messages
              if (this.shouldShowAvatarValue) {
                Stack() {
                  this.AvatarView(this.getSideFaceURL(false), this.getSideUserID(false))
                }
                .margin({ right: this.effectiveConfig.avatarSpacing ?? 6 })
              } else if (this.effectiveConfig.isShowLeftAvatar ?? true) {
                // When avatar should not be shown but left avatar is enabled,
                // render empty space with same dimensions for alignment
                Stack() {}
                  .width(32)
                  .height(32)
                  .margin({ right: this.effectiveConfig.avatarSpacing ?? 6 })
              }

              Column() {
                // Show nickname for left messages (others)
                if (this.effectiveConfig.isShowLeftNickname) {
                  this.NicknameView()
                }
                
                this.MessageBubble(this.message)
                this.QuoteBubble(this.message)
                
                // ASR text bubble (separate from voice bubble)
                if (this.shouldShowAsrBubble(this.message)) {
                  this.AsrTextBubble(this.message)
                }
                
                // Translation text bubble (separate from text bubble)
                if (this.shouldShowTranslationBubble(this.message)) {
                  this.TranslationTextBubble(this.message)
                }
                
            // Show reaction bar
            if (this.effectiveConfig.isSupportReaction && this.message.reactionList && this.message.reactionList.length > 0) {
              MessageReactionBar({
                reactionList: this.message.reactionList,
                onClickCallback: () => {
                  this.showReactionDetail();
                }
              })
            }
          }
          .alignItems(HorizontalAlign.Start)
            }
            .width('80%')
            .justifyContent(FlexAlign.Start)
          }
        }
        .width('100%')
        .justifyContent(this.getEffectiveIsSelf() ? FlexAlign.End : FlexAlign.Start)
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
          enableArrow: false,
          mask: false,
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.showClassicActionPopup = false;
            }
          }
        })
      }
    }
  }

  private updateAvatarVisibility(): void {
    const newValue = this.shouldShowAvatar(this.effectiveConfig.alignment ?? MessageAlignment.LEFT);
    this.shouldShowAvatarValue = newValue;
  }

  private shouldShowAvatar(alignment: MessageAlignment): boolean {
    // In classic UI mode, always show avatars for both sender and receiver
    if (AppBuilderConfig.getInstance().useClassicUI) {
      return true;
    }
    
    switch (alignment) {
      case MessageAlignment.LEFT:
        // In LEFT mode, always show avatar based on style configuration
          return true;
      case MessageAlignment.RIGHT:
        // In RIGHT mode, always show avatar based on style configuration
          return  true
      case MessageAlignment.TWO_SIDED:
      default:
        // In TWO_SIDED mode, respect both showAvatar flag and style configuration
        if (this.getEffectiveIsSelf()) {
          const showRight = this.effectiveConfig.isShowRightAvatar ?? false;
          return showRight;
        } else {
          return this.showAvatar && (this.effectiveConfig.isShowLeftAvatar ?? true);
        }
    }
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
    const payload = message.messagePayload;
    if (payload instanceof TextMessagePayload) {
      const text = payload.text;
      if (!text || text.length === 0) {
        return undefined;
      }
      return new TextSendMessagePayload(text);
    }
    if (payload instanceof ImageMessagePayload) {
      const imagePath = payload.originalImagePath;
      if (!imagePath || imagePath.length === 0) {
        return undefined;
      }
      return new ImageSendMessagePayload(imagePath, payload.originalImageWidth, payload.originalImageHeight);
    }
    if (payload instanceof VideoMessagePayload) {
      const videoPath = payload.videoPath;
      if (!videoPath || videoPath.length === 0) {
        return undefined;
      }
      return new VideoSendMessagePayload(
        videoPath,
        payload.videoType ?? '',
        payload.videoDuration,
        payload.videoSnapshotPath ?? '',
        payload.videoSnapshotWidth,
        payload.videoSnapshotHeight
      );
    }
    if (payload instanceof AudioMessagePayload) {
      const audioPath = payload.audioPath;
      if (!audioPath || audioPath.length === 0) {
        return undefined;
      }
      return new AudioSendMessagePayload(audioPath, payload.audioDuration);
    }
    if (payload instanceof FileMessagePayload) {
      const filePath = payload.filePath;
      if (!filePath || filePath.length === 0) {
        return undefined;
      }
      return new FileSendMessagePayload(filePath, payload.fileName ?? '', payload.fileSize);
    }
    if (payload instanceof FaceMessagePayload) {
      return new FaceSendMessagePayload(payload.faceIndex, payload.faceData ?? '');
    }
    if (payload instanceof CustomMessagePayload) {
      const customData = payload.customData;
      if (!customData || customData.length === 0) {
        return undefined;
      }
      return new CustomSendMessagePayload(
        customData,
        payload.description ?? '',
        payload.extensionInfo ?? ''
      );
    }
    return undefined;
  }

  private buildSendMessageOption(message: MessageInfo): SendMessageOption {
    const option = new SendMessageOption();
    option.atUserList = message.atUserList && message.atUserList.length > 0 ? message.atUserList : undefined;
    option.quotedMessage = undefined;
    option.needReadReceipt = message.needReadReceipt;
    option.isExtensionEnabled = message.isExtensionEnabled;
    option.onlineUserOnly = false;
    option.offlinePushInfo = message.offlinePushInfo;
    return option;
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