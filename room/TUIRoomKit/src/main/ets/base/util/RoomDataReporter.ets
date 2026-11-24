import { RoomStore } from '@tencentcloud/atomicxcore'

export class RoomDataReporter {
  private static readonly frameworkNative: number = 1
  private static readonly roomComponent: number = 18
  private static readonly languageArkTS: number = 11

  static reportComponent(): void {
    const params: Record<string, Object> = {
      'framework': RoomDataReporter.frameworkNative,
      'component': RoomDataReporter.roomComponent,
      'language': RoomDataReporter.languageArkTS,
    }
    const jsonObject: Record<string, Object> = {
      'api': 'setFramework',
      'params': params,
    }
    const jsonString: string = JSON.stringify(jsonObject)
    RoomStore.shared().callExperimentalAPI(jsonString).catch(() => {

    })
  }
}
