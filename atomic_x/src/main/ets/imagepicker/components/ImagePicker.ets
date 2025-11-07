import { BusinessError } from '@kit.BasicServicesKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';

export interface ImagePickerConfig {
  maxCount?: number;
  gridCount?: number;
  primaryColor?: string;
}

export interface ImagePickerResult {
  filePath: string;
  fileName: string;
  fileSize: number;
  extension: string;
  type: 'image';
}

export class ImagePicker {

  static async pickImages(config: ImagePickerConfig = {}): Promise<ImagePickerResult> {
    const maxCount = config.maxCount || 1;
    const gridCount = config.gridCount || 4;
    const primaryColor = config.primaryColor || '#007AFF';

    try {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      PhotoSelectOptions.maxSelectNumber = maxCount;
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      
      const PhotoSelectResult = await photoPicker.select(PhotoSelectOptions);
      
      if (PhotoSelectResult && PhotoSelectResult.photoUris && PhotoSelectResult.photoUris.length > 0) {
        const imagePath = PhotoSelectResult.photoUris[0];
        
        try {
          const stat = await fs.stat(imagePath);
          const fileName = ImagePicker.getFileNameFromPath(imagePath);
          const extension = ImagePicker.getFileExtension(fileName);
          
          const result: ImagePickerResult = {
            filePath: imagePath,
            fileName: fileName,
            fileSize: stat.size,
            extension: extension,
            type: 'image'
          };
          return result;
        } catch (error) {
          console.error(`[ImagePicker] Failed to get file info:`, error);
          const fileName = ImagePicker.getFileNameFromPath(imagePath);
          const extension = ImagePicker.getFileExtension(fileName);
          
          const result: ImagePickerResult = {
            filePath: imagePath,
            fileName: fileName,
            fileSize: 0,
            extension: extension,
            type: 'image'
          };
          return result;
        }
      } else {
        const result: ImagePickerResult = {
          filePath: '',
          fileName: '',
          fileSize: 0,
          extension: '',
          type: 'image'
        };
        return result;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[ImagePicker] pickImages failed with err: ${err.code}, ${err.message}`);
      const result: ImagePickerResult = {
        filePath: '',
        fileName: '',
        fileSize: 0,
        extension: '',
        type: 'image'
      };
      return result;
    }
  }

  private static isImageExtension(extension?: string): boolean {
    if (!extension) return false;
    const imageExtensions = ['jpg', 'png', 'gif', 'jpeg', 'bmp', 'webp', 'tiff', 'svg'];
    return imageExtensions.includes(extension);
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