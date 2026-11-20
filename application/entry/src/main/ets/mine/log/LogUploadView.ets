import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { LogFile, LogUploadManager } from './LogUploadManager'

@Component
export struct LogUploadView {
  onClose: () => void = () => {}
  @State private names: string[] = []
  @State private selected: number = 0
  @State private busy: boolean = false
  private files: LogFile[] = []
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    try {
      this.files = LogUploadManager.scan(getContext(this) as common.UIAbilityContext)
      this.names = this.files.map((file: LogFile) => file.name)
    } catch (error) {
      promptAction.showToast({ message: (error as Error).message })
    }
  }
  aboutToDisappear(): void { this.alive = false }

  private async share(): Promise<void> {
    const file = this.files[this.selected]
    if (this.busy || file === undefined) { return }
    this.busy = true
    try {
      await LogUploadManager.share(getContext(this) as common.UIAbilityContext, file)
      if (this.alive) { this.onClose() }
    } catch (error) {
      if (this.alive) { promptAction.showToast({ message: (error as Error).message }) }
    } finally {
      if (this.alive) { this.busy = false }
    }
  }

  build() {
    Column() {
      Stack() {
        Text($r('app.string.app_logs')).fontSize(14).fontWeight(500).fontColor(Color.Black)
        Row() {
          Button($r('app.string.app_cancel')).fontSize(14).fontColor($r('app.color.app_primary'))
            .backgroundColor(Color.Transparent).height(44).onClick(() => this.onClose())
          Blank()
          Button($r('app.string.app_share')).fontSize(14).fontColor($r('app.color.app_primary'))
            .backgroundColor(Color.Transparent).height(44).enabled(this.files.length > 0 && !this.busy)
            .onClick(() => this.share())
        }.width('100%')
      }.height(44).width('100%')
      if (this.names.length > 0) {
        TextPicker({ range: this.names, selected: this.selected }).width('100%').layoutWeight(1)
          .onChange((value: string | string[], index: number | number[]) => {
            if (typeof index === 'number') { this.selected = index }
          })
      } else {
        Text($r('app.string.app_no_logs')).fontSize(15).fontColor($r('app.color.app_secondary'))
          .layoutWeight(1).textAlign(TextAlign.Center).width('100%')
      }
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
