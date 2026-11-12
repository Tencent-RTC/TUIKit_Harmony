import { V2TIMErrorCode, V2TIMManager, V2TIMMessage, V2TIMTTSVoiceFormat } from '@tencentcloud/imsdk';

interface TtsError {
  code?: number;
  message?: string;
}

export class TtsSession {
  private msgId?: string;
  private streamId?: string;

  get boundMsgId(): string | undefined {
    return this.msgId;
  }

  startFor(message: V2TIMMessage, onStarted: () => void, onFailed: (code: number, desc: string) => void): boolean {
    const streamElem = message.streamElem;
    if (!streamElem) {
      return false;
    }
    this.msgId = message.msgID;
    this.streamId = streamElem.streamID ?? '';
    if (!this.msgId || this.streamId.length === 0) {
      onFailed(V2TIMErrorCode.ERR_INVALID_PARAMETERS, 'streamID is empty');
      return true;
    }
    const voiceFormat: V2TIMTTSVoiceFormat = { voiceID: '', speed: 1.0 };
    try {
      V2TIMManager.getMessageManager().startTTS(this.msgId, this.streamId, 0, voiceFormat)
        .then(() => {
          onStarted();
        })
        .catch((error: TtsError) => {
          onFailed(error?.code ?? -1, error?.message ?? '');
        });
    } catch (e) {
      const error = e as Error;
      onFailed(-1, error?.message ?? '');
    }
    return true;
  }

  stop(): void {
    const msgId = this.msgId;
    const streamId = this.streamId;
    if (msgId === undefined) {
      return;
    }
    this.msgId = undefined;
    this.streamId = undefined;
    if (!streamId || streamId.length === 0) {
      return;
    }
    try {
      V2TIMManager.getMessageManager().stopTTS(msgId, streamId).catch(() => {
      });
    } catch (e) {
      return;
    }
  }
}
