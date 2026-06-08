// HarmonyOS resource keys disallow ".", so dotted keys like "TUICallKit.answer"
// are normalised to "TUICallKit_answer" before lookup.

import { common } from '@kit.AbilityKit';
import resourceManager from '@ohos.resourceManager';
import { Logger } from './utils/Logger';

let appContext: common.UIAbilityContext | common.Context | null = null;

export function setLocalizedContext(context: common.UIAbilityContext | common.Context): void {
  appContext = context;
}

function normalizeKey(key: string): string {
  return key.replace(/\./g, '_');
}

/** Returns the localized string for `key`. Falls back to raw key on missing context. */
export function TUICallKitLocalize(key: string): string {
  const normalized = normalizeKey(key);
  if (!appContext) {
    return normalized;
  }
  try {
    const rm: resourceManager.ResourceManager = appContext.resourceManager;
    return rm.getStringByNameSync(normalized);
  } catch (e) {
    Logger.warn('TUICallKitLocalize miss key=', normalized, 'err=', e);
    return normalized;
  }
}

export function TUICallKitLocalizeResource(key: string): Resource {
  const normalized = normalizeKey(key);
  return $r('app.string.' + normalized);
}
