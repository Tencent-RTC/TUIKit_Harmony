export class TimerUtil {
  /** Format seconds → "MM:SS" or "H:MM:SS" when ≥ 1h. */
  static secondToHMSString(seconds: number): string {
    const total = Math.max(0, Math.floor(seconds));
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    const s = total % 60;
    const mm = m < 10 ? `0${m}` : `${m}`;
    const ss = s < 10 ? `0${s}` : `${s}`;
    if (h > 0) {
      return `${h}:${mm}:${ss}`;
    }
    return `${mm}:${ss}`;
  }

  static schedule(intervalMs: number, callback: () => void): number {
    return setInterval(callback, intervalMs);
  }

  static cancel(handle: number | undefined): void {
    if (handle !== undefined && handle !== null) {
      clearInterval(handle);
    }
  }

  static delay(delayMs: number, callback: () => void): number {
    return setTimeout(callback, delayMs);
  }

  static cancelDelay(handle: number | undefined): void {
    if (handle !== undefined && handle !== null) {
      clearTimeout(handle);
    }
  }
}
