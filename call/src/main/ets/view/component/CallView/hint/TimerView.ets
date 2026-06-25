// Shows either the "Waiting" hint or the HMS-formatted call duration.
//
// Visibility rules:
//   status == accept                    → show HMS duration
//   1:1 waiting                         → hide
//   multi-party callee waiting          → hide
//   multi-party caller waiting          → show "Waiting"
//
// Why a local clock (not `activeCall.duration`): atomicxcore's
// `CallInfo.duration` is documented to auto-increment per second, but on
// HarmonyOS that is not implemented — the field stays at 0 from accept
// through hangup. We capture `Date.now()` on the first `accept` transition
// and recompute every 1Hz tick. The 1Hz pulse is delivered by mutating
// `@State refreshTick`, which marks this component dirty and re-runs build()
// → displayText().

import { CallParticipantInfo, CallInfo, CallParticipantStatus } from '@tencentcloud/atomicxcore';
import { TimerUtil } from '../../../../common/utils/TimerUtil';
import { TUICallKitLocalize } from '../../../../common/Localized';
import { CallConstants } from '../../../../common/CallConstants';

@Component
export struct TimerView {
  @ObjectLink selfInfo: CallParticipantInfo;
  @ObjectLink activeCall: CallInfo;

  /** Numeric value is irrelevant — only the mutation matters for ArkUI's @State change-tracking. */
  @State private refreshTick: number = 0;

  /** 0 = "not started yet". Never reset once set; the next call gets a fresh component instance. */
  private startTimeMs: number = 0;

  private intervalId: number = -1;

  aboutToAppear(): void {
    this.intervalId = setInterval((): void => {
      this.refreshTick = this.refreshTick + 1;
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
  }

  build() {
    // ArkUI's @Component build() requires exactly one root *container* node
    // and disallows free statements alongside it; the ensureStartTime()
    // side-effect lives inside displayText() instead.
    Column() {
      Text(this.displayText())
        .fontColor(CallConstants.Color_White)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .visibility(this.shouldShow() ? Visibility.Visible : Visibility.Hidden);
    };
  }

  private ensureStartTime(): void {
    if (this.startTimeMs !== 0) {
      return;
    }
    if (this.selfInfo.status === CallParticipantStatus.accept) {
      this.startTimeMs = Date.now();
    }
  }

  private displayText(): string {
    this.ensureStartTime();

    // Read refreshTick so this method's call-site (build()) registers a
    // dependency on it — ArkUI's tracker only counts *reads* during build,
    // not writes.
    const _tick: number = this.refreshTick;
    void _tick;

    if (this.selfInfo.status === CallParticipantStatus.accept) {
      if (this.startTimeMs === 0) {
        return TimerUtil.secondToHMSString(0);
      }
      const elapsedMs: number = Date.now() - this.startTimeMs;
      const seconds: number = Math.max(0, Math.floor(elapsedMs / 1000));
      return TimerUtil.secondToHMSString(seconds);
    }
    return TUICallKitLocalize('TUICallKit.waitAccept');
  }

  private shouldShow(): boolean {
    if (this.selfInfo.status === CallParticipantStatus.accept) {
      return true;
    }

    const isOneToOne = (this.activeCall.chatGroupId?.length ?? 0) === 0
      && (this.activeCall.inviteeIds?.length ?? 0) <= 1;
    if (isOneToOne) {
      return false;
    }

    if (this.selfInfo.status === CallParticipantStatus.waiting) {
      const isCaller = this.activeCall.inviterId === this.selfInfo.id;
      return isCaller;
    }

    return true;
  }
}
