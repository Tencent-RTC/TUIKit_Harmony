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
  ConversationAction,
  ContextProvider,
  LanguageState
} from '../../basecomponent/Index';
import {
  ConversationListStore,
  ConversationInfo,
  ConversationFetchOption,
  ConversationType,
  ErrorInfo,
  ConversationDataSource,
  ReceiveMessageOpt,
  LoginStore,
  ConversationListState,
  GroupType,
  ConversationMarkType,
  GroupAtType,
  GroupAtInfo,
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
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
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
      if (this.hasMarkUnreadAction() ) {
        Button() {
          Column() {
            Image($rawfile('conversationlist/ic_public_check.svg'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
            Text(this.hasUnreadStatus(item) ? $r('app.string.mark_as_read') : $r('app.string.mark_as_unread'))
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
          if (this.hasUnreadStatus(item)) {
            // Mark as read: first clear unread count, then remove unread mark
            this.conversationListStore.clearConversationUnreadCount(item.ID)
              .then(() => {
                console.log('Cleared unread count successfully');
                this.conversationListStore.markConversation([item.ID], ConversationMarkType.UNREAD, false)
                  .then(() => {
                    console.log('Marked as read successfully');
                  })
                  .catch((error: ErrorInfo) => {
                    console.error('Failed to mark as read:', error.message);
                  });
              })
              .catch((error: ErrorInfo) => {
                console.error('Failed to clear unread count:', error.message);
              });
          } else {
            // Mark as unread: only add unread mark, don't modify unreadCount
            this.conversationListStore.markConversation([item.ID], ConversationMarkType.UNREAD, true)
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
                    type: (item.receiveOption != ReceiveMessageOpt.RECEIVE && this.hasUnreadStatus(item) ?
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
                    .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)


                  if (item.receiveOption === ReceiveMessageOpt.RECEIVE && this.hasUnreadStatus(item)) {
                    BadgeControl({
                      text: this.getUnreadBadgeText(item),
                      type: BadgeType.Text
                    })
                      .margin({ left: 4 })
                  }


                  if (item.receiveOption != ReceiveMessageOpt.RECEIVE && item.groupType != GroupType.MEETING) {
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
                    .fontColor(this.themeState.colors.textColorSecondary)
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private formatTimeFromTs(timestamp: number): string {
    const MIN_VALID_TIMESTAMP = 946684800; // 2000-01-01 00:00:00 UTC
    const now = new Date();
    const MAX_VALID_TIMESTAMP = Math.floor(now.getTime() / 1000) + 365 * 24 * 60 * 60;

    if (!timestamp || timestamp < MIN_VALID_TIMESTAMP || timestamp > MAX_VALID_TIMESTAMP) {
      return '';
    }

    const date = new Date(timestamp * 1000);

    const isSameDay = date.getFullYear() === now.getFullYear() &&
      date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate();

    if (isSameDay) {
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }

    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');

    if (date.getFullYear() === now.getFullYear()) {
      return `${month}/${day}`;
    }

    return `${date.getFullYear()}/${month}/${day}`;
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

        // Fetch total unread count
        this.conversationListStore.getConversationTotalUnreadCount()
          .catch((error: ErrorInfo) => {
            console.error('Failed to get total unread count:', error.message);
          });

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
    // Check if conversation has draft - draft takes priority
    if (item.draft && item.draft.length > 0) {
      return item.draft;
    }
    
    const abstract = MessageUtils.getMessageAbstract(item.lastMessage);
    
    // For muted conversations, only show [X条] when unreadCount >= 2
    // This avoids confusion when user marks as unread (unreadCount = 0)
    if (item.receiveOption !== ReceiveMessageOpt.RECEIVE && (item.unreadCount ?? 0) >= 2) {
      // For muted conversations with 2+ unread messages, add count prefix for string type
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

  /**
   * Check if conversation has draft
   */
  private hasDraft(item: ConversationInfo): boolean {
    return item.draft !== undefined && item.draft !== null && item.draft.length > 0;
  }

  /**
   * Check if conversation has unread status (real unread count > 0 OR marked as unread)
   */
  private hasUnreadStatus(item: ConversationInfo): boolean {
    return (item.unreadCount ?? 0) > 0 || item.markList.includes(ConversationMarkType.UNREAD);
  }

  /**
   * Get unread badge text for display
   * - If unreadCount > 0: show real count
   * - If unreadCount = 0 but marked as unread: show "1" (fake number)
   */
  private getUnreadBadgeText(item: ConversationInfo): string {
    const unreadCount = item.unreadCount ?? 0;
    if (unreadCount > 0) {
      return unreadCount > 99 ? '99+' : unreadCount.toString();
    }
    // Marked as unread but no real unread count, show fake "1"
    return '1';
  }

  /**
   * Build @ tag text based on groupAtInfoList
   * - Only show for group conversations with unreadCount > 0
   * - If both @all and @me exist, show both: "[@所有人] [有人@我]"
   */
  private buildAtTagText(item: ConversationInfo): string {
    // Only show @ tag for group chats with unread messages
    if ((item.unreadCount ?? 0) <= 0 || !item.ID || !item.ID.startsWith('group_')) {
      return '';
    }

    const atInfoList = item.groupAtInfoList;
    if (!atInfoList || atInfoList.length === 0) {
      return '';
    }

    let hasAtAll = false;
    let hasAtMe = false;

    for (const atInfo of atInfoList) {
      switch (atInfo.atType) {
        case GroupAtType.AT_ALL:
          hasAtAll = true;
          break;
        case GroupAtType.AT_ME:
          hasAtMe = true;
          break;
        case GroupAtType.AT_ALL_AT_ME:
          hasAtAll = true;
          hasAtMe = true;
          break;
      }
    }

    let result = '';
    if (hasAtAll) {
      result += getContext().resourceManager.getStringSync($r('app.string.conversation_at_all_tag').id);
    }
    if (hasAtAll && hasAtMe) {
      result += ' ';
    }
    if (hasAtMe) {
      result += getContext().resourceManager.getStringSync($r('app.string.conversation_at_me_tag').id);
    }

    return result;
  }

  @Builder
  buildMixedContent(content: string | Resource, item: ConversationInfo) {
    if (typeof content === 'string') {
      // Check if this is draft content
      if (this.hasDraft(item)) {
        // Build draft preview with red [Draft] label
        Text() {
          // Add unread count prefix for muted conversations (only when unreadCount >= 2)
          if (item.receiveOption !== ReceiveMessageOpt.RECEIVE && (item.unreadCount ?? 0) >= 2) {
            Span(`[${item.unreadCount}${getContext().resourceManager.getStringSync($r('app.string.conversation_list_message_count_unit').id)}]`)
              .fontColor(this.themeState.colors.textColorSecondary)
          }
          // Add @ tag(s) if present
          if (this.buildAtTagText(item).length > 0) {
            Span(this.buildAtTagText(item))
              .fontColor(this.themeState.colors.textColorError)
            Span(' ')
          }
          // Red [Draft] label
          Span(getContext().resourceManager.getStringSync($r('app.string.conversation_draft_label').id))
            .fontColor(this.themeState.colors.textColorError)
          // Space after draft label
          Span(' ')
          // Draft content with emoji parsing
          ForEach(EmojiDataManager.parseEmojiText(content), (segment: EmojiTextSegment, index: number) => {
            if (segment.type === 'text') {
              Span(segment.content)
                .fontColor(this.themeState.colors.textColorSecondary)
            } else if (segment.type === 'emoji' && segment.imageFile) {
              ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
                .verticalAlign(ImageSpanAlignment.CENTER)
            }
          }, (segment: EmojiTextSegment, index: number) => `draft_${segment.type}_${index}_${segment.content}`)
        }
        .fontSize(12)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
      } else {
        // Handle regular string content with emoji parsing
        Text() {
          // Add @ tag(s) if present (before message content)
          if (this.buildAtTagText(item).length > 0) {
            Span(this.buildAtTagText(item))
              .fontColor(this.themeState.colors.textColorError)
            Span(' ')
          }
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
        .fontColor(this.themeState.colors.textColorSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
      }
    } else {
      // Handle Resource content with optional count prefix for muted conversations (only when unreadCount >= 2)
      if (item.receiveOption !== ReceiveMessageOpt.RECEIVE && (item.unreadCount ?? 0) >= 2) {
        // Show count prefix for muted conversations with Resource content
        Text() {
          // Add @ tag(s) if present
          if (this.buildAtTagText(item).length > 0) {
            Span(this.buildAtTagText(item))
              .fontColor(this.themeState.colors.textColorError)
            Span(' ')
          }
          Span(`[${item.unreadCount}${getContext().resourceManager.getStringSync($r('app.string.conversation_list_message_count_unit').id)}] `)
          Span(content)
        }
        .fontSize(12)
        .fontColor(this.themeState.colors.textColorSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
      } else {
        // Handle Resource content directly without count
        if (this.buildAtTagText(item).length > 0) {
          Text() {
            Span(this.buildAtTagText(item))
              .fontColor(this.themeState.colors.textColorError)
            Span(' ')
            Span(content)
          }
          .fontSize(12)
          .fontColor(this.themeState.colors.textColorSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
        } else {
          Text(content)
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
        }
      }
    }
  }
}