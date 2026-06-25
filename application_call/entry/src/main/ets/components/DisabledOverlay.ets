// DisabledOverlay.ets — wraps arbitrary content with grey-out + click-to-toast.
// Used by SettingsPage for the four call_v2-unsupported entries (AI transcriber,
// resolution / resolution mode / fill mode / rotation / beauty level).

import { Toast, resolveResource } from '../common/Toast';

@Component
export struct DisabledOverlay {
  @Prop disabled: boolean = true;
  @Prop hint: ResourceStr = '';
  @BuilderParam content: () => void = this.emptyContent;

  @Builder emptyContent() {}

  build() {
    Stack() {
      this.content();

      if (this.disabled) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(255, 255, 255, 0.6)')
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            Toast.show(resolveResource(getContext(this), this.hint));
          });
      }
    }
    .width('100%');
  }
}
