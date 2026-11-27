export class BarrageEmoji {
  readonly token: string
  readonly assetName: string

  constructor(token: string, assetName: string) {
    this.token = token
    this.assetName = assetName
  }

  static readonly all: BarrageEmoji[] = [
    new BarrageEmoji('[TUIEmoji_Smile]', 'live_barrage_emoji_0'),
    new BarrageEmoji('[TUIEmoji_Expect]', 'live_barrage_emoji_1'),
    new BarrageEmoji('[TUIEmoji_Blink]', 'live_barrage_emoji_2'),
    new BarrageEmoji('[TUIEmoji_Guffaw]', 'live_barrage_emoji_3'),
    new BarrageEmoji('[TUIEmoji_KindSmile]', 'live_barrage_emoji_4'),
    new BarrageEmoji('[TUIEmoji_Haha]', 'live_barrage_emoji_5'),
    new BarrageEmoji('[TUIEmoji_Cheerful]', 'live_barrage_emoji_6'),
    new BarrageEmoji('[TUIEmoji_Speechless]', 'live_barrage_emoji_7'),
    new BarrageEmoji('[TUIEmoji_Amazed]', 'live_barrage_emoji_8'),
    new BarrageEmoji('[TUIEmoji_Sorrow]', 'live_barrage_emoji_9'),
    new BarrageEmoji('[TUIEmoji_Complacent]', 'live_barrage_emoji_10'),
    new BarrageEmoji('[TUIEmoji_Silly]', 'live_barrage_emoji_11'),
    new BarrageEmoji('[TUIEmoji_Lustful]', 'live_barrage_emoji_12'),
    new BarrageEmoji('[TUIEmoji_Giggle]', 'live_barrage_emoji_13'),
    new BarrageEmoji('[TUIEmoji_Kiss]', 'live_barrage_emoji_14'),
    new BarrageEmoji('[TUIEmoji_Wail]', 'live_barrage_emoji_15'),
    new BarrageEmoji('[TUIEmoji_TearsLaugh]', 'live_barrage_emoji_16'),
    new BarrageEmoji('[TUIEmoji_Trapped]', 'live_barrage_emoji_17'),
    new BarrageEmoji('[TUIEmoji_Mask]', 'live_barrage_emoji_18'),
    new BarrageEmoji('[TUIEmoji_Fear]', 'live_barrage_emoji_19'),
    new BarrageEmoji('[TUIEmoji_BareTeeth]', 'live_barrage_emoji_20'),
    new BarrageEmoji('[TUIEmoji_FlareUp]', 'live_barrage_emoji_21'),
    new BarrageEmoji('[TUIEmoji_Yawn]', 'live_barrage_emoji_22'),
    new BarrageEmoji('[TUIEmoji_Tact]', 'live_barrage_emoji_23'),
    new BarrageEmoji('[TUIEmoji_Stareyes]', 'live_barrage_emoji_24'),
    new BarrageEmoji('[TUIEmoji_ShutUp]', 'live_barrage_emoji_25'),
    new BarrageEmoji('[TUIEmoji_Sigh]', 'live_barrage_emoji_26'),
    new BarrageEmoji('[TUIEmoji_Hehe]', 'live_barrage_emoji_27'),
    new BarrageEmoji('[TUIEmoji_Silent]', 'live_barrage_emoji_28'),
    new BarrageEmoji('[TUIEmoji_Surprised]', 'live_barrage_emoji_29'),
    new BarrageEmoji('[TUIEmoji_Askance]', 'live_barrage_emoji_30'),
    new BarrageEmoji('[TUIEmoji_Ok]', 'live_barrage_emoji_31'),
    new BarrageEmoji('[TUIEmoji_Shit]', 'live_barrage_emoji_32'),
    new BarrageEmoji('[TUIEmoji_Monster]', 'live_barrage_emoji_33'),
    new BarrageEmoji('[TUIEmoji_Daemon]', 'live_barrage_emoji_34'),
    new BarrageEmoji('[TUIEmoji_Rage]', 'live_barrage_emoji_35'),
    new BarrageEmoji('[TUIEmoji_Fool]', 'live_barrage_emoji_36'),
    new BarrageEmoji('[TUIEmoji_Pig]', 'live_barrage_emoji_37'),
    new BarrageEmoji('[TUIEmoji_Cow]', 'live_barrage_emoji_38'),
    new BarrageEmoji('[TUIEmoji_Ai]', 'live_barrage_emoji_39'),
    new BarrageEmoji('[TUIEmoji_Skull]', 'live_barrage_emoji_40'),
    new BarrageEmoji('[TUIEmoji_Bombs]', 'live_barrage_emoji_41'),
    new BarrageEmoji('[TUIEmoji_Coffee]', 'live_barrage_emoji_42'),
    new BarrageEmoji('[TUIEmoji_Cake]', 'live_barrage_emoji_43'),
    new BarrageEmoji('[TUIEmoji_Beer]', 'live_barrage_emoji_44'),
    new BarrageEmoji('[TUIEmoji_Flower]', 'live_barrage_emoji_45'),
    new BarrageEmoji('[TUIEmoji_Watermelon]', 'live_barrage_emoji_46'),
    new BarrageEmoji('[TUIEmoji_Rich]', 'live_barrage_emoji_47'),
    new BarrageEmoji('[TUIEmoji_Heart]', 'live_barrage_emoji_48'),
    new BarrageEmoji('[TUIEmoji_Moon]', 'live_barrage_emoji_49'),
    new BarrageEmoji('[TUIEmoji_Sun]', 'live_barrage_emoji_50'),
    new BarrageEmoji('[TUIEmoji_Star]', 'live_barrage_emoji_51'),
    new BarrageEmoji('[TUIEmoji_RedPacket]', 'live_barrage_emoji_52'),
    new BarrageEmoji('[TUIEmoji_Celebrate]', 'live_barrage_emoji_53'),
    new BarrageEmoji('[TUIEmoji_Bless]', 'live_barrage_emoji_54'),
    new BarrageEmoji('[TUIEmoji_Fortune]', 'live_barrage_emoji_55'),
    new BarrageEmoji('[TUIEmoji_Convinced]', 'live_barrage_emoji_56'),
    new BarrageEmoji('[TUIEmoji_Prohibit]', 'live_barrage_emoji_57'),
    new BarrageEmoji('[TUIEmoji_666]', 'live_barrage_emoji_58'),
    new BarrageEmoji('[TUIEmoji_857]', 'live_barrage_emoji_59'),
    new BarrageEmoji('[TUIEmoji_Knife]', 'live_barrage_emoji_60'),
    new BarrageEmoji('[TUIEmoji_Like]', 'live_barrage_emoji_61'),
  ]
}

export class BarrageEmojiSegment {
  readonly text: string
  readonly emoji?: BarrageEmoji

  constructor(text: string, emoji?: BarrageEmoji) {
    this.text = text
    this.emoji = emoji
  }
}

export class BarrageEmojiConverter {
  private static readonly emojiByToken: Map<string, BarrageEmoji> = BarrageEmojiConverter.makeIndex()
  private static readonly emojiByAssetName: Map<string, BarrageEmoji> = BarrageEmojiConverter.makeAssetIndex()

  private static makeIndex(): Map<string, BarrageEmoji> {
    const result: Map<string, BarrageEmoji> = new Map()
    BarrageEmoji.all.forEach((emoji: BarrageEmoji) => result.set(emoji.token, emoji))
    return result
  }

  private static makeAssetIndex(): Map<string, BarrageEmoji> {
    const result: Map<string, BarrageEmoji> = new Map()
    BarrageEmoji.all.forEach((emoji: BarrageEmoji) => result.set(emoji.assetName, emoji))
    return result
  }

  static emojiForAssetName(assetName: string): BarrageEmoji | undefined {
    return BarrageEmojiConverter.emojiByAssetName.get(assetName)
  }

  static assetNameFromResource(value: string): string {
    if (value.startsWith('app.media.')) {
      return value.substring('app.media.'.length)
    }
    const slash = value.lastIndexOf('/')
    const fileName = value.substring(slash + 1)
    const extension = fileName.lastIndexOf('.')
    return extension > 0 ? fileName.substring(0, extension) : fileName
  }

  static parse(text: string): BarrageEmojiSegment[] {
    const result: BarrageEmojiSegment[] = []
    let current = 0
    while (current < text.length) {
      const opening = text.indexOf('[', current)
      if (opening < 0) {
        BarrageEmojiConverter.appendText(text.slice(current), result)
        break
      }
      BarrageEmojiConverter.appendText(text.slice(current, opening), result)
      const closing = text.indexOf(']', opening + 1)
      if (closing < 0) {
        BarrageEmojiConverter.appendText(text.slice(opening), result)
        break
      }
      const token = text.slice(opening, closing + 1)
      const emoji = BarrageEmojiConverter.emojiByToken.get(token)
      if (emoji === undefined) {
        BarrageEmojiConverter.appendText(token, result)
      } else {
        result.push(new BarrageEmojiSegment('', emoji))
      }
      current = closing + 1
    }
    return result
  }

  static characters(text: string): string[] {
    const codePoints = Array.from(text)
    const result: string[] = []
    let current = ''
    let previous = ''
    let regionalCount = 0
    for (const character of codePoints) {
      const codePoint = character.codePointAt(0) ?? 0
      if (current.length === 0) {
        current = character
        regionalCount = BarrageEmojiConverter.isRegionalIndicator(codePoint) ? 1 : 0
        previous = character
        continue
      }
      const previousCodePoint = previous.codePointAt(0) ?? 0
      const joins = previousCodePoint === 13 && codePoint === 10 ||
        previousCodePoint === 0x200D || BarrageEmojiConverter.isExtend(codePoint) ||
        BarrageEmojiConverter.isRegionalIndicator(codePoint) && regionalCount % 2 === 1
      if (joins) {
        current += character
      } else {
        result.push(current)
        current = character
      }
      if (BarrageEmojiConverter.isRegionalIndicator(codePoint)) {
        regionalCount = joins ? regionalCount + 1 : 1
      } else if (!BarrageEmojiConverter.isExtend(codePoint) && codePoint !== 0x200D) {
        regionalCount = 0
      }
      previous = character
    }
    if (current.length > 0) {
      result.push(current)
    }
    return result
  }

  static visibleLength(text: string): number {
    return BarrageEmojiConverter.parse(text).reduce((count: number, segment: BarrageEmojiSegment) =>
      count + (segment.emoji === undefined ? BarrageEmojiConverter.characters(segment.text).length : 1), 0)
  }

  static visiblePrefix(text: string, limit: number): string {
    if (limit <= 0) {
      return ''
    }
    let count = 0
    let result = ''
    const segments = BarrageEmojiConverter.parse(text)
    for (const segment of segments) {
      if (segment.emoji !== undefined) {
        if (count >= limit) {
          return result
        }
        result += segment.emoji.token
        count += 1
        continue
      }
      const remaining = limit - count
      if (remaining <= 0) {
        return result
      }
      const characters = BarrageEmojiConverter.characters(segment.text)
      if (characters.length <= remaining) {
        result += segment.text
        count += characters.length
      } else {
        result += characters.slice(0, remaining).join('')
        return result
      }
    }
    return result
  }

  private static isRegionalIndicator(codePoint: number): boolean {
    return codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF
  }

  private static isExtend(codePoint: number): boolean {
    return codePoint === 0x200D || codePoint === 0x20E3 ||
      codePoint >= 0x0300 && codePoint <= 0x036F ||
      codePoint >= 0x1AB0 && codePoint <= 0x1AFF ||
      codePoint >= 0x1DC0 && codePoint <= 0x1DFF ||
      codePoint >= 0x20D0 && codePoint <= 0x20FF ||
      codePoint >= 0xFE20 && codePoint <= 0xFE2F ||
      codePoint >= 0xFE00 && codePoint <= 0xFE0F ||
      codePoint >= 0xE0100 && codePoint <= 0xE01EF ||
      codePoint >= 0x1F3FB && codePoint <= 0x1F3FF ||
      codePoint >= 0xE0020 && codePoint <= 0xE007F
  }

  private static appendText(text: string, result: BarrageEmojiSegment[]): void {
    if (text.length > 0) {
      result.push(new BarrageEmojiSegment(text))
    }
  }
}
