import { MMKV } from '@tencent/mmkv';
import { EventBus } from '../../basecomponent/utils/EventBus';

const STORAGE_KEY_PREFIX: string = 'chat_background::';
const EVENT_PREFIX: string = 'chatBackgroundChanged::';

export class ChatBackgroundStore {
  static getImageUri(conversationID: string): string | null {
    if (!conversationID) {
      return null;
    }
    try {
      const imageUri = MMKV.defaultMMKV().decodeString(`${STORAGE_KEY_PREFIX}${conversationID}`);
      return imageUri && imageUri.trim().length > 0 ? imageUri : null;
    } catch (_) {
      return null;
    }
  }

  static setImageUri(conversationID: string, imageUri: string | null): void {
    if (!conversationID) {
      return;
    }
    const normalizedUri = imageUri?.trim() || '';
    try {
      const mmkv = MMKV.defaultMMKV();
      if (normalizedUri) {
        mmkv.encodeString(`${STORAGE_KEY_PREFIX}${conversationID}`, normalizedUri);
      } else {
        mmkv.removeValueForKey(`${STORAGE_KEY_PREFIX}${conversationID}`);
      }
      EventBus.getInstance().post(ChatBackgroundStore.eventName(conversationID), {});
    } catch (_) {
    }
  }

  static eventName(conversationID: string): string {
    return `${EVENT_PREFIX}${conversationID}`;
  }
}
