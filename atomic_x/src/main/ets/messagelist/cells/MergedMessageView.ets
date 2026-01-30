import { MessageInfo, MessageBody, MessageListStore } from '@tencentcloud/atomicxcore';
import { ThemeState, ContextProvider, LanguageState } from '../../basecomponent/Index';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MergedMessageDetailPage } from '../ui/MergedMessageDetailPage';
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct MergedMessageViewContent {
  @ObjectLink messageBody: MessageBody;
  @ObjectLink message: MessageInfo;
  @ObjectLink messageListStore: MessageListStore;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  onRequestCloseParentDialog?: () => void; // Callback to close parent dialog (e.g., MessageActionDialog)
  
  private readonly BUBBLE_WIDTH: number = 220;
  private detailDialogController?: CustomDialogController;

  private shouldShowReceipt(): boolean {
    return MessageUtils.shouldShowReadReceipt(this.message,
      this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
      this.isInMergedDetailView);
  }
  
  private getMergedTitle(): string {
    return this.messageBody?.mergedMessage?.title ?? '';
  }
  
  private getAbstractList(): string[] {
    return this.messageBody?.mergedMessage?.abstractList ?? [];
  }
  
  @Builder
  buildAbstractText(abstract: string) {
    Text() {
      ForEach(EmojiDataManager.parseEmojiText(abstract), (segment: EmojiTextSegment, index: number) => {
        if (segment.type === 'text') {
          Span(segment.content)
        } else if (segment.type === 'emoji' && segment.imageFile) {
          ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
            .width(14)
            .height(14)
            .objectFit(ImageFit.Contain)
            .verticalAlign(ImageSpanAlignment.CENTER)
        }
      }, (segment: EmojiTextSegment, index: number) => `${segment.type}_${index}_${segment.content}`)
    }
    .fontSize(12)
    .fontColor(this.themeState.colors.textColorSecondary)
    .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
    .maxLines(1)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // Title
        Text(this.getMergedTitle() || $r('app.string.merged_message_title'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeState.colors.textColorPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
          .padding({ left: 12, right: 12, top: 10 })
        
        // Abstract list (max 4 lines)
        if (this.getAbstractList().length > 0) {
          Column({ space: 4 }) {
            ForEach(this.getAbstractList().slice(0, 4), (abstract: string, index: number) => {
              this.buildAbstractText(abstract)
            }, (abstract: string, index: number) => `abstract_${index}`)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 })
          .alignItems(HorizontalAlign.Start)
        }
        
        // Divider
        Divider()
          .color(this.themeState.colors.shadowColor)
          .strokeWidth(0.5)
          .margin({ left: 12, right: 12, top: 8 })
        
        // Bottom hint with read receipt spacing
        Row() {
          Text($r('app.string.merged_message_hint'))
            .fontSize(10)
            .fontColor(this.themeState.colors.textColorTertiary)
          
          if (this.shouldShowReceipt()) {
            Blank()
              .width(18)
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 6, bottom: 8 })
      }
      .width(this.BUBBLE_WIDTH)
      .borderRadius(8)
      .onClick(() => {
        this.openMergedMessageDetail();
      })

      // Read receipt icon
      if (this.shouldShowReceipt()) {
        Image(MessageUtils.getReadReceiptIconResource(this.message))
          .width(14)
          .height(14)
          .margin({ right: 8, bottom: 6 })
      }
    }
    .width(this.BUBBLE_WIDTH)
  }
  
  private openMergedMessageDetail() {
    console.info('[MergedMessageView] Opening merged message detail, messageID:', this.message.ID);
    
    // Close parent dialog first if callback is provided (e.g., MessageActionDialog)
    if (this.onRequestCloseParentDialog) {
      this.onRequestCloseParentDialog();
    }
    
    // Add a small delay to ensure parent dialog closes before opening new one
    setTimeout(() => {
      this.detailDialogController = new CustomDialogController({
        builder: MergedMessageDetailPage({
          mergedMessage: this.message,
          depth: 0
        }),
        autoCancel: false,
        customStyle: true,
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
      });
      
      this.detailDialogController.open();
    }, 100);
  }
}

@Builder
export function MergedMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    MergedMessageViewContent({
      message: context.message,
      messageBody: context.message.messageBody,
      messageListStore: context.messageListStore,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false,
      onRequestCloseParentDialog: context.onRequestCloseParentDialog
    })
  }
}
