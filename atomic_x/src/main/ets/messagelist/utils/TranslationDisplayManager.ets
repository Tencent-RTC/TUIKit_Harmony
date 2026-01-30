/**
 * Translation Display Manager
 * Manages the display state of translation text bubbles.
 *
 * Kotlin/Compose 对齐策略：
 * - **默认展示**：当消息已有翻译结果时，进入消息列表默认展示翻译气泡
 * - **会话内可隐藏**：用户在当前会话中点“隐藏”后，本次会话内不再展示
 * - **非持久化**：退出消息列表后实例销毁，隐藏状态丢失
 *
 * 实现方式：使用“hidden set”模式。
 * - `isExpanded(messageID)` 实际含义为“未被隐藏”，用于兼容既有调用点
 */
@Observed
export class TranslationDisplayManager {
  // Stores message IDs that have been hidden (collapsed) in this session
  private hiddenMessageIDs: Set<string> = new Set();
  // Stores message IDs that are currently translating
  private translatingMessageIDs: Set<string> = new Set();
  // Listeners for state changes
  private listeners: Set<() => void> = new Set();
  // Version counter to trigger UI updates (ArkTS can detect primitive changes)
  public version: number = 0;

  constructor() {}

  /**
   * Check if translation bubble should be considered expanded (i.e., not hidden) for a message.
   * Note: actual rendering should still depend on whether translatedText exists.
   */
  isExpanded(messageID: string | undefined): boolean {
    if (!messageID || messageID.length === 0) {
      return false;
    }
    return !this.hiddenMessageIDs.has(messageID);
  }

  /**
   * Expand (show) translation bubble for a message in this session.
   * With hidden-set semantics, this means removing from hidden set.
   */
  expand(messageID: string | undefined): void {
    if (!messageID || messageID.length === 0) {
      return;
    }
    if (this.hiddenMessageIDs.has(messageID)) {
      this.hiddenMessageIDs.delete(messageID);
      this.version++; // Trigger UI update
      console.log(`[TranslationDisplayManager] 👁️ Show translation bubble for message: ${messageID}, version: ${this.version}`);
      this.notifyListeners();
    }
  }

  /**
   * Collapse (hide) translation bubble for a message in this session.
   * With hidden-set semantics, this means adding to hidden set.
   */
  collapse(messageID: string | undefined): void {
    if (!messageID || messageID.length === 0) {
      return;
    }
    if (!this.hiddenMessageIDs.has(messageID)) {
      this.hiddenMessageIDs.add(messageID);
      this.version++; // Trigger UI update
      console.log(`[TranslationDisplayManager] 🙈 Hide translation bubble for message: ${messageID}, version: ${this.version}`);
      this.notifyListeners();
    }
  }

  /**
   * Check if a message is currently being translated
   */
  isTranslating(messageID: string | undefined): boolean {
    if (!messageID || messageID.length === 0) {
      return false;
    }
    return this.translatingMessageIDs.has(messageID);
  }

  /**
   * Set the translating state for a message.
   * When starting translation, always unhide the bubble so loading state can be shown.
   */
  setTranslating(messageID: string | undefined, translating: boolean): void {
    if (!messageID || messageID.length === 0) {
      return;
    }

    let changed = false;

    if (translating) {
      if (!this.translatingMessageIDs.has(messageID)) {
        this.translatingMessageIDs.add(messageID);
        changed = true;
      }
      // Ensure bubble is visible when translating
      if (this.hiddenMessageIDs.has(messageID)) {
        this.hiddenMessageIDs.delete(messageID);
        changed = true;
      }

      if (changed) {
        this.version++; // Trigger UI update
        console.log(`[TranslationDisplayManager] ⏳ Started translating message: ${messageID}, version: ${this.version}`);
        this.notifyListeners();
      }
    } else {
      if (this.translatingMessageIDs.has(messageID)) {
        this.translatingMessageIDs.delete(messageID);
        changed = true;
      }

      if (changed) {
        this.version++; // Trigger UI update
        console.log(`[TranslationDisplayManager] ✅ Finished translating message: ${messageID}, version: ${this.version}`);
        this.notifyListeners();
      }
    }
  }

  /**
   * Clear all hidden and translating states
   */
  clear(): void {
    if (this.hiddenMessageIDs.size > 0 || this.translatingMessageIDs.size > 0) {
      this.hiddenMessageIDs.clear();
      this.translatingMessageIDs.clear();
      this.version++; // Trigger UI update
      console.log(`[TranslationDisplayManager] 🗑️ Cleared all states, version: ${this.version}`);
      this.notifyListeners();
    }
  }

  /**
   * Add a listener for state changes
   */
  addListener(callback: () => void): void {
    this.listeners.add(callback);
  }

  /**
   * Remove a listener
   */
  removeListener(callback: () => void): void {
    this.listeners.delete(callback);
  }

  /**
   * Notify all listeners of state change
   */
  private notifyListeners(): void {
    console.log(`[TranslationDisplayManager] 📢 Notifying ${this.listeners.size} listeners`);
    this.listeners.forEach((callback) => {
      try {
        callback();
      } catch (error) {
        console.error(`[TranslationDisplayManager] ❌ Listener callback error:`, error);
      }
    });
  }
}
