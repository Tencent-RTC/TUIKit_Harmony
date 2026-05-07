import {
  RoomParticipant,
  RoomParticipantStore,
  RoomParticipantState,
  RoomParticipantController,
  RoomParticipantView,
  VideoStreamType,
  FillMode,
  DeviceStatus,
} from '@tencentcloud/atomicxcore';
import { Avatar, AvatarContent, AvatarContentType, AvatarSize, AvatarShape, RadiusScheme } from '@tencentcloud/atomicx';
import { RoomColors } from '../../../base/resources/RoomColors';
import { ParticipantUserInfoView } from './ParticipantUserInfoView';

@Component
export struct ParticipantVideoItemView {
  roomId: string = '';
  @Prop participant: RoomParticipant = new RoomParticipant();
  @Prop @Watch('onStreamTypeChanged') isScreenStream: boolean = false;
  @Prop @Watch('onCameraStatusChanged') cameraStatus: DeviceStatus = DeviceStatus.off;
  @Prop @Watch('onScreenShareStatusChanged') screenShareStatus: DeviceStatus = DeviceStatus.off;

  itemWidth: number | string = '100%';
  itemHeight: number | string = '100%';
  radius: number = RadiusScheme.largeRadius;

  @State private participantState: RoomParticipantState = new RoomParticipantState();
  private controller?: RoomParticipantController;
  private controllerUserId: string = '';
  private isVisible: boolean = false;

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomId).state;
    this.createController();
  }

  aboutToDisappear(): void {
    this.clearController();
  }

  onCameraStatusChanged(): void {
    this.syncControllerState();
  }

  onScreenShareStatusChanged(): void {
    this.syncControllerState();
  }

  onStreamTypeChanged(): void {
    this.clearController();
    this.createController();
    if (this.isVisible) {
      this.setControllerActive(true);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.controller) {
        RoomParticipantView({ controller: this.controller })
      }

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#22262E')
        .visibility(!this.hasVideo(this.getCurrentParticipant()) && !this.isScreenStream
          ? Visibility.Visible : Visibility.Hidden)

      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: this.getCurrentParticipant().avatarURL,
        } as AvatarContent,
        avatarSize: AvatarSize.XXL,
        shape: AvatarShape.Round,
      })
        .visibility(!this.hasVideo(this.getCurrentParticipant()) && !this.isScreenStream
          ? Visibility.Visible : Visibility.Hidden)

      if (this.isSpeaking(this.getCurrentParticipant().userID) && !this.isScreenStream) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(this.radius)
          .border({
            width: 3,
            color: RoomColors.fluorescentGreen,
          })
      }

      Column() {
        Blank().layoutWeight(1)

        Row() {
          ParticipantUserInfoView({
            roomId: this.roomId,
            participant: this.getCurrentParticipant(),
          })
        }
        .padding({ left: 7, right: 7, bottom: 4 })
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(this.isScreenStream ? HitTestMode.Transparent : HitTestMode.Default)
    }
    .width(this.itemWidth)
    .height(this.itemHeight)
    .borderRadius(this.radius)
    .clip(true)
    .hitTestBehavior(this.isScreenStream ? HitTestMode.Transparent : HitTestMode.Default)
    .onVisibleAreaChange([0.5], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio >= 0.5) {
        if (!this.isVisible) {
          this.isVisible = true;
          if (!this.controller) {
            this.createController();
          }
          this.setControllerActive(true);
        }
      } else {
        if (this.isVisible) {
          this.isVisible = false;
          this.setControllerActive(false);
        }
      }
    })
  }

  private getCurrentParticipant(): RoomParticipant {
    return this.participantState.participantList.find((p: RoomParticipant) => p.userID === this.participant.userID) ?? this.participant;
  }

  private createController(): void {
    if (this.controller) {
      return;
    }
    const currentParticipant = this.getCurrentParticipant();
    const streamType = this.getExpectedStreamType();
    
    this.controller = RoomParticipantController.create(streamType, currentParticipant);
    this.controller.setFillMode(streamType === VideoStreamType.screen ? FillMode.fit : FillMode.fill);
    
    this.controllerUserId = currentParticipant.userID;
  }

  private setControllerActive(active: boolean): void {
    if (this.controller) {
      this.controller.setActive(active);
    }
  }

  private syncControllerState(): void {
    const currentParticipant = this.getCurrentParticipant();

    if (!this.controller) {
      this.createController();
      if (this.isVisible) {
        this.setControllerActive(true);
      }
      return;
    }

    if (this.controllerUserId !== currentParticipant.userID) {
      this.clearController();
      this.createController();
      if (this.isVisible) {
        this.setControllerActive(true);
      }
      return;
    }

    this.controller.updateParticipant(currentParticipant);
  }

  private clearController(): void {
    if (this.controller) {
      this.controller.setActive(false);
      this.controller = undefined;
    }
    this.controllerUserId = '';
  }

  private getExpectedStreamType(): VideoStreamType {
    return this.isScreenStream ? VideoStreamType.screen : VideoStreamType.camera;
  }

  private hasVideo(currentParticipant: RoomParticipant): boolean {
    return this.isScreenStream 
      ? currentParticipant.screenShareStatus === DeviceStatus.on
      : currentParticipant.cameraStatus === DeviceStatus.on;
  }

  private isSpeaking(userId: string): boolean {
    const volume = this.participantState.speakingUsers?.get(userId) ?? 0;
    return volume >= 10;
  }
}