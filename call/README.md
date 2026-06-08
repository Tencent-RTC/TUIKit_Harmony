# @tencentcloud/tuicallkit (Harmony)

Harmony NEXT TUICallKit. Powered by `@tencentcloud/atomicxcore`.

The SDK owns its own top-level overlay — business pages do **not** need to
embed any SDK component into their render tree. Mount once at
`UIAbility.onWindowStageCreate`, tear down at `onWindowStageDestroy`.

## Requirements

- HarmonyOS NEXT, **API 12+** (`compatibleSdkVersion >= 5.0.0(12)`).
- ArkUI ArkTS.

## Permissions

Declare the following in your entry module's `module.json5`. Without these the
SDK cannot capture audio/video, keep the call alive in the background, or
detect network changes.

```json5
{
  "module": {
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.USE_BLUETOOTH" },
      { "name": "ohos.permission.GET_BUNDLE_INFO" },
      { "name": "ohos.permission.GET_NETWORK_INFO" },
      { "name": "ohos.permission.GET_WIFI_INFO" },
      { "name": "ohos.permission.MODIFY_AUDIO_SETTINGS" },
      { "name": "ohos.permission.KEEP_BACKGROUND_RUNNING" },
      {
        "name": "ohos.permission.MICROPHONE",
        "reason": "$string:permission_microphone_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
      },
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:permission_camera_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
      }
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        // ... your existing fields ...
        "backgroundModes": ["audioRecording", "audioPlayback"]
      }
    ]
  }
}
```

Notes:

- `MICROPHONE` and `CAMERA` are user-grant permissions. The SDK requests them
  at the right time (when a call starts / the call UI shows); do **not**
  pre-request them at app launch.
- `backgroundModes` `audioRecording` + `audioPlayback` are required on
  Harmony — without them the system mutes the mic and cuts the speaker as
  soon as the screen turns off or the app goes to background.
- `KEEP_BACKGROUND_RUNNING` is required together with `backgroundModes` to
  keep the call running when the app is backgrounded.

## Install

In your `app/build-profile.json5`:

```json5
{
  "modules": [
    // ...
    {
      "name": "tuicallkit",
      "srcPath": "../call"
    }
  ]
}
```

In your entry module's `oh-package.json5`:

```json5
{
  "dependencies": {
    "@tencentcloud/atomicxcore": "^4.2.0",
    "@tencentcloud/tuicallkit": "file:../../call"
  }
}
```

> The `srcPath: "../call"` and `file:../../call` examples assume the `call`
> HAR module sits next to your `entry` module. Adjust the relative path to
> match your actual project layout.

## Integration

Mount the call-kit overlay **once** in your `EntryAbility`:

```ts
// EntryAbility.ets
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { TUICallKit } from '@tencentcloud/tuicallkit';

export default class EntryAbility extends UIAbility {
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    windowStage.loadContent('pages/Index');

    // Bootstrap (audio/notif/PiP features, event listeners) and attach the
    // SDK-owned overlay onto the host Window. Business pages are zero-touch —
    // no @Component to embed.
    TUICallKit.createInstance(this.context).attach(windowStage);
  }

  onWindowStageDestroy(): void {
    TUICallKit.createInstance(this.context).detach();
  }
}
```

That's it. Outgoing / incoming call UI now renders on top of any page that the
host Ability shows.

### Login

Login is handled by `atomicxcore`. You **must** complete login before calling
`TUICallKit.calls(...)`, `TUICallKit.join(...)` or `TUICallKit.setSelfInfo(...)`.

```ts
import { LoginStore } from '@tencentcloud/atomicxcore';

await LoginStore.shared().login(SDK_APP_ID, userId, userSig, getContext(this));
```

`SDK_APP_ID` / `userSig` come from your IM/RTC backend; the `context` is the
UIAbility context.

### (Optional) Set self profile

Provide a nickname and avatar that will be shown to the peer. **Call this
only after `LoginStore.login()` resolves** — the SDK reads the current
logged-in `userID` internally.

```ts
import { TUICallKit } from '@tencentcloud/tuicallkit';

await TUICallKit.createInstance(getContext(this))
  .setSelfInfo('Alice', 'https://example.com/avatar.png');
```

### Make a call

```ts
import { TUICallKit, CallMediaType } from '@tencentcloud/tuicallkit';

await TUICallKit.createInstance(getContext(this))
  .calls(['userId_to_call'], CallMediaType.video);
```

## API surface (public)

```ts
class TUICallKit {
  /** Aligned with Android `TUICallKit.createInstance(context: Context)`. */
  static createInstance(context: common.Context): TUICallKit;

  attach(windowStage: window.WindowStage): void;   // idempotent
  detach(): void;                                  // safe pre-attach

  setSelfInfo(nickname: string, avatar: string): Promise<void>;
  calls(userIdList: string[], mediaType: CallMediaType, params?: CallParams): Promise<void>;
  join(callId: string): Promise<void>;
  setCallingBell(filePath: string): void;
  enableMuteMode(enable: boolean): void;
  enableFloatWindow(enable: boolean): void;        // gates system Picture-in-Picture
  enableIncomingBanner(enable: boolean): void;
  setScreenOrientation(orientation: number): Promise<void>;
}
```

## Notes

- `attach` is idempotent: a re-`attach` automatically detaches the previous
  mount before re-mounting. Hot-reload safe.
- `detach` is safe pre-`attach` and safe to call repeatedly.
- The overlay's `none` state has `width=0/height=0` and
  `hitTestBehavior(HitTestMode.None)`, so it never participates in layout or
  intercepts touches when there is no active call — your page receives input
  exactly as before.
- System Picture-in-Picture is opt-in via `enableFloatWindow(true)` and the
  device's system PiP support; in-app draggable float-window is intentionally
  not provided on Harmony.
