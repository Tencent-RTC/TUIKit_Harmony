import { CallManager } from '../../manager/CallManager'
import { promptAction, router } from '@kit.ArkUI'
import TUILogin from '../../common/TUILogin'
import Logger from '../../common/Logger'
import json from '@ohos.util.json'
import { TUIError } from '@tencentcloud/rtcroomengine'
import '../inviteuser/SelectMemberView'

const TAG: string = "CallInviteUserButton"

@ComponentV2
export struct CallInviteUserButton {
  private chatGroupId = CallManager.getInstance().callState.chatGroupId

  build() {
    Column() {
      Image($r('app.media.callkit_ic_invite_user')).width(24).height(24)
        .onClick(() => {
          this.inviteUser()
        })
        .visibility(this.chatGroupId?.length > 0 ? Visibility.Visible : Visibility.Hidden)
    }
  }

  private inviteUser(): void {
    if (this.chatGroupId?.length <= 0) {
      promptAction.showToast({ message: $r("app.string.callkit_chat_group_id_empty") })
      return
    }
    let list: Array<string> = new Array()
    for (const user of CallManager.getInstance().userState.remoteUserArray) {
      if (user?.userId?.length > 0 && !list.includes(user.userId)) {
        list.push(user.userId);
      }
    }
    if (!list.includes(TUILogin.userId)) {
      list.push(TUILogin.userId)
    }
    Logger.info(TAG, `inviteUserButton clicked, chatGroupId: ${this.chatGroupId}, list: ${list}`)
    this.startSelectMemberView(list)
  }

  private startSelectMemberView(list: Array<string>) {
    try {
      let param: InviteUserInfo = {
        groupId: this.chatGroupId,
        selectMemberList: list
      }
      try {
        router.pushNamedRoute({ name: 'SelectMemberViewRoute', params: param })
      } catch (err) {
        let message = (err as TUIError).message
        let code = (err as TUIError).code
        Logger.error(TAG, `pushNamedRoute failed, code is ${code}, message is ${message}`);
      }
    } catch (err) {
      Logger.error(TAG, `pushNamedRoute failed, error: ${json.stringify(err)}`);
    }
  }
}

export interface InviteUserInfo {
  groupId: string;
  selectMemberList: string[];
}