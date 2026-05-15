import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { TUICallRole, TUICallStatus } from '@tencentcloud/rtcroomengine';
import { CallManager } from '../CallManager';
import Logger from '../../common/Logger';
import { CallEvent } from '../../common/Constants';

const TAG = "CallVibratorFeature"

export class CallVibratorFeature {
  private VIBRATOR_ID: number = 0
  private retryCount: number = 0
  private RETRY_INTERVAL: number = 1000
  private stopVibrateTaskId: number = -99
  private isVibrating: boolean = false

  constructor() {
    emitter.on({ eventId: CallEvent.CALL_STATUS }, (eventData: emitter.EventData) => {
      let selfUser = CallManager.getInstance().userState.selfUser
      Logger.info(TAG, `eventData: ${JSON.stringify(eventData)}, selfUser: ${selfUser}`)
      if (selfUser.callRole != TUICallRole.Called) {
        return
      }
      if (selfUser.callStatus != TUICallStatus.Waiting) {
        this.stopVibrating()
      } else {
        this.startVibrating()
      }
    });
  }

  private startVibrating() {
    this.vibrate()
    this.isVibrating = true
    let startInternalId = setInterval(() => {
      if (CallManager.getInstance().userState.selfUser.callStatus != TUICallStatus.Waiting) {
        clearInterval(startInternalId)
        return
      }
      this.vibrate()
    }, 3000);
  }

  private vibrate() {
    try {
      vibrator.startVibration({ type: 'time', duration: 1000 }, { id: this.VIBRATOR_ID, usage: 'ring' },
        (error: BusinessError) => {
          if (error) {
            Logger.error(TAG, `startVibrating failed. Code: ${error.code}, message: ${error.message}`);
            return;
          }
        });
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      Logger.error(TAG, `startVibrating failed, Code: ${e.code}, message: ${e.message}`);
    }
  }

  private stopVibrating() {
    if (!this.isVibrating) {
      return
    }
    this.isVibrating = false
    if (this.stopVibrateTaskId) {
      clearTimeout(this.stopVibrateTaskId)
      this.stopVibrateTaskId = -99
    }
    this.retryCount = 0
    const maxRetryCount = 3
    const attemptStop = async (currentRetry: number = 0) => {
      try {
        await this.unVibrate();
        this.retryCount = 0;
        return;
      } catch (error) {
        if (currentRetry >= maxRetryCount) {
          this.retryCount = 0;
          Logger.error(TAG, `stopVibrating failed, exceeding max retry count`)
          return;
        }
        this.stopVibrateTaskId = setTimeout(() => {
          attemptStop(currentRetry + 1);
        }, this.RETRY_INTERVAL);
      }
    };

    attemptStop().catch((error: BusinessError) => {
      Logger.error(TAG, `stopVibrating failed, exceeding max retry count, error: ${error.code},${error.message}`)
    });
  }

  private unVibrate(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        vibrator.stopVibration((error: BusinessError) => {
          if (error) {
            Logger.error(TAG, `stopVibrating failed. Code: ${error.code}, message: ${error.message}`);
            reject(error)
            return;
          }
          resolve()
        })
      } catch (err) {
        reject(err)
        let e: BusinessError = err as BusinessError;
        Logger.error(TAG, `stopVibrating error occurred. Code: ${e.code}, message: ${e.message}`);
      }
    })
  }
}