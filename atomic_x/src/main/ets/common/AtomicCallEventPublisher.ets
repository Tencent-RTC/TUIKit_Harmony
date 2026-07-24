import { PublishParams, TUIEventBus } from '../basecomponent/Index';
import { CallMediaType } from '../call/common/CallStore';
import { DataReport, InteractionMetrics } from '@tencentcloud/atomicxcore';

/**
 * Unified publisher for Chat -> Call events, aligned with Android
 * `chat/uikit/components/common/AtomicCallEventPublisher.kt`.
 *
 * The payload shape intentionally keeps the same Harmony ChatPage protocol
 * used before this logic was moved down into atomic_x:
 *   - participantIds: string[]
 *   - mediaType: 'audio' | 'video'
 *   - chatGroupId: string (empty for C2C)
 *   - timeout: number
 */
export class AtomicCallEventPublisher {
  static readonly MEDIA_TYPE_AUDIO: CallMediaType = CallMediaType.audio;
  static readonly MEDIA_TYPE_VIDEO: CallMediaType = CallMediaType.video;

  private static readonly EVENT_START_CALL: string = 'call.startCall';
  private static readonly EVENT_START_JOIN: string = 'call.startJoin';
  private static readonly KEY_PARTICIPANT_IDS: string = 'participantIds';
  private static readonly KEY_MEDIA_TYPE: string = 'mediaType';
  private static readonly KEY_CHAT_GROUP_ID: string = 'chatGroupId';
  private static readonly KEY_TIMEOUT: string = 'timeout';
  private static readonly KEY_CALL_ID: string = 'callId';
  private static readonly DEFAULT_TIMEOUT_SECONDS: number = 30;

  private static isCallKitIntegrated(): boolean {
    return TUIEventBus.getInstance().hasSubscribers(AtomicCallEventPublisher.EVENT_START_CALL);
  }

  /**
   * Publish a "chat -> start call" event.
   *
   * @param participantIds callee user IDs; empty list is a no-op
   * @param mediaType      one of `MEDIA_TYPE_AUDIO` / `MEDIA_TYPE_VIDEO`
   *                       (`'audio'` / `'video'`, matching the original
   *                       Harmony ChatPage event protocol)
   * @param chatGroupId    optional group ID for a group call
   */
  static publishStartCall(participantIds: string[], mediaType: CallMediaType, chatGroupId?: string): void {
    if (!participantIds || participantIds.length === 0) {
      return;
    }
    // NOTE: `chatGroupId` MUST always be present in the payload (even as an
    // empty string for C2C calls). Harmony TUICallKit reads the value with
    // `data['chatGroupId'] as string` and treats a missing key as a broken
    // event, which then cascades into remote-view `StartRemoteView` losing
    // its `userId` param and failing with `user_id param invalid`.
    // This matches the original (working) shape emitted by ChatPage before
    // the Chat->Call publisher was refactored.
    const data: Record<string, Object> = {};
    data[AtomicCallEventPublisher.KEY_PARTICIPANT_IDS] = participantIds as Object;
    data[AtomicCallEventPublisher.KEY_MEDIA_TYPE] = mediaType as Object;
    data[AtomicCallEventPublisher.KEY_CHAT_GROUP_ID] =
      ((chatGroupId !== undefined) ? chatGroupId : '') as Object;
    data[AtomicCallEventPublisher.KEY_TIMEOUT] = AtomicCallEventPublisher.DEFAULT_TIMEOUT_SECONDS as Object;

    // Skip reporting when the host app has not integrated CallKit.
    if (AtomicCallEventPublisher.isCallKitIntegrated()) {
      DataReport.reportInteractionMetrics(InteractionMetrics.CHAT_INVOKE_CALL);
    }

    const params = new PublishParams(false, data);
    TUIEventBus.getInstance().publish(AtomicCallEventPublisher.EVENT_START_CALL, null, params);
  }

  /**
   * Publish a "chat -> join existing call" event (for the join-call banner).
   */
  static publishStartJoin(callId: string): void {
    if (!callId || callId.length === 0) {
      return;
    }
    const data: Record<string, Object> = {};
    data[AtomicCallEventPublisher.KEY_CALL_ID] = callId as Object;
    const params = new PublishParams(false, data);
    TUIEventBus.getInstance().publish(AtomicCallEventPublisher.EVENT_START_JOIN, null, params);
  }
}
