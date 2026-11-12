import { abilityAccessCtrl, ApplicationStateChangeCallback, common, Permissions } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AlertDialog, AtomicxNavigator, ThemeState, Toast } from '../../basecomponent/Index';
import { AICallController, AICallControllerCallbacks } from './AICallController';
import { AICallState, TranscriptEntry } from './AICallState';
import { TranscriptView } from './ui/TranscriptView';
import { VoiceOrbLevel, VoiceOrbView } from './ui/VoiceOrbView';

interface AICallPageArgs {
  robotUserId: string;
}

@Builder
function AICallPageBuilder(args: Object) {
  AICallPage({
    robotUserId: (args as AICallPageArgs).robotUserId,
    onClose: () => {
      AtomicxNavigator.pop();
    }
  })
}

export function pushAICallPage(robotUserId: string): boolean {
  const args: AICallPageArgs = { robotUserId: robotUserId };
  return AtomicxNavigator.push(wrapBuilder(AICallPageBuilder), args);
}

@CustomDialog
export struct AICallActivity {
  dialogController: CustomDialogController;
  robotUserId: string = '';

  build() {
    AICallPage({
      robotUserId: this.robotUserId,
      onClose: () => {
        this.dialogController.close();
      }
    })
  }
}

@Component
struct AICallPage {
  private static readonly ORB_SIZE_FULL: number = 280;
  private static readonly ORB_SIZE_COMPACT: number = 72;
  private static readonly ORB_LAYOUT_ANIM_MS: number = 320;
  private static readonly BACKGROUND: string = '#121417';
  private static readonly BUTTON_BACKGROUND: string = '#1FFFFFFF';
  private static readonly HANGUP_BACKGROUND: string = '#FF5A5F';
  robotUserId: string = '';
  onClose?: () => void;
  @State private orbState: AICallState = AICallState.IDLE;
  @State private statusText: Resource = $r('app.string.uikit_ai_call_listening');
  @State private isMuted: boolean = false;
  @State private subtitleVisible: boolean = true;
  @State private showingTranscriptPanel: boolean = false;
  @State private latestEntries: TranscriptEntry[] = [];
  @State private orbSize: number = AICallPage.ORB_SIZE_FULL;
  private orbLevel: VoiceOrbLevel = new VoiceOrbLevel();
  private controller?: AICallController;
  private currentState: AICallState = AICallState.IDLE;
  private listeningFailed: boolean = false;
  private visible: boolean = true;
  private closed: boolean = false;
  private asrUnavailableDialogShown: boolean = false;
  private appStateCallback?: ApplicationStateChangeCallback;

  aboutToAppear(): void {
    this.setKeepScreenOn(true);
    this.registerAppStateCallback();
    this.renderState(AICallState.IDLE);
    this.ensureMicrophonePermission();
  }

  aboutToDisappear(): void {
    this.closed = true;
    this.unregisterAppStateCallback();
    this.setKeepScreenOn(false);
    this.controller?.release();
    this.controller = undefined;
  }

  private showAsrServiceUnavailableDialog(): void {
    if (this.closed || this.asrUnavailableDialogShown) {
      return;
    }
    this.asrUnavailableDialogShown = true;
    const resourceManager = getContext(this).resourceManager;
    let message: string;
    let exitText: string;
    try {
      message = `${resourceManager.getStringSync($r('app.string.uikit_ai_call_asr_unavailable_title').id)}\n` +
        `${resourceManager.getStringSync($r('app.string.uikit_ai_call_asr_unavailable_content').id)}`;
      exitText = resourceManager.getStringSync($r('app.string.uikit_ai_call_asr_unavailable_exit').id);
    } catch (e) {
      message = '';
      exitText = '';
    }
    AlertDialog.show(message, exitText, undefined, () => {
      this.finish();
    }, this.getUIContext());
  }

  private onAudioInterrupted(resumed: boolean): void {
    if (resumed) {
      if (this.visible) {
        this.controller?.resume();
      }
    } else {
      this.controller?.pause();
    }
  }

  build() {
    Stack() {
      Column() {
        Stack() {
          Text($r('app.string.uikit_ai_call_mode_free'))
            .fontSize(14)
            .fontColor(Color.White)
            .height(32)
            .padding({ left: 14, right: 14 })
            .borderRadius(16)
            .backgroundColor(AICallPage.BUTTON_BACKGROUND)
        }
        .width('100%')
        .height(56)

        Stack() {
          VoiceOrbView({ state: this.orbState, level: this.orbLevel })
            .width(this.orbSize)
            .height(this.orbSize)
        }
        .width('100%')
        .layoutWeight(this.showingTranscriptPanel ? 0 : 1)

        if (this.showingTranscriptPanel) {
          TranscriptView({ entries: this.latestEntries })
            .width('100%')
            .layoutWeight(1.4)
        }

        Text(this.statusText)
          .fontSize(14)
          .fontColor('#B8BDC4')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 32 })

        Row({ space: 16 }) {
          this.CallButton(this.isMuted ? $rawfile('aiassistant/ic_call_mic_off.svg') :
            $rawfile('aiassistant/ic_call_mic.svg'), AICallPage.BUTTON_BACKGROUND, () => {
            this.onMicClicked();
          })
          this.CallButton(this.subtitleVisible ? $rawfile('aiassistant/ic_call_subtitle.svg') :
            $rawfile('aiassistant/ic_call_subtitle_off.svg'), AICallPage.BUTTON_BACKGROUND, () => {
            this.toggleSubtitle();
          })
          this.CallButton($rawfile('aiassistant/ic_call_hangup.svg'), AICallPage.HANGUP_BACKGROUND, () => {
            this.finish();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 24, right: 24 })

        Text($r('app.string.uikit_ai_call_disclaimer'))
          .fontSize(11)
          .fontColor('#6E747C')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 12, bottom: 16 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AICallPage.BACKGROUND)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  CallButton(icon: Resource, background: string, action: () => void) {
    Stack() {
      Image(icon)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(background)
    .onClick(action)
  }

  private finish(): void {
    if (this.closed) {
      return;
    }
    this.closed = true;
    this.controller?.release();
    this.controller = undefined;
    this.onClose?.();
  }

  private async ensureMicrophonePermission(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const permission: Permissions = 'ohos.permission.MICROPHONE';
    let granted = false;
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, [permission]);
      granted = result.authResults.length > 0 &&
        result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      granted = false;
    }
    if (this.closed) {
      return;
    }
    if (!granted) {
      Toast.info($r('app.string.uikit_ai_call_permission_denied'), this.getUIContext());
      this.finish();
      return;
    }
    await this.onMicrophoneReady();
  }

  private async onMicrophoneReady(): Promise<void> {
    if (this.robotUserId.trim().length === 0) {
      this.finish();
      return;
    }
    const callbacks: AICallControllerCallbacks = {
      onStateChanged: (state: AICallState): void => {
        if (state !== AICallState.IDLE) {
          this.listeningFailed = false;
        }
        this.renderState(state);
      },
      onTranscriptChanged: (entries: TranscriptEntry[]): void => {
        this.latestEntries = entries;
        this.applySubtitleVisibility();
      },
      onAudioLevel: (level: number): void => {
        this.orbLevel.set(level);
      },
      onError: (message: Resource): void => {
        Toast.info(message, this.getUIContext());
      },
      onListeningFailed: (): void => {
        this.listeningFailed = true;
        this.renderState(this.currentState);
      },
      onAsrServiceUnavailable: (): void => {
        this.showAsrServiceUnavailableDialog();
      },
      onAudioInterrupted: (resumed: boolean): void => {
        this.onAudioInterrupted(resumed);
      }
    };
    const controller = new AICallController(this.robotUserId, callbacks);
    this.controller = controller;
    const started = await controller.start();
    if (this.closed) {
      controller.release();
      return;
    }
    if (!started) {
      this.controller = undefined;
      controller.release();
      this.finish();
    }
  }

  private onMicClicked(): void {
    if (this.listeningFailed && !this.isMuted) {
      this.controller?.retryListening();
      return;
    }
    this.toggleMute();
  }

  private toggleMute(): void {
    this.isMuted = !this.isMuted;
    this.controller?.setMuted(this.isMuted);
    this.renderState(this.currentState);
  }

  private toggleSubtitle(): void {
    this.subtitleVisible = !this.subtitleVisible;
    this.applySubtitleVisibility();
  }

  private shouldShowTranscriptPanel(): boolean {
    return this.subtitleVisible && this.latestEntries.some((entry: TranscriptEntry) => entry.text.trim().length > 0);
  }

  private applySubtitleVisibility(): void {
    const showPanel = this.shouldShowTranscriptPanel();
    if (showPanel === this.showingTranscriptPanel) {
      return;
    }
    this.getUIContext().animateTo({ duration: AICallPage.ORB_LAYOUT_ANIM_MS, curve: Curve.FastOutSlowIn }, () => {
      this.showingTranscriptPanel = showPanel;
      this.orbSize = showPanel ? AICallPage.ORB_SIZE_COMPACT : AICallPage.ORB_SIZE_FULL;
    });
  }

  private renderState(state: AICallState): void {
    this.currentState = state;
    this.orbState = this.isMuted ? AICallState.LISTENING : state;
    if (this.isMuted) {
      this.statusText = $r('app.string.uikit_ai_call_muted');
    } else if (this.listeningFailed) {
      this.statusText = $r('app.string.uikit_ai_call_start_failed_retry');
    } else if (state === AICallState.THINKING) {
      this.statusText = $r('app.string.uikit_ai_call_thinking');
    } else if (state === AICallState.SPEAKING) {
      this.statusText = $r('app.string.uikit_ai_call_speaking');
    } else {
      this.statusText = $r('app.string.uikit_ai_call_listening');
    }
  }

  private registerAppStateCallback(): void {
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => {
        this.visible = true;
        this.controller?.resume();
      },
      onApplicationBackground: () => {
        this.visible = false;
        this.controller?.pause();
      }
    };
    this.appStateCallback = callback;
    try {
      getContext(this).getApplicationContext().on('applicationStateChange', callback);
    } catch (e) {
      this.appStateCallback = undefined;
    }
  }

  private unregisterAppStateCallback(): void {
    const callback = this.appStateCallback;
    if (!callback) {
      return;
    }
    this.appStateCallback = undefined;
    try {
      getContext(this).getApplicationContext().off('applicationStateChange', callback);
    } catch (e) {
      return;
    }
  }

  private setKeepScreenOn(keepOn: boolean): void {
    window.getLastWindow(getContext(this)).then((win: window.Window) => {
      win.setWindowKeepScreenOn(keepOn).catch(() => {
      });
      if (keepOn) {
        win.setWindowSystemBarProperties({
          statusBarColor: AICallPage.BACKGROUND,
          statusBarContentColor: '#FFFFFF',
          navigationBarColor: AICallPage.BACKGROUND,
          navigationBarContentColor: '#FFFFFF'
        }).catch(() => {
        });
        win.setWindowBackgroundColor(AICallPage.BACKGROUND);
      } else {
        ThemeState.getInstance().settingStatusBarAuto();
      }
    }).catch(() => {
    });
  }
}
