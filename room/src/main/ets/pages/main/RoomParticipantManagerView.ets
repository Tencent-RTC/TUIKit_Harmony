import {
  RoomParticipantStore,
  RoomParticipantState,
  RoomParticipant,
  RoomUser,
  DeviceStatus,
  DeviceType,
  ParticipantRole,
  ErrorInfo,
} from '@tencentcloud/atomicxcore';
import {
  Avatar,
  AvatarContent,
  AvatarContentType,
  AvatarSize,
  AvatarShape,
  Toast,
  AlertDialog,
  RadiusScheme,
} from '@tencentcloud/atomicx';
import { RoomColors } from '../../base/resources/RoomColors';
import { RoomImages } from '../../base/resources/RoomImages';
import { RoomConstants } from '../../base/constants/RoomConstants';
import { ErrorLocalized } from '../../base/error/ErrorLocalized';
import { window } from '@kit.ArkUI';

@Component
export struct RoomParticipantManagerView {
  roomId: string = '';
  participant?: RoomParticipant;
  audience?: RoomUser;
  onClose?: () => void;

  private participantStore?: RoomParticipantStore;
  @State private participantState: RoomParticipantState | undefined = undefined;
  @State private isLandscape: boolean = false;
  private readonly timeout: number = 30;

  aboutToAppear(): void {
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore?.state;
    this.updateOrientation();
  }

  private updateOrientation(): void {
    try {
      const windowInstance = window.getLastWindow(this.getUIContext().getHostContext());
      windowInstance.then((win) => {
        const properties = win.getWindowProperties();
        const rect = properties.windowRect;
        this.isLandscape = rect.width > rect.height;
      });
    } catch (e) {
      this.isLandscape = false;
    }
  }

  build() {
    Column() {
      if (this.participant) {
        this.ParticipantContentBuilder();
      } else if (this.audience) {
        this.AudienceContentBuilder();
      }
    }
    .backgroundColor(RoomColors.g2)
    .borderRadius({ topLeft: RadiusScheme.superLargeRadius, topRight: RadiusScheme.superLargeRadius })
  }

  @Builder
  ParticipantContentBuilder() {
    Column() {
      this.DropDownButtonBuilder();
      this.UserHeaderBuilder({
        displayName: this.getParticipantDisplayName(this.getCurrentParticipant()),
        avatarURL: this.getCurrentParticipant().avatarURL,
        userName: this.getCurrentParticipant().userName,
        isLocal: this.isLocalParticipant(),
        role: this.getCurrentParticipant().role,
      });
      Column() {
        Scroll() {
          Column() {
            if (this.isWebinar()) {
              this.SetParticipantControlBuilder({ userID: this.getCurrentParticipant().userID, isParticipant: true });
              this.DividerBuilder();
            }
            if (!this.isLocalParticipant()) {
              this.AudioControlBuilder({ participant: this.getCurrentParticipant() });
              this.DividerBuilder();
              if (!this.isWebinar()) {
                this.VideoControlBuilder({ participant: this.getCurrentParticipant() });
              }
              this.DividerBuilder();
            }
            if (this.isLocalOwner() && !this.isLocalParticipant()) {
              this.TransferOwnerControlBuilder({ participant: this.getCurrentParticipant() });
              this.DividerBuilder();
              this.AdminControlBuilder({
                userID: this.getCurrentParticipant().userID,
                displayName: this.getParticipantDisplayName(this.getCurrentParticipant()),
                isAdmin: this.getCurrentParticipant().role === ParticipantRole.admin,
              });
              this.DividerBuilder();
            }
            if (this.canManage() && !this.isLocalParticipant()) {
              this.KickControlBuilder({
                userID: this.getCurrentParticipant().userID,
                displayName: this.getParticipantDisplayName(this.getCurrentParticipant()),
              });
            }
          }
        }
      }
      .constraintSize({ maxHeight: this.isLandscape ? 295 : undefined })
      .margin({ top: 10 })
    }
    .padding({ top: this.isLandscape ? 20 : 10, bottom: 20 })
  }

  @Builder
  AudienceContentBuilder() {
    Column() {
      this.DropDownButtonBuilder();
      this.UserHeaderBuilder({
        displayName: this.getAudienceDisplayName(this.getCurrentAudience()),
        avatarURL: this.getCurrentAudience().avatarURL,
        userName: this.getCurrentAudience().userName,
        role: this.isAudienceAdmin() ? ParticipantRole.admin : undefined,
      });
      Column() {
        Scroll() {
          Column() {
            this.SetParticipantControlBuilder({ userID: this.getCurrentAudience().userID, isParticipant: false });
            this.DividerBuilder();
            this.KickControlBuilder({
              userID: this.getCurrentAudience().userID,
              displayName: this.getAudienceDisplayName(this.getCurrentAudience()),
            });
          }
        }
      }
      .constraintSize({ maxHeight: this.isLandscape ? 295 : undefined })
      .margin({ top: 10 })
    }
    .padding({ top: this.isLandscape ? 20 : 10, bottom: 20 })
  }

  @Builder
  DropDownButtonBuilder() {
    Row() {
      Image(RoomImages.roomLine)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height(35)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onClose?.();
    })
  }

  @Builder
  DividerBuilder() {
    Divider()
      .strokeWidth(1)
      .color(RoomColors.dividerGreyWith10Alpha)
      .margin({ left: 16, right: 16 })
  }

  @Builder
  UserHeaderBuilder(params: UserHeaderParams) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: params.avatarURL,
        } as AvatarContent,
        avatarSize: AvatarSize.M,
        shape: AvatarShape.Round,
      })

      Column() {
        Row() {
          Text(params.displayName)
            .fontSize(16)
            .fontColor(RoomColors.g7)
            .fontWeight(FontWeight.Medium)
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

        if (params.role !== undefined && params.role !== ParticipantRole.generalUser) {
          this.RoleBadgeBuilder({ role: params.role });
        }
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  RoleBadgeBuilder(params: RoleBadgeParams) {
    Row({ space: 2 }) {
      Image(params.role === ParticipantRole.owner ? RoomImages.ownerIcon : RoomImages.adminIcon)
        .width(14)
        .height(14)
        .objectFit(ImageFit.Contain)

      Text(params.role === ParticipantRole.owner
        ? this.getString($r('app.string.roomkit_role_owner'))
        : this.getString($r('app.string.roomkit_role_admin')))
        .fontSize(12)
        .fontColor(params.role === ParticipantRole.owner ? RoomColors.b1d : RoomColors.adminOrange)
    }
    .margin({ top: 4 })
  }

  @Builder
  ControlItemBuilder(params: ControlItemParams) {
    Row() {
      if (params.displayIcon) {
        Image(params.displayIcon)
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .margin({ right: 12 })
      }

      Text(params.displayText)
        .fontSize(16)
        .fontColor(params.textColor ?? RoomColors.white)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      params.onPressed();
    })
  }

  @Builder
  AudioControlBuilder(params: AudioControlParams) {
    if (params.participant.microphoneStatus === DeviceStatus.on) {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_mute')),
        displayIcon: RoomImages.unmuteAudio,
        onPressed: () => {
          this.onClose?.();
          this.handleAudioControl(params.participant);
        },
      });
    } else {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_request_unmute_audio')),
        displayIcon: RoomImages.roomMicOff,
        onPressed: () => {
          this.onClose?.();
          this.handleAudioControl(params.participant);
        },
      });
    }
  }

  @Builder
  VideoControlBuilder(params: VideoControlParams) {
    if (params.participant.cameraStatus === DeviceStatus.on) {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_stop_video')),
        displayIcon: RoomImages.roomCameraOn,
        onPressed: () => {
          this.onClose?.();
          this.handleVideoControl(params.participant);
        },
      });
    } else {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_request_start_video')),
        displayIcon: RoomImages.roomCameraOff,
        onPressed: () => {
          this.onClose?.();
          this.handleVideoControl(params.participant);
        },
      });
    }
  }

  @Builder
  TransferOwnerControlBuilder(params: TransferOwnerControlParams) {
    this.ControlItemBuilder({
      displayText: this.getString($r('app.string.roomkit_transfer_owner')),
      displayIcon: RoomImages.transferOwner,
      onPressed: () => {
        this.onClose?.();
        this.handleTransferOwner(params.participant);
      },
    });
  }

  @Builder
  AdminControlBuilder(params: AdminControlParams) {
    if (params.isAdmin) {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_revoke_admin')),
        displayIcon: RoomImages.setAdmin,
        onPressed: () => {
          this.onClose?.();
          this.handleAdminControl(params.userID, params.displayName, params.isAdmin);
        },
      });
    } else {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_set_admin')),
        displayIcon: RoomImages.setAdmin,
        onPressed: () => {
          this.onClose?.();
          this.handleAdminControl(params.userID, params.displayName, params.isAdmin);
        },
      });
    }
  }

  @Builder
  KickControlBuilder(params: KickControlParams) {
    this.ControlItemBuilder({
      displayText: this.getString($r('app.string.roomkit_remove_member')),
      displayIcon: RoomImages.roomKickOut,
      textColor: RoomColors.exitRed,
      onPressed: () => {
        this.onClose?.();
        this.handleKick(params.userID, params.displayName);
      },
    });
  }

  @Builder
  SetParticipantControlBuilder(params: SetParticipantControlParams) {
    if (params.isParticipant) {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_set_audience')),
        displayIcon: RoomImages.setAdmin,
        onPressed: () => {
          this.onClose?.();
          this.handleSetParticipant(params.userID, params.isParticipant);
        },
      });
    } else {
      this.ControlItemBuilder({
        displayText: this.getString($r('app.string.roomkit_set_participant')),
        displayIcon: RoomImages.setAdmin,
        onPressed: () => {
          this.onClose?.();
          this.handleSetParticipant(params.userID, params.isParticipant);
        },
      });
    }
  }

  private async handleAudioControl(participant: RoomParticipant): Promise<void> {
    if (participant.microphoneStatus === DeviceStatus.on) {
      await this.participantStore?.closeParticipantDevice(participant.userID, DeviceType.microphone);
    } else {
      Toast.info($r('app.string.roomkit_toast_audio_invite_sent'), this.getUIContext());
      try {
        await this.participantStore?.inviteToOpenDevice(participant.userID, DeviceType.microphone, this.timeout);
      } catch (e) {
        const error = e as ErrorInfo;
        Toast.info(ErrorLocalized.convertToErrorMessage(error.code, error.message, this.getUIContext()),
          this.getUIContext());
      }
    }
  }

  private async handleVideoControl(participant: RoomParticipant): Promise<void> {
    if (participant.cameraStatus === DeviceStatus.on) {
      await this.participantStore?.closeParticipantDevice(participant.userID, DeviceType.camera);
    } else {
      Toast.info($r('app.string.roomkit_toast_video_invite_sent'), this.getUIContext());
      try {
        await this.participantStore?.inviteToOpenDevice(participant.userID, DeviceType.camera, this.timeout);
      } catch (e) {
        const error = e as ErrorInfo;
        Toast.info(ErrorLocalized.convertToErrorMessage(error.code, error.message, this.getUIContext()),
          this.getUIContext());
      }
    }
  }

  private handleTransferOwner(participant: RoomParticipant): void {
    const participantDisplayName = this.getParticipantDisplayName(participant);
    const title =
      this.getString($r('app.string.roomkit_msg_transfer_owner_to')).replace('xxx', participantDisplayName);
    const content = `${this.getString($r('app.string.roomkit_msg_transfer_owner_tip'))}？`;
    AlertDialog.show(
      title,
      content,
      $r('app.string.roomkit_cancel'),
      $r('app.string.roomkit_confirm'),
      undefined,
      () => {},
      async () => {
        try {
          await this.participantStore?.transferOwner(participant.userID);
          const msg =
            this.getString($r('app.string.roomkit_toast_owner_transferred')).replace('xxx', participantDisplayName);
          Toast.success(msg, this.getUIContext());
        } catch (_e) {
        }
      },
      this.getUIContext(),
    );
  }

  private async handleAdminControl(userID: string, displayName: string, isAdmin: boolean): Promise<void> {
    if (isAdmin) {
      try {
        await this.participantStore?.revokeAdmin(userID);
        const msg = this.getString($r('app.string.roomkit_toast_admin_revoked')).replace('xxx', displayName);
        Toast.success(msg, this.getUIContext());
      } catch (_e) {
      }
    } else {
      try {
        await this.participantStore?.setAdmin(userID);
        const msg = this.getString($r('app.string.roomkit_toast_admin_set')).replace('xxx', displayName);
        Toast.success(msg, this.getUIContext());
      } catch (_e) {
      }
    }
  }

  private handleKick(userID: string, displayName: string): void {
    const content = this.getString($r('app.string.roomkit_confirm_remove_member')).replace('xxx', displayName);
    AlertDialog.show(
      $r('app.string.roomkit_remove_member'),
      content,
      $r('app.string.roomkit_cancel'),
      $r('app.string.roomkit_confirm'),
      undefined,
      () => {},
      async () => {
        await this.participantStore?.kickUser(userID);
      },
      this.getUIContext(),
    );
  }

  private async handleSetParticipant(userID: string, isParticipant: boolean): Promise<void> {
    try {
      if (isParticipant) {
        await this.participantStore?.demoteParticipantToAudience(userID);
      } else {
        await this.participantStore?.promoteAudienceToParticipant(userID);
      }
    } catch (e) {
      const error = e as ErrorInfo;
      Toast.error(ErrorLocalized.convertToErrorMessage(error.code, error.message, this.getUIContext()),
        this.getUIContext());
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

  private isLocalParticipant(): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return localParticipant?.userID === this.getCurrentParticipant().userID;
  }

  private isLocalOwner(): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return localParticipant?.role === ParticipantRole.owner;
  }

  private isLocalAdmin(): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return localParticipant?.role === ParticipantRole.admin;
  }

  private canManage(): boolean {
    return this.isLocalOwner() || this.isLocalAdmin();
  }

  private isAudienceAdmin(): boolean {
    if (!this.audience) {
      return false;
    }
    const adminList = this.participantState?.adminList ?? [];
    return adminList.some((admin) => admin.userID === this.audience!.userID);
  }

  private isWebinar(): boolean {
    return this.roomId.startsWith(RoomConstants.webinarPrefix);
  }

  private getString(resource: Resource): string {
    return this.getUIContext().getHostContext()?.resourceManager.getStringSync(resource) ?? '';
  }
}

interface UserHeaderParams {
  displayName: string;
  avatarURL: string;
  userName: string;
  isLocal?: boolean;
  role?: ParticipantRole;
}

interface RoleBadgeParams {
  role: ParticipantRole;
}

interface ControlItemParams {
  displayText: string;
  displayIcon?: Resource;
  textColor?: string;
  onPressed: () => void;
}

interface AudioControlParams {
  participant: RoomParticipant;
}

interface VideoControlParams {
  participant: RoomParticipant;
}

interface TransferOwnerControlParams {
  participant: RoomParticipant;
}

interface AdminControlParams {
  userID: string;
  displayName: string;
  isAdmin: boolean;
}

interface KickControlParams {
  userID: string;
  displayName: string;
}

interface SetParticipantControlParams {
  userID: string;
  isParticipant: boolean;
}
