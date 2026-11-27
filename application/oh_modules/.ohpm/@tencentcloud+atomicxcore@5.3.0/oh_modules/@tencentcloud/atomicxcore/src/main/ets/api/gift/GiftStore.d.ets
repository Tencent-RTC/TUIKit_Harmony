/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   GiftStore @ AtomicXCore
 * Function: Gift-related interface, managing gift sending, gift state synchronization, and gift event listening in live rooms/voice chat rooms.

 */
import { LiveUserInfo } from '../live/LiveAudienceStore';
import BasicDataSource from '../common/BasicDataSource';
import BasicData from '../common/BasicData';
/**
 * Gift data model, containing complete attribute information of a single gift.
 *
 * Contains complete information about the gift including ID, name, description, icon, animation resource, etc.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [giftID] | `String` | Gift ID |
 * | [name] | `String` | Gift name |
 * | [desc] | `String` | Gift description |
 * | [iconURL] | `String` | Network URL of the gift icon image |
 * | [resourceURL] | `String` | Network URL of the gift animation resource file |
 * | [level] | `int` | Gift level |
 * | [coins] | `int` | Gift price (coins) |
 * | [extensionInfo] | `Map<String, String>` | Gift extension information |
 */
export declare class Gift {
    /**
     * Gift ID.
     */
    giftID: string;
    /**
     * Gift name.
     */
    name: string;
    /**
     * Gift description.
     */
    desc: string;
    /**
     * Network URL of the gift icon image, used to load gift thumbnails.
     */
    iconURL: string;
    /**
     * Network URL of the gift animation resource file, used to load gift display animations.
     */
    resourceURL: string;
    /**
     * Gift level, used to distinguish gift rarity or value tier.
     */
    level: number;
    /**
     * Gift price (coins).
     */
    coins: number;
    /**
     * Gift extension information, customizable fields (such as effect type, sending restrictions, etc.).
     */
    extensionInfo: Map<string, string>;
}
/**
 * Gift category.
 *
 * Contains gift category ID, name, description, and the gift list under this category.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [categoryID] | `String` | Category unique identifier ID |
 * | [name] | `String` | Category display name |
 * | [desc] | `String` | Category description information |
 * | [extensionInfo] | `Map<String, String>` | Category extension information |
 * | [giftList] | `List<Gift>` | All gifts under the current category |
 */
export declare class GiftCategory extends BasicData {
    /**
     * Category unique identifier ID, used to distinguish different gift categories.
     */
    categoryID: string;
    /**
     * Category display name, used for UI category display (such as "Popular Gifts", "Premium Gifts").
     */
    name: string;
    /**
     * Category description information, used to explain the characteristics of this category.
     */
    desc: string;
    /**
     * Category extension information, containing custom fields (such as sorting weight, display style, etc.).
     */
    extensionInfo: Map<string, string>;
    /**
     * All gifts under the current category.
     */
    giftList: Array<Gift>;
}
/**
 * Gift statistics information, containing gift sending statistics for a receiver.
 *
 * Contains the total gifts sent, total coins, and unique sender count for a specific receiver.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [receiver] | `String` | Receiver account ID |
 * | [totalGiftCount] | `int` | Total number of gifts sent |
 * | [totalGiftCoins] | `int` | Total gift coins value |
 * | [totalGiftSendersCount] | `int` | Total number of unique gift senders |
 */
export declare class GiftStatisticInfo extends BasicData {
    /**
     * Receiver account ID.
     */
    receiver: string;
    /**
     * Total number of gifts sent to this receiver.
     */
    totalGiftCount: number;
    /**
     * Total gift coins value.
     */
    totalGiftCoins: number;
    /**
     * Total number of unique gift senders.
     */
    totalGiftSendersCount: number;
}
/**
 * Gift state, managing the gift data state of the current room, supporting real-time updates and subscription listening.
 *
 * Contains all gift categories and gift lists available in the current room, supporting real-time updates.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [usableGifts] | `ValueListenable<List<GiftCategory>>` | All gift categories and gift lists available in the current room |
 * | [isGiftEnabled] | `ValueListenable<bool>` | Whether the gift feature is enabled in the current room |
 * | [userGiftStatisticsList] | `ValueListenable<List<GiftStatisticInfo>>` | Gift statistics list for all receivers |
 *
 * > **Tip**: Gift state is automatically updated. Subscribe to [giftState] to receive real-time updates.
 */
@Observed
export declare class GiftState {
    /**
     * All gift categories and gift lists available in the current room.
     */
    usableGifts: GiftCategoryDataSource;
    /**
     * Whether the gift feature is enabled in the current room, supports real-time updates and can be subscribed to.
     */
    isGiftEnabled: boolean;
    /**
     * Gift statistics list for all receivers.
     */
    userGiftStatisticsList: GiftStatisticInfoDataSource;
}
export declare class GiftListener {
    onReceiveGift?: (liveID: string, gift: Gift, count: number, sender: LiveUserInfo) => void;
    onReceiveGiftWithReceiver?: (liveID: string, gift: Gift, count: number, sender: LiveUserInfo, receiver: LiveUserInfo) => void;
}
/**
 * Gift-related interface, managing gift sending, gift state synchronization, and gift event listening in live rooms/voice chat rooms.
 *
 * `GiftStore` Gift management class for handling gift-related business logic in live rooms/voice chat rooms.
 * `GiftStore` provides a complete set of gift management APIs, including sending gifts, refreshing gift lists, setting language, and listening to gift events.
 * Through this class, gift interaction features can be implemented in live rooms.
 *
 * ### Key Features
 *
 * - **Gift Sending**: Support sending specified gifts to the current room.
 * - **Gift List**: Get and refresh the available gift list in the current room.
 * - **Language Setting**: Set the display language for gift information.
 * - **Event Listening**: Listen to gift receiving events.
 *
 * > **Important**: Use the [GiftStore.create] factory method to create a `GiftStore` instance, passing a valid live room ID.
 *
 * > **Tip**: Gift state updates are delivered through the [giftState] publisher. Subscribe to it to receive real-time updates of gift data in the room.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### Gift Operations
 *
 */
export declare abstract class GiftStore {
    protected state: GiftState;
    get giftState(): GiftState;
    abstract addGiftListener(listener: GiftListener): void;
    abstract removeGiftListener(listener: GiftListener): void;
    static create(liveID: string): GiftStore;
    /**
     * Set the display language for gift information.
     *
     * @param language Language code ("zh-CN" for Chinese, "en" for English). After setting, gift names, descriptions, etc. will be updated to the corresponding language when the display interface is refreshed.
     */
    abstract setLanguage(language: string): void;
    /**
     * Manually refresh the available gift list in the current room.
     */
    abstract refreshUsableGifts(): Promise<void>;
    /**
     * Send a specified gift to the current room
     *
     * @param giftID Unique identifier ID of the gift to send.
     * @param count Number of gifts to send at once.
     * @param receiver Receiver's user ID.
     */
    abstract sendGift(giftID: string, count: number, receiver: string): Promise<void>;
    /**
     * Enable or disable the gift feature in the current room.
     *
     * @param enabled `true` to enable the gift feature, `false` to disable it. The latest value can be observed through ``GiftState/isGiftEnabled``.
     */
    abstract setGiftEnabled(enabled: boolean): Promise<void>;
}
export declare class GiftCategoryDataSource extends BasicDataSource<GiftCategory> {
}
export declare class GiftStatisticInfoDataSource extends BasicDataSource<GiftStatisticInfo> {
}
