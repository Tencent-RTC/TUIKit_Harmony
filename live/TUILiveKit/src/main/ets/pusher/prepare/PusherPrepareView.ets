import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { LiveTheme, rgba } from '../../common/theme/LiveTheme'
import { PusherSettingsActionHandling, PusherSettingsState } from '../settings/PusherSettingsActionHandling'
import { PusherSettingsItemView, Style } from '../settings/PusherSettingsItemView'
import { CountdownView } from './CountdownView'
import { PrepareMoreSettingsView } from './PrepareMoreSettingsView'
import { PusherCoverPickerView } from './PusherCoverPickerView'
import { PusherLiveInfoEditorView } from './PusherLiveInfoEditorView'
import { PusherPrepareGradientOverlayView } from './PusherPrepareGradientOverlayView'

@Component
export struct PusherPrepareView {
  @Prop title: string = ''
  @Prop coverURL: string = LiveKitResources.defaultCoverURL
  @Prop settings: PusherSettingsState = new PusherSettingsState()
  @Prop @Watch('deactivate') deactivateToken: number = 0
  onCountdownFinished?: (title: string) => void
  onExit?: () => void
  onSelectCover?: (coverURL: string) => void
  onTitleChanged?: (title: string) => void
  onFlipCamera?: () => void
  onShowBeauty?: () => void
  onRefreshSettings?: () => void
  settingsActionHandler?: PusherSettingsActionHandling
  @StorageProp(LiveKitSafeArea.topKey) safeTop: number = 0
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private isCountdownPresented: boolean = false
  @State private countdownValue: number = 0
  @State private isCoverPickerPresented: boolean = false
  @State private isMoreSettingsPresented: boolean = false
  @State private editingTitle: string = ''
  @State private viewportHeight: number = 0
  @State private controlsHeight: number = 169
  private countdownTimer: number = -1
  private countdownTitle?: string

  aboutToAppear(): void {
    this.editingTitle = this.title
  }

  aboutToDisappear(): void {
    this.stopCountdown()
  }

  deactivate(): void {
    this.stopCountdown()
    this.isCountdownPresented = false
  }

  private start(): void {
    if (this.isCountdownPresented) {
      return
    }
    this.getUIContext().getFocusController().clearFocus()
    this.countdownTitle = this.editingTitle.length > 0 ? this.editingTitle : this.title
    this.countdownValue = 3
    this.isCountdownPresented = true
  }

  private countdownReady(): void {
    if (!this.isCountdownPresented || this.countdownTimer >= 0) {
      return
    }
    this.countdownTimer = setInterval(() => this.advanceCountdown(), 1000)
  }

  private advanceCountdown(): void {
    if (this.countdownTimer < 0) {
      return
    }
    if (this.countdownValue > 1) {
      this.countdownValue -= 1
      return
    }
    const title = this.countdownTitle ?? this.editingTitle
    this.stopCountdown()
    this.isCountdownPresented = false
    this.onCountdownFinished?.(title)
  }

  private stopCountdown(): void {
    clearInterval(this.countdownTimer)
    this.countdownTimer = -1
    this.countdownValue = 0
    this.countdownTitle = undefined
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.isCountdownPresented) {
        Stack({ alignContent: Alignment.TopStart }) {
          PusherPrepareGradientOverlayView()
          Scroll() {
            PusherLiveInfoEditorView({
              title: this.countdownTimer >= 0 ? this.editingTitle : this.title,
              coverURL: this.coverURL,
              onChangeCover: () => {
                this.getUIContext().getFocusController().clearFocus()
                this.isCoverPickerPresented = true
              },
              onTitleChanged: (title: string) => {
                this.editingTitle = title
                this.onTitleChanged?.(title)
              },
            })
          }
          .width('100%')
          .height(Math.max(0, this.viewportHeight - this.safeTop - 85 - this.safeBottom - 7 - this.controlsHeight - 40))
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .position({ x: 0, y: this.safeTop + 85 })

          Text('×')
            .fontSize(30)
            .fontWeight(FontWeight.Lighter)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(44)
            .height(44)
            .position({ x: 8, y: this.safeTop + 4 })
            .onClick(() => this.onExit?.())
          Column() {
            Row({ space: 32 }) {
              PusherSettingsItemView({
                title: LiveKitResources.localizedString('tuilivekit.pusher.beautify'),
                assetName: 'livekit_prepare_beauty',
                itemStyle: Style.prepare,
                onTap: () => this.onShowBeauty?.(),
              })
              PusherSettingsItemView({
                title: LiveKitResources.localizedString('tuilivekit.pusher.flip_camera'),
                assetName: 'livekit_prepare_flip',
                itemStyle: Style.prepare,
                onTap: () => this.onFlipCamera?.(),
              })
              PusherSettingsItemView({
                title: LiveKitResources.localizedString('tuilivekit.common.more'),
                assetName: 'livekit_prepare_more',
                itemStyle: Style.prepare,
                onTap: () => {
                  this.onRefreshSettings?.()
                  this.isMoreSettingsPresented = true
                },
              })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 46 })

            Stack() {
              Text(LiveKitResources.localizedString('tuilivekit.pusher.prepare.start_live'))
                .fontSize(16)
                .fontWeight(600)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .width('100%')
                .height('100%')
                .borderRadius(24)
                .linearGradient({
                  direction: GradientDirection.RightTop,
                  colors: [[rgba(0, 0.32, 0.85, 0.92), 0], [LiveTheme.Color.brand(0.8), 1]],
                })
            }
            .width('100%')
            .height(52)
            .padding(2)
            .borderRadius(26)
            .linearGradient({
              direction: GradientDirection.RightTop,
              colors: [[LiveTheme.Color.brandDeepBlue, 0], [LiveTheme.Color.brandBlue, 0.5],
                [LiveTheme.Color.brandCyan, 1]],
            })
            .shadow({ radius: 14, color: 'rgba(0, 82, 217, 0.4)', offsetY: 8 })
            .onClick(() => this.start())
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .position({ left: 0, bottom: this.safeBottom + 7 })
          .onAreaChange((_: Area, area: Area) => this.controlsHeight = area.height as number)
        }
        .width('100%')
        .height('100%')
      } else {
        CountdownView({
          number: this.countdownValue,
          onReady: () => this.countdownReady(),
          onCancel: () => {
            this.stopCountdown()
            this.isCountdownPresented = false
          },
        })
      }
      PrepareMoreSettingsView({
        isPresented: this.isMoreSettingsPresented,
        settings: this.settings,
        actionHandler: this.settingsActionHandler,
        onDismiss: () => this.isMoreSettingsPresented = false,
      })
      PusherCoverPickerView({
        isPresented: this.isCoverPickerPresented,
        selectedURL: this.coverURL,
        onDismiss: () => this.isCoverPickerPresented = false,
        onSelect: (url: string) => this.onSelectCover?.(url),
      })
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_: Area, area: Area) => this.viewportHeight = area.height as number)
  }
}
