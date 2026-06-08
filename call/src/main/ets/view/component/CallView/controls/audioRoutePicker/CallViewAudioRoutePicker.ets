import { DeviceState, AudioRoute } from '@tencentcloud/atomicxcore';
import { ControlsButton } from '../../../../../common/widgets/ControlsButton';
import { CallKitBundle } from '../../../../../common/CallKitBundle';
import { TUICallKitLocalize } from '../../../../../common/Localized';
import { CallConstants } from '../../../../../common/CallConstants';
import { AudioRouteManager } from '../../../../../manager/AudioRouteManager';

// HarmonyOS has no AVRoutePickerView equivalent. v1 simply toggles
// speaker / earpiece via AudioRouteManager.

@Component
export struct CallViewAudioRoutePicker {
  @ObjectLink deviceState: DeviceState;

  /** Forwarded to ControlsButton — used by MultiCallControlsView to fade the title in/out as the panel collapses. */
  titleAlpha: number = 1;
  titleTranslateY: number = 0;

  build() {
    ControlsButton({
      image: this.iconForCurrent(),
      title: this.titleForCurrent(),
      titleAlpha: this.titleAlpha,
      titleTranslateY: this.titleTranslateY,
      isSelected: this.deviceState.currentAudioRoute === AudioRoute.speakerphone,
      bgColor: CallConstants.Color_BgMask,
      onTap: (): void => {
        AudioRouteManager.toggle();
      },
    });
  }

  private iconForCurrent(): Resource {
    return this.deviceState.currentAudioRoute === AudioRoute.speakerphone
      ? CallKitBundle.imageMap('icon_handsfree_on')
      : CallKitBundle.imageMap('icon_handsfree');
  }

  private titleForCurrent(): string {
    return this.deviceState.currentAudioRoute === AudioRoute.speakerphone
      ? TUICallKitLocalize('TUICallKit.AVRoutePickerView.speakerPhone')
      : TUICallKitLocalize('TUICallKit.AVRoutePickerView.earpiece');
  }
}
