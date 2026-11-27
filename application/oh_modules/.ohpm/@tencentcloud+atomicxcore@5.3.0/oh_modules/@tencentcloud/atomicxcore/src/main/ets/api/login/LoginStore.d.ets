/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LoginStore @ AtomicXCore
 * Function: Login related interfaces, managing user login, logout, user information settings and other operations.
 */
import { EventEmitter } from '../common/EventEmitter';
import common from "@ohos.app.ability.common";
import { V2TIMGender } from '@tencentcloud/imsdk';
/**
 * Login status.
 */
export declare enum LoginStatus {
    /**
     * Not logged in.
     */
    UNLOGIN = 3,
    /**
     * Logged in.
     */
    LOGINED = 1
}
/**
 * Friend verification type.
 */
export declare enum AllowType {
    /**
     * Allow anyone.
     */
    ALLOW_ANY = 0,
    /**
     * Need confirmation.
     */
    NEED_CONFIRM = 1,
    /**
     * Deny anyone.
     */
    DENY_ANY = 2
}
/**
 * Gender.
 */
export declare enum Gender {
    /**
     * Unknown.
     */
    UNKNOWN = 0,
    /**
     * Male.
     */
    MALE = 1,
    /**
     * Female.
     */
    FEMALE = 2
}
/**
 * User profile.
 *
 * User profile data structure, containing user ID, nickname, avatar, gender and other personal information.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [userID] | `string` | User ID |
 * | [nickname] | `string?` | Nickname |
 * | [avatarURL] | `string?` | Avatar URL |
 * | [selfSignature] | `string?` | Personal signature |
 * | [gender] | `Gender?` | Gender |
 * | [role] | `number?` | Role. This field has no business restrictions, so you can safely use any valid integer value. |
 * | [level] | `number?` | Level. This field has no business restrictions, so you can safely use any valid integer value. |
 * | [birthday] | `number?` | Birthday. This field has no business restrictions, so you can safely use any valid integer value. |
 * | [allowType] | `AllowType?` | Friend verification type |
 * | [customInfo] | `Map<string, ArrayBuffer>?` | Custom information |
 */
@Observed
export declare class UserProfile {
    /**
     * User ID.
     */
    userID: string;
    /**
     * Nickname.
     */
    nickname?: string;
    /**
     * Avatar URL.
     */
    avatarURL?: string;
    /**
     * Personal signature.
     */
    selfSignature?: string;
    /**
     * Gender.
     */
    gender?: Gender;
    /**
     * Role. This field has no business restrictions, so you can safely use any valid integer value.
     */
    role?: number;
    /**
     * Level. This field has no business restrictions, so you can safely use any valid integer value.
     */
    level?: number;
    /**
     * Birthday. This field has no business restrictions, so you can safely use any valid integer value.
     */
    birthday?: number;
    /**
     * Friend verification type.
     */
    allowType?: AllowType;
    /**
     * Custom information.
     */
    customInfo?: Map<string, ArrayBuffer>;
    constructor(userID?: string, nickname?: string, avatarURL?: string);
}
/**
 * Login state.
 *
 * Login state data structure, containing current login status and logged-in user information.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [loginStatus] | `LoginStatus?` | Login status |
 * | [loginUserInfo] | `UserProfile?` | Logged-in user information |
 */
@Observed
export declare class LoginState {
    /**
     * Login status.
     */
    loginStatus?: LoginStatus;
    /**
     * Logged-in user information.
     */
    loginUserInfo?: UserProfile;
}
/**
 * Login event.
 */
export declare enum LoginEvent {
    /**
     * Current user kicked offline.
     */
    KICKED_OFFLINE = 0,
    /**
     * Login ticket expired.
     */
    LOGIN_EXPIRED = 1
}
/**
 * Login related interfaces, managing user login, logout, user information settings and other operations.
 *
 * `LoginStore` Login management class for handling user login, logout and user information management business logic.
 * `LoginStore` provides a complete set of login management APIs, including user login, logout, and personal information settings.
 * Through this class, you can manage user login status and user profiles.
 *
 * ### Key Features
 *
 * - **User Login**: Supports login using SDK application ID, user ID and user signature.
 * - **User Logout**: Supports user logout operation.
 * - **Personal Information Settings**: Supports setting user nickname, avatar, gender and other personal information.
 *
 * > **Important**: Use [LoginStore.shared] singleton object to access the `LoginStore` instance.
 *
 * > **Tip**: Login status updates are delivered through [state] publisher. Subscribe to it to receive real-time updates about login status.
 *
 * ### Getting Instance
 * - [LoginStore.shared] - Singleton object.
 *
 * ### Observing State
 * - [state] - Login state.
 *
 * ### Events Handling
 * - [loginEventEmitter] - Login event emitter
 *
 * ### Login Operations
 * - [login] - Login.
 * - [logout] - Logout.
 * - [setSelfInfo] - Set personal information.
 *
 * @see [LoginState]
 * @see [UserProfile]
 * @see [LoginStatus]
 * @see [Gender]
 * @see [AllowType]
 * @see [LoginEvent]
 */
@Observed
export declare class LoginStore {
    private static instance;
    private impl;
    sdkAppID: number;
    readonly loginEventEmitter: EventEmitter<LoginEvent>;
    private constructor();
    get state(): Readonly<LoginState>;
    static shared(): LoginStore;
    /**
     * Login
     *
     * @param sdkAppID SDK application ID. Get this from [TRTC console](https://console.trtc.io/app).
     * @param userID User ID. The recommended length limit is 32 bytes, and only uppercase and lowercase English letters (a-zA-Z), digits (0-9), underscores, and hyphens are allowed.
     * @param userSig User signature. For the generation of userSig, please refer to the [Secure authentication with userSig](https://trtc.io/document/35166).
     * @param context Context.
     */
    login(sdkAppID: number, userID: string, userSig: string, context?: common.Context): Promise<void>;
    /**
     * Logout
     */
    logout(): Promise<void>;
    /**
     * Set personal information
     *
     * @param userProfile User profile.
     */
    setSelfInfo(userProfile: UserProfile): Promise<void>;
}
export declare namespace LoginStatus {
    function parse(value: number): LoginStatus;
}
export declare namespace AllowType {
    function parse(value: number): AllowType;
}
export declare namespace Gender {
    function parse(value: number): Gender;
    function toV2TIMGender(gender: Gender): V2TIMGender;
}
