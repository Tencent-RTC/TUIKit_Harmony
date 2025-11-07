import {
  Avatar,
  AvatarSize,
  AvatarShape,
  AvatarBadge,
  AvatarBadgePosition,
  AvatarStatus,
  TextUtils,
  ThemeState,
  BadgeControl,
  BadgeType,
  AvatarContentType,
  AppBuilderConfig,
  ConversationAction
} from '../../basecomponent/Index';
import {
  ConversationListStore,
  ConversationInfo,
  ConversationFetchOption,
  ConversationType,
  ErrorInfo,
  ConversationDataSource,
  ConversationReceiveOption,
  LoginStore,
  ConversationListState,
  GroupType,
} from '@tencentcloud/atomicxcore';
import { ConversationMoreDialog, ConversationDialogAction as DialogAction } from './ConversationMoreDialog';
import { router } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { MessageUtils } from '../../messagelist/utils/MessageUtils';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MessageStatus } from '@tencentcloud/atomicxcore';
import { ConversationActionConfigProtocol, ChatConversationActionConfig } from '../config/ConversationListConfig';

// Custom action interface for ConversationList
export interface ConversationCustomAction {
  title: string | Resource;
  iconName?: string | Resource;
  action: (conversation: ConversationInfo) => void;
}

@Component
@Entry
export struct ConversationList {
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly BADGE_SIZE: number = 20;
  private static readonly DIVIDER_HEIGHT: number = 0.1;
  private static readonly ITEM_HEIGHT: number = 76;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State isLoading: boolean = false;
  customActions?: ConversationCustomAction[] = [];
  config?: ConversationActionConfigProtocol = undefined;
  private conversationListStyle: ConversationActionConfigProtocol = new ChatConversationActionConfig();
  dialogController: CustomDialogController | null = null
  @State private conversationListStore: ConversationListStore = ConversationListStore.create();
  @State private conversationListState: ConversationListState = this.conversationListStore.state;
  onConversationClick?: (item: ConversationInfo) => void;

  aboutToAppear() {
    // Initialize style
    if (this.config) {
      this.conversationListStyle = this.config;
    }
    
    this.fetchConversationList();
    console.info('ConversationListPage aboutToAppear');
  }

  aboutToDisappear() {

  }

  @Builder
  ActionButtonsBuilder(item: ConversationInfo) {
    Row() {
      // Show "More" button if there are other actions configured
      if (this.hasOtherActions()) {
        Button() {
          Column() {
            Image($rawfile('conversationlist/ic_public_more.svg'))
              .width(24)
              .height(24)
              .fillColor(Color.White)

            Text($r('app.string.more'))
              .fontSize(12)
              .fontColor(Color.White)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .type(ButtonType.Normal)
        .backgroundColor(this.themeState.colors.textColorAntiPrimary)
        .width(70)
        .height(ConversationList.ITEM_HEIGHT)
        .onClick(() => {
          this.showMoreDialog(item);
        })
      }
      // Show "Mark as Read/Unread" button if MARK_UNREAD is in config
      if (this.hasMarkUnreadAction() && ((item.unreadCount ?? 0) > 0)) {
        Button() {
          Column() {
            Image($rawfile('conversationlist/ic_public_check.svg'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
            Text((item.unreadCount ?? 0) > 0 ? $r('app.string.mark_as_read') : $r('app.string.mark_as_unread'))
              .fontSize(12)
              .fontColor(Color.White)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .type(ButtonType.Normal)
        .backgroundColor(this.themeState.colors.textColorLink)
        .width(70)
        .height(ConversationList.ITEM_HEIGHT)
        .onClick(() => {
          // Toggle read/unread status
          if ((item.unreadCount ?? 0) > 0) {
            // Mark as read
            this.conversationListStore.markConversationUnread(item.ID, false)
              .then(() => {
                console.log('Marked as read successfully');
              })
              .catch((error: ErrorInfo) => {
                console.error('Failed to mark as read:', error.message);
              });
          } else {
            // Mark as unread
            this.conversationListStore.markConversationUnread(item.ID, true)
              .then(() => {
                console.log('Marked as unread successfully');
              })
              .catch((error: ErrorInfo) => {
                console.error('Failed to mark as unread:', error.message);
              });
          }
        })
      }

    }
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Image($rawfile('search/empty_chat_icon.svg'))
        .width(100)
        .height(100)
        .fillColor(this.themeState.colors.textColorPrimary)
        .margin({ bottom: 16 })

      Text($r('app.string.no_messages_title'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorTertiary)

      Text($r('app.string.no_messages_desc'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BottomLogoBuilder() {
    Row() {
      Column() {
        Image($rawfile('conversationlist/conversation_bottom_tencent_logo.svg'))
          .width(120)
          .height(20)
          .objectFit(ImageFit.Contain)

        Text($r('app.string.conversationlist_copyright'))
          .fontSize(10)
          .fontColor(this.themeState.colors.textColorTertiary)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeState.colors.textColorPrimary)

      Text($r('app.string.loading_message'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorTertiary)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ConversationListBuilder() {
    List({ space: 0 }) {
      LazyForEach(this.conversationListState.conversationDataSource, (item: ConversationInfo) => {
        ListItem() {
          Column() {

            Row() {

              Stack() {
                Avatar({
                  content: {
                    type: AvatarContentType.Image,
                    name: item.title,
                    url: item.avatarURL
                  },
                  avatarSize: AvatarSize.M,
                  badge: {
                    type: (item.receiveOption != ConversationReceiveOption.RECEIVE && ((item.unreadCount ?? 0) > 0) ?
                    AvatarBadge.Dot :
                    AvatarBadge.None),
                    position: AvatarBadgePosition.Up
                  },
                  // status: AvatarStatus.Online
                })
              }
              .margin({ right: 8 })

              Column() {

                Row() {
                  Text(item.title || $r('app.string.conversationlist_title_placeholder'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.themeState.colors.textColorPrimary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)


                  if (item.receiveOption === ConversationReceiveOption.RECEIVE && (item.unreadCount ?? 0) > 0) {
                    BadgeControl({
                      text: (item.unreadCount ?? 0) > 99 ? '99+' : (item.unreadCount ?? 0).toString(),
                      type: BadgeType.Text
                    })
                      .margin({ left: 4 })
                  }


                  if (item.receiveOption != ConversationReceiveOption.RECEIVE && item.groupType != GroupType.MEETING) {
                    Image($rawfile('conversationlist/muted_icon.svg'))
                      .width(16)
                      .height(16)
                      .fillColor(this.themeState.colors.textColorSecondary)
                      .margin({ left: 4 })
                  }
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)


                Row() {
                  if (item.lastMessage?.status === MessageStatus.sending) {
                    LoadingProgress()
                      .width(12)
                      .height(12)
                      .margin({ right: 4 })
                  }

                  if (item.lastMessage?.isSelf && item.lastMessage?.status === MessageStatus.sendFail) {
                    Image($rawfile('messagelist/icon_message_send_error.svg'))
                      .width(12)
                      .height(12)
                      .margin({ right: 4 })
                  }

                  this.buildMixedContent(this.getDisplaySubTitle(item), item)

                  Text(this.formatTimeFromTs(item.timestamp || 0))
                    .fontSize(12)
                    .fontColor('#7A7A7A')
                    .margin({ left: 8 })
                }
                .width('100%')
                .margin({ top: 4 })
                .alignItems(VerticalAlign.Center)
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .height(ConversationList.ITEM_HEIGHT)
            .padding({ left: 16, right: 16 })
            .backgroundColor(item.isPinned ? this.themeState.colors.bgColorInput :
            this.themeState.colors.bgColorOperate)
            .onClick(() => {
              if (this.onConversationClick) {
                this.onConversationClick(item);
              }
              console.info(`Navigate to conversation detail with ID: ${item.ID}`);
            })


            if (this.conversationListState.conversationDataSource.getIndex(item) <
              this.conversationListState.conversationDataSource.totalCount() - 1) {
              Divider()
                .height(ConversationList.DIVIDER_HEIGHT)
                .color(this.themeState.colors.textColorPrimary)
                .margin({ left: 16 + ConversationList.AVATAR_SIZE + 8 })
            }
          }
        }
        .swipeAction({ end: this.ActionButtonsBuilder(item) })
      }, (item: ConversationInfo) => item.getKey())


      ListItem() {
        this.BottomLogoBuilder()
      }
    }
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onReachEnd(() => {

      this.loadMoreConversationList();
    })
    .width('100%')
    .layoutWeight(1)
  }

  build() {
    Column() {
      if (this.conversationListState.conversationDataSource.totalCount() > 0) {

        this.ConversationListBuilder()
      } else if (this.isLoading) {

        this.LoadingStateBuilder()
      } else {
        // Empty state
        Column() {
          this.EmptyStateBuilder()


          this.BottomLogoBuilder()
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  private formatTimeFromTs(ts: number): string {
    if (!ts || ts <= 0) {
      return ''
    }
    const date = new Date(ts * 1000)
    const h = date.getHours().toString().padStart(2, '0')
    const m = date.getMinutes().toString().padStart(2, '0')
    return `${h}:${m}`
  }

  // Helper methods to determine button visibility using style
  private hasMarkUnreadAction(): boolean {
    return this.conversationListStyle.isSupportMarkUnread ?? 
           AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MARK_UNREAD);
  }

  private hasOtherActions(): boolean {
    // Check if any action other than MARK_UNREAD is supported using style
    const hasDelete = this.conversationListStyle.isSupportDelete ?? 
                      AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.DELETE);
    const hasMute = this.conversationListStyle.isSupportMute ?? 
                    AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MUTE);
    const hasPin = this.conversationListStyle.isSupportPin ?? 
                   AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.PIN);
    
    return hasDelete || hasMute || hasPin;
  }

  private fetchConversationList() {
    this.isLoading = true;
    const option = new ConversationFetchOption();
    option.count = 100;


    this.conversationListStore.fetchConversationList(option)
      .then(() => {
        const count = this.conversationListState.conversationDataSource.totalCount();


        if (count === 0) {


          setTimeout(() => {
            this.retryFetchConversationList();
          }, 1000);
        } else {
          this.isLoading = false;
        }
      })
      .catch((error: ErrorInfo) => {

        this.isLoading = false;
      });
  }

  private retryFetchConversationList() {
    const option = new ConversationFetchOption();
    option.count = 100;


    this.conversationListStore.fetchConversationList(option)
      .then(() => {
        const count = this.conversationListState.conversationDataSource.totalCount();

        this.isLoading = false;
      })
      .catch((error: ErrorInfo) => {

        this.isLoading = false;
      });
  }

  private loadMoreConversationList() {
    if (this.isLoading || !this.conversationListState.hasMoreConversation) {

      return;
    }


    this.isLoading = true;
    this.conversationListStore.fetchMoreConversationList()
      .then(() => {

        this.isLoading = false;
      })
      .catch((error: ErrorInfo) => {

        this.isLoading = false;
      });
  }

  private showMoreDialog(conversation: ConversationInfo) {

    this.dialogController = new CustomDialogController({
      builder: ConversationMoreDialog({
        conversation: conversation,
        customActions: this.customActions, // Pass customActions to ConversationMoreDialog
        config: this.conversationListStyle, // Pass style to ConversationMoreDialog
        onAction: (action: DialogAction, conversationId: string) => {
          this.handleConversationAction(action, conversationId, conversation);
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)',
      autoCancel: true
    });


    this.dialogController.open();
  }

  private handleConversationAction(action: DialogAction, conversationId: string, conversation: ConversationInfo) {
    switch (action) {
      case DialogAction.DELETE:
        console.log('Deleting conversation:', conversationId);
        this.deleteConversation(conversation);
        break;

      case DialogAction.CLEAR:
        console.log('Clearing conversation messages:', conversationId);
        this.conversationListStore.clearConversationMessages(conversationId)
          .then(() => {
            console.log('Conversation messages cleared successfully');
          })
          .catch((error: ErrorInfo) => {
            console.error('Failed to clear conversation messages:', error.message);
          });
        break;

      case DialogAction.PIN:
        console.log('Toggling conversation pin status:', conversationId);
        this.conversationListStore.pinConversation(conversationId, !conversation.isPinned)
          .then(() => {
            console.log('Conversation pin status updated successfully');
          })
          .catch((error: ErrorInfo) => {
            console.error('Failed to update conversation pin status:', error.message);
          });
        break;

      case DialogAction.MUTE:
        console.log('Muting conversation:', conversationId);
        break;

      case DialogAction.HIDE:
        console.log('Hiding conversation:', conversationId);
        break;
    }
  }

  private deleteConversation(conversation: ConversationInfo) {
    this.conversationListStore.deleteConversation(conversation.ID)
      .then(() => {

      })
      .catch((error: ErrorInfo) => {

      });
  }

  private getDisplaySubTitle(item: ConversationInfo): string | Resource {
    const abstract = MessageUtils.getMessageAbstract(item.lastMessage);
    
    if (item.receiveOption !== ConversationReceiveOption.RECEIVE && (item.unreadCount ?? 0) > 0) {
      // For muted conversations with unread messages, only add count prefix for string type
      if (typeof abstract === 'string') {
        const messageCount = `[${item.unreadCount}${getContext().resourceManager.getStringSync($r('app.string.conversation_list_message_count_unit').id)}] `;
        return messageCount + abstract;
      } else {
        // For Resource type (system messages), return as-is to preserve localization
        // The count will be handled separately in buildMixedContent
        return abstract;
      }
    } else {
      return abstract; // Return as-is (string | Resource)
    }
  }

  @Builder
  buildMixedContent(content: string | Resource, item: ConversationInfo) {
    if (typeof content === 'string') {
      // Handle string content with emoji parsing
      Text() {
        ForEach(EmojiDataManager.parseEmojiText(content), (segment: EmojiTextSegment, index: number) => {
          if (segment.type === 'text') {
            Span(segment.content)
          } else if (segment.type === 'emoji' && segment.imageFile) {
            ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .verticalAlign(ImageSpanAlignment.CENTER)
          }
        }, (segment: EmojiTextSegment, index: number) => `${segment.type}_${index}_${segment.content}`)
      }
      .fontSize(12)
      .fontColor('#7A7A7A')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
    } else {
      // Handle Resource content with optional count prefix for muted conversations
      if (item.receiveOption !== ConversationReceiveOption.RECEIVE && (item.unreadCount ?? 0) > 0) {
        // Show count prefix for muted conversations with Resource content
        Text() {
          Span(`[${item.unreadCount}${getContext().resourceManager.getStringSync($r('app.string.conversation_list_message_count_unit').id)}] `)
          Span(content)
        }
        .fontSize(12)
        .fontColor('#7A7A7A')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      } else {
        // Handle Resource content directly without count
        Text(content)
          .fontSize(12)
          .fontColor('#7A7A7A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
    }
  }
}