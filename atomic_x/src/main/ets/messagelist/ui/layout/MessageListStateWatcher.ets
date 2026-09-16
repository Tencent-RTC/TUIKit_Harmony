import { MessageListState } from '@tencentcloud/atomicxcore';

@Component
export struct MessageListStateWatcher {
  @ObjectLink @Watch('onStateChanged') messageListState: MessageListState;
  onMessageListChanged?: () => void;

  aboutToAppear(): void {
    this.onMessageListChanged?.();
  }

  onStateChanged(): void {
    this.onMessageListChanged?.();
  }

  build() {
    Stack()
      .width(0)
      .height(0)
      .visibility(Visibility.None)
  }
}
