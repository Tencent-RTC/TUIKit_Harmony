import BasicDataSource from '../common/BasicDataSource';
import { RoomParticipant } from './RoomParticipantStore';
import { RoomUser } from './RoomStore';
export declare class RoomParticipantDataSource extends BasicDataSource<RoomParticipant> {
    toArray(): RoomParticipant[];
    find(predicate: (p: RoomParticipant) => boolean): RoomParticipant | undefined;
    some(predicate: (p: RoomParticipant) => boolean): boolean;
}
export declare class RoomAudienceDataSource extends BasicDataSource<RoomUser> {
    find(predicate: (p: RoomUser) => boolean): RoomUser | undefined;
    some(predicate: (p: RoomUser) => boolean): boolean;
}
