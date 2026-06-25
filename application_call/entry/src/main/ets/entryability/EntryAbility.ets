import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { TUICallKit } from '@tencentcloud/tuicallkit';
import { UserStore } from '../common/UserStore';

const DOMAIN = 0xCA11;
const TAG = 'CallTest';

// NOTE: We intentionally do NOT request CAMERA / MICROPHONE permissions on
// app launch. Aligned with Android `tuicallkit-kt` (no Application-level
// preflight) and iOS `TUICallKit_Swift` — runtime permissions are requested
// lazily by `Permission.hasPermission(...)` only when:
//   1. the user calls `TUICallKit.calls(...)` (outgoing call), or
//   2. the call page (`CallMainPage`) is about to display (incoming-accepted /
//      outgoing-active path).

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    const store = UserStore.instance;
    await store.init(this.context);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content: pages/Index');
      // The SDK owns its own top-level overlay; mount it onto the host
      // WindowStage's main Window after `loadContent` has resolved so that
      // the OverlayManager is ready.
      try {
        TUICallKit.createInstance(this.context).attach(windowStage);
        hilog.info(DOMAIN, TAG, 'TUICallKit.attach done');
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'TUICallKit.attach failed: %{public}s', JSON.stringify(e));
      }
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
    try {
      TUICallKit.createInstance(this.context).detach();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'TUICallKit.detach failed: %{public}s', JSON.stringify(e));
    }
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
