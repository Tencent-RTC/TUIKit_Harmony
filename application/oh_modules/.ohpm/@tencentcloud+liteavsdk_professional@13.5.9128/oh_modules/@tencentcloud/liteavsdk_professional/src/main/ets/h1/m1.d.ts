export declare enum r10 {
    ERR_SUCCESS = 0,
    ERR_FAILED = -1,
    ERR_INVALID_PARAMETER = -2,
    ERR_INVALID_ACCESS_TOKEN = -3,
    ERR_RATE_LIMITED = -4,
    ERR_UNAUTHORIZED_OPERATION = -5,
    ERR_DEVICE_BOUND = -1000,
    ERR_BIND_TOKEN_NOT_EXIST = -1001,
    ERR_BIND_TOKEN_IS_EXPIRED = -1002,
    ERR_BIND_TOKEN_NO_PAIR_WITH_DEVICE = -1003,
    ERR_INVALID_MESSAGE_ID = -1004,
    ERR_FAMILY_DEVICE_LIMIT_EXCEEDED = -1005,
    ERR_CAN_NOT_BIND_SAME_FAMILY = -1006,
    ERR_FAMILY_NOT_EXIST = -1007,
    ERR_PRODUCT_NOT_EXIST = -1008,
    ERR_DEVICE_NOT_EXIST = -1009,
    ERR_DEVICE_OFFLINE = -1010,
    ERR_CAMERA_START_FAIL = -2000,
    ERR_CAMERA_NOT_AUTHORIZED = -2001,
    ERR_CAMERA_OCCUPY = -2002,
    ERR_MIC_START_FAIL = -2003,
    ERR_MIC_NOT_AUTHORIZED = -2004,
    ERR_MIC_OCCUPY = -2005,
    ERR_SPEAKER_START_FAIL = -2006,
    ERR_RECORD_DURATION_TOO_SHORT = -2007,
    ERR_FILE_PATH_UNWRITABLE = -2008,
    ERR_FILE_PATH_ALREADY_EXIST = -2009,
    ERR_DEVICE_SWITCH_TO_VOIP = -2010
}
export declare enum c13 {
    UNKNOWN = 0,
    MEMBER = 1,
    ADMIN = 2
}
export declare class d13 {
    familyId: string;
    name: string;
    createTime: number;
    updateTime: number;
    role: c13;
}
export declare class e13 {
    roomId: string;
    name: string;
    familyId: string;
    g13: number;
    createTime: number;
    updateTime: number;
}
export declare class z11 {
    userId: string;
    nickName: string;
    h13: string;
    role: c13;
    i13: number;
}
export declare class q10 {
    productId: string;
    deviceName: string;
}
export declare class f13 {
    j13: boolean;
    k13: number;
    l13: number;
}
export declare class y11 {
    deviceId: q10;
    aliasName: string;
    familyId: string;
    roomId: string;
    iconUrl: string;
    createTime: number;
    updateTime: number;
    status: f13;
}
export declare class n11<T> {
    nextPageToken: string;
    dataList: T[];
}
export interface l11<T> {
    onSuccess(result: T): void;
    onError(errorCode: r10, errorMessage: string): void;
}
