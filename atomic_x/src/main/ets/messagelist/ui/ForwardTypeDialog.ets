import { ActionSheet, ActionItem } from '../../basecomponent/Index';
import { MessageForwardType } from '@tencentcloud/atomicxcore';

/**
 * Forward type selection dialog
 * Uses ActionSheet style consistent with ConversationMoreDialog
 */
@CustomDialog
export struct ForwardTypeDialog {
  controller: CustomDialogController;
  @State actionItems: ActionItem[] = [];
  
  // Whether to show separate forward option (disabled when > 30 messages)
  showSeparateOption: boolean = true;
  // Tip text when exceeds limit
  limitTip?: string | Resource;
  
  onForwardTypeSelected?: (type: MessageForwardType) => void;
  onCancel?: () => void;

  aboutToAppear() {
    const items: ActionItem[] = [];
    
    if (this.showSeparateOption) {
      items.push({
        text: $r('app.string.forward_separately'),
        value: 'separate'
      });
    }
    
    items.push({
      text: $r('app.string.forward_merged'),
      value: 'merged'
    });
    
    this.actionItems = items;
  }

  build() {
    ActionSheet({
      controller: this.controller,
      title: this.showSeparateOption ? '' : this.limitTip,
      options: this.actionItems,
      showCancel: true,
      cancelText: $r('app.string.cancel'),
      onActionSelected: (item: ActionItem) => {
        if (this.onForwardTypeSelected) {
          if (item.value === 'separate') {
            this.onForwardTypeSelected(MessageForwardType.separate);
          } else {
            this.onForwardTypeSelected(MessageForwardType.merged);
          }
        }
      },
      onDismiss: () => {
        if (this.onCancel) {
          this.onCancel();
        }
      }
    })
  }
}
