export class EnergyVad {
  private static readonly MAX_ACCUM_MS: number = 60000;
  private static readonly MIN_CALIBRATION_RMS: number = 1.0;
  private static readonly CALIBRATION_ATTEMPT_FACTOR: number = 4;

  private readonly frameDurationMs: number;
  private readonly calibrationFrames: number;
  private readonly silenceThresholdFactor: number;
  private readonly speechThresholdFactor: number;
  private readonly minNoiseFloor: number;
  private readonly maxNoiseFloor: number;
  private readonly speechHangoverMs: number;
  private noiseFloor: number = Number.POSITIVE_INFINITY;
  private calibratedFrames: number = 0;
  private calibrationAttempts: number = 0;
  private silenceAccumMs: number = 0;
  private speechAccumMs: number = 0;
  private speechGapMs: number = 0;

  constructor(frameDurationMs: number = 20, calibrationFrames: number = 15, silenceThresholdFactor: number = 2.0,
    speechThresholdFactor: number = 2.5, minNoiseFloor: number = 100.0, maxNoiseFloor: number = 2000.0,
    speechHangoverMs: number = 240) {
    this.frameDurationMs = frameDurationMs;
    this.calibrationFrames = calibrationFrames;
    this.minNoiseFloor = minNoiseFloor;
    this.silenceThresholdFactor = silenceThresholdFactor;
    this.speechThresholdFactor = speechThresholdFactor;
    this.maxNoiseFloor = maxNoiseFloor;
    this.speechHangoverMs = speechHangoverMs;
  }

  get isCalibrated(): boolean {
    return this.calibratedFrames >= this.calibrationFrames ||
      this.calibrationAttempts >= this.calibrationFrames * EnergyVad.CALIBRATION_ATTEMPT_FACTOR;
  }

  get effectiveNoiseFloor(): number {
    if (!Number.isFinite(this.noiseFloor)) {
      return this.minNoiseFloor;
    }
    return Math.min(Math.max(this.noiseFloor, this.minNoiseFloor), this.maxNoiseFloor);
  }

  get speechAccumulationMs(): number {
    return this.speechAccumMs;
  }

  get silenceAccumulationMs(): number {
    return this.silenceAccumMs;
  }

  reset(): void {
    this.silenceAccumMs = 0;
    this.speechAccumMs = 0;
    this.speechGapMs = 0;
  }

  resetCalibration(): void {
    this.noiseFloor = Number.POSITIVE_INFINITY;
    this.calibratedFrames = 0;
    this.calibrationAttempts = 0;
    this.reset();
  }

  accept(pcm: Int16Array): number {
    const rms = EnergyVad.rms(pcm);
    if (!this.isCalibrated) {
      this.calibrationAttempts++;
      if (rms >= EnergyVad.MIN_CALIBRATION_RMS) {
        this.noiseFloor = Math.min(this.noiseFloor, rms);
        this.calibratedFrames++;
      }
      return rms;
    }
    const floor = this.effectiveNoiseFloor;
    if (rms < floor * this.silenceThresholdFactor) {
      this.silenceAccumMs = Math.min(this.silenceAccumMs + this.frameDurationMs, EnergyVad.MAX_ACCUM_MS);
    } else {
      this.silenceAccumMs = 0;
    }
    if (rms > floor * this.speechThresholdFactor) {
      this.speechGapMs = 0;
      this.speechAccumMs = Math.min(this.speechAccumMs + this.frameDurationMs, EnergyVad.MAX_ACCUM_MS);
    } else if (this.speechAccumMs > 0) {
      this.speechGapMs += this.frameDurationMs;
      if (this.speechGapMs >= this.speechHangoverMs) {
        this.speechAccumMs = 0;
        this.speechGapMs = 0;
      }
    }
    return rms;
  }

  hasSilenceFor(holdMs: number): boolean {
    return this.isCalibrated && this.silenceAccumMs >= holdMs;
  }

  hasSpeechFor(holdMs: number): boolean {
    return this.isCalibrated && this.speechAccumMs >= holdMs;
  }

  private static rms(pcm: Int16Array): number {
    if (pcm.length === 0) {
      return 0;
    }
    let sum = 0;
    for (let i = 0; i < pcm.length; i++) {
      const v = pcm[i];
      sum += v * v;
    }
    return Math.sqrt(sum / pcm.length);
  }
}
