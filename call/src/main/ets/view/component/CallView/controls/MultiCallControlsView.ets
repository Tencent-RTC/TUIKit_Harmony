import { common } from '@kit.AbilityKit';
import {
  CallStore, DeviceStore, CallParticipantInfo, DeviceState, CallMediaType,
  CallParticipantStatus, DeviceStatus, AudioRoute,
} from '@tencentcloud/atomicxcore';
import { ControlsButton } from '../../../../common/widgets/ControlsButton';
import { CallKitBundle } from '../../../../common/CallKitBundle';
import { TUICallKitLocalize } from '../../../../common/Localized';
import { CallConstants } from '../../../../common/CallConstants';
import { Constants } from '../../../../common/Constants';
import { Logger } from '../../../../common/utils/Logger';
import { Permission } from '../../../../common/utils/Permission';
import { Toast } from '../../../../common/widgets/Toast';
import { CallEndedFlag } from '../../../../state/CallEndedFlag';
import { CallingBellFeature } from '../../../../feature/CallingBellFeature';
import { CallingVibratorFeature } from '../../../../feature/CallingVibratorFeature';

const BTN_LARGE: number = 56;
const BTN_SMALL: number = 42;
const BTN_WRAP: number = 100;            // Flutter `btnWidth`
/** Switch-camera glyph size — Flutter `imgHeight: 28`. */
const BTN_SMALL_GLYPH: number = 28;

const BOTTOM_EDGE: number = 16;
const COLLAPSED_BOTTOM_EDGE: number = 28;
const ROW_GAP: number = 40;              // Flutter `edge`

const BUTTON_LIFT: number = 12;
const ANIM_DURATION: number = 300;

@Component
export struct MultiCallControlsView {
  @ObjectLink selfInfo: CallParticipantInfo;
  @ObjectLink deviceState: DeviceState;
  @State expanded: boolean = true;
  @State matchRotation: number = 0;
  @Link controlsHeight: number;
  @State screenWidthVp: number = 360;

  mediaType: CallMediaType = CallMediaType.video;
  enableVirtualBackground: boolean = true;
  bottomExtension: number = 0;

  aboutToAppear(): void {
    this.controlsHeight = this.expanded
      ? CallConstants.groupFunctionViewHeight
      : CallConstants.groupSmallFunctionViewHeight;
  }

  build() {
    if (this.isCalleeWaiting()) {
      this.waitingLayout();
    } else {
      this.cardContainer();
    }
  }

  /** Flutter `_buildWaitingFunctionView`: Row(spaceEvenly){ reject, accept } + 40vp gap. */
  @Builder
  waitingLayout() {
    Column() {
      Row() {
        this.declineBtn();
        this.answerBtn();
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly);

      Blank().height(40);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .constraintSize({ maxWidth: Constants.CONTROLS_CONTAINER_MAX_WIDTH });
  }

  @Builder
  cardContainer() {
    Stack() {
      Column()
        .width('100%')
        .height(this.controlsHeight + this.bottomExtension)
        .backgroundColor('rgb(52,56,66)')
        .borderRadius({ topLeft: 16, topRight: 16 });
      // mic — expanded W/4, collapsed W*2/6.
      // Bottom gap = (BOTTOM_EDGE | COLLAPSED_BOTTOM_EDGE) + bottomExtension
      // + BUTTON_LIFT — the LIFT lifts the whole row above Flutter's literal
      // baseline to compensate for HarmonyOS' nav indicator geometry.
      Column() { this.muteBtn(); }
        .width(BTN_WRAP)
        .position({
          x: this.screenWidthVp * (this.expanded ? 1 / 4 : 2 / 6) - BTN_WRAP / 2,
          y: this.expanded
            ? (this.controlsHeight + this.bottomExtension)
              - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + BTN_LARGE + ROW_GAP) - BTN_LARGE
            : (this.controlsHeight + this.bottomExtension)
              - BTN_SMALL - (COLLAPSED_BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT),
        });

      // speaker — expanded W/2, collapsed W*3/6 (= W/2).
      Column() { this.audioRouteBtn(); }
        .width(BTN_WRAP)
        .position({
          x: this.screenWidthVp * (1 / 2) - BTN_WRAP / 2,
          y: this.expanded
            ? (this.controlsHeight + this.bottomExtension)
              - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + BTN_LARGE + ROW_GAP) - BTN_LARGE
            : (this.controlsHeight + this.bottomExtension)
              - BTN_SMALL - (COLLAPSED_BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT),
        });

      // camera — expanded 3W/4, collapsed W*4/6.
      Column() { this.cameraBtn(); }
        .width(BTN_WRAP)
        .position({
          x: this.screenWidthVp * (this.expanded ? 3 / 4 : 4 / 6) - BTN_WRAP / 2,
          y: this.expanded
            ? (this.controlsHeight + this.bottomExtension)
              - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + BTN_LARGE + ROW_GAP) - BTN_LARGE
            : (this.controlsHeight + this.bottomExtension)
              - BTN_SMALL - (COLLAPSED_BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT),
        });

      // hangup — expanded W/2 (own row), collapsed W*5/6 (same row).
      Column() { this.hangupBtn(); }
        .width(BTN_WRAP)
        .position({
          x: this.screenWidthVp * (this.expanded ? 1 / 2 : 5 / 6) - BTN_WRAP / 2,
          y: this.expanded
            ? (this.controlsHeight + this.bottomExtension)
              - BTN_LARGE - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT)
            : (this.controlsHeight + this.bottomExtension)
              - BTN_SMALL - (COLLAPSED_BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT),
        });

      // Arrow at W/6.
      //
      // iOS canonical (VideoCallerAndCalleeAcceptedView.swift:222):
      //   matchBtn.centerY = hangup.centerY (in BOTH expanded + collapsed)
      // We apply the same rule + the BUTTON_LIFT so it tracks hangup.
      Image(CallKitBundle.imageMap('icon_match'))
        .width(BTN_SMALL)
        .height(BTN_SMALL)
        .objectFit(ImageFit.Contain)
        .rotate({ angle: this.matchRotation })
        .position({
          x: this.screenWidthVp * (1 / 6) - BTN_SMALL / 2,
          y: this.expanded
            ? (this.controlsHeight + this.bottomExtension)
              - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + BTN_LARGE / 2) - BTN_SMALL / 2
            : (this.controlsHeight + this.bottomExtension)
              - (COLLAPSED_BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + BTN_SMALL / 2) - BTN_SMALL / 2,
        })
        .onClick((): void => {
          this.toggleExpanded(!this.expanded);
        });

      // Switch-camera small button — only visible when expanded + camera on.
      //
      // Flutter: 28vp glyph at left = W*3/4 - 14 (after imgOffsetX:-16),
      // bottom = bottomEdge + smallBtn/4 expanded | bottomEdge + 35 collapsed.
      // Plus BUTTON_LIFT to track the rest of the row.
      if (this.deviceState.cameraStatus === DeviceStatus.on) {
        Image(CallKitBundle.imageMap('switch_camera'))
          .width(BTN_SMALL_GLYPH)
          .height(BTN_SMALL_GLYPH)
          .objectFit(ImageFit.Contain)
          .position({
            x: this.screenWidthVp * (3 / 4) - BTN_SMALL_GLYPH,
            y: this.expanded
              ? (this.controlsHeight + this.bottomExtension)
                - BTN_SMALL_GLYPH - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + BTN_SMALL / 4)
              : (this.controlsHeight + this.bottomExtension)
                - BTN_SMALL_GLYPH - (BOTTOM_EDGE + this.bottomExtension + BUTTON_LIFT + 35),
          })
          .opacity(this.expanded ? 1 : 0)
          .hitTestBehavior(this.expanded ? HitTestMode.Default : HitTestMode.None)
          .onClick((): void => {
            DeviceStore.shared().switchCamera(!this.deviceState.isFrontCamera);
          });
      }
    }
    .width('100%')
    .height(this.controlsHeight + this.bottomExtension)
    .clip(false)
    .onAreaChange((_old: Area, area: Area): void => {
      const aw = Number(area.width);
      if (!Number.isNaN(aw) && aw > 0 && aw !== this.screenWidthVp) {
        this.screenWidthVp = aw;
      }
    })
    .gesture(
      PanGesture({ direction: PanDirection.Vertical })
        .onActionEnd((event: GestureEvent): void => {
          if (event.offsetY < -30 && !this.expanded) {
            this.toggleExpanded(true);
          } else if (event.offsetY > 30 && this.expanded) {
            this.toggleExpanded(false);
          }
        })
    );
  }

  private isCalleeWaiting(): boolean {
    const inviterId = CallStore.shared().state.activeCall.inviterId;
    const isCaller = inviterId === this.selfInfo.id;
    return !isCaller && this.selfInfo.status === CallParticipantStatus.waiting;
  }

  private toggleExpanded(next: boolean): void {
    if (this.expanded === next) {
      return;
    }
    animateTo(
      { duration: ANIM_DURATION, curve: Curve.EaseInOut },
      (): void => {
        this.expanded = next;
        this.controlsHeight = next
          ? CallConstants.groupFunctionViewHeight
          : CallConstants.groupSmallFunctionViewHeight;
        this.matchRotation = next ? 0 : 180;
      },
    );
  }

  // ---- Buttons ----

  @Builder
  declineBtn() {
    ControlsButton({
      image: CallKitBundle.imageMap('icon_hangup'),
      title: TUICallKitLocalize('TUICallKit.decline'),
      bgColor: CallConstants.Color_HangupRed,
      imageSize: BTN_LARGE,
      onTap: (): void => {
        CallEndedFlag().markSelfEnded();
        CallingBellFeature.shared().stopAll();
        CallingVibratorFeature.shared().stop();
        void CallStore.shared().reject().catch((e: Object): void => {
          Logger.warn('reject failed', e);
        });
      },
    });
  }

  @Builder
  answerBtn() {
    ControlsButton({
      image: this.mediaType === CallMediaType.video
        ? CallKitBundle.imageMap('icon_video_dialing')
        : CallKitBundle.imageMap('icon_dialing'),
      title: TUICallKitLocalize('TUICallKit.answer'),
      bgColor: CallConstants.Color_AnswerGreen,
      imageSize: BTN_LARGE,
      onTap: (): void => {
        CallingBellFeature.shared().stopAll();
        CallingVibratorFeature.shared().stop();
        void CallStore.shared().accept().catch((e: Object): void => {
          Logger.warn('accept failed', e);
        });
      },
    });
  }

  @Builder
  hangupBtn() {
    ControlsButton({
      image: CallKitBundle.imageMap('icon_hangup'),
      title: '',
      bgColor: CallConstants.Color_HangupRed,
      imageSize: this.expanded ? BTN_LARGE : BTN_SMALL,
      onTap: (): void => {
        CallEndedFlag().markSelfEnded();
        void CallStore.shared().hangup().catch((e: Object): void => {
          Logger.warn('hangup failed', e);
        });
      },
    });
  }

  @Builder
  muteBtn() {
    ControlsButton({
      image: this.deviceState.microphoneStatus === DeviceStatus.on
        ? CallKitBundle.imageMap('icon_mute')
        : CallKitBundle.imageMap('icon_mute_on'),
      title: this.expanded
        ? (this.deviceState.microphoneStatus === DeviceStatus.on
          ? TUICallKitLocalize('TUICallKit.unmuted')
          : TUICallKitLocalize('TUICallKit.muted'))
        : '',
      isSelected: this.deviceState.microphoneStatus !== DeviceStatus.on,
      bgColor: CallConstants.Color_BgMask,
      imageSize: this.expanded ? BTN_LARGE : BTN_SMALL,
      onTap: (): void => {
        if (this.deviceState.microphoneStatus === DeviceStatus.on) {
          DeviceStore.shared().closeLocalMicrophone();
        } else {
          void DeviceStore.shared().openLocalMicrophone();
        }
      },
    });
  }

  @Builder
  audioRouteBtn() {
    ControlsButton({
      image: this.deviceState.currentAudioRoute === AudioRoute.speakerphone
        ? CallKitBundle.imageMap('icon_handsfree_on')
        : CallKitBundle.imageMap('icon_handsfree'),
      title: this.expanded
        ? (this.deviceState.currentAudioRoute === AudioRoute.speakerphone
          ? TUICallKitLocalize('TUICallKit.AVRoutePickerView.speakerPhone')
          : TUICallKitLocalize('TUICallKit.AVRoutePickerView.earpiece'))
        : '',
      isSelected: this.deviceState.currentAudioRoute === AudioRoute.speakerphone,
      bgColor: CallConstants.Color_BgMask,
      imageSize: this.expanded ? BTN_LARGE : BTN_SMALL,
      onTap: (): void => {
        const next = this.deviceState.currentAudioRoute === AudioRoute.speakerphone
          ? AudioRoute.earpiece
          : AudioRoute.speakerphone;
        DeviceStore.shared().setAudioRoute(next);
      },
    });
  }

  @Builder
  cameraBtn() {
    ControlsButton({
      image: this.deviceState.cameraStatus === DeviceStatus.on
        ? CallKitBundle.imageMap('icon_camera_on')
        : CallKitBundle.imageMap('icon_camera_off'),
      title: this.expanded
        ? (this.deviceState.cameraStatus === DeviceStatus.on
          ? TUICallKitLocalize('TUICallKit.cameraOn')
          : TUICallKitLocalize('TUICallKit.cameraOff'))
        : '',
      isSelected: this.deviceState.cameraStatus === DeviceStatus.on,
      bgColor: CallConstants.Color_BgMask,
      imageSize: this.expanded ? BTN_LARGE : BTN_SMALL,
      onTap: (): void => {
        if (this.deviceState.cameraStatus === DeviceStatus.on) {
          DeviceStore.shared().closeLocalCamera();
          return;
        }
        let context: common.UIAbilityContext;
        try {
          context = getContext(this) as common.UIAbilityContext;
        } catch (e) {
          Logger.error('MultiCallControlsView: getContext failed', e);
          return;
        }
        Permission.requestCameraInCall(context)
          .then((granted: boolean): void => {
            if (!granted) {
              Logger.warn('MultiCallControlsView: camera permission denied');
              Toast.showOnTop(TUICallKitLocalize('TUICallKit.FailedToGetCameraPermission.Title'));
              return;
            }
            DeviceStore.shared().openLocalCamera(this.deviceState.isFrontCamera).catch((err: Object): void => {
              Logger.warn('MultiCallControlsView: openLocalCamera failed', err);
            });
          })
          .catch((e: Object): void => {
            Logger.error('MultiCallControlsView: requestCameraInCall threw', e);
          });
      },
    });
  }
}
