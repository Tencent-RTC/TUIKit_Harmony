import { curves } from '@kit.ArkUI'
import { LiveKitResources } from '../LiveKitResources'
import { LiveText } from './LiveText'
import { black, LiveTheme, rgba, white } from './LiveTheme'

export const volumeWaveThreshold: number = 0

@Observed
export class LiveSeatState {
  name: string = ''
  avatarURL: string = ''
  microphoneOn: boolean = false
  isEmpty: boolean = true
  showsNoVideo: boolean = false
  showsOverlay: boolean = false
  volume: number = 0

  updateContent(name: string, avatarURL: string, microphoneOn: boolean): void {
    this.name = name
    this.avatarURL = avatarURL
    this.microphoneOn = microphoneOn
  }

  updateVisibility(isEmpty: boolean, showsNoVideo: boolean, showsOverlay: boolean): void {
    this.isEmpty = isEmpty
    this.showsNoVideo = showsNoVideo
    this.showsOverlay = showsOverlay
  }

  updateVolume(volume: number): void {
    if (this.volume !== volume) {
      this.volume = volume
    }
  }
}

@Component
export struct LiveSeat {
  @ObjectLink seat: LiveSeatState
  emptyTitle: string = ''
  @State private seatWidth: number = 0
  @State private seatHeight: number = 0
  @State private waveScale: number = 1
  @State private waveOpacity: number = 0
  private waveTask: number = -1

  aboutToDisappear(): void {
    clearTimeout(this.waveTask)
  }

  private shortSide(): number {
    return Math.min(this.seatWidth, this.seatHeight)
  }

  private avatarSize(): number {
    const side = this.shortSide()
    return side <= 110 ? 42 : side <= 140 ? 30 : side > 250 ? 67 : 63
  }

  private showsWave(): boolean {
    return !this.seat.isEmpty && this.seat.showsNoVideo && this.seat.volume > volumeWaveThreshold
  }

  @Builder
  waveRing(delay: number) {
    Circle()
      .width(this.avatarSize() + 4)
      .height(this.avatarSize() + 4)
      .fill(Color.Transparent)
      .stroke(white(0.9))
      .strokeWidth(2)
      .scale({ x: this.waveScale, y: this.waveScale })
      .opacity(this.waveOpacity)
      .animation({
        duration: 1400,
        delay: delay,
        iterations: -1,
        curve: curves.cubicBezierCurve(0.16, 0.5, 0.4, 1)
      })
      .onDisAppear(() => {
        if (delay === 0) {
          clearTimeout(this.waveTask)
        }
      })
      .onAppear(() => {
        if (delay === 0) {
          this.startWave()
        }
      })
  }

  @Builder
  noVideoView() {
    Stack() {
      if (this.showsWave()) {
        this.waveRing(0)
        this.waveRing(700)
      }
      Image(this.seat.avatarURL.length > 0 ? this.seat.avatarURL :
        LiveKitResources.image('livekit_livelist_default_avatar'))
        .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
        .width(this.avatarSize())
        .height(this.avatarSize())
        .borderRadius(this.avatarSize() / 2)
        .objectFit(ImageFit.Cover)
    }
    .width('100%')
    .height('100%')
    .linearGradient(
      { direction: GradientDirection.RightBottom, colors: [[rgba(0.1, 0.18, 0.27), 0], [rgba(0.03, 0.06, 0.12), 1]] })
  }

  @Builder
  overlayView() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.seatWidth > 12 && this.seatHeight >= 14) {
        Column()
          .width('100%')
          .height(14)
          .position({ x: 0, y: this.seatHeight - 14 })
          .linearGradient({ angle: 180, colors: [[black(0), 0], [black(0.4), 1]] })
        Row() {
          Image(
            LiveKitResources.image(this.seat.microphoneOn ? 'livekit_coguest_seat_mic' : 'livekit_coguest_seat_muted'))
            .width(12)
            .height(12)
            .objectFit(ImageFit.Contain)
        }
        .width(Math.min(20, this.seatWidth - 12))
        .height(14)
        .borderRadius(7)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(black(0.32))
        .position({ x: 6, y: 6 })

        Text(this.seat.name)
          .fontSize(10)
          .fontColor(white(0.8))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(Math.max(0, this.seatWidth - 8))
          .height(14)
          .position({ x: 4, y: Math.max(0, this.seatHeight - 14) })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  emptyView() {
    Column({ space: 3 }) {
      Text('+')
        .fontSize(this.shortSide() - 2 <= 110 ? 29 : 26)
        .fontWeight(100)
        .fontColor(white(0.46))
        .height(this.shortSide() - 2 <= 110 ? 32 : 30)
      if (this.seatHeight - 2 >= (this.shortSide() - 2 <= 110 ? 32 : 30) + 17) {
        Text(this.emptyTitle)
          .attributeModifier(new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.tertiary, TextAlign.Center))
          .height(14)
      }
    }
    .width('100%')
    .height('100%')
    .margin(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(white(this.shortSide() - 2 <= 110 ? 0.055 : 0.035))
  }

  private startWave(): void {
    this.waveScale = 1
    this.waveOpacity = 0.78
    clearTimeout(this.waveTask)
    this.waveTask = setTimeout(() => {
      if (this.showsWave()) {
        this.waveScale = 1.38
        this.waveOpacity = 0
      }
    }, 0)
  }

  build() {
    Stack() {
      if (!this.seat.isEmpty && this.seat.showsNoVideo) {
        this.noVideoView()
      }
      if (!this.seat.isEmpty && this.seat.showsOverlay) {
        this.overlayView()
      }
      if (this.seat.isEmpty) {
        this.emptyView()
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
    .onAreaChange((_: Area, area: Area) => {
      this.seatWidth = area.width as number
      this.seatHeight = area.height as number
    })
  }
}
