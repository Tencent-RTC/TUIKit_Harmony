import { ConversationListState, ConversationListStore } from '@tencentcloud/atomicxcore'
import { HomeTabBar, homeSurface } from './HomeTabBar'

@Component
export struct HomeView {
  @Link fullscreen: boolean
  @Prop interactionEnabled: boolean = true
  @Prop profileStyle: number = 0
  onTab: (index: number) => void = () => {}
  @State private selected: number = 1
  @State private visited: boolean[] = [false, true, false, false, false]
  private conversationStore: ConversationListStore = ConversationListStore.create()
  @State private conversations: ConversationListState = this.conversationStore.state
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0
  @BuilderParam roomContent: (active: boolean) => void = this.emptyContent
  @BuilderParam liveContent: (active: boolean) => void = this.emptyContent
  @BuilderParam messageContent: () => void = this.emptyContent
  @BuilderParam mineContent: () => void = this.emptyContent

  aboutToAppear(): void { this.conversationStore.loadConversations() }
  @Builder emptyContent() {}

  @Builder placeholder(title: Resource) {
    Column({ space: 16 }) {
      Text(title).fontSize(20).fontColor($r('app.color.app_text'))
      Text($r('app.string.app_placeholder')).fontSize(16).fontColor($r('app.color.app_secondary'))
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.visited[0]) {
        Column() { this.roomContent(this.selected === 0) }.width('100%').height('100%')
          .padding({ bottom: this.fullscreen ? 0 : 56 + this.safeBottom })
          .visibility(this.selected === 0 ? Visibility.Visible : Visibility.Hidden)
      }
      Column() { this.liveContent(this.selected === 1) }
        .width('100%').height('100%').visibility(this.selected === 1 ? Visibility.Visible : Visibility.Hidden)
      if (this.visited[2]) {
        Column() { this.placeholder($r('app.string.app_call')) }
          .width('100%').height('100%').visibility(this.selected === 2 ? Visibility.Visible : Visibility.Hidden)
      }
      if (this.visited[3]) {
        Column() { this.messageContent() }.width('100%').height('100%')
          .padding({ top: this.safeTop, bottom: this.fullscreen ? 0 : 56 + this.safeBottom })
          .visibility(this.selected === 3 ? Visibility.Visible : Visibility.Hidden)
      }
      if (this.visited[4]) {
        Column() { this.mineContent() }.width('100%').height('100%')
          .padding({ bottom: 56 + this.safeBottom })
          .visibility(this.selected === 4 ? Visibility.Visible : Visibility.Hidden)
      }
      if (!this.fullscreen) {
        Column() {
          HomeTabBar({ selected: this.selected, profileStyle: this.profileStyle, unreadCount: this.conversations.totalUnreadCount,
            onSelect: (index: number) => {
              if (!this.interactionEnabled) { return }
              this.selected = index
              this.onTab(index)
              this.visited = this.visited.map((value: boolean, i: number) => value || i === index)
            } })
        }.padding({ bottom: this.safeBottom })
          .backgroundColor(homeSurface(this.selected, this.profileStyle))
      }
    }.width('100%').height('100%')
      .backgroundColor(homeSurface(this.selected, this.profileStyle))
  }
}
