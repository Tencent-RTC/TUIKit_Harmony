import { DeviceStore, DeviceState, AudioRoute, RoomStore, RoomState } from '@tencentcloud/atomicxcore';
import { RoomColors } from '../../base/resources/RoomColors';
import { RoomImages } from '../../base/resources/RoomImages';
import { RoomConstants } from '../../base/constants/RoomConstants';
import { RoomExitView } from './room_view/RoomExitView';
import { RoomInfoView } from './RoomInfoView';

@Component
export struct RoomTopBarView {
  roomId: string = '';
  onExit?: () => void;
  onDismissSheets?: (dismiss: () => void) => void;

  private deviceStore: DeviceStore = DeviceStore.shared();
  private roomStore: RoomStore = RoomStore.shared();
  @State private deviceState: DeviceState = DeviceStore.shared().state;
  @State private roomState: RoomState = RoomStore.shared().state;
  @State private timerText: string = '00:00';
  private initTimestamp: number = 0;
  private timerId: number = -1;
  @State private isExitSheetVisible: boolean = false;
  @State private isInfoSheetVisible: boolean = false;

  aboutToAppear(): void {
    this.onDismissSheets?.(() => {
      this.isExitSheetVisible = false;
      this.isInfoSheetVisible = false;
    });
    this.initTimestamp = Date.now();
    this.startTimer();
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          if (!this.isWebinar()) {
            this.SpeakerButtonBuilder()
            Blank()
              .width(24)
            this.SwitchCameraButtonBuilder()
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)

        this.TitleBuilder()

        Row() {
          this.ExitButtonBuilder()
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .height(54)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .backgroundColor(RoomColors.darkBlack)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  exitSheetBuilder() {
    RoomExitView({
      roomId: this.roomId,
      onExit: this.onExit,
      onClose: () => { this.isExitSheetVisible = false; },
    })
  }

  @Builder
  infoSheetBuilder() {
    RoomInfoView({
      roomId: this.roomId,
      onClose: () => { this.isInfoSheetVisible = false; },
    })
  }

  @Builder
  SpeakerButtonBuilder() {
    Image(this.deviceState.currentAudioRoute === AudioRoute.speakerphone
      ? RoomImages.roomSpeakerphone
      : RoomImages.roomEarpiece)
      .width(20)
      .height(20)
      .fillColor(RoomColors.white)
      .onClick(() => {
        this.handleSpeakerToggle();
      })
  }

  @Builder
  SwitchCameraButtonBuilder() {
    Image(RoomImages.roomSwitchCamera)
      .width(20)
      .height(20)
      .fillColor(RoomColors.white)
      .onClick(() => {
        this.handleSwitchCamera();
      })
  }

  @Builder
  TitleBuilder() {
    Column() {
      Row() {
        Text(this.roomState.currentRoom?.roomName ?? this.roomId)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(RoomColors.white)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({
            maxWidth: 180
          })

        Blank()
          .width(2)

        Image(RoomImages.roomDropDown)
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)
          .fillColor(RoomColors.g5)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Blank()
        .height(5)

      Text(this.timerText)
        .fontSize(12)
        .fontColor(RoomColors.white)
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.handleRoomInfoTap();
    })
    .bindSheet($$this.isInfoSheetVisible, this.infoSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: false,
      showClose: false,
      backgroundColor: Color.Transparent,
    })
  }

  @Builder
  ExitButtonBuilder() {
    Row() {
      Image(RoomImages.roomExit)
        .width(20)
        .height(20)

      Blank()
        .width(3)

      Text($r('app.string.roomkit_end'))
        .fontSize(14)
        .fontColor(RoomColors.exitRed)
        .fontWeight(FontWeight.Bold)
    }
    .onClick(() => {
      this.handleExitTap();
    })
    .bindSheet($$this.isExitSheetVisible, this.exitSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: false,
      showClose: false,
      backgroundColor: RoomColors.mainBlack,
    })
  }

  private isWebinar(): boolean {
    return this.roomId.startsWith(RoomConstants.webinarPrefix);
  }

  private startTimer(): void {
    this.updateTimerText();
    this.timerId = setInterval(() => {
      this.updateTimerText();
    }, 1000);
  }

  private updateTimerText(): void {
    const currentTimestamp = Date.now();
    const totalSeconds = Math.floor((currentTimestamp - this.initTimestamp) / 1000);

    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor(totalSeconds / 60) % 60;
    const seconds = totalSeconds % 60;

    if (hours > 0) {
      this.timerText = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    } else {
      this.timerText = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
  }

  private handleSpeakerToggle(): void {
    const newRoute = this.deviceState.currentAudioRoute === AudioRoute.speakerphone
      ? AudioRoute.earpiece
      : AudioRoute.speakerphone;
    this.deviceStore.setAudioRoute(newRoute);
  }

  private handleSwitchCamera(): void {
    this.deviceStore.switchCamera(!this.deviceStore.state.isFrontCamera);
  }

  private handleExitTap(): void {
    this.isExitSheetVisible = true;
  }

  private handleRoomInfoTap(): void {
    this.isInfoSheetVisible = true;
  }
}
