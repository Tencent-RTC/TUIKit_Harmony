import { CoGuestLayoutTemplate } from '@tencentcloud/atomicxcore'
import measure from '@ohos.measure'
import { LiveKitResources, LiveKitSafeArea } from '../../../../common/LiveKitResources'
import { BottomSheetView } from '../../../../common/theme/BottomSheetView'
import { LiveText } from '../../../../common/theme/LiveText'
import { LiveTheme, rgba, white } from '../../../../common/theme/LiveTheme'
import {
  allLayouts,
  LayoutInfo,
  PusherCoGuestActionHandling,
  State as CoGuestState,
  User
} from '../PusherCoGuestStore'
import {
  ActionStyle,
  preferredHeight,
  PusherCoGuestGroupStyle,
  PusherCoGuestUserSectionView,
  UserRow
} from './PusherCoGuestUserSectionView'

const scrollTopInset: number = 78
const scrollBottomInset: number = 16
const sectionSpacing: number = 12
const layoutSectionHeight: number = 162
const maximumPanelHeight: number = 654
const minimumTopGap: number = 80

@Component
export struct PusherCoGuestSettingsView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop state: CoGuestState = new CoGuestState()
  actionHandler?: PusherCoGuestActionHandling
  onDismiss?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private containerHeight: number = 0
  @State private containerWidth: number = 0
  private readonly scroller: Scroller = new Scroller()

  private onPresentedChanged(): void {
    if (this.isPresented) {
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    }
  }

  private rows(users: User[], titleKey: string, style: ActionStyle, enabled: boolean = true): UserRow[] {
    return users.map((user: User) => new UserRow(user, LiveKitResources.localizedString(titleKey), style,
      this.state.pendingUserIDs.includes(user.userID), enabled))
  }

  private connectedRows(): UserRow[] {
    return this.rows(this.state.connected, 'tuilivekit.pusher.coguest.end', ActionStyle.destructive)
  }

  private applicantRows(): UserRow[] {
    return this.rows(this.state.applicants, 'tuilivekit.pusher.coguest.accept', ActionStyle.primary, !this.state.isFull)
  }

  private candidateRows(): UserRow[] {
    return this.rows(this.state.invitees, 'tuilivekit.pusher.coguest.cancel_invitation', ActionStyle.destructive)
      .concat(
        this.rows(this.state.candidates, 'tuilivekit.pusher.coguest.invite', ActionStyle.primary, !this.state.isFull))
  }

  private sheetHeight(): number {
    const sections: UserRow[][] = [this.connectedRows()]
    if (this.applicantRows().length > 0) {
      sections.push(this.applicantRows())
    }
    if (this.candidateRows().length > 0) {
      sections.push(this.candidateRows())
    }
    const contentHeight = layoutSectionHeight +
      sections.reduce((sum: number, rows: UserRow[]) => sum + sectionSpacing + preferredHeight(rows), 0)
    const target = scrollTopInset + contentHeight + scrollBottomInset + this.safeBottom
    const available = this.containerHeight > 0 ? this.containerHeight - minimumTopGap : maximumPanelHeight
    return Math.min(Math.min(maximumPanelHeight, available), target)
  }

  private titleInset(): number {
    const width = measure.measureText({
      textContent: LiveKitResources.localizedString('tuilivekit.pusher.coguest.end_all'),
      fontSize: LiveTheme.Typography.size(LiveTheme.TextRole.action)
    })
    return 16 + 8 + Math.max(88, this.getUIContext().px2vp(width))
  }

  private titleWidth(): number {
    const measured = measure.measureText({
      textContent: LiveKitResources.localizedString('tuilivekit.pusher.coguest.settings'),
      fontSize: LiveTheme.Typography.size(LiveTheme.TextRole.sheetTitle), fontWeight: 600
    })
    return Math.max(0, Math.min(this.getUIContext().px2vp(measured), this.containerWidth - this.titleInset() - 16))
  }

  private titleLeft(): number {
    return Math.max(16, Math.min((this.containerWidth - this.titleWidth()) / 2,
      this.containerWidth - this.titleInset() - this.titleWidth()))
  }

  private isEndAllEnabled(): boolean {
    return !this.state.connected.every((user: User) => this.state.pendingUserIDs.includes(user.userID))
  }

  @Builder
  groupHighlight() {
    Column().height(1).width('calc(100% - 32vp)')
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [[white(0), 0], [white(0.10), 0.5], [white(0), 1]]
      })
      .hitTestBehavior(HitTestMode.None)
  }

  build() {
    Stack() {
      BottomSheetView({
        isPresented: this.isPresented,
        sheetHeight: this.sheetHeight(),
        onDismiss: () => this.onDismiss?.(),
      }) {
          Stack({ alignContent: Alignment.TopStart }) {
            Text(LiveKitResources.localizedString('tuilivekit.pusher.coguest.settings'))
              .attributeModifier(
                new LiveText(LiveTheme.TextRole.sheetTitle, LiveTheme.TextTone.primary, TextAlign.Center))
              .minFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.sheetTitle) * 0.8)
              .maxFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.sheetTitle))
              .maxLines(1)
              .width(this.titleWidth())
              .height(20)
              .position({ x: this.titleLeft(), y: 36 })
            if (this.state.connected.length > 0) {
              Text(LiveKitResources.localizedString('tuilivekit.pusher.coguest.end_all'))
                .attributeModifier(new LiveText(LiveTheme.TextRole.action, LiveTheme.TextTone.primary, TextAlign.End))
                .fontColor(rgba(0.898, 0.420, 0.451))
                .constraintSize({ minWidth: 88 })
                .height(20)
                .position({ right: 16, top: 36 })
                .enabled(this.isEndAllEnabled())
                .opacity(this.isEndAllEnabled() ? 1 : 0.46)
                .onClick(() => this.actionHandler?.endAllConnections())
            }
            List({ space: sectionSpacing, scroller: this.scroller }) {
              ListItem() {
                Stack({ alignContent: Alignment.TopStart }) {
                  Text(LiveKitResources.localizedString('tuilivekit.pusher.coguest.layout'))
                    .attributeModifier(new LiveText(LiveTheme.TextRole.sectionTitle, LiveTheme.TextTone.secondary))
                    .height(15)
                    .position({ x: 16, y: 16 })
                  Column({ space: 8 }) {
                    ForEach([0, 2], (start: number) => {
                      Row({ space: 8 }) {
                        ForEach(allLayouts.slice(start, start + 2), (layout: CoGuestLayoutTemplate) => {
                          CoGuestLayoutControl({
                            layout: layout,
                            isSelected: this.state.layout.templateId === layout.templateId,
                            isUpdatingLayout: this.state.isUpdatingLayout,
                            onSelect: () => this.actionHandler?.selectLayout(layout),
                          })
                        }, (layout: CoGuestLayoutTemplate) => `${layout.templateId}`)
                      }
                        .width('100%')
                        .layoutWeight(1)
                    }, (start: number) => `${start}`)
                  }
                    .width('100%')
                    .height(104)
                    .padding({ left: 16, right: 16 })
                    .position({ x: 0, y: 42 })
                }
                  .width('100%')
                  .height(layoutSectionHeight)
                  .borderRadius(PusherCoGuestGroupStyle.cornerRadius)
                  .backgroundColor(PusherCoGuestGroupStyle.background)
                  .overlay(this.groupHighlight(), { align: Alignment.Top })
              }

              PusherCoGuestUserSectionView({
                sectionTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.connected'),
                emptyText: LiveKitResources.localizedString('tuilivekit.pusher.coguest.empty'),
                showsCount: true,
                rows: this.connectedRows(),
                onAction: (userID: string) => this.actionHandler?.disconnect(userID),
              })
              if (this.applicantRows().length > 0) {
                PusherCoGuestUserSectionView({
                  sectionTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.applicants'),
                  rows: this.applicantRows(),
                  onAction: (userID: string) => this.actionHandler?.acceptApplication(userID),
                })
              }
              if (this.candidateRows().length > 0) {
                PusherCoGuestUserSectionView({
                  sectionTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.candidates'),
                  rows: this.candidateRows(),
                  onAction: (userID: string) => {
                    if (this.state.invitees.some((user: User) => user.userID === userID)) {
                      this.actionHandler?.cancelInvitation(userID)
                    } else {
                      this.actionHandler?.invite(userID)
                    }
                  },
                })
              }
            }
              .padding({ left: 16, right: 16 })
              .scrollBar(BarState.Off)
              .align(Alignment.Top)
              .width('100%')
              .height(this.sheetHeight() - scrollTopInset - scrollBottomInset - this.safeBottom)
              .position({ x: 0, y: scrollTopInset })
          }
            .width('100%')
            .height('100%')
        }
    }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .onAreaChange((_: Area, area: Area) => {
        this.containerHeight = area.height as number
        this.containerWidth = area.width as number
      })
  }
}

@Component
  struct CoGuestLayoutControl {
  @Prop layout: CoGuestLayoutTemplate = CoGuestLayoutTemplate.dynamicLayout
  @Prop isSelected: boolean = false
  @Prop isUpdatingLayout: boolean = false
  onSelect?: () => void

  build() {
    Stack() {
      Row({ space: 8 }) {
        Image(LiveKitResources.image(LayoutInfo.assetName(this.layout)))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .fillColor(this.isSelected ? rgba(0.557, 0.812, 1) : white(0.72))
        Text(LayoutInfo.title(this.layout))
          .attributeModifier(new LiveText(LiveTheme.TextRole.itemTitle, LiveTheme.TextTone.secondary, TextAlign.Start,
            this.isSelected))
          .fontColor(this.isSelected ? rgba(0.557, 0.812, 1) : white(0.72))
          .maxLines(2)
          .minFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.itemTitle) * 0.85)
          .maxFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.itemTitle))
          .layoutWeight(1)
      }
        .width('100%')
        .height('100%')
        .padding({
          left: 12,
          right: 12,
          top: 4,
          bottom: 4
        })

      CoGuestLayoutBorder({ isSelected: this.isSelected })
    }
      .layoutWeight(1)
      .height('100%')
      .borderRadius(12)
      .backgroundColor('rgba(0, 0, 0, 0.22)')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: this.isSelected ? [[LiveTheme.Color.brand(0.26), 0], [rgba(0, 0.32, 0.85, 0.16), 1]] :
          [[white(0.05), 0], [white(0.015), 1]],
      })
      .enabled(!this.isUpdatingLayout)
      .onClick(() => this.onSelect?.())
  }
}

@Component
  struct CoGuestLayoutBorder {
  @Prop @Watch('draw') isSelected: boolean = false
  private readonly context: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private canvasWidth: number = 0
  private canvasHeight: number = 0

  private draw(): void {
    const ctx = this.context
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight)
    if (this.canvasWidth <= 0 || this.canvasHeight <= 0) {
      return
    }
    const lineWidth = this.isSelected ? 1.5 : 1
    const inset = lineWidth / 2
    const radius = 12 - inset
    const right = this.canvasWidth - inset
    const bottom = this.canvasHeight - inset
    const gradient = ctx.createLinearGradient(0, this.canvasHeight, this.canvasWidth, 0)
    gradient.addColorStop(0, LiveTheme.Color.brandDeepBlue)
    gradient.addColorStop(0.5, LiveTheme.Color.brandBlue)
    gradient.addColorStop(1, LiveTheme.Color.brandCyan)
    ctx.strokeStyle = this.isSelected ? gradient : white(0.14)
    ctx.lineWidth = lineWidth
    ctx.beginPath()
    ctx.moveTo(inset + radius, inset)
    ctx.arcTo(right, inset, right, bottom, radius)
    ctx.arcTo(right, bottom, inset, bottom, radius)
    ctx.arcTo(inset, bottom, inset, inset, radius)
    ctx.arcTo(inset, inset, right, inset, radius)
    ctx.closePath()
    ctx.stroke()
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
      .onReady(() => this.draw())
      .onAreaChange((_: Area, area: Area) => {
        this.canvasWidth = area.width as number
        this.canvasHeight = area.height as number
        this.draw()
      })
  }
}
