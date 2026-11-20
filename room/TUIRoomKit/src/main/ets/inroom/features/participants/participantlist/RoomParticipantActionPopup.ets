import { common } from '@kit.AbilityKit'
import {
  DeviceStatus,
  DeviceStore,
  DeviceType,
  ParticipantRole,
  RoomParticipant,
  RoomParticipantListener,
  RoomParticipantState,
  RoomParticipantStore,
  RoomState,
  RoomStore,
} from '@tencentcloud/atomicxcore'
import { RoomDialog, RoomDialogVariant } from '../../../../base/dialog/RoomDialog'
import { RoomPopup, RoomPopupContentHeight } from '../../../../base/popup/RoomPopup'
import { RoomToast } from '../../../../base/toast/RoomToast'
import { ErrorLocalized } from '../../../../base/error/ErrorLocalized'
import { canManage, getParticipantDisplayName } from '../../../../base/util/DisplayName'
import { RoomDataObserver } from '../../../../base/util/RoomDataObserver'
import { RoomDevicePermission } from '../../../../base/util/RoomDevicePermission'
import { RoomResources } from '../../../../base/util/RoomResources'

const renameInputID: string = 'roomkit_participant_rename_input'

interface ActionRowParams {
  icon: string
  title: string
  danger: boolean
  action: () => void
}

@Component
export struct RoomParticipantActionPopup {
  @Prop roomID: string = ''
  @Prop @Watch('updateTargetState') targetUserID: string = ''
  @Prop isPresented: boolean = false
  onDismiss?: () => void
  @State private participantState?: RoomParticipantState = undefined
  @State private roomState: RoomState = RoomStore.shared().state
  @State private target?: RoomParticipant = undefined
  @State private localRole?: ParticipantRole = undefined
  @State private isChatMuted: boolean = false
  @State private renameText: string = ''
  @State private isRenamePresented: boolean = false
  @State private isTransferConfirmPresented: boolean = false
  @State private isKickConfirmPresented: boolean = false
  @State private confirmationTarget?: RoomParticipant = undefined
  private readonly participantListObserver: RoomDataObserver = new RoomDataObserver(() => this.updateTargetState())
  private readonly participantListener: RoomParticipantListener = new RoomParticipantListener()
  private renameTargetUserID: string = ''

  aboutToAppear(): void {
    const store = RoomParticipantStore.create(this.roomID)
    this.participantState = store.state
    store.state.participantList.registerDataChangeListener(this.participantListObserver)
    this.participantListener.onOwnerChanged = () => this.updateTargetState()
    this.participantListener.onAdminSet = () => this.updateTargetState()
    this.participantListener.onAdminRevoked = () => this.updateTargetState()
    this.participantListener.onUserMessageDisabled = () => this.updateTargetState()
    this.participantListener.onAllMessagesDisabled = () => this.updateTargetState()
    store.addRoomParticipantListener(this.participantListener)
    this.updateTargetState()
  }

  aboutToDisappear(): void {
    this.participantState?.participantList.unregisterDataChangeListener(this.participantListObserver)
    RoomParticipantStore.create(this.roomID).removeRoomParticipantListener(this.participantListener)
  }

  private updateTargetState(): void {
    const state = this.participantState
    this.target = state?.participantList.find((participant: RoomParticipant) => participant.userID === this.targetUserID)
    this.localRole = state?.localParticipant?.role
    this.isChatMuted = this.target !== undefined && (state?.messageDisabledUserList.some(
      (user) => user.userID === this.targetUserID) ?? false)
    this.validatePermission()
  }

  private isSelf(): boolean {
    return this.targetUserID.length > 0 && this.targetUserID === this.participantState?.localParticipant?.userID
  }

  private canManageTarget(): boolean {
    if (this.target === undefined) {
      return false
    }
    return this.isSelf() || canManage(this.localRole, this.target.role)
  }

  private isUserManageable(userID: string): boolean {
    const state = this.participantState
    const target = state?.participantList.find((participant: RoomParticipant) => participant.userID === userID)
    const local = state?.localParticipant
    if (target === undefined || local === undefined) {
      return false
    }
    return target.userID === local.userID || canManage(local.role, target.role)
  }

  private validatePermission(): void {
    if (this.targetUserID.length > 0 && !this.canManageTarget()) {
      this.onDismiss?.()
    }
    if (this.isRenamePresented && !this.isUserManageable(this.renameTargetUserID)) {
      this.isRenamePresented = false
    }
    const confirmationTarget = this.confirmationTarget
    if (confirmationTarget !== undefined && !this.isUserManageable(confirmationTarget.userID)) {
      this.isTransferConfirmPresented = false
      this.isKickConfirmPresented = false
    }
    if (this.localRole !== ParticipantRole.owner) {
      this.isTransferConfirmPresented = false
    }
  }

  private closeAnd(action: () => void): void {
    this.onDismiss?.()
    action()
  }

  private showRename(target: RoomParticipant): void {
    this.renameTargetUserID = target.userID
    this.renameText = getParticipantDisplayName(target)
    this.isRenamePresented = true
  }

  private showTransferOwnerConfirmation(target: RoomParticipant): void {
    this.confirmationTarget = target
    this.isTransferConfirmPresented = true
  }

  private showKickConfirmation(target: RoomParticipant): void {
    this.confirmationTarget = target
    this.isKickConfirmPresented = true
  }

  private async toggleSelfMicrophone(): Promise<void> {
    const target = this.target as RoomParticipant
    const store = RoomParticipantStore.create(this.roomID)
    if (target.microphoneStatus === DeviceStatus.on) {
      store.muteMicrophone()
      return
    }
    const room = this.roomState.currentRoom
    if (room?.isAllMicrophoneDisabled && this.localRole === ParticipantRole.generalUser) {
      RoomToast.show(RoomResources.string('roomkit_device_all_mic_disabled'))
      return
    }
    const context = getContext(this) as common.UIAbilityContext
    const granted = await RoomDevicePermission.requestMicrophonePermission(context)
    if (!granted) {
      RoomToast.show(RoomResources.string('roomkit_device_mic_no_permission'))
      return
    }
    try {
      await store.unmuteMicrophone()
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private async toggleSelfCamera(): Promise<void> {
    const target = this.target as RoomParticipant
    if (target.cameraStatus === DeviceStatus.on) {
      DeviceStore.shared().closeLocalCamera()
      return
    }
    const room = this.roomState.currentRoom
    if (room?.isAllCameraDisabled && this.localRole === ParticipantRole.generalUser) {
      RoomToast.show(RoomResources.string('roomkit_device_all_cam_disabled'))
      return
    }
    const context = getContext(this) as common.UIAbilityContext
    const granted = await RoomDevicePermission.requestCameraPermission(context)
    if (!granted) {
      RoomToast.show(RoomResources.string('roomkit_device_camera_no_permission'))
      return
    }
    try {
      await DeviceStore.shared().openLocalCamera(DeviceStore.shared().state.isFrontCamera)
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private async toggleRemoteDevice(device: DeviceType): Promise<void> {
    const store = RoomParticipantStore.create(this.roomID)
    const target = this.target as RoomParticipant
    const enabled = device === DeviceType.microphone ? target.microphoneStatus === DeviceStatus.on :
      target.cameraStatus === DeviceStatus.on
    try {
      if (enabled) {
        await store.closeParticipantDevice(target.userID, device)
        RoomToast.show(RoomResources.string(device === DeviceType.microphone ? 'roomkit_participants_mute_done' :
          'roomkit_participants_cam_stop_done', getParticipantDisplayName(target)))
      } else {
        await store.inviteToOpenDevice(target.userID, device, 30)
      }
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private async toggleChat(): Promise<void> {
    const store = RoomParticipantStore.create(this.roomID)
    const target = this.target as RoomParticipant
    const shouldMute = !this.isChatMuted
    try {
      await store.disableUserMessage(target.userID, shouldMute)
      RoomToast.show(RoomResources.string(shouldMute ? 'roomkit_participants_mute_chat_done' :
        'roomkit_participants_unmute_chat_done', getParticipantDisplayName(target)))
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private async submitRename(): Promise<void> {
    const name = this.renameText.trim()
    if (name.length === 0) {
      return
    }
    this.isRenamePresented = false
    try {
      await RoomParticipantStore.create(this.roomID).updateParticipantNameCard(this.renameTargetUserID, name)
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private async updateAdmin(revoke: boolean): Promise<void> {
    const store = RoomParticipantStore.create(this.roomID)
    const target = this.target as RoomParticipant
    try {
      if (revoke) {
        await store.revokeAdmin(target.userID)
        RoomToast.show(RoomResources.string('roomkit_participants_revoke_admin_done', getParticipantDisplayName(target)))
      } else {
        await store.setAdmin(target.userID)
        RoomToast.show(RoomResources.string('roomkit_participants_set_admin_done', getParticipantDisplayName(target)))
      }
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  @Builder
  actionRow(params: ActionRowParams) {
    Row({ space: 10 }) {
      Image(RoomResources.image(params.icon)).width(15).height(15)
      Text(params.title)
        .fontSize(13)
        .fontColor(params.danger ? $r('app.color.roomkit_danger') : $r('app.color.roomkit_fg_primary'))
    }
    .width('100%')
    .height(42)
    .padding({ left: 12, right: 12 })
    .onClick(() => this.closeAnd(params.action))
  }

  @Builder
  selfActions(target: RoomParticipant) {
    this.actionRow({
      icon: target.microphoneStatus === DeviceStatus.on ? 'roomkit_icon_microphone' : 'roomkit_icon_microphone_off',
      title: RoomResources.string(target.microphoneStatus === DeviceStatus.on ?
        'roomkit_participants_mic_close' : 'roomkit_participants_mic_open'),
      danger: false,
      action: () => this.toggleSelfMicrophone(),
    })
    this.actionRow({
      icon: target.cameraStatus === DeviceStatus.on ? 'roomkit_icon_camera' : 'roomkit_icon_camera_off',
      title: RoomResources.string(target.cameraStatus === DeviceStatus.on ?
        'roomkit_participants_cam_close' : 'roomkit_participants_cam_open'),
      danger: false,
      action: () => this.toggleSelfCamera(),
    })
    this.actionRow({
      icon: 'roomkit_icon_rename',
      title: RoomResources.string('roomkit_participants_rename'),
      danger: false,
      action: () => this.showRename(target),
    })
  }

  @Builder
  managedParticipantActions(target: RoomParticipant) {
    this.actionRow({
      icon: 'roomkit_icon_rename',
      title: RoomResources.string('roomkit_participants_rename'),
      danger: false,
      action: () => this.showRename(target),
    })
    if (this.localRole === ParticipantRole.owner) {
      this.actionRow({
        icon: 'roomkit_icon_transfer_owner',
        title: RoomResources.string('roomkit_participants_transfer_owner'),
        danger: false,
        action: () => this.showTransferOwnerConfirmation(target),
      })
      if (target.role === ParticipantRole.admin) {
        this.actionRow({
          icon: 'roomkit_icon_revoke_admin',
          title: RoomResources.string('roomkit_participants_revoke_admin'),
          danger: false,
          action: () => this.updateAdmin(true),
        })
      } else {
        this.actionRow({
          icon: 'roomkit_icon_set_admin',
          title: RoomResources.string('roomkit_participants_set_admin'),
          danger: false,
          action: () => this.updateAdmin(false),
        })
      }
      Column().width('100%').height(1).backgroundColor($r('app.color.roomkit_border')).margin({ top: 10, bottom: 10 })
    }

    this.actionRow({
      icon: target.microphoneStatus === DeviceStatus.on ? 'roomkit_icon_microphone' : 'roomkit_icon_microphone_off',
      title: RoomResources.string(target.microphoneStatus === DeviceStatus.on ?
        'roomkit_participants_audio_disable' : 'roomkit_participants_audio_allow'),
      danger: false,
      action: () => this.toggleRemoteDevice(DeviceType.microphone),
    })
    this.actionRow({
      icon: target.cameraStatus === DeviceStatus.on ? 'roomkit_icon_camera' : 'roomkit_icon_camera_off',
      title: RoomResources.string(target.cameraStatus === DeviceStatus.on ?
        'roomkit_participants_video_disable' : 'roomkit_participants_video_allow'),
      danger: false,
      action: () => this.toggleRemoteDevice(DeviceType.camera),
    })
    this.actionRow({
      icon: this.isChatMuted ? 'roomkit_icon_chat' : 'roomkit_icon_chat_off',
      title: RoomResources.string(this.isChatMuted ? 'roomkit_participants_chat_unmute' :
        'roomkit_participants_chat_mute'),
      danger: false,
      action: () => this.toggleChat(),
    })
    Column().width('100%').height(1).backgroundColor($r('app.color.roomkit_border')).margin({ top: 10, bottom: 10 })
    this.actionRow({
      icon: 'roomkit_icon_kick_danger',
      title: RoomResources.string('roomkit_participants_kick'),
      danger: true,
      action: () => this.showKickConfirmation(target),
    })
  }

  @Builder
  participantActions() {
    Column() {
      if (this.target !== undefined) {
        if (this.isSelf()) {
          this.selfActions(this.target)
        } else if (this.canManageTarget()) {
          this.managedParticipantActions(this.target)
        }
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 24 })
  }

  @Builder
  renameDialog() {
    RoomDialog({
      isPresented: this.isRenamePresented,
      title: RoomResources.string('roomkit_participants_rename'),
      message: RoomResources.string('roomkit_participants_rename_desc'),
      primaryText: RoomResources.string('roomkit_participants_confirm'),
      secondaryText: RoomResources.string('roomkit_room_common_cancel'),
      inputFocusID: renameInputID,
      onPrimary: () => this.submitRename(),
      onSecondary: () => this.isRenamePresented = false,
      onDismiss: () => this.isRenamePresented = false,
    }) {
      TextInput({ text: $$this.renameText, placeholder: RoomResources.string('roomkit_participants_rename_placeholder') })
        .id(renameInputID)
        .height(44)
        .fontSize(15)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .placeholderFont({ size: 15 })
        .placeholderColor($r('app.color.roomkit_fg_tertiary'))
        .maxLength(10)
        .enterKeyType(EnterKeyType.Done)
        .onSubmit(() => this.submitRename())
    }
  }

  @Builder
  transferOwnerDialog(target: RoomParticipant) {
    RoomDialog({
      isPresented: this.isTransferConfirmPresented,
      title: RoomResources.string('roomkit_participants_transfer_owner'),
      message: RoomResources.string('roomkit_participants_transfer_owner_message', getParticipantDisplayName(target)),
      primaryText: RoomResources.string('roomkit_participants_transfer_owner_confirm'),
      primaryVariant: RoomDialogVariant.PRIMARY,
      secondaryText: RoomResources.string('roomkit_room_common_cancel'),
      onPrimary: () => {
        this.isTransferConfirmPresented = false
        RoomParticipantStore.create(this.roomID).transferOwner(target.userID).then(() => {
          RoomToast.show(RoomResources.string('roomkit_participants_transfer_owner_done', getParticipantDisplayName(target)))
        }).catch((error: Error) => ErrorLocalized.showError(error))
      },
      onSecondary: () => this.isTransferConfirmPresented = false,
      onDismiss: () => this.isTransferConfirmPresented = false,
    })
  }

  @Builder
  kickDialog(target: RoomParticipant) {
    RoomDialog({
      isPresented: this.isKickConfirmPresented,
      title: RoomResources.string('roomkit_participants_kick'),
      message: RoomResources.string('roomkit_participants_kick_message', getParticipantDisplayName(target)),
      primaryText: RoomResources.string('roomkit_participants_kick_confirm'),
      primaryVariant: RoomDialogVariant.DANGER,
      secondaryText: RoomResources.string('roomkit_room_common_cancel'),
      onPrimary: () => {
        this.isKickConfirmPresented = false
        RoomParticipantStore.create(this.roomID).kickUser(target.userID).then(() => {
          RoomToast.show(RoomResources.string('roomkit_participants_kick_done', getParticipantDisplayName(target)))
        }).catch((error: Error) => ErrorLocalized.showError(error))
      },
      onSecondary: () => this.isKickConfirmPresented = false,
      onDismiss: () => this.isKickConfirmPresented = false,
    })
  }

  build() {
    Stack() {
      RoomPopup({
        isPresented: this.isPresented && this.target !== undefined,
        contentHeight: RoomPopupContentHeight.AUTO,
        onDismiss: () => this.onDismiss?.(),
      }) {
        this.participantActions()
      }
      this.renameDialog()
      if (this.confirmationTarget !== undefined) {
        this.transferOwnerDialog(this.confirmationTarget)
        this.kickDialog(this.confirmationTarget)
      }
    }
  }
}
