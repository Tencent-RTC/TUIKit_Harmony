import {
  CoGuestLayoutTemplate,
  AtomicLiveController,
  AtomicLiveView,
  AtomicLiveViewImpl,
  AtomicLiveViewType,
  DeviceStatus
} from '@tencentcloud/atomicxcore'
import { PusherCoGuestSeatViewProvider } from '../living/coguest/seat/PusherCoGuestSeatViewProvider'

export const pusherVideoBottomInset: number = 102

const idleBackground: string = 'rgba(31, 31, 31, 1)'

@Observed
export class PusherVideoViewController {
  @Track readonly coreView: AtomicLiveView =
    new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.pushView))
  @Track isCoGuestStageVisible: boolean = false
  @Track readonly coGuestSeatViewProvider: PusherCoGuestSeatViewProvider = new PusherCoGuestSeatViewProvider()

  constructor() {
    this.coreView.controller.setViewChangeAdapter(this.coGuestSeatViewProvider)
  }

  updateCoGuestVideoState(isLiving: boolean, layout: CoGuestLayoutTemplate, connectedGuestCount: number): void {
    this.coGuestSeatViewProvider.update(isLiving, layout, connectedGuestCount)
    this.isCoGuestStageVisible = isLiving && (connectedGuestCount > 0 ||
      layout.templateId !== CoGuestLayoutTemplate.floatLayout.templateId)
  }

  updateLocalCameraStatus(status: DeviceStatus): void {
    this.coGuestSeatViewProvider.updateLocalCameraStatus(status)
  }

  set onCoGuestGeometryChanged(callback: (() => void) | undefined) {
    this.coGuestSeatViewProvider.onGeometryChanged = callback
  }

  get onCoGuestGeometryChanged(): (() => void) | undefined {
    return this.coGuestSeatViewProvider.onGeometryChanged
  }

  coGuestSmallWindowRegions(): Area[] {
    return this.coGuestSeatViewProvider.smallWindowRegions()
  }

  coGuestUserID(x: number, y: number): string | undefined {
    return this.coGuestSeatViewProvider.guestUserID(x, y)
  }
}

@Component
export struct PusherVideoView {
  @ObjectLink controller: PusherVideoViewController
  @Provide('pusherSeatProvider') seatProvider: PusherCoGuestSeatViewProvider = this.controller.coGuestSeatViewProvider

  build() {
    Stack() {
      AtomicLiveViewImpl({ view: this.controller.coreView })
    }
      .width('100%')
      .height('100%')
      .backgroundColor(this.controller.isCoGuestStageVisible ? Color.Transparent : idleBackground)
  }
}
