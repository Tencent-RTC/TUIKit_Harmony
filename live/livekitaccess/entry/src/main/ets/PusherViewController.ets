import { PusherView } from 'tuilivekit'

@Component
export struct PusherViewController {
  liveID: string = ''
  onExitAfterAccountInvalidation?: () => void
  onBack?: () => void

  aboutToDisappear(): void {
    const onExit = this.onExitAfterAccountInvalidation
    if (onExit !== undefined) {
      this.onExitAfterAccountInvalidation = undefined
      setTimeout(onExit, 0)
    }
  }

  private goBack(): void {
    const onExit = this.onExitAfterAccountInvalidation
    if (onExit !== undefined) {
      this.onExitAfterAccountInvalidation = undefined
      onExit()
      return
    }
    this.onBack?.()
  }

  build() {
    PusherView({ liveID: this.liveID, onExit: () => this.goBack() })
  }
}
