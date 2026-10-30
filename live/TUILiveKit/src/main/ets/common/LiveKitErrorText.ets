import { BusinessError } from '@kit.BasicServicesKit'

export class LiveKitErrorText {
  static message(error: BusinessError | Error): string {
    const detail = (error.message ?? '').trim()
    const code = (error as BusinessError).code ?? -1
    return detail.length === 0 ? `AtomicXCore error (${code})` : detail
  }

  static code(error: BusinessError | Error): number {
    return (error as BusinessError).code ?? -1
  }
}
