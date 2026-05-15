import { TUICallRole, TUICallStatus } from '@tencentcloud/rtcroomengine';
import { emitter } from '@kit.BasicServicesKit';
import { CallEvent } from '../common/Constants';

@ObservedV2
export class UserState {
  @Trace selfUser: User = new User()
  @Trace remoteUserArray: Array<User> = new Array()

  public reset() {
    if (this.selfUser.callStatus != TUICallStatus.None) {
      emitter.emit({ eventId: CallEvent.CALL_STATUS, priority: emitter.EventPriority.HIGH },
        { data: { userId: this.selfUser.userId, callStatus: TUICallStatus.None } });
    }
    this.selfUser.reset()

    for (let user of this.remoteUserArray) {
      user.reset()
    }
    this.remoteUserArray.length = 0
  }
}

@ObservedV2
export class User {
  userId: string = ""
  @Trace nickname: string = ""
  @Trace avatar: string = "https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar3.png"
  @Trace isAudioAvailable: boolean = false
  @Trace isVideoAvailable: boolean = false
  @Trace callRole: TUICallRole = TUICallRole.None
  @Trace callStatus: TUICallStatus = TUICallStatus.None

  get viewId(): string {
    return this.userId + "#MainStream"
  }

  public reset() {
    this.nickname = ""
    this.avatar = "https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar3.png"
    this.isAudioAvailable = false
    this.isVideoAvailable = false
    this.callRole = TUICallRole.None
    this.callStatus = TUICallStatus.None
  }

  toString(): string {
    return `User{userId=${this.userId},nickname=${this.nickname},avatar=${this.avatar},callRole=${this.callRole},
    callStatus=${this.callStatus},isAudioAvailable=${this.isAudioAvailable}, isVideoAvailable=${this.isVideoAvailable}}`
  }
}