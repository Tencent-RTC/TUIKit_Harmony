import { MessageInfo, MessageStatus, MessageActionStore, ErrorInfo } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState, LanguageState } from '../../basecomponent/Index';
import { MessageBody } from '@tencentcloud/atomicxcore';
import { MessageListStore } from '@tencentcloud/atomicxcore';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct TextMessageViewContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State message?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @State private parsedSegments: EmojiTextSegment[] = [];

  aboutToAppear() {
    this.updateParsedSegments();
  }

  aboutToUpdate() {
    this.updateParsedSegments();
  }

  private shouldShowReceipt(): boolean {
    return this.message !== undefined && MessageUtils.shouldShowReadReceipt(this.message,
      this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
      this.isInMergedDetailView);
  }

  private shouldShowSending(): boolean {
    return this.message?.status === MessageStatus.sending;
  }

  build() {
    Column() {
      // Text content
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
      .fontSize(14)
      .fontColor(this.message?.isSelf ?
        this.themeState.colors.textColorAntiPrimary :
        this.themeState.colors.textColorPrimary)
      .textOverflow({ overflow: TextOverflow.None })
      .maxLines(999)
      .wordBreak(WordBreak.BREAK_ALL)
      .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
      // Read receipt indicator on new line
      if (this.shouldShowReceipt() || this.shouldShowSending()) {
        Row() {
          if (this.shouldShowReceipt() && this.message) {
            Image(MessageUtils.getReadReceiptIconResource(this.message))
              .width(14)
              .height(14)
          }

          if (this.shouldShowSending()) {
            LoadingProgress()
              .width(12)
              .height(12)
          }
        }
        .alignSelf(ItemAlign.End)
        .margin({ top: 2 })
      }
    }
    .padding({
      left: 8,
      right: 8,
      top: 8,
      bottom: 6
    })
  }

  private updateParsedSegments() {
    const text = this.messageBody?.text ?? '';
    this.parsedSegments = EmojiDataManager.parseEmojiText(text);
  }
}

@Builder
export function TextMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    TextMessageViewContent({
      message: context.message,
      messageBody: context.message.messageBody,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false
    })
  }
}
