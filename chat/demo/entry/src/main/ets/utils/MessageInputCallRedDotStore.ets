import { MMKV } from '@tencent/mmkv';
import DemoConstants from './DemoConstants';

/**
 * Remembers whether the user already tapped a call entry in the message input's
 * more panel, keyed per SDKAppID so switching accounts brings the dot back.
 */
export class MessageInputCallRedDotStore {
  static shouldShow(sdkAppID: number, actionID: string): boolean {
    if (sdkAppID <= 0) {
      return false;
    }
    return !MMKV.defaultMMKV().decodeBool(MessageInputCallRedDotStore.storageKey(sdkAppID, actionID), false);
  }

  // The subset of actionIDs that still deserves a dot.
  static pendingActionIDs(sdkAppID: number, actionIDs: string[]): string[] {
    return actionIDs.filter((actionID: string): boolean => MessageInputCallRedDotStore.shouldShow(sdkAppID, actionID));
  }

  static markClicked(sdkAppID: number, actionID: string): void {
    if (sdkAppID <= 0) {
      return;
    }
    MMKV.defaultMMKV().encodeBool(MessageInputCallRedDotStore.storageKey(sdkAppID, actionID), true);
  }

  private static storageKey(sdkAppID: number, actionID: string): string {
    return `${DemoConstants.MESSAGE_INPUT_CALL_RED_DOT_CLICKED_PREFIX}${sdkAppID}${actionID}`;
  }
}
