import { TUICallMediaType, TUICallRole, TUICallScene, TUICallStatus } from '@tencentcloud/rtcroomengine'
import { CallManager } from '../manager/CallManager'
import { FunctionView } from './component/FunctionView'
import { CallHintView } from './component/CallHintView'
import { MultiGridView } from './component/multi/MultiGridView'
import { User } from '../state/UserState'
import { StreamView } from './component/StreamView'
import { MultiCallWaitingView } from './component/multi/MultiCallWaitingView'
import { CallTimeView } from './component/CallTimeView'
import Logger from '../common/Logger'
import { CallInviteUserButton } from './component/CallInviteUserButton'

const TAG: string = "CallMainView"

@Entry({ routeName: 'CallMainViewRoute' })
@ComponentV2
export struct CallMainView {
  @Param selfUser: User = CallManager.getInstance().userState.selfUser
  @Param remoteUsers: Array<User> = CallManager.getInstance().userState.remoteUserArray
  @Local isViewSwitched: boolean = false

  aboutToAppear(): void {
    Logger.info(TAG, "aboutToAppear")
    Logger.log(TAG, `selfUser: ${this.selfUser.userId}, remoteUserArray: ${this.remoteUsers}`)
  }

  aboutToDisappear(): void {
    Logger.info(TAG, "aboutToDisappear")
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (CallManager.getInstance().callState.scene == TUICallScene.Single) {
        this.singleCallViewBuilder()
      } else {
        this.multiCallViewBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundImage(CallManager.getInstance().userState.selfUser.avatar)
    .backgroundImageSize(ImageSize.FILL)
    .backdropBlur(80)
  }

  onPageShow(): void {
    let isVideoCall = CallManager.getInstance().callState.mediaType == TUICallMediaType.Video
    if (!isVideoCall) {
      return
    }
    if (CallManager.getInstance().mediaState.isCameraOpen) {
      let frontCamera = CallManager.getInstance().mediaState.isFrontCamera
      CallManager.getInstance().openCamera(frontCamera, CallManager.getInstance().userState.selfUser.viewId)
    }
    for (let user of this.remoteUsers) {
      CallManager.getInstance().startRemoteView(user.userId, user.viewId)
    }
  }

  onBackPress(): boolean {
    return true
  }

  @Builder
  private singleCallViewBuilder() {
    if (CallManager.getInstance().callState.mediaType == TUICallMediaType.Video) {
      Stack() {
        this.overlayVideoViewBuilder()

        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
          CallTimeView()
          Blank()
          if (CallManager.getInstance().userState.selfUser.callStatus == TUICallStatus.Waiting) {
            this.waitingViewUserInfoBuilder()
          }
          Blank()
          CallHintView().margin({ bottom: 20 })
          FunctionView().width('100%').margin({ bottom: 40 })
        }.height('100%').margin({ top: 80 }).padding({ bottom: 40 })
      }.height('100%')
    } else if (CallManager.getInstance().callState.mediaType == TUICallMediaType.Audio) {
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
        CallTimeView().margin({ top: 60 })
        Blank()
        this.waitingViewUserInfoBuilder()
        Blank()
        CallHintView().margin({ bottom: 20 })
        FunctionView().width('100%')
      }
      .backgroundImage(CallManager.getInstance().userState.remoteUserArray[0].avatar)
      .backgroundImageSize(ImageSize.FILL)
      .backdropBlur(80)
      .width('100%')
      .height('100%')
      .padding({ bottom: 40 })
    }
  }

  @Builder
  private multiCallViewBuilder() {
    Column() {
      //TODO: 画中画按钮
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        // this.floatButtonBuilder()
        Blank()
        CallTimeView()
        if (CallManager.getInstance().userState.selfUser.callRole == TUICallRole.Call) {
          CallHintView()
        }
        Blank()
        CallInviteUserButton()
      }.width('90%').margin({ left: 20, right: 20, bottom: 10 }).padding({ top: 60 })

      if (CallManager.getInstance().userState.selfUser.callRole == TUICallRole.Called &&
        CallManager.getInstance().userState.selfUser.callStatus == TUICallStatus.Waiting) {
        Column() {
          this.waitingViewUserInfoBuilder()
          MultiCallWaitingView().height('auto').margin({ bottom: 80 })
          CallHintView().height('auto').margin({ bottom: 60 })
          FunctionView().width('100%').padding(10)
        }.justifyContent(FlexAlign.End).height('auto')
      } else {
        MultiGridView({ builder: gridVideoViewBuilder })
        Blank()
        FunctionView().width('100%')
      }
    }.width('100%').height('100%').justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  private waitingViewUserInfoBuilder() {
    Column() {
      Image(this.remoteUsers[0].avatar)
        .alt($r('app.media.callkit_ic_avatar'))
        .width(100)
        .height(100)
        .borderRadius(15)
        .margin({ bottom: 10 })
      Text(this.remoteUsers[0].nickname).fontSize(16).fontColor($r('app.color.callkit_color_white')).margin(8)
    }.alignItems(HorizontalAlign.Center)
  }

  @Builder
  private overlayVideoViewBuilder() {
    Stack({ alignContent: Alignment.TopEnd }) {
      if (!this.isViewSwitched) {
        if (this.selfUser.callStatus == TUICallStatus.Accept) {
          StreamView({ user: this.remoteUsers[0] }).width('100%').height('100%').align(Alignment.BottomEnd)

          StreamView({ user: this.selfUser })
            .width(120).height(180).margin({ top: 100, right: 20 })
            .onClick(() => {
              this.isViewSwitched = !this.isViewSwitched
            })
        } else {
          StreamView({ user: this.selfUser }).width('100%').height('100%').align(Alignment.BottomEnd)
            .onClick(() => {
              this.isViewSwitched = !this.isViewSwitched
            })
        }
      } else {
        StreamView({ user: this.selfUser }).width('100%').height('100%').align(Alignment.BottomEnd)

        if (this.selfUser.callStatus == TUICallStatus.Accept) {
          StreamView({ user: this.remoteUsers[0] })
            .width(120).height(180).margin({ top: 100, right: 20 })
            .onClick(() => {
              this.isViewSwitched = !this.isViewSwitched
            })
        }
      }
    }.width('100%').height('100%')
  }
}

@Builder
function gridVideoViewBuilder() {
  StreamView({ user: CallManager.getInstance().userState.selfUser })
    .width('100%').height('100%').align(Alignment.BottomEnd)

  ForEach(CallManager.getInstance().userState.remoteUserArray, (item: User) => {
    StreamView({ user: item }).width('100%').height('100%').align(Alignment.BottomEnd)
  }, (item: User) => item.userId)
}