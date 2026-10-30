import { curves } from '@kit.ArkUI'
import { LiveKitResources } from '../LiveKitResources'
import { LevelBadgeView } from '../theme/LevelBadgeView'
import { LiveText } from '../theme/LiveText'
import { LiveTheme, rgba } from '../theme/LiveTheme'

export class AudienceWelcome {
  userID: string
  userName: string
  level: number

  constructor(userID: string, userName: string, level: number) {
    this.userID = userID
    this.userName = userName
    this.level = level
  }
}

class AudienceWelcomeTier {
  backgroundColors: string[]
  borderColor: string
  borderWidth: number
  shadowColor: string
  shadowRadius: number
  actionTextColor: string

  constructor(level: number) {
    const isPremium = level >= 25 && level < 40
    const isElite = level >= 40
    this.backgroundColors = isElite
      ? [rgba(0.59, 0.36, 0.14, 0.82), rgba(0.53, 0.28, 0.61, 0.72), rgba(0.15, 0.1, 0.27, 0.56)]
      : isPremium
        ? [rgba(0.31, 0.22, 0.67, 0.82), rgba(0.5, 0.25, 0.72, 0.7), rgba(0.12, 0.08, 0.23, 0.54)]
        : [rgba(0.04, 0.04, 0.06, 0.34), rgba(0.04, 0.04, 0.06, 0.34), rgba(0.04, 0.04, 0.06, 0.34)]
    this.borderWidth = isElite || isPremium ? 1 : 0
    this.borderColor = isElite ? rgba(1, 0.9, 0.62, 0.3) : isPremium ? rgba(0.83, 0.68, 1, 0.2) : 'rgba(0,0,0,0)'
    this.shadowColor = isElite ? rgba(0.86, 0.58, 0.27, 0.18) : 'rgba(0,0,0,0)'
    this.shadowRadius = isElite ? 8 : 0
    this.actionTextColor = isElite ? rgba(1, 0.973, 0.867) : rgba(0.949, 0.961, 0.98)
  }
}

@Component
export struct AudienceWelcomeView {
  @Prop @Watch('onWelcomeChanged') welcome: AudienceWelcome | undefined = undefined
  @Prop @Watch('reset') resetToken: number = 0
  onVisibilityChanged?: (isVisible: boolean) => void
  @State private current: AudienceWelcome | undefined = undefined
  @State private bannerOpacity: number = 0
  @State private bannerOffsetX: number = 0
  private queue: AudienceWelcome[] = []
  private activeToken: number = 0
  private isActive: boolean = false
  private isWelcomeVisible: boolean = false
  private animationTasks: number[] = []
  private bannerLaidOut: boolean = false
  private isMounted: boolean = false

  aboutToAppear(): void {
    this.isMounted = true
    this.onWelcomeChanged()
  }

  aboutToDisappear(): void {
    this.isMounted = false
    this.reset()
  }

  private tier(): AudienceWelcomeTier {
    return new AudienceWelcomeTier(this.current?.level ?? 0)
  }

  private onWelcomeChanged(): void {
    if (this.welcome !== undefined) {
      this.enqueue(this.welcome)
    }
  }

  enqueue(welcome: AudienceWelcome): void {
    this.queue.push(welcome)
    this.showNextIfNeeded()
  }

  reset(): void {
    this.activeToken++
    this.animationTasks.forEach((task: number) => clearTimeout(task))
    this.animationTasks = []
    this.bannerLaidOut = false
    this.isActive = false
    this.queue = []
    this.bannerOpacity = 0
    this.bannerOffsetX = 0
    this.current = undefined
    this.updateWelcomeVisibility(false)
  }

  private showNextIfNeeded(): void {
    if (!this.isMounted || this.isActive || this.queue.length === 0) {
      return
    }
    const welcome = this.queue.shift()!
    ++this.activeToken
    this.isActive = true
    this.current = welcome
    this.updateWelcomeVisibility(true)
    this.bannerOpacity = 0
    this.bannerOffsetX = -(228 + 24)
    if (this.bannerLaidOut) {
      this.scheduleAnimation()
    }
  }

  private scheduleAnimation(): void {
    const token = this.activeToken
    this.animationTasks.push(setTimeout(() => {
      if (this.isMounted && this.activeToken === token) {
        this.startAnimation(token)
      }
    }, 0))
  }

  private startAnimation(token: number): void {
    this.animationTasks = []
    this.getUIContext().animateTo({ duration: 420, curve: Curve.EaseOut }, () => this.bannerOpacity = 1)
    this.getUIContext().animateTo({ duration: 680, curve: curves.cubicBezierCurve(0.18, 0.78, 0.22, 1) },
      () => this.bannerOffsetX = 0)
    this.animationTasks.push(setTimeout(() => {
      if (this.activeToken !== token) {
        return
      }
      this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseIn }, () => {
        this.bannerOpacity = 0
        this.bannerOffsetX = -30
      })
      this.animationTasks.push(setTimeout(() => {
        if (this.activeToken !== token) {
          return
        }
        this.isActive = false
        this.bannerOffsetX = 0
        if (this.queue.length === 0) {
          this.current = undefined
          this.bannerLaidOut = false
          this.updateWelcomeVisibility(false)
        } else {
          this.showNextIfNeeded()
        }
      }, 360))
    }, 3200))
  }

  private updateWelcomeVisibility(isVisible: boolean): void {
    if (this.isWelcomeVisible === isVisible) {
      return
    }
    this.isWelcomeVisible = isVisible
    this.onVisibilityChanged?.(isVisible)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.current !== undefined) {
        Row() {
          LevelBadgeView({ level: this.current.level })
          Text(this.current.userName.length === 0 ? this.current.userID : this.current.userName)
            .attributeModifier(new LiveText(LiveTheme.TextRole.action))
            .fontColor(LiveTheme.Color.nickname)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .flexShrink(1)
            .margin({ left: 5 })
          Text(LiveKitResources.localizedString('tuilivekit.pusher.living.audience_entered'))
            .attributeModifier(new LiveText(LiveTheme.TextRole.action))
            .fontColor(this.tier().actionTextColor)
            .flexShrink(0)
            .margin({ left: 6 })
        }
        .width(228)
        .height(28)
        .padding({ left: 9, right: 9 })
        .margin({ left: 12 })
        .borderRadius(12)
        .borderWidth(this.tier().borderWidth)
        .borderColor(this.tier().borderColor)
        .linearGradient({
          angle: 104,
          colors: [[this.tier().backgroundColors[0], 0],
            [this.tier().backgroundColors[1], 0.58],
            [this.tier().backgroundColors[2], 1]],
        })
        .shadow({
          radius: this.tier().shadowRadius,
          color: this.tier().shadowColor,
        })
        .opacity(this.bannerOpacity)
        .translate({ x: this.bannerOffsetX })
        .onAreaChange(() => {
          if (!this.bannerLaidOut) {
            this.bannerLaidOut = true
            this.scheduleAnimation()
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
