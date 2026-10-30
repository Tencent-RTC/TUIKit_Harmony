import { CoGuestStore, LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveKitErrorText } from '../../../common/LiveKitErrorText'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { LiveKitLog } from '../../../common/log/LiveKitLog'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { rgba, white } from '../../../common/theme/LiveTheme'
import { LiveToast } from '../../../common/theme/LiveToastView'
import { CoGuestIconController, CoGuestStatus } from './CoGuestIcon'

const applyErrorMessageKeys: Map<number, string> = new Map([
  [100004, 'tuilivekit.player.coguest.error.room_not_exist'],
  [100005, 'tuilivekit.player.coguest.error.not_room_member'],
  [100200, 'tuilivekit.player.coguest.error.seat_locked'],
  [100202, 'tuilivekit.player.coguest.error.already_requesting'],
  [100203, 'tuilivekit.player.coguest.error.already_on_seat'],
  [100205, 'tuilivekit.player.coguest.error.seat_full'],
  [100210, 'tuilivekit.player.coguest.error.seat_occupied'],
  [100211, 'tuilivekit.player.coguest.error.not_supported'],
])

export function applyForSeat(controller: CoGuestIconController, requestVideo: boolean): void {
  const liveID = controller.liveInfo?.liveID ?? ''
  if (controller.uiState !== CoGuestStatus.idle || liveID.length === 0) {
    return
  }
  controller.openCameraAfterAccept = requestVideo
  const extraInfo = requestVideo ? '{"mediaType":"video"}' : '{"mediaType":"audio"}'
  CoGuestStore.create(liveID).applyForSeat(-1, 0, extraInfo).catch((error: Error) => {
    controller.openCameraAfterAccept = true
    const code = LiveKitErrorText.code(error)
    LiveKitLog.error(`[PlayerCoGuest] applyForSeat failed: code=${code}, message=${error.message}`)
    LiveToast.show(LiveKitResources.localizedString(applyErrorMessageKeys.get(code) ??
      'tuilivekit.player.coguest.error.apply_failed'))
    controller.updateUiState(CoGuestStatus.idle)
  })
  controller.updateUiState(CoGuestStatus.requesting)
}

@Component
export struct RequestingPanel {
  @ObjectLink controller: CoGuestIconController
  @Prop liveInfo: LiveInfo
  onDismiss?: () => void
  onRequestSettings?: () => void

  private ownerName(): string {
    const owner = this.liveInfo.liveOwner
    const name = owner.userName.length === 0 ? owner.userID : owner.userName
    const characters = Array.from(name)
    return characters.length > 15 ? characters.slice(0, 15).join('') + '…' : name
  }

  private cancelApplication(): void {
    const liveID = this.liveInfo.liveID
    if (this.controller.uiState !== CoGuestStatus.requesting || liveID.length === 0) {
      return
    }
    CoGuestStore.create(liveID).cancelApplication().then(() => this.controller.openCameraAfterAccept = true).catch(() => {
    })
    this.controller.updateUiState(CoGuestStatus.idle)
  }

  build() {
    BottomSheetView({
      isPresented: this.controller.isApplyPanelPresented,
      sheetHeight: 221,
      onDismiss: () => this.onDismiss?.(),
    }) {
      Column() {
        Image(this.liveInfo.liveOwner.avatarURL)
          .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
          .width(58)
          .height(58)
          .borderRadius(29)
          .borderWidth(1)
          .borderColor(rgba(0.29, 0.62, 1, 0.82))
          .objectFit(ImageFit.Cover)
          .margin({ top: 32 })
        Text(this.ownerName())
          .fontSize(16)
          .fontWeight(600)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(22)
          .margin({ top: 10 })
        if (this.controller.uiState === CoGuestStatus.requesting) {
          Text(LiveKitResources.localizedString('tuilivekit.player.coguest.cancel_application'))
            .fontSize(13)
            .fontWeight(600)
            .fontColor(white(0.72))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(40)
            .borderRadius(11)
            .borderWidth(1)
            .borderColor(white(0.10))
            .backgroundColor(white(0.07))
            .margin({ top: 19 })
            .onClick(() => this.cancelApplication())
        } else {
          Row() {
            Text(LiveKitResources.localizedString('tuilivekit.player.coguest.voice'))
              .fontSize(13)
              .fontWeight(600)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height('100%')
              .padding({ right: 20 })
              .onClick(() => applyForSeat(this.controller, false))
            Text(LiveKitResources.localizedString('tuilivekit.player.coguest.video'))
              .fontSize(13)
              .fontWeight(600)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height('100%')
              .padding({ left: 20 })
              .onClick(() => {
                if (this.controller.uiState === CoGuestStatus.idle) {
                  this.onRequestSettings?.()
                }
              })
          }
          .width('100%')
          .height(40)
          .margin({ top: 19 })
          .backgroundImage(LiveKitResources.image('livekit_player_coguest_requesting_button_bg'))
          .backgroundImageSize(ImageSize.FILL)
        }
      }
      .padding({ left: 20, right: 20 })
    }
  }
}
