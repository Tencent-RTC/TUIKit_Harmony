import { MessageInfo, MessageStatus, TipsMessagePayload } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MessageUtils } from '../utils/MessageUtils';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct SystemMessageViewContent {
  @State message?: MessageInfo = undefined;
  @State messagePayload?: TipsMessagePayload = undefined;
  @StorageLink('themeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Row() {
      Text(this.formatSystemInfo())
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

  private formatSystemInfo(): string | Resource {
    if (this.message?.status === MessageStatus.REVOKED) {
      return MessageUtils.getRecallDisplayString(this.message);
    }
    const tipsList = this.messagePayload?.groupTips;
    if (!tipsList || tipsList.length === 0) {
      return $r('app.string.message_tips_unsupport_custom');
    }
    return MessageUtils.getSystemInfoDisplayString(tipsList[0]);
  }
}

@Builder
export function SystemMessageView(context: MessageRenderContext) {
  if (context.message && (context.message.messagePayload || context.message.status === MessageStatus.REVOKED)) {
    SystemMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as TipsMessagePayload
    })
  }
}
