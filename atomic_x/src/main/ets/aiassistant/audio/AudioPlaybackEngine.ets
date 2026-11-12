import { audio } from '@kit.AudioKit';
import { AIConstants } from '../AIConstants';

export class AudioPlaybackEngine {
  private static readonly DRAIN_MARGIN_MS: number = 200;
  private static readonly DRAIN_TIMEOUT_MAX_MS: number = 2000;
  private static readonly FADE_IN_SAMPLES: number = 160;
  private static readonly LEVEL_FULL_SCALE: number = 6000;
  private static readonly PLAYBACK_GAIN: number = 1.4;

  private readonly onFinished: () => void;
  private readonly onInterrupt?: (resumed: boolean) => void;
  private renderer?: audio.AudioRenderer;
  private queue: Int16Array[] = [];
  private headOffset: number = 0;
  private running: boolean = false;
  private released: boolean = false;
  private endOfStream: boolean = false;
  private levelValue: number = 0;
  private flushEpoch: number = 0;
  private fadeInPending: boolean = true;
  private writtenSamples: number = 0;
  private lastRealEndSamples: number = 0;
  private startTimeMs: number = 0;
  private drainTimer?: number;

  constructor(onFinished: () => void, onInterrupt?: (resumed: boolean) => void) {
    this.onFinished = onFinished;
    this.onInterrupt = onInterrupt;
  }

  get currentLevel(): number {
    return this.levelValue;
  }

  async start(): Promise<boolean> {
    if (this.running) {
      return true;
    }
    const options: audio.AudioRendererOptions = {
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      rendererInfo: {
        usage: audio.StreamUsage.STREAM_USAGE_VOICE_ASSISTANT,
        rendererFlags: 0
      }
    };
    let renderer: audio.AudioRenderer;
    try {
      renderer = await audio.createAudioRenderer(options);
    } catch (e) {
      return false;
    }
    if (this.released) {
      renderer.release().catch(() => {
      });
      return false;
    }
    try {
      renderer.on('writeData', (buffer: ArrayBuffer): audio.AudioDataCallbackResult => this.onWriteData(buffer));
      renderer.on('audioInterrupt', (event: audio.InterruptEvent) => this.handleInterrupt(event));
      await renderer.setVolume(1.0);
      await renderer.start();
    } catch (e) {
      renderer.release().catch(() => {
      });
      return false;
    }
    if (this.released) {
      this.releaseRenderer(renderer);
      return false;
    }
    this.renderer = renderer;
    this.running = true;
    this.endOfStream = false;
    this.fadeInPending = true;
    this.writtenSamples = 0;
    this.lastRealEndSamples = 0;
    this.startTimeMs = Date.now();
    return true;
  }

  enqueue(pcm: Int16Array): void {
    if (!this.running || pcm.length === 0) {
      return;
    }
    this.queue.push(pcm);
  }

  markEndOfStream(): void {
    this.endOfStream = true;
  }

  flush(): void {
    this.flushEpoch++;
    this.queue = [];
    this.headOffset = 0;
    this.endOfStream = false;
    this.levelValue = 0;
    this.fadeInPending = true;
    this.cancelDrainTimer();
    if (!this.running) {
      return;
    }
    this.renderer?.flush().catch(() => {
    });
  }

  stop(): void {
    this.released = true;
    this.running = false;
    this.queue = [];
    this.headOffset = 0;
    this.levelValue = 0;
    this.cancelDrainTimer();
    const renderer = this.renderer;
    this.renderer = undefined;
    if (renderer) {
      this.releaseRenderer(renderer);
    }
  }

  private releaseRenderer(renderer: audio.AudioRenderer): void {
    try {
      renderer.off('writeData');
      renderer.off('audioInterrupt');
    } catch (e) {
    }
    renderer.stop()
      .catch(() => {
      })
      .finally(() => {
        renderer.release().catch(() => {
        });
      });
  }

  private handleInterrupt(event: audio.InterruptEvent): void {
    if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE ||
      event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) {
      this.onInterrupt?.(false);
      return;
    }
    if (event.hintType === audio.InterruptHint.INTERRUPT_HINT_RESUME) {
      const renderer = this.renderer;
      if (renderer && this.running && renderer.state !== audio.AudioState.STATE_RUNNING) {
        renderer.start().catch(() => {
        });
      }
      this.onInterrupt?.(true);
    }
  }

  private onWriteData(buffer: ArrayBuffer): audio.AudioDataCallbackResult {
    const out = new Int16Array(buffer);
    out.fill(0);
    if (!this.running) {
      return audio.AudioDataCallbackResult.VALID;
    }
    let filled = 0;
    let sum = 0;
    while (filled < out.length && this.queue.length > 0) {
      const head = this.queue[0];
      if (this.headOffset === 0 && this.fadeInPending) {
        this.fadeInPending = false;
        AudioPlaybackEngine.applyFadeIn(head);
      }
      const count = Math.min(out.length - filled, head.length - this.headOffset);
      for (let i = 0; i < count; i++) {
        const sample = head[this.headOffset + i];
        const amplified = Math.max(-32768, Math.min(32767,
          Math.trunc(sample * AudioPlaybackEngine.PLAYBACK_GAIN)));
        out[filled + i] = amplified;
        sum += amplified * amplified;
      }
      filled += count;
      this.headOffset += count;
      if (this.headOffset >= head.length) {
        this.queue.shift();
        this.headOffset = 0;
      }
    }
    if (filled > 0) {
      const rms = Math.sqrt(sum / filled);
      this.levelValue = Math.min(Math.max(rms / AudioPlaybackEngine.LEVEL_FULL_SCALE, 0), 1);
      this.lastRealEndSamples = this.writtenSamples + filled;
    }
    this.writtenSamples += out.length;
    if (this.endOfStream && this.queue.length === 0 && this.drainTimer === undefined) {
      this.scheduleDrain();
    }
    return audio.AudioDataCallbackResult.VALID;
  }

  private scheduleDrain(): void {
    const epoch = this.flushEpoch;
    const samplesPerMs = AIConstants.SAMPLE_RATE / 1000;
    const elapsedMs = Date.now() - this.startTimeMs;
    const remainingMs = Math.max(0, this.lastRealEndSamples / samplesPerMs - elapsedMs);
    const timeoutMs = Math.min(remainingMs + AudioPlaybackEngine.DRAIN_MARGIN_MS,
      AudioPlaybackEngine.DRAIN_TIMEOUT_MAX_MS);
    this.drainTimer = setTimeout(() => {
      this.drainTimer = undefined;
      if (!this.running || epoch !== this.flushEpoch || !this.endOfStream || this.queue.length > 0) {
        return;
      }
      this.endOfStream = false;
      this.levelValue = 0;
      this.onFinished();
    }, timeoutMs);
  }

  private cancelDrainTimer(): void {
    if (this.drainTimer !== undefined) {
      clearTimeout(this.drainTimer);
      this.drainTimer = undefined;
    }
  }

  private static applyFadeIn(chunk: Int16Array): void {
    const n = Math.min(chunk.length, AudioPlaybackEngine.FADE_IN_SAMPLES);
    if (n <= 1) {
      return;
    }
    for (let i = 0; i < n; i++) {
      chunk[i] = Math.trunc(chunk[i] * (i / n));
    }
  }
}
