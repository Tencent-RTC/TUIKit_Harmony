import { TUICallRole } from '@tencentcloud/rtcroomengine';
import { CallManager } from '../../../manager/CallManager';
import { User } from '../../../state/UserState';

@ComponentV2
export struct MultiCallWaitingView {
  @Param userList: User[] = Array();

  aboutToAppear(): void {
    this.userList.push(CallManager.getInstance().userState.selfUser);
    let list = CallManager.getInstance().userState.remoteUserArray
      .filter(user => user.callRole !== TUICallRole.Call)
    for (let user of list) {
      this.userList.push(user)
    }
  }

  build() {
    Column() {
      Text($r('app.string.callkit_invitee_user_list'))
        .fontSize(12).fontColor($r('app.color.callkit_color_white')).margin(6)
      List() {
        ForEach(this.userList, (item: User) => {
          ListItem() {
            Image(item.avatar).alt($r('app.media.callkit_ic_avatar')).width(40).height(40).margin(4).borderRadius(8)
          }
        }, (item: User) => item.userId)
      }.listDirection(Axis.Horizontal).height('10%')
    }
  }
}