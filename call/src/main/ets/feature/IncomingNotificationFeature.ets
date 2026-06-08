// Background / lock-screen system notification for incoming calls. Fills the
// gap that `IncomingBannerView` only covers when the host app is foreground.
//
// Foreground → no-op (in-app banner / call page already surfaces the call).
// Background → SOCIAL_COMMUNICATION-slot notification with caller name,
// media type, and Answer / Decline action buttons. Tapping a button launches
// the host UIAbility with `parameters.callkitAction = 'accept' | 'reject'`,
// which the host's `EntryAbility.onNewWant` is expected to forward to
// `CallStore.shared().accept() / .reject()` (see README sample).

import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { CallStore, CallInfo, CallParticipantInfo, CallMediaType } from '@tencentcloud/atomicxcore';
import { TUICallKitLocalize } from '../common/Localized';
import { Logger } from '../common/utils/Logger';
import { UserManager } from '../manager/UserManager';
import { AppStateObserver } from './AppStateObserver';

// Constant id keeps cancel() stateless and lets a fresh `publish()` update in
// place rather than stacking.
const NOTIFICATION_ID: number = 0xCA11_001;

export const NOTIFICATION_CALL_ACTION_KEY: string = 'callkitAction';
export const NOTIFICATION_CALL_ACTION_ACCEPT: string = 'accept';
export const NOTIFICATION_CALL_ACTION_REJECT: string = 'reject';

export class IncomingNotificationFeature {
  private static _instance: IncomingNotificationFeature | null = null;

  static shared(): IncomingNotificationFeature {
    if (!IncomingNotificationFeature._instance) {
      IncomingNotificationFeature._instance = new IncomingNotificationFeature();
    }
    return IncomingNotificationFeature._instance;
  }

  private context: common.UIAbilityContext | null = null;
  private hasPublished: boolean = false;

  init(context: common.UIAbilityContext): void {
    if (this.context) {
      return;
    }
    this.context = context;
  }

  /** No-op pre-init or when foreground. Avatar fetch is best-effort. */
  async publish(): Promise<void> {
    if (!this.context) {
      Logger.warn('IncomingNotificationFeature.publish: not initialized');
      return;
    }
    if (!AppStateObserver().isBackground()) {
      Logger.info('IncomingNotificationFeature.publish: foreground, skip');
      return;
    }
    const state = CallStore.shared().state;
    const activeCall: CallInfo = state.activeCall;
    if (!activeCall.callId || activeCall.callId.length === 0) {
      Logger.warn('IncomingNotificationFeature.publish: no active call');
      return;
    }
    const caller: CallParticipantInfo | undefined = state.allParticipants
      .find((p: CallParticipantInfo): boolean => p.id === activeCall.inviterId);
    const callerName: string = UserManager.getUserDisplayName(caller);
    const tipKey: string = this.tipKey(activeCall);

    try {
      const acceptAgent = await this.buildWantAgent(NOTIFICATION_CALL_ACTION_ACCEPT, 1);
      const rejectAgent = await this.buildWantAgent(NOTIFICATION_CALL_ACTION_REJECT, 2);
      const tapAgent = await this.buildWantAgent('', 0);
      const largeIcon: image.PixelMap | undefined = await this.tryLoadAvatarPixelMap(caller?.avatarURL);

      const request: notificationManager.NotificationRequest = {
        id: NOTIFICATION_ID,
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        wantAgent: tapAgent,
        // SOCIAL_COMMUNICATION already provides heads-up + sound by default;
        // there is no public `fullScreenIntentWantAgent` field on the surface.
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: callerName.length > 0 ? callerName : TUICallKitLocalize('TUICallKit.have_new_invitation'),
            text: TUICallKitLocalize(tipKey),
          },
        },
        largeIcon,
        actionButtons: [
          { title: TUICallKitLocalize('TUICallKit.decline'), wantAgent: rejectAgent },
          { title: TUICallKitLocalize('TUICallKit.answer'), wantAgent: acceptAgent },
        ],
      };

      await notificationManager.publish(request);
      this.hasPublished = true;
      Logger.info('IncomingNotificationFeature.publish: posted', activeCall.callId);
    } catch (e) {
      Logger.warn('IncomingNotificationFeature.publish failed', e);
    }
  }

  async cancel(): Promise<void> {
    if (!this.hasPublished) {
      return;
    }
    this.hasPublished = false;
    try {
      await notificationManager.cancel(NOTIFICATION_ID);
    } catch (e) {
      Logger.warn('IncomingNotificationFeature.cancel failed', e);
    }
  }

  async destroy(): Promise<void> {
    await this.cancel();
    this.context = null;
  }

  private tipKey(call: CallInfo): string {
    if ((call.chatGroupId?.length ?? 0) > 0) {
      return 'TUICallKit.Group.inviteToGroupCall';
    }
    return call.mediaType === CallMediaType.video
      ? 'TUICallKit.inviteToVideoCall'
      : 'TUICallKit.inviteToAudioCall';
  }

  private async buildWantAgent(action: string, requestCode: number): Promise<WantAgent> {
    if (!this.context) {
      throw new Error('IncomingNotificationFeature: context not bound');
    }
    const parameters: Record<string, string> = {};
    if (action.length > 0) {
      parameters[NOTIFICATION_CALL_ACTION_KEY] = action;
    }
    const info: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: this.context.abilityInfo.bundleName,
        abilityName: this.context.abilityInfo.name,
        parameters,
      }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };
    return wantAgent.getWantAgent(info);
  }

  /** Returns undefined on any failure; the notification will fall back to the bundle's default icon. */
  private async tryLoadAvatarPixelMap(url: string | undefined): Promise<image.PixelMap | undefined> {
    if (!url || url.length === 0 || !url.startsWith('http')) {
      return undefined;
    }
    try {
      const req = http.createHttp();
      const resp = await req.request(url, { method: http.RequestMethod.GET });
      req.destroy();
      if (resp.responseCode !== http.ResponseCode.OK) {
        return undefined;
      }
      const buffer: ArrayBuffer = resp.result as ArrayBuffer;
      const source = image.createImageSource(buffer);
      const pixelMap = await source.createPixelMap();
      source.release();
      return pixelMap;
    } catch (e) {
      Logger.warn('IncomingNotificationFeature: avatar fetch failed', e);
      return undefined;
    }
  }
}
