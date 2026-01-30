/**
 * ASR Display Manager
 * Manages the display state of ASR (Automatic Speech Recognition) text bubbles.
 *
 * Kotlin/Compose 对齐策略：
 * - **默认展示**：当消息已有 asrText 时，进入消息列表默认展示 ASR 气泡
 * - **会话内可隐藏**：用户在当前会话中点“隐藏”后，本次会话内不再展示
 * - **非持久化**：退出消息列表后实例销毁，隐藏状态丢失
 *
 * 实现方式：使用“hidden set”模式。
 * - `isExpanded(messageID)` 实际含义为“未被隐藏”，用于兼容既有调用点
 */
@Observed
export class AsrDisplayManager {
  // Stores message IDs that have been hidden (collapsed) in this session
  private hiddenMessageIDs: Set<string> = new Set();
  // Stores message IDs that are currently converting
  private convertingMessageIDs: Set<string> = new Set();
  // Listeners for state changes
  private listeners: Set<() => void> = new Set();
  // Version counter to trigger UI updates (ArkTS can detect primitive changes)
  public version: number = 0;

  constructor() {}

  /**
   * Check if ASR bubble should be considered expanded (i.e., not hidden) for a message.
   * Note: actual rendering should still depend on whether asrText exists.
   */
  isExpanded(messageID: string | undefined): boolean {
    if (!messageID || messageID.length === 0) {
      return false;
    }
    return !this.hiddenMessageIDs.has(messageID);
  }

  /**
   * Expand (show) ASR bubble for a message in this session.
   * With hidden-set semantics, this means removing from hidden set.
   */
  expand(messageID: string | undefined): void {
    if (!messageID || messageID.length === 0) {
      return;
    }
    if (this.hiddenMessageIDs.has(messageID)) {
      this.hiddenMessageIDs.delete(messageID);
      this.version++; // Trigger UI update
      console.log(`[AsrDisplayManager] 👁️ Show ASR bubble for message: ${messageID}, version: ${this.version}`);
      this.notifyListeners();
    }
  }

  /**
   * Collapse (hide) ASR bubble for a message in this session.
   * With hidden-set semantics, this means adding to hidden set.
   */
  collapse(messageID: string | undefined): void {
    if (!messageID || messageID.length === 0) {
      return;
    }
    if (!this.hiddenMessageIDs.has(messageID)) {
      this.hiddenMessageIDs.add(messageID);
      this.version++; // Trigger UI update
      console.log(`[AsrDisplayManager] 🙈 Hide ASR bubble for message: ${messageID}, version: ${this.version}`);
      this.notifyListeners();
    }
  }

  /**
   * Check if a message is currently being converted
   */
  isConverting(messageID: string | undefined): boolean {
    if (!messageID || messageID.length === 0) {
      return false;
    }
    return this.convertingMessageIDs.has(messageID);
  }

  /**
   * Set the converting state for a message.
   * When starting conversion, always unhide the bubble so loading state can be shown.
   */
  setConverting(messageID: string | undefined, converting: boolean): void {
    if (!messageID || messageID.length === 0) {
      return;
    }

    let changed = false;

    if (converting) {
      if (!this.convertingMessageIDs.has(messageID)) {
        this.convertingMessageIDs.add(messageID);
        changed = true;
      }
      // Ensure bubble is visible when converting
      if (this.hiddenMessageIDs.has(messageID)) {
        this.hiddenMessageIDs.delete(messageID);
        changed = true;
      }

      if (changed) {
        this.version++; // Trigger UI update
        console.log(`[AsrDisplayManager] ⏳ Started converting message: ${messageID}, version: ${this.version}`);
        this.notifyListeners();
      }
    } else {
      if (this.convertingMessageIDs.has(messageID)) {
        this.convertingMessageIDs.delete(messageID);
        changed = true;
      }

      if (changed) {
        this.version++; // Trigger UI update
        console.log(`[AsrDisplayManager] ✅ Finished converting message: ${messageID}, version: ${this.version}`);
        this.notifyListeners();
      }
    }
  }

  /**
   * Clear all hidden and converting states
   */
  clear(): void {
    if (this.hiddenMessageIDs.size > 0 || this.convertingMessageIDs.size > 0) {
      this.hiddenMessageIDs.clear();
      this.convertingMessageIDs.clear();
      this.version++; // Trigger UI update
      console.log(`[AsrDisplayManager] 🗑️ Cleared all states, version: ${this.version}`);
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
    console.log(`[AsrDisplayManager] 📢 Notifying ${this.listeners.size} listeners`);
    this.listeners.forEach((callback) => {
      try {
        callback();
      } catch (error) {
        console.error(`[AsrDisplayManager] ❌ Listener callback error:`, error);
      }
    });
  }
}
