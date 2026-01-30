import { ThemeState } from '../../basecomponent/Index';
import { EmojiDataManager, EmojiItem } from '../../emojipicker/data/EmojiData';
import { preferences } from '@kit.ArkData';

const MAX_QUICK_EMOJI_COUNT = 6;
const RECENT_EMOJI_KEY = 'recent_emojis';

/**
 * Recent Emoji Manager
 * Manages recently used emojis for quick access
 */
export class RecentEmojiManager {
  private static instance: RecentEmojiManager;
  private recentEmojis: string[] = [];
  private preferences?: preferences.Preferences;
  private listeners: Set<() => void> = new Set();

  private constructor() {
    this.loadRecentEmojisSync();
  }

  static getInstance(): RecentEmojiManager {
    if (!RecentEmojiManager.instance) {
      RecentEmojiManager.instance = new RecentEmojiManager();
    }
    return RecentEmojiManager.instance;
  }

  private loadRecentEmojisSync() {
    try {
      const dataPreferences = preferences.getPreferencesSync(getContext(), { name: 'emoji_preferences' });
      this.preferences = dataPreferences;
      const stored = dataPreferences.getSync(RECENT_EMOJI_KEY, '[]') as string;
      this.recentEmojis = JSON.parse(stored);
      console.log(`[ReactionEmoji] 💾 Loaded ${this.recentEmojis.length} recent emoji IDs from storage: [${this.recentEmojis.join(', ')}]`);
    } catch (error) {
      console.error('[ReactionEmoji] ❌ Failed to load recent emojis:', error);
      this.recentEmojis = [];
    }
  }

  addRecentEmoji(emojiId: string) {
    console.log(`[ReactionEmoji] ➕ Adding recent emoji: ${emojiId}`);
    
    // Remove if already exists
    const index = this.recentEmojis.indexOf(emojiId);
    if (index > -1) {
      console.log(`[ReactionEmoji] 🔄 Emoji already exists at index ${index}, moving to front`);
      this.recentEmojis.splice(index, 1);
    }
    
    // Add to front
    this.recentEmojis.unshift(emojiId);
    
    // Keep only last 20
    if (this.recentEmojis.length > 20) {
      this.recentEmojis = this.recentEmojis.slice(0, 20);
    }
    
    console.log(`[ReactionEmoji] 💾 Updated recent emoji IDs (top 6): [${this.recentEmojis.slice(0, 6).join(', ')}]`);
    
    // Save to preferences
    try {
      if (this.preferences) {
        this.preferences.putSync(RECENT_EMOJI_KEY, JSON.stringify(this.recentEmojis));
        this.preferences.flush();
        console.log(`[ReactionEmoji] ✅ Saved to storage successfully`);
      } else {
        console.warn(`[ReactionEmoji] ⚠️ Preferences not initialized, cannot save`);
      }
    } catch (error) {
      console.error('[ReactionEmoji] ❌ Failed to save recent emojis:', error);
    }
    
    // Notify listeners
    console.log(`[ReactionEmoji] 📢 Notifying ${this.listeners.size} listeners`);
    this.notifyListeners();
  }

  getRecentEmojis(): string[] {
    return [...this.recentEmojis];
  }

  addListener(callback: () => void) {
    this.listeners.add(callback);
  }

  removeListener(callback: () => void) {
    this.listeners.delete(callback);
  }

  private notifyListeners() {
    this.listeners.forEach(callback => {
      try {
        callback();
      } catch (error) {
        console.error('[ReactionEmoji] ❌ Error in listener callback:', error);
      }
    });
  }
}

@Component
export struct ReactionEmojiPicker {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  onEmojiClick?: (emoji: EmojiItem) => void;
  onExpandClick?: () => void;
  @State private quickEmojis: EmojiItem[] = [];
  private updateListener: () => void = () => {
    this.loadQuickEmojis();
  };

  aboutToAppear() {
    console.log('[ReactionEmoji] 🚀 Component aboutToAppear - loading quick emojis');
    this.loadQuickEmojis();
    // Register listener for emoji updates
    RecentEmojiManager.getInstance().addListener(this.updateListener);
    console.log('[ReactionEmoji] 👂 Registered listener for emoji updates');
  }

  aboutToDisappear() {
    console.log('[ReactionEmoji] 👋 Component aboutToDisappear - unregistering listener');
    // Unregister listener
    RecentEmojiManager.getInstance().removeListener(this.updateListener);
  }

  private loadQuickEmojis() {
    const recentEmojiIds = RecentEmojiManager.getInstance().getRecentEmojis();
    const allEmojis = EmojiDataManager.getAllEmojis();
    const result: EmojiItem[] = [];

    console.log(`[ReactionEmoji] 📋 Loading quick emojis...`);
    console.log(`[ReactionEmoji] 📋 Recent emoji IDs from storage: [${recentEmojiIds.join(', ')}]`);
    console.log(`[ReactionEmoji] 📋 Total available emojis: ${allEmojis.length}`);

    // Add recent emojis first
    for (const id of recentEmojiIds) {
      if (result.length >= MAX_QUICK_EMOJI_COUNT) break;
      const emoji = EmojiDataManager.getEmojiById(id);
      if (emoji) {
        result.push(emoji);
        console.log(`[ReactionEmoji] ✅ Added recent emoji - ID: ${emoji.id}, Name: ${emoji.name}, Image: ${emoji.imageFile}`);
      } else {
        console.warn(`[ReactionEmoji] ⚠️ Cannot find emoji with ID: ${id} (may have been removed from emoji list)`);
      }
    }

    // Fill with default emojis if not enough recent ones
    if (result.length < MAX_QUICK_EMOJI_COUNT) {
      const needed = MAX_QUICK_EMOJI_COUNT - result.length;
      console.log(`[ReactionEmoji] 🔄 Need ${needed} more emojis, filling with defaults...`);
      for (const emoji of allEmojis) {
        if (result.length >= MAX_QUICK_EMOJI_COUNT) break;
        if (!result.some(e => e.id === emoji.id)) {
          result.push(emoji);
          console.log(`[ReactionEmoji] ➕ Added default emoji - ID: ${emoji.id}, Name: ${emoji.name}`);
        }
      }
    }

    const newQuickEmojis = result.slice(0, MAX_QUICK_EMOJI_COUNT);
    console.log(`[ReactionEmoji] ✨ Final quick emojis (${newQuickEmojis.length}):`);
    newQuickEmojis.forEach((e, index) => {
      console.log(`[ReactionEmoji]   ${index + 1}. ID: ${e.id}, Name: ${e.name}, Image: ${e.imageFile}`);
    });
    
    // Force update the state
    this.quickEmojis = newQuickEmojis;
  }

  build() {
    Row() {
      // Quick emoji items
      ForEach(this.quickEmojis, (emoji: EmojiItem) => {
        this.EmojiItem(emoji)
      }, (emoji: EmojiItem) => emoji.id)

      // Expand button
      Row() {
        Image($rawfile('messagelist/icon_extion_more.png'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
      .width(28)
      .height(28)
      .justifyContent(FlexAlign.Center)
      .borderRadius(8)
      .onClick(() => {
        if (this.onExpandClick) {
          this.onExpandClick();
        }
      })
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.themeState.colors.dropdownColorDefault)
    .borderRadius(16)
  }

  @Builder
  EmojiItem(emoji: EmojiItem) {
    Row() {
      Image(EmojiDataManager.getEmojiImageResource(emoji.imageFile))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    }
    .width(28)
    .height(28)
    .justifyContent(FlexAlign.Center)
    .borderRadius(8)
    .onClick(() => {
      console.log(`[ReactionEmoji] 👆 User clicked emoji - ID: ${emoji.id}, Name: ${emoji.name}, Image: ${emoji.imageFile}`);
      RecentEmojiManager.getInstance().addRecentEmoji(emoji.id);
      if (this.onEmojiClick) {
        console.log(`[ReactionEmoji] 📤 Triggering onEmojiClick callback`);
        this.onEmojiClick(emoji);
      }
    })
    .margin({ right: 8 })
  }
}
