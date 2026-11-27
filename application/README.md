# App-UIKit HarmonyOS

以当前 iOS `ios/application` 为模版的原生 ArkTS / ArkUI 综合应用。

- 五 Tab：会议、直播、通话、消息、我的，默认选中直播；通话保留占位。
- 会议：快速会议、加入会议、设备开关、视频设置及真实 `MeetingView`；预约会议与日程仅保留首页入口或空态。
- 直播：双列、预览、进房、上下翻房和视频开播；语音、游戏开播保留占位。房内能力由现有 TUILiveKit 提供。
- 消息：复用会话、搜索定位消息、聊天、单聊资料和群设置。输入区隐藏通话按钮，其他通话操作显示未接入提示。
- 我的：真实资料、头像/昵称修改、退出登录，以及实际 SDK 日志的选择与系统分享。

代码职责见 [CODE_MAP](CODE_MAP.md)，执行记录见 [同步计划](../../docs/task/harmony/application-sync-plan.md)。本轮完成源码检查、逻辑回归、Debug 编译，并在用户明确授权下完成登录、直播预览、伊尔凡直播间进入/关闭返回的设备联机验证；未验证会议、开播、消息收发和分享。

## 环境与打开方式

用 DevEco Studio 打开本目录 `harmony/application`，不是 `entry/`。工程根注册 entry HAP，以及相邻的 Live、Room、Chat 和 atomic_x HAR；不复制它们的实现。

当前验证环境为 DevEco Studio / SDK 6.0.0，target API 20，compatible API 20；支持手机竖屏。Node、ohpm、Hvigor 与 JBR 的发现规则沿用仓库构建脚本。UI 以 vp / fp 和真实窗口安全区布局，不整屏缩放。

`bundleName` 为 `com.tencent.uikit.application`，Ability 为 `EntryAbility`，应用名为 `App-UIKit`。

## SDK 配置

统一修改 [`entry/src/main/ets/debug/GenerateTestUserSig.ets`](entry/src/main/ets/debug/GenerateTestUserSig.ets) 的 SDKAPPID、SECRETKEY 和 EXPIRETIME。该文件复用现有鸿蒙 Live 接入工程的测试配置与签名实现，登录/注册/资料操作使用真实 LoginStore；默认开发配置可直接用于接入验证。

根 `oh-package.json5` 的 overrides 固定线上 AtomicXCore 5.3.0、IM 9.1.7818。IM 版本与 AtomicXCore 发布包的 dependencyPkgVersion 一致；原 Chat / atomic_x 的开发依赖声明保持原样，新应用不依赖仓库外的引擎源码。礼物播放器使用 Live 组件声明的线上包。

流水线与原生 iOS / Android 一致：先把 AtomicXCore 构件流水线的 `atomicxcore_*.har` 拉到仓库根 `SDK/`（或 `ATOMICXCORE_ARTIFACTS_DIR`），构建脚本发现后临时复制到本工程 `libs/`，并把根 overrides 与 entry 依赖改为该本地 HAR；未找到时继续使用上面的线上版本。改动的 `oh-package.json5`、各模块锁文件和复制的 HAR 在脚本退出时恢复或删除，不提交。

直播沿用当前鸿蒙组件的能力边界：MP4 礼物等已有平台差异不会因增加 App 宿主自动补齐，详见 [Live Code Map](../live/CODE_MAP.md)。

## 检查与构建

从仓库根目录执行：

```sh
HARMONY_UNSIGNED=1 scripts/build_hap.sh debug application
```

产物为 `build/harmony/application/app_arkts_harmony_<三段版本>_unsigned.hap`，命名与 `app_kotlin_android_*`、`app_swift_ios_*` 一致；三段版本取 `APP_VERSION`，未设置时取 `AppScope/app.json5` 的 versionName。流水线设置 `APP_VERSION`（如 `5.3.0.4600`）与 `APP_BUILD_NUM` 时，脚本临时写入 versionName / versionCode。脚本会执行 ohpm 安装与 Hvigor 构建；原 `scripts/build_hap.sh debug` 仍构建独立 LiveKitAccess。

仅安装依赖时，在本目录执行：

```sh
ohpm install --all
```

本地逻辑回归不需要设备，在本目录执行：

```sh
node tests/live_home_list_store.test.cjs
node tests/login_controller.test.cjs
node tests/preview_lifecycle.test.cjs
```

测试读取实际生产代码并使用 SDK 测试替身，覆盖分页/快照/迟到结果、登录与注册、Player 创建与释放、退场后的入房响应隔离。它们使用 DevEco SDK 自带 TypeScript；SDK 不在 macOS 默认位置时设置 `DEVECO_SDK_HOME`。测试不证明实际 SDK 网络行为、ArkUI 绘制或设备效果。

## 签名与验证边界

默认生成 unsigned HAP，不能直接作为真机安装包。本机签名放被忽略的 `signing.local.json`；格式与 [Live 签名配置](../live/README.md#本机签名) 一致，文件放在本工程根目录。不要提交证书、密码、local.properties 或构建缓存。

`hvigorfile.ts` 会注入本机签名并自动把 `default` 产品关联到 `default` 签名配置；DevEco 临时写入共享 `build-profile.json5` 的签名配置也会被关联，但构建后仍应把凭据迁回本机文件，并将共享文件恢复为 `signingConfigs: []`。如果安装提示 `9568320 / no signature file`，说明当前包没有签名：通常是产品未关联签名、选择了 unsigned HAP，或运行配置设置了 `HARMONY_UNSIGNED=1`。配置后从仓库根执行以下命令，安装新生成的 signed HAP，不要选择 `unsigned.hap`：

```sh
env -u HARMONY_UNSIGNED scripts/build_hap.sh debug application
```

签名产物：`build/harmony/application/app_arkts_harmony_<三段版本>.hap`。DevEco 使用同一工程构建时也会读取本机文件；其运行配置不要设置 `HARMONY_UNSIGNED=1`。

本轮在用户明确授权下执行设备安装、启动、登录、直播列表/预览、伊尔凡直播间进入、关闭返回和预览画面连续性验证；会议创建/加入、开播、消息收发、实际安全区/键盘与分享仍未验证。这里只验证 Debug 接入，尚未做对外 Release 发布与混淆验收。

## 素材

品牌、启动图标和个人页 PNG 按用户授权复用 iOS application。首页开播/关闭图标因原 Ardot 节点缺失或请求超时，经用户额外授权复用前轮同源导出文件；没有重绘替代。Room 首页的 7 个 SVG 原样迁移自 iOS RoomKitAccess，未生成替代 PNG。来源、像素尺寸与校验和记录在 [assets-source.json](assets-source.json)。

iOS 缺少昵称弹层关闭图和头像选中角标，本端同样不补造图标；昵称可点蒙层/系统返回关闭，头像保留选中描边。
