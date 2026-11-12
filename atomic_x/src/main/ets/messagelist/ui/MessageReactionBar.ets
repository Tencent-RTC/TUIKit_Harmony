import { MessageReaction, UserProfile } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { EmojiDataManager } from '../../emojipicker/data/EmojiData';

const MAX_DISPLAY_REACTIONS = 5;
const CHIP_MAX_WIDTH = 180;
const CHIP_TEXT_MAX_WIDTH = 120;
const MAX_REACTION_ROW_WIDTH = 220;
const CHIP_HORIZONTAL_SPACING = 8;
const MEDIA_REACTION_TOP_MARGIN = 6;

@Component
export struct MessageReactionBar {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @Prop reactionList: MessageReaction[] = [];
  @Prop isSentBySelf: boolean = false;
  @Prop isMediaBubble: boolean = false;
  onClickCallback?: () => void;

  build() {
    if (this.reactionList.length === 0) {
      Row()
        .width(0)
        .height(0)
    } else {
      Column({ space: 6 }) {
        ForEach(this.getReactionRows(), (row: MessageReaction[]) => {
          Row({ space: CHIP_HORIZONTAL_SPACING }) {
            ForEach(row, (reaction: MessageReaction) => {
              this.ReactionItem(reaction)
            }, (reaction: MessageReaction) => reaction.reactionID)
          }
          .width('auto')
          .justifyContent(this.isSentBySelf ? FlexAlign.End : FlexAlign.Start)
        }, (row: MessageReaction[], rowIndex: number) => `${rowIndex}`)
      }
      .width('auto')
      .alignItems(this.isSentBySelf ? HorizontalAlign.End : HorizontalAlign.Start)
      .alignSelf(this.isSentBySelf ? ItemAlign.End : ItemAlign.Start)
      .padding(this.isMediaBubble ? 0 : { left: 12, right: 12, bottom: 6 })
      .margin({ top: this.isMediaBubble ? MEDIA_REACTION_TOP_MARGIN : 2 })
      .onClick(() => {
        if (this.onClickCallback) {
          this.onClickCallback();
        }
      })
    }
  }

  @Builder
  ReactionItem(reaction: MessageReaction) {
    Row() {
      if (this.getEmoji(reaction)) {
        Image(EmojiDataManager.getEmojiImageResource(this.getEmoji(reaction)!.imageFile))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
      }

      if (this.getEmoji(reaction) && this.getReactionLabel(reaction).length > 0) {
        Row()
          .width(1)
          .height(14)
          .backgroundColor(this.getDividerColor())
          .margin({ left: 4, right: 4 })
      }

      if (this.getReactionLabel(reaction).length > 0) {
        Text(this.getReactionLabel(reaction))
          .fontSize(11)
          .lineHeight(15.4)
          .fontColor(this.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
          this.themeState.colors.textColorSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: CHIP_TEXT_MAX_WIDTH })
      }
    }
    .alignItems(VerticalAlign.Center)
    .constraintSize({ maxWidth: CHIP_MAX_WIDTH })
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(this.getChipBackgroundColor())
    .borderRadius(12)
    .margin({ bottom: 0 })
  }

  private getDisplayReactions(): MessageReaction[] {
    return this.reactionList.slice(0, MAX_DISPLAY_REACTIONS);
  }

  private getReactionRows(): MessageReaction[][] {
    const rows: MessageReaction[][] = [];
    let currentRow: MessageReaction[] = [];
    let currentRowWidth = 0;

    this.getDisplayReactions().forEach((reaction: MessageReaction) => {
      const itemWidth = this.getReactionItemWidth(reaction);
      const nextRowWidth = currentRow.length === 0 ? itemWidth :
        currentRowWidth + CHIP_HORIZONTAL_SPACING + itemWidth;
      if (currentRow.length > 0 && nextRowWidth > MAX_REACTION_ROW_WIDTH) {
        rows.push(currentRow);
        currentRow = [];
        currentRowWidth = 0;
      }

      currentRow.push(reaction);
      currentRowWidth = currentRow.length === 1 ? itemWidth :
        currentRowWidth + CHIP_HORIZONTAL_SPACING + itemWidth;
    });

    if (currentRow.length > 0) {
      rows.push(currentRow);
    }
    return rows;
  }

  private getReactionItemWidth(reaction: MessageReaction): number {
    const label = this.getReactionLabel(reaction);
    const dividerWidth = this.getEmoji(reaction) && label.length > 0 ? 9 : 0;
    const measuredTextWidth = this.measureLabelWidth(label);
    const measuredWidth = 16 + dividerWidth + measuredTextWidth + 16;
    return Math.min(CHIP_MAX_WIDTH, measuredWidth);
  }

  private measureLabelWidth(label: string): number {
    let width = 0;
    for (let index = 0; index < label.length; index++) {
      const code = label.charCodeAt(index);
      width += code >= 0x3000 ? 12 : (code === 0x20 ? 4 : 6);
    }
    return Math.min(CHIP_TEXT_MAX_WIDTH, width);
  }

  private getEmoji(reaction: MessageReaction) {
    return EmojiDataManager.getEmojiByName(reaction.reactionID);
  }

  private getReactionLabel(reaction: MessageReaction): string {
    const count = Math.max(0, Math.floor(reaction.totalUserCount ?? 0));
    if (count <= 0) {
      return '';
    }

    const firstUser: UserProfile | undefined = reaction.partialUserList?.[0];
    const displayName = firstUser?.nickname?.trim() || firstUser?.userID?.trim();
    if (!displayName) {
      return count.toString();
    }
    return count === 1 ? displayName : `${displayName}等${count}人`;
  }

  private getChipBackgroundColor(): string {
    const baseColor = this.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
      this.themeState.colors.textColorPrimary;
    return this.withAlpha(baseColor, this.isSentBySelf ? '18' : '10');
  }

  private getDividerColor(): string {
    const baseColor = this.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
      this.themeState.colors.textColorPrimary;
    return this.withAlpha(baseColor, this.isSentBySelf ? '40' : '20');
  }

  private withAlpha(color: string, alpha: string): string {
    if (color.length === 9 && color.startsWith('#')) {
      return `#${alpha}${color.substring(3)}`;
    }
    return color;
  }
}
