import { preferences } from '@kit.ArkData'
import { LoginStore } from '@tencentcloud/atomicxcore'
import { getTRTCShareInstance } from '@tencentcloud/liteavsdk_professional'
import { LiveKitResources } from '../LiveKitResources'
import { BottomSheetView } from '../theme/BottomSheetView'
import { LiveSlider } from '../theme/LiveSlider'
import { LiveText } from '../theme/LiveText'
import { LiveTheme, rgba, white } from '../theme/LiveTheme'

class StoredBeauty {
  isEnabled: boolean = true
  smoothLevel: number = 0
  whitenessLevel: number = 0
  ruddyLevel: number = 0
}

export class BeautyPreferences {
  isEnabled: boolean = true
  smoothLevel: number = 0
  whitenessLevel: number = 0
  ruddyLevel: number = 0

  static get currentKey(): string | undefined {
    const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    return userID.length === 0 ? undefined : `TUILiveKit.beauty.v1.${LoginStore.shared().sdkAppID}.${userID}`
  }

  private static store(): preferences.Preferences {
    return preferences.getPreferencesSync(getContext(), { name: 'TUILiveKit' })
  }

  static load(key: string | undefined): BeautyPreferences {
    const settings = new BeautyPreferences()
    if (key === undefined) {
      return settings
    }
    try {
      const stored = JSON.parse(BeautyPreferences.store().getSync(key, '{}') as string) as StoredBeauty
      settings.isEnabled = stored.isEnabled ?? true
      settings.smoothLevel = BeautyPreferences.validated(stored.smoothLevel)
      settings.whitenessLevel = BeautyPreferences.validated(stored.whitenessLevel)
      settings.ruddyLevel = BeautyPreferences.validated(stored.ruddyLevel)
    } catch (e) {
    }
    return settings
  }

  static restore(): void {
    BeautyPreferences.load(BeautyPreferences.currentKey).apply()
  }

  private static validated(value: number | undefined): number {
    return value !== undefined && Number.isFinite(value) ? Math.min(9, Math.max(0, value)) : 0
  }

  save(key: string | undefined): void {
    if (key === undefined) {
      return
    }
    const store = BeautyPreferences.store()
    store.putSync(key, JSON.stringify(this))
    store.flush()
  }

  apply(): void {
    const manager = getTRTCShareInstance().getBeautyManager()
    manager.setBeautyLevel(this.isEnabled ? this.smoothLevel : 0)
    manager.setWhitenessLevel(this.isEnabled ? this.whitenessLevel : 0)
    manager.setRuddyLevel(this.isEnabled ? this.ruddyLevel : 0)
  }
}

enum Kind {
  smooth,
  whiteness,
  ruddy,
}

const kinds: Kind[] = [Kind.smooth, Kind.whiteness, Kind.ruddy]
const titleKeys: string[] =
  ['tuilivekit.pusher.beauty.smooth', 'tuilivekit.pusher.beauty.whiteness', 'tuilivekit.pusher.beauty.ruddy']
const assetNames: string[] = ['livekit_beauty_smooth', 'livekit_beauty_whiteness', 'livekit_beauty_ruddy']
const accent: string = rgba(0.31, 0.64, 1)

@Component
export struct BeautyPanel {
  @Prop isPresented: boolean = false
  onDismiss?: () => void
  @State private settings: BeautyPreferences = new BeautyPreferences()
  @State private selectedKind: Kind = Kind.smooth
  private preferencesKey?: string
  private isActive: boolean = false

  private canEdit(): boolean {
    return this.isActive && this.preferencesKey === BeautyPreferences.currentKey
  }

  private value(): number {
    return [this.settings.smoothLevel, this.settings.whitenessLevel, this.settings.ruddyLevel][this.selectedKind]
  }

  private sheetWillPresent(): void {
    this.preferencesKey = BeautyPreferences.currentKey
    this.settings = BeautyPreferences.load(this.preferencesKey)
    this.settings.apply()
    this.selectedKind = Kind.smooth
    this.isActive = true
  }

  private setEnabled(enabled: boolean): void {
    if (!this.canEdit() || this.settings.isEnabled === enabled) {
      return
    }
    this.settings.isEnabled = enabled
    this.settings.save(this.preferencesKey)
    this.settings.apply()
  }

  private setBeautyLevel(raw: number): void {
    if (!this.canEdit() || !this.settings.isEnabled || !Number.isFinite(raw)) {
      return
    }
    const value = Math.min(9, Math.max(0, raw))
    if (this.selectedKind === Kind.smooth) {
      this.settings.smoothLevel = value
    } else if (this.selectedKind === Kind.whiteness) {
      this.settings.whitenessLevel = value
    } else {
      this.settings.ruddyLevel = value
    }
    this.settings.save(this.preferencesKey)
    this.settings.apply()
  }

  @Builder
  option(kind: Kind) {
    Column() {
      Stack() {
        Image(LiveKitResources.image(assetNames[kind]))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          .opacity(this.selectedKind === kind ? 1 : 0.82)
      }
      .width(44)
      .height(44)
      .margin({ top: 4 })
      .borderRadius(22)
      .borderWidth(1)
      .borderColor(this.selectedKind === kind ? accent : white(0.12))
      .backgroundColor(this.selectedKind === kind ? rgba(0.18, 0.48, 0.92, 0.32) : white(0.08))

      Text(LiveKitResources.localizedString(titleKeys[kind]))
        .attributeModifier(new LiveText(LiveTheme.TextRole.control,
          this.selectedKind === kind ? LiveTheme.TextTone.primary : LiveTheme.TextTone.secondary, TextAlign.Center))
        .width('100%')
        .height(14)
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .height(73)
    .accessibilityText(LiveKitResources.localizedString(titleKeys[kind]))
    .onClick(() => this.selectedKind = kind)
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      onDismiss: () => this.onDismiss?.(),
      sheetHeight: 220,
      sheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.beauty'),
      sheetWillPresent: () => this.sheetWillPresent(),
      sheetWillDismiss: () => this.isActive = false,
    }) {
      Column() {
        Row({ space: 8 }) {
          Text(LiveKitResources.localizedString(titleKeys[this.selectedKind]))
            .attributeModifier(new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.secondary))
            .constraintSize({ minWidth: 34 })
            .height(32)
          Slider({
            value: this.value(),
            min: 0,
            max: 9,
            step: 1
          })
            .attributeModifier(new LiveSlider())
            .layoutWeight(1)
            .enabled(this.settings.isEnabled)
            .opacity(this.settings.isEnabled ? 1 : 0.4)
            .onChange((value: number) => this.setBeautyLevel(value))
          Text(`${Math.round(this.value())}`)
            .attributeModifier(
              new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.primary, TextAlign.End, true))
            .width(22)
        }
        .padding({ left: 4, right: 4 })
        .height(32)

        Row() {
          Column() {
            Stack() {
              Toggle({ type: ToggleType.Switch, isOn: this.settings.isEnabled })
                .selectedColor(rgba(0.18, 0.52, 0.95))
                .width(41.31)
                .height(25.11)
                .accessibilityText(LiveKitResources.localizedString('tuilivekit.pusher.beauty'))
                .onChange((isOn: boolean) => this.setEnabled(isOn))
            }
            .width('100%')
            .height(52)

            Text(LiveKitResources.localizedString('tuilivekit.pusher.beauty'))
              .attributeModifier(
                new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.secondary, TextAlign.Center))
              .width('100%')
              .height(14)
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .height(73)

          ForEach(kinds, (kind: Kind) => this.option(kind))
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .padding({ left: 20, right: 20 })
      .margin({ top: 68 })
      .height(112)
    }
  }
}
