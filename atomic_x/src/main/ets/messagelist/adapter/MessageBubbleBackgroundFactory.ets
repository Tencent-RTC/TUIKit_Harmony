import { MessageInfo, MessageType } from '@tencentcloud/atomicxcore';
import { LengthMetrics } from '@kit.ArkUI';
import { SemanticColorScheme } from '../../basecomponent/Index';

const BUBBLE_CORNER_RADIUS: number = 10;
const BUBBLE_POINTED_CORNER_RADIUS: number = 2;
const BUBBLE_BORDER_WIDTH: number = 1;

export class MessageBubbleBackgroundFactory {
  static shouldHideBubbleBackground(message: MessageInfo): boolean {
    return message.messageType === MessageType.IMAGE || message.messageType === MessageType.VIDEO;
  }

  static resolveBackgroundColor(message: MessageInfo, isSelf: boolean,
    colors: SemanticColorScheme): ResourceColor {
    if (MessageBubbleBackgroundFactory.shouldHideBubbleBackground(message)) {
      return Color.Transparent;
    }
    return isSelf ? colors.bgColorBubbleOwn : colors.bgColorBubbleReciprocal;
  }

  static resolveBorderColor(message: MessageInfo, isSelf: boolean, colors: SemanticColorScheme): ResourceColor {
    if (MessageBubbleBackgroundFactory.shouldHideBubbleBackground(message)) {
      return Color.Transparent;
    }
    return MessageBubbleBackgroundFactory.resolveBackgroundColor(message, isSelf, colors);
  }

  static resolveBorderWidth(message: MessageInfo): number {
    return MessageBubbleBackgroundFactory.shouldHideBubbleBackground(message) ? 0 : BUBBLE_BORDER_WIDTH;
  }

  static resolveBorderRadiuses(message: MessageInfo, isRightSide: boolean): LocalizedBorderRadiuses {
    const radius = MessageBubbleBackgroundFactory.shouldHideBubbleBackground(message) ? 0 : BUBBLE_CORNER_RADIUS;
    const roundedRadius = LengthMetrics.vp(radius);
    const pointedRadius = LengthMetrics.vp(BUBBLE_POINTED_CORNER_RADIUS);

    return {
      topStart: isRightSide ? roundedRadius : pointedRadius,
      topEnd: isRightSide ? pointedRadius : roundedRadius,
      bottomStart: roundedRadius,
      bottomEnd: roundedRadius
    } as LocalizedBorderRadiuses;
  }
}
