import { emitter } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { media } from '@kit.MediaKit'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'
import { TUICallRole, TUICallStatus } from '@tencentcloud/rtcroomengine'
import { AudioMusicParam, getTRTCShareInstance, TXAudioEffectManager, TXMusicPlayObserver } from '@tencentcloud/liteavsdk_professional'
import Logger from '../../common/Logger'
import GlobalState from '../../state/GlobalState'
import { CallManager } from '../CallManager'
import { Preference } from '../../common/Preference'
import { CallEvent } from '../../common/Constants'

const TAG = "CallBellFeature"

export class CallBellFeature {
  static readonly PROFILE_TUICALLKIT: string = "per_profile_tuicallkit"
  static readonly PROFILE_CALL_BELL: string = "per_call_bell"
  static readonly PROFILE_MUTE_MODE: string = "per_mute_mode"
  private AUDIO_ID: number = 1008
  private avPlayer: media.AVPlayer | null = null;
  private calleeRawId: string = 'phone_ringing.mp3'
  private callerRawId: string = 'phone_dialing.mp3'
  private calleeBellFile: string = ''

  constructor() {
    emitter.on({ eventId: CallEvent.CALL_STATUS }, (eventData: emitter.EventData) => {
      let selfUser = CallManager.getInstance().userState.selfUser
      Logger.info(TAG, `eventData: ${JSON.stringify(eventData)}, selfUser: ${selfUser}`)
      if (selfUser.callStatus != TUICallStatus.Waiting) {
        this.stop()
        return
      }
      this.start()
    });
  }

  start() {
    if (CallManager.getInstance().userState.selfUser.callRole == TUICallRole.Call) {
      this.startDialingMusic()
    } else {
      this.startRinging()
    }
  }

  stop() {
    this.stopDialingMusic()
    this.stopRinging()
  }

  private musicObserver: TXMusicPlayObserver = {
    onStart: (id, errcode) => {
      Logger.info(TAG, `Music ${id} started playing. Error code: ${errcode}`);
    },
    onComplete: (id, errcode) => {
      Logger.info(TAG, `Music ${id} complete playing. Error code: ${errcode}`);
    }
  };

  private startDialingMusic() {
    Logger.info(TAG, `startDialingMusic`)
    let audioEffectManager: TXAudioEffectManager = getTRTCShareInstance().getAudioEffectManager()
    audioEffectManager.setMusicObserver(this.AUDIO_ID, this.musicObserver)
    audioEffectManager.setMusicPlayoutVolume(this.AUDIO_ID, 100)

    let params: AudioMusicParam = new AudioMusicParam()
    params.id = this.AUDIO_ID
    params.path = this.getLocalRawResource(this.callerRawId)
    params.isShortFile = true
    audioEffectManager.startPlayMusic(params)
  }

  private stopDialingMusic() {
    getTRTCShareInstance().getAudioEffectManager().stopPlayMusic(this.AUDIO_ID)
  }

  private async startRinging() {
    Logger.info(TAG, `startRinging`)
    if (GlobalState.enableMuteMode == true) {
      return
    }
    if (this.avPlayer === null) {
      await this.initAVPlayer()
    }
    Logger.info(TAG, `startRinging current state: ${this.avPlayer?.state}`)
    if (this.avPlayer?.state == 'playing') {
      this.avPlayer.stop()
    }
    await this.applyCalleeBellResource()
  }

  private stopRinging() {
    if (this.avPlayer === null) {
      return;
    }
    this.avPlayer.stop()
  }

  private async initAVPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      Logger.log(TAG, `initAVPlayer: `, this.avPlayer);
      this.avPlayer.loop = true
      this.avPlayer.audioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_VOICE_COMMUNICATION,
        rendererFlags: 0
      };
      await this.setAVPlayerCallback();
      this.applyCalleeBellResource()
    } catch (error) {
      Logger.error(TAG, `initAVPlayer failed, error: `, error);
    }
  }

  private async applyCalleeBellResource(): Promise<void> {
    if (this.avPlayer == null) {
      return
    }

    this.calleeBellFile =
      Preference.getInstance(CallBellFeature.PROFILE_TUICALLKIT).getString(CallBellFeature.PROFILE_CALL_BELL, "")

    if (this.calleeBellFile != null && this.calleeBellFile.trim().length > 0) {
      Logger.info(TAG, `calleeBellFile: ${this.calleeBellFile}`)
      let regex: RegExp = new RegExp('^(http|https)', 'i');
      if (regex.test(this.calleeBellFile)) {
        this.avPlayer.url = this.calleeBellFile
        return
      }
      let rawFile = this.getLocalRawResource(this.calleeBellFile)
      let fileId = await this.getLocalBellFile(rawFile)
      Logger.log(TAG, `getFileId, fileId: `, fileId);
      this.avPlayer.dataSrc = fileId
      return
    }

    let mgr = (getContext() as (common.UIAbilityContext)).resourceManager;
    let rawId = mgr.getRawFdSync(this.calleeRawId)
    Logger.log(TAG, `getRawId: rawId: `, rawId);
    this.avPlayer.fdSrc = rawId
  }

  private async setAVPlayerCallback(): Promise<void> {
    if (this.avPlayer === null) {
      return;
    }

    this.avPlayer.on('error', (err) => {
      if (this.avPlayer != null) {
        Logger.error(TAG, `setAVPlayerCallback Invoke avPlayer failed, error: ${err.code}, errorMsg: ${err.message}`);
        this.avPlayer.reset();
      }
    });
    this.avPlayer.on('stateChange', async (state, reason) => {
      if (this.avPlayer === null) {
        return;
      }
      switch (state) {
        case 'idle':
          this.avPlayer.release();
          this.initAVPlayer();
          break;
        case 'initialized':
          this.avPlayer.prepare();
          break;
        case 'prepared':
          this.avPlayer.play();
          break;
        default:
          break;
      }
    });
  }

  private async getLocalBellFile(filePath: string): Promise<media.AVDataSrcDescriptor> {
    let fd: number = 0;
    let fileSize: number = -1;

    let src: media.AVDataSrcDescriptor = {
      fileSize: -1, callback: (buf: ArrayBuffer, length: number, pos: number | undefined) => {
        let num = 0;
        if (buf == undefined || length == undefined || pos == undefined) {
          return -1;
        }
        num = fileIo.readSync(fd, buf, { offset: pos, length: length });
        if (num > 0 && (fileSize >= pos)) {
          return num;
        }
        return -1;
      }
    };
    Logger.info(TAG, `getLocalBellFile, filePath: ` + filePath);
    await fileIo.open(filePath).then((file: fileIo.File) => {
      fd = file.fd;
    });
    fileSize = fileIo.statSync(filePath).size;
    src.fileSize = fileSize;
    Logger.info(TAG, `getLocalBellFile, src: ${src.fileSize} , `, src);
    return src
  }

  private getLocalRawResource(fileName: string): string {
    let context = (getContext() as (common.UIAbilityContext))

    let filePath = context!.filesDir + '/' + fileName;
    // path: /data/storage/el2/base/haps/entry/files
    let content = context.resourceManager.getRawFileContentSync(fileName)
    let file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    let writeLen = fileIo.writeSync(file.fd, content.buffer);
    filePath = file.path
    Logger.info(TAG, `getLocalRawResource, filePath: ` + filePath);
    fileIo.closeSync(file);
    return filePath
  }
}