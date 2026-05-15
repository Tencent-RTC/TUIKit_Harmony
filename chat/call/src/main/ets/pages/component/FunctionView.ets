import { TUICallMediaType, TUICallRole, TUICallScene, TUICallStatus } from '@tencentcloud/rtcroomengine';
import { CallManager } from '../../manager/CallManager';
import GlobalState from '../../state/GlobalState';
import { User } from '../../state/UserState';

@ComponentV2
export struct FunctionView {
  @Local selfUser: User = CallManager.getInstance().userState.selfUser
  @Local scene: TUICallScene = CallManager.getInstance().callState.scene
  @Local mediaType: TUICallMediaType = CallManager.getInstance().callState.mediaType

  build() {
    if (this.selfUser.callRole == TUICallRole.Call) {
      if (this.scene != TUICallScene.Single) {
        this.videoAcceptViewBuilder()
      } else {
        if (this.mediaType == TUICallMediaType.Video) {
          if (this.selfUser.callStatus == TUICallStatus.Waiting) {
            this.videoWaitingViewBuilder()
          } else {
            this.videoAcceptViewBuilder()
          }
        } else {
          this.audioAcceptViewBuilder()
        }
      }
    } else {
      if (this.selfUser.callStatus == TUICallStatus.Waiting) {
        this.calleeWaitingViewBuilder()
      } else {
        if (this.scene == TUICallScene.Single && this.mediaType == TUICallMediaType.Audio) {
          this.audioAcceptViewBuilder()
        } else {
          this.videoAcceptViewBuilder()
        }
      }
    }
  }

  @Builder
  private calleeWaitingViewBuilder() {
    Row() {
      hangupButton()
      dialingButton()
    }.width('100%').justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  private audioAcceptViewBuilder() {
    Row() {
      Row() {
        micButton()
        hangupButton()
        audioPlaybackDeviceButton()
      }.width('100%').justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Bottom)
    }.width('100%').alignItems(VerticalAlign.Center)
  }

  @Builder
  private videoWaitingViewBuilder() {
    Column() {
      if (GlobalState.enableVirtualBackground) {
        Row() {
          switchCameraBigButton()
          blurBigButton()
          cameraButton()
        }.width('100%').justifyContent(FlexAlign.SpaceEvenly)

        hangupButton()
      } else {
        Row() {
          switchCameraBigButton()
          hangupButton()
          cameraButton()
        }.width('100%').justifyContent(FlexAlign.SpaceEvenly)
      }
    }.width('100%').justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  private videoAcceptViewBuilder() {
    Column() {
      Row() {
        micButton()
        audioPlaybackDeviceButton()
        cameraButton()
      }.width('100%').justifyContent(FlexAlign.SpaceEvenly).margin({ bottom: 20 })

      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        if (GlobalState.enableVirtualBackground && CallManager.getInstance().callState.scene == TUICallScene.Single
          && CallManager.getInstance().mediaState.isCameraOpen) {
          blurButton()
        }

        Image($r("app.media.callkit_ic_hangup"))
          .width($r("app.float.callkit_icon_size_middle")).height($r("app.float.callkit_icon_size_middle"))
          .margin({ left: 50, right: 50 }).onClick(() => {
          CallManager.getInstance().hangup()
        })

        if (CallManager.getInstance().callState.scene == TUICallScene.Single &&
        CallManager.getInstance().mediaState.isCameraOpen) {
          switchCameraButton()
        }
      }
    }
    .height('auto')
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .backgroundColor(this.showFunctionViewBackground() ? $r("app.color.callkit_color_gray_background") :
    Color.Transparent)
    .borderRadius({ topLeft: 12, topRight: 12 })
    .padding(20)
  }

  private showFunctionViewBackground(): boolean {
    if (CallManager.getInstance().callState.scene == TUICallScene.Single) {
      return false
    }
    if (CallManager.getInstance().userState.selfUser.callStatus == TUICallStatus.Waiting) {
      return false
    }
    return true
  }
}

@Builder
function hangupButton() {
  Column() {
    Image($r("app.media.callkit_ic_hangup"))
      .width($r("app.float.callkit_icon_size_middle")).height($r("app.float.callkit_icon_size_middle"))
      .margin({ bottom: 8 })
    Text((CallManager.getInstance().userState.selfUser.callRole == TUICallRole.Call &&
      CallManager.getInstance().userState.selfUser.callStatus == TUICallStatus.Waiting) ?
    $r('app.string.callkit_cancel') :
    $r('app.string.callkit_hangup'))
      .fontSize($r('app.float.callkit_text_size_middle'))
      .fontColor($r('app.color.callkit_color_white'))
      .padding(8)
  }.onClick(() => {
    CallManager.getInstance().hangup()
  })
}

@Builder
function dialingButton() {
  Column() {
    Image($r("app.media.callkit_ic_dialing"))
      .width($r("app.float.callkit_icon_size_middle")).height($r("app.float.callkit_icon_size_middle"))
      .margin({ bottom: 8 })
    Text($r('app.string.callkit_accept'))
      .fontSize($r('app.float.callkit_text_size_middle'))
      .fontColor($r('app.color.callkit_color_white'))
      .padding(8)
  }.onClick(() => {
    CallManager.getInstance().accept()
  })
}

@Builder
function micButton() {
  Column() {
    Image(CallManager.getInstance().mediaState.isMicrophoneOpen ? $r("app.media.callkit_ic_mic_open") :
    $r("app.media.callkit_ic_mic_close"))
      .width($r('app.float.callkit_icon_size_middle')).height($r('app.float.callkit_icon_size_middle'))
      .margin({ bottom: 8 })
    Text(CallManager.getInstance().mediaState.isMicrophoneOpen ? $r("app.string.callkit_mic_open") :
    $r("app.string.callkit_mic_close"))
      .fontSize($r('app.float.callkit_text_size_middle')).fontColor($r('app.color.callkit_color_white')).padding(8)
  }.onClick(() => {
    if (CallManager.getInstance().mediaState.isMicrophoneOpen) {
      CallManager.getInstance().closeMicrophone()
    } else {
      CallManager.getInstance().openMicrophone()
    }
  })
}

@Builder
function audioPlaybackDeviceButton() {
  Column() {
    Image(CallManager.getInstance().mediaState.isSpeakerphone ? $r("app.media.callkit_ic_speakerphone_on") :
    $r("app.media.callkit_ic_speakerphone_off"))
      .width($r('app.float.callkit_icon_size_middle')).height($r('app.float.callkit_icon_size_middle'))
      .margin({ bottom: 8 })
    Text(CallManager.getInstance().mediaState.isSpeakerphone ? $r('app.string.callkit_use_speakerphone') :
    $r('app.string.callkit_use_earpiece'))
      .fontSize($r('app.float.callkit_text_size_middle')).fontColor($r('app.color.callkit_color_white')).padding(8)
  }.onClick(() => {
    CallManager.getInstance().selectAudioPlaybackDevice(!CallManager.getInstance().mediaState.isSpeakerphone)
  })
}

@Builder
function cameraButton() {
  Column() {
    Image(CallManager.getInstance().mediaState.isCameraOpen ? $r("app.media.callkit_ic_camera_on") :
    $r("app.media.callkit_ic_camera_off"))
      .width($r('app.float.callkit_icon_size_middle')).height($r('app.float.callkit_icon_size_middle'))
      .margin({ bottom: 8 })
    Text(CallManager.getInstance().mediaState.isCameraOpen ? $r("app.string.callkit_camera_open") :
    $r('app.string.callkit_camera_close'))
      .fontSize($r('app.float.callkit_text_size_middle')).fontColor($r('app.color.callkit_color_white')).padding(8)
  }.onClick(() => {
    if (CallManager.getInstance().mediaState.isCameraOpen) {
      CallManager.getInstance().closeCamera()
    } else {
      let isFront = CallManager.getInstance().mediaState.isFrontCamera
      CallManager.getInstance().openCamera(isFront, CallManager.getInstance().userState.selfUser.viewId)
    }
  })
}

@Builder
export function switchCameraButton() {
  Column() {
    Image($r("app.media.callkit_ic_switch_camera"))
      .width($r('app.float.callkit_icon_size_mini')).height($r('app.float.callkit_icon_size_mini'))
  }.onClick(() => {
    CallManager.getInstance().switchCamera(!CallManager.getInstance().mediaState.isFrontCamera)
  })
}

@Builder
function switchCameraBigButton() {
  Column() {
    Image($r("app.media.callkit_ic_switch_camera_off"))
      .width($r('app.float.callkit_icon_size_middle')).height($r('app.float.callkit_icon_size_middle'))
      .margin({ bottom: 8 })
    Text($r("app.string.callkit_switch_camera"))
      .fontSize($r('app.float.callkit_text_size_middle')).fontColor($r('app.color.callkit_color_white')).padding(8)
  }.onClick(() => {
    CallManager.getInstance().switchCamera(!CallManager.getInstance().mediaState.isFrontCamera)
  })
}

@Builder
export function blurButton() {
  Column() {
    Image($r("app.media.callkit_ic_blur_background"))
      .width($r('app.float.callkit_icon_size_mini')).height($r('app.float.callkit_icon_size_mini'))
  }.onClick(() => {
    CallManager.getInstance().setBlurBackground(!CallManager.getInstance().viewState.isVirtualBackgroundOpened)
  })
}

@Builder
function blurBigButton() {
  Column() {
    Image(CallManager.getInstance().viewState.isVirtualBackgroundOpened ? $r("app.media.callkit_ic_blur_on") :
    $r("app.media.callkit_ic_blur_off"))
      .width($r('app.float.callkit_icon_size_middle')).height($r('app.float.callkit_icon_size_middle'))
      .margin({ bottom: 8 })
    Text($r("app.string.callkit_blur_background"))
      .fontSize($r('app.float.callkit_text_size_middle')).fontColor($r('app.color.callkit_color_white')).padding(8)
  }.onClick(() => {
    CallManager.getInstance().setBlurBackground(!CallManager.getInstance().viewState.isVirtualBackgroundOpened)
  })
}