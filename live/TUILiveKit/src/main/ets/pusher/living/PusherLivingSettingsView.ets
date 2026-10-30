import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { LiveTheme } from '../../common/theme/LiveTheme'
import { PusherAudioEffectSheet } from '../settings/AudioEffectView'
import { PusherSettingsActionHandling, PusherSettingsState } from '../settings/PusherSettingsActionHandling'
import { PusherSettingsItemView } from '../settings/PusherSettingsItemView'

class SettingItem {
  titleKey: string
  assetName: string
  iconWidth: number
  iconHeight: number
  action: () => void

  constructor(titleKey: string, assetName: string, iconWidth: number, iconHeight: number, action: () => void) {
    this.titleKey = titleKey
    this.assetName = assetName
    this.iconWidth = iconWidth
    this.iconHeight = iconHeight
    this.action = action
  }
}

@Component
export struct PusherLivingSettingsView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop settings: PusherSettingsState = new PusherSettingsState()
  settingsActionHandler?: PusherSettingsActionHandling
  onDismiss?: () => void
  onToggleMute?: () => void
  onPause?: () => void
  onShowBeauty?: () => void
  onShowComment?: () => void
  onShowBackgroundMusic?: () => void
  onFlipCamera?: () => void
  @State private showsAudio: boolean = false
  private pendingDismissAction?: () => void

  aboutToDisappear(): void {
    this.pendingDismissAction = undefined
    this.showsAudio = false
  }

  private onPresentedChanged(): void {
    if (this.isPresented) {
      this.pendingDismissAction = undefined
    }
  }

  private animateDismiss(completion: (() => void) | undefined): void {
    this.pendingDismissAction = completion
    this.onDismiss?.()
  }

  private sheetDidDismiss(): void {
    this.showsAudio = false
    const pending = this.pendingDismissAction
    this.pendingDismissAction = undefined
    pending?.()
  }

  private items(section: number): SettingItem[] {
    if (section === 0) {
      return [
        new SettingItem('tuilivekit.pusher.living.pause', 'livekit_living_setting_pause', 17, 17,
          () => this.animateDismiss(this.onPause)),
        new SettingItem(this.settings.isMuted ? 'tuilivekit.pusher.living.unmute' : 'tuilivekit.pusher.living.mute',
          this.settings.isMuted ? 'livekit_living_setting_mic_off' : 'livekit_living_setting_mic_on', 44, 44,
          () => this.onToggleMute?.()),
      ]
    }
    if (section === 1) {
      return [
        new SettingItem('tuilivekit.pusher.beautify', 'livekit_living_setting_beauty', 18.05, 16.3,
          () => this.animateDismiss(this.onShowBeauty)),
        new SettingItem('tuilivekit.pusher.mirror', this.settings.isMirrorEnabled ? 'livekit_settings_mirror_on' :
          'livekit_settings_mirror_off', 21, 22, () => this.settingsActionHandler?.toggleMirror()),
        new SettingItem('tuilivekit.pusher.flip_camera', 'livekit_living_setting_flip', 21, 18.5,
          () => this.onFlipCamera?.()),
        new SettingItem('tuilivekit.pusher.audio_effects', 'livekit_living_setting_audio', 18.1, 18.6,
          () => this.showsAudio = true),
      ]
    }
    return [
      new SettingItem('tuilivekit.pusher.living.music', 'livekit_living_setting_music', 14.93, 17.63,
        () => this.animateDismiss(this.onShowBackgroundMusic)),
      new SettingItem('tuilivekit.pusher.living.comment', 'livekit_living_setting_comment', 19, 16,
        () => this.animateDismiss(this.onShowComment)),
    ]
  }

  @Builder
  itemRow(section: number, top: number) {
    Row() {
      ForEach(this.items(section), (item: SettingItem) => {
        PusherSettingsItemView({
          title: LiveKitResources.localizedString(item.titleKey),
          assetName: item.assetName,
          iconWidth: item.iconWidth,
          iconHeight: item.iconHeight,
          showsIconBackground: item.iconWidth !== 44,
          onTap: item.action,
        })
          .layoutWeight(1)
      }, (item: SettingItem) => item.titleKey + item.assetName)
      ForEach(Array.from<number>({ length: 5 - this.items(section).length }), () => {
        Blank().layoutWeight(1)
      })
    }
    .width('100%')
    .height(84)
    .padding({ left: 16, right: 16 })
    .position({ x: 0, y: top })
  }

  @Builder
  sectionTitle(titleKey: string, top: number) {
    Text(LiveKitResources.localizedString(titleKey))
      .attributeModifier(new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.tertiary))
      .height(15)
      .position({ x: 20, y: top })
  }

  build() {
    PusherAudioEffectSheet({
      isPresented: this.isPresented,
      showsAudio: this.showsAudio,
      mainSheetHeight: 385,
      captureVolume: this.settings.captureVolume,
      onDismiss: () => this.onDismiss?.(),
      onSetCaptureVolume: (volume: number) => this.settingsActionHandler?.setCaptureVolume(volume),
      sheetDidDismiss: () => this.sheetDidDismiss(),
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
        this.itemRow(0, 30)
        this.sectionTitle('tuilivekit.pusher.living.basic_settings', 121)
        this.itemRow(1, 148)
        this.sectionTitle('tuilivekit.pusher.living.interaction', 239)
        this.itemRow(2, 266)
      }
      .width('100%')
      .height(385)
    }
  }
}
