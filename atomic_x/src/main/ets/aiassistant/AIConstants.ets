export class AIConstants {
  static readonly VOICE_ENTER_ACTION: string = 'enterVoiceCall';
  static readonly VOICE_LEAVE_ACTION: string = 'leaveVoiceCall';
  static readonly VOICE_SESSION_DESCRIPTION: string = 'voice call session';
  static readonly TRANSFER_TO_HUMAN_TEXT: string = '转人工';
  static readonly SAMPLE_RATE: number = 16000;
  static readonly CHANNEL_COUNT: number = 1;
  static readonly FRAME_SAMPLES: number = 320;
  static readonly FRAME_BYTES: number = 640;
  static readonly FRAME_DURATION_MS: number = 20;
  static readonly UPLOAD_BATCH_FRAMES: number = 5;
  static readonly ASR_LANGUAGE: string = 'zh';
  static readonly SILENCE_HOLD_MS: number = 1500;
  static readonly VAD_MIN_NOISE_FLOOR: number = 100.0;
  static readonly PRE_ROLL_MAX_PACKETS: number = 100;
  static readonly NOISE_CALIBRATION_MS: number = 300;
  static readonly ASR_START_TIMEOUT_MS: number = 8000;
  static readonly ASR_DRAIN_TIMEOUT_MS: number = 700;
  static readonly ASR_BARGE_IN_MIN_CHARS: number = 2;
  static readonly STREAM_REPLY_TIMEOUT_MS: number = 30000;
  static readonly SPEAKING_IDLE_TIMEOUT_MS: number = 10000;
}
