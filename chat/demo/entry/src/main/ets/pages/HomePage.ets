import { SettingsPage } from './SettingsPage'
import { ContactsPage, ChatDialog } from 'chatuikit'
import { ImageSizeUtil,ThemeState, BadgeControl, BadgeType } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { UserInteractionHelper, GroupSettingDialog } from '@tencentcloud/atomicx/src/main/ets/chatsetting/Index';
import { ConversationsPage } from 'chatuikit'
import {
  ContactInfo,
  ContactState,
  ContactStore
} from '@tencentcloud/atomicxcore'
import {
  ConversationInfo,
  ConversationListStore,
  ConversationListState
} from '@tencentcloud/atomicxcore'
import {
  GroupState,
  GroupStore
} from '@tencentcloud/atomicxcore'
import {
  LoginEvent,
  LoginStore
} from '@tencentcloud/atomicxcore'
import { MessageInfo } from '@tencentcloud/atomicxcore'
import { ImmersiveMode, LevelMode } from '@kit.ArkUI'
import { promptAction, router } from '@kit.ArkUI'
import { setNotificationClickCallback, clearNotificationClickCallback } from '../push/TIMPushInterfaces';
import { TUICallKit, CallMediaType as CallKitMediaType, CallParams as CallKitParams } from '@tencentcloud/tuicallkit';
import { TUIEventBus, TUIObserver, NotifyParams } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index'
import { CallMediaType } from '@tencentcloud/atomicx/src/main/ets/call/common/CallStore'

class CallStartObserver implements TUIObserver {
  onNotify(event: string, _key: string | null, params: NotifyParams | null): void {
    if (event === 'call.startCall' && params?.data) {
      const data = params.data;
      const participantIds: string[] = (data['participantIds'] as string[]) ?? [];
      const mediaType: CallMediaType = (data['mediaType'] as CallMediaType) ?? CallMediaType.audio;
      if (participantIds.length === 0) {
        return;
      }
      const callKitMediaType: CallKitMediaType =
        mediaType === CallMediaType.video ? CallKitMediaType.video : CallKitMediaType.audio;
      const chatGroupId: string = (data['chatGroupId'] as string) ?? '';
      const timeout: number = (data['timeout'] as number) ?? 30;
      let callParams: CallKitParams | undefined = undefined;
      if (chatGroupId.length > 0) {
        callParams = new CallKitParams('', timeout, '', chatGroupId);
      }
      TUICallKit.createInstance(getContext()).calls(participantIds, callKitMediaType, callParams);
    }
  }
}

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
  @State private contactStore: ContactStore = ContactStore.shared;
  @Watch('onApplicationUnreadCountChanged')
  @State private contactState: ContactState = this.contactStore.state as ContactState;
  @State private groupStore: GroupStore = GroupStore.shared;
  @Watch('onApplicationUnreadCountChanged')
  @State private groupState: GroupState = this.groupStore.state as GroupState;
  @State private conversationListStore: ConversationListStore = ConversationListStore.create();
  @Watch('onConversationUnreadCountChanged')
  @State private conversationListState: ConversationListState = this.conversationListStore.state;
  private chatDialogController?: CustomDialogController;
  private groupSettingDialogController?: CustomDialogController;
  private userInteractionHelper: UserInteractionHelper = new UserInteractionHelper();
  private unsubscribeLoginEvent?: () => void;
  private callEventObserver?: TUIObserver;

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

    this.initCallKit();
    this.initContactBadge();
    this.subscribeLoginEvent();
    this.registerPushNotificationCallback();
  }

  aboutToDisappear() {
    if (this.unsubscribeLoginEvent) {
      this.unsubscribeLoginEvent();
      this.unsubscribeLoginEvent = undefined;
    }
    clearNotificationClickCallback();
    if (this.callEventObserver) {
      TUIEventBus.getInstance().unsubscribe('call.startCall', null, this.callEventObserver);
    }
  }

  private initCallKit(): void {
    TUICallKit.createInstance(getContext())
    this.callEventObserver = new CallStartObserver();
    TUIEventBus.getInstance().subscribe('call.startCall', null, this.callEventObserver);
  }

  private registerPushNotificationCallback() {
    setNotificationClickCallback((conversationID: string, title: string, avatarUrl: string) => {
      console.info(`[HomePage] Push notification clicked, navigating to: ${conversationID}`);
      this.showChatDialog(conversationID, title, avatarUrl);
    });
  }

  private subscribeLoginEvent(): void {
    this.unsubscribeLoginEvent = LoginStore.shared().loginEventEmitter.subscribe(this, (event: LoginEvent) => {
      if (event === LoginEvent.KICKED_OFFLINE) {
        this.handleKickedOffline();
      } else if (event === LoginEvent.LOGIN_EXPIRED) {
        this.handleUserSigExpired();
      }
    });
    console.info('[HomePage] ✅ LoginEvent subscribed');
  }

  private handleKickedOffline() {
    console.warn('[HomePage] 🚫 Kicked offline - User logged in from another device');
    
    // Close all dialogs
    if (this.groupSettingDialogController) {
      this.groupSettingDialogController.close();
      this.groupSettingDialogController = undefined;
    }
    if (this.chatDialogController) {
      this.chatDialogController.close();
      this.chatDialogController = undefined;
    }

    // Show alert dialog
    AlertDialog.show({
      title: $r('app.string.kicked_offline_title'),
      message: $r('app.string.kicked_offline_message'),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      confirm: {
        value: $r('app.string.relogin_button'),
        action: () => {
          router.back();
        }
      }
    });
  }

  private handleUserSigExpired() {
    console.warn('[HomePage] ⏰ UserSig expired - Need to re-login');
    
    // Close all dialogs
    if (this.groupSettingDialogController) {
      this.groupSettingDialogController.close();
      this.groupSettingDialogController = undefined;
    }
    if (this.chatDialogController) {
      this.chatDialogController.close();
      this.chatDialogController = undefined;
    }

    // Show alert dialog
    AlertDialog.show({
      title: $r('app.string.login_expired_title'),
      message: $r('app.string.login_expired_message'),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      confirm: {
        value: $r('app.string.relogin_button'),
        action: () => {
          router.back();
        }
      }
    });
  }

  onApplicationUnreadCountChanged() {
    console.info(`HomePage.TAB_CONTACT: ${this.contactState.friendApplicationUnreadCount + this.groupState.unreadApplicationCount}，friendApplicationUnreadCount：${this.contactState.friendApplicationUnreadCount} groupApplicationUnreadCount：${this.groupState.unreadApplicationCount}`);
    this.updateTabBadge(HomePage.TAB_CONTACT,
      this.contactState.friendApplicationUnreadCount + this.groupState.unreadApplicationCount);
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
            },
            onConversationClickWithMessage: (item: ConversationInfo, locateMessage?: MessageInfo) => {
              this.showChatDialog(item.conversationID, item.title || 'Chat', item.avatarURL, locateMessage);
            }
          })
        }.tabBar(this.TabBuilder(HomePage.TAB_MESSAGE))

        TabContent() {
          ContactsPage({
            contactStore: this.contactStore,
            groupStore: this.groupStore,
            onContactClick: (contact: ContactInfo) => {
              this.handleContactClick(contact);
            },
            onGroupClick: (group: ContactInfo) => {
              this.handleGroupClick(group);
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
    this.contactStore.loadFriendApplications();
    this.groupStore.loadApplications();
    this.updateTabBadge(HomePage.TAB_CONTACT,
      this.contactState.friendApplicationUnreadCount + this.groupState.unreadApplicationCount);
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
    console.info(`[HomePage] Conversation clicked: ${item.conversationID}`);
    this.showChatDialog(item.conversationID, item.title || 'Chat', item.avatarURL);
  }

  private handleContactClick(contact: ContactInfo): void {
    console.info(`[HomePage] Contact clicked: ${contact.userID}`);
    if (contact.userID) {
      this.showChatDialog(
        `c2c_${contact.userID}`,
        contact.friendRemark || contact.nickname || contact.userID,
        contact.avatarURL
      );
    }
  }

  private handleGroupClick(group: ContactInfo): void {
    console.info(`[HomePage] Group clicked: ${group.userID}`);
    if (group.userID) {
      this.showChatDialog(
        `group_${group.userID}`,
        group.nickname || group.userID,
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
          },

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
}