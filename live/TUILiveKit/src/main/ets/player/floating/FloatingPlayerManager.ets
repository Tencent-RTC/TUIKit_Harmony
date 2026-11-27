import PiPWindow from '@ohos.PiPWindow'
import { UIContext } from '@ohos.arkui.UIContext'
import { window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LoginStore } from '@tencentcloud/atomicxcore'
import { LiveKitLog } from '../../common/log/LiveKitLog'
import { PlayerStatus, PlayerViewController } from '../PlayerView'
import { FloatingContent } from './FloatingPlayerView'

export interface FloatingPlayerHost {
  onStarted: (liveID: string) => void
  onRestore: (liveID: string, restoreID: string) => void
}

type FloatingDismissListener = (liveID: string) => void

export class PlayerPageRoute {
  readonly pageID: string = util.generateRandomUUID(true)
  readonly liveID: string
  readonly autoEnterRoom: boolean
  readonly restoreID: string

  constructor(liveID: string = '', autoEnterRoom: boolean = false, restoreID: string = '') {
    this.liveID = liveID
    this.autoEnterRoom = autoEnterRoom
    this.restoreID = restoreID
  }
}

class PlayerNavigation {
  readonly stack: NavPathStack
  readonly routeName: string
  readonly isAvailable: () => boolean
  readonly onPlayerPageChanged?: (visible: boolean) => void
  isOpening: boolean = false
  revision: number = 0

  constructor(stack: NavPathStack, routeName: string, isAvailable: () => boolean,
    onPlayerPageChanged?: (visible: boolean) => void) {
    this.stack = stack
    this.routeName = routeName
    this.isAvailable = isAvailable
    this.onPlayerPageChanged = onPlayerPageChanged
  }

  isCurrent(route: PlayerPageRoute): boolean {
    const index = this.stack.size() - 1
    if (index < 0 || this.stack.getAllPathName()[index] !== this.routeName) return false
    const current = this.stack.getParamByIndex(index) as PlayerPageRoute | undefined
    return current?.pageID === route.pageID
  }

  notifyPlayerPageHidden(): void {
    const revision = this.revision
    setTimeout(() => {
      if (FloatingPlayerManager.isNavigation(this) && this.revision === revision) {
        this.onPlayerPageChanged?.(false)
      }
    }, 800)
  }
}

enum Phase {
  starting,
  floating,
  restoring,
}

class FloatingSession {
  readonly restoreID: string = util.generateRandomUUID(true)
  readonly userID: string = LoginStore.shared().state.loginUserInfo?.userID ?? ''
  readonly liveID: string
  readonly player: PlayerViewController
  phase: Phase = Phase.starting
  handedOver: boolean = false
  viewBindingAttempted: boolean = false
  cancelled: boolean = false
  isFloating: boolean = false
  wasFloating: boolean = false
  creating?: Promise<PiPWindow.PiPController>
  starting?: Promise<void>
  clearing?: Promise<void>
  disposing?: Promise<void>
  content?: FloatingContent
  pip?: PiPWindow.PiPController
  stopObserving?: () => void
  resolveStarted?: (started: boolean) => void

  constructor(player: PlayerViewController) {
    this.player = player
    this.liveID = player.liveID ?? ''
  }
}

export class FloatingPlayerManager {
  private static host?: FloatingPlayerHost
  private static session?: FloatingSession
  private static stopping?: Promise<void>
  private static navigation?: PlayerNavigation
  private static dismissListeners: FloatingDismissListener[] = []
  private static pendingDismissLiveID: string = ''
  private static dismissRevision: number = 0

  static isNavigation(navigation: PlayerNavigation): boolean {
    return FloatingPlayerManager.navigation === navigation
  }

  static isFloating(liveID: string = ''): boolean {
    const session = FloatingPlayerManager.session
    return session !== undefined && session.isFloating && !session.cancelled &&
      (liveID.length === 0 || session.liveID === liveID)
  }

  static addFloatingDismissListener(listener: FloatingDismissListener): () => void {
    FloatingPlayerManager.dismissListeners.push(listener)
    return () => {
      FloatingPlayerManager.dismissListeners =
        FloatingPlayerManager.dismissListeners.filter((item: FloatingDismissListener) => item !== listener)
    }
  }

  private static cancelFloatingDismiss(): void {
    FloatingPlayerManager.dismissRevision++
    FloatingPlayerManager.pendingDismissLiveID = ''
  }

  private static scheduleFloatingDismiss(liveID: string): void {
    if (liveID.length === 0) return
    const revision = ++FloatingPlayerManager.dismissRevision
    FloatingPlayerManager.pendingDismissLiveID = liveID
    setTimeout(() => {
      if (revision !== FloatingPlayerManager.dismissRevision || FloatingPlayerManager.isFloating()) return
      const pending = FloatingPlayerManager.pendingDismissLiveID
      FloatingPlayerManager.pendingDismissLiveID = ''
      if (pending.length === 0) return
      FloatingPlayerManager.dismissListeners.forEach((listener: FloatingDismissListener) => listener(pending))
    }, 800)
  }

  static bindNavigation(stack: NavPathStack, isAvailable: () => boolean, routeName: string = 'player',
    onPlayerPageChanged?: (visible: boolean) => void): () => void {
    const navigation = new PlayerNavigation(stack, routeName, isAvailable, onPlayerPageChanged)
    FloatingPlayerManager.navigation = navigation
    const unbind = FloatingPlayerManager.bindHost({
      onStarted: (liveID: string) => {
        if (FloatingPlayerManager.navigation !== navigation || !navigation.isAvailable() ||
          navigation.stack.getAllPathName()[navigation.stack.size() - 1] !== navigation.routeName) {
          throw new Error('playerNotVisible')
        }
        navigation.notifyPlayerPageHidden()
        navigation.stack.pop({})
      },
      onRestore: (liveID: string, restoreID: string) => {
        if (FloatingPlayerManager.navigation !== navigation || !navigation.isAvailable() ||
          navigation.isOpening || navigation.stack.size() > 0) throw new Error('playerRestoreUnavailable')
        const route = new PlayerPageRoute(liveID, true, restoreID)
        navigation.onPlayerPageChanged?.(true)
        navigation.stack.pushPath({
          name: navigation.routeName,
          param: route,
          onPop: () => {
            FloatingPlayerManager.releaseUnclaimed(restoreID)
            navigation.notifyPlayerPageHidden()
          },
        })
      },
    })
    return () => {
      if (FloatingPlayerManager.navigation !== navigation) return
      navigation.revision++
      FloatingPlayerManager.navigation = undefined
      navigation.onPlayerPageChanged?.(false)
      unbind()
    }
  }

  static async enterFloatingView(player: PlayerViewController, uiContext: UIContext, isValid: () => boolean,
    onHandedOver: () => void): Promise<boolean> {
    if (FloatingPlayerManager.host === undefined || FloatingPlayerManager.session !== undefined ||
      FloatingPlayerManager.stopping !== undefined || !player.impl.canEnterFloating || !isValid()) {
      return false
    }
    FloatingPlayerManager.cancelFloatingDismiss()
    if (!PiPWindow.isPiPEnabled()) throw new Error('pictureInPictureUnsupported')
    const session = new FloatingSession(player)
    const host = FloatingPlayerManager.host
    FloatingPlayerManager.session = session
    try {
      const context = uiContext.getHostContext() as common.UIAbilityContext
      const mainWindow: window.Window = await window.getLastWindow(context)
      if (session.cancelled || FloatingPlayerManager.session !== session || !isValid()) {
        throw new Error('pictureInPictureCancelled')
      }
      session.content = new FloatingContent(mainWindow.getUIContext())
      session.creating = PiPWindow.create({
        context: context,
        componentController: session.content.controller,
        templateType: PiPWindow.PiPTemplateType.VIDEO_LIVE,
        controlGroups: new Array<PiPWindow.PiPControlGroup>(),
        contentWidth: 120,
        contentHeight: 180,
        customUIController: session.content.video,
      }, session.content.node).then((pip: PiPWindow.PiPController) => {
        session.pip = pip
        return pip
      })
      const pip: PiPWindow.PiPController = await session.creating
      if (session.cancelled || FloatingPlayerManager.session !== session || !isValid()) {
        throw new Error('pictureInPictureCancelled')
      }
      const started = new Promise<boolean>((resolve: (started: boolean) => void) => session.resolveStarted = resolve)
      const mainUIContext = mainWindow.getUIContext()
      pip.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
        mainUIContext.runScopedTask(() => FloatingPlayerManager.onStateChanged(session, state, reason))
      })
      pip.setAutoStartEnabled(false)
      pip.setPiPControlEnabled(PiPWindow.PiPControlType.VIDEO_PLAY_PAUSE, false)
      pip.setPiPControlEnabled(PiPWindow.PiPControlType.MUTE_SWITCH, false)
      session.starting = pip.startPiP()
      await session.starting
      if (!await started || session.cancelled || FloatingPlayerManager.session !== session ||
        FloatingPlayerManager.host !== host || !isValid() || !player.impl.canEnterFloating || !FloatingPlayerManager.matchesUser(session)) {
        throw new Error('pictureInPictureCancelled')
      }
      session.viewBindingAttempted = true
      player.impl.setVideoView(session.content.view)
      session.phase = Phase.floating
      session.handedOver = true
      player.impl.beginFloating()
      onHandedOver()
      player.onCloseClicked = undefined
      player.onJoinLiveClicked = undefined
      player.impl.onFloatingWindowRequested = undefined
      session.stopObserving = player.status((status: PlayerStatus) => {
        if (status === PlayerStatus.end) {
          FloatingPlayerManager.release().catch((error: Error) => LiveKitLog.error(`[PiP] end: ${error.message}`))
        }
      })
      host.onStarted(session.liveID)
      return true
    } catch (error) {
      await FloatingPlayerManager.clear(session, session.handedOver)
      throw error as Error
    }
  }

  static async enterPlayerPage(liveID: string, autoEnterRoom: boolean = false): Promise<void> {
    const navigation = FloatingPlayerManager.navigation
    if (navigation === undefined || navigation.isOpening || !navigation.isAvailable() ||
      navigation.stack.size() > 0 || liveID.length === 0) return
    const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (userID.length === 0) return
    const revision = navigation.revision
    navigation.isOpening = true
    try {
      await FloatingPlayerManager.release()
      FloatingPlayerManager.cancelFloatingDismiss()
      if (FloatingPlayerManager.navigation !== navigation || revision !== navigation.revision ||
        !navigation.isAvailable() || navigation.stack.size() > 0 ||
        userID !== (LoginStore.shared().state.loginUserInfo?.userID ?? '')) return
      navigation.onPlayerPageChanged?.(true)
      navigation.stack.pushPath({
        name: navigation.routeName,
        param: new PlayerPageRoute(liveID, autoEnterRoom),
        onPop: () => navigation.notifyPlayerPageHidden(),
      })
    } finally {
      navigation.isOpening = false
    }
  }

  static closePlayerPage(route: PlayerPageRoute): void {
    const navigation = FloatingPlayerManager.navigation
    if (navigation !== undefined && navigation.isCurrent(route)) navigation.stack.pop({})
  }

  static isPageCurrent(route: PlayerPageRoute): boolean {
    const navigation = FloatingPlayerManager.navigation
    return navigation !== undefined && navigation.isAvailable() && navigation.isCurrent(route)
  }

  static invalidateNavigation(): void {
    const navigation = FloatingPlayerManager.navigation
    if (navigation !== undefined) navigation.revision++
  }

  static bindHost(host: FloatingPlayerHost): () => void {
    FloatingPlayerManager.host = host
    return () => {
      if (FloatingPlayerManager.host !== host) return
      FloatingPlayerManager.host = undefined
      FloatingPlayerManager.release().catch((error: Error) => LiveKitLog.error(`[PiP] release: ${error.message}`))
    }
  }

  static claim(liveID: string, restoreID: string): PlayerViewController | undefined {
    const session = FloatingPlayerManager.session
    if (session === undefined || session.cancelled || session.phase !== Phase.restoring || restoreID.length === 0 ||
      session.restoreID !== restoreID || session.liveID !== liveID || !FloatingPlayerManager.matchesUser(session) ||
      session.player.impl.status === PlayerStatus.end) {
      return undefined
    }
    FloatingPlayerManager.cancelFloatingDismiss()
    FloatingPlayerManager.session = undefined
    session.stopObserving?.()
    session.stopObserving = undefined
    session.player.impl.resumeFloating()
    FloatingPlayerManager.disposePiP(session).catch((error: Error) => LiveKitLog.error(`[PiP] restore: ${error.message}`))
    return session.player
  }

  static releaseUnclaimed(restoreID: string): void {
    if (restoreID.length === 0 || FloatingPlayerManager.session?.restoreID !== restoreID) return
    FloatingPlayerManager.release().catch((error: Error) => LiveKitLog.error(`[PiP] unclaimed: ${error.message}`))
  }

  static async release(): Promise<void> {
    const session = FloatingPlayerManager.session
    if (session !== undefined) await FloatingPlayerManager.clear(session, session.handedOver)
    else await FloatingPlayerManager.stopping
  }

  private static matchesUser(session: FloatingSession): boolean {
    return session.userID.length > 0 && session.userID === (LoginStore.shared().state.loginUserInfo?.userID ?? '')
  }

  private static onStateChanged(session: FloatingSession, state: PiPWindow.PiPState, reason: string): void {
    if (session.cancelled || FloatingPlayerManager.session !== session) return
    if (state === PiPWindow.PiPState.STARTED) {
      session.isFloating = true
      session.wasFloating = true
      session.resolveStarted?.(true)
      session.resolveStarted = undefined
    } else if (state === PiPWindow.PiPState.ABOUT_TO_RESTORE && session.phase === Phase.floating) {
      if (!FloatingPlayerManager.matchesUser(session) || FloatingPlayerManager.host === undefined) {
        FloatingPlayerManager.release().catch((error: Error) => LiveKitLog.error(`[PiP] restore: ${error.message}`))
        return
      }
      session.phase = Phase.restoring
      try {
        FloatingPlayerManager.host.onRestore(session.liveID, session.restoreID)
      } catch (error) {
        FloatingPlayerManager.release().catch((failure: Error) => LiveKitLog.error(`[PiP] restore: ${failure.message}`))
      }
    } else if (state === PiPWindow.PiPState.STOPPED && session.phase === Phase.restoring) {
      session.isFloating = false
      FloatingPlayerManager.disposePiP(session).catch((error: Error) => LiveKitLog.error(`[PiP] stop: ${error.message}`))
    } else if (state === PiPWindow.PiPState.STOPPED || state === PiPWindow.PiPState.ERROR) {
      session.isFloating = false
      session.resolveStarted?.(false)
      session.resolveStarted = undefined
      LiveKitLog.info(`[PiP] stopped: ${reason}`)
      FloatingPlayerManager.release().catch((error: Error) => LiveKitLog.error(`[PiP] stop: ${error.message}`))
    }
  }

  private static async clear(session: FloatingSession, releasePlayer: boolean): Promise<void> {
    if (session.clearing !== undefined) return session.clearing
    session.cancelled = true
    session.resolveStarted?.(false)
    session.resolveStarted = undefined
    session.stopObserving?.()
    session.stopObserving = undefined
    if (releasePlayer) {
      session.player.impl.releaseFloating()
    } else if (session.viewBindingAttempted) {
      try {
        session.player.impl.setVideoView()
      } catch (error) {
        LiveKitLog.error(`[PiP] restoreView: ${(error as Error).message}`)
      }
    }
    session.clearing = FloatingPlayerManager.drainAndDispose(session)
    await session.clearing
    if (FloatingPlayerManager.session === session) FloatingPlayerManager.session = undefined
    if (session.wasFloating) FloatingPlayerManager.scheduleFloatingDismiss(session.liveID)
  }

  private static async drainAndDispose(session: FloatingSession): Promise<void> {
    await session.creating?.catch(() => {})
    await session.starting?.catch(() => {})
    await FloatingPlayerManager.disposePiP(session)
  }

  private static async disposePiP(session: FloatingSession): Promise<void> {
    if (session.disposing !== undefined) return session.disposing
    session.isFloating = false
    const pip = session.pip
    if (pip === undefined) {
      session.content?.release()
      session.content = undefined
      return
    }
    session.pip = undefined
    pip.off('stateChange')
    const stopping = pip.stopPiP().catch((error: Error) => {
      LiveKitLog.info(`[PiP] stopPiP: ${error.message}`)
    }).then(() => {
      session.content?.release()
      session.content = undefined
    })
    session.disposing = stopping
    FloatingPlayerManager.stopping = stopping
    await stopping
    if (FloatingPlayerManager.stopping === stopping) FloatingPlayerManager.stopping = undefined
  }
}
