import { MessageInfo } from '@tencentcloud/atomicxcore';
import { Avatar, AvatarContentType, AvatarSize, ThemeState } from '@tencentcloud/atomicx';
import { MessageList } from '@tencentcloud/atomicx';
import { MessageInput } from '@tencentcloud/atomicx';

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
  @State conversationID: string = '';
  @State title: string = '';
  @State status: string = '';
  @State avatarUrl: string = '';
  @State locateMessage?: MessageInfo = undefined;
  
  // External callbacks
  onBack?: () => void;
  onUserClick?: (userID: string) => void;
  onChatHeaderClick?: (conversationID: string) => void;
  dialogController?: CustomDialogController;

  aboutToAppear(): void {
  }

  aboutToDisappear(): void {
  }

  build() {
    Stack() {
      Column() {
        this.LargeTitleBuilder();
        MessageList({
          conversationID: this.conversationID,
          onUserClick: (userID: string) => {
            console.log(`[ChatPage] User avatar clicked: ${userID}`);
            if (this.onUserClick) {
              this.onUserClick(userID);
            }
          }
        })
          .width('100%')
          .layoutWeight(1)

        MessageInput({
          conversationID: this.conversationID,
        })
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
          // Back button
          Image($r('app.media.back_icon'))
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.textColorSecondary)
            .onClick(() => {
              if (this.onBack) {
                this.onBack();
              }
            })

          Row({ space: 8 }) {
            // Avatar
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
          .onClick(() => {
            console.log(`[ChatPage] Chat header clicked: ${this.conversationID}`);
            if (this.onChatHeaderClick) {
              this.onChatHeaderClick(this.conversationID);
            }
          })
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(56)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)

      // Divider
      Divider()
        .width('100%')
        .height(0.3)
        .color(this.themeState.colors.strokeColorSecondary)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}
