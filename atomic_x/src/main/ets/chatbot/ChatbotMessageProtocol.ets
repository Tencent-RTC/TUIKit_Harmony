import { MessageInfo, MessageType, CustomMessagePayload } from '@tencentcloud/atomicxcore';
import { V2TIMElemType, V2TIMMessage } from '@tencentcloud/imsdk';
import { util } from '@kit.ArkTS';

export enum ChatbotMessageSource {
  FLOW,
  INTERRUPT,
  ERROR,
  UNKNOWN
}

export const CHATBOT_PLUGIN_VALUE: number = 2;
export const CHATBOT_SOURCE_FLOW: number = 2;
export const CHATBOT_SOURCE_INTERRUPT: number = 22;
export const CHATBOT_SOURCE_ERROR: number = 23;
export const CHATBOT_FINISHED: number = 1;

export class ChatbotMessageData {
  source: ChatbotMessageSource;
  chunks: string[];
  isFinished: boolean;
  msgKey: string;
  errorInfo: string;
  isPlaceholder: boolean;

  constructor(source: ChatbotMessageSource, chunks: string[], isFinished: boolean, msgKey: string,
    errorInfo: string, isPlaceholder: boolean) {
    this.source = source;
    this.chunks = chunks;
    this.isFinished = isFinished;
    this.msgKey = msgKey;
    this.errorInfo = errorInfo;
    this.isPlaceholder = isPlaceholder;
  }

  get displayText(): string {
    if (this.source === ChatbotMessageSource.FLOW) {
      return this.chunks.join('');
    }
    if (this.source === ChatbotMessageSource.ERROR) {
      return this.errorInfo;
    }
    return '';
  }

  get isVisualResponse(): boolean {
    return this.source === ChatbotMessageSource.FLOW || this.source === ChatbotMessageSource.ERROR;
  }
}

type JsonRecord = Record<string, string | number | boolean | object | null>;

function readNumber(json: JsonRecord, key: string): number | undefined {
  const value = json[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? undefined : parsed;
  }
  return undefined;
}

function readString(json: JsonRecord, key: string): string {
  const value = json[key];
  return typeof value === 'string' ? value : '';
}

function readBoolean(json: JsonRecord, key: string): boolean | undefined {
  const value = json[key];
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value !== 0;
  }
  return undefined;
}

function readStringArray(json: JsonRecord, key: string): string[] {
  const value = json[key];
  if (!Array.isArray(value)) {
    return [];
  }
  const result: string[] = [];
  for (const item of value as Object[]) {
    if (typeof item === 'string') {
      result.push(item);
    }
  }
  return result;
}

function decodeCustomDataFromRawMessage(rawMessage?: V2TIMMessage): string {
  if (!rawMessage) {
    return '';
  }
  if (rawMessage.elemType !== V2TIMElemType.V2TIM_ELEM_TYPE_CUSTOM) {
    return '';
  }
  const data = rawMessage.customElem?.data;
  if (!data || data.byteLength === 0) {
    return '';
  }
  try {
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(new Uint8Array(data));
  } catch (e) {
    return '';
  }
}

function toSource(value?: number): ChatbotMessageSource {
  if (value === CHATBOT_SOURCE_FLOW) {
    return ChatbotMessageSource.FLOW;
  }
  if (value === CHATBOT_SOURCE_INTERRUPT) {
    return ChatbotMessageSource.INTERRUPT;
  }
  if (value === CHATBOT_SOURCE_ERROR) {
    return ChatbotMessageSource.ERROR;
  }
  return ChatbotMessageSource.UNKNOWN;
}

export class ChatbotMessageProtocol {
  static parseCustomData(customData?: string): ChatbotMessageData | undefined {
    if (!customData || customData.trim().length === 0) {
      return undefined;
    }
    let json: JsonRecord | undefined;
    try {
      const parsed: Object = JSON.parse(customData) as Object;
      if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
        return undefined;
      }
      json = parsed as JsonRecord;
    } catch (e) {
      return undefined;
    }
    if (readNumber(json, 'chatbotPlugin') !== CHATBOT_PLUGIN_VALUE) {
      return undefined;
    }
    const finishedValue = readNumber(json, 'isFinished');
    return new ChatbotMessageData(
      toSource(readNumber(json, 'src')),
      readStringArray(json, 'chunks'),
      finishedValue === undefined ? true : finishedValue === CHATBOT_FINISHED,
      readString(json, 'msgKey'),
      readString(json, 'errorInfo'),
      readBoolean(json, 'localPlaceholder') ?? false
    );
  }

  static parse(message?: MessageInfo): ChatbotMessageData | undefined {
    if (!message || message.messageType !== MessageType.CUSTOM) {
      return undefined;
    }
    const payload = message.messagePayload as CustomMessagePayload | undefined;
    let customData = payload?.customData ?? '';
    if (customData.length === 0) {
      customData = decodeCustomDataFromRawMessage(message.rawMessage);
    }
    return ChatbotMessageProtocol.parseCustomData(customData);
  }

  static createInterruptPayload(msgKey: string): string {
    const payload: Record<string, string | number> = {
      'chatbotPlugin': CHATBOT_PLUGIN_VALUE,
      'src': CHATBOT_SOURCE_INTERRUPT,
      'msgKey': msgKey
    };
    return JSON.stringify(payload);
  }

  static createPlaceholderCustomData(): string {
    const payload: Record<string, string | number | boolean | string[]> = {
      'chatbotPlugin': CHATBOT_PLUGIN_VALUE,
      'src': CHATBOT_SOURCE_FLOW,
      'chunks': [],
      'isFinished': 0,
      'localPlaceholder': true
    };
    return JSON.stringify(payload);
  }
}
