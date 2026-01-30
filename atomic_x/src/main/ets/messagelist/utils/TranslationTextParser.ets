import { MessageInfo, C2CSettingStore } from '@tencentcloud/atomicxcore';
import { EmojiDataManager } from '../../emojipicker/data/EmojiData';
import { MentionInfo } from '../../messageinput/components/MentionInfo';

/**
 * Split result containing text segments and indices
 */
export class SplitTextResult {
  result: string[] = [];
  text: string[] = [];
  textIndex: number[] = [];
}

/**
 * Text translation parser that handles emoji and @ mentions
 * This implementation is consistent with iOS/Android TranslationTextParser logic
 */
export class TranslationTextParser {
  public static readonly kSplitStringResultKey = 'result';
  public static readonly kSplitStringTextKey = 'text';
  public static readonly kSplitStringTextIndexKey = 'textIndex';

  /**
   * Parse text message and return translation components
   * @param text Original text
   * @param atUserNames @ user name list (without @ prefix)
   * @returns Object containing "result", "text", "textIndex" keys
   */
  public static splitTextByEmojiAndAtUsers(
    text: string,
    atUserNames?: string[]
  ): SplitTextResult | null {
    if (!text || text.length === 0) {
      return null;
    }

    let result: string[] = [];

    // Build user strings with @ prefix and trailing space
    const atUsers: string[] = [];
    if (atUserNames && atUserNames.length > 0) {
      atUserNames.forEach(user => {
        atUsers.push(`@${user} `);
      });
    }

    // Find @user ranges in the string
    const atUserRanges = TranslationTextParser.rangeOfAtUsers(atUsers, text);

    // Split text using @user ranges
    const atUserSplitResult = TranslationTextParser.splitArrayWithRanges(atUserRanges, text);
    if (!atUserSplitResult) {
      return null;
    }

    const splitArrayByAtUser = atUserSplitResult.strings;
    const atUserIndexSet = new Set(atUserSplitResult.specialIndexes);

    // Iterate through split array and match emoji in non-@ parts
    let k = -1;
    const textIndexArray: number[] = [];

    for (let i = 0; i < splitArrayByAtUser.length; i++) {
      const str = splitArrayByAtUser[i];
      if (atUserIndexSet.has(i)) {
        // str is @user info, keep as-is
        result.push(str);
        k++;
      } else {
        // str is not @user info, parse emoji
        const emojiRanges = TranslationTextParser.matchTextByEmoji(str);
        const emojiSplitResult = TranslationTextParser.splitArrayWithRanges(emojiRanges, str);
        if (emojiSplitResult) {
          const splitArrayByEmoji = emojiSplitResult.strings;
          const emojiIndexSet = new Set(emojiSplitResult.specialIndexes);

          for (let j = 0; j < splitArrayByEmoji.length; j++) {
            const tmp = splitArrayByEmoji[j];
            result.push(tmp);
            k++;
            if (!emojiIndexSet.has(j)) {
              // This is text that needs translation
              textIndexArray.push(k);
            }
          }
        }
      }
    }

    // Extract text array using indices from result
    const textArray: string[] = [];
    for (const n of textIndexArray) {
      if (n < result.length) {
        textArray.push(result[n]);
      }
    }

    const finalResult = new SplitTextResult();
    finalResult.result = result;
    finalResult.text = textArray;
    finalResult.textIndex = textIndexArray;
    return finalResult;
  }

  /**
   * Reconstruct translated text by replacing text fragments with translations
   */
  public static replacedStringWithArray(
    array: string[],
    indexArray: number[],
    replaceDict?: Record<string, string>
  ): string | null {
    if (!replaceDict) {
      return null;
    }

    const mutableArray = [...array];

    for (const value of indexArray) {
      if (value < 0 || value >= mutableArray.length) {
        continue;
      }
      const replacement = replaceDict[mutableArray[value]];
      if (replacement !== undefined) {
        mutableArray[value] = replacement;
      }
    }

    return mutableArray.join('');
  }

  /**
   * Get @ user names from message's atUserList
   * Note: Currently returns userIDs as fallback. In production, should call UserStore to get display names.
   */
  public static async getAtUserNames(messageInfo?: MessageInfo): Promise<string[] | null> {
    if (!messageInfo || !messageInfo.atUserList || messageInfo.atUserList.length === 0) {
      return null;
    }

    const atUserIDs = messageInfo.atUserList;

    // Separate @All from regular users
    const regularUserIDs: string[] = [];
    const atAllIndexes: number[] = [];

    for (let i = 0; i < atUserIDs.length; i++) {
      const userID = atUserIDs[i];
      // Use MentionInfo constant for @All
      if (userID === MentionInfo.AT_ALL_USER_ID) {
        atAllIndexes.push(i);
      } else {
        regularUserIDs.push(userID);
      }
    }

    // If only @All
    if (regularUserIDs.length === 0) {
      // Use localized string
      const allText = getContext().resourceManager.getStringSync($r('app.string.mention_all').id);
      return Array(atAllIndexes.length).fill(allText);
    }

    // Get user info
    // For now, fallback to userID
    const names: string[] = [...regularUserIDs];

    // Restore @All at original positions
    const allText = getContext().resourceManager.getStringSync($r('app.string.mention_all').id);
    for (const idx of atAllIndexes) {
      if (idx <= names.length) {
        names.splice(idx, 0, allText);
      }
    }

    return names;
  }

  // Private helper methods

  private static rangeOfAtUsers(atUsers: string[], text: string): TextRange[] {
    // Find all '@' positions
    const atPositions: number[] = [];
    for (let i = 0; i < text.length; i++) {
      if (text[i] === '@') {
        atPositions.push(i);
      }
    }

    const result: TextRange[] = [];
    const usedPositions = new Set<number>();

    for (const user of atUsers) {
      for (const idx of atPositions) {
        if (usedPositions.has(idx)) continue;
        if (text.length >= user.length && idx <= text.length - user.length) {
          const substring = text.substring(idx, idx + user.length);
          if (substring === user) {
            result.push(new TextRange(idx, user.length));
            usedPositions.add(idx);
          }
        }
      }
    }
    return result;
  }

  private static splitArrayWithRanges(ranges: TextRange[], text: string): SplitResult | null {
    if (ranges.length === 0) {
      return new SplitResult([text], []);
    }
    if (text.length === 0) {
      return null;
    }

    // Sort by location
    ranges.sort((a, b) => a.location - b.location);

    const result: string[] = [];
    const indexes: number[] = [];
    let prev = 0;
    let j = -1;

    for (let i = 0; i < ranges.length; i++) {
      const cur = ranges[i];

      // Add text before current range
      if (cur.location > prev) {
        const str = text.substring(prev, cur.location);
        result.push(str);
        j++;
      }

      // Add content within current range (special element)
      const str = text.substring(cur.location, cur.location + cur.length);
      result.push(str);
      j++;
      indexes.push(j);

      prev = cur.location + cur.length;

      // Handle text after last range
      if (i === ranges.length - 1 && prev < text.length) {
        const last = text.substring(prev);
        result.push(last);
      }
    }

    return new SplitResult(result, indexes);
  }

  private static matchTextByEmoji(text: string): TextRange[] {
    const result: TextRange[] = [];

    // TUIKit custom emoji: \[[a-zA-Z0-9_\u4e00-\u9fa5]+\]
    const customEmojiRegex = /\[[a-zA-Z0-9_\u4e00-\u9fa5]+\]/g;
    let match: RegExpExecArray | null = null;
    while ((match = customEmojiRegex.exec(text)) !== null) {
      const emojiName = match[0];
      // Verify if it's a registered emoji
      if (TranslationTextParser.isRegisteredEmoji(emojiName)) {
        result.push(new TextRange(match.index, match[0].length));
      }
    }

    // Unicode emoji
    const unicodeEmojiRegex = TranslationTextParser.getUnicodeEmojiRegex();
    unicodeEmojiRegex.lastIndex = 0; // Reset regex state
    while ((match = unicodeEmojiRegex.exec(text)) !== null) {
      result.push(new TextRange(match.index, match[0].length));
    }

    return result;
  }

  /**
   * Check if a string is a registered TUIKit emoji
   */
  private static isRegisteredEmoji(name: string): boolean {
    try {
      const emoji = EmojiDataManager.getEmojiByName(name);
      return emoji !== undefined;
    } catch (error) {
      console.warn(`[TranslationTextParser] Error checking emoji: ${name}`, error);
      return false;
    }
  }

  /**
   * Get Unicode emoji regex
   * Matches common emoji ranges including:
   * - Emoticons (U+1F600-U+1F64F)
   * - Symbols & Pictographs (U+1F300-U+1F5FF)
   * - Transport & Map Symbols (U+1F680-U+1F6FF)
   * - Regional Indicator Symbols (U+1F1E0-U+1F1FF)
   * - Supplemental Symbols (U+1F900-U+1F9FF)
   * - Misc Symbols (U+2600-U+26FF)
   * - Dingbats (U+2700-U+27BF)
   */
  private static getUnicodeEmojiRegex(): RegExp {
    // Comprehensive Unicode emoji regex
    return /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{1F900}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1F018}-\u{1F270}]|[\u{238C}-\u{2454}]|[\u{20D0}-\u{20FF}]/gu;
  }
}

class TextRange {
  public location: number;
  public length: number;

  constructor(location: number, length: number) {
    this.location = location;
    this.length = length;
  }
}

class SplitResult {
  public strings: string[];
  public specialIndexes: number[];

  constructor(strings: string[], specialIndexes: number[]) {
    this.strings = strings;
    this.specialIndexes = specialIndexes;
  }
}
