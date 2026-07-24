import { MessageInfo, CustomMessagePayload } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';

export enum CallProtocolType {
  unknown,
  send,
  cancel,
  accept,
  reject,
  timeout,
  hangup,
  switchToAudio,
  switchToAudioConfirm,
  lineBusy
}

export enum CallStreamMediaType {
  unknown,
  audio,
  video
}

export enum CallParticipantType {
  unknown,
  c2c,
  group
}

export enum CallParticipantRole {
  unknown,
  caller,
  callee
}

export enum CallMessageDirection {
  incoming,
  outcoming
}

export class CallingMessageDataProvider {
  private _isCallingSignal: boolean = false;
  private _isExcludedFromLastMessage: boolean = false;
  private _isExcludedFromUnreadCount: boolean = false;
  private _protocolType: CallProtocolType = CallProtocolType.unknown;
  private _streamMediaType: CallStreamMediaType = CallStreamMediaType.unknown;
  private _participantType: CallParticipantType = CallParticipantType.unknown;
  private _participantRole: CallParticipantRole = CallParticipantRole.unknown;
  private _direction: CallMessageDirection = CallMessageDirection.incoming;
  private _excludeFromHistory: boolean = false;
  private _content: string = '';
  private _callerId: string = '';
  private _groupID: string = '';
  private _actionType: number = 0;
  private _inviteeList: string[] = [];
  private _jsonData: Record<string, Object> | null = null;
  private messageInfo: MessageInfo;

  get isCallingSignal(): boolean {
    return this._isCallingSignal;
  }

  get content(): string {
    return this._content;
  }

  get protocolType(): CallProtocolType {
    return this._protocolType;
  }

  get streamMediaType(): CallStreamMediaType {
    return this._streamMediaType;
  }

  get participantType(): CallParticipantType {
    return this._participantType;
  }

  get participantRole(): CallParticipantRole {
    return this._participantRole;
  }

  get direction(): CallMessageDirection {
    return this._direction;
  }

  get excludeFromHistory(): boolean {
    return this._excludeFromHistory;
  }

  constructor(messageInfo: MessageInfo) {
    this.messageInfo = messageInfo;
    this._isExcludedFromLastMessage = messageInfo.rawMessage?.isExcludedFromLastMessage ?? false;
    this._isExcludedFromUnreadCount = messageInfo.rawMessage?.isExcludedFromUnreadCount ?? false;

    const customPayload = messageInfo.messagePayload as CustomMessagePayload | undefined;
    const dataStr = customPayload?.customData;
    if (!dataStr) {
      return;
    }

    try {
      if (!dataStr) {
        return;
      }

      const outerData = JSON.parse(dataStr) as Record<string, Object>;
      if (!outerData) {
        return;
      }

      this._actionType = (outerData['actionType'] as number) ?? 0;
      this._groupID = (outerData['groupID'] as string) ?? '';
      const inviteeList = outerData['inviteeList'] as string[];
      if (inviteeList) {
        this._inviteeList = inviteeList;
      }

      const innerDataStr = outerData['data'] as string;
      if (innerDataStr && typeof innerDataStr === 'string') {
        this._jsonData = JSON.parse(innerDataStr) as Record<string, Object>;
      } else if (innerDataStr && typeof innerDataStr === 'object') {
        this._jsonData = innerDataStr as Record<string, Object>;
      } else {
        this._jsonData = outerData;
      }
    } catch (err) {
      return;
    }

    if (!this._jsonData) {
      return;
    }

    this.setIsCallingSignal();
    this.setProtocolType();
    this.setStreamMediaType();
    this.setParticipantType();
    this.setCallerId();
    this.setParticipantRole();
    this.setDirection();
    this.setExcludeFromHistory();
    this.setContent();
  }

  private setIsCallingSignal(): void {
    const businessID = this._jsonData?.['businessID'] as string;
    this._isCallingSignal = businessID === 'av_call' || businessID === 'rtc_call';
  }

  private setProtocolType(): void {
    switch (this._actionType) {
      case 1: {
        const data = this._jsonData?.['data'] as Record<string, Object>;
        if (data) {
          const cmd = data['cmd'] as string;
          if (cmd === 'switchToAudio') {
            this._protocolType = CallProtocolType.switchToAudio;
          } else if (cmd === 'hangup') {
            this._protocolType = CallProtocolType.hangup;
          } else if (cmd === 'videoCall') {
            this._protocolType = CallProtocolType.send;
          } else if (cmd === 'audioCall') {
            this._protocolType = CallProtocolType.send;
          } else {
            this._protocolType = CallProtocolType.unknown;
          }
        } else {
          const callEnd = this._jsonData?.['call_end'];
          if (callEnd !== undefined && callEnd !== null) {
            this._protocolType = CallProtocolType.hangup;
          } else {
            this._protocolType = CallProtocolType.send;
          }
        }
        break;
      }
      case 2:
        this._protocolType = CallProtocolType.cancel;
        break;
      case 3: {
        const data = this._jsonData?.['data'] as Record<string, Object>;
        if (data) {
          const cmd = data['cmd'] as string;
          if (cmd === 'switchToAudio') {
            this._protocolType = CallProtocolType.switchToAudioConfirm;
          } else {
            this._protocolType = CallProtocolType.accept;
          }
        } else {
          this._protocolType = CallProtocolType.accept;
        }
        break;
      }
      case 4:
        if (this._jsonData?.['line_busy'] !== undefined && this._jsonData?.['line_busy'] !== null) {
          this._protocolType = CallProtocolType.lineBusy;
        } else {
          this._protocolType = CallProtocolType.reject;
        }
        break;
      case 5:
        this._protocolType = CallProtocolType.timeout;
        break;
      default:
        this._protocolType = CallProtocolType.unknown;
        break;
    }
  }

  private setStreamMediaType(): void {
    this._streamMediaType = CallStreamMediaType.unknown;
    if (this._protocolType === CallProtocolType.unknown) {
      return;
    }

    const callType = this._jsonData?.['call_type'] as number;
    if (callType === 1) {
      this._streamMediaType = CallStreamMediaType.audio;
    } else if (callType === 2) {
      this._streamMediaType = CallStreamMediaType.video;
    }

    if (this._protocolType === CallProtocolType.send) {
      const data = this._jsonData?.['data'] as Record<string, Object>;
      if (data) {
        const cmd = data['cmd'] as string;
        if (cmd === 'audioCall') {
          this._streamMediaType = CallStreamMediaType.audio;
        } else if (cmd === 'videoCall') {
          this._streamMediaType = CallStreamMediaType.video;
        }
      }
    } else if (this._protocolType === CallProtocolType.switchToAudio ||
      this._protocolType === CallProtocolType.switchToAudioConfirm) {
      this._streamMediaType = CallStreamMediaType.video;
    }
  }

  private setParticipantType(): void {
    if (this._protocolType === CallProtocolType.unknown) {
      this._participantType = CallParticipantType.unknown;
      return;
    }

    this._participantType = this._groupID.length > 0 ? CallParticipantType.group : CallParticipantType.c2c;
  }

  private setCallerId(): void {
    if (this._protocolType === CallProtocolType.unknown) {
      return;
    }

    const data = this._jsonData?.['data'] as Record<string, Object>;
    if (data) {
      const inviter = data['inviter'] as string;
      if (inviter) {
        this._callerId = inviter;
      }
    }

    if (this._callerId.length === 0) {
      this._callerId = LoginStore.shared().state.loginUserInfo?.userID ?? '';
    }
  }

  private setParticipantRole(): void {
    const loginUserId = LoginStore.shared().state.loginUserInfo?.userID;
    this._participantRole = this._callerId === loginUserId
      ? CallParticipantRole.caller
      : CallParticipantRole.callee;
  }

  private setDirection(): void {
    this._direction = this._participantRole === CallParticipantRole.caller
      ? CallMessageDirection.outcoming
      : CallMessageDirection.incoming;
  }

  private setExcludeFromHistory(): void {
    this._excludeFromHistory = this._protocolType !== CallProtocolType.unknown &&
      this._isExcludedFromLastMessage && this._isExcludedFromUnreadCount;
  }

  private setContent(): void {
    if (this._excludeFromHistory) {
      this._content = '';
      return;
    }

    const isCaller = this._participantRole === CallParticipantRole.caller;
    const showName = this.getShowName();
    const ctx = getContext();

    if (this._participantType === CallParticipantType.c2c) {
      if (this._protocolType === CallProtocolType.reject) {
        this._content = this.getStr(ctx, isCaller ? $r('app.string.call_reject_caller') : $r('app.string.call_reject_callee'));
      } else if (this._protocolType === CallProtocolType.cancel) {
        this._content = this.getStr(ctx, isCaller ? $r('app.string.call_cancel_caller') : $r('app.string.call_cancel_callee'));
      } else if (this._protocolType === CallProtocolType.hangup) {
        const callEnd = this._jsonData?.['call_end'] as number;
        const time = this.getShowTime(callEnd ?? 0);
        this._content = `${this.getStr(ctx, $r('app.string.call_stop_tip'))}${time}`;
      } else if (this._protocolType === CallProtocolType.timeout) {
        this._content = this.getStr(ctx, isCaller ? $r('app.string.call_timeout_caller') : $r('app.string.call_timeout_callee'));
      } else if (this._protocolType === CallProtocolType.lineBusy) {
        this._content = this.getStr(ctx, isCaller ? $r('app.string.call_line_busy_caller') : $r('app.string.call_line_busy_callee'));
      } else if (this._protocolType === CallProtocolType.send) {
        this._content = this.getStr(ctx, $r('app.string.call_start'));
      } else if (this._protocolType === CallProtocolType.accept) {
        this._content = this.getStr(ctx, $r('app.string.call_accept_call'));
      } else if (this._protocolType === CallProtocolType.switchToAudio) {
        this._content = this.getStr(ctx, $r('app.string.call_switch_to_audio'));
      } else if (this._protocolType === CallProtocolType.switchToAudioConfirm) {
        this._content = this.getStr(ctx, $r('app.string.call_switch_to_audio_accept'));
      } else {
        this._content = this.getStr(ctx, $r('app.string.call_unknown'));
      }
    } else if (this._participantType === CallParticipantType.group) {
      if (this._protocolType === CallProtocolType.send) {
        this._content = `"${showName}" ${this.getStr(ctx, $r('app.string.call_group_send'))}`;
      } else if (this._protocolType === CallProtocolType.cancel) {
        this._content = this.getStr(ctx, $r('app.string.call_group_end'));
      } else if (this._protocolType === CallProtocolType.hangup) {
        this._content = this.getStr(ctx, $r('app.string.call_group_end'));
      } else if (this._protocolType === CallProtocolType.timeout || this._protocolType === CallProtocolType.lineBusy) {
        let inviteeNames = '';
        for (const invitee of this._inviteeList) {
          inviteeNames = `${inviteeNames}${invitee}、`;
        }
        if (inviteeNames.length > 0) {
          inviteeNames = inviteeNames.substring(0, inviteeNames.length - 1);
        }
        this._content = inviteeNames + this.getStr(ctx, $r('app.string.call_group_no_answer'));
      } else if (this._protocolType === CallProtocolType.reject) {
        this._content = `"${showName}" ${this.getStr(ctx, $r('app.string.call_group_reject'))}`;
      } else if (this._protocolType === CallProtocolType.accept) {
        this._content = `"${showName}" ${this.getStr(ctx, $r('app.string.call_group_accept'))}`;
      } else if (this._protocolType === CallProtocolType.switchToAudio) {
        this._content = `"${showName}" ${this.getStr(ctx, $r('app.string.call_switch_to_audio'))}`;
      } else if (this._protocolType === CallProtocolType.switchToAudioConfirm) {
        this._content = `"${showName}" ${this.getStr(ctx, $r('app.string.call_group_confirm_switch_to_audio'))}`;
      } else {
        this._content = this.getStr(ctx, $r('app.string.call_unknown'));
      }
    } else {
      this._content = this.getStr(ctx, $r('app.string.call_unknown'));
    }
  }

  private getStr(ctx: Context, res: Resource): string {
    try {
      return ctx.resourceManager.getStringSync(res.id);
    } catch (e) {
      return '';
    }
  }

  private twoDigits(n: number): string {
    return n >= 10 ? `${n}` : `0${n}`;
  }

  private getShowTime(seconds: number): string {
    const secondsShow = seconds % 60;
    const minutesShow = Math.floor(seconds / 60);
    return `${this.twoDigits(minutesShow)}:${this.twoDigits(secondsShow)}`;
  }

  private getShowName(): string {
    const rawMessage = this.messageInfo.rawMessage;
    if (!rawMessage) {
      return '';
    }

    if (rawMessage.nameCard && rawMessage.nameCard.length > 0) {
      return rawMessage.nameCard;
    } else if (rawMessage.friendRemark && rawMessage.friendRemark.length > 0) {
      return rawMessage.friendRemark;
    } else if (rawMessage.nickName && rawMessage.nickName.length > 0) {
      return rawMessage.nickName;
    } else {
      return this.messageInfo.from?.userID ?? '';
    }
  }
}
