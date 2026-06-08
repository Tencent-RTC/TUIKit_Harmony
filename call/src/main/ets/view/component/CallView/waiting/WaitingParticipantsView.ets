import { CallInfo, CallParticipantInfo, CallParticipantStatus } from '@tencentcloud/atomicxcore';
import { CallConstants } from '../../../../common/CallConstants';
import { TUICallKitLocalize } from '../../../../common/Localized';
import { UserManager } from '../../../../manager/UserManager';
import { WaitingParticipantsCell } from './WaitingParticipantsCell';

@Component
export struct WaitingParticipantsView {
  @ObjectLink activeCall: CallInfo;
  @ObjectLink allParticipants: CallParticipantInfo[];
  selfId: string = '';

  build() {
    Column({ space: 16 }) {
      this.callerHeader();

      if (this.otherParticipants().length > 0) {
        Text(TUICallKitLocalize('TUICallKit.calleeTip'))
          .fontColor(CallConstants.Color_White)
          .fontSize(12)
          .margin({ top: 16 });

        Row({ space: 12 }) {
          ForEach(this.otherParticipants(), (p: CallParticipantInfo): void => {
            WaitingParticipantsCell({ participant: p });
          }, (p: CallParticipantInfo): string => p.id);
        }
        .width('100%')
        .padding({ left: 32, right: 32 })
        .justifyContent(FlexAlign.Center);
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%');
  }

  @Builder
  callerHeader() {
    Column({ space: 8 }) {
      if (this.findCaller() && this.findCaller()!.avatarURL && this.findCaller()!.avatarURL!.length > 0) {
        Image(this.findCaller()!.avatarURL!)
          .width(CallConstants.mainAvatarSize)
          .height(CallConstants.mainAvatarSize)
          .borderRadius(6)
          .alt($r('app.media.default_user_icon'));
      } else {
        Image($r('app.media.default_user_icon'))
          .width(CallConstants.mainAvatarSize)
          .height(CallConstants.mainAvatarSize)
          .borderRadius(6);
      }
      Text(this.findCaller() ? UserManager.getUserDisplayName(this.findCaller()) : '')
        .fontColor(CallConstants.Color_White)
        .fontSize(18)
        .fontWeight(FontWeight.Bold);
      Text(TUICallKitLocalize('TUICallKit.Group.inviteToGroupCall'))
        .fontColor(CallConstants.Color_OweWhite)
        .fontSize(13);
    }
    .alignItems(HorizontalAlign.Center);
  }

  private findCaller(): CallParticipantInfo | undefined {
    const inviterId = this.activeCall.inviterId;
    return this.allParticipants.find((p: CallParticipantInfo): boolean => p.id === inviterId);
  }

  /** All participants other than the caller and self, capped at MAX_PARTICIPANT. */
  private otherParticipants(): CallParticipantInfo[] {
    const inviterId = this.activeCall.inviterId;
    const filtered = this.allParticipants.filter((p: CallParticipantInfo): boolean => {
      return p.id !== inviterId && p.id !== this.selfId
        && p.status === CallParticipantStatus.waiting;
    });
    return filtered.slice(0, CallConstants.MAX_PARTICIPANT);
  }
}
