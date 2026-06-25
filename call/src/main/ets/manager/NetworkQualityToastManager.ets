// Surfaces transient network-degradation notices via a bottom Toast.
//
// atomicxcore exposes CallState as @Observed but ships no typed change
// listener, so we poll `networkQualities` at 1 Hz. Each poll is
// O(participants) and only allocates when crossing the "poor" threshold.

import { CallStore, CallParticipantStatus, NetworkQuality } from '@tencentcloud/atomicxcore';
import { Toast } from '../common/widgets/Toast';
import { TUICallKitLocalize } from '../common/Localized';
import { Logger } from '../common/utils/Logger';

const THROTTLE_MS: number = 10_000;
const POLL_MS: number = 1_000;

enum Channel {
  selfPoor = 0,
  peerPoor = 1,
}

export class NetworkQualityToastManager {
  private static timerId: number = 0;
  private static lastShownAt: Map<Channel, number> = new Map<Channel, number>();

  static start(): void {
    NetworkQualityToastManager.stop();
    NetworkQualityToastManager.timerId = setInterval((): void => {
      NetworkQualityToastManager.tick();
    }, POLL_MS);
    Logger.info('NetworkQualityToastManager started');
  }

  static stop(): void {
    if (NetworkQualityToastManager.timerId !== 0) {
      clearInterval(NetworkQualityToastManager.timerId);
      NetworkQualityToastManager.timerId = 0;
    }
    NetworkQualityToastManager.lastShownAt.clear();
  }

  private static tick(): void {
    const state = CallStore.shared().state;
    // waiting/none → no toast; only surface during accepted calls.
    if (state.selfInfo.status !== CallParticipantStatus.accept) {
      return;
    }
    const qualities = state.networkQualities;
    if (!qualities || qualities.size === 0) {
      return;
    }
    const selfId = state.selfInfo.id;
    const selfQuality = qualities.get(selfId);
    if (NetworkQualityToastManager.isPoor(selfQuality)) {
      NetworkQualityToastManager.fire(Channel.selfPoor, 'TUICallKit.Self.NetworkLowQuality');
      // Self-poor outranks peer-poor; skip peer scan to avoid back-to-back toasts.
      return;
    }
    let peerPoor = false;
    qualities.forEach((q: NetworkQuality, uid: string): void => {
      if (uid !== selfId && NetworkQualityToastManager.isPoor(q)) {
        peerPoor = true;
      }
    });
    if (peerPoor) {
      NetworkQualityToastManager.fire(Channel.peerPoor, 'TUICallKit.OtherParty.NetworkLowQuality');
    }
  }

  private static fire(channel: Channel, key: string): void {
    const now = Date.now();
    const last = NetworkQualityToastManager.lastShownAt.get(channel) ?? 0;
    if (now - last < THROTTLE_MS) {
      return;
    }
    NetworkQualityToastManager.lastShownAt.set(channel, now);
    Toast.show(TUICallKitLocalize(key));
  }

  private static isPoor(q: NetworkQuality | undefined): boolean {
    return q === NetworkQuality.poor || q === NetworkQuality.bad
      || q === NetworkQuality.veryBad || q === NetworkQuality.down;
  }
}
