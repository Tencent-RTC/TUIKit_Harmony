// Vendor configuration: https://cloud.tencent.com/document/product/269/108856
// Quick integration: https://cloud.tencent.com/document/product/269/108892

import common from "@ohos.app.ability.common";
import { TIMPushListener, TIMPushManager, TIMPushMessage, TIMPushResult } from '@tencentcloud/timpush';
import { Log } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { PushConfig } from '../signature/PushConfig';

let pushListener: TIMPushListener = {
  onMessageReceived: (data) => {
    const message = data as TIMPushMessage;
    Log.i("TIMPush","onReceiveMessage:" + message.toString());
  },
  onNotificationClicked: (data) => {
    const dataStr = data as string;
    Log.i("TIMPush","onNotificationClicked: " + dataStr);
    handleNotificationClick(dataStr);
  },
  onRevokePushMessage: (data) => {
    Log.i("TIMPush","onRevokePushMessage"+ data);
  }
}

export class TIMPushInterfaces {
  static registerPush(context: common.Context) {
    TIMPushManager.getInstance()
      .registerPush(context, PushConfig.sdkAppId, PushConfig.appKey, PushConfig.businessID)
      .then((result) => {
        Log.i("TIMPush","registerPush success：" + result.message);
      })
      .catch((error: TIMPushResult) => {
        Log.i("TIMPush","registerPush failed" + error.code + error.message);
      })
  }

  static unRegisterPush() {
    TIMPushManager.getInstance()
      .unRegisterPush()
      .then((result) => {
        Log.i("TIMPush","unRegisterPush success："+ result.message);
      })
      .catch((error: TIMPushResult) => {
        Log.i("TIMPush","unRegisterPush failed" + error.code + error.message);
      })
  }

  static getRegistrationID() {
    TIMPushManager.getInstance()
      .getRegistrationID()
      .then((result) => {
        Log.i("TIMPush","getRegistrationID success："+ result.message);
      })
      .catch((error: TIMPushResult) => {
        Log.i("TIMPush","getRegistrationID failed" + error.code + error.message);
      })
  }

  static setRegistrationID(registrationID: string) {
    TIMPushManager.getInstance()
      .setRegistrationID(registrationID)
      .then((result) => {
        Log.i("TIMPush","setRegistrationID success：" + result.message);
      })
      .catch((error: TIMPushResult) => {
        Log.i("TIMPush","setRegistrationID failed" + error.code + error.message);
      })
  }

  static addPushListener() {
    TIMPushManager.getInstance().addPushListener(pushListener);
  }

  static removePushListener() {
    TIMPushManager.getInstance().removePushListener(pushListener);
  }

  static disablePostNotificationInForeground() {
    TIMPushManager.getInstance().disablePostNotificationInForeground(true);
  }

  static callExperimentalAPI() {
    TIMPushManager.getInstance()
      .callExperimentalAPI("setPushConfig", JSON.stringify({ "runningPlatform": 1 }))
      .then((result) => {
        Log.i("TIMPush","callExperimentalAPI success：" + result.message);
      })
      .catch((error: TIMPushResult) => {
        Log.i("TIMPush","callExperimentalAPI failed" + error.code + error.message);
      });
  }
}

/**
 * Push notification entity data structure
 * Corresponds to the "entity" field in the notification ext
 */
export interface PushNotificationEntity {
  action: number;
  content: string;
  sender: string;
  nickname: string;
  faceUrl: string;
  chatType: number; // 1 = C2C (one-to-one chat), 2 = GROUP (group chat)
  version: number;
}

/**
 * Parsed push notification full data structure
 */
export interface ParsedPushNotification {
  entity: PushNotificationEntity;
}

/**
 * Notification click callback function type
 * @param conversationID Conversation ID (format: c2c_{userID} or group_{groupID})
 * @param title Conversation title (sender nickname)
 * @param avatarUrl Avatar URL
 */
export type NotificationClickCallback = (conversationID: string, title: string, avatarUrl: string) => void;

/**
 * Cached push navigation info (stored when callback is not yet registered during cold start)
 */
interface PendingNavigation {
  conversationID: string;
  title: string;
  avatarUrl: string;
}

/**
 * Notification click callback function
 */
let notificationClickCallback: NotificationClickCallback | null = null;

/**
 * Cached pending navigation (cold start scenario)
 */
let pendingNavigation: PendingNavigation | null = null;

/**
 * Fingerprint of the last handled notification data, used for deduplication to prevent duplicate SDK callbacks
 */
let lastHandledNotificationKey: string = '';

/**
 * Set the notification click callback for navigating to the chat page.
 * If there is cached cold-start navigation info, it will be consumed immediately.
 * @param callback Callback function
 */
export function setNotificationClickCallback(callback: NotificationClickCallback): void {
  notificationClickCallback = callback;

  // Consume cached cold-start navigation info
  if (pendingNavigation) {
    const nav = pendingNavigation;
    pendingNavigation = null; // Clear before invoking callback to avoid re-entry
    Log.i("TIMPush", `Consuming pending navigation: ${nav.conversationID}`);
    callback(nav.conversationID, nav.title, nav.avatarUrl);
  }
}

/**
 * Clear the notification click callback and cached navigation info.
 * Called on logout / HomePage destruction to avoid stale data causing duplicate navigation.
 */
export function clearNotificationClickCallback(): void {
  Log.i("TIMPush", "Clearing notification click callback and pending navigation");
  notificationClickCallback = null;
  pendingNavigation = null;
  lastHandledNotificationKey = '';
}

/**
 * Parse the notification click JSON string data
 * @param jsonStr Push notification JSON string
 * @returns Parsed PushNotificationEntity or null
 */
function parseNotificationEntity(jsonStr: string): PushNotificationEntity | null {
  try {
    if (!jsonStr) {
      Log.w("TIMPush", "Notification data is empty");
      return null;
    }

    const parsed = JSON.parse(jsonStr) as ParsedPushNotification;
    if (!parsed || !parsed.entity) {
      Log.w("TIMPush", "Invalid notification data structure");
      return null;
    }

    const entity = parsed.entity;
    Log.i("TIMPush", `Parsed notification: chatType=${entity.chatType}, sender=${entity.sender}, nickname=${entity.nickname}`);

    return entity;
  } catch (error) {
    Log.e("TIMPush", `Failed to parse notification: ${error}`);
    return null;
  }
}

/**
 * Build conversation ID
 * @param chatType Chat type (1=C2C, 2=GROUP)
 * @param sender Sender ID
 * @returns Formatted conversation ID
 */
function buildConversationID(chatType: number, sender: string): string {
  // chatType: 1 = C2C (one-to-one chat), 2 = GROUP (group chat)
  const prefix = chatType === 1 ? 'c2c_' : 'group_';
  return `${prefix}${sender}`;
}

/**
 * Handle notification click event and trigger navigation.
 * If the callback is registered, navigates immediately; otherwise caches the navigation info for HomePage to consume.
 * Each notification is processed only once (deduplicated via notificationKey).
 */
function handleNotificationClick(data: string): void {
  // Deduplication: do not process the same notification data twice
  const notificationKey = data;
  if (notificationKey === lastHandledNotificationKey) {
    Log.i("TIMPush", "Duplicate notification click ignored");
    return;
  }
  lastHandledNotificationKey = notificationKey;

  const entity = parseNotificationEntity(data);
  if (!entity) {
    Log.w("TIMPush", "Cannot handle notification click: failed to parse entity");
    return;
  }

  const conversationID = buildConversationID(entity.chatType, entity.sender);
  const title = entity.nickname || entity.sender;
  const avatarUrl = entity.faceUrl || '';

  Log.i("TIMPush", `Navigating to chat: conversationID=${conversationID}, title=${title}`);

  if (notificationClickCallback) {
    notificationClickCallback(conversationID, title, avatarUrl);
  } else {
    // Cold start: callback not yet registered, cache navigation info
    Log.i("TIMPush", "Callback not registered yet, caching pending navigation");
    pendingNavigation = { conversationID, title, avatarUrl };
  }
}
