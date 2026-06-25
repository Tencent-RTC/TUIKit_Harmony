import { MessageInfo, GroupSettingStore, GroupMemberRole, GroupMember, LoginStore } from '@tencentcloud/atomicxcore';
import { Avatar, AvatarContentType, AvatarSize, LanguageState, ThemeState } from '@tencentcloud/atomicx';
import { MessageList, MultiSelectBottomBar, MultiSelectActions } from '@tencentcloud/atomicx';
import { MessageInput } from '@tencentcloud/atomicx';
import { TUIEventBus, PublishParams } from '@tencentcloud/atomicx';
import { CallMediaType } from '@tencentcloud/atomicx';
import { UserPicker, UserPickerData } from '@tencentcloud/atomicx';

@CustomDialog
struct GroupMemberPickerDialog {
  controller: CustomDialogController;
  @State dataSource: UserPickerData<GroupMember>[] = [];
  @State isLoading: boolean = true;
  @State private selectedKeysOrder: string[] = [];
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  groupID: string = '';
  onConfirm?: (selectedItems: UserPickerData<GroupMember>[]) => void;
  private groupSettingStore?: GroupSettingStore;
  private selectedItems: UserPickerData<GroupMember>[] = [];

  aboutToAppear(): void {
    this.fetchGroupMembers();
  }

  private fetchGroupMembers(): void {
    if (!this.groupID) {
      this.isLoading = false;
      return;
    }
    this.groupSettingStore = GroupSettingStore.create(this.groupID);
    this.groupSettingStore.fetchGroupMemberList(GroupMemberRole.ALL)
      .then(() => {
        this.updateMembersFromState();
        this.isLoading = false;
      })
      .catch((error: Error) => {
        console.error('[GroupMemberPickerDialog] Failed to load group members:', error.message);
        this.isLoading = false;
      });
  }

  private updateMembersFromState(): void {
    if (!this.groupSettingStore) {
      return;
    }
    const currentUserID: string = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    const members = this.groupSettingStore.state.allMembers;
    const list: UserPickerData<GroupMember>[] = members
      .filter((member: GroupMember) => member.userID !== currentUserID)
      .map((member: GroupMember): UserPickerData<GroupMember> => {
        const displayName = this.getDisplayName(member);
        const data: UserPickerData<GroupMember> = {
          key: member.userID,
          label: displayName,
          avatarUrl: member.avatarURL,
          extraData: member,
        };
        return data;
      });
    this.dataSource = list;
  }

  private getDisplayName(member: GroupMember): string {
    if (member.nameCard && member.nameCard.length > 0) {
      return member.nameCard;
    }
    if (member.nickname && member.nickname.length > 0) {
      return member.nickname;
    }
    return member.userID;
  }

  private handleConfirmClick(): void {
    if (this.onConfirm && this.selectedItems.length > 0) {
      this.onConfirm(this.selectedItems);
    }
    this.controller.close();
  }

  private handleCancelClick(): void {
    this.controller.close();
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          this.TitleBarBuilder()
          Divider()
            .height(1)
            .color(this.themeState.colors.strokeColorSecondary)
          UserPicker({
            dataSource: this.dataSource,
            defaultSelectedItems: [],
            showNavigationBar: false,
            showSelectedTags: false,
            onSelectedChanged: (items: UserPickerData<ESObject>[]) => {
              this.selectedItems = items as UserPickerData<GroupMember>[];
              this.selectedKeysOrder = items.map((i: UserPickerData<ESObject>): string => i.key);
            },
          })
            .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('70%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  TitleBarBuilder() {
    Row() {
      Text($r('app.string.cancel_button'))
        .fontSize(16)
        .fontWeight(400)
        .fontColor(this.themeState.colors.textColorLink)
        .onClick(() => {
          this.handleCancelClick();
        })

      Blank()

      Text($r('app.string.chatsetting_group_members_title'))
        .fontSize(18)
        .fontWeight(600)
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Text($r('app.string.confirm'))
        .fontSize(16)
        .fontWeight(400)
        .fontColor(this.selectedKeysOrder.length > 0 ?
        this.themeState.colors.textColorLink :
        this.themeState.colors.textColorSecondary)
        .enabled(this.selectedKeysOrder.length > 0)
        .onClick(() => {
          this.handleConfirmClick();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

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
  onCallMessageClick?: (userID: string, isVideoCall: boolean) => void;
  onCallStart?: (participantIds: string[], mediaType: CallMediaType, chatGroupId: string, timeout: number) => void;

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
      onCallStart: (participantIds: string[], mediaType: CallMediaType, chatGroupId: string, timeout: number) => {
        if (this.onCallStart) {
          this.onCallStart(participantIds, mediaType, chatGroupId, timeout);
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
  private groupMemberPickerController?: CustomDialogController;

  onBack?: () => void;
  onUserClick?: (userID: string) => void;
  onChatHeaderClick?: (conversationID: string) => void;
  onCallStart?: (participantIds: string[], mediaType: CallMediaType, chatGroupId: string, timeout: number) => void;
  dialogController?: CustomDialogController;

  aboutToAppear(): void {
  }

  aboutToDisappear(): void {
  }

  private isGroupConversation(): boolean {
    return this.conversationID.startsWith('group_');
  }

  private getGroupID(): string {
    if (this.conversationID.startsWith('group_')) {
      return this.conversationID.substring(6);
    }
    return '';
  }

  private getUserID(): string {
    if (this.conversationID.startsWith('c2c_')) {
      return this.conversationID.substring(4);
    }
    return '';
  }

  private dispatchCallStart(participantIds: string[], mediaType: CallMediaType, chatGroupId: string, timeout: number): void {
    if (participantIds.length === 0) {
      return;
    }
    if (this.onCallStart) {
      this.onCallStart(participantIds, mediaType, chatGroupId, timeout);
      return;
    }
    // Fallback: keep legacy event-bus path for callers that have not yet
    // wired the direct callback.
    const data: Record<string, Object> = {
      'participantIds': participantIds,
      'mediaType': mediaType as Object,
      'chatGroupId': chatGroupId as Object,
      'timeout': timeout as Object,
    };
    TUIEventBus.getInstance().publish('call.startCall', null, new PublishParams(false, data));
  }

  private onVoiceCallClick(): void {
    if (this.isGroupConversation()) {
      const chatGroupId = this.getGroupID();
      this.showGroupMemberPicker(chatGroupId, CallMediaType.audio);
    } else {
      this.dispatchCallStart([this.getUserID()], CallMediaType.audio, '', 30);
    }
  }

  private onVideoCallClick(): void {
    if (this.isGroupConversation()) {
      const chatGroupId = this.getGroupID();
      this.showGroupMemberPicker(chatGroupId, CallMediaType.video);
    } else {
      this.dispatchCallStart([this.getUserID()], CallMediaType.video, '', 30);
    }
  }

  private onCallMessageClick(userID: string, isVideoCall: boolean): void {
    this.dispatchCallStart([userID], isVideoCall ? CallMediaType.video : CallMediaType.audio, '', 30);
  }

  private showGroupMemberPicker(chatGroupId: string, mediaType: CallMediaType): void {
    this.groupMemberPickerController = new CustomDialogController({
      builder: GroupMemberPickerDialog({
        groupID: chatGroupId,
        onConfirm: (selectedItems: UserPickerData<GroupMember>[]) => {
          if (selectedItems.length > 0) {
            const participantIds: string[] = selectedItems.map((item: UserPickerData<GroupMember>): string => item.key);
            this.dispatchCallStart(participantIds, mediaType, chatGroupId, 30);
          }
        },
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true,
    });
    this.groupMemberPickerController.open();
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
            onVoiceCallClick: () => {
              this.onVoiceCallClick();
            },
            onVideoCallClick: () => {
              this.onVideoCallClick();
            },
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
          Image($rawfile("basecomponent/common_back_icon.svg"))
            .scale({
              x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
              y: 1
            })
            .width(10)
            .height(10)
            .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
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
          .onClick(() => {
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

      Divider()
        .width('100%')
        .height(0.3)
        .color(this.themeState.colors.strokeColorSecondary)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}
