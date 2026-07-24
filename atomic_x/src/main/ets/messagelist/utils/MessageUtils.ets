import { MessageInfo, MessageType, MessageStatus, TextMessagePayload, AudioMessagePayload, CustomMessagePayload, TipsMessagePayload, GroupTipsInfo, JoinGroup, InviteToGroup, QuitGroup, KickedFromGroup, SetGroupAdmin, CancelGroupAdmin, ChangeGroupName, ChangeGroupAvatar, ChangeGroupNotification, ChangeGroupIntroduction, ChangeGroupOwner, ChangeGroupMuteAll, ChangeJoinGroupApproval, ChangeInviteToGroupApproval, MuteGroupMember, PinGroupMessage, UnpinGroupMessage } from '@tencentcloud/atomicxcore';
import { ConversationType } from '@tencentcloud/atomicxcore';
import { GroupJoinOption, GroupInviteOption } from '@tencentcloud/atomicxcore';
import { GroupMember } from '@tencentcloud/atomicxcore';
import { CallingMessageDataProvider } from './CallingMessageDataProvider';

interface GroupTipsLike {
  opUser?: GroupMember;
  joinMember?: GroupMember;
  inviter?: GroupMember;
  invitees?: GroupMember[];
  quitMember?: GroupMember;
  kickedMembers?: GroupMember[];
  setAdminMembers?: GroupMember[];
  cancelAdminMembers?: GroupMember[];
  groupName?: string;
  groupAvatar?: string;
  groupNotification?: string;
  groupIntroduction?: string;
  groupOwner?: string;
  isMuteAll?: boolean;
  groupJoinOption?: GroupJoinOption;
  groupInviteOption?: GroupInviteOption;
  mutedGroupMembers?: GroupMember[];
  isSelfMuted?: boolean;
  muteTime?: number;
}

export class ReadReceiptLabelInfo {
  text: string;
  isHighlight: boolean;

  constructor(text: string, isHighlight: boolean) {
    this.text = text;
    this.isHighlight = isHighlight;
  }
}

export class MessageUtils {
  // TODO(harmony): IM SDK Harmony 版会把群 @ 系统镜像消息(sender 以 @TIM#SYSTEM 结尾)
  // 透传到 onRecvNewMessage,Android SDK 在 native 层已消化。SDK 修复后可移除此方法及调用方。
  static isMentionMirrorMessage(message: MessageInfo): boolean {
    if (message.messageType === MessageType.TIPS) {
      return false;
    }
    const senderID = message.from?.userID ?? '';
    return senderID.endsWith('@TIM#SYSTEM');
  }

  static getRecallDisplayString(message: MessageInfo): string | Resource {
    const revokeReason = message.revokeReason ?? '';
    if (message.conversationType === ConversationType.GROUP) {
      const revokerName = MessageUtils.revokerDisplayName(message);
      if (revokerName.length > 0) {
        if (revokeReason.length > 0) {
          return `${revokerName}${MessageUtils.resourceToString($r('app.string.message_tips_recall'))}: ${revokeReason}`;
        }
        return $r('app.string.message_tips_recall_format', revokerName);
      }
      if (revokeReason.length > 0) {
        return `${MessageUtils.resourceToString($r('app.string.message_tips_normal_recall'))}: ${revokeReason}`;
      }
      return $r('app.string.message_tips_normal_recall');
    }
    if (message.isSentBySelf) {
      if (revokeReason.length > 0) {
        return `${MessageUtils.resourceToString($r('app.string.message_tips_you_recall'))}: ${revokeReason}`;
      }
      return $r('app.string.message_tips_you_recall');
    }
    if (revokeReason.length > 0) {
      return `${MessageUtils.resourceToString($r('app.string.message_tips_others_recall'))}: ${revokeReason}`;
    }
    return $r('app.string.message_tips_others_recall');
  }

  static getSystemInfoDisplayString(tips?: GroupTipsInfo): string | Resource {
    if (!tips) {
      return '';
    }

    const t = tips as GroupTipsLike;
    if (t.joinMember !== undefined) {
      return $r('app.string.message_tips_join_group',
        MessageUtils.memberDisplayName(t.joinMember));
    } else if (t.invitees !== undefined && t.inviter !== undefined) {
      return $r('app.string.message_tips_invite_join_group',
        MessageUtils.memberDisplayName(t.inviter),
        MessageUtils.joinMemberNames(t.invitees));
    } else if (t.quitMember !== undefined) {
      return $r('app.string.message_tips_leave_group',
        MessageUtils.memberDisplayName(t.quitMember));
    } else if (t.kickedMembers !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_kickoff_group',
        MessageUtils.memberDisplayName(t.opUser),
        MessageUtils.joinMemberNames(t.kickedMembers));
    } else if (t.setAdminMembers !== undefined) {
      return $r('app.string.message_tips_set_admin',
        MessageUtils.joinMemberNames(t.setAdminMembers));
    } else if (t.cancelAdminMembers !== undefined) {
      return $r('app.string.message_tips_cancel_admin',
        MessageUtils.joinMemberNames(t.cancelAdminMembers));
    } else if (t.groupName !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_name',
        MessageUtils.memberDisplayName(t.opUser), t.groupName);
    } else if (t.groupAvatar !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_avatar',
        MessageUtils.memberDisplayName(t.opUser));
    } else if (t.groupNotification !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_announce',
        MessageUtils.memberDisplayName(t.opUser), t.groupNotification);
    } else if (t.groupIntroduction !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_intro',
        MessageUtils.memberDisplayName(t.opUser), t.groupIntroduction);
    } else if (t.groupOwner !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_owner',
        MessageUtils.memberDisplayName(t.opUser), t.groupOwner);
    } else if (t.isMuteAll !== undefined && t.opUser !== undefined) {
      const op = MessageUtils.memberDisplayName(t.opUser);
      return t.isMuteAll ?
        $r('app.string.message_tips_shutup_all', op) :
        $r('app.string.message_tips_cancel_shutup_all', op);
    } else if (t.groupJoinOption !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_join',
        MessageUtils.memberDisplayName(t.opUser),
        MessageUtils.getJoinApprovalDescription(t.groupJoinOption));
    } else if (t.groupInviteOption !== undefined && t.opUser !== undefined) {
      return $r('app.string.message_tips_edit_group_invite',
        MessageUtils.memberDisplayName(t.opUser),
        MessageUtils.getInviteApprovalDescription(t.groupInviteOption));
    } else if (t.mutedGroupMembers !== undefined) {
      const memberShowName = MessageUtils.joinMemberNames(t.mutedGroupMembers);
      const isSelfMuted = t.isSelfMuted ?? false;
      const muteTime = t.muteTime ?? 0;
      if (muteTime === 0) {
        if (isSelfMuted) {
          return $r('app.string.message_tips_self_unmute');
        }
        return $r('app.string.message_tips_member_unmute', memberShowName);
      }
      const duration = MessageUtils.formatMuteTime(muteTime);
      if (isSelfMuted) {
        return $r('app.string.message_tips_self_mute', duration);
      }
      return $r('app.string.message_tips_member_mute', memberShowName, duration);
    } else if (tips instanceof PinGroupMessage && t.opUser !== undefined) {
      return $r('app.string.message_tips_group_pin',
        MessageUtils.memberDisplayName(t.opUser));
    } else if (tips instanceof UnpinGroupMessage && t.opUser !== undefined) {
      return $r('app.string.message_tips_group_unpin',
        MessageUtils.memberDisplayName(t.opUser));
    } else {
      return '';
    }
  }

  static getMessageAbstract(messageInfo?: MessageInfo): string | Resource {
    if (!messageInfo) {
      return '';
    }

    switch (messageInfo.messageType) {
      case MessageType.TEXT: {
        const textPayload = messageInfo.messagePayload as TextMessagePayload | undefined;
        return textPayload?.text || '';
      }
      case MessageType.IMAGE:
        return $r('app.string.message_type_image');
      case MessageType.AUDIO:
        return $r('app.string.message_type_voice');
      case MessageType.FILE:
        return $r('app.string.message_type_file');
      case MessageType.VIDEO:
        return $r('app.string.message_type_video');
      case MessageType.FACE:
        return $r('app.string.message_type_animate_emoji');
      case MessageType.MERGED:
        return $r('app.string.message_type_merged');
      case MessageType.CUSTOM: {
        const customPayload = messageInfo.messagePayload as CustomMessagePayload | undefined;
        const dataStr = customPayload?.customData;
        if (!dataStr) {
          return $r('app.string.message_tips_unsupport_custom');
        }
        try {
          const customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
          const callingProvider = new CallingMessageDataProvider(messageInfo);
          if (callingProvider.isCallingSignal) {
            return callingProvider.content;
          }
          if (customInfo && customInfo['businessID'] === 'group_create') {
            const sender = customInfo['opUser'] as string || '';
            const cmd = customInfo['cmd'] as number || 0;
            if (cmd === 1) {
              return $r('app.string.community_create_tips_format', sender);
            }
            return $r('app.string.group_create_tips_format', sender);
          }
          if (customInfo && customInfo['businessID'] === 'text_link') {
            const text = customInfo['text'];
            if (typeof text === 'string' && text.length > 0) {
              return text;
            }
            return $r('app.string.message_tips_unsupport_custom');
          }
          return $r('app.string.message_tips_unsupport_custom');
        } catch (e) {
          return $r('app.string.message_tips_unsupport_custom');
        }
      }
      case MessageType.TIPS: {
        if (messageInfo.status === MessageStatus.REVOKED) {
          return MessageUtils.getRecallDisplayString(messageInfo);
        }
        const tipsPayload = messageInfo.messagePayload as TipsMessagePayload | undefined;
        const tipsList = tipsPayload?.groupTips;
        if (tipsList && tipsList.length > 0) {
          return MessageUtils.getSystemInfoDisplayString(tipsList[0]);
        }
        return '';
      }
      default:
        return '';
    }
  }

  static formatMuteTime(seconds: number): string {
    if (seconds <= 0) {
      return '';
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
      return '';
    }
    if (timeStamp === 0) {
      return '';
    }
    const date = new Date(timeStamp * 1000);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  private static getJoinApprovalDescription(option?: GroupJoinOption): string | Resource {
    switch (option) {
      case GroupJoinOption.FORBID:
        return $r('app.string.group_join_disable');
      case GroupJoinOption.AUTH:
        return $r('app.string.group_admin_approve');
      case GroupJoinOption.ANY:
        return $r('app.string.group_auto_approval');
      default:
        return $r('app.string.group_admin_approve');
    }
  }

  private static getInviteApprovalDescription(option?: GroupInviteOption): string | Resource {
    switch (option) {
      case GroupInviteOption.FORBID:
        return $r('app.string.group_invite_disable');
      case GroupInviteOption.AUTH:
        return $r('app.string.group_admin_approve');
      case GroupInviteOption.ANY:
        return $r('app.string.group_auto_approval');
      default:
        return $r('app.string.group_admin_approve');
    }
  }

  private static memberDisplayName(member: GroupMember): string {
    if (member.nameCard && member.nameCard.length > 0) {
      return member.nameCard;
    }
    if (member.friendRemark && member.friendRemark.length > 0) {
      return member.friendRemark;
    }
    if (member.nickname && member.nickname.length > 0) {
      return member.nickname;
    }
    return member.userID;
  }

  private static revokerDisplayName(message: MessageInfo): string {
    const revoker = message.revokerInfo;
    if (!revoker) {
      return '';
    }
    if (revoker.nickname && revoker.nickname.length > 0) {
      return revoker.nickname;
    }
    return revoker.userID ?? '';
  }

  private static resourceToString(resource: Resource): string {
    try {
      return getContext().resourceManager.getStringSync(resource.id);
    } catch (e) {
      return '';
    }
  }

  private static joinMemberNames(members: GroupMember[]): string {
    return members.map((m: GroupMember) => MessageUtils.memberDisplayName(m)).join(', ');
  }

  static senderDisplayName(message: MessageInfo): string {
    const sender = message.from;
    if (!sender) {
      return '';
    }
    if (sender.nameCard && sender.nameCard.length > 0) {
      return sender.nameCard;
    }
    if (sender.friendRemark && sender.friendRemark.length > 0) {
      return sender.friendRemark;
    }
    if (sender.nickname && sender.nickname.length > 0) {
      return sender.nickname;
    }
    return sender.userID ?? '';
  }

  static getMessageAbstractString(messageInfo?: MessageInfo): string {
    const abstract = MessageUtils.getMessageAbstract(messageInfo);
    if (typeof abstract === 'string') {
      return abstract;
    }
    try {
      return getContext().resourceManager.getStringSync(abstract.id);
    } catch (e) {
      return '';
    }
  }

  static shouldShowReadReceipt(message: MessageInfo, enableReadReceipt: boolean,
    isInMergedDetailView: boolean = false): boolean {
    return !isInMergedDetailView &&
      enableReadReceipt === true &&
      message.isSentBySelf === true &&
      !!message.needReadReceipt &&
      message.status === MessageStatus.SEND_SUCCESS &&
      message.messageType !== MessageType.TIPS;
  }

  static getReadReceiptIconResource(message: MessageInfo): Resource {
    const isGroup = message.conversationType === ConversationType.GROUP;

    if (!isGroup) {
      const peerRead = message.readReceiptInfo?.isPeerRead === true;
      return peerRead ? $rawfile('messagelist/msg_status_all_people_read.svg') :
        $rawfile('messagelist/msg_status_send_succ.svg');
    }

    const readCount = message.readReceiptInfo?.readCount ?? 0;
    const unreadCount = message.readReceiptInfo?.unreadCount ?? 0;
    const totalCount = readCount + unreadCount;

    if (readCount === 0) {
      return $rawfile('messagelist/msg_status_send_succ.svg');
    }

    if (readCount === totalCount && totalCount > 0) {
      return $rawfile('messagelist/msg_status_all_people_read.svg');
    }

    return $rawfile('messagelist/msg_status_some_people_read.svg');
  }

  static getReadReceiptLabelInfo(message: MessageInfo): ReadReceiptLabelInfo | null {
    const isGroup = message.conversationType === ConversationType.GROUP;

    if (!isGroup) {
      const peerRead = message.readReceiptInfo?.isPeerRead === true;
      if (peerRead) {
        return new ReadReceiptLabelInfo(
          getContext().resourceManager.getStringSync($r('app.string.read_receipt_read_by').id), false);
      }
      return new ReadReceiptLabelInfo(
        getContext().resourceManager.getStringSync($r('app.string.read_receipt_delivered_to').id), true);
    }

    const readCount = message.readReceiptInfo?.readCount ?? 0;
    const unreadCount = message.readReceiptInfo?.unreadCount ?? 0;
    const totalCount = readCount + unreadCount;

    if (totalCount > 0 && readCount === totalCount) {
      return new ReadReceiptLabelInfo(
        getContext().resourceManager.getStringSync($r('app.string.read_receipt_all_read').id), false);
    }
    if (readCount > 0) {
      try {
        const template = getContext().resourceManager.getStringSync($r('app.string.read_receipt_n_person_read').id);
        return new ReadReceiptLabelInfo(template.replace('%d', readCount.toString()), true);
      } catch (e) {
        return new ReadReceiptLabelInfo(`${readCount}`, true);
      }
    }
    return new ReadReceiptLabelInfo(
      getContext().resourceManager.getStringSync($r('app.string.read_receipt_delivered_to').id), true);
  }

  static getMessageStateHash(message: MessageInfo): string {
    try {
      const stateObj: Map<string, Object | undefined> = new Map();
      stateObj.set('msgID', message.msgID);
      stateObj.set('status', message.status);
      stateObj.set('timestamp', message.timestamp);
      stateObj.set('isSentBySelf', message.isSentBySelf);
      stateObj.set('messageType', message.messageType);
      stateObj.set('receiptIsPeerRead', message.readReceiptInfo?.isPeerRead);
      stateObj.set('receiptReadCount', message.readReceiptInfo?.readCount);
      stateObj.set('receiptUnreadCount', message.readReceiptInfo?.unreadCount);
      stateObj.set('uploadProgress', message.uploadMediaProgress);
      stateObj.set('downloadProgress', message.downloadMediaProgress);
      stateObj.set('extensionListLength', message.extensionList?.length);
      stateObj.set('reactionListLength', message.reactionList?.length);
      if (message.quoteInfo) {
        stateObj.set('quoteMsgID', message.quoteInfo.msgID);
        stateObj.set('quoteStatus', message.quoteInfo.status);
        stateObj.set('quoteMessageType', message.quoteInfo.messageType);
        if (message.quoteInfo.messagePayload instanceof TextMessagePayload) {
          stateObj.set('quoteTextLength', message.quoteInfo.messagePayload.text?.length);
        }
      }
      const reactionList = message.reactionList;
      if (reactionList && reactionList.length > 0) {
        const reactionSignature = reactionList
          .map((r) => `${r.reactionID}:${r.totalUserCount ?? 0}:${r.reactedByMyself ? 1 : 0}`)
          .join('|');
        stateObj.set('reactionSignature', reactionSignature);
      }

      if (message.messageType === MessageType.TEXT) {
        const textPayload = message.messagePayload as TextMessagePayload | undefined;
        stateObj.set('translatedSize', textPayload?.translatedText?.size);
        stateObj.set('translateLanguage', textPayload?.translateLanguage);
      } else if (message.messageType === MessageType.AUDIO) {
        const audioPayload = message.messagePayload as AudioMessagePayload | undefined;
        stateObj.set('asrTextLength', audioPayload?.asrText?.length);
      }

      const entries: Array<[string, Object | undefined]> = [];
      stateObj.forEach((value: Object | undefined, key: string) => {
        entries.push([key, value]);
      });
      const jsonStr = JSON.stringify(entries);
      let hash = 0;
      for (let i = 0; i < jsonStr.length; i++) {
        const char = jsonStr.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
      }
      return hash.toString();
    } catch (e) {
      return message.msgID;
    }
  }
}
