import { SettingsPage } from './SettingsPage'
import { ContactsPage, ChatDialog } from 'chatuikit'
import { ImageSizeUtil, ThemeState, BadgeControl, BadgeType, UserInteractionHelper, GroupSettingDialog, FriendApplicationListView, GroupApplicationListView, GroupListView, BlackListView } from '@tencentcloud/atomicx';
import { ConversationsPage } from 'chatuikit'
import { LoginStore, ContactListStore, ContactListState, ConversationListStore, ConversationListState, ConversationInfo, MessageInfo, ContactInfo } from '@tencentcloud/atomicxcore'
import { ImmersiveMode, LevelMode } from '@kit.ArkUI'

@Observed
class TabItem {
  index: number;
  title: Resource;
  selectedIcon: Resource;
  normalIcon: Resource;
  badgeCount?: number;

  constructor(index: number, title: Resource, selectedIcon: Resource, normalIcon: Resource, badgeCount?: number) {
    this.index = index;
    this.title = title;
    this.selectedIcon = selectedIcon;
    this.normalIcon = normalIcon;
    this.badgeCount = badgeCount;
  }
}

@Entry
@Component
struct HomePage {
  private static readonly TAB_BAR_HEIGHT: number = 56;
  private static readonly ICON_SIZE: number = 24;
  private static readonly INDICATOR_WIDTH: number = 16;
  private static readonly INDICATOR_HEIGHT: number = 3;
  private static readonly TAB_MESSAGE: number = 0;
  private static readonly TAB_CONTACT: number = 1;
  private static readonly TAB_PROFILE: number = 2;
  @State currentIndex: number = 0;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State tabItems: TabItem[] = [];
  private tabsController: TabsController = new TabsController();
  @State private contactListStore: ContactListStore = ContactListStore.create();
  @Watch('onApplicationUnreadCountChanged')
  @State private contactListState: ContactListState = this.contactListStore.state;
  @State private conversationListStore: ConversationListStore = ConversationListStore.create();
  @Watch('onConversationUnreadCountChanged')
  @State private conversationListState: ConversationListState = this.conversationListStore.state;
  private chatDialogController?: CustomDialogController;
  private groupSettingDialogController?: CustomDialogController;
  private newContactsDialogController?: CustomDialogController;
  private newGroupsDialogController?: CustomDialogController;
  private myGroupDialogController?: CustomDialogController;
  private blackListDialogController?: CustomDialogController;
  @State private dialogAnimationOffset: number = 0;
  private userInteractionHelper: UserInteractionHelper = new UserInteractionHelper();

  aboutToAppear() {
    this.tabItems = [
      new TabItem(
        HomePage.TAB_MESSAGE,
        $r("app.string.demo_conversation_tab_name"),
        $r('app.media.tab_message_selected'),
        $r('app.media.tab_message_normal'),
        0
      ),
      new TabItem(
        HomePage.TAB_CONTACT,
        $r("app.string.demo_contact_tab_name"),
        $r('app.media.tab_contact_selected'),
        $r('app.media.tab_contact_normal'),
        0
      ),
      new TabItem(
        HomePage.TAB_PROFILE,
        $r("app.string.demo_profile_tab_name"),
        $r('app.media.tab_profile_selected'),
        $r('app.media.tab_profile_normal'),
        0
      )
    ];

    this.initContactBadge();
  }

  aboutToDisappear() {

  }

  onApplicationUnreadCountChanged() {
    console.info(`HomePage.TAB_CONTACT: ${this.contactListState.friendApplicationUnreadCount + this.contactListState.groupApplicationUnreadCount}，friendApplicationUnreadCount：${this.contactListState.friendApplicationUnreadCount} groupApplicationUnreadCount：${this.contactListState.groupApplicationUnreadCount}`);
    this.updateTabBadge(HomePage.TAB_CONTACT,
      this.contactListState.friendApplicationUnreadCount + this.contactListState.groupApplicationUnreadCount);
  }

  onConversationUnreadCountChanged() {
    console.info(`HomePage.TAB_MESSAGE: ${this.conversationListState.totalUnreadCount}`);
    this.updateTabBadge(HomePage.TAB_MESSAGE, this.conversationListState.totalUnreadCount);
  }

  @Builder
  TabIcon(index: number) {
    Stack() {
      Image(this.currentIndex === index ?
      this.getTabItem(index).selectedIcon :
      this.getTabItem(index).normalIcon)
        .width(HomePage.ICON_SIZE)
        .height(HomePage.ICON_SIZE)
        .objectFit(ImageFit.Contain)
        .fillColor(this.currentIndex === index ?
        this.themeState.colors.textColorLink :
        this.themeState.colors.textColorSecondary)


      if (this.getTabItem(index).badgeCount && this.getTabItem(index).badgeCount! > 0) {
        BadgeControl({
          text: this.getTabItem(index).badgeCount! > 99 ? '99+' : this.getTabItem(index).badgeCount!.toString(),
          type: BadgeType.Text
        })
          .position({
            x: HomePage.ICON_SIZE - 2,
            y: 2
          })
          .align(Alignment.TopEnd)
      }
    }
    .width(HomePage.ICON_SIZE + 8)
    .height(HomePage.ICON_SIZE + 8)
    .margin({ bottom: 4 })
  }

  @Builder
  TabBuilder(index: number) {
    Column() {

      this.TabIcon(index)

      Text(this.getTabItem(index).title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ?
        this.themeState.colors.textColorLink :
        this.themeState.colors.textColorSecondary)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)


      if (this.currentIndex === index) {
        Row() {
          Row()
            .width(HomePage.INDICATOR_WIDTH)
            .height(HomePage.INDICATOR_HEIGHT)
            .borderRadius(HomePage.INDICATOR_HEIGHT / 2)
            .backgroundColor(this.themeState.colors.textColorLink)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 2 })
      } else {

        Row()
          .width('100%')
          .height(HomePage.INDICATOR_HEIGHT)
          .margin({ top: 2 })
      }
    }
    .width('100%')
    .height(HomePage.TAB_BAR_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(index);
    })
  }

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabsController
      }) {
        TabContent() {
          ConversationsPage({
            onConversationClick: (item: ConversationInfo) => {
              this.handleConversationClick(item);
            }
          })
        }.tabBar(this.TabBuilder(HomePage.TAB_MESSAGE))

        TabContent() {
          ContactsPage({
            contactListStore: this.contactListStore,
            onContactClick: (contact: ContactInfo) => {
              this.handleContactClick(contact);
            },
            onGroupClick: (group: ContactInfo) => {
              this.handleGroupClick(group);
            },
            onNewFriendsClick: () => {
              console.info('[HomePage] New friends clicked');
              this.showNewContactsDialog();
            },
            onGroupApplicationsClick: () => {
              console.info('[HomePage] Group applications clicked');
              this.showNewGroupsDialog();
            },
            onGroupListClick: () => {
              console.info('[HomePage] Group list clicked');
              this.showMyGroupDialog();
            },
            onBlackListClick: () => {
              console.info('[HomePage] Blacklist clicked');
              this.showBlackListDialog();
            }
          })
        }.tabBar(this.TabBuilder(HomePage.TAB_CONTACT))

        TabContent() {
          SettingsPage()
        }.tabBar(this.TabBuilder(HomePage.TAB_PROFILE))
      }
      .barHeight(HomePage.TAB_BAR_HEIGHT)
      .barMode(BarMode.Fixed)
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
    }
    .width('100%')
    .height('100%')
  }

  updateTabBadge(tabIndex: number, badgeCount: number) {
    const tabItem = this.getTabItem(tabIndex);
    if (tabItem) {
      tabItem.badgeCount = badgeCount;

      this.tabItems = [...this.tabItems];

    }
  }

  private initContactBadge() {
    this.contactListStore.fetchFriendApplicationList()
      .then(() => {
        this.contactListStore.fetchGroupApplicationList().then(() => {
          this.updateTabBadge(HomePage.TAB_CONTACT,
            this.contactListState.friendApplicationUnreadCount + this.contactListState.groupApplicationUnreadCount);
        })
      })
      .catch((error: Error) => {

      });
  }

  private getTabItem(index: number): TabItem {
    for (let i = 0; i < this.tabItems.length; i++) {
      if (this.tabItems[i].index === index) {
        return this.tabItems[i];
      }
    }
    return this.tabItems[0];
  }

  private handleConversationClick(item: ConversationInfo): void {
    console.info(`[HomePage] Conversation clicked: ${item.ID}`);
    this.showChatDialog(item.ID, item.title || 'Chat', item.avatarURL);
  }

  private handleContactClick(contact: ContactInfo): void {
    console.info(`[HomePage] Contact clicked: ${contact.contactID}`);
    if (contact.contactID) {
      this.showChatDialog(
        `c2c_${contact.contactID}`,
        contact.title || contact.contactID,
        contact.avatarURL
      );
    }
  }

  private handleGroupClick(group: ContactInfo): void {
    console.info(`[HomePage] Group clicked: ${group.contactID}`);
    if (group.contactID) {
      this.showChatDialog(
        `group_${group.contactID}`,
        group.title || group.contactID,
        group.avatarURL
      );
    }
  }

  private showChatDialog(conversationID: string, title: string, avatarUrl?: string, locateMessage?: MessageInfo): void {
    try {
      if (this.chatDialogController) {
        this.chatDialogController.close();
        this.chatDialogController = undefined;
      }

      this.chatDialogController = new CustomDialogController({
        builder: ChatDialog({
          conversationID: conversationID,
          title: title,
          avatarUrl: avatarUrl || '',
          status: '',
          locateMessage: locateMessage,
          onBack: () => {
            console.log('[HomePage] Chat back button clicked');
          },
          onUserClick: (userID: string) => {
            console.log('[HomePage] User clicked in message list:', userID);
            this.handleUserClick(userID);
          },
          onChatHeaderClick: (clickedConversationID: string) => {
            console.log('[HomePage] Chat header clicked:', clickedConversationID);
            this.handleChatHeaderClick(clickedConversationID);
          }
        }),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.chatDialogController = undefined;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal,
          onFinish: () => {
            // Animation finished
          }
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal,
          onFinish: () => {
            // Animation finished
          }
        }
      });

      this.chatDialogController.open();
    } catch (error) {
      console.error('[HomePage] showChatDialog error:', error);
    }
  }

  private handleUserClick(userID: string): void {
    console.info(`[HomePage] Handle user click: ${userID}`);
    // Show user profile based on friendship status
    this.userInteractionHelper.showUserProfileByFriendship(
      userID,
      this.getUIContext(),
      (newConversationID?: string, title?: string, avatarUrl?: string) => {
        if (newConversationID) {
          this.showChatDialog(newConversationID, title || 'Chat', avatarUrl);
        }
      },
      () => {
        console.log('[HomePage] Contact deleted from user interaction');
        if (this.chatDialogController) {
          this.chatDialogController.close();
          this.chatDialogController = undefined;
        }
      }
    );
  }

  private handleChatHeaderClick(conversationID: string): void {
    console.info(`[HomePage] Handle chat header click: ${conversationID}`);
    const isGroupChat = conversationID.startsWith('group_');
    
    if (isGroupChat) {
      // Show group setting dialog
      const groupID = conversationID.replace('group_', '');
      this.showGroupSettingDialog(groupID);
    } else {
      // Show C2C user profile
      const userID = conversationID.replace('c2c_', '');
      this.userInteractionHelper.showUserProfileByFriendship(
        userID,
        this.getUIContext(),
        (newConversationID?: string, title?: string, avatarUrl?: string) => {
          if (newConversationID) {
            this.showChatDialog(newConversationID, title || 'Chat', avatarUrl);
          }
        },
        () => {
          console.log('[HomePage] Contact deleted from chat header');
          if (this.chatDialogController) {
            this.chatDialogController.close();
            this.chatDialogController = undefined;
          }
        }
      );
    }
  }

  private showGroupSettingDialog(groupID: string): void {
    try {
      if (this.groupSettingDialogController) {
        this.groupSettingDialogController.close();
        this.groupSettingDialogController = undefined;
      }

      if (!groupID || groupID.length === 0) {
        return;
      }

      this.groupSettingDialogController = new CustomDialogController({
        builder: GroupSettingDialog({
          groupID: groupID,
          onSendMessageClick: (newConversationID?: string, title?: string, avatarUrl?: string) => {
            if (newConversationID) {
              this.showChatDialog(newConversationID, title || 'Chat', avatarUrl);
            }
          },
          onGroupDelete: () => {
            console.log('[HomePage] Group deleted, closing dialogs');
            // Close the group setting dialog first
            if (this.groupSettingDialogController) {
              this.groupSettingDialogController.close();
              this.groupSettingDialogController = undefined;
            }
            // Then close the chat dialog
            if (this.chatDialogController) {
              this.chatDialogController.close();
              this.chatDialogController = undefined;
            }
          }
        }),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.groupSettingDialogController = undefined;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal,
          onFinish: () => {
            // Animation finished
          }
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal,
          onFinish: () => {
            // Animation finished
          }
        }
      });

      this.groupSettingDialogController.open();
    } catch (error) {
      console.error('[HomePage] showGroupSettingDialog error:', error);
    }
  }

  @Builder
  NewContactsDialogBuilder() {
    Column() {
      FriendApplicationListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.newContactsDialogController?.close();
          this.newContactsDialogController = undefined;
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
  NewGroupsDialogBuilder() {
    Column() {
      GroupApplicationListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.newGroupsDialogController?.close();
          this.newGroupsDialogController = undefined;
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
  MyGroupDialogBuilder() {
    Column() {
      GroupListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.myGroupDialogController?.close();
          this.myGroupDialogController = undefined;
        },
        onShowProfile: (group: ContactInfo) => {
          console.log('[HomePage] Selected group:', group.title);
          this.myGroupDialogController?.close();
          this.myGroupDialogController = undefined;
          // Navigate to group chat
          this.handleGroupClick(group);
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
        contactListStore: this.contactListStore,
        onBack: () => {
          this.blackListDialogController?.close();
          this.blackListDialogController = undefined;
        },
        onShowProfile: (item: ContactInfo) => {
          this.blackListDialogController?.close();
          this.blackListDialogController = undefined;
          // Navigate to contact chat
          this.handleContactClick(item);
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

  // Generic method to show contact management dialogs
  private showContactManagementDialog(
    type: 'newContacts' | 'newGroups' | 'myGroups' | 'blackList'
  ): void {
    try {
      // Get the corresponding controller and builder
      let controller: CustomDialogController | undefined;
      let builder: () => void;
      let controllerSetter: (ctrl: CustomDialogController | undefined) => void;
      let errorName: string;

      switch (type) {
        case 'newContacts':
          controller = this.newContactsDialogController;
          builder = this.NewContactsDialogBuilder.bind(this);
          controllerSetter = (ctrl) => { this.newContactsDialogController = ctrl; };
          errorName = 'showNewContactsDialog';
          break;
        case 'newGroups':
          controller = this.newGroupsDialogController;
          builder = this.NewGroupsDialogBuilder.bind(this);
          controllerSetter = (ctrl) => { this.newGroupsDialogController = ctrl; };
          errorName = 'showNewGroupsDialog';
          break;
        case 'myGroups':
          controller = this.myGroupDialogController;
          builder = this.MyGroupDialogBuilder.bind(this);
          controllerSetter = (ctrl) => { this.myGroupDialogController = ctrl; };
          errorName = 'showMyGroupDialog';
          break;
        case 'blackList':
          controller = this.blackListDialogController;
          builder = this.BlackListDialogBuilder.bind(this);
          controllerSetter = (ctrl) => { this.blackListDialogController = ctrl; };
          errorName = 'showBlackListDialog';
          break;
      }

      // Close existing dialog if open
      if (controller) {
        controller.close();
        controllerSetter(undefined);
      }

      // Set animation offset
      this.dialogAnimationOffset = 100;

      // Create new dialog controller
      const newController = new CustomDialogController({
        builder: builder,
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          controllerSetter(undefined);
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal,
          onFinish: () => {
            // Animation finished
          }
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal,
          onFinish: () => {
            // Animation finished
          }
        }
      });

      controllerSetter(newController);
      newController.open();
    } catch (error) {
      console.error(`[HomePage] showContactManagementDialog(${type}) error:`, error);
    }
  }

  private showNewContactsDialog(): void {
    this.showContactManagementDialog('newContacts');
  }

  private showNewGroupsDialog(): void {
    this.showContactManagementDialog('newGroups');
  }

  private showMyGroupDialog(): void {
    this.showContactManagementDialog('myGroups');
  }

  private showBlackListDialog(): void {
    this.showContactManagementDialog('blackList');
  }
}