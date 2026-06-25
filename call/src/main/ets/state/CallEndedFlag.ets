// Process-wide flag for "the local user just hung up / rejected".
//
// Workaround for the HarmonyOS engine sometimes reporting the *peer* id as
// `onCallEnded(userId:)` even when we ended the call ourselves — which would
// otherwise misclassify a self-end as a remote-end and fire the wrong
// "the other party hung up" toast. View buttons set the flag *before*
// invoking hangup/reject; `TUICallKitImpl.handleCallEnded` consumes it.

class CallEndedFlagImpl {
  private flag: boolean = false;

  markSelfEnded(): void {
    this.flag = true;
  }

  consumeAndClear(): boolean {
    const v = this.flag;
    this.flag = false;
    return v;
  }

  clear(): void {
    this.flag = false;
  }
}

let _instance: CallEndedFlagImpl | null = null;

export function CallEndedFlag(): CallEndedFlagImpl {
  if (_instance === null) {
    _instance = new CallEndedFlagImpl();
  }
  return _instance;
}
