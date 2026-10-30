import {
  TCGiftPlaybackEvent,
  TCGiftPlaybackEventType,
  TCGiftPlayer,
  TCGiftPlayerView,
  TCGiftPreparationResult,
  TCGiftPreparationTask,
} from '@tencentcloud/tcgiftplayerkit'
import { LiveKitLog } from '../../log/LiveKitLog'

const effectTimeout: number = 30000

class Effect {
  readonly resourceURL: string
  task?: TCGiftPreparationTask
  result?: TCGiftPreparationResult

  constructor(resourceURL: string) {
    this.resourceURL = resourceURL
  }

  dispose(): void {
    this.task?.cancel()
    this.task = undefined
    this.result?.resource?.release()
    this.result = undefined
  }
}

@Observed
export class GiftAnimationController {
  readonly giftPlayer: TCGiftPlayer = new TCGiftPlayer()
  private queue: Effect[] = []
  private currentEffect?: Effect
  private hasStartedPlayback: boolean = false
  private timeout: number = -1

  enqueue(resourceURL: string): void {
    this.queue.push(new Effect(resourceURL))
    this.playNextIfNeeded()
    this.prepareNextIfNeeded()
  }

  reset(): void {
    const pending = this.queue
    this.queue = []
    pending.forEach((effect: Effect) => effect.dispose())
    this.clearCurrentEffect()
  }

  private playNextIfNeeded(): void {
    if (this.currentEffect !== undefined || this.queue.length === 0) {
      return
    }
    const effect = this.queue.shift()!
    this.currentEffect = effect
    this.scheduleTimeout(effect)
    if (effect.result !== undefined) {
      this.consumePreparation(effect)
    } else {
      this.prepare(effect)
    }
  }

  private prepareNextIfNeeded(): void {
    if (!this.hasStartedPlayback || this.queue.length === 0) {
      return
    }
    this.prepare(this.queue[0])
  }

  private prepare(effect: Effect): void {
    if (effect.task !== undefined || effect.result !== undefined) {
      return
    }
    effect.task = this.giftPlayer.prepare(effect.resourceURL, (result: TCGiftPreparationResult) => {
      effect.task = undefined
      effect.result = result
      this.consumePreparation(effect)
    })
  }

  private consumePreparation(effect: Effect): void {
    const result = effect.result
    if (this.currentEffect !== effect || result === undefined) {
      return
    }
    const resource = result.resource
    if (resource === undefined) {
      LiveKitLog.error(`Gift preparation failed: ${result.error?.message ?? ''}`)
      this.finishCurrentEffect()
      return
    }
    this.giftPlayer.play(resource, (event: TCGiftPlaybackEvent) => {
      if (this.currentEffect !== effect) {
        return
      }
      if (event.type === TCGiftPlaybackEventType.started) {
        this.hasStartedPlayback = true
        this.scheduleTimeout(effect)
        this.prepareNextIfNeeded()
      } else if (event.type === TCGiftPlaybackEventType.finished) {
        this.finishCurrentEffect()
      } else {
        LiveKitLog.error(`Gift playback failed: ${event.error?.message ?? ''}`)
        this.finishCurrentEffect()
      }
    })
  }

  private scheduleTimeout(effect: Effect): void {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      if (this.currentEffect === effect) {
        LiveKitLog.error('Gift effect timed out')
        this.finishCurrentEffect()
      }
    }, effectTimeout)
  }

  private finishCurrentEffect(): void {
    this.clearCurrentEffect()
    this.playNextIfNeeded()
  }

  private clearCurrentEffect(): void {
    const previous = this.currentEffect
    this.currentEffect = undefined
    clearTimeout(this.timeout)
    this.timeout = -1
    this.hasStartedPlayback = false
    this.giftPlayer.stop()
    previous?.dispose()
  }
}

@Component
export struct GiftAnimationView {
  @ObjectLink controller: GiftAnimationController

  aboutToDisappear(): void {
    this.controller.reset()
  }

  build() {
    Stack() {
      TCGiftPlayerView({ player: this.controller.giftPlayer })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
