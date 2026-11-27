/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   HouseBuilder @ TXLiteAVSDK
 * Function: License 校验接口
 */
/**
 * License 功能类型枚举
 */
export declare enum FunctionType {
    PlayerStandard = 32,
    PlayerMonet = 64,
    PlayerPremium = 128,
    PlayerEnterprise = 256,
    PlayerProjection = 512
}
/**
 * License 校验结果枚举
 */
export declare enum Result {
    OK = 0,
    ErrorJsonFormat = -1,
    ErrorSignature = -2,
    ErrorDecode = -3,
    ErrorPackage = -4,
    ErrorFeature = -5,
    ErrorInnerNotExist = -6,
    ErrorLocalNotExist = -7,
    ErrorContentEmpty = -8,
    ErrorWriteHouse = -9,
    ErrorWritePituHouse = -10,
    ErrorExpired = -11,
    ErrorDownload = -12,
    ErrorNoAuthorization = -13,
    ErrorUnknown = -14
}
/**
 * License 校验工具类
 */
export declare class HouseBuilder {
    private static sharedInstance;
    private housebuilder;
    private constructor();
    /**
     * 校验 License 功能
     *
     * @param functionType 功能类型
     * @returns 校验结果，0 表示成功，负数表示失败
     */
    static valid(m1: FunctionType): Result;
}
