# HarmonyOS Chat UIKit

公开入口为 `ConversationsPage`、`ContactsPage`、`ChatPage` / `ChatDialog`。组件使用仓库 `harmony/atomic_x`；SDK状态和写操作由AtomicXCore Store持有。

`ChatPage({ conversationID, enableCalls: false })` 可隐藏消息输入区的音频/视频通话入口；`ChatDialog`同样支持并转发此参数。默认`true`，既有接入行为保持。设置页等其他入口由宿主承接回调或事件；本参数不初始化或关闭CallKit。

本组件原依赖声明仍指向开发引擎；综合应用在根`oh-package.json5`使用`overrides`统一为线上`@tencentcloud/atomicxcore@5.3.0`，其兼容性已通过综合应用编译验证。构建命令与宿主接入见[综合应用说明](../../application/README.md)；代码边界见[CODE_MAP](CODE_MAP.md)。
