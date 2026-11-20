@Component
export struct AvatarCollectionCell {
  @Prop url: string = ''
  @Prop selected: boolean = false
  onSelect: () => void = () => {}

  build() {
    Image(this.url).width('100%').height(77).objectFit(ImageFit.Cover).borderRadius(8)
      .border({ width: 2, color: this.selected ? $r('app.color.app_primary') : Color.Transparent })
      .onClick(() => this.onSelect())
  }
}
