import {
  ActionItem,
  ActionSheet,
  Avatar,
  AvatarContentType,
  AvatarSize,
  TextUtils,
  ThemeState,
  Toast
} from '../../basecomponent/Index';
import { GroupMember, GroupMemberRole, GroupSettingState, GroupSettingStore, GroupType, LoginStore } from '@tencentcloud/atomicxcore';
import { GroupPermission, GroupPermissionManager } from '../manager/GroupPermissionManager';
import { ActionButtonConfig } from '../dialog/GroupSettingDialogs';
import { UserInteractionHelper } from '../helper/UserInteractionHelper';

@Component
export struct GroupMemberListPage {
  private static readonly CELL_HEIGHT: number = 56;
  private static readonly SECTION_MARGIN: number = 12;
  private static readonly HORIZONTAL_PADDING: number = 16;
  private static readonly BORDER_RADIUS: number = 12;
  private static readonly MEMBER_AVATAR_SIZE: number = 40;
  private static readonly SEARCH_BAR_HEIGHT: number = 36;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State groupStore?: GroupSettingStore = undefined;
  @State groupState?: GroupSettingState = this.groupStore?.state;
  @State isLoading: boolean = true;
  @State searchText: string = '';
  @State filteredMembers: GroupMember[] = [];
  @State showSearchBar: boolean = false;
  @State selectedMember?: GroupMember = undefined;
  @Prop groupID: string = '';
  @Prop groupName: string | Resource = $r('app.string.chatsetting_group_members_title');
  onMemberSelect?: (member: GroupMember) => void;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  dialogController?: CustomDialogController;
  private memberOptionsDialogController?: CustomDialogController;
  private userInteractionHelper: UserInteractionHelper = new UserInteractionHelper();

  aboutToAppear(): void {
    if (this.groupID) {
      this.groupStore = GroupSettingStore.create(this.groupID);
      this.groupState = this.groupStore.state;
      this.loadGroupData();
    }
  }

  aboutToDisappear(): void {
    this.groupStore = undefined;
    this.groupState = undefined;

    if (this.memberOptionsDialogController) {
      this.memberOptionsDialogController = undefined;
    }

    // Clean up user interaction dialogs
    UserInteractionHelper.closeDialog();
  }

  build() {
    Column() {
      this.NavigationBarBuilder()

      if (this.isLoading) {
        this.LoadingStateBuilder()
      } else {
        Column() {


          this.MemberStatsBuilder()


          this.MemberListBuilder()
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorInput)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorInput)
  }

  onBackPress(): boolean {
    this.closeDialog();
    return true;
  }

  @Builder
  NavigationBarBuilder() {
    Row() {
      // Back button
      Image($rawfile('search/back_icon.svg'))
        .width(24)
        .height(24)
        .fillColor(this.themeState.colors.textColorLink)
        .onClick(() => {
          this.closeDialog();
        })

      Blank()

      // Title
      Text(this.groupName)
        .fontSize(18)
        .fontWeight(600)
        .fontFamily('SF Pro Display')
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)

    // Divider
    Divider()
      .height(0.5)
      .color(this.themeState.colors.strokeColorSecondary)
  }

  @Builder
  LoadingStateBuilder() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.themeState.colors.textColorLink)

      Text($r('app.string.chatsetting_loading_group_members'))
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MemberStatsBuilder() {
    Row() {
      Text(`${this.filteredMembers.length} Members`)
        .fontSize(14)
        .fontWeight(500)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorSecondary)

      Blank()

    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8
    })
  }

  @Builder
  MemberListBuilder() {
    List() {
      // 1. Show current user first (if exists in members)
      ForEach(this.getCurrentUserMembers(), (member: GroupMember) => {
        ListItem() {
          this.MemberRowBuilder(member)
        }
      })

      // 2. Show group owner (if not current user)
      ForEach(this.getGroupOwnerMembers(), (member: GroupMember) => {
        ListItem() {
          this.MemberRowBuilder(member)
        }
      })

      // 3. Show admin members (excluding current user and owner)
      ForEach(this.getAdminMembers(), (member: GroupMember) => {
        ListItem() {
          this.MemberRowBuilder(member)
        }
      })

      // 4. Show ordinary members (excluding current user)
      ForEach(this.getOrdinaryMembers(), (member: GroupMember) => {
        ListItem() {
          this.MemberRowBuilder(member)
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .margin({ left: 16, right: 16, bottom: 16 })
    .divider({
      strokeWidth: 1,
      color: this.themeState.colors.strokeColorSecondary,
      startMargin: GroupMemberListPage.HORIZONTAL_PADDING + GroupMemberListPage.MEMBER_AVATAR_SIZE + 12,
      endMargin: GroupMemberListPage.HORIZONTAL_PADDING
    })
  }

  @Builder
  MemberRowBuilder(member: GroupMember) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: member.avatarURL,
          name: TextUtils.getAvatarLetter(member.nickname) || '',
        },
        avatarSize: AvatarSize.M,
      })

      Column({ space: 2 }) {
        Row() {
          Text((member.nameCard || member.nickname || member.userID).toString())
            .fontSize(17)
            .fontWeight(400)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)


          if (member.role === GroupMemberRole.OWNER) {
            Text($r('app.string.chatsetting_owner'))
              .fontSize(12)
              .fontWeight(500)
              .fontFamily('SF Pro Text')
              .fontColor(this.themeState.colors.textColorTertiary)
              .padding({
                left: 6,
                right: 6,
                top: 2,
                bottom: 2
              })
              .backgroundColor('rgba(255, 149, 0, 0.1)')
              .borderRadius(4)
          } else if (member.role === GroupMemberRole.ADMIN) {
            Text($r('app.string.chatsetting_admin'))
              .fontSize(12)
              .fontWeight(500)
              .fontFamily('SF Pro Text')
              .fontColor(this.themeState.colors.textColorLink)
              .padding({
                left: 6,
                right: 6,
                top: 2,
                bottom: 2
              })
              .backgroundColor('rgba(3, 101, 249, 0.1)')
              .borderRadius(4)
          }
        }

        if (member.userID !== (member.nameCard || member.nickname) && member.userID) {
          Text(`@${member.userID.toString()}`)
            .fontSize(14)
            .fontWeight(400)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }


        if (member.muteUntil && member.muteUntil > Date.now() / 1000) {
          Text($r('app.string.chatsetting_muted'))
            .fontSize(12)
            .fontWeight(500)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorTertiary)
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .backgroundColor('rgba(255, 88, 76, 0.1)')
            .borderRadius(4)
        }

      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)


      if (this.canManageMember(member)) {
        Image($rawfile('search/right_arrow_icon.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(GroupMemberListPage.CELL_HEIGHT)
    .padding({ left: GroupMemberListPage.HORIZONTAL_PADDING, right: GroupMemberListPage.HORIZONTAL_PADDING })
    .onClick(() => {
      if (this.canManageMember(member)) {
        this.showMemberOptions(member);
      } else {
        this.handleMemberClick(member);
      }
    })
  }

  private closeDialog(): void {
    if (this.dialogController) {
      this.dialogController.close();
    }
  }

  private async loadGroupData(): Promise<void> {
    if (!this.groupStore) {
      return;
    }

    try {
      await Promise.all([
        this.groupStore.fetchGroupInfo(),
        this.groupStore.fetchGroupMemberList()
      ]);
      this.filterMembers();
      console.log('[GroupMemberListPage] Group data loaded successfully');
    } catch (error) {
      console.error('[GroupMemberListPage] Failed to load group data:', error);
      Toast.info($r('app.string.chatsetting_load_group_info_fail_toast'), this.getUIContext());
    } finally {
      this.isLoading = false;
    }
  }

  private filterMembers(): void {
    const allMembers = this.groupState?.allMembers || [];

    if (this.searchText.trim().length === 0) {
      this.filteredMembers = allMembers;
    } else {
      const searchLower = this.searchText.toLowerCase();
      this.filteredMembers = allMembers.filter(member => {
        const name = (member.nameCard || member.nickname || member.userID).toLowerCase();
        const userID = member.userID.toLowerCase();
        return name.includes(searchLower) || userID.includes(searchLower);
      });
    }
  }

  private getCurrentUserMembers(): GroupMember[] {
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;
    if (!currentUserID) {
      return [];
    }
    return this.filteredMembers.filter(member => member.userID === currentUserID);
  }

  private getGroupOwnerMembers(): GroupMember[] {
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;
    return this.filteredMembers.filter(member =>
    member.role === GroupMemberRole.OWNER && member.userID !== currentUserID
    );
  }

  private getAdminMembers(): GroupMember[] {
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;
    return this.filteredMembers.filter(member =>
    member.role === GroupMemberRole.ADMIN && member.userID !== currentUserID
    );
  }

  private getOrdinaryMembers(): GroupMember[] {
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;
    return this.filteredMembers.filter(member =>
    member.role === GroupMemberRole.MEMBER && member.userID !== currentUserID
    );
  }

  private getFilteredOrdinaryMembers(): GroupMember[] {
    return this.filteredMembers.filter(member =>
    member.role === GroupMemberRole.MEMBER
    );
  }

  private hasPermission(permission: GroupPermission): boolean {
    const userRole = this.groupState?.currentUserRole;
    if (!userRole) {
      return false;
    }

    const groupType = this.convertStringToGroupType(this.groupState?.groupType);
    return GroupPermissionManager.hasPermission(groupType, userRole, permission);
  }

  private convertStringToGroupType(typeString: string | undefined): GroupType {
    if (!typeString) {
      return GroupType.WORK;
    }
    switch (typeString) {
      case 'Work':
        return GroupType.WORK;
      case 'Public':
        return GroupType.PUBLIC;
      case 'Meeting':
        return GroupType.MEETING;
      case 'AVChatRoom':
        return GroupType.AVCHATROOM;
      case 'Community':
        return GroupType.COMMUNITY;
      default:
        return GroupType.WORK;
    }
  }

  private canManageMember(member: GroupMember): boolean {

    if (member.userID === LoginStore.shared().state.loginUserInfo?.userID) {
      return false;
    }


    if (this.groupState?.currentUserRole === GroupMemberRole.OWNER) {
      return this.hasPermission(GroupPermission.SET_GROUP_MEMBER_ROLE) ||
      this.hasPermission(GroupPermission.REMOVE_GROUP_MEMBER);
    }


    if (this.groupState?.currentUserRole === GroupMemberRole.ADMIN &&
      member.role === GroupMemberRole.MEMBER) {
      return this.hasPermission(GroupPermission.REMOVE_GROUP_MEMBER);
    }

    return false;
  }

  private handleMemberClick(member: GroupMember): void {
    console.log('[GroupMemberListPage] Member clicked:', member.userID);
    // Show member detail dialog
    this.showMemberDetail(member);
  }

  private showMemberOptions(member: GroupMember): void {
    console.log('[GroupMemberListPage] Show options for member:', member.userID);
    this.selectedMember = member;


    const options: ActionButtonConfig[] = [];


    options.push({
      text: $r('app.string.chatsetting_member_detail'),
      action: 'detail',
      showDivider: true
    });


    if (this.groupState?.currentUserRole === GroupMemberRole.OWNER &&
      member.role === GroupMemberRole.MEMBER) {
      options.push({
        text: $r('app.string.chatsetting_member_set_admin'),
        action: 'setAdmin',
        showDivider: true
      });
    }


    if (this.groupState?.currentUserRole === GroupMemberRole.OWNER &&
      member.role === GroupMemberRole.ADMIN) {
      options.push({
        text: $r('app.string.chatsetting_member_remove_admin'),
        action: 'removeAdmin',
        showDivider: true
      });
    }


    if (this.canRemoveMember(member)) {
      options.push({
        text: $r('app.string.chatsetting_member_remove'),
        action: 'removeMember',
        color: '#FF584C',
        showDivider: false
      });
    }


    const actionItems: ActionItem[] = options.map((option: ActionButtonConfig): ActionItem => ({
      text: option.text,
      value: option.action,
      isDestructive: option.color === '#FF584C'
    }));


    this.memberOptionsDialogController = new CustomDialogController({
      builder: ActionSheet({
        title: `管理成员: ${member.nameCard || member.nickname || member.userID}`,
        options: actionItems,
        onActionSelected: (item: ActionItem) => {
          this.handleMemberAction(item.value as string, member);
        },
        onDismiss: () => {
          this.selectedMember = undefined;
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)',
      autoCancel: true
    });

    this.memberOptionsDialogController.open();
  }

  private canRemoveMember(member: GroupMember): boolean {

    if (member.userID === LoginStore.shared().state.loginUserInfo?.userID) {
      return false;
    }

    const currentUserRole = this.groupState?.currentUserRole;


    if (currentUserRole === GroupMemberRole.OWNER) {
      return member.role !== GroupMemberRole.OWNER &&
      this.hasPermission(GroupPermission.REMOVE_GROUP_MEMBER);
    }


    if (currentUserRole === GroupMemberRole.ADMIN &&
      member.role === GroupMemberRole.MEMBER) {
      return this.hasPermission(GroupPermission.REMOVE_GROUP_MEMBER);
    }

    return false;
  }

  private handleMemberAction(action: string, member: GroupMember): void {
    console.log('[GroupMemberListPage] Handle member action:', action, 'for member:', member.userID);

    switch (action) {
      case 'detail':
        this.showMemberDetail(member);
        break;
      case 'setAdmin':
        this.setMemberAsAdmin(member);
        break;
      case 'removeAdmin':
        this.removeMemberAdmin(member);
        break;
      case 'removeMember':
        this.removeMemberFromGroup(member);
        break;
      default:
        console.warn('[GroupMemberListPage] Unknown action:', action);
    }


    this.selectedMember = undefined;
  }

  private showMemberDetail(member: GroupMember): void {
    console.log('[GroupMemberListPage] Show member detail for:', member.userID);

    if (!member.userID) {
      console.error('[GroupMemberListPage] Member userID is empty');
      return;
    }

    // Use UserInteractionHelper to show user profile based on friendship
    this.userInteractionHelper.showUserProfileByFriendship(
      member.userID,
      this.getUIContext(),
      this.onSendMessageClick
    );
  }

  private setMemberAsAdmin(member: GroupMember): void {
    console.log('[GroupMemberListPage] Set member as admin:', member.userID);

    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable_toast'), this.getUIContext());
      return;
    }


    Toast.info($r('app.string.chatsetting_member_setting_admin'), this.getUIContext());

    this.groupStore.setGroupMemberRole(member.userID, GroupMemberRole.ADMIN)
      .then(() => {
        this.loadGroupData();
      })
      .catch((error: Error) => {
        console.error('[GroupMemberListPage] Failed to set member as admin:', error);
        Toast.info($r('app.string.chatsetting_member_setting_admin_fail'), this.getUIContext());
      });
  }

  private removeMemberAdmin(member: GroupMember): void {
    console.log('[GroupMemberListPage] Remove member admin:', member.userID);

    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable_toast'), this.getUIContext());
      return;
    }


    Toast.info($r('app.string.chatsetting_member_removing_admin'), this.getUIContext());

    this.groupStore.setGroupMemberRole(member.userID, GroupMemberRole.MEMBER)
      .then(() => {
        this.loadGroupData();
      })
      .catch((error: Error) => {
        console.error('[GroupMemberListPage] Failed to remove member admin:', error);
        Toast.info($r('app.string.chatsetting_member_remove_admin_fail'), this.getUIContext());
      });
  }

  private removeMemberFromGroup(member: GroupMember): void {
    console.log('[GroupMemberListPage] Remove member from group:', member.userID);

    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable_toast'), this.getUIContext());
      return;
    }


    Toast.info($r('app.string.chatsetting_member_removing'), this.getUIContext());

    this.groupStore.deleteGroupMember([member])
      .then(() => {
        this.loadGroupData();
      })
      .catch((error: Error) => {
        console.error('[GroupMemberListPage] Failed to remove member from group:', error);
        Toast.info($r('app.string.chatsetting_member_remove_fail'), this.getUIContext());
      });
  }
}

