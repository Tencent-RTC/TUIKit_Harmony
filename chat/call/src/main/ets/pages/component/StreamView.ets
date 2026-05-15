import { User } from '../../state/UserState'
import { MultiCallLoadingView } from './multi/MultiCallLoadingView'
import { TUICallScene, TUICallStatus } from '@tencentcloud/rtcroomengine'
import { CallManager } from '../../manager/CallManager'
import Logger from '../../common/Logger'

const TAG: string = "StreamView"

@ComponentV2
export struct StreamView {
  @Param user: User = new User()

  @Monitor("user.isVideoAvailable")
  onVideoAvailableChange(monitor: IMonitor) {
    Logger.info(TAG,
      `[${this.user.userId}] videoAvailable change from ${monitor.value()?.before} to ${monitor.value()?.now}`);
    CallManager.getInstance().startRemoteView(this.user.userId, this.user.viewId)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      //avatar
      Image(this.user.avatar)
        .alt($r('app.media.callkit_ic_avatar'))
        .objectFit(this.isMultiCall() ? ImageFit.Fill : ImageFit.Cover)
        .width(this.isMultiCall() ? '100%' : 60)
        .height(this.isMultiCall() ? '100%' : 60)
        .borderRadius(this.isMultiCall() ? 0 : 8)
        .visibility(this.isAvatarVisible() ? Visibility.Visible : Visibility.Hidden)
      //videoView
      XComponent({ id: this.user.viewId, type: XComponentType.SURFACE, libraryname: 'liteavsdk' })
        .backgroundColor(Color.Gray)
        .width('100%').height('100%')
        .visibility(this.user.isVideoAvailable ? Visibility.Visible : Visibility.Hidden)

      MultiCallLoadingView({ loading: this.isLoadingViewVisible() })
        .visibility(this.isLoadingViewVisible() ? Visibility.Visible : Visibility.Hidden)

      //nickname
      Row() {
        Text(this.user.userId).fontColor($r('app.color.callkit_color_white')).fontSize(12).margin(4)
          .visibility(this.isNicknameVisible() ? Visibility.Visible : Visibility.Hidden)
      }.width('100%').height('100%').alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height('100%')
    .backgroundImage(this.user.avatar)
    .backgroundImageSize(ImageSize.FILL)
    .backdropBlur(80)
  }

  private isLoadingViewVisible(): boolean {
    if (this.user.userId == CallManager.getInstance().userState.selfUser.userId) {
      return false
    }
    return this.user.callStatus != TUICallStatus.Accept
  }

  private isMultiCall(): boolean {
    return CallManager.getInstance().callState.scene != TUICallScene.Single
  }

  private isAvatarVisible(): boolean {
    const selfUser = CallManager.getInstance().userState.selfUser
    return !(this.user.userId == selfUser.userId && selfUser.callStatus == TUICallStatus.Waiting && !this.isMultiCall())
  }

  private isNicknameVisible(): boolean {
    const selfUser = CallManager.getInstance().userState.selfUser;
    return this.isMultiCall() && this.user.userId !== selfUser.userId && !this.user.isVideoAvailable
  }
}