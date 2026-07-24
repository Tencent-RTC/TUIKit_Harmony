import { MessageInfo, CustomMessagePayload } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct CreateGroupMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: CustomMessagePayload;
  @StorageLink('themeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Text(this.getCreateText())
      .fontSize(14)
      .fontColor(this.themeState.colors.textColorSecondary)
      .fontWeight(400)
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
  }

  private getSenderDisplayName(): string {
    if (!this.message) {
      return '';
    }
    const displayName = this.message.rawMessage?.nickName ||
      this.message.rawMessage?.sender ||
      this.message.from?.userID ||
      '';
    return displayName;
  }

  private isCommunity(): boolean {
    const dataStr = this.messagePayload?.customData;
    if (!dataStr) {
      return false;
    }
    try {
      const customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
      return customInfo?.['cmd'] === 1;
    } catch (error) {
      return false;
    }
  }

  private getCreateText(): Resource {
    const senderName = this.getSenderDisplayName();
    return this.isCommunity() ?
      $r('app.string.community_create_tips_format', senderName) :
      $r('app.string.group_create_tips_format', senderName);
  }
}

@Builder
export function CreateGroupMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    CreateGroupMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as CustomMessagePayload
    })
  }
}