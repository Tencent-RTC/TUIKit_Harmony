import { ChatMessageInputConfig, MessageInputConfigProtocol } from '../messageinput/config/MessageInputConfig';

/**
 * Chatbot conversations only support plain text input, so attachment / call /
 * mention entries are disabled. Mirrors the Android ChatbotMessageInputConfig.
 */
export function createChatbotMessageInputConfig(base: MessageInputConfigProtocol): MessageInputConfigProtocol {
  return new ChatMessageInputConfig({
    inputStyle: base.inputStyle,
    isShowAudioRecorder: false,
    isShowPhotoTaker: false,
    isShowAudioCall: false,
    isShowVideoCall: false,
    isShowMore: false,
    isShowSendButton: base.isShowSendButton,
    enableMention: false,
    enableReadReceipt: false,
    enableTyping: false
  });
}
