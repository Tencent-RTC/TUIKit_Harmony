import { MessageInfo, MessageActionStore, MessageType, TextMessagePayload } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { TranslationTextParser } from '../utils/TranslationTextParser';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';

export interface MessageListTranslateHost {
  findLatestMessage(msgID: string): MessageInfo | undefined;

  refreshDataSource(): void;

  getMessageIndex(msgID: string): number;

  forceRefresh(index: number): void;

  scrollToBottomIfLastMessage(message: MessageInfo): void;

  showInfoToast(resource: Resource): void;
}

export class MessageListTranslateCoordinator {
  private host?: MessageListTranslateHost;

  attach(host: MessageListTranslateHost): void {
    this.host = host;
  }

  static getTranslatedText(message: MessageInfo): string {
    const textPayload = message.messagePayload as TextMessagePayload | undefined;
    const translatedTextMapRaw = textPayload?.translatedText;
    const translatedTextMap: Record<string, string> = {};
    if (translatedTextMapRaw) {
      translatedTextMapRaw.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });
    }
    const originalText = textPayload?.text ?? '';
    if (originalText.length === 0) {
      return '';
    }
    const translated = translatedTextMap[originalText];
    if (translated && translated.length > 0) {
      return translated;
    }
    const splitResult = TranslationTextParser.splitTextByEmojiAndAtUsers(originalText, undefined);
    if (!splitResult) {
      return '';
    }
    const hasTranslatedFragment = splitResult.text.some((text: string) => translatedTextMap[text] !== undefined);
    if (!hasTranslatedFragment) {
      return '';
    }
    const replacedText = TranslationTextParser.replacedStringWithArray(
      splitResult.result,
      splitResult.textIndex,
      translatedTextMap
    );
    return replacedText ?? '';
  }

  async translate(message: MessageInfo, displayManager: TranslationDisplayManager): Promise<void> {
    if (!message || message.messageType !== MessageType.TEXT) {
      return;
    }

    displayManager.setTranslating(message.msgID, true);
    displayManager.expand(message.msgID);

    const textPayload = message.messagePayload as TextMessagePayload | undefined;
    const originalText = textPayload?.text ?? '';
    if (originalText.length === 0) {
      displayManager.setTranslating(message.msgID, false);
      return;
    }

    try {
      const atUserNames = await TranslationTextParser.getAtUserNames(message);
      const splitResult = TranslationTextParser.splitTextByEmojiAndAtUsers(originalText, atUserNames ?? undefined);

      if (!splitResult) {
        displayManager.setTranslating(message.msgID, false);
        displayManager.collapse(message.msgID);
        return;
      }

      const textArray = splitResult.text;
      const textIndexArray = splitResult.textIndex;
      const resultArray = splitResult.result;

      if (textArray.length === 0 || textArray.every((text: string) => text.trim().length === 0)) {
        displayManager.setTranslating(message.msgID, false);
        displayManager.collapse(message.msgID);
        return;
      }

      const targetLanguage = AppBuilderConfig.getInstance().getTranslateTargetLanguage();

      await new Promise<void>((resolve, reject) => {
        const messageActionStore = MessageActionStore.create(message);
        const completion = new CompletionHandlerAdapter(() => {
          resolve();
        }, (code: number, desc: string) => {
          reject(new Error(`translateText failed: ${code} ${desc}`));
        });
        messageActionStore.translateText(textArray, undefined, targetLanguage, completion);
      });

      displayManager.setTranslating(message.msgID, false);

      const latestMessage = this.host?.findLatestMessage(message.msgID) ?? message;
      const latestTextPayload = latestMessage.messagePayload as TextMessagePayload | undefined;
      const fallbackTextPayload = message.messagePayload as TextMessagePayload | undefined;
      const translatedTextMap: Record<string, string> = {};
      latestTextPayload?.translatedText?.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });
      fallbackTextPayload?.translatedText?.forEach((value: string, key: string) => {
        translatedTextMap[key] = value;
      });

      const translatedFullText = TranslationTextParser.replacedStringWithArray(
        resultArray,
        textIndexArray,
        translatedTextMap
      );

      if (!translatedFullText || translatedFullText.length === 0) {
        displayManager.collapse(message.msgID);
        this.host?.showInfoToast($r('app.string.messagelist_translate_failed'));
      } else {
        if (latestTextPayload) {
          if (!latestTextPayload.translatedText) {
            latestTextPayload.translatedText = new Map<string, string>();
          }
          latestTextPayload.translatedText.set(originalText, translatedFullText);
        }
        this.host?.refreshDataSource();
        const refreshIndex = this.host?.getMessageIndex(message.msgID) ?? -1;
        if (refreshIndex >= 0) {
          this.host?.forceRefresh(refreshIndex);
        }
        this.host?.scrollToBottomIfLastMessage(latestMessage);
      }
    } catch (error) {
      console.error(`[MessageListTranslateCoordinator] translation failed:`, error);
      displayManager.setTranslating(message.msgID, false);
      displayManager.collapse(message.msgID);
      this.host?.showInfoToast($r('app.string.messagelist_translate_failed'));
    }
  }
}
