import {
  MessageInfo,
  MessageType,
  SystemMessageInfo,
  GroupJoinOption,
  RecallMessageSystemMessage,
  JoinGroupSystemMessage,
  InviteToGroupSystemMessage,
  QuitGroupSystemMessage,
  KickedFromGroupSystemMessage,
  SetGroupAdminSystemMessage,
  CancelGroupAdminSystemMessage,
  ChangeGroupNameSystemMessage,
  ChangeGroupAvatarSystemMessage,
  ChangeGroupNotificationSystemMessage,
  ChangeGroupIntroductionSystemMessage,
  ChangeGroupOwnerSystemMessage,
  ChangeGroupMuteAllSystemMessage,
  ChangeJoinGroupApprovalSystemMessage,
  ChangeInviteToGroupApprovalSystemMessage,
  MuteGroupMemberSystemMessage,
  PinGroupMessageSystemMessage,
  UnpinGroupMessageSystemMessage
} from '@tencentcloud/atomicxcore';
import { TextUtils } from '../../basecomponent/Index';
import { util } from '@kit.ArkTS';

export class MessageUtils {
  static getSystemInfoDisplayString(systemInfo?: SystemMessageInfo): string | Resource {
    if (!systemInfo) {
      return "";
    }

    if (systemInfo instanceof RecallMessageSystemMessage) {
      return MessageUtils.getRecallDisplayString(systemInfo);
    } else if (systemInfo instanceof JoinGroupSystemMessage) {
      return MessageUtils.getJoinGroupDisplayString(systemInfo);
    } else if (systemInfo instanceof InviteToGroupSystemMessage) {
      return MessageUtils.getInviteToGroupDisplayString(systemInfo);
    } else if (systemInfo instanceof QuitGroupSystemMessage) {
      return MessageUtils.getQuitGroupDisplayString(systemInfo);
    } else if (systemInfo instanceof KickedFromGroupSystemMessage) {
      return MessageUtils.getKickedFromGroupDisplayString(systemInfo);
    } else if (systemInfo instanceof SetGroupAdminSystemMessage) {
      return MessageUtils.getSetGroupAdminDisplayString(systemInfo);
    } else if (systemInfo instanceof CancelGroupAdminSystemMessage) {
      return MessageUtils.getCancelGroupAdminDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeGroupNameSystemMessage) {
      return MessageUtils.getChangeGroupNameDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeGroupAvatarSystemMessage) {
      return MessageUtils.getChangeGroupAvatarDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeGroupNotificationSystemMessage) {
      return MessageUtils.getChangeGroupNotificationDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeGroupIntroductionSystemMessage) {
      return MessageUtils.getChangeGroupIntroductionDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeGroupOwnerSystemMessage) {
      return MessageUtils.getChangeGroupOwnerDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeGroupMuteAllSystemMessage) {
      return MessageUtils.getChangeGroupMuteAllDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeJoinGroupApprovalSystemMessage) {
      return MessageUtils.getChangeJoinGroupApprovalDisplayString(systemInfo);
    } else if (systemInfo instanceof ChangeInviteToGroupApprovalSystemMessage) {
      return MessageUtils.getChangeInviteToGroupApprovalDisplayString(systemInfo);
    } else if (systemInfo instanceof MuteGroupMemberSystemMessage) {
      return MessageUtils.getMuteGroupMemberDisplayString(systemInfo);
    } else if (systemInfo instanceof PinGroupMessageSystemMessage) {
      return MessageUtils.getPinGroupMessageDisplayString(systemInfo);
    } else if (systemInfo instanceof UnpinGroupMessageSystemMessage) {
      return MessageUtils.getUnpinGroupMessageDisplayString(systemInfo);
    } else {
      return $r('app.string.unknown');
    }
  }

  static getRecallDisplayString(systemInfo: RecallMessageSystemMessage): string | Resource {
    const reason = systemInfo.recallReason || "";
    if (systemInfo.isRecalledBySelf) {
      return $r('app.string.message_tips_you_recall');
    } else if (systemInfo.isInGroup) {
      const op = systemInfo.recallMessageOperator || "";
      if (reason) {
        const baseMessage = $r('app.string.message_tips_recall_format', op);
        return `${baseMessage}: ${reason}`;
      } else {
        return $r('app.string.message_tips_recall_format', op);
      }
    } else {
      return $r('app.string.message_tips_others_recall');
    }
  }

  static getJoinGroupDisplayString(systemInfo: JoinGroupSystemMessage): string | Resource {
    const name = systemInfo.joinMember || "";
    return $r('app.string.message_tips_join_group', name);
  }

  static getInviteToGroupDisplayString(systemInfo: InviteToGroupSystemMessage): string | Resource {
    const inviter = systemInfo.inviter || "";
    const invitees = systemInfo.inviteesShowName || "";
    return $r('app.string.message_tips_invite_join_group', inviter, invitees);
  }

  static getQuitGroupDisplayString(systemInfo: QuitGroupSystemMessage): string | Resource {
    const name = systemInfo.quitMember || "";
    return $r('app.string.message_tips_leave_group', name);
  }

  static getKickedFromGroupDisplayString(systemInfo: KickedFromGroupSystemMessage): string | Resource {
    const op = systemInfo.kickOperator || "";
    const kicked = systemInfo.kickedMembersShowName || "";
    return $r('app.string.message_tips_kickoff_group', op, kicked);
  }

  static getSetGroupAdminDisplayString(systemInfo: SetGroupAdminSystemMessage): string | Resource {
    const name = systemInfo.setAdminMembersShowName || "";
    return $r('app.string.message_tips_set_admin', name);
  }

  static getCancelGroupAdminDisplayString(systemInfo: CancelGroupAdminSystemMessage): string | Resource {
    const name = systemInfo.cancelAdminMembersShowName || "";
    return $r('app.string.message_tips_cancel_admin', name);
  }

  static getChangeGroupNameDisplayString(systemInfo: ChangeGroupNameSystemMessage): string | Resource {
    const op = systemInfo.groupNameOperator || "";
    const name = systemInfo.groupName || '';
    return $r('app.string.message_tips_edit_group_name', op, name);
  }

  static getChangeGroupAvatarDisplayString(systemInfo: ChangeGroupAvatarSystemMessage): string | Resource {
    const op = systemInfo.groupAvatarOperator || "";
    return $r('app.string.message_tips_edit_group_avatar', op);
  }

  static getChangeGroupNotificationDisplayString(systemInfo: ChangeGroupNotificationSystemMessage): string | Resource {
    const op = systemInfo.groupNotificationOperator || "";
    const announce = systemInfo.groupNotification || '';
    return $r('app.string.message_tips_edit_group_announce', op, announce);
  }

  static getChangeGroupIntroductionDisplayString(systemInfo: ChangeGroupIntroductionSystemMessage): string | Resource {
    const op = systemInfo.groupIntroductionOperator || "";
    const intro = systemInfo.groupIntroduction || '';
    return $r('app.string.message_tips_edit_group_intro', op, intro);
  }

  static getChangeGroupOwnerDisplayString(systemInfo: ChangeGroupOwnerSystemMessage): string | Resource {
    const op = systemInfo.groupOwnerOperator || "";
    const owner = systemInfo.groupOwner || "";
    return $r('app.string.message_tips_edit_group_owner', op, owner);
  }

  static getChangeGroupMuteAllDisplayString(systemInfo: ChangeGroupMuteAllSystemMessage): string | Resource {
    const op = systemInfo.groupMuteAllOperator || "";
    return systemInfo.isMuteAll ?
      $r('app.string.message_tips_shutup_all', op) :
      $r('app.string.message_tips_cancel_shutup_all', op);
  }

  static getChangeJoinGroupApprovalDisplayString(systemInfo: ChangeJoinGroupApprovalSystemMessage): string | Resource {
    const op = systemInfo.groupJoinApprovalOperator || "";
    const approvalDesc = MessageUtils.getJoinApprovalDescription(systemInfo.groupJoinOption);
    return $r('app.string.message_tips_edit_group_join', op, approvalDesc);
  }

  static getChangeInviteToGroupApprovalDisplayString(systemInfo: ChangeInviteToGroupApprovalSystemMessage): string | Resource {
    const op = systemInfo.groupInviteApprovalOperator || "";
    const approvalDesc = MessageUtils.getInviteApprovalDescription(systemInfo.groupInviteOption);
    return $r('app.string.message_tips_edit_group_invite', op, approvalDesc);
  }

  static getMuteGroupMemberDisplayString(systemInfo: MuteGroupMemberSystemMessage): string | Resource {
    const muteTime = systemInfo.muteTime || 0;
    const memberShowName = systemInfo.mutedGroupMembersShowName || "";
    const isSelfMuted = systemInfo.isSelfMuted || false;
    
    if (muteTime === 0) {
      if (isSelfMuted) {
        return $r('app.string.message_tips_self_unmute');
      } else {
        return $r('app.string.message_tips_member_unmute', memberShowName || "");
      }
    } else {
      const duration = MessageUtils.formatMuteTime(muteTime);
      if (isSelfMuted) {
        return $r('app.string.message_tips_self_mute', duration);
      } else {
        return $r('app.string.message_tips_member_mute', memberShowName || "", duration);
      }
    }
  }

  static getPinGroupMessageDisplayString(systemInfo: PinGroupMessageSystemMessage): string | Resource {
    const op = systemInfo.pinGroupMessageOperator || "";
    return $r('app.string.message_tips_group_pin', op);
  }

  static getUnpinGroupMessageDisplayString(systemInfo: UnpinGroupMessageSystemMessage): string | Resource {
    const op = systemInfo.unpinGroupMessageOperator || "";
    return $r('app.string.message_tips_group_unpin', op);
  }

  static getMessageAbstract(messageInfo?: MessageInfo): string | Resource {
    if (!messageInfo) {
      return "";
    }

    switch (messageInfo.messageType) {
      case MessageType.Text:
        return messageInfo.messageBody?.text || "";
      case MessageType.Image:
        return $r('app.string.message_type_image');
      case MessageType.Sound:
        return $r('app.string.message_type_voice');
      case MessageType.File:
        return $r('app.string.message_type_file');
      case MessageType.Video:
        return $r('app.string.message_type_video');
      case MessageType.Face:
        return $r('app.string.message_type_animate_emoji');
      case MessageType.Custom:
        const customMessage = messageInfo.messageBody?.customMessage;
        const data = customMessage?.data;
        if (data) {
          const textDecoder = new util.TextDecoder('utf-8');
          const dataStr = textDecoder.decode(new Uint8Array(data));
          if (dataStr) {
            try {
              const customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
              if (customInfo && customInfo["businessID"] === "group_create") {
                const sender = customInfo["opUser"] as string || "";
                const cmd = customInfo["cmd"] as number || 0;
                if (cmd === 1) {
                  return $r('app.string.community_create_tips_format', sender);
                } else {
                  return $r('app.string.group_create_tips_format', sender);
                }
              } else {
                return $r('app.string.message_tips_unsupport_custom');
              }
            } catch (e) {
              console.error("error:", e.message);
            }
          }
          return $r('app.string.message_tips_unsupport_custom');
        }
      case MessageType.System:
        const systemMessages = messageInfo.messageBody?.systemMessage;
        if (systemMessages && systemMessages.length > 0) {
          return MessageUtils.getSystemInfoDisplayString(systemMessages[0]);
        }
        return "";
      default:
        return "";
    }
  }

  static formatMuteTime(seconds: number): string {
    if (seconds <= 0) {
      return "";
    }

    let timeStr = `${seconds} second${seconds > 1 ? 's' : ''}`;

    if (seconds > 60) {
      const second = seconds % 60;
      let min = Math.floor(seconds / 60);
      timeStr = `${min} min ${second} sec`;

      if (min > 60) {
        min = Math.floor(seconds / 60) % 60;
        const hour = Math.floor(Math.floor(seconds / 60) / 60);
        timeStr = `${hour} hour ${min} min ${second} sec`;

        if (hour % 24 === 0) {
          const day = Math.floor(Math.floor(Math.floor(seconds / 60) / 60) / 24);
          timeStr = `${day} day${day > 1 ? 's' : ''}`;
        } else if (hour > 24) {
          const newHour = Math.floor(Math.floor(seconds / 60) / 60) % 24;
          const day = Math.floor(Math.floor(Math.floor(seconds / 60) / 60) / 24);
          timeStr = `${day} day ${newHour} hour ${min} min ${second} sec`;
        }
      }
    }

    return timeStr;
  }

  static convertDateToHMStr(timeStamp?: number): string {
    if (!timeStamp) {
      return "";
    }
    if (timeStamp === 0) {
      return "";
    }

    const date = new Date(timeStamp * 1000);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  private static getJoinApprovalDescription(option?: GroupJoinOption): string | Resource {
    try {
      switch (option) {
        case GroupJoinOption.FORBID:
          return $r('app.string.group_join_disable');
        case GroupJoinOption.AUTH:
          return $r('app.string.group_admin_approve');
        case GroupJoinOption.ANY:
          return $r('app.string.group_auto_approval');
        default:
          return $r('app.string.unknown');
      }
    } catch (error) {
      console.error('[MessageUtils] Failed to get join approval description:', error);
      return '';
    }
  }

  private static getInviteApprovalDescription(option?: GroupJoinOption): string | Resource {
    switch (option) {
      case GroupJoinOption.FORBID:
        return $r('app.string.group_invite_disable');
      case GroupJoinOption.AUTH:
        return $r('app.string.group_admin_approve');
      case GroupJoinOption.ANY:
        return $r('app.string.group_auto_approval');
      default:
        return $r('app.string.unknown');
    }
  }
}
