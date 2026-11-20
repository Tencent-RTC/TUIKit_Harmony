import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { CoHostState } from './PusherCoHostStore'

@Component
export struct PusherCoHostActionsView {
  @Prop isPresented: boolean = false
  @Prop state: CoHostState = new CoHostState()
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  onDismiss?: () => void
  onDidDismiss?: () => void
  onInviteMore?: () => void
  onEnd?: () => void
  private title(): string {
    return this.state.connected.length === 1 ?
      LiveKitResources.localizedFormat('tuilivekit.pusher.cohost.connected_with', this.state.connected[0].userName) :
      LiveKitResources.localizedFormat('tuilivekit.pusher.cohost.connected_count', this.state.connected.length + 1)
  }
  build() {
    BottomSheetView({
      isPresented: this.isPresented, sheetHeight: 148 + this.safeBottom,
      onDismiss: this.onDismiss, sheetDidDismiss: this.onDidDismiss
    }) {
      Column() {
        Row({ space: 12 }) {
          Text(this.title()).fontSize(15).fontWeight(600).fontColor(Color.White)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          Text(LiveKitResources.localizedString(this.state.isExiting ? 'tuilivekit.common.processing' :
            'tuilivekit.pusher.cohost.end')).fontSize(14).fontWeight(600).fontColor('#9ECFFF')
            .constraintSize({ minWidth: 64 }).height(44).textAlign(TextAlign.End)
            .enabled(this.state.isConnected && !this.state.isExiting && this.state.pendingLiveIDs.length === 0)
            .opacity(!this.state.isExiting && this.state.pendingLiveIDs.length === 0 ? 1 : 0.46)
            .onClick(() => this.onEnd?.())
        }.width('100%').height(44).margin({ top: 28 })
        Row({ space: 4 }) {
          Image(LiveKitResources.image('livekit_cohost_add')).width(14).height(17).objectFit(ImageFit.Contain)
          Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.invite_more'))
            .fontSize(14).fontWeight(600).fontColor(Color.White).maxLines(1)
        }.width('100%').height(41).justifyContent(FlexAlign.Center).margin({ top: 11 })
          .linearGradient({ direction: GradientDirection.RightTop, colors: [['#1F7AFF', 0], ['#0052D9', 1]] })
          .borderRadius(12).border({ width: 1, color: '#6462ABFF' })
          .shadow({ radius: 10, color: '#2E0052D9', offsetY: 8 })
          .enabled(this.state.isConnected && !this.state.isExiting).opacity(this.state.isExiting ? 0.46 : 1)
          .onClick(() => this.onInviteMore?.())
      }.width('100%').padding({ left: 16, right: 16 })
    }
  }
}
