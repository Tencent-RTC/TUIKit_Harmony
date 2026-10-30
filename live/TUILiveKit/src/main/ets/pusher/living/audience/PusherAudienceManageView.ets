import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { PusherSettingsItemView } from '../../settings/PusherSettingsItemView'
import { Action, FollowStatus, State as AudienceState, User } from './PusherAudienceStore'

const contentHeight: number = 191

@Component
export struct PusherAudienceManageView {
  @Prop @Watch('bind') isPresented: boolean = false
  @Prop @Watch('bind') state: AudienceState = new AudienceState()
  @Prop @Watch('bind') selectedUserID: string = ''
  @Prop @Watch('completeAction') completedAction: string = ''
  onDismiss?: () => void
  onToggleFollow?: (userID: string) => void
  onToggleMessagePermission?: (userID: string) => void
  onRemoveFromRoom?: (userID: string) => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0

  private user(): User | undefined {
    return this.state.users.find((user: User) => user.userID === this.selectedUserID)
  }

  private bind(): void {
    if (this.isPresented && this.selectedUserID.length > 0 && this.user() === undefined) {
      this.onDismiss?.()
    }
  }

  private completeAction(): void {
    const parts = this.completedAction.split('|')
    if (parts.length < 3 || parts[0] !== this.selectedUserID || parts[2] !== '1') {
      return
    }
    const action = Number(parts[1]) as Action
    if (action === Action.mute || action === Action.unmute || action === Action.remove) {
      this.onDismiss?.()
    }
  }

  private perform(action?: (userID: string) => void): void {
    if (this.selectedUserID.length > 0) {
      action?.(this.selectedUserID)
    }
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: contentHeight + this.safeBottom,
      sheetTitle: this.user()?.userName || this.user()?.userID || '',
      onDismiss: () => this.onDismiss?.(),
    }) {
      Row() {
        PusherSettingsItemView({
          title: LiveKitResources.localizedString(
            this.state.followStatus(this.selectedUserID) === FollowStatus.following ?
              'tuilivekit.pusher.audience.following' : 'tuilivekit.pusher.audience.follow'),
          assetName: this.state.followStatus(this.selectedUserID) === FollowStatus.following ?
            'livekit_pusher_audience_followed' : 'livekit_pusher_audience_follow',
          onTap: () => this.perform(this.onToggleFollow),
        })
          .layoutWeight(1)
          .enabled(!this.state.pendingActionByUserID.has(this.selectedUserID) &&
            this.state.followStatus(this.selectedUserID) !== FollowStatus.unknown)
          .opacity(
            [Action.follow, Action.unfollow].includes(this.state.pendingActionByUserID.get(this.selectedUserID) ?? -1) ?
              0.46 : 1)
        PusherSettingsItemView({
          title: LiveKitResources.localizedString(this.state.mutedUserIDs.includes(this.selectedUserID) ?
            'tuilivekit.pusher.audience.unmute' : 'tuilivekit.pusher.audience.mute'),
          assetName: 'livekit_pusher_audience_mute',
          onTap: () => this.perform(this.onToggleMessagePermission),
        })
          .layoutWeight(1)
          .enabled(!this.state.pendingActionByUserID.has(this.selectedUserID))
          .opacity(
            [Action.mute, Action.unmute].includes(this.state.pendingActionByUserID.get(this.selectedUserID) ?? -1) ?
              0.46 : 1)
        PusherSettingsItemView({
          title: LiveKitResources.localizedString('tuilivekit.pusher.audience.remove'),
          assetName: 'livekit_pusher_audience_remove',
          iconWidth: 21,
          iconHeight: 21,
          onTap: () => this.perform(this.onRemoveFromRoom),
        })
          .layoutWeight(1)
          .enabled(!this.state.pendingActionByUserID.has(this.selectedUserID))
          .opacity(this.state.pendingActionByUserID.get(this.selectedUserID) === Action.remove ? 0.46 : 1)
      }
      .width('100%')
      .height(84)
      .padding({ left: 16, right: 16 })
      .margin({ top: 75 })
    }
  }
}
