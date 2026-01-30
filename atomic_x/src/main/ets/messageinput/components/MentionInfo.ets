export class MentionInfo {
  static readonly AT_ALL_USER_ID: string = '__kImSDK_MesssageAtALL__';

  userID: string;
  nickName: string;
  startIndex: number;

  constructor(userID: string, nickName: string, startIndex: number) {
    this.userID = userID;
    this.nickName = nickName;
    this.startIndex = startIndex;
  }

  get mentionText(): string {
    return `@${this.nickName} `;
  }

  get length(): number {
    return this.mentionText.length;
  }

  get endIndex(): number {
    return this.startIndex + this.length;
  }

  static create(userID: string, nickName: string, startIndex: number): MentionInfo {
    return new MentionInfo(userID, nickName, startIndex);
  }
}
