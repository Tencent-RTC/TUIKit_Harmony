import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { ThemeMode } from '../theme/ThemeState';
import { ContextProvider, getAppContext } from './ContextProvider';
import dataPreferences from '@ohos.data.preferences';
import { i18n } from '@kit.LocalizationKit';
import { Configuration } from '@kit.ArkUI';

export enum MessageAlignment {
  LEFT = 'left',
  RIGHT = 'right',
  TWO_SIDED = 'two-sided'
}

export enum MessageAction {
  COPY = 'copy',
  RECALL = 'recall',
  DELETE = 'delete',
  FORWARD = 'forward',
  MULTISELECT = 'multiselect'
}

export enum ConversationAction {
  DELETE = 'delete',
  MUTE = 'mute',
  PIN = 'pin',
  MARK_UNREAD = 'markUnread',
  CLEAR_HISTORY = 'clearHistory'
}


export enum GlobalAvatarShape {
  CIRCULAR = 'circular',
  SQUARE = 'square',
  ROUNDED = 'rounded'
}

export class AppBuilderConfig {
  private static instance: AppBuilderConfig | null = null;
  private static configLoaded: boolean = false;
  public themeMode: ThemeMode = ThemeMode.system;
  public primaryColor: string = '#1C66E5';
  public messageAlignment: MessageAlignment = MessageAlignment.TWO_SIDED;
  public messageActionList: MessageAction[] = [MessageAction.COPY, MessageAction.RECALL, MessageAction.DELETE];
  public enableCreateConversation: boolean = true;
  public conversationActionList: ConversationAction[] =
    [ConversationAction.DELETE, ConversationAction.MUTE, ConversationAction.PIN, ConversationAction.MARK_UNREAD,
      ConversationAction.CLEAR_HISTORY];
  public hideSendButton: boolean = false;
  public hideSearch: boolean = false;
  public enableReadReceipt: boolean = false;
  public avatarShape: GlobalAvatarShape = GlobalAvatarShape.CIRCULAR;
  public translateTargetLanguage: string = '';
  /**
   * Use classic UI style for the entire app
   * When true: classic floating popup for message actions, classic input bar, etc.
   * When false: modern full-screen dialog style (default)
   */
  public useClassicUI: boolean = false;

  private constructor() {
  }

  public setEnableReadReceipt(enable: boolean): void {
    this.enableReadReceipt = enable;
    try {
      const context = getAppContext();
      if (context) {
        const pref = dataPreferences.getPreferencesSync(context, { name: 'AppBuilderConfig' });
        pref.putSync('EnableReadReceipt', enable);
        pref.flushSync();
      }
    } catch (e) {
      console.error('Failed to save enableReadReceipt to preferences', e);
    }
  }

  public setUseClassicUI(enable: boolean): void {
    this.useClassicUI = enable;
    try {
      const context = getAppContext();
      if (context) {
        const pref = dataPreferences.getPreferencesSync(context, { name: 'AppBuilderConfig' });
        pref.putSync('UseClassicUI', enable);
        pref.flushSync();
        console.log(`[AppBuilderConfig] Saved useClassicUI: ${enable}`);
      }
    } catch (e) {
      console.error('Failed to save useClassicUI to preferences', e);
    }
  }

  public setTranslateTargetLanguage(language: string): void {
    this.translateTargetLanguage = language;
    try {
      const context = getAppContext();
      if (context) {
        const pref = dataPreferences.getPreferencesSync(context, { name: 'AppBuilderConfig' });
        pref.putSync('TranslateTargetLanguage', language);
        pref.flushSync();
        console.log(`[AppBuilderConfig] Saved translateTargetLanguage: ${language}`);
      }
    } catch (e) {
      console.error('Failed to save translateTargetLanguage to preferences', e);
    }
  }

  public getTranslateTargetLanguage(): string {
    if (this.translateTargetLanguage) {
      return this.translateTargetLanguage;
    }
    
    // Return default language if not set
    return this.getDefaultTranslateLanguage();
  }

  private getDefaultTranslateLanguage(): string {
    try {
      // Get device current language using the same method as SettingsPage
      let currentLanguage: string = Configuration.getLocale().language;
      
      // Check if app has preferred language set
      const preferredLanguage = i18n.System.getAppPreferredLanguage();
      if (preferredLanguage && preferredLanguage.length > 0) {
        currentLanguage = preferredLanguage;
      }
      
      const supportedLanguages = ['zh', 'en', 'ja', 'ko', 'fr', 'de', 'es', 'it', 'pt', 'ru', 'tr', 'vi', 'id', 'th', 'ms', 'hi'];
      
      // Extract language code (e.g., "zh-CN" -> "zh")
      const langCode: string = currentLanguage.split('-')[0] || 'en';
      
      if (supportedLanguages.includes(langCode)) {
        console.log(`[AppBuilderConfig] Default translate language from device: ${langCode}`);
        return langCode;
      }
    } catch (e) {
      console.error('[AppBuilderConfig] Failed to get default translate language', e);
    }
    
    // Default to English if device language not supported
    console.log('[AppBuilderConfig] Using fallback translate language: en');
    return 'en';
  }

  public static resetConfigLoadedFlag(): void {
    AppBuilderConfig.configLoaded = false;
  }

  public static getInstance(): AppBuilderConfig {
    if (!AppBuilderConfig.instance) {
      AppBuilderConfig.instance = new AppBuilderConfig();
    }
    if (!AppBuilderConfig.configLoaded) {
      AppBuilderConfig.instance.loadConfigFromProvider();
    }
    return AppBuilderConfig.instance;
  }

  private loadConfigFromProvider(): void {
    if (AppBuilderConfig.configLoaded) {
      return;
    }

    const context = getAppContext();
    if (context && (context as common.UIAbilityContext).resourceManager) {
      this.loadConfigFromContext(context as common.UIAbilityContext);
    } else {
    }

    try {
      if (context) {
        const pref = dataPreferences.getPreferencesSync(context, { name: 'AppBuilderConfig' });
        if (pref.hasSync('EnableReadReceipt')) {
          this.enableReadReceipt = pref.getSync('EnableReadReceipt', false) as boolean;
        }
        if (pref.hasSync('UseClassicUI')) {
          this.useClassicUI = pref.getSync('UseClassicUI', false) as boolean;
          console.log(`[AppBuilderConfig] Loaded useClassicUI: ${this.useClassicUI}`);
        }
        if (pref.hasSync('TranslateTargetLanguage')) {
          this.translateTargetLanguage = pref.getSync('TranslateTargetLanguage', '') as string;
          console.log(`[AppBuilderConfig] Loaded translateTargetLanguage: ${this.translateTargetLanguage}`);
        } else {
          // Set default language if not saved before
          this.translateTargetLanguage = this.getDefaultTranslateLanguage();
          console.log(`[AppBuilderConfig] Using default translateTargetLanguage: ${this.translateTargetLanguage}`);
        }
      }
    } catch (e) {
      console.error('Failed to load from preferences', e);
    }

    AppBuilderConfig.configLoaded = true;
  }

  private loadConfigFromContext(context: common.UIAbilityContext): void {
    try {
      const content = context.resourceManager.getRawFileContentSync('appConfig.json');
      const uint8Array = new Uint8Array(content.buffer);
      const jsonString = AppBuilderHelper.uint8ArrayToString(uint8Array);
      const json = JSON.parse(jsonString) as Record<string, ESObject>;

      AppBuilderHelper.parseConfigForInstance(json, this);
      console.log('loadConfigFromContext success from context');
    } catch (error) {
      console.log(' AppBuilderConfig load filed:', error);
    }
  }
}

export class AppBuilderHelper {
  private static configLoadAttempted: boolean = false;

  public static setAppConfig(context?: common.UIAbilityContext): void {

    if (AppBuilderHelper.configLoadAttempted) {
      console.log('[AppBuilderHelper] The configuration has been loaded, skipping the reload');
      return;
    }

    AppBuilderHelper.configLoadAttempted = true;

    let targetContext = context;
    if (!targetContext) {
      const appContext = ContextProvider.getAppContext();
      if (appContext && (appContext as common.UIAbilityContext).resourceManager) {
        targetContext = appContext as common.UIAbilityContext;
      }
    }

    if (!targetContext) {
      console.log('[AppBuilderHelper] No Context available, using default configuration');
      return;
    }

    try {
      const content = targetContext.resourceManager.getRawFileContentSync('appConfig.json');
      const uint8Array = new Uint8Array(content.buffer);
      const jsonString = AppBuilderHelper.uint8ArrayToString(uint8Array);
      const json = JSON.parse(jsonString) as Record<string, ESObject>;

      AppBuilderHelper.parseConfig(json);
      console.log('[AppBuilderHelper] Successfully loaded the application configuration file');
    } catch (error) {
      console.log('[AppBuilderHelper]Failed to load the configuration file:', error);
    }
  }


  public static forceReloadConfig(context?: common.UIAbilityContext): void {
    AppBuilderHelper.configLoadAttempted = false;
    AppBuilderConfig.resetConfigLoadedFlag();
    AppBuilderHelper.setAppConfig(context);
  }

  public static setJsonPath(path: string): void {
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(path);
      const fileSize = stat.size;
      const arrayBuffer = new ArrayBuffer(fileSize);
      const readLen = fs.readSync(file.fd, arrayBuffer);
      fs.closeSync(file);
      if (readLen <= 0) {
        return;
      }

      const uint8Array = new Uint8Array(arrayBuffer, 0, readLen);
      const jsonString = AppBuilderHelper.uint8ArrayToString(uint8Array);
      const json = JSON.parse(jsonString) as Record<string, ESObject>;

      AppBuilderHelper.parseConfig(json);
    } catch (error) {
    }
  }

  public static uint8ArrayToString(uint8Array: Uint8Array): string {
    let result = '';
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }
    return result;
  }

  public static parseConfigForInstance(json: Record<string, ESObject>, config: AppBuilderConfig): void {
    if (json['theme'] && typeof json['theme'] === 'object') {
      const theme = json['theme'] as Record<string, ESObject>;

      if (theme['mode'] && typeof theme['mode'] === 'string') {
        const modeString = theme['mode'] as string;
        const themeType = AppBuilderHelper.getThemeTypeFromString(modeString);
        if (themeType !== null) {
          config.themeMode = themeType;
        }
      }

      if (theme['primaryColor'] && typeof theme['primaryColor'] === 'string') {
        config.primaryColor = theme['primaryColor'] as string;
      }
    }


    if (json['messageList'] && typeof json['messageList'] === 'object') {
      const messageList = json['messageList'] as Record<string, ESObject>;

      if (messageList['alignment'] && typeof messageList['alignment'] === 'string') {
        const alignmentString = messageList['alignment'] as string;
        const alignment = AppBuilderHelper.getMessageAlignmentFromString(alignmentString);
        if (alignment !== null) {
          config.messageAlignment = alignment;
        }
      }

      if (typeof messageList['enableReadReceipt'] === 'boolean') {
        config.enableReadReceipt = messageList['enableReadReceipt'] as boolean;
      }

      if (messageList['messageActionList'] && Array.isArray(messageList['messageActionList'])) {
        const actionList = messageList['messageActionList'] as string[];
        config.messageActionList = actionList
          .map(action => AppBuilderHelper.getMessageActionFromString(action))
          .filter(action => action !== null) as MessageAction[];
      }
    }


    if (json['conversationList'] && typeof json['conversationList'] === 'object') {
      const conversationList = json['conversationList'] as Record<string, ESObject>;

      if (typeof conversationList['enableCreateConversation'] === 'boolean') {
        config.enableCreateConversation = conversationList['enableCreateConversation'] as boolean;
      }

      if (conversationList['conversationActionList'] && Array.isArray(conversationList['conversationActionList'])) {
        const actionList = conversationList['conversationActionList'] as string[];
        config.conversationActionList = actionList
          .map(action => AppBuilderHelper.getConversationActionFromString(action))
          .filter(action => action !== null) as ConversationAction[];
      }
    }


    if (json['messageInput'] && typeof json['messageInput'] === 'object') {
      const messageInput = json['messageInput'] as Record<string, ESObject>;

      if (messageInput['hideSendButton'] && typeof messageInput['hideSendButton'] === 'boolean') {
        config.hideSendButton = messageInput['hideSendButton'] as boolean;
      }

      // if (messageInput['attachmentPickerMode'] && typeof messageInput['attachmentPickerMode'] === 'string') {
      //   const modeString = messageInput['attachmentPickerMode'] as string;
      //   const mode = this.getAttachmentPickerModeFromString(modeString);
      //   if (mode !== null) {
      //     config.attachmentPickerMode = mode;
      //   }
      // }
    }


    if (json['search'] && typeof json['search'] === 'object') {
      const search = json['search'] as Record<string, ESObject>;

      if (search['hideSearch'] && typeof search['hideSearch'] === 'boolean') {
        config.hideSearch = search['hideSearch'] as boolean;
      }
    }


    if (json['avatar'] && typeof json['avatar'] === 'object') {
      const avatar = json['avatar'] as Record<string, ESObject>;

      if (avatar['shape'] && typeof avatar['shape'] === 'string') {
        const shapeString = avatar['shape'] as string;
        const shape = AppBuilderHelper.getGlobalAvatarShapeFromString(shapeString);
        if (shape !== null) {
          config.avatarShape = shape;
        }
      }
    }

    console.log('parseConfig success');
  }

  private static parseConfig(json: Record<string, ESObject>): void {
    const config = AppBuilderConfig.getInstance();
    AppBuilderHelper.parseConfigForInstance(json, config);
  }

  private static getThemeTypeFromString(value: string): ThemeMode | null {
    switch (value) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  private static getMessageAlignmentFromString(value: string): MessageAlignment | null {
    switch (value) {
      case 'left':
        return MessageAlignment.LEFT;
      case 'right':
        return MessageAlignment.RIGHT;
      case 'two-sided':
        return MessageAlignment.TWO_SIDED;
      default:
        return null;
    }
  }


  private static getMessageActionFromString(value: string): MessageAction | null {
    switch (value) {
      case 'copy':
        return MessageAction.COPY;
      case 'recall':
        return MessageAction.RECALL;
      case 'delete':
        return MessageAction.DELETE;
      case 'forward':
        return MessageAction.FORWARD;
      case 'multiselect':
        return MessageAction.MULTISELECT;
      default:
        return null;
    }
  }


  private static getConversationActionFromString(value: string): ConversationAction | null {
    switch (value) {
      case 'delete':
        return ConversationAction.DELETE;
      case 'mute':
        return ConversationAction.MUTE;
      case 'pin':
        return ConversationAction.PIN;
      case 'markUnread':
        return ConversationAction.MARK_UNREAD;
      case 'clearHistory':
        return ConversationAction.CLEAR_HISTORY;
      default:
        return null;
    }
  }


  private static getGlobalAvatarShapeFromString(value: string): GlobalAvatarShape | null {
    switch (value) {
      case 'circular':
        return GlobalAvatarShape.CIRCULAR;
      case 'square':
        return GlobalAvatarShape.SQUARE;
      case 'rounded':
        return GlobalAvatarShape.ROUNDED;
      default:
        return null;
    }
  }


  // private static getAttachmentPickerModeFromString(value: string): AttachmentPickerMode | null {
  //   switch (value) {
  //     case 'collapsed': return AttachmentPickerMode.COLLAPSED;
  //     case 'expanded': return AttachmentPickerMode.EXPANDED;
  //     default: return null;
  //   }
  // }
}
