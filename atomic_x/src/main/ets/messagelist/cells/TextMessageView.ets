import { MessageInfo, MessageStatus } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState } from '../../basecomponent/Index';
import { MessageBody } from '@tencentcloud/atomicxcore';
import { MessageListStore } from '@tencentcloud/atomicxcore';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';

@Component
export struct TextMessageViewContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State message?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;
  @State private parsedSegments: EmojiTextSegment[] = [];

  aboutToAppear() {
    this.updateParsedSegments();
  }

  aboutToUpdate() {
    this.updateParsedSegments();
  }

  @Builder
  buildMixedContent() {
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
    .fontSize(16)
    .fontColor(this.message?.isSelf ?
    this.themeState.colors.textColorAntiPrimary :
    this.themeState.colors.textColorPrimary)
    .textOverflow({ overflow: TextOverflow.None })
    .maxLines(999)
    .wordBreak(WordBreak.BREAK_ALL)
  }

  build() {
    Column() {

      this.buildMixedContent()

      Row() {
        if (this.message?.status === MessageStatus.sending) {
          LoadingProgress()
            .width(12)
            .height(12)
            .margin({ right: 4 })
        }
      }
      .alignSelf(ItemAlign.End)
      .margin({ top: 4 })

    }
    .alignItems(HorizontalAlign.Start)
    .constraintSize({
      maxWidth: '100%',
      minWidth: 0
    })
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
export function TextMessageView(messageData: MessageInfo, MessageListStore?: MessageListStore) {
  if (messageData && messageData.messageBody) {
    TextMessageViewContent({
      message: messageData,
      messageBody: messageData.messageBody
    })
  }
}