import {
  MessageInfo,
  MessageType,
  MessageMediaFileType,
  MessageListStore,
  MessageStatus,
  CustomMessageInfo,
  MessageInputStore,
  ErrorInfo,
  MessageActionStore,
  LoginStore
} from '@tencentcloud/atomicxcore';

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
import { SystemMessageView } from '../cells/SystemMessageView';
import { CreateGroupMessageView } from '../cells/CreateGroupMessageView';
import { util } from '@kit.ArkTS';
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
import { EmojiItem } from '../../emojipicker/data/EmojiData';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';

/**
 * Display mode for MessageItem
 */
export enum MessageDisplayMode {
  Normal = 'normal',   // Normal chat list mode
  Merged = 'merged'    // Merged message detail mode (all messages left-aligned with same bubble color)
}

@Builder
export function GetMessageView(context: MessageRenderContext) {
  if (context.message.messageType == MessageType.Text) {
    TextMessageView(context);
  } else if (context.message.messageType == MessageType.Image) {
    ImageMessageView(context);
  } else if (context.message.messageType == MessageType.File) {
    FileMessageView(context);
  } else if (context.message.messageType == MessageType.Sound) {
    SoundMessageView(context);
  } else if (context.message.messageType == MessageType.Video) {
    VideoMessageView(context);
  } else if (context.message.messageType == MessageType.Face) {
    FaceMessageView(context);
  } else if (context.message.messageType == MessageType.Merged) {
    MergedMessageView(context);
  } else if (context.message.messageType == MessageType.System) {
    SystemMessageView(context);
  } else if (context.message.messageType == MessageType.Custom) {
    // Custom message - handled in MessageItem build method
    if (context.message.messageBody?.customMessage) {
      if (isGroupCreated(context.message.messageBody?.customMessage)) {
        CreateGroupMessageView(context);
      } else {
        SystemMessageView(context);
      }
    } else {
      SystemMessageView(context);
    }
  } else {
    // Unsupported message type
    if ((context.config ?? new ChatMessageListConfig()).isShowUnsupportMessage) {
      TextMessageView(context);
    }
  }
}

function isGroupCreated(customMessage: CustomMessageInfo) {
  const data = customMessage?.data;
  if (data) {
    const textDecoder = new util.TextDecoder('utf-8');
    const dataStr = textDecoder.decode(new Uint8Array(data));
    const customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
    if (customInfo["businessID"] === 'group_create') {
      return true;
    }
    return false;
  }
  return false;
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
  onEmojiReaction?: (emoji: EmojiItem, message: MessageInfo) => void;
  onExpandEmojiPicker?: (message: MessageInfo) => void;

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.showAvatar = this.initialShowAvatar;
    this.updateAvatarVisibility();
    this.downloadMessageViewSource(this.message);

    // Auto-close action popup when message status becomes revoke or violation
    if ((this.message.status === MessageStatus.recalled || this.message.status === MessageStatus.violation)
      && this.showClassicActionPopup) {
      this.showClassicActionPopup = false;
    }
    // Initialize MessageInputStore for resending messages
    if (this.messageListStore.conversationID) {
      this.inputStore = MessageInputStore.create(this.messageListStore.conversationID);
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
    if (!message || !this.messageListStore) {
      return;
    }

    try {

      if (message.messageType === MessageType.Image) {

        this.messageListStore.downloadMessageResource(message, MessageMediaFileType.thumbImage)
          .then(() => {
            console.info('[MessageItem] Successfully downloaded thumb image');
          })
          .catch((error: object) => {
            console.error('[MessageItem] Failed to download thumb image:', error);
          });
      } else if (message.messageType === MessageType.Video) {

        this.messageListStore.downloadMessageResource(message, MessageMediaFileType.videoSnapshot)
          .then(() => {
            console.info('[MessageItem] Successfully downloaded video snapshot');
          })
          .catch((error: object) => {
            console.error('[MessageItem] Failed to download video snapshot:', error);
          });
      } else if (message.messageType === MessageType.Sound) {

        this.messageListStore.downloadMessageResource(message, MessageMediaFileType.sound)
          .then(() => {
            console.info('[MessageItem] Successfully downloaded sound');
          })
          .catch((error: object) => {
            console.error('[MessageItem] Failed to download sound:', error);
          });
      } else if (message.messageType === MessageType.File) {

        console.info('[MessageItem] File message, not downloading automatically');
      }
    } catch (error) {
      console.error('[MessageItem] Error in downloadMessageViewSource:', error);
    }
  }

  @Builder
  AvatarView(url?: string) {
    if (this.shouldShowAvatarValue) {
      Stack() {
        Avatar({
          content: {
            type: AvatarContentType.Image,
            name: this.message.sender?.userID || '',
            url: url || '',
          },
          avatarSize: AvatarSize.S
        })
      }
      .width(32)
      .height(32)
      .onClick(() => {
        if (!this.message.isSelf && this.onUserClick && this.message.sender?.userID) {
          this.onUserClick(this.message.sender.userID);
        } 
      })
      .gesture(
        LongPressGesture({ repeat: false, duration: 500 })
          .onAction(() => {
            // Long press on avatar triggers @ mention (only for non-self messages)
            if (!this.message.isSelf && this.onUserLongPress && this.message.sender?.userID) {
              const userID = this.message.sender.userID;
              const nickname = this.message.sender.nickname || userID;
              this.onUserLongPress(userID, nickname);
            }
          })
      )
    }
  }

  @Builder
  NicknameView() {
    Text(this.message.sender?.nickname || this.message.sender?.userID || '')
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
        .fontColor(this.message.isSelf ?
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
    return (this.effectiveConfig.isShowTimeInBubble ?? false) && message.messageType === MessageType.Text;
  }

  /**
   * Check if message should hide bubble background (for image and video messages)
   */
  private shouldHideBubbleBackground(): boolean {
    return this.message.messageType === MessageType.Image || this.message.messageType === MessageType.Video;
  }

  /**
   * Get bubble background color based on message type and display mode
   */
  private getBubbleBackgroundColor(): ResourceColor {
    if (this.shouldHideBubbleBackground()) {
      return Color.Transparent;
    }
    
    if (this.displayMode === MessageDisplayMode.Merged) {
      return this.themeState.colors.bgColorBubbleReciprocal;
    }
    
    return this.message.isSelf ? 
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

  @Builder
  MessageBubble(message: MessageInfo) {

    if (message.messageType === MessageType.System || message.messageType === MessageType.Custom) {

      Text("")
        .width(0)
        .height(0)
    } else if (message.messageType === MessageType.Image || message.messageType === MessageType.Video) {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
      }
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
    } else if (message.isSelf) {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
      }
      .borderRadius({
        topStart: LengthMetrics.vp(16),
        topEnd: LengthMetrics.vp(16),
        bottomStart: LengthMetrics.vp(16),
        bottomEnd: LengthMetrics.vp(0)
      } as LocalizedBorderRadiuses)
      .backgroundColor(this.themeState.colors.bgColorBubbleOwn)
      .borderColor(this.themeState.colors.bgColorBubbleOwn)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
    } else {
      Column() {
        GetMessageView(this.createRenderContext(message));
        this.TimeInBubbleView();
      }
      .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius({
        topStart: LengthMetrics.vp(16),
        topEnd: LengthMetrics.vp(16),
        bottomStart: LengthMetrics.vp(0),
        bottomEnd: LengthMetrics.vp(16)
      } as LocalizedBorderRadiuses)
      .flexShrink(1)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
    }
  }

  /**
   * Check if ASR text bubble should be shown
   * Returns true if converting or if has asrText and is expanded
   */
  private shouldShowAsrBubble(message: MessageInfo): boolean {
    if (message.messageType !== MessageType.Sound) {
      return false;
    }
    
    // Access version to trigger reactivity when AsrDisplayManager changes
    const _ = this.asrDisplayManager.version;
    
    const isConverting = this.asrDisplayManager.isConverting(message.msgID);
    if (isConverting) {
      return true;
    }
    
    const isExpanded = this.asrDisplayManager.isExpanded(message.msgID);
    if (!isExpanded) {
      return false;
    }
    
    const asrText = message.messageBody?.asrText ?? '';
    return asrText.length > 0;
  }

  /**
   * Check if translation text bubble should be shown
   * Returns true if translating or if has translatedText and is expanded
   */
  private shouldShowTranslationBubble(message: MessageInfo): boolean {
    if (message.messageType !== MessageType.Text) {
      return false;
    }
    
    // Access version to trigger reactivity when TranslationDisplayManager changes
    const _ = this.translationDisplayManager.version;
    
    const isTranslating = this.translationDisplayManager.isTranslating(message.msgID);
    if (isTranslating) {
      return true;
    }
    
    const isExpanded = this.translationDisplayManager.isExpanded(message.msgID);
    if (!isExpanded) {
      return false;
    }
    
    // Get translated text
    const translatedText = this.getTranslatedText(message);
    return translatedText.length > 0;
  }

  /**
   * Get translated text from message
   */
  private getTranslatedText(message: MessageInfo): string {
    const translatedTextMapRaw = message.messageBody?.translatedText;
    const translatedTextMap: Record<string, string> = {};
    if (translatedTextMapRaw) {
      translatedTextMapRaw.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });
    }
    const originalText = message.messageBody?.text ?? '';
    const translated = translatedTextMap[originalText];
    return translated ?? '';
  }

  /**
   * ASR Text Bubble - Separate bubble below voice message
   */
  @Builder
  AsrTextBubble(message: MessageInfo) {
    Column() {
      if (this.asrDisplayManager?.isConverting(message.msgID) ?? false) {
        // Loading state
        LoadingProgress()
          .width(16)
          .height(16)
          .color(message.isSelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
      } else {
        // Text display state
        Text(message.messageBody?.asrText ?? '')
          .fontSize(14)
          .fontColor(message.isSelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
      }
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(message.isSelf ? this.themeState.colors.bgColorBubbleOwn :
    this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(12)
    .margin({ top: 10 })
    .bindPopup(this.showAsrMenu && this.asrMenuMessage?.msgID === message.msgID, {
      builder: this.AsrTextMenuBuilder,
      placement: message.isSelf ? Placement.TopRight : Placement.TopLeft,
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
          // Only show menu when not in loading state
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
        // Loading state
        LoadingProgress()
          .width(16)
          .height(16)
          .color(message.isSelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorPrimary)
      } else {
        // Text display with bottom tips
        Column({ space: 6 }) {
          // Translation text content with emoji support
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
          .fontColor(message.isSelf ? this.themeState.colors.textColorAntiPrimary :
            this.themeState.colors.textColorPrimary)
          .textOverflow({ overflow: TextOverflow.None })
          .maxLines(999)
          .wordBreak(WordBreak.BREAK_ALL)
          
          // Bottom tips: checkmark icon + "Powered by Tencent Cloud IM"
          Row({ space: 4 }) {
            // Check circle icon (matching Flutter Icons.check_circle)
            Image($rawfile('basecomponent/check_circle_filled.svg'))
              .width(10)
              .height(10)
              .fillColor(message.isSelf ? 
                this.themeState.colors.textColorAntiPrimary :
                this.themeState.colors.textColorSecondary)
            
            Text($r('app.string.messagelist_translation_tips'))
              .fontSize(10)
              .fontColor(message.isSelf ? 
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
    .backgroundColor(message.isSelf ? this.themeState.colors.bgColorBubbleOwn :
    this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(12)
    .margin({ top: 10 })
    .bindPopup(this.showTranslationMenu && this.translationMenuMessage?.msgID === message.msgID, {
      builder: this.TranslationTextMenuBuilder,
      placement: message.isSelf ? Placement.TopRight : Placement.TopLeft,
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
          // Only show menu when not in translating state
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
        // Hide button
        {
          text: $r('app.string.action_hide'),
          icon: $rawfile('messagelist/icon_extion_delete.svg'),
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
              const asrText = this.asrMenuMessage.messageBody?.asrText ?? '';
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
        // Hide button
        {
          text: $r('app.string.action_hide'),
          icon: $rawfile('messagelist/icon_extion_delete.svg'),
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
              // Get translated text and copy it
              const translatedTextMapRaw = this.translationMenuMessage.messageBody?.translatedText;
              const translatedTextMap: Record<string, string> = {};
              if (translatedTextMapRaw) {
                translatedTextMapRaw.forEach((value: string, key: string) => {
                  translatedTextMap[key] = value;
                });
              }
              const originalText = this.translationMenuMessage.messageBody?.text ?? '';
              const translatedText = translatedTextMap[originalText] ?? '';
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
      if (this.message.messageType === MessageType.System) {
        // Only show system messages if configured
        if (this.effectiveConfig.isShowSystemMessage) {
          Row() {
            GetMessageView(this.createRenderContext());
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })
        }
      } else if (this.message.messageType === MessageType.Custom) {
        Row() {
          GetMessageView(this.createRenderContext());
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      } else {
        Row() {
          if (this.shouldShowAvatarValue) {
            Stack() {
              this.AvatarView(this.message?.rawMessage?.faceURL)
            }
            .margin({ right: this.effectiveConfig.avatarSpacing ?? 6 })
          }

          Column() {
            // In merged mode, always show nickname above bubble for all messages
            // In normal LEFT mode, only show nickname for non-self messages above bubble
            if (this.displayMode === MessageDisplayMode.Merged) {
              // Merged mode: show nickname above bubble for all messages
              if (this.message.isSelf ? this.effectiveConfig.isShowRightNickname : this.effectiveConfig.isShowLeftNickname) {
                this.NicknameView()
              }
            } else {
              // Normal LEFT mode: only show nickname for non-self messages
              if (!this.message.isSelf && this.effectiveConfig.isShowLeftNickname) {
                this.NicknameView()
              }
            }
            
            Column() {
              GetMessageView(this.createRenderContext());
            }
            .borderRadius(this.getBubbleBorderRadius())
            // In merged mode, always use left bubble color; in normal mode, use color based on isSelf
            .backgroundColor(this.getBubbleBackgroundColor())
            .borderWidth(this.getBubbleBorderWidth())
            .borderColor(this.getBubbleBorderColor())
            .flexShrink(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Start)
            
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
            if (this.message.status === MessageStatus.violation) {
              Text($r('app.string.messagelist_violation_warning'))
                .fontSize(12)
                .fontColor(this.themeState.colors.textColorError)
                .margin({ top: 4 })
            }
            
            // In normal LEFT mode, show nickname below bubble for self messages
            if (this.displayMode !== MessageDisplayMode.Merged) {
              if (this.message.isSelf && this.effectiveConfig.isShowRightNickname) {
                this.NicknameView()
              }
            }
          }
          .flexShrink(1)
          .alignItems(HorizontalAlign.Start)

          if (this.message.isSelf && (this.message.status === MessageStatus.sendFail || this.message.status === MessageStatus.violation)) {
            Image($rawfile('messagelist/icon_message_send_error.svg'))
              .width(16)
              .height(16)
              .margin({ left: 4 })
              .onClick(() => {
                // Only show resend dialog for sendFail, not for violation
                if (this.message.status === MessageStatus.sendFail) {
                  this.showResendConfirmDialog();
                }
              })
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)
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
          this.message.status !== MessageStatus.recalled &&
          this.message.status !== MessageStatus.violation,
          {
          builder: this.ClassicActionPopupBuilder,
          placement: this.message.isSelf ? Placement.TopRight : Placement.TopLeft,
          enableArrow: false,
          mask: false,
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.showClassicActionPopup = false;
            }
          }
        })
        .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.1)' : 'transparent')
        .borderRadius(this.isHighlighted ? 8 : 0)
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  messageAlignmentRightStyle() {
    Column() {
      if (this.message.messageType === MessageType.System) {
        // Only show system messages if configured
        if (this.effectiveConfig.isShowSystemMessage) {
          Row() {
            GetMessageView(this.createRenderContext());
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })
        }
      } else if (this.message.messageType === MessageType.Custom) {
        Row() {
          GetMessageView(this.createRenderContext());
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      } else {
        Row() {
          if (this.message.isSelf && (this.message.status === MessageStatus.sendFail || this.message.status === MessageStatus.violation)) {
            Image($rawfile('messagelist/icon_message_send_error.svg'))
              .width(16)
              .height(16)
              .margin({ right: 4 })
              .onClick(() => {
                // Only show resend dialog for sendFail, not for violation
                if (this.message.status === MessageStatus.sendFail) {
                  this.showResendConfirmDialog();
                }
              })
          }
          Column() {
            // Show nickname for left messages (others)
            if (!this.message.isSelf && this.effectiveConfig.isShowLeftNickname) {
              this.NicknameView()
            }
            
            Column() {
              GetMessageView(this.createRenderContext());
            }
            .borderRadius(this.getBubbleBorderRadius())
            .backgroundColor(this.getBubbleBackgroundColor())
            .borderWidth(this.getBubbleBorderWidth())
            .borderColor(this.getBubbleBorderColor())
            .flexShrink(1)
            .alignItems(HorizontalAlign.End)
            .justifyContent(FlexAlign.End)
            
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
            if (this.message.isSelf && this.effectiveConfig.isShowRightNickname) {
              this.NicknameView()
            }
          }
          .flexShrink(1)
          .alignItems(HorizontalAlign.End)

          if (this.shouldShowAvatarValue) {
            Stack() {
              this.AvatarView(this.message?.rawMessage?.faceURL)
            }
            .margin({ left: this.effectiveConfig.avatarSpacing ?? 6 })
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.End)
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
          this.message.status !== MessageStatus.recalled &&
          this.message.status !== MessageStatus.violation,
          {
          builder: this.ClassicActionPopupBuilder,
          placement: this.message.isSelf ? Placement.TopRight : Placement.TopLeft,
          enableArrow: false,
          mask: false,
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.showClassicActionPopup = false;
            }
          }
        })
        .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.1)' : 'transparent')
        .borderRadius(this.isHighlighted ? 8 : 0)
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  messageAlignmentTwosideStyle() {
    Column() {
      if (this.message.messageType === MessageType.System) {
        // Only show system messages if configured
        if (this.effectiveConfig.isShowSystemMessage) {
          Row() {
            GetMessageView(this.createRenderContext());
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })
        }
      } else if (this.message.messageType === MessageType.Custom) {
        Row() {
          GetMessageView(this.createRenderContext());
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      } else {
        Row() {
          if (this.message.isSelf) {
            // Sender's message (right side)
            Row() {
              if (this.message.status === MessageStatus.sendFail || this.message.status === MessageStatus.violation) {
                Image($rawfile('messagelist/icon_message_send_error.svg'))
                  .width(16)
                  .height(16)
                  .margin({ right: 4 })
                  .onClick(() => {
                    // Only show resend dialog for sendFail, not for violation
                    if (this.message.status === MessageStatus.sendFail) {
                      this.showResendConfirmDialog();
                    }
                  })
              }

              Column() {
                // Show nickname for right messages (self)
                if (this.effectiveConfig.isShowRightNickname) {
                  this.NicknameView()
                }
                
                this.MessageBubble(this.message)
                
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
                if (this.message.status === MessageStatus.violation) {
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
                  this.AvatarView(this.message?.rawMessage?.faceURL)
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
                  this.AvatarView(this.message?.rawMessage?.faceURL)
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
        .justifyContent(this.message.isSelf ? FlexAlign.End : FlexAlign.Start)
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
          this.message.status !== MessageStatus.recalled &&
          this.message.status !== MessageStatus.violation,
          {
          builder: this.ClassicActionPopupBuilder,
          placement: this.message.isSelf ? Placement.TopRight : Placement.TopLeft,
          enableArrow: false,
          mask: false,
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.showClassicActionPopup = false;
            }
          }
        })
        .backgroundColor(this.isHighlighted ? 'rgba(0, 122, 255, 0.1)' : 'transparent')
        .borderRadius(this.isHighlighted ? 8 : 0)
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
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
        if (this.message.isSelf) {
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

    console.info('[MessageItem] Resending original message:', this.message.ID);

    // Send the original message using MessageInputStore
    this.inputStore.sendMessage(this.message)
      .then(() => {
        console.info('[MessageItem] Message resent successfully');
        Toast.info($r('app.string.messagelist_resend_success'), this.getUIContext());
      })
      .catch((error: ErrorInfo) => {
        const localizedMessage = IMErrorCode.getErrorMessage(error.code ??-1,""+error.code +error.message);
        Toast.info(localizedMessage, this.getUIContext());
      });
  }

  private showReactionDetail() {
    if (!this.message.reactionList || this.message.reactionList.length === 0) {
      return;
    }

    // In merged message detail view, do not show reaction detail dialog
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
            this.messageActionStore.fetchMessageReactionUsers(reactionID, 50);
          }
        },
        onRemoveReaction: (reactionID: string) => {
          if (this.messageActionStore) {
            this.messageActionStore.removeMessageReaction(reactionID);
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });

    this.reactionDetailController.open();
  }
}
