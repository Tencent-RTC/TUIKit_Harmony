import { Emoji, EmojiGroup } from '../../emojipicker/model/EmojiGroup';

export class FaceMessageResourceResolver {
  static resolve(faceName: string | undefined, faceIndex: number, groups: EmojiGroup[]): Emoji | undefined {
    const normalizedName = faceName ? faceName.trim() : '';
    if (normalizedName.length === 0) {
      return undefined;
    }
    const lowerName = normalizedName.toLowerCase();
    const isMatched = (item: Emoji): boolean => item.key === normalizedName ||
      item.emojiName.toLowerCase() === lowerName ||
      item.key.replace(/^\[+|\]+$/g, '').toLowerCase() === lowerName;
    const indexedEmoji = faceIndex >= 0 && faceIndex < groups.length ? groups[faceIndex].emojis.find(isMatched) :
      undefined;
    if (indexedEmoji) {
      return indexedEmoji;
    }
    for (const group of groups) {
      const emoji = group.emojis.find(isMatched);
      if (emoji) {
        return emoji;
      }
    }
    return undefined;
  }
}
