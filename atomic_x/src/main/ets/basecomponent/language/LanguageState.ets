import { i18n } from '@kit.LocalizationKit';
import { Configuration } from '@kit.ArkUI';

/**
 * LanguageState - Global language state manager
 * Manages application language settings and RTL/LTR layout direction
 */
@Observed
export class LanguageState {
  private static instance: LanguageState;
  private currentLanguage: string = '';
  private currentLayoutDirection: LayoutDirection = LayoutDirection.LTR;
  private subscribers: Array<(direction: LayoutDirection) => void> = [];
  
  private static readonly RTL_LANGUAGES: string[] = ['ar', 'he', 'fa', 'ur'];

  private constructor() {
    this.initLanguage();
  }

  static getInstance(): LanguageState {
    if (!LanguageState.instance) {
      LanguageState.instance = new LanguageState();
    }
    return LanguageState.instance;
  }

  /**
   * Initialize language state from system configuration
   */
  private initLanguage(): void {
    this.currentLanguage = this.getSystemLanguage();
    this.currentLayoutDirection = this.calculateLayoutDirection(this.currentLanguage);
    this.syncToAppStorage();
  }

  /**
   * Get current system language
   */
  private getSystemLanguage(): string {
    let language: string = Configuration.getLocale().language;
    const preferredLanguage: string = i18n.System.getAppPreferredLanguage();
    if (preferredLanguage && preferredLanguage.length > 0) {
      language = preferredLanguage;
    }
    return language;
  }

  /**
   * Calculate layout direction based on language code
   */
  private calculateLayoutDirection(languageCode: string): LayoutDirection {
    const isRTL: boolean = LanguageState.RTL_LANGUAGES.some((lang: string): boolean => 
      languageCode.startsWith(lang)
    );
    return isRTL ? LayoutDirection.RTL : LayoutDirection.LTR;
  }

  /**
   * Update language and layout direction
   * Should be called after language switch
   */
  updateLanguage(languageCode: string): void {
    console.log(`[LanguageState] 🌐 Updating language to: ${languageCode}`);
    
    this.currentLanguage = languageCode;
    this.currentLayoutDirection = this.calculateLayoutDirection(languageCode);
    
    this.syncToAppStorage();
    this.notifySubscribers();
    
    console.log(`[LanguageState] ✅ Layout direction updated to: ${this.currentLayoutDirection === LayoutDirection.RTL ? 'RTL' : 'LTR'}`);
  }

  /**
   * Sync current state to AppStorage for @StorageLink binding
   */
  private syncToAppStorage(): void {
    AppStorage.setOrCreate('LanguageState', this);
    AppStorage.setOrCreate('layoutDirection', this.currentLayoutDirection);
  }

  /**
   * Subscribe to layout direction changes
   */
  subscribe(callback: (direction: LayoutDirection) => void): void {
    this.subscribers.push(callback);
  }

  /**
   * Unsubscribe from layout direction changes
   */
  unsubscribe(callback: (direction: LayoutDirection) => void): void {
    this.subscribers = this.subscribers.filter(cb => cb !== callback);
  }

  /**
   * Notify all subscribers about layout direction change
   */
  private notifySubscribers(): void {
    console.log(`[LanguageState] 📢 Notifying ${this.subscribers.length} subscribers`);
    this.subscribers.forEach(cb => cb(this.currentLayoutDirection));
  }

  /**
   * Get current language code
   */
  getLanguage(): string {
    return this.currentLanguage;
  }

  /**
   * Get current layout direction
   */
  getLayoutDirection(): LayoutDirection {
    return this.currentLayoutDirection;
  }

  /**
   * Check if current language is RTL
   */
  isRTL(): boolean {
    return this.currentLayoutDirection === LayoutDirection.RTL;
  }

  /**
   * Static method: Check if a language code is RTL
   */
  static isLanguageRTL(languageCode: string): boolean {
    return LanguageState.RTL_LANGUAGES.some((lang: string): boolean => 
      languageCode.startsWith(lang)
    );
  }

  /**
   * Static method: Get layout direction for a language code
   */
  static getLayoutDirectionForLanguage(languageCode: string): LayoutDirection {
    return LanguageState.isLanguageRTL(languageCode) ? LayoutDirection.RTL : LayoutDirection.LTR;
  }
}
