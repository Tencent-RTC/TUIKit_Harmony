import { MessageInfo, CustomMessagePayload } from '@tencentcloud/atomicxcore';
import { V2TIMElemType, V2TIMMessage } from '@tencentcloud/imsdk';
import { util } from '@kit.ArkTS';
import { ThemeState } from '../../basecomponent/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';

export interface CustomMessage {
  businessID: string;
  text: string;
  link: string;
}

export const CUSTOM_BUSINESS_ID_TEXT_LINK: string = 'text_link';

export function parseCustomMessage(customData?: string): CustomMessage {
  const result: CustomMessage = { businessID: '', text: '', link: '' };
  if (!customData || customData.length === 0) {
    return result;
  }
  try {
    const info = JSON.parse(customData) as Record<string, string | number | boolean | object>;
    const businessID = info['businessID'];
    const text = info['text'];
    const link = info['link'];
    result.businessID = typeof businessID === 'string' ? businessID : '';
    result.text = typeof text === 'string' ? text : '';
    result.link = typeof link === 'string' ? link : '';
  } catch (e) {
    console.error('[CustomMessageView] parse error:', e);
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
  const customElem = rawMessage.customElem;
  const data = customElem?.data;
  if (!data || data.byteLength === 0) {
    return '';
  }
  try {
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(new Uint8Array(data));
  } catch (e) {
    console.error('[CustomMessageView] decode raw customElem error:', e);
    return '';
  }
}

@Component
export struct CustomMessageViewContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: CustomMessagePayload;
  @State private customMessage: CustomMessage = { businessID: '', text: '', link: '' };

  aboutToAppear() {
    this.parseCustomData();
  }

  aboutToUpdate() {
    this.parseCustomData();
  }

  private parseCustomData(): void {
    let customData = this.messagePayload?.customData ?? '';
    if (customData.length === 0) {
      customData = decodeCustomDataFromRawMessage(this.message?.rawMessage);
    }
    this.customMessage = parseCustomMessage(customData);
  }

  build() {
    if (this.customMessage.businessID === CUSTOM_BUSINESS_ID_TEXT_LINK) {
      this.buildTextLinkMessage();
    } else {
      this.buildUnsupportedCustomMessage();
    }
  }

  @Builder
  private buildTextLinkMessage() {
    Column() {
      if (this.customMessage.text.length > 0) {
        Text(this.customMessage.text)
          .fontSize(15)
          .fontColor(this.message?.isSentBySelf ?
            this.themeState.colors.textColorAntiPrimary :
            this.themeState.colors.textColorPrimary)
          .textOverflow({ overflow: TextOverflow.None })
          .maxLines(999)
          .wordBreak(WordBreak.BREAK_ALL)
      }

      if (this.customMessage.link.length > 0) {
        Text($r('app.string.custom_message_view_details'))
          .fontSize(15)
          .fontColor(this.themeState.colors.textColorLink)
          .decoration({ type: TextDecorationType.Underline })
          .textOverflow({ overflow: TextOverflow.None })
          .maxLines(999)
          .wordBreak(WordBreak.BREAK_ALL)
          .margin({ top: 6 })
          .onClick(() => {
            this.openLink(this.customMessage.link);
          })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 8,
      right: 8,
      top: 8,
      bottom: 6
    })
  }

  @Builder
  private buildUnsupportedCustomMessage() {
    Text($r('app.string.message_tips_unsupport_custom'))
      .fontSize(15)
      .fontColor(this.message?.isSentBySelf ?
        this.themeState.colors.textColorAntiPrimary :
        this.themeState.colors.textColorPrimary)
      .padding({
        left: 8,
        right: 8,
        top: 8,
        bottom: 8
      })
  }

  private openLink(link: string): void {
    if (!link || link.length === 0) {
      return;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const wantInfo: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: link
      };
      context.startAbility(wantInfo).then(() => {
      }).catch((err: BusinessError) => {
        console.error(`[CustomMessageView] openLink failed, code=${err.code}, msg=${err.message}`);
      });
    } catch (e) {
      const err = e as BusinessError;
      console.error(`[CustomMessageView] openLink exception, code=${err.code}, msg=${err.message}`);
    }
  }
}

@Builder
export function CustomMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    CustomMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as CustomMessagePayload
    })
  }
}