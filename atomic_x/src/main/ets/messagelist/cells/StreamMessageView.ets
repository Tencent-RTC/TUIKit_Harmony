import { MessageInfo, StreamMessagePayload } from '@tencentcloud/atomicxcore';
import { display } from '@kit.ArkUI';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import { LanguageState, ThemeState } from '../../basecomponent/Index';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct StreamMessageViewContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: StreamMessagePayload;
  @Prop config?: MessageListStyleProtocol = undefined;
  @State private markdownText: string = '';
  @State private bubbleMaxWidth: number = 240;
  private markdownController: MarkdownController = new MarkdownController();

  aboutToAppear(): void {
    this.updateMarkdownText();
    this.configureMarkdownController();
    this.updateBubbleMaxWidth();
  }

  aboutToUpdate(): void {
    this.updateMarkdownText();
    this.configureMarkdownController();
    this.updateBubbleMaxWidth();
  }

  build() {
    Column() {
      Markdown({
        controller: this.markdownController,
        text: this.markdownText,
        mode: 'text'
      })
        .width('100%')
        .constraintSize({ minWidth: 0, maxWidth: Math.max(0, this.bubbleMaxWidth - 24) })
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
    }
    .constraintSize({ minWidth: 0, maxWidth: this.bubbleMaxWidth })
    .padding({
      left: 12,
      right: 12,
      top: 10,
      bottom: 10
    })
  }

  private resolveBubbleMaxWidth(): number {
    let screenWidth = 360;
    try {
      screenWidth = px2vp(display.getDefaultDisplaySync().width);
    } catch (error) {
    }
    const horizontalPadding = this.config?.horizontalPadding ?? 16;
    const avatarSpacing = this.config?.avatarSpacing ?? 8;
    const hasAvatar = (this.config?.isShowLeftAvatar ?? true) || (this.config?.isShowRightAvatar ?? true);
    const avatarArea = hasAvatar ? 40 + avatarSpacing : 0;
    const maxRowWidth = Math.max(0, screenWidth - horizontalPadding * 2 - avatarArea);
    const preferredBubbleMaxWidth = screenWidth * 0.72 + (hasAvatar ? 0 : 40 + avatarSpacing);
    return Math.min(maxRowWidth, preferredBubbleMaxWidth);
  }

  private updateBubbleMaxWidth(): void {
    const nextWidth = this.resolveBubbleMaxWidth();
    if (nextWidth !== this.bubbleMaxWidth) {
      this.bubbleMaxWidth = nextWidth;
    }
  }

  private configureMarkdownController(): void {
    const textColor = this.message?.isSentBySelf ?
      this.themeState.colors.textColorAntiPrimary :
      this.themeState.colors.textColorPrimary;
    this.markdownController.setTextColor(textColor)
      .setTextSize(16)
      .setTextLineHeight(24)
      .setHyperlinkTextColor(this.message?.isSentBySelf ? textColor : this.themeState.colors.textColorLink)
      .setHyperlinkUnderlineState(true)
      .setTextSelectionEnable(false)
      .setCodeBlockActionAreaVisible(false);
  }

  private updateMarkdownText(): void {
    this.markdownText = this.messagePayload?.markdown ?? '';
  }
}

@Builder
export function StreamMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    StreamMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as StreamMessagePayload,
      config: context.config
    })
  }
}
