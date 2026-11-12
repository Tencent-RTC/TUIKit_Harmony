import { AIConstants } from '../AIConstants';
import { AudioPlaybackEngine } from './AudioPlaybackEngine';
import { SystemOpusDecoder } from './SystemOpusDecoder';

export class TtsDecodeWorker {
  private readonly playback: AudioPlaybackEngine;
  private readonly onChunkDecoded: (generation: number, decodedMs: number, isFinished: boolean) => void;
  private decoder?: SystemOpusDecoder;
  private released: boolean = false;
  private generationValue: number = 0;

  constructor(playback: AudioPlaybackEngine,
    onChunkDecoded: (generation: number, decodedMs: number, isFinished: boolean) => void) {
    this.playback = playback;
    this.onChunkDecoded = onChunkDecoded;
  }

  get generation(): number {
    return this.generationValue;
  }

  beginStream(): void {
    if (this.released) {
      return;
    }
    if (this.decoder) {
      this.decoder.reset();
    } else {
      this.ensureDecoder();
    }
  }

  decode(packets: ArrayBuffer[], isFinished: boolean): void {
    if (this.released) {
      return;
    }
    const gen = this.generationValue;
    const decoder = this.ensureDecoder();
    if (decoder) {
      decoder.decode(packets, isFinished, gen);
      return;
    }
    if (isFinished) {
      this.playback.markEndOfStream();
    }
    this.onChunkDecoded(gen, 0, isFinished);
  }

  invalidate(): void {
    this.generationValue++;
    this.decoder?.reset();
  }

  release(): void {
    this.generationValue++;
    this.released = true;
    this.decoder?.release();
    this.decoder = undefined;
  }

  private ensureDecoder(): SystemOpusDecoder | undefined {
    if (!this.decoder && !this.released) {
      this.decoder = SystemOpusDecoder.create((tag: number, pcm: ArrayBuffer, finished: boolean) => {
        this.handleChunk(tag, pcm, finished);
      });
    }
    return this.decoder;
  }

  private handleChunk(tag: number, pcm: ArrayBuffer, finished: boolean): void {
    if (this.released || tag !== this.generationValue) {
      return;
    }
    const samples = new Int16Array(pcm);
    if (samples.length > 0) {
      this.playback.enqueue(samples);
    }
    if (finished) {
      this.playback.markEndOfStream();
    }
    this.onChunkDecoded(tag, samples.length * 1000 / AIConstants.SAMPLE_RATE, finished);
  }
}
