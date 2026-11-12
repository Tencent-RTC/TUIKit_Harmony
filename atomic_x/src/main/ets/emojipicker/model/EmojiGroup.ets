export class EmojiGroup {
  id: string;
  name: string;
  desc: string;
  emojiGroupIconUrl: ResourceStr;
  emojis: Emoji[];
  isLittleEmoji: boolean;
  supportReaction: boolean;

  constructor(id: string, name: string, desc: string, emojiGroupIconUrl: ResourceStr, emojis: Emoji[],
    isLittleEmoji: boolean = false, supportReaction?: boolean) {
    this.id = id;
    this.name = name;
    this.desc = desc;
    this.emojiGroupIconUrl = emojiGroupIconUrl;
    this.emojis = emojis;
    this.isLittleEmoji = isLittleEmoji;
    this.supportReaction = supportReaction ?? isLittleEmoji;
  }
}

export class Emoji {
  key: string;
  emojiName: string;
  emojiUrl: ResourceStr;

  constructor(key: string, emojiName: string, emojiUrl: ResourceStr = '') {
    this.key = key;
    this.emojiName = emojiName;
    this.emojiUrl = emojiUrl;
  }
}
