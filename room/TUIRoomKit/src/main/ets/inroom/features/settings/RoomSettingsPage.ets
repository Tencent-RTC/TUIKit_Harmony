import { DeviceState, DeviceStore, MirrorType, VideoQuality } from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../base/util/RoomResources'
import { RoomSafeArea } from '../../../base/util/RoomSafeArea'
import { RoomSettingsOptionsPage, roomVideoQualityDisplayName } from './RoomSettingsOptionsPage'

export enum RoomSettingsRowStyle {
  TOGGLE,
  NAVIGATION,
  OPTION,
}

@Component
export struct RoomSettingsNavBar {
  @Prop title: string = ''
  onBack?: () => void
  @State private isPressed: boolean = false
  @StorageProp(RoomSafeArea.topKey) private safeTop: number = 0

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Stack() {
          Image(RoomResources.image('roomkit_icon_back'))
            .width(22)
            .height(22)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .opacity(this.isPressed ? 0.72 : 1)
        .onTouch((event: TouchEvent) => {
          this.isPressed = event.type === TouchType.Down
        })
        .onClick(() => this.onBack?.())
      }
      .width('100%')
      .padding({ left: 8 })
      Text(this.title)
        .fontSize(17)
        .fontWeight(600)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .textAlign(TextAlign.Center)
        .constraintSize({ maxWidth: '70%' })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(52 + this.safeTop)
    .padding({ top: this.safeTop })
    .backgroundColor($r('app.color.roomkit_bg_surface'))
  }
}

@Component
export struct RoomSettingsRow {
  @Prop style: RoomSettingsRowStyle = RoomSettingsRowStyle.NAVIGATION
  @Prop title: string = ''
  @Prop desc: string = ''
  @Prop value: string = ''
  @Prop isOn: boolean = false
  @Prop isChecked: boolean = false
  @Prop isToggleEnabled: boolean = true
  @Prop showsSeparator: boolean = false
  @State private isPressed: boolean = false
  onToggle?: (isOn: boolean) => void
  onTap?: () => void

  @Builder
  toggleView(isOn: boolean) {
    Toggle({ type: ToggleType.Switch, isOn: isOn })
      .width(40)
      .height(22)
      .selectedColor($r('app.color.roomkit_accent'))
      .enabled(this.isToggleEnabled)
      .onChange((value: boolean) => {
        this.onToggle?.(value)
      })
  }

  build() {
    Column() {
      if (this.showsSeparator) {
        Column()
          .height(1)
          .width('100%')
          .backgroundColor($r('app.color.roomkit_border'))
      }
      Row() {
        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(16)
            .fontColor($r('app.color.roomkit_fg_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.desc.length > 0) {
            Text(this.desc)
              .fontSize(12)
              .fontColor($r('app.color.roomkit_fg_tertiary'))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ right: this.style === RoomSettingsRowStyle.TOGGLE ? 8 : 0 })
        if (this.style === RoomSettingsRowStyle.TOGGLE) {
          if (this.isOn) {
            this.toggleView(true)
          } else {
            this.toggleView(false)
          }
        } else if (this.style === RoomSettingsRowStyle.NAVIGATION) {
          Text(this.value)
            .fontSize(14)
            .fontColor($r('app.color.roomkit_fg_tertiary'))
            .margin({ right: 12 })
          Image(RoomResources.image('roomkit_icon_chevron_right_tertiary'))
            .width(16)
            .height(16)
        } else {
          if (this.isChecked) {
            Image(RoomResources.image('roomkit_icon_check_accent'))
              .width(16)
              .height(16)
          }
        }
      }
      .width('100%')
      .padding({
        left: 14,
        right: 14,
        top: this.style === RoomSettingsRowStyle.TOGGLE ? 9 : 0,
        bottom: this.style === RoomSettingsRowStyle.TOGGLE ? 9 : 0,
      })
      .height(this.style === RoomSettingsRowStyle.TOGGLE ? undefined : 52)
    }
    .width('100%')
    .opacity(this.isToggleEnabled ? 1 : 0.45)
    .backgroundColor(this.isPressed && this.style !== RoomSettingsRowStyle.TOGGLE ?
      $r('app.color.roomkit_bg_press') : Color.Transparent)
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => {
      if (this.style !== RoomSettingsRowStyle.TOGGLE) {
        this.onTap?.()
      }
    })
  }
}

@Component
export struct RoomSettingsPage {
  onBack?: () => void
  @State private deviceState: DeviceState = DeviceStore.shared().state
  @State private isOptionsVisible: boolean = false

  aboutToAppear(): void {
    RoomSafeArea.observe()
  }

  aboutToDisappear(): void {
    RoomSafeArea.stopObserving()
  }

  private isMirrorOn(): boolean {
    return this.deviceState.isFrontCamera && this.deviceState.localMirrorType !== MirrorType.disable
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        RoomSettingsNavBar({
          title: RoomResources.string('roomkit_settings_title'),
          onBack: () => this.onBack?.(),
        })
        Scroll() {
          Column() {
            Text(RoomResources.string('roomkit_settings_group_video'))
              .fontSize(11)
              .fontColor($r('app.color.roomkit_fg_tertiary'))
              .width('100%')
              .padding({ left: 32, right: 32, top: 16 })
            Column() {
              RoomSettingsRow({
                style: RoomSettingsRowStyle.TOGGLE,
                title: RoomResources.string('roomkit_settings_mirror'),
                desc: RoomResources.string('roomkit_settings_mirror_desc'),
                isOn: this.isMirrorOn(),
                isToggleEnabled: this.deviceState.isFrontCamera,
                onToggle: (isOn: boolean) => {
                  DeviceStore.shared().switchMirror(isOn ? MirrorType.enable : MirrorType.disable)
                },
              })
              RoomSettingsRow({
                style: RoomSettingsRowStyle.NAVIGATION,
                title: RoomResources.string('roomkit_settings_resolution'),
                value: roomVideoQualityDisplayName(this.deviceState.localVideoQuality),
                showsSeparator: true,
                onTap: () => {
                  this.isOptionsVisible = true
                },
              })
            }
            .backgroundColor($r('app.color.roomkit_bg_surface'))
            .borderRadius(12)
            .clip(true)
            .margin({ left: 16, right: 16, top: 6, bottom: 24 })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      }
      .width('100%')
      .height('100%')
      if (this.isOptionsVisible) {
        RoomSettingsOptionsPage({
          onBack: () => {
            this.isOptionsVisible = false
          },
        })
          .width('100%')
          .height('100%')
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.translate({ x: '100%' }).animation({ duration: 250, curve: Curve.EaseOut }),
            TransitionEffect.translate({ x: '100%' }).animation({ duration: 250, curve: Curve.EaseIn }),
          ))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.roomkit_bg_canvas'))
  }
}
