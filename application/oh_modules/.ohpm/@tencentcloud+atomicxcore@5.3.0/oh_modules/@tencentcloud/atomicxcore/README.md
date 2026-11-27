# AtomicXCore for HarmonyOS

## Introduction

`AtomicXCore` is Tencent Cloud's atomic business capability layer for HarmonyOS,
providing a unified set of **Store**s that cover **Instant Messaging (IM)** and
**Audio / Video Call** scenarios out of the box.

It wraps Tencent Cloud's IM SDK and TRTC engine behind a consistent,
reactive, UI-friendly API designed for ArkTS/ETS, so upper-layer business or
UIKit code can stay thin and focused on rendering.

Same capability set is also available on iOS / Android / Flutter, making
`AtomicXCore` the cross-platform foundation of Tencent Cloud's client UIKits.

## Features

### Instant Messaging

- **Login / Session** — `LoginStore`: login / logout with `userSig`, session lifecycle
- **Message List** — `MessageListStore`: paged history, new-message streaming, read-receipt
- **Message Sending** — `MessageActionStore` / `MessageInputStore`: send / recall / forward / edit,
  supports text, image, video, audio, file and custom messages
- **Conversation** — `ConversationListStore` / `ConversationGroupStore`: conversation list,
  pinning, unread count, conversation grouping
- **Contact** — `ContactListStore`, `C2CSettingStore`, `GroupSettingStore`:
  friend list, C2C and group chat settings
- **Search** — `SearchStore`: unified search across messages and conversations

### Real-Time Audio / Video Call

- **Call Lifecycle** — `CallStore`: initiate / answer / reject / hang up calls,
  supports both 1v1 and group calls, with configurable timeout, custom
  pass-through data and cloud recording policy
- **Call Participants** — observable participant list, mic / camera state,
  speaker volumes and per-user network quality
- **Call History** — paged recent call records query and deletion
- **Device** — `DeviceStore`: microphone / camera / speaker management

> Note: Starting from `4.2.0`, the implementations of `RoomStore` and
> `RoomParticipantStore` have been temporarily removed due to an architecture
> upgrade. If you need the audio / video room scenario, please lock the
> dependency to version `4.1.0`.

## Environment Requirements

- DevEco Studio NEXT Release or later
- HarmonyOS SDK **API 12** or later (`compatibleSdkVersion: 12`)
- ArkTS / ETS

## Installation

### Via ohpm

```shell
ohpm install @tencentcloud/atomicxcore
```

### Via oh-package.json5

Add the following dependency to your `oh-package.json5`:

```json5
{
  "dependencies": {
    "@tencentcloud/atomicxcore": "^5.3.0"
  }
}
```

Then run:

```shell
ohpm install
```

## Quick Start

```ts
import {
  LoginStore,
  ConversationListStore,
  ConversationFetchOption,
} from '@tencentcloud/atomicxcore'

// 1. Login (LoginStore is a singleton, use shared())
await LoginStore.shared().login(
  YOUR_SDK_APP_ID,
  'user_123',
  'xxxxxxxx', // userSig
)

// 2. Fetch conversation list
const conversationListStore = ConversationListStore.create()
const option = new ConversationFetchOption()
option.count = 100
await conversationListStore.fetchConversationList(option)
```

Each store exposes a reactive `state` (decorated with `@Observed`).
In ArkTS pages simply hold the store and render `state` with `@ObjectLink`:

```ts
@Entry
@Component
struct ConversationListPage {
  @State store: ConversationListStore = ConversationListStore.create()

  build() {
    List() {
      LazyForEach(this.store.state.conversationDataSource, (item) => {
        ListItem() {
          // render item
        }
      })
    }
  }
}
```

For the audio / video call scenario, see `CallStore` in the API reference.
A typical caller-side flow:

```ts
import { CallStore, CallMediaType, CallParams } from '@tencentcloud/atomicxcore'

// Place a 1v1 video call
await CallStore.shared().calls(
  ['user_456'],
  CallMediaType.video,
  new CallParams(),
)
```

## Architecture

`AtomicXCore` follows a **Store pattern** architecture:

- **API Layer** — Public interfaces under `api/**` (e.g. `LoginStore`, `MessageListStore`, `CallStore`)
- **Implementation Layer** — Concrete implementations under `impl/**`, wired up via factory
  auto-registration (e.g. `StoreFactory`, triggered as a side-effect import in `Index.ets`)
- **State Management** — Reactive state powered by `@Observed` / `@ObjectLink`,
  exposed via `subscribe` / `unsubscribe`
- **Data Source** — `BasicDataSource` optimized for `LazyForEach` rendering;
  specialized data sources: `ConversationDataSource`, `ContactDataSource`,
  `MessageDataSource`
- **Event System** — `EventEmitter` with `WeakRef` references to avoid leaks
- **Error Model** — Unified `ErrorInfo` across all async APIs

## Dependencies

| Package | Version | Purpose |
| --- | --- | --- |
| `@tencentcloud/imsdk` | `^8.6.7020` | Tencent Cloud IM SDK for HarmonyOS |
| `@tencentcloud/liteavsdk_professional` | `^13.2.1135` | LiteAV professional edition, underlying audio / video and call engine |

## Support & Feedback

For technical support, documentation and community discussions:

- [HarmonyOS Development Guide](https://developer.huawei.com/consumer/en/harmonyos)
- [Tencent Cloud IM Documentation](https://www.tencentcloud.com/products/im)
- [Tencent Cloud TRTC Documentation](https://www.tencentcloud.com/products/trtc)

## License

Proprietary — see the `LICENSE` file for details.
