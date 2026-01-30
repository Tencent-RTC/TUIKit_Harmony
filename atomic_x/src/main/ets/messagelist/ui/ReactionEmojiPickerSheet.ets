import { ThemeState } from '../../basecomponent/Index';
import { EmojiDataManager, EmojiItem } from '../../emojipicker/data/EmojiData';
import { RecentEmojiManager } from './ReactionEmojiPicker';

@CustomDialog
export struct ReactionEmojiPickerSheet {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller: CustomDialogController;
  onEmojiSelect?: (emoji: EmojiItem) => void;
  @State private allEmojis: EmojiItem[] = [];

  aboutToAppear() {
    this.allEmojis = EmojiDataManager.getAllEmojis();
  }

  build() {
    Column() {
      // Drag indicator (handle bar)
      Row() {
        Row()
          .width(36)
          .height(4)
          .borderRadius(2)
          .backgroundColor(this.themeState.colors.strokeColorPrimary)
      }
      .width('100%')
      .height(28)
      .justifyContent(FlexAlign.Center)

      // Emoji grid with scroll
      Scroll() {
        Grid() {
          ForEach(this.allEmojis, (emoji: EmojiItem) => {
            GridItem() {
              this.EmojiGridItem(emoji)
            }
          }, (emoji: EmojiItem) => emoji.id)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width('100%')
        .padding(16)
      }
      .scrollBar(BarState.Auto)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('50%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  EmojiGridItem(emoji: EmojiItem) {
    Row() {
      Image(EmojiDataManager.getEmojiImageResource(emoji.imageFile))
        .width(32)
        .height(32)
        .objectFit(ImageFit.Contain)
    }
    .width(40)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      console.log(`[ReactionEmoji] 👆 User clicked emoji in FullPage - ID: ${emoji.id}, Name: ${emoji.name}, Image: ${emoji.imageFile}`);
      // Add to recent emojis
      RecentEmojiManager.getInstance().addRecentEmoji(emoji.id);
      
      if (this.onEmojiSelect) {
        console.log(`[ReactionEmoji] 📤 Triggering onEmojiSelect callback from FullPage`);
        this.onEmojiSelect(emoji);
      }
      this.controller.close();
    })
  }
}
