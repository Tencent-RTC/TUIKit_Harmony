// SegmentRow.ets — list row with a label on the left and a segmented control on the right.
// Mirrors iOS UISegmentedControl used in SettingsViewController for ResolutionMode /
// FillMode / Rotation / OtherSetting (screen orientation).
//
// Visual: rounded rect container, equal-width buttons separated by hairline dividers,
// selected segment filled white-on-blue, unselected gray-on-clear, similar to UIKit.

import { Toast, resolveResource } from '../common/Toast';

@Component
export struct SegmentRow {
  @Prop label: ResourceStr = '';
  @Prop options: string[] = [];
  @Prop selectedIndex: number = 0;
  @Prop disabled: boolean = false;
  @Prop disabledHint: ResourceStr = '';
  onSelect: (index: number) => void = () => {};

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(16)
          .fontColor('#000000')
          .flexShrink(0);

        Blank();

        // Segmented control container.
        Row() {
          ForEach(this.options, (opt: string, idx: number) => {
            Stack() {
              Text(opt)
                .fontSize(13)
                .fontColor(idx === this.selectedIndex ? Color.White : '#333333')
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .layoutWeight(1)
            .height('100%')
            .backgroundColor(idx === this.selectedIndex ? '#006EFF' : Color.Transparent)
            .onClick(() => {
              if (this.disabled) {
                Toast.show(resolveResource(getContext(this), this.disabledHint));
                return;
              }
              if (idx !== this.selectedIndex) {
                this.onSelect(idx);
              }
            });

            if (idx < this.options.length - 1) {
              Divider()
                .vertical(true)
                .strokeWidth(1)
                .color('#CCCCCC')
                .height('60%');
            }
          });
        }
        .height(30)
        .layoutWeight(1)
        .margin({ left: 20 })
        .borderRadius(6)
        .borderWidth(1)
        .borderColor('#CCCCCC')
        .clip(true)
        .backgroundColor(Color.White);
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .opacity(this.disabled ? 0.4 : 1.0);

      Divider()
        .color('#EEEEEE')
        .strokeWidth(1)
        .width('100%');
    }
    .width('100%');
  }
}
