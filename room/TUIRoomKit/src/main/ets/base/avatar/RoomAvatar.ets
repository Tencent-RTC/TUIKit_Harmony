@Component
export struct RoomAvatar {
  @Prop text: string = ''
  @Prop avatarSize: number = 32
  @Prop @Watch('onImageSourceChanged') image: Resource | undefined = undefined
  @Prop @Watch('onImageSourceChanged') url: string = ''
  @State private imageLoadFailed: boolean = false
  @State private displayedImage: Resource | string | undefined = undefined

  aboutToAppear(): void {
    this.updateImageSource()
  }

  private onImageSourceChanged(): void {
    this.updateImageSource()
  }

  private updateImageSource(): void {
    const source: Resource | string | undefined = this.image !== undefined ? this.image :
      (this.url.trim().length > 0 ? this.url : undefined)
    if (this.displayedImage === source) {
      return
    }
    this.displayedImage = source
    this.imageLoadFailed = false
  }

  private hasImage(): boolean {
    return this.displayedImage !== undefined && !this.imageLoadFailed
  }

  private initial(): string {
    const source = this.text.trim()
    if (source.length === 0) {
      return ''
    }
    const first = Array.from(source)[0]
    return first.toUpperCase()
  }

  build() {
    Stack() {
      if (this.hasImage()) {
        Image(this.displayedImage ?? '')
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .onComplete(() => this.imageLoadFailed = false)
          .onError(() => this.imageLoadFailed = true)
      } else {
        Text(this.initial())
          .fontSize(Math.max(this.avatarSize * 0.375, 10))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.roomkit_fg_on_accent'))
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
    .backgroundColor($r('app.color.roomkit_accent'))
    .borderRadius(this.avatarSize / 2)
    .clip(true)
  }
}
