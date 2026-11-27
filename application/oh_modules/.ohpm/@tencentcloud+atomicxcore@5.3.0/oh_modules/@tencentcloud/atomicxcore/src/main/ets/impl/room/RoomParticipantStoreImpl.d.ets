/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   RoomParticipantStoreImpl @ AtomicEngine
 * Function: RoomParticipantStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。
 */
import { DeviceType } from '../../api/device/DeviceStore';
import { ListResult, RoomUser } from '../../api/room/RoomStore';
import { RoomParticipant, RoomParticipantListener, RoomParticipantStore } from '../../api/room/RoomParticipantStore';
import { IStore } from '../common/IStore';
@Observed
export declare class RoomParticipantStoreImpl extends RoomParticipantStore implements IStore {
    private static readonly log;
    private roomID;
    private listeners;
    private eventToken;
    private stateToken;
    constructor(roomID: string);
    addRoomParticipantListener(listener: RoomParticipantListener): void;
    removeRoomParticipantListener(listener: RoomParticipantListener): void;
    getParticipantList(cursor?: string): Promise<ListResult<RoomParticipant>>;
    getAudienceList(cursor?: string): Promise<ListResult<RoomUser>>;
    searchUsers(keyword: string): Promise<ListResult<RoomUser>>;
    promoteAudienceToParticipant(userID: string): Promise<void>;
    demoteParticipantToAudience(userID: string): Promise<void>;
    transferOwner(userID: string): Promise<void>;
    setAdmin(userID: string): Promise<void>;
    revokeAdmin(userID: string): Promise<void>;
    kickUser(userID: string): Promise<void>;
    updateParticipantNameCard(userID: string, nameCard: string): Promise<void>;
    updateParticipantMetaData(userID: string, metaData: Map<string, string>): Promise<void>;
    muteMicrophone(): void;
    unmuteMicrophone(): Promise<void>;
    closeParticipantDevice(userID: string, device: DeviceType): Promise<void>;
    disableUserMessage(userID: string, disable: boolean): Promise<void>;
    disableAllDevices(device: DeviceType, disable: boolean): Promise<void>;
    disableAllMessages(disable: boolean): Promise<void>;
    requestToOpenDevice(device: DeviceType, timeout?: number): Promise<void>;
    cancelOpenDeviceRequest(device: DeviceType): Promise<void>;
    approveOpenDeviceRequest(device: DeviceType, userID: string): Promise<void>;
    rejectOpenDeviceRequest(device: DeviceType, userID: string): Promise<void>;
    inviteToOpenDevice(userID: string, device: DeviceType, timeout?: number): Promise<void>;
    cancelOpenDeviceInvitation(userID: string, device: DeviceType): Promise<void>;
    acceptOpenDeviceInvitation(userID: string, device: DeviceType): Promise<void>;
    declineOpenDeviceInvitation(userID: string, device: DeviceType): Promise<void>;
    beforeEnterRoom(_roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(_roomID: string): void;
    private static onModuleEvent;
    private static onModuleStateChanged;
    private static resolveChangedList;
    private static insertParticipantsByOrder;
    private static applyListModify;
    private static applyListModifyToDataSource;
    private static mapToRoomUser;
    private static intToDeviceStatus;
    private static intToParticipantRole;
    private static intToRoomParticipantStatus;
    private static mapToRoomParticipant;
    private static mapCallToPendingParticipant;
    private static callStatusToParticipantStatus;
    private static mapToNetworkInfo;
    private static intToNetworkQuality;
    private static mapToDeviceRequestInfo;
    private static intToDeviceType;
    private static intToKickedOutOfRoomReason;
    private static parseListResult;
}
