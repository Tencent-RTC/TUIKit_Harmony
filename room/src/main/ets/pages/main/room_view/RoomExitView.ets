import { router } from '@kit.ArkUI';
import { RoomStore, RoomParticipantStore, ParticipantRole, RoomParticipantState } from '@tencentcloud/atomicxcore';
import { RoomColors } from '../../../base/resources/RoomColors';
import { RoomImages } from '../../../base/resources/RoomImages';

@Component
export struct RoomExitView {
  roomId: string = '';
  onExit?: () => void;
  onClose?: () => void;

  private roomStore: RoomStore = RoomStore.shared();
  private participantStore?: RoomParticipantStore;
  @State private participantState: RoomParticipantState | undefined = undefined;

  aboutToAppear(): void {
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore?.state;
  }

  build() {
    Column() {
      this.DropDownButtonBuilder()

      this.HintTextBuilder()

      Blank()
        .height(16)

      Divider()
        .color(RoomColors.dividerGrey)
        .height(1)

      this.LeaveRoomButtonBuilder()

      Divider()
        .color(RoomColors.dividerGrey)
        .height(1)

      if (this.isRoomOwner()) {
        this.EndRoomButtonBuilder()
      }
    }
    .width('100%')
    .padding({ bottom: 34 })
  }

  @Builder
  DropDownButtonBuilder() {
    Row() {
      Image(RoomImages.roomLine)
        .width(24)
        .height(4)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height(35)
    .flexShrink(0)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onClose?.();
    })
  }

  @Builder
  HintTextBuilder() {
    Row() {
      Text(this.isRoomOwner()
        ? $r('app.string.roomkit_confirm_leave_room_by_owner')
        : $r('app.string.roomkit_confirm_leave_room_by_genera_user'))
        .fontSize(12)
        .fontColor('#FF7C85A6')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(17)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  LeaveRoomButtonBuilder() {
    Row() {
      Text($r('app.string.roomkit_leave_room'))
        .fontSize(18)
        .fontColor(RoomColors.brandBlue)
    }
    .width('100%')
    .height(58)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.handleLeaveRoom();
    })
  }

  @Builder
  EndRoomButtonBuilder() {
    Row() {
      Text($r('app.string.roomkit_end_room'))
        .fontSize(18)
        .fontColor(RoomColors.exitRed)
    }
    .width('100%')
    .height(58)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.handleEndRoom();
    })
  }

  private isRoomOwner(): boolean {
    return this.participantState?.localParticipant?.role === ParticipantRole.owner;
  }

  private async handleLeaveRoom(): Promise<void> {
    await this.roomStore.leaveRoom();
    this.onClose?.();
    this.handleExit();
  }

  private async handleEndRoom(): Promise<void> {
    await this.roomStore.endRoom();
    this.onClose?.();
    this.handleExit();
  }

  private handleExit(): void {
    if (this.onExit) {
      this.onExit();
    } else {
      router.back();
    }
  }
}
