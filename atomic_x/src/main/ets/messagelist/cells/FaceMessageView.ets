import { MessageInfo } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil } from '../../basecomponent/Index';
import { MessageBody } from '@tencentcloud/atomicxcore';
import { MessageListStore } from '@tencentcloud/atomicxcore';

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
export function FaceMessageView(messageData: MessageInfo, MessageListStore?: MessageListStore) {
  if (messageData && messageData.messageBody) {
    FaceMessageViewContent({ messageBody: messageData.messageBody })
  }
}