import { RoomSettingsPage } from 'tuiroomkit'
import { RoomMainPage } from './RoomMainPage'
import { RoomHomePage } from './RoomHomePage'
import { RoomJoinPage } from './RoomJoinPage'
import { RoomPageTheme } from './RoomPageComponents'
import { RoomQuickStartPage } from './RoomQuickStartPage'

class MeetingRequest {
  roomID: string
  roomName: string
  isCreate: boolean
  microphoneOn: boolean
  cameraOn: boolean
  speakerOn: boolean

  constructor(roomID: string, roomName: string, isCreate: boolean, microphoneOn: boolean, cameraOn: boolean,
    speakerOn: boolean) {
    this.roomID = roomID
    this.roomName = roomName
    this.isCreate = isCreate
    this.microphoneOn = microphoneOn
    this.cameraOn = cameraOn
    this.speakerOn = speakerOn
  }
}

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

  private openMeeting(request: MeetingRequest): void {
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
            this.openMeeting(new MeetingRequest(roomID, roomName, true, microphoneOn, cameraOn, speakerOn))
          } })
      } else if (name === 'join') {
        RoomJoinPage({ active: this.active && this.joinActive, onBack: () => this.back(),
          onJoin: (roomID: string, microphoneOn: boolean, cameraOn: boolean, speakerOn: boolean) => {
            this.openMeeting(new MeetingRequest(roomID, roomID, false, microphoneOn, cameraOn, speakerOn))
          } })
      } else {
        RoomMainPage({ roomID: (parameter as MeetingRequest).roomID, roomName: (parameter as MeetingRequest).roomName,
          isCreate: (parameter as MeetingRequest).isCreate,
          autoEnableMicrophone: (parameter as MeetingRequest).microphoneOn,
          autoEnableCamera: (parameter as MeetingRequest).cameraOn,
          autoEnableSpeaker: (parameter as MeetingRequest).speakerOn, onClose: () => this.closeMeeting() })
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
