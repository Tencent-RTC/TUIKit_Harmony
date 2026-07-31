import { MessageInfo } from '@tencentcloud/atomicxcore';
import { Avatar, AvatarContentType, AvatarSize, LanguageState, NotifyParams, ThemeState, TUIEventBus, TUIObserver } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { MessageList, MultiSelectBottomBar, MultiSelectActions } from '@tencentcloud/atomicx/src/main/ets/messagelist/Index';
import { MessageInput } from '@tencentcloud/atomicx/src/main/ets/messageinput/Index';

// NOTE: Call-related event publishing (AtomicCallEventPublisher, TUICallKit
// invocation reporting) has been moved into the atomic_x MessageInput /
// chat setting components, aligned with the Android blueprint. ChatPage no
// longer needs to know about it: host apps that only integrate the atomic_x
// components still emit correct call events.

@CustomDialog
export struct ChatDialog {
  controller: CustomDialogController;
  conversationID: string = '';
  title: string = 'chat';
  status: string = '';
  avatarUrl: string = '';
  locateMessage?: MessageInfo = undefined;
  onBack?: () => void;
  onUserClick?: (userID: string) => void;
  onChatHeaderClick?: (conversationID: string) => void;

  build() {
    ChatPage({
      conversationID: this.conversationID,
      title: this.title,
      status: this.status,
      avatarUrl: this.avatarUrl,
      locateMessage: this.locateMessage,
      onBack: () => {
        if (this.onBack) {
          this.onBack();
        }
        this.controller.close();
      },
      onUserClick: (userID: string) => {
        if (this.onUserClick) {
          this.onUserClick(userID);
        }
      },
      onChatHeaderClick: (conversationID: string) => {
        if (this.onChatHeaderClick) {
          this.onChatHeaderClick(conversationID);
        }
      },
      dialogController: this.controller
    })
  }
}



@Component
export struct ChatPage {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State conversationID: string = '';
  @State title: string = '';
  @State status: string = '';
  @State avatarUrl: string = '';
  @State locateMessage?: MessageInfo = undefined;
  @State isMultiSelectMode: boolean = false;
  @State selectedCount: number = 0;
  private multiSelectActions?: MultiSelectActions = undefined;

  onBack?: () => void;
  onUserClick?: (userID: string) => void;
  onChatHeaderClick?: (conversationID: string) => void;
  dialogController?: CustomDialogController;
  private chatProfileObserver?: TUIObserver;
  aboutToAppear(): void {
    this.chatProfileObserver = new ChatProfileUpdatedObserver(this);
    TUIEventBus.getInstance().subscribe('chat.conversation.profileUpdated', null, this.chatProfileObserver);
    console.info(`[ChatPage] subscribe profileUpdated. conversationID=${this.conversationID}`);
  }

  aboutToDisappear(): void {
    if (this.chatProfileObserver) {
      TUIEventBus.getInstance().unsubscribe('chat.conversation.profileUpdated', null, this.chatProfileObserver);
      this.chatProfileObserver = undefined;
      console.info(`[ChatPage] unsubscribe profileUpdated. conversationID=${this.conversationID}`);
    }
  }

  applyProfileUpdate(conversationID: string, title?: string, avatarURL?: string): void {
    console.info(`[ChatPage] applyProfileUpdate. self=${this.conversationID}, incoming=${conversationID}, title=${title}, avatar=${avatarURL}`);
    if (conversationID !== this.conversationID) {
      return;
    }
    if (title !== undefined) {
      this.title = title;
      console.info(`[ChatPage] title updated to: ${title}`);
    }
    if (avatarURL !== undefined) {
      this.avatarUrl = avatarURL;
    }
  }

  build() {
    Stack() {
      Column() {
        this.LargeTitleBuilder();
        MessageList({
          conversationID: this.conversationID,
          locateMessage: this.locateMessage,
          onUserClick: (userID: string) => {
            if (this.onUserClick) {
              this.onUserClick(userID);
            }
          },
          onMultiSelectModeChange: (isMultiSelectMode: boolean, selectedCount: number, actions?: MultiSelectActions) => {
            this.isMultiSelectMode = isMultiSelectMode;
            this.selectedCount = selectedCount;
            this.multiSelectActions = actions;
          }
        })
          .width('100%')
          .layoutWeight(1)

        if (this.isMultiSelectMode) {
          MultiSelectBottomBar({
            selectedCount: this.selectedCount,
            onCancel: () => {
              if (this.multiSelectActions) {
                this.multiSelectActions.cancel();
              }
            },
            onDelete: () => {
              if (this.multiSelectActions) {
                this.multiSelectActions.deleteMessages();
              }
            },
            onForward: () => {
              if (this.multiSelectActions) {
                this.multiSelectActions.forward();
              }
            }
          })
        } else {
          MessageInput({
            conversationID: this.conversationID,
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  LargeTitleBuilder() {
    Column() {
      Row() {
        Row({ space: 8 }) {
          Row() {
            Image($rawfile("basecomponent/common_back_icon.svg"))
              .scale({
                x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
                y: 1
              })
              .width(16)
              .height(16)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
          .width(44)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            if (this.onBack) {
              this.onBack();
            }
          })

          Row({ space: 8 }) {
            Avatar({
              content: {
                type: AvatarContentType.Image,
                url: this.avatarUrl,
                name: this.title || '',
              },
              avatarSize: AvatarSize.S,
            })

            Column() {
              Text(this.title)
                .fontSize(14)
                .fontColor(this.themeState.colors.textColorPrimary)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.status)
                .fontSize(12)
                .fontColor(this.themeState.colors.textColorTertiary)
                .fontWeight(FontWeight.Regular)
                .textAlign(TextAlign.Start)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .constraintSize({ maxWidth: '60%' })
          }
          .layoutWeight(1)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        Image($rawfile('conversationlist/ic_public_more.svg'))
          .width(24)
          .height(24)
          .fillColor(this.themeState.colors.textColorPrimary)
          .onClick(() => {
            if (this.onChatHeaderClick) {
              this.onChatHeaderClick(this.conversationID);
            }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)

      Divider()
        .width('100%')
        .height(0.3)
        .color(this.themeState.colors.strokeColorSecondary)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

class ChatProfileUpdatedObserver implements TUIObserver {
  private readonly host: ChatPage;

  constructor(host: ChatPage) {
    this.host = host;
  }

  onNotify(event: string, key: string | null, params: NotifyParams | null): void {
    console.info(`[ChatProfileUpdatedObserver] onNotify. event=${event}, key=${key}, hasData=${params?.data != null}`);
    const data = params?.data;
    if (!data) {
      return;
    }
    const conversationID = data['conversationID'] as string | undefined;
    if (!conversationID) {
      return;
    }
    const title = data['title'] as string | undefined;
    const avatarURL = data['avatarURL'] as string | undefined;
    this.host.applyProfileUpdate(conversationID, title, avatarURL);
  }
}