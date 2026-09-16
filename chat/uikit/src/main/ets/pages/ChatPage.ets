import { MessageInfo, ConversationListStore } from '@tencentcloud/atomicxcore';
import { LanguageState, NotifyParams, ThemeState, TUIEventBus, TUIObserver } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { MessageList, MultiSelectBottomBar, MultiSelectActions } from '@tencentcloud/atomicx/src/main/ets/messagelist/Index';
import { MessageInput, ChatMessageInputConfig } from '@tencentcloud/atomicx/src/main/ets/messageinput/Index';

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
  onSecurityReportClick?: () => void;

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
      onSecurityReportClick: () => {
        if (this.onSecurityReportClick) {
          this.onSecurityReportClick();
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
  @State isPeerTyping: boolean = false;
  @State selectedCount: number = 0;
  @State unreadCount: number = 0;
  @State showSecurityBar: boolean = true;
  private multiSelectActions?: MultiSelectActions = undefined;

  onBack?: () => void;
  onUserClick?: (userID: string) => void;
  onChatHeaderClick?: (conversationID: string) => void;
  onSecurityReportClick?: () => void;
  dialogController?: CustomDialogController;
  private chatProfileObserver?: TUIObserver;
  private unreadTimer?: number;
  aboutToAppear(): void {
    this.chatProfileObserver = new ChatProfileUpdatedObserver(this);
    TUIEventBus.getInstance().subscribe('chat.conversation.profileUpdated', null, this.chatProfileObserver);
    this.startUnreadObserver();
    console.info(`[ChatPage] subscribe profileUpdated. conversationID=${this.conversationID}`);
  }

  aboutToDisappear(): void {
    if (this.chatProfileObserver) {
      TUIEventBus.getInstance().unsubscribe('chat.conversation.profileUpdated', null, this.chatProfileObserver);
      this.chatProfileObserver = undefined;
      console.info(`[ChatPage] unsubscribe profileUpdated. conversationID=${this.conversationID}`);
    }
    if (this.unreadTimer !== undefined) {
      clearInterval(this.unreadTimer);
      this.unreadTimer = undefined;
    }
  }

  private startUnreadObserver(): void {
    try {
      const store: ConversationListStore = ConversationListStore.create();
      const refresh: () => void = () => {
        try {
          const total: number = store.state.totalUnreadCount;
          this.unreadCount = total;
        } catch (_e) {
          this.unreadCount = 0;
        }
      };
      refresh();
      this.unreadTimer = setInterval(refresh, 1500);
    } catch (e) {
      console.warn(`[ChatPage] startUnreadObserver failed: ${e}`);
    }
  }

  private formatUnread(count: number): string {
    if (count <= 0) {
      return '';
    }
    if (count > 99) {
      return '99+';
    }
    return `${count}`;
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

  onBackPress(): boolean {
    if (this.isMultiSelectMode) {
      this.multiSelectActions?.cancel();
      return true;
    }
    return false;
  }

  build() {
    Column() {
      this.LargeTitleBuilder();
      if (this.showSecurityBar) {
        this.SecurityWarningBuilder();
      }
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
          onDelete: () => {
            this.multiSelectActions?.deleteMessages();
          },
          onSeparateForward: () => {
            this.multiSelectActions?.forwardSeparately();
          },
          onMergedForward: () => {
            this.multiSelectActions?.forwardMerged();
          }
        })
      } else {
        MessageInput({
          conversationID: this.conversationID,
          config: new ChatMessageInputConfig({
            enableTyping: true,
            onTypingStatusChanged: (isTyping: boolean): void => {
              this.isPeerTyping = isTyping;
            }
          })
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  LargeTitleBuilder() {
    Column() {
      Row() {
        Row() {
          if (this.isMultiSelectMode) {
            Text($r('app.string.cancel'))
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorPrimary)
              .onClick(() => {
                this.multiSelectActions?.cancel();
              })
          } else {
            Row() {
              Image($rawfile("basecomponent/common_back_icon.svg"))
                .scale({
                  x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
                  y: 1
                })
                .width(16)
                .height(16)
                .fillColor(this.themeState.colors.textColorSecondary)
            }
            .height(48)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .padding({ left: 4, right: 4 })
            .onClick(() => {
              this.onBack?.();
            })

            if (this.unreadCount > 0) {
              Row() {
                Text(this.formatUnread(this.unreadCount))
                  .fontSize(12)
                  .fontColor(this.themeState.colors.textColorButton)
                  .textAlign(TextAlign.Center)
              }
              .width(22)
              .height(22)
              .borderRadius(11)
              .backgroundColor(this.themeState.colors.buttonColorOff)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .margin({ left: 2 })
            }
          }
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)

        Text(this.isPeerTyping ? $r('app.string.chat_typing_indicator') : this.title)
          .fontSize(17)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(2)

        Row() {
          Image($rawfile('conversationlist/ic_public_more.svg'))
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.textColorSecondary)
            .visibility(this.isMultiSelectMode ? Visibility.Hidden : Visibility.Visible)
            .onClick(() => {
              if (!this.isMultiSelectMode) {
                this.onChatHeaderClick?.(this.conversationID);
              }
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .width('100%')
        .height(0.5)
        .color(this.themeState.colors.strokeColorPrimary)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  SecurityWarningBuilder() {
    Row() {
      Image($rawfile('messagelist/ic_security_warning.svg'))
        .width(16)
        .height(16)
        .margin({ top: 3 })

      Column() {
        Text() {
          Span('请勿轻信汇款、中奖等信息，谨慎对待陌生电话，避免上当受骗。遇到可疑情况请及时反馈。 ')
            .fontColor('#A02800')
            .fontSize(14)
          Span('点此举报')
            .fontColor('#147AFF')
            .fontSize(14)
            .onClick(() => {
              if (this.onSecurityReportClick) {
                this.onSecurityReportClick();
              }
            })
        }
        .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, right: 7 })

      Image($rawfile('messagelist/ic_security_close.svg'))
        .width(22)
        .height(22)
        .padding(3)
        .onClick(() => {
          this.showSecurityBar = false;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 17, top: 16, bottom: 16 })
    .backgroundColor('#FFE8D5')
    .alignItems(VerticalAlign.Top)
  }
}

class ChatProfileUpdatedObserver implements TUIObserver {
  private readonly host: ChatPage;

  constructor(host: ChatPage) {
    this.host = host;
  }

  onNotify(event: string, key: string | null, params: NotifyParams | null): void {
    console.info(`[ChatProfileUpdatedObserver] onNotify. event=${event}, key=${key}, hasData=${params?.data != null}`);
    const data: Record<string, Object> | null | undefined = params?.data;
    if (!data) {
      return;
    }
    const conversationIDValue: Object | undefined = data['conversationID'];
    if (!conversationIDValue) {
      return;
    }
    const conversationID: string = conversationIDValue as string;
    const titleValue: Object | undefined = data['title'];
    const avatarURLValue: Object | undefined = data['avatarURL'];
    const title: string | undefined = titleValue === undefined ? undefined : (titleValue as string);
    const avatarURL: string | undefined = avatarURLValue === undefined ? undefined : (avatarURLValue as string);
    this.host.applyProfileUpdate(conversationID, title, avatarURL);
  }
}