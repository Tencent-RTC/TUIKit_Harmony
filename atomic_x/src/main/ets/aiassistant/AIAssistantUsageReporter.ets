import { V2TIMManager } from '@tencentcloud/imsdk';

interface FeatureUsageParam {
  UIComponentType: number;
}

export class AIAssistantUsageReporter {
  private static readonly MESSAGE_USAGE: number = 1022;
  private static readonly VOICE_ENTRY: number = 1023;
  private hasReportedMessageUsage: boolean = false;
  private readonly report: (type: number) => void;

  constructor(report?: (type: number) => void) {
    this.report = report ?? AIAssistantUsageReporter.reportFeatureUsage;
  }

  onMessageSent(): void {
    if (this.hasReportedMessageUsage) {
      return;
    }
    this.hasReportedMessageUsage = true;
    this.report(AIAssistantUsageReporter.MESSAGE_USAGE);
  }

  onVoiceEntered(): void {
    this.report(AIAssistantUsageReporter.VOICE_ENTRY);
  }

  private static reportFeatureUsage(type: number): void {
    const param: FeatureUsageParam = { UIComponentType: type };
    try {
      const promise = V2TIMManager.getInstance().callExperimentalAPI('reportTUIFeatureUsage', JSON.stringify(param));
      promise?.catch(() => {
      });
    } catch (e) {
      return;
    }
  }
}
