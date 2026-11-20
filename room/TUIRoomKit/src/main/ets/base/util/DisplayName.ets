import { DeviceRequestInfo, ParticipantRole, RoomParticipant, RoomUser, UserProfile } from '@tencentcloud/atomicxcore'

function nonBlank(value: string | undefined, fallback: string): string {
  return value !== undefined && value.trim().length > 0 ? value : fallback
}

export function getUserDisplayName(profile: UserProfile): string {
  return nonBlank(profile.nickname, profile.userID)
}

export function getParticipantDisplayName(participant: RoomParticipant): string {
  return nonBlank(participant.nameCard, nonBlank(participant.userName, participant.userID))
}

export function getRoomUserDisplayName(user: RoomUser): string {
  return nonBlank(user.userName, user.userID)
}

export function getSenderName(request: DeviceRequestInfo): string {
  return nonBlank(request.senderNameCard, nonBlank(request.senderUserName, request.senderUserID))
}

export function canManage(role: ParticipantRole | undefined, target: ParticipantRole): boolean {
  if (role === ParticipantRole.owner) {
    return true
  }
  return role === ParticipantRole.admin && target === ParticipantRole.generalUser
}
