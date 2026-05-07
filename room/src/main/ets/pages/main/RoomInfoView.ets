import pasteboard from '@ohos.pasteboard';
import { RoomStore, RoomState } from '@tencentcloud/atomicxcore';
import { Toast, RadiusScheme } from '@tencentcloud/atomicx';
import { RoomColors } from '../../base/resources/RoomColors';
import { RoomImages } from '../../base/resources/RoomImages';

@Component
export struct RoomInfoView {
  roomId: string = '';
  onClose?: () => void;

  @State private roomState: RoomState = RoomStore.shared().state;

  build() {
    Column() {
      this.DropDownButtonBuilder()

      Column() {
        Text(this.roomState.currentRoom?.roomName ?? this.roomId)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(RoomColors.g7)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Blank()
          .height(24)

        this.InfoItemBuilder(
          $r('app.string.roomkit_role_owner'),
          this.roomState.currentRoom?.roomOwner.userName
            ?? this.roomState.currentRoom?.roomOwner.userID
            ?? '',
        )

        Blank()
          .height(16)

        this.InfoItemWithTrailingBuilder(
          $r('app.string.roomkit_room_id'),
          this.roomId,
        )

        Blank()
          .height(24)

        Button($r('app.string.roomkit_copy_room_info'))
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Normal)
          .fontColor(RoomColors.g6)
          .backgroundColor(RoomColors.dividerGreyWith20Alpha)
          .borderRadius(RadiusScheme.smallRadius)
          .onClick(() => {
            this.handleCopyAllRoomInfo();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(254)
    .backgroundColor(RoomColors.g2)
    .borderRadius({
      topLeft: RadiusScheme.superLargeRadius,
      topRight: RadiusScheme.superLargeRadius,
    })
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
    .height(40)
    .flexShrink(0)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onClose?.();
    })
  }

  @Builder
  CopyButtonBuilder() {
    Row() {
      Image(RoomImages.roomCopy)
        .width(16)
        .height(16)
        .fillColor(RoomColors.white)

      Blank()
        .width(2)

      Text($r('app.string.roomkit_copy'))
        .fontSize(12)
        .fontColor(RoomColors.white)
    }
    .width(62)
    .height(25)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(RoomColors.g4)
    .borderRadius(5)
    .onClick(() => {
      this.handleCopyRoomId();
    })
  }

  @Builder
  InfoItemBuilder(prefixText: string | Resource, infoText: string) {
    Row() {
      Text(prefixText)
        .fontSize(14)
        .fontColor(RoomColors.g5)
        .width(73)

      Blank()
        .width(20)

      Text(infoText)
        .fontSize(14)
        .fontColor(RoomColors.g7)
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  InfoItemWithTrailingBuilder(prefixText: string | Resource, infoText: string) {
    Row() {
      Text(prefixText)
        .fontSize(14)
        .fontColor(RoomColors.g5)
        .width(73)

      Blank()
        .width(20)

      Text(infoText)
        .fontSize(14)
        .fontColor(RoomColors.g7)
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Blank()
        .width(4)

      this.CopyButtonBuilder()
    }
    .width('100%')
  }

  private handleCopyRoomId(): void {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.roomId);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData, (err) => {
      if (!err) {
        Toast.info($r('app.string.roomkit_toast_room_id_copied'), this.getUIContext());
      }
    });
  }

  private handleCopyAllRoomInfo(): void {
    const currentRoom = this.roomState.currentRoom;
    if (!currentRoom) {
      return;
    }

    const roomNameLabel = this.getUIContext().getHostContext()?.resourceManager
      .getStringSync($r('app.string.roomkit_room_name')) ?? 'Room name';
    const roomIdLabel = this.getUIContext().getHostContext()?.resourceManager
      .getStringSync($r('app.string.roomkit_room_id')) ?? 'Room ID';

    const allInfo = `${roomNameLabel}: ${currentRoom.roomName}\n${roomIdLabel}: ${currentRoom.roomID}`;

    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, allInfo);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData, (err) => {
      if (!err) {
        Toast.info($r('app.string.roomkit_toast_room_info_copied'), this.getUIContext());
      }
    });
  }
}
