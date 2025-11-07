import {
  AlertDialog,
  Avatar,
  AvatarContentType,
  AvatarSize,
  Switch,
  SwitchType,
  ThemeState,
  Toast
} from '../../basecomponent/Index';
import {
  ContactInfo,
  ContactListState,
  ContactListStore,
  ContactOnlineStatus,
  ConversationListStore,
  GroupJoinOption,
  GroupMember,
  GroupMemberRole,
  GroupSettingState,
  GroupSettingStore,
  GroupType,
  LoginStore,
  ErrorInfo
} from '@tencentcloud/atomicxcore';
import { GroupPermission, GroupPermissionManager } from '../manager/GroupPermissionManager';
import { ImmersiveMode, LevelMode, router } from '@kit.ArkUI';
import { AvatarSelector } from './AvatarSelector';
import { GroupNameEditDialog, InviteGroupMethodDialog, JoinGroupMethodDialog } from '../dialog/GroupSettingDialogs';
import { GroupAnnouncementView } from './GroupAnnouncementView';
import { GroupManagementView } from './GroupManagementView';
import { GroupMemberListPage } from './GroupMemberListPage';
import { UserPicker, UserPickerData } from '../../userpicker/Index';
import { C2CChatSetting } from './C2CChatSetting';
import { ContactDetailPage } from '../../contactlist/pages/dialog/ContactDetailPage';
import { UserInteractionHelper } from '../helper/UserInteractionHelper';

type UserPickerDataType = ContactInfo | GroupMember;

function convertContactToUserPickerData(contact: ContactInfo): UserPickerData<ContactInfo> {
  return {
    key: contact.contactID || '',
    label: contact.title || contact.contactID || '',
    avatarUrl: contact.avatarURL || '',
    extraData: contact
  };
}

function convertGroupMemberToUserPickerData(member: GroupMember): UserPickerData<GroupMember> {
  return {
    key: member.userID || '',
    label: member.nameCard || member.nickname || member.userID || '',
    avatarUrl: member.avatarURL || '',
    extraData: member
  };
}

@CustomDialog
export struct GroupSettingDialog {
  controller: CustomDialogController;
  groupID: string = '';
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onGroupDelete?: () => void;

  build() {
    GroupChatSetting({
      groupID: this.groupID,
      onSendMessageClick: (newConversationID?: string, title?: string, avatarUrl?: string) => {
        if (this.onSendMessageClick) {
          this.onSendMessageClick(newConversationID, title, avatarUrl);
        }
      },
      onGroupDelete: () => {
        if (this.onGroupDelete) {
          this.onGroupDelete();
        }
      },
      dialogController: this.controller
    })
  }
}

interface LoadingProgress {
  groupInfo: boolean;
  conversationInfo: boolean;
  groupMembers: boolean;
  selfMemberInfo: boolean;
}

@CustomDialog
struct AvatarPickerDialog {
  controller: CustomDialogController;
  title: string | Resource = $r('app.string.chatsetting_select_avatar');
  urlList: string[] = [];
  onConfirm?: (selectedUrl: string, selectedIndex: number) => void;

  build() {
    AvatarSelector({
      title: this.title,
      urlList: this.urlList,
      onConfirm: this.onConfirm,
      onBack: () => {
        this.controller.close();
      }
    })
  }
}

@CustomDialog
struct GroupAnnouncementDialog {
  controller: CustomDialogController;
  groupID: string = '';
  onSave?: (announcement: string) => void;

  build() {
    GroupAnnouncementView({
      groupID: this.groupID,
      onSave: this.onSave,
      onBack: () => {
        this.controller.close();
      }
    })
  }
}

@CustomDialog
struct GroupMemberListDialog {
  controller: CustomDialogController;
  groupID: string = '';
  groupName: string = '';
  onMemberSelect?: (member: GroupMember) => void;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;

  build() {
    GroupMemberListPage({
      groupID: this.groupID,
      groupName: this.groupName,
      onMemberSelect: this.onMemberSelect,
      onSendMessageClick: this.onSendMessageClick,
      dialogController: this.controller
    })
  }
}

@CustomDialog
struct UserPickerDialog {
  controller: CustomDialogController;
  title: string | Resource = $r('app.string.chatsetting_select_user');
  dataSource: UserPickerData<UserPickerDataType>[] = [];
  preSelectedUsers: string[] = [];
  maxSelectCount: number = -1;
  confirmButtonText: string | Resource = $r('app.string.chatsetting_complete');
  action: string = '';
  onConfirm?: (selectedItems: UserPickerDataType[], action: string) => void;

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
      onSelectedChanged: (selectedItems: UserPickerData<UserPickerDataType>[]) => {
        if (this.onConfirm) {
          const selectedData: UserPickerDataType[] = selectedItems.map((item: UserPickerData<UserPickerDataType>): UserPickerDataType => item.extraData);
          this.onConfirm(selectedData, this.action);
        }
        this.controller.close();
      }
    })
  }
}

@CustomDialog
struct GroupManagementDialog {
  controller: CustomDialogController;
  groupID: string = '';

  build() {
    GroupManagementView({
      groupID: this.groupID,
      onBack: () => {
        this.controller.close();
      }
    })
  }
}


@Component
export struct GroupChatSetting {
  private static readonly AVATAR_SIZE: number = 80;
  private static readonly CELL_HEIGHT: number = 56;
  private static readonly SECTION_MARGIN: number = 12;
  private static readonly HORIZONTAL_PADDING: number = 8;
  private static readonly MEMBER_AVATAR_SIZE: number = 40;
  private static readonly ACTION_BUTTON_SIZE: number = 56;
  private static readonly BORDER_RADIUS: number = 12;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State groupStore?: GroupSettingStore = undefined;
  @State groupState?: GroupSettingState = this.groupStore?.state;
  @State conversationStore?: ConversationListStore = ConversationListStore.create();
  @State conversationID: string = '';
  @State showMemberList: boolean = true;
  @State isLoading: boolean = true;
  @State loadingProgress: LoadingProgress = {
    groupInfo: false,
    conversationInfo: false,
    groupMembers: false,
    selfMemberInfo: false
  };
  @State showJoinGroupDialog: boolean = false;
  @State showInviteGroupDialog: boolean = false;
  groupID: string = '';
  dialogController?: CustomDialogController;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onGroupDelete?: () => void;
  private contactListStore: ContactListStore = ContactListStore.create();
  @State private contactListState: ContactListState = this.contactListStore.state;
  private userInteractionHelper: UserInteractionHelper = new UserInteractionHelper();
  private loadingTimeoutId?: number;
  private joinGroupDialogController?: CustomDialogController;
  private inviteGroupDialogController?: CustomDialogController;
  private groupNameEditDialogController?: CustomDialogController;
  private groupNicknameEditDialogController?: CustomDialogController;
  private avatarPickerDialogController?: CustomDialogController;
  private groupAnnouncementDialogController?: CustomDialogController;
  private groupMemberListDialogController?: CustomDialogController;
  private userPickerDialogController?: CustomDialogController;
  private groupManagementDialogController?: CustomDialogController;

  aboutToAppear(): void {
    console.info('[GroupSettingPage]aboutToAppear Param:', {
      groupID: this.groupID
    });

    if (this.groupID && this.groupID.length > 0) {
      this.conversationID = `group_${this.groupID}`;
      this.groupStore = GroupSettingStore.create(this.groupID);
      this.groupState = this.groupStore.state;
      this.loadGroupData();
    } else {
      this.isLoading = false;
    }
  }

  aboutToDisappear(): void {

    if (this.loadingTimeoutId) {
      clearTimeout(this.loadingTimeoutId);
      this.loadingTimeoutId = undefined;
    }

    // Clean up user interaction dialogs
    UserInteractionHelper.closeDialog();

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
            this.GroupInfoSectionBuilder()
            this.NotificationSettingsSectionBuilder()
            this.SettingsSectionBuilder()
            this.MyGroupNicknameSectionBuilder()
            if (this.showMemberList && this.hasPermission(GroupPermission.GET_GROUP_MEMBER_LIST)) {
              this.MemberListSectionBuilder()
            }
            this.ActionButtonsSectionBuilder()
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  StatusBarBuilder() {

    Blank().height(0)
  }

  @Builder
  LoadingStateBuilder() {
    Column({ space: 16 }) {

      LoadingProgress()
        .width(40)
        .height(40)
        .color('#0365F9')


      Text($r('app.string.chatsetting_loading_group_information'))
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorSecondary)


      Column({ space: 8 }) {
        this.LoadingItemBuilder($r('app.string.chatsetting_group_info'),
          this.loadingProgress.groupInfo)
        this.LoadingItemBuilder($r('app.string.chatsetting_conversation_settings'),
          this.loadingProgress.conversationInfo)
        this.LoadingItemBuilder($r('app.string.chatsetting_group_members'),
          this.loadingProgress.groupMembers)
        this.LoadingItemBuilder($r('app.string.chatsetting_member_settings'),
          this.loadingProgress.selfMemberInfo)
      }
      .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F2F2F7')
  }

  @Builder
  LoadingItemBuilder(label: Resource, isCompleted: boolean) {
    Row({ space: 8 }) {

      if (isCompleted) {
        Image($r('sys.symbol.checkmark_circle_fill'))
          .width(16)
          .height(16)
          .fillColor('#34C759')
      } else {
        LoadingProgress()
          .width(16)
          .height(16)
          .color('#0365F9')
      }


      Text(label)
        .fontSize(14)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(isCompleted ? '#34C759' : this.themeState.colors.textColorSecondary)
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ left: 40, right: 40 })
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
          if (this.dialogController) {
            this.dialogController.close();
          } else {
            console.warn('[GroupSettingPage] dialogController not available');
          }
        })

      Blank()

      // Title
      Text($r('app.string.chatsetting_group_info'))
        .fontSize(18)
        .fontWeight(600)
        .fontFamily('SF Pro Display')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)

    // Divider
    Divider()
      .height(0.5)
      .color(this.themeState.colors.strokeColorSecondary)
  }

  @Builder
  GroupInfoSectionBuilder() {
    Column() {

      Stack() {
        Avatar({
          content: {
            type: AvatarContentType.Image,
            url: this.groupState?.avatarUrl,
            name: this.getGroupInitials() || '',
          },
          avatarSize: AvatarSize.XXL,
        })

        if (this.hasPermission(GroupPermission.SET_GROUP_AVATAR)) {
          Stack() {
            Circle()
              .width(24)
              .height(24)
              .fill('rgba(0, 0, 0, 0.6)')

            Image($rawfile('chatsetting/setting_edit_icon.svg'))
              .width(12)
              .height(12)
              .fillColor(this.themeState.colors.textColorLink)
          }
          .position({ x: GroupChatSetting.AVATAR_SIZE - 24, y: GroupChatSetting.AVATAR_SIZE - 24 })
        }
      }
      .onClick(() => {
        if (this.hasPermission(GroupPermission.SET_GROUP_AVATAR)) {
          this.navigateToAvatarPicker();
        }
      })
      .width(GroupChatSetting.AVATAR_SIZE)
      .height(GroupChatSetting.AVATAR_SIZE)
      .margin({ top: 24, bottom: 16 })


      Row() {
        Text((this.groupState?.groupName || ''))
          .fontSize(24)
          .fontWeight(600)
          .fontFamily('PingFang HK')
          .fontColor(this.themeState.colors.textColorPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.hasPermission(GroupPermission.SET_GROUP_NAME)) {
          Image($rawfile('chatsetting/setting_edit_icon.svg'))
            .width(15)
            .height(15)
            .margin({ left: 12 })
            .fillColor(this.themeState.colors.textColorLink)
            .onClick(() => {
              this.openGroupNameEditDialog();
            })
        }
      }
      .margin({ bottom: 16 })


      Text(`ID: ${this.groupStore?.groupID}`)
        .fontSize(15)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorSecondary)
        .margin({ bottom: 16 })

      Row({ space: 24 }) {
        this.QuickActionButtonBuilder($r('app.string.chatsetting_message'),
          $rawfile('chatsetting/setting_sendmessage_icon.svg'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 24 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius(GroupChatSetting.BORDER_RADIUS)
    .padding({
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      top: GroupChatSetting.SECTION_MARGIN,
      bottom: GroupChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  QuickActionButtonBuilder(label: string | Resource, icon: string | Resource) {
    Column({ space: 8 }) {

      Image(icon)
        .width(36)
        .height(36)
        .fillColor(this.themeState.colors.textColorLink)
        .borderRadius(12)


      Text(label)
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('PingFang SC')
        .fontColor(this.themeState.colors.textColorPrimary)
        .textAlign(TextAlign.Center)
    }
    .width(92)
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(12)
    .padding({ top: 16, bottom: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.handleQuickActionClick(label);
    })
  }

  @Builder
  NotificationSettingsSectionBuilder() {
    Column({ space: 0 }) {

      if (this.hasPermission(GroupPermission.SET_DO_NOT_DISTURB)) {
        this.MuteNotificationRowBuilder()
        this.DividerBuilder()
      }


      if (this.hasPermission(GroupPermission.PIN_GROUP)) {
        this.PinConversationRowBuilder()
      }
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(GroupChatSetting.BORDER_RADIUS)
    .padding({
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: GroupChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  MuteNotificationRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_mute_notifications'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Switch({
        checked: this.groupState?.isNotDisturb ?? false,
        type: SwitchType.Basic,
        onCheckedChange: (isOn: boolean) => {
          if (this.conversationID) {
            this.conversationStore?.muteConversation(this.conversationID, isOn).then(() => {
            }).catch((error: Error) => {
            });
          }
        }
      })
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
  }

  @Builder
  PinConversationRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_pin_conversation'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Switch({
        checked: this.groupState?.isPinned ?? false,
        type: SwitchType.Basic,
        onCheckedChange: (isOn: boolean) => {
          if (this.conversationID) {
            this.conversationStore?.pinConversation(this.conversationID, isOn).then(() => {

            }).catch((error: Error) => {

            });
          }
        }
      })
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
  }

  @Builder
  GroupNoticeRowBuilder() {
    Column({ space: 8 }) {

      Row() {
        Text($r('app.string.chatsetting_group_announcement'))
          .fontSize(16)
          .fontWeight(400)
          .fontFamily('PingFang SC')
          .fontColor(this.themeState.colors.textColorPrimary)

        Blank()

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)

      }
      .width('100%')
      .alignItems(VerticalAlign.Center)


      Row() {
        Text(this.groupState?.notice)
          .fontSize(14)
          .fontWeight(400)
          .fontFamily('PingFang SC')
          .fontColor(this.themeState.colors.textColorSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 8,
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .onClick(() => {
      this.navigateToGroupAnnouncement();
    })
  }

  @Builder
  SettingsSectionBuilder() {
    Column({ space: 0 }) {

      if (this.hasPermission(GroupPermission.SET_GROUP_NOTICE)) {
        this.GroupNoticeRowBuilder()
        this.DividerBuilder()
      }


      if (this.hasPermission(GroupPermission.SET_GROUP_MANAGEMENT)) {
        this.GroupManagementRowBuilder()
        this.DividerBuilder()
      }


      if (this.hasPermission(GroupPermission.GET_GROUP_TYPE)) {
        this.GroupTypeRowBuilder()
        this.DividerBuilder()
      }


      if (this.hasPermission(GroupPermission.SET_JOIN_GROUP_APPROVAL_TYPE)) {
        this.JoinMethodRowBuilder()
        this.DividerBuilder()
      }


      if (this.hasPermission(GroupPermission.SET_INVITE_TO_GROUP_APPROVAL_TYPE)) {
        this.InviteMethodRowBuilder()
      }
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(GroupChatSetting.BORDER_RADIUS)
    .padding({
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: GroupChatSetting.SECTION_MARGIN
    })

  }

  @Builder
  GroupManagementRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_group_management'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Row({ space: 8 }) {
        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      this.navigateToGroupManagement();
    })
  }

  @Builder
  GroupTypeRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_group_type'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Row({ space: 8 }) {
        Text(this.getGroupTypeDisplayName())
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      console.log('Group Type clicked');
    })
  }

  @Builder
  JoinMethodRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_join_group_method'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Row({ space: 8 }) {
        Text(this.getJoinMethodDisplayName())
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      this.joinGroupDialogController = new CustomDialogController({
        builder: JoinGroupMethodDialog({
          currentOpt: this.groupState?.joinGroupApprovalType,
          onSelect: (opt: GroupJoinOption) => {
            this.groupStore?.setGroupJoinOption(opt);
          },
          onCancel: () => {
            // Dialog will close automatically
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true,
        maskColor: 'rgba(0, 0, 0, 0.6)',
        autoCancel: true
      });
      this.joinGroupDialogController.open();
    })
  }

  @Builder
  InviteMethodRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_invite_method'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Row({ space: 8 }) {
        Text(this.getInviteMethodDisplayName())
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      this.inviteGroupDialogController = new CustomDialogController({
        builder: InviteGroupMethodDialog({
          currentOpt: this.groupState?.inviteToGroupApprovalType,
          onSelect: (opt: GroupJoinOption) => {
            console.log('Set invite method:', opt);
            this.groupStore?.setGroupInviteOption(opt);
          },
          onCancel: () => {
            // Dialog will close automatically
          }
        }),
        alignment: DialogAlignment.Bottom,
        customStyle: true,
        maskColor: 'rgba(0, 0, 0, 0.6)',
        autoCancel: true
      });
      this.inviteGroupDialogController.open();
    })
  }

  @Builder
  DividerBuilder() {
    Divider()
      .height(0.4)
      .color(this.themeState.colors.strokeColorSecondary)
  }

  @Builder
  MyGroupNicknameSectionBuilder() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.chatsetting_mygroup_nickname'))
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)

        Blank()

        Row({ space: 8 }) {
          Text(this.getCurrentUserNickname())
            .fontSize(17)
            .fontWeight(400)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Image($rawfile('search/right_arrow_icon.svg'))
            .width(12)
            .height(24)
            .fillColor(this.themeState.colors.textColorSecondary)
        }
      }
      .width('100%')
      .height(GroupChatSetting.CELL_HEIGHT)
      .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
      .onClick(() => {
        this.openGroupNicknameEditDialog();
      })
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(GroupChatSetting.BORDER_RADIUS)
    .padding({
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: GroupChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  ChatBackgroundSectionBuilder() {
    if (this.hasPermission(GroupPermission.SET_BACKGROUND)) {
      Column({ space: 0 }) {
        Row() {
          Text($r('app.string.chatsetting_chat_background'))
            .fontSize(17)
            .fontWeight(400)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorPrimary)

          Blank()

          Row({ space: 8 }) {
            Text($r('app.string.chatsetting_default'))
              .fontSize(17)
              .fontWeight(400)
              .fontFamily('SF Pro Text')
              .fontColor(this.themeState.colors.textColorPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Image($rawfile('search/right_arrow_icon.svg'))
              .width(12)
              .height(24)
              .fillColor(this.themeState.colors.textColorSecondary)
          }
        }
        .width('100%')
        .height(GroupChatSetting.CELL_HEIGHT)
        .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
        .onClick(() => {
          console.log('Chat Background clicked');

        })
      }
      .backgroundColor(this.themeState.colors.bgColorTopBar)
      .borderRadius(GroupChatSetting.BORDER_RADIUS)
      .padding({
        left: GroupChatSetting.HORIZONTAL_PADDING,
        right: GroupChatSetting.HORIZONTAL_PADDING
      })
      .margin({
        bottom: GroupChatSetting.SECTION_MARGIN
      })
    }
  }

  @Builder
  MemberListSectionBuilder() {
    Column({ space: 0 }) {

      Row() {
        Text($r('app.string.chatsetting_members'))
          .fontSize(17)
          .fontWeight(600)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)

        Blank()

        Text(`${this.groupState?.memberCount ?? 0} 人`)
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorPrimary)

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)

      }
      .width('100%')
      .height(GroupChatSetting.CELL_HEIGHT)
      .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
      .onClick(() => {
        this.navigateToGroupMemberList();
      })

      this.DividerBuilder()


      if (this.hasPermission(GroupPermission.ADD_GROUP_MEMBER) && 
          this.groupState?.inviteToGroupApprovalType !== GroupJoinOption.FORBID) {
        this.AddMemberButtonBuilder()
        this.DividerBuilder()
      }


      ForEach(this.getDisplayMembers(), (member: GroupMember, index: number) => {
        this.MemberRowBuilder(member)
        if (index < this.getDisplayMembers().length - 1) {
          this.DividerBuilder()
        }
      })
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(GroupChatSetting.BORDER_RADIUS)
    .padding({
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: GroupChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  AddMemberButtonBuilder() {
    Row() {
      Stack() {
        Circle()
          .width(GroupChatSetting.MEMBER_AVATAR_SIZE)
          .height(GroupChatSetting.MEMBER_AVATAR_SIZE)
          .fill('rgba(3, 101, 249, 0.1)')

        Text('+')
          .fontSize(20)
          .fontColor(this.themeState.colors.textColorLink)
          .fontWeight(300)
      }
      .width(GroupChatSetting.MEMBER_AVATAR_SIZE)
      .height(GroupChatSetting.MEMBER_AVATAR_SIZE)

      Text($r('app.string.chatsetting_add_member'))
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('PingFang SC')
        .fontColor(this.themeState.colors.textColorLink)
        .margin({ left: 12 })

      Blank()
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      this.navigateToAddMember();
    })
  }

  @Builder
  MemberRowBuilder(member: GroupMember) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: member.avatarURL,
          name: member.nickname || '',
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


          if (member.role === GroupMemberRole.OWNER) {
            Text($r('app.string.chatsetting_owner_role'))
              .fontSize(13)
              .fontWeight(500)
              .fontFamily('SF Pro Text')
              .fontColor('#FF9500')
              .margin({ left: 8 })
              .padding({
                left: 6,
                right: 6,
                top: 2,
                bottom: 2
              })
              .backgroundColor('rgba(255, 149, 0, 0.1)')
              .borderRadius(4)
          } else if (member.role === GroupMemberRole.ADMIN) {
            Text($r('app.string.chatsetting_admin_role'))
              .fontSize(13)
              .fontWeight(500)
              .fontFamily('SF Pro Text')
              .fontColor('#0365F9')
              .margin({ left: 8 })
              .padding({
                left: 6,
                right: 6,
                top: 2,
                bottom: 2
              })
              .backgroundColor('rgba(0, 122, 255, 0.1)')
              .borderRadius(4)
          }
        }

        if (member.userID !== (member.nameCard || member.nickname) && member.userID) {
          Text(`@${member.userID.toString()}`)
            .fontSize(15)
            .fontWeight(400)
            .fontFamily('SF Pro Text')
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)


      Image($rawfile('search/right_arrow_icon.svg'))
        .width(12)
        .height(24)
        .fillColor(this.themeState.colors.textColorSecondary)

    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .padding({ left: GroupChatSetting.HORIZONTAL_PADDING, right: GroupChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      if (this.hasPermission(GroupPermission.GET_GROUP_MEMBER_INFO)) {
        console.log(`View member info: ${member.userID}`);
        this.showMemberOptions(member);
      }
    })
  }

  @Builder
  ActionButtonsSectionBuilder() {
    Column({ space: 0 }) {

      if (this.hasPermission(GroupPermission.CLEAR_HISTORY_MESSAGES)) {
        this.ActionButtonBuilder($r('app.string.chatsetting_clear_chat_history'),
          this.themeState.colors.textColorError, () => {
            this.showClearHistoryConfirmDialog();
          })

        if (this.hasPermission(GroupPermission.TRANSFER_OWNER) ||
        this.hasPermission(GroupPermission.DISMISS_GROUP) ||
        this.hasPermission(GroupPermission.DELETE_AND_QUIT) ||
        this.hasPermission(GroupPermission.REPORT_GROUP)) {
          this.DividerBuilder()
        }
      }


      if (this.hasPermission(GroupPermission.TRANSFER_OWNER)) {
        this.ActionButtonBuilder($r('app.string.chatsetting_transfer_ownership'),
          this.themeState.colors.textColorWarning, () => {
            this.navigateToTransferOwnership();
          })

        if (this.hasPermission(GroupPermission.DISMISS_GROUP) ||
        this.hasPermission(GroupPermission.DELETE_AND_QUIT) ||
        this.hasPermission(GroupPermission.REPORT_GROUP)) {
          this.DividerBuilder()
        }
      }


      if (this.hasPermission(GroupPermission.DISMISS_GROUP)) {
        this.ActionButtonBuilder($r('app.string.chatsetting_dismiss_group'),
          this.themeState.colors.textColorError, () => {
            this.showDismissGroupConfirmDialog();
          })

        if (this.hasPermission(GroupPermission.DELETE_AND_QUIT) ||
        this.hasPermission(GroupPermission.REPORT_GROUP)) {
          this.DividerBuilder()
        }
      }


      if (this.hasPermission(GroupPermission.DELETE_AND_QUIT)) {
        this.ActionButtonBuilder($r('app.string.chatsetting_leave_group'),
          this.themeState.colors.textColorError, () => {
            this.showLeaveGroupConfirmDialog();
          })

        if (this.hasPermission(GroupPermission.REPORT_GROUP)) {
          this.DividerBuilder()
        }
      }


      if (this.hasPermission(GroupPermission.REPORT_GROUP)) {
        this.ActionButtonBuilder($r('app.string.chatsetting_report_group'),
          this.themeState.colors.textColorWarning, () => {
            Toast.info($r('app.string.chatsetting_report_group_toast'), this.getUIContext());
          })
      }
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(GroupChatSetting.BORDER_RADIUS)
    .padding({
      left: GroupChatSetting.HORIZONTAL_PADDING,
      right: GroupChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: GroupChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  ActionButtonBuilder(title: string | Resource, textColor: string, action: () => void) {
    Row() {
      Text(title)
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(textColor)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(GroupChatSetting.CELL_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .onClick(action)
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

    console.info('[GroupSettingPage] Starting to load group data...');

    try {

      const promises = [
        this.loadGroupInfo(),
        this.loadConversationInfo(),
        this.loadGroupMembers(),
        this.loadSelfMemberInfo()
      ];

      await Promise.all(promises);
      console.info('[GroupSettingPage] All data loaded successfully');
    } catch (error) {
      console.error('[GroupSettingPage] Error loading group data:', error);
    } finally {
      this.isLoading = false;

      if (this.loadingTimeoutId) {
        clearTimeout(this.loadingTimeoutId);
        this.loadingTimeoutId = undefined;
      }
    }


    this.loadingTimeoutId = setTimeout(() => {
      if (this.isLoading) {
        console.warn('[GroupSettingPage] Loading timeout, forcing completion');
        this.isLoading = false;
      }
    }, 10000);
  }

  private async loadGroupInfo(): Promise<void> {
    try {
      await this.groupStore?.fetchGroupInfo();
      this.loadingProgress.groupInfo = true;
      console.info('[GroupSettingPage] Group info loaded');
    } catch (error) {
      console.error('[GroupSettingPage] Failed to load group info:', error);
      this.loadingProgress.groupInfo = true;
    }
  }

  private async loadConversationInfo(): Promise<void> {
    try {
      await this.conversationStore?.fetchConversationInfo(this.conversationID);
      this.loadingProgress.conversationInfo = true;
      console.info('[GroupSettingPage] Conversation info loaded');
    } catch (error) {
      console.error('[GroupSettingPage] Failed to load conversation info:', error);
      this.loadingProgress.conversationInfo = true;
    }
  }

  private async loadGroupMembers(): Promise<void> {
    try {
      await this.groupStore?.fetchGroupMemberList();
      this.loadingProgress.groupMembers = true;
      console.info('[GroupSettingPage] Group members loaded');
    } catch (error) {
      console.error('[GroupSettingPage] Failed to load group members:', error);
      this.loadingProgress.groupMembers = true;
    }
  }

  private async loadSelfMemberInfo(): Promise<void> {
    try {
      await this.groupStore?.fetchSelfMemberInfo();
      this.loadingProgress.selfMemberInfo = true;
      console.info('[GroupSettingPage] Self member info loaded');
    } catch (error) {
      console.error('[GroupSettingPage] Failed to load self member info:', error);
      this.loadingProgress.selfMemberInfo = true;
    }
  }

  private hasPermission(permission: GroupPermission): boolean {
    const userRole = this.groupState?.currentUserRole;
    if (!userRole) {
      return false;
    }


    const groupType = this.convertStringToGroupType(this.groupState?.groupType);

    return GroupPermissionManager.hasPermission(
      groupType,
      userRole,
      permission
    );
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

  private showMemberOptions(member: GroupMember): void {
    console.log(`[GroupSettingPage] Show options for member: ${member.userID}`);
    
    if (!member.userID) {
      console.error(`[GroupSettingPage] Member userID is empty`);
      return;
    }

    // Use UserInteractionHelper to show user profile based on friendship
    this.userInteractionHelper.showUserProfileByFriendship(
      member.userID,
      this.getUIContext(),
      this.onSendMessageClick
    );
  }


  private getGroupInitials(): string {
    const groupName = this.groupState?.groupName || 'Group';
    const words = groupName.split(' ');
    if (words.length >= 2) {
      return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
    }
    return groupName.charAt(0).toUpperCase();
  }

  private getMemberInitials(member: GroupMember): string {
    const name = member.nameCard || member.nickname || member.userID;
    const words = name.split(' ');
    if (words.length >= 2) {
      return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
    }
    return name.charAt(0).toUpperCase();
  }

  private getDisplayMembers(): GroupMember[] {
    const allMembers = this.groupState?.allMembers ?? [];
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;

    if (allMembers.length === 0) {
      return [];
    }


    const currentUser = allMembers.find(member => member.userID === currentUserID);


    const otherMembers = allMembers.filter(member => member.userID !== currentUserID);


    const displayMembers: GroupMember[] = [];


    if (currentUser) {
      displayMembers.push(currentUser);
    }


    const maxOtherMembers = 2;
    const otherMembersToShow = otherMembers.slice(0, maxOtherMembers);
    displayMembers.push(...otherMembersToShow);

    return displayMembers;
  }

  private getCurrentUserNickname(): string {

    if (this.groupState?.selfNameCard && this.groupState.selfNameCard.length > 0) {
      return this.groupState.selfNameCard;
    }


    const allMembers = this.groupState?.allMembers ?? [];
    const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;


    const currentUser = allMembers.find(member => member.userID === currentUserID);

    if (currentUser) {

      return currentUser.nameCard || currentUser.nickname || currentUser.userID || 'Not set';
    }

    return 'Not set';
  }

  private getGroupTypeDisplayName(): Resource {
    const groupType = this.groupState?.groupType;
    if (!groupType) {
      return $r('app.string.chatsetting_group_type_work_group');
    }
    switch (groupType) {
      case GroupType.WORK:
        return $r('app.string.chatsetting_group_type_work');
      case GroupType.PUBLIC:
        return $r('app.string.chatsetting_group_type_public_group');
      case GroupType.MEETING:
        return $r('app.string.chatsetting_group_type_meeting');
      case GroupType.AVCHATROOM:
        return $r('app.string.chatsetting_group_type_chat_room');
      case GroupType.COMMUNITY:
        return $r('app.string.chatsetting_group_type_community');
      default:
        return $r('app.string.chatsetting_group_type_work_group');
    }
  }

  private getJoinMethodDisplayName(): Resource {
    const joinOption = this.groupState?.joinGroupApprovalType;
    if (joinOption === undefined) {
      return $r('app.string.chatsetting_join_method_need_approval');
    }

    switch (joinOption) {
      case GroupJoinOption.AUTH:
        return $r('app.string.chatsetting_join_method_need_admin_approval');
      case GroupJoinOption.ANY:
        return $r('app.string.chatsetting_join_method_anyone_can_join');
      case GroupJoinOption.FORBID:
        return $r('app.string.chatsetting_forbid_add_group');
      default:
        return $r('app.string.chatsetting_join_method_need_approval');
    }
  }

  private getInviteMethodDisplayName(): Resource {
    switch (this.groupState?.inviteToGroupApprovalType) {
      case GroupJoinOption.AUTH:
        return $r('app.string.chatsetting_join_method_need_admin_approval');
      case GroupJoinOption.ANY:
        return $r('app.string.chatsetting_invite_method_anyone_can_invite');
      case GroupJoinOption.FORBID:
        return $r('app.string.chatsetting_forbid_invite');
      default:
        return $r('app.string.chatsetting_invite_method_anyone_can_invite');
    }
  }

  private navigateToGroupMemberList(): void {
    try {
      console.log('[GroupSettingPage] Show group member list dialog');
      this.showGroupMemberListDialog();
    } catch (error) {
      console.error('[GroupSettingPage] Error showing group member list dialog:', error);
      Toast.error($r('app.string.chatsetting_open_group_member_list_fail'), this.getUIContext());
    }
  }

  private navigateToGroupManagement(): void {
    try {
      console.log('[GroupSettingPage] Show group management dialog');
      this.showGroupManagementDialog();
    } catch (error) {
      console.error('[GroupSettingPage] Error showing group management dialog:', error);
      Toast.error($r('app.string.chatsetting_open_group_management_fail'), this.getUIContext());
    }
  }

  private navigateToGroupAnnouncement(): void {
    try {
      console.log('[GroupSettingPage] Show group announcement dialog');
      this.showGroupAnnouncementDialog();

    } catch (error) {
      console.error('[GroupSettingPage] Error navigating to group announcement:', error);
      Toast.error($r('app.string.chatsetting_open_group_announcement_fail'), this.getUIContext());
    }
  }

  private navigateToAvatarPicker(): void {
    try {
      console.log('[GroupSettingPage] Navigate to avatar picker for group:', this.groupStore?.groupID);


      const avatarUrlList: string[] =
        Array.from<undefined, string>({ length: 24 }, (_: undefined, index: number): string =>
        `https://im.sdk.qcloud.com/download/tuikit-resource/group-avatar/group_avatar_${index + 1}.png`
        );

      console.log('[GroupSettingPage] Avatar URL list:', avatarUrlList);


      if (!avatarUrlList || avatarUrlList.length === 0) {
        console.error('[GroupSettingPage] Avatar URL list is empty');
        Toast.info($r('app.string.chatsetting_no_avatar_available'), this.getUIContext());
        return;
      }

      console.log('[GroupSettingPage] Show avatar picker dialog');
      this.showAvatarPickerDialog(avatarUrlList);

    } catch (error) {
      console.error('[GroupSettingPage] Error navigating to avatar picker:', error);
      Toast.error($r('app.string.chatsetting_open_avatar_picker_fail'), this.getUIContext());
    }
  }

  private openGroupNameEditDialog(): void {
    this.groupNameEditDialogController = new CustomDialogController({
      builder: GroupNameEditDialog({
        currentName: this.groupState?.groupName || '',
        onSave: (newName: string) => {
          if (newName && newName.trim().length > 0) {
            this.groupStore?.updateGroupProfile(newName.trim())
              .then(() => {
                Toast.success($r('app.string.chatsetting_group_name_update_success'), this.getUIContext());

                this.groupStore?.fetchGroupInfo();
              })
              .catch((error: Error) => {
                console.error('[GroupSettingPage] Failed to update group name:', error);
                Toast.error($r('app.string.chatsetting_group_name_update_fail'), this.getUIContext());
              });
          }
        },
        onCancel: () => {
          // Dialog will close automatically
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)',
      autoCancel: true
    });

    this.groupNameEditDialogController.open();
  }

  private openGroupNicknameEditDialog(): void {
    this.groupNicknameEditDialogController = new CustomDialogController({
      builder: GroupNameEditDialog({
        title: $r('app.string.chatsetting_edit_my_group_nickname'),
        currentName: this.getCurrentUserNickname(),
        placeholder: $r('app.string.chatsetting_input_group_nickname_placeholder'),
        helpText: $r('app.string.chatsetting_group_nickname_help_text'),
        maxLength: 20,
        onSave: (newNickname: string) => {
          if (newNickname && newNickname.trim().length > 0) {
            this.groupStore?.setSelfGroupNameCard(newNickname.trim())
              .then(() => {
                Toast.success($r('app.string.chatsetting_group_nickname_update_success'), this.getUIContext());

                this.groupStore?.fetchSelfMemberInfo();
              })
              .catch((error: Error) => {
                console.error('[GroupSettingPage] Failed to update group nickname:', error);
                Toast.error($r('app.string.chatsetting_group_nickname_update_fail'), this.getUIContext());
              });
          }
        },
        onCancel: () => {
          // Dialog will close automatically
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)',
      autoCancel: true
    });

    this.groupNicknameEditDialogController.open();
  }



  private async navigateToTransferOwnership(): Promise<void> {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }

    try {
      console.log('[GroupSettingPage] Navigate to transfer ownership page');


      const currentUserID = LoginStore.shared().state.loginUserInfo?.userID;
      const allMembers = this.groupState?.allMembers ?? [];


      const availableMembers = allMembers.filter(member =>
      member.userID !== currentUserID
      );

      if (availableMembers.length === 0) {
        Toast.info($r('app.string.chatsetting_no_transferable_member'), this.getUIContext());
        return;
      }


      const memberUserPickerData: UserPickerData<GroupMember>[] = availableMembers.map(member => 
        convertGroupMemberToUserPickerData(member)
      );

      this.showUserPickerDialog(
        memberUserPickerData,
        'transferOwnership',
        $r('app.string.chatsetting_select_new_owner')
      );

    } catch (error) {
      console.error('[GroupSettingPage] Error navigating to transfer ownership:', error);
      Toast.error($r('app.string.chatsetting_open_member_picker_fail'), this.getUIContext());
    }
  }

  private async navigateToAddMember(): Promise<void> {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }

    try {
      console.log('[GroupSettingPage] Navigate to add member page');


      Toast.info($r('app.string.chatsetting_getting_friend_list'), this.getUIContext());


      const currentMemberIds = (this.groupState?.allMembers ?? []).map(member => member.userID);


      const friendList: UserPickerData<ContactInfo>[] = await this.getFriendList();


      const availableFriends = friendList.filter(friend =>
      !currentMemberIds.includes(friend.key)
      );

      if (availableFriends.length === 0) {
        Toast.info($r('app.string.chatsetting_no_friends_to_add'), this.getUIContext());
        return;
      }


      this.showUserPickerDialog(
        availableFriends,
        'addMember',
        $r('app.string.chatsetting_select_friends_to_add')
      );

    } catch (error) {
      console.error('[GroupSettingPage] Error navigating to add member:', error);
      Toast.error($r('app.string.chatsetting_open_friend_picker_fail'), this.getUIContext());
    }
  }

  private async getFriendList(): Promise<UserPickerData<ContactInfo>[]> {
    try {

      await this.contactListStore.fetchFriendList();


      const friendList: UserPickerData<ContactInfo>[] = [];
      for (let i = 0; i < this.contactListState.contactDataSource.totalCount(); i++) {
        const contact = this.contactListState.contactDataSource.getData(i) as ContactInfo;
        if (contact) {
          const userPickerData = convertContactToUserPickerData(contact);
          friendList.push(userPickerData);
        }
      }

      console.log(`[GroupSettingPage] getFriendList count: ${friendList.length}`);
      return friendList;

    } catch (error) {
      Toast.error($r('app.string.chatsetting_get_friend_list_fail'), this.getUIContext());
      return [];
    }
  }

  private handleSelectedContactsForAddMember(selectedContacts: ContactInfo[]): void {
    if (!this.groupStore || selectedContacts.length === 0) {
      return;
    }

    console.log('[GroupSettingPage] Handle selected contacts for adding to group:', selectedContacts.map(c => c.title || c.contactID));


    AlertDialog.show(
      $r('app.string.chatsetting_invite_friends_to_group'),
      $r('app.string.chatsetting_confirm_add_members_dialog_format', selectedContacts.length.toString()),
      $r('app.string.chatsetting_cancel'),
      $r('app.string.chatsetting_confirm'),
      undefined, // onDismiss
      () => {
        console.log('[GroupSettingPage] User cancelled add member operation');
      },
      () => {
        this.addSelectedContactsToGroup(selectedContacts);
      },
      this.getUIContext()
    );
  }

  private async addSelectedContactsToGroup(selectedContacts: ContactInfo[]): Promise<void> {
    if (!this.groupStore) {
      return;
    }

    Toast.info($r('app.string.chatsetting_inviting_friends_to_group'), this.getUIContext());

    try {

      const userIDs = selectedContacts.map(contact => contact.contactID);


      await this.groupStore.addGroupMember(userIDs);

      Toast.success($r('app.string.chatsetting_success_invite_friends_format', selectedContacts.length), this.getUIContext());
      console.log('[GroupSettingPage] Successfully added users to group');


      await this.loadGroupData();

    } catch (error) {
      console.error('[GroupSettingPage] Failed to add users to group:', error);
      Toast.error($r('app.string.chatsetting_invite_friends_to_group_fail'), this.getUIContext());
    }
  }

  private handleSelectedMemberForTransferOwnership(selectedMembers: GroupMember[]): void {
    if (!this.groupStore || selectedMembers.length === 0) {
      return;
    }

    const selectedMember = selectedMembers[0];
    console.log('[GroupSettingPage] Handle selected member for transfer ownership:', selectedMember.nameCard || selectedMember.nickname || selectedMember.userID);


    AlertDialog.show(
      $r('app.string.chatsetting_transfer_ownership_title'),
      $r('app.string.chatsetting_confirm_transfer_ownership_dialog_format', selectedMember.nameCard || selectedMember.nickname || selectedMember.userID),
      $r('app.string.chatsetting_cancel_transfer'),
      $r('app.string.chatsetting_confirm_transfer'),
      () => {
        //onDismiss
      },
      () => {
        console.log('[GroupSettingPage] User cancelled transfer ownership operation');
      },
      () => {
        this.transferOwnershipToMember(selectedMember);
      },
      this.getUIContext()

    );
  }

  private async transferOwnershipToMember(targetMember: GroupMember): Promise<void> {
    if (!this.groupStore) {
      return;
    }

    Toast.info($r('app.string.chatsetting_transferring_ownership'), this.getUIContext());

    try {

      await this.groupStore.changeGroupOwner(targetMember.userID);

      Toast.success($r('app.string.chatsetting_transfer_ownership_success_format', targetMember.nameCard || targetMember.nickname || targetMember.userID), this.getUIContext());
      console.log('[GroupSettingPage] Successfully transferred ownership to:', targetMember.userID);


      await this.loadGroupData();


      setTimeout(() => {
        this.closeDialog();
      }, 1000);

    } catch (error) {
      console.error('[GroupSettingPage] Failed to transfer ownership:', error);
      Toast.error($r('app.string.chatsetting_transfer_ownership_failed'), this.getUIContext());
    }
  }

  private getMemberRoleDisplayName(role: GroupMemberRole): string | Resource {
    switch (role) {
      case GroupMemberRole.OWNER:
        return $r('app.string.chatsetting_owner_role');
      case GroupMemberRole.ADMIN:
        return $r('app.string.chatsetting_admin_role');
      case GroupMemberRole.MEMBER:
        return $r('app.string.chatsetting_regular_member_role');
      default:
        return $r('app.string.chatsetting_member_role');
    }
  }

  private handleAvatarSelected(selectedAvatar: string): void {
    console.log('[GroupSettingPage] Avatar selected:', selectedAvatar);

    if (!selectedAvatar || !this.groupStore) {
      console.error('[GroupSettingPage] Invalid avatar or group state');
      return;
    }

    try {

      Toast.info($r('app.string.chatsetting_updating_group_avatar'), this.getUIContext());


      this.groupStore.updateGroupProfile(undefined, undefined, selectedAvatar)
        .then(() => {
          Toast.success($r('app.string.chatsetting_group_avatar_update_successful'), this.getUIContext());
          console.log('[GroupSettingPage] Group avatar updated successfully');


          this.groupStore?.fetchGroupInfo();
        })
        .catch((error: Error) => {
          console.error('[GroupSettingPage] Failed to update group avatar:', error);
          Toast.error($r('app.string.chatsetting_group_avatar_update_failed'), this.getUIContext());
        });
    } catch (error) {
      console.error('[GroupSettingPage] Error handling avatar selection:', error);
      Toast.error($r('app.string.chatsetting_avatar_processing_failed'), this.getUIContext());
    }
  }

  private showDismissGroupConfirmDialog(): void {
    const groupName = this.groupState?.groupName || '';

    AlertDialog.show(
      $r('app.string.chatsetting_dismiss_group_title'),
      $r('app.string.chatsetting_dismiss_group_confirm_format', groupName),
      $r('app.string.chatsetting_cancel_dismiss'),
      $r('app.string.chatsetting_confirm_dismiss'),
      undefined, // onDismiss
      () => {

        console.log('[GroupSettingPage] User cancelled dismiss group');
      },
      () => {

        console.log('[GroupSettingPage] User confirmed dismiss group');
        this.performDismissGroup();
      },
      this.getUIContext()
    );
  }

  private performDismissGroup(): void {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }


    Toast.info($r('app.string.chatsetting_dismissing_group_progress'), this.getUIContext());

    this.groupStore.dismissGroup()
      .then(() => {
        Toast.success($r('app.string.chatsetting_dismiss_group_successful'), this.getUIContext());
        console.log('[GroupSettingPage] Group dismissed successfully');

        // Delete conversation after dismissing group
        return this.conversationStore?.deleteConversation(this.conversationID);
      })
      .then(() => {
        console.log('[GroupSettingPage] Conversation deleted after group dismiss');
        
        // Trigger onGroupDelete callback
        if (this.onGroupDelete) {
          this.onGroupDelete();
        }
        
        // Close dialog
        this.closeDialog();
      })
      .catch((error: Error) => {
        console.error('[GroupSettingPage] Failed to dismiss group or delete conversation:', error);
        Toast.error($r('app.string.chatsetting_dismiss_group_failed'), this.getUIContext());
      });
  }

  private showClearHistoryConfirmDialog(): void {
    const groupName = this.groupState?.groupName || '';

    AlertDialog.show(
      $r('app.string.chatsetting_clear_chat_history_title'),
      $r('app.string.chatsetting_clear_chat_history_confirm_format', groupName),
      $r('app.string.chatsetting_cancel_clear'),
      $r('app.string.chatsetting_confirm_clear'),
      undefined, // onDismiss
      () => {

        console.log('[GroupSettingPage] User cancelled clear history');
      },
      () => {

        console.log('[GroupSettingPage] User confirmed clear history');
        this.performClearHistory();
      },
      this.getUIContext()
    );
  }

  private performClearHistory(): void {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }


    Toast.info($r('app.string.chatsetting_clearing_chat_history'), this.getUIContext());

    this.conversationStore?.clearConversationMessages(this.conversationID).then(() => {
      Toast.success($r('app.string.chatsetting_clear_chat_history_successful'), this.getUIContext());
      console.log('[GroupSettingPage] Chat history cleared successfully');
    }).catch((error: Error) => {
      console.error('[GroupSettingPage] Failed to clear history:', error);
      Toast.error($r('app.string.chatsetting_clear_chat_history_failed'), this.getUIContext());
    });
  }

  private showLeaveGroupConfirmDialog(): void {
    const groupName = this.groupState?.groupName || '';

    AlertDialog.show(
      $r('app.string.chatsetting_leave_group_title'),
      $r('app.string.chatsetting_leave_group_confirm_format', groupName),
      $r('app.string.chatsetting_cancel_leave'),
      $r('app.string.chatsetting_confirm_leave'),
      undefined, // onDismiss
      () => {

        console.log('[GroupSettingPage] User cancelled leave group');
      },
      () => {

        console.log('[GroupSettingPage] User confirmed leave group');
        this.performLeaveGroup();
      },
      this.getUIContext()
    );
  }

  private performLeaveGroup(): void {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }


    Toast.info($r('app.string.chatsetting_leaving_group_progress'), this.getUIContext());

    this.groupStore.quitGroup()
      .then(() => {
        Toast.success($r('app.string.chatsetting_leave_group_successful'), this.getUIContext());
        console.log('[GroupSettingPage] Left group successfully');

        // Delete conversation after leaving group
        return this.conversationStore?.deleteConversation(this.conversationID);
      })
      .then(() => {
        console.log('[GroupSettingPage] Conversation deleted after leaving group');
        
        // Trigger onGroupDelete callback
        if (this.onGroupDelete) {
          this.onGroupDelete();
        }
        
        // Close dialog
        this.closeDialog();
      })
      .catch((error: Error) => {
        console.error('[GroupSettingPage] Failed to leave group or delete conversation:', error);
        Toast.error($r('app.string.chatsetting_leave_group_failed'), this.getUIContext());
      });
  }

  private handleQuickActionClick(label: string | Resource): void {
    if (!this.groupStore) {
      Toast.info($r('app.string.chatsetting_group_info_unavailable'), this.getUIContext());
      return;
    }

    this.handleSendMessageClick();
  }

  private handleSendMessageClick(): void {

    if (this.onSendMessageClick) {
      const contactTitle = this.groupState?.groupName  || '';
      const contactAvatarUrl = this.groupState?.avatarUrl || '';
      this.onSendMessageClick(this.conversationID, contactTitle, contactAvatarUrl);
    }

    this.closeDialog();
  }

  private showAvatarPickerDialog(urlList: string[]): void {
    try {
      if (this.avatarPickerDialogController) {
        this.avatarPickerDialogController.close();
        this.avatarPickerDialogController = undefined;
      }

      this.avatarPickerDialogController = new CustomDialogController({
        builder: AvatarPickerDialog({
          title: $r('app.string.chatsetting_select_avatar'),
          urlList: urlList,
          onConfirm: (selectedUrl: string, selectedIndex: number) => {
            this.handleAvatarSelected(selectedUrl);
          }
        }),
        alignment: DialogAlignment.Default,
        customStyle: true,
        autoCancel: true,
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        cancel: () => {
          this.avatarPickerDialogController = undefined;
        }
      });

      this.avatarPickerDialogController.open();
    } catch (error) {

    }
  }

  private showGroupAnnouncementDialog(): void {
    try {
      if (this.groupAnnouncementDialogController) {
        this.groupAnnouncementDialogController.close();
        this.groupAnnouncementDialogController = undefined;
      }

      if (!this.groupStore?.groupID) {

        return;
      }

      this.groupAnnouncementDialogController = new CustomDialogController({
        builder: GroupAnnouncementDialog({
          groupID: this.groupStore?.groupID,
          onSave: (announcement: string) => {
            console.log('[GroupSettingPage] GroupAnnouncement saved:', announcement);
            this.groupStore?.fetchGroupInfo();
          }
        }),
        alignment: DialogAlignment.Default,
        customStyle: true,
        autoCancel: true,
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        cancel: () => {
          this.groupAnnouncementDialogController = undefined;
        }
      });

      this.groupAnnouncementDialogController.open();
    } catch (error) {

    }
  }

  private showGroupMemberListDialog(): void {
    try {
      if (this.groupMemberListDialogController) {
        this.groupMemberListDialogController.close();
        this.groupMemberListDialogController = undefined;
      }

      if (!this.groupStore?.groupID) {

        return;
      }

      this.groupMemberListDialogController = new CustomDialogController({
        builder: GroupMemberListDialog({
          groupID: this.groupStore?.groupID || '',
          groupName: this.groupState?.groupName || 'Info',
          onMemberSelect: (member: GroupMember) => {
            console.log('[GroupSettingPage] Select member:', member.userID);
          },
          onSendMessageClick: this.onSendMessageClick
        }),
        alignment: DialogAlignment.Default,
        customStyle: true,
        autoCancel: true,
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        cancel: () => {
          this.groupMemberListDialogController = undefined;
        }
      });

      this.groupMemberListDialogController.open();
    } catch (error) {

    }
  }

  private showUserPickerDialog(dataSource: UserPickerData<UserPickerDataType>[], action: string, title?: string | Resource): void {
    try {
      if (this.userPickerDialogController) {
        this.userPickerDialogController.close();
        this.userPickerDialogController = undefined;
      }

      this.userPickerDialogController = new CustomDialogController({
        builder: UserPickerDialog({
          title: title || $r('app.string.chatsetting_select_user'),
          dataSource: dataSource,
          preSelectedUsers: [],
          maxSelectCount: -1,
          confirmButtonText: $r('app.string.chatsetting_complete'),
          action: action,
          onConfirm: (selectedItems: UserPickerDataType[], actionType: string) => {
            this.handleSelectedUsersResult(selectedItems, actionType);
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

  private handleSelectedUsersResult(selectedItems: UserPickerDataType[], action: string): void {
    console.log('[GroupSettingPage] handleSelectedUsersResult action:', action, 'selectedItems.length:', selectedItems.length);

    switch (action) {
      case 'addMember':
        // selectedItems are ContactInfo objects
        this.handleSelectedContactsForAddMember(selectedItems as ContactInfo[]);
        break;
      case 'transferOwnership':
        // selectedItems are GroupMember objects
        this.handleSelectedMemberForTransferOwnership(selectedItems as GroupMember[]);
        break;
      default:
        console.warn('[GroupSettingPage]unkown action:', action);
    }
  }

  private showGroupManagementDialog(): void {
    try {
      if (this.groupManagementDialogController) {
        this.groupManagementDialogController.close();
        this.groupManagementDialogController = undefined;
      }

      if (!this.groupStore?.groupID) {

        return;
      }

      this.groupManagementDialogController = new CustomDialogController({
        builder: GroupManagementDialog({
          groupID: this.groupStore?.groupID || ''
        }),
        alignment: DialogAlignment.Default,
        customStyle: true,
        autoCancel: true,
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        cancel: () => {
          this.groupManagementDialogController = undefined;
        }
      });

      this.groupManagementDialogController.open();
    } catch (error) {

    }
  }
}