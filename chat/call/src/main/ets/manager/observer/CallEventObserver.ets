import { CallManager } from '../CallManager'
import { User } from '../../state/UserState'
import Logger from '../../common/Logger'
import TUICallEngine, {
  TUICallEndReason,
  TUICallEvents,
  TUICallMediaType,
  TUICallObserverExtraInfo,
  TUICallRole,
  TUICallScene,
  TUICallStatus
} from '@tencentcloud/rtcroomengine'
import TUILogin from '../../common/TUILogin'
import { UserManager } from '../UserManager'
import { emitter } from '@kit.BasicServicesKit'
import LongTimeTask from '../../common/LongTimeTask'
import json from '@ohos.util.json'
import Constants, { CallEvent } from '../../common/Constants'

const TAG: string = "CallEventObserver"

export class CallEventObserver {
  private callTimerTaskId: number = -1

  public subscribeEvent() {
    TUICallEngine.createInstance().on(TUICallEvents.onError, this.onError.bind(this))

    TUICallEngine.createInstance().on(TUICallEvents.onCallReceived, this.onCallReceived.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onCallBegin, this.onCallBegin.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onCallEnd, this.onCallEnd.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onCallNotConnected, this.onCallNotConnected.bind(this))

    TUICallEngine.createInstance().on(TUICallEvents.onUserReject, this.onUserReject.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserNoResponse, this.onUserNoResponse.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserLineBusy, this.onUserLineBusy.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserInviting, this.onUserInviting.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserJoin, this.onUserJoin.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserLeave, this.onUserLeave.bind(this))

    TUICallEngine.createInstance().on(TUICallEvents.onUserVideoAvailable, this.onUserVideoAvailable.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserAudioAvailable, this.onUserAudioAvailable.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserVoiceVolumeChanged, this.onUserVoiceVolumeChanged.bind(this))
    TUICallEngine.createInstance()
      .on(TUICallEvents.onUserNetworkQualityChanged, this.onUserNetworkQualityChanged.bind(this))

    TUICallEngine.createInstance().on(TUICallEvents.onKickedOffline, this.onKickedOffline.bind(this))
    TUICallEngine.createInstance().on(TUICallEvents.onUserSigExpired, this.onUserSigExpired.bind(this))
  }

  public unsubscribeEvent() {
    TUICallEngine.createInstance().off(TUICallEvents.onError, this.onError.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onCallReceived, this.onCallReceived.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onCallBegin, this.onCallBegin.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onCallEnd, this.onCallEnd.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onCallNotConnected, this.onCallNotConnected.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserReject, this.onUserReject.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserNoResponse, this.onUserNoResponse.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserLineBusy, this.onUserLineBusy.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserInviting, this.onUserInviting.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserJoin, this.onUserJoin.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserLeave, this.onUserLeave.bind(this))

    TUICallEngine.createInstance().off(TUICallEvents.onUserVideoAvailable, this.onUserVideoAvailable.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserAudioAvailable, this.onUserAudioAvailable.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserVoiceVolumeChanged, this.onUserVoiceVolumeChanged.bind(this))
    TUICallEngine.createInstance()
      .off(TUICallEvents.onUserNetworkQualityChanged, this.onUserNetworkQualityChanged.bind(this))

    TUICallEngine.createInstance().off(TUICallEvents.onKickedOffline, this.onKickedOffline.bind(this))
    TUICallEngine.createInstance().off(TUICallEvents.onUserSigExpired, this.onUserSigExpired.bind(this))
  }

  private onError(code: number, message: string | null): void {
    Logger.error(TAG, `onError, errorCode: ${code}, errorMsg: ${message}`)
  }

  private onCallReceived(callId: string, callerId: string, calleeIdList: string[], mediaType: TUICallMediaType,
    info: TUICallObserverExtraInfo): void {
    Logger.log(TAG,
      `onCallReceived, callId: ${callId}, callerId: ${callerId}, calleeIdList: ${calleeIdList},
       mediaType: ${TUICallMediaType[mediaType]}, info: ${json.stringify(info)}`)
    this.setFramework()
    if (mediaType == TUICallMediaType.None || calleeIdList == null || calleeIdList.length == 0) {
      return
    }
    CallManager.getInstance().callState.mediaType = mediaType
    let groupId : string = info?.chatGroupId
    CallManager.getInstance().callState.chatGroupId = groupId != null ? groupId : ""
    let scene : TUICallScene = TUICallScene.Single
    if (groupId != null && groupId.length > 0) {
      scene = TUICallScene.Group
    } else if (calleeIdList.length > 1) {
      scene = TUICallScene.Multi
    }
    Logger.log(TAG, `onCallReceived, scene: ${scene}`)

    CallManager.getInstance().callState.scene = scene
    CallManager.getInstance().callState.callId = callId

    if (callerId.length != 0) {
      let user = new User()
      user.userId = callerId
      user.callRole = TUICallRole.Call
      user.callStatus = TUICallStatus.Waiting
      CallManager.getInstance().userState.remoteUserArray.push(user)
      UserManager.instance.updateUserInfo(user)
    }
    for (let userId of calleeIdList) {
      if (userId.length > 0 && userId != TUILogin.userId) {
        let user = new User()
        user.userId = userId
        user.callRole = TUICallRole.Called
        user.callStatus = TUICallStatus.Waiting
        CallManager.getInstance().userState.remoteUserArray.push(user)
        UserManager.instance.updateUserInfo(user)
      }
    }
    let selfUser = CallManager.getInstance().userState.selfUser
    selfUser.userId = TUILogin.userId
    selfUser.avatar = TUILogin.avatar
    selfUser.nickname = TUILogin.nickname
    selfUser.callRole = TUICallRole.Called
    selfUser.callStatus = TUICallStatus.Waiting

    emitter.emit({ eventId: CallEvent.CALL_STATUS, priority: emitter.EventPriority.HIGH },
      { data: { userId: selfUser.userId, callStatus: TUICallStatus.Waiting } });

    //初始化被叫的设备开关状态
    let isVideoCall = CallManager.getInstance().callState.mediaType == TUICallMediaType.Video
    CallManager.getInstance().mediaState.isCameraOpen = isVideoCall
    CallManager.getInstance().selectAudioPlaybackDevice(isVideoCall)
  }

  private onCallBegin(callId: string, mediaType: TUICallMediaType, info: TUICallObserverExtraInfo): void {
    Logger.log(TAG,
      `onCallBegin, callId: ${callId}, mediaType: ${TUICallMediaType[mediaType]}, info: ${json.stringify(info)}`)

    let selfUser = CallManager.getInstance().userState.selfUser
    if (selfUser.callStatus != TUICallStatus.Accept) {
      selfUser.callStatus = TUICallStatus.Accept

      emitter.emit({ eventId: CallEvent.CALL_STATUS, priority: emitter.EventPriority.HIGH },
        { data: { userId: selfUser.userId, callStatus: TUICallStatus.Accept } });
    }
    if (CallManager.getInstance().mediaState.isMicrophoneOpen) {
      CallManager.getInstance().openMicrophone()
    } else {
      CallManager.getInstance().closeMicrophone()
    }
    this.startLongTimeTask()
    this.startCallTimer()
  }

  private onCallEnd(callId: string, mediaType: TUICallMediaType, reason: TUICallEndReason, userId: string,
    totalTime: number, info: TUICallObserverExtraInfo): void {
    Logger.log(TAG,
      `onCallEnd, callId: ${callId}, mediaType: ${TUICallMediaType[mediaType]}, reason: ${TUICallEndReason[reason]},
       userId: ${userId}, totalTime: ${totalTime}, info: ${JSON.stringify(info)}`)
    this.resetCall()
  }

  private onCallNotConnected(callId: string, mediaType: TUICallMediaType, reason: TUICallEndReason, userId: string,
    info: TUICallObserverExtraInfo): void {
    Logger.log(TAG,
      `onCallNotConnected, callId: ${callId}, mediaType: ${TUICallMediaType[mediaType]},
      reason: ${TUICallEndReason[reason]}, userId: ${userId}, info: ${JSON.stringify(info)}`)
    this.resetCall()
  }

  private onUserReject(userId: string): void {
    Logger.log(TAG, `onUserReject, userId: ${userId}`)
    this.removeUserOnLeave(userId)
  }

  private onUserNoResponse(userId: string): void {
    Logger.log(TAG, `onUserNoResponse, userId: ${userId}`)
    this.removeUserOnLeave(userId)
  }

  private onUserLineBusy(userId: string): void {
    Logger.log(TAG, `onUserLineBusy, userId: ${userId}`)
    this.removeUserOnLeave(userId)
  }

  private onUserInviting(userId: string): void {
    Logger.log(TAG, `onUserInviting, userId: ${userId}`)
    let user = this.findUser(userId)
    if (user.userId.length == 0) {
      user.userId = userId
      user.callRole == TUICallRole.Called
    }
    if (!CallManager.getInstance().userState.remoteUserArray.includes(user) &&
      userId != CallManager.getInstance().userState.selfUser.userId) {
      user.callStatus = TUICallStatus.Waiting
      CallManager.getInstance().userState.remoteUserArray.push(user)
    }
    if (user.nickname.trim().length === 0 || user.avatar.trim().length === 0) {
      UserManager.instance.updateUserInfo(user)
    }
  }

  private onUserJoin(userId: string): void {
    Logger.log(TAG, `onUserJoin, userId: ${userId}`)
    let user = this.findUser(userId)
    if (user.userId.length == 0) {
      user.userId = userId
    }
    user.callStatus = TUICallStatus.Accept
    if (!CallManager.getInstance().userState.remoteUserArray.includes(user) &&
      userId != CallManager.getInstance().userState.selfUser.userId) {
      CallManager.getInstance().userState.remoteUserArray.push(user)
    }
    if (user.nickname.trim().length === 0 || user.avatar.trim().length === 0) {
      UserManager.instance.updateUserInfo(user)
    }
  }

  private onUserLeave(userId: string): void {
    Logger.log(TAG, `onUserLeave, userId: ${userId}`)
    this.removeUserOnLeave(userId)
  }

  private onUserVideoAvailable(userId: string, videoAvailable: boolean): void {
    Logger.log(TAG, `onUserVideoAvailable, userId: ${userId}, videoAvailable: ${videoAvailable}`)
    let user = this.findUser(userId)
    if (user.userId.length != 0) {
      user.isVideoAvailable = videoAvailable
    }
  }

  private onUserAudioAvailable(userId: string, audioAvailable: boolean): void {
    Logger.log(TAG, `onUserAudioAvailable, userId: ${userId}, audioAvailable: ${audioAvailable}`)
    let user = this.findUser(userId)
    if (user.userId.length != 0) {
      user.isAudioAvailable = audioAvailable
    }
  }

  private onUserVoiceVolumeChanged(): void {
    //TODO
  }

  private onUserNetworkQualityChanged(): void {
    //TODO
  }

  private onKickedOffline(): void {
    Logger.log(TAG, `onKickedOffline`)
    CallManager.getInstance().hangup()
    this.resetCall()
  }

  private onUserSigExpired(): void {
    Logger.log(TAG, `onUserSigExpired`)
    CallManager.getInstance().hangup()
    this.resetCall()
  }

  private findUser(userId: string): User {
    if (userId.length == 0) {
      return new User()
    }
    if (userId == CallManager.getInstance().userState.selfUser.userId) {
      return CallManager.getInstance().userState.selfUser
    }
    let list = CallManager.getInstance().userState.remoteUserArray
    for (let user of list) {
      if (user.userId == userId) {
        return user
      }
    }
    return new User()
  }

  private removeUserOnLeave(userId: string) {
    let user = this.findUser(userId)
    if (user == null || user.userId.length == 0) {
      return
    }
    user.reset()

    let remoteUserList = CallManager.getInstance().userState.remoteUserArray
    let index = remoteUserList.indexOf(user)
    if (index > -1) {
      remoteUserList.splice(index, 1)
    }

    if (CallManager.getInstance().callState.scene == TUICallScene.Single) {
      this.resetCall()
    }
  }

  private resetCall() {
    Logger.log(TAG, "reset call")
    CallManager.getInstance().reset()
    this.stopLongTimeTask()
    this.stopCallTimer()
  }

  private startCallTimer() {
    if (this.callTimerTaskId != -1) {
      clearInterval(this.callTimerTaskId)
    }
    this.callTimerTaskId = setInterval(() => {
      CallManager.getInstance().callState.callDuration++
    }, 1000);
  }

  private stopCallTimer() {
    clearInterval(this.callTimerTaskId)
  }

  private startLongTimeTask() {
    LongTimeTask.startLongTask()
  }

  private stopLongTimeTask() {
    LongTimeTask.stopLongTask()
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