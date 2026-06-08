import {
  CallStore, DeviceStore, CallMediaType, CallParticipantStatus,
  CallParticipantInfo, CallInfo, DeviceState, DeviceEvent, NetworkQuality,
} from '@tencentcloud/atomicxcore';
import { CallCoreView, CallCoreController, CallLayoutTemplate, VolumeLevel } from '@tencentcloud/atomicxcore';
import { CallConstants } from '../../../common/CallConstants';
import { CallKitBundle } from '../../../common/CallKitBundle';
import { Constants } from '../../../common/Constants';
import { TimerView } from './hint/TimerView';
import { HintView } from './hint/HintView';
import { WaitingParticipantsView } from './waiting/WaitingParticipantsView';
import { SingleCallControlsView } from './controls/SingleCallControlsView';
import { MultiCallControlsView } from './controls/MultiCallControlsView';
import { SmartCellularSwitchRecommendationView } from './smartCellularSwitchRecommendation/SmartCellularSwitchRecommendationView';
import { Logger } from '../../../common/utils/Logger';
import { ViewStateClass } from '../../../state/ViewState';

@Component
export struct CallView {
  @State controller: CallCoreController = new CallCoreController();
  @State controlsHeight: number = CallConstants.groupFunctionViewHeight;
  @State smartCellularVisible: boolean = false;
  @State screenHeightVp: number = 800;

  @ObjectLink viewState: ViewStateClass;
  @ObjectLink callState_activeCall: CallInfo;
  @ObjectLink callState_selfInfo: CallParticipantInfo;
  @ObjectLink callState_allParticipants: CallParticipantInfo[];
  @ObjectLink deviceState: DeviceState;

  private smartCellularUnsubscribe: (() => void) | null = null;

  aboutToAppear(): void {
    this.applyControllerResources();
    this.applyControllerLayout();

    this.smartCellularUnsubscribe = DeviceStore.shared().deviceEventEmitter.subscribe(
      this,
      (event: DeviceEvent): void => {
        if (event === DeviceEvent.onSmartCellularSwitchRecommended) {
          this.smartCellularVisible = true;
        }
      },
    );
  }

  aboutToDisappear(): void {
    if (this.smartCellularUnsubscribe !== null) {
      this.smartCellularUnsubscribe();
      this.smartCellularUnsubscribe = null;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.backgroundAvatar();

      CallCoreView({ controller: this.controller })
        .width('100%')
        .height('100%')
        .padding({ top: this.isGroupCall() ? this.viewState.statusBarHeight + 50 : 0 })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .visibility(this.shouldHideCoreView() ? Visibility.Hidden : Visibility.Visible);

      if (this.shouldShowWaitingRoster()) {
        WaitingParticipantsView({
          activeCall: this.callState_activeCall,
          allParticipants: this.callState_allParticipants,
          selfId: this.callState_selfInfo.id,
        })
          .margin({ top: this.viewState.statusBarHeight + 80 });
      }

      Column() {
        TimerView({
          selfInfo: this.callState_selfInfo,
          activeCall: this.callState_activeCall,
        });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: this.viewState.statusBarHeight + 20 });

      if (!this.isGroupCall()) {
        Column() {
          HintView({
            selfInfo: this.callState_selfInfo,
            activeCall: this.callState_activeCall,
            isCaller: this.isCaller(),
          });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: this.screenHeightVp * 2 / 3 })
        .hitTestBehavior(HitTestMode.None);
      }

      Column() {
        if (this.isGroupCall()) {
          MultiCallControlsView({
            selfInfo: this.callState_selfInfo,
            deviceState: this.deviceState,
            controlsHeight: this.controlsHeight,
            mediaType: this.callState_activeCall.mediaType ?? CallMediaType.audio,
            enableVirtualBackground: true,
            bottomExtension: this.viewState.navBarHeight,
          });
        } else {
          SingleCallControlsView({
            selfInfo: this.callState_selfInfo,
            deviceState: this.deviceState,
            mediaType: this.callState_activeCall.mediaType ?? CallMediaType.audio,
            isCaller: this.isCaller(),
            enableVirtualBackground: true,
            // Single has no card background; it just adds the safe-area
            // inset to its own bottom padding.
            bottomSafeInset: this.viewState.navBarHeight,
          });
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .hitTestBehavior(HitTestMode.Transparent);

      SmartCellularSwitchRecommendationView({
        visible: this.smartCellularVisible,
        onImprove: (): void => {
          Logger.info('SmartCellular: user chose Improve');
        },
        onKeepWifi: (): void => {
          Logger.info('SmartCellular: user chose KeepWifi');
        },
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CallConstants.Color_Black)
    .onAreaChange((_old: Area, area: Area): void => {
      const h = Number(area.height);
      if (!Number.isNaN(h) && h > 0 && h !== this.screenHeightVp) {
        this.screenHeightVp = h;
      }
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  backgroundAvatar() {
    Stack() {
      if (this.backgroundAvatarUrl().length > 0) {
        Image(this.backgroundAvatarUrl())
          .width('100%')
          .height('100%')
          .alt($r('app.media.default_participant_icon'))
          .blur(80)
          .objectFit(ImageFit.Cover);
      } else {
        Image($r('app.media.default_participant_icon'))
          .width('100%')
          .height('100%')
          .blur(80)
          .objectFit(ImageFit.Cover);
      }
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(CallConstants.Color_BlurMask);
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  private backgroundAvatarUrl(): string {
    if (this.isGroupCall()) {
      return this.callState_selfInfo.avatarURL ?? '';
    }
    const peer = this.findPeerForAvatar();
    return (peer?.avatarURL ?? this.callState_selfInfo.avatarURL) ?? '';
  }

  /** Foreground peer avatar shown during 1:1 waiting (rounded square, not a circle). */

  private isCaller(): boolean {
    return this.callState_activeCall.inviterId === this.callState_selfInfo.id;
  }

  private isGroupCall(): boolean {
    // Aligned with iOS CallView.swift:73 — chatGroupId non-empty OR more
    // than one invitee (covers a 2-participant group call where
    // allParticipants.length === 2 would otherwise be misclassified as 1:1).
    return (this.callState_activeCall.chatGroupId?.length ?? 0) > 0
      || (this.callState_activeCall.inviteeIds?.length ?? 0) > 1;
  }

  private isInWaitingState(): boolean {
    return this.callState_selfInfo.status === CallParticipantStatus.waiting;
  }

  private isCalledWaiting(): boolean {
    return this.callState_selfInfo.id !== this.callState_activeCall.inviterId
      && this.isInWaitingState();
  }

  private shouldHideCoreView(): boolean {
    return this.isGroupCall() && this.isCalledWaiting();
  }

  private shouldShowWaitingRoster(): boolean {
    return this.isGroupCall() && this.isCalledWaiting();
  }

  private findPeerForAvatar(): CallParticipantInfo | undefined {
    if (this.callState_allParticipants.length === 0) {
      return undefined;
    }
    if (!this.isGroupCall()) {
      return this.callState_allParticipants
        .find((p: CallParticipantInfo): boolean => p.id !== this.callState_selfInfo.id);
    }
    return this.callState_allParticipants
      .find((p: CallParticipantInfo): boolean => p.id === this.callState_activeCall.inviterId);
  }

  private applyControllerResources(): void {
    const muteIcon: ResourceStr = $r('app.media.icon_mic_off');
    const audioInputIcon: ResourceStr = $r('app.media.icon_volume');
    const networkBadIcon: ResourceStr = $r('app.media.group_network_low_quality');

    const volumes = new Map<VolumeLevel, ResourceStr>();
    volumes.set(VolumeLevel.mute, muteIcon);
    volumes.set(VolumeLevel.low, audioInputIcon);
    volumes.set(VolumeLevel.medium, audioInputIcon);
    volumes.set(VolumeLevel.high, audioInputIcon);
    volumes.set(VolumeLevel.peak, audioInputIcon);
    this.controller.setVolumeLevelIcons(volumes);

    const networks = new Map<NetworkQuality, ResourceStr>();
    networks.set(NetworkQuality.bad, networkBadIcon);
    networks.set(NetworkQuality.veryBad, networkBadIcon);
    this.controller.setNetworkQualityIcons(networks);

    this.controller.setWaitingAnimation($r('app.media.callview_ic_loading'));
    this.controller.setDefaultAvatar($r('app.media.default_participant_icon'));
  }

  private applyControllerLayout(): void {
    const layout = this.isGroupCall() ? CallLayoutTemplate.grid : CallLayoutTemplate.float;
    this.controller.setLayoutTemplate(layout);
  }
}
