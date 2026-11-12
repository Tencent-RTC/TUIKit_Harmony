import aiaudiocodec from 'libaiaudiocodec.so';

export class SystemOpusDecoder {
  private static cachedSupported?: boolean;
  private handle: number;

  private constructor(handle: number) {
    this.handle = handle;
  }

  static isSupported(): boolean {
    const cached = SystemOpusDecoder.cachedSupported;
    if (cached !== undefined) {
      return cached;
    }
    let supported = false;
    try {
      supported = aiaudiocodec.isDecoderSupported();
    } catch (e) {
      supported = false;
    }
    SystemOpusDecoder.cachedSupported = supported;
    return supported;
  }

  static create(onChunk: (tag: number, pcm: ArrayBuffer, finished: boolean) => void): SystemOpusDecoder | undefined {
    if (!SystemOpusDecoder.isSupported()) {
      return undefined;
    }
    try {
      const handle = aiaudiocodec.createDecoder(onChunk);
      return handle > 0 ? new SystemOpusDecoder(handle) : undefined;
    } catch (e) {
      return undefined;
    }
  }

  decode(packets: ArrayBuffer[], finished: boolean, tag: number): void {
    if (this.handle > 0) {
      aiaudiocodec.decode(this.handle, packets, finished, tag);
    }
  }

  reset(): void {
    if (this.handle > 0) {
      aiaudiocodec.reset(this.handle);
    }
  }

  release(): void {
    if (this.handle > 0) {
      aiaudiocodec.release(this.handle);
      this.handle = 0;
    }
  }
}
