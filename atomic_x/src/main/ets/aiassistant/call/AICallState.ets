export enum AICallState {
  IDLE,
  LISTENING,
  THINKING,
  SPEAKING
}

export class TranscriptEntry {
  readonly isFromUser: boolean;
  readonly text: string;
  readonly isFailed: boolean;

  constructor(isFromUser: boolean, text: string, isFailed: boolean = false) {
    this.isFromUser = isFromUser;
    this.text = text;
    this.isFailed = isFailed;
  }
}
