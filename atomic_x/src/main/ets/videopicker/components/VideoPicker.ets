import { BusinessError } from '@kit.BasicServicesKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';

export interface VideoPickerConfig {
  maxCount?: number;
  gridCount?: number;
  primaryColor?: string;
}

export interface VideoPickerResult {
  filePath: string;
  fileName: string;
  fileSize: number;
  extension: string;
  type: 'video';
}

export class VideoPicker {

  static async pickVideos(config: VideoPickerConfig = {}): Promise<VideoPickerResult> {
    const maxCount = config.maxCount || 1;
    const gridCount = config.gridCount || 4;
    const primaryColor = config.primaryColor || '#007AFF';

    try {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      PhotoSelectOptions.maxSelectNumber = maxCount;
      let photoPicker = new photoAccessHelper.PhotoViewPicker();

      const PhotoSelectResult = await photoPicker.select(PhotoSelectOptions);

      if (PhotoSelectResult && PhotoSelectResult.photoUris && PhotoSelectResult.photoUris.length > 0) {
        const videoPath = PhotoSelectResult.photoUris[0];

        try {
          const stat = await fs.stat(videoPath);
          const fileName = VideoPicker.getFileNameFromPath(videoPath);
          const extension = VideoPicker.getFileExtension(fileName);
          
          const result: VideoPickerResult = {
            filePath: videoPath,
            fileName: fileName,
            fileSize: stat.size,
            extension: extension,
            type: 'video'
          };
          return result;
        } catch (error) {
          console.error(`[VideoPicker] Failed to get file info:`, error);
          const fileName = VideoPicker.getFileNameFromPath(videoPath);
          const extension = VideoPicker.getFileExtension(fileName);
          
          const result: VideoPickerResult = {
            filePath: videoPath,
            fileName: fileName,
            fileSize: 0,
            extension: extension,
            type: 'video'
          };
          return result;
        }
      } else {
        const result: VideoPickerResult = {
          filePath: '',
          fileName: '',
          fileSize: 0,
          extension: '',
          type: 'video'
        };
        return result;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[VideoPicker] pickVideos failed with err: ${err.code}, ${err.message}`);
      const result: VideoPickerResult = {
        filePath: '',
        fileName: '',
        fileSize: 0,
        extension: '',
        type: 'video'
      };
      return result;
    }
  }

  private static isVideoExtension(extension?: string): boolean {
    if (!extension) return false;
    const videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', '3gp', 'webm'];
    return videoExtensions.includes(extension);
  }

  private static getFileNameFromPath(filePath: string): string {
    const lastSlashIndex = filePath.lastIndexOf('/');
    return lastSlashIndex >= 0 ? filePath.substring(lastSlashIndex + 1) : filePath;
  }

  private static getFileExtension(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
      return fileName.substring(lastDotIndex + 1).toLowerCase();
    }
    return '';
  }
}