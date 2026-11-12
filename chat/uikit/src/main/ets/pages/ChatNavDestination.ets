import { MessageInfo } from '@tencentcloud/atomicxcore';
import { MessageListStyleProtocol } from '@tencentcloud/atomicx/src/main/ets/messagelist/Index';
import { MessageInputConfigProtocol } from '@tencentcloud/atomicx/src/main/ets/messageinput/Index';
import { KeyboardAvoidMode as UIContextKeyboardAvoidMode, UIContext } from '@ohos.arkui.UIContext';
import { ChatPage } from './ChatPage';

export interface ChatDestinationParams {
  conversationID: string;
  title: string;
  status?: string;
  avatarUrl?: string;
  locateMessage?: MessageInfo;
  headerActionIcon?: Resource;
  moreActionRedDotIDs?: string[];
  onMoreActionRedDotTap?: (actionID: string) => void;
  messageListConfig?: MessageListStyleProtocol;
  messageInputConfig?: MessageInputConfigProtocol;
  onUserClick?: (userID: string) => void;
  onChatHeaderClick?: (conversationID: string, uiContext: UIContext) => void;
  onSecurityReportClick?: () => void;
}

@Component
export struct ChatNavDestination {
  params: ChatDestinationParams = { conversationID: '', title: '' };
  pathStack: NavPathStack = new NavPathStack();
  private backHandler?: () => boolean;
  private previousKeyboardAvoidMode?: UIContextKeyboardAvoidMode;

  aboutToAppear(): void {
    this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode();
    this.getUIContext().setKeyboardAvoidMode(UIContextKeyboardAvoidMode.NONE);
  }

  aboutToDisappear(): void {
    if (this.previousKeyboardAvoidMode !== undefined) {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
      this.previousKeyboardAvoidMode = undefined;
    }
  }

  build() {
    NavDestination() {
      ChatPage({
        conversationID: this.params.conversationID,
        title: this.params.title,
        status: this.params.status ?? '',
        avatarUrl: this.params.avatarUrl ?? '',
        locateMessage: this.params.locateMessage,
        headerActionIcon: this.params.headerActionIcon,
        moreActionRedDotIDs: this.params.moreActionRedDotIDs,
        onMoreActionRedDotTap: this.params.onMoreActionRedDotTap,
        messageListConfig: this.params.messageListConfig,
        messageInputConfig: this.params.messageInputConfig,
        useUIContextFocus: true,
        onBack: () => {
          this.pathStack.pop();
        },
        onRegisterBackHandler: (handler: () => boolean): void => {
          this.backHandler = handler;
        },
        onUserClick: this.params.onUserClick,
        onChatHeaderClick: this.params.onChatHeaderClick,
        onSecurityReportClick: this.params.onSecurityReportClick
      })
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      if (this.backHandler && this.backHandler()) {
        return true;
      }
      this.pathStack.pop();
      return true;
    })
  }
}
