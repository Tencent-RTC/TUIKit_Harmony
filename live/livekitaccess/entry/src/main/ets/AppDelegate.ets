import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'

export default class AppDelegate extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate('livekit.access.context', this.context)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const mainWindow = windowStage.getMainWindowSync()
    mainWindow.setWindowLayoutFullScreen(true)
    windowStage.loadContent('LiveKitAccessCoordinator', () => {
      try {
        mainWindow.setWindowBackgroundColor('#000000')
      } catch (error) {
      }
    })
  }
}
