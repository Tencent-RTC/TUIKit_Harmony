import {
  RoomParticipantStore,
  RoomParticipantState,
  RoomParticipant,
  RoomUser,
  DeviceStatus,
  ParticipantRole,
} from '@tencentcloud/atomicxcore';
import {
  Avatar,
  AvatarContent,
  AvatarContentType,
  AvatarSize,
  AvatarShape,
} from '@tencentcloud/atomicx';
import { RoomColors } from '../../../base/resources/RoomColors';
import { RoomImages } from '../../../base/resources/RoomImages';
import { RoomConstants } from '../../../base/constants/RoomConstants';
import { RoomParticipantManagerView } from '../RoomParticipantManagerView';

@Component
export struct RoomMemberItemView {
  roomId: string = '';
  participant?: RoomParticipant;
  audience?: RoomUser;

  private participantStore?: RoomParticipantStore;
  @State private participantState: RoomParticipantState | undefined = undefined;
  @State private isManagerSheetVisible: boolean = false;
  @State private selectedParticipant: RoomParticipant | undefined = undefined;
  @State private selectedAudience: RoomUser | undefined = undefined;

  aboutToAppear(): void {
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore?.state;
  }

  build() {
    Column() {
      if (this.participant) {
        this.ParticipantItemBuilder();
      } else if (this.audience) {
        this.AudienceItemBuilder();
      }
    }
    .bindSheet($$this.isManagerSheetVisible, this.ManagerSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: false,
      showClose: false,
      backgroundColor: RoomColors.g2,
    })
  }

  @Builder
  ManagerSheetBuilder() {
    RoomParticipantManagerView({
      roomId: this.roomId,
      participant: this.selectedParticipant,
      audience: this.selectedAudience,
      onClose: () => {
        this.isManagerSheetVisible = false;
      },
    })
  }

  @Builder
  ParticipantItemBuilder() {
    Column() {
      Row() {
        this.AvatarBuilder({ avatarURL: this.getCurrentParticipant().avatarURL,
          userName: this.getCurrentParticipant().userName });

        Column() {
          this.ParticipantUserInfoBuilder({
            participant: this.getCurrentParticipant(),
            isLocal: this.isLocalParticipant(this.getCurrentParticipant()),
          });
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)

        Row({ space: 20 }) {
          this.StatusIconsBuilder({ participant: this.getCurrentParticipant() });
        }
        .margin({ left: 12 })
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ bottom: 10 })
    .onClick(() => {
      this.handleParticipantTap(this.getCurrentParticipant());
    })
  }

  @Builder
  AudienceItemBuilder() {
    Column() {
      Row() {
        this.AvatarBuilder({ avatarURL: this.getCurrentAudience().avatarURL,
          userName: this.getCurrentAudience().userName });

        Column() {
          this.AudienceUserInfoBuilder({
            audience: this.getCurrentAudience(),
            isAdmin: this.isAudienceAdmin(this.getCurrentAudience()),
            isLocal: this.isLocalAudience(this.getCurrentAudience()),
          });
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ bottom: 10 })
    .onClick(() => {
      this.handleAudienceTap(this.getCurrentAudience());
    })
  }

  @Builder
  AvatarBuilder(params: AvatarParams) {
    Avatar({
      content: {
        type: AvatarContentType.Image,
        url: params.avatarURL,
      } as AvatarContent,
      avatarSize: AvatarSize.M,
      shape: AvatarShape.Round,
    })
  }

  @Builder
  ParticipantUserInfoBuilder(params: ParticipantInfoParams) {
    Row() {
      Text(this.getParticipantDisplayName(params.participant))
        .fontSize(16)
        .fontColor(RoomColors.g7)
        .fontWeight(FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: '60%' })

      if (params.isLocal) {
        Text(`(${this.getString($r('app.string.roomkit_me'))})`)
          .fontSize(14)
          .fontColor(RoomColors.g7)
          .margin({ left: 4 })
      }
    }

    if (params.participant.role !== ParticipantRole.generalUser) {
      Row({ space: 2 }) {
        Image(params.participant.role === ParticipantRole.owner ? RoomImages.ownerIcon : RoomImages.adminIcon)
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)

        Text(params.participant.role === ParticipantRole.owner
          ? this.getString($r('app.string.roomkit_role_owner'))
          : this.getString($r('app.string.roomkit_role_admin')))
          .fontSize(12)
          .fontColor(params.participant.role === ParticipantRole.owner ? RoomColors.b1d : RoomColors.adminOrange)
      }
      .margin({ top: 2 })
    }
  }

  @Builder
  AudienceUserInfoBuilder(params: AudienceInfoParams) {
    Row() {
      Text(this.getAudienceDisplayName(params.audience))
        .fontSize(16)
        .fontColor(RoomColors.g7)
        .fontWeight(FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: '60%' })

      if (params.isLocal) {
        Text(`(${this.getString($r('app.string.roomkit_me'))})`)
          .fontSize(14)
          .fontColor(RoomColors.g7)
          .margin({ left: 4 })
      }
    }

    if (params.isAdmin) {
      Row({ space: 2 }) {
        Image(RoomImages.adminIcon)
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)

        Text(this.getString($r('app.string.roomkit_role_admin')))
          .fontSize(12)
          .fontColor(RoomColors.adminOrange)
      }
      .margin({ top: 2 })
    }
  }

  @Builder
  StatusIconsBuilder(params: StatusIconParams) {
    if (params.participant.screenShareStatus === DeviceStatus.on && !this.isWebinar()) {
      Image(RoomImages.screenShare)
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    }

    Image(params.participant.microphoneStatus === DeviceStatus.on ? RoomImages.userMicOn : RoomImages.userMicOff)
      .width(20)
      .height(20)
      .objectFit(ImageFit.Contain)

    if (!this.isWebinar()) {
      Image(params.participant.cameraStatus === DeviceStatus.on ? RoomImages.userCameraOn : RoomImages.userCameraOff)
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    }
  }

  private getCurrentParticipant(): RoomParticipant {
    if (!this.participant) {
      return new RoomParticipant();
    }
    const found = this.participantState?.participantList.find((p: RoomParticipant) => p.userID === this.participant!.userID);
    return found ?? this.participant;
  }

  private getCurrentAudience(): RoomUser {
    if (!this.audience) {
      return new RoomUser();
    }
    const found = this.participantState?.audienceList.find((a: RoomUser) => a.userID === this.audience!.userID);
    return found ?? this.audience;
  }

  private isLocalParticipant(participant: RoomParticipant): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return localParticipant?.userID === participant.userID;
  }

  private isLocalAudience(audience: RoomUser): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return localParticipant?.userID === audience.userID;
  }

  private isAudienceAdmin(audience: RoomUser): boolean {
    const adminList = this.participantState?.adminList ?? [];
    return adminList.some((admin) => admin.userID === audience.userID);
  }

  private canControlUser(participant: RoomParticipant): boolean {
    const localParticipant = this.participantState?.localParticipant;
    if (!localParticipant || localParticipant.userID === participant.userID) {
      return false;
    }
    if (localParticipant.role === ParticipantRole.owner) {
      return true;
    }
    if (localParticipant.role === ParticipantRole.admin && participant.role === ParticipantRole.generalUser) {
      return true;
    }
    return false;
  }

  private canControlAudience(audience: RoomUser): boolean {
    const localParticipant = this.participantState?.localParticipant;
    if (!localParticipant || localParticipant.userID === audience.userID) {
      return false;
    }
    if (localParticipant.role === ParticipantRole.owner) {
      return true;
    }
    const isAudienceAdmin = this.isAudienceAdmin(audience);
    if (localParticipant.role === ParticipantRole.admin && !isAudienceAdmin) {
      return true;
    }
    return false;
  }

  private handleParticipantTap(participant: RoomParticipant): void {
    if (!this.canControlUser(participant)) {
      return;
    }
    this.selectedParticipant = participant;
    this.selectedAudience = undefined;
    this.isManagerSheetVisible = true;
  }

  private handleAudienceTap(audience: RoomUser): void {
    if (!this.canControlAudience(audience)) {
      return;
    }
    this.selectedAudience = audience;
    this.selectedParticipant = undefined;
    this.isManagerSheetVisible = true;
  }

  private getParticipantDisplayName(participant: RoomParticipant): string {
    if (participant.nameCard && participant.nameCard.length > 0) {
      return participant.nameCard;
    }
    if (participant.userName && participant.userName.length > 0) {
      return participant.userName;
    }
    return participant.userID;
  }

  private getAudienceDisplayName(audience: RoomUser): string {
    if (audience.userName && audience.userName.length > 0) {
      return audience.userName;
    }
    return audience.userID;
  }

  private isWebinar(): boolean {
    return this.roomId.startsWith(RoomConstants.webinarPrefix);
  }

  private getString(resource: Resource): string {
    return this.getUIContext().getHostContext()?.resourceManager.getStringSync(resource) ?? '';
  }
}

interface AvatarParams {
  avatarURL: string;
  userName: string;
}

interface ParticipantInfoParams {
  participant: RoomParticipant;
  isLocal: boolean;
}

interface AudienceInfoParams {
  audience: RoomUser;
  isAdmin: boolean;
  isLocal: boolean;
}

interface StatusIconParams {
  participant: RoomParticipant;
}
