// Drives the device vibrator while the user is being called (waiting + invitee).
// Suppressed when `GlobalState.enableMuteMode == true`.

import vibrator from '@ohos.vibrator';
import { CallParticipantStatus } from '@tencentcloud/atomicxcore';
import { Logger } from '../common/utils/Logger';
import { GlobalState } from '../state/GlobalState';
import { CallStatusObserver } from './CallStatusObserver';

const VIBRATE_INTERVAL_MS: number = 1500;
const VIBRATE_DURATION_MS: number = 1000;

export class CallingVibratorFeature {
  private static instance: CallingVibratorFeature | null = null;
  private timerHandle: number | null = null;
  private active: boolean = false;
  private subscribed: boolean = false;

  static shared(): CallingVibratorFeature {
    if (!CallingVibratorFeature.instance) {
      CallingVibratorFeature.instance = new CallingVibratorFeature();
    }
    return CallingVibratorFeature.instance;
  }

  /**
   * Idempotent. Subscribes to status transitions so an accepted / rejected /
   * cancelled call stops the vibrator immediately — `onCallEnded` only fires
   * on hang-up, never on pickup.
   */
  init(): void {
    if (this.subscribed) {
      return;
    }
    this.subscribed = true;
    CallStatusObserver().addListener((status: CallParticipantStatus): void => {
      if (status === CallParticipantStatus.waiting) {
        return;
      }
      this.stop();
    });
  }

  start(): void {
    if (this.active) {
      return;
    }
    if (GlobalState().enableMuteMode) {
      Logger.info('CallingVibratorFeature: mute mode enabled, skip vibration');
      return;
    }
    Logger.info('CallingVibratorFeature.start');
    this.active = true;
    this.fire();
    this.timerHandle = setInterval((): void => {
      this.fire();
    }, VIBRATE_INTERVAL_MS);
  }

  stop(): void {
    this.active = false;
    if (this.timerHandle !== null) {
      clearInterval(this.timerHandle);
      this.timerHandle = null;
    }
    try {
      vibrator.stopVibration();
    } catch (e) {
      Logger.warn('CallingVibratorFeature.stop: stopVibration failed', e);
    }
  }

  // `usage: 'notification'` requires elevated permission on some devices and
  // silently rejects with code 201; `unknown` works on all devices that have
  // ohos.permission.VIBRATE granted.
  private fire(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: VIBRATE_DURATION_MS,
      }, {
        usage: 'unknown',
      }).catch((e: Object): void => {
        Logger.warn('CallingVibratorFeature.startVibration rejected', JSON.stringify(e));
      });
    } catch (e) {
      Logger.warn('CallingVibratorFeature.startVibration failed', e);
    }
  }
}
