import { MessageInfo, FaceMessagePayload } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil } from '../../basecomponent/Index';
import { MessageRenderContext } from '../context/MessageRenderContext';

let DEFAULT_IMAGE_MAX_SIZE = 180;

@Component
export struct FaceMessageViewContent {
  @State mesage?: MessageInfo = undefined;
  @ObjectLink messagePayload: FaceMessagePayload;

  getImageSize(): SizeOptions {
    return { width: 24, height: 24 };
  }

  build() {
    Column() {
      Image(this.messagePayload?.faceData)
        .borderRadius(5)
        .interpolation(ImageInterpolation.Medium)
        .objectFit(ImageFit.Cover)
        .size(this.getImageSize())
    }
  }
}

@Builder
export function FaceMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    FaceMessageViewContent({ messagePayload: context.message.messagePayload as FaceMessagePayload })
  }
}