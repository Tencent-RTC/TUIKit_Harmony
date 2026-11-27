import { RoomStore } from '@tencentcloud/atomicxcore'

export class RoomDataReporter {
  private static readonly framework: number = 1
  private static readonly component: number = 18
  private static readonly language: number = 11

  static reportComponent(): void {
    const params: Record<string, Object> = {
      'framework': RoomDataReporter.framework,
      'component': RoomDataReporter.component,
      'language': RoomDataReporter.language,
    }
    const payload: Record<string, Object> = {
      'api': 'LoginModule.setFramework',
      'params': params,
    }
    RoomStore.shared().callExperimentalAPI(JSON.stringify(payload)).catch(() => undefined)
  }
}
