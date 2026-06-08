// Toast wrapper that always renders on the HOST app's main Window.
//
// `promptAction.showToast` is a static API — without an explicit UIContext
// it picks the currently-focused window. When the SDK's SubWindow is in
// `fullView`, it captures focus, so a toast issued at call-end (e.g.
// "对方拒绝了你的通话请求") would be parented to the SubWindow and silently
// disappear when SubWindowManager.teardown destroys it ~immediately
// afterwards.
//
// Fix: capture the host's main-window UIContext at SDK `attach(windowStage)`
// time and route every toast through it. The host main Window outlives the
// SubWindow, so toasts survive the SubWindow tear-down.

import window from '@ohos.window';
import { UIContext, promptAction } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

export class Toast {
  private static _hostUIContext: UIContext | null = null;

  /**
   * Bind the host's main-window UIContext. Called by
   * `TUICallKit.attach(windowStage)`.
   */
  static bindHost(windowStage: window.WindowStage): void {
    try {
      const mainWin: window.Window = windowStage.getMainWindowSync();
      Toast._hostUIContext = mainWin.getUIContext();
      Logger.info('Toast.bindHost: host UIContext captured');
    } catch (e) {
      Logger.warn('Toast.bindHost failed', e);
    }
  }

  /** Drop the cached UIContext on `TUICallKit.detach()`. */
  static unbindHost(): void {
    Toast._hostUIContext = null;
  }

  static show(message: string, durationMs: number = 2000): void {
    if (!message) {
      return;
    }
    const opts: promptAction.ShowToastOptions = {
      message,
      duration: durationMs,
      bottom: '10%',
    };
    try {
      if (Toast._hostUIContext) {
        Toast._hostUIContext.getPromptAction().showToast(opts);
      } else {
        // Fallback: SDK was never bound (e.g. error toast fires before
        // attach). The static API picks whichever window is currently
        // focused — tolerable when the SubWindow isn't up yet.
        promptAction.showToast(opts);
      }
    } catch (e) {
      Logger.warn('Toast.show failed', e);
    }
  }

  static showOnTop(message: string, durationMs: number = 2000): void {
    if (!message) {
      return;
    }
    const opts: promptAction.ShowToastOptions = {
      message,
      duration: durationMs,
      bottom: '10%',
    };
    try {
      promptAction.showToast(opts);
    } catch (e) {
      Logger.warn('Toast.showOnTop failed', e);
    }
  }

  static showError(message: string): void {
    Toast.show(message, 2500);
  }
}
