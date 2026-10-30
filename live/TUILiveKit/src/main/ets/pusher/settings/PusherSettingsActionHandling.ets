export class PusherSettingsState {
  isMirrorEnabled: boolean = true
  isMuted: boolean = false
  captureVolume: number = 100

  constructor(isMirrorEnabled: boolean = true, isMuted: boolean = false, captureVolume: number = 100) {
    this.isMirrorEnabled = isMirrorEnabled
    this.isMuted = isMuted
    this.captureVolume = captureVolume
  }
}

export interface PusherSettingsActionHandling {
  toggleMirror(): void

  setCaptureVolume(volume: number): void
}
