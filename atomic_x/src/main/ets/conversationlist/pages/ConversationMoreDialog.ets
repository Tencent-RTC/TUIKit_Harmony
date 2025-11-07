import { ActionSheet, ActionItem, AppBuilderConfig, ConversationAction } from '../../basecomponent/Index';
import { ConversationInfo } from '@tencentcloud/atomicxcore';
import { ConversationCustomAction } from './ConversationList';
import { ConversationActionConfigProtocol } from '../config/ConversationListConfig';

export enum ConversationDialogAction {
  HIDE = 'hideConversation',
  PIN = 'pinConversation',
  CLEAR = 'clearConversation',
  DELETE = 'deleteConversation',
  MUTE = 'muteConversation'
}

@CustomDialog
export struct ConversationMoreDialog {
  @ObjectLink conversation: ConversationInfo;
  controller?: CustomDialogController;
  @State actionItems: ActionItem[] = [];
  customActions?: ConversationCustomAction[] = []; // Custom actions from ConversationList
  config?: ConversationActionConfigProtocol = undefined; // Style configuration
  onAction?: (action: ConversationDialogAction, conversationId: string) => void;

  aboutToAppear() {
    // Generate action items based on style configuration (priority over AppBuilderConfig)
    const configuredActions: ActionItem[] = [];

    // Check each action using style (with fallback to AppBuilderConfig)
    if (this.shouldShowAction(ConversationAction.DELETE)) {
      const actionItem = this.getActionItem(ConversationAction.DELETE);
      if (actionItem) {
        configuredActions.push(actionItem);
      }
    }

    if (this.shouldShowAction(ConversationAction.PIN)) {
      const actionItem = this.getActionItem(ConversationAction.PIN);
      if (actionItem) {
        configuredActions.push(actionItem);
      }
    }

    if (this.shouldShowAction(ConversationAction.MUTE)) {
      const actionItem = this.getActionItem(ConversationAction.MUTE);
      if (actionItem) {
        configuredActions.push(actionItem);
      }
    }

    // Add clear history action if supported
    if (this.shouldShowAction(ConversationAction.CLEAR_HISTORY)) {
      const actionItem = this.getActionItem(ConversationAction.CLEAR_HISTORY);
      if (actionItem) {
        configuredActions.push(actionItem);
      }
    }

    // Add custom actions from ConversationList
    if (this.customActions && this.customActions.length > 0) {
      this.customActions.forEach((customAction, index) => {
        configuredActions.push({
          text: customAction.title,
          value: `custom_${index}` // Use index as unique identifier
        });
      });
    }

    this.actionItems = configuredActions;
  }

  build() {
    ActionSheet({
      controller: this.controller!,
      options: this.actionItems,
      showCancel: true,
      cancelText: $r('app.string.cancel'),
      onActionSelected: (item: ActionItem) => {
        this.handleAction(item.value as ConversationDialogAction);
      },
      onDismiss: () => {
        // Handle dialog dismiss
      }
    })
  }

  /**
   * Check if an action should be shown based on style configuration
   * Priority: style > AppBuilderConfig
   */
  private shouldShowAction(action: ConversationAction): boolean {
    if (!this.config) {
      // No style provided, use AppBuilderConfig
      return AppBuilderConfig.getInstance().conversationActionList.includes(action);
    }

    // Use style configuration with priority
    switch (action) {
      case ConversationAction.DELETE:
        return this.config.isSupportDelete ??
               AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.DELETE);
      case ConversationAction.MUTE:
        return this.config.isSupportMute ??
               AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MUTE);
      case ConversationAction.PIN:
        return this.config.isSupportPin ??
               AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.PIN);
      case ConversationAction.MARK_UNREAD:
        return this.config.isSupportMarkUnread ??
               AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MARK_UNREAD);
      case ConversationAction.CLEAR_HISTORY:
        return this.config.isSupportClearHistory ??
               AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.CLEAR_HISTORY);
      default:
        return AppBuilderConfig.getInstance().conversationActionList.includes(action);
    }
  }

  /**
   * Map ConversationAction to ConversationDialogAction and ActionItem
   */
  private getActionItem(action: ConversationAction): ActionItem | null {
    switch (action) {
      case ConversationAction.DELETE:
        return {
          text: $r('app.string.delete_conversation'),
          value: ConversationDialogAction.DELETE,
          isDestructive: true
        };

      case ConversationAction.PIN:
        return {
          text: this.conversation?.isPinned ?
          $r('app.string.unpin_conversation') :
          $r('app.string.pin_conversation'),
          value: ConversationDialogAction.PIN
        };

    // case ConversationAction.HIDE:
    //   return {
    //     text: $r('app.string.hide_conversation'),
    //     value: ConversationDialogAction.HIDE
    //   };

    // case ConversationAction.MUTE:
    //   return {
    //     text: "set mute",
    //     value: ConversationDialogAction.MUTE
    //   };
      case ConversationAction.CLEAR_HISTORY:
        return {
          text: $r('app.string.clear_messages'),
          value: ConversationDialogAction.CLEAR
        }
    // MARK_UNREAD is handled separately in ActionButtonsBuilder, not in more dialog
      case ConversationAction.MARK_UNREAD:
        return null;

      default:
        return null;
    }
  }

  private handleAction(action: ConversationDialogAction | string) {
    console.log('ConversationMoreDialog action:', action);

    // Check if it's a custom action
    if (typeof action === 'string' && action.startsWith('custom_')) {
      this.handleCustomAction(action);
      return;
    }

    if (this.onAction) {
      this.onAction(action as ConversationDialogAction, this.conversation.ID);
    }
  }

  // Handle custom action execution
  private handleCustomAction(action: string) {
    const customActionIndex = parseInt(action.replace('custom_', ''));
    const customAction = this.customActions?.[customActionIndex];
    if (customAction && customAction.action) {
      try {
        customAction.action(this.conversation); // Pass the full ConversationInfo object
        console.log(`[ConversationMoreDialog] Custom action executed at index: ${customActionIndex}`);
      } catch (error) {
        console.error(`[ConversationMoreDialog] Failed to execute custom action at index ${customActionIndex}:`, error);
      }
    } else {
      console.warn(`[ConversationMoreDialog] Custom action not found at index: ${customActionIndex}`);
    }
  }
} 