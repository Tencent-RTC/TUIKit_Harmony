import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x2727;
const TAG: string = 'TUICallKit';

export class Logger {
  static debug(...args: Object[]): void {
    hilog.debug(DOMAIN, TAG, '%{public}s', Logger.format(args));
  }

  static info(...args: Object[]): void {
    hilog.info(DOMAIN, TAG, '%{public}s', Logger.format(args));
  }

  static warn(...args: Object[]): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', Logger.format(args));
  }

  static error(...args: Object[]): void {
    hilog.error(DOMAIN, TAG, '%{public}s', Logger.format(args));
  }

  private static format(args: Object[]): string {
    return args.map((v: Object): string => {
      if (v === null || v === undefined) {
        return String(v);
      }
      if (typeof v === 'string') {
        return v;
      }
      try {
        return JSON.stringify(v);
      } catch (_e) {
        return String(v);
      }
    }).join(' ');
  }
}
