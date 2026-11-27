import { l11, d13, e13, z11 } from "./m1";
export interface i12 {
    createFamily(name: string, callback: l11<d13>): void;
    deleteFamily(familyId: string, callback: l11<void>): void;
    getFamilyList(callback: l11<d13[]>): void;
    updateFamilyInfo(newFamilyInfo: d13, callback: l11<void>): void;
    createRoom(familyId: string, name: string, callback: l11<e13>): void;
    deleteRoom(familyId: string, roomId: string, callback: l11<void>): void;
    setRoomName(familyId: string, roomId: string, name: string, callback: l11<void>): void;
    getRoomList(familyId: string, callback: l11<e13[]>): void;
    createFamilyInviteToken(familyId: string, callback: l11<string>): void;
    joinFamilyAsMember(inviteToken: string, callback: l11<void>): void;
    removeMemberFromFamily(familyId: string, userId: string, callback: l11<void>): void;
    getMemberList(familyId: string, callback: l11<z11[]>): void;
}
