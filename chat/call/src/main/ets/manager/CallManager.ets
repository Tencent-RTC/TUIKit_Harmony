import { emitter } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import json from '@ohos.util.json'
import Logger from '../common/Logger'
import TUILogin from '../common/TUILogin'
import { User, UserState } from '../state/UserState'
import { MediaState } from '../state/MediaState'
import { CallState } from '../state/CallState'
import TUICallEngine, {
  TUIAudioPlaybackDevice,
  TUICallMediaType,
  TUICallParams,
  TUICallRole,
  TUICallScene,
  TUICallStatus,
  TUICamera,
  TUIError,
  TUIErrorCode
} from '@tencentcloud/rtcroomengine'
import { CallEventObserver } from './observer/CallEventObserver'
import { UserManager } from './UserManager'

import Constants, { CallEvent } from '../common/Constants'
import GlobalState from '../state/GlobalState'
import { Preference } from '../common/Preference'
import { CallBellFeature } from './feature/CallBellFeature'
import { CallVibratorFeature } from './feature/CallVibratorFeature'
import { ViewState } from '../state/ViewState'
import { LiteAVBase } from '@tencentcloud/liteavsdk_professional'

const TAG: string = "CallManager"
const BLUR_LEVEL_HIGH = 3
const BLUR_LEVEL_CLOSE = 0

export class CallManager {
  private static instance: CallManager
  mediaState: MediaState = new MediaState()
  userState: UserState = new UserState()
  callState: CallState = new CallState()
  viewState: ViewState = new ViewState()
  private callEventObserver: CallEventObserver = new CallEventObserver()
  private callBellFeature: CallBellFeature | null = null
  private callVibratorFeature: CallVibratorFeature | null = null

  private constructor() {
    LiteAVBase.setContext(getContext())
    this.callEventObserver.subscribeEvent()
    if (this.callBellFeature == null) {
      this.callBellFeature = new CallBellFeature()
    }
    if (this.callVibratorFeature == null) {
      this.callVibratorFeature = new CallVibratorFeature()
    }
  }

  static getInstance(): CallManager {
    if (!CallManager.instance) {
      CallManager.instance = new CallManager()
    }
    return CallManager.instance
  }

  public destroy() {
    this.callEventObserver.unsubscribeEvent()
  }

  public calls(userList: string[], mediaType: TUICallMediaType, callParams: TUICallParams | null): Promise<void> {
    Logger.log(TAG,
      `calls, userList:${userList}, mediaType:${TUICallMediaType[mediaType]}, callParams: ${json.stringify(callParams)}`)

    return new Promise((resolve, reject) => {
      this.setFramework()
      if (mediaType != TUICallMediaType.Audio && mediaType != TUICallMediaType.Video) {
        Logger.error(TAG, `calls failed, mediaType is invalid`)
        reject(new TUIError({ code: TUIErrorCode.Failed, message: "calls failed, mediaType is invalid" }))
        return
      }

      if (userList == null || userList.length == 0) {
        Logger.error(TAG, `calls failed, userId is empty`)
        reject(new TUIError({ code: TUIErrorCode.Failed, message: "calls failed, userList is empty" }))
        return
      }
      if (userList.length >= Constants.MAX_USER) {
        Logger.error(TAG, `calls failed, exceeding max user number: 9`)
        promptAction.showToast({ message: $r('app.string.callkit_user_exceed_limit') })
        reject(new TUIError({ code: TUIErrorCode.Failed, message: "calls failed, exceeding max user number: 9" }))
        return
      }

      this.userState.selfUser.userId = TUILogin.userId
      this.userState.selfUser.avatar = TUILogin.avatar
      this.userState.selfUser.nickname = TUILogin.nickname

      TUICallEngine.createInstance().calls(userList, mediaType, callParams).then(() => {
        Logger.info(TAG, `engine calls success`)
        for (let userId of userList) {
          let user = new User()
          user.userId = userId
          user.callRole = TUICallRole.Called
          user.callStatus = TUICallStatus.Waiting
          CallManager.instance.userState.remoteUserArray.push(user)
          UserManager.instance.updateUserInfo(user)
        }
        Logger.log(TAG, `calls success, userList: ${json.stringify(userList)}`)
        this.userState.selfUser.callRole = TUICallRole.Call
        this.userState.selfUser.callStatus = TUICallStatus.Waiting

        let groupId = callParams?.chatGroupId
        this.callState.chatGroupId = groupId != null ? groupId : "";

        let scene = TUICallScene.Single
        if (groupId != null && groupId.length > 0) {
          scene = TUICallScene.Group
        } else if (userList.length > 1) {
          scene = TUICallScene.Multi
        }
        this.callState.scene = scene
        this.callState.mediaType = mediaType
        this.initCameraAndAudioDeviceState()

        emitter.emit({ eventId: CallEvent.CALL_STATUS, priority: emitter.EventPriority.HIGH },
          { data: { userId: this.userState.selfUser.userId, callStatus: TUICallStatus.Waiting } });

        resolve()
      }).catch((error: TUIError) => {
        Logger.error(TAG, `calls failed, errorCode: ${error.code}, errorMsg: ${error.message}`)
        promptAction.showToast({ message: error.message })
        reject(error)
      });
    })
  }

  public join(callId: string): Promise<void> {
    Logger.info(TAG, `join, callId: ${callId}`)
    this.setFramework()
    return new Promise((resolve, reject) => {
      if (callId == null || callId.length <= 0) {
        Logger.error(TAG, `join failed, callId is empty`)
        reject(new TUIError({ code: TUIErrorCode.Failed, message: "join failed, callId is empty" }))
        return
      }
      this.userState.selfUser.userId = TUILogin.userId
      this.userState.selfUser.avatar = TUILogin.avatar
      this.userState.selfUser.nickname = TUILogin.nickname

      TUICallEngine.createInstance().join(callId).then(() => {
        this.userState.selfUser.callRole = TUICallRole.Called
        this.callState.scene = TUICallScene.Multi
        this.callState.mediaType = TUICallMediaType.Audio

        this.userState.selfUser.callStatus = TUICallStatus.Waiting
        this.initCameraAndAudioDeviceState()
        resolve()
      }).catch((error: TUIError) => {
        Logger.error(TAG, `join failed callId: $callId, errCode: $errCode, errMsg: $errMsg`)
        promptAction.showToast({ message: error.message })
        reject(error)
      });
    })
  }

  public inviteUser(userList: string[], callParams: TUICallParams | null): Promise<void> {
    Logger.info(TAG, `inviteUser, userIdList: ${userList}, callParams: ${json.stringify(callParams)}`)
    return new Promise((resolve, reject) => {
      TUICallEngine.createInstance().inviteUser(userList, callParams).then((userResult: string[]) => {
        Logger.warn(TAG, `inviteUser, userResult: ${json.stringify(userResult)}`)
        if (userResult == null || userResult.length <= 0) {
          reject(new TUIError({ code: TUIErrorCode.Failed, message: "inviteUser failed, userList is empty" }))
          return
        }
        this.callState.scene = TUICallScene.Multi
        resolve()
      }).catch((error: TUIError) => {
        Logger.error(TAG, `inviteUser failed, error: `, error)
        reject(error)
      });
    })
  }

  public accept() {
    Logger.log(TAG, `accept`)
    TUICallEngine.createInstance().accept().then(() => {
    }).catch((error: TUIError) => {
      this.reset()
    });
  }

  public reject() {
    Logger.log(TAG, `reject`)
    TUICallEngine.createInstance().reject()
    this.reset()
  }

  public hangup() {
    Logger.log(TAG, `hangup`)
    TUICallEngine.createInstance().hangup()
    this.reset()
  }

  public openCamera(frontCamera: boolean, view: string) {
    Logger.log(TAG, `openCamera: front: ${frontCamera}, view: ${view}`)
    let camera = frontCamera ? TUICamera.Front : TUICamera.Back
    this.mediaState.isFrontCamera = frontCamera
    TUICallEngine.createInstance().openCamera(camera, view).then(() => {
      this.userState.selfUser.isVideoAvailable = true
      this.mediaState.isCameraOpen = true
    }).catch((error: TUIError) => {
      Logger.error(TAG, `openCamera failed, errorCode: ${error.code}, errorMsg: ${error.message}`)
      this.userState.selfUser.isVideoAvailable = false
      this.mediaState.isCameraOpen = false
    });
  }

  public closeCamera() {
    Logger.log(TAG, `closeCamera`)
    TUICallEngine.createInstance().closeCamera()
    this.userState.selfUser.isVideoAvailable = false
    this.mediaState.isCameraOpen = false
  }

  public switchCamera(frontCamera: boolean) {
    Logger.log(TAG, `switchCameram isFrontCamera: ${frontCamera}`)
    TUICallEngine.createInstance().switchCamera(frontCamera ? TUICamera.Front : TUICamera.Back)
    this.mediaState.isFrontCamera = frontCamera
  }

  public openMicrophone() {
    Logger.log(TAG, `openMicrophone`)
    TUICallEngine.createInstance().openMicrophone().then(() => {
      this.userState.selfUser.isAudioAvailable = true
      this.mediaState.isMicrophoneOpen = true
    }).catch((error: TUIError) => {
      Logger.error(TAG, `openMicrophone failed, errorCode: ${error.code}, errorMsg: ${error.message}`)
      this.userState.selfUser.isAudioAvailable = false
      this.mediaState.isMicrophoneOpen = false
    });
  }

  public closeMicrophone() {
    Logger.log(TAG, `closeMicrophone`)
    TUICallEngine.createInstance().closeMicrophone()
    this.userState.selfUser.isAudioAvailable = false
    this.mediaState.isMicrophoneOpen = false
  }

  public selectAudioPlaybackDevice(isSpeakerphone: boolean) {
    Logger.log(TAG, `selectAudioPlaybackDevice, isSpeakerphone: ${isSpeakerphone}`)
    let device = isSpeakerphone ? TUIAudioPlaybackDevice.Speakerphone : TUIAudioPlaybackDevice.Earpiece
    TUICallEngine.createInstance().selectAudioPlaybackDevice(device)
    this.mediaState.isSpeakerphone = isSpeakerphone
  }

  public startRemoteView(userId: string, view: string) {
    Logger.log(TAG, `startRemoteView: userId: ${userId}, view: ${view}`)
    TUICallEngine.createInstance().startRemoteView(userId, view)
  }

  public reset() {
    Logger.info(TAG, "reset")
    this.userState.reset()
    this.callState.reset()
    this.mediaState.reset()
    this.viewState.reset()
  }

  public setSelfInfo(nickname: string, avatar: string): Promise<void> {
    Logger.info(TAG, `setSelfInfo, nickname: ${nickname}, avatar:${avatar}`)
    return TUICallEngine.createInstance().setSelfInfo(nickname, avatar)
  }

  public setCallingBell(filePath: string) {
    Logger.info(TAG, `setCallingBell, filePath: ${filePath}`)
    Preference.getInstance(CallBellFeature.PROFILE_TUICALLKIT).putString(CallBellFeature.PROFILE_CALL_BELL, filePath)
  }

  public enableMuteMode(enable: boolean) {
    Logger.info(TAG, `enableMuteMode, enable: ${enable}`)
    GlobalState.enableMuteMode = enable
    Preference.getInstance(CallBellFeature.PROFILE_TUICALLKIT).putBoolean(CallBellFeature.PROFILE_MUTE_MODE, enable)
  }

  public enableFloatWindow(enable: boolean) {
    Logger.info(TAG, `enableFloatWindow, enable: ${enable}`)
    GlobalState.enableFloatWindow = enable
  }

  public enableMultiDeviceAbility(enable: boolean): Promise<void> {
    Logger.info(TAG, `enableMultiDeviceAbility, enable: ${enable}`)
    return TUICallEngine.createInstance().enableMultiDeviceAbility(enable)
  }

  public enableVirtualBackground(enable: Boolean) {
    Logger.info(TAG, `enableVirtualBackground, enable: ${enable}`)
    GlobalState.enableVirtualBackground = enable
  }

  public setBlurBackground(enable: Boolean): Promise<void> {
    Logger.info(TAG, `setBlurBackground, enable: ${enable}`)
    return new Promise((resolve, reject) => {
      let level = enable ? BLUR_LEVEL_HIGH : BLUR_LEVEL_CLOSE
      this.viewState.isVirtualBackgroundOpened = true
      TUICallEngine.createInstance().setBlurBackground(level).then(() => {
        resolve()
      }).catch((error: TUIError) => {
        this.viewState.isVirtualBackgroundOpened = false
        Logger.error(TAG, `setBlurBackground failed, errCode: ${error.code},message: ${error.message}`)
        reject(error)
      });
    })
  }

  private initCameraAndAudioDeviceState() {
    let isVideoCall = this.callState.mediaType == TUICallMediaType.Video
    this.mediaState.isCameraOpen = isVideoCall
    this.selectAudioPlaybackDevice(isVideoCall)
  }

  private setFramework() {
    let params: Record<string, number> = {
      "framework": Constants.FRAMEWORK, "component": Constants.COMPONENT, "language": Constants.LANGUAGE
    }
    let data: Record<string, Object> = {
      "api": "setFramework",
      "params": params
    };
    Logger.info(TAG, `setFramework: ${json.stringify(data)}`)
    TUICallEngine.createInstance().callExperimentalAPI(json.stringify(data));
  }
}