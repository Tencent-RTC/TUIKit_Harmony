// Process-wide singleton wrapping HarmonyOS `applicationStateChange`.
// Centralised to keep the registration count = 1 per process and avoid state
// divergence between multiple consumers (CallingBellFeature, IncomingNotificationFeature).

import { common } from '@kit.AbilityKit';
import ApplicationStateChangeCallback from '@ohos.app.ability.ApplicationStateChangeCallback';
import { Logger } from '../common/utils/Logger';

type Listener = (isBackground: boolean) => void;

class AppStateObserverImpl {
  private context: common.UIAbilityContext | null = null;
  private listeners: Set<Listener> = new Set();
  private _isBackground: boolean = false;

  private readonly callback: ApplicationStateChangeCallback = {
    onApplicationForeground: (): void => {
      this.updateState(false);
    },
    onApplicationBackground: (): void => {
      this.updateState(true);
    },
  };

  /** Idempotent; must be called from `TUICallKit.init`. */
  init(context: common.UIAbilityContext): void {
    if (this.context) {
      return;
    }
    this.context = context;
    try {
      context.getApplicationContext().on('applicationStateChange', this.callback);
    } catch (e) {
      Logger.warn('AppStateObserver.init: register applicationStateChange failed', e);
    }
  }

  destroy(): void {
    if (!this.context) {
      return;
    }
    try {
      this.context.getApplicationContext().off('applicationStateChange', this.callback);
    } catch (e) {
      Logger.warn('AppStateObserver.destroy: off failed', e);
    }
    this.context = null;
    this.listeners.clear();
  }

  /** Pre-init / post-destroy default = false (assume foreground, the safer path). */
  isBackground(): boolean {
    return this._isBackground;
  }

  addListener(cb: Listener): () => void {
    this.listeners.add(cb);
    return (): void => {
      this.listeners.delete(cb);
    };
  }

  private updateState(isBackground: boolean): void {
    if (this._isBackground === isBackground) {
      return;
    }
    this._isBackground = isBackground;
    // Snapshot in case a listener mutates `listeners` during dispatch.
    const snapshot: Listener[] = Array.from(this.listeners);
    snapshot.forEach((cb): void => {
      try {
        cb(isBackground);
      } catch (e) {
        Logger.warn('AppStateObserver.listener threw', e);
      }
    });
  }
}

const _instance: AppStateObserverImpl = new AppStateObserverImpl();

export function AppStateObserver(): AppStateObserverImpl {
  return _instance;
}
