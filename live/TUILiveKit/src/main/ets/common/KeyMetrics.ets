import { V2TIMManager } from '@tencentcloud/atomicxcore'

export class KeyMetrics {
  static readonly componentLiveStream: number = 21
  static readonly liveIntegrationSuccessful: number = 1120

  static setComponent(component: number): void {
  }

  static reportAtomicMetrics(platform: number): void {
    const param: Record<string, Object> = { 'UIComponentType': platform }
    V2TIMManager.getInstance().callExperimentalAPI('reportTUIFeatureUsage', JSON.stringify(param))
      ?.catch((error: Error) => console.error(`TUILiveKit-DataReporter reportFeatureUsage failed: ${error.message}`))
  }
}
