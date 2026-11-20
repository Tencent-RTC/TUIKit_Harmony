import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { CoHostState } from './PusherCoHostStore'

@Component
export struct PusherCoHostIncomingInviteView {
  @Prop @Watch('updateTimer') isPresented: boolean = false
  @Prop @Watch('updateCountdown') state: CoHostState = new CoHostState()
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  onAccept?: () => void
  onReject?: () => void
  onDidDismiss?: () => void
  @State private containerHeight: number = 0
  @State private remaining: number = 0
  private timer: number = -1
  aboutToAppear(): void { this.updateTimer() }
  aboutToDisappear(): void { clearInterval(this.timer) }
  private updateCountdown(): void {
    this.remaining = Math.max(0, Math.ceil((this.state.applicantDeadline - Date.now()) / 1000))
  }
  private updateTimer(): void {
    clearInterval(this.timer)
    this.timer = -1
    this.updateCountdown()
    if (this.isPresented) this.timer = setInterval(() => this.updateCountdown(), 1000)
  }
  private busy(): boolean { return !this.state.applicant || this.state.isBusy(this.state.applicant.liveID) }
  build() {
    Stack() {
      BottomSheetView({
        isPresented: this.isPresented,
        sheetHeight: Math.min(286 + this.safeBottom,
          this.containerHeight > 0 ? Math.max(0, this.containerHeight - 40) : 286 + this.safeBottom),
        isDismissibleByTappingOutside: false, sheetDidDismiss: this.onDidDismiss
      }) {
        Scroll() {
          Column() {
            Text(LiveKitResources.localizedString(this.state.applicant?.followType === 3 ?
              'tuilivekit.pusher.cohost.incoming_mutual' : 'tuilivekit.pusher.cohost.incoming'))
              .fontSize(15).fontWeight(600).fontColor('#D6FFFFFF').height(22)
              .width('calc(100% - 44vp)').maxLines(1).minFontSize(12.75).maxFontSize(15).margin({ top: 35 })
            Stack({ alignContent: Alignment.TopStart }) {
              Image(this.state.applicant?.avatarURL || LiveKitResources.image('livekit_livelist_default_avatar'))
                .alt(LiveKitResources.image('livekit_livelist_default_avatar')).objectFit(ImageFit.Cover)
                .width(76).height(76).borderRadius(38).border({ width: 3, color: '#72B3FF' }).clip(true)
                .shadow({ radius: 12.5, color: '#3D000000', offsetY: 10 })
              Image(LiveKitResources.image('livekit_cohost_invitation_badge')).width(52).height(57)
                .objectFit(ImageFit.Contain).position({ x: 39, y: 38 }).hitTestBehavior(HitTestMode.None)
            }.width(76).height(76).margin({ top: 31 }).clip(false)
            Text(this.state.applicant?.userName ?? '').fontSize(17).fontWeight(FontWeight.Bold).fontColor(Color.White)
              .width('calc(100% - 40vp)').height(24).maxLines(1).textAlign(TextAlign.Center)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 12 })
            Row({ space: 10 }) {
              Text(this.busy() ? LiveKitResources.localizedString('tuilivekit.common.processing') :
                LiveKitResources.localizedFormat('tuilivekit.pusher.cohost.reject_countdown', this.remaining))
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#BDFFFFFF').layoutWeight(1).height(44)
                .textAlign(TextAlign.Center).borderRadius(13).backgroundColor('#17FFFFFF')
                .onClick(() => this.onReject?.())
              Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.accept'))
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor(Color.White).layoutWeight(1).height(44)
                .textAlign(TextAlign.Center).borderRadius(13)
                .linearGradient({ direction: GradientDirection.RightBottom, colors: [['#43D5FF', 0], ['#5379FF', 1]] })
                .shadow({ radius: 11, color: '#474598FF', offsetY: 8 }).onClick(() => this.onAccept?.())
            }.width('calc(100% - 40vp)').height(44).margin({ top: 42 })
              .enabled(!this.busy() && this.remaining > 0).opacity(!this.busy() && this.remaining > 0 ? 1 : 0.46)
          }.width('100%').padding({ bottom: this.safeBottom })
        }.width('100%').height('100%').scrollBar(BarState.Off)
      }
    }.width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .onAreaChange((_: Area, area: Area) => this.containerHeight = Number(area.height))
  }
}
