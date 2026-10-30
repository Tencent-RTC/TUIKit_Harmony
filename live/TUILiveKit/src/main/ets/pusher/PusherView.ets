import { abilityAccessCtrl, ApplicationStateChangeCallback, common, Permissions } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { thermal } from '@kit.BasicServicesKit'
import {
  AtomicPusher,
  CoGuestLayoutTemplate,
  AVStatistics,
  DeviceState,
  DeviceStatus,
  DeviceStore,
  EndedReason,
  KickedOutReason,
  LiveSeatStore,
  LoginEvent,
  LoginState,
  LoginStore,
  MirrorType,
  PusherCode,
  PusherConnectState,
  PusherInfo,
  PusherListener,
  PusherState,
  PusherSummary,
  SeatMode,
  UserProfile,
  VideoQuality,
} from '@tencentcloud/atomicxcore'
import { BeautyPanel, BeautyPreferences } from '../common/beauty/BeautyPanel'
import { KeyMetrics } from '../common/KeyMetrics'
import { LiveKitErrorText } from '../common/LiveKitErrorText'
import { LiveKitDataObserver, LiveKitResources, LiveKitSafeArea } from '../common/LiveKitResources'
import { LiveKitLog } from '../common/log/LiveKitLog'
import { LiveToast } from '../common/theme/LiveToastView'
import { black } from '../common/theme/LiveTheme'
import { PusherCoGuestStore, State as CoGuestState } from './living/coguest/PusherCoGuestStore'
import { PusherLivingView, PusherLivingViewController } from './living/PusherLivingView'
import { PusherDeviceStatusState, TemperatureStatus } from './living/status/PusherDeviceStatusView'
import { PusherPrepareView } from './prepare/PusherPrepareView'
import { AudioEffectState } from './settings/AudioEffectView'
import { PusherSettingsActionHandling, PusherSettingsState } from './settings/PusherSettingsActionHandling'
import { PusherSummaryContext, PusherSummaryView } from './summary/PusherSummaryView'
import { pusherVideoBottomInset, PusherVideoView, PusherVideoViewController } from './video/PusherVideoView'

@Observed
export class PusherPresentationState {
  @Track hostName: string = LiveKitResources.localizedString('tuilivekit.common.host')
  @Track hostAvatarURL: string = ''
  @Track settings: PusherSettingsState = new PusherSettingsState()
  @Track deviceStatus: PusherDeviceStatusState = new PusherDeviceStatusState()
}

enum Phase {
  prepare,
  living,
  summary,
}

class BackgroundDevices {
  camera: boolean
  microphone: boolean
  isFront: boolean

  constructor(camera: boolean, microphone: boolean, isFront: boolean) {
    this.camera = camera
    this.microphone = microphone
    this.isFront = isFront
  }
}

class SettingsActionHandler implements PusherSettingsActionHandling {
  private readonly onToggleMirror: () => void
  private readonly onSetCaptureVolume: (volume: number) => void

  constructor(onToggleMirror: () => void, onSetCaptureVolume: (volume: number) => void) {
    this.onToggleMirror = onToggleMirror
    this.onSetCaptureVolume = onSetCaptureVolume
  }

  toggleMirror(): void {
    this.onToggleMirror()
  }

  setCaptureVolume(volume: number): void {
    this.onSetCaptureVolume(volume)
  }
}

function temperatureStatus(level: thermal.ThermalLevel): TemperatureStatus {
  if (level <= thermal.ThermalLevel.NORMAL) {
    return TemperatureStatus.normal
  }
  return level === thermal.ThermalLevel.WARM ? TemperatureStatus.fair : TemperatureStatus.serious
}

@Component
export struct PusherView {
  @Provide('pusherAudioEffect') audioEffect: AudioEffectState = new AudioEffectState()
  liveID: string = ''
  onExit?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private phase: Phase = Phase.prepare
  @State private liveTitle: string = LiveKitResources.localizedString('tuilivekit.pusher.default_title')
  @State private coverURL: string = LiveKitResources.defaultCoverURL
  @State private presentationState: PusherPresentationState = new PusherPresentationState()
  @State private isBeautyPresented: boolean = false
  @State private isEndingLive: boolean = false
  @State private isCoGuestStageActive: boolean = false
  @State private prepareDeactivateToken: number = 0
  @State private summaryContext: PusherSummaryContext | undefined = undefined
  @State private summary: PusherSummary | undefined = undefined
  @State private videoController: PusherVideoViewController = new PusherVideoViewController()
  @State private livingController: PusherLivingViewController = new PusherLivingViewController('')
  @State @Watch('onDeviceStateChanged') private deviceState: DeviceState = new DeviceState()
  @State @Watch('onLoginStateChanged') private loginState: LoginState = new LoginState()
  @State @Watch('onPushStateChanged') private pushState: PusherState = new PusherState()
  private seatStore?: LiveSeatStore
  private coGuestStore?: PusherCoGuestStore
  private connectedGuestCount: number = 0
  private coGuestLayout: CoGuestLayoutTemplate = CoGuestLayoutTemplate.dynamicLayout
  private liveStartTime?: Date
  private liveEndTime?: Date
  private elapsedSeconds: number = 0
  private isPaused: boolean = false
  private pausedSeconds: number = 0
  private accumulatedPauseDuration: number = 0
  private pauseStartTime?: Date
  private elapsedTimer: number = -1
  private pauseTimer: number = -1
  private pushSessionID?: number
  private sessionSeed: number = 0
  private pusherListener?: PusherListener
  private isPusherAttached: boolean = false
  private hasConnected: boolean = false
  private interruptionMessage?: string
  private previewOperationID?: number
  private unmuteOperationID?: number
  private didInitializeAudioSettings: boolean = false
  private didInitializePreviewSettings: boolean = false
  private didStartPreview: boolean = false
  private isPreviewStarting: boolean = false
  private backgroundDevices?: BackgroundDevices
  private needsDeviceCleanup: boolean = false
  private didReleaseSession: boolean = false
  private didRequestExit: boolean = false
  private isApplicationActive: boolean = true
  private unobservers: (() => void)[] = []
  private applicationStateCallback?: ApplicationStateChangeCallback
  private readonly settingsActionHandler: PusherSettingsActionHandling = new SettingsActionHandler(
    () => this.toggleMirror(), (volume: number) => this.setCaptureVolume(volume))
  private readonly hostBackHandler = (liveID: string): void => {
    if (liveID === this.liveID && this.phase === Phase.summary) {
      this.exitPage()
    }
  }

  aboutToAppear(): void {
    // The demo host forwards its native back event; phase ownership stays here.
    const context = getContext(this) as common.UIAbilityContext
    context.eventHub.on('tuilivekit.pusher.hostBack', this.hostBackHandler)
    LiveKitSafeArea.observe()
    const seatStore = LiveSeatStore.create(this.liveID)
    this.seatStore = seatStore
    this.coGuestStore = new PusherCoGuestStore(this.liveID, seatStore)
    this.livingController = new PusherLivingViewController(this.liveID)
    this.updateHostProfile(LoginStore.shared().state.loginUserInfo)
    DeviceStore.shared().updateVideoQuality(VideoQuality.quality720P)
    this.presentationState.settings = this.makeSettingsState()
    this.presentationState.deviceStatus = this.makeDeviceStatusState(DeviceStore.shared().state as DeviceState)
    this.bindActions()
    this.bindState()
    this.deviceState = DeviceStore.shared().state as DeviceState
    this.loginState = LoginStore.shared().state as LoginState
    this.subscribeThermalState()
    this.subscribeAVStatistics()
    this.subscribeAccountEvents()
    this.subscribeCaptureLifecycle()
    AtomicPusher.shared().setView(this.videoController.coreView)
    this.isPusherAttached = true
    this.startPreviewIfNeeded()
  }

  aboutToDisappear(): void {
    const context = getContext(this) as common.UIAbilityContext
    context.eventHub.off('tuilivekit.pusher.hostBack', this.hostBackHandler)
    this.cleanupSession()
    this.summaryContext = undefined
  }

  private canCapture(): boolean {
    return this.isApplicationActive && !this.didReleaseSession && !this.isEndingLive && this.phase !== Phase.summary &&
      !this.isPaused
  }

  private bindActions(): void {
    const living = this.livingController
    living.onShowBeauty = () => this.showBeauty(Phase.living)
    living.onEnd = () => this.endLive()
    living.onToggleMute = () => this.toggleMute()
    living.onPause = () => this.pauseLive()
    living.onResume = () => this.resumeLive()
    living.onFlipCamera = () => this.switchCamera()
    living.settingsActionHandler = this.settingsActionHandler
    living.coGuestActionHandler = this.coGuestStore
    living.coGuestSmallWindowRegions = () => this.videoController.coGuestSmallWindowRegions()
    this.videoController.onCoGuestGeometryChanged = () => living.updateCommentWidth()
    living.onCoGuestStageTap = (x: number, y: number) => {
      const userID = this.videoController.coGuestUserID(x, y)
      if (userID === undefined) {
        return false
      }
      living.showCoGuestActions(userID)
      return true
    }
  }

  private bindState(): void {
    const coGuestStore = this.coGuestStore!
    coGuestStore.onToast = (message: string) => {
      if (this.phase === Phase.living && !this.isEndingLive && !this.didReleaseSession) {
        LiveToast.show(message)
      }
    }
    coGuestStore.onStateChanged = (state: CoGuestState) => {
      if (this.connectedGuestCount !== state.connected.length ||
        this.coGuestLayout.templateId !== state.layout.templateId) {
        this.connectedGuestCount = state.connected.length
        this.coGuestLayout = state.layout
        this.updateCoGuestPresentation()
      }
      this.livingController.updateCoGuest(state)
    }
    this.render()
  }

  private showBeauty(requestedPhase: Phase): void {
    if (this.isEndingLive || this.didReleaseSession || this.phase !== requestedPhase || this.isBeautyPresented) {
      return
    }
    this.isBeautyPresented = true
  }

  private render(): void {
    this.isBeautyPresented = false
    this.updateCoGuestPresentation()
    if (this.phase !== Phase.living) {
      this.livingController.resetAudienceWelcomes()
    }
    if (this.phase === Phase.living) {
      this.livingController.updateHost(this.presentationState.hostName, this.presentationState.hostAvatarURL)
      this.livingController.updateElapsedSeconds(this.elapsedSeconds)
      this.livingController.updatePause(this.isPaused, this.pausedSeconds)
    }
    this.updateSettings()
    this.updateDeviceStatus()
    if (this.phase === Phase.summary) {
      const context = new PusherSummaryContext()
      context.startTime = this.liveStartTime
      context.endTime = this.liveEndTime ?? new Date()
      context.pausedSeconds = Math.floor(this.accumulatedPauseDuration + this.currentPauseDuration())
      context.interruptionMessage = this.interruptionMessage
      this.summaryContext = context
    } else {
      this.summaryContext = undefined
    }
  }

  private updateHostProfile(profile: UserProfile | undefined): void {
    const nickname = (profile?.nickname ?? '').trim()
    const name =
      nickname.length === 0 ? (profile?.userID ?? LiveKitResources.localizedString('tuilivekit.common.host')) :
        nickname
    const avatarURL = profile?.avatarURL ?? ''
    if (this.presentationState.hostName === name && this.presentationState.hostAvatarURL === avatarURL) {
      return
    }
    this.presentationState.hostName = name
    this.presentationState.hostAvatarURL = avatarURL
    if (this.phase === Phase.living) {
      this.livingController.updateHost(name, avatarURL)
    }
  }

  private updateSettings(): void {
    const settings = this.presentationState.settings
    this.presentationState.settings = new PusherSettingsState(settings.isMirrorEnabled, settings.isMuted,
      settings.captureVolume)
    if (this.phase === Phase.living) {
      this.livingController.updateSettings(this.presentationState.settings)
    }
  }

  private updateDeviceStatus(): void {
    if (this.phase === Phase.living) {
      this.livingController.updateDeviceStatus(this.presentationState.deviceStatus,
        this.presentationState.settings.isMuted, this.presentationState.settings.captureVolume)
    }
  }

  private updateCoGuestPresentation(): void {
    const isLiving = this.phase === Phase.living
    this.isCoGuestStageActive = isLiving && (this.connectedGuestCount > 0 ||
      this.coGuestLayout.templateId !== CoGuestLayoutTemplate.floatLayout.templateId)
    this.videoController.updateCoGuestVideoState(isLiving, this.coGuestLayout, this.connectedGuestCount)
    this.livingController.setCoGuestStageActive(this.isCoGuestStageActive)
  }

  private updateCoverURL(value: string): void {
    if (LiveKitResources.presetCoverURLs.includes(value) && this.coverURL !== value) {
      this.coverURL = value
    }
  }

  private startPreviewIfNeeded(): void {
    if (!this.canCapture() || this.didStartPreview || this.isPreviewStarting) {
      return
    }
    if (!this.didInitializeAudioSettings) {
      this.didInitializeAudioSettings = true
      this.audioEffect.resetForNewSession()
      this.setCaptureVolume(100)
    }
    const operationID = ++this.sessionSeed
    this.previewOperationID = operationID
    this.isPreviewStarting = true
    if (this.backgroundDevices?.camera === false) {
      this.requestMicrophoneAccess(operationID)
      return
    }
    this.requestAccess('ohos.permission.CAMERA', (granted: boolean) => {
      if (!this.validatePreviewOperation(operationID)) {
        return
      }
      if (!granted) {
        this.finishPreview()
        return
      }
      const isFront = this.backgroundDevices?.isFront ??
        (this.didInitializePreviewSettings ? DeviceStore.shared().state.isFrontCamera : true)
      if (!this.didInitializePreviewSettings) {
        this.didInitializePreviewSettings = true
        DeviceStore.shared().switchMirror(MirrorType.enable)
        this.presentationState.settings.isMirrorEnabled = true
        this.updateSettings()
      }
      BeautyPreferences.restore()
      this.needsDeviceCleanup = true
      DeviceStore.shared().openLocalCamera(isFront).then(() => {
        if (this.validatePreviewOperation(operationID)) {
          this.requestMicrophoneAccess(operationID)
        }
      }).catch(() => {
        if (this.validatePreviewOperation(operationID)) {
          this.finishPreview()
        }
      })
    })
  }

  private requestMicrophoneAccess(operationID: number): void {
    if (!this.validatePreviewOperation(operationID)) {
      return
    }
    if (this.backgroundDevices?.microphone === false) {
      this.finishPreview()
      this.didStartPreview = true
      this.backgroundDevices = undefined
      return
    }
    this.requestAccess('ohos.permission.MICROPHONE', (granted: boolean) => {
      if (!this.validatePreviewOperation(operationID)) {
        return
      }
      if (!granted) {
        this.finishPreview()
        return
      }
      this.needsDeviceCleanup = true
      if (this.presentationState.settings.isMuted) {
        this.seatStore?.muteMicrophone()
      }
      const completion = (isSuccess: boolean): void => {
        if (!this.didReleaseSession && (this.isPaused || !this.isApplicationActive)) {
          this.seatStore?.muteMicrophone()
        }
        if (!this.validatePreviewOperation(operationID)) {
          return
        }
        this.previewOperationID = undefined
        this.isPreviewStarting = false
        if (isSuccess) {
          this.didStartPreview = true
          this.backgroundDevices = undefined
          if (this.presentationState.settings.isMuted) {
            this.seatStore?.muteMicrophone()
          }
        }
      }
      let request: Promise<void> | undefined = undefined
      if (DeviceStore.shared().state.microphoneStatus === DeviceStatus.on) {
        request = this.presentationState.settings.isMuted ? undefined : this.seatStore?.unmuteMicrophone()
      } else {
        request = DeviceStore.shared().openLocalMicrophone()
      }
      if (request === undefined) {
        completion(true)
      } else {
        request.then(() => completion(true)).catch(() => completion(false))
      }
    })
  }

  private requestAccess(permission: Permissions, completion: (granted: boolean) => void): void {
    const context = getContext(this) as common.UIAbilityContext
    abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [permission])
      .then((result) => completion(result.authResults[0] === 0)).catch(() => completion(false))
  }

  private validatePreviewOperation(operationID: number): boolean {
    if (this.previewOperationID !== operationID) {
      return false
    }
    if (!this.canCapture()) {
      this.finishPreview()
      return false
    }
    return true
  }

  private finishPreview(): void {
    this.previewOperationID = undefined
    this.isPreviewStarting = false
  }

  private stopPreview(closeMicrophone: boolean = false): void {
    this.previewOperationID = undefined
    if (this.needsDeviceCleanup) {
      DeviceStore.shared().closeLocalCamera()
      if (closeMicrophone) {
        this.needsDeviceCleanup = false
        DeviceStore.shared().closeLocalMicrophone()
      } else {
        this.seatStore?.muteMicrophone()
      }
    }
    this.didStartPreview = false
    this.isPreviewStarting = false
  }

  private switchCamera(): void {
    DeviceStore.shared().switchCamera(!DeviceStore.shared().state.isFrontCamera)
  }

  private refreshSettings(): void {
    this.presentationState.settings = this.makeSettingsState()
    this.updateSettings()
    this.updateDeviceStatus()
  }

  private toggleMirror(): void {
    const enabled = DeviceStore.shared().state.localMirrorType !== MirrorType.disable
    DeviceStore.shared().switchMirror(enabled ? MirrorType.disable : MirrorType.enable)
    this.presentationState.settings.isMirrorEnabled = !enabled
    this.updateSettings()
  }

  private toggleMute(): void {
    if (this.phase !== Phase.living || this.isPaused || this.isEndingLive || this.didReleaseSession ||
      this.unmuteOperationID !== undefined) {
      return
    }
    const wasMuted = this.presentationState.settings.isMuted
    this.presentationState.settings.isMuted = !wasMuted
    this.updateSettings()
    this.updateDeviceStatus()
    if (!wasMuted) {
      this.seatStore?.muteMicrophone()
      return
    }
    const operationID = ++this.sessionSeed
    this.unmuteOperationID = operationID
    const finish = (isSuccess: boolean): void => {
      if (!this.didReleaseSession && (this.isPaused || !this.isApplicationActive)) {
        this.seatStore?.muteMicrophone()
      }
      if (this.unmuteOperationID !== operationID) {
        return
      }
      this.unmuteOperationID = undefined
      if (this.phase !== Phase.living || this.isEndingLive || this.didReleaseSession || isSuccess) {
        return
      }
      this.presentationState.settings.isMuted = wasMuted
      this.updateSettings()
      this.updateDeviceStatus()
      LiveToast.show(LiveKitResources.localizedString('tuilivekit.pusher.error.mute_switch_failed'))
    }
    this.seatStore?.unmuteMicrophone().then(() => finish(true)).catch(() => finish(false))
  }

  private setCaptureVolume(volume: number): void {
    const value = Math.min(100, Math.max(0, volume))
    DeviceStore.shared().setCaptureVolume(value)
    this.presentationState.settings.captureVolume = value
    this.updateSettings()
    this.updateDeviceStatus()
  }

  private startLive(title: string): void {
    if (this.phase !== Phase.prepare || this.didReleaseSession || !this.isPusherAttached ||
      this.pushSessionID !== undefined) {
      return
    }
    this.liveTitle = title
    if (this.liveID.length === 0 || new util.TextEncoder().encodeInto(this.liveID).length > 48) {
      LiveToast.show(LiveKitResources.localizedString('tuilivekit.pusher.error.start_failed'))
      return
    }
    this.enterLivingPhase()
    this.requestStartLive()
  }

  private enterLivingPhase(): void {
    this.livingController.activateAudience()
    this.livingController.activateLikes()
    this.livingController.activateComments()
    this.livingController.activateMusic()
    this.coGuestStore?.activate()
    this.liveStartTime = new Date()
    this.liveEndTime = undefined
    this.elapsedSeconds = 0
    this.isPaused = false
    this.pausedSeconds = 0
    this.accumulatedPauseDuration = 0
    this.pauseStartTime = undefined
    this.phase = Phase.living
    this.render()
    this.elapsedTimer = setInterval(() => {
      if (this.phase !== Phase.living || this.isEndingLive || this.didReleaseSession) {
        return
      }
      this.updateElapsedTime()
      this.livingController.updateElapsedSeconds(this.elapsedSeconds)
    }, 1000)
  }

  private requestStartLive(): void {
    if (this.pushSessionID !== undefined || !this.isPusherAttached) {
      return
    }
    const sessionID = ++this.sessionSeed
    this.pushSessionID = sessionID
    this.hasConnected = false
    this.pushState = AtomicPusher.shared().getState()
    const listener = new PusherListener(
      (code: PusherCode, message: string) => {
        if (this.pushSessionID === sessionID) {
          this.handlePushError(code, message)
        }
      },
      (reason: EndedReason, summary: PusherSummary | undefined) => {
        if (this.pushSessionID === sessionID) {
          this.handleLiveEnded(reason, summary)
        }
      },
      (reason: KickedOutReason, message: string) => {
        if (this.pushSessionID === sessionID) {
          this.handleKickedOut(reason)
        }
      })
    this.pusherListener = listener
    AtomicPusher.shared().addListener(listener)
    KeyMetrics.reportAtomicMetrics(KeyMetrics.liveIntegrationSuccessful)
    KeyMetrics.setComponent(KeyMetrics.componentLiveStream)
    const title = this.liveTitle.trim()
    const config = new PusherInfo()
    config.liveID = this.liveID
    config.liveName = title.length === 0 ? LiveKitResources.localizedString('tuilivekit.pusher.default_title') : title
    config.coverURL = this.coverURL
    config.backgroundURL = 'https://liteav.sdk.qcloud.com/app/res/picture/livekit/coGuestBackGroud.png'
    config.isPublicVisible = true
    AtomicPusher.shared().startPush(config)
  }

  private onPushStateChanged(): void {
    const state = this.pushState
    if (this.pushSessionID === undefined || this.phase !== Phase.living || this.isEndingLive ||
      this.didReleaseSession ||
      state.pusherInfo.liveID !== this.liveID) {
      return
    }
    if (state.networkState === PusherConnectState.CONNECTED && !this.hasConnected) {
      this.hasConnected = true
      const sessionID = this.pushSessionID
      this.seatStore?.setSeatMode(SeatMode.APPLY).catch((error: Error) => {
        if (this.pushSessionID === sessionID && this.phase === Phase.living && !this.isEndingLive &&
          !this.didReleaseSession) {
          LiveToast.show(LiveKitErrorText.message(error))
        }
      })
      this.coGuestStore?.didConnect()
      this.livingController.refreshAudience()
    }
    const statistics = state.statistics
    const status = this.presentationState.deviceStatus.copy()
    status.videoBitrate = Math.max(0, statistics.videoBitrate)
    status.videoWidth = Math.max(0, statistics.videoWidth)
    status.videoHeight = Math.max(0, statistics.videoHeight)
    status.frameRate = Math.max(0, statistics.videoFps)
    status.audioBitrate = Math.max(0, statistics.audioBitrate)
    status.hasAVStatistics = state.networkState === PusherConnectState.CONNECTED
    this.applyDeviceStatus(status)
  }

  private handlePushError(code: PusherCode, message: string): void {
    if (this.didReleaseSession || this.phase !== Phase.living || code === PusherCode.OK) {
      return
    }
    LiveKitLog.error(`[PusherView] push failed liveID=${this.liveID} code=${code} message=${message}`)
    const text = PusherView.pushErrorMessage(code, message)
    if (code === PusherCode.ERROR_START_PUSH_REQUEST_FAILED && !this.hasConnected && !this.isEndingLive) {
      this.returnToPrepareAfterStartFailure()
    }
    LiveToast.show(text)
  }

  private handleLiveEnded(reason: EndedReason, summary: PusherSummary | undefined): void {
    if (this.didReleaseSession) {
      return
    }
    this.summary = summary
    this.removePusherListener()
    if (this.phase !== Phase.living) {
      return
    }
    if (this.isEndingLive) {
      this.settleLive()
      return
    }
    this.interrupt(reason === EndedReason.ENDED_BY_SERVER ? 'server' : 'ended')
  }

  private handleKickedOut(reason: KickedOutReason): void {
    if (this.didReleaseSession || this.phase !== Phase.living) {
      return
    }
    this.interrupt(['admin', 'other_device', 'server', 'network', 'expired'][reason] ?? 'ended')
  }

  private interrupt(reasonKey: string): void {
    this.interruptionMessage = LiveKitResources.localizedString('tuilivekit.pusher.interruption.' + reasonKey)
    this.removePusherListener()
    this.settleLive()
  }

  private static pushErrorMessage(code: PusherCode, message: string): string {
    let key = 'operation_failed'
    if (code === PusherCode.ERROR_START_PUSH_REQUEST_FAILED || code === PusherCode.ERROR_UPDATE_CONFIG_REQUEST_FAILED) {
      const isContentRejected = /^\s*error_code:\s*100026(?:\s*[,|]|\s*$)/.test(message)
      key = isContentRejected ? 'content_rejected' :
        (code === PusherCode.ERROR_START_PUSH_REQUEST_FAILED ? 'start_failed' : 'update_failed')
    }
    return LiveKitResources.localizedString(`tuilivekit.pusher.error.${key}`)
  }

  private returnToPrepareAfterStartFailure(): void {
    this.removePusherListener()
    this.unmuteOperationID = undefined
    this.phase = Phase.prepare
    clearInterval(this.elapsedTimer)
    this.elapsedTimer = -1
    this.finishPause()
    this.liveStartTime = undefined
    this.liveEndTime = undefined
    this.elapsedSeconds = 0
    this.accumulatedPauseDuration = 0
    this.interruptionMessage = undefined
    this.livingController.resetAfterStartFailure()
    this.coGuestStore?.deactivate()
    this.prepareDeactivateToken++
    this.render()
    this.startPreviewIfNeeded()
  }

  private subscribeAccountEvents(): void {
    this.unobservers.push(LoginStore.shared().loginEventEmitter.subscribe(this, (event: LoginEvent) => {
      if (event !== LoginEvent.KICKED_OFFLINE || this.didReleaseSession) {
        return
      }
      if (this.phase === Phase.living) {
        this.interruptionMessage = LiveKitResources.localizedString('tuilivekit.pusher.interruption.account')
        this.endLive()
      } else if (this.phase === Phase.prepare) {
        setTimeout(() => this.exitPage(), 0)
      }
    }))
  }

  private onLoginStateChanged(): void {
    if (!this.didReleaseSession) {
      this.updateHostProfile(this.loginState.loginUserInfo)
    }
  }

  private removePusherListener(): void {
    this.pushSessionID = undefined
    if (this.pusherListener !== undefined) {
      AtomicPusher.shared().removeListener(this.pusherListener)
      this.pusherListener = undefined
    }
  }

  private releasePusher(): void {
    const hadSession = this.pushSessionID !== undefined
    this.removePusherListener()
    if (!this.isPusherAttached) {
      return
    }
    this.isPusherAttached = false
    if (hadSession && this.phase === Phase.living && !this.isEndingLive) {
      AtomicPusher.shared().stopPush()
    }
    AtomicPusher.shared().release()
  }

  private pauseLive(): void {
    if (this.phase !== Phase.living || this.isEndingLive || this.didReleaseSession || this.isPaused) {
      return
    }
    this.pauseStartTime = new Date()
    this.isPaused = true
    this.updateElapsedTime()
    this.livingController.updateElapsedSeconds(this.elapsedSeconds)
    this.backgroundDevices = undefined
    this.pausedSeconds = 0
    this.livingController.pauseComments()
    this.stopPreview()
    this.livingController.updatePause(this.isPaused, this.pausedSeconds)
    this.pauseTimer = setInterval(() => {
      if (this.isPaused) {
        this.pausedSeconds = Math.floor(this.currentPauseDuration())
        this.livingController.updatePause(this.isPaused, this.pausedSeconds)
      }
    }, 1000)
  }

  private resumeLive(): void {
    if (this.phase !== Phase.living || this.isEndingLive || this.didReleaseSession || !this.isPaused) {
      return
    }
    this.finishPause()
    this.livingController.resumeComments()
    this.startPreviewIfNeeded()
    this.livingController.updatePause(this.isPaused, this.pausedSeconds)
  }

  private endLive(): void {
    if (this.phase !== Phase.living || this.isEndingLive || this.didReleaseSession) {
      return
    }
    this.isEndingLive = true
    this.isBeautyPresented = false
    AtomicPusher.shared().stopPush()
  }

  private finishLivePresentation(): void {
    if (this.liveEndTime !== undefined) {
      return
    }
    this.livingController.deactivateAudience(false)
    this.livingController.deactivateLikes(false)
    this.livingController.deactivateComments(false)
    this.livingController.deactivateMusic()
    this.coGuestStore?.deactivate()
    this.finishPause()
    clearInterval(this.elapsedTimer)
    this.elapsedTimer = -1
    this.liveEndTime = new Date()
    this.updateElapsedTime()
  }

  private settleLive(): void {
    if (this.phase !== Phase.living || this.didReleaseSession) {
      return
    }
    this.finishLivePresentation()
    this.phase = Phase.summary
    this.render()
    this.cleanupSession()
  }

  private exitPage(): void {
    if (this.didRequestExit) {
      return
    }
    this.didRequestExit = true
    this.cleanupSession()
    this.onExit?.()
  }

  private cleanupSession(): void {
    if (this.didReleaseSession) {
      return
    }
    this.didReleaseSession = true
    this.backgroundDevices = undefined
    this.previewOperationID = undefined
    this.unmuteOperationID = undefined
    this.isBeautyPresented = false
    this.prepareDeactivateToken++
    if (this.phase === Phase.living) {
      this.finishLivePresentation()
    }
    this.livingController.deactivateAudience(true)
    this.livingController.deactivateLikes(true)
    this.livingController.deactivateComments(true)
    this.livingController.deactivateMusic()
    this.coGuestStore?.deactivate()
    this.unobservers.forEach((unobserve: () => void) => unobserve())
    this.unobservers = []
    if (this.applicationStateCallback !== undefined) {
      getContext(this).getApplicationContext().off('applicationStateChange', this.applicationStateCallback)
      this.applicationStateCallback = undefined
    }
    try {
      thermal.unregisterThermalLevelCallback()
    } catch (error) {
    }
    this.stopPreview(true)
    this.releasePusher()
    this.videoController.coGuestSeatViewProvider.release()
    this.invalidateLifecycle()
    this.isEndingLive = false
  }

  private makeSettingsState(): PusherSettingsState {
    const deviceState = DeviceStore.shared().state
    return new PusherSettingsState(deviceState.localMirrorType !== MirrorType.disable,
      this.presentationState.settings.isMuted, deviceState.captureVolume)
  }

  private makeDeviceStatusState(deviceState: DeviceState): PusherDeviceStatusState {
    const status = this.presentationState.deviceStatus.copy()
    status.cameraStatus = deviceState.cameraStatus
    status.microphoneStatus = deviceState.microphoneStatus
    status.cameraError = deviceState.cameraLastError
    status.microphoneError = deviceState.microphoneLastError
    status.temperatureStatus = temperatureStatus(thermal.getLevel())
    status.networkKind = deviceState.networkType
    status.networkQuality = deviceState.networkInfo.quality
    status.delay = deviceState.networkInfo.delay
    status.downLoss = deviceState.networkInfo.downLoss
    status.upLoss = deviceState.networkInfo.upLoss
    return status
  }

  private applyDeviceStatus(status: PusherDeviceStatusState): void {
    if (status.equals(this.presentationState.deviceStatus)) {
      return
    }
    this.presentationState.deviceStatus = status
    this.updateDeviceStatus()
  }

  private subscribeThermalState(): void {
    try {
      thermal.registerThermalLevelCallback((level: thermal.ThermalLevel) => {
        const status = this.presentationState.deviceStatus.copy()
        status.temperatureStatus = temperatureStatus(level)
        this.applyDeviceStatus(status)
      })
    } catch (error) {
    }
  }

  private onDeviceStateChanged(): void {
    if (this.didReleaseSession) {
      return
    }
    this.videoController.updateLocalCameraStatus(this.deviceState.cameraStatus)
    this.applyDeviceStatus(this.makeDeviceStatusState(this.deviceState))
  }

  private subscribeAVStatistics(): void {
    const avStatistics = this.seatStore!.liveSeatState.avStatistics
    this.unobservers.push(LiveKitDataObserver.observe(avStatistics, () => {
      if (this.didReleaseSession) {
        return
      }
      const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
      const list = avStatistics.getAllData()
      const statistics = list.find((item: AVStatistics) => item.userID === userID) ??
        list.find((item: AVStatistics) => item.userID.length === 0)
      const status = this.presentationState.deviceStatus.copy()
      status.audioSampleRate = statistics?.audioSampleRate ?? 0
      this.applyDeviceStatus(status)
    }))
  }

  private subscribeCaptureLifecycle(): void {
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => {
        this.isApplicationActive = true
        this.startPreviewIfNeeded()
      },
      onApplicationBackground: () => {
        this.isApplicationActive = false
        this.prepareDeactivateToken++
        this.suspendCapture()
      },
    }
    this.applicationStateCallback = callback
    getContext(this).getApplicationContext().on('applicationStateChange', callback)
  }

  private suspendCapture(): void {
    if (this.didReleaseSession) {
      return
    }
    if (this.backgroundDevices === undefined && !this.isPaused && this.phase !== Phase.summary &&
      (this.didStartPreview || this.isPreviewStarting || this.needsDeviceCleanup)) {
      const state = DeviceStore.shared().state
      this.backgroundDevices = new BackgroundDevices(state.cameraStatus === DeviceStatus.on || this.isPreviewStarting,
        state.microphoneStatus === DeviceStatus.on || this.isPreviewStarting,
        this.didInitializePreviewSettings ? state.isFrontCamera : true)
    }
    this.stopPreview()
  }

  private updateElapsedTime(): void {
    if (this.liveStartTime === undefined) {
      return
    }
    const endTime = (this.isPaused ? this.pauseStartTime : this.liveEndTime) ?? new Date()
    this.elapsedSeconds = Math.max(0,
      Math.floor((endTime.getTime() - this.liveStartTime.getTime()) / 1000 - this.accumulatedPauseDuration))
  }

  private currentPauseDuration(): number {
    if (!this.isPaused || this.pauseStartTime === undefined) {
      return 0
    }
    return Math.max(0, (Date.now() - this.pauseStartTime.getTime()) / 1000)
  }

  private finishPause(): void {
    clearInterval(this.pauseTimer)
    this.pauseTimer = -1
    this.accumulatedPauseDuration += this.currentPauseDuration()
    this.pauseStartTime = undefined
    this.pausedSeconds = 0
    this.isPaused = false
  }

  private invalidateLifecycle(): void {
    this.removePusherListener()
    clearInterval(this.elapsedTimer)
    this.elapsedTimer = -1
    clearInterval(this.pauseTimer)
    this.pauseTimer = -1
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isCoGuestStageActive) {
        Image(LiveKitResources.image('livekit_pusher_coguest_background'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
          .hitTestBehavior(HitTestMode.None)
      }
      if (this.phase !== Phase.summary) {
        PusherVideoView({ controller: this.videoController })
          .width('100%')
          .height(`calc(100% - ${pusherVideoBottomInset}vp)`)
          .borderRadius(16)
          .clip(true)
      }
      if (this.phase === Phase.prepare) {
        PusherPrepareView({
          title: this.liveTitle,
          coverURL: this.coverURL,
          settings: this.presentationState.settings,
          deactivateToken: this.prepareDeactivateToken,
          settingsActionHandler: this.settingsActionHandler,
          onExit: () => this.exitPage(),
          onCountdownFinished: (title: string) => this.startLive(title),
          onSelectCover: (url: string) => this.updateCoverURL(url),
          onTitleChanged: (title: string) => {
            if (this.phase === Phase.prepare && !this.didReleaseSession) {
              this.liveTitle = title
            }
          },
          onFlipCamera: () => this.switchCamera(),
          onShowBeauty: () => this.showBeauty(Phase.prepare),
          onRefreshSettings: () => this.refreshSettings(),
        })
      }
      if (this.phase === Phase.living) {
        PusherLivingView({ controller: this.livingController })
      }
      if (this.phase === Phase.summary) {
        PusherSummaryView({
          context: this.summaryContext,
          summary: this.summary,
          onExit: () => this.exitPage(),
        })
      }
      BeautyPanel({ isPresented: this.isBeautyPresented, onDismiss: () => this.isBeautyPresented = false })
      if (this.isEndingLive) {
        Column({ space: 16 }) {
          LoadingProgress().width(48).height(48).color(Color.White)
          Text(LiveKitResources.localizedString('tuilivekit.pusher.ending'))
            .fontSize(16)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .padding({ left: 24, right: 24 })
        }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(black(0.55))
      }
    }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
  }
}
