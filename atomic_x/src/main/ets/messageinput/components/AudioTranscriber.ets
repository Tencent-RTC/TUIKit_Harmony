import { V2TIMManager } from '@tencentcloud/imsdk';

export type AudioTranscriberCompleted = (text?: string) => void;
export type AudioTranscriberFailure = (code: number, desc: string) => void;

type ExperimentalAPIResult = string | Object | undefined;

interface ExperimentalAPIError {
  code?: number;
  message?: string;
}

export class AudioTranscriber {
  private static readonly API_UPLOAD_FILE: string = 'uploadFile';
  private static readonly API_CONVERT_VOICE_TO_TEXT: string = 'convertVoiceToText';
  private static readonly KEY_FILE_PATH: string = 'filePath';
  private static readonly KEY_FILE_TYPE: string = 'fileType';
  private static readonly KEY_URL: string = 'url';
  private static readonly KEY_LANGUAGE: string = 'language';
  private static readonly ERROR_UNKNOWN: number = -1;
  private static readonly FILE_TYPE_AUDIO: number = 3;

  convert(filePath: string, language: string = '', onFailure?: AudioTranscriberFailure,
    onCompleted?: AudioTranscriberCompleted): void {
    this.uploadFile(filePath, (url: string) => {
      if (url.length === 0) {
        this.completeFailure(onFailure, onCompleted, AudioTranscriber.ERROR_UNKNOWN, 'upload url is empty');
        return;
      }
      this.convertVoiceToText(url, language, (text?: string) => {
        onCompleted?.(text);
      }, (code: number, desc: string) => {
        this.completeFailure(onFailure, onCompleted, code, desc);
      });
    }, (code: number, desc: string) => {
      this.completeFailure(onFailure, onCompleted, code, desc);
    });
  }

  private uploadFile(filePath: string, onSuccess: (url: string) => void, onFailure: AudioTranscriberFailure): void {
    this.callExperimentalApi(AudioTranscriber.API_UPLOAD_FILE, AudioTranscriber.buildUploadFileParams(filePath),
      onSuccess, onFailure);
  }

  private convertVoiceToText(url: string, language: string, onSuccess: (text?: string) => void,
    onFailure: AudioTranscriberFailure): void {
    this.callExperimentalApi(AudioTranscriber.API_CONVERT_VOICE_TO_TEXT,
      AudioTranscriber.buildConvertVoiceToTextParams(url, language), onSuccess, onFailure);
  }

  private callExperimentalApi(api: string, params: string, onSuccess: (result: string) => void,
    onFailure: AudioTranscriberFailure): void {
    try {
      const promise = V2TIMManager.getInstance().callExperimentalAPI(api, params);
      if (!promise) {
        onFailure(AudioTranscriber.ERROR_UNKNOWN, '');
        return;
      }
      promise
        .then((result: ExperimentalAPIResult) => {
          onSuccess(result?.toString() ?? '');
        })
        .catch((error: ExperimentalAPIError) => {
          onFailure(error.code ?? AudioTranscriber.ERROR_UNKNOWN, error.message ?? '');
        });
    } catch (exception) {
      const error = exception as Error;
      onFailure(AudioTranscriber.ERROR_UNKNOWN, error.message ?? '');
    }
  }

  private completeFailure(onFailure: AudioTranscriberFailure | undefined,
    onCompleted: AudioTranscriberCompleted | undefined, code: number, desc: string): void {
    onFailure?.(code, desc);
    onCompleted?.(undefined);
  }

  private static buildUploadFileParams(filePath: string): string {
    const params: Record<string, Object> = {};
    params[AudioTranscriber.KEY_FILE_PATH] = filePath;
    params[AudioTranscriber.KEY_FILE_TYPE] = AudioTranscriber.FILE_TYPE_AUDIO;
    return JSON.stringify(params);
  }

  private static buildConvertVoiceToTextParams(url: string, language: string): string {
    const params: Record<string, Object> = {};
    params[AudioTranscriber.KEY_URL] = url;
    params[AudioTranscriber.KEY_LANGUAGE] = language;
    return JSON.stringify(params);
  }
}
