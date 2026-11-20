import { NetworkQuality, RoomParticipant } from '@tencentcloud/atomicxcore'
import { RoomParticipantCell } from './RoomParticipantCell'
import {
  RoomFloatingPosition,
  RoomFloatingSide,
  RoomItemRect,
  RoomParticipantLayout,
  RoomStageSize,
} from './RoomParticipantLayout'

@Component
export struct RoomParticipantFloatView {
  @Prop roomID: string = ''
  @Prop @Watch('onParticipantChanged') participant: RoomParticipant = new RoomParticipant()
  @Prop isLocal: boolean = false
  @Prop volume: number = 0
  @Prop networkQuality: NetworkQuality = NetworkQuality.unknown
  @Prop isPlaying: boolean = false
  @Prop stageWidth: number = 0
  @Prop stageHeight: number = 0
  @Prop settledPosition: RoomFloatingPosition = { side: RoomFloatingSide.RIGHT, verticalFraction: 0 }
  @State private isDragging: boolean = false
  @State private dragLeft: number = 0
  @State private dragTop: number = 0
  @State private cellParticipant?: RoomParticipant = undefined
  onPositionChange?: (position: RoomFloatingPosition) => void
  private dragStart?: RoomItemRect
  private cellSyncTimer: number = -1
  private isViewReady: boolean = false

  aboutToAppear(): void {
    this.isViewReady = true
    this.cellParticipant = this.participant
  }

  aboutToDisappear(): void {
    this.isViewReady = false
    clearTimeout(this.cellSyncTimer)
  }

  private onParticipantChanged(): void {
    if (!this.isViewReady) {
      return
    }
    if (this.cellParticipant?.userID === this.participant.userID) {
      this.cellParticipant = this.participant
      return
    }
    this.cellParticipant = undefined
    clearTimeout(this.cellSyncTimer)
    this.cellSyncTimer = setTimeout(() => {
      if (this.isViewReady) {
        this.cellParticipant = this.participant
      }
    }, 0)
  }

  private stageSize(): RoomStageSize {
    return { width: this.stageWidth, height: this.stageHeight }
  }

  private floatingRect(): RoomItemRect {
    const size = this.stageSize()
    if (this.isDragging && this.dragStart !== undefined) {
      return {
        x: this.dragLeft,
        y: this.dragTop,
        width: this.dragStart.width,
        height: this.dragStart.height,
      }
    }
    return RoomParticipantLayout.floatingBounds(size, this.settledPosition)
  }

  private handlePanStart(): void {
    const start = RoomParticipantLayout.floatingBounds(this.stageSize(), this.settledPosition)
    this.dragStart = start
    this.dragLeft = start.x
    this.dragTop = start.y
    this.isDragging = true
  }

  private handlePanUpdate(offsetX: number, offsetY: number): void {
    const start = this.dragStart
    if (start === undefined) {
      return
    }
    const clamped = RoomParticipantLayout.clampFloatingPosition(
      start.x + offsetX, start.y + offsetY, start, this.stageSize())
    this.dragLeft = clamped.x
    this.dragTop = clamped.y
  }

  private handlePanEnd(): void {
    const position = RoomParticipantLayout.settledFloatingPosition(this.floatingRect(), this.stageSize())
    this.isDragging = false
    this.dragStart = undefined
    this.onPositionChange?.(position)
  }

  build() {
    if (this.cellParticipant !== undefined) {
      RoomParticipantCell({
        roomID: this.roomID,
        participant: this.cellParticipant,
        isScreenStream: false,
        isLocal: this.isLocal,
        volume: this.volume,
        networkQuality: this.networkQuality,
        isPlaying: this.isPlaying,
      })
        .position({ left: this.floatingRect().x, top: this.floatingRect().y })
        .width(this.floatingRect().width)
        .height(this.floatingRect().height)
        .gesture(
          PanGesture()
            .onActionStart(() => this.handlePanStart())
            .onActionUpdate((event: GestureEvent) => this.handlePanUpdate(event.offsetX, event.offsetY))
            .onActionEnd(() => this.handlePanEnd())
            .onActionCancel(() => this.handlePanEnd())
        )
    }
  }
}
