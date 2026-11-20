import {
  DeviceStatus,
  FillMode,
  NetworkQuality,
  RoomParticipant,
  RoomParticipantController,
  RoomParticipantStore,
  RoomParticipantView,
  VideoStreamType,
} from '@tencentcloud/atomicxcore'
import { RoomDataObserver } from '../../../base/util/RoomDataObserver'
import { RoomParticipantOverlayView } from './RoomParticipantOverlayView'

@Observed
export class RoomParticipantGridItem {
  readonly userID: string
  participant: RoomParticipant
  isLocal: boolean = false
  volume: number = 0
  networkQuality: NetworkQuality = NetworkQuality.unknown
  isPlaying: boolean = false
  x: number = 0
  y: number = 0
  width: number = 0
  height: number = 0

  constructor(participant: RoomParticipant) {
    this.userID = participant.userID
    this.participant = participant
  }
}

@Component
export struct RoomParticipantCell {
  @Prop roomID: string = ''
  @Prop participant: RoomParticipant = new RoomParticipant()
  @Prop @Watch('scheduleStreamTypeSync') isScreenStream: boolean = false
  @Prop @Watch('schedulePlaybackSync') isLocal: boolean = false
  @Prop volume: number = 0
  @Prop networkQuality: NetworkQuality = NetworkQuality.unknown
  @Prop @Watch('schedulePlaybackSync') isPlaying: boolean = false
  @State private currentParticipant: RoomParticipant = new RoomParticipant()
  private cellWidth: number = 0
  private store?: RoomParticipantStore
  private unsubscribe?: () => void
  @State private controller?: RoomParticipantController = undefined
  private controllerStreamType?: VideoStreamType
  private controllerUserID: string = ''
  private cellHeight: number = 0
  private streamTypeSyncTimer: number = -1
  private playbackSyncTimer: number = -1
  private resizeSyncTimer: number = -1

  aboutToAppear(): void {
    this.currentParticipant = this.participant
    this.createController()
    this.bindParticipant()
  }

  aboutToDisappear(): void {
    this.unsubscribe?.()
    clearTimeout(this.streamTypeSyncTimer)
    clearTimeout(this.playbackSyncTimer)
    clearTimeout(this.resizeSyncTimer)
    this.releaseController()
  }

  private bindParticipant(): void {
    if (this.roomID.length === 0 || this.currentParticipant.userID.length === 0) {
      return
    }
    const userID = this.currentParticipant.userID
    this.store = RoomParticipantStore.create(this.roomID)
    this.unsubscribe = RoomDataObserver.observe(this.store.state.participantList, () => {
      const latest = this.store?.state.participantList.toArray()
        .find((item: RoomParticipant) => item.userID === userID)
      if (latest === undefined || latest === this.currentParticipant) {
        return
      }
      this.currentParticipant = latest
      this.syncParticipant()
    })
  }

  private hasVideo(): boolean {
    if (this.isScreenStream) {
      return !this.isLocal && this.currentParticipant.screenShareStatus === DeviceStatus.on
    }
    return this.currentParticipant.cameraStatus === DeviceStatus.on
  }

  private desiredStreamType(): VideoStreamType {
    return this.isScreenStream ? VideoStreamType.screen : VideoStreamType.camera
  }

  private hasMatchingController(): boolean {
    return this.controller !== undefined && this.controllerStreamType === this.desiredStreamType()
  }

  private createController(): void {
    const stream = this.desiredStreamType()
    this.controller = RoomParticipantController.create(stream, this.currentParticipant)
    this.controllerStreamType = stream
    this.controllerUserID = this.currentParticipant.userID
    this.controller.setFillMode(this.isScreenStream ? FillMode.fit : FillMode.fill)
    this.syncPlayback()
  }

  private releaseController(): void {
    this.controller?.setActive(false)
    this.controller = undefined
    this.controllerStreamType = undefined
    this.controllerUserID = ''
  }

  private scheduleStreamTypeSync(): void {
    this.releaseController()
    clearTimeout(this.streamTypeSyncTimer)
    this.streamTypeSyncTimer = setTimeout(() => this.syncStreamType(), 0)
  }

  private schedulePlaybackSync(): void {
    clearTimeout(this.playbackSyncTimer)
    this.playbackSyncTimer = setTimeout(() => this.syncPlayback(), 0)
  }

  private syncParticipant(): void {
    if (this.controller !== undefined && this.controllerUserID !== this.currentParticipant.userID) {
      this.releaseController()
    }
    this.controller?.updateParticipant(this.currentParticipant)
    this.syncPlayback()
  }

  private syncStreamType(): void {
    this.releaseController()
    this.createController()
  }

  private syncPlayback(): void {
    const isActive = this.isPlaying && this.hasMatchingController() && this.hasVideo()
    this.controller?.setActive(isActive)
  }

  build() {
    Stack() {
      if (this.hasMatchingController() && this.hasVideo()) {
        RoomParticipantView({ controller: this.controller })
          .width('100%')
          .height('100%')
          .onAppear(() => this.schedulePlaybackSync())
      }
      RoomParticipantOverlayView({
        participant: this.currentParticipant,
        isScreenStream: this.isScreenStream,
        isLocal: this.isLocal,
        volume: this.volume,
        networkQuality: this.networkQuality,
      })
    }
    .width('100%')
    .height('100%')
    .borderRadius(12)
    .clip(true)
    .backgroundColor($r(this.isScreenStream ? 'app.color.roomkit_bg_inverse' : 'app.color.roomkit_bg_canvas'))
    .onAreaChange((_: Area, area: Area) => {
      const width = area.width as number
      const height = area.height as number
      const sizeChanged = this.cellWidth > 0 && this.cellHeight > 0 &&
        (this.cellWidth !== width || this.cellHeight !== height)
      this.cellWidth = width
      this.cellHeight = height
      if (sizeChanged && this.isLocal && !this.isScreenStream && this.isPlaying && this.hasVideo()) {
        this.controller?.setActive(false)
        clearTimeout(this.resizeSyncTimer)
        this.resizeSyncTimer = setTimeout(() => this.syncPlayback(), 0)
      }
    })
  }
}

@Component
export struct RoomParticipantGridCell {
  @Prop roomID: string = ''
  @ObjectLink item: RoomParticipantGridItem

  build() {
    RoomParticipantCell({
      roomID: this.roomID,
      participant: this.item.participant,
      isScreenStream: false,
      isLocal: this.item.isLocal,
      volume: this.item.volume,
      networkQuality: this.item.networkQuality,
      isPlaying: this.item.isPlaying,
    })
      .position({ x: this.item.x, y: this.item.y })
      .width(this.item.width)
      .height(this.item.height)
  }
}
