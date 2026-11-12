import {
  V2TIMAdvancedMsgListener,
  V2TIMElemType,
  V2TIMManager,
  V2TIMMessage,
  V2TIMSDKListener,
  V2TIMTTSResponse
} from '@tencentcloud/imsdk';
import { MessageInputStore, TextSendMessagePayload } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { AIConstants } from '../AIConstants';
import { AIAssistantControlMessages } from '../AIAssistantControlMessages';
import { AsrBargeIn } from '../audio/AsrBargeIn';
import { AsrSession, AsrSessionListener, AsrSessionTranscript } from '../audio/AsrSession';
import { AudioPlaybackEngine } from '../audio/AudioPlaybackEngine';
import { EnergyVad } from '../audio/EnergyVad';
import { PreRollBuffer } from '../audio/PreRollBuffer';
import { SystemOpusDecoder } from '../audio/SystemOpusDecoder';
import { TtsDecodeWorker } from '../audio/TtsDecodeWorker';
import { TtsSession } from '../audio/TtsSession';
import { AsrServiceError } from '../../messageinput/asr/AsrServiceError';
import { RealtimeAsrAudioCapture } from '../../messageinput/asr/RealtimeAsrAudioCapture';
import { AICallState, TranscriptEntry } from './AICallState';

export interface AICallControllerCallbacks {
  onStateChanged: (state: AICallState) => void;
  onTranscriptChanged: (entries: TranscriptEntry[]) => void;
  onAudioLevel: (level: number) => void;
  onError: (message: Resource) => void;
  onListeningFailed: () => void;
  onAsrServiceUnavailable: () => void;
  onAudioInterrupted: (resumed: boolean) => void;
}

export class AICallController {
  private static readonly MIC_LEVEL_FULL_SCALE: number = 3000;

  private readonly robotUserId: string;
  private readonly conversationID: string;
  private readonly callbacks: AICallControllerCallbacks;
  private readonly vad: EnergyVad = new EnergyVad(
    AIConstants.FRAME_DURATION_MS,
    Math.floor(AIConstants.NOISE_CALIBRATION_MS / AIConstants.FRAME_DURATION_MS),
    undefined,
    undefined,
    AIConstants.VAD_MIN_NOISE_FLOOR
  );
  private readonly messageInputStore: MessageInputStore;
  private readonly preRoll: PreRollBuffer = new PreRollBuffer(AIConstants.PRE_ROLL_MAX_PACKETS);
  private readonly ttsSession: TtsSession = new TtsSession();
  private readonly asrListener: AsrSessionListener;
  private state: AICallState = AICallState.IDLE;
  private released: boolean = false;
  private muted: boolean = false;
  private hasRecognizedText: boolean = false;
  private preRollActive: boolean = false;
  private playback?: AudioPlaybackEngine;
  private capture?: RealtimeAsrAudioCapture;
  private asrSession?: AsrSession;
  private pausedExternally: boolean = false;
  private startFailed: boolean = false;
  private ttsDecoder?: TtsDecodeWorker;
  private streamingMsgId?: string;
  private hasStartedTTS: boolean = false;
  private ttsStartPending: boolean = false;
  private aiEntryIndex: number = -1;
  private enqueuedAudioMs: number = 0;
  private sentences: Map<number, string> = new Map();
  private drainGeneration: number = 0;
  private drainTimeout?: number;
  private awaitingAsrForListening: boolean = false;
  private committedUserText: string = '';
  private transcript: TranscriptEntry[] = [];
  private replyTimeoutTimer?: number;
  private speakingWatchdogTimer?: number;
  private readonly msgListener: V2TIMAdvancedMsgListener;
  private readonly sdkListener: V2TIMSDKListener;

  constructor(robotUserId: string, callbacks: AICallControllerCallbacks) {
    this.robotUserId = robotUserId;
    this.conversationID = `c2c_${robotUserId}`;
    this.callbacks = callbacks;
    this.messageInputStore = MessageInputStore.create(this.conversationID);
    this.asrListener = {
      onStarted: (): void => {
        this.onAsrStarted();
      },
      onStartFailed: (code: number, desc: string): void => {
        this.onAsrStartFailed(code, desc);
      }
    };
    this.msgListener = {
      onRecvNewMessage: (msg: V2TIMMessage): void => {
        this.handleStreamMessage(msg);
      },
      onRecvMessageModified: (msg: V2TIMMessage): void => {
        this.handleStreamMessage(msg);
      },
      onRecvTTSResponse: (response: V2TIMTTSResponse): void => {
        this.handleTtsResponse(response);
      }
    };
    this.sdkListener = {
      onExperimentalNotify: (key: string, param: string | Object): void => {
        const response = AsrSession.parseNotify(key, param);
        if (response) {
          this.handleAsrResponse(response);
        }
      }
    };
  }

  async start(): Promise<boolean> {
    if (this.released) {
      return false;
    }
    if (!RealtimeAsrAudioCapture.isSupported()) {
      this.callbacks.onError($r('app.string.uikit_ai_call_audio_unavailable'));
      return false;
    }
    V2TIMManager.getMessageManager().addAdvancedMsgListener(this.msgListener);
    V2TIMManager.getInstance().addSDKListener(this.sdkListener);

    const engine = await this.openCapture();
    if (this.released) {
      engine?.stop();
      return false;
    }
    if (!engine) {
      V2TIMManager.getMessageManager().removeAdvancedMsgListener(this.msgListener);
      V2TIMManager.getInstance().removeSDKListener(this.sdkListener);
      this.callbacks.onError($r('app.string.uikit_ai_call_audio_unavailable'));
      return false;
    }
    this.capture = engine;

    const player = new AudioPlaybackEngine(() => this.onPlaybackFinished(), (resumed: boolean) => {
      if (!this.released) {
        this.callbacks.onAudioInterrupted(resumed);
      }
    });
    const playerStarted = await player.start();
    if (this.released) {
      player.stop();
      return false;
    }
    this.playback = playerStarted ? player : undefined;
    if (this.playback) {
      this.ttsDecoder = new TtsDecodeWorker(this.playback, (generation: number, decodedMs: number,
        isFinished: boolean) => {
        this.onTtsChunkDecoded(generation, decodedMs, isFinished);
      });
    }
    if (!this.canPlayTts()) {
      this.callbacks.onError($r('app.string.uikit_ai_call_playback_unavailable'));
    }

    this.asrSession = new AsrSession(this.asrListener);
    this.awaitingAsrForListening = true;
    this.startNewAsrSession(false);
    AIAssistantControlMessages.enterVoiceCall(this.conversationID);
    return true;
  }

  release(): void {
    if (this.released) {
      return;
    }
    this.released = true;
    AIAssistantControlMessages.leaveVoiceCall(this.conversationID);
    this.cancelReplyTimeout();
    this.cancelSpeakingWatchdog();
    this.closeDrainWindow();
    this.capture?.stop();
    this.capture = undefined;
    this.discardPreRoll();
    this.ttsSession.stop();
    this.ttsDecoder?.release();
    this.ttsDecoder = undefined;
    this.playback?.stop();
    this.playback = undefined;
    this.asrSession?.stop();
    this.asrSession = undefined;
    V2TIMManager.getMessageManager().removeAdvancedMsgListener(this.msgListener);
    V2TIMManager.getInstance().removeSDKListener(this.sdkListener);
    this.setState(AICallState.IDLE);
  }

  setMuted(newMuted: boolean): void {
    if (this.released || this.muted === newMuted) {
      return;
    }
    this.muted = newMuted;
    if (newMuted) {
      this.abandonCurrentReply();
      this.discardPreRoll();
      this.asrSession?.stop();
      this.awaitingAsrForListening = false;
      this.committedUserText = '';
      this.clearSentences();
      this.notifyTranscript();
      this.setState(AICallState.IDLE);
    } else if (!this.pausedExternally) {
      this.enterListening();
    }
  }

  pause(): void {
    if (this.released || this.pausedExternally) {
      return;
    }
    this.pausedExternally = true;
    this.abandonCurrentReply();
    this.discardPreRoll();
    this.asrSession?.stop();
    this.awaitingAsrForListening = false;
    this.committedUserText = '';
    this.clearSentences();
    this.notifyTranscript();
    this.capture?.stop();
    this.capture = undefined;
    this.setState(AICallState.IDLE);
  }

  async resume(): Promise<void> {
    if (this.released || !this.pausedExternally) {
      return;
    }
    const engine = await this.openCapture();
    if (this.released || !this.pausedExternally) {
      engine?.stop();
      return;
    }
    if (!engine) {
      this.callbacks.onError($r('app.string.uikit_ai_call_audio_unavailable'));
      return;
    }
    this.pausedExternally = false;
    this.capture = engine;
    this.vad.resetCalibration();
    if (this.muted) {
      return;
    }
    this.enterListening();
  }

  retryListening(): void {
    if (this.released || !this.startFailed || this.muted || this.pausedExternally) {
      return;
    }
    this.enterListening();
  }

  private onAsrStarted(): void {
    if (this.released) {
      return;
    }
    this.startFailed = false;
    if (!this.awaitingAsrForListening) {
      return;
    }
    this.awaitingAsrForListening = false;
    if (this.state === AICallState.SPEAKING || this.ttsSession.boundMsgId !== undefined) {
      this.discardPreRoll();
      if (this.state === AICallState.THINKING) {
        this.scheduleReplyTimeout();
      }
      return;
    }
    const preRollPackets = this.takePreRoll();
    this.setState(AICallState.LISTENING);
    for (const packet of preRollPackets) {
      this.asrSession?.pushPacket(packet);
    }
  }

  private onAsrStartFailed(code: number, _desc: string): void {
    if (this.released) {
      return;
    }
    this.discardPreRoll();
    this.awaitingAsrForListening = false;
    this.startFailed = true;
    if (AsrServiceError.isServiceUnavailable(code)) {
      this.capture?.stop();
      this.capture = undefined;
      this.callbacks.onAsrServiceUnavailable();
    } else {
      this.callbacks.onError($r('app.string.uikit_ai_call_start_failed'));
      this.callbacks.onListeningFailed();
    }
    this.setState(AICallState.IDLE);
  }

  private async openCapture(): Promise<RealtimeAsrAudioCapture | undefined> {
    const engine = new RealtimeAsrAudioCapture(
      (packet: ArrayBuffer) => this.onCapturedPacket(packet),
      (pcm: Int16Array) => this.onAudioFrame(pcm)
    );
    const started = await engine.start();
    return started ? engine : undefined;
  }

  private onCapturedPacket(packet: ArrayBuffer): void {
    if (this.released || this.muted) {
      return;
    }
    const shouldUpload = this.state === AICallState.LISTENING ||
      this.state === AICallState.THINKING ||
      this.state === AICallState.SPEAKING;
    if (!shouldUpload) {
      return;
    }
    this.asrSession?.pushPacket(packet);
  }

  private onAudioFrame(pcm: Int16Array): void {
    if (this.released || this.muted) {
      return;
    }
    const frameState = this.state;
    const rms = this.vad.accept(pcm);
    let level: number;
    if (frameState === AICallState.SPEAKING) {
      level = this.playback?.currentLevel ?? 0;
    } else {
      level = Math.min(Math.max(rms / AICallController.MIC_LEVEL_FULL_SCALE, 0), 1);
    }
    this.callbacks.onAudioLevel(level);
    if (frameState === AICallState.LISTENING &&
      this.vad.hasSilenceFor(AIConstants.SILENCE_HOLD_MS) && this.hasRecognizedText) {
      this.finishListeningTurn();
    }
  }

  private takePreRoll(): ArrayBuffer[] {
    if (!this.preRollActive) {
      this.preRoll.clear();
      return [];
    }
    this.preRollActive = false;
    return this.preRoll.drain();
  }

  private discardPreRoll(): void {
    this.preRollActive = false;
    this.preRoll.clear();
  }

  private startNewAsrSession(resetEncoder: boolean = true): void {
    this.asrSession?.stop();
    this.vad.reset();
    if (resetEncoder) {
      this.capture?.requestEncoderReset();
    }
    this.asrSession?.start();
  }

  private handleAsrResponse(response: AsrSessionTranscript): void {
    if (this.released) {
      return;
    }
    const session = this.asrSession;
    if (!session) {
      return;
    }
    const responseId = response.sessionID;
    if (!responseId || responseId.length === 0) {
      return;
    }
    const accepted = responseId === session.sessionId ||
      (this.drainTimeout !== undefined && responseId === session.drainSessionId);
    if (!accepted) {
      return;
    }
    if (response.isFinished && responseId === session.sessionId) {
      session.noteRemoteFinished(responseId);
      if (!this.muted && !this.pausedExternally) {
        const wantListen = this.state === AICallState.LISTENING || this.awaitingAsrForListening;
        if (wantListen) {
          this.awaitingAsrForListening = true;
        }
        session.start();
      }
    }
    const text = response.text;
    if (text.length === 0) {
      return;
    }
    switch (this.state) {
      case AICallState.LISTENING:
        this.sentences.set(response.chunkIndex, text);
        this.hasRecognizedText = true;
        this.notifyTranscript(this.joinedText());
        break;
      case AICallState.THINKING:
        if (this.drainTimeout !== undefined) {
          this.sentences.set(response.chunkIndex, text);
          this.hasRecognizedText = true;
          this.notifyTranscript(this.joinedText());
        } else {
          this.maybeBargeInFromAsr(response.chunkIndex, text);
        }
        break;
      case AICallState.SPEAKING:
        this.maybeBargeInFromAsr(response.chunkIndex, text);
        break;
      default:
        break;
    }
  }

  private maybeBargeInFromAsr(chunkIndex: number, text: string): void {
    const probe = new Map<number, string>(this.sentences);
    probe.set(chunkIndex, text);
    const candidate = AICallController.joinSentences(probe);
    if (!AsrBargeIn.shouldBargeIn(candidate, this.committedUserText, this.currentLlmText(),
      AIConstants.ASR_BARGE_IN_MIN_CHARS)) {
      return;
    }
    this.sentences.set(chunkIndex, text);
    this.hasRecognizedText = true;
    const extra = AsrBargeIn.extraBeyondCommitted(candidate, this.committedUserText);
    if (extra !== undefined) {
      this.sentences.clear();
      this.sentences.set(0, extra);
    }
    this.notifyTranscript(this.joinedText());
    if (this.state === AICallState.SPEAKING) {
      this.bargeIn();
    } else {
      this.interruptThinking();
    }
  }

  private clearSentences(): void {
    this.sentences.clear();
    this.hasRecognizedText = false;
  }

  private joinedText(): string {
    return AICallController.joinSentences(this.sentences);
  }

  private static joinSentences(sentences: Map<number, string>): string {
    const keys = Array.from(sentences.keys()).sort((a: number, b: number) => a - b);
    let result = '';
    for (const key of keys) {
      result += sentences.get(key) ?? '';
    }
    return result;
  }

  private finishListeningTurn(): void {
    if (this.state !== AICallState.LISTENING) {
      return;
    }
    const gen = ++this.drainGeneration;
    this.drainTimeout = setTimeout(() => {
      this.finishDrain(gen);
    }, AIConstants.ASR_DRAIN_TIMEOUT_MS);
    this.vad.reset();
    this.setState(AICallState.THINKING);
    this.notifyTranscript(this.joinedText());
  }

  private finishDrain(gen: number): void {
    if (this.released || gen !== this.drainGeneration) {
      return;
    }
    this.closeDrainWindow();
    const text = this.joinedText();
    this.committedUserText = text;
    this.clearSentences();
    if (this.state !== AICallState.THINKING) {
      return;
    }
    if (text.length === 0) {
      this.enterListening();
      return;
    }
    this.transcript.push(new TranscriptEntry(true, text));
    const entryIndex = this.transcript.length - 1;
    this.notifyTranscript();
    this.scheduleReplyTimeout();
    this.sendToRobot(text, entryIndex);
  }

  private closeDrainWindow(): void {
    this.drainGeneration++;
    if (this.drainTimeout !== undefined) {
      clearTimeout(this.drainTimeout);
      this.drainTimeout = undefined;
    }
    this.asrSession?.endDrain();
  }

  private sendToRobot(text: string, entryIndex: number): void {
    this.messageInputStore.sendMessage(new TextSendMessagePayload(text), undefined,
      new CompletionHandlerAdapter(undefined, () => {
        if (this.released) {
          return;
        }
        this.markUserEntryFailed(entryIndex);
        this.callbacks.onError($r('app.string.uikit_ai_call_send_failed'));
        if (this.state !== AICallState.THINKING) {
          return;
        }
        this.cancelReplyTimeout();
        this.enterListening();
      }));
  }

  private canPlayTts(): boolean {
    return this.playback !== undefined && this.ttsDecoder !== undefined && SystemOpusDecoder.isSupported();
  }

  private handleStreamMessage(msg: V2TIMMessage): void {
    if (this.released) {
      return;
    }
    if (msg.sender !== this.robotUserId) {
      return;
    }
    if (msg.elemType !== V2TIMElemType.V2TIM_ELEM_TYPE_STREAM) {
      return;
    }
    const streamElem = msg.streamElem;
    if (!streamElem) {
      return;
    }
    if (this.streamingMsgId !== msg.msgID) {
      this.streamingMsgId = msg.msgID;
      this.hasStartedTTS = false;
      this.ttsStartPending = false;
      this.aiEntryIndex = -1;
      this.enqueuedAudioMs = 0;
      this.ttsDecoder?.beginStream();
    }

    this.updateAiTranscript(streamElem.markdown ?? '');

    if (!this.hasStartedTTS && !this.ttsStartPending && this.state === AICallState.THINKING && this.canPlayTts()) {
      this.ttsStartPending = true;
      const attached = this.ttsSession.startFor(msg, () => {
        this.ttsStartPending = false;
        if (!this.released) {
          this.hasStartedTTS = true;
        }
      }, () => {
        this.ttsStartPending = false;
      });
      if (!attached) {
        this.ttsStartPending = false;
      }
    }

    if (streamElem.isStreamEnded && !this.hasStartedTTS && !this.ttsStartPending &&
      this.state === AICallState.THINKING && this.drainTimeout === undefined) {
      this.enterListening();
    }
  }

  private updateAiTranscript(markdown: string): void {
    if (markdown.length === 0) {
      return;
    }
    if (this.aiEntryIndex >= 0 && this.aiEntryIndex < this.transcript.length) {
      this.transcript[this.aiEntryIndex] = new TranscriptEntry(false, markdown);
    } else {
      this.transcript.push(new TranscriptEntry(false, markdown));
      this.aiEntryIndex = this.transcript.length - 1;
    }
    this.notifyTranscript();
  }

  private handleTtsResponse(response: V2TIMTTSResponse): void {
    if (this.released) {
      return;
    }
    if (response.msgID !== this.ttsSession.boundMsgId) {
      return;
    }
    const worker = this.ttsDecoder;
    if (!worker) {
      return;
    }
    const packets = (response.audioDataList ?? []).filter((data: ArrayBuffer) => data && data.byteLength > 0);
    worker.decode(packets, response.isFinished);
    if (this.state === AICallState.THINKING) {
      this.cancelReplyTimeout();
      this.setState(AICallState.SPEAKING);
    }
    if (this.state === AICallState.SPEAKING) {
      this.armSpeakingWatchdog(0);
    }
  }

  private onTtsChunkDecoded(generation: number, decodedMs: number, isFinished: boolean): void {
    if (this.released || generation !== this.ttsDecoder?.generation) {
      return;
    }
    this.enqueuedAudioMs += decodedMs;
    if (this.state === AICallState.SPEAKING) {
      this.armSpeakingWatchdog(isFinished ? this.enqueuedAudioMs : 0);
    }
  }

  private armSpeakingWatchdog(pendingPlaybackMs: number): void {
    this.cancelSpeakingWatchdog();
    this.speakingWatchdogTimer = setTimeout(() => {
      this.speakingWatchdogTimer = undefined;
      if (this.released || this.state !== AICallState.SPEAKING) {
        return;
      }
      this.enterListening();
    }, AIConstants.SPEAKING_IDLE_TIMEOUT_MS + pendingPlaybackMs);
  }

  private cancelSpeakingWatchdog(): void {
    if (this.speakingWatchdogTimer !== undefined) {
      clearTimeout(this.speakingWatchdogTimer);
      this.speakingWatchdogTimer = undefined;
    }
  }

  private scheduleReplyTimeout(): void {
    this.cancelReplyTimeout();
    this.replyTimeoutTimer = setTimeout(() => {
      this.replyTimeoutTimer = undefined;
      if (this.state === AICallState.THINKING) {
        this.callbacks.onError($r('app.string.uikit_ai_call_reply_timeout'));
        this.enterListening();
      }
    }, AIConstants.STREAM_REPLY_TIMEOUT_MS);
  }

  private cancelReplyTimeout(): void {
    if (this.replyTimeoutTimer !== undefined) {
      clearTimeout(this.replyTimeoutTimer);
      this.replyTimeoutTimer = undefined;
    }
  }

  private onPlaybackFinished(): void {
    if (this.released || this.state !== AICallState.SPEAKING) {
      return;
    }
    this.enterListening();
  }

  private bargeIn(): void {
    if (this.released || this.state !== AICallState.SPEAKING) {
      return;
    }
    this.enterListening(true, true);
  }

  private interruptThinking(): void {
    if (this.released || this.state !== AICallState.THINKING || this.drainTimeout !== undefined) {
      return;
    }
    this.enterListening(true, true);
  }

  private enterListening(resetEncoder: boolean = true, keepAsrText: boolean = false): void {
    this.abandonCurrentReply();
    if (!keepAsrText) {
      this.clearSentences();
    }
    this.vad.reset();
    this.discardPreRoll();
    if (this.asrSession?.isLive === true) {
      this.awaitingAsrForListening = false;
      this.setState(AICallState.LISTENING);
      this.notifyTranscript(this.joinedText());
      return;
    }
    this.awaitingAsrForListening = true;
    this.setState(AICallState.THINKING);
    this.startNewAsrSession(resetEncoder);
  }

  private abandonCurrentReply(): void {
    this.cancelReplyTimeout();
    this.cancelSpeakingWatchdog();
    this.closeDrainWindow();
    this.ttsSession.stop();
    this.ttsDecoder?.invalidate();
    this.playback?.flush();
  }

  private markUserEntryFailed(index: number): void {
    if (index < 0 || index >= this.transcript.length) {
      return;
    }
    const entry = this.transcript[index];
    this.transcript[index] = new TranscriptEntry(entry.isFromUser, entry.text, true);
    this.notifyTranscript();
  }

  private setState(newState: AICallState): void {
    if (this.state === newState) {
      return;
    }
    this.state = newState;
    this.callbacks.onStateChanged(newState);
  }

  private currentLlmText(): string {
    if (this.aiEntryIndex >= 0 && this.aiEntryIndex < this.transcript.length) {
      return this.transcript[this.aiEntryIndex].text;
    }
    for (let i = this.transcript.length - 1; i >= 0; i--) {
      if (!this.transcript[i].isFromUser) {
        return this.transcript[i].text;
      }
    }
    return '';
  }

  private notifyTranscript(pendingUserText: string = ''): void {
    const entries = this.transcript.slice();
    if (pendingUserText.length > 0) {
      entries.push(new TranscriptEntry(true, pendingUserText));
    }
    this.callbacks.onTranscriptChanged(entries);
  }
}
