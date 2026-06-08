import {
  CallParticipantInfo, CallInfo, CallParticipantStatus, CallMediaType,
} from '@tencentcloud/atomicxcore';
import { TUICallKitLocalize } from '../../../../common/Localized';
import { CallConstants } from '../../../../common/CallConstants';

@Component
export struct HintView {
  @ObjectLink selfInfo: CallParticipantInfo;
  @ObjectLink activeCall: CallInfo;

  isCaller: boolean = false;

  /**
   * Caller-only "Connected" toast control. On the first transition into
   * `accept`, show "Connected" for 1s then clear and never show again for
   * this call.
   *
   * `needShowAcceptHint` initial value depends on the mount-time status so
   * a floating window resume doesn't re-fire the toast.
   */
  @State private needShowAcceptHint: boolean = true;
  @State private hasShownAcceptHint: boolean = false;
  private acceptHintTimerId: number = -1;

  aboutToAppear(): void {
    this.needShowAcceptHint = this.selfInfo.status !== CallParticipantStatus.accept;
  }

  aboutToDisappear(): void {
    if (this.acceptHintTimerId !== -1) {
      clearTimeout(this.acceptHintTimerId);
      this.acceptHintTimerId = -1;
    }
  }

  build() {
    Text(this.displayText())
      .fontColor(CallConstants.Color_White)
      .fontSize(15)
      .margin({ top: 20 })
      .visibility(this.displayText().length > 0 ? Visibility.Visible : Visibility.Hidden);
  }

  private displayText(): string {
    // Multi-party + accept → blank. Avoids leaking the "Connected" toast
    // into the multi-call ACK state.
    if (this.selfInfo.status === CallParticipantStatus.accept && this.isMultiParty()) {
      return '';
    }

    if (this.selfInfo.status === CallParticipantStatus.waiting) {
      return this.waitingText();
    }

    if (this.selfInfo.status === CallParticipantStatus.accept
      && this.isCaller
      && this.needShowAcceptHint) {
      this.scheduleAcceptHintDismiss();
      return TUICallKitLocalize('TUICallKit.accept');
    }

    return '';
  }

  private waitingText(): string {
    if (this.isMultiParty()) {
      return TUICallKitLocalize('TUICallKit.Group.inviteToGroupCall');
    }
    if (this.isCaller) {
      return TUICallKitLocalize('TUICallKit.waitAccept');
    }
    return this.activeCall.mediaType === CallMediaType.video
      ? TUICallKitLocalize('TUICallKit.inviteToVideoCall')
      : TUICallKitLocalize('TUICallKit.inviteToAudioCall');
  }

  private isMultiParty(): boolean {
    if ((this.activeCall.chatGroupId?.length ?? 0) > 0) {
      return true;
    }
    return (this.activeCall.inviteeIds?.length ?? 0) > 1;
  }

  /** Called from displayText() during build; guarded by `hasShownAcceptHint`. */
  private scheduleAcceptHintDismiss(): void {
    if (this.hasShownAcceptHint) {
      return;
    }
    this.hasShownAcceptHint = true;
    this.acceptHintTimerId = setTimeout(() => {
      this.needShowAcceptHint = false;
      this.acceptHintTimerId = -1;
    }, 1000);
  }
}
