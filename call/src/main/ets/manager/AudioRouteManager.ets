import { DeviceStore, AudioRoute } from '@tencentcloud/atomicxcore';
import { Logger } from '../common/utils/Logger';

// v1 STUB: only "speakerphone <-> earpiece" two-state switching is supported.
// Bluetooth / wired-headset detection is out of scope for v1.

export class AudioRouteManager {
  /** v1 stub. TODO: integrate @ohos.bluetooth / @ohos.multimedia.audio device routing. */
  static isBluetoothHeadsetConnected(): boolean {
    return false;
  }

  /** v1 stub. */
  static isWiredHeadsetConnected(): boolean {
    return false;
  }

  static syncAudioRouteFromSystem(): AudioRoute {
    return DeviceStore.shared().state.currentAudioRoute;
  }

  static toggle(): void {
    const current = DeviceStore.shared().state.currentAudioRoute;
    const next = current === AudioRoute.speakerphone
      ? AudioRoute.earpiece
      : AudioRoute.speakerphone;
    DeviceStore.shared().setAudioRoute(next);
    Logger.info('AudioRouteManager.toggle ->', next);
  }

  /** v1 stub: HarmonyOS has no AVRoutePickerView equivalent. */
  static enableAvRoutePickerMode(): void {
    Logger.info('AudioRouteManager.enableAvRoutePickerMode: not supported on HarmonyOS (TODO)');
  }
}
