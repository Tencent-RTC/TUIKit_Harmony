import { RoomResources } from '../../../../base/util/RoomResources'

@Component
export struct RoomChatEmojiView {
  onSelect?: (emoji: string) => void

  static readonly supportedEmojis: string[] = [
    '😀', '😂', '🤣', '😊', '😍', '🥰', '😘', '😜', '🤔', '😎', '🥳', '😢', '😱', '🤗', '🙌', '💪',
    '👍', '👏', '❤️', '🔥', '⭐', '🎉', '🎊', '💯', '😇', '🤩', '😋', '🤭', '😏', '🥺', '😤', '🫡',
    '👋', '✌️', '🤝', '💐', '🌹', '🏆', '🎵', '💡',
  ]

  build() {
    Grid() {
      ForEach(RoomChatEmojiView.supportedEmojis, (emoji: string) => {
        GridItem() {
          Text(emoji)
            .width('100%')
            .height(34)
            .fontSize(22)
            .textAlign(TextAlign.Center)
        }
        .onClick(() => this.onSelect?.(emoji))
      }, (emoji: string) => emoji)
    }
    .width('100%')
    .height(180)
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(0)
    .columnsGap(0)
    .padding(4)
    .scrollBar(BarState.Off)
  }
}
