import { ParticipantRole, RoomParticipantState, RoomParticipantStore, RoomStore } from '@tencentcloud/atomicxcore'
import { RoomLeavePopoverView, RoomLeavePopoverAlign } from './RoomLeavePopoverView'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomToast } from '../../../../base/toast/RoomToast'

enum RoomLeaveKind {
  SELF,
  ALL,
}

@Component
export struct RoomLeaveRoomButton {
  @Prop @Watch('bindRoom') roomID: string = ''
  onLeaveOrEnd?: () => void
  @State private participantState?: RoomParticipantState = undefined
  @State private isOpen: boolean = false
  @State private isPressed: boolean = false
  @State private isEndPressed: boolean = false
  @State private isLeavePressed: boolean = false

  aboutToAppear(): void {
    this.bindRoom()
  }

  aboutToDisappear(): void {
    this.isOpen = false
  }

  private bindRoom(): void {
    this.isOpen = false
    this.participantState = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID).state : undefined
  }

  private isOwner(): boolean {
    return this.participantState?.localParticipant?.role === ParticipantRole.owner
  }

  private leave(kind: RoomLeaveKind): void {
    const request = kind === RoomLeaveKind.ALL ? RoomStore.shared().endRoom() : RoomStore.shared().leaveRoom()
    const complete = () => {
      RoomToast.show(RoomResources.string(kind === RoomLeaveKind.ALL ? 'roomkit_main_ended' : 'roomkit_main_left'))
      this.onLeaveOrEnd?.()
    }
    request.then(complete).catch(complete)
  }

  private handleTap(): void {
    if (!this.isOwner()) {
      this.leave(RoomLeaveKind.SELF)
      return
    }
    this.isOpen = !this.isOpen
  }

  private menuItemColor(isDanger: boolean, kind: RoomLeaveKind): ResourceColor {
    const pressed = kind === RoomLeaveKind.ALL ? this.isEndPressed : this.isLeavePressed
    if (isDanger) {
      return pressed ? $r('app.color.roomkit_danger_pressed') : $r('app.color.roomkit_danger')
    }
    return pressed ? $r('app.color.roomkit_bg_press') : $r('app.color.roomkit_bg_hover')
  }

  @Builder
  menuItem(title: string, isDanger: boolean, kind: RoomLeaveKind) {
    Stack() {
      Text(title)
        .fontSize(15)
        .fontWeight(500)
        .fontColor(isDanger ? $r('app.color.roomkit_fg_on_danger') : $r('app.color.roomkit_fg_primary'))
    }
    .width('100%')
    .height(44)
    .borderRadius(12)
    .backgroundColor(this.menuItemColor(isDanger, kind))
    .onTouch((event: TouchEvent) => {
      const pressed = event.type === TouchType.Down
      if (kind === RoomLeaveKind.ALL) {
        this.isEndPressed = pressed
      } else {
        this.isLeavePressed = pressed
      }
    })
    .onClick(() => {
      this.isOpen = false
      this.leave(kind)
    })
  }

  @Builder
  menuContent() {
    Column({ space: 6 }) {
      this.menuItem(RoomResources.string('roomkit_main_leave_end'), true, RoomLeaveKind.ALL)
      this.menuItem(RoomResources.string('roomkit_main_leave_self'), false, RoomLeaveKind.SELF)
    }
    .width('100%')
  }

  @Builder
  triggerContent() {
    Stack() {
      Image(RoomResources.image('roomkit_icon_end_call'))
        .width(15)
        .height(15)
        .opacity(this.isOpen ? 0 : 1)
      Text(RoomResources.string('roomkit_common_cancel'))
        .fontSize(13)
        .fontWeight(600)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .opacity(this.isOpen ? 1 : 0)
    }
    .constraintSize({ minWidth: 54 })
    .height(28)
    .padding({ left: 14, right: 14 })
    .borderRadius(14)
    .backgroundColor(this.isOpen ? $r('app.color.roomkit_bg_press') :
      (this.isPressed ? $r('app.color.roomkit_danger_pressed') : $r('app.color.roomkit_danger')))
    .scale({ x: this.isPressed ? 0.97 : 1, y: this.isPressed ? 0.97 : 1 })
    .animation({ duration: 80 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => this.handleTap())
  }

  build() {
    RoomLeavePopoverView({
      isPresented: this.isOpen,
      popoverAlign: RoomLeavePopoverAlign.END,
      gap: 8,
      minWidth: 176,
      showsArrow: false,
      onClose: () => {
        this.isOpen = false
      },
      anchor: (): void => this.triggerContent(),
      content: (): void => this.menuContent(),
    })
  }
}
