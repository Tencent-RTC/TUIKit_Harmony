import { TUICallMediaType, TUICallScene } from '@tencentcloud/rtcroomengine'

@ObservedV2
export class CallState {
  @Trace mediaType: TUICallMediaType = TUICallMediaType.None
  @Trace scene: TUICallScene = TUICallScene.Single
  @Trace callDuration: number = 0
  chatGroupId: string = ""
  callId: string = ""

  public reset() {
    this.mediaType = TUICallMediaType.None
    this.scene = TUICallScene.Single
    this.callDuration = 0
    this.chatGroupId = ""
    this.callId = ""
  }
}