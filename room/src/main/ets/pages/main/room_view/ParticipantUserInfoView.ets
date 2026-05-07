import {
  RoomParticipant,
  RoomParticipantStore,
  RoomParticipantState,
  ParticipantRole,
  DeviceStatus,
} from '@tencentcloud/atomicxcore';
import { RoomColors } from '../../../base/resources/RoomColors';
import { RoomImages } from '../../../base/resources/RoomImages';

@Component
export struct ParticipantUserInfoView {
  roomId: string = '';
  @Prop participant: RoomParticipant = new RoomParticipant();

  @State private participantState: RoomParticipantState = new RoomParticipantState();

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomId).state;
  }

  build() {
    Row() {
      if (this.participant.role === ParticipantRole.owner ||
        this.participant.role === ParticipantRole.admin) {
        Image(this.participant.role === ParticipantRole.owner
          ? RoomImages.roomOwner
          : RoomImages.roomAdministrator)
          .width(24)
          .height(24)
          .borderRadius(12)
          .clip(true)
      }

      Blank()
        .width(4)

      Image(this.participant.microphoneStatus === DeviceStatus.on
        ? RoomImages.roomMicOnEmpty
        : RoomImages.roomMicOff)
        .width(14)
        .height(14)

      Blank()
        .width(4)

      Text(this.getDisplayName())
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(RoomColors.white)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 120 })

      Blank()
        .width(4)
    }
    .height(24)
    .backgroundColor(RoomColors.translucentLightBlack)
    .borderRadius(12)
    .alignItems(VerticalAlign.Center)
  }

  private getDisplayName(): string {
    if (this.participant.nameCard.length > 0) {
      return this.participant.nameCard;
    }
    if (this.participant.userName.length > 0) {
      return this.participant.userName;
    }
    return this.participant.userID;
  }
}
