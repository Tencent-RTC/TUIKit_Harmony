import { MessageInfo, MessageInputStore, TextSendMessagePayload } from '@tencentcloud/atomicxcore';
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';
import { KeyboardAvoidMode as UIContextKeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { ThemeState, Toast } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { CompletionHandlerAdapter } from '@tencentcloud/atomicx/src/main/ets/basecomponent/utils/CompletionHandlers';
import { AtomicCallEventPublisher } from '@tencentcloud/atomicx/src/main/ets/common/AtomicCallEventPublisher';
import {
  CallMessageClickContext,
  ChatMessageListConfig,
  MessageList,
  MultiSelectActions,
  MultiSelectBottomBar
} from '@tencentcloud/atomicx/src/main/ets/messagelist/Index';
import { ChatMessageInputConfig, MessageInput } from '@tencentcloud/atomicx/src/main/ets/messageinput/Index';
import {
  AgentWelcomeInserter,
  AIAssistantAgent,
  AIAssistantAgentLoader,
  AIAssistantControlMessages,
  AIAssistantHandoffStatus,
  AIAssistantHandoffStatusLoader,
  AIAssistantUsageReporter,
  AICallActivity,
  pushAICallPage,
  AIConstants
} from '@tencentcloud/atomicx/src/main/ets/aiassistant/Index';
import { SystemOpusDecoder } from '@tencentcloud/atomicx/src/main/ets/aiassistant/audio/SystemOpusDecoder';
import { RealtimeAsrAudioCapture } from '@tencentcloud/atomicx/src/main/ets/messageinput/asr/RealtimeAsrAudioCapture';

@Component
export struct AIAssistantPageView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('themeVersion') themeVersion: number = 0;
  agentLoader?: AIAssistantAgentLoader;
  handoffStatusLoader?: AIAssistantHandoffStatusLoader;
  @Prop @Watch('onPageVisible') isPageVisible: boolean = true;
  @State private agents: AIAssistantAgent[] = [];
  @State private selectedAgentName: string = '';
  @State private boundConversationID: string = '';
  @State private showEmpty: boolean = false;
  @State private isMultiSelectMode: boolean = false;
  @State private selectedCount: number = 0;
  @State private transferOverlayHeight: number = 0;
  @State private showAgentMenu: boolean = false;
  private selectedAgent?: AIAssistantAgent;
  private multiSelectActions?: MultiSelectActions;
  private messageListConfig: ChatMessageListConfig = new ChatMessageListConfig();
  private usageReporter: AIAssistantUsageReporter = new AIAssistantUsageReporter();
  private isVoiceCallSupported: boolean = RealtimeAsrAudioCapture.isSupported() && SystemOpusDecoder.isSupported();
  private attached: boolean = false;
  private fetchGeneration: number = 0;
  private callCheckGeneration: number = 0;
  private isCheckingHandoffStatus: boolean = false;
  private callDialogController?: CustomDialogController;
  private previousKeyboardAvoidMode?: UIContextKeyboardAvoidMode;

  aboutToAppear(): void {
    this.attached = true;
    this.updateKeyboardAvoidMode();
    if (this.agentLoader) {
      this.reloadAgents();
    }
  }

  aboutToDisappear(): void {
    this.attached = false;
    this.restoreKeyboardAvoidMode();
    this.fetchGeneration++;
    this.callCheckGeneration++;
    this.isCheckingHandoffStatus = false;
    this.callDialogController?.close();
    this.callDialogController = undefined;
  }

  onPageVisible(): void {
    this.updateKeyboardAvoidMode();
    if (this.isPageVisible && this.attached && this.agentLoader) {
      this.reloadAgents();
    }
  }

  private updateKeyboardAvoidMode(): void {
    if (this.isPageVisible && this.previousKeyboardAvoidMode === undefined) {
      this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode();
      this.getUIContext().setKeyboardAvoidMode(UIContextKeyboardAvoidMode.NONE);
    } else if (!this.isPageVisible) {
      this.restoreKeyboardAvoidMode();
    }
  }

  private restoreKeyboardAvoidMode(): void {
    if (this.previousKeyboardAvoidMode !== undefined) {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
      this.previousKeyboardAvoidMode = undefined;
    }
  }

  build() {
    Column() {
      this.HeaderBuilder()

      if (this.showEmpty) {
        Text($r('app.string.uikit_ai_agents_empty'))
          .fontSize(15)
          .fontColor(this.themeState.colors.textColorSecondary)
          .textAlign(TextAlign.Center)
          .padding({ left: 32, right: 32, top: 48, bottom: 48 })
          .width('100%')
          .layoutWeight(1)
      } else if (this.boundConversationID.length > 0) {
        ForEach([`${this.boundConversationID}_${this.themeVersion}`], (chatKey: string) => {
          this.ChatBuilder(this.boundConversationID)
        }, (chatKey: string) => chatKey)
      } else {
        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorTopBar)
  }

  @Builder
  HeaderBuilder() {
    Column() {
      Row() {
        Blank()
          .layoutWeight(1)

        Row() {
          Text(this.selectedAgentName.length > 0 ? this.selectedAgentName : $r('app.string.uikit_ai_page_title'))
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 180 })
          if (this.agents.length > 1) {
            Image($rawfile('aiassistant/ic_title_dropdown.svg'))
              .width(16)
              .height(16)
              .margin({ left: 2 })
              .fillColor(this.themeState.colors.textColorPrimary)
          }
        }
        .layoutWeight(2)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          if (this.agents.length > 1) {
            this.showAgentMenu = true;
          }
        })
        .bindMenu(this.showAgentMenu, this.AgentMenuBuilder(), {
          onDisappear: () => {
            this.showAgentMenu = false;
          }
        })

        Row() {
          if (this.agents.length > 0 && this.isVoiceCallSupported) {
            Image($rawfile('aiassistant/ic_call.svg'))
              .width(20)
              .height(20)
              .colorFilter(new ColorFilter(AIAssistantPageView.tintMatrix(this.themeState.colors.textColorPrimary)))
              .onClick(() => {
                this.onCallClicked();
              })
          }
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })

      Divider()
        .width('100%')
        .height(0.5)
        .color(this.themeState.colors.strokeColorPrimary)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  AgentMenuBuilder() {
    Menu() {
      ForEach(this.agents, (agent: AIAssistantAgent) => {
        MenuItem({ content: agent.displayName })
          .onClick(() => {
            this.bindAgent(agent, this.agents);
          })
      }, (agent: AIAssistantAgent) => agent.id + agent.conversationID)
    }
  }

  @Builder
  ChatBuilder(conversationID: string) {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        MessageList({
          conversationID: conversationID,
          config: this.messageListConfig,
          bottomContentInset: this.isMultiSelectMode ? 0 : this.transferOverlayHeight,
          onMultiSelectModeChange: (isMultiSelectMode: boolean, selectedCount: number,
            actions?: MultiSelectActions) => {
            this.isMultiSelectMode = isMultiSelectMode;
            this.selectedCount = selectedCount;
            this.multiSelectActions = actions;
          }
        })
          .width('100%')
          .height('100%')

        if (!this.isMultiSelectMode) {
          Text($r('app.string.uikit_ai_transfer_to_human'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .borderWidth(1)
            .borderColor(this.themeState.colors.strokeColorPrimary)
            .backgroundColor(this.themeState.colors.bgColorOperate)
            .margin({ left: 12, bottom: 8 })
            .onAreaChange((_oldValue: Area, newValue: Area) => {
              this.transferOverlayHeight = Number(newValue.height) + 8;
            })
            .onClick(() => {
              this.sendTransferToHuman();
            })
        }
      }
      .width('100%')
      .layoutWeight(1)

      if (this.isMultiSelectMode) {
        MultiSelectBottomBar({
          selectedCount: this.selectedCount,
          onDelete: () => {
            this.multiSelectActions?.deleteMessages();
          },
          onSeparateForward: () => {
            this.multiSelectActions?.forwardSeparately();
          },
          onMergedForward: () => {
            this.multiSelectActions?.forwardMerged();
          }
        })
      } else {
        MessageInput({
          conversationID: conversationID,
          keyboardPlaceholderBottomInset: 88,
          config: new ChatMessageInputConfig({
            enableSendRecordedVoice: false,
            isShowAudioCall: false,
            isShowVideoCall: false,
            isShowMore: false,
            isShowEmojiButton: false,
            isShowPlusButton: false
          }),
          onTextMessageSent: () => {
            this.usageReporter.onMessageSent();
          }
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  private reloadAgents(): void {
    const loader = this.agentLoader;
    if (!loader) {
      return;
    }
    const generation = ++this.fetchGeneration;
    loader((loadedAgents: AIAssistantAgent[]) => {
      if (generation !== this.fetchGeneration || !this.attached) {
        return;
      }
      this.onAgentsLoaded(loadedAgents);
    });
  }

  private onAgentsLoaded(agents: AIAssistantAgent[]): void {
    this.agents = agents;
    if (agents.length === 0) {
      this.selectedAgent = undefined;
      this.selectedAgentName = '';
      this.boundConversationID = '';
      this.showEmpty = true;
      return;
    }
    this.showEmpty = false;
    const currentId = this.selectedAgent?.id;
    const next = agents.find((agent: AIAssistantAgent) => agent.id === currentId) ?? agents[0];
    this.bindAgent(next, agents);
  }

  private bindAgent(agent: AIAssistantAgent, agents: AIAssistantAgent[]): void {
    if (this.selectedAgent?.id !== agent.id) {
      this.callCheckGeneration++;
      this.isCheckingHandoffStatus = false;
    }
    this.selectedAgent = agent;
    this.selectedAgentName = agent.displayName;
    this.agents = agents;
    if (this.boundConversationID === agent.conversationID) {
      AgentWelcomeInserter.insertIfConversationEmpty(agent, () => {
      });
      return;
    }
    AgentWelcomeInserter.insertIfConversationEmpty(agent, () => {
      if (!this.attached || this.selectedAgent?.id !== agent.id ||
        this.selectedAgent?.conversationID !== agent.conversationID) {
        return;
      }
      this.messageListConfig = new ChatMessageListConfig({
        isShowLeftAvatar: false,
        isShowRightAvatar: false
      })
        .addMessageExclusion((message: MessageInfo): boolean => AIAssistantControlMessages.isControlMessage(message))
        .setEnableChatbotReplyPlaceholder(false)
        .setCallMessageClickListener((clickContext: CallMessageClickContext): boolean => {
          this.onCallMessageClicked(clickContext);
          return true;
        });
      this.isMultiSelectMode = false;
      this.selectedCount = 0;
      this.multiSelectActions = undefined;
      this.boundConversationID = agent.conversationID;
    });
  }

  private onCallClicked(): void {
    const agent = this.selectedAgent;
    if (!agent) {
      return;
    }
    const statusLoader = this.handoffStatusLoader;
    if (!statusLoader) {
      this.startAiVoiceCall(agent);
      return;
    }
    if (this.isCheckingHandoffStatus) {
      return;
    }
    this.isCheckingHandoffStatus = true;
    const generation = ++this.callCheckGeneration;
    statusLoader((status: AIAssistantHandoffStatus) => {
      if (generation !== this.callCheckGeneration) {
        return;
      }
      this.isCheckingHandoffStatus = false;
      if (!this.attached || this.selectedAgent?.id !== agent.id) {
        return;
      }
      if (status.isSeatCallable) {
        AtomicCallEventPublisher.publishStartCall([status.seatImUserId.trim()],
          AtomicCallEventPublisher.MEDIA_TYPE_AUDIO);
      } else if (status.isWaitingForSeat) {
        Toast.info($r('app.string.uikit_ai_call_handoff_waiting'), this.getUIContext());
      } else {
        this.startAiVoiceCall(agent);
      }
    });
  }

  private onCallMessageClicked(clickContext: CallMessageClickContext): void {
    const agent = this.selectedAgent;
    if (!agent) {
      return;
    }
    const statusLoader = this.handoffStatusLoader;
    if (!statusLoader) {
      Toast.info($r('app.string.uikit_ai_call_handoff_required'), this.getUIContext());
      return;
    }
    if (this.isCheckingHandoffStatus) {
      return;
    }
    this.isCheckingHandoffStatus = true;
    const generation = ++this.callCheckGeneration;
    statusLoader((status: AIAssistantHandoffStatus) => {
      if (generation !== this.callCheckGeneration) {
        return;
      }
      this.isCheckingHandoffStatus = false;
      if (!this.attached || this.selectedAgent?.id !== agent.id) {
        return;
      }
      if (status.isSeatCallable) {
        clickContext.startCall(status.seatImUserId);
      } else if (status.isWaitingForSeat) {
        Toast.info($r('app.string.uikit_ai_call_handoff_waiting'), this.getUIContext());
      } else {
        Toast.info($r('app.string.uikit_ai_call_handoff_required'), this.getUIContext());
      }
    });
  }

  private startAiVoiceCall(agent: AIAssistantAgent): void {
    if (!this.isVoiceCallSupported || agent.imUserId.trim().length === 0) {
      return;
    }
    this.usageReporter.onVoiceEntered();
    if (pushAICallPage(agent.imUserId)) {
      return;
    }
    this.callDialogController?.close();
    this.callDialogController = new CustomDialogController({
      builder: AICallActivity({
        robotUserId: agent.imUserId
      }),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      customStyle: true,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
      maskColor: 'rgba(0, 0, 0, 0)',
      cancel: () => {
        this.callDialogController = undefined;
      },
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND
    });
    this.callDialogController.open();
  }

  private sendTransferToHuman(): void {
    const conversationID = this.boundConversationID;
    if (conversationID.length === 0) {
      return;
    }
    MessageInputStore.create(conversationID).sendMessage(
      new TextSendMessagePayload(AIConstants.TRANSFER_TO_HUMAN_TEXT),
      undefined,
      new CompletionHandlerAdapter(() => {
        this.usageReporter.onMessageSent();
      }, () => {
        Toast.info($r('app.string.uikit_ai_call_send_failed'), this.getUIContext());
      })
    );
  }

  private static tintMatrix(color: string): number[] {
    let hex = color.startsWith('#') ? color.substring(1) : color;
    if (hex.length === 8) {
      hex = hex.substring(2);
    }
    const value = hex.length === 6 ? Number.parseInt(hex, 16) : 0;
    const safe = Number.isNaN(value) ? 0 : value;
    const r = ((safe >> 16) & 0xff) / 255;
    const g = ((safe >> 8) & 0xff) / 255;
    const b = (safe & 0xff) / 255;
    return [
      0, 0, 0, 0, r,
      0, 0, 0, 0, g,
      0, 0, 0, 0, b,
      0, 0, 0, 1, 0
    ];
  }
}
