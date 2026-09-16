import { CustomMessagePayload, MessageInfo } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../basecomponent/Index';
import { MessageRenderContext } from '../messagelist/context/MessageRenderContext';
import { ChatbotMessageData, ChatbotMessageProtocol, ChatbotMessageSource } from './ChatbotMessageProtocol';

const DOT_COUNT: number = 3;
const DOT_MIN_OPACITY: number = 0.25;
const DOT_SIZE: number = 4;
const DOT_SPACING: number = 7;
const ANIMATION_PERIOD_MS: number = 900;
const ANIMATION_FRAME_MS: number = 60;
const CHATBOT_MAX_BUBBLE_WIDTH: number = 240;
const CHATBOT_HORIZONTAL_PADDING: number = 24;

@Component
export struct ChatbotMessageViewContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State message?: MessageInfo = undefined;
  @ObjectLink @Watch('onMessagePayloadChanged') messagePayload: CustomMessagePayload;
  @State private displayText: string = '';
  @State private isLoading: boolean = false;
  @State   private phase: number = 0;
  private animationTimer?: number;

  aboutToAppear() {
    this.parseChatbotData();
  }

  onMessagePayloadChanged(): void {
    this.parseChatbotData();
  }

  aboutToDisappear() {
    this.stopAnimation();
  }

  private parseChatbotData(): void {
    const customData = this.messagePayload.customData;
    const data: ChatbotMessageData | undefined = ChatbotMessageProtocol.parseCustomData(customData) ??
      ChatbotMessageProtocol.parse(this.message);
    if (!data) {
      this.displayText = '';
      this.updateLoading(false);
      return;
    }
    this.displayText = data.displayText;
    const loading = data.isPlaceholder || (data.source === ChatbotMessageSource.FLOW && !data.isFinished);
    this.updateLoading(loading);
  }

  private updateLoading(loading: boolean): void {
    if (this.isLoading === loading) {
      if (loading && this.animationTimer === undefined) {
        this.startAnimation();
      }
      return;
    }
    this.isLoading = loading;
    if (loading) {
      this.startAnimation();
    } else {
      this.stopAnimation();
    }
  }

  private startAnimation(): void {
    if (this.animationTimer !== undefined) {
      return;
    }
    this.animationTimer = setInterval(() => {
      this.phase = (this.phase + ANIMATION_FRAME_MS / ANIMATION_PERIOD_MS) % 1;
    }, ANIMATION_FRAME_MS);
  }

  private stopAnimation(): void {
    if (this.animationTimer !== undefined) {
      clearInterval(this.animationTimer);
      this.animationTimer = undefined;
    }
    this.phase = 0;
  }

  private getDotOpacity(index: number): number {
    const wave = (Math.sin((this.phase - index / DOT_COUNT) * 2 * Math.PI) + 1) / 2;
    return DOT_MIN_OPACITY + wave * (1 - DOT_MIN_OPACITY);
  }

  build() {
    Row() {
      if (this.displayText.length > 0) {
        Text(this.displayText)
          .fontSize(16)
          .lineHeight(21)
          .fontColor(this.themeState.colors.textColorPrimary)
          .textOverflow({ overflow: TextOverflow.None })
          .maxLines(999)
          .wordBreak(WordBreak.BREAK_ALL)
          .flexShrink(1)
          .constraintSize({ minWidth: 0, maxWidth: CHATBOT_MAX_BUBBLE_WIDTH - CHATBOT_HORIZONTAL_PADDING })
      }

      if (this.isLoading) {
        Row({ space: DOT_SPACING - DOT_SIZE }) {
          ForEach([0, 1, 2], (index: number) => {
            Circle()
              .width(DOT_SIZE)
              .height(DOT_SIZE)
              .fill(this.themeState.colors.textColorSecondary)
              .opacity(this.getDotOpacity(index))
          }, (index: number) => index.toString())
        }
        .margin({ left: this.displayText.length > 0 ? 4 : 0 })
      }
    }
    .alignItems(VerticalAlign.Bottom)
    .constraintSize({ minWidth: 0, maxWidth: CHATBOT_MAX_BUBBLE_WIDTH })
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8
    })
  }
}

@Builder
export function ChatbotMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    ChatbotMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as CustomMessagePayload
    })
  }
}
