import { V2TIMFollowTypeCheckResult, LiveInfo, LoginStore, V2TIMFriendshipListener, V2TIMManager, V2TIMUserFullInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { rgba, white } from '../../../common/theme/LiveTheme'

export function isFollowed(followType: number): boolean {
  return followType === 1 || followType === 3
}

@Component
export struct HostInfoView {
  @Prop @Watch('bind') liveInfo: LiveInfo
  @Prop likeCount: number = 0
  onError?: (message: string) => void
  @State private hostUserID: string = ''
  @State private followingHostUserIDs: string[] = []
  @State private isFollowButtonHidden: boolean = false
  private lastFollowTapTime: number = 0
  private friendshipListener?: V2TIMFriendshipListener

  aboutToAppear(): void {
    this.bind()
    const listener: V2TIMFriendshipListener = {
      onMyFollowingListChanged: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => {
        const userIDs = userInfoList.map((info: V2TIMUserFullInfo) => info.userID ?? '').filter((id: string) => id.length > 0)
        this.handleFollowingListChanged(userIDs)
      }
    }
    this.friendshipListener = listener
    V2TIMManager.getFriendshipManager().addFriendListener(listener)
  }

  aboutToDisappear(): void {
    if (this.friendshipListener !== undefined) {
      V2TIMManager.getFriendshipManager().removeFriendListener(this.friendshipListener)
      this.friendshipListener = undefined
    }
  }

  private bind(): void {
    const ownerUserID = this.liveInfo.liveOwner.userID
    if (ownerUserID !== this.hostUserID) {
      this.followingHostUserIDs = []
      this.lastFollowTapTime = 0
    }
    const selfID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    this.hostUserID = ownerUserID
    this.isFollowButtonHidden = ownerUserID.length === 0 || ownerUserID === selfID
    if (!this.isFollowButtonHidden) {
      this.checkFollowType([ownerUserID], true)
    }
  }

  private ownerName(): string {
    const name = this.liveInfo.liveOwner.userName.length === 0 ? this.liveInfo.liveOwner.userID : this.liveInfo.liveOwner.userName
    const characters = Array.from(name)
    return characters.length > 7 ? characters.slice(0, 7).join('') + '…' : name
  }

  private isFollowing(): boolean {
    return this.hostUserID.length > 0 && this.followingHostUserIDs.includes(this.hostUserID)
  }

  private handleFollowTap(): void {
    if (this.hostUserID.length === 0) {
      return
    }
    const now = Date.now() / 1000
    if (now - this.lastFollowTapTime < 1) {
      return
    }
    this.lastFollowTapTime = now
    const userID = this.hostUserID
    const isFollowing = this.followingHostUserIDs.includes(userID)
    this.updateFollowingSet(userID, !isFollowing)
    const manager = V2TIMManager.getFriendshipManager()
    const request = isFollowing ? manager.unfollowUser([userID]) : manager.followUser([userID])
    request.catch((error: Error) => {
      if (this.hostUserID === userID) {
        this.reportError(error.message)
      }
    })
  }

  private checkFollowType(userIDs: string[], requireCurrentHost: boolean = false): void {
    if (userIDs.length === 0) {
      return
    }
    const hostUserID = this.hostUserID
    V2TIMManager.getFriendshipManager().checkFollowType(userIDs).then((results: V2TIMFollowTypeCheckResult[]) => {
      if (requireCurrentHost && this.hostUserID !== hostUserID) {
        return
      }
      results.forEach((result: V2TIMFollowTypeCheckResult) => this.updateFollowingSet(result.userID, isFollowed(result.followType)))
    }).catch((error: Error) => {
      if (!requireCurrentHost || this.hostUserID === hostUserID) {
        this.reportError(error.message)
      }
    })
  }

  private handleFollowingListChanged(userIDs: string[]): void {
    this.checkFollowType(userIDs)
  }

  private reportError(message: string | undefined): void {
    this.onError?.(message !== undefined && message.length > 0 ? message :
      LiveKitResources.localizedString('tuilivekit.player.operation_failed'))
  }

  private updateFollowingSet(userID: string | undefined, followed: boolean): void {
    if (userID === undefined || userID.length === 0) {
      return
    }
    const contains = this.followingHostUserIDs.includes(userID)
    if (followed && !contains) {
      this.followingHostUserIDs = this.followingHostUserIDs.concat([userID])
    } else if (!followed && contains) {
      this.followingHostUserIDs = this.followingHostUserIDs.filter((id: string) => id !== userID)
    }
  }

  build() {
    Row({ space: 2 }) {
      Image(this.liveInfo.liveOwner.avatarURL)
        .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
        .width(32)
        .height(32)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
        .backgroundColor(rgba(0.141, 0.188, 0.278))
      Column() {
        Text(this.ownerName())
          .fontSize(12)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 80 })
          .layoutWeight(1)
        Text(LiveKitResources.localizedFormat('tuilivekit.player.like_count', this.likeCount))
          .fontSize(10)
          .fontColor(white(0.6))
          .maxLines(1)
          .layoutWeight(1)
      }
      .height(32)
      .alignItems(HorizontalAlign.Start)
      .flexShrink(1)
      if (!this.isFollowButtonHidden) {
        Text(LiveKitResources.localizedString(this.isFollowing() ? 'tuilivekit.player.unfollow' : 'tuilivekit.player.follow'))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .height(28)
          .constraintSize({ minWidth: 44 })
          .padding({ left: 9, right: 9 })
          .borderRadius(13.5)
          .backgroundColor(this.isFollowing() ? rgba(0.996, 0.157, 0.463, 0.25) : rgba(0.996, 0.157, 0.463))
          .borderWidth(this.isFollowing() ? 1 : 0)
          .borderColor(this.isFollowing() ? rgba(0.996, 0.157, 0.463, 0.38) : 'rgba(0,0,0,0)')
          .flexShrink(0)
          .onClick(() => this.handleFollowTap())
      }
    }
    .height(36)
    .padding({ left: 2, right: 2 })
    .borderRadius(18)
    .borderWidth(1)
    .borderColor(white(0.06))
    .clip(true)
    .linearGradient({
      angle: 90,
      colors: [[rgba(0.039, 0.047, 0.071, 0.22), 0], [rgba(0.055, 0.063, 0.11, 0.20), 0.52],
        [rgba(0.482, 0.302, 1, 0.18), 0.82], [rgba(1, 0.357, 0.478, 0.16), 1]],
    })
  }
}
