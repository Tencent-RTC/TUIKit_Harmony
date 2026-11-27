import { CreateRoomOptions } from '@tencentcloud/atomicxcore'
import { EnterRoomParams, MeetingView, RoomBehavior, RoomConnectConfig, RoomSettingsPage } from 'tuiroomkit'
import { RoomHomePage } from './RoomHomePage'
import { RoomJoinPage } from './RoomJoinPage'
import { RoomPageTheme } from './RoomPageComponents'
import { RoomQuickStartPage } from './RoomQuickStartPage'

@Component
export struct RoomRootPage {
  @Prop active: boolean = true
  onFullscreen: (fullscreen: boolean) => void = () => {}
  onBackReady: (handler: (() => boolean) | undefined) => void = () => {}
  @State private quickActive: boolean = false
  @State private joinActive: boolean = false
  @State private settingsVisible: boolean = false
  private stack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.onBackReady(() => {
      if (this.settingsVisible) { this.settingsVisible = false; return true }
      if (this.stack.size() === 0) { return false }
      this.back()
      return true
    })
  }

  aboutToDisappear(): void {
    this.onBackReady(undefined)
    this.onFullscreen(false)
  }

  private back(): void {
    this.stack.pop()
    this.onFullscreen(false)
  }

  private openMeeting(request: EnterRoomParams): void {
    this.stack.pushPath({ name: 'meeting', param: request })
    this.onFullscreen(true)
  }

  private closeMeeting(): void {
    this.stack.clear()
    this.quickActive = false
    this.joinActive = false
    this.onFullscreen(false)
  }

  @Builder
  destination(name: string, parameter: Object) {
    NavDestination() {
      if (name === 'quick') {
        RoomQuickStartPage({ active: this.active && this.quickActive, onBack: () => this.back(),
          onStart: (roomID: string, roomName: string, microphoneOn: boolean, cameraOn: boolean, speakerOn: boolean) => {
            this.openMeeting(new EnterRoomParams(roomID,
              RoomBehavior.createAndJoinRoom(new CreateRoomOptions(roomName)),
              new RoomConnectConfig(microphoneOn, cameraOn, speakerOn)))
          } })
      } else if (name === 'join') {
        RoomJoinPage({ active: this.active && this.joinActive, onBack: () => this.back(),
          onJoin: (roomID: string, microphoneOn: boolean, cameraOn: boolean, speakerOn: boolean) => {
            this.openMeeting(new EnterRoomParams(roomID, RoomBehavior.join,
              new RoomConnectConfig(microphoneOn, cameraOn, speakerOn)))
          } })
      } else {
        MeetingView({ roomID: (parameter as EnterRoomParams).roomID,
          behavior: (parameter as EnterRoomParams).behavior, config: (parameter as EnterRoomParams).config,
          onClose: () => this.closeMeeting() })
      }
    }
    .hideTitleBar(true)
    .backgroundColor(name === 'meeting' ? Color.Black : RoomPageTheme.canvas)
    .onShown(() => {
      this.quickActive = name === 'quick'
      this.joinActive = name === 'join'
      this.onFullscreen(name === 'meeting')
    })
    .onHidden(() => {
      if (name === 'quick') { this.quickActive = false }
      if (name === 'join') { this.joinActive = false }
    })
    .onBackPressed(() => { this.back(); return true })
  }

  @Builder
  private settingsPage() {
    RoomSettingsPage({ onBack: () => this.settingsVisible = false })
  }

  build() {
    Navigation(this.stack) {
      RoomHomePage({
        onQuickMeeting: () => this.stack.pushPath({ name: 'quick' }),
        onJoinMeeting: () => this.stack.pushPath({ name: 'join' }),
        onSettings: () => this.settingsVisible = true,
      })
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.destination)
    .width('100%')
    .height('100%')
    .backgroundColor(RoomPageTheme.canvas)
    .bindContentCover(this.settingsVisible, this.settingsPage(), {
      modalTransition: ModalTransition.DEFAULT,
      onDisappear: () => this.settingsVisible = false,
    })
  }
}
