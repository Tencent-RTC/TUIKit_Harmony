import { camera, cameraPicker } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common as commonKit } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';

/**
 * Video recording configuration
 */
export interface TakeVideoConfig {
  maxVideoDuration?: number;
  minVideoDuration?: number;
  videoQuality?: VideoQuality;
  recordMode?: RecordMode;
  primaryColor?: string;
  defaultFrontCamera?: boolean;
}

/**
 * Photo capture configuration
 */
export interface TakePhotoConfig {
  primaryColor?: string;
  defaultFrontCamera?: boolean;
}

/**
 * Recording modes
 */
export enum RecordMode {
  MIXED = 0,
  PHOTO_ONLY = 1,
  VIDEO_ONLY = 2
}

/**
 * Video quality levels
 */
export enum VideoQuality {
  LOW = 1,
  MEDIUM = 2,
  HIGH = 3
}

/**
 * Video recorder error codes
 */
export enum VideoRecorderErrorCode {
  PERMISSION_DENIED = -1,
  RECORD_CANCEL = -2,
  RECORD_INNER_ERROR = -3
}

/**
 * Recording result listener interface
 */
export interface RecordListener {
  onPhotoCaptured?: (filePath: string) => void;
  onVideoCaptured?: (filePath: string, duration: number) => void;
  onError?: (errorCode: VideoRecorderErrorCode) => void;
}

/**
 * Video recorder singleton class
 */
export class VideoRecorder {
  private static instance: VideoRecorder | null = null;

  private constructor() {}

  static getInstance(): VideoRecorder {
    if (VideoRecorder.instance === null) {
      VideoRecorder.instance = new VideoRecorder();
    }
    return VideoRecorder.instance;
  }

  /**
   * Launch camera for video recording (supports both video and photo based on config)
   */
  async takeVideo(
    config: TakeVideoConfig = {},
    listener: RecordListener,
    context?: common.UIAbilityContext
  ): Promise<void> {
    try {
      const actualContext = context || getContext() as common.UIAbilityContext;
      
      // Determine camera position based on config
      const cameraPosition = config.defaultFrontCamera 
        ? camera.CameraPosition.CAMERA_POSITION_FRONT 
        : camera.CameraPosition.CAMERA_POSITION_BACK;

      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: cameraPosition
      };

      // Determine media types based on record mode
      let mediaTypes: cameraPicker.PickerMediaType[] = [];
      switch (config.recordMode) {
        case RecordMode.PHOTO_ONLY:
          mediaTypes = [cameraPicker.PickerMediaType.PHOTO];
          break;
        case RecordMode.VIDEO_ONLY:
          mediaTypes = [cameraPicker.PickerMediaType.VIDEO];
          break;
        case RecordMode.MIXED:
        default:
          mediaTypes = [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO];
          break;
      }

      let pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(
        actualContext as commonKit.Context,
        mediaTypes,
        pickerProfile
      );

      // Handle result
      if (pickerResult && pickerResult.resultUri && pickerResult.resultUri.length > 0) {
        const resultPath = pickerResult.resultUri;
        
        // Determine if it's a photo or video based on the media type or file extension
        if (this.isPhotoResult(resultPath, mediaTypes)) {
          if (listener.onPhotoCaptured) {
            listener.onPhotoCaptured(resultPath);
          }
        } else {
          if (listener.onVideoCaptured) {
            const duration = 0;
            listener.onVideoCaptured(resultPath, duration);
          }
        }
      } else {
        // User cancelled
        if (listener.onError) {
          listener.onError(VideoRecorderErrorCode.RECORD_CANCEL);
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('[VideoRecorder] takeVideo error:', err);
      if (listener.onError) {
        listener.onError(VideoRecorderErrorCode.RECORD_INNER_ERROR);
      }
    }
  }

  /**
   * Launch camera for photo capture only
   */
  async takePhoto(
    config: TakePhotoConfig = {},
    listener: RecordListener,
    context?: common.UIAbilityContext
  ): Promise<void> {
    const takeVideoConfig: TakeVideoConfig = {
      recordMode: RecordMode.PHOTO_ONLY,
      primaryColor: config.primaryColor,
      defaultFrontCamera: config.defaultFrontCamera
    };
    
    await this.takeVideo(takeVideoConfig, listener, context);
  }

  /**
   * Helper method to determine if result is a photo
   */
  private isPhotoResult(filePath: string, mediaTypes: cameraPicker.PickerMediaType[]): boolean {
    // If only photo type was requested, it's definitely a photo
    if (mediaTypes.length === 1 && mediaTypes[0] === cameraPicker.PickerMediaType.PHOTO) {
      return true;
    }
    
    // If only video type was requested, it's definitely a video
    if (mediaTypes.length === 1 && mediaTypes[0] === cameraPicker.PickerMediaType.VIDEO) {
      return false;
    }
    
    // For mixed mode, check file extension
    const extension = filePath.toLowerCase().split('.').pop() || '';
    const photoExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return photoExtensions.includes(extension);
  }

} 