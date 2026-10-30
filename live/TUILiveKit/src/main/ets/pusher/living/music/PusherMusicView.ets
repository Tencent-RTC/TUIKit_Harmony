import curves from '@ohos.curves'
import { AudioMusicParam, MusicPlayStatus, MusicState, MusicStore } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveTheme, white } from '../../../common/theme/LiveTheme'

class Track {
  name: string
  url: string
  duration: string

  constructor(nameKey: string, url: string, duration: string) {
    this.name = LiveKitResources.localizedString(nameKey)
    this.url = url
    this.duration = duration
  }
}

class WaveParameters {
  duration: number
  delay: number
  low: number
  high: number

  constructor(duration: number, delay: number, low: number, high: number) {
    this.duration = duration
    this.delay = delay
    this.low = low
    this.high = high
  }
}

const waveParameters: WaveParameters[] = [new WaveParameters(620, 180, 3, -4), new WaveParameters(790, 510, 2, -5),
  new WaveParameters(530, 340, 4, -3), new WaveParameters(710, 620, 2, -4)]

@Component
struct MusicWaveView {
  @Prop @Watch('update') isPlaying: boolean = false
  @State private phases: boolean[] = [false, false, false, false]
  private startTimer: number = -1
  private isLaidOut: boolean = false
  private readonly waveCurve: ICurve = curves.cubicBezierCurve(0.37, 0, 0.63, 1)

  aboutToAppear(): void {
    this.update()
  }

  aboutToDisappear(): void {
    clearTimeout(this.startTimer)
    this.isLaidOut = false
    this.phases = [false, false, false, false]
  }

  private update(): void {
    clearTimeout(this.startTimer)
    this.phases = [false, false, false, false]
    if (this.isPlaying && this.isLaidOut) {
      this.startTimer = setTimeout(() => {
        this.startTimer = -1
        if (this.isPlaying && this.isLaidOut) {
          this.phases = [true, true, true, true]
        }
      }, 0)
    }
  }

  build() {
    Row() {
      ForEach(waveParameters, (parameters: WaveParameters, index: number) => {
        Column()
          .width(4)
          .height(4)
          .borderRadius(2)
          .backgroundColor(LiveTheme.Color.brandCyan)
          .shadow({ radius: 5, color: LiveTheme.Color.brandCyan })
          .opacity(this.isPlaying ? (this.phases[index] ? 1 : 0.64) : 0.9)
          .translate({ y: this.isPlaying ? (this.phases[index] ? parameters.high : parameters.low) : 0 })
          .scale(this.isPlaying ? (this.phases[index] ? { x: 1.08, y: 1.08 } : { x: 0.82, y: 0.82 }) : { x: 1, y: 1 })
          .animation(this.isPlaying ? {
            duration: parameters.duration,
            delay: -parameters.delay,
            iterations: -1,
            playMode: PlayMode.Alternate,
            curve: this.waveCurve,
          } : { duration: 0 })
      }, (parameters: WaveParameters, index: number) => `${index}`)
    }
    .width(25)
    .height(18)
    .justifyContent(FlexAlign.SpaceBetween)
    .onAreaChange((_: Area, area: Area) => {
      if (!this.isLaidOut && Number(area.width) > 0 && Number(area.height) > 0) {
        this.isLaidOut = true
        this.update()
      }
    })
  }
}

@Component
export struct PusherMusicView {
  @Prop @Watch('onPresentationChanged') isPresented: boolean = false
  @Prop liveID: string = ''
  @Prop @Watch('onActiveChanged') isActive: boolean = false
  @Prop @Watch('onSuspendedChanged') isSuspended: boolean = false
  onDismiss?: () => void
  @State @Watch('updateState') private musicState: MusicState = new MusicState()
  private readonly tracks: Track[] = [
    new Track('tuilivekit.pusher.music.happy',
      'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/PositiveHappyAdvertising.mp3', '05:45'),
    new Track('tuilivekit.pusher.music.sad',
      'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/SadCinematicPiano.mp3', '06:06'),
    new Track('tuilivekit.pusher.music.wonder_world',
      'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/WonderWorld.mp3', '02:05'),
  ]
  @State private currentURL: string | undefined = undefined
  @State private playStatus: MusicPlayStatus = MusicPlayStatus.IDLE
  private stateRefreshTimer: number = -1
  private sessionID: number = 0
  private musicStore?: MusicStore
  private isObserving: boolean = false
  private resumeURL?: string

  aboutToAppear(): void {
    this.onActiveChanged()
  }

  aboutToDisappear(): void {
    this.deactivate()
  }

  private onActiveChanged(): void {
    this.isActive ? this.activate() : this.deactivate()
  }

  private activate(): void {
    if (this.isObserving || this.liveID.length === 0) {
      return
    }
    this.isObserving = true
    this.musicStore = MusicStore.create(this.liveID)
    this.musicState = this.musicStore.musicState
    this.updateState()
    this.onPresentationChanged()
  }

  private deactivate(): void {
    this.sessionID += 1
    clearInterval(this.stateRefreshTimer)
    this.stateRefreshTimer = -1
    this.currentURL = undefined
    this.playStatus = MusicPlayStatus.IDLE
    this.resumeURL = undefined
    if (!this.isObserving) {
      return
    }
    this.isObserving = false
    this.musicStore?.stopPlay()
    this.musicState = new MusicState()
  }

  private onSuspendedChanged(): void {
    if (!this.isObserving || this.musicStore === undefined) {
      return
    }
    const current = this.musicStore.musicState
    if (this.isSuspended) {
      const isPlaying = current.playStatus === MusicPlayStatus.PLAYING || current.playStatus === MusicPlayStatus.LOADING
      this.resumeURL = isPlaying ? current.playURL : undefined
      if (this.resumeURL !== undefined) {
        this.musicStore.pausePlay()
      }
    } else {
      const shouldResume = this.resumeURL !== undefined && this.resumeURL === current.playURL &&
        current.playStatus === MusicPlayStatus.PAUSED
      this.resumeURL = undefined
      if (shouldResume) {
        this.musicStore.resumePlay()
      }
    }
  }

  private onPresentationChanged(): void {
    clearInterval(this.stateRefreshTimer)
    this.stateRefreshTimer = -1
    if (!this.isObserving || !this.isPresented) {
      return
    }
    this.updateState()
    // Read only while visible; SDK remains the playback state owner.
    this.stateRefreshTimer = setInterval(() => this.updateState(), 200)
  }

  private updateState(): void {
    if (!this.isObserving || this.musicStore === undefined) {
      return
    }
    const state = this.musicStore.musicState
    if (this.currentURL !== state.playURL || this.playStatus !== state.playStatus) {
      console.info(`[PusherMusic] state=${state.playStatus}, hasURL=${(state.playURL?.length ?? 0) > 0}`)
      this.currentURL = state.playURL
      this.playStatus = state.playStatus
    }
    if (this.isSuspended && state.playStatus === MusicPlayStatus.PLAYING) {
      this.musicStore.pausePlay()
    }
  }

  private toggle(track: Track): void {
    const store = this.musicStore
    if (!this.isObserving || this.isSuspended || store === undefined) {
      return
    }
    this.updateState()
    if (this.currentURL === track.url) {
      if (this.playStatus === MusicPlayStatus.PLAYING ||
        this.playStatus === MusicPlayStatus.LOADING) {
        store.pausePlay()
        this.updateState()
        return
      }
      if (this.playStatus === MusicPlayStatus.PAUSED) {
        store.resumePlay()
        this.updateState()
        return
      }
    } else if (this.currentURL !== undefined) {
      store.stopPlay()
    }
    store.setPitch(0)
    const param = new AudioMusicParam()
    param.path = track.url
    const session = this.sessionID
    store.startPlay(param).then(() => {
      if (!this.isObserving || session !== this.sessionID) {
        return
      }
      this.updateState()
      console.info(
        `[PusherMusic] start completed: state=${this.playStatus}, matchesRequested=${this.currentURL === track.url}`)
    }).catch((error: Error) => {
      if (this.isObserving && session === this.sessionID) {
        this.updateState()
        console.error(`[PusherMusic] start failed: ${error.message}`)
      }
    })
    this.updateState()
  }

  private isCurrent(track: Track): boolean {
    return this.currentURL === track.url && this.playStatus !== MusicPlayStatus.IDLE
  }

  private isPlaying(track: Track): boolean {
    return this.currentURL === track.url &&
      (this.playStatus === MusicPlayStatus.PLAYING || this.playStatus === MusicPlayStatus.LOADING)
  }

  @Builder
  musicCell(track: Track) {
    Row() {
      Stack() {
        Image(LiveKitResources.image('livekit_living_setting_music')).width(18).height(21).objectFit(ImageFit.Contain)
        if (this.isCurrent(track)) {
          Stack() {
            MusicWaveView({ isPlaying: this.isPresented && !this.isSuspended && this.isPlaying(track) })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(5, 7, 12, 0.56)')
        }
      }
      .width(50)
      .height(50)
      .borderRadius(9)
      .backgroundColor(white(0.06))
      .clip(true)

      Column({ space: 7 }) {
        Text(track.name)
          .attributeModifier(new LiveText(LiveTheme.TextRole.body))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(track.duration).attributeModifier(new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.tertiary))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12, right: 12 })

      Stack() {
        if (this.isCurrent(track)) {
          Image(LiveKitResources.image(this.isPlaying(track) ? 'livekit_music_pause' : 'livekit_music_play'))
            .width(19)
            .height(19)
            .objectFit(ImageFit.Contain)
        }
      }
      .width(28)
      .height(28)
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .onClick(() => this.toggle(track))
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: 370,
      sheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.living.music'),
      onDismiss: () => this.onDismiss?.(),
    }) {
      List() {
        ForEach(this.tracks, (track: Track) => {
          ListItem() {
            this.musicCell(track)
          }
        }, (track: Track) => track.url)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height(310)
      .padding({ top: 4, bottom: 16 })
      .margin({ top: 60 })
    }
  }
}
