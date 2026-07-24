import { MessageQuoteInfo } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import {
  MessageQuoteDisplayData,
  MessageQuoteDisplayPolicy,
  MessageQuoteLabels
} from './MessageQuoteDisplayPolicy';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/data/EmojiData';

@Component
export struct MessageQuoteBubbleView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink quoteInfo: MessageQuoteInfo;
  onQuoteClick?: (quoteInfo: MessageQuoteInfo) => void;

  private resolveDisplayData(): MessageQuoteDisplayData {
    return MessageQuoteDisplayPolicy.resolve(this.quoteInfo, this.buildLabels());
  }

  private buildLabels(): MessageQuoteLabels {
    return {
      deleted: this.getString($r('app.string.message_list_quote_deleted')),
      revoked: this.getString($r('app.string.message_list_quote_revoked')),
      image: this.getString($r('app.string.message_list_message_type_image')),
      video: this.getString($r('app.string.message_list_message_type_video')),
      voice: this.getString($r('app.string.message_list_message_type_voice')),
      file: this.getString($r('app.string.message_list_message_type_file')),
      face: this.getString($r('app.string.message_list_message_type_animate_emoji')),
      custom: this.getString($r('app.string.message_list_message_type_custom')),
      merged: this.getString($r('app.string.message_list_message_type_merged')),
      unknown: this.getString($r('app.string.message_list_unsupported_message'))
    };
  }

  private getString(resource: Resource): string {
    try {
      return getContext(this).resourceManager.getStringSync(resource);
    } catch (_e) {
      return '';
    }
  }

  build() {
    Column() {
      if (this.resolveDisplayData().senderName.length > 0) {
        Text(`${this.resolveDisplayData().senderName}:`)
          .fontSize(12)
          .fontColor(this.themeState.colors.textColorSecondary)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (!this.resolveDisplayData().thumbnail) {
        Text() {
          ForEach(EmojiDataManager.parseEmojiText(this.resolveDisplayData().contentText),
            (segment: EmojiTextSegment, index: number) => {
              if (segment.type === 'text') {
                Span(segment.content)
              } else if (segment.type === 'emoji' && segment.imageFile) {
                ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
                  .width(16)
                  .height(16)
                  .objectFit(ImageFit.Contain)
                  .verticalAlign(ImageSpanAlignment.CENTER)
              }
            },
            (segment: EmojiTextSegment, index: number) => `quote_${segment.type}_${index}_${segment.content}`)
        }
          .fontSize(12)
          .fontColor(this.themeState.colors.textColorSecondary)
          .fontStyle(this.resolveDisplayData().isStatusText ? FontStyle.Italic : FontStyle.Normal)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      } else {
        Stack() {
          Image(this.resolveDisplayData().thumbnail!.path)
            .width(36)
            .height(36)
            .borderRadius(4)
            .objectFit(ImageFit.Cover)

          if (this.resolveDisplayData().thumbnail!.isVideo) {
            Text('▶')
              .fontSize(16)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
          }
        }
        .width(36)
        .height(36)
        .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
        .borderRadius(4)
        .margin({ top: 6 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(8)
    .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(8)
    .onClick(() => {
      if (this.onQuoteClick) {
        this.onQuoteClick(this.quoteInfo);
      }
    })
  }
}
