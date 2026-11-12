export const ATOMICX_PAGE_ROUTE: string = 'atomicx.page';

export interface AtomicxPageParams {
  builder: WrappedBuilder<[Object]>;
  args: Object;
  onBackPressed?: () => boolean;
}

/**
 * Pushes atomic_x full pages into the host Navigation.
 * The host binds its NavPathStack and registers ATOMICX_PAGE_ROUTE in its navDestination builder;
 * when no stack is bound, callers fall back to their original dialog presentation.
 */
export class AtomicxNavigator {
  private static pathStack?: NavPathStack;

  static bind(pathStack: NavPathStack): void {
    AtomicxNavigator.pathStack = pathStack;
  }

  static unbind(pathStack: NavPathStack): void {
    if (AtomicxNavigator.pathStack === pathStack) {
      AtomicxNavigator.pathStack = undefined;
    }
  }

  static isAvailable(): boolean {
    return AtomicxNavigator.pathStack !== undefined;
  }

  static push(builder: WrappedBuilder<[Object]>, args: Object, onBackPressed?: () => boolean): boolean {
    const pathStack = AtomicxNavigator.pathStack;
    if (!pathStack) {
      return false;
    }
    const params: AtomicxPageParams = {
      builder: builder,
      args: args,
      onBackPressed: onBackPressed
    };
    pathStack.pushPathByName(ATOMICX_PAGE_ROUTE, params, true);
    return true;
  }

  static pop(): void {
    AtomicxNavigator.pathStack?.pop();
  }
}
