import { ProfileDetailPage, SettingsPage } from './SettingsPage'
import { ContactsPage, ChatNavDestination, ChatDestinationParams, AIAssistantPageView } from 'chatuikit'
import { AlertDialog as AtomicAlertDialog, ImageSizeUtil,ThemeState, BadgeControl, BadgeType, Toast, AtomicxNavigator, AtomicxPageParams, ATOMICX_PAGE_ROUTE } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { UserInteractionHelper, GroupChatSetting, C2CChatSetting, GroupMemberListPage, GroupManagementView, GroupAnnouncementView } from '@tencentcloud/atomicx/src/main/ets/chatsetting/Index';
import { BlackListView, GroupListView, FriendApplicationListView, GroupApplicationListView } from '@tencentcloud/atomicx/src/main/ets/contactlist/Index';
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
import { UIContext } from '@ohos.arkui.UIContext'
import { promptAction, router } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import { setNotificationClickCallback, clearNotificationClickCallback } from '../push/TIMPushInterfaces';
import { TUICallKit, CallMediaType as CallKitMediaType, CallParams as CallKitParams } from '@tencentcloud/tuicallkit';
import { PublishParams, TUIEventBus, TUIObserver, NotifyParams } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index'
import { CompletionHandlerAdapter } from '@tencentcloud/atomicx/src/main/ets/basecomponent/utils/CompletionHandlers'
import { CallMediaType } from '@tencentcloud/atomicx/src/main/ets/call/common/CallStore'
import { MessageInputActionIDs } from '@tencentcloud/atomicx/src/main/ets/messageinput/Index'
import { CallMessageClickContext, ChatMessageListConfig } from '@tencentcloud/atomicx/src/main/ets/messagelist/Index'
import { ChatbotConversationControllers, ChatbotConversationPolicy } from '@tencentcloud/atomicx/src/main/ets/chatbot/Index'
import { AIAssistantAgent, AIAssistantControlMessages, AIAssistantHandoffStatus } from '@tencentcloud/atomicx/src/main/ets/aiassistant/Index'
import { MessageInputCallRedDotStore } from '../utils/MessageInputCallRedDotStore'
import { SupportAgentCatalog } from '../ai/SupportAgentCatalog'
import { ChatTitleResolver } from '../chat/ChatTitleResolver'

interface GroupSettingRouteParams {
  groupID: string;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onGroupDelete?: () => void;
}

interface C2CSettingRouteParams {
  userID: string;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onContactDelete?: () => void;
}

interface GroupMemberListRouteParams {
  groupID: string;
  groupName: string;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
}

interface GroupManagementRouteParams {
  groupID: string;
}

interface GroupAnnouncementRouteParams {
  groupID: string;
  onSave?: (announcement: string) => void;
}

interface ContactManagementRouteParams {
  onShowProfile?: (item: ContactInfo) => void;
}

interface ProfileDetailRouteParams {
  onProfileUpdated?: () => void;
}

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
  private static readonly TAB_AI: number = 0;
  private static readonly TAB_MESSAGE: number = 1;
  private static readonly TAB_CONTACT: number = 2;
  private static readonly TAB_PROFILE: number = 3;
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
  private pathStack: NavPathStack = new NavPathStack();
  private userInteractionHelper: UserInteractionHelper = new UserInteractionHelper();
  private unsubscribeLoginEvent?: () => void;
  private callEventObserver?: TUIObserver;
  private isCheckingHandoffStatus: boolean = false;

  aboutToAppear() {
    AtomicxNavigator.bind(this.pathStack);
    this.tabItems = [
      new TabItem(
        HomePage.TAB_AI,
        $r("app.string.demo_tab_ai"),
        $r('app.media.tab_ai'),
        $r('app.media.tab_ai'),
        0
      ),
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
    AtomicxNavigator.unbind(this.pathStack);
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
    
    this.pathStack.clear();

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
    
    this.pathStack.clear();

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

  private handleAtomicxPageBack(params: AtomicxPageParams): boolean {
    if (params.onBackPressed && params.onBackPressed()) {
      return true;
    }
    this.pathStack.pop();
    return true;
  }

  @Builder
  pageMap(name: string, params: Object) {
    if (name === ATOMICX_PAGE_ROUTE) {
      NavDestination() {
        (params as AtomicxPageParams).builder.builder((params as AtomicxPageParams).args)
      }
      .hideTitleBar(true)
      .onBackPressed(() => this.handleAtomicxPageBack(params as AtomicxPageParams))
    } else if (name === 'chat') {
      ChatNavDestination({
        params: params as ChatDestinationParams,
        pathStack: this.pathStack
      })
    } else if (name === 'groupSetting') {
      NavDestination() {
        GroupChatSetting({
          groupID: (params as GroupSettingRouteParams).groupID,
          navPathStack: this.pathStack,
          onClose: () => {
            this.pathStack.pop();
          },
          onSendMessageClick: (params as GroupSettingRouteParams).onSendMessageClick,
          onGroupDelete: (params as GroupSettingRouteParams).onGroupDelete
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'groupMemberList') {
      NavDestination() {
        GroupMemberListPage({
          groupID: (params as GroupMemberListRouteParams).groupID,
          groupName: (params as GroupMemberListRouteParams).groupName,
          onSendMessageClick: (params as GroupMemberListRouteParams).onSendMessageClick,
          onBack: () => {
            this.pathStack.pop();
          }
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'groupManagement') {
      NavDestination() {
        GroupManagementView({
          groupID: (params as GroupManagementRouteParams).groupID,
          onBack: () => {
            this.pathStack.pop();
          }
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'groupAnnouncement') {
      NavDestination() {
        GroupAnnouncementView({
          groupID: (params as GroupAnnouncementRouteParams).groupID,
          onBack: () => {
            this.pathStack.pop();
          },
          onSave: (params as GroupAnnouncementRouteParams).onSave
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'friendApplications') {
      NavDestination() {
        FriendApplicationListView({
          contactStore: this.contactStore,
          onBack: () => {
            this.pathStack.pop();
          }
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'groupApplications') {
      NavDestination() {
        GroupApplicationListView({
          groupStore: this.groupStore,
          onBack: () => {
            this.pathStack.pop();
          }
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'myGroups') {
      NavDestination() {
        GroupListView({
          groupStore: this.groupStore,
          onBack: () => {
            this.pathStack.pop();
          },
          onShowProfile: (params as ContactManagementRouteParams).onShowProfile
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'blackList') {
      NavDestination() {
        BlackListView({
          contactStore: this.contactStore,
          onBack: () => {
            this.pathStack.pop();
          },
          onShowProfile: (params as ContactManagementRouteParams).onShowProfile
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'profileDetail') {
      NavDestination() {
        ProfileDetailPage({
          onClose: () => {
            this.pathStack.pop();
          },
          onProfileUpdated: (params as ProfileDetailRouteParams).onProfileUpdated
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    } else if (name === 'c2cSetting') {
      NavDestination() {
        C2CChatSetting({
          userID: (params as C2CSettingRouteParams).userID,
          onClose: () => {
            this.pathStack.pop();
          },
          onSendMessageClick: (params as C2CSettingRouteParams).onSendMessageClick,
          onContactDelete: (params as C2CSettingRouteParams).onContactDelete
        })
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.pathStack.pop();
        return true;
      })
    }
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
        Tabs({
        barPosition: BarPosition.End,
        controller: this.tabsController
      }) {
        TabContent() {
          AIAssistantPageView({
            agentLoader: (onResult: (agents: AIAssistantAgent[]) => void) => {
              SupportAgentCatalog.fetch(onResult);
            },
            handoffStatusLoader: (onResult: (status: AIAssistantHandoffStatus) => void) => {
              SupportAgentCatalog.fetchHandoffStatus(onResult);
            },
            isPageVisible: this.currentIndex === HomePage.TAB_AI
          })
        }.tabBar(this.TabBuilder(HomePage.TAB_AI))

        TabContent() {
          ConversationsPage({
            onConversationClick: (item: ConversationInfo) => {
              this.handleConversationClick(item);
            },
            onConversationClickWithMessage: (item: ConversationInfo, locateMessage?: MessageInfo) => {
              this.showChatDialog(item.conversationID, item.title ?? '', item.avatarURL, locateMessage);
            }
          })
        }.tabBar(this.TabBuilder(HomePage.TAB_MESSAGE))

        TabContent() {
          ContactsPage({
            contactStore: this.contactStore,
            groupStore: this.groupStore,
            navPathStack: this.pathStack,
            onContactClick: (contact: ContactInfo) => {
              this.handleContactClick(contact);
            },
            onGroupClick: (group: ContactInfo) => {
              this.handleGroupClick(group);
            }
          })
        }.tabBar(this.TabBuilder(HomePage.TAB_CONTACT))

        TabContent() {
          SettingsPage({
            navPathStack: this.pathStack
          })
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
    .hideTitleBar(true)
    .hideToolBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.pageMap)
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
    this.showChatDialog(item.conversationID, item.title ?? '', item.avatarURL);
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
    const params: ChatDestinationParams = {
      conversationID: conversationID,
      title: ChatTitleResolver.resolve(title, conversationID),
      headerActionIcon: ChatbotConversationPolicy.isChatbotConversation(conversationID) ?
        $rawfile('aiassistant/ic_clear_history.svg') : undefined,
      avatarUrl: avatarUrl || '',
      status: '',
      locateMessage: locateMessage,
      messageListConfig: this.createChatMessageListConfig(conversationID),
      moreActionRedDotIDs: MessageInputCallRedDotStore.pendingActionIDs(
        LoginStore.shared().sdkAppID,
        [MessageInputActionIDs.VIDEO_CALL, MessageInputActionIDs.AUDIO_CALL]
      ),
      onMoreActionRedDotTap: (actionID: string) => {
        MessageInputCallRedDotStore.markClicked(LoginStore.shared().sdkAppID, actionID);
      },
      onUserClick: (userID: string) => {
        console.log('[HomePage] User clicked in message list:', userID);
        this.handleUserClick(userID);
      },
      onChatHeaderClick: (clickedConversationID: string, uiContext: UIContext) => {
        console.log('[HomePage] Chat header clicked:', clickedConversationID);
        this.handleChatHeaderClick(clickedConversationID, uiContext);
      },
      onSecurityReportClick: () => {
        console.log('[HomePage] Security report clicked');
        const context = getContext(this) as common.UIAbilityContext;
        const wantInfo: Want = {
          action: 'ohos.want.action.viewData',
          entities: ['entity.system.browsable'],
          uri: 'https://cloud.tencent.com/act/event/report-platform'
        };
        context.startAbility(wantInfo);
      }
    };

    while (this.pathStack.size() > 0) {
      this.pathStack.pop(false);
    }
    this.pathStack.pushPathByName('chat', params, true);
  }

  private createChatMessageListConfig(conversationID: string): ChatMessageListConfig {
    const isChatbotConversation = ChatbotConversationPolicy.isChatbotConversation(conversationID);
    const config = new ChatMessageListConfig().addMessageExclusion((message: MessageInfo): boolean => AIAssistantControlMessages.isControlMessage(message));
    if (isChatbotConversation) {
      config.setCallMessageClickListener((clickContext: CallMessageClickContext): boolean => {
        this.handleChatbotCallMessageClick(clickContext);
        return true;
      });
    }
    return config;
  }

  private handleChatbotCallMessageClick(clickContext: CallMessageClickContext): void {
    if (this.isCheckingHandoffStatus) {
      return;
    }
    this.isCheckingHandoffStatus = true;
    SupportAgentCatalog.fetchHandoffStatus((status: AIAssistantHandoffStatus) => {
      this.isCheckingHandoffStatus = false;
      if (this.pathStack.size() === 0) {
        return;
      }
      if (status.isSeatCallable) {
        clickContext.startCall(status.seatImUserId);
      } else if (status.isWaitingForSeat) {
        Toast.info($r('app.string.uikit_ai_call_handoff_waiting'), this.getUIContext());
      } else {
        Toast.info($r('app.string.uikit_ai_call_handoff_required'), this.getUIContext());
      }
    });
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
        this.pathStack.clear();
      },
      (clickedUserID: string) => {
        this.showC2CSettingPage(clickedUserID);
      }
    );
  }

  private handleChatHeaderClick(conversationID: string, uiContext?: UIContext): void {
    if (ChatbotConversationPolicy.isChatbotConversation(conversationID)) {
      this.showClearChatHistoryConfirmation(conversationID, uiContext);
      return;
    }
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
        uiContext ?? this.getUIContext(),
        (newConversationID?: string, title?: string, avatarUrl?: string) => {
          if (newConversationID) {
            this.showChatDialog(newConversationID, title || 'Chat', avatarUrl);
          }
        },
        () => {
          console.log('[HomePage] Contact deleted from chat header');
          this.pathStack.clear();
        },
        (clickedUserID: string) => {
          this.showC2CSettingPage(clickedUserID);
        }
      );
    }
  }

  private showClearChatHistoryConfirmation(conversationID: string, uiContext?: UIContext): void {
    const context = uiContext ?? this.getUIContext();
    if (ChatbotConversationControllers.isActive(conversationID)) {
      Toast.info($r('app.string.message_input_chatbot_waiting_tips'), context);
      return;
    }
    AtomicAlertDialog.show(
      undefined,
      $r('app.string.chatsetting_clear_contact_history_confirm'),
      $r('app.string.chatsetting_cancel_clear'),
      $r('app.string.chatsetting_confirm_clear'),
      undefined,
      undefined,
      () => {
        this.clearChatHistory(conversationID);
      },
      context,
      true
    );
  }

  private clearChatHistory(conversationID: string): void {
    if (ChatbotConversationControllers.isActive(conversationID)) {
      Toast.info($r('app.string.message_input_chatbot_waiting_tips'), this.getUIContext());
      return;
    }
    ConversationListStore.create().clearConversationMessages(conversationID, new CompletionHandlerAdapter(() => {
      ChatbotConversationControllers.clear(conversationID);
      const data: Record<string, Object> = {
        'conversationID': conversationID as Object,
      };
      TUIEventBus.getInstance().publish('chat.messageList.chatHistoryCleared', null, new PublishParams(false, data));
      Toast.success($r('app.string.chatsetting_clear_chat_success'), this.getUIContext());
    }, (_code: number, desc: string) => {
      Toast.error(desc.length > 0 ? desc : $r('app.string.chatsetting_clear_chat_fail'), this.getUIContext());
    }));
  }

  private showC2CSettingPage(userID: string): void {
    if (!userID || userID.length === 0) {
      return;
    }
    const params: C2CSettingRouteParams = {
      userID: userID,
      onSendMessageClick: (newConversationID?: string, title?: string, avatarUrl?: string) => {
        if (newConversationID) {
          this.showChatDialog(newConversationID, title || 'Chat', avatarUrl);
        }
      },
      onContactDelete: () => {
        this.pathStack.clear();
      }
    };
    this.pathStack.pushPathByName('c2cSetting', params, true);
  }

  private showGroupSettingDialog(groupID: string): void {
    if (!groupID || groupID.length === 0) {
      return;
    }
    const params: GroupSettingRouteParams = {
      groupID: groupID,
      onSendMessageClick: (newConversationID?: string, title?: string, avatarUrl?: string) => {
        if (newConversationID) {
          this.showChatDialog(newConversationID, title || 'Chat', avatarUrl);
        }
      },
      onGroupDelete: () => {
        console.log('[HomePage] Group deleted, closing pages');
        this.pathStack.clear();
      }
    };
    this.pathStack.pushPathByName('groupSetting', params, true);
  }
}