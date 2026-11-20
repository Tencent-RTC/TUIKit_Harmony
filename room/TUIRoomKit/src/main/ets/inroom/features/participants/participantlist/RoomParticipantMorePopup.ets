import { DeviceType, ParticipantRole, RoomInfo, RoomParticipantStore } from '@tencentcloud/atomicxcore'
import { RoomPopup, RoomPopupContentHeight } from '../../../../base/popup/RoomPopup'
import { RoomToast } from '../../../../base/toast/RoomToast'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { RoomResources } from '../../../../base/util/RoomResources'

@Component
export struct RoomParticipantMorePopup {
  @Prop roomID: string = ''
  @Prop room?: RoomInfo
  @Prop @Watch('validateRole') localRole?: ParticipantRole
  @Prop isPresented: boolean = false
  onDismiss?: () => void

  private isManager(): boolean {
    return this.localRole === ParticipantRole.owner || this.localRole === ParticipantRole.admin
  }

  private validateRole(): void {
    if (!this.isManager()) {
      this.onDismiss?.()
    }
  }

  private async toggleScreenShare(): Promise<void> {
    if (this.room === undefined || this.room.roomID !== this.roomID || !this.isManager()) {
      this.onDismiss?.()
      return
    }
    const disable = !this.room.isAllScreenShareDisabled
    this.onDismiss?.()
    try {
      await RoomParticipantStore.create(this.roomID).disableAllDevices(DeviceType.screenShare, disable)
      RoomToast.show(RoomResources.string(disable ? 'roomkit_participants_share_owner_only_done' :
        'roomkit_participants_share_everyone_done'))
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  build() {
    RoomPopup({
      isPresented: this.isPresented,
      contentHeight: RoomPopupContentHeight.AUTO,
      onDismiss: () => this.onDismiss?.(),
    }) {
      Column() {
        Text(RoomResources.string(this.room?.isAllScreenShareDisabled ?
          'roomkit_participants_share_everyone' : 'roomkit_participants_share_owner_only'))
          .width('100%')
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .padding({ left: 12, right: 12 })
          .onClick(() => this.toggleScreenShare())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 24 })
    }
  }
}
