import { DeviceStatus } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../../../common/LiveKitResources'
import { BottomSheetView } from '../../../../common/theme/BottomSheetView'
import { LiveText } from '../../../../common/theme/LiveText'
import { LiveTheme, rgba, white } from '../../../../common/theme/LiveTheme'
import { PusherCoGuestActionHandling, State as CoGuestState, User } from '../PusherCoGuestStore'

const additionalBottomSpacing: number = 12
const contentHeight: number = 136 + additionalBottomSpacing
const minimumPanelHeight: number = 150 + additionalBottomSpacing

@Component
export struct PusherCoGuestAudienceManageView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop @Watch('bind') state: CoGuestState = new CoGuestState()
  @Prop @Watch('bind') selectedUserID: string = ''
  actionHandler?: PusherCoGuestActionHandling
  onDismiss?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  private isAwaitingActionCompletion: boolean = false
  private didObservePendingAction: boolean = false

  private user(): User | undefined {
    return this.state.connected.find((user: User) => user.userID === this.selectedUserID)
  }

  private isPending(): boolean {
    return this.state.pendingUserIDs.includes(this.selectedUserID)
  }

  private onPresentedChanged(): void {
    this.isAwaitingActionCompletion = false
    this.didObservePendingAction = false
  }

  private bind(): void {
    if (!this.isPresented || this.selectedUserID.length === 0) {
      return
    }
    if (this.user() === undefined) {
      this.onDismiss?.()
      return
    }
    if (this.isAwaitingActionCompletion) {
      this.didObservePendingAction = this.didObservePendingAction || this.isPending()
      if (this.didObservePendingAction && !this.isPending()) {
        this.onDismiss?.()
      }
    }
  }

  private perform(action: (handler: PusherCoGuestActionHandling, userID: string) => void): void {
    if (this.actionHandler === undefined || this.selectedUserID.length === 0) {
      return
    }
    this.isAwaitingActionCompletion = true
    this.didObservePendingAction = false
    action(this.actionHandler, this.selectedUserID)

  }

  @Builder
  itemControl(titleKey: string, assetName: string, titleColor: string, action: () => void) {
    Column({ space: 7 }) {
      Image(LiveKitResources.image(assetName)).width(44).height(44).objectFit(ImageFit.Contain)
      Text(LiveKitResources.localizedString(titleKey))
        .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.primary, TextAlign.Center))
        .fontColor(titleColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .height(16)
    }
    .width(80)
    .height(72)
    .enabled(!this.isPending())
    .opacity(this.isPending() ? 0.46 : 1)
    .onClick(action)
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: Math.max(minimumPanelHeight, contentHeight + this.safeBottom),
      onDismiss: () => this.onDismiss?.(),
      sheetWillDismiss: () => this.onPresentedChanged(),
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text(LiveKitResources.localizedFormat('tuilivekit.pusher.coguest.manage_user', this.user()?.userName ?? ''))
          .attributeModifier(new LiveText(LiveTheme.TextRole.dialogTitle, LiveTheme.TextTone.primary, TextAlign.Center))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .height(22)
          .padding({ left: 20, right: 20 })
          .position({ x: 0, y: 27 })
        Row() {
          if (this.user()?.allowOpenMicrophone === true && this.user()?.microphoneStatus === DeviceStatus.on) {
            this.itemControl('tuilivekit.pusher.coguest.mute_user', 'livekit_coguest_action_mic', white(0.75),
              () => this.perform(
                (handler: PusherCoGuestActionHandling, userID: string) => handler.toggleRemoteMicrophone(userID)))
          } else {
            this.itemControl('tuilivekit.pusher.coguest.unmute_user', 'livekit_coguest_action_mic_off', white(0.75),
              () => this.perform(
                (handler: PusherCoGuestActionHandling, userID: string) => handler.toggleRemoteMicrophone(userID)))
          }
          this.itemControl('tuilivekit.pusher.coguest.disconnect_user', 'livekit_coguest_action_disconnect',
            rgba(1, 0.565, 0.584),
            () => this.perform((handler: PusherCoGuestActionHandling, userID: string) => handler.disconnect(userID)))
        }
        .width(200)
        .height(72)
        .justifyContent(FlexAlign.SpaceBetween)
        .position({ left: '50%', top: 70 })
        .translate({ x: -100 })
      }
      .width('100%')
      .height('100%')
    }
  }
}
