// Bottom controls panel for 1-on-1 calls. Layout mirrors Flutter
// SingleCallControlsWidget exactly:
//
//   Flutter Positioned wrapping:    bottom: 40 + safeArea.bottom
//   Flutter inner layout:           Row(spaceEvenly) [+ Column for video]
//
// This view ports the same flow-based layout to ArkUI: a single Column
// with `padding.bottom = 40` plus inner Row(s) using
// `justifyContent(SpaceEvenly)`. The system nav-bar inset is added by
// the PARENT (CallView's controls Column), so this view only handles
// the Flutter literal `40` baseline.
//
// Five layouts (matching Flutter `_viewStrategies`):
//   - audio_waiting_caller: mic / hangup(cancel) / speaker
//   - audio_waiting_called: reject / accept
//   - audio_accept:         mic / hangup / speaker
//   - video_waiting_caller: switchCamera / hangup(cancel) / camera
//   - video_waiting_called: reject / accept
//   - video_accept:         row1 [mic / speaker / camera] + row2 [_, hangup, switchCamera-small]

import {
  CallStore, DeviceStore, CallParticipantInfo, DeviceState, CallMediaType,
  CallParticipantStatus, DeviceStatus,
} from '@tencentcloud/atomicxcore';
import { ControlsButton } from '../../../../common/widgets/ControlsButton';
import { CallViewAudioRoutePicker } from './audioRoutePicker/CallViewAudioRoutePicker';
import { CallKitBundle } from '../../../../common/CallKitBundle';
import { TUICallKitLocalize } from '../../../../common/Localized';
import { CallConstants } from '../../../../common/CallConstants';
import { Constants } from '../../../../common/Constants';
import { Logger } from '../../../../common/utils/Logger';
import { CallEndedFlag } from '../../../../state/CallEndedFlag';
import { CallingBellFeature } from '../../../../feature/CallingBellFeature';
import { CallingVibratorFeature } from '../../../../feature/CallingVibratorFeature';

enum Layout {
  calleeWaiting = 0,        // accept + reject
  audio = 1,                // mic + hangup + speaker
  videoWaitingCaller = 2,   // switchCamera + hangup(cancel) + camera
  videoAccept = 3,          // mic/speaker/camera + hangup + switchCameraSmall
}

/** Big button image (60vp) — matches Flutter `imgHeight: 60`. */
const BTN_LARGE: number = 60;
/** Small button image (28vp) — matches Flutter switchCameraSmall `imgHeight: 28`. */
const BTN_SMALL: number = 28;

/**
 * Bottom inset before the system nav indicator. Matches
 * `Flutter Positioned(bottom: 40 + MediaQuery.padding.bottom)`.
 */
const BOTTOM_INSET: number = 40;

/** Vertical gap between the primary row and the hangup row in video_accept. */
const ROW_GAP: number = 20;

@Component
export struct SingleCallControlsView {
  @ObjectLink selfInfo: CallParticipantInfo;
  @ObjectLink deviceState: DeviceState;
  @State mediaType: CallMediaType = CallMediaType.audio;
  isCaller: boolean = false;
  enableVirtualBackground: boolean = true;

  /**
   * Bottom safe-area inset (≈ navBarHeight). Added to BOTTOM_INSET so the
   * total bottom padding is `40 + safe`, exactly matching Flutter
   * `Positioned(bottom: 40 + MediaQuery.padding.bottom)`.
   */
  bottomSafeInset: number = 0;

  build() {
    Column() {
      this.layoutContent();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ bottom: BOTTOM_INSET + this.bottomSafeInset })
    .constraintSize({ maxWidth: Constants.CONTROLS_CONTAINER_MAX_WIDTH });
  }

  @Builder
  layoutContent() {
    if (this.currentLayout() === Layout.calleeWaiting) {
      this.layoutCalleeWaiting();
    } else if (this.currentLayout() === Layout.audio) {
      this.layoutAudio();
    } else if (this.currentLayout() === Layout.videoWaitingCaller) {
      this.layoutVideoWaitingCaller();
    } else {
      this.layoutVideoAccept();
    }
  }

  /** Flutter `_buildAudioAndVideoCalleeWaitingView`: Row(spaceEvenly){ reject, accept }. */
  @Builder
  layoutCalleeWaiting() {
    Row() {
      this.declineBtn();
      this.answerBtn();
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly);
  }

  /**
   * Flutter `_buildAudioAcceptedView` and `_buildAudioCallerWaitingView`:
   * Row(spaceEvenly){ mic, hangup, speaker }. Hangup tip differs (cancel vs
   * hangup) which is handled by `hangupBtn(titleOverride)`.
   */
  @Builder
  layoutAudio() {
    Row() {
      this.muteBtn();
      this.hangupBtn(this.isWaitingCaller() ? 'cancel' : undefined);
      this.audioRoutePicker();
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly);
  }

  /** Flutter `_buildVideoCallerWaitingView`: Row(spaceEvenly){ switchCamera, hangup(cancel), camera }. */
  @Builder
  layoutVideoWaitingCaller() {
    Row() {
      this.switchCameraLargeBtn();
      this.hangupBtn('cancel');
      this.cameraBtn();
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly);
  }

  /**
   * Flutter `_buildVideoCallerAndCalleeAcceptedView`:
   *   Column(start){
   *     Row(spaceEvenly){ mic, speaker, camera },
   *     SizedBox(height: 20),
   *     Row(spaceEvenly){ SizedBox(100), hangup, cameraStatus.on ? switchCameraSmall : SizedBox(100) }
   *   }
   */
  @Builder
  layoutVideoAccept() {
    Column() {
      Row() {
        this.muteBtn();
        this.audioRoutePicker();
        this.cameraBtn();
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly);

      // Flutter SizedBox(height: 20) between primary row and hangup row.
      Blank().height(ROW_GAP);

      Row() {
        // Left placeholder — matches Flutter `SizedBox(width: 100)`.
        Column().width(100).height(BTN_LARGE);

        this.hangupBtn('');

        // Right slot: small switch-camera when camera is on, else placeholder.
        if (this.deviceState.cameraStatus === DeviceStatus.on) {
          this.switchCameraSmallBtn();
        } else {
          Column().width(100).height(BTN_LARGE);
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly);
    }
    .width('100%');
  }

  private currentLayout(): Layout {
    // Callee in waiting state — same UI for audio + video.
    if (this.selfInfo.status === CallParticipantStatus.waiting && !this.isCaller) {
      return Layout.calleeWaiting;
    }
    if (this.mediaType === CallMediaType.audio) {
      // audio_waiting_caller and audio_accept share the same Row layout
      // (only the hangup tip changes — handled by hangupBtn).
      return Layout.audio;
    }
    // Video, caller side.
    if (this.selfInfo.status !== CallParticipantStatus.accept) {
      return Layout.videoWaitingCaller;
    }
    return Layout.videoAccept;
  }

  private isWaitingCaller(): boolean {
    return this.isCaller && this.selfInfo.status === CallParticipantStatus.waiting;
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
        // See markSelfEnded rationale in CallEndedFlag.
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

  /**
   * `titleOverride`:
   *   undefined → `TUICallKit.hangup`     (audio default)
   *   'cancel'  → `TUICallKit.cancel`     (caller waiting / outgoing)
   *   ''        → icon-only               (video accepted in-call)
   */
  @Builder
  hangupBtn(titleOverride?: string) {
    ControlsButton({
      image: CallKitBundle.imageMap('icon_hangup'),
      title: titleOverride === undefined
        ? TUICallKitLocalize('TUICallKit.hangup')
        : (titleOverride.length > 0 ? TUICallKitLocalize(`TUICallKit.${titleOverride}`) : ''),
      bgColor: CallConstants.Color_HangupRed,
      imageSize: BTN_LARGE,
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
      title: this.deviceState.microphoneStatus === DeviceStatus.on
        ? TUICallKitLocalize('TUICallKit.unmuted')
        : TUICallKitLocalize('TUICallKit.muted'),
      isSelected: this.deviceState.microphoneStatus !== DeviceStatus.on,
      bgColor: CallConstants.Color_BgMask,
      imageSize: BTN_LARGE,
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
  cameraBtn() {
    ControlsButton({
      image: this.deviceState.cameraStatus === DeviceStatus.on
        ? CallKitBundle.imageMap('icon_camera_on')
        : CallKitBundle.imageMap('icon_camera_off'),
      title: this.deviceState.cameraStatus === DeviceStatus.on
        ? TUICallKitLocalize('TUICallKit.cameraOn')
        : TUICallKitLocalize('TUICallKit.cameraOff'),
      isSelected: this.deviceState.cameraStatus === DeviceStatus.on,
      bgColor: CallConstants.Color_BgMask,
      imageSize: BTN_LARGE,
      onTap: (): void => {
        if (this.deviceState.cameraStatus === DeviceStatus.on) {
          DeviceStore.shared().closeLocalCamera();
        } else {
          void DeviceStore.shared().openLocalCamera(this.deviceState.isFrontCamera);
        }
      },
    });
  }

  @Builder
  audioRoutePicker() {
    CallViewAudioRoutePicker({ deviceState: this.deviceState });
  }

  /** Flutter `_getSwitchCameraButton` — large 60vp icon, used in videoWaitingCaller. */
  @Builder
  switchCameraLargeBtn() {
    ControlsButton({
      image: CallKitBundle.imageMap('icon_big_switch_camera'),
      title: TUICallKitLocalize('TUICallKit.switchCamera'),
      bgColor: CallConstants.Color_BgMask,
      imageSize: BTN_LARGE,
      onTap: (): void => {
        DeviceStore.shared().switchCamera(!this.deviceState.isFrontCamera);
      },
    });
  }

  /** Flutter `_getSwitchCameraSmallButton` — 28vp icon, no title. Used in videoAccept. */
  @Builder
  switchCameraSmallBtn() {
    ControlsButton({
      image: CallKitBundle.imageMap('switch_camera'),
      title: '',
      bgColor: CallConstants.Color_BgMask,
      imageSize: BTN_SMALL,
      onTap: (): void => {
        DeviceStore.shared().switchCamera(!this.deviceState.isFrontCamera);
      },
    });
  }
}
