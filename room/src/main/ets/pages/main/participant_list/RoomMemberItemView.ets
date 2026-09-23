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

@Component
export struct RoomMemberItemView {
  roomId: string = '';
  participant?: RoomParticipant;
  audience?: RoomUser;
  onParticipantTap?: (participant: RoomParticipant) => void;
  onAudienceTap?: (audience: RoomUser) => void;

  private participantStore?: RoomParticipantStore;
  @State private participantState: RoomParticipantState | undefined = undefined;
  @State private resolvedParticipant: RoomParticipant | undefined = undefined;
  @State private resolvedAudience: RoomUser | undefined = undefined;

  private listListener: DataChangeListener = {
    onDataReloaded: () => {
      this.refreshFromStore();
    },
    onDataAdd: () => {
      this.refreshFromStore();
    },
    onDataChange: () => {
      this.refreshFromStore();
    },
    onDataDelete: () => {
      this.refreshFromStore();
    },
    onDataMove: () => {
      this.refreshFromStore();
    },
    onDataAdded: () => {
      this.refreshFromStore();
    },
    onDataChanged: () => {
      this.refreshFromStore();
    },
    onDataDeleted: () => {
      this.refreshFromStore();
    },
    onDataMoved: () => {
      this.refreshFromStore();
    },
    onDatasetChange: () => {
      this.refreshFromStore();
    },
  };

  aboutToAppear(): void {
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore?.state;
    this.refreshFromStore();
    if (this.participant) {
      this.participantState?.participantList.registerDataChangeListener(this.listListener);
    } else if (this.audience) {
      this.participantState?.audienceList.registerDataChangeListener(this.listListener);
    }
  }

  aboutToDisappear(): void {
    if (this.participant) {
      this.participantState?.participantList.unregisterDataChangeListener(this.listListener);
    } else if (this.audience) {
      this.participantState?.audienceList.unregisterDataChangeListener(this.listListener);
    }
  }

  private refreshFromStore(): void {
    if (this.participant) {
      const found = this.participantState?.participantList.find(
        (p: RoomParticipant) => p.userID === this.participant!.userID);
      this.resolvedParticipant = found ?? this.participant;
    }
    if (this.audience) {
      const found = this.participantState?.audienceList.find(
        (a: RoomUser) => a.userID === this.audience!.userID);
      this.resolvedAudience = found ?? this.audience;
    }
  }

  build() {
    Column() {
      if (this.participant) {
        this.ParticipantItemBuilder();
      } else if (this.audience) {
        this.AudienceItemBuilder();
      }
    }
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
      this.onParticipantTap?.(this.getCurrentParticipant());
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
      this.onAudienceTap?.(this.getCurrentAudience());
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
    return this.resolvedParticipant ?? this.participant ?? new RoomParticipant();
  }

  private getCurrentAudience(): RoomUser {
    return this.resolvedAudience ?? this.audience ?? new RoomUser();
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

  private getString(resource: Resource, ...args: Array<string | number>): string {
    return this.getUIContext().getHostContext()?.resourceManager.getStringSync(resource, ...args) ?? '';
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
