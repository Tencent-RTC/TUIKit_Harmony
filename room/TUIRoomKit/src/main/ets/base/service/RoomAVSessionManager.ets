import avSession from '@ohos.multimedia.avsession'
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager'
import wantAgent from '@ohos.app.ability.wantAgent'
import { ApplicationStateChangeCallback, bundleManager, common } from '@kit.AbilityKit'

export class RoomAVSessionManager {
  private static running: boolean = false
  private static session?: avSession.AVSession
  private static context?: common.UIAbilityContext
  private static readonly applicationStateCallback: ApplicationStateChangeCallback = {
    onApplicationForeground: () => {
    },
    onApplicationBackground: () => {
      const context = RoomAVSessionManager.context
      if (RoomAVSessionManager.running && context !== undefined) {
        RoomAVSessionManager.startBackgroundTask(context).catch(() => {
        })
      }
    },
  }

  static async start(context: common.UIAbilityContext): Promise<boolean> {
    if (RoomAVSessionManager.running) {
      return true
    }
    RoomAVSessionManager.context = context
    try {
      const session = await avSession.createAVSession(context, 'tuiroomkit', 'video')
      RoomAVSessionManager.session = session
      await session.activate()
      await RoomAVSessionManager.startBackgroundTask(context)
      context.getApplicationContext().on('applicationStateChange', RoomAVSessionManager.applicationStateCallback)
      RoomAVSessionManager.running = true
      return true
    } catch (error) {
      await RoomAVSessionManager.cleanup(context)
      RoomAVSessionManager.context = undefined
      return false
    }
  }

  static async stop(context: common.UIAbilityContext): Promise<void> {
    if (!RoomAVSessionManager.running && RoomAVSessionManager.session === undefined) {
      return
    }
    RoomAVSessionManager.running = false
    try {
      context.getApplicationContext().off('applicationStateChange', RoomAVSessionManager.applicationStateCallback)
    } catch (error) {
    }
    await RoomAVSessionManager.cleanup(context)
    RoomAVSessionManager.context = undefined
  }

  private static async startBackgroundTask(context: common.UIAbilityContext): Promise<void> {
    const agent = await wantAgent.getWantAgent({
      wants: [{ bundleName: RoomAVSessionManager.bundleName(), abilityName: context.abilityInfo.name }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    })
    await backgroundTaskManager.startBackgroundRunning(context, ['audioRecording', 'audioPlayback'], agent)
  }

  private static async cleanup(context: common.UIAbilityContext): Promise<void> {
    try {
      await RoomAVSessionManager.session?.deactivate()
      await RoomAVSessionManager.session?.destroy()
    } catch (error) {
    }
    RoomAVSessionManager.session = undefined
    try {
      await backgroundTaskManager.stopBackgroundRunning(context)
    } catch (error) {
    }
  }

  private static bundleName(): string {
    return bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).name
  }
}
