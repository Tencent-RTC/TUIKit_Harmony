export declare enum StoreType {
    RoomStore = 0,
    DeviceStore = 1,
    RoomParticipantStore = 2,
    ContactStore = 3,
    ConversationGroupStore = 4,
    ConversationListStore = 5,
    GroupStore = 6,
    GroupMemberStore = 7,
    MessageActionStore = 8,
    MessageInputStore = 9,
    MessageListStore = 10,
    SearchStore = 11,
    LiveListStore = 12,
    LiveSeatStore = 13,
    LiveAudienceStore = 14,
    CoHostStore = 15,
    CoGuestStore = 16,
    BattleStore = 17,
    LikeStore = 18,
    LiveSummaryStore = 19,
    BarrageStore = 20,
    GiftStore = 21,
    MusicStore = 22
}
export type StoreCreator = () => Object;
export type StringStoreCreator = (arg: string) => Object;
export type ObjectStoreCreator = (arg: Object) => Object;
export declare class StoreRegistry {
    private static creators;
    static registerCreator(key: StoreType, creator: StoreCreator): void;
    static registerCreator(key: StoreType, creator: StringStoreCreator): void;
    static registerCreator(key: StoreType, creator: ObjectStoreCreator): void;
    static create(key: StoreType, args?: Object[]): Object;
    static getStore(key: StoreType, roomID?: string): Object;
    static registerChatStoreCreators(): void;
}
