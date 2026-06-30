import { AbilityConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { MMKV } from '@tencent/mmkv';
import { ContextProvider } from '@tencentcloud/atomicx'
import {
  FlutterBoostDelegate,
  FlutterBoostRouteOptions,
  FlutterBoostSetupOptions,
  FlutterBoostSetupOptionsBuilder,
  FlutterBoost
} from 'flutter_boost'
import { FlutterEngine, FlutterManager } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '@ohos/flutter_module';
import router from '@ohos.router';
import { TUICallKit } from '@tencentcloud/tuicallkit';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility implements FlutterBoostDelegate {

  pushNativeRoute(options: FlutterBoostRouteOptions,
    onPageResult?: (pageName: string, result: Record<string, Object>) => void): void {
  }

  pushFlutterRoute(options: FlutterBoostRouteOptions,
    onPageResult?: (pageName: string, result: Record<string, Object>) => void): void {
    router.pushUrl({
      url: 'pages/FlutterBoostHostPage',
      params: {
        uri: options.getPageName(),
        uniqueId: options.getUniqueId() ?? '',
        argsJson: JSON.stringify(options.getArguments())
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'pushFlutterRoute fail: %{public}s', JSON.stringify(err));
    });
  }

  popRoute(options: FlutterBoostRouteOptions): boolean {
    return false;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    MMKV.initialize(this.context.getApplicationContext());
    ContextProvider.init(this.context);
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    FlutterManager.getInstance().popUIAbility(this);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    FlutterManager.getInstance().pushWindowStage(this, windowStage);

    const options: FlutterBoostSetupOptions = new FlutterBoostSetupOptionsBuilder().build();
    try {
      await FlutterBoost.getInstance().setup(this, this.context, (engine: FlutterEngine) => {
        // 注册 FlutterBoost + webview_flutter_ohos 等插件（勿只注册 Boost）
        GeneratedPluginRegistrant.registerWith(engine);
      }, options);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'FlutterBoost.setup failed: %{public}s',
        err instanceof Error ? err.message : JSON.stringify(err));
    }
    
    TUICallKit.createInstance(this.context).attach(windowStage);


    windowStage.loadContent('pages/SplashScreenPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');

    FlutterManager.getInstance().popWindowStage(this);

    TUICallKit.createInstance(this.context).detach();

  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    FlutterBoost.getInstance().onForeground();
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    FlutterBoost.getInstance().onBackground();
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onConfigurationUpdate');
    ContextProvider.onConfigurationUpdate(newConfig);
  }
}
