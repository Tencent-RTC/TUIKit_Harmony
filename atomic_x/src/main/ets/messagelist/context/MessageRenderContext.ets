import { MessageInfo, MessageListStore } from '@tencentcloud/atomicxcore';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';

/**
 * MessageRenderContext - 消息渲染上下文
 * 
 * 封装消息渲染所需的所有参数，避免函数参数膨胀。
 */
export interface MessageRenderContext {
  /** 消息数据 */
  message: MessageInfo;
  
  /** 消息列表 Store */
  messageListStore: MessageListStore;
  
  /** 消息列表样式配置 */
  config?: MessageListStyleProtocol;
  
  /** 是否在合并消息详情视图中 */
  isInMergedDetailView?: boolean;
  
  /** ASR 显示管理器（语音转文字） */
  asrDisplayManager?: AsrDisplayManager;
  
  /** ASR 气泡长按回调 */
  onAsrBubbleLongPress?: (message: MessageInfo) => void;
  
  /** 请求关闭父级对话框的回调（如 MessageActionDialog） */
  onRequestCloseParentDialog?: () => void;
}

export function createMessageRenderContext(
  message: MessageInfo,
  messageListStore: MessageListStore,
  config?: MessageListStyleProtocol,
  isInMergedDetailView: boolean = false,
  asrDisplayManager?: AsrDisplayManager,
  onAsrBubbleLongPress?: (message: MessageInfo) => void,
  onRequestCloseParentDialog?: () => void
): MessageRenderContext {
  return {
    message,
    messageListStore,
    config,
    isInMergedDetailView,
    asrDisplayManager,
    onAsrBubbleLongPress,
    onRequestCloseParentDialog
  };
}
