import { AnimatorResult, curves } from '@kit.ArkUI'
import { LikeListener, LikeStore, LiveUserInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../LiveKitResources'

const mainSize: number = 52
const mainDuration: number = 660
const auxiliarySize: number = 24
const maximumAuxiliaryCount: number = 14
const buttonSize: number = 36
const maximumButtonCount: number = 14
const reactionAssetNames: string[] = ['livekit_like_thumb', 'livekit_like_thumb', 'livekit_like_heart',
  'livekit_like_heart', 'livekit_like_double_heart', 'livekit_like_fire', 'livekit_like_sparkle']

enum Kind {
  main,
  auxiliary,
  button,
}

class Frame {
  duration: number
  curve: Curve | ICurve
  x: number
  y: number
  scale: number
  rotation: number
  opacity: number

  constructor(duration: number, x: number, y: number, scale: number, rotation: number, opacity: number,
    curve: Curve | ICurve = Curve.Linear) {
    this.duration = duration
    this.x = x
    this.y = y
    this.scale = scale
    this.rotation = rotation
    this.opacity = opacity
    this.curve = curve
  }
}

let reactionSeed: number = 0

function random(lower: number, upper: number): number {
  return lower + Math.random() * (upper - lower)
}

@Observed
class Reaction {
  id: number = ++reactionSeed
  kind: Kind
  assetName: string
  left: number
  top: number
  size: number
  x: number = 0
  y: number = 0
  scale: number = 1
  rotation: number = 0
  opacity: number = 1
  frames: Frame[]

  constructor(kind: Kind, assetName: string, left: number, top: number, size: number, initial: Frame, frames: Frame[]) {
    this.kind = kind
    this.assetName = assetName
    this.left = left
    this.top = top
    this.size = size
    this.frames = frames
    this.apply(initial)
  }

  apply(frame: Frame): void {
    this.x = frame.x
    this.y = frame.y
    this.scale = frame.scale
    this.rotation = frame.rotation
    this.opacity = frame.opacity
  }

  get duration(): number {
    return this.frames.reduce((total: number, frame: Frame) => total + frame.duration, 0)
  }
}

@Observed
export class LikeAnimationController {
  reactions: Reaction[] = []
  private likeStore?: LikeStore
  private likeListener?: LikeListener
  private auxiliaryOriginProvider?: () => Position
  private isAttached: boolean = false
  private burstTasks: number[] = []
  private generation: number = 0

  attach(): void {
    this.isAttached = true
  }

  detach(): void {
    this.isAttached = false
    this.removeAllAnimations()
  }

  activate(liveID: string, auxiliaryOriginProvider: () => Position): void {
    this.deactivate()
    this.auxiliaryOriginProvider = auxiliaryOriginProvider
    const store = LikeStore.create(liveID)
    this.likeStore = store
    const listener = new LikeListener()
    listener.onReceiveLikesMessage = (eventLiveID: string, totalLikesReceived: number, sender: LiveUserInfo) => {
      if (this.likeListener === listener && eventLiveID === liveID) {
        const origin = this.auxiliaryOriginProvider?.() ?? { x: 0, y: 0 } as Position
        this.showReceivedLikes(Math.min(totalLikesReceived, 6), origin)
      }
    }
    this.likeListener = listener
    store.addLikeListener(listener)
  }

  deactivate(): void {
    this.removeAllAnimations()
    if (this.likeListener !== undefined) {
      this.likeStore?.removeLikeListener(this.likeListener)
      this.likeListener = undefined
    }
    this.likeStore = undefined
    this.auxiliaryOriginProvider = undefined
  }

  showStageLike(point: Position, auxiliaryOrigin: Position): void {
    const assetName = this.randomAssetName()
    this.showMainReaction(point, assetName)
    this.showAuxiliaryReaction(auxiliaryOrigin, assetName)
  }

  showReceivedLikes(count: number, auxiliaryOrigin: Position): void {
    const generation = this.generation
    const animationCount = Math.min(6, Math.max(1, count))
    for (let index = 0; index < animationCount; index++) {
      const task = setTimeout(() => {
        this.burstTasks = this.burstTasks.filter((pending: number) => pending !== task)
        if (this.isAttached && this.generation === generation) {
          this.showAuxiliaryReaction(auxiliaryOrigin, this.randomAssetName())
        }
      }, index * 120)
      this.burstTasks.push(task)
    }
  }

  showButtonLike(origin: Position): void {
    this.showButtonReaction(origin, this.randomAssetName())
  }

  removeAllAnimations(): void {
    this.generation += 1
    this.burstTasks.forEach((task: number) => clearTimeout(task))
    this.burstTasks = []
    this.reactions = []
  }

  remove(reaction: Reaction): void {
    this.reactions = this.reactions.filter((item: Reaction) => item !== reaction)
  }

  private add(reaction: Reaction, limit: number): void {
    const sameKind = this.reactions.filter((item: Reaction) => item.kind === reaction.kind)
    const overflow = sameKind.length >= limit ? sameKind[0] : undefined
    this.reactions = this.reactions.filter((item: Reaction) => item !== overflow).concat([reaction])
  }

  private showMainReaction(point: Position, assetName: string): void {
    const total = mainDuration
    this.add(new Reaction(Kind.main, assetName, (point.x as number) - mainSize * 0.5, (point.y as number) - mainSize,
      mainSize, new Frame(0, 0, 0, 0.04, -28, 1), [
        new Frame(total * 0.30303, 0, 0, 1, -28, 1, curves.cubicBezierCurve(0.2, 0.82, 0.32, 1)),
        new Frame(total * (0.51515 - 0.30303), 0, 0, 1, 8, 1, curves.cubicBezierCurve(0.18, 0.72, 0.24, 1)),
        new Frame(total * (0.65152 - 0.51515), 0, 0, 1, -4, 1, curves.cubicBezierCurve(0.24, 0.76, 0.3, 1)),
        new Frame(total * (1 - 0.65152), 0, -6, 1.18, -4, 0, Curve.EaseOut),
      ]), Number.MAX_SAFE_INTEGER)
  }

  private showAuxiliaryReaction(origin: Position, assetName: string): void {
    const rise = random(120, 140)
    const duration = random(1800, 2050)
    this.add(new Reaction(Kind.auxiliary, assetName, (origin.x as number) + random(-8, 8) - auxiliarySize * 0.5,
      (origin.y as number) - auxiliarySize * 0.5, auxiliarySize, new Frame(0, 0, 0, 1, 0, 0.38), [
        new Frame(duration * 0.34, -random(4, 6), -rise * 0.34, 1, 0, 0.38),
        new Frame(duration * 0.32, -random(1, 3), -rise * 0.66, 1, 0, 0.38),
        new Frame(duration * 0.12, -random(5, 7), -rise * 0.78, 1, 0, 0.38),
        new Frame(duration * 0.22, -random(3, 5), -rise, 1, 0, 0),
      ]), maximumAuxiliaryCount)
  }

  private showButtonReaction(origin: Position, assetName: string): void {
    const rise = random(120, 150)
    const duration = random(1500, 1700)
    this.add(new Reaction(Kind.button, assetName, (origin.x as number) + random(-5, 5) - buttonSize * 0.5,
      (origin.y as number) - buttonSize * 0.5, buttonSize, new Frame(0, 0, 0, 0.2, 0, 1), [
        new Frame(duration * 0.125, 0, -70, 1, 0, 1, curves.cubicBezierCurve(0.16, 0.78, 0.24, 1)),
        new Frame(duration * 0.2975, -random(4, 6), -(70 + rise * 0.34), 1, 0, 0.66),
        new Frame(duration * 0.28, -random(1, 3), -(70 + rise * 0.66), 1, 0, 0.34),
        new Frame(duration * 0.105, -random(5, 7), -(70 + rise * 0.78), 1, 0, 0.22),
        new Frame(duration * 0.1925, -random(3, 5), -(70 + rise), 1, 0, 0),
      ]), maximumButtonCount)
  }

  private randomAssetName(): string {
    return reactionAssetNames[Math.floor(Math.random() * reactionAssetNames.length)]
  }
}

@Component
struct ReactionView {
  @ObjectLink reaction: Reaction
  onFinished?: () => void
  @State private buttonFrame: Frame = new Frame(0, 0, 0, 0.2, 0, 1)
  @State private isImageReady: boolean = false
  private startTask: number = -1
  private finishTask: number = -1
  private hasStarted: boolean = false
  private hasAppeared: boolean = false
  private isDisposed: boolean = false
  private buttonAnimator?: AnimatorResult

  aboutToDisappear(): void {
    this.isDisposed = true
    this.hasAppeared = false
    clearTimeout(this.startTask)
    clearTimeout(this.finishTask)
    const animation = this.buttonAnimator
    this.buttonAnimator = undefined
    animation?.cancel()
  }

  private startAnimation(): void {
    if (this.hasStarted || this.isDisposed || !this.hasAppeared || !this.isImageReady) {
      return
    }
    this.hasStarted = true
    this.startTask = setTimeout(() => {
      if (this.isDisposed) {
        return
      }
      if (this.reaction.kind === Kind.button) {
        this.startButtonAnimation()
        return
      }
      const keyframes: KeyframeState[] = this.reaction.frames.map((frame: Frame): KeyframeState => {
        const state: KeyframeState =
          { duration: frame.duration, curve: frame.curve, event: () => this.reaction.apply(frame) }
        return state
      })
      this.getUIContext().keyframeAnimateTo({ iterations: 1 }, keyframes)
      this.finishTask = setTimeout(() => this.onFinished?.(), this.reaction.duration)
    }, 0)
  }

  private startButtonAnimation(): void {
    const context = this.getUIContext()
    const animation = context.createAnimator({
      duration: Math.round(this.reaction.duration),
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1,
    })
    this.buttonAnimator = animation
    animation.onFrame = (progress: number) => {
      context.runScopedTask(() => {
        if (!this.isDisposed && this.buttonAnimator === animation) {
          this.applyButtonProgress(progress)
        }
      })
    }
    animation.onFinish = () => {
      context.runScopedTask(() => {
        if (this.isDisposed || this.buttonAnimator !== animation) {
          return
        }
        this.applyButtonProgress(1)
        this.buttonAnimator = undefined
        this.onFinished?.()
      })
    }
    this.applyButtonProgress(0)
    animation.play()
  }

  private applyButtonProgress(progress: number): void {
    const elapsed = Math.min(Math.max(progress, 0), 1) * this.reaction.duration
    let startedAt = 0
    let previous = new Frame(0, 0, 0, 0.2, 0, 1)
    const frames = this.reaction.frames
    for (let index = 0; index < frames.length; index++) {
      const frame = frames[index]
      if (elapsed <= startedAt + frame.duration || index === frames.length - 1) {
        const fraction = Math.min(Math.max((elapsed - startedAt) / frame.duration, 0), 1)
        const motion = index === 0 ? (frame.curve as ICurve).interpolate(fraction) : fraction
        this.buttonFrame = new Frame(0,
          previous.x + (frame.x - previous.x) * motion,
          previous.y + (frame.y - previous.y) * motion,
          previous.scale + (frame.scale - previous.scale) * motion,
          previous.rotation + (frame.rotation - previous.rotation) * motion,
          previous.opacity + (frame.opacity - previous.opacity) * fraction)
        return
      }
      startedAt += frame.duration
      previous = frame
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(LiveKitResources.image(this.reaction.assetName))
        .width(this.reaction.size)
        .height(this.reaction.size)
        .objectFit(ImageFit.Contain)
        .rotate({ angle: this.reaction.kind === Kind.button ? this.buttonFrame.rotation : this.reaction.rotation,
          centerX: '50%', centerY: this.reaction.kind === Kind.main ? '62%' : '50%' })
        .scale({
          x: this.reaction.kind === Kind.button ? this.buttonFrame.scale : this.reaction.scale,
          y: this.reaction.kind === Kind.button ? this.buttonFrame.scale : this.reaction.scale,
          centerX: '50%',
          centerY: this.reaction.kind === Kind.main ? '62%' : '50%'
        })
        .opacity(this.isImageReady ? (this.reaction.kind === Kind.button ? this.buttonFrame.opacity : this.reaction.opacity) : 0)
        .onComplete((event) => {
          if (!this.isDisposed && event?.loadingStatus === 1) {
            this.isImageReady = true
            this.startAnimation()
          }
        })
        .onError(() => {
          if (!this.isDisposed) {
            this.onFinished?.()
          }
        })
    }
    .width(this.reaction.size)
    .height(this.reaction.size)
    .translate({
      x: this.reaction.kind === Kind.button ? this.buttonFrame.x : this.reaction.x,
      y: this.reaction.kind === Kind.button ? this.buttonFrame.y : this.reaction.y,
    })
    .onAppear(() => {
      this.hasAppeared = true
      this.startAnimation()
    })
  }
}

@Component
export struct LikeAnimationView {
  @ObjectLink controller: LikeAnimationController

  aboutToAppear(): void {
    this.controller.attach()
  }

  aboutToDisappear(): void {
    this.controller.detach()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.controller.reactions, (reaction: Reaction) => {
        ReactionView({ reaction: reaction, onFinished: () => this.controller.remove(reaction) })
          .width(reaction.size)
          .height(reaction.size)
          .position({ x: reaction.left, y: reaction.top })
      }, (reaction: Reaction) => `${reaction.id}`)
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.BLOCK_DESCENDANTS)
  }
}
