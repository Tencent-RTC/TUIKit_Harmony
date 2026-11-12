import common from '@ohos.app.ability.common';
import resourceManager from '@ohos.resourceManager';
import { i18n } from '@kit.LocalizationKit';
import { getAppContext } from '../basecomponent/utils/ContextProvider';
import { EmojiDataManager, EmojiItem } from './data/EmojiData';
import { Emoji, EmojiGroup } from './model/EmojiGroup';

export class EmojiManager {
  static readonly BUILT_IN_EMOJI_GROUP_ID: string = 'tui_built_in_little_emoji';
  static readonly EMOJI_GROUP_STATE_KEY: string = 'EmojiGroupState';
  private static readonly SHIPPED_EMOJI_LOCALES: string[] = ['en', 'zh-Hans-CN', 'zh-Hant-TW', 'ar-SA'];
  private static readonly CHINESE_ELEMENT_EMOJI_KEYS: Set<string> = new Set<string>([
    '[TUIEmoji_Rich]', '[TUIEmoji_Bless]', '[TUIEmoji_Fortune]', '[TUIEmoji_Convinced]',
    '[TUIEmoji_Prohibit]', '[TUIEmoji_666]', '[TUIEmoji_857]'
  ]);
  private static instance: EmojiManager | null = null;
  private appContext: common.Context | null = null;
  private emojiNamesLoadedLanguageTag: string | undefined = undefined;
  private _emojiGroupList: EmojiGroup[] = [];
  private emojiByKeyMap: Map<string, Emoji> = new Map<string, Emoji>();
  private emojiByNameMap: Map<string, Emoji> = new Map<string, Emoji>();
  private allLocaleEmojiNamesLoaded: boolean = false;
  private _sortedLittleEmojiList: Emoji[] = [];
  private _sortedLittleEmojiKeyList: string[] = [];
  private _sortedLittleEmojiNameList: string[] = [];
  private _emojiIndexVersion: number = 0;

  private constructor() {
    const appContext = getAppContext();
    if (appContext === null) {
      console.error('EmojiManager init failed: application context is null');
      return;
    }
    const builtInEmojiGroup = this.loadBuiltInEmojiGroup(appContext);
    if (builtInEmojiGroup) {
      this.appContext = appContext;
      this._emojiGroupList.push(builtInEmojiGroup);
      this.rebuildEmojiIndex();
      this.emojiNamesLoadedLanguageTag = this.currentLanguageTag();
    }
  }

  static getInstance(): EmojiManager {
    if (!EmojiManager.instance) {
      EmojiManager.instance = new EmojiManager();
    }
    return EmojiManager.instance;
  }

  get emojiIndexVersion(): number {
    this.reloadEmojiNamesIfLocaleChanged();
    return this._emojiIndexVersion;
  }

  get sortedLittleEmojiList(): Emoji[] {
    this.reloadEmojiNamesIfLocaleChanged();
    return this._sortedLittleEmojiList.slice();
  }

  get sortedLittleEmojiKeyList(): string[] {
    return this._sortedLittleEmojiKeyList.slice();
  }

  get sortedLittleEmojiNameList(): string[] {
    this.ensureAllLocaleEmojiNamesLoaded();
    return this._sortedLittleEmojiNameList.slice();
  }

  get reactionEmojiGroup(): EmojiGroup | undefined {
    return this._emojiGroupList.find((group: EmojiGroup) => group.supportReaction);
  }

  get reactionEmojiList(): Emoji[] {
    return this.reactionEmojiGroup?.emojis ?? [];
  }

  get emojiGroupList(): EmojiGroup[] {
    this.reloadEmojiNamesIfLocaleChanged();
    return this._emojiGroupList.slice();
  }

  addEmojiGroup(emojiGroup: EmojiGroup, index: number = -1): EmojiManager {
    const groups = this._emojiGroupList.filter((group: EmojiGroup) => group.id !== emojiGroup.id);
    groups.splice(this.coerceInsertIndex(index, groups.length), 0, emojiGroup);
    this._emojiGroupList = groups;
    this.rebuildEmojiIndex();
    return this;
  }

  addEmojiGroups(emojiGroups: EmojiGroup[]): EmojiManager {
    const uniqueEmojiGroups = new Map<string, EmojiGroup>();
    emojiGroups.forEach((group: EmojiGroup) => uniqueEmojiGroups.set(group.id, group));
    const groups = this._emojiGroupList.filter((group: EmojiGroup) => !uniqueEmojiGroups.has(group.id));
    uniqueEmojiGroups.forEach((group: EmojiGroup) => groups.push(group));
    this._emojiGroupList = groups;
    this.rebuildEmojiIndex();
    return this;
  }

  removeEmojiGroup(emojiGroup: string | EmojiGroup): EmojiManager {
    const id = typeof emojiGroup === 'string' ? emojiGroup : emojiGroup.id;
    const groups = this._emojiGroupList.filter((group: EmojiGroup) => group.id !== id);
    if (groups.length !== this._emojiGroupList.length) {
      this._emojiGroupList = groups;
      this.rebuildEmojiIndex();
    }
    return this;
  }

  removeEmojiGroups(emojiGroups: EmojiGroup[]): EmojiManager {
    const ids = new Set<string>(emojiGroups.map((group: EmojiGroup) => group.id));
    const groups = this._emojiGroupList.filter((group: EmojiGroup) => !ids.has(group.id));
    if (groups.length !== this._emojiGroupList.length) {
      this._emojiGroupList = groups;
      this.rebuildEmojiIndex();
    }
    return this;
  }

  clearEmojiGroups(): EmojiManager {
    if (this._emojiGroupList.length > 0) {
      this._emojiGroupList = [];
      this.rebuildEmojiIndex();
    }
    return this;
  }

  getEmojiGroup(groupId: string): EmojiGroup | undefined {
    return this._emojiGroupList.find((group: EmojiGroup) => group.id === groupId);
  }

  getEmojiGroups(): EmojiGroup[] {
    return this._emojiGroupList.slice();
  }

  containsEmojiGroup(groupId: string): boolean {
    return this.getEmojiGroup(groupId) !== undefined;
  }

  moveEmojiGroup(groupId: string, toIndex: number): EmojiManager {
    const position = this._emojiGroupList.findIndex((group: EmojiGroup) => group.id === groupId);
    if (position >= 0) {
      const target = Math.min(Math.max(toIndex, 0), this._emojiGroupList.length - 1);
      if (target !== position) {
        const groups = this._emojiGroupList.slice();
        const moved = groups.splice(position, 1);
        groups.splice(target, 0, moved[0]);
        this._emojiGroupList = groups;
        this.rebuildEmojiIndex();
      }
    }
    return this;
  }

  findEmojiByKey(key: string): Emoji | undefined {
    return this.emojiByKeyMap.get(key);
  }

  findEmojiByName(name: string): Emoji | undefined {
    this.ensureAllLocaleEmojiNamesLoaded();
    return this.emojiByNameMap.get(name);
  }

  containsEmojiKey(text: string): boolean {
    return this._sortedLittleEmojiKeyList.some((key: string) => text.includes(key));
  }

  isChineseLocale(): boolean {
    if (this.appContext === null) {
      return false;
    }
    return this.currentLanguageTag().toLowerCase().startsWith('zh');
  }

  isEmojiVisibleInPicker(key: string): boolean {
    if (this.isChineseLocale()) {
      return true;
    }
    return !EmojiManager.CHINESE_ELEMENT_EMOJI_KEYS.has(key);
  }

  filterEmojiGroupsForPicker(groups: EmojiGroup[]): EmojiGroup[] {
    if (this.isChineseLocale()) {
      return groups;
    }
    return groups.map((group: EmojiGroup): EmojiGroup => {
      if (group.id !== EmojiManager.BUILT_IN_EMOJI_GROUP_ID) {
        return group;
      }
      return this.copyEmojiGroup(group,
        group.emojis.filter((emoji: Emoji) => !EmojiManager.CHINESE_ELEMENT_EMOJI_KEYS.has(emoji.key)));
    });
  }

  reactionEmojiListForPicker(): Emoji[] {
    const group = this.reactionEmojiGroup;
    if (!group) {
      return [];
    }
    if (this.isChineseLocale() || group.id !== EmojiManager.BUILT_IN_EMOJI_GROUP_ID) {
      return group.emojis;
    }
    return group.emojis.filter((emoji: Emoji) => !EmojiManager.CHINESE_ELEMENT_EMOJI_KEYS.has(emoji.key));
  }

  private reloadEmojiNamesIfLocaleChanged(): void {
    const context = this.appContext;
    if (context === null) {
      return;
    }
    const languageTag = this.currentLanguageTag();
    if (this.emojiNamesLoadedLanguageTag === languageTag) {
      return;
    }
    const groupIndex = this._emojiGroupList.findIndex((group: EmojiGroup) =>
      group.id === EmojiManager.BUILT_IN_EMOJI_GROUP_ID);
    if (groupIndex < 0) {
      this.emojiNamesLoadedLanguageTag = languageTag;
      return;
    }
    const builtInGroup = this._emojiGroupList[groupIndex];
    const localizedEmojis = builtInGroup.emojis.map((emoji: Emoji): Emoji => {
      const localizedName = this.localizedEmojiName(context.resourceManager, emoji.key);
      return localizedName !== undefined && localizedName !== emoji.emojiName ?
        new Emoji(emoji.key, localizedName, emoji.emojiUrl) : emoji;
    });
    const groups = this._emojiGroupList.slice();
    groups[groupIndex] = this.copyEmojiGroup(builtInGroup, localizedEmojis);
    this._emojiGroupList = groups;
    this.emojiNamesLoadedLanguageTag = languageTag;
    this.rebuildEmojiIndex();
  }

  private currentLanguageTag(): string {
    return i18n.System.getAppPreferredLanguage();
  }

  private localizedEmojiName(manager: resourceManager.ResourceManager, key: string): string | undefined {
    try {
      const name = manager.getStringByNameSync(key.replace(/^\[|\]$/g, ''));
      return name ? `[${name}]` : undefined;
    } catch (e) {
      return undefined;
    }
  }

  private loadBuiltInEmojiGroup(context: common.Context): EmojiGroup | undefined {
    const emojis = EmojiDataManager.getAllEmojis().map((item: EmojiItem): Emoji =>
      new Emoji(item.name, this.localizedEmojiName(context.resourceManager, item.name) ?? item.name,
        EmojiDataManager.getEmojiImageResource(item.imageFile)));
    if (emojis.length === 0) {
      return undefined;
    }
    return new EmojiGroup(EmojiManager.BUILT_IN_EMOJI_GROUP_ID, 'LittleYellowFaceEmoji', '', emojis[0].emojiUrl,
      emojis, true);
  }

  private copyEmojiGroup(group: EmojiGroup, emojis: Emoji[]): EmojiGroup {
    return new EmojiGroup(group.id, group.name, group.desc, group.emojiGroupIconUrl, emojis, group.isLittleEmoji,
      group.supportReaction);
  }

  private coerceInsertIndex(index: number, size: number): number {
    return index < 0 || index > size ? size : index;
  }

  private rebuildEmojiIndex(): void {
    this.emojiByKeyMap.clear();
    const allGroups = this._emojiGroupList.slice();
    const littleEmojis: Emoji[] = [];
    allGroups.forEach((group: EmojiGroup) => {
      group.emojis.forEach((emoji: Emoji) => {
        this.emojiByKeyMap.set(emoji.key, emoji);
        if (group.isLittleEmoji) {
          littleEmojis.push(emoji);
        }
      });
    });

    this.emojiByNameMap.clear();
    littleEmojis.forEach((emoji: Emoji) => this.emojiByNameMap.set(emoji.emojiName, emoji));
    this.allLocaleEmojiNamesLoaded = false;
    this._sortedLittleEmojiNameList = this.sortedByLengthDescending(Array.from(this.emojiByNameMap.keys()));

    this._sortedLittleEmojiList = littleEmojis.slice().sort((a: Emoji, b: Emoji) => b.key.length - a.key.length);
    this._sortedLittleEmojiKeyList = this._sortedLittleEmojiList.map((emoji: Emoji) => emoji.key);
    AppStorage.setOrCreate<EmojiGroup[]>(EmojiManager.EMOJI_GROUP_STATE_KEY, allGroups);
    this._emojiIndexVersion += 1;
  }

  private ensureAllLocaleEmojiNamesLoaded(): void {
    if (this.allLocaleEmojiNamesLoaded) {
      return;
    }
    const context = this.appContext;
    if (context === null) {
      return;
    }
    this.allLocaleEmojiNamesLoaded = true;
    try {
      EmojiManager.SHIPPED_EMOJI_LOCALES.forEach((locale: string) => {
        const config = context.resourceManager.getOverrideConfiguration();
        config.locale = locale;
        const localeManager = context.resourceManager.getOverrideResourceManager(config);
        EmojiDataManager.getAllEmojis().forEach((item: EmojiItem) => {
          const emoji = this.emojiByKeyMap.get(item.name);
          const name = this.localizedEmojiName(localeManager, item.name);
          if (emoji && name !== undefined && !this.emojiByNameMap.has(name)) {
            this.emojiByNameMap.set(name, emoji);
          }
        });
      });
    } catch (e) {
      console.error(`EmojiManager load emoji names failed: ${JSON.stringify(e)}`);
    }
    this._sortedLittleEmojiNameList = this.sortedByLengthDescending(Array.from(this.emojiByNameMap.keys()));
  }

  private sortedByLengthDescending(values: string[]): string[] {
    return values.sort((a: string, b: string) => b.length - a.length);
  }
}
