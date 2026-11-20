import { PusherView } from 'tuilivekit'
import { BroadcastTypeBarView } from './BroadcastTypeBarView'

@Component
export struct PusherViewController {
  liveID: string = ''
  onExit: () => void = () => {}

  @Builder typeBar() { BroadcastTypeBarView() }

  build() {
    PusherView({ liveID: this.liveID, prepareAccessory: (): void => this.typeBar(), onExit: this.onExit })
  }
}
