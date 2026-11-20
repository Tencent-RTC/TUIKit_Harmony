import { window } from '@kit.ArkUI'

export class RoomSafeArea {
  static readonly topKey: string = 'tuir.room.safeArea.top'
  static readonly bottomKey: string = 'tuir.room.safeArea.bottom'
  static readonly keyboardKey: string = 'tuir.room.keyboard.height'
  private static target?: window.Window
  private static avoidAreaCallback?: () => void
  private static keyboardCallback?: (height: number) => void
  private static revision: number = 0
  private static isResolving: boolean = false
  private static observerCount: number = 0

  static observe(): void {
    RoomSafeArea.observerCount++
    if (RoomSafeArea.target !== undefined || RoomSafeArea.isResolving) {
      return
    }
    RoomSafeArea.isResolving = true
    const revision = ++RoomSafeArea.revision
    window.getLastWindow(getContext()).then((target: window.Window) => {
      if (revision !== RoomSafeArea.revision) {
        return
      }
      const update = (): void => {
        const system = target.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
        const indicator = target.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
        AppStorage.setOrCreate(RoomSafeArea.topKey, px2vp(system.topRect.height))
        AppStorage.setOrCreate(RoomSafeArea.bottomKey,
          px2vp(Math.max(system.bottomRect.height, indicator.bottomRect.height)))
      }
      const onKeyboard = (height: number): void => {
        AppStorage.setOrCreate(RoomSafeArea.keyboardKey, px2vp(height))
      }
      RoomSafeArea.target = target
      RoomSafeArea.isResolving = false
      RoomSafeArea.avoidAreaCallback = update
      RoomSafeArea.keyboardCallback = onKeyboard
      update()
      target.on('avoidAreaChange', update)
      target.on('keyboardHeightChange', onKeyboard)
    }).catch(() => {
      if (revision === RoomSafeArea.revision) {
        RoomSafeArea.isResolving = false
      }
    })
  }

  static stopObserving(): void {
    if (RoomSafeArea.observerCount > 0) {
      RoomSafeArea.observerCount--
    }
    if (RoomSafeArea.observerCount > 0) {
      return
    }
    RoomSafeArea.revision++
    RoomSafeArea.isResolving = false
    if (RoomSafeArea.target !== undefined) {
      if (RoomSafeArea.avoidAreaCallback !== undefined) {
        RoomSafeArea.target.off('avoidAreaChange', RoomSafeArea.avoidAreaCallback)
      }
      if (RoomSafeArea.keyboardCallback !== undefined) {
        RoomSafeArea.target.off('keyboardHeightChange', RoomSafeArea.keyboardCallback)
      }
    }
    RoomSafeArea.target = undefined
    RoomSafeArea.avoidAreaCallback = undefined
    RoomSafeArea.keyboardCallback = undefined
  }

  static bottomClearance(minimum: number = 34): number {
    const bottom = AppStorage.get(RoomSafeArea.bottomKey) as number | undefined
    return Math.max(minimum, bottom ?? 0)
  }
}
