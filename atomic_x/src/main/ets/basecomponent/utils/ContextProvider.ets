import common from '@ohos.app.ability.common'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { Configuration as AbilityConfiguration } from '@kit.AbilityKit'
import { Configuration } from '@kit.ArkUI'
import { ThemeState } from '../theme/ThemeState'
import { LanguageState } from '../language/LanguageState'
import { i18n } from '@kit.LocalizationKit'

/**
 * Global Context Provider
 * Used to provide context to components such as ThemeState and AppBuilderHelper in the application.
 */
export class ContextProvider {
  private static instance: ContextProvider;
  private _appContext: common.Context | null = null;

  private constructor() {
  }

  static getInstance(): ContextProvider {
    if (!ContextProvider.instance) {
      ContextProvider.instance = new ContextProvider();
    }
    return ContextProvider.instance;
  }

  /**
   * Initialize Context
   * @param context Application Context
   */
  static init(context: common.Context): void {
    const provider = ContextProvider.getInstance();
    if (!context) {
      hilog.error(0x0000, 'ContextProvider', 'init context is null');
      return;
    }
    provider._appContext = context;

    // Update the Context configuration (if supported by the Context)
    if ((context as common.UIAbilityContext).config) {
      ContextProvider.initSystemConfig((context as common.UIAbilityContext).config);
    }

    hilog.info(0x0000, 'ContextProvider', 'Context initialized successfully');
  }

  /**
   * Get the application context
   * @returns the application context, or null if uninitialized
   */
  static getAppContext(): common.Context | null {
    const provider = ContextProvider.getInstance();
    if (!provider._appContext) {
      hilog.warn(0x0000, 'ContextProvider', 'Context not initialized, please call init() first');
    }
    return provider._appContext;
  }

  /**
   * Check if the context is initialized
   * @returns true if context is initialized, false otherwise
   */
  static isInitialized(): boolean {
    const provider = ContextProvider.getInstance();
    return provider._appContext !== null;
  }

  /**
   * Handle configuration updates
   * @param newConfig New configuration
   */
  static onConfigurationUpdate(newConfig: AbilityConfiguration): void {
    try {
      // Update the system color mode to AppStorage
      AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
      hilog.info(0x0000, 'ContextProvider', 'Configuration updated - colorMode: %{public}d', newConfig.colorMode);

      // Update the system language to AppStorage
      if (newConfig.language) {
        AppStorage.setOrCreate('currentLanguage', newConfig.language);
        hilog.info(0x0000, 'ContextProvider', 'Configuration updated - language: %{public}s', newConfig.language);
        
        // Notify LanguageState to update layout direction
        ContextProvider.notifyLanguageStateUpdate(newConfig.language);
      }

      // Notify ThemeState to check color mode changes
      ContextProvider.notifyThemeStateUpdate();

      // Update the Context configuration (if supported by the Context)
      const provider = ContextProvider.getInstance();
      if (provider._appContext && (provider._appContext as common.UIAbilityContext).config) {
        (provider._appContext as common.UIAbilityContext).config = newConfig;
      }

    } catch (error) {
      hilog.error(0x0000, 'ContextProvider', 'Failed to update configuration: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Clear the Context (for testing or special scenarios)
   */
  static clear(): void {
    const provider = ContextProvider.getInstance();
    provider._appContext = null;
    hilog.info(0x0000, 'ContextProvider', 'Context cleared');
  }

  /**
   * Initialize system configuration to AppStorage
   * @param config System configuration
   */
  private static initSystemConfig(config: AbilityConfiguration): void {
    try {
      // 设置系统颜色模式到 AppStorage
      AppStorage.setOrCreate('currentColorMode', config.colorMode);
      hilog.info(0x0000, 'ContextProvider', 'System colorMode initialized: %{public}d', config.colorMode);

      // 设置系统语言到 AppStorage
      if (config.language) {
        AppStorage.setOrCreate('currentLanguage', config.language);
        hilog.info(0x0000, 'ContextProvider', 'System language initialized: %{public}s', config.language);
      }
    } catch (error) {
      hilog.error(0x0000, 'ContextProvider', 'Failed to initialize system config: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Notify ThemeState to check for color mode updates
   */
  private static notifyThemeStateUpdate(): void {
    try {
      ThemeState.getInstance().checkCurrentColorMode()
    } catch (error) {
      hilog.warn(0x0000, 'ContextProvider', 'Failed to notify ThemeState: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Notify LanguageState to update layout direction
   */
  private static notifyLanguageStateUpdate(language: string): void {
    try {
      LanguageState.getInstance().updateLanguage(language);
    } catch (error) {
      hilog.warn(0x0000, 'ContextProvider', 'Failed to notify LanguageState: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Check if current language is RTL (Right-to-Left)
   * Supports Arabic (ar), Hebrew (he), Persian (fa), and Urdu (ur)
   * @returns true if current language is RTL, false otherwise
   */
  static isRTL(): boolean {
    return LanguageState.getInstance().isRTL();
  }

  /**
   * Get current layout direction based on language
   * @returns LayoutDirection.RTL for RTL languages, LayoutDirection.LTR otherwise
   */
  static getLayoutDirection(): LayoutDirection {
    return LanguageState.getInstance().getLayoutDirection();
  }
}

/**
 * Convenient method to obtain the application context
 */
export const getAppContext = (): common.Context | null => {
  return ContextProvider.getAppContext();
}

/**
 * Convenient method to check if the Context has been initialized
 */
export const isContextInitialized = (): boolean => {
  return ContextProvider.isInitialized();
}
