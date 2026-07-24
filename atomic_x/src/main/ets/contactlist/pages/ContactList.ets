import { BadgeControl, BadgeType, ThemeState, AZOrderedList, AZOrderedListItem, AZOrderedListConfig } from '../../basecomponent/Index';
import { ContactInfo, ContactState, ContactStore } from '@tencentcloud/atomicxcore';
import { GroupState, GroupStore } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { GroupListView } from './manager/GroupListView';
import { BlackListView } from './manager/BlackListView';
import { FriendApplicationListView } from './manager/FriendApplicationListView';
import { GroupApplicationListView } from './manager/GroupApplicationListView';
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';


@Component
export struct ContactList {
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly ITEM_HEIGHT: number = 68;
  private static readonly SEARCH_BAR_HEIGHT: number = 36;
  private static readonly NOTIFICATION_BADGE_SIZE: number = 20;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink contactStore: ContactStore;
  @ObjectLink groupStore: GroupStore;
  @State private contactState: ContactState = this.contactStore.state as ContactState;
  @State private groupState: GroupState = this.groupStore.state as GroupState;
  // State management
  @State isLoading: boolean = false;
  @State showSearchResults: boolean = false;
  @State searchResults: ContactInfo[] = [];
  @State currentSelectedLetter: string = '';
  onContactClick?: (item: ContactInfo) => void;
  onGroupClick?: (item: ContactInfo) => void;
  private friendApplicationDialogController: CustomDialogController | null = null;
  private groupApplicationDialogController: CustomDialogController | null = null;
  private groupListDialogController: CustomDialogController | null = null;
  private blackListDialogController: CustomDialogController | null = null;
  @State private dialogAnimationOffset: number = 0;

  aboutToAppear() {
    this.contactState = this.contactStore.state as ContactState;
    this.groupState = this.groupStore.state as GroupState;

    this.fetchContactList();
    console.info('ContactListPage aboutToAppear');
    this.contactStore.loadBlackList();
    this.contactStore.loadFriendApplications();
    this.groupStore.loadApplications();
  }

  aboutToDisappear() {
  }


  @Builder
  ManagementSectionBuilder() {
    Column() {

      Row() {
        Text($r('app.string.new_contacts'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Row() {
          if (this.contactState.friendApplicationUnreadCount > 0) {
            BadgeControl({
              text: this.contactState.friendApplicationUnreadCount.toString(),
              type: BadgeType.Text
            })
              .margin({ right: 8 })
          }

          Image($rawfile('contactlist/contact_arrow.svg'))
            .width(12)
            .height(12)
            .fillColor(this.themeState.colors.textColorPrimary)
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to new contacts page');
        this.showFriendApplicationDialogInternal();
      })


      Row() {
        Text($r('app.string.new_group_requests'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Row() {
          if (this.groupState.unreadApplicationCount > 0) {
            BadgeControl({
              text: this.groupState.unreadApplicationCount.toString(),
              type: BadgeType.Text
            })
              .margin({ right: 8 })
          }

          Image($rawfile('contactlist/contact_arrow.svg'))
            .width(12)
            .height(12)
            .fillColor(this.themeState.colors.textColorPrimary)
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to new group requests page');
        this.showGroupApplicationDialogInternal();
      })


      Row() {
        Text($r('app.string.my_group'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Image($rawfile('contactlist/contact_arrow.svg'))
          .width(12)
          .height(12)
          .fillColor(this.themeState.colors.textColorPrimary)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to my groups');
        this.showGroupListDialogInternal();
      })


      Row() {
        Text($r('app.string.the_blacklist'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Image($rawfile('contactlist/contact_arrow.svg'))
          .width(12)
          .height(12)
          .fillColor(this.themeState.colors.textColorPrimary)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to blacklist management');
        this.showBlackListDialogInternal();
      })
    }
    .margin({ left: 0, right: 0 })
  }


  @Builder
  ContactListBuilder() {
    Column() {
      if (this.showSearchResults) {
        this.SearchResultsBuilder()
      } else {
        this.GroupedContactListBuilder()
      }
    }
  }


  // Helper method to create header builder with context
  getHeaderBuilder(): () => void {
    return () => {
      this.ManagementSectionBuilder()
    }
  }

  @Builder
  GroupedContactListBuilder() {
    AZOrderedList({
      dataSource: this.convertContactsToAZOrderedListItems(),
      config: { showIndexBar: true },
      header: this.getHeaderBuilder(),
      onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
        if (this.onContactClick) {
          this.onContactClick(item.extraData);
        }
      }
    })
  }



  @Builder
  SearchResultsBuilder() {
    if (this.searchResults.length > 0) {
      AZOrderedList({
        dataSource: this.convertSearchResultsToAZOrderedListItems(),
        config: { showIndexBar: false },
        header: this.getHeaderBuilder(),
        onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
          if (this.onContactClick) {
            this.onContactClick(item.extraData);
          }
        }
      })
    } else {
      Column() {
        this.ManagementSectionBuilder()
        
        Column() {
          Text($r('app.string.no_results_found'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ top: 50 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
    }
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Text($r('app.string.no_contacts_title'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')

      Text($r('app.string.no_contacts_desc'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeState.colors.textColorLink)

      Text($r('app.string.loading_contacts'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {

      Stack() {

        if (this.isLoading) {
          this.LoadingStateBuilder()
        } else if (this.contactState.friendList.length === 0) {
          Column() {
            this.ManagementSectionBuilder()
            this.EmptyStateBuilder()
          }
        } else {
          this.ContactListBuilder()
        }


      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  private fetchContactList() {

    this.isLoading = true;
    this.contactStore.loadFriends(new CompletionHandlerAdapter(() => {
      this.isLoading = false;
    }, () => {
      this.isLoading = false;
    }));


    setTimeout(() => {
      if (this.isLoading) {
        console.warn('fetchContactList time out');
        this.isLoading = false;
      }
    }, 5000);
  }

  private getContactDisplayName(contact: ContactInfo): string {
    return (contact.friendRemark && contact.friendRemark.length > 0) ? contact.friendRemark
      : (contact.nickname && contact.nickname.length > 0) ? contact.nickname
        : contact.userID || '';
  }

  // Convert ContactInfo to AZOrderedListItem
  private convertContactsToAZOrderedListItems(): AZOrderedListItem<ContactInfo>[] {
    const items: AZOrderedListItem<ContactInfo>[] = [];

    for (let i = 0; i < this.contactState.friendList.length; i++) {
      const contact = this.contactState.friendList[i];
      if (contact) {
        items.push({
          key: contact.userID,
          label: this.getContactDisplayName(contact),
          avatarUrl: contact.avatarURL,
          extraData: contact
        });
      }
    }

    return items;
  }

  // Convert search results to AZOrderedListItem
  private convertSearchResultsToAZOrderedListItems(): AZOrderedListItem<ContactInfo>[] {
    return this.searchResults.map((contact: ContactInfo): AZOrderedListItem<ContactInfo> => ({
      key: contact.userID,
      label: this.getContactDisplayName(contact),
      avatarUrl: contact.avatarURL,
      extraData: contact
    }));
  }

  // Dialog builders for sub-pages
  @Builder
  FriendApplicationDialogBuilder() {
    Column() {
      FriendApplicationListView({
        contactStore: this.contactStore,
        onBack: () => {
          this.friendApplicationDialogController?.close();
          this.friendApplicationDialogController = null;
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  @Builder
  GroupApplicationDialogBuilder() {
    Column() {
      GroupApplicationListView({
        groupStore: this.groupStore,
        onBack: () => {
          this.groupApplicationDialogController?.close();
          this.groupApplicationDialogController = null;
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  @Builder
  GroupListDialogBuilder() {
    Column() {
      GroupListView({
        groupStore: this.groupStore,
        onBack: () => {
          this.groupListDialogController?.close();
          this.groupListDialogController = null;
        },
        onShowProfile: (group: ContactInfo) => {
          console.log('[ContactList] Selected group:', group.nickname);
          this.groupListDialogController?.close();
          this.groupListDialogController = null;
          // Trigger onGroupClick callback
          if (this.onGroupClick) {
            this.onGroupClick(group);
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  @Builder
  BlackListDialogBuilder() {
    Column() {
      BlackListView({
        contactStore: this.contactStore,
        onBack: () => {
          this.blackListDialogController?.close();
          this.blackListDialogController = null;
        },
        onShowProfile: (item: ContactInfo) => {
          this.blackListDialogController?.close();
          this.blackListDialogController = null;
          // Trigger onContactClick callback
          if (this.onContactClick) {
            this.onContactClick(item);
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  // Internal dialog display methods
  private showFriendApplicationDialogInternal(): void {
    try {
      if (this.friendApplicationDialogController) {
        this.friendApplicationDialogController.close();
        this.friendApplicationDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.friendApplicationDialogController = new CustomDialogController({
        builder: this.FriendApplicationDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.friendApplicationDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.friendApplicationDialogController.open();
    } catch (error) {
      console.error('[ContactList] showFriendApplicationDialog error:', error);
    }
  }

  private showGroupApplicationDialogInternal(): void {
    try {
      if (this.groupApplicationDialogController) {
        this.groupApplicationDialogController.close();
        this.groupApplicationDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.groupApplicationDialogController = new CustomDialogController({
        builder: this.GroupApplicationDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.groupApplicationDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.groupApplicationDialogController.open();
    } catch (error) {
      console.error('[ContactList] showGroupApplicationDialog error:', error);
    }
  }

  private showGroupListDialogInternal(): void {
    try {
      if (this.groupListDialogController) {
        this.groupListDialogController.close();
        this.groupListDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.groupListDialogController = new CustomDialogController({
        builder: this.GroupListDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.groupListDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.groupListDialogController.open();
    } catch (error) {
      console.error('[ContactList] showGroupListDialog error:', error);
    }
  }

  private showBlackListDialogInternal(): void {
    try {
      if (this.blackListDialogController) {
        this.blackListDialogController.close();
        this.blackListDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.blackListDialogController = new CustomDialogController({
        builder: this.BlackListDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.blackListDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.blackListDialogController.open();
    } catch (error) {
      console.error('[ContactList] showBlackListDialog error:', error);
    }
  }

}