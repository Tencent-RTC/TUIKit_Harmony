import { TranscriptEntry } from '../AICallState';

@Component
export struct TranscriptView {
  private static readonly COLOR_USER: string = '#FF8A9099';
  private static readonly COLOR_ASSISTANT: string = '#FFF2F4F6';
  private static readonly COLOR_FAILED: string = '#FFFF5A5F';
  @Prop @Watch('onEntriesChanged') entries: TranscriptEntry[] = [];
  private scroller: Scroller = new Scroller();

  onEntriesChanged(): void {
    if (this.entries.length > 0) {
      this.scroller.scrollToIndex(this.entries.length - 1);
    }
  }

  build() {
    List({ scroller: this.scroller }) {
      ForEach(this.entries, (entry: TranscriptEntry) => {
        ListItem() {
          Text(entry.text)
            .fontSize(16)
            .lineHeight(24)
            .fontColor(entry.isFailed ? TranscriptView.COLOR_FAILED :
              (entry.isFromUser ? TranscriptView.COLOR_USER : TranscriptView.COLOR_ASSISTANT))
            .width('100%')
            .padding({ top: 6, bottom: 6 })
        }
      }, (entry: TranscriptEntry, index: number) => `${index}_${entry.isFromUser}_${entry.isFailed}_${entry.text}`)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 8, bottom: 8 })
    .edgeEffect(EdgeEffect.None)
    .scrollBar(BarState.Off)
    .onAppear(() => {
      this.onEntriesChanged();
    })
  }
}
