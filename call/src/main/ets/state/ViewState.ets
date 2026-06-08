export enum CallRoute {
  none = 0,
  banner = 1,
  fullView = 2,
}

@Observed
export class ViewStateClass {
  router: CallRoute = CallRoute.none;
  /** Status-bar height in vp, injected by SubWindowManager via getWindowAvoidArea(TYPE_SYSTEM). */
  statusBarHeight: number = 0;
  /** Navigation-indicator height in vp, injected via TYPE_NAVIGATION_INDICATOR. */
  navBarHeight: number = 0;

  reset(): void {
    this.router = CallRoute.none;
    // Safe-area heights are device hardware properties; preserved across calls.
  }
}

let _instance: ViewStateClass | null = null;

export function ViewState(): ViewStateClass {
  if (!_instance) {
    _instance = new ViewStateClass();
  }
  return _instance;
}
