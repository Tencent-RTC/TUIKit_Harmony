import { RoomColors } from '../../../base/resources/RoomColors';

@Component
export struct PageIndicatorView {
  currentIndex: number = 0;
  pageCount: number = 0;
  color: string = RoomColors.g3;
  activeColor: string = RoomColors.white;
  indicatorSize: number = 6;
  spacing: number = 4;

  build() {
    Row() {
      ForEach(Array.from<number, number>({ length: this.pageCount }, (_v: number, i: number): number => i), (index: number) => {
        Column()
          .width(this.indicatorSize)
          .height(this.indicatorSize)
          .borderRadius(this.indicatorSize / 2)
          .backgroundColor(index === this.currentIndex ? this.activeColor : this.color)
          .margin({ left: this.spacing, right: this.spacing })
      }, (index: number) => index.toString())
    }
    .justifyContent(FlexAlign.Center)
  }
}
