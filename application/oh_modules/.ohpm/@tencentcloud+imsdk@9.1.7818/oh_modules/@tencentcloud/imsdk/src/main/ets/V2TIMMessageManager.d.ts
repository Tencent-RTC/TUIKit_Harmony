/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMAdvancedMsgListener, V2TIMGroupMessageReadMemberList, V2TIMGroupMessageReadMembersFilter, V2TIMMessage, V2TIMMessageExtension, V2TIMMessageExtensionResult, V2TIMMessageListGetOption, V2TIMMessagePriority, V2TIMMessageReactionResult, V2TIMMessageReactionUserResult, V2TIMMessageReceipt, V2TIMMessageSearchParam, V2TIMMessageSearchResult, V2TIMOfflinePushInfo, V2TIMReceiveMessageOpt, V2TIMReceiveMessageOptInfo, V2TIMUploadCallback, V2TIMMessageModifyResult, V2TIMTTSVoiceFormat } from "../../../Index";
/**
 * 腾讯云通信服务 IMSDK
 *
 * 消息高级接口，里面包含了所有高级消息的创建、收发逻辑
 */
export declare class V2TIMMessageManager {
    /**
     * 监听 - 高级（图片、语音、视频等）消息
     */
    /**
     * 1.1 添加高级消息的事件监听器
     */
    addAdvancedMsgListener(listener: V2TIMAdvancedMsgListener): void;
    /**
     * 1.2 移除高级消息监听器
     */
    removeAdvancedMsgListener(listener: V2TIMAdvancedMsgListener): void;
    /**
     * 创建 - 高级（图片、语音、视频等）消息
     */
    /**
     * 2.1 创建文本消息
     */
    createTextMessage(text: string): V2TIMMessage;
    /**
     * 2.2 创建文本消息，并且可以附带 @ 提醒功能（该接口已弃用，推荐使用 CreateAtSignedGroupMessage 接口）
     *
     * 提醒消息仅适用于在群组中发送的消息
     *
     * @param atUserList 需要 @ 的用户列表，如果需要 @ALL，请传入 kImSDK_MesssageAtALL 常量字符串。
     * 举个例子，假设该条文本消息希望@提醒 denny 和 lucy 两个用户，同时又希望 @所有人，atUserList
     * 传 {"denny","lucy",kImSDK_MesssageAtALL}
     *
     * @note atUserList 使用注意事项
     * - 默认情况下，最多支持 @ 30个用户，超过限制后，消息会发送失败。
     * - atUserList 的总数不能超过默认最大数，包括 @ALL。
     * - 直播群（AVChatRoom）不支持发送 @ 消息。
     */
    createTextAtMessage(text: string, atUserList: string[]): V2TIMMessage | undefined;
    /**
     * 2.4 创建自定义消息
     *
     * @param description 自定义消息描述信息，做离线Push时文本展示。
     * @param extension 离线 Push 时扩展字段信息。
     */
    createCustomMessage(data: ArrayBuffer, option?: {
        description?: string;
        extension?: string;
    }): V2TIMMessage;
    /**
     * 2.5 创建图片消息（图片最大支持 28 MB）
     *
     * @param imagePath 图片路径
     *
     * @note 如果初始化时传入了 hap 的 context，图片必现在 hap 的 context.cacheDir 目录下，例如 getContext().cacheDir + "/image.jpg"
     *       如果初始化时传入了 app 的 context，图片必须在 app 的 context.cacheDir 目录下，例如 getContext().getApplicationContext().cacheDir + "/image.jpg"
     */
    createImageMessage(imagePath: string): V2TIMMessage;
    /**
     * 2.6 创建语音消息（语音最大支持 28 MB）
     *
     * @param soundPath 音频文件路径
     * @param duration  语音时长，单位 s
     *
     * @note 如果初始化时传入了 hap 的 context，音频文件必现在 hap 的 context.cacheDir 目录下，例如 getContext().cacheDir + "/sound.mp3"
     *       如果初始化时传入了 app 的 context，音频文件必须在 app 的 context.cacheDir 目录下，例如 getContext().getApplicationContext().cacheDir + "/sound.mp3"
     */
    createSoundMessage(soundPath: string, duration: number): V2TIMMessage;
    /**
     * 2.7 创建视频消息（视频最大支持 100 MB）
     *
     * @param videoFilePath 视频文件路径
     * @param type          视频类型，如 mp4 mov 等
     * @param duration      视频时长，单位 s
     * @param snapshotPath  视频封面图片路径
     *
     * @note 如果初始化时传入了 hap 的 context，视频文件必现在 hap 的 context.cacheDir 目录下，例如 getContext().cacheDir + "/video.mp4"
     *       如果初始化时传入了 app 的 context，视频文件必须在 app 的 context.cacheDir 目录下，例如 getContext().getApplicationContext().cacheDir + "/video.mp4"
     *
     * @note 如果初始化时传入了 hap 的 context，图片必现在 hap 的 context.cacheDir 目录下，例如 getContext().cacheDir + "/snapshot.jpg"
     *       如果初始化时传入了 app 的 context，图片必须在 app 的 context.cacheDir 目录下，例如 getContext().getApplicationContext().cacheDir + "/snapshot.jpg"
     */
    createVideoMessage(videoFilePath: string, type: string, duration: number, snapshotPath: string): V2TIMMessage;
    /**
     * 2.8 创建文件消息（文件最大支持 100 MB）
     *
     * @param videoFilePath 文件路径
     * @param fileName      文件名
     *
     * @note 如果初始化时传入了 hap 的 context，图片必现在 hap 的 context.cacheDir 目录下，例如 getContext().cacheDir + "/file.zip"
     *       如果初始化时传入了 app 的 context，图片必须在 app 的 context.cacheDir 目录下，例如 getContext().getApplicationContext().cacheDir + "/file.zip"
     */
    createFileMessage(filePath: string, fileName: string): V2TIMMessage;
    /**
     * 2.9 创建地理位置消息
     */
    createLocationMessage(desc: string, longitude: number, latitude: number): V2TIMMessage;
    /**
     * 2.10 创建表情消息
     *
     * SDK 并不提供表情包，如果开发者有表情包，可使用 index 存储表情在表情包中的索引，
     * 或者直接使用 data 存储表情二进制信息以及字符串 key，都由用户自定义，SDK 内部只做透传。
     *
     * @param index 表情索引
     * @param data  自定义数据
     */
    createFaceMessage(index: number, data: ArrayBuffer): V2TIMMessage;
    /**
     * 2.11 创建合并消息（5.2.210 及以上版本支持）
     *
     * <p> 我们在收到一条合并消息的时候，通常会在聊天界面这样显示：
     * <p> |vinson 和 lynx 的聊天记录                         |        -- title         （标题）
     * <p> |vinson：新版本 SDK 计划什么时候上线呢？             |        -- abstract1 （摘要信息1）
     * <p> |lynx：计划下周一，具体时间要看下这两天的系统测试情况..|        -- abstract2 （摘要信息2）
     * <p> |vinson：好的.                                     |        -- abstract3 （摘要信息3）
     * <p> 聊天界面通常只会展示合并消息的标题和摘要信息，完整的转发消息列表，需要用户主动点击转发消息 UI  后再获取。
     *
     * <p> 多条被转发的消息可以被创建成一条合并消息 V2TIMMessage，然后调用 SendMessage 接口发送，实现步骤如下：
     * <p> 1. 调用 CreateMergerMessage 创建一条合并消息 V2TIMMessage。
     * <p> 2. 调用 SendMessage 发送转发消息 V2TIMMessage。
     *
     * <p> 收到合并消息解析步骤：
     * <p> 1. 通过 V2TIMMessage 获取 mergerElem。
     * <p> 2. 通过 mergerElem 获取 title 和 abstractList UI 展示。
     * <p> 3. 当用户点击摘要信息 UI 的时候，调用 DownloadMessageList 接口获取转发消息列表。
     *
     *
     * @param messageList 消息列表（最大支持 300 条，消息对象必须是 V2TIM_MSG_STATUS_SEND_SUCC 状态，消息类型不能为 V2TIMGroupTipsElem）
     * @param title 合并消息的来源，比如 "vinson 和 lynx 的聊天记录"、"xxx 群聊的聊天记录"。
     * @param abstractList 合并消息的摘要列表(最大支持 5 条摘要，每条摘要的最大长度不超过 100 个字符),不同的消息类型可以设置不同的摘要信息，比如:
     * 文本消息可以设置为：sender：text，图片消息可以设置为：sender：[图片]，文件消息可以设置为：sender：[文件]。
     * @param compatibleText 合并消息兼容文本，低版本 SDK 如果不支持合并消息，默认会收到一条文本消息，文本消息的内容为 compatibleText，
     * 该参数不能为空字符串。
     */
    createMergerMessage(messageList: V2TIMMessage[], title: string, abstractList: string[], compatibleText: string): V2TIMMessage | undefined;
    /**
     * 2.12 创建转发消息（5.2.210 及以上版本支持）
     *
     * 如果需要转发一条消息，不能直接调用 SendMessage 接口发送原消息，需要先 CreateForwardMessage
     * 创建一条转发消息再发送。
     *
     * @param message 待转发的消息对象，消息状态必须为 V2TIM_MSG_STATUS_SEND_SUCC，消息类型不能为
     * V2TIMGroupTipsElem。
     * @return 转发消息对象，elem 内容和原消息完全一致。
     */
    createForwardMessage(message: V2TIMMessage): V2TIMMessage | undefined;
    /**
     * 2.13 创建定向群消息（6.0 及以上版本支持）
     *
     * 如果您需要在群内给指定群成员列表发消息，可以创建一条定向群消息，定向群消息只有指定群成员才能收到。
     *
     * @param message 原始消息对象
     * @param receiverList 消息接收者列表
     * @return 定向群消息对象
     *
     * @note
     * - 原始消息对象不支持群 @ 消息。
     * - 消息接收者列表最大支持 50 个。
     * - 直播群（AVChatRoom）不支持发送定向群消息。
     * - 定向群消息默认不计入群会话的未读计数。
     */
    createTargetedGroupMessage(message: V2TIMMessage, receiverList: string[]): V2TIMMessage | undefined;
    /**
     * 2.14 创建带 @ 标记的群消息（7.0 及以上版本支持）
     *
     * 如果您需要发送的群消息附带 @ 提醒功能，可以创建一条带 @ 标记的群消息。
     *
     * @param message 原始消息对象
     * @param atUserList 需要 @ 的用户列表，如果需要 @ALL，请传入 kImSDK_MesssageAtALL 常量字符串。
     * 举个例子，假设该条消息希望@提醒 denny 和 lucy 两个用户，同时又希望@所有人，atUserList 传 @[@"denny",@"lucy",kImSDK_MesssageAtALL]
     * @return 群 @ 消息对象
     *
     * @note atUserList 使用注意事项
     * - 默认情况下，最多支持 @ 30个用户，超过限制后，消息会发送失败。
     * - atUserList 的总数不能超过默认最大数，包括 @ALL。
     * - 直播群（AVChatRoom）不支持发送 @ 消息。
     */
    createAtSignedGroupMessage(message: V2TIMMessage, atUserList: string[]): V2TIMMessage | undefined;
    /**
     * 2.15 创建引用消息
     *
     * 如果您需要发送一条引用了其他消息的消息，可以调用该接口创建引用消息。
     *
     * @param message 原始消息对象，需要通过对应的 createXXXMessage 接口进行创建。
     * @param quotedMessage 被引用的消息对象
     * @return 引用消息对象，如果创建失败返回 undefined
     */
    createQuoteMessage(message: V2TIMMessage, quotedMessage: V2TIMMessage): V2TIMMessage | undefined;
    /**
     * 发送 - 高级（图片、语音、视频等）消息
     */
    /**
     * 3.1 发送高级消息（高级版本：可以指定优先级，推送信息等特性）
     *
     * @param message           待发送的消息对象，需要通过对应的 CreateXXXMessage 接口进行创建。
     * @param receiver          消息接收者的 userID, 如果是发送 C2C 单聊消息，只需要指定 receiver
     * 即可。
     * @param groupID           目标群组 ID，如果是发送群聊消息，只需要指定 groupID 即可。
     * @param priority
     * 消息优先级，仅针对群聊消息有效。请把重要消息设置为高优先级（比如红包、礼物消息），高频且不重要的消息设置为低优先级（比如点赞消息）。
     * @param onlineUserOnly    是否只有在线用户才能收到，如果设置为 true
     * ，接收方历史消息拉取不到，常被用于实现“对方正在输入”或群组里的非重要提示等弱提示功能，该字段不支持
     * AVChatRoom。
     * @param offlinePushInfo   离线推送时携带的标题和内容。
     * @return 消息唯一标识
     * @note
     * - 设置 offlinePushInfo 字段，需要先在 V2TIMOfflinePushManager
     * 开启推送，推送开启后，除了自定义消息，其他消息默认都会推送。
     * - 如果自定义消息也需要推送，请设置 offlinePushInfo 的 desc
     * 字段，设置成功后，推送的时候会默认展示 desc 信息。
     * - AVChatRoom 群聊不支持 onlineUserOnly 字段，如果是 AVChatRoom 请将该字段设置为 false。
     * - 如果设置 onlineUserOnly 为 true 时，该消息为在线消息且不会被计入未读计数。
     */
    sendMessage(message: V2TIMMessage, option?: {
        receiver?: string;
        groupID?: string;
        priority?: V2TIMMessagePriority;
        callback?: V2TIMUploadCallback;
        onlineUserOnly?: boolean;
        offlinePushInfo?: V2TIMOfflinePushInfo;
    }): {
        msgID: string;
        promise: Promise<V2TIMMessage>;
    };
    /**
     * 接收 - 设置消息的接口选项（接收|接收但不提醒|不接收）
     */
    /**
     * 4.1 设置针对某个用户的 C2C 消息接收选项（支持批量设置）
     * <p>5.3.425 及以上版本支持
     *
     * @note
     * - 该接口支持批量设置，您可以通过参数 userIDList 设置一批用户，但一次最大允许设置 30 个用户。
     * - 该接口调用频率被限制为1秒内最多调用5次。
     *
     *
     * @param opt    三种类型的消息接收选项：
     *              V2TIMMessage.V2TIM_RECEIVE_MESSAGE：在线正常接收消息，离线时会有厂商的离线推送通知
     *              V2TIMMessage.V2TIM_NOT_RECEIVE_MESSAGE：不会接收到消息
     *              V2TIMMessage.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE：在线正常接收消息，离线不会有推送通知
     *
     */
    setC2CReceiveMessageOpt(userIDList: string[], opt: V2TIMReceiveMessageOpt): Promise<void>;
    /**
     * 4.2 查询针对某个用户的 C2C 消息接收选项
     * <p>5.3.425 及以上版本支持
     */
    getC2CReceiveMessageOpt(userIDList: string[]): Promise<V2TIMReceiveMessageOptInfo[]>;
    /**
     * 4.3 设置群消息的接收选项
     *
     * @param opt    消息接收选项：
     *               V2TIMReceiveMessageOpt.V2TIM_RECEIVE_MESSAGE：在线正常接收消息，离线时会有厂商的离线推送通知
     *               V2TIMReceiveMessageOpt.V2TIM_NOT_RECEIVE_MESSAGE：不会接收到群消息
     *               V2TIMReceiveMessageOpt.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE：在线正常接收消息，离线不会有推送通知
     *               V2TIMReceiveMessageOpt.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT：在线正常接收消息，离线只推送 @ 消息
     *               V2TIMReceiveMessageOpt.V2TIM_NOT_RECEIVE_MESSAGE_EXCEPT_AT：在线和离线都只接收@消息
     */
    setGroupReceiveMessageOpt(groupID: string, opt: V2TIMReceiveMessageOpt): Promise<void>;
    /**
     * 4.4 设置全局消息接收选项，从 7.4 版本开始支持。
     *
     * @param opt 全局消息接收选项，支持两种取值：
     *              V2TIMReceiveMessageOpt.V2TIM_RECEIVE_MESSAGE：在线正常接收消息，离线时会有厂商的离线推送通知，默认为该选项
     *              V2TIMReceiveMessageOpt.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE：在线正常接收消息，离线不会有推送通知，可用于实现消息免打扰功能
     * @param startHour   免打扰开始时间：小时，取值范围[0 - 23]
     * @param startMinute 免打扰开始时间：分钟，取值范围[0 - 59]
     * @param startSecond 免打扰开始时间：秒，取值范围[0 - 59]
     * @param duration    免打扰持续时长：单位：秒，取值范围 [0 - 24*60*60].
     *
     * @note
     *  - 当 duration 的取值小于 24*60*60 时，可用于实现重复免打扰，即消息免打扰从每天的 startHour:startMinute:startSecond 表示的时间点开始，持续时长为 druation 秒
     *  - 当 duration 取值不小于 24*60*60 时，可用于实现永久免打扰，即从调用该 API 当天 startHour:startMinute:startSecond 表示的时间点开始永久消息免打扰
     */
    setAllReceiveMessageOpt(opt: V2TIMReceiveMessageOpt, startHour: number, startMinute: number, startSecond: number, duration: number): Promise<void>;
    /**
     * 4.5 设置全局消息接收选项，从 7.4 版本开始支持。
     *
     * @param opt 全局消息接收选项，支持两种取值：
     *              V2TIMReceiveMessageOpt.V2TIM_RECEIVE_MESSAGE：在线正常接收消息，离线时会有厂商的离线推送通知，默认为该选项
     *              V2TIMReceiveMessageOpt.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE：在线正常接收消息，离线不会有推送通知，可用于实现消息免打扰功能
     * @param startTimeStamp 免打扰开始时间，UTC 时间戳，单位：秒
     * @param duration       免打扰持续时长，单位：秒
     */
    setAllReceiveMessageOpt2(opt: V2TIMReceiveMessageOpt, startTimeStamp: number, duration: number): Promise<void>;
    /**
     *  4.5 获取登录用户全局消息接收选项，从 7.4 版本开始支持
     */
    getAllReceiveMessageOpt(): Promise<V2TIMReceiveMessageOptInfo>;
    /**
     * 获取历史消息、撤回、删除、标记已读等高级接口
     */
    /**
     * 5.1 获取历史消息高级接口
     *
     * @param option 拉取消息选项设置，可以设置从云端、本地拉取更老或更新的消息
     *
     * @note
     *  - 如果没有触发登录，调用该接口不会返回历史消息
     *  - 如果登录失败，调用该接口会返回本地历史消息
     *  - 如果 SDK 检测到没有网络，调用该接口会返回本地历史消息
     *  - 如果登录成功且网络正常，当 option 设置为拉取云端历史消息，调用该接口会先请求云端历史消息，然后再和本地历史消息合并后返回
     *  - 只有会议群（Meeting）才能拉取到进群前的历史消息，直播群（AVChatRoom）消息不存漫游和本地数据库，调用这个接口无效
     */
    getHistoryMessageList(option: V2TIMMessageListGetOption): Promise<V2TIMMessage[]>;
    /**
     * 5.2 撤回消息
     *
     * @note
     * - 撤回消息的时间限制默认 2 minutes，超过 2 minutes 的消息不能撤回，您也可以在 [控制台](https://console.cloud.tencent.com/im)（功能配置 -> 登录与消息 ->
     * 消息撤回设置）自定义撤回时间限制。
     * - 仅支持单聊和群组中发送的普通消息，无法撤销 onlineUserOnly 为 true 即仅在线用户才能收到的消息，也无法撤销直播群（AVChatRoom）中的消息。
     * - 如果发送方撤回消息，已经收到消息的一方会收到 V2TIMAdvancedMsgListener::OnRecvMessageRevoked 回调。
     * - 从 IMSDK 7.4 版本开始，支持撤回包括直播群（AVChatRoom）、社群在内的所有群类型的消息。
     * - 在单聊场景中，仅能撤回自己的消息；在群聊场景中，除了可以撤回自己的消息外，管理员或者群主也可以撤回其他群成员的消息。
     */
    revokeMessage(message: V2TIMMessage): Promise<void>;
    /**
     * 5.3 消息变更
     *
     * @note
     * - 如果消息修改成功，自己和对端用户（C2C）或群组成员（Group）都会收到 OnRecvMessageModified 回调。
     * - 如果在修改消息过程中，消息已经被其他人修改，callback 会返回 ERR_SDK_MSG_MODIFY_CONFLICT 错误。
     * - 消息无论修改成功或则失败，callback 都会返回最新的消息对象。
     */
    modifyMessage(message: V2TIMMessage): Promise<V2TIMMessageModifyResult>;
    /**
     *  5.4 删除本地消息
     *
     *  @note 该接口只能删除本地历史，消息删除后，SDK 会在本地把这条消息标记为已删除状态，getHistoryMessage 不能再拉取到，如果程序卸载重装，本地会失去对这条消息的删除标记，getHistoryMessage 还能再拉取到该条消息。
     */
    deleteMessageFromLocalStorage(message: V2TIMMessage): Promise<void>;
    /**
     * 5.5 删除本地及云端的消息
     *
     * @note 该接口会在 deleteMessageFromLocalStorage 的基础上，同步删除云端存储的消息，且无法恢复。需要注意的是：
     * - 一次最多只能删除 50 条消息
     * - 要删除的消息必须属于同一会话
     * - 一秒钟最多只能调用一次该接口
     * - 如果该账号在其他设备上拉取过这些消息，那么调用该接口删除后，这些消息仍然会保存在那些设备上，即删除消息不支持多端同步。
     */
    deleteMessages(messages: V2TIMMessage[]): Promise<void>;
    /**
     * 5.6 清空单聊本地及云端的消息（不删除会话）
     * <p> 5.4.666 及以上版本支持
     *
     * @note
     * - 会话内的消息在本地删除的同时，在服务器也会同步删除。
     *
     */
    clearC2CHistoryMessage(userID: string): Promise<void>;
    /**
     * 5.7 清空群聊本地及云端的消息（不删除会话）
     * <p> 5.4.666 及以上版本支持
     *
     * @note
     * - 会话内的消息在本地删除的同时，在服务器也会同步删除。
     */
    clearGroupHistoryMessage(groupID: string): Promise<void>;
    /**
     * 5.8 向群组消息列表中添加一条消息
     *
     * 该接口主要用于满足向群组聊天会话中插入一些提示性消息的需求，比如“您已经退出该群”，这类消息有展示
     * 在聊天消息区的需求，但并没有发送给其他人的必要。
     * 所以 InsertGroupMessageToLocalStorage() 相当于一个被禁用了网络发送能力的 SendMessage() 接口。
     *
     * @return msgID 消息唯一标识
     *
     * @note 通过该接口 save 的消息只存本地，程序卸载后会丢失。
     */
    insertGroupMessageToLocalStorage(message: V2TIMMessage, groupID: string, sender: string): {
        msgID: string;
        promise: Promise<V2TIMMessage>;
    };
    /**
     * 5.9 向C2C消息列表中添加一条消息
     *
     * 该接口主要用于满足向C2C聊天会话中插入一些提示性消息的需求，比如“您已成功发送消息”，这类消息有展示
     * 在聊天消息去的需求，但并没有发送给对方的必要。
     * 所以 InsertC2CMessageToLocalStorage()相当于一个被禁用了网络发送能力的 SendMessage() 接口。
     *
     * @return msgID 消息唯一表示
     * @note 通过该接口 save 的消息只存本地，程序卸载后会丢失。
     */
    insertC2CMessageToLocalStorage(message: V2TIMMessage, userID: string, sender: string): {
        msgID: string;
        promise: Promise<V2TIMMessage>;
    };
    /**
     * 5.10 根据 messageID 查询指定会话中的本地消息，包括状态 status 为 V2TIM_MSG_STATUS_LOCAL_REVOKED（已撤回）和 V2TIM_MSG_STATUS_HAS_DELETED（已删除）的消息
     * @param messageIDList 消息 ID 列表
     * @note 通过 V2TIMMessage 的 status 来区分消息的状态
     */
    findMessages(messageIDList: string[]): Promise<V2TIMMessage[]>;
    /**
     * 5.11 搜索本地消息（5.4.666 及以上版本支持，需要您购买旗舰版套餐）
     * @param searchParam 消息搜索参数，详见 V2TIMMessageSearchParam 的定义
     * @note 返回的列表不包含消息状态 status 为 V2TIM_MSG_STATUS_LOCAL_REVOKED（已撤回）和 V2TIM_MSG_STATUS_HAS_DELETED（已删除）的消息
     */
    searchLocalMessages(searchParam: V2TIMMessageSearchParam): Promise<V2TIMMessageSearchResult>;
    /**
     * 5.12 搜索云端消息（7.3 及以上版本支持）
     * @param searchParam 消息搜索参数，详见 V2TIMMessageSearchParam 的定义
     * @note
     * - 该功能为 IM 增值功能，详见[价格说明](https://cloud.tencent.com/document/product/269/11673?from=17176#.E5.9F.BA.E7.A1.80.E6.9C.8D.E5.8A.A1.E8.AF.A6.E6.83.85)
     * - 如果您没有开通该服务，调用接口会返回 60020 错误码
     * - 返回的列表不包含消息状态 status 为 V2TIM_MSG_STATUS_LOCAL_REVOKED（已撤回）和 V2TIM_MSG_STATUS_HAS_DELETED（已删除）的消息
     */
    searchCloudMessages(searchParam: V2TIMMessageSearchParam): Promise<V2TIMMessageSearchResult>;
    /**
     * 5.13 发送消息已读回执（6.1 及其以上版本支持）
     *
     * @note
     * - 该功能为旗舰版功能，[购买旗舰版套餐包](https://buy.cloud.tencent.com/avc?from=17485)后可使用，详见[价格说明](https://cloud.tencent.com/document/product/269/11673?from=17221#.E5.9F.BA.E7.A1.80.E6.9C.8D.E5.8A.A1.E8.AF.A6.E6.83.85)。
     * - 向群消息发送已读回执，需要您先到控制台打开对应的开关，详情参考文档 [群消息已读回执](https://cloud.tencent.com/document/product/269/75343#.E8.AE.BE.E7.BD.AE.E6.94.AF.E6.8C.81.E5.B7.B2.E8.AF.BB.E5.9B.9E.E6.89.A7.E7.9A.84.E7.BE.A4.E7.B1.BB.E5.9E.8B) 。
     * - messageList 里的消息必须在同一个会话中。
     * - 该接口调用成功后，会话未读数不会变化，消息发送者会收到 onRecvMessageReadReceipts 回调，回调里面会携带消息的最新已读信息。
     */
    sendMessageReadReceipts(messageList: V2TIMMessage[]): Promise<void>;
    /**
     * 5.14 获取消息已读回执（6.1 及其以上版本支持）
     * @param messageList 消息列表
     *
     * @note
     * - 该功能为旗舰版功能，[购买旗舰版套餐包](https://buy.cloud.tencent.com/avc?from=17485)后可使用，详见[价格说明](https://cloud.tencent.com/document/product/269/11673?from=17221#.E5.9F.BA.E7.A1.80.E6.9C.8D.E5.8A.A1.E8.AF.A6.E6.83.85)。
     * - 获取群消息已读回执，需要您先到控制台打开对应的开关，详情参考文档 [群消息已读回执](https://cloud.tencent.com/document/product/269/75343#.E8.AE.BE.E7.BD.AE.E6.94.AF.E6.8C.81.E5.B7.B2.E8.AF.BB.E5.9B.9E.E6.89.A7.E7.9A.84.E7.BE.A4.E7.B1.BB.E5.9E.8B) 。
     * - messageList 里的消息必须在同一个会话中。
     */
    getMessageReadReceipts(messageList: V2TIMMessage[]): Promise<V2TIMMessageReceipt[]>;
    /**
     * 5.15 获取群消息已读群成员列表（6.1 及其以上版本支持）
     * @param message 群消息
     * @param filter  指定拉取已读或未读群成员列表。
     * @param nextSeq 分页拉取的游标，第一次默认取传 0，后续分页拉取时，传上一次分页拉取成功回调里的 nextSeq。
     * @param count   分页拉取的个数，最多支持 100 个。
     *
     * @note
     * - 该功能为旗舰版功能，[购买旗舰版套餐包](https://buy.cloud.tencent.com/avc?from=17485)后可使用，详见[价格说明](https://cloud.tencent.com/document/product/269/11673?from=17221#.E5.9F.BA.E7.A1.80.E6.9C.8D.E5.8A.A1.E8.AF.A6.E6.83.85)。
     * - 使用该功能之前，请您先到控制台打开对应的开关，详情参考文档 [群消息已读回执](https://cloud.tencent.com/document/product/269/75343#.E8.AE.BE.E7.BD.AE.E6.94.AF.E6.8C.81.E5.B7.B2.E8.AF.BB.E5.9B.9E.E6.89.A7.E7.9A.84.E7.BE.A4.E7.B1.BB.E5.9E.8B) 。
     */
    getGroupMessageReadMemberList(message: V2TIMMessage, filter: V2TIMGroupMessageReadMembersFilter, nextSeq: number, count: number): Promise<V2TIMGroupMessageReadMemberList>;
    /**
     * 5.16 设置消息扩展（6.7 及其以上版本支持，需要您购买旗舰版套餐）
     * @param message 消息对象，消息需满足三个条件：1、消息发送前需设置 supportMessageExtension 为 true，2、消息必须是发送成功的状态，3、消息不能是社群（Community）和直播群（AVChatRoom）消息。
     * @param extensions 扩展信息，如果扩展 key 已经存在，则修改扩展的 value 信息，如果扩展 key 不存在，则新增扩展。
     *
     * @note
     * - 扩展 key 最大支持 100 字节，扩展 value 最大支持 1KB，单次最多支持设置 20 个扩展，单条消息最多可设置 300 个扩展。
     * - 当多个用户同时设置或删除同一个扩展 key 时，只有第一个用户可以执行成功，其它用户会收到 23001 错误码和最新的扩展信息，在收到错误码和扩展信息后，请按需重新发起设置操作。
     * - 我们强烈建议不同的用户设置不同的扩展 key，这样大部分场景都不会冲突，比如投票、接龙、问卷调查，都可以把自己的 userID 作为扩展 key。
     */
    setMessageExtensions(message: V2TIMMessage, extensions: V2TIMMessageExtension[]): Promise<V2TIMMessageExtensionResult[]>;
    /**
     * 5.17 获取消息扩展（6.7 及其以上版本支持，需要您购买旗舰版套餐）
     */
    getMessageExtensions(message: V2TIMMessage): Promise<V2TIMMessageExtension[]>;
    /**
     * 5.18 删除消息扩展（6.7 及其以上版本支持，需要您购买旗舰版套餐）
     * @param keys 消息扩展 key 列表, 单次最大支持删除 20 个消息扩展，如果设置为 nil ，表示删除所有消息扩展
     *
     * @note
     * - 当多个用户同时设置或删除同一个扩展 key 时，只有第一个用户可以执行成功，其它用户会收到 23001 错误码和最新的扩展信息，在收到错误码和扩展信息后，请按需重新发起删除操作。
     */
    deleteMessageExtensions(message: V2TIMMessage, keys: string[]): Promise<V2TIMMessageExtensionResult[]>;
    /**
     * 5.19 添加消息回应（可以用于实现表情回复）（7.4 及其以上版本支持，需要您购买旗舰版套餐）
     *
     *  <p> 表情回应功能是指对某条消息通过表情符号进行互动回应，我们可以看到每种表情的回应人数和回应人列表。
     *  <p> 目前常见的消息回应展示方式会有如下两种风格：
     *  <p> 风格一：
     *  <p>  ----------------------------
     *  <p> |   lucy, happy birthday!    |
     *  <p>  ----------------------------
     *  <p> |   😄 1  💐 2  👍🏻 10        |
     *  <p>  ----------------------------
     *  <p> 风格二：
     *  <p>  ------------------------------------------------
     *  <p> |   lucy, happy birthday!                        |
     *  <p>  ------------------------------------------------
     *  <p> |  😁 bob 💐olivia 🎂david                       |
     *  <p> |  👍🏻 denny、james、lucy、linda、thomas 等10人     |
     *  <p>  ------------------------------------------------
     *  <p>
     *  <p> 当用户点击某个表情后，会跳转到表情回应详情界面：
     *  <p>  |  😄   |   💐    |   👍🏻   |
     *  <p>  |  bob  |  olivia |  lucy   |
     *  <p>  |  ...  |   ...   |  denny  |
     *  <p>  |  ...  |   ...   |  ...    |
     *  <p> 用户可以根据某个表情分页拉取使用该表情的用户信息。
     *  <p>
     *  <p> 您可以基于 SDK API 实现表情回应能力:
     *  <p> 1、调用 AddMessageReaction    接口为一条消息添加一个 emoji，添加成功后，emoji 下就会存储当前操作用户。
     *  <p> 2、调用 RemoveMessageReaction 接口删除已经添加的 emoji，删除成功后，emoji 下就不再存储当前操作用户。
     *  <p> 3、调用 GetMessageReactions   接口批量拉取多条消息的 emoji 列表，其中每个 emoji 都包含了当前使用者总人数以及前 N（默认 10）个使用者用户资料。
     *  <p> 4、调用 GetAllUserListOfMessageReaction 接口分页拉取消息 emoji 的全量使用者用户资料。
     *  <p> 5、监听 onRecvMessageReactionsChanged 回调，感知 emoji 的使用者信息变更，该回调会携带 emoji 最新的使用者信息（包含使用者总人数以及前 N 个使用者用户资料）。
     *
     * @param reactionID 消息回应 ID，在表情回复场景，reactionID 为表情 ID，单条消息最大支持 10 个 Reaction，单个 Reaction 最大支持 100 个用户。
     *
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     * - 如果单条消息 Reaction 数量超过最大限制，调用接口会报 ERR_SVR_MSG_REACTION_COUNT_LIMIT 错误。
     * - 如果单个 Reaction 用户数量超过最大限制，调用接口会报 ERR_SVR_MSG_REACTION_USER_COUNT_LIMIT 错误。
     * - 如果 Reaction 已经包含当前用户，调用接口会报 ERR_SVR_MSG_REACTION_ALREADY_CONTAIN_USER 错误。
     */
    addMessageReaction(message: V2TIMMessage, reactionID: string): Promise<void>;
    /**
     * 5.20 删除消息回应（7.4 及其以上版本支持，需要您购买旗舰版套餐）
     *
     * @note
     * - 如果 Reaction 不存在，调用接口会报 ERR_SVR_MSG_REACTION_NOT_EXISTS 错误。
     * - 如果 Reaction 不包含当前用户，调用接口会报 ERR_SVR_MSG_REACTION_NOT_CONTAIN_USER 错误。
     */
    removeMessageReaction(message: V2TIMMessage, reactionID: string): Promise<void>;
    /**
     * 5.21 批量拉取多条消息回应信息（7.4 及其以上版本支持，需要您购买旗舰版套餐）
     *
     * @param messageList 消息列表，一次最大支持 20 条消息，消息必须属于同一个会话。
     * @param maxUserCountPerReaction 取值范围 【0,10】，每个 Reaction 最多只返回前 10 个用户信息，如需更多用户信息，可以按需调用 getAllUserListOfMessageReaction 接口分页拉取。
     *
     */
    getMessageReactions(messageList: V2TIMMessage[], maxUserCountPerReaction: number): Promise<V2TIMMessageReactionResult>;
    /**
     * 5.22 分页拉取使用指定消息回应用户信息（7.4 及其以上版本支持，需要您购买旗舰版套餐）
     *
     * @param message 消息对象
     * @param reactionID 消息回应 ID
     * @param nextSeq 分页拉取的游标，第一次传 0，后续分页传 succ 返回的 nextSeq。
     * @param count 一次分页最大拉取个数，最大支持 100 个。
     *
     */
    getMessageReactionUserList(message: V2TIMMessage, reactionID: string, nextSeq: number, count: number): Promise<V2TIMMessageReactionUserResult>;
    /**
     * 5.23 翻译文本消息
     *
     * @param sourceTextList 待翻译文本数组。
     * @param sourceLanguage 源语言。可以设置为特定语言或 ”auto“。“auto“ 表示自动识别源语言。传空默认为 ”auto“。
     * @param targetLanguage 目标语言。支持的目标语言有多种，例如：英语-“en“，简体中文-”zh“，法语-”fr“，德语-”de“等。详情请参考文档：[文本翻译语言支持](https://cloud.tencent.com/document/product/269/85380#.E6.96.87.E6.9C.AC.E7.BF.BB.E8.AF.91.E8.AF.AD.E8.A8.80.E6.94.AF.E6.8C.81)。
     * @param callback 翻译结果回调。其中 result 的 key 为待翻译文本, value 为翻译后文本。
     */
    translateText(sourceTextList: string[], sourceLanguage: string, targetLanguage: string): Promise<Map<string, string>>;
    /**
     * 5.24 设置群消息置顶（7.9 及以上版本支持，需要您购买旗舰版套餐）
     * @param groupID 群 ID
     * @param isPinned 是否置顶
     *
     * @note
     * - 此接口用于置顶和取消置顶对应的群消息，如果置顶消息数量超出限制sdk会返回错误码10070。
     */
    pinGroupMessage(groupID: string, message: V2TIMMessage, isPinned: boolean): Promise<void>;
    /**
     * 5.25 获取已置顶的群消息列表（7.9 及以上版本支持，需要您购买旗舰版套餐）
     * @param groupID 群 ID
     *
     * @note
     * - 此接口用于获取置顶消息列表，如果置顶消息已过期不会返回
     */
    getPinnedGroupMessageList(groupID: string): Promise<V2TIMMessage[]>;
    /**
     * 6.1 发起 TTS 流式语音合成
     *
     * @param msgID         触发语音合成的文本消息 msgID
     * @param streamMsgID   业务侧生成的流式任务 ID（用于标识一次 TTS 会话）
     * @param ackIndex      业务方当前已成功播放的分片索引；用于 SDK 侧做流控 ack
     * @param voiceFormat   语音格式参数（声音 ID / 语速）
     *
     * @note
     * - SDK 会通过独立的 StreamConnection 进行实时音频推送，推送结果通过 onRecvTTSResponse 回调返回。
     * - 请在确保已登录成功后再调用，账号终止（登出/踢下线/强制下线/切号/UserSig 过期）会导致本地任务被清理。
     */
    startTTS(msgID: string, streamMsgID: string, ackIndex: number, voiceFormat: V2TIMTTSVoiceFormat): Promise<void>;
    /**
     * 6.2 停止 TTS 流式语音合成（连接级关闭）
     *
     * @param msgID         文本消息 msgID
     * @param streamMsgID   流式任务 ID
     *
     * @note
     * - stopTTS 为**连接级**关闭：SDK 会关闭共享的 StreamConnection，并立即清理该连接上的全部活跃 TTS 任务与本地映射。
     * - 成功后 SDK 不承诺为本地清理的其它活跃任务补发 onRecvTTSResponse(isFinished = true)。
     * - 若当前没有活跃任务，该接口会失败（ERR_INVALID_PARAMETERS）。
     */
    stopTTS(msgID: string, streamMsgID: string): Promise<void>;
}
