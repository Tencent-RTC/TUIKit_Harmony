export class AIAssistantAgent {
  readonly id: string;
  readonly name: string;
  readonly welcome: string;
  readonly imUserId: string;
  readonly imNickname: string;

  constructor(id: string, name: string, welcome: string, imUserId: string, imNickname: string) {
    this.id = id;
    this.name = name;
    this.welcome = welcome;
    this.imUserId = imUserId;
    this.imNickname = imNickname;
  }

  get conversationID(): string {
    return `c2c_${this.imUserId}`;
  }

  get displayName(): string {
    if (this.imNickname.trim().length > 0) {
      return this.imNickname;
    }
    if (this.name.trim().length > 0) {
      return this.name;
    }
    return this.imUserId;
  }
}

export type AIAssistantAgentLoader = (onResult: (agents: AIAssistantAgent[]) => void) => void;

export class AIAssistantHandoffStatus {
  static readonly STATE_QUEUED: string = 'queued';
  static readonly STATE_OFFERED: string = 'offered';
  static readonly STATE_ASSIGNED: string = 'assigned';
  static readonly STATE_CLOSED: string = 'closed';
  static readonly INACTIVE: AIAssistantHandoffStatus = new AIAssistantHandoffStatus();

  readonly callable: boolean;
  readonly state: string;
  readonly seatImUserId: string;

  constructor(callable: boolean = false, state: string = '', seatImUserId: string = '') {
    this.callable = callable;
    this.state = state;
    this.seatImUserId = seatImUserId;
  }

  get isSeatCallable(): boolean {
    return this.callable && this.seatImUserId.trim().length > 0;
  }

  get isWaitingForSeat(): boolean {
    return !this.isSeatCallable && (
      this.state === AIAssistantHandoffStatus.STATE_QUEUED ||
        this.state === AIAssistantHandoffStatus.STATE_OFFERED ||
        this.state === AIAssistantHandoffStatus.STATE_ASSIGNED
    );
  }
}

export type AIAssistantHandoffStatusLoader = (onResult: (status: AIAssistantHandoffStatus) => void) => void;
