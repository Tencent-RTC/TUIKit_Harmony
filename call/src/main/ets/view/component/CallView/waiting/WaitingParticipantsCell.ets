import { CallParticipantInfo } from '@tencentcloud/atomicxcore';
import { CallConstants } from '../../../../common/CallConstants';

@Component
export struct WaitingParticipantsCell {
  @ObjectLink participant: CallParticipantInfo;

  build() {
    Stack() {
      if (this.participant.avatarURL && this.participant.avatarURL.length > 0) {
        Image(this.participant.avatarURL)
          .width(CallConstants.waitingCellAvatarSize)
          .height(CallConstants.waitingCellAvatarSize)
          .borderRadius(2)
          .alt($r('app.media.default_participant_icon'))
          .objectFit(ImageFit.Cover);
      } else {
        Image($r('app.media.default_participant_icon'))
          .width(CallConstants.waitingCellAvatarSize)
          .height(CallConstants.waitingCellAvatarSize)
          .borderRadius(2)
          .objectFit(ImageFit.Cover);
      }
    }
    .width(CallConstants.waitingCellAvatarSize)
    .height(CallConstants.waitingCellAvatarSize);
  }
}
