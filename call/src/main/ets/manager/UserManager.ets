// v1: friend-info lookup by userID is NOT implemented (atomicxcore exposes
// no equivalent API yet). Display name resolution is local-only.

import { CallParticipantInfo, LoginStore, UserProfile } from '@tencentcloud/atomicxcore';

export class UserManager {
  static getUserDisplayName(p: CallParticipantInfo | undefined | null): string {
    if (!p) {
      return '';
    }
    if (p.remark && p.remark.length > 0) {
      return p.remark;
    }
    if (p.name && p.name.length > 0) {
      return p.name;
    }
    return p.id ?? '';
  }

  static getSelfUserInfo(): UserProfile | undefined {
    return LoginStore.shared().state.loginUserInfo;
  }

  static getSelfUserID(): string {
    const p = UserManager.getSelfUserInfo();
    return p?.userID ?? '';
  }
}
