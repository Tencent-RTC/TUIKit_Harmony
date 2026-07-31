import { BusinessError } from '@kit.BasicServicesKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';
import common from '@ohos.app.ability.common';
import { fileUri } from '@kit.CoreFileKit';

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
  sourceUri: string;
}

export class AlbumPicker {

  static async pickMedia(config: AlbumPickerConfig = {}): Promise<AlbumPickerResult[]> {
    const pickMode = config.pickMode || PickMode.ALL;
    const maxCount = config.maxCount || 1;

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
        const context = getContext() as common.UIAbilityContext;
        const cacheRoot = context.cacheDir + '/album_picker/';
        try {
          await fs.mkdir(cacheRoot, true);
        } catch (_) {
          // ignore already exists
        }

        const results: AlbumPickerResult[] = [];

        for (const mediaUri of PhotoSelectResult.photoUris) {
          try {
            const fileName = AlbumPicker.getFileNameFromPath(mediaUri);
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

            // 通过 MediaAssetManager 请求原图/原视频（强制走云端下载）
            const localPath = await AlbumPicker.fetchOriginalMediaToLocal(
              context, mediaUri, mediaType, cacheRoot, extension
            );

            if (!localPath) {
              console.error(`[AlbumPicker] Fetch original media failed: ${mediaUri}`);
              continue;
            }

            let fileSize = 0;
            try {
              const stat = await fs.stat(localPath);
              fileSize = stat.size;
            } catch (statError) {
              console.warn(`[AlbumPicker] Failed to get file size for ${localPath}:`, statError);
            }

            if (fileSize <= 0) {
              console.error(`[AlbumPicker] Original media is empty, drop: ${localPath}`);
              try { await fs.unlink(localPath); } catch (_) { /* ignore */ }
              continue;
            }

            const result: AlbumPickerResult = {
              filePath: localPath,
              fileName: AlbumPicker.getFileNameFromPath(localPath),
              fileSize: fileSize,
              extension: extension,
              type: mediaType,
              sourceUri: mediaUri
            };
            results.push(result);
          } catch (error) {
            console.error(`[AlbumPicker] Failed to process file ${mediaUri}:`, error);
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

  /**
   * 通过 MediaAssetManager 请求原图/原视频并落盘到 sandbox。
   * - 对于云图库（iCloud/华为云空间）中的资源，系统会自动触发下载。
   * - 使用 HIGH_QUALITY_MODE 强制拿到原图/原视频，避免拿到缩略图或空占位文件。
   */
  private static async fetchOriginalMediaToLocal(
    context: common.UIAbilityContext,
    sourceUri: string,
    mediaType: PickMode.IMAGE | PickMode.VIDEO,
    cacheRoot: string,
    extension: string
  ): Promise<string | undefined> {
    // 查询 PhotoAsset
    let asset: photoAccessHelper.PhotoAsset | undefined;
    try {
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', sourceUri);
      const fetchResult = await photoAccessHelper.getPhotoAccessHelper(context).getAssets({
        fetchColumns: [],
        predicates: predicates,
      });
      asset = await fetchResult.getFirstObject();
    } catch (e) {
      console.error('[AlbumPicker] getAssets failed:', JSON.stringify(e));
      return undefined;
    }
    if (!asset) {
      console.error('[AlbumPicker] Asset not found for uri:', sourceUri);
      return undefined;
    }

    const timestamp = Date.now();
    const safeExt = extension && extension.length > 0
      ? extension
      : (mediaType === PickMode.VIDEO ? 'mp4' : 'jpg');
    const destPath = `${cacheRoot}${mediaType === PickMode.VIDEO ? 'video' : 'img'}_${timestamp}.${safeExt}`;

    if (mediaType === PickMode.IMAGE) {
      return AlbumPicker.requestImageOriginal(context, asset, destPath);
    } else {
      return AlbumPicker.requestVideoOriginal(context, asset, destPath);
    }
  }

  private static requestImageOriginal(
    context: common.UIAbilityContext,
    asset: photoAccessHelper.PhotoAsset,
    destPath: string
  ): Promise<string | undefined> {
    return new Promise<string | undefined>((resolve) => {
      const requestOptions: photoAccessHelper.RequestOptions = {
        deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE,
      };
      const handler: photoAccessHelper.MediaAssetDataHandler<ArrayBuffer> = {
        onDataPrepared: async (data: ArrayBuffer) => {
          if (!data || data.byteLength === 0) {
            console.error('[AlbumPicker] requestImageData returned empty buffer');
            resolve(undefined);
            return;
          }
          try {
            const file = await fs.open(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
            await fs.write(file.fd, data);
            await fs.close(file);
            resolve(destPath);
          } catch (e) {
            console.error('[AlbumPicker] write image failed:', JSON.stringify(e));
            try { await fs.unlink(destPath); } catch (_) { /* ignore */ }
            resolve(undefined);
          }
        },
      };
      photoAccessHelper.MediaAssetManager
        .requestImageData(context, asset, requestOptions, handler)
        .catch((err: BusinessError) => {
          console.error(`[AlbumPicker] requestImageData failed: ${err.code}, ${err.message}`);
          resolve(undefined);
        });
    });
  }

  private static async requestVideoOriginal(
    context: common.UIAbilityContext,
    asset: photoAccessHelper.PhotoAsset,
    destPath: string
  ): Promise<string | undefined> {
    let destFileOpened: fs.File | undefined;
    try {
      destFileOpened = await fs.open(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    } catch (e) {
      console.error('[AlbumPicker] open dest video file failed:', JSON.stringify(e));
      return undefined;
    }
    try { await fs.close(destFileOpened); } catch (_) { /* ignore */ }

    const destUri = fileUri.getUriFromPath(destPath);

    return new Promise<string | undefined>((resolve) => {
      const requestOptions: photoAccessHelper.RequestOptions = {
        deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE,
      };
      const handler: photoAccessHelper.MediaAssetDataHandler<boolean> = {
        onDataPrepared: async (data: boolean) => {
          if (!data) {
            console.error('[AlbumPicker] requestVideoFile returned false');
            try { await fs.unlink(destPath); } catch (_) { /* ignore */ }
            resolve(undefined);
            return;
          }
          resolve(destPath);
        },
      };
      photoAccessHelper.MediaAssetManager
        .requestVideoFile(context, asset, requestOptions, destUri, handler)
        .catch(async (err: BusinessError) => {
          console.error(`[AlbumPicker] requestVideoFile failed: ${err.code}, ${err.message}`);
          try { await fs.unlink(destPath); } catch (_) { /* ignore */ }
          resolve(undefined);
        });
    });
  }

  private static isImageExtension(extension?: string): boolean {
    if (!extension) return false;
    const imageExtensions = ['jpg', 'png', 'gif', 'jpeg', 'bmp', 'webp', 'tiff', 'svg', 'heic', 'heif'];
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
