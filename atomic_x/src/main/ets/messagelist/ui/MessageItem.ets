import {
  MessageInfo,
  MessageType,
  MessageMediaFileType,
  MessageListStore,
  MessageStatus,
  CustomMessageInfo,
  MessageInputStore,
  ErrorInfo
} from '@tencentcloud/atomicxcore';

import { TextMessageView } from '../cells/TextMessageView';
import { ImageMessageView } from '../cells/ImageMessageView';
import { FaceMessageView } from '../cells/FaceMessageView';
import { FileMessageView } from '../cells/FileMessageView';
import { SoundMessageView } from '../cells/SoundMessageView';
import { VideoMessageView } from '../cells/VideoMessageView';
import { Avatar, AvatarSize, AvatarContentType, TextUtils, ThemeState, ActionSheet, ActionItem,
  Toast } from '../../basecomponent/Index';
import { AppBuilderConfig, MessageAlignment } from '../../basecomponent/utils/AppBuilderHelper';
import { SystemMessageView } from '../cells/SystemMessageView';
import { CreateGroupMessageView } from '../cells/CreateGroupMessageView';
import { util } from '@kit.ArkTS';
import promptAction from '@ohos.promptAction';
import { IMErrorCode } from '../../basecomponent/utils/IMErrorCode';
import { MessageListStyleProtocol, ChatMessageListConfig } from '../config/MessageListConfig';

@Builder
export function GetMessageView(message: MessageInfo, MessageListStore: MessageListStore, config?: MessageListStyleProtocol) {
  if (message.messageType == MessageType.Text) {
    TextMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.Image) {
    ImageMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.File) {
    FileMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.Sound) {
    SoundMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.Video) {
    VideoMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.Face) {
    FaceMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.System) {
    SystemMessageView(message, MessageListStore);
  } else if (message.messageType == MessageType.Custom) {
    // Custom message - handled in MessageItem build method
    if (message.messageBody?.customMessage) {
      if (isGroupCreated(message.messageBody?.customMessage)) {
        CreateGroupMessageView(message, MessageListStore);
      } else {
        SystemMessageView(message, MessageListStore);
      }
    } else {
      SystemMessageView(message, MessageListStore);
    }
  } else {
    // Unsupported message type
    if ((config ?? new ChatMessageListConfig()).isShowUnsupportMessage) {
      TextMessageView(message, MessageListStore);
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
  onLongPress?: (message: MessageInfo) => void;
  onUserClick?: (userID: string) => void;
  @ObjectLink messageListStore: MessageListStore;
  @State private shouldShowAvatarValue: boolean = true;
  @State private inputStore?: MessageInputStore = undefined;
  private resendDialogController?: CustomDialogController;
  @State private effectiveConfig: MessageListStyleProtocol = new ChatMessageListConfig();

  aboutToAppear() {
    if (this.config) {
      this.effectiveConfig = this.config;
    }
    this.showAvatar = this.initialShowAvatar;
    this.updateAvatarVisibility();
    this.downloadMessageViewSource(this.message);

    // Initialize MessageInputStore for resending messages
    if (this.messageListStore.conversationID) {
      this.inputStore = MessageInputStore.create(this.messageListStore.conversationID);
    }
  }

  public refreshConfig(): void {
    this.updateAvatarVisibility();
  }

  private onInitialShowAvatarChanged(): void {
    this.showAvatar = this.initialShowAvatar;
    this.updateAvatarVisibility();
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
    Stack() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          name: this.message.sender || '',
          url: url || '',
        },
        avatarSize: AvatarSize.S
      })
    }
    .width(32)
    .height(32)
    .visibility(this.shouldShowAvatarValue ? Visibility.Visible : Visibility.Hidden)
    .onClick(() => {
      if (this.onUserClick && this.message.sender) {
        this.onUserClick(this.message.sender);
      }
    })
  }

  @Builder
  NicknameView() {
    Text(this.message.sender  || '')
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

  @Builder
  MessageBubble(message: MessageInfo) {

    if (message.messageType === MessageType.System || message.messageType === MessageType.Custom) {

      Text("")
        .width(0)
        .height(0)
    } else if (message.isSelf) {
      Column() {
        GetMessageView(message, this.messageListStore, this.effectiveConfig);
        this.TimeInBubbleView();
      }
      .borderRadius({
        topLeft: 16,
        topRight: 16,
        bottomLeft: 16,
        bottomRight: 0
      })
      .backgroundColor(this.themeState.colors.bgColorBubbleOwn)
      .borderColor(this.themeState.colors.bgColorBubbleOwn)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
    } else {
      Column() {
        GetMessageView(message, this.messageListStore, this.effectiveConfig);
        this.TimeInBubbleView();
      }
      .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius({
        topLeft: 16,
        topRight: 16,
        bottomLeft: 0,
        bottomRight: 16
      })
      .flexShrink(1)
      .padding({ bottom: this.shouldShowTimeInBubble(message) ? 4 : 0 })
    }
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
  }

  @Builder
  messageAlignmentLeftStyle() {
    Column() {
      if (this.message.messageType === MessageType.System) {
        // Only show system messages if configured
        if (this.effectiveConfig.isShowSystemMessage) {
          Row() {
            GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })
        }
      } else if (this.message.messageType === MessageType.Custom) {
        Row() {
          GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      } else {
        Row() {
          Stack() {
            this.AvatarView(this.message?.rawMessage?.faceURL)
          }
          .margin({ right: this.effectiveConfig.avatarSpacing ?? 6 })

          Column() {
            // Show nickname for left messages (others)
            if (!this.message.isSelf && this.effectiveConfig.isShowLeftNickname) {
              this.NicknameView()
            }
            
            Column() {
              GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
            }
            .borderRadius(16)
            .backgroundColor(this.message.isSelf ?
            this.themeState.colors.bgColorBubbleOwn :
            this.themeState.colors.bgColorBubbleReciprocal)
            .borderWidth(1)
            .borderColor(this.message.isSelf ?
            this.themeState.colors.bgColorBubbleOwn :
            this.themeState.colors.bgColorBubbleReciprocal)
            .flexShrink(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Start)
            
            // Show nickname for right messages (self)
            if (this.message.isSelf && this.effectiveConfig.isShowRightNickname) {
              this.NicknameView()
            }
          }
          .flexShrink(1)
          .alignItems(HorizontalAlign.Start)

          if (this.message.isSelf && this.message.status === MessageStatus.sendFail) {
            Image($rawfile('messagelist/icon_message_send_error.svg'))
              .width(16)
              .height(16)
              .margin({ left: 4 })
              .onClick(() => {
                this.showResendConfirmDialog();
              })
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.Start)
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction((event: GestureEvent) => {
              console.log('[MessageItem] LongPress detected');
              if (this.onLongPress) {
                this.onLongPress(this.message);
              }
            })
        )
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
            GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })
        }
      } else if (this.message.messageType === MessageType.Custom) {
        Row() {
          GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      } else {
        Row() {
          if (this.message.isSelf && this.message.status === MessageStatus.sendFail) {
            Image($rawfile('messagelist/icon_message_send_error.svg'))
              .width(16)
              .height(16)
              .margin({ right: 4 })
              .onClick(() => {
                this.showResendConfirmDialog();
              })
          }
          Column() {
            // Show nickname for left messages (others)
            if (!this.message.isSelf && this.effectiveConfig.isShowLeftNickname) {
              this.NicknameView()
            }
            
            Column() {
              GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
            }
            .borderRadius(16)
            .backgroundColor(this.message.isSelf ?
            this.themeState.colors.bgColorBubbleOwn :
            this.themeState.colors.bgColorBubbleReciprocal)
            .borderWidth(1)
            .borderColor(this.message.isSelf ?
            this.themeState.colors.bgColorBubbleOwn :
            this.themeState.colors.bgColorBubbleReciprocal)
            .flexShrink(1)
            .alignItems(HorizontalAlign.End)
            .justifyContent(FlexAlign.End)
            
            // Show nickname for right messages (self)
            if (this.message.isSelf && this.effectiveConfig.isShowRightNickname) {
              this.NicknameView()
            }
          }
          .flexShrink(1)
          .alignItems(HorizontalAlign.End)


          Stack() {
            this.AvatarView(this.message?.rawMessage?.faceURL)
          }
          .margin({ left: this.effectiveConfig.avatarSpacing ?? 6 })
        }
        .width('90%')
        .justifyContent(FlexAlign.End)
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction((event: GestureEvent) => {
              console.log('[MessageItem] LongPress detected');
              if (this.onLongPress) {
                this.onLongPress(this.message);
              }
            })
        )

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
            GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })
        }
      } else if (this.message.messageType === MessageType.Custom) {
        Row() {
          GetMessageView(this.message, this.messageListStore, this.effectiveConfig);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 8 })
      } else {
        Row() {
          if (this.message.isSelf) {
            // Sender's message (right side)
            Row() {
              Column() {
                // Show nickname for right messages (self)
                if (this.effectiveConfig.isShowRightNickname) {
                  this.NicknameView()
                }
                
                this.MessageBubble(this.message)
              }
              .flexShrink(1)
              .alignItems(HorizontalAlign.End)

              if (this.message.status === MessageStatus.sendFail) {
                Image($rawfile('messagelist/icon_message_send_error.svg'))
                  .width(16)
                  .height(16)
                  .margin({ left: 4 })
                  .onClick(() => {
                    this.showResendConfirmDialog();
                  })
              }
            }
            .width('90%')
            .justifyContent(FlexAlign.End)
          } else {
            Row() {
              // Avatar
              Stack() {
                this.AvatarView(this.message?.rawMessage?.faceURL)
              }
              .margin({ right: this.effectiveConfig.avatarSpacing ?? 6 })

              Column() {
                // Show nickname for left messages (others)
                if (this.effectiveConfig.isShowLeftNickname) {
                  this.NicknameView()
                }
                
                this.MessageBubble(this.message)
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
              if (this.onLongPress) {
                this.onLongPress(this.message);
              }
            })
        )
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
    this.shouldShowAvatarValue = this.shouldShowAvatar(this.effectiveConfig.alignment ?? MessageAlignment.LEFT);
  }

  private shouldShowAvatar(alignment: MessageAlignment): boolean {
    switch (alignment) {
      case MessageAlignment.LEFT:
        // In LEFT mode, always show avatar based on style configuration
        return this.message.isSelf ? 
          (this.effectiveConfig.isShowRightAvatar ?? false) :
          (this.effectiveConfig.isShowLeftAvatar ?? true);
      case MessageAlignment.RIGHT:
        // In RIGHT mode, always show avatar based on style configuration
        return this.message.isSelf ? 
          (this.effectiveConfig.isShowRightAvatar ?? false) :
          (this.effectiveConfig.isShowLeftAvatar ?? true);
      case MessageAlignment.TWO_SIDED:
      default:
        // In TWO_SIDED mode, respect both showAvatar flag and style configuration
        if (this.message.isSelf) {
          return this.effectiveConfig.isShowRightAvatar ?? false;
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
      promptAction.showToast({
        message: $r('app.string.messagelist_resend_failed'),
        duration: 2000
      });
      return;
    }

    console.info('[MessageItem] Resending original message:', this.message.ID);

    // Send the original message using MessageInputStore
    this.inputStore.sendMessage(this.message)
      .then(() => {
        console.info('[MessageItem] Message resent successfully');
        promptAction.showToast({
          message: $r('app.string.messagelist_resend_success'),
          duration: 2000
        });
      })
      .catch((error: ErrorInfo) => {
        const localizedMessage = IMErrorCode.getErrorMessage(error.code ??-1,""+error.code +error.message);
        Toast.error(localizedMessage, this.getUIContext());
      });
  }
}
