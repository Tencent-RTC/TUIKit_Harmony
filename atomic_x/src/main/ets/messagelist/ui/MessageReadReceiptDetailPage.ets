import { MessageActionStore } from '@tencentcloud/atomicxcore';
import { MessageInfo, MessageListStore } from '@tencentcloud/atomicxcore';
import { GroupMember } from '@tencentcloud/atomicxcore';
import {
  AtomicxNavigator,
  Avatar,
  AvatarContentType,
  AvatarSize,
  BackButton,
  TextUtils,
  ThemeState,
  Toast
} from '../../basecomponent/Index';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';

interface MessageReadReceiptDetailArgs {
  message: MessageInfo;
  messageListStore: MessageListStore;
}

@Builder
function MessageReadReceiptDetailPageBuilder(args: Object) {
  MessageReadReceiptDetailContent({
    message: (args as MessageReadReceiptDetailArgs).message,
    messageListStore: (args as MessageReadReceiptDetailArgs).messageListStore,
    onClose: () => {
      AtomicxNavigator.pop();
    }
  })
}

export function pushMessageReadReceiptDetailPage(message: MessageInfo, messageListStore: MessageListStore): boolean {
  const args: MessageReadReceiptDetailArgs = { message: message, messageListStore: messageListStore };
  return AtomicxNavigator.push(wrapBuilder(MessageReadReceiptDetailPageBuilder), args);
}

@CustomDialog
export struct MessageReadReceiptDetailPage {
  controller: CustomDialogController;
  message!: MessageInfo;
  messageListStore!: MessageListStore;

  build() {
    MessageReadReceiptDetailContent({
      message: this.message,
      messageListStore: this.messageListStore,
      onClose: () => {
        this.controller.close();
      }
    })
  }
}

@Component
struct MessageReadReceiptDetailContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  message!: MessageInfo;
  messageListStore!: MessageListStore;
  onClose?: () => void;

  private messageActionStore?: MessageActionStore = undefined;
  @State private selectedReadTab: boolean = true;

  @State private readMemberList: GroupMember[] = [];
  @State private unReadMemberList: GroupMember[] = [];
  @State private hasMoreReadMembers: boolean = true;
  @State private hasMoreUnReadMembers: boolean = true;

  private readonly HEADER_HEIGHT: number = 56;
  private readonly MEMBER_CELL_HEIGHT: number = 52;

  aboutToAppear() {
    this.messageActionStore = MessageActionStore.create(this.message);
    this.selectedReadTab = (this.message.readReceiptInfo?.readCount ?? 0) > 0;
    this.loadInitialData();
  }

  build() {
    Column() {
      this.buildHeader();

      Divider()
        .width('100%')
        .height(1)
        .color(this.themeState.colors.strokeColorSecondary);

      Column() {
        Row({ space: 12 }) {
          this.buildReceiptTab(true);
          this.buildReceiptTab(false);
        }
        .width('100%')
        .height(40)

        Scroll() {
          Column() {
            ForEach(this.getMembers(this.selectedReadTab), (member: GroupMember) => {
              this.buildMemberRow(member);
            }, (member: GroupMember) => member.userID)

            if (this.hasMoreMembers(this.selectedReadTab)) {
              this.buildLoadMoreButton(this.selectedReadTab);
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .margin({ top: 12 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .align(Alignment.Top)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private buildHeader() {
    Row() {
      BackButton({
        onBack: () => {
          this.onClose?.();
        }
      })

      Text($r('app.string.read_receipt_detail_title'))
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row()
        .width(44)
        .height(44)
    }
    .width('100%')
    .height(this.HEADER_HEIGHT)
    .padding({ left: 0, right: 0 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  private getMembers(isRead: boolean): Array<GroupMember> {
    return isRead ? this.readMemberList : this.unReadMemberList;
  }

  private hasMoreMembers(isRead: boolean): boolean {
    return isRead ? this.hasMoreReadMembers : this.hasMoreUnReadMembers;
  }

  private getSectionTitle(isRead: boolean): Resource {
    return isRead ? $r('app.string.read_receipt_read_by') : $r('app.string.read_receipt_delivered_to');
  }

  @Builder
  private buildReceiptTab(isRead: boolean) {
    Row({ space: 4 }) {
      Text(this.getSectionTitle(isRead))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedReadTab === isRead
          ? this.themeState.colors.textColorPrimary
          : this.themeState.colors.textColorSecondary)

      Text(` (${this.getMembers(isRead).length})`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedReadTab === isRead
          ? this.themeState.colors.textColorPrimary
          : this.themeState.colors.textColorSecondary)
    }
    .layoutWeight(1)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.selectedReadTab === isRead
      ? this.themeState.colors.tabColorSelected
      : this.themeState.colors.tabColorUnselected)
    .borderRadius(20)
    .onClick(() => {
      this.selectedReadTab = isRead;
    })
  }

  @Builder
  private buildMemberRow(member: GroupMember) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: member.avatarURL,
          name: TextUtils.getAvatarLetter(member.nameCard || member.nickname || member.userID) || '',
        },
        avatarSize: AvatarSize.S,
      })

      Text((member.nameCard || member.nickname || member.userID).toString())
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 12 })

      Blank();
    }
    .width('100%')
    .height(this.MEMBER_CELL_HEIGHT)
    .padding({ left: 4, right: 4, top: 8, bottom: 8 })
  }

  @Builder
  private buildLoadMoreButton(isRead: boolean) {
    Row() {
      Blank();
      Text($r('app.string.messagelist_loading_more'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorLink)
      Blank();
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius(8)
    .margin({ top: 8 })
    .onClick(() => {
      this.loadMoreMembers(isRead);
    })
  }

  private loadInitialData() {
    if (!this.messageActionStore) {
      return;
    }

    this.messageActionStore.loadReadMembers(20, new CompletionHandlerAdapter(() => {
      this.syncStateFromStore();
    }, () => {
      Toast.info($r('app.string.read_receipt_load_failed'), this.getUIContext());
    }));

    this.messageActionStore.loadUnreadMembers(20, new CompletionHandlerAdapter(() => {
      this.syncStateFromStore();
    }, () => {
      Toast.info($r('app.string.read_receipt_load_failed'), this.getUIContext());
    }));
  }

  private loadMoreMembers(isRead: boolean) {
    if (!this.messageActionStore) {
      return;
    }

    this.messageActionStore.loadMoreMembers(isRead, new CompletionHandlerAdapter(() => {
      this.syncStateFromStore();
    }, () => {
      Toast.info($r('app.string.read_receipt_load_failed'), this.getUIContext());
    }));
  }

  private syncStateFromStore() {
    if (!this.messageActionStore) {
      return;
    }
    const state = this.messageActionStore.state;
    this.readMemberList = Array.from(state.readMemberList);
    this.unReadMemberList = Array.from(state.unreadMemberList);
    this.hasMoreReadMembers = state.hasMoreReadMembers;
    this.hasMoreUnReadMembers = state.hasMoreUnreadMembers;
  }

}
