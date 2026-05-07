import {
  RoomParticipant,
  RoomParticipantStore,
  RoomParticipantState,
  DeviceStatus,
} from '@tencentcloud/atomicxcore';
import { display, mediaquery } from '@kit.ArkUI';
import { ParticipantVideoItemView } from './ParticipantVideoItemView';

@Component
export struct ParticipantLayoutView {
  roomId: string = '';
  @Prop participants: RoomParticipant[] = [];
  @Prop startIndex: number = 0;
  @Prop endIndex: number = -1;
  @Prop currentPageIndex: number = 0;
  @Prop isScreenLayout: boolean = false;
  @Prop screenParticipant?: RoomParticipant;

  @State private participantState: RoomParticipantState = new RoomParticipantState();
  @State private isPortrait: boolean = true;
  @State private screenWidthVp: number = 0;
  @State private screenHeightVp: number = 0;

  private portraitListener = mediaquery.matchMediaSync('(orientation: portrait)');

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomId).state;
    this.portraitListener.on('change', this.onOrientationChange);
    this.initDisplayInfo();
  }

  aboutToDisappear(): void {
    this.portraitListener.off('change', this.onOrientationChange);
  }

  build() {
    Column() {
      if (this.isScreenLayout && this.screenParticipant !== undefined) {
        this.buildScreenShareLayout()
      } else {
        this.buildGridLayout()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildScreenShareLayout() {
    ParticipantVideoItemView({
      roomId: this.roomId,
      participant: this.screenParticipant!,
      itemWidth: '100%',
      itemHeight: '100%',
      isScreenStream: true,
      cameraStatus: this.getLatestCameraStatus(this.screenParticipant!.userID),
      screenShareStatus: this.getLatestScreenShareStatus(this.screenParticipant!.userID),
    })
  }

  @Builder
  private buildGridLayout() {
    Column() {
      Flex({
        wrap: FlexWrap.Wrap,
        justifyContent: this.getHorizontalAlignment(),
        alignContent: this.getWrapAlignment(),
      }) {
        ForEach(this.getPageParticipants(), (participant: RoomParticipant) => {
          ParticipantVideoItemView({
            roomId: this.roomId,
            participant: participant,
            itemWidth: this.getGridItemWidth(),
            itemHeight: this.getGridItemHeight(),
            isScreenStream: false,
            cameraStatus: this.getLatestCameraStatus(participant.userID),
            screenShareStatus: this.getLatestScreenShareStatus(participant.userID),
          })
            .margin({ left: 3.5, right: 3.5, top: 3.5, bottom: 3.5 })
        }, (participant: RoomParticipant) => participant.userID)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 4.5, right: 4.5, top: 47, bottom: 47 })
  }

  private onOrientationChange = (mediaQueryResult: mediaquery.MediaQueryResult) => {
    this.isPortrait = mediaQueryResult.matches;
    this.initDisplayInfo();
  }

  private initDisplayInfo(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidthVp = px2vp(displayInfo.width);
      this.screenHeightVp = px2vp(displayInfo.height);
    } catch (_e) {
      this.screenWidthVp = 360;
      this.screenHeightVp = 780;
    }
  }

  private getPageParticipants(): RoomParticipant[] {
    const itemCount = this.endIndex - this.startIndex + 1;
    if (itemCount <= 0) {
      return [];
    }
    const result: RoomParticipant[] = [];
    for (let i = this.startIndex; i <= this.endIndex && i < this.participants.length; i++) {
      result.push(this.participants[i]);
    }
    return result;
  }

  private getGridItemWidth(): number {
    return (this.screenWidthVp - 8 - 8 - 7) / 2;
  }

  private getGridItemHeight(): number {
    return this.getGridItemWidth();
  }

  private getHorizontalAlignment(): FlexAlign {
    const hasScreen = this.participantState.participantWithScreen !== undefined;
    const userListLength = this.participants.length;
    const totalPages = hasScreen ? Math.ceil(userListLength / 6) + 1 : Math.ceil(userListLength / 6);
    const isMultiPage = this.isScreenLayout || userListLength > 6;

    if (isMultiPage) {
      return (totalPages === this.currentPageIndex + 1 && userListLength % 6 !== 0)
        ? FlexAlign.Start
        : FlexAlign.Center;
    } else {
      const itemCount = this.endIndex - this.startIndex + 1;
      if (itemCount === 1) {
        return FlexAlign.Center;
      }
      return (itemCount % 2 !== 0) ? FlexAlign.Start : FlexAlign.Center;
    }
  }

  private getWrapAlignment(): FlexAlign {
    const hasScreen = this.participantState.participantWithScreen !== undefined;
    const userListLength = this.participants.length;
    const totalPages = hasScreen ? Math.ceil(userListLength / 6) + 1 : Math.ceil(userListLength / 6);
    return (this.isScreenLayout || userListLength > 6)
      ? (totalPages === this.currentPageIndex + 1 && userListLength % 6 !== 0)
          ? FlexAlign.Start
          : FlexAlign.Center
      : FlexAlign.Center;
  }

  private getLatestCameraStatus(userID: string): DeviceStatus {
    const p = this.participantState.participantList.find((item: RoomParticipant) => item.userID === userID);
    return p ? p.cameraStatus : DeviceStatus.off;
  }

  private getLatestScreenShareStatus(userID: string): DeviceStatus {
    const p = this.participantState.participantList.find((item: RoomParticipant) => item.userID === userID);
    return p ? p.screenShareStatus : DeviceStatus.off;
  }
}