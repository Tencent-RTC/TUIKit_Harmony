import { ThemeState } from '../../basecomponent/Index';
import {
  CompletionHandler,
  GroupMember,
  GroupMemberFilterRole,
  GroupMemberStore,
  LoginStore
} from '@tencentcloud/atomicxcore';
import { UserPicker, UserPickerData } from '../../userpicker/Index';

/**
 * Dialog for selecting group members.
 *
 * Aligned with Android `GroupMemberPickerDialog` (chatsetting/ui).
 * Currently used by `MessageInput.showGroupCallMemberPicker` for group call.
 *
 * - Uses `GroupMemberStore` to load members
 * - Filters out the current login user (cannot call oneself)
 * - Emits selected user IDs via `onConfirm`; publisher happens in caller
 */
class GroupMembersLoadHandler implements CompletionHandler {
  private readonly dialog: GroupMemberPickerDialog;

  constructor(dialog: GroupMemberPickerDialog) {
    this.dialog = dialog;
  }

  onSuccess(): void {
    this.dialog.onLoadMembersSuccess();
  }

  onFailure(code: number, desc: string): void {
    this.dialog.onLoadMembersFailure(code, desc);
  }
}

@CustomDialog
export struct GroupMemberPickerDialog {
  controller: CustomDialogController;
  @State dataSource: UserPickerData<GroupMember>[] = [];
  @State isLoading: boolean = true;
  @State private selectedKeysOrder: string[] = [];
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  groupID: string = '';
  onConfirm?: (selectedItems: UserPickerData<GroupMember>[]) => void;
  private groupMemberStore?: GroupMemberStore;
  private selectedItems: UserPickerData<GroupMember>[] = [];

  aboutToAppear(): void {
    this.fetchGroupMembers();
  }

  private fetchGroupMembers(): void {
    if (!this.groupID) {
      this.isLoading = false;
      return;
    }
    this.groupMemberStore = GroupMemberStore.create(this.groupID);
    this.groupMemberStore.loadMembers([GroupMemberFilterRole.ALL], new GroupMembersLoadHandler(this));
  }

  onLoadMembersSuccess(): void {
    this.updateMembersFromState();
    this.isLoading = false;
  }

  onLoadMembersFailure(code: number, desc: string): void {
    console.error('[GroupMemberPickerDialog] Failed to load group members:', code, desc);
    this.isLoading = false;
  }

  private updateMembersFromState(): void {
    if (!this.groupMemberStore) {
      return;
    }
    const currentUserID: string = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    const members = this.groupMemberStore.state.memberList;
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
            onSelectedChanged: (items: UserPickerData<GroupMember>[]) => {
              this.selectedItems = items;
              this.selectedKeysOrder = items.map((i: UserPickerData<GroupMember>): string => i.key);
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
