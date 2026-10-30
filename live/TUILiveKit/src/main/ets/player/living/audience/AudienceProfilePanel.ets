import { V2TIMFollowTypeCheckResult, V2TIMManager } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { rgba, white } from '../../../common/theme/LiveTheme'
import { isFollowed } from '../hostinfo/HostInfoView'

@Component
export struct AudienceProfilePanel {
  @Prop isPresented: boolean = false
  userID: string = ''
  userName: string = ''
  avatarURL: string = ''
  onDismiss?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private isFollowing: boolean = false
  @State private isBusy: boolean = false
  private lastFollowTapTime: number = 0

  aboutToAppear(): void {
    V2TIMManager.getFriendshipManager().checkFollowType([this.userID]).then((results: V2TIMFollowTypeCheckResult[]) => {
      if (results.length > 0) {
        this.isFollowing = isFollowed(results[0].followType)
      }
    }).catch(() => {
    })
  }

  private displayName(): string {
    const name = this.userName.length === 0 ? this.userID : this.userName
    const characters = Array.from(name)
    return characters.length > 15 ? characters.slice(0, 15).join('') + '…' : name
  }

  private toggleFollow(): void {
    const now = Date.now() / 1000
    if (now - this.lastFollowTapTime < 1) {
      return
    }
    this.lastFollowTapTime = now
    this.isBusy = true
    const manager = V2TIMManager.getFriendshipManager()
    const following = this.isFollowing
    const request = following ? manager.unfollowUser([this.userID]) : manager.followUser([this.userID])
    request.then(() => this.isFollowing = !following).catch(() => {
    }).finally(() => this.isBusy = false)
  }

  build() {
    BottomSheetView({ isPresented: this.isPresented, sheetHeight: 212 + this.safeBottom, onDismiss: () => this.onDismiss?.() }) {
      Column() {
        Stack() {
          Image(this.avatarURL.length > 0 ? this.avatarURL : LiveKitResources.image('livekit_livelist_default_avatar'))
            .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
            .width(54)
            .height(54)
            .borderRadius(27)
            .objectFit(ImageFit.Cover)
        }
        .width(58)
        .height(58)
        .borderRadius(29)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [[rgba(0, 0.322, 0.851), 0], [rgba(0.29, 0.62, 1), 0.5], [rgba(0.494, 0.91, 1), 1]],
        })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.3)', offsetY: 8 })
        Text(this.displayName())
          .fontSize(16)
          .fontWeight(600)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 10 })
        Text(LiveKitResources.localizedString(this.isFollowing ? 'tuilivekit.player.unfollow' : 'tuilivekit.player.follow'))
          .fontSize(13)
          .fontWeight(600)
          .fontColor(this.isFollowing ? white(0.72) : Color.White)
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(40)
          .margin({ top: 22 })
          .borderRadius(11)
          .borderWidth(1)
          .borderColor(this.isFollowing ? white(0.1) : rgba(0.29, 0.62, 1, 0.35))
          .backgroundColor(this.isFollowing ? white(0.07) : 'rgba(0,0,0,0)')
          .linearGradient(this.isFollowing ? { colors: [] } : {
            direction: GradientDirection.RightBottom,
            colors: [[rgba(0.055, 0.282, 0.725), 0], [rgba(0.224, 0.463, 0.741), 1]],
          })
          .shadow({ radius: 9, color: rgba(0, 0.322, 0.851, this.isFollowing ? 0 : 0.2), offsetY: 7 })
          .enabled(!this.isBusy)
          .onClick(() => this.toggleFollow())
      }
      .padding({ left: 20, right: 20 })
      .margin({ top: 32 })
    }
  }
}
