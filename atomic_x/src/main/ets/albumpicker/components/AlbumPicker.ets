import { BusinessError } from '@kit.BasicServicesKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';

export enum PickMode {
  IMAGE = 'IMAGE',
  VIDEO = 'VIDEO',
  ALL = 'ALL'
}

export interface AlbumPickerConfig {
  pickMode?: PickMode;
  maxCount?: number;
  gridCount?: number;
  primaryColor?: string;
}

export interface AlbumPickerResult {
  filePath: string;
  fileName: string;
  fileSize: number;
  extension: string;
  type: PickMode.IMAGE | PickMode.VIDEO;
}

export class AlbumPicker {

  static async pickMedia(config: AlbumPickerConfig = {}): Promise<AlbumPickerResult[]> {
    const pickMode = config.pickMode || PickMode.ALL;
    const maxCount = config.maxCount || 1;
    const gridCount = config.gridCount || 4;
    const primaryColor = config.primaryColor || '#007AFF';

    try {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      
      switch (pickMode) {
        case PickMode.IMAGE:
          PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
          break;
        case PickMode.VIDEO:
          PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
          break;
        case PickMode.ALL:
        default:
          PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE;
          break;
      }
      
      PhotoSelectOptions.maxSelectNumber = maxCount;
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      
      const PhotoSelectResult = await photoPicker.select(PhotoSelectOptions);
      
      if (PhotoSelectResult && PhotoSelectResult.photoUris && PhotoSelectResult.photoUris.length > 0) {
        const results: AlbumPickerResult[] = [];
        
        for (const mediaPath of PhotoSelectResult.photoUris) {
          try {
            const fileName = AlbumPicker.getFileNameFromPath(mediaPath);
            const extension = AlbumPicker.getFileExtension(fileName);
            
            let mediaType: PickMode.IMAGE | PickMode.VIDEO;
            if (AlbumPicker.isImageExtension(extension)) {
              mediaType = PickMode.IMAGE;
            } else if (AlbumPicker.isVideoExtension(extension)) {
              mediaType = PickMode.VIDEO;
            } else {
              console.warn(`[AlbumPicker] Unknown media file type: ${extension}`);
              if (extension.includes('mp4') || extension.includes('avi') || extension.includes('mov')) {
                mediaType = PickMode.VIDEO;
              } else {
                mediaType = PickMode.IMAGE; 
              }
            }
            
            let fileSize = 0;
            try {
              const stat = await fs.stat(mediaPath);
              fileSize = stat.size;
            } catch (statError) {
              console.warn(`[AlbumPicker] Failed to get file size for ${mediaPath}:`, statError);
            }
            
            const result: AlbumPickerResult = {
              filePath: mediaPath,
              fileName: fileName,
              fileSize: fileSize,
              extension: extension,
              type: mediaType
            };
            results.push(result);
          } catch (error) {
            console.error(`[AlbumPicker] Failed to process file ${mediaPath}:`, error);
            continue;
          }
        }
        
        return results;
      } else {
        return [];
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[AlbumPicker] pickMedia failed with err: ${err.code}, ${err.message}`);
      return [];
    }
  }

  private static isImageExtension(extension?: string): boolean {
    if (!extension) return false;
    const imageExtensions = ['jpg', 'png', 'gif', 'jpeg', 'bmp', 'webp', 'tiff', 'svg'];
    return imageExtensions.includes(extension);
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
