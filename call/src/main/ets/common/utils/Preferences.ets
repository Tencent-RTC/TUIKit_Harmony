// Wraps @ohos.data.preferences. Getters return defaults synchronously before
// the one-time async init() resolves.

import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { Constants } from '../Constants';
import { Logger } from './Logger';

let store: preferences.Preferences | null = null;

export class Preferences {
  static async init(context: common.Context): Promise<void> {
    if (store) {
      return;
    }
    try {
      store = await preferences.getPreferences(context, Constants.TUI_CALLKIT_PREF_NAME);
    } catch (e) {
      Logger.error('Preferences.init failed', e);
    }
  }

  static async getMuteMode(): Promise<boolean> {
    if (!store) {
      return false;
    }
    try {
      return await store.get(Constants.ENABLE_MUTEMODE_USERDEFAULT, false) as boolean;
    } catch (_e) {
      return false;
    }
  }

  static async setMuteMode(enable: boolean): Promise<void> {
    if (!store) {
      return;
    }
    try {
      await store.put(Constants.ENABLE_MUTEMODE_USERDEFAULT, enable);
      await store.flush();
    } catch (e) {
      Logger.warn('Preferences.setMuteMode failed', e);
    }
  }

  static async getCallingBellPath(): Promise<string> {
    if (!store) {
      return '';
    }
    try {
      return await store.get(Constants.TUI_CALLING_BELL_KEY, '') as string;
    } catch (_e) {
      return '';
    }
  }

  static async setCallingBellPath(path: string): Promise<void> {
    if (!store) {
      return;
    }
    try {
      await store.put(Constants.TUI_CALLING_BELL_KEY, path);
      await store.flush();
    } catch (e) {
      Logger.warn('Preferences.setCallingBellPath failed', e);
    }
  }
}
