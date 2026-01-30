import { MessageInfo } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil } from '../../basecomponent/Index';
import { MessageBody } from '@tencentcloud/atomicxcore';
import { MessageListStore } from '@tencentcloud/atomicxcore';
import { MessageRenderContext } from '../context/MessageRenderContext';

let DEFAULT_IMAGE_MAX_SIZE = 180;

@Component
export struct FaceMessageViewContent {
  @State mesage?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;

  getImageSize(): SizeOptions {
    // Faces are typically square, so we'll return a fixed size
    return { width: 24, height: 24 };
  }

  build() {
    Column() {
      Image(this.messageBody?.faceName)
        .borderRadius(5)
        .interpolation(ImageInterpolation.Medium)
        .objectFit(ImageFit.Cover)
        .size(this.getImageSize())
    }
  }
}

@Builder
export function FaceMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    FaceMessageViewContent({ messageBody: context.message.messageBody })
  }
}