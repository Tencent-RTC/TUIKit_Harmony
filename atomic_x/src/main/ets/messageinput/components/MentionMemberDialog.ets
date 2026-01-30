import { ThemeState } from '../../basecomponent/Index';
import { GroupMember, GroupMemberRole, GroupSettingStore } from '@tencentcloud/atomicxcore';
import { UserPicker, UserPickerData } from '../../userpicker/Index';
import { MentionInfo } from './MentionInfo';

/**
 * Dialog for selecting group members to mention
 * - Built on top of UserPicker
 * - Provides a fixed "@All" entry at the top
 */
@CustomDialog
export struct MentionMemberDialog {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  @State private isLoading: boolean = true;
  @State private isLoadingMore: boolean = false;
  @State private dataSource: UserPickerData<GroupMember>[] = [];
  @State private selectedItems: UserPickerData<GroupMember>[] = [];
  @State private selectedKeysOrder: string[] = [];

  controller?: CustomDialogController;
  groupID: string = '';
  atPosition: number = 0;
  onMembersSelected?: (mentions: MentionInfo[]) => void;
  onCancel?: () => void;

  private groupSettingStore?: GroupSettingStore;

  aboutToAppear() {
    if (this.groupID) {
      this.groupSettingStore = GroupSettingStore.create(this.groupID);
      this.loadMembers();
    } else {
      this.isLoading = false;
    }
  }

  private loadMembers(): void {
    if (!this.groupSettingStore) {
      this.isLoading = false;
      return;
    }

    this.groupSettingStore.fetchGroupMemberList(GroupMemberRole.ALL)
      .then(() => {
        this.updateMembersFromState();
        this.isLoading = false;
      })
      .catch((error: Error) => {
        console.error('[MentionMemberDialog] Failed to load group members:', error.message);
        this.isLoading = false;
      });
  }

  private loadMoreMembers(): void {
    if (!this.groupSettingStore || this.isLoadingMore) {
      return;
    }

    const state = this.groupSettingStore.state;
    if (!state.hasMoreGroupMembers) {
      return;
    }

    this.isLoadingMore = true;
    this.groupSettingStore.fetchMoreGroupMemberList()
      .then(() => {
        this.updateMembersFromState();
        this.isLoadingMore = false;
      })
      .catch((error: Error) => {
        console.error('[MentionMemberDialog] Failed to load more group members:', error.message);
        this.isLoadingMore = false;
      });
  }

  private updateMembersFromState(): void {
    if (!this.groupSettingStore) {
      return;
    }

    const members = this.groupSettingStore.state.allMembers;
    const list: UserPickerData<GroupMember>[] = members.map((member: GroupMember): UserPickerData<GroupMember> => {
      const displayName = this.getDisplayName(member);
      const data: UserPickerData<GroupMember> = {
        key: member.userID,
        label: displayName,
        avatarUrl: member.avatarURL,
        extraData: member
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

  private handleAtAllClick(): void {
    const mentionInfo: MentionInfo = MentionInfo.create(
      MentionInfo.AT_ALL_USER_ID,
      getContext().resourceManager.getStringSync($r('app.string.mention_all').id),
      this.atPosition
    );

    if (this.onMembersSelected) {
      this.onMembersSelected([mentionInfo]);
    }
    this.controller?.close();
  }

  private handleConfirmClick(): void {
    const selectedMentions: MentionInfo[] = [];

    this.selectedItems.forEach((user: UserPickerData<GroupMember>) => {
      const member = user.extraData;
      if (member) {
        selectedMentions.push(MentionInfo.create(member.userID, this.getDisplayName(member), this.atPosition));
      }
    });

    if (this.onMembersSelected && selectedMentions.length > 0) {
      this.onMembersSelected(selectedMentions);
    }

    this.controller?.close();
  }

  private handleCancelInternal = () => {
    if (this.onCancel) {
      this.onCancel();
    }
    this.controller?.close();
  }

  build() {
    Column() {
      // Custom Title Bar to replace UserPicker's internal one
      this.TitleBarBuilder()
      Divider()
        .height(1)
        .color(this.themeState.colors.strokeColorSecondary)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(this.themeState.colors.textColorLink)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          // Fixed "@All" entry
          this.AtAllHeaderBuilder()
          
          UserPicker({
            dataSource: this.dataSource,
            defaultSelectedItems: [],
            showNavigationBar: false, 
            showSelectedTags: false,  
            onSelectedChanged: (items: UserPickerData<ESObject>[]) => {
              this.selectedItems = items as UserPickerData<GroupMember>[];
              this.selectedKeysOrder = items.map((i: UserPickerData<ESObject>): string => i.key);
            },
            onReachEnd: () => {
              this.loadMoreMembers();
            }
          })
          .layoutWeight(1)
        }
        .layoutWeight(1)
      }

      if (this.isLoadingMore) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.themeState.colors.textColorLink)
        }
        .width('100%')
        .height(40)
        .justifyContent(FlexAlign.Center)
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
          this.handleCancelInternal();
        })

      Blank()

      Text($r('app.string.mention_select_member'))
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

  @Builder
  AtAllHeaderBuilder() {
    Column() {
      Row() {
        // @All icon
        Stack() {
          Circle()
            .width(40)
            .height(40)
            .fill(this.themeState.colors.textColorLink)

          Text('@')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(40)
        .height(40)

        Text($r('app.string.mention_all'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorLink)
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .onClick(() => {
        this.handleAtAllClick();
      })

      Divider()
        .height(0.5)
        .color(this.themeState.colors.strokeColorSecondary)
    }
  }
}
