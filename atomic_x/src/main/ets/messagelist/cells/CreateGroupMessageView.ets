import { MessageInfo, MessageStatus } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MessageBody, MessageListStore } from '@tencentcloud/atomicxcore';
import { util } from '@kit.ArkTS';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct CreateGroupMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;
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
    this.message.sender?.userID ||
      '';

    return displayName;
  }

  private isCommunity(): boolean {
    const data = this.message?.messageBody?.customMessage?.data;
    const customInfo = undefined;
    if (data) {
      const textDecoder = new util.TextDecoder('utf-8');
      const dataStr = textDecoder.decode(new Uint8Array(data));
      let customInfo: Record<string, string | number | boolean | object> | undefined;
      try {
        customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
      } catch (error) {
        return false;
      }
      return customInfo?.["cmd"] === 1;
    }
    return false;
  }

  private getCreateText(): Resource {
    const senderName = this.getSenderDisplayName();
    return this.isCommunity() ? $r('app.string.community_create_tips_format',senderName):$r('app.string.group_create_tips_format',senderName)
  }
}

@Builder
export function CreateGroupMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    CreateGroupMessageViewContent({
      message: context.message,
      messageBody: context.message.messageBody
    })
  }
} 