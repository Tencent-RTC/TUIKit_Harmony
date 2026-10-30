import { LiveKitResources } from '../../common/LiveKitResources'
import { PusherAudioEffectSheet } from '../settings/AudioEffectView'
import { PusherSettingsActionHandling, PusherSettingsState } from '../settings/PusherSettingsActionHandling'
import { PusherSettingsItemView } from '../settings/PusherSettingsItemView'

@Component
export struct PrepareMoreSettingsView {
  @Prop isPresented: boolean = false
  @Prop settings: PusherSettingsState = new PusherSettingsState()
  actionHandler?: PusherSettingsActionHandling
  onDismiss?: () => void
  @State private showsAudio: boolean = false

  build() {
    PusherAudioEffectSheet({
      isPresented: this.isPresented,
      showsAudio: this.showsAudio,
      mainSheetHeight: 191,
      mainSheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.settings.more'),
      captureVolume: this.settings.captureVolume,
      onDismiss: () => this.onDismiss?.(),
      onSetCaptureVolume: (volume: number) => this.actionHandler?.setCaptureVolume(volume),
      sheetDidDismiss: () => this.showsAudio = false,
    }) {
      Row() {
        PusherSettingsItemView({
          title: LiveKitResources.localizedString('tuilivekit.pusher.mirror'),
          assetName: this.settings.isMirrorEnabled ? 'livekit_settings_mirror_on' : 'livekit_settings_mirror_off',
          onTap: () => this.actionHandler?.toggleMirror(),
        })
          .layoutWeight(1)
        PusherSettingsItemView({
          title: LiveKitResources.localizedString('tuilivekit.pusher.audio_effects'),
          assetName: 'livekit_settings_audio_effect',
          onTap: () => this.showsAudio = true,
        })
          .layoutWeight(1)
      }
      .height(84)
      .padding({ left: 16, right: 16 })
      .margin({ top: 75 })
    }
  }
}
