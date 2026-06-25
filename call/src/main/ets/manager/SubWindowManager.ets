import window from '@ohos.window';
import display from '@ohos.display';
import { ViewState, CallRoute } from '../state/ViewState';
import { Logger } from '../common/utils/Logger';
import { RouterManager } from './RouterManager';
import { TUI_CALLKIT_OVERLAY_ROUTE_NAME } from '../pages/CallKitOverlayPage';

const SUB_WINDOW_NAME: string = 'TUICallKitSubWindow';
const BANNER_HORIZONTAL_INSET_VP: number = 8;
const BANNER_HEIGHT_VP: number = 92;
const BANNER_TOP_OFFSET_VP: number = 48;

export class SubWindowManager {
  private static _instance: SubWindowManager | null = null;

  static shared(): SubWindowManager {
    if (!SubWindowManager._instance) {
      SubWindowManager._instance = new SubWindowManager();
    }
    return SubWindowManager._instance;
  }

  private _windowStage: window.WindowStage | null = null;
  private _subWindow: window.Window | null = null;
  private _avoidAreaListener: ((data: window.AvoidAreaOptions) => void) | null = null;
  private _origStatusBarColor: string | null = null;
  private _currentRoute: CallRoute = CallRoute.none;
  private _ensuringWindow: boolean = false;

  /**
   * Bind the host's WindowStage so subsequent route transitions can spawn
   * SubWindows on demand. Idempotent.
   */
  attach(windowStage: window.WindowStage): void {
    if (this._windowStage !== null) {
      Logger.info('SubWindowManager.attach: already attached, replacing windowStage');
      this.detach();
    }
    this._windowStage = windowStage;

    // Subscribe to ViewState.router changes via RouterManager (the single
    // mutator). RouterManager forwards every transition to us.
    RouterManager.bindRouteListener((next: CallRoute): void => {
      this.applyRoute(next);
    });

    // Replay any in-flight route (e.g. cold-start dispatched a banner before
    // attach finished).
    const r = ViewState().router;
    if (r !== CallRoute.none) {
      this.applyRoute(r);
    }

    Logger.info('SubWindowManager.attach: success');
  }

  /** Must be called from `onWindowStageDestroy`. */
  detach(): void {
    RouterManager.bindRouteListener(null);
    this.applyRoute(CallRoute.none);
    this._windowStage = null;
    Logger.info('SubWindowManager.detach: success');
  }

  /**
   * Apply a new route. Each branch is idempotent.
   */
  private applyRoute(next: CallRoute): void {
    if (next === this._currentRoute && this._subWindow !== null) {
      return;
    }
    Logger.info('SubWindowManager.applyRoute:', this._currentRoute, '->', next);
    this._currentRoute = next;

    if (next === CallRoute.none) {
      void this.teardownSubWindow();
      return;
    }

    void this.ensureSubWindow().then((win: window.Window | null): void => {
      if (win === null) {
        return;
      }
      // Re-check the current route — ensureSubWindow is async; the user may
      // have transitioned again (e.g. banner → none on auto-reject).
      if (this._currentRoute === CallRoute.banner) {
        this.applyBannerGeometry(win);
      } else if (this._currentRoute === CallRoute.fullView) {
        this.applyFullViewGeometry(win);
      } else {
        void this.teardownSubWindow();
      }
    });
  }

  private async ensureSubWindow(): Promise<window.Window | null> {
    if (this._subWindow !== null) {
      return this._subWindow;
    }
    if (this._ensuringWindow) {
      return null;
    }
    const stage = this._windowStage;
    if (stage === null) {
      Logger.warn('SubWindowManager.ensureSubWindow: windowStage is null');
      return null;
    }
    this._ensuringWindow = true;

    let subWin: window.Window;
    try {
      subWin = await stage.createSubWindow(SUB_WINDOW_NAME);
    } catch (e) {
      Logger.error('SubWindowManager.ensureSubWindow: createSubWindow failed', e);
      this._ensuringWindow = false;
      return null;
    }

    try {
      // HAR packages can't register pages via main_pages.json, but they CAN
      // expose @Entry({ routeName }) entries that the host loads by name.
      await subWin.loadContentByName(TUI_CALLKIT_OVERLAY_ROUTE_NAME);
    } catch (e) {
      Logger.error('SubWindowManager.ensureSubWindow: loadContentByName failed', e);
      try {
        await subWin.destroyWindow();
      } catch (_) { /* best-effort */ }
      this._ensuringWindow = false;
      return null;
    }

    try {
      subWin.setWindowBackgroundColor('#00000000');
    } catch (e) {
      Logger.warn('SubWindowManager.ensureSubWindow: setWindowBackgroundColor failed', e);
    }

    let uiCtx: UIContext;
    try {
      uiCtx = subWin.getUIContext();
    } catch (e) {
      Logger.error('SubWindowManager.ensureSubWindow: getUIContext failed', e);
      try {
        await subWin.destroyWindow();
      } catch (_) { /* best-effort */ }
      this._ensuringWindow = false;
      return null;
    }

    this._subWindow = subWin;
    this.injectSafeAreaInsets(subWin, uiCtx);
    this.installAvoidAreaListener(subWin, uiCtx);
    this.applyStatusBarLightContent(subWin);

    try {
      await subWin.showWindow();
    } catch (e) {
      Logger.warn('SubWindowManager.ensureSubWindow: showWindow failed', e);
    }

    this._ensuringWindow = false;
    Logger.info('SubWindowManager.ensureSubWindow: created');
    return subWin;
  }

  private async teardownSubWindow(): Promise<void> {
    const subWin = this._subWindow;
    const listener = this._avoidAreaListener;
    const origStatusBarColor = this._origStatusBarColor;
    this._subWindow = null;
    this._avoidAreaListener = null;
    this._origStatusBarColor = null;

    if (subWin !== null && listener !== null) {
      try {
        subWin.off('avoidAreaChange', listener);
      } catch (e) {
        Logger.warn('SubWindowManager.teardownSubWindow: off listener failed', e);
      }
    }

    if (subWin !== null && origStatusBarColor !== null) {
      try {
        subWin.setWindowSystemBarProperties({ statusBarContentColor: origStatusBarColor })
          .catch((e: Object): void => {
            Logger.warn('SubWindowManager.teardownSubWindow: restore statusBarContentColor failed', e);
          });
      } catch (e) {
        Logger.warn('SubWindowManager.teardownSubWindow: restore statusBarContentColor threw', e);
      }
    }

    // Reset injected safe-area state so a future re-attach starts clean.
    const vs = ViewState();
    vs.statusBarHeight = 0;
    vs.navBarHeight = 0;

    if (subWin !== null) {
      try {
        await subWin.destroyWindow();
      } catch (e) {
        Logger.warn('SubWindowManager.teardownSubWindow: destroyWindow failed', e);
      }
    }
    Logger.info('SubWindowManager.teardownSubWindow: done');
  }

  private applyBannerGeometry(subWin: window.Window): void {
    let uiCtx: UIContext;
    try {
      uiCtx = subWin.getUIContext();
    } catch (e) {
      Logger.warn('SubWindowManager.applyBannerGeometry: getUIContext failed', e);
      return;
    }
    try {
      const dpy = display.getDefaultDisplaySync();
      const screenWidthPx = dpy.width;
      const insetPx = uiCtx.vp2px(BANNER_HORIZONTAL_INSET_VP);
      const heightPx = uiCtx.vp2px(BANNER_HEIGHT_VP);
      const topOffsetPx = uiCtx.vp2px(BANNER_TOP_OFFSET_VP)
        + uiCtx.vp2px(ViewState().statusBarHeight);

      subWin.setWindowLayoutFullScreen(true).catch((e: Object): void => {
        Logger.warn('SubWindowManager.applyBannerGeometry: setWindowLayoutFullScreen(true) failed', e);
      });
      subWin.resize(screenWidthPx - insetPx * 2, heightPx).catch((e: Object): void => {
        Logger.warn('SubWindowManager.applyBannerGeometry: resize failed', e);
      });
      subWin.moveWindowTo(insetPx, topOffsetPx).catch((e: Object): void => {
        Logger.warn('SubWindowManager.applyBannerGeometry: moveWindowTo failed', e);
      });
    } catch (e) {
      Logger.warn('SubWindowManager.applyBannerGeometry: threw', e);
    }
  }

  /**
   * FullView geometry: cover the entire screen, immersive (extends behind
   * status bar + navigation indicator). iOS analogue:
   *   window.frame = currentScreenFrame; backgroundColor = .black.
   */
  private applyFullViewGeometry(subWin: window.Window): void {
    try {
      const dpy = display.getDefaultDisplaySync();
      subWin.moveWindowTo(0, 0).catch((e: Object): void => {
        Logger.warn('SubWindowManager.applyFullViewGeometry: moveWindowTo failed', e);
      });
      subWin.resize(dpy.width, dpy.height).catch((e: Object): void => {
        Logger.warn('SubWindowManager.applyFullViewGeometry: resize failed', e);
      });
      subWin.setWindowLayoutFullScreen(true).catch((e: Object): void => {
        Logger.warn('SubWindowManager.applyFullViewGeometry: setWindowLayoutFullScreen failed', e);
      });
    } catch (e) {
      Logger.warn('SubWindowManager.applyFullViewGeometry: threw', e);
    }
  }

  private injectSafeAreaInsets(subWin: window.Window, uiCtx: UIContext): void {
    const vs = ViewState();
    try {
      const sysArea = subWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      vs.statusBarHeight = uiCtx.px2vp(sysArea.topRect.height);
    } catch (e) {
      Logger.warn('SubWindowManager.injectSafeAreaInsets: TYPE_SYSTEM failed', e);
    }
    try {
      const navArea = subWin.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      vs.navBarHeight = uiCtx.px2vp(navArea.bottomRect.height);
    } catch (e) {
      Logger.warn('SubWindowManager.injectSafeAreaInsets: TYPE_NAVIGATION_INDICATOR failed', e);
    }
    Logger.info('SubWindowManager: safe-area injected, status=', vs.statusBarHeight,
      'vp, nav=', vs.navBarHeight, 'vp');
  }

  private installAvoidAreaListener(subWin: window.Window, uiCtx: UIContext): void {
    const listener = (data: window.AvoidAreaOptions): void => {
      const vs = ViewState();
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        vs.statusBarHeight = uiCtx.px2vp(data.area.topRect.height);
      } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        vs.navBarHeight = uiCtx.px2vp(data.area.bottomRect.height);
      }
    };
    try {
      subWin.on('avoidAreaChange', listener);
      this._avoidAreaListener = listener;
    } catch (e) {
      Logger.warn('SubWindowManager.installAvoidAreaListener: on failed', e);
    }
  }

  private applyStatusBarLightContent(subWin: window.Window): void {
    try {
      const props = subWin.getWindowSystemBarProperties();
      this._origStatusBarColor = props.statusBarContentColor ?? '#000000';
    } catch (e) {
      Logger.warn('SubWindowManager.applyStatusBarLightContent: read failed', e);
      this._origStatusBarColor = '#000000';
    }
    try {
      subWin.setWindowSystemBarProperties({ statusBarContentColor: '#FFFFFF' })
        .catch((e: Object): void => {
          Logger.warn('SubWindowManager.applyStatusBarLightContent: rejected', e);
        });
    } catch (e) {
      Logger.warn('SubWindowManager.applyStatusBarLightContent: threw', e);
    }
  }
}
