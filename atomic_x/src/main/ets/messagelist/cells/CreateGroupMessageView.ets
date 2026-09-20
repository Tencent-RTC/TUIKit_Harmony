import { MessageInfo } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';
import { MessageUtils } from '../utils/MessageUtils';

@Component
export struct CreateGroupMessageViewContent {
  @State message?: MessageInfo = undefined;
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

  private getCreateText(): string | Resource {
    return MessageUtils.getCreateGroupDisplayString(this.message);
  }
}

@Builder
export function CreateGroupMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    CreateGroupMessageViewContent({ message: context.message })
  }
}