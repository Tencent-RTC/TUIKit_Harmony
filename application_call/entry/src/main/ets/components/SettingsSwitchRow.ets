// SettingsSwitchRow.ets — list row with a label on the left and a Toggle on the right.
// Mirrors iOS SettingsCustomSwitchView.

import { Toast, resolveResource } from '../common/Toast';

@Component
export struct SettingsSwitchRow {
  @Prop label: ResourceStr = '';
  @Prop isOn: boolean = false;
  @Prop disabled: boolean = false;
  @Prop disabledHint: ResourceStr = '';
  onChange: (value: boolean) => void = () => {};

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .selectedColor('#006EFF')
          .enabled(!this.disabled)
          .onChange((value: boolean) => {
            this.onChange(value);
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
