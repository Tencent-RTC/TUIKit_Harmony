/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LikeStore @ AtomicXCore
 * Function: Like related interfaces, managing like sending, like state synchronization, and like event listening operations in live rooms/voice chat rooms.
 */
import { LiveUserInfo } from './LiveAudienceStore';
/**
 * Like state, used to display and subscribe to like information in live rooms/voice chat rooms.
 *
 * Contains the total accumulated like count of the current live room/voice chat room, supporting real-time updates.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [totalLikeCount] | `ValueListenable<int>` | Total accumulated like count of the current room |
 *
 * > **Tip**: Like count updates automatically. Subscribe to [likeState] to receive real-time updates.
 */
@Observed
export declare class LikeState {
    /**
     * Total accumulated like count of the current live room/voice chat room, supporting real-time updates and subscription listening.
     */
    totalLikeCount: number;
}
export declare class LikeListener {
    onReceiveLikesMessage?: (liveID: string, totalLikesReceived: number, sender: LiveUserInfo) => void;
}
/**
 * Like related interfaces, managing like sending, like state synchronization, and like event listening operations in live rooms/voice chat rooms.
 *
 * `LikeStore` Like management class for handling like-related business logic in live rooms/voice chat rooms.
 * `LikeStore` provides a complete set of like management APIs, including sending likes, listening to like events, and getting like states. Through this class, you can implement like interaction features in live rooms.
 *
 * ### Key Features
 *
 * - **Like Sending**: Support sending likes to the current room.
 * - **Like State**: Get the accumulated like count of the current room.
 * - **Event Listening**: Listen to like receiving events.
 *
 * > **Important**: Use the [create] factory method to create a `LikeStore` instance, which requires a valid live room ID.
 *
 * > **Tip**: Like state updates are delivered through the [likeState] publisher. Subscribe to it to receive real-time updates of like data in the room.
 *
 */
export declare abstract class LikeStore {
    protected state: LikeState;
    get likeState(): LikeState;
    static create(liveID: string): LikeStore;
    /**
     * Send likes to the current room. All users who have subscribed to like events will receive this like notification.
     *
     * @param count Like count, default is 1.
     */
    abstract sendLike(count: number): Promise<void>;
    /**
     * Add like event listener
     *
     * @param listener Listener.
     */
    abstract addLikeListener(listener: LikeListener): void;
    /**
     * Remove like event listener
     *
     * @param listener Listener.
     */
    abstract removeLikeListener(listener: LikeListener): void;
}
