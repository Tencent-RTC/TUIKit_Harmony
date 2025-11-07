import {
  Avatar,
  AvatarContentType,
  AvatarSize,
  Switch,
  SwitchType,
  TextUtils,
  ThemeState,
  Toast
} from '../../basecomponent/Index';
import { GroupMember, GroupMemberRole, GroupSettingState, GroupSettingStore, GroupType, LoginStore } from '@tencentcloud/atomicxcore';
import { UserPicker, UserPickerData } from '../../userpicker/Index';
import { ImmersiveMode, LevelMode } from '@ohos.promptAction';


@CustomDialog
struct UserPickerDialogInManagement {
  controller: CustomDialogController;
  title: string | Resource = $r('app.string.chatsetting_select_user');
  dataSource: UserPickerData<GroupMember>[] = [];
  preSelectedUsers: string[] = [];
  maxSelectCount: number = -1;
  confirmButtonText: string | Resource = $r('app.string.chatsetting_complete');
  action: string = '';
  onConfirm?: (selectedMembers: GroupMember[], action: string) => void;

  build() {
    UserPicker({
      dataSource: this.dataSource,
      defaultSelectedItems: this.preSelectedUsers,
      lockedItems: [], // No locked items for now
      maxCount: this.maxSelectCount > 0 ? this.maxSelectCount : undefined,
      showNavigationBar: true,
      title: this.title,
      confirmButtonText: this.confirmButtonText,
      onCancel: () => {
        this.controller.close();
      },
      onSelectedChanged: (selectedItems: UserPickerData<GroupMember>[]) => {
        if (this.onConfirm) {
          const selectedMembers = selectedItems.map(item => item.extraData);
          this.onConfirm(selectedMembers, this.action);
        }
        this.controller.close();
      }
    })
  }
}

@Component
export struct GroupManagementView {
  private static readonly CELL_HEIGHT: number = 56;
  private static readonly SECTION_MARGIN: number = 12;
  private static readonly HORIZONTAL_PADDING: number = 16;
  private static readonly BORDER_RADIUS: number = 12;
  @Provide themeState: ThemeState = ThemeState.getInstance();
  @State groupStore?: GroupSettingStore = undefined;
  @State groupState?: GroupSettingState = this.groupStore?.state;
  @State isLoading: boolean = true;
  groupID: string = '';
  onBack?: () => void;
  dialogController?: CustomDialogController;
  onDialogClose?: () => void;
  private userPickerDialogController?: CustomDialogController;

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
  }

  build() {
    Column() {
      this.NavigationBarBuilder()

      if (this.isLoading) {
        this.LoadingStateBuilder()
      } else {
        Scroll() {
          Column({ space: 0 }) {
            this.GroupManagementSectionBuilder()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
        }
        .backgroundColor(this.themeState.colors.bgColorInput)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorInput)
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
      Text($r('app.string.chatsetting_group_management_title'))
        .fontSize(18)
        .fontWeight(600)
        .fontFamily('SF Pro Display')
        .fontColor(this.themeState.colors.textColorPrimary)

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

      Text($r('app.string.chatsetting_loading_group_management'))
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
  GroupManagementSectionBuilder() {
    Column({ space: 0 }) {

      this.MuteAllMembersRowBuilder()

      this.DividerBuilder()


      this.AddMutedMemberRowBuilder()
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(GroupManagementView.BORDER_RADIUS)
    .margin({
      bottom: GroupManagementView.SECTION_MARGIN
    })


    this.MutedMembersListBuilder()
  }

  @Builder
  MuteAllMembersRowBuilder() {
    Row() {
      Column({ space: 4 }) {
        Text($r('app.string.chatsetting_mute_all_members'))
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)
          .alignSelf(ItemAlign.Start)

        Text($r('app.string.chatsetting_mute_all_members_description'))
          .fontSize(13)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorSecondary)
          .alignSelf(ItemAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank()

      Switch({
        checked: this.groupState?.isAllMuted ?? false,
        type: SwitchType.Basic,
        onCheckedChange: (isOn: boolean) => {
          this.handleMuteAllMembersChange(isOn);
        }
      })
    }
    .width('100%')
    .height(GroupManagementView.CELL_HEIGHT + 16)
    .padding({
      left: GroupManagementView.HORIZONTAL_PADDING,
      right: GroupManagementView.HORIZONTAL_PADDING,
      top: 8,
      bottom: 8
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  AddMutedMemberRowBuilder() {
    Row() {
      Column({ space: 4 }) {
        Text($r('app.string.chatsetting_add_muted_members'))
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)
          .alignSelf(ItemAlign.Start)

        Text($r('app.string.chatsetting_add_muted_members_description'))
          .fontSize(13)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorSecondary)
          .alignSelf(ItemAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank()

      Image($rawfile('search/right_arrow_icon.svg'))
        .width(12)
        .height(24)
        .fillColor(this.themeState.colors.textColorSecondary)
    }
    .width('100%')
    .height(GroupManagementView.CELL_HEIGHT + 16)
    .padding({
      left: GroupManagementView.HORIZONTAL_PADDING,
      right: GroupManagementView.HORIZONTAL_PADDING,
      top: 8,
      bottom: 8
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.navigateToMutedMemberList();
    })
  }

  @Builder
  DividerBuilder() {
    Divider()
      .height(1)
      .color(this.themeState.colors.strokeColorSecondary)
      .margin({ left: GroupManagementView.HORIZONTAL_PADDING })
  }

  @Builder
  MutedMembersListBuilder() {
    if (this.getMutedMembers().length > 0) {
      Column({ space: 0 }) {

        Row() {
          Text($r('app.string.chatsetting_mute_title',this.getMutedMembers().length.toString()))
            .fontSize(15)
            .fontWeight(600)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorPrimary)

          Blank()
        }
        .width('100%')
        .height(44)
        .padding({
          left: GroupManagementView.HORIZONTAL_PADDING,
          right: GroupManagementView.HORIZONTAL_PADDING
        })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.themeState.colors.bgColorTopBar)


        List({ space: 0 }) {
          ForEach(this.getMutedMembers(), (member: GroupMember, index: number) => {
            ListItem() {
              this.MutedMemberRowBuilder(member, index === this.getMutedMembers().length - 1)
            }
            .swipeAction({
              end: this.UnmuteActionBuilder(member)
            })
          })
        }
        .backgroundColor(this.themeState.colors.bgColorTopBar)
        .divider({
          strokeWidth: 0
        })
      }
      .backgroundColor(this.themeState.colors.bgColorTopBar)
      .borderRadius(GroupManagementView.BORDER_RADIUS)
      .margin({
        bottom: GroupManagementView.SECTION_MARGIN
      })
    }
  }

  @Builder
  MutedMemberRowBuilder(member: GroupMember, isLast: boolean) {
    Column() {
      Row({ space: 12 }) {
        // Avatar
        Avatar({
          content: {
            type: AvatarContentType.Image,
            url: member.avatarURL,
            name: TextUtils.getAvatarLetter(member.nameCard || member.nickname || member.userID) || '',
          },
          avatarSize: AvatarSize.M,
        })
        // User info
        Column({ space: 2 }) {
          Text(member.nameCard || member.nickname || member.userID)
            .fontSize(17)
            .fontWeight(400)
            .maxLines(1)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorPrimary)
            .alignSelf(ItemAlign.Start)

          Text(this.getMuteTimeText(member.muteUntil))
            .fontSize(13)
            .fontWeight(400)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorSecondary)
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Blank()
      }
      .width('100%')
      .height(GroupManagementView.CELL_HEIGHT)
      .padding({
        left: GroupManagementView.HORIZONTAL_PADDING,
        right: GroupManagementView.HORIZONTAL_PADDING
      })
      .alignItems(VerticalAlign.Center)


      if (!isLast) {
        Divider()
          .height(1)
          .color(this.themeState.colors.strokeColorSecondary)
          .margin({ left: GroupManagementView.HORIZONTAL_PADDING + 52 })
      }
    }
  }

  @Builder
  UnmuteActionBuilder(member: GroupMember) {
    Button() {
      Column() {

        Text($r('app.string.chatsetting_unmute'))
          .fontSize(12)
          .fontColor(Color.White)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .type(ButtonType.Normal)
    .backgroundColor(this.themeState.colors.textColorLink)
    .width(80)
    .height(GroupManagementView.CELL_HEIGHT)
    .onClick(() => {
      this.showUnmuteConfirmDialog(member);
    })
  }

  private closeDialog(): void {
    if (this.dialogController) {

      this.dialogController.close();
      if (this.onDialogClose) {
        this.onDialogClose();
      }
    } else if (this.onBack) {

      this.onBack();
    } else {

    }
  }

  private getMutedMembers(): GroupMember[] {
    return (this.groupState?.allMembers ?? []).filter(member =>
    member.muteUntil > Date.now() / 1000
    ) ?? [];
  }

  private handleMuteAllMembersChange(isOn: boolean): void {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }


    const loadingMessage = isOn ? $r('app.string.chatsetting_muting_all_members_start') :
    $r('app.string.chatsetting_unmuting_all_members_start');
    Toast.info(loadingMessage, this.getUIContext());


    this.groupStore.setMuteAllMembers(isOn)
      .then(() => {
        const successMessage = isOn ? $r('app.string.chatsetting_mute_all_members_success') :
        $r('app.string.chatsetting_unmute_all_members_success');
        Toast.info(successMessage, this.getUIContext());
        console.log(`[GroupManagementPage] Mute all members ${isOn ? 'enabled' : 'disabled'} successfully`);
      })
      .catch((error: Error) => {
        const errorMessage = isOn ? $r('app.string.chatsetting_enable_mute_all_members_fail') :
        $r('app.string.chatsetting_disable_mute_all_members_fail');
        Toast.info(errorMessage, this.getUIContext());
        console.error(`[GroupManagementPage] Failed to ${isOn ? 'enable' : 'disable'} mute all members:`, error);
      });
  }

  public convertMemberToUserPickerData(member: GroupMember): UserPickerData<GroupMember> {
    return {
      key: member.userID,
      label: member.nameCard || member.nickname || member.userID,
      avatarUrl: member.avatarURL,
      extraData: member
    };
  }
  private navigateToMutedMemberList(): void {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }

    if (this.groupState?.groupType == GroupType.WORK) {
      Toast.info($r('app.string.chatsetting_work_group_mute_members_unsupported'), this.getUIContext());
      return;
    }
    try {
      console.log('[GroupManagementPage] Navigate to user picker for muted members');


      const mutedMemberIds = (this.groupState?.allMembers ?? [])
        .filter(member => member.muteUntil > Date.now() / 1000)
        .map(member => member.userID);


      const currentUserRole = this.groupState?.currentUserRole;
      console.log(`[GroupManagementPage] Current user role: ${currentUserRole}, total members: ${(this.groupState?.allMembers ??
        []).length}`);

      const filteredMembers = (this.groupState?.allMembers ?? []).filter(member => {

        if (member.userID === LoginStore.shared().state.loginUserInfo?.userID) {
          return false;
        }


        if (currentUserRole === 300) { // GroupMemberRole.ADMIN
          return member.role === 200;
        }


        if (currentUserRole === 400) { // GroupMemberRole.OWNER
          return member.role === 300 || member.role === 200;
        }


        return false;
      });

      console.log(`[GroupManagementPage] Filtered ${filteredMembers.length} members available for muting`);

      const userPickerData: UserPickerData<GroupMember>[] = filteredMembers.map(member =>
      this.convertMemberToUserPickerData(member)
      );


      if (userPickerData.length === 0) {
        Toast.info($r('app.string.chatsetting_no_members_to_mute'), this.getUIContext());
        console.log('[GroupManagementPage] No members available to mute');
        return;
      }


      this.showUserPickerDialog(
        userPickerData,
        'muteMember',
        $r('app.string.chatsetting_select_members_to_mute')
      );

    } catch (error) {
      console.error('[GroupManagementPage] Error navigating to user picker:', error);
      Toast.info($r('app.string.chatsetting_open_member_picker_fail'), this.getUIContext());
    }
  }

  private handleSelectedMembersForMute(selectedMembers: GroupMember[]): void {
    if (!this.groupStore || selectedMembers.length === 0) {
      return;
    }

    console.log('[GroupManagementPage] Handle selected members for mute:', selectedMembers.map(m => m.nameCard || m.nickname || m.userID));


    AlertDialog.show({
      title: $r('app.string.chatsetting_mute_confirm'),
      message: $r('app.string.chatsetting_mute_confirm_message',selectedMembers.length.toString()),
      primaryButton: {
        value: $r('app.string.chatsetting_confirm'),
        action: () => {
          this.muteSelectedMembers(selectedMembers);
        }
      },
      secondaryButton: {
        value: $r('app.string.chatsetting_cancel'),
        action: () => {
          console.log('[GroupManagementPage] User cancelled mute operation');
        }
      }
    });
  }

  private async muteSelectedMembers(selectedMembers: GroupMember[]): Promise<void> {
    if (!this.groupStore) {
      return;
    }

    Toast.info($r('app.string.chatsetting_muting_members'), this.getUIContext());

    try {

      const muteTime = 24 * 60 * 60;
      const mutePromises = selectedMembers.map(member =>
      this.groupStore!.setGroupMemberMuteTime(member.userID, muteTime)
      );

      await Promise.all(mutePromises);

      Toast.info(($r('app.string.chatsetting_mute_success',selectedMembers.length.toString())), this.getUIContext());
      console.log('[GroupManagementPage] Successfully muted selected users');

      await this.loadGroupData();

    } catch (error) {
      console.error('[GroupManagementPage] Failed to mute selected users:', error);
      Toast.info($r('app.string.chatsetting_mute_fail'), this.getUIContext());
    }
  }

  private getMuteTimeText(muteUntil: number): string | Resource {
    if (muteUntil <= 0) {
      return '';
    }

    const now = Date.now() / 1000;
    const remainingSeconds = muteUntil - now;

    if (remainingSeconds <= 0) {
      return $r('app.string.chatsetting_mute_time_text_unmuted');
    }

    const days = Math.floor(remainingSeconds / (24 * 60 * 60));
    const hours = Math.floor((remainingSeconds % (24 * 60 * 60)) / (60 * 60));
    const minutes = Math.floor((remainingSeconds % (60 * 60)) / 60);

    if (days > 0) {
      return $r('app.string.chatsetting_mute_time_text_remaining',days.toString(),hours.toString())
    } else if (hours > 0) {
      return $r('app.string.chatsetting_mute_time_text_remaining2',hours.toString(),minutes.toString())
    } else {
      return $r('app.string.chatsetting_mute_time_text_remaining3',minutes.toString())
    }
  }

  private showUnmuteConfirmDialog(member: GroupMember): void {
    AlertDialog.show({
      title: $r('app.string.chatsetting_unmute_confirm'),
      message: $r('app.string.chatsetting_unmute_confirm_message', member.nameCard || member.nickname || member.userID),
      primaryButton: {
        value: $r('app.string.chatsetting_confirm'),
        action: () => {
          this.unmuteMember(member);
        }
      },
      secondaryButton: {
        value: $r('app.string.chatsetting_cancel'),
        action: () => {
          console.log('[GroupManagementPage] User cancelled unmute operation');
        }
      }
    });
  }

  private async unmuteMember(member: GroupMember): Promise<void> {
    if (!this.groupStore) {
      return;
    }

    Toast.info($r('app.string.chatsetting_unmuting_member'), this.getUIContext());

    try {
      await this.groupStore.setGroupMemberMuteTime(member.userID, 0);

      Toast.info($r('app.string.chatsetting_unmute_success',member.nameCard || member.nickname || member.userID), this.getUIContext());
      console.log(`[GroupManagementPage] Successfully unmuted member: ${member.userID}`);
      await this.loadGroupData();

    } catch (error) {
      console.error('[GroupManagementPage] Failed to unmute member:', error);
      Toast.info($r('app.string.chatsetting_unmute_fail'), this.getUIContext());
    }
  }

  private async loadGroupData(): Promise<void> {
    if (!this.groupStore) {
      return;
    }

    try {
      await this.groupStore.fetchGroupInfo();
      await this.groupStore.fetchGroupMemberList();
      console.log('[GroupManagementPage] Group info loaded successfully');
    } catch (error) {
      console.error('[GroupManagementPage] Failed to load group info:', error);
      Toast.info($r('app.string.chatsetting_load_group_info_fail'), this.getUIContext());
    } finally {
      this.isLoading = false;
    }
  }

  private showUserPickerDialog(dataSource: UserPickerData<GroupMember>[], action: string, title: string | Resource): void {
    try {
      if (this.userPickerDialogController) {
        this.userPickerDialogController.close();
        this.userPickerDialogController = undefined;
      }

      this.userPickerDialogController = new CustomDialogController({
        builder: UserPickerDialogInManagement({
          title: title,
          dataSource: dataSource,
          preSelectedUsers: action === 'muteMember' ? this.getMutedMemberIds() : [],
          maxSelectCount: -1,
          confirmButtonText: action === 'muteMember' ? $r('app.string.chatsetting_mute') :
          $r('app.string.chatsetting_complete'),
          action: action,
          onConfirm: (selectedMembers: GroupMember[], actionType: string) => {
            this.handleUserPickerResult(selectedMembers, actionType);
          }
        }),
        alignment: DialogAlignment.Default,
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        customStyle: true,
        autoCancel: true,
        cancel: () => {
          this.userPickerDialogController = undefined;
        }
      });

      this.userPickerDialogController.open();
    } catch (error) {

    }
  }

  private handleUserPickerResult(selectedMembers: GroupMember[], action: string): void {
    console.log('[GroupManagementPage] handleUserPickerResult action :', action, 'selectedMembers.length:', selectedMembers.length);

    switch (action) {
      case 'muteMember':
        this.handleSelectedMembersForMute(selectedMembers);
        break;
      default:
        console.warn('[GroupManagementPage] unknown action:', action);
    }
  }

  private getMutedMemberIds(): string[] {
    if (!this.groupState) {
      return [];
    }

    const currentTime = Date.now() / 1000;
    return this.groupState.allMembers
      .filter(member => member.muteUntil && member.muteUntil > currentTime)
      .map(member => member.userID);
  }
}
