import { getTRTCShareInstance } from '@tencentcloud/liteavsdk_professional'
import { LiveKitResources } from '../../common/LiveKitResources'
import { BottomSheetView } from '../../common/theme/BottomSheetView'
import { LiveSlider } from '../../common/theme/LiveSlider'
import { LiveText } from '../../common/theme/LiveText'
import { LiveToast } from '../../common/theme/LiveToastView'
import { LiveTheme, rgba } from '../../common/theme/LiveTheme'
import { PusherSettingsItemView, PusherSettingsSelectionStyle, Style } from './PusherSettingsItemView'

class SoundOption {
  value: number
  titleKey: string
  assetName: string

  constructor(value: number, titleKey: string, assetName: string) {
    this.value = value
    this.titleKey = titleKey
    this.assetName = assetName
  }
}

const changerOptions: SoundOption[] = [
  new SoundOption(0, 'tuilivekit.pusher.settings.voice.original', 'livekit_voice_original'),
  new SoundOption(1, 'tuilivekit.pusher.settings.voice.child', 'livekit_voice_child'),
  new SoundOption(2, 'tuilivekit.pusher.settings.voice.loli', 'livekit_voice_loli'),
  new SoundOption(3, 'tuilivekit.pusher.settings.voice.uncle', 'livekit_voice_uncle'),
  new SoundOption(11, 'tuilivekit.pusher.settings.voice.spirit', 'livekit_voice_spirit'),
]
const reverbOptions: SoundOption[] = [
  new SoundOption(0, 'tuilivekit.pusher.settings.reverb.none', 'livekit_reverb_none'),
  new SoundOption(1, 'tuilivekit.pusher.settings.reverb.ktv', 'livekit_reverb_ktv'),
  new SoundOption(6, 'tuilivekit.pusher.settings.reverb.metal', 'livekit_reverb_metal'),
  new SoundOption(4, 'tuilivekit.pusher.settings.reverb.deep', 'livekit_reverb_deep'),
  new SoundOption(5, 'tuilivekit.pusher.settings.reverb.bright', 'livekit_reverb_bright'),
]

@Observed
export class AudioEffectState {
  isEarMonitorOpened: boolean = false
  earMonitorVolume: number = 100
  audioChangerType: number = 0
  audioReverbType: number = 0

  // AtomicXCore 5.2.2 has no audio-effect state/read API. Keep requested values
  // scoped to this pusher session until the SDK exposes an observable store.
  private apply(action: () => void, update: () => void): void {
    try {
      action()
      update()
    } catch (error) {
      LiveToast.show(`${error}`)
    }
  }

  resetForNewSession(): void {
    this.setVoiceEarMonitorEnable(false)
    this.setVoiceEarMonitorVolume(100)
    this.setAudioChangerType(0)
    this.setAudioReverbType(0)
  }

  setVoiceEarMonitorEnable(enable: boolean): void {
    this.apply(() => getTRTCShareInstance().getAudioEffectManager().enableVoiceEarMonitor(enable),
      () => this.isEarMonitorOpened = enable)
  }

  setVoiceEarMonitorVolume(volume: number): void {
    const value = Math.max(0, Math.min(100, Math.round(volume)))
    this.apply(() => getTRTCShareInstance().getAudioEffectManager().setVoiceEarMonitorVolume(value),
      () => this.earMonitorVolume = value)
  }

  setAudioChangerType(type: number): void {
    if (!changerOptions.some((option: SoundOption) => option.value === type)) {
      return
    }
    this.apply(() => getTRTCShareInstance().getAudioEffectManager().setVoiceChangerType(type),
      () => this.audioChangerType = type)
  }

  setAudioReverbType(type: number): void {
    if (!reverbOptions.some((option: SoundOption) => option.value === type)) {
      return
    }
    this.apply(() => getTRTCShareInstance().getAudioEffectManager().setVoiceReverbType(type),
      () => this.audioReverbType = type)
  }
}

@Component
export struct AudioEffectView {
  @Prop captureVolume: number = 100
  @Prop isActive: boolean = false
  onSetCaptureVolume?: (volume: number) => void
  @ObjectLink audioState: AudioEffectState

  @Builder
  settingsVolumeView(title: string, value: number, onChange: (value: number) => void) {
    Row() {
      Text(title)
        .attributeModifier(new LiveText(LiveTheme.TextRole.itemTitle, LiveTheme.TextTone.secondary))
        .maxLines(2)
        .width(112)
        .margin({ left: 16 })
      Text(`${Math.round(value)}`)
        .attributeModifier(new LiveText(LiveTheme.TextRole.action, LiveTheme.TextTone.secondary, TextAlign.End))
        .width(30)
        .margin({ left: 8, right: 10 })
      Slider({
        value: value,
        min: 0,
        max: 100,
        step: 1
      })
        .attributeModifier(new LiveSlider())
        .layoutWeight(1)
        .margin({ right: 16 })
        .onChange((next: number) => {
          if (this.isActive) {
            onChange(Math.round(next))
          }
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  soundOptionSection(title: string, options: SoundOption[], selected: number, onSelect: (value: number) => void) {
    Column() {
      Text(title)
        .attributeModifier(new LiveText(LiveTheme.TextRole.sectionTitle, LiveTheme.TextTone.tertiary))
        .height(15)
      Row() {
        ForEach(options, (option: SoundOption) => {
          PusherSettingsItemView({
            title: LiveKitResources.localizedString(option.titleKey),
            assetName: option.assetName,
            isSelected: option.value === (options.some((item: SoundOption) => item.value === selected) ? selected :
              options[0].value),
            itemStyle: Style.soundOption,
            onTap: () => {
              if (this.isActive) {
                onSelect(option.value)
              }
            },
          })
            .layoutWeight(1)
        }, (option: SoundOption) => `${option.value}`)
      }
      .width('100%')
      .height(64)
      .margin({ top: 7 })
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .height(86)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      Column() {
        Row() {
          Text(LiveKitResources.localizedString('tuilivekit.pusher.settings.ear_monitor'))
            .attributeModifier(new LiveText(LiveTheme.TextRole.body, LiveTheme.TextTone.primary, TextAlign.Start, true))
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.audioState.isEarMonitorOpened })
            .selectedColor(rgba(0.18, 0.52, 0.95))
            .width(41.31)
            .height(25.11)
            .onChange((isOn: boolean) => {
              if (this.isActive) {
                this.audioState.setVoiceEarMonitorEnable(isOn)
              }
            })
        }
        .height(48)
        .padding({ left: 16, right: 14.845 })

        Row() {
          this.settingsVolumeView(LiveKitResources.localizedString('tuilivekit.pusher.settings.ear_monitor_volume'),
            this.audioState.earMonitorVolume,
            (value: number) => this.audioState.setVoiceEarMonitorVolume(Math.min(100, Math.max(0, value))))
        }
        .height(48)
      }
      .height(96)
      .borderRadius(14)
      .borderWidth(1)
      .borderColor(PusherSettingsSelectionStyle.idleBorder)
      .backgroundColor(PusherSettingsSelectionStyle.idleBackground)

      Text(LiveKitResources.localizedString('tuilivekit.pusher.settings.audio'))
        .attributeModifier(new LiveText(LiveTheme.TextRole.sectionTitle, LiveTheme.TextTone.tertiary))
        .height(15)
        .margin({ top: 12 })
      Row() {
        this.settingsVolumeView(LiveKitResources.localizedString('tuilivekit.pusher.settings.capture_volume'),
          this.captureVolume, (value: number) => this.onSetCaptureVolume?.(value))
      }
      .height(46)
      .margin({ top: 7 })
      .borderRadius(14)
      .borderWidth(1)
      .borderColor(PusherSettingsSelectionStyle.idleBorder)
      .backgroundColor(PusherSettingsSelectionStyle.idleBackground)

      Column({ space: 12 }) {
        this.soundOptionSection(LiveKitResources.localizedString('tuilivekit.pusher.settings.voice_changer'),
          changerOptions,
          this.audioState.audioChangerType, (value: number) => this.audioState.setAudioChangerType(value))
        this.soundOptionSection(LiveKitResources.localizedString('tuilivekit.pusher.settings.reverb'), reverbOptions,
          this.audioState.audioReverbType, (value: number) => this.audioState.setAudioReverbType(value))
      }
      .margin({ top: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct PusherAudioEffectSheet {
  @Consume('pusherAudioEffect') audioState: AudioEffectState
  @Prop isPresented: boolean = false
  @Prop showsAudio: boolean = false
  @Prop mainSheetHeight: number = 0
  @Prop mainSheetTitle: string = ''
  @Prop captureVolume: number = 100
  onDismiss?: () => void
  onSetCaptureVolume?: (volume: number) => void
  sheetDidDismiss?: () => void
  @BuilderParam mainContent: () => void
  @State private isActive: boolean = false

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: this.showsAudio ? 466 : this.mainSheetHeight,
      sheetTitle: this.showsAudio ? LiveKitResources.localizedString('tuilivekit.pusher.audio_effects') :
        this.mainSheetTitle,
      onDismiss: () => this.onDismiss?.(),
      sheetWillPresent: () => this.isActive = true,
      sheetWillDismiss: () => this.isActive = false,
      sheetDidDismiss: () => this.sheetDidDismiss?.(),
    }) {
      if (this.showsAudio) {
        AudioEffectView({
          captureVolume: this.captureVolume,
          isActive: this.isActive && this.showsAudio,
          audioState: this.audioState,
          onSetCaptureVolume: (volume: number) => this.onSetCaptureVolume?.(volume),
        })
          .padding({ left: 16, right: 16 })
          .margin({ top: 60 })
          .height(372)
      } else {
        this.mainContent()
      }
    }
  }
}
