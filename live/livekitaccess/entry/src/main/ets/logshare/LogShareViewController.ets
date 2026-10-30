import { common } from '@kit.AbilityKit'
import { fileUri } from '@kit.CoreFileKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { systemShare } from '@kit.ShareKit'
import { Entry, Export, LogShareFiles } from './LogShareFiles'

function text(key: string, ...args: (string | number)[]): string {
  return getContext().resourceManager.getStringByNameSync(`livekit_access_logs_${key}`, ...args)
}

function formatSize(size: number): string {
  if (size < 1024) {
    return `${size} bytes`
  }
  const units = ['KB', 'MB', 'GB']
  let value = size / 1000
  let index = 0
  while (value >= 1000 && index < units.length - 1) {
    value /= 1000
    index++
  }
  return `${value.toFixed(value >= 10 ? 0 : 1)} ${units[index]}`
}

@Component
export struct LogShareViewController {
  onClose?: () => void
  @State private files: Entry[] = []
  @State private busy: boolean = false
  @State private prompt?: string = undefined
  @State private backgroundMessage?: string = undefined
  private active: boolean = true

  aboutToAppear(): void {
    this.loadFiles()
  }

  aboutToDisappear(): void {
    this.active = false
  }

  private loadFiles(): void {
    this.busy = true
    this.prompt = undefined
    setTimeout(() => {
      if (!this.active) {
        return
      }
      this.busy = false
      try {
        this.files = LogShareFiles.scan()
        this.backgroundMessage = this.files.length === 0 ? text('empty') : undefined
      } catch (error) {
        this.backgroundMessage = text('read_failed')
      }
    }, 0)
  }

  private select(entries: Entry[], archive: boolean): void {
    if (this.busy) {
      return
    }
    this.busy = true
    this.prompt = undefined
    LogShareFiles.prepare(entries, archive).then((exported: Export) => {
      if (!this.active) {
        exported.remove()
        return
      }
      this.busy = false
      this.share(exported, archive)
    }).catch(() => {
      if (!this.active) {
        return
      }
      this.busy = false
      this.getUIContext().showAlertDialog({
        title: text('failed'),
        message: text('retry'),
        confirm: {
          value: getContext().resourceManager.getStringByNameSync('livekit_access_ok'),
          action: () => this.loadFiles(),
        },
      })
    })
  }

  private share(exported: Export, archive: boolean): void {
    const data = new systemShare.SharedData({
      utd: archive ? uniformTypeDescriptor.UniformDataType.ZIP_ARCHIVE : uniformTypeDescriptor.UniformDataType.FILE,
      uri: fileUri.getUriFromPath(exported.file),
    })
    const controller = new systemShare.ShareController(data)
    controller.on('dismiss', () => exported.remove())
    controller.show(getContext(this) as common.UIAbilityContext, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE,
    }).catch(() => {
      exported.remove()
      if (this.active) {
        this.prompt = text('failed')
      }
    })
  }

  @Builder
  row(title: string, detail: string, isAction: boolean, action: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title).fontSize(17).fontColor(isAction ? '#007AFF' : '#000000')
        Text(detail).fontSize(12).fontColor('rgba(60, 60, 67, 0.6)')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›').fontSize(20).fontColor('rgba(60, 60, 67, 0.3)')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 11, bottom: 11 })
    .backgroundColor(Color.White)
    .onClick(action)
  }

  build() {
    Column() {
      Stack() {
        Text(text('title')).fontSize(17).fontWeight(FontWeight.Medium)
        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.xmark')).fontSize(20)
          }
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.active = false
            this.onClose?.()
          })
          Blank()
          if (this.busy) {
            LoadingProgress().width(24).height(24)
          }
        }
        .width('100%')
        .padding({ left: 8, right: 16 })
      }
      .width('100%')
      .height(56)
      if (this.prompt !== undefined) {
        Text(this.prompt).fontSize(13).fontColor('rgba(60, 60, 67, 0.6)').margin({ bottom: 8 })
      }
      if (this.files.length > 0) {
        List({ space: 0 }) {
          ListItemGroup({ footer: this.footer() }) {
            ListItem() {
              this.row(text('archive'), text('count', this.files.length), true, () => this.select(this.files, true))
            }
          }
          ListItemGroup({ header: this.header() }) {
            ForEach(this.files, (file: Entry) => {
              ListItem() {
                this.row(file.name, `${new Date(file.modified).toLocaleString()} · ${formatSize(file.size)}`, false,
                  () => this.select([file], false))
              }
            }, (file: Entry) => file.path)
          }
          .divider({ strokeWidth: 0.5, color: 'rgba(60, 60, 67, 0.29)', startMargin: 16 })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .enabled(!this.busy)
      } else {
        Text(this.backgroundMessage ?? '')
          .fontColor('rgba(60, 60, 67, 0.6)')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  header() {
    Text(text('single')).fontSize(13).fontColor('rgba(60, 60, 67, 0.6)').padding({ left: 16, top: 16, bottom: 6 })
  }

  @Builder
  footer() {
    Text(text('scope')).fontSize(13).fontColor('rgba(60, 60, 67, 0.6)').padding({ left: 16, top: 6, bottom: 16 })
  }
}
