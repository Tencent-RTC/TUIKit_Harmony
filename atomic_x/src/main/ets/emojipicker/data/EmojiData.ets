import { EmojiPicker } from '../../../../../Index';
import { EmojiLocalizationUtils } from '../utils/EmojiLocalizationUtils';
import { loadEmojisFromResource } from '../utils/EmojiResourceLoader';
export interface EmojiItem {
  id: string;
  name: string;
  imageFile: string;
  category: string;
}
export interface EmojiCategory {
  id: string;
  name: string;
  icon: string;
}

export interface EmojiTextSegment {
  type: 'text' | 'emoji';
  content: string;
  imageFile?: string;
}
export class EmojiDataManager {
  static readonly categories: EmojiCategory[] = [
    { id: 'recent', name: 'emoji_category_recent', icon: '' },
    { id: 'all', name: 'emoji_category_all', icon: '' },
  ];
  // Lazy load emojis from resource file
  private static _emojis: EmojiItem[] | null = null;
  
  static get emojis(): EmojiItem[] {
    if (EmojiDataManager._emojis === null) {
      EmojiDataManager._emojis = loadEmojisFromResource();
    }
    return EmojiDataManager._emojis;
  }
  private static fileNameToEmojiNameMap: Map<string, string> | null = null;

  static getEmojiNameByFileName(fileName: string): string | undefined {

    EmojiDataManager.initFileNameMapping();
    return EmojiDataManager.fileNameToEmojiNameMap!.get(fileName);
  }

  static getEmojiNameByResourceString(resourceStr: string): string | undefined {
    let extractedFileName = '';

    if (resourceStr.startsWith('resource://RAWFILE/')) {
      // rawfile : resource://RAWFILE/emojipicker/emoji_34.png
      const filePath = resourceStr.replace('resource://RAWFILE/', '');
      const parts = filePath.split('/');
      extractedFileName = parts[parts.length - 1].replace('.png', ''); // get emoji_34
    } else if (resourceStr.startsWith('resource:///')) {
      // old style : resource:///emoji_34.png
      const fileName = resourceStr.replace('resource:///', '');
      extractedFileName = fileName.replace('.png', '');
    } else {
      try {
        const resourceObj: Record<string, Object> = JSON.parse(resourceStr) as Record<string, Object>;
        if (resourceObj.params && Array.isArray(resourceObj.params) && resourceObj.params.length > 0) {
          const paramStr: string = resourceObj.params[0] as string;
          if (paramStr.startsWith('app.media.')) {
            extractedFileName = paramStr.replace('app.media.', '');
          } else if (paramStr.includes('/')) {
            const parts = paramStr.split('/');
            extractedFileName = parts[parts.length - 1].replace('.png', '');
          } else {
            extractedFileName = paramStr.replace('.png', '');
          }
        }
      } catch (e) {
        console.warn(`[EmojiDataManager] errorStr: ${resourceStr}`);
        return undefined;
      }
    }

    if (extractedFileName) {
      return EmojiDataManager.getEmojiNameByFileName(extractedFileName);
    }

    return undefined;
  }

  static getMappingSize(): number {
    EmojiDataManager.initFileNameMapping();
    return EmojiDataManager.fileNameToEmojiNameMap!.size;
  }

  static getAllEmojis(): EmojiItem[] {
    return EmojiDataManager.emojis;
  }

  static getEmojisByCategory(category: string): EmojiItem[] {
    if (category === 'all') {
      return EmojiDataManager.emojis;
    }
    return EmojiDataManager.emojis.filter(emoji => emoji.category === category);
  }

  static getEmojiById(id: string): EmojiItem | undefined {
    return EmojiDataManager.emojis.find(emoji => emoji.id === id);
  }

  static getEmojiByName(name: string): EmojiItem | undefined {
    return EmojiDataManager.emojis.find(emoji => emoji.name === name);
  }

  static getCategories(): EmojiCategory[] {
    return EmojiDataManager.categories;
  }

  static getDefaultRecentEmojis(): EmojiItem[] {
    return EmojiDataManager.emojis.slice(0, 8);
  }

  static getEmojiImageResource(imageFile: string): Resource {
    return $rawfile(`emojipicker/${imageFile}.png`);
  }

  static getEmojiDisplayName(emoji: EmojiItem): Resource {
    return $r(`app.string.${emoji.name}`);
  }

  static getCategoryDisplayName(categoryId: string): Resource {
    const category = EmojiDataManager.categories.find(cat => cat.id === categoryId);
    if (category) {
      return $r(`app.string.${category.name}`);
    }
    return $r('app.string.emoji_category_all');
  }

  static getEmojiTypeDisplayName(type: 'normal' | 'large'): Resource {
    return $r(`app.string.emoji_type_${type}`);
  }

  static getEmojiDisplayNameString(emoji: EmojiItem, context?: Context): string {
    return EmojiLocalizationUtils.getEmojiDisplayName(emoji.name, context);
  }

  static getCategoryDisplayNameString(categoryId: string, context?: Context): string {
    const category = EmojiDataManager.categories.find(cat => cat.id === categoryId);
    if (category) {
      return EmojiLocalizationUtils.getCategoryDisplayName(category.name, context);
    }
    return EmojiLocalizationUtils.getCategoryDisplayName('emoji_category_all', context);
  }

  static getEmojiTypeDisplayNameString(type: 'normal' | 'large', context?: Context): string {
    return EmojiLocalizationUtils.getCategoryDisplayName(`emoji_type_${type}`, context);
  }

  static parseEmojiText(text: string): EmojiTextSegment[] {
    const segments: EmojiTextSegment[] = [];
    const emojiRegex = /\[[a-zA-Z0-9_@\u4e00-\u9fa5]+\]/g;

    let lastIndex = 0;
    let match: RegExpExecArray | null = null;

    while ((match = emojiRegex.exec(text)) !== null) {
      if (match.index > lastIndex) {
        const textContent = text.substring(lastIndex, match.index);
        if (textContent.length > 0) {
          segments.push({
            type: 'text',
            content: textContent
          });
        }
      }

      const emojiName: string = match[0];
      const allEmojis: EmojiItem[] = EmojiDataManager.getAllEmojis();
      const emoji: EmojiItem | undefined = allEmojis.find((item: EmojiItem) => item.name === emojiName);

      if (emoji) {
        segments.push({
          type: 'emoji',
          content: emojiName,
          imageFile: emoji.imageFile
        });
      } else {
        segments.push({
          type: 'text',
          content: emojiName
        });
      }

      lastIndex = emojiRegex.lastIndex;
    }

    if (lastIndex < text.length) {
      const remainingText = text.substring(lastIndex);
      if (remainingText.length > 0) {
        segments.push({
          type: 'text',
          content: remainingText
        });
      }
    }

    return segments;
  }

  private static initFileNameMapping(): void {
    if (EmojiDataManager.fileNameToEmojiNameMap === null) {
      EmojiDataManager.fileNameToEmojiNameMap = new Map<string, string>();
      EmojiDataManager.emojis.forEach(emoji => {

        const fileName = emoji.imageFile.replace('.png', '');
        EmojiDataManager.fileNameToEmojiNameMap!.set(fileName, emoji.name);
      });

      
    }
  }
} 