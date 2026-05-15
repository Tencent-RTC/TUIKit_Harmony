import { promptAction, router } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import TUICallEngine, {
  TUICallEvents,
  TUICallMediaType,
  TUICallParams,
  TUICallRole,
  TUICallScene,
  TUICallStatus,
  TUIError
} from '@tencentcloud/rtcroomengine';
import { CallManager } from './manager/CallManager';
import { TUICallKit } from './TUICallKit';
import Permission from './common/Permission';
import Logger from './common/Logger';
import { JSON } from '@kit.ArkTS';
import './pages/CallMainView';
import { CallEvent } from './common/Constants';

const TAG = "TUICallKitImpl"

export class TUICallKitImpl extends TUICallKit {
  private static instance: TUICallKitImpl;
  private context: Context;

  private constructor(context: Context) {
    super();
    CallManager.getInstance()
    this.context = context;
    this.subscribeEvent()
    this.subscribeCallStatusChange()
  }

  static getInstance(context: Context): TUICallKitImpl {
    if (!TUICallKitImpl.instance) {
      TUICallKitImpl.instance = new TUICallKitImpl(context);
    }
    return TUICallKitImpl.instance;
  }

  static createInstance(context: Context): TUICallKitImpl {
    return TUICallKitImpl.getInstance(context);
  }

  login(sdkAppId: number, userId: string, userSig: string): Promise<void> {
    return new Promise((resolve, reject) => {
      // TODO: implement login logic
      const ctx = getContext();
      TUICallEngine.createInstance().login(ctx, sdkAppId, userId, userSig).then(() => {
        Logger.info(TAG, "TUICallEngine login success");
        resolve();
      }).catch((error: Object) => {
        Logger.info(TAG, "TUICallEngine login failed, " + error);
        reject(error);
      });
    });
  }

  override calls(userIdList: string[], mediaType: number, params: Record<string, Object> | null): Promise<void> {
    const tuiMediaType: TUICallMediaType = mediaType as TUICallMediaType;
    Logger.log(TAG, `calls start, userIdList: ${userIdList}, mediaType: ${tuiMediaType}, param: ${params}`)
    let callParams: TUICallParams | null = null;
    if (params) {
      callParams = {
        roomId: { intRoomId: 0, strRoomId: '' },
        offlinePushInfo: null,
        timeout: (params['timeout'] as number) ?? 30,
        userData: null,
        chatGroupId: (params['chatGroupId'] as string) ?? '',
      } as TUICallParams;
    }
    return new Promise((resolve, reject) => {
      Permission.requestPermission(tuiMediaType).then((data) => {
        if (!data.grantStatus) {
          reject(data)
          Logger.error(TAG, `calls failed, permission denied, data: ${data}}`)
          return
        }
        Logger.info(TAG, `calls start, permission requested success`)
        CallManager.getInstance().calls(userIdList, tuiMediaType, callParams).then(() => {
          Logger.info(TAG, `calls start success`)
          this.startCallMainView()
          resolve()
        }).catch((error: TUIError) => {
          reject(error)
          Logger.error(TAG, `calls failed, errorCode: ${error.code}, errorMsg: ${error.message}`)
        });
      })
    })
  }

  override join(callId: string): Promise<void> {
    return new Promise((resolve, reject) => {
      Permission.requestPermission(TUICallMediaType.Audio).then((data) => {
        if (!data.grantStatus) {
          reject(data)
          Logger.error(TAG, `join failed, permission denied, data: ${data}}`)
          return
        }
        Logger.info(TAG, `join start, permission requested success`)
        CallManager.getInstance().join(callId).then(() => {
          this.startCallMainView()
          resolve()
        }).catch((error: TUIError) => {
          reject(error)
          Logger.error(TAG, `join failed, errorCode: ${error.code}, errorMsg: ${error.message}`)
        });
      })
    })
  }

  override setSelfInfo(nickname: string, avatar: string): Promise<void> {
    return CallManager.getInstance().setSelfInfo(nickname, avatar)
  }

  override setCallingBell(filePath: string): void {
    CallManager.getInstance().setCallingBell(filePath)
  }

  override enableMuteMode(enable: boolean): void {
    CallManager.getInstance().enableMuteMode(enable)
  }

  override enableVirtualBackground(enable: boolean): void {
    CallManager.getInstance().enableVirtualBackground(enable)
  }

  private subscribeEvent() {
    TUICallEngine.createInstance().on(TUICallEvents.onUserReject, () => {
      if (TUICallScene.Single == CallManager.getInstance().callState.scene) {
        promptAction.showToast({ message: $r('app.string.callkit_toast_callee_reject') })
      }
    })
    TUICallEngine.createInstance().on(TUICallEvents.onUserNoResponse, () => {
      promptAction.showToast({ message: $r('app.string.callkit_toast_callee_no_response') })
    })
    TUICallEngine.createInstance().on(TUICallEvents.onUserLineBusy, () => {
      promptAction.showToast({ message: $r('app.string.callkit_toast_line_busy') })
    })
    TUICallEngine.createInstance().on(TUICallEvents.onUserLeave, () => {
      if (TUICallScene.Single == CallManager.getInstance().callState.scene) {
        promptAction.showToast({ message: $r('app.string.callkit_toast_callee_hangup') })
      }
    })
  }

  private subscribeCallStatusChange() {
    Logger.info(TAG, `subscribeCallStatusChange`)
    emitter.on({ eventId: CallEvent.CALL_STATUS }, (eventData: emitter.EventData) => {
      let selfUser = CallManager.getInstance().userState.selfUser
      Logger.info(TAG, `selfUser callStatus changed: ${selfUser}`)
      if (selfUser.callStatus == TUICallStatus.None) {
        this.stopCallMainView()
        return
      }
      if (selfUser.callRole == TUICallRole.Called && selfUser.callStatus == TUICallStatus.Waiting) {
        this.startCallMainView()
      }
    });
  }

  private startCallMainView() {
    Logger.info(TAG, `startCallMainView`)

    Permission.requestPermission(CallManager.getInstance().callState.mediaType).then((data) => {
      if (!data.grantStatus) {
        Logger.error(TAG, `calls failed, permission denied, data: ${data}}`)
        if (CallManager.getInstance().userState.selfUser.callRole == TUICallRole.Called) {
          CallManager.getInstance().reject()
        }
        return
      }
      Logger.info(TAG, `startCallMainView, permission requested success`)
      router.pushNamedRoute({ name: 'CallMainViewRoute' }).then(() => {
      }).catch((error: TUIError) => {
        Logger.error(TAG, `pushNamedRoute failed, error: ${error.code}, ${error.message}`);
      });
    })
  }

  private stopCallMainView() {
    const isCallMainView = router.getState()?.name === 'CallMainView';
    Logger.info(TAG, `stopCallMainView, isCallMainView: ${JSON.stringify(router.getState())}`)
    if (isCallMainView) {
      router.back()
    }
  }
}