/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   BarrageStore @ AtomicXCore
 * Function: Barrage related interfaces, managing barrage sending, barrage state synchronization, and barrage event listening in live rooms/voice chat rooms.

 */
import { LiveUserInfo } from '../live/LiveAudienceStore';
import BasicDataSource from '../common/BasicDataSource';
import BasicData from '../common/BasicData';
/**
 * Barrage type enumeration, used to distinguish different barrage message types.
 */
export declare enum BarrageType {
    /**
     * Text type barrage, contains plain text content.
     */
    TEXT = 0,
    /**
     * Custom type barrage, supports business custom data format (such as barrages with special effects, interactive messages, etc.).
     */
    CUSTOM = 1
}
/**
 * Barrage data model, containing complete attribute information of a single barrage.
 *
 * Contains complete information about the barrage sender, content, type, etc.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [liveID] | `String` | Unique identifier ID of the live room/voice chat room the barrage belongs to |
 * | [sender] | `LiveUserInfo` | User information of the barrage sender |
 * | [sequence] | `int` | Unique sequence ID of the barrage message |
 * | [timestampInSecond] | `int` | Barrage sending timestamp (unit: seconds) |
 * | [messageType] | `BarrageType` | Barrage message type (text or custom) |
 * | [textContent] | `String` | Message content of text type barrage |
 * | [extensionInfo] | `Map<String, String>` | Barrage extension information |
 * | [businessID] | `String` | Business identifier ID of custom type barrage |
 * | [data] | `String` | Specific data content of custom type barrage |
 */
export declare class Barrage extends BasicData {
    /**
     * Unique identifier ID of the live room/voice chat room the barrage belongs to.
     */
    liveID: string;
    /**
     * User information of the barrage sender (such as user ID, nickname, avatar, etc.).
     */
    sender: LiveUserInfo;
    /**
     * Unique sequence ID of the barrage message, used for message sorting and deduplication.
     */
    sequence: number;
    /**
     * Barrage sending timestamp (unit: seconds), used to display sending time order.
     */
    timestampInSecond: number;
    /**
     * Barrage message type (text or custom).
     */
    messageType: BarrageType;
    /**
     * Message content of text type barrage, i.e., the text content of the barrage.
     */
    textContent: string;
    /**
     * Barrage extension information, customizable fields (such as display style, priority, etc.). Valid when messageType is TEXT.
     */
    extensionInfo: Map<string, string>;
    /**
     * Business identifier ID of custom type barrage, used to distinguish custom barrages from different business scenarios.
     */
    businessID: string;
    /**
     * Specific data content of custom type barrage (usually JSON format string), valid when messageType is CUSTOM.
     */
    data: string;
}
/**
 * Barrage state, managing the barrage data state of the current room.
 *
 * Contains the barrage message list of the current room, supports real-time updates.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [messageList] | `ValueListenable<List<Barrage>>` | Barrage message list of the current room |
 * | [isMessageDisable] | `ValueListenable<bool>` | Whether messages are disabled for all users in the current room |
 *
 * > **Tip**: Subscribe to [barrageState] to receive real-time updates of barrage data in the room.
 */
@Observed
export declare class BarrageState {
    /**
     * Barrage message list of the current room, supports real-time updates and can be subscribed to.
     */
    messageList: BarrageDataSource;
    /**
     * Whether messages are disabled for all users in the current room, supports real-time updates and can be subscribed to.
     */
    isMessageDisable: boolean;
}
/**
 * Barrage event listener.
 *
 *
 *
 * | Callback | Type | Description |
 * |--------|------|-----------|
 * | [onCustomMessageReceived] | `void Function(Barrage)?` | Callback triggered when a custom barrage message is received |
 */
export declare class BarrageListener {
    /**
     * Callback triggered when a custom barrage message is received.
     */
    onCustomMessageReceived?: (barrage: Barrage) => void;
}
/**
 * Barrage related interfaces, managing barrage sending, barrage state synchronization, and barrage event listening in live rooms/voice chat rooms.
 *
 * `BarrageStore` Barrage management class for handling barrage related business logic in live rooms/voice chat rooms.
 * `BarrageStore` provides a complete set of barrage management APIs, including sending text barrages, sending custom barrages, and adding local tip messages.
 * Through this class, you can implement barrage interaction functionality in live rooms.
 *
 * ### Key Features
 *
 * - **Text Barrage**: Supports sending plain text barrage messages.
 * - **Custom Barrage**: Supports sending custom format barrages (such as barrages with special effects).
 * - **Local Tips**: Supports adding tip messages visible only locally.
 *
 * > **Important**: Use the [create] factory method to create a `BarrageStore` instance, which requires a valid live room ID.
 *
 * > **Tip**: Barrage state updates are delivered through the [barrageState] publisher. Subscribe to it to receive real-time updates of barrage data in the room.
 *
 * ### Creating Instance
 *
 * ### Observing State
 *
 * ### Events Handling
 *
 * ### Sending Barrage
 *
 * ### Message Management
 *
 * ### Local Messages
 *
 */
export declare abstract class BarrageStore {
    protected state: BarrageState;
    get barrageState(): BarrageState;
    static create(liveID: string): BarrageStore;
    /**
     * Send a text type barrage. After sending successfully, the receiver can obtain barrage messages by subscribing to messageList in BarrageState in advance.
     *
     * @param text Text barrage content.
     * @param extensionInfo Extension information, can contain custom fields (such as specifying barrage color, font size, etc.).
     */
    abstract sendTextMessage(text: string, extensionInfo: Map<string, string>): Promise<void>;
    /**
     * Send a custom type barrage message. After sending successfully, the receiver can receive custom messages by subscribing to the CustomMessageEventPublisher provided by BarrageStore.
     *
     * @param businessID Business identifier ID, used to distinguish custom barrages from different business scenarios.
     * @param data Custom data content, usually JSON format string, used to pass business custom data.
     */
    abstract sendCustomMessage(businessID: string, data: string): Promise<void>;
    /**
     * Enable or disable messages for all users in the room. After setting successfully, the latest state can be observed by subscribing to isMessageDisable in BarrageState.
     *
     * @param disable `true` to disable messages for all users, `false` to allow them.
     */
    abstract setMessageDisable(disable: boolean): Promise<void>;
    /**
     * Add local tip message (add tip or operation feedback message locally, visible only to the current client).
     *
     * @param message Local barrage message (such as system tips, operation feedback, etc., visible only to the current user).
     */
    abstract appendLocalTip(message: Barrage): void;
    /**
     * Add barrage event listener.
     *
     * @param listener Barrage event listener instance.
     */
    abstract addBarrageListener(listener: BarrageListener): void;
    /**
     * Remove barrage event listener.
     *
     * @param listener Barrage event listener instance to be removed.
     */
    abstract removeBarrageListener(listener: BarrageListener): void;
}
export declare class BarrageDataSource extends BasicDataSource<Barrage> {
}
