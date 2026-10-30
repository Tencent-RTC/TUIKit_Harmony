import { getTRTCShareInstance } from '@tencentcloud/liteavsdk_professional'

enum Level {
  info = 0,
  warn = 1,
  error = 2,
}

export class LiveKitLog {
  static info(message: string, file: string = '', line: number = 0): void {
    LiveKitLog.log(Level.info, message, file, line)
  }

  static warn(message: string, file: string = '', line: number = 0): void {
    LiveKitLog.log(Level.warn, message, file, line)
  }

  static error(message: string, file: string = '', line: number = 0): void {
    LiveKitLog.log(Level.error, message, file, line)
  }

  private static log(level: Level, message: string, file: string, line: number): void {
    const params: Record<string, Object> = {
      'level': level as number,
      'message': message,
      'module': 'TUILiveKit',
      'file': file,
      'line': line,
    }
    const payload: Record<string, Object> = { 'api': 'TuikitLog', 'params': params }
    try {
      getTRTCShareInstance().callExperimentalAPI(JSON.stringify(payload))
    } catch (e) {
      console.error(`[TUILiveKit] ${message}`)
    }
  }
}
