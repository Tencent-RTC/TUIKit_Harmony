import { MessageActionStore, MessageInfo, MessageListStore, GroupMember, MessageType } from '@tencentcloud/atomicxcore';
import {
  Avatar,
  AvatarContentType,
  AvatarSize,
  TextUtils,
  ThemeState,
  Toast
} from '../../basecomponent/Index';
import { GetMessageView } from './MessageItem';
import { ChatMessageListConfig, MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageRenderContext } from '../context/MessageRenderContext';

@CustomDialog
export struct MessageReadReceiptDetailPage {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  controller: CustomDialogController;
  message!: MessageInfo;
  messageListStore!: MessageListStore;

  private messageActionStore?: MessageActionStore = undefined;
  @State private isReadSectionExpanded: boolean = true;
  @State private isUnReadSectionExpanded: boolean = true;

  @State private readMemberList: GroupMember[] = [];
  @State private unReadMemberList: GroupMember[] = [];
  @State private hasMoreReadMembers: boolean = true;
  @State private hasMoreUnReadMembers: boolean = true;

  private readonly HEADER_HEIGHT: number = 56;
  private readonly MEMBER_CELL_HEIGHT: number = 56;
  private readonly SECTION_RADIUS: number = 30;
  private readonly previewConfig: MessageListStyleProtocol = new ChatMessageListConfig({
    enableReadReceipt: false,
    isSupportCopy: false,
    isSupportDelete: false,
    isSupportRecall: false,
    isSupportForward: false,
    isSupportMultiSelect: false,
  });

  aboutToAppear() {
    this.messageActionStore = MessageActionStore.create(this.message);
    this.loadInitialData();
  }

  build() {
    Column() {
      this.buildHeader();

      Scroll() {
        Column({ space: 12 }) {
          Text(this.formatTimestampToMMDDHHmm(this.message.timestamp))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ top: 16, bottom: 4 })

          this.buildMessageBubble();

          this.buildMemberSection(true);
          this.buildMemberSection(false);
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorDefault)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private buildHeader() {
    Row() {
      Image($rawfile('messagelist/back_icon.svg'))
        .width(12)
        .height(20)
        .fillColor(this.themeState.colors.textColorLink)
        .onClick(() => {
          this.controller.close();
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
        .width(24)
        .height(24)
    }
    .width('100%')
    .height(this.HEADER_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  private buildMessageBubble() {
    Row() {
      Blank();

      Column() {
        GetMessageView({
          message: this.message,
          messageListStore: this.messageListStore,
          config: this.previewConfig,
          isInMergedDetailView: true
        });
      }
      .borderRadius({
        topLeft: 16,
        topRight: 16,
        bottomLeft: 16,
        bottomRight: 0
      })
      .backgroundColor(this.themeState.colors.bgColorBubbleOwn)
      .borderWidth(1)
      .borderColor(this.themeState.colors.bgColorBubbleOwn)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .margin({ bottom: 12 })
  }

  private getMembers(isRead: boolean): Array<GroupMember> {
    return isRead ? this.readMemberList : this.unReadMemberList;
  }

  private hasMoreMembers(isRead: boolean): boolean {
    return isRead ? this.hasMoreReadMembers : this.hasMoreUnReadMembers;
  }

  private isSectionExpanded(isRead: boolean): boolean {
    return isRead ? this.isReadSectionExpanded : this.isUnReadSectionExpanded;
  }

  private toggleSectionExpanded(isRead: boolean) {
    if (isRead) {
      this.isReadSectionExpanded = !this.isReadSectionExpanded;
    } else {
      this.isUnReadSectionExpanded = !this.isUnReadSectionExpanded;
    }
  }

  private getSectionTitle(isRead: boolean): Resource {
    return isRead ? $r('app.string.read_receipt_read_by') : $r('app.string.read_receipt_delivered_to');
  }

  @Builder
  private buildMemberSection(isRead: boolean) {
    Column() {
      Row() {
        Text(this.getSectionTitle(isRead))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeState.colors.textColorPrimary)

        Text(` (${this.getMembers(isRead).length})`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeState.colors.textColorSecondary)

        Blank();

        Text(this.isSectionExpanded(isRead) ? '▲' : '▼')
          .fontSize(12)
          .fontColor(this.themeState.colors.textColorSecondary)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .borderRadius(this.isSectionExpanded(isRead) ? 40 : this.SECTION_RADIUS)
      .onClick(() => {
        this.toggleSectionExpanded(isRead);
      })

      if (this.isSectionExpanded(isRead)) {
        Column() {
          ForEach(this.getMembers(isRead), (member: GroupMember) => {
            this.buildMemberRow(member);
          }, (member: GroupMember) => member.userID)

          if (this.hasMoreMembers(isRead)) {
            this.buildLoadMoreButton(isRead);
          }
        }
        .width('100%')
        .padding({ top: 8 })
      }
    }
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
        avatarSize: AvatarSize.M,
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
    .padding({ left: 8, right: 8 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius(8)
    .margin({ top: 8 })
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

    this.messageActionStore.fetchMessageReadMembers(20)
      .then(() => {
        this.syncStateFromStore();
      })
      .catch(() => {
        Toast.info($r('app.string.read_receipt_load_failed'), this.getUIContext());
      });

    this.messageActionStore.fetchMessageUnreadMembers(20)
      .then(() => {
        this.syncStateFromStore();
      })
      .catch(() => {
        Toast.info($r('app.string.read_receipt_load_failed'), this.getUIContext());
      });
  }

  private loadMoreMembers(isRead: boolean) {
    if (!this.messageActionStore) {
      return;
    }

    this.messageActionStore.fetchMoreMessageMembers(isRead)
      .then(() => {
        this.syncStateFromStore();
      })
      .catch(() => {
        Toast.info($r('app.string.read_receipt_load_failed'), this.getUIContext());
      });
  }

  private syncStateFromStore() {
    if (!this.messageActionStore) {
      return;
    }
    const state = this.messageActionStore.state;
    this.readMemberList = [...state.readMemberList];
    this.unReadMemberList = [...state.unReadMemberList];
    this.hasMoreReadMembers = state.hasMoreReadMembers;
    this.hasMoreUnReadMembers = state.hasMoreUnReadMembers;
  }

  private formatTimestampToMMDDHHmm(timestamp?: number): string {
    if (!timestamp) {
      return '';
    }

    const ms = timestamp > 1000000000000 ? timestamp : timestamp * 1000;
    const date = new Date(ms);
    const mm = (date.getMonth() + 1).toString().padStart(2, '0');
    const dd = date.getDate().toString().padStart(2, '0');
    const hh = date.getHours().toString().padStart(2, '0');
    const min = date.getMinutes().toString().padStart(2, '0');
    return `${mm}-${dd} ${hh}:${min}`;
  }
}
