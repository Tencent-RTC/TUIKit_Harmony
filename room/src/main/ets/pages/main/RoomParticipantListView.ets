import {
  RoomStore,
  RoomState,
  RoomParticipantStore,
  RoomParticipantState,
  RoomParticipant,
  RoomUser,
  ParticipantRole,
  DeviceType,
} from '@tencentcloud/atomicxcore';
import { AlertDialog, RadiusScheme } from '@tencentcloud/atomicx';
import { RoomColors } from '../../base/resources/RoomColors';
import { RoomImages } from '../../base/resources/RoomImages';
import { RoomConstants } from '../../base/constants/RoomConstants';
import { RoomMemberItemView } from './participant_list/RoomMemberItemView';

enum ParticipantTab {
  participant = 0,
  audience = 1,
}

@Component
export struct RoomParticipantListView {
  roomId: string = '';
  onClose?: () => void;

  private roomStore: RoomStore = RoomStore.shared();
  private participantStore?: RoomParticipantStore;
  @State private roomState: RoomState = RoomStore.shared().state;
  @State private participantState: RoomParticipantState | undefined = undefined;
  @State private currentTab: ParticipantTab = ParticipantTab.participant;

  aboutToAppear(): void {
    this.participantStore = RoomParticipantStore.create(this.roomId);
    this.participantState = this.participantStore?.state;
  }

  build() {
    Column() {
      this.DropDownButtonBuilder();

      if (this.isWebinar()) {
        this.TabBarBuilder();
      } else {
        this.TitleBuilder();
      }

      this.MemberListBuilder();

      if (this.shouldShowBottomButtons()) {
        this.BottomButtonsBuilder();
      }

      Blank()
        .height(34)
    }
    .width('100%')
    .backgroundColor(RoomColors.g2)
    .borderRadius({ topLeft: RadiusScheme.superLargeRadius, topRight: RadiusScheme.superLargeRadius })
  }

  @Builder
  DropDownButtonBuilder() {
    Column() {
      Image(RoomImages.roomLine)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height(35)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (this.onClose) {
        this.onClose();
      }
    })
  }

  @Builder
  TitleBuilder() {
    Row() {
      Text(this.getMemberCountTitle())
        .fontSize(16)
        .fontColor(RoomColors.g7)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(24)
    .padding({ left: 16, right: 16 })
    .margin({ top: 10 })
  }

  @Builder
  TabBarBuilder() {
    Row() {
      this.TabItemBuilder({
        title: this.getParticipantTabTitle(),
        isSelected: this.currentTab === ParticipantTab.participant,
        onTap: () => {
          this.currentTab = ParticipantTab.participant;
        },
      });

      this.TabItemBuilder({
        title: this.getAudienceTabTitle(),
        isSelected: this.currentTab === ParticipantTab.audience,
        onTap: () => {
          this.currentTab = ParticipantTab.audience;
        },
      });
    }
    .height(36)
    .margin({ left: 16, right: 16, top: 10 })
    .padding(2)
    .backgroundColor(RoomColors.dividerGrey)
    .borderRadius(6)
  }

  @Builder
  TabItemBuilder(params: TabItemParams) {
    Column() {
      Text(params.title)
        .fontSize(14)
        .fontColor(params.isSelected ? Color.White : RoomColors.g6)
        .fontWeight(params.isSelected ? FontWeight.Medium : FontWeight.Regular)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(params.isSelected ? RoomColors.g3 : Color.Transparent)
    .borderRadius(6)
    .onClick(() => {
      params.onTap();
    })
  }

  @Builder
  MemberListBuilder() {
    Column() {
      if (this.currentTab === ParticipantTab.participant) {
        this.ParticipantListViewBuilder();
      } else {
        this.AudienceListViewBuilder();
      }
    }
    .layoutWeight(1)
    .width('100%')
    .margin({ top: 15 })
  }

  @Builder
  ParticipantListViewBuilder() {
    List() {
      LazyForEach(this.participantState?.participantList, (participant: RoomParticipant) => {
        ListItem() {
          RoomMemberItemView({
            roomId: this.roomId,
            participant: participant,
          })
        }
      }, (participant: RoomParticipant) => participant.userID)
    }
    .width('100%')
    .layoutWeight(1)
    .divider({
      strokeWidth: 1,
      color: RoomColors.dividerGrey,
      startMargin: 66,
      endMargin: 16,
    })
    .scrollBar(BarState.Off)
  }

  @Builder
  AudienceListViewBuilder() {
    List() {
      LazyForEach(this.participantState?.audienceList, (audience: RoomUser) => {
        ListItem() {
          RoomMemberItemView({
            roomId: this.roomId,
            audience: audience,
          })
        }
      }, (audience: RoomUser) => audience.userID)
    }
    .width('100%')
    .layoutWeight(1)
    .divider({
      strokeWidth: 1,
      color: RoomColors.dividerGrey,
      startMargin: 66,
      endMargin: 16,
    })
    .scrollBar(BarState.Off)
  }

  @Builder
  BottomButtonsBuilder() {
    Row({ space: 9 }) {
      Button(this.getMuteAllAudioText())
        .type(ButtonType.Normal)
        .height(40)
        .backgroundColor(RoomColors.g3)
        .borderRadius(6)
        .fontSize(14)
        .fontColor(this.isAllMicMuted() ? '#FFF2504B' : RoomColors.g6)
        .layoutWeight(1)
        .onClick(() => {
          this.handleAllMuteAudio();
        })

      Button(this.getDisableAllVideoText())
        .type(ButtonType.Normal)
        .height(40)
        .backgroundColor(RoomColors.g3)
        .borderRadius(6)
        .fontSize(14)
        .fontColor(this.isAllVideoDisabled() ? RoomColors.exitRed : RoomColors.g6)
        .layoutWeight(1)
        .onClick(() => {
          this.handleAllDisableVideo();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 15 })
  }

  // --- Private methods ---

  private isWebinar(): boolean {
    return this.roomId.startsWith(RoomConstants.webinarPrefix);
  }

  private getString(resource: Resource): string {
    return this.getUIContext().getHostContext()?.resourceManager.getStringSync(resource) ?? '';
  }

  private getMemberCountTitle(): string {
    const count = this.roomState.currentRoom?.participantCount ?? 0;
    return this.getString($r('app.string.roomkit_member_count')).replace('xxx', count.toString());
  }

  private getParticipantTabTitle(): string {
    const count = this.roomState.currentRoom?.participantCount ?? 0;
    return this.getString($r('app.string.roomkit_participant')).replace('xxx', count.toString());
  }

  private getAudienceTabTitle(): string {
    const count = this.roomState.currentRoom?.audienceCount ?? 0;
    return this.getString($r('app.string.roomkit_audience')).replace('xxx', count.toString());
  }

  private shouldShowBottomButtons(): boolean {
    if (this.isWebinar()) {
      return false;
    }
    const localParticipant = this.participantState?.localParticipant;
    return localParticipant?.role === ParticipantRole.owner
      || localParticipant?.role === ParticipantRole.admin;
  }

  private isAllMicMuted(): boolean {
    return this.roomState.currentRoom?.isAllMicrophoneDisabled ?? false;
  }

  private isAllVideoDisabled(): boolean {
    return this.roomState.currentRoom?.isAllCameraDisabled ?? false;
  }

  private getMuteAllAudioText(): string {
    return this.isAllMicMuted()
      ? this.getString($r('app.string.roomkit_unmute_all_audio'))
      : this.getString($r('app.string.roomkit_mute_all_audio'));
  }

  private getDisableAllVideoText(): string {
    return this.isAllVideoDisabled()
      ? this.getString($r('app.string.roomkit_enable_all_video'))
      : this.getString($r('app.string.roomkit_disable_all_video'));
  }

  // --- Actions ---

  private handleAllMuteAudio(): void {
    const isCurrentlyMuted = this.isAllMicMuted();
    const title = isCurrentlyMuted
      ? this.getString($r('app.string.roomkit_msg_all_members_will_be_unmuted'))
      : this.getString($r('app.string.roomkit_msg_all_members_will_be_muted'));
    const content = isCurrentlyMuted
      ? this.getString($r('app.string.roomkit_msg_members_can_unmute'))
      : this.getString($r('app.string.roomkit_msg_members_cannot_unmute'));
    const confirmText = isCurrentlyMuted
      ? this.getString($r('app.string.roomkit_confirm_release'))
      : this.getString($r('app.string.roomkit_mute_all_audio'));
    const cancelText = this.getString($r('app.string.roomkit_cancel'));

    AlertDialog.show(
      title,
      content,
      cancelText,
      confirmText,
      () => {},
      () => {},
      () => {
        this.participantStore?.disableAllDevices(DeviceType.microphone, !isCurrentlyMuted);
      },
      this.getUIContext(),
    );
  }

  private handleAllDisableVideo(): void {
    const isCurrentlyDisabled = this.isAllVideoDisabled();
    const title = isCurrentlyDisabled
      ? this.getString($r('app.string.roomkit_msg_all_members_video_enabled'))
      : this.getString($r('app.string.roomkit_msg_all_members_video_disabled'));
    const content = isCurrentlyDisabled
      ? this.getString($r('app.string.roomkit_msg_members_can_start_video'))
      : this.getString($r('app.string.roomkit_msg_members_cannot_start_video'));
    const confirmText = isCurrentlyDisabled
      ? this.getString($r('app.string.roomkit_confirm_release'))
      : this.getString($r('app.string.roomkit_disable_all_video'));
    const cancelText = this.getString($r('app.string.roomkit_cancel'));

    AlertDialog.show(
      title,
      content,
      cancelText,
      confirmText,
      () => {},
      () => {},
      () => {
        this.participantStore?.disableAllDevices(DeviceType.camera, !isCurrentlyDisabled);
      },
      this.getUIContext(),
    );
  }
}

interface TabItemParams {
  title: string;
  isSelected: boolean;
  onTap: () => void;
}
