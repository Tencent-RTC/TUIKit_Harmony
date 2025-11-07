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
import {
  C2CSettingState,
  C2CSettingStore,
  ConversationInfo,
  ConversationListState,
  ConversationListStore
} from '@tencentcloud/atomicxcore';
import { GroupNameEditDialog } from '../dialog/GroupSettingDialogs';

@CustomDialog
export struct C2CSettingDialog {
  controller: CustomDialogController;
  userID: string = '';
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onContactDelete?: () => void;

  build() {
    C2CChatSetting({
      userID: this.userID,
      onSendMessageClick: (newConversationID?: string, title?: string, avatarUrl?: string) => {
        if (this.onSendMessageClick) {
          this.onSendMessageClick(newConversationID, title, avatarUrl);
        }
      },
      onContactDelete: () => {
        if (this.onContactDelete) {
          this.onContactDelete();
        }
      },
      dialogController: this.controller
    })
  }
}

@Component
export struct C2CChatSetting {
  private static readonly CELL_HEIGHT: number = 56;
  private static readonly SECTION_MARGIN: number = 12;
  private static readonly HORIZONTAL_PADDING: number = 8;
  private static readonly BORDER_RADIUS: number = 12;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State c2cStore?: C2CSettingStore = undefined;
  @State c2cState?: C2CSettingState = undefined;
  @State conversationStore?: ConversationListStore = ConversationListStore.create();
  @State conversationState?: ConversationListState = this.conversationStore?.state;
  @State conversationID: string = '';
  @State isLoading: boolean = true;
  userID: string = '';
  dialogController?: CustomDialogController;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onContactDelete?: () => void;
  private remarkEditDialogController?: CustomDialogController = new CustomDialogController({
    builder: GroupNameEditDialog({
      title: $r('app.string.chatsetting_set_remark'),
      currentName: this.c2cState?.remark || '',
      placeholder: $r('app.string.chatsetting_input_remark_name'),
      helpText: $r('app.string.chatsetting_remark_help_text'),
      maxLength: 30,
      onSave: (newRemark: string) => {
        this.handleRemarkSave(newRemark);
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  aboutToAppear(): void {
    console.info('[C2CChatSettingPage] parm:', {
      userID: this.userID
    });
    if (this.userID && this.userID.length > 0) {
      this.conversationID = `c2c_${this.userID}`;
      this.initializeWithUserID();
    } else {
      this.isLoading = false;
    }
  }

  aboutToDisappear(): void {
    if (this.remarkEditDialogController) {
      this.remarkEditDialogController = undefined;
    }
    this.c2cStore = undefined;
  }

  build() {
    Column() {
      this.NavigationBarBuilder()

      if (this.isLoading) {

        this.LoadingStateBuilder()
      } else {

        Scroll() {
          Column({ space: 0 }) {
            this.UserInfoSectionBuilder()
            this.RemarkSectionBuilder()
            this.NotificationSettingsSectionBuilder()
            this.BlacklistSectionBuilder()
            this.ActionButtonsSectionBuilder()
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorOperate)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  LoadingStateBuilder() {
    Column({ space: 16 }) {

      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.themeState.colors.textColorLink)


      Text($r('app.string.chatsetting_loading_contact_information'))
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
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
          if (this.dialogController) {
            this.dialogController.close();
          } else {
            console.warn('[C2CChatSettingPage] dialogController not available');
          }
        })

      Blank()

      // Title
      Text($r('app.string.chatsetting_contact_info_title'))
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
  UserInfoSectionBuilder() {
    Column() {

      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: this.c2cState?.avatarURL,
          name: this.getUserInitials() || '',
        },
        avatarSize: AvatarSize.XL,
      }).margin({ top: 24, bottom: 16 })

      Text((this.c2cState?.nickname || this.c2cStore?.userID || ''))
        .fontSize(24)
        .fontWeight(600)
        .fontFamily('PingFang HK')
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 4 })

      // User ID
      Text(`ID: ${this.c2cStore?.userID}`)
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
    .borderRadius(C2CChatSetting.BORDER_RADIUS)
    .padding({
      left: C2CChatSetting.HORIZONTAL_PADDING,
      right: C2CChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      top: C2CChatSetting.SECTION_MARGIN,
      bottom: C2CChatSetting.SECTION_MARGIN
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
    .backgroundColor(this.themeState.colors.bgColorInput)
    .borderRadius(12)
    .padding({ top: 16, bottom: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.handleQuickActionClick(label);
    })
  }

  @Builder
  RemarkSectionBuilder() {
    Column({ space: 0 }) {

      this.RemarkRowBuilder()
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(C2CChatSetting.BORDER_RADIUS)
    .padding({
      left: C2CChatSetting.HORIZONTAL_PADDING,
      right: C2CChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: C2CChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  NotificationSettingsSectionBuilder() {
    Column({ space: 0 }) {

      this.DoNotDisturbRowBuilder()
      this.DividerBuilder()


      this.TopChatRowBuilder()
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(C2CChatSetting.BORDER_RADIUS)
    .padding({
      left: C2CChatSetting.HORIZONTAL_PADDING,
      right: C2CChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: C2CChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  ChatBackgroundSectionBuilder() {
    Column({ space: 0 }) {

      this.ChatBackgroundRowBuilder()
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(C2CChatSetting.BORDER_RADIUS)
    .padding({
      left: C2CChatSetting.HORIZONTAL_PADDING,
      right: C2CChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: C2CChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  BlacklistSectionBuilder() {
    Column({ space: 0 }) {

      this.BlacklistRowBuilder()
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(C2CChatSetting.BORDER_RADIUS)
    .padding({
      left: C2CChatSetting.HORIZONTAL_PADDING,
      right: C2CChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: C2CChatSetting.SECTION_MARGIN
    })
  }

  @Builder
  RemarkRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_set_remark_title'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Row({ space: 8 }) {
        Text(this.c2cState?.remark || '')
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(C2CChatSetting.CELL_HEIGHT)
    .padding({ left: C2CChatSetting.HORIZONTAL_PADDING, right: C2CChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      this.showRemarkEditDialog();
    })
  }

  @Builder
  DoNotDisturbRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_mute_notifications'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Switch({
        checked: this.c2cState?.isNotDisturb || false,
        onCheckedChange: (isOn: boolean) => {
          if (this.conversationID) {
            this.conversationStore?.muteConversation(this.conversationID, isOn).then(() => {
            }).catch((error: Error) => {
              console.error('setChatMuted failed:', error);
            });
          }
        },
        type: SwitchType.Basic
      })
    }
    .width('100%')
    .height(C2CChatSetting.CELL_HEIGHT)
    .padding({ left: C2CChatSetting.HORIZONTAL_PADDING, right: C2CChatSetting.HORIZONTAL_PADDING })
  }

  @Builder
  TopChatRowBuilder() {
    Row() {
      Text($r('app.string.pin_conversation'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Switch({
        checked: this.c2cState?.isPinned || false,
        type: SwitchType.Basic,
        onCheckedChange: (isOn: boolean) => {
          if (this.conversationID) {
            this.conversationStore?.pinConversation(this.conversationID, isOn).then(() => {
            }).catch((error: Error) => {
              console.error('setChatMuted failed:', error);
            });
          }
        }
      })
    }
    .width('100%')
    .height(C2CChatSetting.CELL_HEIGHT)
    .padding({ left: C2CChatSetting.HORIZONTAL_PADDING, right: C2CChatSetting.HORIZONTAL_PADDING })
  }

  @Builder
  ChatBackgroundRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_chat_background'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Row({ space: 8 }) {
        Text('Default')
          .fontSize(17)
          .fontWeight(400)
          .fontFamily('SF Pro Text')
          .fontColor(this.themeState.colors.textColorSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($rawfile('search/right_arrow_icon.svg'))
          .width(12)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
    }
    .width('100%')
    .height(C2CChatSetting.CELL_HEIGHT)
    .padding({ left: C2CChatSetting.HORIZONTAL_PADDING, right: C2CChatSetting.HORIZONTAL_PADDING })
    .onClick(() => {
      console.log('Chat background clicked');

    })
  }

  @Builder
  BlacklistRowBuilder() {
    Row() {
      Text($r('app.string.chatsetting_blacklist'))
        .fontSize(17)
        .fontWeight(400)
        .fontFamily('SF Pro Text')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()

      Switch({
        checked: this.c2cState?.isInBlacklist || false,
        type: SwitchType.Basic,
        onCheckedChange: (isOn: boolean) => {
          if (isOn) {
            this.c2cStore?.addToBlacklist()
              .then(() => {
                Toast.success($r('app.string.chatsetting_added_to_blacklist'), this.getUIContext());
              })
              .catch((error: Error) => {
                Toast.error($r('app.string.chatsetting_add_blacklist_fail'), this.getUIContext());
                console.error('Add to blacklist failed:', error);
              });
          } else {
            this.c2cStore?.removeFromBlacklist()
              .then(() => {
                Toast.success($r('app.string.chatsetting_removed_from_blacklist'), this.getUIContext());
              })
              .catch((error: Error) => {
                Toast.error($r('app.string.chatsetting_remove_blacklist_fail'), this.getUIContext());
                console.error('Remove from blacklist failed:', error);
              });
          }
        }
      })
    }
    .width('100%')
    .height(C2CChatSetting.CELL_HEIGHT)
    .padding({ left: C2CChatSetting.HORIZONTAL_PADDING, right: C2CChatSetting.HORIZONTAL_PADDING })
  }

  @Builder
  DividerBuilder() {
    Divider()
      .height(1)
      .color(this.themeState.colors.strokeColorSecondary)
  }

  @Builder
  ActionButtonsSectionBuilder() {
    Column({ space: 0 }) {

      this.ActionButtonBuilder($r('app.string.chatsetting_clear_chat_history_title'),
        this.themeState.colors.textColorError, () => {
          if (this.conversationID) {
            this.conversationStore?.clearConversationMessages(this.conversationID).then(() => {
              Toast.success($r('app.string.chatsetting_clear_chat_success'), this.getUIContext());
            }).catch((error: Error) => {
              Toast.error($r('app.string.chatsetting_clear_chat_fail'), this.getUIContext());
              console.error('Clear history failed:', error);
            });
          }
        })

      this.DividerBuilder()


      this.ActionButtonBuilder($r('app.string.chatsetting_delete_friend'),
        this.themeState.colors.textColorError, () => {
          this.c2cStore?.deleteFriend().then(() => {
            Toast.success($r('app.string.chatsetting_delete_friend_success'), this.getUIContext());

            // Delete conversation after deleting friend
            if (this.conversationID.length > 0) {
              return this.conversationStore?.deleteConversation(this.conversationID ?? "");
            }
            return Promise.resolve();
          }).then(() => {
            console.log('[C2CChatSetting] Conversation deleted after friend deletion');
            
            // Trigger onContactDelete callback first
            if (this.onContactDelete) {
              console.log('[C2CChatSetting] Calling onContactDelete callback');
              this.onContactDelete();
            }

            // Then close the dialog
            if (this.dialogController) {
              this.dialogController.close();
            }
          }).catch((error: Error) => {
            Toast.error($r('app.string.chatsetting_delete_friend_fail'), this.getUIContext());
            console.error('Delete friend or conversation failed:', error);
          });
        })
    }
    .backgroundColor(this.themeState.colors.bgColorTopBar)
    .borderRadius(C2CChatSetting.BORDER_RADIUS)
    .padding({
      left: C2CChatSetting.HORIZONTAL_PADDING,
      right: C2CChatSetting.HORIZONTAL_PADDING
    })
    .margin({
      bottom: C2CChatSetting.SECTION_MARGIN
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
    .height(C2CChatSetting.CELL_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .onClick(action)
  }

  private showRemarkEditDialog(): void {

    this.remarkEditDialogController = new CustomDialogController({
      builder: GroupNameEditDialog({
        title: $r('app.string.chatsetting_set_remark'),
        currentName: this.c2cState?.remark || '',
        placeholder: $r('app.string.chatsetting_input_remark_name'),
        helpText: $r('app.string.chatsetting_remark_help_text'),
        maxLength: 30,
        onSave: (newRemark: string) => {
          this.handleRemarkSave(newRemark);
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      autoCancel: true
    });

    this.remarkEditDialogController.open();
  }

  private handleRemarkSave(newRemark: string): void {
    if (!this.c2cStore) {
      Toast.error($r('app.string.chatsetting_user_status_error'), this.getUIContext());
      return;
    }


    this.c2cStore.setUserRemark(newRemark)
      .then(() => {
        Toast.success($r('app.string.chatsetting_remark_set_success'), this.getUIContext());
      })
      .catch((error: Error) => {
        Toast.error($r('app.string.chatsetting_remark_set_fail',""), this.getUIContext());
      });
  }

  private handleQuickActionClick(label: string | Resource): void {
    if (!this.c2cStore) {
      Toast.error($r('app.string.chatsetting_user_status_error'), this.getUIContext());
      return;
    }
      this.handleSendMessageClick();
  }

  private handleSendMessageClick(): void {
    if (this.onSendMessageClick) {
      const contactTitle: string = this.c2cState?.remark || this.c2cState?.nickname || this.c2cStore?.userID || 'Contact';
      const contactAvatarUrl: string = this.c2cState?.avatarURL || '';
      this.onSendMessageClick(this.conversationID, contactTitle, contactAvatarUrl);
    }
    if (this.dialogController) {
      this.dialogController.close();
    }
  }

  private initializeWithUserID(): void {
    console.info('[C2CChatSettingPage] userID:', this.userID);

    if (this.userID) {
      try {
        this.c2cStore = C2CSettingStore.create(this.userID);
        this.c2cState = this.c2cStore.state;
        this.c2cStore?.fetchUserInfo()
          .then(() => {
            // User info fetched
          });
        this.c2cStore.checkBlacklistStatus()
          .then(() => {
            // Blacklist status checked
          });

        if (this.conversationID) {
          let conversation = new ConversationInfo();
          conversation.ID = this.conversationID;
          this.conversationStore?.fetchConversationInfo(this.conversationID).then(() => {
            this.isLoading = false;
          }).catch((error: Error) => {
            Toast.error($r('app.string.chatsetting_clear_chat_fail'), this.getUIContext());
            console.error('Fetch conversation info failed:', error);
          });
        }

      } catch (error) {
        console.error('[C2CChatSettingPage] Initialize failed:', error);
      }
    }
  }

  private getUserInitials(): string {
    const name = this.c2cState?.nickname || this.c2cStore?.userID || 'Dominik';
    const words = name.split(' ');
    if (words.length >= 2) {
      return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase();
    }
    return name.charAt(0).toUpperCase();
  }
}