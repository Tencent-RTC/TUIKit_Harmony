import { common } from '@kit.AbilityKit'
import {
  AudioRoute,
  CreateRoomOptions,
  DeviceRequestInfo,
  DeviceStore,
  DeviceType,
  KickedOutOfRoomReason,
  LoginStore,
  ParticipantRole,
  RecordingStopReason,
  RoomInfo,
  RoomListener,
  RoomParticipantListener,
  RoomParticipantState,
  RoomParticipantStore,
  RoomState,
  RoomStore,
  RoomType,
  RoomUser,
} from '@tencentcloud/atomicxcore'
import { RoomDialog } from '../../base/dialog/RoomDialog'
import { ErrorLocalized, ErrorRule } from '../../base/error/ErrorLocalized'
import { RoomAVSessionManager } from '../../base/service/RoomAVSessionManager'
import { RoomToast } from '../../base/toast/RoomToast'
import { RoomResources } from '../../base/util/RoomResources'
import { RoomSafeArea } from '../../base/util/RoomSafeArea'
import { getRoomUserDisplayName, getSenderName } from '../../base/util/DisplayName'
import { RoomView } from '../features/roomview/RoomView'
import { RoomDevicePermission } from '../../base/util/RoomDevicePermission'
import { RoomScreenSharingPlaceholderView } from '../features/screenshare/RoomScreenSharingPlaceholderView'
import { MeetingTopBar } from './MeetingTopBar'
import { MeetingToolBar } from './MeetingToolBar'
import { MeetingLoadingView } from './MeetingLoadingView'
import { MeetingPasswordDialog } from './MeetingPasswordDialog'

@Component
export struct MeetingView {
  @Prop roomID: string = ''
  @Prop roomName: string = ''
  @Prop isCreate: boolean = false
  @Prop autoEnableMicrophone: boolean = false
  @Prop autoEnableCamera: boolean = false
  @Prop autoEnableSpeaker: boolean = false
  onClose?: () => void
  @State private roomState: RoomState = RoomStore.shared().state
  @State private participantState?: RoomParticipantState = undefined
  @State private isLoading: boolean = true
  @State private isPasswordPresented: boolean = false
  @State private wrongPassword: boolean = false
  @State private isRecordingNotificationPresented: boolean = false
  @State private microphoneInvitation?: DeviceRequestInfo = undefined
  @State private cameraInvitation?: DeviceRequestInfo = undefined
  @State private latestInvitationDevice?: DeviceType = undefined
  private roomListener: RoomListener = new RoomListener()
  private participantListener: RoomParticipantListener = new RoomParticipantListener()

  aboutToAppear(): void {
    RoomSafeArea.observe()
    const participantStore = RoomParticipantStore.create(this.roomID)
    this.participantState = participantStore.state
    this.setupListeners()
    RoomStore.shared().addRoomListener(this.roomListener)
    participantStore.addRoomParticipantListener(this.participantListener)
    this.joinOrCreate()
  }

  aboutToDisappear(): void {
    RoomParticipantStore.create(this.roomID).removeRoomParticipantListener(this.participantListener)
    RoomStore.shared().removeRoomListener(this.roomListener)
    RoomSafeArea.stopObserving()
    const context = getContext(this) as common.UIAbilityContext
    RoomAVSessionManager.stop(context)
  }

  private joinOrCreate(): void {
    this.isLoading = true
    const request = this.isCreate ?
      RoomStore.shared().createAndJoinRoom(this.roomID, RoomType.standard,
        new CreateRoomOptions(this.roomName.length > 0 ? this.roomName : this.roomID)) :
      RoomStore.shared().joinRoom(this.roomID, RoomType.standard)
    request.then(() => {
      this.isLoading = false
      RoomAVSessionManager.start(getContext(this) as common.UIAbilityContext)
      this.applyConnectConfig()
    }).catch((error: Error) => {
      this.isLoading = false
      const code = Number(Reflect.get(error, 'code') ?? -1)
      if (!this.isCreate && (code === ErrorRule.PASSWORD_REQUIRED || code === ErrorRule.WRONG_PASSWORD)) {
        this.wrongPassword = code === ErrorRule.WRONG_PASSWORD
        this.isPasswordPresented = true
      } else {
        ErrorLocalized.showError(error)
        this.closeMeeting()
      }
    })
  }

  private joinWithPassword(password: string): void {
    this.isPasswordPresented = false
    this.isLoading = true
    RoomStore.shared().joinRoom(this.roomID, RoomType.standard, password).then(() => {
      this.isLoading = false
      RoomAVSessionManager.start(getContext(this) as common.UIAbilityContext)
      this.applyConnectConfig()
      RoomParticipantStore.create(this.roomID).getParticipantList().catch(() => {
      })
    }).catch((error: Error) => {
      this.isLoading = false
      const code = Number(Reflect.get(error, 'code') ?? -1)
      if (code === ErrorRule.PASSWORD_REQUIRED || code === ErrorRule.WRONG_PASSWORD) {
        this.wrongPassword = code === ErrorRule.WRONG_PASSWORD
        this.isPasswordPresented = true
      } else {
        ErrorLocalized.showError(error)
        this.closeMeeting()
      }
    })
  }

  private closeMeeting(): void {
    this.onClose?.()
  }

  private async applyConnectConfig(): Promise<void> {
    const deviceStore = DeviceStore.shared()
    deviceStore.setAudioRoute(this.autoEnableSpeaker ? AudioRoute.speakerphone : AudioRoute.earpiece)
    const context = getContext(this) as common.UIAbilityContext
    if (this.autoEnableMicrophone && this.canOpenMicrophone()) {
      const granted = await RoomDevicePermission.requestMicrophonePermission(context)
      if (granted) {
        try {
          await RoomParticipantStore.create(this.roomID).unmuteMicrophone()
        } catch (error) {
          ErrorLocalized.showError(error as Error)
        }
      } else {
        RoomToast.show(RoomResources.string('roomkit_device_mic_no_permission'))
      }
    }
    if (this.autoEnableCamera && this.canOpenCamera()) {
      const granted = await RoomDevicePermission.requestCameraPermission(context)
      if (granted) {
        try {
          await deviceStore.openLocalCamera(deviceStore.state.isFrontCamera)
        } catch (error) {
          ErrorLocalized.showError(error as Error)
        }
      } else {
        RoomToast.show(RoomResources.string('roomkit_device_camera_no_permission'))
      }
    }
  }

  private canOpenMicrophone(): boolean {
    const role = this.participantState?.localParticipant?.role
    const manager = role === ParticipantRole.owner || role === ParticipantRole.admin
    return manager || this.roomState.currentRoom?.isAllMicrophoneDisabled !== true
  }

  private canOpenCamera(): boolean {
    const role = this.participantState?.localParticipant?.role
    const manager = role === ParticipantRole.owner || role === ParticipantRole.admin
    return manager || this.roomState.currentRoom?.isAllCameraDisabled !== true
  }

  private setupListeners(): void {
    this.roomListener.onRoomEnded = () => {
      RoomToast.show(RoomResources.string('roomkit_room_ended_by_host'))
      this.closeMeeting()
    }
    this.roomListener.onRecordingStarted = (_roomInfo: RoomInfo, operator: RoomUser) => {
      this.handleRecordingStarted(operator)
    }
    this.roomListener.onRecordingStopped = (_roomInfo: RoomInfo, operator: RoomUser, reason: RecordingStopReason) => {
      this.handleRecordingStopped(operator, reason)
    }
    this.participantListener.onAdminSet = (user: RoomUser) => {
      if (this.isLocal(user.userID)) {
        RoomToast.show(RoomResources.string('roomkit_room_notifications_become_admin'))
      }
    }
    this.participantListener.onAdminRevoked = (user: RoomUser) => {
      if (this.isLocal(user.userID)) {
        RoomToast.show(RoomResources.string('roomkit_room_notifications_admin_revoked'))
      }
    }
    this.participantListener.onOwnerChanged = (newOwner: RoomUser) => {
      if (this.isLocal(newOwner.userID)) {
        RoomToast.show(RoomResources.string('roomkit_room_notifications_become_owner'))
      }
    }
    this.participantListener.onKickedFromRoom = (reason: KickedOutOfRoomReason) => {
      RoomToast.show(RoomResources.string(this.kickedMessage(reason)))
      this.closeMeeting()
    }
    this.participantListener.onParticipantDeviceClosed = (device: DeviceType, operator: RoomUser) => {
      let key = ''
      switch (device) {
        case DeviceType.microphone:
          key = 'roomkit_room_notifications_microphone_closed'
          break
        case DeviceType.camera:
          key = 'roomkit_room_notifications_camera_closed'
          break
        case DeviceType.screenShare:
          key = 'roomkit_room_notifications_screen_share_closed'
          break
      }
      RoomToast.show(RoomResources.string(key, getRoomUserDisplayName(operator)))
    }
    this.participantListener.onUserMessageDisabled = (disable: boolean) => {
      RoomToast.show(RoomResources.string(disable ? 'roomkit_room_notifications_message_muted' :
        'roomkit_room_notifications_message_unmuted'))
    }
    this.participantListener.onAllDevicesDisabled = (device: DeviceType, disable: boolean, operator: RoomUser) => {
      if (this.isLocal(operator.userID)) {
        return
      }
      let key = ''
      switch (device) {
        case DeviceType.microphone:
          key = disable ? 'roomkit_room_notifications_all_microphones_disabled' :
            'roomkit_room_notifications_all_microphones_enabled'
          break
        case DeviceType.camera:
          key = disable ? 'roomkit_room_notifications_all_cameras_disabled' :
            'roomkit_room_notifications_all_cameras_enabled'
          break
        case DeviceType.screenShare:
          key = disable ? 'roomkit_room_notifications_all_screen_shares_disabled' :
            'roomkit_room_notifications_all_screen_shares_enabled'
          break
      }
      RoomToast.show(RoomResources.string(key))
    }
    this.participantListener.onAllMessagesDisabled = (disable: boolean, operator: RoomUser) => {
      if (!this.isLocal(operator.userID)) {
        RoomToast.show(RoomResources.string(disable ? 'roomkit_room_notifications_all_messages_disabled' :
          'roomkit_room_notifications_all_messages_enabled'))
      }
    }
    this.participantListener.onDeviceInvitationReceived = (invitation: DeviceRequestInfo) => {
      if (invitation.device === DeviceType.microphone) {
        this.microphoneInvitation = invitation
        this.latestInvitationDevice = DeviceType.microphone
      } else if (invitation.device === DeviceType.camera) {
        this.cameraInvitation = invitation
        this.latestInvitationDevice = DeviceType.camera
      }
    }
    this.participantListener.onDeviceInvitationCancelled = (invitation: DeviceRequestInfo) => this.clearInvitation(invitation)
    this.participantListener.onDeviceInvitationTimeout = (invitation: DeviceRequestInfo) => this.clearInvitation(invitation)
    this.participantListener.onDeviceInvitationDeclined = (invitation: DeviceRequestInfo) => {
      RoomToast.show(RoomResources.string('roomkit_room_notifications_device_request_rejected',
        this.deviceName(invitation.device)))
    }
  }

  private activeInvitation(): DeviceRequestInfo | undefined {
    if (this.latestInvitationDevice === DeviceType.microphone && this.microphoneInvitation !== undefined) {
      return this.microphoneInvitation
    }
    if (this.latestInvitationDevice === DeviceType.camera && this.cameraInvitation !== undefined) {
      return this.cameraInvitation
    }
    return this.microphoneInvitation ?? this.cameraInvitation
  }

  private clearInvitation(invitation: DeviceRequestInfo): void {
    if (invitation.device === DeviceType.microphone && this.microphoneInvitation?.senderUserID === invitation.senderUserID) {
      this.microphoneInvitation = undefined
      if (this.latestInvitationDevice === DeviceType.microphone) {
        this.latestInvitationDevice = undefined
      }
    } else if (invitation.device === DeviceType.camera && this.cameraInvitation?.senderUserID === invitation.senderUserID) {
      this.cameraInvitation = undefined
      if (this.latestInvitationDevice === DeviceType.camera) {
        this.latestInvitationDevice = undefined
      }
    }
  }

  private async acceptInvitation(): Promise<void> {
    const invitation = this.activeInvitation()
    if (invitation === undefined) {
      return
    }
    const participantStore = RoomParticipantStore.create(this.roomID)
    this.clearInvitation(invitation)
    const context = getContext(this) as common.UIAbilityContext
    const granted = invitation.device === DeviceType.microphone ?
      await RoomDevicePermission.requestMicrophonePermission(context) :
      await RoomDevicePermission.requestCameraPermission(context)
    if (!granted) {
      try {
        await participantStore.declineOpenDeviceInvitation(invitation.senderUserID, invitation.device)
      } catch (error) {
      }
      RoomToast.show(RoomResources.string(invitation.device === DeviceType.microphone ?
        'roomkit_device_mic_no_permission' : 'roomkit_device_camera_no_permission'))
      return
    }
    try {
      await participantStore.acceptOpenDeviceInvitation(invitation.senderUserID, invitation.device)
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private async declineInvitation(): Promise<void> {
    const invitation = this.activeInvitation()
    if (invitation === undefined) {
      return
    }
    this.clearInvitation(invitation)
    try {
      await RoomParticipantStore.create(this.roomID).declineOpenDeviceInvitation(invitation.senderUserID, invitation.device)
    } catch (error) {
      ErrorLocalized.showError(error as Error)
    }
  }

  private invitationMessage(invitation?: DeviceRequestInfo): string {
    if (invitation === undefined) {
      return ''
    }
    switch (invitation.device) {
      case DeviceType.microphone:
        return RoomResources.string('roomkit_room_notifications_microphone_invitation_received', getSenderName(invitation))
      case DeviceType.camera:
        return RoomResources.string('roomkit_room_notifications_camera_invitation_received', getSenderName(invitation))
      default:
        return ''
    }
  }

  private invitationPrimaryText(device?: DeviceType): string {
    switch (device) {
      case DeviceType.microphone:
        return RoomResources.string('roomkit_room_notifications_open_microphone')
      case DeviceType.camera:
        return RoomResources.string('roomkit_room_notifications_open_camera')
      default:
        return ''
    }
  }

  private invitationSecondaryText(device?: DeviceType): string {
    switch (device) {
      case DeviceType.microphone:
        return RoomResources.string('roomkit_room_notifications_keep_mute')
      case DeviceType.camera:
        return RoomResources.string('roomkit_room_notifications_keep_off')
      default:
        return ''
    }
  }

  private handleRecordingStarted(operator: RoomUser): void {
    if (this.isLocal(operator.userID)) {
      return
    }
    this.isRecordingNotificationPresented = true
  }

  private handleRecordingStopped(operator: RoomUser, reason: RecordingStopReason): void {
    this.isRecordingNotificationPresented = false
    if (reason === RecordingStopReason.recorderLeftRoom) {
      RoomToast.show(RoomResources.string('roomkit_cloud_recording_ended_abnormal'))
    } else if (!this.isLocal(operator.userID)) {
      RoomToast.show(RoomResources.string('roomkit_cloud_recording_end_title'))
    }
  }

  private isLocal(userID: string): boolean {
    return userID.length > 0 && userID === LoginStore.shared().state.loginUserInfo?.userID
  }

  private deviceName(device: DeviceType): string {
    switch (device) {
      case DeviceType.microphone: return RoomResources.string('roomkit_room_notifications_microphone')
      case DeviceType.camera: return RoomResources.string('roomkit_room_notifications_camera')
      case DeviceType.screenShare: return RoomResources.string('roomkit_room_notifications_screen_share')
    }
  }

  private kickedMessage(reason: KickedOutOfRoomReason): string {
    switch (reason) {
      case KickedOutOfRoomReason.kickedByAdmin: return 'roomkit_room_notifications_kicked_by_admin'
      case KickedOutOfRoomReason.kickedByServer: return 'roomkit_room_notifications_kicked_by_server'
      case KickedOutOfRoomReason.replacedByAnotherDevice:
        return 'roomkit_room_notifications_replaced_by_another_device'
      case KickedOutOfRoomReason.connectionTimeout: return 'roomkit_room_notifications_connection_timeout'
      case KickedOutOfRoomReason.invalidStatusOnReconnect:
        return 'roomkit_room_notifications_invalid_status_on_reconnect'
      case KickedOutOfRoomReason.roomLimitExceeded: return 'roomkit_room_notifications_room_limit_exceeded'
      default: return 'roomkit_room_notifications_default_kicked_out'
    }
  }

  build() {
    Stack() {
      Column() {
        MeetingTopBar({ roomID: this.roomID, onLeaveOrEnd: () => this.closeMeeting() })
        Stack() {
          RoomView({ roomID: this.roomID })
          RoomScreenSharingPlaceholderView({ roomID: this.roomID })
        }
        .layoutWeight(1)
        MeetingToolBar({ roomID: this.roomID })
      }
      .width('100%')
      .height('100%')
      RoomDialog({
        isPresented: this.activeInvitation() !== undefined,
        title: RoomResources.string('roomkit_room_common_notification'),
        message: this.invitationMessage(this.activeInvitation()),
        primaryText: this.invitationPrimaryText(this.activeInvitation()?.device),
        secondaryText: this.invitationSecondaryText(this.activeInvitation()?.device),
        cancelable: false,
        onPrimary: () => this.acceptInvitation(),
        onSecondary: () => this.declineInvitation(),
      })
      RoomDialog({
        isPresented: this.isRecordingNotificationPresented,
        title: RoomResources.string('roomkit_cloud_recording_notify_title'),
        message: RoomResources.string('roomkit_cloud_recording_notify_content'),
        primaryText: RoomResources.string('roomkit_cloud_recording_notify_confirm'),
        secondaryText: RoomResources.string('roomkit_cloud_recording_notify_cancel'),
        cancelable: false,
        onPrimary: () => this.isRecordingNotificationPresented = false,
        onSecondary: () => {
          this.isRecordingNotificationPresented = false
          RoomStore.shared().leaveRoom().then(() => {
            this.closeMeeting()
          }).catch((error: Error) => {
            ErrorLocalized.showError(error)
          })
        },
        onDismiss: () => this.isRecordingNotificationPresented = false,
      })
      MeetingPasswordDialog({
        isPresented: this.isPasswordPresented,
        wrongPassword: this.wrongPassword,
        onSubmit: (password: string) => this.joinWithPassword(password),
        onCancel: () => this.closeMeeting(),
      })
      MeetingLoadingView({ isVisible: this.isLoading })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.roomkit_bg_surface'))
  }
}
