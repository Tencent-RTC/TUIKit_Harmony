// DropMenuRow.ets — list row with label + ArkUI Select on the right.
// Aligned with iOS SwiftDropMenuListView.
//
// iOS appends " > " to each option's title in the popover; we mirror that by
// rendering options/value with a trailing " >" suffix to keep visual parity.

import { Toast, resolveResource } from '../common/Toast';

@Component
export struct DropMenuRow {
  @Prop label: ResourceStr = '';
  @Prop options: string[] = [];
  @Prop selectedIndex: number = 0;
  @Prop disabled: boolean = false;
  @Prop disabledHint: ResourceStr = '';
  onSelect: (index: number, value: string) => void = () => {};

  private suffix(value: string): string {
    return `${value} >`;
  }

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        Select(this.options.map((o) => {
          return { value: this.suffix(o) } as SelectOption;
        }))
          .selected(this.selectedIndex)
          .value(this.options.length > 0 ? this.suffix(this.options[this.selectedIndex]) : '')
          .font({ size: 16 })
          .fontColor('#333333')
          .selectedOptionFont({ size: 16 })
          .optionFont({ size: 16 })
          .enabled(!this.disabled)
          .onSelect((index: number, value: string) => {
            // strip the trailing " >" suffix when reporting the value back
            const raw = value.endsWith(' >') ? value.substring(0, value.length - 2) : value;
            this.onSelect(index, raw);
          });
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .opacity(this.disabled ? 0.4 : 1.0)
      .onClick(() => {
        if (this.disabled) {
          Toast.show(resolveResource(getContext(this), this.disabledHint));
        }
      });

      Divider()
        .color('#EEEEEE')
        .strokeWidth(1)
        .width('100%');
    }
    .width('100%');
  }
}
