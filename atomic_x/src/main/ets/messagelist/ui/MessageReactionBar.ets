import { MessageReaction } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { EmojiDataManager } from '../../emojipicker/data/EmojiData';

const MAX_DISPLAY_REACTIONS = 5;

@Component
export struct MessageReactionBar {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @Prop reactionList: MessageReaction[] = [];
  onClickCallback?: () => void;

  build() {
    if (this.reactionList.length === 0) {
      // Return empty component if no reactions
      Row()
        .width(0)
        .height(0)
    } else {
      Row() {
        this.ReactionContent()
      }
      .margin({ top: 4 })
    }
  }

  @Builder
  ReactionContent() {
    Row() {
      // Display reactions
      ForEach(this.getDisplayReactions(), (reaction: MessageReaction) => {
        this.ReactionItem(reaction, this.getDisplayReactions().length === 1)
      }, (reaction: MessageReaction) => reaction.reactionID)

      // Show "..." if there are more reactions
      if (this.hasMoreReactions()) {
        Text('...')
          .fontSize(13)
          .fontColor(this.themeState.colors.textColorTertiary)
          .margin({ right: 3 })
      }

      // Show total count if multiple reactions or has more
      if (this.getDisplayReactions().length > 1 || this.hasMoreReactions()) {
        Text(this.getTotalCount().toString())
          .fontSize(13)
          .fontColor(this.themeState.colors.textColorTertiary)
      }
    }
    .padding({ left: 9, right: 9, top: 5, bottom: 5 })
    .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(51)
    .borderWidth(1)
    .borderColor(this.themeState.colors.strokeColorPrimary)
    .onClick(() => {
      if (this.onClickCallback) {
        this.onClickCallback();
      }
    })
  }

  @Builder
  ReactionItem(reaction: MessageReaction, showCount: boolean) {
    Row() {
      // Emoji image
      if (this.getEmoji(reaction)) {
        Image(EmojiDataManager.getEmojiImageResource(this.getEmoji(reaction)!.imageFile))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
      }

      // Show count if single reaction
      if (showCount && (reaction.totalUserCount ?? 0) > 0) {
        Text((reaction.totalUserCount ?? 0).toString())
          .fontSize(13)
          .fontColor(this.themeState.colors.textColorTertiary)
          .margin({ left: 3 })
      }
    }
    .margin({ right: 3 })
  }

  private getDisplayReactions(): MessageReaction[] {
    return this.reactionList.slice(0, MAX_DISPLAY_REACTIONS);
  }

  private hasMoreReactions(): boolean {
    return this.reactionList.length > MAX_DISPLAY_REACTIONS;
  }

  private getTotalCount(): number {
    return this.reactionList.reduce((sum, r) => sum + Number(r.totalUserCount ?? 0), 0);
  }

  private getEmoji(reaction: MessageReaction) {
    // reactionID is emoji name like "[TUIEmoji_Smile]"
    const emoji = EmojiDataManager.getEmojiByName(reaction.reactionID);
    if (!emoji) {
      console.warn(`[MessageReactionBar] Emoji not found for reactionID: ${reaction.reactionID}`);
    }
    return emoji;
  }
}
