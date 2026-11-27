import { display } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { ImageMessagePayload } from '@tencentcloud/atomicxcore'
import { roomChatImageUri } from './RoomChatMessageCell'

const HEIGHT_FRACTION = 0.7
const MAX_HEIGHT = 560
const MAX_SCALE = 5

@Component
export struct RoomChatImagePreviewView {
  @Prop payload: ImageMessagePayload
  @State private sourceIndex: number = 0
  @State private zoomScale: number = 1
  @State private offsetX: number = 0
  @State private offsetY: number = 0
  @State private containerWidth: number = 0
  @State private imageSources: string[] = []
  @State private cachedPreviewHeight: number = MAX_HEIGHT
  private baseScale: number = 1
  private baseOffsetX: number = 0
  private baseOffsetY: number = 0

  aboutToAppear(): void {
    this.imageSources = this.imageCandidates()
    this.cachedPreviewHeight = this.calculatePreviewHeight()
  }

  private isAccessible(path: string | undefined): boolean {
    if (path === undefined || path.length === 0) {
      return false
    }
    try {
      return fileIo.accessSync(path)
    } catch (error) {
      return false
    }
  }

  private imageCandidates(): string[] {
    const localPaths: (string | undefined)[] = [
      this.payload.originalImagePath,
      this.payload.largeImagePath,
      this.payload.thumbImagePath,
    ]
    const remoteURLs: (string | undefined)[] = [
      this.payload.originalImageURL,
      this.payload.largeImageURL,
      this.payload.thumbImageURL,
    ]
    const locals = localPaths.filter((path: string | undefined) => this.isAccessible(path)) as string[]
    const remotes = remoteURLs.filter((url: string | undefined) => url !== undefined && url.length > 0) as string[]
    return locals.concat(remotes)
  }

  private imageSource(): string {
    return roomChatImageUri(this.imageSources[this.sourceIndex] ?? '')
  }

  private showNextImage(): void {
    if (this.sourceIndex < this.imageSources.length - 1) {
      this.sourceIndex++
    }
  }

  private calculatePreviewHeight(): number {
    try {
      return Math.min(px2vp(display.getDefaultDisplaySync().height) * HEIGHT_FRACTION, MAX_HEIGHT)
    } catch (error) {
      return MAX_HEIGHT
    }
  }

  private previewHeight(): number {
    return this.cachedPreviewHeight
  }

  private clampOffset(x: number, y: number, scale: number): void {
    const maxX = this.containerWidth * (scale - 1) / 2
    const maxY = this.previewHeight() * (scale - 1) / 2
    this.offsetX = Math.min(Math.max(x, -maxX), maxX)
    this.offsetY = Math.min(Math.max(y, -maxY), maxY)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.imageSource())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .scale({ x: this.zoomScale, y: this.zoomScale })
        .translate({ x: this.offsetX, y: this.offsetY })
        .onError(() => this.showNextImage())
    }
    .width('100%')
    .height(this.previewHeight())
    .clip(true)
    .backgroundColor($r('app.color.roomkit_bg_surface'))
    .onAreaChange((_: Area, area: Area) => this.containerWidth = Number(area.width))
    .gesture(GestureGroup(GestureMode.Parallel,
      PinchGesture()
        .onActionStart(() => this.baseScale = this.zoomScale)
        .onActionUpdate((event: GestureEvent) => {
          this.zoomScale = Math.min(Math.max(this.baseScale * event.scale, 1), MAX_SCALE)
          this.clampOffset(this.offsetX, this.offsetY, this.zoomScale)
        })
        .onActionEnd(() => this.baseScale = this.zoomScale),
      PanGesture()
        .onActionStart(() => {
          this.baseOffsetX = this.offsetX
          this.baseOffsetY = this.offsetY
        })
        .onActionUpdate((event: GestureEvent) => {
          this.clampOffset(this.baseOffsetX + event.offsetX, this.baseOffsetY + event.offsetY, this.zoomScale)
        })
        .onActionEnd(() => {
          this.baseOffsetX = this.offsetX
          this.baseOffsetY = this.offsetY
        })
    ))
  }
}
