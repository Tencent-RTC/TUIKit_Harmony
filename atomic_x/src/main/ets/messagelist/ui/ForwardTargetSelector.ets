import { ThemeState, AvatarContentType } from '../../basecomponent/Index';
import { Avatar, AvatarSize, AvatarShape } from '../../basecomponent/Index';
import { MessageCheckBox } from './MessageCheckBox';
import {
  ConversationListStore,
  ConversationInfo,
  ConversationFetchOption,
  ConversationListState,
} from '@tencentcloud/atomicxcore';

/**
 * ForwardTargetSelector component for selecting conversation targets to forward messages
 * Displays a list of recent conversations with multi-select capability
 * Supports selecting multiple conversations for batch forwarding
 */
@CustomDialog
export struct ForwardTargetSelector {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State private conversationListStore: ConversationListStore = ConversationListStore.create();
  @State private conversationListState: ConversationListState = this.conversationListStore.state;
  @State private selectedConversationIDs: Set<string> = new Set();
  @State private selectedConversations: ConversationInfo[] = [];
  @State private isLoading: boolean = false;
  
  controller: CustomDialogController;
  currentConversationID?: string; // Current conversation (no longer excluded)
  onConfirm?: (conversationIDs: string[]) => void;
  onCancel?: () => void;
  
  private readonly HEADER_HEIGHT: number = 56;
  private readonly ITEM_HEIGHT: number = 64;
  private readonly AVATAR_SIZE: number = 40;
  private readonly BOTTOM_BAR_HEIGHT: number = 60;
  private readonly HORIZONTAL_PADDING: number = 16;
  private readonly CHIP_HEIGHT: number = 32;

  aboutToAppear() {
    this.loadConversations();
  }

  build() {
    Column() {
      // Header
      this.HeaderBar();
      
      // Conversation list
      this.ConversationListView();
      
      // Bottom bar with selected conversations and send button
      if (this.selectedConversationIDs.size > 0) {
        this.SelectedConversationBar();
      }
    }
    .width('100%')
    .height('80%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  HeaderBar() {
    Row() {
      Text($r('app.string.cancel'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorLink)
        .onClick(() => {
          if (this.onCancel) {
            this.onCancel();
          }
          this.controller.close();
        })
      
      Text($r('app.string.forward_select_conversation'))
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // Placeholder for symmetry
      Text('')
        .fontSize(16)
        .fontColor(Color.Transparent)
        .width(40)
    }
    .width('100%')
    .height(this.HEADER_HEIGHT)
    .padding({ left: this.HORIZONTAL_PADDING, right: this.HORIZONTAL_PADDING })
    .alignItems(VerticalAlign.Center)
    .borderWidth({ bottom: 0.5 })
    .borderColor(this.themeState.colors.strokeColorPrimary)
  }

  @Builder
  ConversationListView() {
    Column() {
      // Section header
      Text($r('app.string.forward_recent_chats'))
        .fontSize(13)
        .fontColor(this.themeState.colors.textColorSecondary)
        .width('100%')
        .padding({ left: this.HORIZONTAL_PADDING, top: 12, bottom: 8 })
      
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 100 })
      } else {
        List() {
          LazyForEach(this.conversationListState.conversationDataSource, (conversation: ConversationInfo) => {
            ListItem() {
              this.ConversationRow(conversation);
            }
          }, (conversation: ConversationInfo) => conversation.ID)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 0.5,
          color: this.themeState.colors.strokeColorPrimary,
          startMargin: this.HORIZONTAL_PADDING + this.AVATAR_SIZE + 12,
          endMargin: this.HORIZONTAL_PADDING
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ConversationRow(conversation: ConversationInfo) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: conversation.avatarURL ?? '',
          name: conversation.title ?? ''
        },
        avatarSize: AvatarSize.M,
        shape: AvatarShape.Round
      })
        .width(this.AVATAR_SIZE)
        .height(this.AVATAR_SIZE)
      
      Text(conversation.title ?? $r('app.string.forward_unnamed_conversation'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: 12 })
      
      // Checkbox for multi-selection
      MessageCheckBox({
        isSelected: this.selectedConversationIDs.has(conversation.ID),
        isEnabled: true,
        onTap: () => {
          this.toggleConversation(conversation);
        }
      })
    }
    .width('100%')
    .height(this.ITEM_HEIGHT)
    .padding({ left: this.HORIZONTAL_PADDING, right: this.HORIZONTAL_PADDING })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.toggleConversation(conversation);
    })
  }

  @Builder
  SelectedConversationBar() {
    Column() {
      Divider()
        .width('100%')
        .height(0.5)
        .color(this.themeState.colors.strokeColorPrimary)
      
      Row() {
        // Selected conversations chips (scrollable)
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.selectedConversations, (conversation: ConversationInfo) => {
              this.ConversationChip(conversation);
            }, (conversation: ConversationInfo) => conversation.ID)
          }
          .padding({ left: this.HORIZONTAL_PADDING, right: 8 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        
        // Send button with count
        Button() {
          Text() {
            Span($r('app.string.forward_send'))
            Span(` (${this.selectedConversationIDs.size})`)
          }
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
        }
        .type(ButtonType.Capsule)
        .backgroundColor(this.themeState.colors.buttonColorPrimaryDefault)
        .height(36)
        .padding({ left: 16, right: 16 })
        .margin({ right: this.HORIZONTAL_PADDING })
        .onClick(() => {
          if (this.onConfirm && this.selectedConversationIDs.size > 0) {
            this.onConfirm(Array.from(this.selectedConversationIDs));
          }
          this.controller.close();
        })
      }
      .width('100%')
      .height(this.BOTTOM_BAR_HEIGHT)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  ConversationChip(conversation: ConversationInfo) {
    Row({ space: 4 }) {
      Text(conversation.title ?? '')
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 100 })
      
      Image($rawfile('messageinput/close_icon.svg'))
        .width(16)
        .height(16)
        .fillColor(this.themeState.colors.textColorSecondary)
        .onClick(() => {
          this.removeConversation(conversation);
        })
    }
    .height(this.CHIP_HEIGHT)
    .padding({ left: 12, right: 8 })
    .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
  }

  private toggleConversation(conversation: ConversationInfo) {
    if (this.selectedConversationIDs.has(conversation.ID)) {
      this.selectedConversationIDs.delete(conversation.ID);
      this.selectedConversations = this.selectedConversations.filter(c => c.ID !== conversation.ID);
    } else {
      this.selectedConversationIDs.add(conversation.ID);
      this.selectedConversations.push(conversation);
    }
    // Trigger UI update
    this.selectedConversationIDs = new Set(this.selectedConversationIDs);
    this.selectedConversations = [...this.selectedConversations];
  }

  private removeConversation(conversation: ConversationInfo) {
    this.selectedConversationIDs.delete(conversation.ID);
    this.selectedConversations = this.selectedConversations.filter(c => c.ID !== conversation.ID);
    // Trigger UI update
    this.selectedConversationIDs = new Set(this.selectedConversationIDs);
  }

  private loadConversations() {
    this.isLoading = true;
    const option = new ConversationFetchOption();
    this.conversationListStore.fetchConversationList(option)
      .then(() => {
        this.isLoading = false;
        console.log('[ForwardTargetSelector] Loaded conversations:', 
          this.conversationListState.conversationDataSource.totalCount());
      })
      .catch((error: Error) => {
        this.isLoading = false;
        console.error('[ForwardTargetSelector] Failed to load conversations:', error);
      });
  }
}
