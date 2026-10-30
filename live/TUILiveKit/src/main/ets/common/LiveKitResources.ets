import { window } from '@kit.ArkUI'
import { i18n } from '@kit.LocalizationKit'
import { BasicData, BasicDataSource } from '@tencentcloud/atomicxcore'

export class LiveKitResources {
  static readonly presetCoverURLs: string[] = [1, 2, 3, 4, 5].map((index: number) =>
    `https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/live/live_cover${index}.png`)
  static readonly defaultCoverURL: string = LiveKitResources.presetCoverURLs[0]
  static readonly defaultBackgroundURL: string =
    'https://liteav.sdk.qcloud.com/app/res/picture/livekit/coGuestBackGroud.png'

  static image(name: string): Resource {
    const resource: Resource = { bundleName: '', moduleName: '', id: -1, params: [`app.media.${name}`], type: 20000 }
    return resource
  }

  static get giftLanguageCode(): string {
    const languageTag = i18n.System.getAppPreferredLanguage().replace('_', '-').toLowerCase()
    if (languageTag !== 'zh' && !languageTag.startsWith('zh-')) {
      return 'en'
    }
    if (languageTag.includes('hans') || languageTag === 'zh' || languageTag.startsWith('zh-cn') ||
      languageTag.startsWith('zh-sg') || languageTag.startsWith('zh-my')) {
      return 'zh-Hans'
    }
    return 'zh-Hant'
  }

  static localizedString(key: string): string {
    try {
      return getContext().resourceManager.getStringByNameSync(key.replace(/[.-]/g, '_'))
    } catch (e) {
      return key
    }
  }

  static localizedFormat(key: string, ...args: (string | number)[]): string {
    try {
      return getContext().resourceManager.getStringByNameSync(key.replace(/[.-]/g, '_'), ...args)
    } catch (e) {
      return key
    }
  }
}

export class LiveKitSafeArea {
  static readonly topKey: string = 'tuilivekit.safeArea.top'
  static readonly bottomKey: string = 'tuilivekit.safeArea.bottom'
  static readonly keyboardKey: string = 'tuilivekit.keyboard.height'
  private static isObserving: boolean = false

  static observe(): void {
    if (LiveKitSafeArea.isObserving) {
      return
    }
    LiveKitSafeArea.isObserving = true
    window.getLastWindow(getContext()).then((target: window.Window) => {
      const update = () => {
        const system = target.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
        const indicator = target.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
        AppStorage.setOrCreate(LiveKitSafeArea.topKey, px2vp(system.topRect.height))
        AppStorage.setOrCreate(LiveKitSafeArea.bottomKey,
          px2vp(Math.max(system.bottomRect.height, indicator.bottomRect.height)))
      }
      update()
      target.on('avoidAreaChange', () => update())
      target.on('keyboardHeightChange', (height: number) => AppStorage.setOrCreate(LiveKitSafeArea.keyboardKey, px2vp(height)))
    }).catch(() => {
      LiveKitSafeArea.isObserving = false
    })
  }
}

export class LiveKitDataObserver implements DataChangeListener {
  private onChange: () => void

  constructor(onChange: () => void) {
    this.onChange = onChange
  }

  static observe<T extends BasicData>(source: BasicDataSource<T>, onChange: () => void): () => void {
    const observer = new LiveKitDataObserver(onChange)
    source.registerDataChangeListener(observer)
    return () => source.unregisterDataChangeListener(observer)
  }

  onDataReloaded(): void {
    this.onChange()
  }

  onDataAdded(index: number): void {
    this.onChange()
  }

  onDataAdd(index: number): void {
    this.onChange()
  }

  onDataMoved(from: number, to: number): void {
    this.onChange()
  }

  onDataMove(from: number, to: number): void {
    this.onChange()
  }

  onDataDeleted(index: number): void {
    this.onChange()
  }

  onDataDelete(index: number): void {
    this.onChange()
  }

  onDataChanged(index: number): void {
    this.onChange()
  }

  onDataChange(index: number): void {
    this.onChange()
  }

  onDatasetChange(dataOperations: DataOperation[]): void {
    this.onChange()
  }
}
