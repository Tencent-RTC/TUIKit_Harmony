// Toast.ets — thin wrapper over promptAction.showToast.

import { promptAction } from '@kit.ArkUI';

export class Toast {
  static show(message: string, duration: number = 2000): void {
    if (!message || message.length === 0) {
      return;
    }
    try {
      promptAction.showToast({ message, duration });
    } catch (_e) {
      // swallow; toast failures should not break callers
    }
  }
}

/**
 * Resolve a `ResourceStr` (Resource | string) to a plain string using the
 * current component's UI context. Returns '' when the resource is missing or
 * cannot be resolved.
 *
 * Usage in a Component method/closure:
 *   Toast.show(resolveResource(getContext(this), this.disabledHint));
 */
export function resolveResource(context: Context, value: ResourceStr): string {
  if (typeof value === 'string') {
    return value;
  }
  if (!value) {
    return '';
  }
  try {
    return context.resourceManager.getStringSync(value as Resource);
  } catch (_e) {
    return '';
  }
}
