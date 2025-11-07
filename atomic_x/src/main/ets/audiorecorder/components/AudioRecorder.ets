import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';

export interface AudioRecorderListener {
  onDurationUpdate?: (duration: number) => void;
  onRecordingStart?: () => void;
  onRecordingStop?: (filePath: string, duration: number) => void;
  onRecordingCancel?: () => void;
  onError?: (error: string) => void;
  onPermissionDenied?: () => void;
}

class AudioRecorderImpl {
  private isRecording: boolean = false;
  private recordingDuration: number = 0;
  private recordingTimer: number | null = null;
  private recordingFilePath: string = '';
  private avRecorder: media.AVRecorder | undefined = undefined;
  private audioFile: fs.File | null = null;
  private context: common.UIAbilityContext | null = null;
  private avProfile: media.AVRecorderProfile = {
    audioBitrate: 100000,
    audioChannels: 1,
    audioCodec: media.CodecMimeType.AUDIO_AAC,
    audioSampleRate: 16000,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
  };
  private avConfig: media.AVRecorderConfig = {
    audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
    profile: this.avProfile,
    url: '',
  };

  private onDurationUpdate?: (duration: number) => void;
  private onRecordingStart?: () => void;
  private onRecordingStop?: (filePath: string, duration: number) => void;
  private onRecordingCancel?: () => void;
  private onError?: (error: string) => void;
  private onPermissionDenied?: () => void;

  constructor(context?: common.UIAbilityContext) {
    this.context = context || null;
  }


  setContext(context: common.UIAbilityContext) {
    this.context = context;
  }


  addListener(listener: AudioRecorderListener) {
    this.onDurationUpdate = listener.onDurationUpdate;
    this.onRecordingStart = listener.onRecordingStart;
    this.onRecordingStop = listener.onRecordingStop;
    this.onRecordingCancel = listener.onRecordingCancel;
    this.onError = listener.onError;
    this.onPermissionDenied = listener.onPermissionDenied;
  }

  getCurrentTime(): number {
    return this.recordingDuration;
  }

  getIsRecording(): boolean {
    return this.isRecording;
  }


  async startRecording(): Promise<boolean> {
    if (this.isRecording) {
      console.warn('[AudioRecorderManager] Already recording, cannot start again');
      return false;
    }

    try {
      if (!this.context) {
        if (this.onError) {
          this.onError('Missing application context, unable to request permissions');
        }
        return false;
      }
      const hasPermission = await this.checkAndRequestMicrophonePermission();
      if (!hasPermission) {

        return false;
      }
      await this.cleanupRecorder();
      this.avRecorder = await media.createAVRecorder();
      this.setAudioRecorderCallback();
      await this.createAndSetFd();
      await this.waitForRecorderState('idle');
      await this.avRecorder.prepare(this.avConfig);
      await this.waitForRecorderState('prepared');
      await this.avRecorder.start();
      await this.waitForRecorderState('started');
      this.isRecording = true;
      this.recordingDuration = 0;
      this.recordingTimer = setInterval(() => {
        this.recordingDuration++;
        if (this.onDurationUpdate) {
          this.onDurationUpdate(this.recordingDuration);
        }
        if (this.recordingDuration >= 60) {
          this.stopRecording();
        }
      }, 1000);
      if (this.onRecordingStart) {
        this.onRecordingStart();
      }
      return true;
    } catch (error) {
      if (this.onError) {
        this.onError(`Failed to start recording: ${error}`);
      }
      await this.cancelRecording();
      return false;
    }
  }

  async stopRecording(): Promise<boolean> {
    if (!this.isRecording) {
      console.warn('[AudioRecorderManager] Not recording, cannot stop');
      return false;
    }
    try {
      if (this.recordingTimer) {
        clearInterval(this.recordingTimer);
        this.recordingTimer = null;
      }
      const duration = this.recordingDuration;
      if (duration < 1) {
        console.warn('[AudioRecorderManager] Recording duration too short, cancelling');
        await this.cancelRecording();
        return false;
      }
      if (this.avRecorder != undefined) {

        if (this.avRecorder.state === 'started' || this.avRecorder.state === 'paused') {

          await this.avRecorder.stop();
          await this.waitForRecorderState('stopped');
        }

        if (this.avRecorder.state === 'stopped') {
          await this.avRecorder.reset();
          await this.waitForRecorderState('idle');
        }
        await this.avRecorder.release();
        this.avRecorder = undefined;
      }

      if (this.audioFile) {
        fs.closeSync(this.audioFile);
        this.audioFile = null;
      }
      const filePath = this.recordingFilePath;
      this.isRecording = false;
      this.recordingDuration = 0;
      if (this.onRecordingStop) {
        this.onRecordingStop(filePath, duration);
      }
      return true;
    } catch (error) {
      if (this.onError) {
        this.onError(`Failed to stop recording: ${error}`);
      }
      await this.cancelRecording();
      return false;
    }
  }
  async cancelRecording(): Promise<boolean> {
    if (!this.isRecording) {
      console.warn('[AudioRecorderManager] Not recording, cannot cancel');
      return false;
    }

    try {
      if (this.recordingTimer) {
        clearInterval(this.recordingTimer);
        this.recordingTimer = null;
      }
      await this.cleanupRecorder();
      if (this.recordingFilePath) {
        try {
          if (fs.accessSync(this.recordingFilePath)) {
            fs.unlinkSync(this.recordingFilePath);
          }
        } catch (error) {
          console.warn(`[AudioRecorderManager] Failed to delete temporary file: ${error}`);
        }
      }
      this.isRecording = false;
      this.recordingDuration = 0;
      this.recordingFilePath = '';

      if (this.onRecordingCancel) {
        this.onRecordingCancel();
      }

      return true;
    } catch (error) {
      if (this.onError) {
        this.onError(`Failed to cancel recording: ${error}`);
      }
      return false;
    }
  }

  checkRecordingFileExists(filePath: string): boolean {
    try {
      return fs.accessSync(filePath);
    } catch (error) {
      console.warn(`[AudioRecorderManager] Failed to check file existence: ${error}`);
      return false;
    }
  }

  getRecordingFileSize(filePath: string): number {
    try {
      const stat = fs.statSync(filePath);
      return stat.size;
    } catch (error) {
      console.warn(`[AudioRecorderManager] Failed to get file size: ${error}`);
      return 0;
    }
  }

  async destroy() {
    if (this.isRecording) {
      await this.cancelRecording();
    }
    await this.cleanupRecorder();
  }

  private async checkAndRequestMicrophonePermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const tokenId = bundleInfo.appInfo.accessTokenId;
      const permission: Permissions = 'ohos.permission.MICROPHONE';
      const grantStatus = await atManager.checkAccessToken(tokenId, permission);

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {

        return true;
      }

      const requestResult = await atManager.requestPermissionsFromUser(this.context!, [permission]);

      if (requestResult.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {

        return true;
      } else {
        console.warn('[AudioRecorderManager] Microphone permission request denied');
        if (this.onPermissionDenied) {
          this.onPermissionDenied();
        }
        return false;
      }
    } catch (error) {

      if (this.onError) {
        this.onError(`Permission check failed: ${error}`);
      }
      return false;
    }
  }


  private async createAndSetFd(): Promise<void> {
    try {
      this.recordingFilePath = this.generateRecordingFilePath();
      await this.ensureDirectoryExists(this.recordingFilePath);
      this.audioFile = fs.openSync(this.recordingFilePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      this.avConfig.url = 'fd://' + this.audioFile.fd;
    } catch (error) {
    }
  }

  private setAudioRecorderCallback() {
    if (this.avRecorder != undefined) {
      this.avRecorder.on('stateChange', (state: media.AVRecorderState, reason: media.StateChangeReason) => {
      });
      this.avRecorder.on('error', (err: BusinessError) => {
        if (this.onError) {
          this.onError(`Recorder error: ${err.message}`);
        }
        this.cancelRecording();
      });
    }
  }
  private generateRecordingFilePath(): string {
    const timestamp = Date.now();
    const fileName = `voice_record_${timestamp}.m4a`;

    const appContext = getContext().getApplicationContext();
    const voiceDir = `${appContext.cacheDir}/atomicx_core_data/voice`;
    return `${voiceDir}/${fileName}`;
  }


  private async ensureDirectoryExists(filePath: string): Promise<void> {
    try {
      const dir = filePath.substring(0, filePath.lastIndexOf('/'));
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
    } catch (error) {
      console.warn(`[AudioRecorderManager] Failed to create directory: ${error}`);
      const parentDir = filePath.substring(0, filePath.lastIndexOf('/'));
      const grandParentDir = parentDir.substring(0, parentDir.lastIndexOf('/'));
      if (fs.accessSync(grandParentDir)) {
      }
    }
  }


  private async waitForRecorderState(targetState: media.AVRecorderState, timeout: number = 5000): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.avRecorder) {
        reject(new Error('Recorder instance not found'));
        return;
      }
      if (this.avRecorder.state === targetState) {
        resolve();
        return;
      }

      const timer = setTimeout(() => {
        reject(new Error(`Timeout waiting for recorder state: ${targetState}`));
      }, timeout);

      const stateChangeHandler = (state: media.AVRecorderState) => {
        if (state === targetState) {
          clearTimeout(timer);
          if (this.avRecorder) {
            this.avRecorder.off('stateChange', stateChangeHandler);
          }
          resolve();
        }
      };

      this.avRecorder.on('stateChange', stateChangeHandler);
    });
  }

  private async cleanupRecorder(): Promise<void> {
    try {
      if (this.avRecorder != undefined) {
        try {
          const currentState = this.avRecorder.state;
          if (currentState === 'started' || currentState === 'paused') {
            await this.avRecorder.stop();
            await this.waitForRecorderState('stopped');
          }
          if (currentState === 'stopped' || currentState === 'prepared') {
            await this.avRecorder.reset();
            await this.waitForRecorderState('idle');
          }
          await this.avRecorder.release();
        } catch (error) {
          console.warn(`[AudioRecorderManager] Error during recorder cleanup: ${error}`);

          try {
            await this.avRecorder.release();
          } catch (releaseError) {
            console.warn(`[AudioRecorderManager] Force release recorder failed: ${releaseError}`);
          }
        }
        this.avRecorder = undefined;
      }
      if (this.audioFile) {
        try {
          fs.closeSync(this.audioFile);
        } catch (error) {
          console.warn(`[AudioRecorderManager] Error closing file: ${error}`);
        }
        this.audioFile = null;
      }
    } catch (error) {
      console.warn(`[AudioRecorderManager] Error during resource cleanup: ${error}`);
    }
  }
}

export class AudioRecorder {
  private static _instance: AudioRecorder | null = null;
  private impl: AudioRecorderImpl;

  private constructor() {
    this.impl = new AudioRecorderImpl();
  }

  static getInstance(): AudioRecorder {
    if (AudioRecorder._instance === null) {
      AudioRecorder._instance = new AudioRecorder();
    }
    return AudioRecorder._instance;
  }

  get currentPower(): number {
    // TODO: Implement current power level
    return 0;
  }

  get currentTime(): number {
    return this.impl.getCurrentTime();
  }

  startRecord(filepath: string | null = null, enableAIDeNoise: boolean = false, listener: AudioRecorderListener): void {
    this.impl.addListener(listener);
    this.impl.startRecording();
  }

  stopRecord(): void {
    this.impl.stopRecording();
  }

  cancelRecord(): void {
    this.impl.cancelRecording();
  }

  setContext(context: common.UIAbilityContext): void {
    this.impl.setContext(context);
  }
}
