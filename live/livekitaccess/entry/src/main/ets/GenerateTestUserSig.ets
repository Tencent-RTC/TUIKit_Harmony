import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'
import { zlib } from '@kit.BasicServicesKit'

export class GenerateTestUserSig {
  static readonly SDKAPPID: number = 0
  private static readonly EXPIRETIME: number = 604800
  private static readonly SECRETKEY: string = ''

  static async genTestUserSig(userID: string): Promise<string> {
    if (GenerateTestUserSig.SDKAPPID <= 0 || GenerateTestUserSig.SECRETKEY.length === 0 || userID.length === 0) {
      return ''
    }
    const currentTime = Math.floor(Date.now() / 1000)
    const document: Record<string, string | number> = {
      'TLS.expire': GenerateTestUserSig.EXPIRETIME,
      'TLS.identifier': userID,
      'TLS.sdkappid': GenerateTestUserSig.SDKAPPID,
      'TLS.sig': GenerateTestUserSig.hmacSHA256(userID, currentTime),
      'TLS.time': currentTime,
      'TLS.ver': '2.0',
    }
    const source = new util.TextEncoder().encodeInto(JSON.stringify(document))
    const compressed = await GenerateTestUserSig.compress(source)
    return compressed === undefined ? '' : GenerateTestUserSig.base64URL(compressed)
  }

  private static hmacSHA256(userID: string, currentTime: number): string {
    const content = `TLS.identifier:${userID}\nTLS.sdkappid:${GenerateTestUserSig.SDKAPPID}\n` +
      `TLS.time:${currentTime}\nTLS.expire:${GenerateTestUserSig.EXPIRETIME}\n`
    const encoder = new util.TextEncoder()
    const key = cryptoFramework.createSymKeyGenerator('HMAC')
      .convertKeySync({ data: encoder.encodeInto(GenerateTestUserSig.SECRETKEY) })
    const mac = cryptoFramework.createMac('SHA256')
    mac.initSync(key)
    mac.updateSync({ data: encoder.encodeInto(content) })
    return new util.Base64Helper().encodeToStringSync(mac.doFinalSync().data)
  }

  private static async compress(source: Uint8Array): Promise<Uint8Array | undefined> {
    const zip = zlib.createZipSync()
    const bound = await zip.compressBound(source.byteLength)
    const destination = new ArrayBuffer(bound)
    const sourceBuffer = source.buffer.slice(source.byteOffset, source.byteOffset + source.byteLength)
    const result = await zip.compress2(destination, sourceBuffer, zlib.CompressLevel.COMPRESS_LEVEL_BEST_SPEED)
    return result.status === zlib.ReturnStatus.OK ? new Uint8Array(destination, 0, result.destLen) : undefined
  }

  private static base64URL(data: Uint8Array): string {
    return new util.Base64Helper().encodeToStringSync(data).replace(/\+/g, '*').replace(/\//g, '-').replace(/=/g, '_')
  }
}
