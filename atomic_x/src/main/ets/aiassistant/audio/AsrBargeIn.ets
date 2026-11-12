export class AsrBargeIn {
  private static readonly PUNCTUATION: string = '，。、；：？！,“”‘’"\'（）()[]【】…—-,:;?!.';

  static significantCharCount(text: string): number {
    let count = 0;
    for (const ch of text) {
      if (AsrBargeIn.isLetterOrDigit(ch)) {
        count++;
      }
    }
    return count;
  }

  static normalize(text: string): string {
    let result = '';
    for (const ch of text) {
      if (ch.trim().length === 0 || AsrBargeIn.PUNCTUATION.includes(ch)) {
        continue;
      }
      result += ch;
    }
    return result;
  }

  private static isLetterOrDigit(ch: string): boolean {
    if (ch >= '0' && ch <= '9') {
      return true;
    }
    if (ch.toLowerCase() !== ch.toUpperCase()) {
      return true;
    }
    const code = ch.codePointAt(0) ?? 0;
    return (code >= 0x4e00 && code <= 0x9fff) ||
      (code >= 0x3400 && code <= 0x4dbf) ||
      (code >= 0x3040 && code <= 0x30ff) ||
      (code >= 0xac00 && code <= 0xd7af) ||
      (code >= 0x0600 && code <= 0x06ff);
  }

  static looksLikeCommitted(asrText: string, committed: string): boolean {
    const asr = AsrBargeIn.normalize(asrText);
    const sent = AsrBargeIn.normalize(committed);
    if (asr.length === 0 || sent.length === 0) {
      return false;
    }
    return asr === sent || sent.startsWith(asr);
  }

  static extraBeyondCommitted(asrText: string, committed: string): string | undefined {
    const asr = AsrBargeIn.normalize(asrText);
    const sent = AsrBargeIn.normalize(committed);
    if (sent.length === 0 || !asr.startsWith(sent) || asr.length <= sent.length) {
      return undefined;
    }
    return asr.substring(sent.length);
  }

  static looksLikeTtsEcho(asrText: string, llmText: string): boolean {
    const asr = AsrBargeIn.normalize(asrText);
    const llm = AsrBargeIn.normalize(llmText);
    if (asr.length < 2 || llm.length === 0) {
      return false;
    }
    return llm.includes(asr);
  }

  static shouldBargeIn(asrText: string, committed: string, llmText: string, minChars: number): boolean {
    const extra = AsrBargeIn.extraBeyondCommitted(asrText, committed);
    const candidate = extra ?? asrText;
    if (extra === undefined && AsrBargeIn.looksLikeCommitted(asrText, committed)) {
      return false;
    }
    if (AsrBargeIn.significantCharCount(candidate) < minChars) {
      return false;
    }
    if (AsrBargeIn.looksLikeTtsEcho(candidate, llmText)) {
      return false;
    }
    return true;
  }
}
