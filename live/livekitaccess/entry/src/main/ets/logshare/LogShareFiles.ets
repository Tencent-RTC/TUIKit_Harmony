import { fileIo } from '@kit.CoreFileKit'
import { zlib } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'

export class Entry {
  path: string
  name: string
  modified: number
  size: number

  constructor(path: string, name: string, modified: number, size: number) {
    this.path = path
    this.name = name
    this.modified = modified
    this.size = size
  }
}

export class Export {
  directory: string
  file: string

  constructor(directory: string, file: string) {
    this.directory = directory
    this.file = file
  }

  remove(): void {
    try {
      fileIo.rmdirSync(this.directory)
    } catch (error) {
    }
  }
}

export class LogShareFiles {
  static scan(): Entry[] {
    const directory = `${getContext().filesDir}/log`
    if (!fileIo.accessSync(directory)) {
      return []
    }
    return fileIo.listFileSync(directory).filter((name: string) => ['xlog', 'clog']
      .includes((name.split('.').pop() ?? '').toLowerCase())).map((name: string) => {
      const path = `${directory}/${name}`
      const stat = fileIo.lstatSync(path)
      return stat.isFile() ? new Entry(path, name, stat.mtime * 1000, stat.size) : undefined
    }).filter((entry: Entry | undefined) => entry !== undefined).map((entry: Entry | undefined) => entry as Entry)
      .sort((lhs: Entry, rhs: Entry) => lhs.modified === rhs.modified ? rhs.name.localeCompare(lhs.name) :
        rhs.modified - lhs.modified)
  }

  static async prepare(entries: Entry[], archive: boolean): Promise<Export> {
    const root = `${getContext().cacheDir}/LiveKitLogExports`
    if (!fileIo.accessSync(root)) {
      fileIo.mkdirSync(root, true)
    }
    fileIo.listFileSync(root).forEach((name: string) => {
      const path = `${root}/${name}`
      if (fileIo.statSync(path).mtime * 1000 < Date.now() - 86400000) {
        fileIo.rmdirSync(path)
      }
    })
    const directory = `${root}/${util.generateRandomUUID()}`
    fileIo.mkdirSync(directory, true)
    try {
      if (entries.length === 0) {
        throw new Error('fileNoSuchFile')
      }
      const snapshot = `${directory}/Logs`
      fileIo.mkdirSync(snapshot)
      entries.forEach((entry: Entry) => fileIo.copyFileSync(entry.path, `${snapshot}/${entry.name}`))
      if (!archive) {
        return new Export(directory, `${snapshot}/${entries[0].name}`)
      }
      const date = new Date()
      const pad = (value: number) => `${value}`.padStart(2, '0')
      const stamp = `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-` +
        `${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`
      const zip = `${directory}/LiveKit-Logs-${stamp}.zip`
      await zlib.compressFile(snapshot, zip, { level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION })
      if (!fileIo.accessSync(zip)) {
        throw new Error('fileReadUnknown')
      }
      fileIo.rmdirSync(snapshot)
      return new Export(directory, zip)
    } catch (error) {
      fileIo.rmdirSync(directory)
      throw error as Error
    }
  }
}
