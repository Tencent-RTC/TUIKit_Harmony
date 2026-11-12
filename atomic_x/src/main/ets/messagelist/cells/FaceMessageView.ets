import { FaceMessagePayload } from '@tencentcloud/atomicxcore';
import { EmojiManager } from '../../emojipicker/EmojiManager';
import { EmojiGroup } from '../../emojipicker/model/EmojiGroup';
import { MessageRenderContext } from '../context/MessageRenderContext';
import { FaceMessageResourceResolver } from './FaceMessageResourceResolver';

const FACE_MESSAGE_SIZE: number = 80;

@Component
export struct FaceMessageViewContent {
  @ObjectLink messagePayload: FaceMessagePayload;
  @StorageLink('EmojiGroupState') emojiGroups: EmojiGroup[] = EmojiManager.getInstance().emojiGroupList;

  private resolveFaceUrl(): ResourceStr {
    const emoji = FaceMessageResourceResolver.resolve(this.messagePayload.faceData, this.messagePayload.faceIndex,
      this.emojiGroups);
    return emoji ? emoji.emojiUrl : $rawfile('basecomponent/common_image_replace_icon.png');
  }

  build() {
    Image(this.resolveFaceUrl())
      .alt($rawfile('basecomponent/common_image_replace_icon.png'))
      .objectFit(ImageFit.Contain)
      .interpolation(ImageInterpolation.Medium)
      .draggable(false)
      .size({ width: FACE_MESSAGE_SIZE, height: FACE_MESSAGE_SIZE })
  }
}

@Builder
export function FaceMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    FaceMessageViewContent({ messagePayload: context.message.messagePayload as FaceMessagePayload })
  }
}
