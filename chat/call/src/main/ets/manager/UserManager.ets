import { ArrayList } from '@kit.ArkTS';
import { V2TIMFriendInfoResult, V2TIMManager } from '@tencentcloud/imsdk';
import { TUIError, TUIErrorCode } from '@tencentcloud/rtcroomengine';
import Logger from '../common/Logger';
import { User } from '../state/UserState';
import json from '@ohos.util.json';

const TAG: string = "UserManager"

export class UserManager {
  public static instance: UserManager = new UserManager()

  public updateUserInfo(user: User) {
    if (user == null || user.userId == null || user.userId.length == 0) {
      return
    }
    let list: string[] = [user.userId]
    this.getFriendsInfo(list).then((users: ArrayList<User>) => {
      if (users == null || users.length == 0) {
        Logger.error(TAG, `updateUserInfo failed, users is empty`)
        return
      }
      const info = users[0]
      Logger.info(TAG, `updateUserInfo, user: ${info.toString()}`)
      user.nickname = (info.nickname == null || info.nickname.length == 0) ? info.userId : info.nickname
      user.avatar = info.avatar
    }).catch((error: TUIError) => {
      Logger.error(TAG, `updateUserInfo failed, errCode:${error.code}, errMsg: ${error.message}`)
    });
  }

  public updateUserInfoList(userList: string[]): Promise<ArrayList<User>> {
    return this.getFriendsInfo(userList)
  }

  private getFriendsInfo(userList: string[]): Promise<ArrayList<User>> {
    return new Promise((resolve, reject) => {
      if (userList == null || userList.length == 0) {
        reject(new TUIError({ code: TUIErrorCode.Failed, message: "getFriendsInfo failed, userList is empty" }))
        Logger.error(TAG, `getFriendsInfo failed, userList is empty`)
        return
      }
      V2TIMManager.getFriendshipManager().getFriendsInfo(userList).then((infoList: V2TIMFriendInfoResult[]) => {
        Logger.warn(TAG, `getFriendsInfo success, infoList:${json.stringify(infoList)}, length: ${infoList.length}`)
        if (infoList == null || infoList.length <= 0) {
          reject(new TUIError({ code: TUIErrorCode.Failed, message: "getFriendsInfo failed, infoList is empty" }))
          return
        }
        let list: ArrayList<User> = new ArrayList()
        for (let info of infoList) {
          if (info == null || info.friendInfo == null) {
            continue
          }
          const friendInfo = info.friendInfo
          const fullInfo = friendInfo.userFullInfo

          let user = new User()
          user.userId = friendInfo.userID

          let name = friendInfo.friendRemark
          if (name == null || name.length == 0) {
            name = fullInfo?.nickName
          }
          user.nickname = name
          user.avatar = fullInfo?.faceURL

          Logger.info(TAG, `getFriendsInfo, user: ${user.toString()}`)
          list.add(user)
        }
        resolve(list)
      }).catch((error: TUIError) => {
        reject(error);
        Logger.info(TAG, `getFriendsInfo failed, errCode:${error.code},  errMsg: ${error.message}`)
      });
    })
  }
}

