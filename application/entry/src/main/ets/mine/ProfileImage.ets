@Component
export struct ProfileImage {
  @Prop @Watch('urlChanged') url: string = ''
  @Prop diameter: number = 72
  @State private failed: boolean = false

  private urlChanged(): void { this.failed = false }

  build() {
    Stack() {
      Image($r('app.media.default_avatar')).width('100%').height('100%').objectFit(ImageFit.Cover)
      if (this.url.length > 0 && !this.failed) {
        Image(this.url).width('100%').height('100%').objectFit(ImageFit.Cover).onError(() => this.failed = true)
      }
    }.width(this.diameter).height(this.diameter).borderRadius(this.diameter / 2).clip(true)
  }
}
