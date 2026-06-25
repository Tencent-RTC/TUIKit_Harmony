// Bridges `CallParticipantInfo.status` (an @Observed field on atomicxcore's
// shared state) to non-@Component subscribers (Bell / Vibrator features).
//
// atomicxcore's `CallEventListener` only fires onCallStarted / onCallReceived /
// onCallEnded — there is no callback for the waiting → accept transition. On
// HarmonyOS @Observed fields can only be subscribed via ArkUI's @ObjectLink
// from an @Component, so `OverlayRoot` does the @ObjectLink work and forwards
// status changes here via `notify(...)`.

import { CallParticipantStatus } from '@tencentcloud/atomicxcore';

type Listener = (status: CallParticipantStatus) => void;

class CallStatusObserverImpl {
  private listeners: Listener[] = [];
  private lastStatus: CallParticipantStatus = CallParticipantStatus.none;

  addListener(cb: Listener): () => void {
    this.listeners.push(cb);
    return (): void => {
      const idx = this.listeners.indexOf(cb);
      if (idx >= 0) {
        this.listeners.splice(idx, 1);
      }
    };
  }

  /** Deduplicated against `lastStatus` so spurious rebuilds do not fan out. */
  notify(status: CallParticipantStatus): void {
    if (status === this.lastStatus) {
      return;
    }
    this.lastStatus = status;
    // Snapshot to be safe against re-entrant unsubscribe() inside a callback.
    const snapshot = this.listeners.slice();
    for (const cb of snapshot) {
      cb(status);
    }
  }
}

let _instance: CallStatusObserverImpl | null = null;

export function CallStatusObserver(): CallStatusObserverImpl {
  if (_instance === null) {
    _instance = new CallStatusObserverImpl();
  }
  return _instance;
}
