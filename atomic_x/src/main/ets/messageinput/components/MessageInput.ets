import { ThemeState, Toast ,IMErrorCode } from '../../basecomponent/Index';
import { EventBus } from '../../basecomponent/utils/EventBus';
import { MessageQuoteEvent } from '../../messagelist/ui/MessageQuoteEvent';
import {
  MessageQuoteDisplayPolicy,
  MessageQuoteLabels
} from '../../messagelist/cells/MessageQuoteDisplayPolicy';
import emitter from '@ohos.events.emitter';
import { MessageInfo, MessageQuoteInfo, MessageType, OfflinePushInfo, TextMessagePayload } from '@tencentcloud/atomicxcore';
import { MessageInputStore, SendMessagePayload, SendMessageOption, TextSendMessagePayload, ImageSendMessagePayload, VideoSendMessagePayload, AudioSendMessagePayload, FileSendMessagePayload, CustomSendMessagePayload } from '@tencentcloud/atomicxcore';
import { ConversationListStore, ConversationInfo, ConversationType } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { MessageInputMoreDialog, MenuItem } from './MessageInputMoreDialog';
import { EmojiDataManager, EmojiItem, EmojiPicker, EmojiTextSegment } from '../../emojipicker/Index';
import { AudioRecorder } from '../../audiorecorder/Index';
import { AudioRecorderView } from '../Index';
import { FilePicker } from '../../filepicker/Index';
import { VideoRecorder, RecordMode, VideoRecorderErrorCode, RecordListener } from '../../videorecorder/Index';
import { AlbumPicker, AlbumPickerResult, PickMode } from '../../albumpicker/Index';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { dataSharePredicates } from '@kit.ArkData';
import image from '@ohos.multimedia.image';
import { MessageInputConfigProtocol, ChatMessageInputConfig, InputStyle } from '../config/MessageInputConfig';
import { MentionInfo } from './MentionInfo';
import { MentionMemberDialog } from './MentionMemberDialog';
import { ClassicInputBar, ClassicInputBarCallbacks } from './ClassicInputBar';
import { MinimalistInputBar, MinimalistInputBarCallbacks } from './MinimalistInputBar';
import { VoiceTranscriptionDraftView } from './VoiceTranscriptionDraftView';
import { AudioTranscriber } from './AudioTranscriber';
import {
  CompletionHandlerAdapter,
  GetConversationInfoCompletionHandlerAdapter
} from '../../basecomponent/utils/CompletionHandlers';
import { AtomicCallEventPublisher } from '../../common/AtomicCallEventPublisher';
import { GroupMemberPickerDialog } from '../../chatsetting/pages/GroupMemberPickerDialog';
import { GroupMember } from '@tencentcloud/atomicxcore';
import { CallMediaType } from '../../call/common/CallStore';
import { UserPickerData } from '../../userpicker/Index';

type VoiceRecordReleaseAction = 'send' | 'cancel' | 'transcribe';

@Component
export struct MessageInput {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  // File size limits in bytes
  private static readonly IMAGE_AUDIO_MAX_SIZE = 28 * 1024 * 1024; // 28MB
  private static readonly VIDEO_FILE_MAX_SIZE = 100 * 1024 * 1024; // 100MB
  conversationID: string = '';
  config?: MessageInputConfigProtocol = undefined;
  onVoiceCallClick?: () => void;
  onVideoCallClick?: () => void;
  private effectiveConfig: MessageInputConfigProtocol = new ChatMessageInputConfig();
  dialogController?: CustomDialogController = undefined;
  private richEditorController: RichEditorController = new RichEditorController();
  @State private inputState: MessageInputStore | null = null;
  @State private showEmojiPicker: boolean = false;
  private context = getContext(this) as common.UIAbilityContext;
  private audioTranscriber: AudioTranscriber = new AudioTranscriber();
  @State private inputFocused: boolean = false;
  private hiddenButtonId: string = 'hiddenFocusButton';
  @State private isVoiceRecording: boolean = false;
  @State private recordingDuration: number = 0;
  @State private showKeyboardPlaceholder: boolean = false;
  @State private shouldCancelRecording: boolean = false;
  @State private shouldTranscribeRecording: boolean = false;
  @State private dragOffset: number = 0;
  @State private showVoiceTranscriptionDraft: boolean = false;
  @State private voiceTranscriptionAudioPath: string = '';
  @State private voiceTranscriptionAudioDuration: number = 0;
  @State private voiceTranscriptionText: string = '';
  @State private voiceTranscriptionLoading: boolean = false;
  private readonly cancelThreshold: number = -50; // Upward drag threshold for cancel
  private voiceRecordReleaseAction: VoiceRecordReleaseAction = 'send';
  private longPressTimer?: number;
  private initialTouchY: number = 0;
  // Draft related properties
  private conversationStore: ConversationListStore = ConversationListStore.create();
  private draftSaveTimer?: number;
  private isLoadingDraft: boolean = false;
  private static readonly DRAFT_SAVE_DELAY: number = 800; // 800ms debounce
  // @ mention related properties
  @State private mentionList: MentionInfo[] = [];
  private mentionDialogController?: CustomDialogController;
  private atPosition: number = 0; // Position where "@" was typed
  private isRemovingMention: boolean = false;
  // Parsed from conversationID for @ mention feature
  private parsedGroupID: string = '';
  private parsedUserID: string = '';
  private parsedConversationType: ConversationType = ConversationType.UNKNOWN;
  // Dialog controller for the group call member picker (kept as field to avoid GC issues)
  private groupCallMemberPickerController?: CustomDialogController;
  // Quote message related properties
  @State private quotedMessage?: MessageInfo = undefined;
  @State private quotedSummary: string = '';
  @State private quotedSenderPrefix: string = '';
  @State private quotedContentText: string = '';

  aboutToAppear() {
    if (this.conversationID) {
      this.inputState = MessageInputStore.create(this.conversationID);
      // Parse conversationType and groupID from conversationID
      this.parseConversationID();
    } else {
      console.error('[MessageInputBar] No conversationID provided, input state will not be created');
    }

    // Initialize style
    if (this.config) {
      this.effectiveConfig = this.config;
    }

    AudioRecorder.getInstance().setContext(this.context);
    
    // Initialize dialog controller with dynamic menu items
    this.initializeDialogController();
    
    // Load draft when component appears
    this.loadDraft();
    
    // Subscribe to EventBus for @ mention events
    EventBus.getInstance().on('onUserLongPress', (eventData) => {
      this.handleMentionEvent(eventData);
    });

    // Subscribe to EventBus for quote message events
    EventBus.getInstance().on(MessageQuoteEvent.QUOTE_MESSAGE, (eventData: emitter.EventData) => {
      this.handleQuoteMessageEvent(eventData);
    });
  }

  /**
   * Parse conversationID to extract conversationType and groupID
   * Format: "group_xxx" for group, "c2c_xxx" for C2C
   */
  private parseConversationID(): void {
    if (this.conversationID.startsWith('group_')) {
      this.parsedConversationType = ConversationType.GROUP;
      this.parsedGroupID = this.conversationID.substring(6); // Remove "group_" prefix
      this.parsedUserID = '';
    } else if (this.conversationID.startsWith('c2c_')) {
      this.parsedConversationType = ConversationType.C2C;
      this.parsedGroupID = '';
      this.parsedUserID = this.conversationID.substring(4); // Remove "c2c_" prefix
    } else {
      this.parsedConversationType = ConversationType.UNKNOWN;
      this.parsedGroupID = '';
      this.parsedUserID = '';
    }
  }

  /**
   * Start an audio call from the input more-menu.
   *
   * Aligned with Android `MessageInputViewModel.startAudioCall`:
   *   - C2C conversation: publish start-call directly to the peer user
   *   - Group conversation: pop up group member picker; after members are
   *     selected, publish start-call with the group id + selected participants
   *
   * Callers can override the default behavior by supplying
   * `onVoiceCallClick`; when provided, we defer to the host and skip the
   * built-in publisher.
   */
  private startAudioCall(): void {
    if (this.onVoiceCallClick) {
      this.onVoiceCallClick();
      return;
    }
    this.handleStartCall(AtomicCallEventPublisher.MEDIA_TYPE_AUDIO);
  }

  /** Same as `startAudioCall` but for video. */
  private startVideoCall(): void {
    if (this.onVideoCallClick) {
      this.onVideoCallClick();
      return;
    }
    this.handleStartCall(AtomicCallEventPublisher.MEDIA_TYPE_VIDEO);
  }

  private handleStartCall(mediaType: CallMediaType): void {
    if (this.parsedConversationType === ConversationType.C2C) {
      if (this.parsedUserID.length === 0) {
        return;
      }
      AtomicCallEventPublisher.publishStartCall([this.parsedUserID], mediaType);
      return;
    }
    if (this.parsedConversationType === ConversationType.GROUP) {
      if (this.parsedGroupID.length === 0) {
        return;
      }
      this.showGroupCallMemberPicker(this.parsedGroupID, mediaType);
    }
  }

  private showGroupCallMemberPicker(chatGroupId: string, mediaType: CallMediaType): void {
    this.groupCallMemberPickerController = new CustomDialogController({
      builder: GroupMemberPickerDialog({
        groupID: chatGroupId,
        onConfirm: (selectedItems: UserPickerData<GroupMember>[]) => {
          if (selectedItems.length > 0) {
            const participantIds: string[] =
              selectedItems.map((item: UserPickerData<GroupMember>): string => item.key);
            AtomicCallEventPublisher.publishStartCall(participantIds, mediaType, chatGroupId);
          }
        },
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true,
    });
    this.groupCallMemberPickerController.open();
  }

  /**
   * Handle @ mention event from EventBus
   * Called when user long presses avatar in message list
   */
  private handleMentionEvent(eventData: emitter.EventData): void {
    const data = eventData.data as Record<string, Object>;
    const source = data['source'] as string;
    const event = data['event'] as string;
    const userID = data['userID'] as string;
    const nickname = data['nickname'] as string;
    
    console.log(`[MessageInput] 📨 Received mention event: source=${source}, event=${event}, userID=${userID}, nickname=${nickname}`);
    
    if (source !== 'MessageList' || event !== 'onUserLongPress') {
      console.log(`[MessageInput] ⚠️ Ignored event - wrong source or type`);
      return;
    }
    
    // Only works in group chat
    if (this.parsedConversationType !== ConversationType.GROUP) {
      console.log('[MessageInput] ⚠️ Not a group chat, ignoring mention event');
      return;
    }
    
    if (!userID || !nickname) {
      console.log('[MessageInput] ⚠️ Empty userID or nickname, ignoring');
      return;
    }
    
    console.log(`[MessageInput]  Inserting mention: userID=${userID}, nickname=${nickname}`);
    this.insertMentionInternal(userID, nickname);
  }

  /**
   * Internal method to insert a mention into the input field
   * @param userID The user ID to mention
   * @param displayName The display name to show (nickname or userID)
   */
  private insertMentionInternal(userID: string, displayName: string): void {
    // Only works in group chat
    if (this.parsedConversationType !== ConversationType.GROUP) {
      console.log('[MessageInput] insertMention: Not a group chat, ignoring');
      return;
    }

    if (!userID || userID.length === 0) {
      console.log('[MessageInput] insertMention: Empty userID, ignoring');
      return;
    }

    console.log(`[MessageInput] 📝 Inserting mention: userID=${userID}, displayName=${displayName}`);

    // Get current cursor position
    const currentOffset = this.richEditorController.getCaretOffset();

    // Create MentionInfo with constructor parameters
    const mention = new MentionInfo(userID, displayName, currentOffset);

    const fullMentionText = mention.mentionText;
    console.log(`[MessageInput]   Insert mention at ${currentOffset}: "${fullMentionText}"`);

    // Insert BuilderSpan (atomic, non-editable block)
    this.richEditorController.addBuilderSpan(
      () => {
        this.MentionSpanBuilder(fullMentionText);
      },
      { offset: currentOffset }
    );

    // Add to mention list
    this.mentionList.push(mention);

    // Move cursor to end of inserted mention (BuilderSpan = 1 position)
    setTimeout(() => {
      this.richEditorController.setCaretOffset(currentOffset + 1);
    }, 50);

    console.log(`[MessageInput] ✅ mentionList now has ${this.mentionList.length} items`);
  }

  aboutToDisappear() {
    // Save draft immediately when component disappears (fallback mechanism)
    this.saveDraftImmediately();
    // Cancel any pending draft save timer
    if (this.draftSaveTimer) {
      clearTimeout(this.draftSaveTimer);
      this.draftSaveTimer = undefined;
    }
    
    // Unsubscribe from EventBus
    EventBus.getInstance().off('onUserLongPress');
    EventBus.getInstance().off(MessageQuoteEvent.QUOTE_MESSAGE);
  }

  // Initialize dialog controller with menu items based on style
  private initializeDialogController(): void {
    const menuItems: MenuItem[] = [];

    // Add default menu items based on style
      menuItems.push({
        id: 'image',
        text: $r('app.string.menu_image'),
        icon: $rawfile('messageinput/image_icon.svg'),
        action: () => {
          this.selectImage();
        }
      });

    if (this.effectiveConfig.isShowPhotoTaker) {
      menuItems.push({
        id: 'photo',
        text: $r('app.string.menu_photo'),
        icon: $rawfile('messageinput/camera_action_icon.svg'),
        action: () => {
          this.takePhoto();
        }
      });
    }

    if (this.effectiveConfig.isShowPhotoTaker) {
      menuItems.push({
        id: 'video',
        text: $r('app.string.menu_video'),
        icon: $rawfile('messageinput/video_icon.svg'),
        action: () => {
          this.recordVideo();
        }
      });
    }

      menuItems.push({
        id: 'file',
        text: $r('app.string.menu_file'),
        icon: $rawfile('messageinput/document_icon.svg'),
        action: () => {
          this.selectFile();
        }
      });

    if (this.effectiveConfig.isShowAudioCall) {
      menuItems.push({
        id: 'voiceCall',
        text: $r('app.string.menu_voice_call'),
        icon: $rawfile('messageinput/voice_call_icon.svg'),
        action: () => {
          this.startAudioCall();
        }
      });
    }

    if (this.effectiveConfig.isShowVideoCall) {
      menuItems.push({
        id: 'videoCall',
        text: $r('app.string.menu_video_call'),
        icon: $rawfile('messageinput/video_call_icon.svg'),
        action: () => {
          this.startVideoCall();
        }
      });
    }

    menuItems.push({
      id: 'customMessage',
      text: $r('app.string.menu_custom'),
      icon: $rawfile('messageinput/custom_icon.svg'),
      action: () => {
        this.sendTextLinkCustomMessage();
      }
    });

    // Create dialog controller with menu items
    this.dialogController = new CustomDialogController({
      builder: MessageInputMoreDialog({
        menuItems: menuItems,
        onCancel: () => {
          console.log('[MessageInput] More dialog cancelled');
        }
      }),
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: -16 },
      customStyle: true,
      autoCancel: true
    });
  }


  build() {
    Column() {
      // Quote preview bar above the input
      this.QuotePreviewBar()
      if (this.showVoiceTranscriptionDraft) {
        this.VoiceTranscriptionDraftBuilder()
      } else {
        // Route to different input bar styles based on configuration
        if (this.effectiveConfig.inputStyle === 'classic') {
          this.buildClassicStyle()
        } else {
          this.buildMinimalistStyle()
        }
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  private VoiceTranscriptionDraftBuilder() {
    VoiceTranscriptionDraftView({
      audioDuration: this.voiceTranscriptionAudioDuration,
      text: this.voiceTranscriptionText,
      isLoading: this.voiceTranscriptionLoading,
      onCancel: () => {
        this.hideVoiceTranscriptionDraft();
      },
      onSendAudio: () => {
        this.sendVoiceMessage(this.voiceTranscriptionAudioDuration, this.voiceTranscriptionAudioPath);
        this.hideVoiceTranscriptionDraft();
      },
      onSendText: (text: string) => {
        this.sendVoiceTranscriptionText(text);
      }
    })
  }

  @Builder
  private QuotePreviewBar() {
    if (this.quotedMessage) {
      Row() {
        Text() {
          if (this.quotedSenderPrefix.length > 0) {
            Span(this.quotedSenderPrefix)
          }
          ForEach(EmojiDataManager.parseEmojiText(this.quotedContentText),
            (segment: EmojiTextSegment, index: number) => {
              if (segment.type === 'text') {
                Span(segment.content)
              } else if (segment.type === 'emoji' && segment.imageFile) {
                ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
                  .width(18)
                  .height(18)
                  .objectFit(ImageFit.Contain)
                  .verticalAlign(ImageSpanAlignment.CENTER)
              }
            },
            (segment: EmojiTextSegment, index: number) => `quote_preview_${segment.type}_${index}_${segment.content}`)
        }
          .fontSize(13)
          .fontColor(this.themeState.colors.textColorSecondary)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('×')
          .fontSize(20)
          .fontColor(this.themeState.colors.textColorSecondary)
          .padding({ left: 12, right: 4 })
          .onClick(() => {
            this.clearQuotedMessage();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    }
  }

  private handleQuoteMessageEvent(eventData: emitter.EventData): void {
    const data = eventData.data as Record<string, Object> | undefined;
    if (!data) {
      return;
    }
    const conversationID = data['conversationID'] as string | undefined;
    if (!conversationID || conversationID !== this.conversationID) {
      return;
    }
    const message = data['message'] as MessageInfo | undefined;
    if (!message) {
      return;
    }
    this.quotedMessage = message;
    this.quotedSummary = this.buildQuotedSummary(message);
    this.updateQuotedSummaryParts(message);
  }

  private clearQuotedMessage(): void {
    this.quotedMessage = undefined;
    this.quotedSummary = '';
    this.quotedSenderPrefix = '';
    this.quotedContentText = '';
  }

  private updateQuotedSummaryParts(message: MessageInfo): void {
    const quoteInfo = new MessageQuoteInfo();
    quoteInfo.msgID = message.msgID;
    quoteInfo.status = message.status;
    quoteInfo.timestamp = message.timestamp ?? 0;
    quoteInfo.sequence = message.sequence ?? 0;
    quoteInfo.sender = message.from;
    quoteInfo.messageType = message.messageType;
    quoteInfo.messagePayload = message.messagePayload;
    const labels: MessageQuoteLabels = {
      deleted: this.getString($r('app.string.message_list_quote_deleted')),
      revoked: this.getString($r('app.string.message_list_quote_revoked')),
      image: this.getString($r('app.string.message_list_message_type_image')),
      video: this.getString($r('app.string.message_list_message_type_video')),
      voice: this.getString($r('app.string.message_list_message_type_voice')),
      file: this.getString($r('app.string.message_list_message_type_file')),
      face: this.getString($r('app.string.message_list_message_type_animate_emoji')),
      custom: this.getString($r('app.string.message_list_message_type_custom')),
      merged: this.getString($r('app.string.message_list_message_type_merged')),
      unknown: this.getString($r('app.string.message_list_unsupported_message'))
    };
    const data = MessageQuoteDisplayPolicy.resolve(quoteInfo, labels);
    this.quotedSenderPrefix = data.senderName.length > 0 ? `${data.senderName}: ` : '';
    this.quotedContentText = data.contentText;
  }

  private buildQuotedSummary(message: MessageInfo): string {
    const quoteInfo = new MessageQuoteInfo();
    quoteInfo.msgID = message.msgID;
    quoteInfo.status = message.status;
    quoteInfo.timestamp = message.timestamp ?? 0;
    quoteInfo.sequence = message.sequence ?? 0;
    quoteInfo.sender = message.from;
    quoteInfo.messageType = message.messageType;
    quoteInfo.messagePayload = message.messagePayload;
    const labels: MessageQuoteLabels = {
      deleted: this.getString($r('app.string.message_list_quote_deleted')),
      revoked: this.getString($r('app.string.message_list_quote_revoked')),
      image: this.getString($r('app.string.message_list_message_type_image')),
      video: this.getString($r('app.string.message_list_message_type_video')),
      voice: this.getString($r('app.string.message_list_message_type_voice')),
      file: this.getString($r('app.string.message_list_message_type_file')),
      face: this.getString($r('app.string.message_list_message_type_animate_emoji')),
      custom: this.getString($r('app.string.message_list_message_type_custom')),
      merged: this.getString($r('app.string.message_list_message_type_merged')),
      unknown: this.getString($r('app.string.message_list_unsupported_message'))
    };
    const data = MessageQuoteDisplayPolicy.resolve(quoteInfo, labels);
    if (data.senderName.length > 0) {
      return `${data.senderName}: ${data.contentText}`;
    }
    return data.contentText;
  }

  private getString(resource: Resource): string {
    try {
      return getContext(this).resourceManager.getStringSync(resource);
    } catch (_e) {
      return '';
    }
  }

  /**
   * Build the classic (WeChat-style) input bar
   * Layout: [voice] [input/press-to-speak] [emoji] [+/send]
   * Features: voice mode toggle, expand panels, press-to-speak
   */
  @Builder
  private buildClassicStyle() {
    if (this.isVoiceRecording) {
      // Voice recording overlay - same as minimalist style
      AudioRecorderView({
        recordingDuration: this.recordingDuration,
        shouldCancelRecording: $shouldCancelRecording,
        shouldTranscribeRecording: $shouldTranscribeRecording,
        primaryColor: this.themeState.colors.textColorLink || '#4A90E2',
        onCancel: () => {
          this.cancelVoiceRecording();
        },
        onSend: (action?: VoiceRecordReleaseAction) => {
          this.finishVoiceRecording(action ?? 'send');
        },
        onTimeLimitReached: () => {
          this.finishVoiceRecording();
        },
        onDragUpdate: (shouldCancel: boolean, shouldTranscribe?: boolean) => {
          this.shouldCancelRecording = shouldCancel;
          this.shouldTranscribeRecording = shouldTranscribe ?? false;
        }
      })
    } else {
      ClassicInputBar({
        inputFocused: $inputFocused,
        isVoiceRecording: $isVoiceRecording,
        showKeyboardPlaceholder: $showKeyboardPlaceholder,
        effectiveConfig: this.effectiveConfig,
        richEditorController: this.richEditorController,
        actionMenuItems: this.getActionMenuItems(),
        callbacks: {
          onSend: () => {
            this.sendTextMessage();
          },
          onVoiceRecordStart: () => {
            this.startVoiceRecording();
          },
          onVoiceRecordEnd: (action: VoiceRecordReleaseAction) => {
            this.finishVoiceRecording(action);
          },
          onVoiceRecordDragUpdate: (dragOffset: number, shouldCancel: boolean, shouldTranscribe?: boolean) => {
            this.dragOffset = dragOffset;
            this.shouldCancelRecording = shouldCancel;
            this.shouldTranscribeRecording = shouldTranscribe ?? false;
          },
          onEmojiSelected: (emoji: EmojiItem) => {
            this.handleEmojiSelected(emoji);
          },
          onDeleteClick: () => {
            this.handleDeleteLastCharacter();
          },
          onInputFocusChange: (focused: boolean) => {
            if (focused) {
              setTimeout(() => {
                if (this.inputFocused) {
                  this.showKeyboardPlaceholder = true;
                }
              }, 100);
            } else {
              this.showKeyboardPlaceholder = false;
            }
          },
          onInputChange: () => {
            if (!this.isLoadingDraft) {
              this.saveDraftWithDebounce();
            }
          },
          onAtTrigger: (cursorPosition: number) => {
            if (this.shouldEnableMention()) {
              this.handleAtInput(cursorPosition);
            }
          },
          onActionItemClick: (menuItem: MenuItem) => {
            menuItem.action();
          },
          onDidChange: (rangeBefore: TextRange, rangeAfter: TextRange) => {
            // Save draft with debounce when content changes
            if (!this.isLoadingDraft) {
              this.saveDraftWithDebounce();
            }
            
            const beforeStart = rangeBefore.start ?? 0;
            const beforeEnd = rangeBefore.end ?? beforeStart;
            const afterStart = rangeAfter.start ?? 0;
            const afterEnd = rangeAfter.end ?? afterStart;
            
            const beforeLen = beforeEnd - beforeStart;
            const afterLen = afterEnd - afterStart;
            
            if (afterLen > beforeLen) {
              // Text was inserted
              const insertPos = beforeStart;
              const insertLen = afterLen - beforeLen;
              console.log(`[MessageInput] onDidChange: INSERT at ${insertPos}, len=${insertLen}`);
              
              // Update mention positions - mentions at or after insertion point shift right
              this.mentionList.forEach((mention: MentionInfo) => {
                if (mention.startIndex >= insertPos) {
                  mention.startIndex += insertLen;
                  console.log(`[MessageInput]   mention shifted to ${mention.startIndex}`);
                }
              });
            } else if (beforeLen > afterLen) {
              // Text was deleted
              const deleteStart = afterStart;
              const deleteLen = beforeLen - afterLen;
              const deleteEnd = deleteStart + deleteLen;
              console.log(`[MessageInput] onDidChange: DELETE from ${deleteStart} to ${deleteEnd}`);
              this.handleMentionDeletion(deleteStart, deleteEnd);
            }

            return true;
          }
        } as ClassicInputBarCallbacks
      })
    }
  }

  /**
   * Build the minimalist (default) input bar
   * Layout: [+] [input + emoji] [microphone] [camera]
   */
  @Builder
  private buildMinimalistStyle() {
    if (this.isVoiceRecording) {
      // Voice recording overlay
      AudioRecorderView({
        recordingDuration: this.recordingDuration,
        shouldCancelRecording: $shouldCancelRecording,
        shouldTranscribeRecording: $shouldTranscribeRecording,
        primaryColor: this.themeState.colors.textColorLink || '#4A90E2',
        transcribeHorizontalActionThreshold: -72,
        onCancel: () => {
          this.cancelVoiceRecording();
        },
        onSend: (action?: VoiceRecordReleaseAction) => {
          this.finishVoiceRecording(action ?? 'send');
        },
        onTimeLimitReached: () => {
          this.finishVoiceRecording();
        },
        onDragUpdate: (shouldCancel: boolean, shouldTranscribe?: boolean) => {
          this.shouldCancelRecording = shouldCancel;
          this.shouldTranscribeRecording = shouldTranscribe ?? false;
        }
      })
    } else {
      MinimalistInputBar({
        showEmojiPicker: $showEmojiPicker,
        inputFocused: $inputFocused,
        isVoiceRecording: $isVoiceRecording,
        effectiveConfig: this.effectiveConfig,
        richEditorController: this.richEditorController,
        callbacks: {
          onMoreClick: () => {
            if (this.dialogController) {
              this.dialogController.open();
            }
          },
          onEmojiToggle: (showEmoji: boolean) => {
            // Emoji toggle handled by MinimalistInputBar
          },
          onVoiceRecordStart: () => {
            this.startVoiceRecording();
          },
          onVoiceRecordEnd: (action: VoiceRecordReleaseAction) => {
            this.finishVoiceRecording(action);
          },
          onVoiceRecordDragUpdate: (dragOffset: number, shouldCancel: boolean, shouldTranscribe?: boolean) => {
            this.dragOffset = dragOffset;
            this.shouldCancelRecording = shouldCancel;
            this.shouldTranscribeRecording = shouldTranscribe ?? false;
          },
          onCameraClick: () => {
            this.takePhoto();
          },
          onInputFocusChange: (focused: boolean) => {
            if (focused) {
              setTimeout(() => {
                if (this.inputFocused) {
                  this.showKeyboardPlaceholder = true;
                }
              }, 100);
            } else {
              this.showKeyboardPlaceholder = false;
            }
          },
          onSubmit: () => {
            this.sendTextMessage();
          },
          onInputChange: () => {
            if (!this.isLoadingDraft) {
              this.saveDraftWithDebounce();
            }
          },
          onAtTrigger: (cursorPosition: number) => {
            if (this.shouldEnableMention()) {
              this.handleAtInput(cursorPosition);
            }
          },
          onDidChange: (rangeBefore: TextRange, rangeAfter: TextRange) => {
            // Save draft with debounce when content changes
            if (!this.isLoadingDraft) {
              this.saveDraftWithDebounce();
            }
            
            const beforeStart = rangeBefore.start ?? 0;
            const beforeEnd = rangeBefore.end ?? beforeStart;
            const afterStart = rangeAfter.start ?? 0;
            const afterEnd = rangeAfter.end ?? afterStart;
            
            const beforeLen = beforeEnd - beforeStart;
            const afterLen = afterEnd - afterStart;
            
            if (afterLen > beforeLen) {
              // Text was inserted
              const insertPos = beforeStart;
              const insertLen = afterLen - beforeLen;
              console.log(`[MessageInput] onDidChange: INSERT at ${insertPos}, len=${insertLen}`);
              
              // Update mention positions - mentions at or after insertion point shift right
              this.mentionList.forEach((mention: MentionInfo) => {
                if (mention.startIndex >= insertPos) {
                  mention.startIndex += insertLen;
                  console.log(`[MessageInput]   mention shifted to ${mention.startIndex}`);
                }
              });
            } else if (beforeLen > afterLen) {
              // Text was deleted
              const deleteStart = afterStart;
              const deleteLen = beforeLen - afterLen;
              const deleteEnd = deleteStart + deleteLen;
              console.log(`[MessageInput] onDidChange: DELETE from ${deleteStart} to ${deleteEnd}`);
              this.handleMentionDeletion(deleteStart, deleteEnd);
            }

            return true;
          },
          onEmojiSelected: (emoji: EmojiItem) => {
            this.handleEmojiSelected(emoji);
          },
          onDeleteClick: () => {
            this.handleDeleteLastCharacter();
          }
        } as MinimalistInputBarCallbacks
      })
    }


    Button()
      .width(0)
      .height(0)
      .opacity(0)
      .focusable(true)
      .id(this.hiddenButtonId)


    if (this.showEmojiPicker) {
      EmojiPicker({
        onEmojiClick: (emoji: EmojiItem) => {
          this.handleEmojiSelected(emoji);
        },
        onDeleteClick: () => {
          this.handleDeleteLastCharacter();
        },
        onSendClick: () => {
          this.sendTextMessage();
        }
      })
        .transition({
          type: TransitionType.Insert,
          opacity: 1,
          translate: { y: 0 }
        })
        .transition({
          type: TransitionType.Delete,
          opacity: 0,
          translate: { y: 280 }
        })
    }

    // Keyboard placeholder to push input bar up
    if (this.showKeyboardPlaceholder && !this.showEmojiPicker) {
      Column()
        .width('100%')
        .height(280) // Same height as emoji picker
        .backgroundColor('transparent')
        .transition({
          type: TransitionType.Insert,
          opacity: 1,
          translate: { y: 0 }
        })
        .transition({
          type: TransitionType.Delete,
          opacity: 0,
          translate: { y: 280 }
        })
    }
  }

  /**
   * Get action menu items for classic input bar
   */
  private getActionMenuItems(): MenuItem[] {
    const menuItems: MenuItem[] = [];
    
    menuItems.push({
      id: 'image',
      text: $r('app.string.menu_image'),
      icon: $rawfile('messageinput/classic/image_icon.svg'),
      action: () => {
        this.selectImage();
      }
    });

    if (this.effectiveConfig.isShowPhotoTaker) {
      menuItems.push({
        id: 'photo',
        text: $r('app.string.menu_photo'),
        icon: $rawfile('messageinput/classic/camera_action_icon.svg'),
        action: () => {
          this.takePhoto();
        }
      });
    }

    if (this.effectiveConfig.isShowPhotoTaker) {
      menuItems.push({
        id: 'video',
        text: $r('app.string.menu_video'),
        icon: $rawfile('messageinput/classic/video_icon.svg'),
        action: () => {
          this.recordVideo();
        }
      });
    }

    menuItems.push({
      id: 'file',
      text: $r('app.string.menu_file'),
      icon: $rawfile('messageinput/classic/document_icon.svg'),
      action: () => {
        this.selectFile();
      }
    });

    if (this.effectiveConfig.isShowAudioCall) {
      menuItems.push({
        id: 'voiceCall',
        text: $r('app.string.menu_voice_call'),
        icon: $rawfile('messageinput/classic/voice_call_icon.svg'),
        action: () => {
          this.startAudioCall();
        }
      });
    }

    if (this.effectiveConfig.isShowVideoCall) {
      menuItems.push({
        id: 'videoCall',
        text: $r('app.string.menu_video_call'),
        icon: $rawfile('messageinput/classic/video_call_icon.svg'),
        action: () => {
          this.startVideoCall();
        }
      });
    }

    menuItems.push({
      id: 'customMessage',
      text: $r('app.string.menu_custom'),
      icon: $rawfile('messageinput/classic/custom_icon.svg'),
      action: () => {
        this.sendTextLinkCustomMessage();
      }
    });

    return menuItems;
  }

  private sendTextLinkCustomMessage(): void {
    if (!this.inputState) {
      console.warn('[MessageInput] sendTextLinkCustomMessage: inputState is not ready');
      return;
    }
    try {
      const customData = JSON.stringify({
        'businessID': 'text_link',
        'text': '欢迎加入腾讯云 IM 大家庭！',
        'link': 'https://cloud.tencent.com/document/product/269/3794'
      } as Record<string, string>);
      const payload = new CustomSendMessagePayload(customData, 'CustomTextLinkMessage', '');
      const option = new SendMessageOption();
      option.needReadReceipt = this.effectiveConfig.enableReadReceipt ?? false;

      this.inputState.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
        console.log('[MessageInput] sendTextLinkCustomMessage: sent successfully');
      }, (code: number, desc: string) => {
        console.error(`[MessageInput] sendTextLinkCustomMessage failed: code=${code}, message=${desc}`);
        const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + desc);
        Toast.error(localizedMessage, this.getUIContext());
      }));
    } catch (error) {
      console.error(`[MessageInput] sendTextLinkCustomMessage exception: ${error}`);
    }
  }

  private async sendTextMessage() {
    console.log(`[MessageInput] === sendTextMessage START ===`);
    const messageText = await this.getMessageText();
    console.log(`[MessageInput] Message text received: "${messageText}"`);
    
    if (!messageText.trim() || !this.inputState) {
      console.warn(`[MessageInput] Message is empty or inputState not ready, aborting send`);
      return;
    }

    // Build atUserList from mentionList
    const atUserList: string[] = this.mentionList.map((mention: MentionInfo): string => mention.userID);
    console.log(`[MessageInput] atUserList: [${atUserList.join(', ')}]`);

    // Clear draft BEFORE sending message (not dependent on send result)
    this.clearDraft();

    // Clear mention list
    this.mentionList = [];

    this.clearEditor();

    try {
      const payload = new TextSendMessagePayload(messageText.trim());
      const option = new SendMessageOption();
      option.needReadReceipt = this.effectiveConfig.enableReadReceipt ?? false;
      if (atUserList.length > 0) {
        option.atUserList = atUserList;
        console.log(`[MessageInput] Message has ${atUserList.length} mentions`);
      }
      option.offlinePushInfo = this.createOfflinePushInfoForText(messageText.trim());
      option.quotedMessage = this.quotedMessage;
      this.clearQuotedMessage();

      console.log(`[MessageInput] Sending message: "${messageText.trim()}", mentions: ${atUserList.length}`);

      this.inputState.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
        console.log(`[MessageInput] Message sent successfully`);
      }, (code: number, desc: string) => {
        console.error(`[MessageInput] Send failed: code=${code}, message=${desc}`);
        const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + desc);
        Toast.error(localizedMessage, this.getUIContext());
      }));
    } catch (error) {
      console.error(`[MessageInput] sendTextMessage exception: ${error}`);
    }
    console.log(`[MessageInput] === sendTextMessage END ===`);
  }

  private async selectImage(): Promise<void> {
    try {
      const results: AlbumPickerResult[] = await AlbumPicker.pickMedia();
      if (results.length > 0) {
        const result = results[0]; 
        if (result.filePath) {
          if (result.type === PickMode.IMAGE) {
            this.handleSelectedMedia(result.filePath, MessageType.IMAGE);
          } else if (result.type === PickMode.VIDEO) {
            this.handleSelectedMedia(result.filePath, MessageType.VIDEO);
          }
        }
      } else {
      }
    } catch (error) {
    }
  }

  private async takePhoto(): Promise<void> {
    try {
      const videoRecorder = VideoRecorder.getInstance();
      
      await videoRecorder.takePhoto(
        { defaultFrontCamera: false },
        {
          onPhotoCaptured: (filePath: string) => {
            console.log(`[MessageInput] Photo captured successfully: ${filePath}`);
            this.handleSelectedMedia(filePath, MessageType.IMAGE);
          },
          onError: (errorCode: VideoRecorderErrorCode) => {
            console.error(`[MessageInput] Photo capture failed: ${errorCode}`);
          }
        } as RecordListener,
        this.context
      );
    } catch (error) {
      console.error('[MessageInput] Photo capture error:', error);
    }
  }

  private async recordVideo(): Promise<void> {
    try {
      const videoRecorder = VideoRecorder.getInstance();
      
      await videoRecorder.takeVideo(
        { recordMode: RecordMode.VIDEO_ONLY },
        {
          onVideoCaptured: (filePath: string, duration: number) => {
            console.log(`[MessageInput] Video recorded successfully: ${filePath}, duration: ${duration}s`);
            this.handleSelectedMedia(filePath, MessageType.VIDEO);
          },
          onError: (errorCode: VideoRecorderErrorCode) => {
            console.error(`[MessageInput] Video recording failed: ${errorCode}`);
          }
        } as RecordListener,
        this.context
      );
    } catch (error) {
      console.error('[MessageInput] Video recording error:', error);
    }
  }

  private async handleSelectedMedia(mediaPath: string, messageType: MessageType) {
    if (!this.inputState) {

      return;
    }
    const user_file_uri = mediaPath;
    const tempDir = this.context.cacheDir + "/media/";
    const fileName = user_file_uri.split("/").pop() || `temp_${Date.now()}`;
    const app_file_path = tempDir + fileName;

    // Ensure temp directory exists
    try {
      await fs.mkdir(tempDir, true);
    } catch (error) {
      // Directory might already exist, ignore error
    }

    let user_file = await fs.open(user_file_uri, fs.OpenMode.READ_ONLY);
    let app_file = await fs.open(app_file_path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    await fs.copyFile(user_file.fd, app_file.fd, 0);
    await fs.close(user_file);
    await fs.close(app_file);

    try {
      let payload: SendMessagePayload | undefined = undefined;
      let pushDescription = '';

      if (messageType === MessageType.IMAGE) {
        let imageWidth = 0;
        let imageHeight = 0;
        try {
          const imageSourceApi = image.createImageSource(app_file_path);
          const imageInfo = await imageSourceApi.getImageInfo();
          imageWidth = imageInfo.size.width;
          imageHeight = imageInfo.size.height;
          console.log(`[MessageInput] Image dimensions: ${imageWidth}x${imageHeight}`);
        } catch (error) {
          console.error('[MessageInput] Failed to get image dimensions:', error);
        }
        payload = new ImageSendMessagePayload(app_file_path, imageWidth, imageHeight);
        pushDescription = getContext().resourceManager.getStringSync($r('app.string.message_type_image').id);
      } else if (messageType === MessageType.VIDEO) {
        const fileExtension = app_file_path.split('.').pop()?.toLowerCase() || 'mp4';
        console.log(`[MessageInput] Video type: ${fileExtension}`);

        const videoFileName = app_file_path.split('/').pop()?.split('.')[0] || 'video_cover';
        const thumbnail_file_path = tempDir + videoFileName + '_cover.jpg';

        let videoDurationSec = 1;
        let snapshotWidth = 0;
        let snapshotHeight = 0;
        let snapshotPath = '';

        try {
          let predicates = new dataSharePredicates.DataSharePredicates();
          predicates.equalTo('uri', user_file_uri);
          let fetchResult = await photoAccessHelper.getPhotoAccessHelper(getContext()).getAssets({
            fetchColumns: [photoAccessHelper.PhotoKeys.DURATION],
            predicates: predicates,
          });
          const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();

          const videoDuration = asset.get(photoAccessHelper.PhotoKeys.DURATION) as number;
          videoDurationSec = (videoDuration / 1000);
          console.log(`[MessageInput] Video duration: ${videoDurationSec} seconds`);

          const thumbnail: image.PixelMap = await asset.getThumbnail();
          const thumbnailInfo = await thumbnail.getImageInfo();
          snapshotWidth = thumbnailInfo.size.width;
          snapshotHeight = thumbnailInfo.size.height;
          console.log(`[MessageInput] Video thumbnail dimensions: ${snapshotWidth}x${snapshotHeight}`);

          const imagePackerApi = image.createImagePacker();
          const thumbnail_file = await fs.open(thumbnail_file_path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
          await imagePackerApi.packToFile(thumbnail, thumbnail_file.fd, {
            format: 'image/jpeg',
            quality: 100,
          });
          await fs.close(thumbnail_file);
          snapshotPath = thumbnail_file_path;
        } catch (error) {
          console.error('[MessageInput] Failed to get video info or generate thumbnail:', error);
        }

        payload = new VideoSendMessagePayload(app_file_path, fileExtension, videoDurationSec,
          snapshotPath, snapshotWidth, snapshotHeight);
        pushDescription = getContext().resourceManager.getStringSync($r('app.string.message_type_video').id);
      }

      if (!payload) {
        return;
      }

      const option = new SendMessageOption();
      option.needReadReceipt = this.effectiveConfig.enableReadReceipt ?? false;
      option.offlinePushInfo = this.createOfflinePushInfoForDescription(pushDescription);
      option.quotedMessage = this.quotedMessage;
      this.clearQuotedMessage();

      if (this.inputState) {
        this.inputState.sendMessage(payload, option, new CompletionHandlerAdapter(undefined, (code: number, desc: string) => {
          const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + desc);
          Toast.error(localizedMessage, this.getUIContext());
        }));
      }
    } catch (error) {

    }
  }

  private handleEmojiSelected(emoji: EmojiItem) {
    this.insertEmojiToEditor(emoji);
    this.inputFocused = false;
  }

  private handleDeleteLastCharacter() {
    try {
      const spans = this.richEditorController.getSpans({
        start: 0,
        end: -1
      });

      if (!spans || spans.length === 0) {
        return;
      }
      let totalLength = 0;
      spans.forEach((span) => {
        const textSpan = span as RichEditorTextSpanResult;
        if (textSpan.value !== undefined && textSpan.value !== null) {
          totalLength += textSpan.value.length;
        } else {
          totalLength += 1;
        }
      });
      if (totalLength > 0) {
        this.richEditorController.deleteSpans({
          start: totalLength - 1,
          end: totalLength
        });
      } else {
      }

    } catch (error) {
    }
  }

  /**
   * Get message text from RichEditor spans
   * Key insight: BuilderSpan occupies 1 position in editor, but represents full mentionText
   * We track spans sequentially and match mentions by their startIndex
   */
  private async getMessageText(): Promise<string> {
    try {
      const spans = await this.richEditorController.getSpans({
        start: 0,
        end: -1
      });

      console.log(`[MessageInput] === getMessageText ===`);
      console.log(`[MessageInput] spans.length=${spans.length}, mentionList.length=${this.mentionList.length}`);

      let messageText = '';
      let currentPosition = 0;
      
      // Create a map of mention positions for O(1) lookup
      const mentionMap = new Map<number, MentionInfo>();
      this.mentionList.forEach((m: MentionInfo) => {
        mentionMap.set(m.startIndex, m);
        console.log(`[MessageInput]   mention: startIndex=${m.startIndex}, text="${m.mentionText}"`);
      });
      
      for (let i = 0; i < spans.length; i++) {
        const span = spans[i];
        
        // Check if this position has a mention
        const mention = mentionMap.get(currentPosition);
        if (mention) {
          console.log(`[MessageInput] [${i}] pos=${currentPosition} -> Mention: "${mention.mentionText}"`);
          messageText += mention.mentionText;
          currentPosition += 1; // BuilderSpan = 1 position
          continue;
        }
        
        // Check TextSpan
        const textSpan = span as RichEditorTextSpanResult;
        if (textSpan.value !== undefined && textSpan.value !== null) {
          console.log(`[MessageInput] [${i}] pos=${currentPosition} -> Text: "${textSpan.value}"`);
          messageText += textSpan.value;
          currentPosition += textSpan.value.length;
          continue;
        }
        
        // Check ImageSpan (emoji)
        const imageSpan = span as RichEditorImageSpanResult;
        if (imageSpan.valueResourceStr !== undefined || imageSpan.valuePixelMap !== undefined) {
          let imageResource: string | Resource | undefined = imageSpan.valueResourceStr;
          if (imageResource) {
            let resourceStr = '';
            if (typeof imageResource === 'string') {
              resourceStr = imageResource;
            } else {
              resourceStr = JSON.stringify(imageResource);
            }
            const emojiName = EmojiDataManager.getEmojiNameByResourceString(resourceStr);
            if (emojiName) {
              console.log(`[MessageInput] [${i}] pos=${currentPosition} -> Emoji: "${emojiName}"`);
              messageText += emojiName;
            }
          }
          currentPosition += 1;
          continue;
        }
        
        // Unknown span - likely a BuilderSpan without matching mention (shouldn't happen)
        console.warn(`[MessageInput] [${i}] pos=${currentPosition} -> Unknown span, skipping`);
        currentPosition += 1;
      }

      console.log(`[MessageInput] Final text: "${messageText}"`);
      return messageText;

    } catch (error) {
      console.error(`[MessageInput] getMessageText error: ${error}`);
      return '';
    }
  }

  private insertEmojiToEditor(emoji: EmojiItem) {
    try {
      const emojiResource = EmojiDataManager.getEmojiImageResource(emoji.imageFile);
      const selection = this.richEditorController.getSelection();
      const cursorPosition = selection.selection[1];
      this.richEditorController.addImageSpan(emojiResource, {
        imageStyle: {
          size: [20, 20],
          verticalAlign: ImageSpanAlignment.CENTER,
          objectFit: ImageFit.Contain
        },
        offset: cursorPosition
      });
    } catch (error) {
    }
  }

  private clearEditor() {
    try {
      this.richEditorController.deleteSpans();
    } catch (error) {
    }
  }

  private hideKeyboard() {
    this.inputFocused = false;
    this.showKeyboardPlaceholder = false;
    try {
      focusControl.requestFocus(this.hiddenButtonId);
    } catch (error) {
      console.warn('[MessageInputBar] hideKeyboard error:', error);
    }
  }

  // Start long press timer
  private startLongPressTimer(): void {
    this.longPressTimer = setTimeout(() => {
      console.log('[MessageInput] Long press timer triggered - start recording');
      this.startVoiceRecording();
    }, 300);
  }

  // Cancel long press timer
  private cancelLongPressTimer(): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = undefined;
    }
  }

  // Start voice recording with gesture control
  private startVoiceRecording(): void {
    this.showEmojiPicker = false;
    this.hideKeyboard();
    
    // Reset recording state
    this.recordingDuration = 0;
    this.shouldCancelRecording = false;
    this.shouldTranscribeRecording = false;
    this.dragOffset = 0;
    
    AudioRecorder.getInstance().startRecord(null, false, {
      onDurationUpdate: (duration: number) => {
        this.recordingDuration = duration;
      },
      onRecordingStart: () => {
        this.recordingDuration = 0;
        this.isVoiceRecording = true;
        console.log('[MessageInput] Voice recording started');
      },
      onRecordingStop: (filePath: string, duration: number) => {
        this.isVoiceRecording = false;
        const releaseAction = this.voiceRecordReleaseAction;
        this.voiceRecordReleaseAction = 'send';
        this.recordingDuration = 0;
        this.shouldCancelRecording = false;
        this.shouldTranscribeRecording = false;
        this.dragOffset = 0;
        if (releaseAction === 'transcribe') {
          this.showVoiceTranscriptionDraftView(filePath, duration);
        } else {
          this.sendVoiceMessage(Math.max(1, Math.floor(duration)), filePath);
        }
        console.log('[MessageInput] Voice recording stopped');
      },
      onRecordingCancel: () => {
        this.isVoiceRecording = false;
        this.voiceRecordReleaseAction = 'send';
        this.recordingDuration = 0;
        this.shouldCancelRecording = false;
        this.shouldTranscribeRecording = false;
        this.dragOffset = 0;
        console.log('[MessageInput] Voice recording cancelled');
      }
    });
  }

  // Finish voice recording (send message)
  private finishVoiceRecording(action: VoiceRecordReleaseAction = 'send'): void {
    if (this.isVoiceRecording) {
      this.voiceRecordReleaseAction = action;
      if (action === 'cancel') {
        AudioRecorder.getInstance().cancelRecord();
      } else {
        AudioRecorder.getInstance().stopRecord();
      }
    }
  }

  // Cancel voice recording
  private cancelVoiceRecording(): void {
    if (this.isVoiceRecording) {
      this.voiceRecordReleaseAction = 'cancel';
      AudioRecorder.getInstance().cancelRecord();
    }
  }

  private showVoiceTranscriptionDraftView(filePath: string, duration: number): void {
    if (!filePath) {
      return;
    }
    this.voiceTranscriptionAudioPath = filePath;
    this.voiceTranscriptionAudioDuration = Math.max(1, Math.floor(duration));
    this.voiceTranscriptionText = '';
    this.voiceTranscriptionLoading = true;
    this.showVoiceTranscriptionDraft = true;
    this.convertLocalAudioToText(filePath);
  }

  private hideVoiceTranscriptionDraft(): void {
    this.showVoiceTranscriptionDraft = false;
    this.voiceTranscriptionAudioPath = '';
    this.voiceTranscriptionAudioDuration = 0;
    this.voiceTranscriptionText = '';
    this.voiceTranscriptionLoading = false;
  }

  private convertLocalAudioToText(filePath: string): void {
    this.audioTranscriber.convert(filePath, '', (code: number, desc: string) => {
      console.error(`[MessageInput] convert local audio to text failed, code: ${code}, desc: ${desc}`);
    }, (text?: string) => {
      if (!this.showVoiceTranscriptionDraft) {
        return;
      }
      this.voiceTranscriptionLoading = false;
      this.voiceTranscriptionText = text?.trim() ?? '';
    });
  }

  private sendVoiceTranscriptionText(text: string): void {
    if (!text || text.trim().length === 0 || !this.inputState) {
      return;
    }
    const option = new SendMessageOption();
    option.needReadReceipt = this.effectiveConfig.enableReadReceipt ?? false;
    option.offlinePushInfo = this.createOfflinePushInfoForText(text.trim());
    const payload = new TextSendMessagePayload(text.trim());
    this.inputState.sendMessage(payload, option, new CompletionHandlerAdapter(() => {
      this.hideVoiceTranscriptionDraft();
    }, (code: number, desc: string) => {
      const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + desc);
      Toast.error(localizedMessage, this.getUIContext());
    }));
  }

  private async sendVoiceMessage(duration: number, voiceFilePath?: string) {
    if (!this.inputState) {
      return;
    }
    try {
      const filePath = voiceFilePath || '';
      if (!filePath) {
        return;
      }
      const payload = new AudioSendMessagePayload(filePath, duration);
      const option = new SendMessageOption();
      option.needReadReceipt = this.effectiveConfig.enableReadReceipt ?? false;
      option.offlinePushInfo = this.createOfflinePushInfoForDescription(
        getContext().resourceManager.getStringSync($r('app.string.message_type_voice').id));
      option.quotedMessage = this.quotedMessage;
      this.clearQuotedMessage();

      this.inputState.sendMessage(payload, option, new CompletionHandlerAdapter(undefined, (code: number, desc: string) => {
        const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + desc);
        Toast.error(localizedMessage, this.getUIContext());
      }));

    } catch (error) {
    }
  }

  private async selectFile() {
    try {
      const results = await FilePicker.pickFiles({ maxCount: 1 });
      if (results.length > 0) {
        const filePath: string = results[0].filePath;
        this.handleSelectedFile(filePath);
      } else {
      }
    } catch (error) {
    }
  }

  private async handleSelectedFile(filePath: string) {
    if (!this.inputState) {
      return;
    }

    const user_file_uri = filePath;
    const tempDir = this.context.cacheDir + "/media/";
    const fileName = user_file_uri.split("/").pop() || `temp_file_${Date.now()}`;
    const app_file_path = tempDir + fileName;

    // Ensure temp directory exists
    try {
      await fs.mkdir(tempDir, true);
    } catch (error) {
      // Directory might already exist, ignore error
    }

    try {

      let user_file = await fs.open(user_file_uri, fs.OpenMode.READ_ONLY);
      let app_file = await fs.open(app_file_path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      await fs.copyFile(user_file.fd, app_file.fd, 0);
      await fs.close(user_file);
      await fs.close(app_file);


      const stat = await fs.stat(app_file_path);
      try {
        const fileSize = stat.size;

        // Check for empty file
        if (fileSize === 0) {
          Toast.error($r('app.string.empty_file_error'), this.getUIContext());
          return;
        }

        // Check file size limit (100MB)
        if (fileSize > MessageInput.VIDEO_FILE_MAX_SIZE) {
          Toast.error($r('app.string.file_size_too_large_error'), this.getUIContext());
          return;
        }
      } catch (error) {
        console.error('[MessageInput] Failed to check file size:', error);
        return;
      }

      const fileName = app_file_path.substring(app_file_path.lastIndexOf('/') + 1);
      const payload = new FileSendMessagePayload(app_file_path, fileName, stat.size);

      const option = new SendMessageOption();
      option.needReadReceipt = this.effectiveConfig.enableReadReceipt ?? false;
      option.offlinePushInfo = this.createOfflinePushInfoForDescription(
        getContext().resourceManager.getStringSync($r('app.string.message_type_file').id));
      option.quotedMessage = this.quotedMessage;
      this.clearQuotedMessage();

      this.inputState.sendMessage(payload, option, new CompletionHandlerAdapter(undefined, (code: number, desc: string) => {
        const localizedMessage = IMErrorCode.getErrorMessage(code ?? -1, '' + code + desc);
        Toast.error(localizedMessage, this.getUIContext());
      }));

    } catch (error) {

    }
  }

  // MARK: - Draft Management

  /**
   * Load draft from ConversationListStore when component appears
   */
  private loadDraft(): void {
    if (!this.conversationID) {
      return;
    }

    this.isLoadingDraft = true;
    this.conversationStore.getConversationInfo(this.conversationID, new GetConversationInfoCompletionHandlerAdapter((info: ConversationInfo) => {
      const draft = info.draft;
      if (draft && draft.length > 0) {
        this.setDraftToEditor(draft);
        console.log(`[MessageInput] Draft loaded: ${draft}`);
      }
      setTimeout(() => {
        this.isLoadingDraft = false;
      }, 200);
    }, (_code: number, desc: string) => {
      console.error(`[MessageInput] Failed to load draft: ${desc}`);
      this.isLoadingDraft = false;
    }));
  }

  /**
   * Set draft content to RichEditor
   * Parses emoji codes and inserts them as image spans
   */
  private setDraftToEditor(draft: string): void {
    // Clear current content first
    this.clearEditor();
    
    // Parse emoji text and insert content
    const segments = EmojiDataManager.parseEmojiText(draft);
    
    segments.forEach((segment) => {
      if (segment.type === 'text') {
        // Insert text span
        this.richEditorController.addTextSpan(segment.content, {
          style: {
            fontColor: this.themeState.colors.textColorPrimary,
            fontSize: 14
          }
        });
      } else if (segment.type === 'emoji' && segment.imageFile) {
        // Insert emoji image span
        const emojiResource = EmojiDataManager.getEmojiImageResource(segment.imageFile);
        this.richEditorController.addImageSpan(emojiResource, {
          imageStyle: {
            size: [20, 20],
            verticalAlign: ImageSpanAlignment.CENTER,
            objectFit: ImageFit.Contain
          }
        });
      }
    });
    
    // Auto focus and move cursor to end after draft is loaded
    setTimeout(() => {
      this.inputFocused = true;
    }, 150);
  }

  /**
   * Save draft with debounce (800ms delay)
   */
  private saveDraftWithDebounce(): void {
    // Cancel previous timer
    if (this.draftSaveTimer) {
      clearTimeout(this.draftSaveTimer);
    }
    
    // Create new timer with debounce delay
    this.draftSaveTimer = setTimeout(() => {
      this.saveDraftImmediately();
    }, MessageInput.DRAFT_SAVE_DELAY);
  }

  /**
   * Save draft immediately to ConversationListStore
   */
  private async saveDraftImmediately(): Promise<void> {
    if (!this.conversationID) {
      return;
    }

    const draftText = await this.getMessageText();

    const draftValue = draftText.trim().length === 0 ? '' : draftText;
    this.conversationStore.setConversationDraft(this.conversationID, draftValue, new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
      console.error(`[MessageInput] Failed to save draft: ${desc}`);
    }));
  }

  /**
   * Clear draft from ConversationListStore
   */
  private clearDraft(): void {
    // Cancel any pending draft save timer
    if (this.draftSaveTimer) {
      clearTimeout(this.draftSaveTimer);
      this.draftSaveTimer = undefined;
    }

    if (!this.conversationID) {
      return;
    }

    this.conversationStore.setConversationDraft(this.conversationID, '', new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
      console.error(`[MessageInput] Failed to clear draft: ${desc}`);
    }));
  }

  // MARK: - @ Mention Management

  /**
   * Check if @ mention feature should be enabled
   * Only enabled for group conversations with a valid groupID and enableMention config is true
   */
  private shouldEnableMention(): boolean {
    const configEnabled = this.effectiveConfig.enableMention ?? true;
    return configEnabled && this.parsedConversationType === ConversationType.GROUP && this.parsedGroupID.length > 0;
  }

  /**
   * Handle "@" character input - show mention member picker
   * @param cursorPosition Current cursor position after "@" was typed
   */
  private handleAtInput(cursorPosition: number): void {
    // Record the position where "@" was typed (cursor position - 1 because cursor is after "@")
    this.atPosition = cursorPosition - 1;
    
    // Show mention member dialog
    this.showMentionMemberDialog();
  }

  /**
   * Show the mention member picker dialog
   */
  private showMentionMemberDialog(): void {
    if (!this.parsedGroupID) {
      console.warn('[MessageInput] Cannot show mention dialog: groupID is empty');
      return;
    }

    this.mentionDialogController = new CustomDialogController({
      builder: MentionMemberDialog({
        groupID: this.parsedGroupID,
        atPosition: this.atPosition,
        onMembersSelected: (mentions: MentionInfo[]) => {
          this.handleMentionSelected(mentions);
        },
        onCancel: () => {
          // Keep the "@" character when user cancels
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)',
      autoCancel: false
    });

    this.mentionDialogController.open();
  }

  /**
   * Handle selected members from mention picker
   * @param mentions Array of selected MentionInfo
   */
  private handleMentionSelected(mentions: MentionInfo[]): void {
    console.log(`[MessageInput] handleMentionSelected: ${mentions.length} mentions`);
    
    if (mentions.length === 0) {
      return;
    }

    // Delete the "@" character first
    this.richEditorController.deleteSpans({
      start: this.atPosition,
      end: this.atPosition + 1
    });

    // Insert each mention as BuilderSpan
    let insertOffset = this.atPosition;
    mentions.forEach((mention: MentionInfo) => {
      // Set the startIndex for this mention
      mention.startIndex = insertOffset;
      
      const fullMentionText = mention.mentionText;
      console.log(`[MessageInput]   Insert mention at ${insertOffset}: "${fullMentionText}"`);
      
      // Insert BuilderSpan (atomic, non-editable block)
      this.richEditorController.addBuilderSpan(
        () => {
          this.MentionSpanBuilder(fullMentionText);
        },
        { offset: insertOffset }
      );
      
      // BuilderSpan = 1 position
      insertOffset += 1;
      
      // Add to mention list
      this.mentionList.push(mention);
    });

    // Move cursor to end of inserted mentions
    setTimeout(() => {
      this.richEditorController.setCaretOffset(insertOffset);
    }, 50);

    console.log(`[MessageInput] mentionList now has ${this.mentionList.length} items`);
  }

  /**
   * Builder for mention span - creates an atomic, non-editable mention block
   */
  @Builder
  MentionSpanBuilder(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(this.themeState.colors.textColorLink || '#4A90E2')
      .fontWeight(FontWeight.Medium)
  }

  /**
   * Handle mention deletion when text is deleted
   * BuilderSpan is atomic - when deleted, remove from mentionList and update positions
   */
  private handleMentionDeletion(deleteStart: number, deleteEnd: number): void {
    if (this.isRemovingMention) {
      return;
    }

    const deleteLength = deleteEnd - deleteStart;
    if (deleteLength <= 0 || this.mentionList.length === 0) {
      return;
    }

    // Find mentions that were deleted
    const deletedCount = this.mentionList.filter((mention: MentionInfo) => {
      return mention.startIndex >= deleteStart && mention.startIndex < deleteEnd;
    }).length;

    if (deletedCount > 0) {
      // Remove deleted mentions
      this.mentionList = this.mentionList.filter((mention: MentionInfo) => {
        return mention.startIndex < deleteStart || mention.startIndex >= deleteEnd;
      });
      console.log(`[MessageInput] Removed ${deletedCount} mentions, remaining: ${this.mentionList.length}`);
    }

    // Update positions of remaining mentions after deletion point
    this.mentionList.forEach((mention: MentionInfo) => {
      if (mention.startIndex >= deleteEnd) {
        mention.startIndex -= deleteLength;
      }
    });
  }

  // MARK: - Offline Push Info Creation

  /**
   * Create offline push info for a text message
   */
  private createOfflinePushInfoForText(text: string): OfflinePushInfo {
    return this.createOfflinePushInfoForDescription(text);
  }

  private createOfflinePushInfoForDescription(description: string): OfflinePushInfo {
    const loginUserInfo = LoginStore.shared().state.loginUserInfo;
    const selfUserId = loginUserInfo?.userID ?? '';
    const selfName = loginUserInfo?.nickname ?? selfUserId;

    const isGroup = this.conversationID.startsWith('group_');
    const groupId = isGroup ? this.conversationID.substring(6) : '';

    let chatName: string | undefined = undefined;
    const conversations = this.conversationStore.state.conversationList;
    const conversationCount = conversations.totalCount();
    for (let i = 0; i < conversationCount; i++) {
      const conversation = conversations.getData(i);
      if (conversation && conversation.conversationID === this.conversationID && conversation.title) {
        chatName = conversation.title;
        break;
      }
    }

    const title = isGroup ? (chatName || groupId) : selfName;

    const ext = this.createOfflinePushExtJson(
      isGroup,
      description,
      isGroup ? groupId : selfUserId,
      title,
      loginUserInfo?.avatarURL
    );

    const pushInfo = new OfflinePushInfo();
    pushInfo.title = title;
    pushInfo.description = this.trimPushDescription(description);
    pushInfo.extensionInfo = new Map<string, Object>();
    pushInfo.extensionInfo.set('ext', ext);
    pushInfo.extensionInfo.set('AndroidOPPOChannelID', 'tuikit');
    pushInfo.extensionInfo.set('AndroidHuaWeiCategory', 'IM');
    pushInfo.extensionInfo.set('AndroidVIVOCategory', 'IM');
    pushInfo.extensionInfo.set('AndroidHonorImportance', 'NORMAL');
    pushInfo.extensionInfo.set('AndroidMeizuNotifyType', 1);
    pushInfo.extensionInfo.set('iOSInterruptionLevel', 'time-sensitive');
    pushInfo.extensionInfo.set('enableIOSBackgroundNotification', false);
    return pushInfo;
  }

  /**
   * Trim push description to max length
   */
  private trimPushDescription(text: string, maxLength: number = 50): string {
    if (typeof text !== 'string') {
      return '';
    }
    const normalized = text.trim().replace(/\n/g, ' ').replace(/\r/g, ' ');
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  /**
   * Create offline push ext JSON
   */
  private createOfflinePushExtJson(
    isGroup: boolean,
    description: string,
    senderId: string,
    senderNickName: string,
    faceUrl?: string
  ): string {
    interface BusinessInfo {
      content: string;
      sender: string;
      nickname: string;
      chatType: number;
      faceUrl?: string;
    }

    const businessInfo: BusinessInfo = {
      content: description,
      sender: senderId,
      nickname: senderNickName,
      chatType: isGroup ? 2 : 1
    };

    if (faceUrl) {
      businessInfo.faceUrl = faceUrl;
    }

    interface ConfigInfo {
      fcmPushType: number;
      fcmNotificationType: number;
    }

    const configInfo: ConfigInfo = {
      fcmPushType: 0,
      fcmNotificationType: 0
    };

    interface ExtJson {
      entity: BusinessInfo;
      timPushFeatures: ConfigInfo;
    }

    const extJson: ExtJson = {
      entity: businessInfo,
      timPushFeatures: configInfo
    };

    return JSON.stringify(extJson);
  }
}
