import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import {
  RoomStore,
  RoomType,
  RoomListener,
  RoomInfo,
  RoomUser,
  DeviceStore,
  DeviceType,
  AudioRoute,
  RoomParticipantStore,
  RoomParticipantListener,
  DeviceRequestInfo,
  KickedOutOfRoomReason,
  LoginStore,
  CreateRoomOptions,
  ErrorInfo,
} from '@tencentcloud/atomicxcore';
import { Toast, AlertDialog } from '@tencentcloud/atomicx';
import { RoomColors } from '../base/resources/RoomColors';
import { RoomConstants } from '../base/constants/RoomConstants';
import { RoomTopBarView } from './main/RoomTopBarView';
import { RoomBottomBarView } from './main/RoomBottomBarView';
import { DeviceOperator, DeviceOperatorType } from '../base/operator/DeviceOperator';
import { ErrorLocalized } from '../base/error/ErrorLocalized';
import { AVSessionManager } from '../base/utils/AVSessionManager';
import { RoomDataReporter } from '../base/reporter/RoomDataReporter';
import { RoomView } from './main/RoomView';

export class ConnectConfig {
  autoEnableMicrophone: boolean = true;
  autoEnableCamera: boolean = true;
  autoEnableSpeaker: boolean = true;

  constructor(autoEnableMicrophone?: boolean, autoEnableCamera?: boolean, autoEnableSpeaker?: boolean) {
    this.autoEnableMicrophone = autoEnableMicrophone ?? true;
    this.autoEnableCamera = autoEnableCamera ?? true;
    this.autoEnableSpeaker = autoEnableSpeaker ?? true;
  }
}

export enum RoomBehaviorType {
  create,
  join,
}

export class RoomBehavior {
  readonly type: RoomBehaviorType;
  readonly createOptions?: CreateRoomOptions;

  private constructor(type: RoomBehaviorType, createOptions?: CreateRoomOptions) {
    this.type = type;
    this.createOptions = createOptions;
  }

  static create(options: CreateRoomOptions): RoomBehavior {
    return new RoomBehavior(RoomBehaviorType.create, options);
  }

  static join(): RoomBehavior {
    return new RoomBehavior(RoomBehaviorType.join);
  }
}

@Component
export struct RoomMainPage {
  roomID: string = '';
  behavior: RoomBehavior = RoomBehavior.join();
  config: ConnectConfig = new ConnectConfig();
  onExit?: () => void;

  private roomStore: RoomStore = RoomStore.shared();
  private deviceStore: DeviceStore = DeviceStore.shared();
  private participantStore?: RoomParticipantStore;
  private roomListener?: RoomListener;
  private participantListener?: RoomParticipantListener;

  private inviteCameraAlertId?: string;
  private inviteMicAlertId?: string;
  private avSessionManager: AVSessionManager = new AVSessionManager();
  private dismissTopBarSheets?: () => void;
  private dismissBottomBarSheets?: () => void;

  aboutToAppear(): void {
    this.setKeepScreenOn(true);
    this.initStore();
    this.createOrJoinRoom();
  }

  aboutToDisappear(): void {
    this.setKeepScreenOn(false);
    this.avSessionManager.stop();
    if (this.participantListener) {
      this.participantStore?.removeRoomParticipantListener(this.participantListener);
    }
    if (this.roomListener) {
      this.roomStore.removeRoomListener(this.roomListener);
    }
    this.deviceStore.reset();
  }

  build() {
    Column() {
      RoomTopBarView({
        roomId: this.roomID,
        onDismissSheets: (dismiss: () => void) => { this.dismissTopBarSheets = dismiss; },
        onExit: () => {
          this.handleExit();
        },
      })

      if (this.isWebinar()) {
        Blank()
          .height(19)
      }

      RoomView({ roomId: this.roomID })
        .width('100%')
        .aspectRatio(this.isWebinar() ? 16 / 9 : undefined)
        .layoutWeight(this.isWebinar() ? undefined : 1)

      if (this.isWebinar()) {
        Blank()
          .layoutWeight(1)
      }

      if (this.isWebinar()) {
        Row() {
          Blank()
          RoomBottomBarView({
            roomId: this.roomID,
            onDismissSheets: (dismiss: () => void) => { this.dismissBottomBarSheets = dismiss; },
          })
        }
        .width('100%')
        .padding({ right: 11, bottom: 5 })
      } else {
        RoomBottomBarView({
          roomId: this.roomID,
          onDismissSheets: (dismiss: () => void) => { this.dismissBottomBarSheets = dismiss; },
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RoomColors.darkBlack)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private isWebinar(): boolean {
    return this.roomID.startsWith(RoomConstants.webinarPrefix);
  }

  private isSelf(user: RoomUser): boolean {
    return user.userID === LoginStore.shared().state.loginUserInfo?.userID;
  }

  private initStore(): void {
    this.participantStore = RoomParticipantStore.create(this.roomID);
    this.participantListener = new RoomParticipantListener();
    this.participantListener.onOwnerChanged = (newOwner: RoomUser, _oldOwner: RoomUser) => {
      if (this.isSelf(newOwner)) {
        Toast.info($r('app.string.roomkit_toast_you_are_owner'), this.getUIContext());
      }
    };
    this.participantListener.onAdminSet = (userInfo: RoomUser) => {
      if (this.isSelf(userInfo)) {
        Toast.info($r('app.string.roomkit_toast_you_are_admin'), this.getUIContext());
      }
    };
    this.participantListener.onAdminRevoked = (userInfo: RoomUser) => {
      if (this.isSelf(userInfo)) {
        Toast.info($r('app.string.roomkit_toast_you_are_no_longer_admin'), this.getUIContext());
      }
    };
    this.participantListener.onKickedFromRoom = (_reason: KickedOutOfRoomReason, _message: string) => {
      AlertDialog.show(
        $r('app.string.roomkit_toast_you_were_removed'),
        $r('app.string.roomkit_ok'),
        undefined,
        () => {
          this.handleExit();
        },
        this.getUIContext(),
      );
    };
    this.participantListener.onParticipantDeviceClosed = (device: DeviceType, _operator: RoomUser) => {
      let message: Resource | undefined;
      if (device === DeviceType.microphone) {
        message = $r('app.string.roomkit_toast_muted_by_host');
      } else if (device === DeviceType.camera) {
        message = $r('app.string.roomkit_toast_camera_closed_by_host');
      }
      if (message) {
        Toast.warning(message, this.getUIContext());
      }
    };
    this.participantListener.onUserMessageDisabled = (disable: boolean, _operator: RoomUser) => {
      if (disable) {
        Toast.warning($r('app.string.roomkit_toast_text_chat_disabled'), this.getUIContext());
      } else {
        Toast.info($r('app.string.roomkit_toast_text_chat_enabled'), this.getUIContext());
      }
    };
    this.participantListener.onAllDevicesDisabled = (device: DeviceType, disable: boolean, _operator: RoomUser) => {
      let message: Resource | undefined;
      if (device === DeviceType.microphone) {
        message = disable
          ? $r('app.string.roomkit_toast_all_audio_disabled')
          : $r('app.string.roomkit_toast_all_audio_enabled');
      } else if (device === DeviceType.camera) {
        message = disable
          ? $r('app.string.roomkit_toast_all_video_disabled')
          : $r('app.string.roomkit_toast_all_video_enabled');
      }
      if (message) {
        if (disable) {
          Toast.warning(message, this.getUIContext());
        } else {
          Toast.info(message, this.getUIContext());
        }
      }
    };
    this.participantListener.onDeviceInvitationReceived = (invitation: DeviceRequestInfo) => {
      const userName = invitation.senderNameCard.length > 0 ? invitation.senderNameCard : invitation.senderUserName;
      let title: string = '';
      if (invitation.device === DeviceType.microphone) {
        title = (this.getUIContext().getHostContext()?.resourceManager.getStringSync($r('app.string.roomkit_msg_invite_unmute_audio')) ?? '')
          .replace('xxx', userName);
      } else if (invitation.device === DeviceType.camera) {
        title = (this.getUIContext().getHostContext()?.resourceManager.getStringSync($r('app.string.roomkit_msg_invite_start_video')) ?? '')
          .replace('xxx', userName);
      }
      const alertId = AlertDialog.show(
        title,
        undefined,
        $r('app.string.roomkit_reject'),
        $r('app.string.roomkit_agree'),
        undefined,
        () => {
          this.participantStore?.declineOpenDeviceInvitation(invitation.senderUserID, invitation.device);
          this.clearDeviceInviteAlertId(invitation.device);
        },
        async () => {
          const context = this.getUIContext().getHostContext();
          if (context) {
            const operatorType = invitation.device === DeviceType.microphone
              ? DeviceOperatorType.microphone
              : DeviceOperatorType.camera;
            const hasPermission = await DeviceOperator.requestPermission(context, operatorType);
            if (!hasPermission) {
              const noPermissionMessage = invitation.device === DeviceType.microphone
                ? $r('app.string.roomkit_err_n1105_mic_no_permission')
                : $r('app.string.roomkit_err_n1101_camera_no_permission');
              Toast.error(noPermissionMessage, this.getUIContext());
            }
          }
          await this.participantStore?.acceptOpenDeviceInvitation(invitation.senderUserID, invitation.device);
          this.clearDeviceInviteAlertId(invitation.device);
        },
        this.getUIContext(),
      );
      this.setDeviceInviteAlertId(invitation.device, alertId);
    };
    this.participantListener.onDeviceInvitationCancelled = (invitation: DeviceRequestInfo) => {
      if (invitation.device === DeviceType.microphone && this.inviteMicAlertId) {
        AlertDialog.closeDialog(this.inviteMicAlertId);
        this.inviteMicAlertId = undefined;
      } else if (invitation.device === DeviceType.camera && this.inviteCameraAlertId) {
        AlertDialog.closeDialog(this.inviteCameraAlertId);
        this.inviteCameraAlertId = undefined;
      }
    };
    this.participantListener.onAudiencePromotedToParticipant = (userInfo: RoomUser) => {
      if (this.isSelf(userInfo)) {
        Toast.info($r('app.string.roomkit_switch_to_participant_byself'), this.getUIContext());
      } else {
        const displayName = userInfo.userName.length > 0 ? userInfo.userName : userInfo.userID;
        const message = (this.getUIContext().getHostContext()?.resourceManager.getStringSync($r('app.string.roomkit_switch_to_participant')) ?? '')
          .replace('xxx', displayName);
        Toast.info(message, this.getUIContext());
      }
    };
    this.participantListener.onParticipantDemotedToAudience = (userInfo: RoomUser) => {
      if (this.isSelf(userInfo)) {
        this.deviceStore.closeLocalMicrophone();
      }
    };

    this.roomListener = new RoomListener();
    this.roomListener.onRoomEnded = (_info: RoomInfo) => {
      AlertDialog.show(
        $r('app.string.roomkit_toast_room_closed'),
        $r('app.string.roomkit_ok'),
        undefined,
        () => {
          this.handleExit();
        },
        this.getUIContext(),
      );
    };

    this.participantStore?.addRoomParticipantListener(this.participantListener);
    this.roomStore.addRoomListener(this.roomListener);
  }

  private async createOrJoinRoom(): Promise<void> {
    RoomDataReporter.reportComponent();
    try {
      if (this.behavior.type === RoomBehaviorType.create) {
        if (this.behavior.createOptions) {
          await this.roomStore.createAndJoinRoom(
            this.roomID,
            RoomType.standard,
            this.behavior.createOptions
          );
        }
      } else {
        const roomType = this.isWebinar() ? RoomType.webinar : RoomType.standard;
        await this.roomStore.joinRoom(this.roomID, roomType);
      }
      await this.initMediaState();
      this.participantStore?.getParticipantList(undefined);
      this.participantStore?.getAudienceList(undefined);
      this.avSessionManager.start();
    } catch (error) {
      const errorInfo = error as ErrorInfo;
      const errorMessage = ErrorLocalized.convertToErrorMessage(errorInfo.code, errorInfo.message, this.getUIContext());
      Toast.error(errorMessage, this.getUIContext());
      this.handleExit();
    }
  }

  private async initMediaState(): Promise<void> {
    if (this.isWebinar()) {
      return;
    }
    if (this.config.autoEnableCamera) {
      await DeviceOperator.openCamera(this.getUIContext());
    }
    if (this.config.autoEnableMicrophone && this.participantStore) {
      await DeviceOperator.unmuteMicrophone(this.getUIContext(), this.participantStore);
    }
    this.deviceStore.setAudioRoute(
      this.config.autoEnableSpeaker ? AudioRoute.speakerphone : AudioRoute.earpiece
    );
  }

  private setDeviceInviteAlertId(deviceType: DeviceType, id: string): void {
    if (deviceType === DeviceType.microphone) {
      this.inviteMicAlertId = id;
    } else if (deviceType === DeviceType.camera) {
      this.inviteCameraAlertId = id;
    }
  }

  private clearDeviceInviteAlertId(deviceType: DeviceType): void {
    if (deviceType === DeviceType.microphone) {
      this.inviteMicAlertId = undefined;
    } else if (deviceType === DeviceType.camera) {
      this.inviteCameraAlertId = undefined;
    }
  }

  private handleExit(): void {
    this.dismissTopBarSheets?.();
    this.dismissBottomBarSheets?.();
    AlertDialog.closeAllDialogs();
    this.inviteMicAlertId = undefined;
    this.inviteCameraAlertId = undefined;
    if (this.onExit) {
      this.onExit();
    } else {
      router.back();
    }
  }

  private setKeepScreenOn(keepOn: boolean): void {
    window.getLastWindow(this.getUIContext().getHostContext()).then((win) => {
      win.setWindowKeepScreenOn(keepOn);
    }).catch(() => {});
  }
}
