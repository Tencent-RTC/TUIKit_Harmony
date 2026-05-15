import {
  V2TIMLogLevel,
  V2TIMManager,
  V2TIMSDKConfig,
  V2TIMSDKListener,
  V2TIMUserFullInfo,
  V2TIMUserStatus
} from '@tencentcloud/imsdk';
import Logger from './Logger';
import { BusinessError } from '@kit.BasicServicesKit';
import { TUIError } from '@tencentcloud/rtcroomengine';
import json from '@ohos.util.json';

const TAG: string = "TUILogin"

@ObservedV2
export class TUILogin {
  sdkAppId: number = 0
  userSig: string = ""
  userId: string = ""
  @Trace nickname: string = ""
  @Trace avatar: string = ""
  private listenerList: Array<V2TIMSDKListener> = new Array()

  public addLoginListener(listener: V2TIMSDKListener) {
    if (listener == null) {
      return
    }
    if (!this.listenerList.includes(listener)) {
      this.listenerList.push(listener)
    }
  }

  public removeLoginListener(listener: V2TIMSDKListener) {
    if (listener == null) {
      return
    }
    const copyList: Array<V2TIMSDKListener> = Array.from(this.listenerList);
    if (copyList.length > 0) {
      let index = copyList.indexOf(listener)
      if (index > -1) {
        copyList.splice(index, 1)
      }
    }
  }

  public login(context: Context, sdkAppId: number, userId: string, userSig: string): Promise<void> {
    return new Promise((resolve, reject) => {
      Logger.info(TAG, `login： sdkAppId:${sdkAppId}, userId: ${userId}`)

      if (userId != null && userId.trim().length != 0 && userId.trim() == V2TIMManager.getInstance().getLoginUser()) {
        resolve()
        Logger.info(TAG, `login, userId: ${userId} already login`)
        this.getUserInfo(userId)
        return
      }

      if (this.sdkAppId != 0 && sdkAppId != this.sdkAppId) {
        this.logout()
      }
      this.sdkAppId = sdkAppId
      this.initIMSDKListener()
      const sdkConfig: V2TIMSDKConfig = {
        logLevel: V2TIMLogLevel.V2TIM_LOG_DEBUG,
        logListener: (logLevel: V2TIMLogLevel, logContent: string) => {
        },
      };

      let initSuccess = V2TIMManager.getInstance().initSDK(getContext().getApplicationContext(), sdkAppId, sdkConfig);
      const version = V2TIMManager.getInstance().getVersion();
      Logger.warn(TAG, `login ,version: ${version}`)

      if (!initSuccess) {
        reject(new TUIError({ code: -1, message: "initSDK failed" }))
        return
      }
      this.userId = userId
      this.userSig = userSig

      V2TIMManager.getInstance().login(userId, userSig).then(() => {
        Logger.info(TAG, `login success, userId: ${userId}`)
        resolve()
        this.getUserInfo(userId)
      }).catch((error: BusinessError) => {
        reject(error)
        Logger.error(TAG, `login failed, error: ${JSON.stringify(error)}`)
      });
    })
  }

  public logout(): Promise<void> {
    return new Promise((resolve, reject) => {
      V2TIMManager.getInstance().logout().then(() => {
        Logger.info(TAG, `logout success`)
        resolve()
      }).catch((error: BusinessError) => {
        Logger.error(TAG, `logout failed, error: ${JSON.stringify(error)}`)
        reject(error)
      });
    })
  }

  private getUserInfo(userId: string) {
    if (userId == null || userId.length == 0) {
      return
    }
    V2TIMManager.getInstance().getUsersInfo([userId]).then((userFullInfoList: V2TIMUserFullInfo[]) => {
      if (userFullInfoList == null || userFullInfoList.length == 0) {
        return
      }
      let user = userFullInfoList[0]
      Logger.log(TAG, `getUserInfo success, userList: ${json.stringify(user)}`)

      this.avatar = user.faceURL
      this.nickname = user.nickName
    }).catch((error: Error) => {
      Logger.log(TAG, `getUserInfo failed, error: ${error}`)
    });
  }

  private initIMSDKListener() {
    const sdkListener: V2TIMSDKListener = {
      onConnecting: () => {
      },
      onConnectSuccess: () => {
      },
      onConnectFailed: (code: number, message: string) => {
      },
      onKickedOffline: () => {
        const copyList: Array<V2TIMSDKListener> = Array.from(this.listenerList);
        if (copyList != null && copyList.length > 0) {
          for (const item of copyList) {
            item?.onKickedOffline
          }
        }
      },
      onUserSigExpired: () => {
        const copyList: Array<V2TIMSDKListener> = Array.from(this.listenerList);
        if (copyList != null && copyList.length > 0) {
          for (const item of copyList) {
            item?.onUserSigExpired
          }
        }
      },
      onSelfInfoUpdated: (info: V2TIMUserFullInfo) => {
        this.avatar = info.faceURL
        this.nickname = info.nickName
      },
      onUserStatusChanged: (userStatusList: V2TIMUserStatus[]) => {
      },
    };
    V2TIMManager.getInstance().addSDKListener(sdkListener)
  }
}

export default new TUILogin()

