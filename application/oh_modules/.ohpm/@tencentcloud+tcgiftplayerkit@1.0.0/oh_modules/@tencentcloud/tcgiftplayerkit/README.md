# TCGiftPlayerKit (HarmonyOS)

HarmonyOS gift animation player HAR, maintained under `harmony/live` alongside `TUILiveKit` and `livekitaccess`. It mirrors the iOS `ios/live/TCGiftPlayerKit` API: one player owns one rendering surface and one playback request; gift queues and room state belong to the host.

The current HarmonyOS Kit plays SVGA only. MP4 resources fail during preparation with `unsupportedFormat`. The Kit has no third-party SVGA dependency and does not depend on AtomicXCore or TUILiveKit.

## Installation

Install the package from the OpenHarmony central repository:

```shell
ohpm install @tencentcloud/tcgiftplayerkit
```

`ohpm i @tencentcloud/tcgiftplayerkit` is equivalent.

## Integration

The module is registered in `livekitaccess/build-profile.json5` with `srcPath: ../TCGiftPlayerKit`. A HAR consumer declares it as a local dependency:

```json5
"dependencies": {
  "@tencentcloud/tcgiftplayerkit": "file:../TCGiftPlayerKit"
}
```

Run `ohpm install --all` from `livekitaccess/` after changing dependencies. Build commands are in the [HarmonyOS README](../README.md).

## Playback

Keep the player for the presentation lifetime and call it from the UI thread. Mount `TCGiftPlayerView` before playing; an unmounted view reports `unmountedView`. If the canvas or its size is not ready yet, playback starts once both are available.

```typescript
import { TCGiftPlaybackEvent, TCGiftPlaybackEventType, TCGiftPlayer, TCGiftPlayerView } from '@tencentcloud/tcgiftplayerkit'

const giftPlayer = new TCGiftPlayer()

TCGiftPlayerView({ player: giftPlayer })
  .width('100%')
  .height('100%')

giftPlayer.playURL(resourceURL, (event: TCGiftPlaybackEvent) => {
  if (event.type === TCGiftPlaybackEventType.started) {
    // The first frame was drawn.
  } else if (event.type === TCGiftPlaybackEventType.finished) {
    // The host may advance its gift queue.
  } else {
    console.error(event.error?.message)
  }
})

// On interruption, exit, reuse or host timeout:
giftPlayer.stop()
```

Accepted inputs are public HTTP(S) URLs, `file://` URLs and absolute paths; the format is detected from the URL path extension. Events are delivered asynchronously; `started` arrives at most once and each request produces at most one `finished` or `failed`. A new play replaces the old request. `stop()` suppresses stale events, does not emit a natural finish and releases the current playback resources; it does not delete the disk cache. There is no pause/resume API.

## Optional prefetch

```typescript
const task = giftPlayer.prepare(nextResourceURL, (result: TCGiftPreparationResult) => {
  if (result.resource !== undefined) {
    nextGift = result.resource
  } else {
    console.error(result.error?.message)
  }
})

// Cancel if the queued gift is discarded. Cancellation suppresses completion.
task.cancel()

// When the gift reaches its turn:
giftPlayer.play(nextGift, onEvent)

// The host owns each prepared resource and releases it when the gift leaves its queue.
nextGift.release()
```

Preparation of the same URL within one player shares a single parse. The prepared resource and an active playback each hold their own lease; parsed data is released after all leases are released. TUILiveKit prepares the next queued gift only after the current one starts and never preloads a gift catalog.

## Downloads and cache

Remote resources are cached in `context.cacheDir/TCGiftPlayerKit/Effects/` by the SHA256 of the URL plus its extension. Concurrent downloads of one URL are merged; the network request is cancelled after its last consumer cancels. Downloads only reach public hosts and public resolved addresses, pin the validated DNS result, use no proxy, follow at most five redirects with per-hop validation and no HTTPS downgrade, accept complete 2xx responses only, and stop at 64 MiB or 30 seconds. Files are written to a temporary path and renamed only after a complete write.

## SVGA support

SVGA 2.x zlib-compressed or raw protobuf files are supported, including bitmap sprites and matte masks. ZIP archives (1.x or `movie.binary` packages), embedded audio, vector shapes and clipPath are not supported. Content uses AspectFit, plays once and is cleared on completion.

Parsing (file read, zlib, protobuf) runs in `taskpool`; only frame arrays and encoded image bytes cross threads. Bitmaps are decoded on the UI thread when first drawn and kept in a cache of about 64 MiB that evicts images unused in the last two frames. The timeline advances by elapsed display time and skips frames under load instead of slowing down.

## Verification

Offline regression transpiled the Kit sources against real gift assets (`car`, `cat`, `sports_car`) to check parsing, draw bounds, duration, events and resource release. Playback on a real device or emulator has not been verified; actual material compatibility requires on-device playback checks.
