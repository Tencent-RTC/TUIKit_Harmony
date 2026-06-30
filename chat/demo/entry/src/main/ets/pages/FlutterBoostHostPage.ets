import { hilog } from '@kit.PerformanceAnalysisKit';
import router from '@ohos.router';
import { FlutterBoostEntry } from 'flutter_boost';
import { FlutterPage, FlutterView } from '@ohos/flutter_ohos';
import { WindowImmersiveHelper } from '../utils/WindowImmersiveHelper';

const TAG = 'FlutterBoostHostPage';
const FLUTTER_DEST_NAME = 'flutter_boost_inner';

export class FlutterBoostRouterOptions {
  uri: string = '';
  params: Record<string, Object> = {};
  uniqueId: string | null = null;

  constructor(uri: string, params: Record<string, Object>, uniqueId: string | null) {
    this.uri = uri;
    this.params = params;
    this.uniqueId = uniqueId;
  }
}

@Component
struct FlutterBoostInnerPage {
  private flutterEntry: FlutterBoostEntry | null = null;
  private flutterView: FlutterView | null = null;
  private routeStack: NavPathStack | null = null;
  @State private flutterReady: boolean = false;
  @Prop routerOptions: FlutterBoostRouterOptions = new FlutterBoostRouterOptions('', {}, null);

  onPopCallback(result: Record<string, Object>): void {
    hilog.info(0x0000, TAG, 'onPopCallback');
    this.routeStack?.pop(result);
  }

  async aboutToAppear(): Promise<void> {
    hilog.info(0x0000, TAG, 'Inner aboutToAppear');
    this.flutterEntry = new FlutterBoostEntry(getContext(this), this.routerOptions, false, this.onPopCallback);
    await this.flutterEntry.aboutToAppear();
    this.flutterView = this.flutterEntry.getFlutterView();
    this.flutterReady = this.flutterView !== null;
  }

  aboutToDisappear(): void {
    hilog.info(0x0000, TAG, 'Inner aboutToDisappear');
    this.flutterEntry?.aboutToDisappear();
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.flutterReady && this.flutterView) {
          FlutterPage({ viewId: this.flutterView.getId() })
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      if (this.flutterEntry) {
        return this.flutterEntry.onBackPressed();
      }
      return false;
    })
    .onShown(() => {
      this.flutterEntry?.onShown();
    })
    .onHidden(() => {
      this.flutterEntry?.onHidden();
    })
    .onReady((ctx: NavDestinationContext) => {
      try {
        this.routeStack = ctx.pathStack;
        this.flutterEntry?.onReady(ctx.pathStack);
      } catch (e) {
        hilog.error(0x0000, TAG, `onReady error: ${JSON.stringify(e)}`);
      }
    })
  }
}

@Entry
@Component
struct FlutterBoostHostPage {
  private stack: NavPathStack = new NavPathStack();
  @State private routerOptions: FlutterBoostRouterOptions =
    new FlutterBoostRouterOptions('', {}, null);

  aboutToAppear(): void {
    void WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
    const pr = router.getParams() as Record<string, Object | string | undefined>;
    const uri = String(pr['uri'] ?? '');
    const uniqueRaw = pr['uniqueId'];
    const uniqueId: string | null =
      (uniqueRaw === undefined || uniqueRaw === null || String(uniqueRaw) === '') ? null : String(uniqueRaw);
    let args: Record<string, Object> = {};
    const aj = pr['argsJson'];
    if (aj !== undefined && aj !== null && String(aj).length > 0) {
      try {
        args = JSON.parse(String(aj)) as Record<string, Object>;
      } catch (_) {
        args = {};
      }
    }
    this.routerOptions = new FlutterBoostRouterOptions(uri, args, uniqueId);

    setTimeout(() => {
      this.stack.pushPath({
        name: FLUTTER_DEST_NAME,
        param: this.routerOptions,
        onPop: () => {
          router.back();
        }
      });
    }, 0);
  }

  @Builder
  navMap(builderName: string, param: FlutterBoostRouterOptions | Record<string, Object>): void {
    if (builderName === FLUTTER_DEST_NAME) {
      FlutterBoostInnerPage({ routerOptions: param as FlutterBoostRouterOptions });
    }
  }

  build() {
    Navigation(this.stack) {
      Column().width('100%').height('100%')
    }
    .navDestination(this.navMap)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
