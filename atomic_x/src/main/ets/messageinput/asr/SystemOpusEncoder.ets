import aiaudiocodec from 'libaiaudiocodec.so';

export class SystemOpusEncoder {
  private static readonly OPUS_BIT_RATE: number = 24000;
  private static cachedSupported?: boolean;
  private handle: number;

  private constructor(handle: number) {
    this.handle = handle;
  }

  static isSupported(): boolean {
    const cached = SystemOpusEncoder.cachedSupported;
    if (cached !== undefined) {
      return cached;
    }
    let supported = false;
    try {
      supported = aiaudiocodec.isEncoderSupported();
    } catch (e) {
      supported = false;
    }
    SystemOpusEncoder.cachedSupported = supported;
    return supported;
  }

  static create(onPackets: (packets: ArrayBuffer[]) => void): SystemOpusEncoder | undefined {
    if (!SystemOpusEncoder.isSupported()) {
      return undefined;
    }
    try {
      const handle = aiaudiocodec.createEncoder(SystemOpusEncoder.OPUS_BIT_RATE, onPackets);
      return handle > 0 ? new SystemOpusEncoder(handle) : undefined;
    } catch (e) {
      return undefined;
    }
  }

  encode(pcm: ArrayBuffer): void {
    if (this.handle > 0) {
      aiaudiocodec.encode(this.handle, pcm);
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
