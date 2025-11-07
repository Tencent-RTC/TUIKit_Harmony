import { EmojiItem } from '../data/EmojiData';
import { util } from '@kit.ArkTS';
import { getAppContext } from '../../basecomponent/utils/ContextProvider';

/**
 * Emoji resource file data structure
 */
interface EmojiResourceItem {
  face_name: string;
  face_file: string;
  face_id: string;
}

/**
 * Simple function to load emojis from resource file
 */
export function loadEmojisFromResource(): EmojiItem[] {
  try {
    let context = getAppContext();

    if (context == null) {
       context = getContext();
    }
    const resourceMgr = context.resourceManager;
    
    // Read the JSON file from rawfile synchronously
    const rawData = resourceMgr.getRawFileContentSync('emojipicker/emoji.json');
    const textDecoder = util.TextDecoder.create('utf-8');
    const jsonString = textDecoder.decodeWithStream(new Uint8Array(rawData.buffer));
    const resourceItems: EmojiResourceItem[] = JSON.parse(jsonString);

    // Convert resource items to EmojiItem format with default category
    const emojis: EmojiItem[] = resourceItems.map((item: EmojiResourceItem): EmojiItem => {
      return {
        id: item.face_id,
        name: item.face_name,
        imageFile: item.face_file,
        category: 'people' // Use default category
      };
    });

    console.log(`[EmojiResourceLoader] Successfully loaded ${emojis.length} emojis from resource file`);
    return emojis;
  } catch (error) {
    console.error('[EmojiResourceLoader] Error loading emoji resource file:', error);
    // Return empty array as fallback
    return [];
  }
}
