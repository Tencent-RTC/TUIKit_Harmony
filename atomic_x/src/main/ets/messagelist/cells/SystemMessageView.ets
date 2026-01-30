import { MessageInfo, MessageStatus } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MessageBody } from '@tencentcloud/atomicxcore';
import { MessageListStore } from '@tencentcloud/atomicxcore';
import { MessageUtils } from '../utils/MessageUtils';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct SystemMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;
  @StorageLink('themeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Row() {
      Text(this.formatSystemInfo(this.message?.messageBody))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorSecondary)
        .padding({
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        })
        .borderRadius(4)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 8 })
  }

  private formatSystemInfo(body?: MessageBody): string | Resource {
    if (!body || !body.systemMessage || body.systemMessage.length === 0) {
      return $r("app.string.message_tips_unsupport_custom");
    }
    return MessageUtils.getSystemInfoDisplayString(body.systemMessage[0]);
  }
}

@Builder
export function SystemMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    SystemMessageViewContent({
      message: context.message,
      messageBody: context.message.messageBody
    })
  }
} 