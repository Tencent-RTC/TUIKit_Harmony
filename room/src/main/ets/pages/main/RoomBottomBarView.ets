import {
  RoomStore,
  RoomState,
  RoomParticipantStore,
  RoomParticipantState,
  RoomParticipant,
  DeviceStatus,
  ParticipantRole,
  LoginStore,
} from '@tencentcloud/atomicxcore';
import { RadiusScheme } from '@tencentcloud/atomicx';
import { RoomColors } from '../../base/resources/RoomColors';
import { RoomImages } from '../../base/resources/RoomImages';
import { RoomConstants } from '../../base/constants/RoomConstants';
import { DeviceOperator } from '../../base/operator/DeviceOperator';
import { RoomParticipantListView } from './RoomParticipantListView';

@Component
export struct RoomBottomBarView {
  roomId: string = '';
  onDismissSheets?: (dismiss: () => void) => void;

  private roomStore: RoomStore = RoomStore.shared();
  private participantStore?: RoomParticipantStore;
  @State private roomState: RoomState = RoomStore.shared().state;
  @State private participantState: RoomParticipantState | undefined = undefined;
  @State private isMemberListSheetVisible: boolean = false;

  aboutToAppear(): void {
    this.onDismissSheets?.(() => {
      this.isMemberListSheetVisible = false;
    });
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore?.state;
  }

  build() {
    if (this.isWebinar()) {
      this.WebinarContentBuilder();
    } else {
      this.StandardContentBuilder();
    }
  }

  @Builder
  StandardContentBuilder() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height(86)
        .backgroundColor(RoomColors.darkBlack)

      Column() {
        Row() {
          this.MemberButtonBuilder();
          this.MicrophoneButtonBuilder();
          this.CameraButtonBuilder();
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        .padding({ left: 16, right: 16, top: 5, bottom: 5 })
      }
    }
    .width('100%')
  }

  @Builder
  WebinarContentBuilder() {
    Row({ space: 8 }) {
      if (this.isSelfInParticipantList()) {
        this.MicrophoneButtonBuilder();
      }
      this.MemberButtonBuilder();
    }
  }

  @Builder
  MemberButtonBuilder() {
    Column() {
      this.ButtonItemBuilder({
        icon: RoomImages.roomMember,
        text: this.getMemberCountText(),
        isWebinar: this.isWebinar(),
        onPressed: () => {
          this.handleMembersPressed();
        },
      });
    }
    .bindSheet($$this.isMemberListSheetVisible, this.memberListSheetBuilder(), {
      height: 650,
      dragBar: false,
      showClose: false,
      backgroundColor: RoomColors.g2,
    })
  }

  @Builder
  MicrophoneButtonBuilder() {
    this.ButtonItemBuilder({
      icon: RoomImages.roomMicOff,
      selectedIcon: RoomImages.roomMicOnEmpty,
      text: this.participantState?.localParticipant?.microphoneStatus === DeviceStatus.on
        ? this.getString($r('app.string.roomkit_mute'))
        : this.getString($r('app.string.roomkit_unmute')),
      isSelected: this.participantState?.localParticipant?.microphoneStatus === DeviceStatus.on,
      opacity: this.isMicDisabledByAdmin() ? 0.5 : 1,
      isWebinar: this.isWebinar(),
      onPressed: () => {
        this.handleMicToggle();
      },
    });
  }

  @Builder
  CameraButtonBuilder() {
    this.ButtonItemBuilder({
      icon: RoomImages.roomCameraOff,
      selectedIcon: RoomImages.roomCameraOn,
      text: this.participantState?.localParticipant?.cameraStatus === DeviceStatus.on
        ? this.getString($r('app.string.roomkit_stop_video'))
        : this.getString($r('app.string.roomkit_start_video')),
      isSelected: this.participantState?.localParticipant?.cameraStatus === DeviceStatus.on,
      opacity: this.isCameraDisabledByAdmin() ? 0.5 : 1,
      onPressed: () => {
        this.handleCameraToggle();
      },
    });
  }

  @Builder
  ButtonItemBuilder(params: ButtonItemParams) {
    Column() {
      Image(params.isSelected && params.selectedIcon ? params.selectedIcon : params.icon)
        .width(params.isWebinar ? 20 : 24)
        .height(params.isWebinar ? 20 : 24)
        .objectFit(ImageFit.Contain)

      Text(params.text)
        .fontSize(params.isWebinar ? 8 : 10)
        .minFontSize(params.isWebinar ? 5 : 6)
        .maxFontSize(params.isWebinar ? 8 : 10)
        .fontColor(RoomColors.white)
        .fontWeight(FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: params.isWebinar ? 3 : 5 })
    }
    .width(params.isWebinar ? 40 : 52)
    .height(params.isWebinar ? 40 : 52)
    .backgroundColor(RoomColors.lightGrey)
    .borderRadius(RadiusScheme.smallRadius)
    .justifyContent(FlexAlign.Center)
    .opacity(params.opacity ?? 1)
    .onClick(() => {
      params.onPressed();
    })
  }

  @Builder
  memberListSheetBuilder() {
    RoomParticipantListView({
      roomId: this.roomId,
      onClose: () => {
        this.isMemberListSheetVisible = false;
      },
    })
  }

  private isWebinar(): boolean {
    return this.roomId.startsWith(RoomConstants.webinarPrefix);
  }

  private getString(resource: Resource): string {
    return this.getUIContext().getHostContext()?.resourceManager.getStringSync(resource) ?? '';
  }

  private getMemberCountText(): string {
    if (this.isWebinar()) {
      return this.getString($r('app.string.roomkit_member'));
    }
    const count = this.roomState.currentRoom?.participantCount ?? 0;
    return this.getString($r('app.string.roomkit_member_count')).replace('xxx', count.toString());
  }

  private isMicDisabledByAdmin(): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return this.roomState.currentRoom?.isAllMicrophoneDisabled === true
      && localParticipant?.role === ParticipantRole.generalUser
      && localParticipant?.microphoneStatus === DeviceStatus.off;
  }

  private isCameraDisabledByAdmin(): boolean {
    const localParticipant = this.participantState?.localParticipant;
    return this.roomState.currentRoom?.isAllCameraDisabled === true
      && localParticipant?.role === ParticipantRole.generalUser
      && localParticipant?.cameraStatus === DeviceStatus.off;
  }

  private handleMembersPressed(): void {
    this.isMemberListSheetVisible = true;
  }

  private handleMicToggle(): void {
    const currentStatus = this.participantState?.localParticipant?.microphoneStatus;
    if (currentStatus === DeviceStatus.on) {
      if (this.participantStore) {
        DeviceOperator.muteMicrophone(this.participantStore);
      }
    } else {
      if (this.participantStore) {
        DeviceOperator.unmuteMicrophone(this.getUIContext(), this.participantStore);
      }
    }
  }

  private handleCameraToggle(): void {
    const currentStatus = this.participantState?.localParticipant?.cameraStatus;
    if (currentStatus === DeviceStatus.on) {
      DeviceOperator.closeCamera();
    } else {
      DeviceOperator.openCamera(this.getUIContext());
    }
  }

  private isSelfInParticipantList(): boolean {
    const localUserId = LoginStore.shared().state.loginUserInfo?.userID;
    if (!localUserId || !this.participantState?.participantList) {
      return false;
    }
    return this.participantState.participantList.some((p: RoomParticipant) => p.userID === localUserId);
  }
}

interface ButtonItemParams {
  icon: Resource;
  selectedIcon?: Resource;
  text: string;
  isSelected?: boolean;
  opacity?: number;
  isWebinar?: boolean;
  onPressed: () => void;
}
