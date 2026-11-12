# HarmonyOS Chat UIKit Code Map

本文覆盖 `harmony/chat/uikit` 的公开页面和宿主回调边界；会话、联系人和消息业务状态由 AtomicXCore / AtomicX 组件持有。

## 公开导出

| 文件 | 职责 |
|---|---|
| `Index.ets` | 包入口，转发 `src/main/ets/index.ets` 的公开导出 |
| `src/main/ets/index.ets` | 导出 `ConversationsPage`、`ContactsPage`、`ChatPage` 和 `ChatDialog` |

## 页面与调用边界

| 文件 | 职责与宿主接口 |
|---|---|
| `src/main/ets/pages/ConversationsPage.ets` | 组合 AtomicX `ConversationList` 和 `SearchBar`；会话、联系人、群和消息搜索结果通过回调交给宿主，不负责页面导航；新建会话和建群使用 AtomicX 弹窗 |
| `src/main/ets/pages/ContactsPage.ets` | 组合 AtomicX `ContactList`；联系人和群点击通过回调交给宿主，新增联系人/群委托 AtomicX 对话框 |
| `src/main/ets/pages/ChatPage.ets` | 组合 `MessageList`、`MessageInput` 和多选操作栏；通过参数与回调承接标题、返回、用户资料、安全举报和更多菜单红点；订阅资料更新并在页面退出时取消订阅与未读计时器 |
| `ChatDialog`（同 `ChatPage.ets`） | 对 `ChatPage` 的弹窗宿主，转发会话参数和回调，返回时关闭对话框 |

`ChatPage.enableCalls` 默认 `true`，只控制输入区的音频/视频通话入口，并传入 `ChatMessageInputConfig.isShowAudioCall` / `isShowVideoCall`。`ChatDialog` 转发该参数；它不负责初始化或关闭 CallKit。综合应用可设为 `false`，其他通话入口仍由宿主处理。

## 状态归属

- 会话、联系人、群、消息和输入能力由 AtomicX 页面组件与 AtomicXCore Store 提供。
- 页面跳转、登录、CallKit 生命周期以及聊天设置的宿主路由由接入 App 负责。
- 本模块只包装页面和回调，不复制聊天业务状态。
