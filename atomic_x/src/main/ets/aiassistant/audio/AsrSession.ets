import { V2TIMManager } from '@tencentcloud/imsdk';
import { AIConstants } from '../AIConstants';

interface ExperimentalError {
  code?: number;
  message?: string;
}

interface StartParam {
  language: string;
}

interface FeedParam {
  sessionID: string;
  dataList: ArrayBuffer[];
}

interface StopParam {
  sessionID: string;
}

interface TranscriptNotify {
  sessionID?: string;
  chunkIndex?: number;
  text?: string;
  isFinished?: boolean;
}

export class AsrSessionTranscript {
  readonly sessionID?: string;
  readonly chunkIndex: number;
  readonly text: string;
  readonly isFinished: boolean;

  constructor(sessionID: string | undefined, chunkIndex: number, text: string, isFinished: boolean) {
    this.sessionID = sessionID;
    this.chunkIndex = chunkIndex;
    this.text = text;
    this.isFinished = isFinished;
  }
}

export interface AsrSessionListener {
  onStarted: () => void;
  onStartFailed: (code: number, desc: string) => void;
}

export class AsrSession {
  static readonly ERR_START_TIMEOUT: number = -1001;
  private static readonly ERR_UNSUPPORTED: number = -1002;
  static readonly NOTIFY_KEY: string = 'onRecvRealtimeTranscriberResponse';
  private static readonly API_START: string = 'startRealtimeTranscriber';
  private static readonly API_FEED: string = 'feedRealtimeAudioData';
  private static readonly API_STOP: string = 'stopRealtimeTranscriber';

  private readonly listener: AsrSessionListener;
  private pendingPackets: ArrayBuffer[] = [];
  private currentSessionId?: string;
  private starting: boolean = false;
  private pendingStartTimeout?: number;
  private drainingSessionId?: string;
  private generation: number = 0;

  constructor(listener: AsrSessionListener) {
    this.listener = listener;
  }

  get sessionId(): string | undefined {
    return this.currentSessionId;
  }

  get isStarting(): boolean {
    return this.starting;
  }

  get drainSessionId(): string | undefined {
    return this.drainingSessionId;
  }

  get isLive(): boolean {
    return this.currentSessionId !== undefined || this.starting;
  }

  start(): void {
    this.drainingSessionId = undefined;
    if (this.starting || this.currentSessionId !== undefined) {
      return;
    }
    this.starting = true;
    const gen = ++this.generation;
    this.pendingPackets = [];
    this.scheduleStartTimeout(gen);
    const param: StartParam = { language: AIConstants.ASR_LANGUAGE };
    AsrSession.callExperimental(AsrSession.API_START, param, (data: string | Object | undefined) => {
      const id = typeof data === 'string' ? data : '';
      if (gen !== this.generation) {
        if (id.length > 0) {
          const stopParam: StopParam = { sessionID: id };
          AsrSession.callExperimental(AsrSession.API_STOP, stopParam);
        }
        return;
      }
      this.cancelStartTimeout();
      this.generation++;
      this.starting = false;
      if (id.length === 0) {
        this.listener.onStartFailed(-1, 'empty sessionID');
        return;
      }
      this.currentSessionId = id;
      this.listener.onStarted();
    }, (code: number, desc: string) => {
      if (gen !== this.generation) {
        return;
      }
      this.cancelStartTimeout();
      this.generation++;
      this.starting = false;
      this.listener.onStartFailed(code, desc);
    });
  }

  pushPacket(packet: ArrayBuffer): void {
    const id = this.currentSessionId;
    if (id === undefined) {
      return;
    }
    this.pendingPackets.push(packet);
    if (this.pendingPackets.length >= AIConstants.UPLOAD_BATCH_FRAMES) {
      this.flush(id);
    }
  }

  stop(onStopped?: () => void): void {
    this.cancelStartTimeout();
    this.generation++;
    this.starting = false;
    const id = this.currentSessionId;
    this.currentSessionId = undefined;
    if (id === undefined) {
      this.pendingPackets = [];
      onStopped?.();
      return;
    }
    if (this.pendingPackets.length > 0) {
      this.flush(id);
    }
    this.drainingSessionId = id;
    const param: StopParam = { sessionID: id };
    AsrSession.callExperimental(AsrSession.API_STOP, param, () => {
      onStopped?.();
    }, () => {
      onStopped?.();
    });
  }

  endDrain(): void {
    this.drainingSessionId = undefined;
  }

  noteRemoteFinished(sessionID: string): void {
    if (this.currentSessionId !== sessionID) {
      return;
    }
    this.generation++;
    this.starting = false;
    this.currentSessionId = undefined;
    this.pendingPackets = [];
  }

  static parseNotify(key: string, param: string | Object): AsrSessionTranscript | undefined {
    if (key !== AsrSession.NOTIFY_KEY) {
      return undefined;
    }
    let notify: TranscriptNotify | undefined;
    if (typeof param === 'string') {
      try {
        notify = JSON.parse(param) as TranscriptNotify;
      } catch (e) {
        return undefined;
      }
    } else {
      notify = param as TranscriptNotify;
    }
    if (!notify) {
      return undefined;
    }
    const chunkIndex = typeof notify.chunkIndex === 'number' ? Math.floor(notify.chunkIndex) : 0;
    return new AsrSessionTranscript(
      typeof notify.sessionID === 'string' ? notify.sessionID : undefined,
      chunkIndex,
      typeof notify.text === 'string' ? notify.text : '',
      notify.isFinished === true
    );
  }

  private scheduleStartTimeout(gen: number): void {
    this.pendingStartTimeout = setTimeout(() => {
      this.pendingStartTimeout = undefined;
      if (gen !== this.generation) {
        return;
      }
      this.generation++;
      this.starting = false;
      this.listener.onStartFailed(AsrSession.ERR_START_TIMEOUT, 'startRealtimeTranscriber timeout');
    }, AIConstants.ASR_START_TIMEOUT_MS);
  }

  private cancelStartTimeout(): void {
    if (this.pendingStartTimeout !== undefined) {
      clearTimeout(this.pendingStartTimeout);
      this.pendingStartTimeout = undefined;
    }
  }

  private flush(sessionID: string): void {
    const batch = this.pendingPackets;
    this.pendingPackets = [];
    const param: FeedParam = { sessionID: sessionID, dataList: batch };
    AsrSession.callExperimental(AsrSession.API_FEED, param, undefined, () => {
    });
  }

  private static callExperimental(api: string, param: Object,
    onSuccess?: (data: string | Object | undefined) => void,
    onError?: (code: number, desc: string) => void): void {
    let promise: Promise<string | Object> | undefined;
    try {
      promise = V2TIMManager.getInstance().callExperimentalAPI(api, param);
    } catch (e) {
      const error = e as Error;
      const callback = onError;
      if (callback) {
        setTimeout(() => callback(AsrSession.ERR_UNSUPPORTED, error?.message ?? ''), 0);
      }
      return;
    }
    if (!promise) {
      const callback = onError;
      if (callback) {
        setTimeout(() => callback(AsrSession.ERR_UNSUPPORTED, ''), 0);
      }
      return;
    }
    promise.then((data: string | Object) => {
      onSuccess?.(data);
    }).catch((error: ExperimentalError) => {
      onError?.(error?.code ?? -1, error?.message ?? '');
    });
  }
}
