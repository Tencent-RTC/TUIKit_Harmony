import { audio } from '@kit.AudioKit';
import { AIConstants } from '../../aiassistant/AIConstants';
import { SystemOpusEncoder } from './SystemOpusEncoder';

export class RealtimeAsrAudioCapture {
  private readonly onPacket: (packet: ArrayBuffer) => void;
  private readonly onPcmFrame?: (pcm: Int16Array) => void;
  private capturer?: audio.AudioCapturer;
  private encoder?: SystemOpusEncoder;
  private running: boolean = false;
  private stopped: boolean = false;
  private pendingEncoderReset: boolean = false;
  private pending: Int16Array = new Int16Array(AIConstants.FRAME_SAMPLES * 8);
  private pendingLength: number = 0;

  constructor(onPacket: (packet: ArrayBuffer) => void, onPcmFrame?: (pcm: Int16Array) => void) {
    this.onPacket = onPacket;
    this.onPcmFrame = onPcmFrame;
  }

  static isSupported(): boolean {
    return SystemOpusEncoder.isSupported();
  }

  get isRunning(): boolean {
    return this.running;
  }

  async start(): Promise<boolean> {
    if (this.running) {
      return true;
    }
    if (!RealtimeAsrAudioCapture.isSupported()) {
      return false;
    }
    const encoder = SystemOpusEncoder.create((packets: ArrayBuffer[]) => {
      if (!this.running) {
        return;
      }
      for (const packet of packets) {
        this.onPacket(packet);
      }
    });
    if (!encoder) {
      return false;
    }
    this.encoder = encoder;
    const options: audio.AudioCapturerOptions = {
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      capturerInfo: {
        source: audio.SourceType.SOURCE_TYPE_VOICE_COMMUNICATION,
        capturerFlags: 0
      }
    };
    let capturer: audio.AudioCapturer;
    try {
      capturer = await audio.createAudioCapturer(options);
    } catch (e) {
      this.releaseEncoder();
      return false;
    }
    if (this.stopped) {
      capturer.release().catch(() => {
      });
      this.releaseEncoder();
      return false;
    }
    try {
      capturer.on('readData', (buffer: ArrayBuffer) => this.onReadData(buffer));
      await capturer.start();
    } catch (e) {
      this.releaseCapturer(capturer);
      this.releaseEncoder();
      return false;
    }
    if (this.stopped) {
      this.releaseCapturer(capturer);
      this.releaseEncoder();
      return false;
    }
    this.capturer = capturer;
    this.pendingLength = 0;
    this.running = true;
    return true;
  }

  stop(): void {
    this.stopped = true;
    this.running = false;
    this.pendingEncoderReset = false;
    this.pendingLength = 0;
    const capturer = this.capturer;
    this.capturer = undefined;
    if (capturer) {
      this.releaseCapturer(capturer);
    }
    this.releaseEncoder();
  }

  requestEncoderReset(): void {
    this.pendingEncoderReset = true;
  }

  private onReadData(buffer: ArrayBuffer): void {
    if (!this.running) {
      return;
    }
    const samples = new Int16Array(buffer.slice(0, buffer.byteLength - (buffer.byteLength % 2)));
    if (this.pendingLength + samples.length > this.pending.length) {
      const grown = new Int16Array((this.pendingLength + samples.length) * 2);
      grown.set(this.pending.subarray(0, this.pendingLength));
      this.pending = grown;
    }
    this.pending.set(samples, this.pendingLength);
    this.pendingLength += samples.length;
    let offset = 0;
    while (this.running && this.pendingLength - offset >= AIConstants.FRAME_SAMPLES) {
      if (this.pendingEncoderReset) {
        this.pendingEncoderReset = false;
        this.encoder?.reset();
      }
      const frame = this.pending.slice(offset, offset + AIConstants.FRAME_SAMPLES);
      this.onPcmFrame?.(frame);
      if (!this.running) {
        break;
      }
      this.encoder?.encode(frame.buffer as ArrayBuffer);
      offset += AIConstants.FRAME_SAMPLES;
    }
    if (offset > 0) {
      const remain = this.pendingLength - offset;
      if (remain > 0) {
        this.pending.copyWithin(0, offset, this.pendingLength);
      }
      this.pendingLength = Math.max(0, remain);
    }
  }

  private releaseCapturer(capturer: audio.AudioCapturer): void {
    try {
      capturer.off('readData');
    } catch (e) {
    }
    capturer.stop()
      .catch(() => {
      })
      .finally(() => {
        capturer.release().catch(() => {
        });
      });
  }

  private releaseEncoder(): void {
    this.encoder?.release();
    this.encoder = undefined;
  }
}
