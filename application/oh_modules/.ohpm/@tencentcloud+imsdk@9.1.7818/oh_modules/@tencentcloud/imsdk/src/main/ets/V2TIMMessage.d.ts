/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMDownloadCallback, V2TIMGroupMemberInfo, V2TIMGroupChangeInfo, V2TIMGroupMemberChangeInfo, V2TIMReceiveMessageOpt, V2TIMUserFullInfo, V2TIMUserInfo, V2TIMGroupMemberFullInfo, V2TIMKeywordListMatchType } from "../../../Index";
export declare const kImSDK_MesssageAtALL = "__kImSDK_MesssageAtALL__";
/**
 * （一）枚举值定义
 */
/**
 * 消息优先级
 */
export declare enum V2TIMMessagePriority {
    /**
     * 默认
     */
    V2TIM_PRIORITY_DEFAULT = 0,
    /**
     * 高优先级，一般用于礼物等重要消息
     */
    V2TIM_PRIORITY_HIGH = 1,
    /**
     * 常规优先级，一般用于普通消息
     */
    V2TIM_PRIORITY_NORMAL = 2,
    /**
     * 低优先级，一般用于点赞消息
     */
    V2TIM_PRIORITY_LOW = 3
}
/**
 * 消息状态
 */
export declare enum V2TIMMessageStatus {
    /**
     * 消息发送中
     */
    V2TIM_MSG_STATUS_SENDING = 1,
    /**
     * 消息发送成功
     */
    V2TIM_MSG_STATUS_SEND_SUCC = 2,
    /**
     * 消息发送失败
     */
    V2TIM_MSG_STATUS_SEND_FAIL = 3,
    /**
     * 消息被删除
     */
    V2TIM_MSG_STATUS_HAS_DELETED = 4,
    /**
     * 导入到本地的消息
     */
    V2TIM_MSG_STATUS_LOCAL_IMPORTED = 5,
    /**
     * 被撤销的消息
     */
    V2TIM_MSG_STATUS_LOCAL_REVOKED = 6
}
/**
 * 消息类型
 */
export declare enum V2TIMElemType {
    /**
     * 未知消息
     */
    V2TIM_ELEM_TYPE_NONE = 0,
    /**
     * 文本消息
     */
    V2TIM_ELEM_TYPE_TEXT = 1,
    /**
     * 自定义消息
     */
    V2TIM_ELEM_TYPE_CUSTOM = 2,
    /**
     * 图片消息
     */
    V2TIM_ELEM_TYPE_IMAGE = 3,
    /**
     * 语音消息
     */
    V2TIM_ELEM_TYPE_SOUND = 4,
    /**
     * 视频消息
     */
    V2TIM_ELEM_TYPE_VIDEO = 5,
    /**
     * 文件消息
     */
    V2TIM_ELEM_TYPE_FILE = 6,
    /**
     * 地理位置消息
     */
    V2TIM_ELEM_TYPE_LOCATION = 7,
    /**
     * 表情消息
     */
    V2TIM_ELEM_TYPE_FACE = 8,
    /**
     * 群 Tips 消息
     */
    V2TIM_ELEM_TYPE_GROUP_TIPS = 9,
    /**
     * 合并消息
     */
    V2TIM_ELEM_TYPE_MERGER = 10,
    /**
     * 流式消息
     */
    V2TIM_ELEM_TYPE_STREAM = 11
}
/**
 * 推送规则
 */
export declare enum V2TIMOfflinePushFlag {
    /**
     * 按照默认规则进行推送
     */
    V2TIM_OFFLINE_PUSH_DEFAULT = 0,
    /**
     * 不进行推送
     */
    V2TIM_OFFLINE_PUSH_NO_PUSH = 1
}
/**
 * 图片类型
 */
export declare enum V2TIMImageType {
    /**
     * 原图
     */
    V2TIM_IMAGE_TYPE_ORIGIN = 1,
    /**
     * 缩略图
     */
    V2TIM_IMAGE_TYPE_THUMB = 2,
    /**
     * 大图
     */
    V2TIM_IMAGE_TYPE_LARGE = 4
}
/**
 * 群 Tips 类型
 */
export declare enum V2TIMGroupTipsType {
    /**
     * 未定义
     */
    V2TIM_GROUP_TIPS_TYPE_NONE = 0,
    /**
     * 主动入群（memberList 加入群组，非 Work 群有效）
     */
    V2TIM_GROUP_TIPS_TYPE_JOIN = 1,
    /**
     * 被邀请入群（opMember 邀请 memberList 入群，从 8.0 版本开始支持除 AVChatRoom 之外的所有群类型）
     */
    V2TIM_GROUP_TIPS_TYPE_INVITE = 2,
    /**
     * 退出群 (opMember 退出群组)
     */
    V2TIM_GROUP_TIPS_TYPE_QUIT = 3,
    /**
     * 踢出群 (opMember 把 memberList 踢出群组)
     */
    V2TIM_GROUP_TIPS_TYPE_KICKED = 4,
    /**
     * 设置管理员 (opMember 把 memberList 设置为管理员)
     */
    V2TIM_GROUP_TIPS_TYPE_SET_ADMIN = 5,
    /**
     * 取消管理员 (opMember 取消 memberList 管理员身份)
     */
    V2TIM_GROUP_TIPS_TYPE_CANCEL_ADMIN = 6,
    /**
     * 群资料变更 (opMember 修改群资料： groupName  introduction  notification  faceUrl  owner  allMute  custom)
     */
    V2TIM_GROUP_TIPS_TYPE_GROUP_INFO_CHANGE = 7,
    /**
     * 群成员资料变更 (opMember 修改群成员资料：muteTime)
     */
    V2TIM_GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE = 8,
    /**
     * 话题资料变更 (opMember 修改话题资料：topicName & introduction & notification & faceUrl & allMute & topicCustomData)
     */
    V2TIM_GROUP_TIPS_TYPE_TOPIC_INFO_CHANGE = 9,
    /**
     * 置顶群消息
     */
    V2TIM_GROUP_TIPS_TYPE_PINNED_MESSAGE_ADDED = 10,
    /**
     * 取消置顶群消息
     */
    V2TIM_GROUP_TIPS_TYPE_PINNED_MESSAGE_DELETED = 11
}
/**
 * 消息拉取方式
 */
export declare enum V2TIMMessageGetType {
    /**
     * 获取云端更老的消息
     */
    V2TIM_GET_CLOUD_OLDER_MSG = 1,
    /**
     * 获取云端更新的消息
     */
    V2TIM_GET_CLOUD_NEWER_MSG = 2,
    /**
     * 获取本地更老的消息
     */
    V2TIM_GET_LOCAL_OLDER_MSG = 3,
    /**
     * 获取本地更新的消息
     */
    V2TIM_GET_LOCAL_NEWER_MSG = 4
}
/**
 * 群消息已读成员列表过滤类型
 */
export declare enum V2TIMGroupMessageReadMembersFilter {
    /**
     * 群消息已读成员列表
     */
    V2TIM_GROUP_MESSAGE_READ_MEMBERS_FILTER_READ = 0,
    /**
     * 群消息未读成员列表
     */
    V2TIM_GROUP_MESSAGE_READ_MEMBERS_FILTER_UNREAD = 1
}
/**
 * iOS 离线推送的类型
 */
export declare enum V2TIMIOSOfflinePushType {
    /**
     * 普通的 APNs 推送
     */
    V2TIM_IOS_OFFLINE_PUSH_TYPE_APNS = 0,
    /**
     * VoIP 推送
     */
    V2TIM_IOS_OFFLINE_PUSH_TYPE_VOIP = 1
}
/**
 * （二）结构体定义
 */
export interface V2TIMOfflinePushConfig {
    /**
     * 从应用获取的 Push Token
     * 详情：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-token-0000001727725878
     */
    token: string;
    /**
     * 从 IM 控制台获取的证书 ID
     * 详情：https://console.cloud.tencent.com/im/push-plugin-push-identifier
     */
    businessID: number;
}
/**
 * 消息引用信息
 */
export declare class V2TIMMessageQuoteInfo {
    /**
     * 被引用的消息 ID
     */
    msgID: string;
    /**
     * 被引用的消息时间
     */
    messageTime: number;
    /**
     * 被引用的消息序号
     */
    messageSequence: number;
}
/**
 * 自定义消息 push。
 */
export declare class V2TIMOfflinePushInfo {
    /**
     * 离线推送展示的标题
     */
    title: string;
    /**
     * 离线推送展示的内容
     *
     * @note 自定义消息进行离线推送，该字段不能为空字符串
     */
    desc: string;
    /**
     * 离线推送透传的扩展字段
     *
     * iOS：收到离线推送的一方可以在 UIApplicationDelegate -> didReceiveRemoteNotification -> userInfo
     * 拿到这个字段，该字段可以做 UI 跳转逻辑
     *
     * 鸿蒙：收到离线推送的一方可以在 UIAbility -> onCreate/onNewWant -> Want.parameters.ext
     * 拿到这个字段，该字段可以做 UI 跳转逻辑
     *
     */
    ext?: string;
    /**
     * 是否关闭推送
     */
    disablePush?: boolean;
    /**
     * iOS 离线推送的类型（仅对 iOS 生效）
     * 默认 V2TIM_IOS_OFFLINE_PUSH_TYPE_APNS
     */
    iOSPushType?: V2TIMIOSOfflinePushType;
    /**
     * 离线推送忽略 badge 计数（仅对 iOS 生效）
     * 如果设置为 true，在 iOS 接收端，这条消息不会使 APP 的应用图标未读计数增加
     */
    ignoreIOSBadge?: boolean;
    /**
     * 离线推送声音设置（仅对 iOS 生效）
     *
     * 当 iOSSound == "kIOSOfflinePushNoSound"，表示接收时不会播放声音
     * 当 iOSSound == "kIOSOfflinePushDefaultSound"，表示接收时播放系统声音
     *
     * 如果要自定义 iOSSound，需要先把语音文件链接进 Xcode 工程，然后把语音文件名（带后缀）设置给 iOSSound
     */
    iOSSound?: string;
    /**
     * iOS 离线推送的通知级别 (iOS 15 及以上支持)
     *
     * @param level 通知级别
     *     "passive"，不会发出声音、振动或横幅提示，只会静默地出现在通知中心。适用于不紧急的信息，例如应用内的社交活动更新或推荐内容。
     *     "active", 会发出声音或振动，并显示横幅提示。适用于一般的重要通知，例如消息提醒、日历事件等。（默认类型）
     *     "time-sensitive"，会发出声音或振动，并显示横幅提示，这种级别的通知会打扰用户，即使用户启用了“专注模式”（Focus Mode）。适用于需要用户立即关注的紧急通知，例如安全警报、重要的时间提醒等。打开需要在苹果开发者平台和 xcode 项目中增加相应的配置。
     *     "critical", 会发出声音或振动，并显示横幅提示。这种级别的通知会打扰用户，即使设备处于静音模式。适用于极其重要的紧急通知，例如公共安全警报、严重的健康警告等。打开需要向 Apple 特殊申请。
     */
    iOSInterruptionLevel?: String;
    /**
     * 设置 iOS 后台透传消息（仅对 iOS 生效）
     *
     * @note 设置打开后，离线接收会唤起应用并透传消息内容 ext
     */
    enableIOSBackgroundNotification?: boolean;
    /**
     * 离线推送声音设置（仅对 Android 生效, 仅 IM SDK 6.1 及以上版本支持）
     * 只有华为和谷歌手机支持设置铃音提示，小米铃音设置请您参照：https://dev.mi.com/console/doc/detailpId=1278%23_3_0
     * 另外，谷歌手机 FCM 推送在 Android 8.0 及以上系统设置声音提示，必须调用 setAndroidFCMChannelID 设置好 channelID，才能生效
     *
     * AndroidSound: Android 工程里 raw 目录中的铃声文件名，不需要后缀名
     */
    AndroidSound?: string;
    /**
     * 离线推送设置 OPPO 手机 8.0 系统及以上的渠道 ID（仅对 Android 生效）
     */
    AndroidOPPOChannelID?: string;
    /**
     * 离线推送设置 FCM 通道手机 8.0 系统及以上的渠道 ID（仅对 Android 生效）
     */
    AndroidFCMChannelID?: string;
    /**
     * 离线推送设置小米通道手机 8.0 系统及以上的渠道 ID（仅对 Android 生效）
     */
    AndroidXiaoMiChannelID?: string;
    /**
     * 离线推送设置 VIVO 手机 （仅对 Android 生效）
     * VIVO 手机离线推送消息分类，0：运营消息，1：系统消息，默认 1
     */
    AndroidVIVOClassification?: number;
    /**
     * 离线推送设置 VIVO 推送消息类别，详见：https://dev.vivo.com.cn/documentCenter/doc/359
     *
     * VIVO 推送服务于 2023 年 4 月 3 日优化消息分类规则，推荐使用 AndroidVIVOCategory 设置消息类别，
     * 不需要再关注和设置 AndroidVIVOClassification
     */
    AndroidVIVOCategory?: string;
    /**
     * 离线推送设置华为推送消息分类
     * 详情：https://developer.huawei.com/consumer/cn/doc/development/HMSCore-Guides/message-interfaceification-0000001149358835
     */
    AndroidHuaWeiCategory?: string;
    /**
     * 离线推送设置 OPPO 推送消息分类，详见：https://open.oppomobile.com/new/developmentDoc/info?id=13189
     *
     * @param category OPPO 推送消息分类
     *                 1、通讯与服务类型有："IM"，"ACCOUNT"等
     *                 2、内容与营销类型有："NEWS"，"CONTENT"等
     *
     */
    AndroidOPPOCategory?: String;
    /**
     * 离线推送设置 OPPO 推送通知栏消息提醒等级，详见：https://open.oppomobile.com/new/developmentDoc/info?id=13189
     *
     * @note 使用生效前，需要先 setAndroidOPPOCategory 指定 category 为 IM 类消息
     *
     * @param level OPPO 通知栏消息提醒等级
     *              1 通知栏
     *              2 通知栏 + 锁屏 （默认）
     *              16 通知栏 + 锁屏 + 横幅 + 震动 + 铃声
     */
    AndroidOPPONotifyLevel?: number;
    /**
     * 离线推送设置 Honor 推送消息分类，详见：https://developer.honor.com/cn/docs/11002/guides/notification-class
     *
     * @param importance Honor 推送消息分类
     *                 "NORMAL", 表示消息为服务通讯类
     *                 "LOW", 表示消息为资讯营销类
     */
    AndroidHonorImportance?: String;
    /**
     * 离线推送设置魅族推送消息分类，详见：https://open.flyme.cn/docs?id=329
     *
     * @note  魅族推送平台⽇常巡查消息分类的接⼊情况，如发现推送内容不符合要求的，将进⾏违规处置
     *
     * @param type 魅族推送消息分类
     *                 0、公信消息：⽤⼾对收到此类消息⽆预期，关注程度较低。
     *                 1、私信消息：⽤⼾预期收到的，与⽤⼾关联较强的消息。
     */
    AndroidMeizuNotifyType?: number;
    /**
     * 设置华为设备离线推送的通知图片
     * imageUrl 使用的协议必须是 HTTPS 协议，取值样例：https://example.com/image.png
     * 图片文件须小于 512KB，规格建议为 40dp x 40dp，弧角大小为 8dp。超出建议规格的图片会存在图片压缩或图片显示不全的情况。图片格式建议使用 JPG/JPEG/PNG。
     */
    AndroidHuaWeiImage?: string;
    /**
     * 设置荣耀设备离线推送的通知图片
     * imageUrl 使用的协议必须是 HTTPS 协议，取值样例：https://example.com/image.png
     * 图标文件大小须小于 100KB，图标建议规格大小：160px x 160px，弧角大小为 32px，超出规格大小的图标会存在图片压缩或显示不全的情况。
     */
    AndroidHonorImage?: string;
    /**
     * 设置 Google FCM 设备离线推送的通知图片，未展开消息时显示为大图标，展开消息后展示为大图片
     * imageUrl 使用的协议必须是 HTTPS 协议，取值样例：https://example.com/image.png
     * 图标文件大小须小于 1 MB，超出规格大小的图标会存在图片压缩或显示不全的情况。
     */
    AndroidFCMImage?: string;
    /**
     * 设置 APNs 离线推送的通知图片, 借助 iOS 10 Service Extension 特性，可以下载并展示在弹窗上.
     * iOSImage 使用的协议必须是 HTTPS 协议，取值样例：https://example.com/image.png
     * 限制说明：
     * - 图片：支持 JPEG、GIF、PNG，大小不超过 10 MB
     * 使用说明：
     * - 需要在 IM 控制台打开 mutable-content 属性，支持 iOS 10 Service Extension 特性
     * - 获取 iOSImage 资源的 key 值是 "image"
     */
    iOSImage?: string;
    /**
     * 设置鸿蒙设备离线推送通知右侧大图标的 URL
     *
     * URL 协议：HTTPS，例如：https://example.com/image.png
     * 图片格式：png、jpg、jpeg、heif、gif、bmp
     * 图片大小：长 * 宽 < 25000 像素
     */
    HarmonyImage?: string;
    /**
     * 设置鸿蒙设备离线推送通知消息类别。完成自分类权益申请后，用于标识通知消息类型，不同的通知消息类型影响消息展示和提醒方式
     */
    HarmonyCategory?: string;
    /**
     * 离线推送忽略 badge 计数（仅对 HarmonyOS 生效）
     * 如果设置为 true，在 HarmonyOS 接收端，这条消息不会使 APP 的应用图标未读计数增加
     */
    ignoreHarmonyBadge?: boolean;
    /**
     * 设置离线推送扩展特性
     *
     * @param vendorParams 支持的字段详见：https://cloud.tencent.com/document/product/269/121188
     *
     * @note example of vendorParams:
     *   {
     *     "fcmPriority": "high",
     *     "vivoNotifyType": 4,
     *     "oppoTemplateId": "id",
     *     "oppoTitleParam": {
     *         "title": "title"
     *      },
     *     "oppoContentParam": {
     *         "content": "content"
     *      }
     *   }
     */
    vendorParams?: string;
}
/**
 * 高级消息
 */
export declare class V2TIMMessage {
    /**
     * 消息 ID（消息创建的时候为空，消息发送的时候会生成）
     */
    msgID: string;
    /**
     * 消息的 UTC 时间戳
     */
    timestamp: number;
    /**
     * 消息发送者
     */
    sender: string;
    /**
     * 消息发送者昵称
     */
    nickName: string;
    /**
     * 消息发送者好友备注
     */
    friendRemark: string;
    /**
     * 如果是群组消息，nameCard 为发送者的群名片
     */
    nameCard: string;
    /**
     * 消息发送者头像
     * 在 C2C 场景下，陌生人的头像不会实时更新，如需更新陌生人的头像（如在 UI
     * 上点击陌生人头像以展示陌生人信息时）， 请调用 V2TIMManager.h -> GetUsersInfo
     * 接口触发信息的拉取。待拉取成功后，SDK 会更新本地头像信息，即 faceURL 字段的内容。
     * @note 请不要在收到每条消息后都去 GetUsersInfo，会严重影响程序性能。
     */
    faceURL: string;
    /**
     * 如果是群组消息，groupID 为会话群组 ID，否则为空
     */
    groupID?: string;
    /**
     * 如果是单聊消息，userID 为会话用户 ID，否则为空，
     * 假设自己和 userA 聊天，无论是自己发给 userA 的消息还是 userA 发给自己的消息，这里的 userID
     * 均为 userA
     */
    userID?: string;
    /**
     * 群聊中的消息序列号云端生成，在群里是严格递增且唯一的,
     * 单聊中的序列号是本地生成，不能保证严格递增且唯一。
     */
    seq: number;
    /**
     * 消息随机码
     */
    random: number;
    /**
     * 消息发送状态
     */
    status: V2TIMMessageStatus;
    /**
     * 是否支持消息扩展（6.7 及其以上版本支持，需要您购买旗舰版套餐）
     * 社群（Community）和直播群（AVChatRoom）消息不支持该功能。
     * 您需要先到 IM 控制台配置该功能。
     */
    supportMessageExtension: boolean;
    /**
     * 消息发送者是否是自己
     */
    isSelf: boolean;
    /**
     * 消息自己是否已读
     */
    isRead(): boolean;
    /**
     * 消息对方是否已读（只有 C2C 消息有效）
     * 该字段为 true 的条件是消息 timestamp <= 对端标记会话已读的时间
     */
    isPeerRead(): boolean;
    /**
     * 消息是否需要已读回执
     * @note
     *  群聊消息 6.1 及以上版本支持该特性，需要您先到 IM 控制台配置支持已读回执的群类型。
     *  单聊消息 6.2 及以上版本支持该特性。
     *  群聊消息和单聊消息都需要购买旗舰版套餐包。
     */
    needReadReceipt: boolean;
    /**
     * 是否是广播消息，仅直播群支持（6.5 及以上版本支持，需要您购买旗舰版套餐）
     */
    isBroadcastMessage: boolean;
    /**
     * 消息优先级（只有 onRecvNewMessage 收到的 V2TIMMessage 获取有效）
     */
    priority: V2TIMMessagePriority;
    /**
     * 群消息中被 @ 的用户 UserID 列表（即该消息都 @ 了哪些人）
     */
    groupAtUserList: string[];
    /**
     * 消息元素类型
     */
    elemType: V2TIMElemType;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_TEXT，textElem 会存储文本消息内容
     */
    textElem?: V2TIMTextElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_CUSTOM，customElem 会存储自定义消息内容
     */
    customElem?: V2TIMCustomElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_IMAGE，imageElem 会存储图片消息内容
     */
    imageElem?: V2TIMImageElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_SOUND，soundElem 会存储语音消息内容
     */
    soundElem?: V2TIMSoundElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_VIDEO，videoElem 会存储视频消息内容
     */
    videoElem?: V2TIMVideoElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_FILE，fileElem 会存储文件消息内容
     */
    fileElem?: V2TIMFileElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_LOCATION，locationElem 会存储地理位置消息内容
     */
    locationElem?: V2TIMLocationElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_FACE，faceElem 会存储表情消息内容
     */
    faceElem?: V2TIMFaceElem;
    /**
     * 消息类型 为 V2TIM_ELEM_TYPE_MERGER，mergerElem 会存储转发消息内容
     */
    mergerElem?: V2TIMMergerElem;
    /**
     *  消息类型 为 V2TIM_ELEM_TYPE_GROUP_TIPS，groupTipsElem 会存储群 tips 消息内容
     */
    groupTipsElem?: V2TIMGroupTipsElem;
    /**
     *  消息类型 为 V2TIM_ELEM_TYPE_STREAM，streamElem 会存储流式消息内容
     */
    streamElem?: V2TIMStreamElem;
    /**
     * 获取消息自定义数据（本地保存，不会发送到对端，程序卸载重装后失效）
     */
    getLocalCustomData(): ArrayBuffer;
    /**
     * 设置消息自定义数据（本地保存，不会发送到对端，程序卸载重装后失效）
     */
    setLocalCustomData(localCustomData: ArrayBuffer): Promise<void>;
    /**
     * 获取消息自定义数据,可以用来标记语音、视频消息是否已经播放（本地保存，不会发送到对端，程序卸载重装后失效）
     */
    getLocalCustomInt(): number;
    /**
     * 设置消息自定义数据,可以用来标记语音、视频消息是否已经播放（本地保存，不会发送到对端，程序卸载重装后失效）
     */
    setLocalCustomInt(localCustomInt: number): Promise<void>;
    /**
     * 消息自定义数据（云端保存，会发送到对端，程序卸载重装后还能拉取到）
     */
    cloudCustomData: ArrayBuffer;
    /**
     * 消息是否不计入会话未读数：默认为 false，表明需要计入会话未读数，设置为
     * true，表明不需要计入会话未读数
     *  5.3.425 及以上版本支持, 会议群（Meeting）默认不支持该字段
     */
    isExcludedFromUnreadCount: boolean;
    /**
     * 消息是否不计入会话 lastMsg：默认为 false，表明需要计入会话 lastMsg，设置为
     * true，表明不需要计入会话 lastMsg
     */
    isExcludedFromLastMessage: boolean;
    /**
     * 消息自定义审核配置 ID（从 7.8 版本开始支持）
     * 在开通【云端审核】功能后，您可以请前往 [控制台](https://console.cloud.tencent.com/im) (云端审核 -> 审核配置 -> 自定义配置 -> 添加自定义配置) 获取配置 ID。
     *【自定义审核】配置流程请参考 [云端审核功能]（https://cloud.tencent.com/document/product/269/78633#a5efc9e8-a7ec-40e3-9b18-8ed1910f589c）
     * @note 该字段需要发消息前设置，仅用于控制发消息时的消息审核策略，其值不会存储在漫游和本地。
     */
    customModerationConfigurationID: String;
    /**
     * 消息是否不过内容审核（【云端审核】）
     * 只有在开通【云端审核】功能后，isExcludedFromContentModeration 设置才有效，设置为 true，表明不过内容审核，设置为 false：表明过内容审核。
     * 【云端审核】开通流程请参考 [云端审核功能](https://cloud.tencent.com/document/product/269/83795#.E4.BA.91.E7.AB.AF.E5.AE.A1.E6.A0.B8.E5.8A.9F.E8.83.BD)
     */
    isExcludedFromContentModeration: boolean;
    /**
     * 是否被标记为有安全风险的消息（从 7.4 版本开始支持）
     * 暂时只支持图片和视频消息。
     * 只有在开通【云端审核】功能后才生效，【云端审核】开通流程请参考 [云端审核功能](https://cloud.tencent.com/document/product/269/83795#.E4.BA.91.E7.AB.AF.E5.AE.A1.E6.A0.B8.E5.8A.9F.E8.83.BD)。
     * 如果您发送的图片或视频消息内容不合规，云端异步审核后会触发 SDK 的 onRecvMessageModified 回调，回调里的 message 对象该字段值为 true。
     */
    isIdentifiedAsRiskMessage: boolean;
    /**
     * 如果您发送的语音或视频消息内容不合规，云端异步审核后会触发 SDK 的 onRecvMessageModified 回调，回调里的 message 对象该字段值为 true。
     */
    hasRiskContent?: boolean;
    /**
     * 是否禁用消息发送前云端回调（从 8.1 版本开始支持）
     */
    disableCloudMessagePreHook?: Boolean;
    /**
     * 是否禁用消息发送后云端回调（从 8.1 版本开始支持）
     */
    disableCloudMessagePostHook?: Boolean;
    /**
     * 消息的离线推送信息
     */
    offlinePushInfo?: V2TIMOfflinePushInfo;
    /**
     * 消息撤回者（从 7.4 版本开始支持）
     * 仅当消息为撤回状态时有效
     */
    revokerInfo?: V2TIMUserFullInfo;
    /**
     * 消息撤回原因 （从 7.4 版本开始支持）
     * 仅当消息为撤回状态时有效
     */
    revokeReason?: string;
    /**
     * 消息置顶者 （从 8.0 版本开始支持）
     * 只有通过 GetPinnedGroupMessageList 获取到的置顶消息才包含该字段
     */
    pinnerInfo?: V2TIMGroupMemberFullInfo;
    /**
     * 消息引用信息
     */
    quoteInfo?: V2TIMMessageQuoteInfo;
}
/**
 * 消息元素基类
 */
export declare class V2TIMElem {
    /**
     * 下一个消息元素
     */
    nextElem?: V2TIMElem;
}
/**
 * 文本消息 V2TIMElem
 */
export declare class V2TIMTextElem extends V2TIMElem {
    /**
     * 消息文本
     */
    text: string;
}
/**
 * 自定义消息 V2TIMElem
 */
export declare class V2TIMCustomElem extends V2TIMElem {
    /**
     * 自定义消息二进制数据
     */
    data: ArrayBuffer;
    /**
     * 自定义消息描述信息
     */
    desc: string;
    /**
     * 自定义消息扩展字段
     */
    extension: string;
}
/**
 * 图片消息 V2TIMElem
 */
/**
 * 图片元素
 */
export declare class V2TIMImage {
    /**
     * 图片 ID，内部标识，可用于外部缓存 key
     */
    uuid: string;
    /**
     * 图片类型
     */
    type: V2TIMImageType;
    /**
     * 图片大小（type == V2TIM_IMAGE_TYPE_ORIGIN 有效）
     */
    size: number;
    /**
     * 图片宽度
     */
    width: number;
    /**
     * 图片高度
     */
    height: number;
    /**
     * 图片 url
     */
    url: string;
    /**
     * 下载图片
     *
     * 下载的数据需要由开发者缓存，IM SDK 每次调用 DownloadImage
     * 都会从服务端重新下载数据。建议通过图片的 uuid 作为 key 进行图片文件的存储。
     *
     * @param path 图片保存路径，必须在应用目录下，例如 getContext().cacheDir
     */
    downloadImage(path: string, callback?: V2TIMDownloadCallback): Promise<void>;
}
/**
 * 图片消息Elem
 */
export declare class V2TIMImageElem extends V2TIMElem {
    /**
     * 图片路径（只有发送方可以获取到）
     */
    path: string;
    /**
     * 接收图片消息的时候这个字段会保存图片的所有规格，目前最多包含三种规格：原图、大图、缩略图，每种规格保存在一个
     * TIMImage 对象中
     */
    imageList: V2TIMImage[];
}
/**
 * 语音消息 V2TIMElem
 */
export declare class V2TIMSoundElem extends V2TIMElem {
    /**
     * 语音文件路径（只有发送方才能获取到）
     */
    path: string;
    /**
     * 语音消息内部 ID
     */
    uuid: string;
    /**
     * 语音数据大小
     */
    dataSize: number;
    /**
     * 语音长度（秒）
     */
    duration: number;
    /**
     * 获取语音的 URL 下载地址
     */
    getUrl(): Promise<string>;
    /**
     * 下载语音
     *
     * DownloadSound 接口每次都会从服务端下载，如需缓存或者存储，开发者可根据 uuid 作为 key
     * 进行外部存储，ImSDK 并不会存储资源文件。
     *
     * @param path 语音保存路径，必须在应用目录下，例如 getContext().cacheDir
     */
    downloadSound(path: string, callback?: V2TIMDownloadCallback): Promise<void>;
    /**
     *  将语音转成文字（7.4 及以上版本支持）
     *
     *  @param language 识别的语言。
     *
     *  @note
     *  - 语音转文字是增值付费功能，处于内测阶段，您可通过 [即时通信 IM 语音转文字插件交流群](https://zhiliao.qq.com/s/c5GY7HIM62CK/cPSYGIIM62CH) 联系我们为您开通体验完整功能。
     */
    convertVoiceToText(language: string): Promise<string>;
}
/**
 * 视频消息 V2TIMElem
 */
export declare class V2TIMVideoElem extends V2TIMElem {
    /**
     * 视频文件路径（只有发送方才能获取到）
     */
    videoPath: string;
    /**
     * 截图文件路径（只有发送方才能获取到）
     */
    snapshotPath: string;
    /**
     * 视频 ID,内部标识，可用于外部缓存 key
     */
    videoUUID: string;
    /**
     * 视频大小
     */
    videoSize: number;
    /**
     * 视频类型
     */
    videoType: string;
    /**
     * 视频时长
     */
    duration: number;
    /**
     * 截图 ID,内部标识，可用于外部缓存 key
     */
    snapshotUUID: string;
    /**
     * 截图 size
     */
    snapshotSize: number;
    /**
     * 截图宽
     */
    snapshotWidth: number;
    /**
     * 截图高
     */
    snapshotHeight: number;
    /**
     * 获取视频的 URL 下载地址
     */
    getVideoUrl(): Promise<string>;
    /**
     * 获取截图的 URL 下载地址
     */
    getSnapshotUrl(): Promise<string>;
    /**
     * 下载视频
     *
     * DownloadVideo 接口每次都会从服务端下载，如需缓存或者存储，开发者可根据 uuid 作为 key
     * 进行外部存储，ImSDK 并不会存储资源文件。
     *
     * @param path 视频保存路径，必须在应用目录下，例如 getContext().cacheDir
     */
    downloadVideo(path: string, callback?: V2TIMDownloadCallback): Promise<void>;
    /**
     * 下载视频截图
     *
     * DownloadSnapshot 接口每次都会从服务端下载，如需缓存或者存储，开发者可根据 uuid 作为 key
     * 进行外部存储，ImSDK 并不会存储资源文件。
     *
     * @param path 截图保存路径，必须在应用目录下，例如 getContext().cacheDir
     */
    downloadSnapshot(path: string, callback?: V2TIMDownloadCallback): Promise<void>;
}
/**
 * 文件消息 V2TIMElem
 */
export declare class V2TIMFileElem extends V2TIMElem {
    /**
     * 文件路径（只有发送方才能获取到）
     */
    path: string;
    /**
     * 文件 ID,内部标识，可用于外部缓存 key
     */
    uuid: string;
    /**
     * 文件显示名称
     */
    filename: string;
    /**
     * 文件大小
     */
    fileSize: number;
    /**
     * 获取文件的 URL 下载地址
     */
    getUrl(): Promise<string>;
    /**
     * 下载文件
     *
     * DownloadFile 接口每次都会从服务端下载，如需缓存或者存储，开发者可根据 uuid 作为 key
     * 进行外部存储，ImSDK 并不会存储资源文件。
     *
     * @param path 文件保存路径，必须在应用目录下，例如 getContext().cacheDir
     */
    downloadFile(path: string, callback?: V2TIMDownloadCallback): Promise<void>;
}
/**
 * 地理位置 V2TIMElem
 */
export declare class V2TIMLocationElem extends V2TIMElem {
    /**
     * 地理位置描述信息
     */
    desc: string;
    /**
     * 经度，发送消息时设置
     */
    longitude: number;
    /**
     * 纬度，发送消息时设置
     */
    latitude: number;
}
/**
 * 表情消息 V2TIMElem
 */
export declare class V2TIMFaceElem extends V2TIMElem {
    /**
     * 表情索引，用户自定义
     * 1. 表情消息由 TIMFaceElem 定义，SDK 并不提供表情包，如果开发者有表情包，可使用 index
     * 存储表情在表情包中的索引，由用户自定义，或者直接使用 data 存储表情二进制信息以及字符串
     * key，都由用户自定义，SDK 内部只做透传。
     * 2. index 和 data 只需要传入一个即可，ImSDK 只是透传这两个数据。
     */
    index: number;
    /**
     * 额外数据，用户自定义
     */
    data: ArrayBuffer;
}
/**
 * 合并消息 V2TIMElem
 */
export declare class V2TIMMergerElem extends V2TIMElem {
    /**
     * 合并消息里面又包含合并消息我们称之为合并嵌套，合并嵌套层数不能超过 100 层，
     * 如果超过限制，layersOverLimit 为 true，title 和 abstractList 为空，DownloadMergerMessage
     * 会返回 ERR_MERGER_MSG_LAYERS_OVER_LIMIT 错误码。
     */
    layersOverLimit: boolean;
    /**
     * 合并消息 title
     */
    title: string;
    /**
     * 合并消息摘要列表
     */
    abstractList: string[];
    /**
     * 下载被合并的消息列表
     */
    downloadMergerMessage(): Promise<V2TIMMessage[]>;
}
/**
 * 群 Tips 消息 V2TIMElem
 */
/**
 * 群 tips 消息会存消息列表，群里所有的人都会展示，比如 xxx 进群，xxx 退群，xxx 群资料被修改了等
 */
export declare class V2TIMGroupTipsElem extends V2TIMElem {
    /**
     * 群组 ID
     */
    groupID: string;
    /**
     * 群Tips类型
     */
    type: V2TIMGroupTipsType;
    /**
     * 操作者群成员资料
     */
    opMember: V2TIMGroupMemberInfo;
    /**
     * 被操作人列表
     */
    memberList: V2TIMGroupMemberInfo[];
    /**
     * 群信息变更（type = V2TIM_GROUP_TIPS_TYPE_INFO_CHANGE 时有效）
     */
    groupChangeInfoList: V2TIMGroupChangeInfo[];
    /**
     * 成员变更（type = V2TIM_GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE 时有效）
     */
    memberChangeInfoList: V2TIMGroupMemberChangeInfo[];
    /**
     * 当前群人数（type =
     * V2TIM_GROUP_TIPS_TYPE_INVITE、TIM_GROUP_TIPS_TYPE_QUIT_GRP、TIM_GROUP_TIPS_TYPE_KICKED
     * 时有效）
     */
    memberCount: number;
}
/**
 * 流式消息 Elem
 */
export declare class V2TIMStreamElem extends V2TIMElem {
    /**
     * 流式消息 ID
     */
    streamID: string;
    /**
     * 流式消息 markdown 内容
     */
    markdown: string;
    /**
     * 流式消息二进制数据
     */
    data: ArrayBuffer;
    /**
     * 流式消息是否结束
     */
    isStreamEnded: boolean;
}
/**
 * TTS 声音格式（发起 startTTS 时由业务指定）
 */
export declare class V2TIMTTSVoiceFormat {
    /**
     * 声音 ID（由业务方与服务器约定，SDK 不做解析）
     */
    voiceID: string;
    /**
     * 语速，取值建议 0.5 ~ 2.0，默认 1.0
     */
    speed: number;
}
/**
 * TTS 流式响应
 *
 * - SDK 会按协议推送顺序回调 onRecvTTSResponse；一次回调可包含一到多个音频分片。
 * - 业务方需严格按 audioDataList 的顺序拼接播放，不要按时间戳重排。
 * - 当 isFinished = true 时表示该 msgID 的 TTS 任务收到终态分片，SDK 会清理该任务的本地映射。
 * - 调用 stopTTS 为连接级关闭：SDK 不承诺为本地清理的其它活跃任务补发 isFinished = true。
 */
export declare class V2TIMTTSResponse {
    /**
     * 文本消息 msgID（与 startTTS 传入的 msgID 一致）
     */
    msgID: string;
    /**
     * 本次回调携带的音频分片数据；按顺序拼接即可得到一段连续音频
     */
    audioDataList: ArrayBuffer[];
    /**
     * 当前分片是否为该任务的最后一帧
     */
    isFinished: boolean;
}
/**
 * 已读回执
 */
/**
 * 消息已读回执
 */
export declare class V2TIMMessageReceipt {
    /**
     * 消息 ID
     */
    msgID: string;
    /**
     * C2C 消息接收对象
     */
    userID: string;
    /**
     * C2C 对端消息是否已读
     */
    isPeerRead: boolean;
    /**
     * C2C 对端已读的时间
     * 如果 msgID 为空，该字段表示对端用户标记会话已读的时间
     * 如果 msgID 不为空，该字段表示对端用户发送消息已读回执的时间（8.1 及以上版本支持）
     */
    timestamp: number;
    /**
     * 群 ID
     */
    groupID: string;
    /**
     * 群消息已读人数
     */
    readCount: number;
    /**
     * 群消息未读人数
     */
    unreadCount: number;
}
/**
 * Group 消息已读群成员信息
 */
export declare class V2TIMGroupMessageReadMemberList {
    /**
     * 获取下一次分页拉取的游标
     */
    nextSeq: number;
    /**
     * 会话列表是否已经拉取完毕
     */
    isFinished: boolean;
    /**
     * 群消息已读或未读的群成员列表
     */
    members: V2TIMGroupMemberInfo[];
}
/**
 * 用户消息接收选项
 */
export declare class V2TIMReceiveMessageOptInfo {
    /**
     * 用户 ID
     */
    userID: string;
    /**
     * 消息接收选项
     */
    receiveOpt: V2TIMReceiveMessageOpt;
    /**
     * 获取消息免打扰开始时间：小时
     */
    startHour: number;
    /**
     * 获取消息免打扰开始时间：分钟
     */
    startMinute: number;
    /**
     * 获取消息免打扰开始时间：秒
     */
    startSecond: number;
    /**
     *  获取消息免打扰开始的 UTC 时间戳
     *  @note
     *  - 如果返回的 startTimeStamp 大于 0，您可以直接使用
     *  - 如果返回的 startTimeStamp 等于 0，您需要调用 getStartHour()、getStartMinute()、getStartSecond() 来获取免打扰的相对开始时间
     */
    startTimeStamp: number;
    /**
     * 获取免打扰持续时长，单位：秒
     */
    duration: number;
}
/**
 * 消息搜索
 */
/**
 * 消息搜索参数
 */
export interface V2TIMMessageSearchParam {
    /**
     * 关键字列表，最多支持5个。当消息发送者以及消息类型均未指定时，关键字列表必须非空；否则，关键字列表可以为空。
     */
    keywordList: string[];
    /**
     * 指定关键字列表匹配类型，可设置为“或”关系搜索或者“与”关系搜索.
     * 取值分别为 V2TIM_KEYWORD_LIST_MATCH_TYPE_OR 和
     * V2TIM_KEYWORD_LIST_MATCH_TYPE_AND，默认为“或”关系搜索。
     */
    keywordListMatchType: V2TIMKeywordListMatchType;
    /**
     * 指定 userID 发送的消息，最多支持5个。
     */
    senderUserIDList: string[];
    /**
     * 指定搜索的消息类型集合，传入空数组表示搜索支持的全部类型消息（V2TIMFaceElem 和
     * V2TIMGroupTipsElem 不支持）取值详见 @V2TIMElemType。
     */
    messageTypeList: V2TIMElemType[];
    /**
     * 搜索“全部会话”还是搜索“指定的会话”：
     *  如果设置 conversationID == nil，代表搜索全部会话。
     *  如果设置 conversationID != nil，代表搜索指定会话。会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"：群聊组成方式为: "group_groupID"
     */
    conversationID: string;
    /**
     * 搜索的起始时间点。默认为0即代表从现在开始搜索。UTC 时间戳，单位：秒
     */
    searchTimePosition: number;
    /**
     * 从起始时间点开始的过去时间范围，单位秒。默认为0即代表不限制时间范围，传24x60x60代表过去一天。
     */
    searchTimePeriod: number;
    /**
     * 分页的页号：用于分页展示查找结果，从零开始起步。
     * 比如：您希望每页展示 10 条结果，请按照如下规则调用：
     * - 首次调用：通过参数 pageSize = 10, pageIndex = 0 调用 searchLocalMessage，从结果回调中的
     * totalCount 可以获知总共有多少条结果。
     * - 计算页数：可以获知总页数：totalPage = (totalCount % pageSize == 0)  (totalCount /
     * pageSize) : (totalCount / pageSize + 1) 。
     * - 再次调用：可以通过指定参数 pageIndex （pageIndex < totalPage）返回后续页号的结果。
     *
     * @note 仅对接口 searchLocalMessages 生效
     */
    pageIndex: number;
    /**
     * 每页结果数量：用于分页展示查找结果，如不希望分页可将其设置成
     * 0，但如果结果太多，可能会带来性能问题。
     * @note 仅对接口 searchLocalMessages 生效
     */
    pageSize: number;
    /**
     * 每次云端搜索返回结果的条数。
     * @note 仅对接口 searchCloudMessages 生效
     */
    searchCount: number;
    /**
     * 每次云端搜索的起始位置。第一次填空字符串，续拉时填写 V2TIMMessageSearchResult 中的返回值。
     * @note 仅对接口 searchCloudMessages 生效
     */
    searchCursor: string;
}
export declare class V2TIMMessageSearchResultItem {
    /**
     * 会话ID
     */
    conversationID: string;
    /**
     * 当前会话一共搜索到了多少条符合要求的消息
     */
    messageCount: number;
    /**
     * 满足搜索条件的消息列表
     * 如果您本次搜索【指定会话】，那么 messageList 中装载的是本会话中所有满足搜索条件的消息列表。
     * 如果您本次搜索【全部会话】，那么 messageList 中装载的消息条数会有如下两种可能：
     *
     * - 如果某个会话中匹配到的消息条数 > 1，则 messageList 为空，您可以在 UI 上显示“ messageCount
     * 条相关记录”。
     * - 如果某个会话中匹配到的消息条数 = 1，则 messageList 为匹配到的那条消息，您可以在 UI
     * 上显示之，并高亮匹配关键词。
     */
    messageList: V2TIMMessage[];
}
export declare class V2TIMMessageSearchResult {
    /**
     * 如果您本次搜索【指定会话】，那么返回满足搜索条件的消息总数量；
     * 如果您本次搜索【全部会话】，那么返回满足搜索条件的消息所在的所有会话总数量。
     */
    totalCount: number;
    /**
     * 如果您本次搜索【指定会话】，那么返回结果列表只包含该会话结果；
     * 如果您本次搜索【全部会话】，那么对满足搜索条件的消息根据会话 ID 分组，分页返回分组结果；
     */
    messageSearchResultItems: V2TIMMessageSearchResultItem[];
    /**
     * 下一次云端搜索的起始位置。
     */
    searchCursor: string;
}
/**
 * 消息拉取
 */
export interface V2TIMMessageListGetOption {
    /**
     * 拉取消息类型，可以设置拉取本地、云端更老或者更新的消息
     *
     * @note 请注意
     * 当设置从云端拉取时，会将本地存储消息列表与云端存储消息列表合并后返回。如果无网络，则直接返回本地消息列表。
     * 关于 getType、拉取消息的起始消息、拉取消息的时间范围 的使用说明：
     * - getType 可以用来表示拉取的方向：往消息时间更老的方向 或者 往消息时间更新的方向；
     * - lastMsg/lastMsgSeq 用来表示拉取时的起点，第一次拉取时可以不填或者填 0；
     * - getTimeBegin/getTimePeriod
     * 用来表示拉取消息的时间范围，时间范围的起止时间点与拉取方向(getType)有关；
     * - 当起始消息和时间范围都存在时，结果集可理解成：「单独按起始消息拉取的结果」与「单独按时间范围拉取的结果」
     * 取交集；
     * - 当起始消息和时间范围都不存在时，结果集可理解成：从当前会话最新的一条消息开始，按照 getType
     * 所指定的方向和拉取方式拉取。
     */
    getType: V2TIMMessageGetType;
    /**
     * 拉取消息数量
     */
    count: number;
    /**
     * 拉取单聊历史消息
     */
    userID?: string;
    /**
     * 拉取群组历史消息
     */
    groupID?: string;
    /**
     * 拉取的消息类型集合，getType 为 V2TIM_GET_LOCAL_OLDER_MSG 和 V2TIM_GET_LOCAL_NEWER_MSG 有效，传入空数组表示拉取全部类型消息，取值详见 @V2TIMElemType。
     */
    messageTypeList?: V2TIMElemType[];
    /**
     * 拉取消息的起始消息
     *
     * @note 请注意，
     * 拉取 C2C 消息，只能使用 lastMsg 作为消息的拉取起点；如果没有指定 lastMsg，默认使用会话的最新消息作为拉取起点。
     * 拉取 Group 消息时，除了可以使用 lastMsg 作为消息的拉取起点外，也可以使用 lastMsgSeq 来指定消息的拉取起点，二者的区别在于：
     * - 使用 lastMsg 作为消息的拉取起点时，返回的消息列表里不包含当前设置的 lastMsg；
     * - 使用 lastMsgSeq 作为消息拉取起点时，返回的消息列表里包含当前设置的 lastMsgSeq 所表示的消息。
     *
     * @note 在拉取 Group 消息时，
     * 如果同时指定了 lastMsg 和 lastMsgSeq，SDK 优先使用 lastMsg 作为消息的拉取起点。
     * 如果 lastMsg 和 lastMsgSeq 都未指定，消息的拉取起点分为如下两种情况：
     * -  如果设置了拉取的时间范围，SDK 会根据 @getTimeBegin 所描述的时间点作为拉取起点；
     * -  如果未设置拉取的时间范围，SDK 默认使用会话的最新消息作为拉取起点。
     */
    lastMsg?: V2TIMMessage;
    lastMsgSeq?: number;
    /**
     * 拉取消息的时间范围
     * @getTimeBegin  表示时间范围的起点；默认为 0，表示从现在开始拉取；UTC 时间戳，单位：秒
     * @getTimePeriod 表示时间范围的长度；默认为 0，表示不限制时间范围；单位：秒
     *
     * @note
     *  时间范围的方向由参数 getType 决定
     *  如果 getType 取 V2TIM_GET_CLOUD_OLDER_MSG/V2TIM_GET_LOCAL_OLDER_MSG，表示从 getTimeBegin 开始，过去的一段时间，时间长度由 getTimePeriod 决定
     *  如果 getType 取 V2TIM_GET_CLOUD_NEWER_MSG/V2TIM_GET_LOCAL_NEWER_MSG，表示从 getTimeBegin 开始，未来的一段时间，时间长度由 getTimePeriod 决定
     *  取值范围区间为闭区间，包含起止时间，二者关系如下：
     * - 如果 getType 指定了朝消息时间更老的方向拉取，则时间范围表示为 [getTimeBegin-getTimePeriod, getTimeBegin]
     * - 如果 getType 指定了朝消息时间更新的方向拉取，则时间范围表示为 [getTimeBegin, getTimeBegin+getTimePeriod]
     */
    getTimeBegin?: number;
    getTimePeriod?: number;
    /**
     * 拉取群组历史消息时，支持按照消息序列号 seq 拉取（从 7.1 版本开始有效）
     *
     * @note
     * - 仅拉取群组历史消息时有效；
     * - 消息序列号 seq 可以通过 V2TIMMessage 对象的 seq 字段获取；
     * - 当 getType 设置为从云端拉取时，会将本地存储消息列表与云端存储消息列表合并后返回；如果无网络，则直接返回本地消息列表；
     * - 当 getType 设置为从本地拉取时，直接返回本地的消息列表；
     * - 当 getType 设置为拉取更旧的消息时，消息列表按照时间逆序，也即消息按照时间戳从大往小的顺序排序；
     * - 当 getType 设置为拉取更新的消息时，消息列表按照时间顺序，也即消息按照时间戳从小往大的顺序排序。
     */
    messageSeqList?: number[];
}
/**
 * 消息拓展
 */
export declare class V2TIMMessageExtension {
    /**
     * 消息扩展信息 key
     */
    extensionKey: string;
    /**
     * 消息扩展信息 value
     */
    extensionValue: string;
}
/**
 * 消息扩展操作结果
 */
export declare class V2TIMMessageExtensionResult {
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 扩展信息
     */
    extension: V2TIMMessageExtension;
}
/**
 * 消息回应
 */
export declare class V2TIMMessageReaction {
    /**
     * 消息回应 ID
     */
    reactionID: string;
    totalUserCount: number;
    partialUserList: V2TIMUserInfo[];
    reactedByMyself: boolean;
}
/**
 * 消息回应列表拉取结果
 */
export declare class V2TIMMessageReactionResult {
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 返回信息
     */
    msgID: string;
    /**
     * 返回信息
     */
    reactionList: V2TIMMessageReaction[];
}
/**
 * 消息回应用户列表拉取结果
 */
export declare class V2TIMMessageReactionUserResult {
    /**
     * 用户列表
     */
    userInfoList: V2TIMUserInfo[];
    /**
     * 下次分页拉取 seq
     */
    nextSeq: number;
    /**
     * 是否全部拉取完毕
     */
    isFinished: boolean;
}
/**
 * 消息回应变更列表
 */
export declare class V2TIMMessageReactionChangeInfo {
    /**
     * 用户列表
     */
    msgID: string;
    /**
     * 用户列表
     */
    reactionList: V2TIMMessageReaction[];
}
/**
 * 消息变更结果
 */
export declare class V2TIMMessageModifyResult {
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 变更消息
     */
    message: V2TIMMessage;
}
