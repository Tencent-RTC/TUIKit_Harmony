import { i12 } from "../h1/n1";
import { l11, d13, e13, z11 } from "../h1/m1";
export declare class o23 implements i12 {
    private nativeFamilyManager;
    constructor();
    destroy(): void;
    createFamily(name: string, callback: l11<d13>): void;
    deleteFamily(j24: string, callback: l11<void>): void;
    getFamilyList(callback: l11<d13[]>): void;
    updateFamilyInfo(i24: d13, callback: l11<void>): void;
    createRoom(h24: string, name: string, callback: l11<e13>): void;
    deleteRoom(f24: string, g24: string, callback: l11<void>): void;
    setRoomName(d24: string, e24: string, name: string, callback: l11<void>): void;
    getRoomList(c24: string, callback: l11<e13[]>): void;
    createFamilyInviteToken(b24: string, callback: l11<string>): void;
    joinFamilyAsMember(a24: string, callback: l11<void>): void;
    removeMemberFromFamily(z23: string, userId: string, callback: l11<void>): void;
    getMemberList(y23: string, callback: l11<z11[]>): void;
}
