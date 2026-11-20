import { BasicData, BasicDataSource } from '@tencentcloud/atomicxcore'
import { AppPageHeader } from '../../common/AppPageHeader'
import { AvatarCollectionCell } from './AvatarCollectionCell'

class AvatarCard extends BasicData {
  readonly url: string
  constructor(index: number) {
    super()
    this.url = `https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_${index}.png`
    this.ID = this.url
  }
}

@Component
export struct AvatarSelectorView {
  @Prop currentURL: string = ''
  @Prop saving: boolean = false
  onBack: () => void = () => {}
  onSave: (url: string) => void = () => {}
  @State private selected: string = ''
  private source: BasicDataSource<AvatarCard> = new BasicDataSource<AvatarCard>()

  aboutToAppear(): void {
    this.selected = this.currentURL
    this.source.setData(Array.from<number>({ length: 20 }).map((value: number, index: number) => new AvatarCard(index + 1)))
  }

  build() {
    Column() {
      AppPageHeader({ title: $r('app.string.app_avatar'), showSave: true,
        canSave: this.selected.length > 0 && this.selected !== this.currentURL, saving: this.saving,
        onBack: this.onBack, onSave: () => this.onSave(this.selected) })
      Grid() {
        LazyForEach(this.source, (card: AvatarCard) => {
          GridItem() {
            AvatarCollectionCell({ url: card.url, selected: card.url === this.selected,
              onSelect: () => { if (!this.saving) { this.selected = card.url } } })
          }.height(77)
        }, (card: AvatarCard) => card.url)
      }.columnsTemplate('1fr 1fr 1fr 1fr').columnsGap(13).rowsGap(13)
        .padding({ top: 24, left: 15, right: 15, bottom: 24 }).width('100%').layoutWeight(1)
    }.width('100%').height('100%').backgroundColor('#F2F2F7')
  }
}
