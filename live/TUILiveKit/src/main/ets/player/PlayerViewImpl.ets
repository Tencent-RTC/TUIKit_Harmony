import { ApplicationStateChangeCallback } from '@kit.AbilityKit'
import {
  AtomicPlayer,
  CoGuestStore,
  DeviceStatus,
  DeviceStore,
  EndedReason,
  KickedOutReason,
  LiveInfo,
  LiveSeatStore,
  LoginStore,
  PlayerListener,
  SeatUserInfo,
} from '@tencentcloud/atomicxcore'
import { BeautyPreferences } from '../common/beauty/BeautyPanel'
import { KeyMetrics } from '../common/KeyMetrics'
import { LiveKitResources, LiveKitSafeArea } from '../common/LiveKitResources'
import { dismissAllBottomSheets } from '../common/theme/BottomSheetView'
import { LiveTheme, white } from '../common/theme/LiveTheme'
import { LiveToast } from '../common/theme/LiveToastView'
import { CoGuestStatus } from './living/coguest/CoGuestIcon'
import { LivingView, LivingViewController } from './living/LivingView'
import { PlayerStatus } from './PlayerView'
import { PreviewView } from './preview/PreviewView'
import { SummaryView } from './summary/SummaryView'
import { PlayerVideoView, PlayerVideoViewController } from './video/PlayerVideoView'

class BackgroundCamera {
  liveID: string
  isFront: boolean

  constructor(liveID: string, isFront: boolean) {
    this.liveID = liveID
    this.isFront = isFront
  }
}

class PendingJoin {
  resolve: (liveInfo: LiveInfo) => void
  reject: (error: Error) => void

  constructor(resolve: (liveInfo: LiveInfo) => void, reject: (error: Error) => void) {
    this.resolve = resolve
    this.reject = reject
  }
}

@Observed
export class PlayerViewImplController {
  onCloseClicked?: () => void
  onJoinLiveClicked?: () => void
  readonly videoView: PlayerVideoViewController = new PlayerVideoViewController()
  readonly overlayView: LivingViewController = new LivingViewController()
  status: PlayerStatus = PlayerStatus.idle
  liveInfo?: LiveInfo
  summaryReason: string = ''
  isPreviewEnabled: boolean = true
  private entranceEnabled: boolean = true
  private readonly player: AtomicPlayer = new AtomicPlayer()
  private readonly statusListeners: Set<(status: PlayerStatus) => void> = new Set()
  private activeToast?: LiveToast
  private isJoinedChannel: boolean = false
  private isEntranceInitiatedJoin: boolean = false
  private joiningLiveID?: string
  private isClosing: boolean = false
  private activatedRoomLiveID?: string
  private playingLiveID?: string
  private backgroundCamera?: BackgroundCamera
  private cameraRestoreID: number = 0
  private isCameraRestoring: boolean = false
  private backgroundMicrophone?: string
  private microphoneRestoreID: number = 0
  private isMicrophoneRestoring: boolean = false
  private pendingJoinCompletions: PendingJoin[] = []
  private isAttached: boolean = false
  private isAppActive: boolean = true
  private applicationStateCallback?: ApplicationStateChangeCallback

  constructor() {
    this.overlayView.onToast = (message: string) => {
      if (this.isJoinedChannel) {
        this.showToast(message)
      }
    }
    this.overlayView.onCoGuestUiStateChanged = (state: CoGuestStatus) => this.handleCoGuestUiState(state)
    this.player.addListener(new PlayerListener(undefined, undefined, (reason: EndedReason) => this.handleLiveEnded(),
      (reason: KickedOutReason, message: string) => this.handleKickedOut(reason)))
  }

  get joinLiveEntranceEnabled(): boolean {
    return this.entranceEnabled
  }

  set joinLiveEntranceEnabled(enabled: boolean) {
    this.entranceEnabled = enabled
  }

  get liveID(): string | undefined {
    return this.liveInfo?.liveID
  }

  addStatusListener(listener: (status: PlayerStatus) => void): () => void {
    this.statusListeners.add(listener)
    listener(this.status)
    return () => this.statusListeners.delete(listener)
  }

  attach(): void {
    this.isAttached = true
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => {
        this.isAppActive = true
        this.restoreCaptureIfNeeded()
        this.restoreMicrophoneIfNeeded()
      },
      onApplicationBackground: () => {
        this.isAppActive = false
        this.suspendCapture()
      },
    }
    this.applicationStateCallback = callback
    getContext().getApplicationContext().on('applicationStateChange', callback)
    this.restoreCaptureIfNeeded()
    this.restoreMicrophoneIfNeeded()
  }

  detach(): void {
    this.isAttached = false
    if (this.applicationStateCallback !== undefined) {
      getContext().getApplicationContext().off('applicationStateChange', this.applicationStateCallback)
      this.applicationStateCallback = undefined
    }
    this.activeToast?.dismiss()
    this.backgroundCamera = undefined
    this.cameraRestoreID++
    this.clearBackgroundMicrophone()
    this.overlayView.invalidateCoGuestCameraRequests(false)
    this.overlayView.invalidateCoGuestMicrophoneRequests()
  }

  setLiveInfo(liveInfo: LiveInfo): void {
    if (this.liveInfo?.liveID === liveInfo.liveID) {
      this.liveInfo = liveInfo
      this.videoView.setLiveInfo(liveInfo)
      this.overlayView.updateLiveInfo(liveInfo)
      return
    }
    this.activeToast?.dismiss()
    this.backgroundCamera = undefined
    this.cameraRestoreID++
    this.clearBackgroundMicrophone()
    this.stopPlay()
    this.leaveChannelSilently()
    this.isJoinedChannel = false
    this.overlayView.prepareForReuse()
    this.overlayView.dismissInteractionOverlays(true)
    this.liveInfo = liveInfo
    this.videoView.setLiveInfo(liveInfo)
    this.overlayView.bind(liveInfo)
    this.overlayView.setJoinedChannel(this.isJoinedChannel)
    this.updateStatus(PlayerStatus.idle)
  }

  startPlay(): void {
    const liveID = this.liveInfo?.liveID ?? ''
    if (liveID.length === 0) {
      return
    }
    this.clearEndedState()
    if (this.playingLiveID === liveID) {
      return
    }
    this.stopPlay()
    this.playingLiveID = liveID
    this.player.setView(this.videoView.coreView)
    this.player.startPlay(`livekit://liveid=${liveID}`)
    if (!this.isJoinedChannel) {
      this.updateStatus(PlayerStatus.playing)
    }
  }

  stopPlay(): void {
    this.activeToast?.dismiss()
    if (this.playingLiveID === undefined) {
      return
    }
    this.player.stopPlay()
    this.playingLiveID = undefined
    if (this.status === PlayerStatus.playing) {
      this.updateStatus(PlayerStatus.idle)
    }
  }

  setVolume(volume: number): void {
    this.player.setVolume(volume)
  }

  joinChannel(): Promise<LiveInfo> {
    const liveInfo = this.liveInfo
    if (liveInfo === undefined) {
      return Promise.reject(new Error('noLiveInfo'))
    }
    if (this.isJoinedChannel) {
      return Promise.resolve(liveInfo)
    }
    const promise = new Promise<LiveInfo>((resolve: (liveInfo: LiveInfo) => void, reject: (error: Error) => void) =>
    this.pendingJoinCompletions.push(new PendingJoin(resolve, reject)))
    if (this.joiningLiveID === liveInfo.liveID) {
      return promise
    }
    this.joiningLiveID = liveInfo.liveID
    this.videoView.setLiveInfo(liveInfo)
    KeyMetrics.reportAtomicMetrics(KeyMetrics.liveIntegrationSuccessful)
    KeyMetrics.setComponent(KeyMetrics.componentLiveStream)
    this.player.joinChannel(liveInfo.liveID).then(() => {
      if (this.joiningLiveID === liveInfo.liveID && this.liveInfo?.liveID === liveInfo.liveID) {
        this.joiningLiveID = undefined
        this.handleJoinSuccess(liveInfo)
      }
    }).catch((error: Error) => {
      if (this.joiningLiveID === liveInfo.liveID && this.liveInfo?.liveID === liveInfo.liveID) {
        this.joiningLiveID = undefined
        this.isEntranceInitiatedJoin = false
        this.showSummaryView()
        this.drainPendingJoinCompletions(undefined, error)
      }
    })
    return promise
  }

  leaveChannel(): Promise<void> {
    this.activeToast?.dismiss()
    if (this.liveInfo?.liveID !== undefined && this.isJoinedChannel) {
      this.performLeave()
    }
    return Promise.resolve()
  }

  handleJoinLiveEntranceTap(): void {
    if (this.isJoinedChannel) {
      return
    }
    this.isPreviewEnabled = false
    this.isEntranceInitiatedJoin = true
    this.joinChannel().catch(() => {
    })
  }

  handleClose(): void {
    if (this.isClosing) {
      return
    }
    this.isClosing = true
    this.activeToast?.dismiss()
    this.leaveChannel().then(() => {
      dismissAllBottomSheets()
      this.isClosing = false
      this.onCloseClicked?.()
    })
  }

  private leaveChannelSilently(): void {
    if (this.isJoinedChannel && this.liveInfo?.liveID !== undefined) {
      this.performLeave()
    }
  }

  private performLeave(): void {
    this.activeToast?.dismiss()
    this.backgroundCamera = undefined
    this.cameraRestoreID++
    this.clearBackgroundMicrophone()
    this.overlayView.deactivateCoGuest()
    this.deactivateRoomFeatures()
    this.overlayView.setJoinedChannel(false)
    this.isJoinedChannel = false
    this.player.leaveChannel()
    if (this.status !== PlayerStatus.end) {
      this.updateStatus(this.playingLiveID !== undefined ? PlayerStatus.playing : PlayerStatus.idle)
    }
  }

  private handleJoinSuccess(liveInfo: LiveInfo): void {
    CoGuestStore.create(liveInfo.liveID).disconnect().catch(() => {
    })
    this.isJoinedChannel = true
    const entranceInitiated = this.isEntranceInitiatedJoin
    this.isEntranceInitiatedJoin = false
    this.activateRoomFeatures(liveInfo.liveID)
    this.overlayView.setJoinedChannel(true)
    this.overlayView.bind(liveInfo)
    this.updateStatus(PlayerStatus.inRoom)
    if (entranceInitiated) {
      this.onJoinLiveClicked?.()
    }
    this.drainPendingJoinCompletions(liveInfo)
  }

  private showSummaryView(reason: string = ''): void {
    if (this.liveInfo === undefined) {
      return
    }
    this.summaryReason = reason
    this.updateStatus(PlayerStatus.end)
  }

  private clearEndedState(): void {
    if (this.status === PlayerStatus.end) {
      this.updateStatus(this.playingLiveID !== undefined ? PlayerStatus.playing : PlayerStatus.idle)
    }
  }

  private handleLiveEnded(): void {
    if ((!this.isJoinedChannel && this.joiningLiveID === undefined && this.playingLiveID === undefined) ||
      this.status === PlayerStatus.end) {
      return
    }
    this.finishRoom()
    this.showSummaryView()
  }

  private handleKickedOut(reason: KickedOutReason): void {
    if (!this.isJoinedChannel && this.joiningLiveID === undefined) {
      return
    }
    const keys: string[] = ['removed', 'other_device', 'server', 'network', 'expired']
    const message = LiveKitResources.localizedString(`tuilivekit.player.interruption.${keys[reason] ?? 'removed'}`)
    this.finishRoom()
    this.showSummaryView(message)
    this.showToast(message)
  }

  private selfSeat(liveID: string): SeatUserInfo | undefined {
    const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    return userID.length === 0 ? undefined : CoGuestStore.create(liveID).coGuestState.connected.getAllData()
      .find((seat: SeatUserInfo) => seat.userID === userID)
  }

  private suspendCapture(): void {
    const liveID = this.liveInfo?.liveID
    if (!this.isAttached || !this.isJoinedChannel || this.status !== PlayerStatus.coGuest || liveID === undefined) {
      return
    }
    const seat = this.selfSeat(liveID)
    const state = DeviceStore.shared().state
    if (seat !== undefined && this.backgroundCamera === undefined && state.cameraStatus === DeviceStatus.on) {
      this.backgroundCamera = new BackgroundCamera(liveID, state.isFrontCamera)
    }
    this.cameraRestoreID++
    this.isCameraRestoring = false
    const wasOpening = this.overlayView.invalidateCoGuestCameraRequests(this.backgroundCamera !== undefined)
    if ((seat !== undefined && this.backgroundCamera !== undefined) || wasOpening) {
      DeviceStore.shared().closeLocalCamera()
    }
    this.microphoneRestoreID++
    this.isMicrophoneRestoring = false
    if (seat?.microphoneStatus === DeviceStatus.on) {
      this.backgroundMicrophone = this.backgroundMicrophone ?? liveID
      LiveSeatStore.create(liveID).muteMicrophone()
    }
  }

  private canRestore(liveID: string): boolean {
    return this.isAttached && this.isAppActive && this.isJoinedChannel && this.status === PlayerStatus.coGuest &&
      this.liveInfo?.liveID === liveID
  }

  private restoreCaptureIfNeeded(): void {
    const camera = this.backgroundCamera
    if (camera === undefined || this.isCameraRestoring || !this.canRestore(camera.liveID) ||
      this.selfSeat(camera.liveID) === undefined) {
      return
    }
    const operationID = ++this.cameraRestoreID
    this.isCameraRestoring = true
    BeautyPreferences.restore()
    DeviceStore.shared().openLocalCamera(camera.isFront).then(() => true).catch(() => false).then((isSuccess: boolean) => {
      if (this.cameraRestoreID !== operationID) {
        if (!this.isAppActive || (this.liveInfo?.liveID === camera.liveID &&
          (!this.isJoinedChannel || this.status !== PlayerStatus.coGuest))) {
          DeviceStore.shared().closeLocalCamera()
        }
        return
      }
      this.isCameraRestoring = false
      this.backgroundCamera = undefined
      if (!this.canRestore(camera.liveID) || this.selfSeat(camera.liveID) === undefined || !isSuccess) {
        DeviceStore.shared().closeLocalCamera()
      }
    })
  }

  private clearBackgroundMicrophone(): void {
    this.backgroundMicrophone = undefined
    this.microphoneRestoreID++
    this.isMicrophoneRestoring = false
  }

  private restoreMicrophoneIfNeeded(): void {
    const liveID = this.backgroundMicrophone
    if (liveID === undefined || this.isMicrophoneRestoring || !this.canRestore(liveID)) {
      return
    }
    const seat = this.selfSeat(liveID)
    if (seat === undefined) {
      return
    }
    if (!seat.allowOpenMicrophone) {
      this.clearBackgroundMicrophone()
      return
    }
    const operationID = ++this.microphoneRestoreID
    this.isMicrophoneRestoring = true
    LiveSeatStore.create(liveID).unmuteMicrophone().then(() => true).catch(() => false).then((isSuccess: boolean) => {
      if (this.microphoneRestoreID !== operationID) {
        if (this.backgroundMicrophone === liveID && !this.isAppActive) {
          LiveSeatStore.create(liveID).muteMicrophone()
        }
        return
      }
      this.isMicrophoneRestoring = false
      const currentSeat = this.selfSeat(liveID)
      if (!isSuccess || this.backgroundMicrophone !== liveID || !this.canRestore(liveID) ||
        currentSeat?.allowOpenMicrophone !== true) {
        this.clearBackgroundMicrophone()
        if (currentSeat !== undefined && this.liveInfo?.liveID === liveID && !this.isAppActive) {
          LiveSeatStore.create(liveID).muteMicrophone()
        }
        return
      }
      this.backgroundMicrophone = undefined
    })
  }

  private handleCoGuestUiState(uiState: CoGuestStatus): void {
    if (!this.isJoinedChannel) {
      return
    }
    if (uiState === CoGuestStatus.idle) {
      this.backgroundCamera = undefined
      this.cameraRestoreID++
      this.clearBackgroundMicrophone()
      if (this.status === PlayerStatus.coGuest) {
        this.updateStatus(PlayerStatus.inRoom)
      }
      return
    }
    this.updateStatus(PlayerStatus.coGuest)
    if (uiState === CoGuestStatus.coGuesting) {
      this.restoreMicrophoneIfNeeded()
    }
  }

  private updateStatus(newValue: PlayerStatus): void {
    if (newValue === PlayerStatus.idle || newValue === PlayerStatus.playing) {
      this.isPreviewEnabled = true
    }
    if (this.status === newValue) {
      return
    }
    this.status = newValue
    this.videoView.setPlayerStatus(newValue)
    this.statusListeners.forEach((listener: (status: PlayerStatus) => void) => listener(newValue))
  }

  private showToast(message: string): void {
    if (!this.isAttached) {
      return
    }
    this.activeToast?.dismiss()
    this.activeToast = LiveToast.show(message)
  }

  private finishRoom(): void {
    this.joiningLiveID = undefined
    this.backgroundCamera = undefined
    this.cameraRestoreID++
    this.clearBackgroundMicrophone()
    this.isJoinedChannel = false
    this.isEntranceInitiatedJoin = false
    this.stopPlay()
    this.overlayView.deactivateCoGuest()
    this.deactivateRoomFeatures()
    this.overlayView.setJoinedChannel(false)
    dismissAllBottomSheets()
    this.drainPendingJoinCompletions(undefined, new Error('roomEnded'))
  }

  private drainPendingJoinCompletions(liveInfo?: LiveInfo, error?: Error): void {
    const completions = this.pendingJoinCompletions
    this.pendingJoinCompletions = []
    completions.forEach((completion: PendingJoin) => liveInfo !== undefined ? completion.resolve(liveInfo) :
      completion.reject(error ?? new Error('joinFailed')))
  }

  private activateRoomFeatures(liveID: string): void {
    if (this.activatedRoomLiveID === liveID) {
      return
    }
    this.overlayView.activateRoomFeatures(liveID, this.liveInfo?.liveOwner.userID ?? '')
    this.activatedRoomLiveID = liveID
  }

  private deactivateRoomFeatures(): void {
    if (this.activatedRoomLiveID === undefined) {
      return
    }
    this.overlayView.deactivateRoomFeatures()
    this.activatedRoomLiveID = undefined
  }
}

@Component
export struct PlayerViewImpl {
  @ObjectLink controller: PlayerViewImplController
  @StorageProp(LiveKitSafeArea.topKey) safeTop: number = 0

  aboutToAppear(): void {
    LiveKitSafeArea.observe()
    this.controller.attach()
  }

  aboutToDisappear(): void {
    this.controller.detach()
  }

  private showsEntrance(): boolean {
    return this.controller.joinLiveEntranceEnabled &&
      (this.controller.status === PlayerStatus.idle || this.controller.status === PlayerStatus.playing)
  }

  private showsOverlay(): boolean {
    return this.controller.status === PlayerStatus.inRoom || this.controller.status === PlayerStatus.coGuest
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      if (this.controller.status !== PlayerStatus.end) {
        PlayerVideoView({ controller: this.controller.videoView })
      }
      LivingView({ controller: this.controller.overlayView, coGuest: this.controller.overlayView.coGuest })
        .visibility(this.showsOverlay() ? Visibility.Visible : Visibility.Hidden)
      if (this.showsEntrance() && this.controller.liveInfo !== undefined) {
        PreviewView({
          liveInfo: this.controller.liveInfo,
          isEnabled: this.controller.isPreviewEnabled,
          isShowing: this.showsEntrance(),
          onTapEnter: () => this.controller.handleJoinLiveEntranceTap(),
        })
      }
      if (this.controller.status === PlayerStatus.end && this.controller.liveInfo !== undefined) {
        SummaryView({ liveInfo: this.controller.liveInfo, reason: this.controller.summaryReason })
      }
      if (this.showsOverlay()) {
        Image(LiveKitResources.image('livekit_living_close'))
          .width(26)
          .height(26)
          .objectFit(ImageFit.Contain)
          .padding(5)
          .borderRadius(13)
          .borderWidth(1)
          .borderColor(white(0.08))
          .backgroundColor(LiveTheme.Color.overlay(0.22))
          .margin({ top: this.safeTop + 13, right: 12 })
          .zIndex(3)
          .accessibilityText(LiveKitResources.localizedString('tuilivekit.player.close_room'))
          .onClick(() => this.controller.handleClose())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(LiveTheme.Color.canvasBackground)
  }
}
