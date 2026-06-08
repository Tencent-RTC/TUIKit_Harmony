// Flips `setWindowKeepScreenOn` around the call lifecycle.
//
// Lock-screen wake-up is NOT handled here — HarmonyOS NEXT does not expose a
// public `setShowOnLockScreen` on `window.Window`; that path is delegated to
// the SOCIAL_COMMUNICATION notification slot via `IncomingNotificationFeature`.

import { common } from '@kit.AbilityKit';
import window from '@ohos.window';
import { Logger } from '../common/utils/Logger';

class ScreenStateManagerImpl {
  private context: common.UIAbilityContext | null = null;
  private currentlyOn: boolean = false;

  init(context: common.UIAbilityContext): void {
    this.context = context;
  }

  async beginCall(): Promise<void> {
    if (this.currentlyOn) {
      return;
    }
    if (!this.context) {
      Logger.warn('ScreenStateManager.beginCall: not initialized');
      return;
    }
    this.currentlyOn = true;
    await this.applyFlags(true);
  }

  async endCall(): Promise<void> {
    if (!this.currentlyOn) {
      return;
    }
    this.currentlyOn = false;
    if (!this.context) {
      return;
    }
    await this.applyFlags(false);
  }

  private async applyFlags(on: boolean): Promise<void> {
    if (!this.context) {
      return;
    }
    let win: window.Window;
    try {
      win = await window.getLastWindow(this.context);
    } catch (e) {
      Logger.warn('ScreenStateManager.applyFlags: getLastWindow failed', e);
      return;
    }

    try {
      await win.setWindowKeepScreenOn(on);
    } catch (e) {
      // May throw on devices without SystemCapability.Window.SessionManager;
      // never block the call flow.
      Logger.warn('ScreenStateManager.applyFlags: setWindowKeepScreenOn failed', on, e);
    }
  }
}

const _instance: ScreenStateManagerImpl = new ScreenStateManagerImpl();

export function ScreenStateManager(): ScreenStateManagerImpl {
  return _instance;
}
