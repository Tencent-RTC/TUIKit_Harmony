import {
  DeviceType,
  LoginStore,
  ParticipantRole,
  RoomParticipant,
  RoomParticipantState,
  RoomParticipantStore,
  RoomState,
  RoomStore,
} from '@tencentcloud/atomicxcore'
import { RoomDataObserver } from '../../../../base/util/RoomDataObserver'
import { canManage, getParticipantDisplayName } from '../../../../base/util/DisplayName'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomToast } from '../../../../base/toast/RoomToast'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { RoomParticipantListCell } from './RoomParticipantListCell'
import { RoomParticipantActionPopup } from './RoomParticipantActionPopup'
import { RoomParticipantMorePopup } from './RoomParticipantMorePopup'

interface FooterButtonParams {
  text: string
  selected: boolean
  action: () => void
}

@Component
export struct RoomParticipantListView {
  @Prop roomID: string = ''
  @State private participantState?: RoomParticipantState = undefined
  @State private roomState: RoomState = RoomStore.shared().state
  @State private searchText: string = ''
  @State private searchResults: RoomParticipant[] = []
  @State private isCollapsed: boolean = false
  @State private selectedTargetUserID: string = ''
  @State private isMorePresented: boolean = false
  private readonly participantListObserver: RoomDataObserver = new RoomDataObserver(() => this.updateSearchResults())

  aboutToAppear(): void {
    const participantStore = RoomParticipantStore.create(this.roomID)
    this.participantState = participantStore.state
    participantStore.state.participantList.registerDataChangeListener(this.participantListObserver)
  }

  aboutToDisappear(): void {
    this.participantState?.participantList.unregisterDataChangeListener(this.participantListObserver)
  }

  private isSearching(): boolean {
    return this.searchText.trim().length > 0
  }

  private updateSearchResults(): void {
    if (!this.isSearching()) {
      return
    }
    const keyword = this.searchText.trim().toLowerCase()
    const participants = this.participantState?.participantList.toArray() ?? []
    this.searchResults = participants.filter((participant: RoomParticipant) =>
      getParticipantDisplayName(participant).toLowerCase().includes(keyword))
  }

  private updateSearchText(searchText: string): void {
    this.searchText = searchText
    if (this.isSearching()) {
      this.updateSearchResults()
    } else {
      this.searchResults = []
    }
  }

  private joinedCount(): number {
    return this.roomState.currentRoom?.participantCount ?? 0
  }

  private panelTitle(): string {
    const count = this.joinedCount()
    return count === 0 ? RoomResources.string('roomkit_participants_panel') :
      RoomResources.string('roomkit_participants_panel_count', `${count}`)
  }

  private localRole(): ParticipantRole | undefined {
    return this.participantState?.localParticipant?.role
  }

  private isManager(): boolean {
    const role = this.localRole()
    return role === ParticipantRole.owner || role === ParticipantRole.admin
  }

  private isSelf(participant: RoomParticipant): boolean {
    return participant.userID === LoginStore.shared().state.loginUserInfo?.userID
  }

  private canAction(participant: RoomParticipant): boolean {
    const role = this.localRole()
    return this.isSelf(participant) || canManage(role, participant.role)
  }

  private currentRoomMatches(): boolean {
    return this.roomState.currentRoom?.roomID === this.roomID
  }

  private async toggleAll(device: DeviceType): Promise<void> {
    if (!this.currentRoomMatches() || !this.isManager()) {
      return
    }
    const room = this.roomState.currentRoom
    const disable = device === DeviceType.microphone ? !room?.isAllMicrophoneDisabled : !room?.isAllCameraDisabled
    try {
      await RoomParticipantStore.create(this.roomID).disableAllDevices(device, disable)
      const key = device === DeviceType.microphone ?
        (disable ? 'roomkit_participants_mute_all_done' : 'roomkit_participants_unmute_all_done') :
        (disable ? 'roomkit_participants_cam_off_all_done' : 'roomkit_participants_cam_on_all_done')
      RoomToast.show(RoomResources.string(key))
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  @Builder
  footerButton(params: FooterButtonParams) {
    Button(params.text)
      .layoutWeight(1)
      .height(34)
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(params.selected ? $r('app.color.roomkit_accent') : $r('app.color.roomkit_fg_primary'))
      .backgroundColor(params.selected ? $r('app.color.roomkit_accent_soft') : $r('app.color.roomkit_bg_surface'))
      .border({
        width: 1,
        color: params.selected ? $r('app.color.roomkit_accent_border') : $r('app.color.roomkit_border'),
      })
      .borderRadius(17)
      .onClick(params.action)
  }

  @Builder
  headerView() {
    Row() {
      Text(this.panelTitle())
        .layoutWeight(1)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .lineHeight(18)
    }
    .width('100%')
    .height(34)
    .padding({ left: 16, right: 16, top: 4, bottom: 12 })
    Row({ space: 10 }) {
      Image(RoomResources.image('roomkit_icon_search_tertiary')).width(14).height(14)
      TextInput({ text: $$this.searchText, placeholder: RoomResources.string('roomkit_participants_search_placeholder') })
        .layoutWeight(1)
        .height(30)
        .fontSize(11)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .placeholderColor($r('app.color.roomkit_fg_tertiary'))
        .placeholderFont({ size: 11 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .enterKeyType(EnterKeyType.Done)
        .cancelButton({ style: CancelButtonStyle.INPUT })
        .onChange((value: string) => this.updateSearchText(value))
    }
    .height(32)
    .margin({ left: 16, right: 16, bottom: 10 })
    .padding({ left: 10, right: 10 })
    .backgroundColor($r('app.color.roomkit_bg_surface'))
    .border({ width: 1, color: $r('app.color.roomkit_border') })
    .borderRadius(16)
  }

  @Builder
  searchEmptyView() {
    Column({ space: 4 }) {
      Image(RoomResources.image('roomkit_ill_participant_search_empty')).width(80).height(64)
      Text(RoomResources.string('roomkit_participants_search_empty'))
        .fontSize(13)
        .fontWeight(600)
        .fontColor($r('app.color.roomkit_fg_primary'))
      Text(RoomResources.string('roomkit_participants_search_empty_desc', this.searchText.trim()))
        .fontSize(11)
        .fontColor($r('app.color.roomkit_fg_tertiary'))
        .textAlign(TextAlign.Center)
      Button(RoomResources.string('roomkit_participants_clear_search'))
        .height(30)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .backgroundColor($r('app.color.roomkit_bg_surface'))
        .border({ width: 1, color: $r('app.color.roomkit_border') })
        .borderRadius(15)
        .padding({ left: 14, right: 14 })
        .margin({ top: 12 })
        .onClick(() => this.updateSearchText(''))
    }
    .layoutWeight(1)
    .padding({ left: 20, right: 20 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  participantListItem(participant: RoomParticipant) {
    ListItem() {
      RoomParticipantListCell({
        participant: participant,
        canAction: this.canAction(participant),
        onTap: () => this.selectedTargetUserID = participant.userID,
      })
    }
  }

  @Builder
  joinedSectionView() {
    Row({ space: 6 }) {
      Image(RoomResources.image('roomkit_icon_chevron_right_tertiary'))
        .width(12)
        .height(12)
        .rotate({ angle: this.isCollapsed ? 0 : 90 })
      Text(RoomResources.string('roomkit_participants_joined'))
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.roomkit_fg_secondary'))
      if (this.joinedCount() > 0) {
        Text('(' + this.joinedCount() + ')')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.roomkit_fg_tertiary'))
      }
    }
    .width('100%')
    .height(28)
    .padding({ left: 24, right: 24, bottom: 4 })
    .onClick(() => this.isCollapsed = !this.isCollapsed)
    List() {
      if (!this.isCollapsed) {
        if (this.isSearching()) {
          ForEach(this.searchResults, (participant: RoomParticipant) => {
            this.participantListItem(participant)
          }, (participant: RoomParticipant) => participant.userID)
        } else {
          LazyForEach(this.participantState?.participantList, (participant: RoomParticipant) => {
            this.participantListItem(participant)
          }, (participant: RoomParticipant) => participant.userID)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ bottom: 16 })
    .scrollBar(BarState.Off)
  }

  @Builder
  participantContent() {
    if (this.isSearching() && this.searchResults.length === 0) {
      this.searchEmptyView()
    } else {
      this.joinedSectionView()
    }
  }

  @Builder
  managementFooter() {
    if (this.isManager()) {
      Row({ space: 8 }) {
        this.footerButton({
          text: RoomResources.string(this.roomState.currentRoom?.isAllMicrophoneDisabled ?
            'roomkit_participants_unmute_all' : 'roomkit_participants_mute_all'),
          selected: this.roomState.currentRoom?.isAllMicrophoneDisabled ?? false,
          action: () => this.toggleAll(DeviceType.microphone),
        })
        this.footerButton({
          text: RoomResources.string(this.roomState.currentRoom?.isAllCameraDisabled ?
            'roomkit_participants_cam_on_all' : 'roomkit_participants_cam_off_all'),
          selected: this.roomState.currentRoom?.isAllCameraDisabled ?? false,
          action: () => this.toggleAll(DeviceType.camera),
        })
        Button(RoomResources.string('roomkit_room_more'))
          .layoutWeight(1)
          .height(34)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .backgroundColor($r('app.color.roomkit_bg_surface'))
          .border({ width: 1, color: $r('app.color.roomkit_border') })
          .borderRadius(17)
          .onClick(() => this.isMorePresented = true)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    }
  }

  @Builder
  participantPopups() {
    RoomParticipantActionPopup({
      roomID: this.roomID,
      targetUserID: this.selectedTargetUserID,
      isPresented: this.selectedTargetUserID.length > 0,
      onDismiss: () => this.selectedTargetUserID = '',
    })
    RoomParticipantMorePopup({
      roomID: this.roomID,
      room: this.roomState.currentRoom,
      localRole: this.localRole(),
      isPresented: this.isMorePresented,
      onDismiss: () => this.isMorePresented = false,
    })
  }

  build() {
    Stack() {
      Column() {
        this.headerView()
        this.participantContent()
        this.managementFooter()
      }
      .width('100%')
      .height('100%')
      this.participantPopups()
    }
    .width('100%')
    .height('100%')
  }
}
