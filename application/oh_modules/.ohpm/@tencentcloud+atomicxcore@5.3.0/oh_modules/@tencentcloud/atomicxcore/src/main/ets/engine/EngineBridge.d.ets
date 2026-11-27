/**
 * 引擎 → ArkTS 的事件分发器（多播），接收 id 和 JSON 字符串，无返回值。
 */
export type EngineEventHandler = (id: string, jsonData: string) => void;
/**
 * 引擎 → ArkTS 的同步查询处理器（单播），接收 JSON 字符串，返回 JSON 字符串。
 */
export type EngineQueryHandler = (jsonData: string) => string;
/**
 * 订阅令牌，用于取消 `EngineBridge.subscribe()` 注册的事件监听。
 */
export declare class SubscriptionToken {
    readonly eventName: string;
    readonly handler: EngineEventHandler;
    constructor(eventName: string, handler: EngineEventHandler);
}
/**
 * EngineBridge —— ArkTS 与 native 引擎之间的桥接单例。
 *
 * 主动 API（ArkTS → 引擎）：
 *   - `EngineBridge.call(eventName, jsonData)` → `Promise<string>`
 *   - `EngineBridge.query(eventName, jsonData)` → `string`
 *
 * 被动 API（引擎 → ArkTS）：
 *   - `EngineBridge.subscribe(eventName, handler)`           多播订阅
 *   - `EngineBridge.setQueryHandler(eventName, handler)`     单播覆盖写入
 *   - `EngineBridge.removeAll()`                             清空所有注册表
 *
 * 生命周期：
 *   - `subscribe` / `setQueryHandler` 仅做轻量登记，**不会**创建 native 引擎。
 *   - 首次调用 `call` / `query` 时才真正创建 native 引擎并 `Init()`，
 *     同时把已登记的事件 / 查询处理器一次性接入 native 的分发回路。
 *   - `EngineBridge.dispose()` 反初始化并清空所有内部状态。
 *
 * 注册表为类级静态字段，使被动 API 无需创建实例即可写入；
 * native 句柄、Init 标志、adapter 安装位由懒构造的私有单例持有。
 */
export declare class EngineBridge {
    private static _shared;
    private static eventHandlers;
    private static queryHandlers;
    private napi;
    private inited;
    private adapterInstalled;
    private constructor();
    /**
     * 获取内部单例；首次访问时自动触发 native 引擎创建与初始化，并把已登记
     * 的事件 / 查询处理器接入 native 分发回路。
     *
     * 仅由主动 API（call / query）使用；被动 API 不应调用，以免提前拉起 native。
     */
    private static shared;
    private ensureInited;
    /**
     * 反初始化引擎，清空所有事件 / 查询处理器，并释放单例。
     */
    static dispose(): void;
    /**
     * 异步调用引擎 API（ArkTS → 引擎）。
     *
     * 内部桥接 NAPI 层的 `Call(eventName, jsonData, callback)`，
     * 将 `(code, message, data)` 三参回调封装为 Promise：
     *   - `code === 0` 时 `resolve(data)`，`data` 为 cpp 层返回的 JSON 字符串；
     *   - 其他情况先打 error 日志，再 `reject(ErrorInfo)`。
     *
     * @param eventName 事件名称
     * @param jsonData  JSON 格式的参数
     * @returns `Promise<string>` 成功时 resolve 的 JSON 字符串；失败时抛出 `ErrorInfo`
     */
    static call(eventName: string, jsonData: string, id?: string): Promise<string>;
    /**
     * 同步查询引擎 API（ArkTS → 引擎）。
     *
     * @param eventName 事件名称
     * @param jsonData  JSON 格式的参数
     * @returns JSON 格式的返回结果
     */
    static query(eventName: string, jsonData: string, id?: string): string;
    /**
     * 订阅引擎 → ArkTS 的事件（被动回调，多播）。
     *
     * 同一个 eventName 可多次订阅，多个 handler 按注册顺序被依次调用。
     *
     * 该 API **不会**触发 native 引擎初始化，仅在内部注册表中登记 handler；
     * 真正的 native 启动延迟到首次 `call` / `query` 时由 `shared()` 完成。
     *
     * @param eventName 事件名称
     * @param handler   接收 JSON 字符串的处理器
     * @returns 订阅令牌，用于后续 `unsubscribe()` 取消订阅
     */
    static subscribe(eventName: string, handler: EngineEventHandler): SubscriptionToken;
    /**
     * 取消由 `subscribe()` 注册的事件监听。
     *
     * @param token `subscribe()` 返回的订阅令牌
     */
    static unsubscribe(token: SubscriptionToken): void;
    /**
     * 注册引擎 → ArkTS 的同步查询处理器（单播，覆盖写入）。
     *
     * 该 API **不会**触发 native 引擎初始化，仅在内部注册表中登记 handler。
     *
     * @param eventName 事件名称
     * @param handler   接收 JSON 字符串并返回 JSON 字符串的处理器
     */
    static setQueryHandler(eventName: string, handler: EngineQueryHandler): void;
    /**
     * 清空所有订阅与查询处理器。
     *
     * 只清空 ArkTS 侧注册表，不解除 native 层已安装的分发器（幂等）。
     */
    static removeAll(): void;
    /**
     * 在 native 引擎初始化完成后安装一次分发器闭包（幂等）。
     *
     * 闭包内部读取的是 `EngineBridge.eventHandlers` / `queryHandlers` 这两张
     * 静态注册表，因此 `subscribe` / `setQueryHandler` 的登记结果可以无缝生效，
     * 既覆盖"先注册后 init"也覆盖"先 init 后注册"。
     */
    private installAdapter;
}
