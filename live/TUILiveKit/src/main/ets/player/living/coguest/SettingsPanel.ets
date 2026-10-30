import { DeviceState, DeviceStore, MirrorType } from '@tencentcloud/atomicxcore'
import { getTRTCShareInstance } from '@tencentcloud/liteavsdk_professional'
import { BeautyPanel, BeautyPreferences } from '../../../common/beauty/BeautyPanel'
import { DebouncedClick } from '../../../common/DebouncedClick'
import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { rgba, white } from '../../../common/theme/LiveTheme'

export enum Mode {
  preview,
  connected,
}

const previewID: string = 'tuilivekit_coguest_settings_preview'

@Component
export struct SettingsPanel {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop mode: Mode = Mode.preview
  onDismiss?: () => void
  onDidDismiss?: () => void
  onApply?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private deviceState: DeviceState = DeviceStore.shared().state as DeviceState
  @State private panelWidth: number = 0
  @State private isBeautyPresented: boolean = false
  @State private isCameraTestActive: boolean = false
  private readonly debouncedClick: DebouncedClick = new DebouncedClick()

  aboutToDisappear(): void {
    this.stopPreview()
  }

  private sheetHeight(): number {
    return (this.mode === Mode.preview ? this.panelWidth + 152 : 190) + this.safeBottom
  }

  private onPresentedChanged(): void {
    if (this.isPresented && this.mode === Mode.preview) {
      this.startPreview()
    }
  }

  private startPreview(): void {
    if (this.mode !== Mode.preview || this.isCameraTestActive) {
      return
    }
    BeautyPreferences.restore()
    DeviceStore.shared().switchCamera(true)
    DeviceStore.shared().switchMirror(MirrorType.enable)
    this.isCameraTestActive = true
  }

  stopPreview(): void {
    if (!this.isCameraTestActive) {
      return
    }
    this.isCameraTestActive = false
    getTRTCShareInstance().stopLocalPreview()
  }

  @Builder
  settingCap(iconName: string, iconWidth: number, iconHeight: number, title: string, action: () => void) {
    Column({ space: 8 }) {
      Stack() {
        Image(LiveKitResources.image(iconName)).width(iconWidth).height(iconHeight).objectFit(ImageFit.Contain)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(white(0.09))
      Text(title).fontSize(12).fontColor(Color.White).textAlign(TextAlign.Center)
    }
    .width(60)
    .height(76)
    .onClick(() => this.debouncedClick.perform(title, action))
  }

  build() {
    Stack() {
      BottomSheetView({
        isPresented: this.isPresented,
        sheetHeight: this.sheetHeight(),
        onDismiss: () => this.onDismiss?.(),
        sheetWillDismiss: () => this.stopPreview(),
        sheetDidDismiss: () => this.onDidDismiss?.(),
      }) {
        Column() {
          Row() {
            Image(LiveKitResources.image('livekit_coguest_chevron_down'))
              .width(36)
              .height(36)
              .objectFit(ImageFit.Contain)
              .rotate({ angle: 90 })
              .borderRadius(18)
              .backgroundColor(white(0.09))
              .onClick(() => this.debouncedClick.perform('back', () => this.onDismiss?.()))
          }
          .width('100%')
          .padding({ left: 16 })
          .margin({ top: 20 })
          .height(36)
          Text(LiveKitResources.localizedString('tuilivekit.player.coguest.settings.title'))
            .fontSize(16)
            .fontWeight(600)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .margin({ top: -32 })
          Text(LiveKitResources.localizedString('tuilivekit.player.coguest.settings.subtitle'))
            .fontSize(12)
            .fontColor(white(0.60))
            .textAlign(TextAlign.Center)
            .margin({ top: 4 })
          if (this.mode === Mode.preview) {
            Stack() {
              if (this.isCameraTestActive) {
                XComponent({ id: previewID, type: XComponentType.SURFACE, libraryname: 'liteavsdk' })
                  .onLoad(() => getTRTCShareInstance().startLocalPreview(true, previewID))
                  .width('100%')
                  .height('100%')
              }
            }
            .width(this.panelWidth - 128)
            .height(this.panelWidth - 128)
            .borderRadius(20)
            .clip(true)
            .backgroundColor(rgba(0.055, 0.098, 0.196))
            .margin({ top: 20 })
          }
          Row() {
            this.settingCap('livekit_living_setting_beauty', 18.05, 16.3,
              LiveKitResources.localizedString('tuilivekit.pusher.beautify'), () => this.isBeautyPresented = true)
            this.settingCap(this.deviceState.localMirrorType !== MirrorType.disable ? 'livekit_settings_mirror_on' :
              'livekit_settings_mirror_off', 21, 22, LiveKitResources.localizedString('tuilivekit.pusher.mirror'),
              () => DeviceStore.shared().switchMirror(this.deviceState.localMirrorType !== MirrorType.disable ?
                MirrorType.disable : MirrorType.enable))
            this.settingCap('livekit_living_setting_flip', 21, 18.5, LiveKitResources.localizedString('tuilivekit.pusher.flip_camera'),
              () => DeviceStore.shared().switchCamera(!this.deviceState.isFrontCamera))
          }
          .width('100%')
          .height(76)
          .padding({ left: 56, right: 56 })
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 20 })
          if (this.mode === Mode.preview) {
            Text(LiveKitResources.localizedString('tuilivekit.player.coguest.apply'))
              .fontSize(15)
              .fontWeight(600)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(44)
              .borderRadius(22)
              .backgroundColor('rgba(59, 123, 255, 1)')
              .margin({ top: 24 })
              .onClick(() => this.debouncedClick.perform('apply', () => this.onApply?.()))
          }
        }
        .width('100%')
      }
      BeautyPanel({ isPresented: this.isBeautyPresented, onDismiss: () => this.isBeautyPresented = false })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .onAreaChange((_: Area, area: Area) => this.panelWidth = area.width as number)
  }
}
