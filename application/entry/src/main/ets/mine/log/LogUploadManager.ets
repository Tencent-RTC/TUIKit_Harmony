import { common } from '@kit.AbilityKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { systemShare } from '@kit.ShareKit'
import { util } from '@kit.ArkTS'

export class LogFile {
  readonly path: string
  readonly name: string
  readonly modified: number
  constructor(path: string, name: string, modified: number) {
    this.path = path
    this.name = name
    this.modified = modified
  }
}

export class LogUploadManager {
  static scan(context: common.UIAbilityContext): LogFile[] {
    const rows: LogFile[] = []
    const directories = [`${context.filesDir}/log`, `${context.cacheDir}/com_tencent_imsdk_log`]
    directories.forEach((directory: string) => {
      if (!fileIo.accessSync(directory)) { return }
      fileIo.listFileSync(directory).forEach((name: string) => {
        if (!/\.(clog|xlog)$/i.test(name)) { return }
        const path = `${directory}/${name}`
        const stat = fileIo.lstatSync(path)
        if (stat.isFile()) { rows.push(new LogFile(path, name, stat.mtime)) }
      })
    })
    return rows.sort((a: LogFile, b: LogFile) => b.modified - a.modified)
  }

  static async share(context: common.UIAbilityContext, file: LogFile): Promise<void> {
    const root = `${context.cacheDir}/AppUIKitLogExports`
    if (!fileIo.accessSync(root)) { fileIo.mkdirSync(root, true) }
    fileIo.listFileSync(root).forEach((name: string) => {
      const path = `${root}/${name}`
      if (fileIo.statSync(path).mtime * 1000 < Date.now() - 86400000) { fileIo.rmdirSync(path) }
    })
    const directory = `${root}/${util.generateRandomUUID()}`
    fileIo.mkdirSync(directory, true)
    try {
      const copy = `${directory}/${file.name}`
      fileIo.copyFileSync(file.path, copy)
      const data = new systemShare.SharedData({ utd: uniformTypeDescriptor.UniformDataType.FILE,
        uri: fileUri.getUriFromPath(copy) })
      const share = new systemShare.ShareController(data)
      share.on('dismiss', () => {
        try { fileIo.rmdirSync(directory) } catch (error) {}
      })
      await share.show(context, { previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE })
    } catch (error) {
      try { fileIo.rmdirSync(directory) } catch (cleanupError) {}
      throw error as Error
    }
  }
}
