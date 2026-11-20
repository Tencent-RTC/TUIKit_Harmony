import { Configuration, UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { MMKV } from '@tencent/mmkv'
import { ContextProvider } from '@tencentcloud/atomicx'

export default class AppDelegate extends UIAbility {
  private mainWindow?: window.Window
  private lightContent: boolean = false
  private onStyle: (light: boolean) => void = (light: boolean) => {
    this.lightContent = light
    this.mainWindow?.setWindowSystemBarProperties({ statusBarColor: '#00000000',
      navigationBarColor: '#00000000', statusBarContentColor: light ? '#FFFFFF' : '#171822',
      navigationBarContentColor: light ? '#FFFFFF' : '#171822' })
  }
  private onAvoidChange: () => void = () => this.publishInsets()
  private onKeyboard: (height: number) => void = (height: number) => {
    AppStorage.setOrCreate('tuilivekit.keyboard.height', px2vp(height))
  }

  onCreate(): void {
    this.context.eventHub.on('app.uikit.lightContent', this.onStyle)
    MMKV.initialize(this.context.getApplicationContext())
    ContextProvider.init(this.context)
  }

  onDestroy(): void {
    this.context.eventHub.off('app.uikit.lightContent', this.onStyle)
    ContextProvider.clear()
  }

  onConfigurationUpdate(config: Configuration): void { ContextProvider.onConfigurationUpdate(config) }

  onWindowStageCreate(stage: window.WindowStage): void {
    this.mainWindow = stage.getMainWindowSync()
    this.mainWindow.setWindowLayoutFullScreen(true)
    AppStorage.setOrCreate('tuilivekit.safeArea.hostManaged', true)
    this.publishInsets()
    this.mainWindow.on('avoidAreaChange', this.onAvoidChange)
    this.mainWindow.on('windowSizeChange', this.onAvoidChange)
    this.mainWindow.on('keyboardHeightChange', this.onKeyboard)
    AppStorage.setOrCreate('app.active', true)
    stage.loadContent('AppCoordinator', () => this.onStyle(this.lightContent))
  }

  onForeground(): void { AppStorage.setOrCreate('app.active', true) }
  onBackground(): void { AppStorage.setOrCreate('app.active', false) }

  onWindowStageDestroy(): void {
    this.mainWindow?.off('avoidAreaChange', this.onAvoidChange)
    this.mainWindow?.off('windowSizeChange', this.onAvoidChange)
    this.mainWindow?.off('keyboardHeightChange', this.onKeyboard)
    this.mainWindow = undefined
  }

  private publishInsets(): void {
    if (this.mainWindow === undefined) { return }
    AppStorage.setOrCreate('app.windowHeight', px2vp(this.mainWindow.getWindowProperties().windowRect.height))
    const system = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    const navigation = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
    const bottom = Math.max(system.bottomRect.height, navigation.bottomRect.height)
    AppStorage.setOrCreate('tuilivekit.safeArea.top', px2vp(system.topRect.height))
    AppStorage.setOrCreate('tuilivekit.safeArea.bottom', px2vp(bottom))
    AppStorage.setOrCreate('topAvoidHeightPx', system.topRect.height)
    AppStorage.setOrCreate('bottomAvoidHeightPx', bottom)
  }
}
