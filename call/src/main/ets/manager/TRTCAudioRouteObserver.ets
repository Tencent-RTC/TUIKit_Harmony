import { DeviceStore, AudioRoute } from '@tencentcloud/atomicxcore';
import { Logger } from '../common/utils/Logger';

// One-off lookup helper for non-component code. ArkUI components observe
// `DeviceStore.state.currentAudioRoute` directly via @ObjectLink instead.

export class TRTCAudioRouteObserver {
  static currentRoute(): AudioRoute {
    return DeviceStore.shared().state.currentAudioRoute;
  }

  static dump(): void {
    Logger.info('TRTCAudioRouteObserver currentRoute=', TRTCAudioRouteObserver.currentRoute());
  }
}
