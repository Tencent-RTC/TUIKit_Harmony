import {
  RoomParticipant,
  RoomParticipantStore,
  RoomParticipantState,
  DeviceStatus,
  LoginStore,
} from '@tencentcloud/atomicxcore';
import { Avatar, AvatarContent, AvatarContentType, AvatarSize, AvatarShape } from '@tencentcloud/atomicx';
import {
  TUIRoomEngine,
  TUIRoomObserver,
  TUIVideoStreamType,
  TUIChangeReason,
  TUISeatFullInfo,
} from '@tencentcloud/rtcroomengine';

let viewIdCounter: number = 0;

function generateWebinarViewId(prefix: string): string {
  viewIdCounter++;
  return `webinar_${prefix}_view_${viewIdCounter}`;
}

@Component
export struct WebinarRoomView {
  roomId: string = '';

  @State private participantState: RoomParticipantState = new RoomParticipantState();

  private participantStore?: RoomParticipantStore;
  private roomEngine: TUIRoomEngine = TUIRoomEngine.sharedInstance() as TUIRoomEngine;
  private roomEngineObserver?: TUIRoomObserver;

  private mixViewId: string = generateWebinarViewId('mix');
  private multiStreamViewId: string = generateWebinarViewId('multi');
  private mixUserId: string = '';
  private multiStreamUserId: string = '';
  private mixViewLoaded: boolean = false;
  private multiStreamViewLoaded: boolean = false;
  @State private showMultiStreamView: boolean = true;
  @State private pushVideoParticipant: RoomParticipant | undefined = undefined;

  private participantListListener: DataChangeListener = {
    onDataReloaded: () => {
      this.updatePushVideoParticipant();
    },
    onDataAdd: () => {
      this.updatePushVideoParticipant();
    },
    onDataChange: () => {
      this.updatePushVideoParticipant();
    },
    onDataDelete: () => {
      this.updatePushVideoParticipant();
    },
    onDataMove: () => {
      this.updatePushVideoParticipant();
    },
    onDataAdded: () => {
      this.updatePushVideoParticipant();
    },
    onDataChanged: () => {
      this.updatePushVideoParticipant();
    },
    onDataDeleted: () => {
      this.updatePushVideoParticipant();
    },
    onDataMoved: () => {
      this.updatePushVideoParticipant();
    },
    onDatasetChange: () => {
      this.updatePushVideoParticipant();
    },
  };

  aboutToAppear(): void {
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore.state;
    this.participantState.participantList.registerDataChangeListener(this.participantListListener);

    this.roomEngineObserver = {
      onUserVideoStateChanged: (userId: string, streamType: TUIVideoStreamType, hasVideo: boolean,
        reason: TUIChangeReason) => {
        this.onUserVideoStateChanged(userId, streamType, hasVideo);
      }
    } as TUIRoomObserver;
    this.roomEngine.addObserver(this.roomEngineObserver);
  }

  aboutToDisappear(): void {
    this.participantState.participantList.unregisterDataChangeListener(this.participantListListener);
    if (this.roomEngineObserver) {
      this.roomEngine.removeObserver(this.roomEngineObserver);
    }
    this.clearVideoView();
  }

  build() {
    Stack() {
      XComponent({
        id: this.mixViewId,
        type: XComponentType.SURFACE,
        libraryname: 'liteavsdk'
      })
        .onLoad(() => {
          this.mixViewLoaded = true;
          if (this.mixUserId.length > 0) {
            this.setRemoteVideoView(this.mixUserId, this.mixViewId);
          }
        })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)

      XComponent({
        id: this.multiStreamViewId,
        type: XComponentType.SURFACE,
        libraryname: 'liteavsdk'
      })
        .onLoad(() => {
          this.multiStreamViewLoaded = true;
          if (this.multiStreamUserId.length > 0) {
            this.setRemoteVideoView(this.multiStreamUserId, this.multiStreamViewId);
          }
        })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .visibility(this.showMultiStreamView ? Visibility.Visible : Visibility.Hidden)

      this.buildAvatarPlaceholder()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildAvatarPlaceholder() {
    if (this.pushVideoParticipant !== undefined && this.pushVideoParticipant.cameraStatus !== DeviceStatus.on) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#FF181A1E')

        Avatar({
          content: {
            type: AvatarContentType.Image,
            url: this.pushVideoParticipant.avatarURL ?? '',
          } as AvatarContent,
          avatarSize: AvatarSize.XL,
          shape: AvatarShape.Round,
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  private clearVideoView(): void {
    if (this.mixUserId.length > 0) {
      this.roomEngine.setRemoteVideoView(this.mixUserId, TUIVideoStreamType.CameraStream, '');
    }
    if (this.multiStreamUserId.length > 0) {
      this.roomEngine.setRemoteVideoView(this.multiStreamUserId, TUIVideoStreamType.CameraStream, '');
    }
  }

  private setRemoteVideoView(userId: string, viewId: string): void {
    this.roomEngine.setRemoteVideoView(userId, TUIVideoStreamType.CameraStream, viewId);
  }

  private onUserVideoStateChanged(userId: string, streamType: TUIVideoStreamType, hasVideo: boolean): void {
    const selfUserId = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    if (userId === selfUserId) {
      return;
    }

    const isMixUser = userId.includes('_feedback_');

    if (hasVideo) {
      if (isMixUser) {
        this.showMultiStreamView = false;
        this.mixUserId = userId;
        if (this.mixViewLoaded) {
          this.setRemoteVideoView(userId, this.mixViewId);
        }
      } else {
        this.showMultiStreamView = true;
        this.multiStreamUserId = userId;
        if (this.multiStreamViewLoaded) {
          this.setRemoteVideoView(userId, this.multiStreamViewId);
        }
      }
      this.roomEngine.startPlayRemoteVideo(userId, TUIVideoStreamType.CameraStream);
    } else {
      this.roomEngine.stopPlayRemoteVideo(userId, TUIVideoStreamType.CameraStream);
    }
  }

  private updatePushVideoParticipant(): void {
    const seatList: TUISeatFullInfo[] = this.roomEngine.querySeatList();
    if (seatList.length === 0) {
      return;
    }
    const firstSeatUserId: string = seatList[0].userId;
    const user = this.participantState.participantList.find((p: RoomParticipant) => p.userID === firstSeatUserId);
    if (user === undefined) {
      return;
    }
    if (user === this.pushVideoParticipant) {
      return;
    }
    this.pushVideoParticipant = user;
  }
}
