import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';

export enum AudioOutputDevice {
  SPEAKER = 'SPEAKER',
  EARPIECE = 'EARPIECE'
}

export interface AudioPlayerListener {
  onPlay?(): void;
  onPause?(): void;
  onResume?(): void;
  onProgressUpdate?(currentPosition: number, duration: number): void;
  onCompletion?(): void;
  onError?(errorMessage: string): void;
  onAudioOutputChanged?(device: AudioOutputDevice): void;
}

export abstract class AudioPlayer {
  static create(): AudioPlayer {
    return new MediaAudioPlayer();
  }

  abstract play(filePath: string): Promise<void>;
  abstract pause(): Promise<void>;
  abstract resume(): Promise<void>;
  abstract stop(): Promise<void>;
  abstract setAudioOutputDevice(device: AudioOutputDevice): AudioPlayer;
  abstract setListener(listener: AudioPlayerListener | null): AudioPlayer;
  abstract getCurrentPosition(): number;
  abstract getDuration(): number;
  abstract isPlaying(): boolean;
  abstract isPaused(): boolean;
}

class MediaAudioPlayer extends AudioPlayer {
  private avPlayer: media.AVPlayer | null = null;
  private _isPlaying: boolean = false;
  private _isPaused: boolean = false;
  private currentDuration: number = 0;
  private currentPosition: number = 0;
  private listener: AudioPlayerListener | null = null;
  private audioOutputDevice: AudioOutputDevice = AudioOutputDevice.SPEAKER;

  setListener(listener: AudioPlayerListener | null): AudioPlayer {
    this.listener = listener;
    return this;
  }

  setAudioOutputDevice(device: AudioOutputDevice): AudioPlayer {
    this.audioOutputDevice = device;
    // TODO: Implement audio output device switching
    if (this.listener?.onAudioOutputChanged) {
      this.listener.onAudioOutputChanged(device);
    }
    return this;
  }

  async play(filePath: string): Promise<void> {
    try {
      if (this.avPlayer) {
        await this.stop();
      }

      this.avPlayer = await media.createAVPlayer();
      this.setupAVPlayerCallbacks();

      const fdPath = await this.getFileDescriptor(filePath);
      this.avPlayer.url = fdPath;

    } catch (error) {
      if (this.listener?.onError) {
        this.listener.onError(`play error: ${error}`);
      }
    }
  }

  async pause(): Promise<void> {
    if (this.avPlayer && this._isPlaying) {
      try {
        await this.avPlayer.pause();
      } catch (error) {
        if (this.listener?.onError) {
          this.listener.onError(`pause error: ${error}`);
        }
      }
    }
  }

  async resume(): Promise<void> {
    if (this.avPlayer && this._isPaused) {
      try {
        await this.avPlayer.play();
      } catch (error) {
        if (this.listener?.onError) {
          this.listener.onError(`resume error: ${error}`);
        }
      }
    }
  }

  async stop(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.stop();
        await this.avPlayer.release();
        this.avPlayer = null;
        this._isPlaying = false;
        this._isPaused = false;
        this.currentPosition = 0;
      } catch (error) {
        if (this.listener?.onError) {
          this.listener.onError(`stop error: ${error}`);
        }
      }
    }
  }

  isPlaying(): boolean {
    return this._isPlaying;
  }

  isPaused(): boolean {
    return this._isPaused;
  }

  getCurrentPosition(): number {
    return this.currentPosition;
  }

  getDuration(): number {
    return this.currentDuration;
  }

  
  private setupAVPlayerCallbacks(): void {
    if (!this.avPlayer) {
      return;
    }

    this.avPlayer.on('error', (err: BusinessError) => {
      if (this.listener?.onError) {
        this.listener.onError(`playError: ${err.message}`);
      }
      this.avPlayer?.reset();
    });

    this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'idle':
          break;
        case 'initialized':
          if (this.avPlayer) {
            this.avPlayer.audioRendererInfo = {
              usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
              rendererFlags: 0
            };
            await this.avPlayer.prepare();
          }
          break;
        case 'prepared':
          if (this.avPlayer) {
            this.currentDuration = this.avPlayer.duration;
            await this.avPlayer.play();
          }
          break;
        case 'playing':
          const wasPlaying = this._isPlaying;
          const wasPaused = this._isPaused;
          
          this._isPlaying = true;
          this._isPaused = false;
          
          if (wasPaused && this.listener?.onResume) {
            this.listener.onResume();
          } else if (!wasPlaying && this.listener?.onPlay) {
            this.listener.onPlay();
          }
          
          this.startProgressTracking();
          break;
        case 'paused':
          this._isPlaying = false;
          this._isPaused = true;
          if (this.listener?.onPause) {
            this.listener.onPause();
          }
          break;
        case 'completed':
          this._isPlaying = false;
          this._isPaused = false;
          this.currentPosition = 0;
          if (this.listener?.onCompletion) {
            this.listener.onCompletion();
          }
          await this.avPlayer?.stop();
          break;
        case 'stopped':
          this._isPlaying = false;
          this._isPaused = false;
          break;
        case 'released':
          this.avPlayer = null;
          break;
        default:
          break;
      }
    });
  }

  
  private async getFileDescriptor(filePath: string): Promise<string> {
    try {
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      return `fd://${file.fd}`;
    } catch (error) {
      throw new Error(`can not open File : ${filePath}`);
    }
  }

  private startProgressTracking(): void {
    const updateProgress = () => {
      if (this.avPlayer && this._isPlaying) {
        this.currentPosition = this.avPlayer.currentTime;

        if (this.listener?.onProgressUpdate) {
          this.listener.onProgressUpdate(this.currentPosition, this.currentDuration);
        }

        setTimeout(updateProgress, 100);
      }
    };

    updateProgress();
  }
} 