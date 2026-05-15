import { TUICallMediaType, TUICallRole, TUICallScene, TUICallStatus } from '@tencentcloud/rtcroomengine'
import { CallManager } from '../../manager/CallManager'

@ComponentV2
export struct CallHintView {
  build() {
    Column() {
      Text(this.getHintMessage())
        .fontColor($r('app.color.callkit_color_white'))
        .fontSize(14)
        .visibility(CallManager.getInstance().userState.selfUser.callStatus == TUICallStatus.Waiting ?
        Visibility.Visible : Visibility.Hidden)
    }.height('auto')
  }

  private getHintMessage(): string {
    let isWaiting = CallManager.getInstance().userState.selfUser.callStatus == TUICallStatus.Waiting
    if (!isWaiting) {
      return ""
    }
    let isCaller = CallManager.getInstance().userState.selfUser.callRole == TUICallRole.Call
    let isMultiCall = CallManager.getInstance().callState.scene != TUICallScene.Single

    if (isCaller) {
      let callerHint = getContext().resourceManager.getStringSync($r('app.string.callkit_waiting_response').id)
      if (isMultiCall) {
        callerHint = getContext().resourceManager.getStringSync($r('app.string.callkit_waiting').id)
      }
      return callerHint
    }
    let calleeHint = ""
    if (isMultiCall) {
      calleeHint = getContext().resourceManager.getStringSync($r('app.string.callkit_invite_multi_call').id)
      return calleeHint
    }
    let isVideoCall = CallManager.getInstance().callState.mediaType == TUICallMediaType.Video
    calleeHint = getContext().resourceManager.getStringSync($r('app.string.callkit_invite_video_call').id)
    if (!isVideoCall) {
      calleeHint = getContext().resourceManager.getStringSync($r('app.string.callkit_invite_audio_call').id)
    }
    return calleeHint
  }
}