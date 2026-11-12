import { ChatMessageInputConfig, MessageInputConfigProtocol } from '../messageinput/config/MessageInputConfig';

export function createChatbotMessageInputConfig(base: MessageInputConfigProtocol): MessageInputConfigProtocol {
  return new ChatMessageInputConfig({
    inputStyle: base.inputStyle,
    isShowAudioRecorder: base.isShowAudioRecorder,
    enableSendRecordedVoice: base.enableSendRecordedVoice,
    isShowPhotoTaker: false,
    isShowAudioCall: false,
    isShowVideoCall: false,
    isShowMore: false,
    isShowEmojiButton: base.isShowEmojiButton,
    isShowPlusButton: base.isShowPlusButton,
    isShowSendButton: base.isShowSendButton,
    enableMention: false,
    enableReadReceipt: false,
    enableTyping: false
  });
}
