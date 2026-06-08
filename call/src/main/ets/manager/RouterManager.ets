import { ViewState, CallRoute } from '../state/ViewState';
import { GlobalState } from '../state/GlobalState';
import { Logger } from '../common/utils/Logger';

type RouteListener = (next: CallRoute) => void;

let _routeListener: RouteListener | null = null;

export class RouterManager {
  static showCallingView(): void {
    ViewState().router = CallRoute.fullView;
    Logger.info('RouterManager: -> fullView');
    if (_routeListener !== null) {
      _routeListener(CallRoute.fullView);
    }
  }

  /** Falls back to fullView when the host has disabled the incoming banner. */
  static showBannerView(): void {
    if (!GlobalState().enableIncomingBanner) {
      RouterManager.showCallingView();
      return;
    }
    ViewState().router = CallRoute.banner;
    Logger.info('RouterManager: -> banner');
    if (_routeListener !== null) {
      _routeListener(CallRoute.banner);
    }
  }

  static closeView(): void {
    ViewState().reset();
    Logger.info('RouterManager: -> none');
    if (_routeListener !== null) {
      _routeListener(CallRoute.none);
    }
  }

  /**
   * Subscribe (or unsubscribe with `null`) to route transitions. Owned by
   * SubWindowManager so the SubWindow can be created / resized / destroyed
   * in lockstep with the route — same pattern as iOS WindowManager.
   */
  static bindRouteListener(listener: RouteListener | null): void {
    _routeListener = listener;
  }
}
