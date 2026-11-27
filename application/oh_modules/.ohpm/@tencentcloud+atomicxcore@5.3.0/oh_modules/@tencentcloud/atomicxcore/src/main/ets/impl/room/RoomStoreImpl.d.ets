/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   RoomStoreImpl @ AtomicEngine
 * Function: RoomStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。
 */
import { CallRejectionReason, CreateRoomOptions, ListResult, RoomCall, RoomCallResult, RoomInfo, RoomListener, RoomStore, RoomType, RoomUser, ScheduleRoomOptions, ScheduleRoomOptionsModifyFlag, StartRecordingOptions, UpdateRoomOptions, UpdateRoomOptionsModifyFlag } from '../../api/room/RoomStore';
import { ExperimentalEventCallback, SubscriptionToken } from '../../api/Define';
@Observed
export declare class RoomStoreImpl extends RoomStore {
    private static instance;
    private static readonly log;
    private listeners;
    private constructor();
    static shared(): RoomStoreImpl;
    addRoomListener(listener: RoomListener): void;
    removeRoomListener(listener: RoomListener): void;
    getScheduledRoomList(cursor: string | undefined): Promise<ListResult<RoomInfo>>;
    getScheduledAttendees(roomID: string, cursor: string | undefined): Promise<ListResult<RoomUser>>;
    scheduleRoom(roomID: string, options: ScheduleRoomOptions): Promise<void>;
    updateScheduledRoom(roomID: string, options: ScheduleRoomOptions, modifyFlagList: ScheduleRoomOptionsModifyFlag[]): Promise<void>;
    addScheduledAttendees(roomID: string, userIDList: string[]): Promise<void>;
    removeScheduledAttendees(roomID: string, userIDList: string[]): Promise<void>;
    cancelScheduledRoom(roomID: string): Promise<void>;
    createAndJoinRoom(roomID: string, roomType: RoomType, options: CreateRoomOptions): Promise<void>;
    joinRoom(roomID: string, roomType: RoomType, password?: string): Promise<void>;
    leaveRoom(): Promise<void>;
    endRoom(): Promise<void>;
    updateRoomInfo(roomID: string, options: UpdateRoomOptions, modifyFlagList: UpdateRoomOptionsModifyFlag[]): Promise<void>;
    getRoomInfo(roomID: string): Promise<RoomInfo>;
    getPendingCalls(roomID: string, cursor: string | undefined): Promise<ListResult<RoomCall>>;
    callUserToRoom(roomID: string, userIDList: string[], timeout?: number, extensionInfo?: string | undefined): Promise<Map<string, RoomCallResult>>;
    cancelCall(roomID: string, userIDList: string[]): Promise<void>;
    acceptCall(roomID: string): Promise<void>;
    rejectCall(roomID: string, reason: CallRejectionReason): Promise<void>;
    startRecording(options?: StartRecordingOptions): Promise<void>;
    stopRecording(): Promise<void>;
    callExperimentalAPI(jsonStr: string): Promise<string>;
    subscribeExperimentalEvent(event: string, callback: ExperimentalEventCallback): SubscriptionToken;
    unsubscribeExperimentalEvent(token: SubscriptionToken): void;
    reset(): void;
    private static onModuleEvent;
    private static onModuleStateChanged;
    private static resolveChangedList;
    private static releaseStoresOnEnterRoomFailed;
    private static applyListModifyToDataSource;
    private static scheduleRoomOptionsToMap;
    private static mapToRoomUser;
    private static mapToRoomInfo;
    private static mapToRecordingInfo;
    private static mapToRoomCall;
    private static intToRoomCallResult;
    private static intToCallRejectionReason;
    private static intToRecordingStopReason;
    private static intToRecordingStatus;
    private static parseListResult;
}
