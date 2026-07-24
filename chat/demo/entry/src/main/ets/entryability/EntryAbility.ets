import { AbilityConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { MMKV } from '@tencent/mmkv';
import { ThemeState } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { i18n } from '@kit.LocalizationKit';
import { AppBuilderConfig, AppBuilderHelper } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { ContextProvider } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index'
import { TIMPushInterfaces } from '../push/TIMPushInterfaces';
import { TUICallKit } from '@tencentcloud/tuicallkit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    MMKV.initialize(this.context.getApplicationContext());
    // Initialize ContextProvider, which will automatically set the system configuration to AppStorage
    ContextProvider.init(this.context);
    // 注册推送监听
    TIMPushInterfaces.addPushListener();
  }


  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/SplashScreenPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      // TUICallKit owns its own top-level overlay; mount it onto the host
      // WindowStage's main Window after `loadContent` has resolved.
      try {
        TUICallKit.createInstance(this.context).attach(windowStage);
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', 'TUICallKit.attach failed: %{public}s', JSON.stringify(e));
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    try {
      TUICallKit.createInstance(this.context).detach();
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', 'TUICallKit.detach failed: %{public}s', JSON.stringify(e));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }


  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onConfigurationUpdate');
    //Use ContextProvider to uniformly handle configuration updates
    ContextProvider.onConfigurationUpdate(newConfig);
  }
}
