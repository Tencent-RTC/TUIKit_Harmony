import { MessageInfo, TextMessagePayload } from '@tencentcloud/atomicxcore';
import { ThemeState, LanguageState } from '../../basecomponent/Index';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct TextMessageViewContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: TextMessagePayload;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @State private parsedSegments: EmojiTextSegment[] = [];

  aboutToAppear() {
    this.updateParsedSegments();
  }

  aboutToUpdate() {
    this.updateParsedSegments();
  }

  build() {
    Column() {
      Text() {
        ForEach(this.parsedSegments, (segment: EmojiTextSegment, index: number) => {
          if (segment.type === 'text') {
            Span(segment.content)
          } else if (segment.type === 'emoji' && segment.imageFile) {
            ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
              .verticalAlign(ImageSpanAlignment.CENTER)
          }
        }, (segment: EmojiTextSegment, index: number) => `${segment.type}_${index}_${segment.content}`)
      }
      .fontSize(15)
      .fontColor(this.message?.isSentBySelf ?
        this.themeState.colors.textColorAntiPrimary :
        this.themeState.colors.textColorPrimary)
      .textOverflow({ overflow: TextOverflow.None })
      .maxLines(999)
      .wordBreak(WordBreak.BREAK_ALL)
      .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
    }
    .constraintSize({ minWidth: 0, maxWidth: 240 })
    .padding({
      left: 8,
      right: 8,
      top: 8,
      bottom: 6
    })
  }

  private updateParsedSegments() {
    const text = this.messagePayload?.text ?? '';
    this.parsedSegments = EmojiDataManager.parseEmojiText(text);
  }
}

@Builder
export function TextMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    TextMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as TextMessagePayload,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false
    })
  }
}
