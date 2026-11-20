import { ConversationInfo, MessageInfo } from '@tencentcloud/atomicxcore'
import { ChatPage, ConversationsPage } from 'chatuikit'
import { GroupSettingDialog, NotifyParams, ThemeMode, ThemeState, TUIEventBus, TUIObserver,
  UserInteractionHelper, UserInteractionResult } from '@tencentcloud/atomicx'
import { ImmersiveMode, LevelMode, promptAction } from '@kit.ArkUI'

class ChatRoute {
  conversation: ConversationInfo
  message?: MessageInfo
  constructor(conversation: ConversationInfo, message?: MessageInfo) {
    this.conversation = conversation
    this.message = message
  }
}

class CallPlaceholderObserver implements TUIObserver {
  onNotify(event: string, key: string | null, params: NotifyParams | null): void {
    promptAction.showToast({ message: $r('app.string.app_placeholder') })
  }
}

@Component
export struct HomeMessagesView {
  onFullscreen: (fullscreen: boolean) => void = () => {}
  onBackReady: (handler: (() => boolean) | undefined) => void = () => {}
  private stack: NavPathStack = new NavPathStack()
  private helper: UserInteractionHelper = new UserInteractionHelper()
  private observer: CallPlaceholderObserver = new CallPlaceholderObserver()
  private groupDialog?: CustomDialogController
  private alive: boolean = false
  private profileRequest: number = 0

  aboutToAppear(): void {
    this.alive = true
    ThemeState.getInstance().setThemeMode(ThemeMode.light)
    TUIEventBus.getInstance().subscribe('call.startCall', null, this.observer)
    TUIEventBus.getInstance().subscribe('call.startJoin', null, this.observer)
    this.onBackReady(() => {
      if (this.stack.size() > 0) { this.goBack(); return true }
      return false
    })
  }

  aboutToDisappear(): void {
    this.alive = false
    this.profileRequest++
    UserInteractionHelper.closeDialog()
    this.groupDialog?.close()
    this.groupDialog = undefined
    TUIEventBus.getInstance().unsubscribe('call.startCall', null, this.observer)
    TUIEventBus.getInstance().unsubscribe('call.startJoin', null, this.observer)
    this.onBackReady(undefined)
  }

  private open(info: ConversationInfo, message?: MessageInfo): void {
    if (!this.alive || info.conversationID.length === 0) { return }
    const top = this.stack.size() > 0 ? this.stack.getParamByIndex(this.stack.size() - 1) as ChatRoute : undefined
    if (top?.conversation.conversationID === info.conversationID && message === undefined) { return }
    this.stack.pushPath({ name: 'chat', param: new ChatRoute(info, message) })
    this.onFullscreen(true)
  }

  private openID(id: string, title: string = '', avatar: string = ''): void {
    const info = new ConversationInfo()
    info.conversationID = id
    info.title = title || id
    info.avatarURL = avatar
    this.open(info)
  }

  private goBack(): void {
    if (!this.alive) { return }
    this.stack.pop()
    this.profileRequest++
    this.onFullscreen(this.stack.size() > 0)
  }

  private showUser(userID: string): void {
    const request = ++this.profileRequest
    this.helper.getUserInteractionInfo(userID).then((result: UserInteractionResult) => {
      if (!this.alive || request !== this.profileRequest) { return }
      UserInteractionHelper.setUIContext(this.getUIContext())
      if (result.isFriend) {
        UserInteractionHelper.showC2CSettingDialog(userID, (id?: string, title?: string, avatar?: string) => {
          if (id !== undefined) { this.openID(id, title, avatar) }
        }, () => { if (this.alive) { this.stack.clear(); this.onFullscreen(false) } })
      } else if (result.userInfo !== undefined) {
        UserInteractionHelper.showContactDetailDialog(result.userInfo)
      }
    }).catch((error: Error) => {
      if (this.alive && request === this.profileRequest) { promptAction.showToast({ message: error.message }) }
    })
  }

  private settings(conversationID: string): void {
    if (!conversationID.startsWith('group_')) {
      this.showUser(conversationID.replace(/^c2c_/, ''))
      return
    }
    this.groupDialog?.close()
    this.groupDialog = new CustomDialogController({
      builder: GroupSettingDialog({ groupID: conversationID.substring(6),
        onSendMessageClick: (id?: string, title?: string, avatar?: string) => {
          if (id !== undefined) { this.openID(id, title, avatar) }
        }, onGroupDelete: () => {
          if (!this.alive) { return }
          this.groupDialog?.close()
          this.groupDialog = undefined
          this.stack.clear()
          this.onFullscreen(false)
        } }),
      autoCancel: false, customStyle: true, maskColor: Color.Transparent,
      alignment: DialogAlignment.Center, levelMode: LevelMode.EMBEDDED, immersiveMode: ImmersiveMode.EXTEND,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
    })
    this.groupDialog.open()
  }

  @Builder chatDestination(route: ChatRoute) {
    NavDestination() {
      ChatPage({ conversationID: route.conversation.conversationID, title: route.conversation.title ?? '',
        avatarUrl: route.conversation.avatarURL ?? '', locateMessage: route.message, enableCalls: false,
        onBack: () => this.goBack(), onUserClick: (userID: string) => this.showUser(userID),
        onChatHeaderClick: (id: string) => this.settings(id) })
    }.hideTitleBar(true).onShown(() => this.onFullscreen(true))
      .onHidden(() => { if (this.alive && this.stack.size() === 0) { this.onFullscreen(false) } })
      .onBackPressed(() => { this.goBack(); return true })
  }

  @Builder destination(name: string, parameter: Object) { this.chatDestination(parameter as ChatRoute) }

  build() {
    Navigation(this.stack) {
      ConversationsPage({ onConversationClick: (info: ConversationInfo) => this.open(info),
        onConversationClickWithMessage: (info: ConversationInfo, message?: MessageInfo) => this.open(info, message) })
    }.hideTitleBar(true).mode(NavigationMode.Stack).navDestination(this.destination)
      .width('100%').height('100%').backgroundColor(Color.White)
  }
}
