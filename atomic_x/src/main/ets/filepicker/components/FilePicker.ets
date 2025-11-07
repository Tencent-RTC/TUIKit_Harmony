import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';

export interface PickerResult {
  filePath: string;
  fileName: string;
  fileSize: number;
  extension: string;
}

export enum FileType {
  ANY = 'ANY',
  MEDIA = 'MEDIA',
  IMAGE = 'IMAGE',
  VIDEO = 'VIDEO',
  AUDIO = 'AUDIO'
}

export interface FilePickerConfig {
  maxCount?: number;
  fileType?: FileType;
}

export class FilePicker {
  private static readonly MAX_FILE_COUNT = 9;

  static async pickFiles(config: FilePickerConfig = {}): Promise<PickerResult[]> {
    const maxCount = config.maxCount || FilePicker.MAX_FILE_COUNT;
    const fileType = config.fileType || FileType.ANY;

    try {
      let selectResult: string[] = [];

      selectResult = await FilePicker.selectDocuments(maxCount);

      if (selectResult.length === 0) {
        return [];
      }

      if (selectResult.length > maxCount) {
        console.warn(`[FilePicker] Selected ${selectResult.length} files, but maxCount is ${maxCount}`);
        selectResult = selectResult.slice(0, maxCount);
      }

      const results: PickerResult[] = [];

      for (const filePath of selectResult) {
        try {
          const stat = await fs.stat(filePath);
          const fileName = FilePicker.getFileNameFromPath(filePath);
          const extension = FilePicker.getFileExtension(fileName);

          results.push({
            filePath: filePath,
            fileName: fileName,
            fileSize: stat.size,
            extension: extension
          });
        } catch (error) {
          console.error(`[FilePicker] Failed to get file info for ${filePath}:`, error);
          const fileName = FilePicker.getFileNameFromPath(filePath);
          const extension = FilePicker.getFileExtension(fileName);
          results.push({
            filePath: filePath,
            fileName: fileName,
            fileSize: 0,
            extension: extension
          });
        }
      }

      return results;
    } catch (error) {
      console.error('[FilePicker] pickFiles failed:', error);
      return [];
    }
  }

  private static async selectDocuments(maxCount: number): Promise<string[]> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const documentSelectOptions: picker.DocumentSelectOptions = {
        maxSelectNumber: maxCount,
      };
      const result = await documentPicker.select(documentSelectOptions);
      return result || [];
    } catch (error) {
      console.error('[FilePicker] selectDocuments failed:', error);
      return [];
    }
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
