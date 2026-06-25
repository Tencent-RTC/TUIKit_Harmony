// Plays dialing / ringing / hangup audio via @ohos.multimedia.media AVPlayer.
// Each AVPlayer instance is single-shot; we recreate per playback.
//
// Background-ringtone deferral: when the callee ringtone is requested while
// the app is in the background, AVPlayer may be denied audio focus. We mark
// `pendingRing` and re-fire on the next foreground transition (only if the
// call is still in `waiting`).

import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import {
  CallStore,
  CallParticipantStatus,
  CallMediaType,
  DeviceStore,
  AudioRoute,
} from '@tencentcloud/atomicxcore';
import { Constants } from '../common/Constants';
import { Logger } from '../common/utils/Logger';
import { Preferences } from '../common/utils/Preferences';
import { GlobalState } from '../state/GlobalState';
import { AppStateObserver } from './AppStateObserver';
import { CallStatusObserver } from './CallStatusObserver';

enum BellKind {
  dialing,
  ringing,
  hangup,
}

export class CallingBellFeature {
  private static instance: CallingBellFeature | null = null;
  private context: common.Context | null = null;
  private player: media.AVPlayer | null = null;
  private currentKind: BellKind | null = null;
  private looping: boolean = false;
  private customRingPath: string = '';
  private pendingRing: boolean = false;
  private appStateUnsubscribe: (() => void) | null = null;

  static shared(): CallingBellFeature {
    if (!CallingBellFeature.instance) {
      CallingBellFeature.instance = new CallingBellFeature();
    }
    return CallingBellFeature.instance;
  }

  init(context: common.Context): void {
    if (this.context) {
      return;
    }
    this.context = context;
    // Stop both dialing and ringing as soon as the local user leaves `waiting`
    // (call accepted / rejected / cancelled / remote hung up before pickup).
    // atomicxcore exposes no typed listener for status changes — this bridge
    // is the only event source.
    CallStatusObserver().addListener((status: CallParticipantStatus): void => {
      if (status === CallParticipantStatus.waiting) {
        return;
      }
      this.stopAll();
    });
  }

  setCustomRingFilePath(path: string): void {
    this.customRingPath = path ?? '';
    void Preferences.setCallingBellPath(this.customRingPath);
  }

  startDialing(): void {
    void this.startBell(BellKind.dialing, true);
  }

  /** Skipped in mute mode; deferred to foreground when app is currently background. */
  startRinging(): void {
    if (GlobalState().enableMuteMode) {
      Logger.info('CallingBellFeature: mute mode enabled, skip ringing');
      return;
    }
    if (AppStateObserver().isBackground()) {
      Logger.info('CallingBellFeature: app is background, defer ringing');
      this.pendingRing = true;
      this.subscribeAppStateOnce();
      return;
    }
    void this.startBell(BellKind.ringing, true);
  }

  playHangupOnce(): void {
    void this.startBell(BellKind.hangup, false);
  }

  stopAll(): void {
    this.pendingRing = false;
    this.unsubscribeAppState();
    this.releasePlayer();
  }

  syncWithCallState(): void {
    const state = CallStore.shared().state;
    const selfStatus = state.selfInfo.status;
    const isInviter = state.activeCall.inviterId === state.selfInfo.id;

    if (selfStatus === CallParticipantStatus.waiting) {
      if (isInviter) {
        this.startDialing();
      } else {
        this.startRinging();
      }
    } else {
      this.stopAll();
    }
  }

  private subscribeAppStateOnce(): void {
    if (this.appStateUnsubscribe !== null) {
      return;
    }
    this.appStateUnsubscribe = AppStateObserver().addListener((isBackground: boolean): void => {
      if (isBackground) {
        return;
      }
      // Foreground transition. Only re-fire if still pending and the call is
      // still in `waiting` (user might have answered / rejected via the
      // system notification while we were backgrounded).
      if (!this.pendingRing) {
        this.unsubscribeAppState();
        return;
      }
      const status = CallStore.shared().state.selfInfo.status;
      if (status !== CallParticipantStatus.waiting) {
        Logger.info('CallingBellFeature: pending ring dropped, status =', status);
        this.pendingRing = false;
        this.unsubscribeAppState();
        return;
      }
      if (GlobalState().enableMuteMode) {
        Logger.info('CallingBellFeature: mute mode enabled on resume, skip pending ring');
        this.pendingRing = false;
        this.unsubscribeAppState();
        return;
      }
      Logger.info('CallingBellFeature: app resumed, firing pending ring');
      this.pendingRing = false;
      this.unsubscribeAppState();
      void this.startBell(BellKind.ringing, true);
    });
  }

  private unsubscribeAppState(): void {
    if (this.appStateUnsubscribe !== null) {
      this.appStateUnsubscribe();
      this.appStateUnsubscribe = null;
    }
  }

  private async startBell(kind: BellKind, loop: boolean): Promise<void> {
    if (!this.context) {
      Logger.warn('CallingBellFeature.startBell: context not initialized');
      return;
    }
    this.releasePlayer();
    this.currentKind = kind;
    this.looping = loop;

    // Force the audio route BEFORE play() so the bell never leaks out of the
    // earpiece. Aligned with iOS:
    //   dial   → mediaType.audio   ⇒ earpiece
    //            mediaType.video   ⇒ speakerphone
    //   ring   → speakerphone (always — iOS uses
    //            `setAudioSessionForRingtone()` + `overrideOutputAudioPort(.speaker)`
    //            to make the incoming ringtone audible regardless of the
    //            currently-selected device).
    CallingBellFeature.applyAudioRouteFor(kind);

    try {
      const player = await media.createAVPlayer();
      this.player = player;
      const fileName = CallingBellFeature.fileNameFor(kind, this.customRingPath);
      const fd = await this.context.resourceManager.getRawFd(fileName);
      player.fdSrc = { fd: fd.fd, offset: fd.offset, length: fd.length };

      player.on('stateChange', (state: media.AVPlayerState): void => {
        if (state === 'initialized') {
          void player.prepare();
        } else if (state === 'prepared') {
          player.loop = loop;
          void player.play();
        } else if (state === 'completed' && !loop) {
          this.releasePlayer();
        } else if (state === 'error') {
          Logger.error('CallingBellFeature: AVPlayer entered error state');
          this.releasePlayer();
        }
      });
      player.on('error', (err: Object): void => {
        Logger.error('CallingBellFeature: AVPlayer error', err);
        this.releasePlayer();
      });
    } catch (e) {
      Logger.error('CallingBellFeature.startBell failed', e);
      this.releasePlayer();
    }
  }

  private static fileNameFor(kind: BellKind, customRingPath: string): string {
    switch (kind) {
      case BellKind.dialing: return Constants.DEFAULT_DIALING_FILE;
      case BellKind.ringing:
        return customRingPath && customRingPath.length > 0
          ? customRingPath
          : Constants.DEFAULT_RINGING_FILE;
      case BellKind.hangup: return Constants.DEFAULT_HANGUP_FILE;
      default: return Constants.DEFAULT_RINGING_FILE;
    }
  }

  private static applyAudioRouteFor(kind: BellKind): void {
    let route: AudioRoute;
    switch (kind) {
      case BellKind.ringing:
        route = AudioRoute.speakerphone;
        break;
      case BellKind.dialing: {
        const mediaType = CallStore.shared().state.activeCall.mediaType;
        route = mediaType === CallMediaType.video
          ? AudioRoute.speakerphone
          : AudioRoute.earpiece;
        break;
      }
      case BellKind.hangup:
      default:
        return;
    }
    try {
      DeviceStore.shared().setAudioRoute(route);
    } catch (e) {
      Logger.warn('CallingBellFeature.applyAudioRouteFor failed', e);
    }
  }

  private releasePlayer(): void {
    const p = this.player;
    this.player = null;
    this.currentKind = null;
    this.looping = false;
    if (!p) {
      return;
    }
    try {
      p.off('stateChange');
      p.off('error');
    } catch (_e) { /* ignore */ }
    void p.release().catch((e: Object): void => {
      Logger.warn('CallingBellFeature.release failed', e);
    });
  }
}
